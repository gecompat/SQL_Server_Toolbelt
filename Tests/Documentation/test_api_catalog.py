"""Regressionen gegen stillen API-Verlust, falsche Defaults und Katalogdrift."""
import json
import tempfile
import unittest
from pathlib import Path

import generate_api_catalog as catalog
import validate_documentation as documentation


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.module = self.root / "Modules/toolbelt.test"
        (self.module / "Source").mkdir(parents=True)
        (self.root / "Documentation/Reference").mkdir(parents=True)
        self.manifest = self.module / "module.yaml"
        self.manifest.write_text('version: "1.0.0"\nobjects:\n'
            '  - {type: USP, schema: toolbelt_test, name: USP_Test, visibility: public}\n'
            '  - type: VW\n    schema: toolbelt_test\n    name: VW_Test\n    visibility: public\n'
            '  - {type: TABLE, schema: toolbelt_test, name: Data, visibility: public}\n'
            '  - {type: USP, schema: toolbelt_test, name: USP_Internal, visibility: internal}\n', encoding="utf-8")
        self.source = self.module / "Source/Test.sql"
        self.source.write_text("CREATE PROCEDURE toolbelt_test.USP_Test\n"
            " @RootAlias nvarchar(20) = N'AS,(--)', /* outer /* nested */ comment */\n"
            " @Answer decimal(10,2) = NULL OUTPUT\nAS SELECT 1;\nGO\n"
            "CREATE VIEW toolbelt_test.VW_Test AS SELECT 1 AS Value;", encoding="utf-8")
        (self.module / "README.md").write_text("# Synthetischer Vertrag\n", encoding="utf-8")
        directory = self.root / "Metadata/UsageSkills/toolbelt_test"
        directory.mkdir(parents=True)
        self.skill = directory / "USP_Test.md"
        self.view_skill = directory / "VW_Test.md"
        for item, path, description, example in (
            (catalog.objects(self.root)[0], self.skill, "Synthetisches Beispiel.",
             "EXEC toolbelt_test.USP_Test @RootAlias=N'example';"),
            (catalog.objects(self.root)[1], self.view_skill, "Synthetische View.",
             "SELECT * FROM toolbelt_test.VW_Test;"),
        ):
            _, params = catalog.signature(item)
            metadata = dict(name=item["name"].lower().replace("_", "-"),
                            description=description, skill_format_version="1.0",
                            module_id=item["module"], schema_name=item["schema"],
                            object_name=item["name"], object_type=item["type"],
                            database_role="toolbelt", is_internal=False, review_status="verified",
                            source_paths=["Modules/toolbelt.test/Source/Test.sql"],
                            parameters=[dict(name=p["name"], sql_type=p["type"], sql_default=p["default"],
                                             is_output=p["output"], argument_required=False,
                                             business_required=False, nullable=True,
                                             description="Synthetischer Output." if p["output"] else "Synthetischer Alias.")
                                        for p in params])
            front = "\n".join(f"{field}: {json.dumps(value, ensure_ascii=False)}"
                              for field, value in metadata.items())
            sections = "\n".join(f"## {section}\n\n" +
                                 (f"```sql\n{example}\n```\n" if section == "Aufrufbeispiele" else "Synthetisch.\n")
                                 for section in catalog.usage_skills.SECTIONS)
            path.write_text(f"---\n{front}\n---\n\n{sections}", encoding="utf-8", newline="\n")

    def test_public_inventory_includes_block_view_and_excludes_internal(self):
        self.assertEqual([i["name"] for i in catalog.objects(self.root)], ["USP_Test", "VW_Test"])

    def test_technical_module_with_explicit_empty_objects_has_no_api(self):
        self.manifest.write_text('version: "1.0.0"\nobjects: []\n', encoding="utf-8")
        self.assertEqual(catalog.objects(self.root), [])

    def test_defaults_and_output_ignore_sql_literals_and_nested_comments(self):
        _, params = catalog.signature(catalog.objects(self.root)[0])
        self.assertEqual(params[0]["default"], "N'AS,(--)'")
        self.assertEqual(params[1], dict(name="@Answer", type="decimal(10,2)", default="NULL", output=True))

    def test_dynamic_aggregate_does_not_parse_enclosing_literal_as_body(self):
        self.source.write_text("EXEC sys.sp_executesql N'CREATE AGGREGATE toolbelt_test.AGF_Test"
            "(@Ordinal int, @Value nvarchar(max)) RETURNS nvarchar(max) EXTERNAL NAME X.Y.Z;';", encoding="utf-8")
        _, params = catalog.signature(dict(schema="toolbelt_test", name="AGF_Test", type="CLR_AGGREGATE", root=self.module))
        self.assertEqual([p["name"] for p in params], ["@Ordinal", "@Value"])

    def test_missing_or_misidentified_skill_is_rejected(self):
        content = self.view_skill.read_text(encoding="utf-8")
        self.view_skill.unlink()
        with self.assertRaisesRegex(ValueError, "Usage-Skill fehlt"):
            catalog.render(self.root)
        self.view_skill.write_text(content.replace('object_name: "VW_Test"', 'object_name: "VW_Other"'),
                                   encoding="utf-8", newline="\n")
        with self.assertRaisesRegex(ValueError, "gehört nicht zur öffentlichen Schnittstelle"):
            catalog.render(self.root)

    def test_unknown_type_and_duplicate_api_fail_closed(self):
        original = self.manifest.read_text(encoding="utf-8")
        self.manifest.write_text(original.replace("type: VW", "type: FUTURE"), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "öffentlicher Typ"):
            catalog.objects(self.root)
        self.manifest.write_text(original + '  - {type: USP, schema: toolbelt_test, name: USP_Test, visibility: public}\n', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Doppelte"):
            catalog.objects(self.root)

    def test_new_parameter_requires_explanation_review(self):
        self.source.write_text(self.source.read_text(encoding="utf-8").replace(
            "@Answer decimal", "@New bit=0, @Answer decimal"), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Parametererklärungen"):
            catalog.render(self.root)

    def test_existing_parameter_binding_cannot_drift_from_skill(self):
        original = self.source.read_text(encoding="utf-8")
        for before, after in (
            ("decimal(10,2)", "decimal(11,2)"),
            ("NULL OUTPUT", "NULL"),
            (" = NULL OUTPUT", " OUTPUT"),
            ("N'AS,(--)'", "N'as,(--)'"),
        ):
            with self.subTest(after=after):
                self.source.write_text(original.replace(before, after), encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "SQL-Parameterbindung"):
                    catalog.render(self.root)

    def test_drift_for_source_contract_example_and_artifact(self):
        for path in [self.source, self.module / "README.md", self.skill,
                     self.root / "Documentation/Reference/API_CATALOG.html"]:
            with self.subTest(path=path.name):
                catalog.check(self.root, write=True)
                old = path.read_text(encoding="utf-8")
                new = old.replace("Synthetisches Beispiel.", "Neues Beispiel.") if path == self.skill else old + "\n-- change\n"
                path.write_text(new, encoding="utf-8", newline="\n")
                with self.assertRaisesRegex(ValueError, "Katalog veraltet"):
                    catalog.check(self.root)
                path.write_text(old, encoding="utf-8", newline="\n")

    def test_render_escapes_html_and_portable_line_endings(self):
        catalog.check(self.root, write=True)
        output = self.root / "Documentation/Reference/API_CATALOG.md"
        content = output.read_text(encoding="utf-8")
        output.write_bytes(content.replace("\n", "\r\n").encode("utf-8"))
        catalog.check(self.root)
        page = catalog.render(self.root)["API_CATALOG.html"]
        self.assertIn("&#x27;example&#x27;", page)
        self.assertIn("../../Modules/toolbelt.test/README.md", page)

    def test_object_parameter_block_regenerates_without_changing_manual_prose(self):
        page = self.module / "Documentation/USP_Test.md"
        page.parent.mkdir()
        page.write_text("# Test\n\nManuelle Erklärung.\n\n" + catalog.PARAMETER_BEGIN
                        + "\nveraltet\n" + catalog.PARAMETER_END + "\n\nManuelles Beispiel.\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Eingabevertrag veraltet"):
            catalog.check(self.root)
        catalog.check(self.root, write=True)
        catalog.check(self.root)
        text = page.read_text(encoding="utf-8")
        self.assertIn("Manuelle Erklärung.", text)
        self.assertIn("Manuelles Beispiel.", text)
        self.assertIn("Synthetischer Output.", text)
        self.assertIn("OUTPUT", text)
        page.write_text(text.replace("Synthetischer Output.", "Falsche Erklärung."), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "Eingabevertrag veraltet"):
            catalog.check(self.root)

    def test_markdown_parameter_text_preserves_data_examples(self):
        self.assertEqual(catalog.markdown_note('JSON <key> | Wert & Länge'),
                         'JSON &lt;key&gt; &#124; Wert &amp; Länge')


class CatalogNavigationTests(unittest.TestCase):
    root = "[Installieren](./INSTALL.md) [Module](./Modules/README.md)"

    @staticmethod
    def table(rows):
        return "<!-- BEGIN GENERATED:MODULE_STATUS_TABLE -->\n" + "".join(
            f"| `{mid}` | synthetic |\n" for mid in rows) + "<!-- END GENERATED:MODULE_STATUS_TABLE -->"

    def test_one_canonical_catalog_needs_no_duplicate_root_inventory(self):
        documentation.validate_catalog_navigation(self.root, self.table(["toolbelt.test"]), {"toolbelt.test"})

    def test_missing_installation_or_catalog_link_fails(self):
        for link in ("[Installieren](./INSTALL.md)", "[Module](./Modules/README.md)"):
            with self.subTest(link=link), self.assertRaises(documentation.ValidationError):
                documentation.validate_catalog_navigation(link, self.table(["toolbelt.test"]), {"toolbelt.test"})

    def test_missing_extra_duplicate_or_unframed_inventory_fails(self):
        for content in (self.table([]), self.table(["toolbelt.other"]),
                        self.table(["toolbelt.test", "toolbelt.test"]), "| `toolbelt.test` | synthetic |"):
            with self.subTest(content=content), self.assertRaises(documentation.ValidationError):
                documentation.validate_catalog_navigation(self.root, content, {"toolbelt.test"})


if __name__ == "__main__":
    unittest.main()
