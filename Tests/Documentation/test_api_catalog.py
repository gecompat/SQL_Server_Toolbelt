"""Regressionen gegen stillen API-Verlust, falsche Defaults und Katalogdrift."""
import json
import tempfile
import unittest
from pathlib import Path

import generate_api_catalog as catalog


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
        self.registry = self.root / "Documentation/Reference/api_examples.json"
        self.registry.write_text(json.dumps({
            "toolbelt_test.USP_Test": dict(summary="Synthetisches Beispiel.", requirements=[],
                parameter_notes={"@RootAlias": "Synthetischer Alias.", "@Answer": "Synthetischer Output."},
                examples=["EXEC toolbelt_test.USP_Test @RootAlias=N'example';"]),
            "toolbelt_test.VW_Test": dict(summary="Synthetische View.", requirements=[], parameter_notes={},
                examples=["SELECT * FROM toolbelt_test.VW_Test;"]),
        }), encoding="utf-8")

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

    def test_registry_missing_and_stale_entries_are_rejected(self):
        entries = json.loads(self.registry.read_text(encoding="utf-8"))
        entries["toolbelt_test.Obsolete"] = entries.pop("toolbelt_test.VW_Test")
        self.registry.write_text(json.dumps(entries), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "unvollständig/veraltet"):
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

    def test_drift_for_source_contract_example_and_artifact(self):
        for path in [self.source, self.module / "README.md", self.registry,
                     self.root / "Documentation/Reference/API_CATALOG.html"]:
            with self.subTest(path=path.name):
                catalog.check(self.root, write=True)
                old = path.read_text(encoding="utf-8")
                new = old.replace("Synthetisches Beispiel.", "Neues Beispiel.") if path == self.registry else old + "\n-- change\n"
                path.write_text(new, encoding="utf-8")
                with self.assertRaisesRegex(ValueError, "Katalog veraltet"):
                    catalog.check(self.root)
                path.write_text(old, encoding="utf-8")

    def test_render_escapes_html_and_portable_line_endings(self):
        catalog.check(self.root, write=True)
        output = self.root / "Documentation/Reference/API_CATALOG.md"
        content = output.read_text(encoding="utf-8")
        output.write_bytes(content.replace("\n", "\r\n").encode("utf-8"))
        catalog.check(self.root)
        page = catalog.render(self.root)["API_CATALOG.html"]
        self.assertIn("&#x27;example&#x27;", page)
        self.assertIn("../../Modules/toolbelt.test/README.md", page)


if __name__ == "__main__":
    unittest.main()
