"""Reale Prototypen und adversarielle Datentransporte; keine SQL-Verbindung."""
from copy import deepcopy
import importlib.util
from pathlib import Path
import re
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("usage_skills", ROOT / "Scripts/Metadata/usage_skills.py")
import sys
skills = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = skills
spec.loader.exec_module(skills)


def prototypes():
    # This suite exercises the first explicitly source-reviewed representatives.
    # Full release completeness is separately enforced, never inferred here.
    result = [skills.read(p, verified=False) for p in sorted((ROOT / "Metadata/UsageSkills").glob("*/*.md"))]
    return [skill for skill in result if skill.metadata["review_status"] == "verified"]


def literal_value(expression):
    # Independent SQL-string reader: doubled apostrophes, no SQL execution.
    values = re.findall(r"N'((?:[^']|'')*)'", expression)
    return "".join(value.replace("''", "'") for value in values)


class UsageSkillTests(unittest.TestCase):
    def test_every_source_is_structurally_valid_and_unreviewed_sources_reject_shipping(self):
        for path in sorted((ROOT / "Metadata/UsageSkills").glob("*/*.md")):
            source = skills.read(path, verified=False)
            if source.metadata["review_status"] == "draft":
                with self.subTest(path=path.name), self.assertRaisesRegex(ValueError, "Ungeprüfter"):
                    skills.validate(source)

    def test_source_prototypes_cover_every_requested_representative_kind(self):
        current = prototypes()
        self.assertTrue({"USP", "TVF", "VIEW", "TABLE", "VW"} <= {s.metadata["object_type"] for s in current})
        self.assertTrue(any(s.metadata["is_internal"] for s in current))
        self.assertTrue(any(s.metadata["object_name"] == "VW_ObjectUsageSkills" for s in current))

    def test_frontmatter_preserves_parameter_defaults_and_flags(self):
        sample = next(s for s in prototypes() if s.metadata["object_name"] == "USP_PrepareResultTable")
        first = sample.metadata["parameters"][0]
        self.assertEqual(first["sql_default"], "NULL")
        self.assertFalse(first["argument_required"])
        self.assertTrue(first["business_required"])
        self.assertFalse(first["nullable"])

    def test_yml_frontmatter_rejects_duplicate_keys_and_executable_tags(self):
        sample = prototypes()[0].markdown
        for text in (sample.replace("---\n", '---\nname: "duplicate"\n', 1),
                     sample.replace('skill_format_version: "1.0"', 'skill_format_version: !!python/object "bad"')):
            with self.subTest(text=text[:40]), self.assertRaises((ValueError, TypeError)):
                skills.parse_frontmatter(text)

    def test_canonical_file_encoding_is_enforced(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample.md"
            data = prototypes()[0].markdown
            for raw in (b"\xef\xbb\xbf" + data.encode(), data.replace("\n", "\r\n").encode()):
                path.write_bytes(raw)
                with self.assertRaises(ValueError):
                    skills.read(path)

    def test_missing_sections_and_unreviewed_sources_cannot_ship(self):
        source = prototypes()[0]
        changed = source.markdown.replace("## Fehlerbehandlung", "## FehlenderAbschnitt")
        with self.assertRaisesRegex(ValueError, "Abschnitt fehlt"):
            skills.validate(skills.Skill(source.metadata, changed))
        metadata = deepcopy(source.metadata)
        metadata["review_status"] = "draft"
        with self.assertRaisesRegex(ValueError, "Ungeprüfter"):
            skills.render_view([skills.Skill(metadata, source.markdown)])

    def test_internal_helpers_require_public_entrypoints(self):
        source = next(s for s in prototypes() if s.metadata["is_internal"])
        metadata = deepcopy(source.metadata)
        metadata["public_entrypoints"] = []
        with self.assertRaisesRegex(ValueError, "öffentliche Einstiege"):
            skills.validate(skills.Skill(metadata, source.markdown))

    def test_description_cannot_be_silently_truncated_or_codepage_converted(self):
        source = prototypes()[0]
        for field, value in (("description", "𐐀" * 2001), ("object_type", "TÄBLE")):
            metadata = deepcopy(source.metadata)
            metadata[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                skills.validate(skills.Skill(metadata, source.markdown))

    def test_source_references_cannot_point_into_private_runtime(self):
        source = prototypes()[0]
        for path in (".runtime/private.sql", "../private.sql", "C:/private.sql", "//host/share/private.sql"):
            metadata = deepcopy(source.metadata)
            metadata["source_paths"] = [path]
            with self.subTest(path=path), self.assertRaises(ValueError):
                skills.validate(skills.Skill(metadata, source.markdown))

    def test_long_unicode_sql_literal_roundtrip_has_no_4000_unit_intermediate(self):
        text = "ÄÖ𐐀 O'Brien\n" * 2000
        expression = skills.sql_literal(text)
        self.assertEqual(literal_value(expression), text)
        self.assertTrue(expression.startswith("CAST(N'"))
        self.assertIn("AS nvarchar(max))", expression)
        for value in re.findall(r"N'((?:[^']|'')*)'", expression):
            self.assertLessEqual(skills.units(value.replace("''", "'")), 2000)

    def test_ddl_comment_transports_exact_skill_without_executable_markdown(self):
        source = prototypes()[0]
        # GO, nested block delimiters and Unicode line separators remain data.
        markdown = source.markdown + "\n/* */\nGO\n-- OBJECT_USAGE_SKILL:END\nÄ𐐀\u2028O'Brien\n"
        changed = skills.Skill(source.metadata, markdown)
        comment = skills.render_ddl_comment(changed)
        self.assertEqual(skills.read_ddl_comment(comment).markdown, markdown)
        self.assertTrue(all(line == "--" or line.startswith("-- ") for line in comment.split("\n")[:-1]))
        self.assertNotIn("-- \n", comment)
        self.assertEqual(skills.read_ddl_comment("CREATE VIEW x AS\n" + comment + "SELECT 1;\n").markdown,
                         markdown)

    def test_ddl_comment_rejects_ambiguous_or_active_payload(self):
        comment = skills.render_ddl_comment(prototypes()[0])
        for broken in (comment + comment, comment.replace("-- name:", "name:", 1),
                       comment.replace(skills.DDL_END, "-- missing", 1)):
            with self.subTest(broken=broken[:50]), self.assertRaises(ValueError):
                skills.read_ddl_comment(broken)

    def test_help_is_one_additional_four_column_constant_resultset(self):
        source = next(s for s in prototypes() if s.metadata["object_type"] == "USP")
        sql = skills.render_help_resultset(source)
        aliases = re.findall(r" AS (\w+)[,;]\n", re.sub(r"N'(?:[^']|'')*'", "''", sql))
        self.assertEqual(aliases, ["SkillFormatVersion", "SchemaName", "ObjectName", "SkillMarkdown"])
        self.assertEqual(literal_value(sql), "".join((source.metadata["skill_format_version"],
                         source.metadata["schema_name"], source.metadata["object_name"], source.markdown)))
        outside_strings = re.sub(r"N'(?:[^']|'')*'", "''", sql)
        self.assertEqual(len(re.findall(r"\bSELECT\b", outside_strings)), 1)
        self.assertNotRegex(outside_strings, r"(?i)\b(?:FROM|EXEC|RETURN|SET|INSERT|UPDATE|DELETE)\b")
        for indent in (0, 4, 8, 64):
            self.assertEqual(literal_value(skills.render_help_projection(source, indent)), literal_value(sql))
            self.assertFalse(any(line and not line.strip() for line in skills.render_help_projection(source, indent).split("\n")))
        with self.assertRaisesRegex(ValueError, "Prozedur"):
            skills.render_help_resultset(next(s for s in prototypes() if s.metadata["object_type"] == "TVF"))

    def test_inline_ddl_projection_keeps_all_executable_bytes_and_is_idempotent(self):
        source = next(s for s in prototypes() if s.metadata["object_name"] == "TVF_GetBitBigInt")
        path = source.metadata["source_paths"][0]
        current = (ROOT / path).read_text(encoding="utf-8-sig")
        original = skills.strip_ddl_projection(ROOT, path, current)
        projected = skills.project_inline_function(original, source)
        self.assertEqual(skills.strip_ddl_projection(ROOT, path, projected), original)
        self.assertEqual(skills.project_inline_function(projected, source), projected)
        self.assertEqual(skills.read_ddl_comment(projected).markdown, source.markdown)
        with self.assertRaisesRegex(ValueError, "quellzugeordnet"):
            skills.strip_ddl_projection(ROOT, path + ".other", projected)
        tampered = projected.replace("Liest das Bit", "Andere Funktion", 1)
        with self.assertRaisesRegex(ValueError, "kanonisch"):
            skills.strip_ddl_projection(ROOT, path, tampered)

    def test_inline_projection_does_not_parse_quoted_or_nested_comment_ddl_as_code(self):
        source = next(s for s in prototypes() if s.metadata["object_name"] == "TVF_GetBitBigInt")
        sql = "/* outer /* CREATE FUNCTION fake AS */ RETURN */\n"
        sql += "CREATE FUNCTION toolbelt_binary.TVF_GetBitBigInt(@Value bigint,@BitOffset bigint)\n"
        sql += "RETURNS TABLE\nAS\nRETURN (SELECT N'CREATE FUNCTION fake AS' AS Value);\n"
        projected = skills.project_inline_function(sql, source)
        self.assertEqual(projected.replace(skills.render_ddl_comment(source), "", 1), sql)
        for broken in (sql.replace("TVF_GetBitBigInt", "TVF_Wrong", 1),
                       sql.replace("RETURNS TABLE", "RETURNS @Result TABLE", 1),
                       sql + "CREATE VIEW y AS SELECT 1;\n", "/* missing end"):
            with self.subTest(broken=broken[:45]), self.assertRaises(ValueError):
                skills.project_inline_function(broken, source)

    def test_internal_procedure_projection_preserves_original_help_and_outputs(self):
        source = next(s for s in prototypes() if s.metadata["object_name"] == "USP_SecondSessionProbe")
        path = source.metadata["source_paths"][0]
        current = (ROOT / path).read_text(encoding="utf-8-sig")
        original = skills.strip_ddl_projection(ROOT, path, skills.strip_help_projection(ROOT, path, current))
        projected = skills.project_procedure_ddl(skills.project_procedure_help(original, source), source)
        self.assertEqual(skills.project_procedure_help(projected, source), projected)
        self.assertEqual(skills.project_procedure_ddl(projected, source), projected)
        self.assertEqual(skills.strip_ddl_projection(ROOT, path,
                         skills.strip_help_projection(ROOT, path, projected)), original)
        # The admitted new SELECT precedes return; existing OUTPUT assignments
        # and original help bytes are protected by the exact roundtrip above.
        _, indent = skills._procedure_help_return(projected, source)
        self.assertIn(skills.render_help_projection(source, indent) + "        RETURN 0;", projected)
        self.assertLess(projected.index(skills.HELP_BEGIN), projected.index("SET @RemoteSessionId = @@SPID"))

    def test_procedure_projection_rejects_nonpositive_guards_and_unreachable_help(self):
        source = next(s for s in prototypes() if s.metadata["object_name"] == "USP_SecondSessionProbe")
        name = "CREATE PROCEDURE toolbelt_core.USP_SecondSessionProbe @Hilfe bit=0 AS\nBEGIN\n"
        valid = name + "IF @Hilfe=1 BEGIN\n SELECT N'RETURN END',CASE WHEN 1=1 THEN 2 END;\n RETURN 0;\nEND;\nEND;\n"
        self.assertIn(skills.HELP_BEGIN, skills.project_procedure_help(valid, source))
        for broken in (valid.replace("@Hilfe=1", "@Hilfe=0"),
                       valid.replace("RETURN 0;", "RETURN 0; SELECT 42;"),
                       valid.replace("SELECT N'", "RETURN 0; SELECT N'", 1),
                       valid.replace("USP_SecondSessionProbe", "USP_Another")):
            with self.subTest(broken=broken[:70]), self.assertRaises(ValueError):
                skills.project_procedure_help(broken, source)

    def test_existing_skill_help_cannot_be_relocated_or_changed(self):
        source = next(s for s in prototypes() if s.metadata["object_name"] == "USP_SecondSessionProbe")
        path = source.metadata["source_paths"][0]
        text = (ROOT / path).read_text(encoding="utf-8-sig")
        text = skills.strip_ddl_projection(ROOT, path, skills.strip_help_projection(ROOT, path, text))
        projected = skills.project_procedure_help(text, source)
        block = skills.render_help_projection(source)
        self.assertIn(block, projected)
        for broken in (projected.replace(block, "", 1) + block,
                       projected.replace(" AS SkillMarkdown;", " AS WrongColumn;", 1),
                       projected.replace(block, block + block, 1)):
            with self.subTest(broken=broken[-50:]), self.assertRaises(ValueError):
                skills.project_procedure_help(broken, source)

    def test_view_contract_is_exactly_eight_columns_and_constant_data(self):
        sql = skills.render_view(prototypes())
        header = sql.split("FROM (VALUES", 1)[0]
        self.assertEqual(re.findall(r" AS (\w+)", header), [
            "SchemaName", "ObjectName", "ObjectType", "DatabaseRole", "IsInternal",
            "Description", "SkillFormatVersion", "SkillMarkdown"])
        self.assertIn("CONVERT(nvarchar(max),v.SkillMarkdown)", header)
        outside_strings = re.sub(r"N?'(?:[^']|'')*'", "''", sql)
        self.assertNotRegex(outside_strings, r"(?i)\b(?:EXEC|INSERT|UPDATE|DELETE|OPENROWSET|HASHBYTES)\b|sys\.")

    def test_input_order_and_iterator_do_not_change_generated_bytes(self):
        current = prototypes()
        expected = skills.render_view(current)
        self.assertEqual(skills.render_view(reversed(current)), expected)
        self.assertEqual(skills.render_view(iter(current)), expected)

    def test_duplicate_identity_and_missing_self_description_are_rejected(self):
        current = prototypes()
        with self.assertRaisesRegex(ValueError, "Doppelte"):
            skills.render_view(current + current[:1])
        with self.assertRaisesRegex(ValueError, "Selbstbeschreibung"):
            skills.render_view([s for s in current if s.metadata["object_name"] != "VW_ObjectUsageSkills"])

    def test_prototype_parameter_shapes_match_real_declarations(self):
        sys.path.insert(0, str(ROOT / "Tests/Documentation"))
        import generate_api_catalog as catalog
        for skill in prototypes():
            m = skill.metadata
            if m["object_type"] == "TABLE":
                continue
            if m["object_name"] == "VW_ObjectUsageSkills":
                # New view is a prototype, not yet registered/installed.
                self.assertEqual(m["parameters"], [])
                continue
            item = {"root": ROOT / "Modules" / m["module_id"], "schema": m["schema_name"],
                    "name": m["object_name"], "type": m["object_type"]}
            _, actual = catalog.signature(item)
            expected = m["parameters"]
            self.assertEqual([(p["name"], p["type"], p["default"], p["output"]) for p in actual],
                             [(p["name"], p["sql_type"], p["sql_default"] or "kein Default", p["is_output"]) for p in expected])


if __name__ == "__main__":
    unittest.main()
