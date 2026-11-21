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
    def test_full_generator_never_creates_partial_output_from_review_drafts(self):
        spec = importlib.util.spec_from_file_location("generate_usage_skills", ROOT / "Scripts/Metadata/generate_usage_skills.py")
        generator = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(generator)
        sources = [skills.read(p, verified=False) for p in (ROOT / "Metadata/UsageSkills").glob("*/*.md")]
        expected = skills.inventory(ROOT)
        incomplete = (any(s.metadata["review_status"] == "draft" for s in sources)
                      or {s.identity for s in sources} != set(expected))
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "not-created" / "Skills.sql"
            if incomplete:
                with self.assertRaises(ValueError):
                    generator.generate(ROOT, output)
                self.assertFalse(output.parent.exists())
            else:
                self.assertEqual(generator.generate(ROOT, output), len(expected))
                self.assertEqual(output.read_text(encoding="utf-8"), skills.render_view(sources))

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
                       sql + sql, "/* missing end"):
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

    def test_grouped_procedures_preserve_their_own_help_and_definition(self):
        sources = [next(s for s in prototypes() if s.metadata["object_name"] == name)
                   for name in ("USP_PrepareResultTable", "USP_SecondSessionProbe")]
        parts = [(ROOT / s.metadata["source_paths"][0]).read_text(encoding="utf-8-sig") for s in sources]
        combined = "\n".join(parts)
        for skill in sources:
            self.assertEqual(skills.project_procedure_help(combined, skill), combined)
            self.assertEqual(skills.project_procedure_ddl(combined, skill), combined)
            a, b = skills._procedure_region(combined, skill)
            self.assertIn(skills.render_help_projection(skill), combined[a:b])
            for other in sources:
                if other.identity != skill.identity:
                    self.assertNotIn(skills.render_help_projection(other), combined[a:b])
        original = combined
        for skill in sources:
            original = original.replace(skills.render_ddl_comment(skill), "", 1)
            original = original.replace(skills.render_help_projection(skill), "", 1)
        for order in (sources, list(reversed(sources))):
            output = original
            for skill in order:
                output = skills.project_procedure_ddl(skills.project_procedure_help(output, skill), skill)
            self.assertEqual(output, combined)
        orphan = combined + skills.render_help_projection(sources[0])
        with self.assertRaisesRegex(ValueError, "außerhalb"):
            skills.project_procedure_help(orphan, sources[1])
        block = skills.render_ddl_comment(sources[0])
        swapped = combined.replace(block, "", 1).replace(skills.render_ddl_comment(sources[1]),
                   block + skills.render_ddl_comment(sources[1]), 1)
        with self.assertRaisesRegex(ValueError, "außerhalb"):
            skills.project_procedure_ddl(swapped, sources[0])

    def test_real_grouped_filesystem_help_binding_ignores_neighbor_procs_and_temp_ddl(self):
        # Parsing an existing draft proves declaration binding only, never its
        # editorial review, help acceptance or execution of filesystem actions.
        source = skills.read(ROOT / "Metadata/UsageSkills/toolbelt_filesystem/USP_ReadBinaryFileChunk.md", verified=False)
        text = (ROOT / source.metadata["source_paths"][0]).read_text(encoding="utf-8-sig")
        a, b = skills._procedure_region(text, source)
        self.assertIn("CREATE TABLE #tbx_fs_result", text[a:b])
        self.assertNotIn("CREATE OR ALTER PROCEDURE [toolbelt_filesystem].[USP_ReadTextFileChunk]", text[a:b])
        line, _ = skills._procedure_help_return(text, source)
        self.assertTrue(a < line < b)
        self.assertLess(line, text.index("CREATE TABLE #tbx_fs_result", a))

    def test_missing_help_parameters_and_guards_preserve_both_original_helpers(self):
        selected = [next(s for s in prototypes() if s.metadata["object_name"] == name)
                    for name in ("USP_InternalEmitHelp", "USP_InternalRouteResult")]
        path = selected[0].metadata["source_paths"][0]
        current = (ROOT / path).read_text(encoding="utf-8-sig")
        # Both identical parameter fragments coexist; removal must be scoped by
        # declaration, never replace the first matching neighbor's parameter.
        original = skills.strip_missing_help_projection(ROOT, path, current)
        # Regenerate only these two helpers. Other grouped definitions retain
        # their own independently projected comments throughout this test.
        for skill in selected:
            original = original.replace(skills.render_ddl_comment(skill), "", 1)
        for order in (selected, list(reversed(selected))):
            result = original
            for skill in order:
                result = skills.project_procedure_ddl(skills.project_missing_procedure_help(result, skill), skill)
                self.assertEqual(skills.project_missing_procedure_help(result, skill), result)
            self.assertEqual(result, current)
        for skill in selected:
            a, b = skills._procedure_region(current, skill)
            parameter, branch = skills.render_missing_help_parts(skill)
            self.assertEqual(current[a:b].count(parameter), 1)
            self.assertEqual(current[a:b].count(branch), 1)
            self.assertIn("IF @Hilfe = 1", branch)
            self.assertIn("RETURN 0;", branch)
            self.assertNotRegex(re.sub(r"N'(?:[^']|'')*'", "''", branch), r"(?i)\bFROM\b|\bEXEC\b|\bINSERT\b")
        self.assertIn("@ObjectName sysname\n", original)
        self.assertNotIn(skills.EARLY_BEGIN, original)

    def test_missing_help_adapter_rejects_changed_guard_or_unsupported_output_initialization(self):
        skill = next(s for s in prototypes() if s.metadata["object_name"] == "USP_InternalRouteResult")
        path = skill.metadata["source_paths"][0]
        text = (ROOT / path).read_text(encoding="utf-8-sig")
        a, b = skills._procedure_region(text, skill)
        changed = text[:a] + text[a:b].replace("IF @Hilfe = 1", "IF @Hilfe = 0", 1) + text[b:]
        with self.assertRaisesRegex(ValueError, "kanonisch"):
            skills.strip_missing_help_projection(ROOT, path, changed)
        original = skills.strip_ddl_projection(ROOT, path, skills.strip_missing_help_projection(ROOT, path, text))
        with self.assertRaisesRegex(ValueError, "ungeklammerte"):
            skills.project_missing_procedure_help(original.replace("@ResultTable sysname = NULL", "(@ResultTable sysname = NULL", 1), skill)
        metadata = deepcopy(skill.metadata)
        metadata["parameters"][0]["is_output"] = True
        altered_markdown = skill.markdown.replace('"is_output": false', '"is_output": true', 1)
        with self.assertRaisesRegex(ValueError, "OUTPUT"):
            skills.render_missing_help_parts(skills.Skill(metadata, altered_markdown))

    def test_multiple_functions_keep_separate_skills_and_generation_order(self):
        current = [s for s in prototypes() if s.metadata["object_name"] in
                   ("TVF_GenerateSeriesBigInt", "TVF_GenerateSeriesBigIntStatus")]
        self.assertEqual(len(current), 2)
        path = current[0].metadata["source_paths"][0]
        text = (ROOT / path).read_text(encoding="utf-8-sig")
        self.assertEqual({s.identity for s in skills.read_ddl_comments(text)}, {s.identity for s in current})
        original = skills.strip_ddl_projection(ROOT, path, text)
        outputs = []
        for order in (current, list(reversed(current))):
            result = original
            for skill in order:
                result = skills.project_function_ddl(result, skill)
                ts, _, i, end = skills._function_declaration(result, skill)
                position = result.index(skills.render_ddl_comment(skill))
                self.assertGreater(position, ts[i][1])
                self.assertLess(position, ts[end][1] if end < len(ts) else len(result))
            outputs.append(result)
        self.assertEqual(outputs, [text, text])
        with self.assertRaisesRegex(ValueError, "Genau ein"):
            skills.read_ddl_comment(text)
        with self.assertRaisesRegex(ValueError, "Doppelte|nicht eindeutig"):
            skills.strip_ddl_projection(ROOT, path, text + skills.render_ddl_comment(current[0]))
        block = skills.render_ddl_comment(current[0])
        relocated = text.replace(block, "", 1) + block
        with self.assertRaisesRegex(ValueError, "außerhalb"):
            skills.strip_ddl_projection(ROOT, path, relocated)

    def test_marker_lines_inside_sql_literals_are_not_ddl_comments(self):
        sample = prototypes()[0]
        literal = "SELECT N'\n" + skills.DDL_BEGIN + "\nnot frontmatter\n" + skills.DDL_END + "\n';\n"
        self.assertEqual(skills.read_ddl_comments(literal), [])
        text = skills.render_ddl_comment(sample) + literal
        self.assertEqual([s.markdown for s in skills.read_ddl_comments(text)], [sample.markdown])
        with self.assertRaisesRegex(ValueError, "markierungen"):
            skills.read_ddl_comments(skills.DDL_END + "\n")

    def test_view_and_table_comments_preserve_definitions_and_creation_guards(self):
        for name in ("WorkType", "VW_WorkTypes"):
            source = next(s for s in prototypes() if s.metadata["object_name"] == name)
            path = source.metadata["source_paths"][0]
            current = (ROOT / path).read_text(encoding="utf-8-sig")
            original = skills.strip_ddl_projection(ROOT, path, current)
            self.assertEqual(skills.project_relation_ddl(original, source), current)
            self.assertEqual(skills.project_relation_ddl(current, source), current)
            self.assertEqual(skills.read_ddl_comment(current).markdown, source.markdown)
            block = skills.render_ddl_comment(source)
            relocated = current.replace(block, "", 1) + block
            with self.assertRaisesRegex(ValueError, "außerhalb"):
                skills.strip_ddl_projection(ROOT, path, relocated)
            if name == "WorkType":
                self.assertTrue(original.startswith("SET ANSI_NULLS ON;"))
                self.assertIn("IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL", original)
                self.assertIn("CREATE NONCLUSTERED INDEX", original)

    def test_table_and_view_adapter_handles_a_shared_file_without_wrong_identity(self):
        table = next(s for s in prototypes() if s.metadata["object_name"] == "WorkType")
        view = next(s for s in prototypes() if s.metadata["object_name"] == "VW_WorkTypes")
        text = "CREATE TABLE toolbelt_core.WorkType\n(\n WorkTypeId bigint NOT NULL\n);\nGO\n"
        text += "CREATE OR ALTER VIEW toolbelt_core.VW_WorkTypes\nAS\nSELECT WorkTypeId FROM toolbelt_core.WorkType;\nGO\n"
        expected = skills.project_relation_ddl(skills.project_relation_ddl(text, table), view)
        self.assertEqual(skills.project_relation_ddl(skills.project_relation_ddl(text, view), table), expected)
        self.assertEqual(len(skills.read_ddl_comments(expected)), 2)
        for s in (table, view):
            expected = expected.replace(skills.render_ddl_comment(s), "", 1)
        self.assertEqual(expected, text)
        with self.assertRaisesRegex(ValueError, "Deklaration"):
            skills.project_relation_ddl(text.replace("CREATE TABLE toolbelt_core.WorkType", "CREATE TABLE toolbelt_core.Another"), table)

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
            if m["object_type"] in ("TABLE", "ASSEMBLY"):
                self.assertEqual(m["parameters"], [])
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

    def test_all_declared_assemblies_have_schemafree_reviewed_contracts(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["object_type"] == "ASSEMBLY"}
        current = {s.identity: s for s in prototypes() if s.metadata["object_type"] == "ASSEMBLY"}
        self.assertTrue(expected)
        self.assertEqual(set(current), set(expected))
        for key, skill in current.items():
            self.assertEqual(key[1], "")
            self.assertTrue(skill.metadata["is_internal"])
            self.assertEqual(skills.source_file(ROOT, key[1], key[2]), skill.source)
            for field, value in expected[key].items():
                self.assertEqual(skill.metadata[field], value)
        sample = next(iter(current.values()))
        metadata = deepcopy(sample.metadata)
        metadata["schema_name"] = "invented_schema"
        with self.assertRaisesRegex(ValueError, "schemafrei"):
            skills.validate(skills.Skill(metadata, sample.markdown))

    def test_semantic_version_module_has_complete_reviewed_skills_and_status_contract(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.validation.semantic-version"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 5)
        for skill in records:
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            self.assertEqual(skills.project_function_ddl(text, skill), text)
            self.assertIn("8000", skill.markdown)
            self.assertTrue(all(p["argument_required"] and p["nullable"]
                                and p["sql_default"] is None for p in skill.metadata["parameters"]))
        parser = next(s for s in records if s.metadata["object_name"] == "TVF_ParseSemanticVersion")
        path = parser.metadata["source_paths"][0]
        code = skills.strip_ddl_projection(ROOT, path, (ROOT / path).read_text(encoding="utf-8-sig"))
        statuses = set(re.findall(r"SET @Code = '([A-Z_]+)'", code)) | {"VALID"}
        documented = set(re.findall(r"\b([A-Z]+(?:_[A-Z]+)+|VALID)\s*\(", parser.markdown))
        self.assertEqual(statuses, documented)

    def test_core_message_skills_return_before_business_validation_and_output(self):
        for name, parameter in (("USP_WriteConsoleMessage", "@message"),
                                ("USP_CaptureErrorEnvelope", "@errornumber")):
            skill = skills.read(ROOT / "Metadata/UsageSkills/toolbelt_core" / (name + ".md"))
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            self.assertEqual(skills.project_procedure_help(text, skill), text)
            self.assertEqual(skills.project_procedure_ddl(text, skill), text)
            ret, indent = skills._procedure_help_return(text, skill)
            self.assertTrue(text[:ret].endswith(skills.render_help_projection(skill, indent)))
            tokens = skills._ddl_tokens(text)
            words = [t[0].casefold() for t in tokens]
            business = next(tokens[i][1] for i in range(len(words) - 2)
                            if words[i:i + 3] == ["if", parameter, "is"])
            self.assertLess(ret, business)

    def test_distance_and_pair_modules_have_complete_source_bound_contracts(self):
        inventory = skills.inventory(ROOT)
        for module, count in (("toolbelt.string.edit-distance", 7), ("toolbelt.string.text-pairs", 1)):
            expected = {key: value for key, value in inventory.items() if value["module_id"] == module}
            records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
            self.assertEqual(skills.validate_coverage(records, expected), count)
            for skill in records:
                if skill.metadata["object_type"] == "ASSEMBLY":
                    continue
                path = skill.metadata["source_paths"][0]
                text = (ROOT / path).read_text(encoding="utf-8-sig")
                if skill.metadata["object_type"] == "USP":
                    self.assertEqual(skills.project_procedure_help(text, skill), text)
                    ret, _ = skills._procedure_help_return(text, skill)
                    tokens = skills._ddl_tokens(text)
                    words = [t[0].casefold() for t in tokens]
                    state_guard = next(tokens[i][1] for i in range(len(words) - 3)
                                       if words[i:i + 3] == ["if", "xact_state", "("])
                    self.assertLess(ret, state_guard)
                else:
                    self.assertEqual(skills.project_function_ddl(text, skill), text)
                    self.assertTrue(all(p["argument_required"] for p in skill.metadata["parameters"]))
                    self.assertIn("ErrorCode", skill.markdown)
                    profile = next(p for p in skill.metadata["parameters"] if p["name"] == "@Profile")
                    for limit in ("2048", "1024", "65536", "32768", "1048576", "16777216"):
                        self.assertIn(limit, profile["description"])

    def test_execution_context_help_preserves_output_and_required_arguments(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.core.execution-context"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 5)
        for skill in records:
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            if skill.metadata["object_type"] != "USP":
                self.assertEqual(skill.metadata["parameters"], [])
                self.assertEqual(skills.project_function_ddl(text, skill), text)
                continue
            self.assertEqual(skills.project_procedure_help(text, skill), text)
            ret, _ = skills._procedure_help_return(text, skill)
            tokens = skills._ddl_tokens(text)
            first_context = next(a for token, a, b in tokens if token.casefold() == "session_context")
            self.assertLess(ret, first_context)
            if skill.metadata["object_name"] == "USP_BeginExecution":
                parameter = skill.metadata["parameters"][0]
                self.assertTrue(parameter["is_output"])
                self.assertEqual(parameter["sql_default"], "NULL")
                before_help_return = [token.casefold() for token, a, b in tokens if a < ret]
                self.assertFalse(any(before_help_return[i:i + 2] == ["set", "@executionid"]
                                     for i in range(len(before_help_return) - 1)))
            else:
                parameter = skill.metadata["parameters"][0]
                self.assertEqual(parameter["name"], "@ExpectedExecutionId")
                self.assertTrue(parameter["argument_required"])
                self.assertIsNone(parameter["sql_default"])

    def test_phonetic_module_has_complete_contracts_and_preserves_transport_types(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.string.phonetic"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 5)
        for skill in records:
            if skill.metadata["object_type"] == "ASSEMBLY":
                continue
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            self.assertEqual(skills.project_function_ddl(text, skill), text)
            self.assertEqual(len(skill.metadata["parameters"]), 1)
            parameter = skill.metadata["parameters"][0]
            self.assertEqual(parameter["name"], "@Text")
            self.assertEqual(parameter["sql_type"], "nvarchar(max)")
            self.assertTrue(parameter["argument_required"] and parameter["nullable"])
            self.assertIsNone(parameter["sql_default"])
            for limit in ("4096", "8192", "16384", "32768"):
                self.assertIn(limit, skill.markdown)
            if skill.metadata["object_type"] == "CLR_TVF":
                self.assertTrue(skill.metadata["is_internal"])
                self.assertIn("nvarchar(max)", skill.markdown.split("## Ergebnisse", 1)[1])
            else:
                self.assertFalse(skill.metadata["is_internal"])
                self.assertIn("varchar(max)", skill.markdown.split("## Ergebnisse", 1)[1])


    def test_csv_contracts_cover_complete_module_and_distinct_error_transports(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.file.csv-memory"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 6)
        for skill in records:
            kind = skill.metadata["object_type"]
            if kind == "ASSEMBLY":
                continue
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            if kind == "USP":
                self.assertEqual(skills.project_procedure_help(text, skill), text)
                self.assertEqual(skills.project_procedure_ddl(text, skill), text)
                ret, _ = skills._procedure_help_return(text, skill)
                words = [t[0].casefold() for t in skills._ddl_tokens(text)]
                tokens = skills._ddl_tokens(text)
                guard = next(tokens[i][1] for i in range(len(words) - 2)
                             if words[i:i + 3] == ["if", "xact_state", "("])
                self.assertLess(ret, guard)
            else:
                self.assertTrue(skill.metadata["is_internal"])
                self.assertEqual(skills.project_function_ddl(text, skill), text)
                self.assertTrue(all(p["argument_required"] and p["sql_default"] is None
                                    for p in skill.metadata["parameters"]))
            results = skill.markdown.split("## Ergebnisse", 1)[1].split("## Aufrufbeispiele", 1)[0]
            if skill.metadata["object_name"] == "SVF_InternalMeasureCsvCell":
                self.assertIn("-55300/-55303/-55307", results)
                self.assertIn("bigint", results)
            elif skill.metadata["object_name"] == "SVF_InternalQuoteCsvCell":
                self.assertIn("Keine Statusspalte", results)
                self.assertIn("CSV_QUOTE_PREVALIDATION_REQUIRED", skill.markdown)
            elif skill.metadata["object_name"] == "TVF_InternalParseCsv":
                self.assertIn("RowKind nvarchar(6)", results)
                self.assertIn("Sentinelzeile", results)


    def test_split_contracts_cover_complete_module_and_exact_scanner_statuses(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.string.split-advanced"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 3)
        for skill in records:
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            if skill.metadata["object_type"] == "USP":
                self.assertEqual(skills.project_procedure_help(text, skill), text)
                self.assertEqual(skills.project_procedure_ddl(text, skill), text)
                ret, _ = skills._procedure_help_return(text, skill)
                tokens = skills._ddl_tokens(text)
                words = [t[0].casefold() for t in tokens]
                call = next(tokens[i][1] for i in range(len(words) - 2)
                            if words[i:i + 2] == ["from", "toolbelt_string"])
                self.assertLess(ret, call)
            else:
                self.assertEqual(skills.project_function_ddl(text, skill), text)
                self.assertTrue(all(p["argument_required"] for p in skill.metadata["parameters"]))
            if skill.metadata["object_name"] == "TVF_SplitAdvanced":
                business = skills.strip_ddl_projection(ROOT, path, text)
                codes = set(re.findall(r"SET @Error = '([A-Z_]+)'", business))
                self.assertEqual(len(codes), 10)
                for code in codes:
                    self.assertIn(code, skill.markdown)
                for limit in ("65536", "16384", "16", "64"):
                    self.assertIn(limit, skill.markdown)


    def test_cancellation_contracts_cover_schema_quotas_and_early_help(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.core.execution-cancel"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 4)
        for skill in records:
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            kind = skill.metadata["object_type"]
            if kind == "TABLE":
                self.assertEqual(skills.project_relation_ddl(text, skill), text)
                for field in ("RequestedByPrincipalId", "RequestedByPrincipalSid",
                              "RequestedByPrincipalCreatedAt", "RowVersion"):
                    self.assertIn(field, skill.markdown)
            elif kind == "USP":
                self.assertEqual(skills.project_procedure_help(text, skill), text)
                self.assertEqual(skills.project_procedure_ddl(text, skill), text)
                ret, _ = skills._procedure_help_return(text, skill)
                tokens = skills._ddl_tokens(text)
                guard = next(t[1] for t in tokens if t[0].casefold() == "@@trancount")
                self.assertLess(ret, guard)
                for code in range(52600, 52607):
                    self.assertIn(str(code), skill.markdown)
                for quota in ("100000", "10000"):
                    self.assertIn(quota, skill.markdown)
            else:
                self.assertEqual(skills.project_function_ddl(text, skill), text)
                self.assertTrue(skill.metadata["parameters"][0]["nullable"])
                self.assertTrue(skill.metadata["parameters"][0]["argument_required"])


    def test_event_relations_describe_full_unfiltered_schema(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.core.event-log"
                    and key[2] in ("EventLog", "VW_Events")}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 2)
        for skill in records:
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            self.assertEqual(skills.project_relation_ddl(text, skill), text)
            self.assertEqual(skill.metadata["parameters"], [])
            self.assertIn("kein technisch erzwungenes SQL-DML-Verbot", skill.markdown)
            self.assertIn("24 Spalten", skill.markdown)
            for column in ("RecordedAtUtc", "DataJson", "CallerTransactionCount", "ErrorLine"):
                self.assertIn("`" + column + "`", skill.markdown)
            if skill.metadata["object_type"] == "TABLE":
                self.assertTrue(skill.metadata["is_internal"])
                self.assertIn("toolbelt_core.VW_Events", skill.metadata["public_entrypoints"])


    def test_event_procedure_skills_complete_module_and_preserve_early_outputs(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.core.event-log"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 6)
        for skill in records:
            if skill.metadata["object_type"] != "USP":
                continue
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            self.assertEqual(skills.project_procedure_help(text, skill), text)
            self.assertEqual(skills.project_procedure_ddl(text, skill), text)
            ret, _ = skills._procedure_help_return(text, skill)
            tokens = skills._ddl_tokens(text)
            words = [t[0].casefold() for t in tokens]
            first_throw = next(t[1] for t in tokens if t[0].casefold() == "throw")
            self.assertLess(ret, first_throw)
            if skill.metadata["object_name"].startswith("USP_Delete"):
                initial = next(tokens[i][1] for i in range(len(words) - 3)
                               if words[i:i + 4] == ["set", "@deletedrows", "=", "0"])
                self.assertLess(initial, ret)
                output = next(p for p in skill.metadata["parameters"] if p["name"] == "@DeletedRows")
                self.assertTrue(output["is_output"])
                self.assertIn("zurückgerollte", output["description"])
                self.assertIn("EINER Transaktion", skill.markdown)
            elif skill.metadata["object_name"] == "USP_WriteEvent":
                self.assertIn("65536", skill.markdown)
                self.assertIn("131072", skill.markdown)
                self.assertIn("1048576", skill.markdown)
                self.assertIn("Duplikate", skill.markdown)
            else:
                self.assertTrue(skill.metadata["is_internal"])
                self.assertEqual(skill.metadata["public_entrypoints"], ["toolbelt_core.USP_WriteEvent"])
                self.assertIn("@EventName=''contoso.helpexample''", text)
                self.assertNotIn("@EventName=''Contoso.HelpExample''", text)


    def test_worktype_policy_contracts_distinguish_token_policy_and_sql_permissions(self):
        names = {"WorkTypePermission", "TVF_WorkTypeAuthorization", "USP_SetWorkTypePermission"}
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.core.work-type" and key[2] in names}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 3)
        for skill in records:
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            kind = skill.metadata["object_type"]
            if kind == "TABLE":
                self.assertEqual(skills.project_relation_ddl(text, skill), text)
                self.assertIn("ON DELETE CASCADE", skill.markdown)
                self.assertIn("kein eigener rowversion-Datentyp", skill.markdown)
            elif kind == "USP":
                self.assertEqual(skills.project_procedure_help(text, skill), text)
                self.assertEqual(skills.project_procedure_ddl(text, skill), text)
                ret, _ = skills._procedure_help_return(text, skill)
                first_control = next(t[1] for t in skills._ddl_tokens(text)
                                     if t[0].casefold() == "has_perms_by_name")
                self.assertLess(ret, first_control)
                for code in range(51590, 51595):
                    self.assertIn(str(code), skill.markdown)
            else:
                self.assertEqual(skills.project_function_ddl(text, skill), text)
                self.assertTrue(skill.metadata["is_internal"])
                self.assertTrue(all(p["argument_required"] and p["nullable"]
                                    and p["sql_default"] is None for p in skill.metadata["parameters"]))
                self.assertIn("weder WorkType.IsEnabled", skill.markdown)
                self.assertIn("Auch dbo erhält keinen impliziten Bypass", skill.markdown)
            for identity in ("DBprincipal-ID/SID/create_date", "RowVersion", "sys.user_token"):
                self.assertIn(identity, skill.markdown)


    def test_worktype_lifecycle_contracts_keep_actual_routing_commit_order(self):
        for name in ("USP_DisableWorkType", "USP_RemoveWorkType", "USP_ResolveWorkType"):
            skill = skills.read(skills.source_file(ROOT, "toolbelt_core", name))
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            self.assertEqual(skills.project_procedure_help(text, skill), text)
            self.assertEqual(skills.project_procedure_ddl(text, skill), text)
            ret, _ = skills._procedure_help_return(text, skill)
            tokens = skills._ddl_tokens(text)
            first_throw = next(t[1] for t in tokens if t[0].casefold() == "throw")
            self.assertLess(ret, first_throw)
            fields = re.findall(r"^\| `\w+` \| `.+(?:NOT NULL|NULL)` \|$", skill.markdown, re.M)
            self.assertEqual(len(fields), 20)
            helper = next(t[1] for t in tokens if t[0].casefold() == "usp_prepareresulttable")
            if name == "USP_DisableWorkType":
                commit = next(t[1] for t in tokens if t[0].casefold() == "commit")
                self.assertLess(commit, helper)
                self.assertIn("VOR ResultTable-Helperprüfung", skill.markdown)
            elif name == "USP_RemoveWorkType":
                delete = next(t[1] for t in tokens if t[0].casefold() == "delete")
                commit = next(t[1] for t in tokens if t[0].casefold() == "commit")
                self.assertLess(helper, delete)
                self.assertLess(delete, commit)
                self.assertIn("kaskadiert WorkTypePermission", skill.markdown)
            else:
                self.assertIn("51595", skill.markdown)
                self.assertIn("51596", skill.markdown)
                self.assertIn("51597", skill.markdown)
                self.assertIn("kein Handleraufruf", skill.markdown)


    def test_worktype_module_has_complete_source_contracts_including_registration(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.core.work-type"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 9)
        skill = next(s for s in records if s.metadata["object_name"] == "USP_RegisterWorkType")
        path = skill.metadata["source_paths"][0]
        text = (ROOT / path).read_text(encoding="utf-8-sig")
        self.assertEqual(skills.project_procedure_help(text, skill), text)
        self.assertEqual(skills.project_procedure_ddl(text, skill), text)
        ret, _ = skills._procedure_help_return(text, skill)
        tokens = skills._ddl_tokens(text)
        first_throw = next(t[1] for t in tokens if t[0].casefold() == "throw")
        self.assertLess(ret, first_throw)
        commit = next(t[1] for t in tokens if t[0].casefold() == "commit")
        helper = next(t[1] for t in tokens if t[0].casefold() == "usp_prepareresulttable")
        self.assertLess(commit, helper)
        for code in list(range(51500, 51513)) + [51518]:
            self.assertIn(str(code), skill.markdown)
        self.assertIn("NICHT die passende Handler-Parametersignatur", skill.markdown)
        self.assertIn("keine neuen Policyzeilen", skill.markdown)


    def test_second_session_contracts_cover_module_and_preserve_dispatch_help_outputs(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.core.second-session"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 6)
        for skill in records:
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            kind = skill.metadata["object_type"]
            if kind in ("TABLE", "VIEW"):
                self.assertEqual(skills.project_relation_ddl(text, skill), text)
                continue
            self.assertEqual(skills.project_procedure_help(text, skill), text)
            self.assertEqual(skills.project_procedure_ddl(text, skill), text)
            ret, _ = skills._procedure_help_return(text, skill)
            name = skill.metadata["object_name"]
            if name == "USP_DispatchWorkType":
                tokens = skills._ddl_tokens(text)
                words = [t[0].casefold() for t in tokens]
                initial = next(tokens[i][1] for i in range(len(words) - 3)
                               if words[i:i + 4] == ["set", "@remotesessionid", "=", "@@spid"])
                self.assertLess(ret, initial)
                outputs = [p for p in skill.metadata["parameters"] if p["is_output"]]
                self.assertEqual(len(outputs), 4)
                self.assertTrue(all("unverändert" in p["description"] for p in outputs))
                self.assertIn("NICHT automatisch", skill.markdown)
                self.assertIn("exakt null SQL-Parameter", skill.markdown)
            elif name == "USP_ExecuteWorkTypeInNewSession":
                self.assertIn("Dispatcher-/ProviderReturnCode", skill.markdown)
                self.assertIn("Handlercode ungleich0", skill.markdown)
                self.assertIn("Remote-Commit liegt vor", skill.markdown)
                fields = re.findall(r"^\| `\w+` \| `.+(?:NOT NULL|NULL)` \|$", skill.markdown, re.M)
                self.assertEqual(len(fields), 16)
            elif name == "USP_ConfigureSecondSessionLoopback":
                self.assertIn("kein kryptografischer Nachweis", skill.markdown)
                fields = re.findall(r"^\| `\w+` \| `.+(?:NOT NULL|NULL)` \|$", skill.markdown, re.M)
                self.assertEqual(len(fields), 9)


    def test_file_content_contracts_cover_postread_quotas_and_failure_row_effects(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.file.content"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 3)
        for skill in records:
            path = skill.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            if skill.metadata["object_type"] == "TABLE":
                self.assertEqual(skills.project_relation_ddl(text, skill), text)
                self.assertFalse(skill.metadata["is_internal"])
                self.assertEqual(skill.metadata["parameters"], [])
                self.assertIn("Keine eigene CHECK-Constraint", skill.markdown)
                continue
            self.assertEqual(skills.project_procedure_help(text, skill), text)
            self.assertEqual(skills.project_procedure_ddl(text, skill), text)
            ret, _ = skills._procedure_help_return(text, skill)
            body = skills.strip_ddl_projection(ROOT, path, skills.strip_help_projection(ROOT, path, text))
            tokens = skills._ddl_tokens(text)
            words = [t[0].casefold() for t in tokens]
            first_temp = next(tokens[i][1] for i in range(len(words) - 1)
                              if words[i:i + 2] == ["create", "table"])
            self.assertLess(ret, first_temp)
            self.assertEqual(body.count("FROM OPENROWSET(BULK "), 1)
            self.assertIn("SINGLE_BLOB", skill.markdown)
            self.assertIn("128", skill.markdown)
            self.assertIn("IsValid=0-Statuszeile", skill.markdown)
            self.assertIn("keine handlegebundene", skill.markdown.lower())
            if skill.metadata["object_name"] == "USP_LoadTextFile":
                for value in ("UTF-8", "UTF-16-LE", "UTF-16-BE", "UTF-32", "Windows-1252"):
                    self.assertIn(value, skill.markdown)
                self.assertIn("keine vollständige Surrogatvalidierung", skill.markdown)


    def test_json_pointer_skill_covers_source_statuses_and_exact_key_comparison(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.json.pointer"}
        skill = skills.read(skills.source_file(ROOT, "toolbelt_json", "TVF_ResolveJsonPointer"))
        self.assertEqual(skills.validate_coverage([skill], expected), 1)
        path = skill.metadata["source_paths"][0]
        text = (ROOT / path).read_text(encoding="utf-8-sig")
        self.assertEqual(skills.project_function_ddl(text, skill), text)
        body = skills.strip_ddl_projection(ROOT, path, text)
        codes = set(re.findall(r"VALUES\('INVALID',NULL,NULL,'([A-Z_]+)'\)", body))
        self.assertEqual(len(codes), 10)
        for code in codes:
            self.assertIn(code, skill.markdown)
        self.assertIn("DATALENGTH([key])=DATALENGTH(@Token)", body)
        self.assertIn("BIN2 PLUS DATALENGTH", skill.markdown)
        for limit in ("16777216", "67108864", "4000", "128"):
            self.assertIn(limit, skill.markdown)
        self.assertTrue(all(p["argument_required"] for p in skill.metadata["parameters"]))
        self.assertEqual([p["sql_default"] for p in skill.metadata["parameters"]],
                         [None, None, "16777216", "128"])


    def test_xlsx_skills_preserve_null_priority_raw_contracts_and_type_display_limits(self):
        expected={k:v for k,v in skills.inventory(ROOT).items() if v['module_id']=='toolbelt.file.xlsx-memory'}
        self.assertEqual(len(expected),10)
        records={k[2]:skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected}
        originals={}
        for name,s in records.items():
            if s.metadata['object_type']=='ASSEMBLY':continue
            path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.read_ddl_comment(text).markdown,s.markdown)
            if name.startswith('USP_'):
                self.assertEqual(skills.project_procedure_ddl(text,s),text)
                self.assertEqual(skills.project_procedure_help(text,s),text)
                clean=skills.strip_help_projection(ROOT,path,text)
            else:
                self.assertEqual(skills.project_function_ddl(text,s),text);clean=text
            originals[name]=skills.strip_ddl_projection(ROOT,path,clean)
            if name.startswith('TVF_Internal'):
                self.assertTrue(s.metadata['public_entrypoints'])
                self.assertTrue(all(p['argument_required'] and p['sql_default'] is None for p in s.metadata['parameters']))
            self.assertIn('keine neue native',s.markdown)
        for name in ('USP_ListXlsxWorksheets','USP_ReadXlsxWorksheetCells'):
            text=originals[name]
            self.assertLess(text.index('IF @XlsxBinary IS NULL'),text.index('THROW 51520'))
            self.assertLess(text.index('IF @XlsxBinary IS NULL'),text.index('EXEC toolbelt_file.USP_InternalXlsxRead'))
            self.assertNotIn('CREATE TABLE #',text)
            self.assertIn('Tablevariablen',records[name].markdown)
        entry=(ROOT/'Modules/toolbelt.file.xlsx-memory/Clr/XlsxEntryPoints.cs').read_text(encoding='utf-8-sig')
        self.assertLess(entry.index('var limits = Limits('),entry.index('if (input.IsNull)'))
        self.assertLess(entry.index('if (cells &&'),entry.index('if (input.IsNull)'))
        self.assertLess(entry.index('input.Length >'),entry.index('input.Value,'))
        self.assertIn('new Row {Error=51520',entry)
        self.assertIn('ErrorNumberNULL',records['TVF_InternalXlsxSheets'].markdown)
        core=originals['USP_InternalXlsxRead']
        self.assertLess(core.index('CREATE TABLE #'),core.index('IF @XlsxBinary IS NULL'))
        self.assertLess(core.index('IF @ResultTable IS NULL\n    BEGIN'),core.index('DECLARE @SheetsDependencyId'))
        self.assertLess(core.index('IF @Hilfe=1'),core.index('IF @ReadCells IS NULL'))
        self.assertIn('sys.parameters',records['USP_InternalXlsxRead'].markdown)
        self.assertIn('keine doppelten Koordinaten',records['USP_ReadXlsxWorksheetCells'].markdown)
        self.assertIn('kein Nachweis aller Worksheet-/SST-Payloads',records['USP_ListXlsxWorksheets'].markdown)
        self.assertIn('Status3',records['TVF_InterpretXlsxCell'].markdown)
        self.assertIn('262144',records['TVF_InterpretXlsxCell'].markdown)
        self.assertIn('[60,61)',records['TVF_InterpretXlsxCell'].markdown)
        self.assertIn('half-away-from-zero',records['TVF_FormatXlsxCell'].markdown)
        self.assertIn('Anzeige aber Unsupported6',records['TVF_FormatXlsxCell'].markdown)
        self.assertIn('en-US,de-DE,tr-TR',records['TVF_FormatXlsxCell'].markdown)
        for name in ('TVF_InterpretXlsxCell','TVF_FormatXlsxCell'):
            self.assertTrue(all(p['sql_default']=='NULL' for p in records[name].metadata['parameters']))
            self.assertIn('ISNULL(',originals[name])
            self.assertIn('11)',originals[name])

    def test_zip_skills_distinguish_status_conventions_metadata_crc_and_file_publication(self):
        expected={k:v for k,v in skills.inventory(ROOT).items() if v['module_id'] in ('toolbelt.archive.zip-memory','toolbelt.archive.zip-files')}
        self.assertEqual(len(expected),10)
        records={k[2]:skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected}
        counts={'USP_CreateZipFromEntries':5,'USP_ExtractZipEntryFromBinary':7,'USP_ListZipEntriesFromBinary':13,
                'USP_CreateZipFileFromEntries':4,'USP_ExtractZipEntryToFile':4,'TVF_InternalZipWriterName':3,
                'TVF_InternalZipWriterArchive':3,'TVF_InternalExtractZipEntryClr':9,'TVF_InternalListZipEntriesClr':15}
        originals={}
        for name,count in counts.items():
            s=records[name];path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            if name.startswith('USP_'):
                self.assertEqual(skills.project_procedure_ddl(text,s),text)
                self.assertEqual(skills.project_procedure_help(text,s),text)
                clean=skills.strip_help_projection(ROOT,path,text)
            else:
                self.assertEqual(skills.project_function_ddl(text,s),text)
                self.assertTrue(all(p['argument_required'] and p['sql_default'] is None for p in s.metadata['parameters']))
                self.assertTrue(s.metadata['public_entrypoints']);clean=text
            originals[name]=skills.strip_ddl_projection(ROOT,path,clean)
            result=s.markdown.split('## Ergebnisse\n\n',1)[1].split('\n\n## ',1)[0]
            self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',result,re.M)),count)
            self.assertIn('keine neue native',s.markdown)
        source=(ROOT/'Modules/toolbelt.archive.zip-memory/Clr/ZipEntryProvider.cs').read_text(encoding='utf-8-sig')
        writer=(ROOT/'Modules/toolbelt.archive.zip-memory/Clr/ZipWriter.cs').read_text(encoding='utf-8-sig')
        encrypted=source.index('if (encrypted)')
        self.assertLess(encrypted,source.index('if (entry.CompressionMethod != 0',encrypted))
        self.assertIn('actualCrc32 != entry.Crc32',source)
        self.assertIn('ValidateLocalHeader(reader, entry);',source)
        self.assertIn('return Array.Empty<ProviderListResult>();',source)
        self.assertIn('Writer-Erfolg0',records['TVF_InternalZipWriterArchive'].markdown)
        self.assertIn('ErrorNumberNULL',records['TVF_InternalExtractZipEntryClr'].markdown)
        self.assertIn('Keine Dekompression oder Prüfung aller Payload-CRCs',records['USP_ListZipEntriesFromBinary'].markdown)
        self.assertIn('MaxArchiveBytes = 268435456L',source)
        self.assertIn('maxArchive.Value',writer)
        self.assertIn('new UTF8Encoding(false, true)',writer)
        self.assertIn('maxNameUnits.Value > 2048',writer)
        self.assertIn('MaxEntryNameCharacters = 1024',source)
        for name in ('USP_CreateZipFileFromEntries','USP_ExtractZipEntryToFile'):
            sql=originals[name]
            self.assertIn('@@TRANCOUNT<>0 OR XACT_STATE()<>0',sql)
            self.assertLess(sql.index('EXEC toolbelt_filesystem.USP_WriteBinaryFile'),sql.index('            BEGIN TRANSACTION;'))
            self.assertNotIn('EXEC toolbelt_filesystem.USP_DeleteFile',sql)
            self.assertIn('bleibt auch bei späterem SQL-Routingfehler bestehen',records[name].markdown)
        raw=records['TVF_InternalExtractZipEntryClr']
        self.assertFalse(next(p for p in raw.metadata['parameters'] if p['name']=='@FailIfEncrypted')['nullable'])
        self.assertIn('SET @FailIfEncrypted = ISNULL(@FailIfEncrypted, 1)',originals['USP_ExtractZipEntryFromBinary'])
        self.assertNotIn('BEGIN TRANSACTION',originals['USP_ListZipEntriesFromBinary'])
        self.assertNotIn('BEGIN TRANSACTION',originals['USP_ExtractZipEntryFromBinary'])
        self.assertIn('Value.WRITE(@Payload,NULL,0)',originals['USP_CreateZipFromEntries'])

    def test_script_parser_skills_keep_tokenization_errors_ast_and_guard_quotas_distinct(self):
        expected={k:v for k,v in skills.inventory(ROOT).items() if v['module_id']=='toolbelt.tsql.script-parser'}
        self.assertEqual(len(expected),6)
        records={k[2]:skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected}
        names=('TVF_ParseScriptNodes','TVF_ParseScriptNodeProperties','TVF_TokenizeScript','TVF_ParseScriptErrors')
        for name,count,limit in zip(names,(13,4,6,6),(32768,131072,8192,256)):
            s=records[name];path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_function_ddl(text,s),text)
            self.assertNotIn(skills.DDL_BEGIN,skills.strip_ddl_projection(ROOT,path,text))
            self.assertTrue(all(p['argument_required'] and p['nullable'] for p in s.metadata['parameters']))
            self.assertEqual([p['sql_default'] for p in s.metadata['parameters']],[None,'160','1','2097152','100'])
            result=s.markdown.split('## Ergebnisse\n\n',1)[1].split('\n\n## ',1)[0]
            self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',result,re.M)),count)
            for value in (str(limit),'16777216','512','8192','32','16','keine neue native'):
                self.assertIn(value,s.markdown)
        self.assertIn('Keine AST-Syntaxvalidierung',records[names[2]].markdown)
        self.assertIn('Auch Errors kann bei gültigem AST',records[names[3]].markdown)
        source=(ROOT/'Modules/toolbelt.tsql.script-parser/Clr/ScriptParserProvider.cs').read_text(encoding='utf-8-sig')
        self.assertLess(source.index('if (input.IsNull) return rows;'),source.index('int version ='))
        self.assertLess(source.index('checked(input.Length * 2L)'),source.index('input.ToSqlString()'))
        self.assertLess(source.index('if (kind == OutputKind.Tokens)'),source.index('parser.Parse(tokens'))
        self.assertIn('if (fragment != null) Walk(fragment, depth, kind, rows, budget)',source)
        self.assertIn('long next = checked(bytes + 128L)',source)
        self.assertIn('StringComparer.Ordinal.Compare(a.Name, b.Name)',source)
        guard=(ROOT/'Modules/toolbelt.tsql.script-parser/Clr/PreparseGuard.cs').read_text(encoding='utf-8-sig')
        self.assertIn('AtomLimit=512, StructureLimit=32, CommentLimit=16',guard)
        self.assertIn('8192,StructureLimit,CommentLimit,0,0',guard)

    def test_json_constructor_skills_cover_module_grouping_phases_and_separate_aggregate_limits(self):
        expected={k:v for k,v in skills.inventory(ROOT).items() if v['module_id']=='toolbelt.json.constructors'}
        self.assertEqual(len(expected),9)
        records={k[2]:skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected}
        for name,s in records.items():
            kind=s.metadata['object_type']
            if kind=='ASSEMBLY':continue
            path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            projected=skills.project_aggregate_ddl(text,s) if kind=='CLR_AGGREGATE' else skills.project_procedure_ddl(text,s) if kind=='USP' else skills.project_function_ddl(text,s)
            self.assertEqual(projected,text)
            if kind=='USP':
                self.assertEqual(skills.project_procedure_help(text,s),text)
                clean=skills.strip_help_projection(ROOT,path,text)
            else:clean=text
            clean=skills.strip_ddl_projection(ROOT,path,clean)
            self.assertNotIn(skills.DDL_BEGIN,clean)
            self.assertIn('keine neue native',s.markdown)
            if kind in ('CLR_AGGREGATE','CLR_TVF'):
                self.assertTrue(all(p['argument_required'] and p['sql_default'] is None for p in s.metadata['parameters']))
        core=records['USP_JsonConstructInternal'];path=core.metadata['source_paths'][0]
        text=(ROOT/path).read_text(encoding='utf-8-sig')
        clean=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text))
        self.assertLess(skills._procedure_help_return(clean,core)[0],clean.index('THROW 53600'))
        self.assertIn('CONVERT(varbinary(2048),[Key]),DATALENGTH([Key])',clean)
        self.assertIn('IF ISJSON(@Value)<>1',clean)
        self.assertIn('WHILE @CostPass<=1',clean)
        self.assertIn('SAVE TRANSACTION @Savepoint',clean)
        self.assertIn('53611',core.markdown)
        for name in ('AGF_JsonArray','AGF_JsonObject'):
            for limit in ('127','5242880','37748736','100000'):
                self.assertIn(limit,records[name].markdown)
        raw=records['FT_JsonEntryEvaluateInternal']
        self.assertEqual(len(raw.metadata['parameters']),6)
        result=raw.markdown.split('## Ergebnisse\n\n',1)[1].split('\n\n## ',1)[0]
        self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',result,re.M)),8)
        self.assertIn('ADAPTER_CONTRACT',raw.markdown)
        self.assertIn('kein AGF-Depthlimit127',raw.markdown)

    def test_bare_help_return_is_preserved_and_still_must_end_positive_branch(self):
        skill=skills.read(skills.source_file(ROOT,'toolbelt_json','USP_JsonConstructInternal'))
        path=skill.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
        original=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text))
        position,_=skills._procedure_help_return(original,skill)
        self.assertTrue(original[position:].lstrip().startswith('RETURN;'))
        projected=skills.project_procedure_ddl(skills.project_procedure_help(original,skill),skill)
        self.assertEqual(skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,projected)),original)
        for tail in ('RETURN 1;','RETURN; SELECT 1;'):
            bad=original[:position]+original[position:].replace('RETURN;',tail,1)
            with self.assertRaises(ValueError):skills.project_procedure_help(bad,skill)

    def test_guarded_aggregate_ddl_roundtrips_and_does_not_interpret_arbitrary_data(self):
        skill=skills.read(skills.source_file(ROOT,'toolbelt_json','AGF_JsonArray'));path=skill.metadata['source_paths'][0]
        payload=('CREATE AGGREGATE toolbelt_json.AGF_JsonArray\n'
                 '(@Ordinal int,@ValueKind nvarchar(max),@Value nvarchar(max),@Profile tinyint)\n'
                 'RETURNS nvarchar(max)\nEXTERNAL NAME [tlblt_JsonConstructors].[Toolbelt.JsonConstructors.JsonArrayAggregate];')
        def wrap(sql):return "IF OBJECT_ID(N'toolbelt_json.AGF_JsonArray') IS NULL\n EXEC sys.sp_executesql N'"+sql.replace("'","''")+"';\nGO\n"
        original=wrap(payload);projected=skills.project_aggregate_ddl(original,skill)
        self.assertEqual(skills.project_aggregate_ddl(projected,skill),projected)
        self.assertEqual(skills.read_ddl_comment(projected).markdown,skill.markdown)
        self.assertEqual(skills.strip_ddl_projection(ROOT,path,projected),original)
        data="SELECT N'"+skills._dynamic_clr_slots(projected,aggregate=True)[0][3].replace("'","''")+"';"
        self.assertEqual(skills.read_ddl_comments(data),[])
        self.assertEqual(skills.strip_ddl_projection(ROOT,path,data),data)
        for bad in (original.replace("OBJECT_ID(N'toolbelt_json.","OBJECT_ID(N'Contoso."),
                    original.replace("';\nGO","' + N'';\nGO"),original+original,original+'\n'+payload,
                    original.split('\n',1)[1],wrap(payload.replace('EXTERNAL NAME','; SELECT 1; EXTERNAL NAME'))):
            with self.assertRaises(ValueError):skills.project_aggregate_ddl(bad,skill)
        moved=wrap(payload+'\n'+skills.render_ddl_comment(skill))
        with self.assertRaises(ValueError):skills.project_aggregate_ddl(moved,skill)
        altered=projected.replace('[Toolbelt.JsonConstructors.JsonArrayAggregate]','[Contoso.Changed]')
        self.assertNotEqual(skills.strip_ddl_projection(ROOT,path,altered),original)
        with self.assertRaises(ValueError):skills.project_aggregate_ddl(projected.replace('5242880','5242881',1),skill)

    def test_pseudonymization_module_skills_cover_null_priority_hash_domains_and_lookup_boundary(self):
        expected={k:v for k,v in skills.inventory(ROOT).items() if v['module_id']=='toolbelt.pseudonymization.deterministic'}
        self.assertEqual(len(expected),8)
        records={k[2]:skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected}
        originals={}
        for name,s in records.items():
            path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_procedure_ddl(text,s) if name.startswith('USP_') else skills.project_function_ddl(text,s),text)
            if name.startswith('USP_'):
                self.assertEqual(skills.project_procedure_help(text,s),text)
                clean=skills.strip_help_projection(ROOT,path,text)
            else:clean=text
            originals[name]=skills.strip_ddl_projection(ROOT,path,clean)
            result=s.markdown.split('## Ergebnisse\n\n',1)[1].split('\n\n## ',1)[0]
            count=3 if name.startswith('USP_') else 1 if name.endswith('IntegerBytes') else 2
            self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',result,re.M)),count)
            self.assertIn('keine neue native',s.markdown)
            if s.metadata['is_internal']:self.assertTrue(s.metadata['public_entrypoints'])
        core=originals['TVF_DeterministicRangeCore']
        self.assertIn('18446744073709551616',core)
        self.assertIn('ORDER BY counter.Attempt',core)
        self.assertLess(core.index('WHEN @Key IS NULL THEN 0'),core.index('WHEN @MappingVersion IS NULL'))
        self.assertIn('0x54425844524E4731, 0',originals['TVF_DeterministicRange'])
        self.assertIn('DATEADD(day',originals['TVF_DeterministicDateShift'])
        translate=originals['TVF_DeterministicTranslate']
        self.assertIn('DATALENGTH(@Profile) = 16',translate)
        self.assertIn('validation.CharacterCount <> validation.DistinctCount',translate)
        geo=originals['TVF_DeterministicGeoJitter']
        self.assertIn('raw.PointBytes <= 128',geo)
        self.assertIn('measured.DistanceMeters <= measured.SafeRadius',geo)
        lookup=originals['USP_DeterministicLookup'];private=originals['USP_DeterministicLookupCore']
        self.assertLess(lookup.index('tempdb.sys.columns'),lookup.index('EXEC toolbelt_pseudonymization.USP_DeterministicLookupCore'))
        self.assertIn('SAVE TRANSACTION @Savepoint',private)
        self.assertIn('WITH(TABLOCK,HOLDLOCK)',private)
        self.assertLess(private.index('IF @PoolBytes > @MaxLookupTextBytes'),private.index('CREATE TABLE #tbx_DeterministicLookup_Pool'))
        self.assertLess(private.index('IF @ResultBytes > @MaxResultBytes'),private.index('CREATE TABLE #tbx_DeterministicLookup_ResultSource'))
        self.assertIn('0x544258444C4B5031,@LookupVersion',private)
        self.assertIn('keiner erneuten Autorisierung',records['USP_DeterministicLookupCore'].markdown)

    def test_regex_module_skills_cover_all_limits_intake_and_private_cores(self):
        expected={k:v for k,v in skills.inventory(ROOT).items() if v['module_id']=='toolbelt.string.regex'}
        self.assertEqual(len(expected),16)
        records={k[2]:skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected}
        for name,s in records.items():
            if s.metadata['object_type']=='ASSEMBLY':continue
            path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_function_ddl(text,s),text)
            clean=skills.strip_ddl_projection(ROOT,path,text)
            self.assertIn('CREATE FUNCTION',clean)
            self.assertNotIn(skills.DDL_BEGIN,clean)
            self.assertTrue(all(p['argument_required'] for p in s.metadata['parameters']))
            self.assertTrue(all(type(p['nullable']) is bool for p in s.metadata['parameters']))
            self.assertIn('keine neue native',s.markdown)
            if name.endswith('Core'):
                self.assertTrue(s.metadata['is_internal'])
                self.assertTrue(all(p['sql_default'] is None for p in s.metadata['parameters']))
                self.assertEqual(s.metadata['public_entrypoints'],['toolbelt_string.'+name[:-4]])
        for name in ('SVF_RegexIsMatch','SVF_RegexCount','SVF_RegexInstr'):
            pattern=next(p for p in records[name].metadata['parameters'] if p['name']=='@Pattern')
            self.assertIn('4000 UTF-16',pattern['description'])
        self.assertIn('ohne eigenes500ms Gesamtbudget',records['SVF_RegexIsMatch'].markdown)
        self.assertIn('100000 erfolgreiche Matchschritte',records['SVF_RegexCount'].markdown)
        self.assertIn('SQL bindet nvarchar(4)',records['SVF_RegexInstr'].markdown)
        for name in ('SVF_RegexReplace','SVF_RegexSubstring','TVF_RegexMatches','TVF_RegexSplit','TVF_RegexCaptures','SVF_RegexReplaceGroups'):
            self.assertIn('8388608',records[name].markdown)
            self.assertIn('64000',records[name].markdown)
            self.assertIn('die offene Form {m,} bleibt nach oben offen',records[name].markdown)
        for name,count in (('TVF_RegexMatches',4),('TVF_RegexSplit',4),('TVF_RegexCaptures',8)):
            result=records[name].markdown.split('## Ergebnisse\n\n',1)[1].split('\n\n## ',1)[0]
            self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',result,re.M)),count)
        self.assertIn('65536',records['SVF_RegexReplaceGroups'].markdown)
        self.assertIn('GroupName je Zeile',records['TVF_RegexCaptures'].markdown)
        self.assertIn('tokenStart bleibt',records['TVF_RegexSplit'].markdown)
        self.assertIn('$1 bleibt hier literal',records['SVF_RegexReplace'].markdown)
        folder=ROOT/'Modules/toolbelt.string.regex/Clr'
        intake=(folder/'RegexBoundedIntake.cs').read_text(encoding='utf-8-sig')
        provider=(folder/'RegexProvider.cs').read_text(encoding='utf-8-sig')
        transform=(folder/'RegexTransformations.cs').read_text(encoding='utf-8-sig')
        captures=(folder/'RegexCaptures.cs').read_text(encoding='utf-8-sig')
        relation=(folder/'RegexRelations.cs').read_text(encoding='utf-8-sig')
        self.assertLess(intake.index('if (value.Length > limit)'),intake.index('char[] copy'))
        self.assertIn('MaxPatternBytes = 8000',provider)
        self.assertIn('long left = 500 - clock.ElapsedMilliseconds',provider)
        self.assertIn('++successful > 100000',provider)
        self.assertIn('1048576 : 8388608',transform)
        self.assertIn('500 : 2000',transform)
        self.assertIn('if (openMaximum) maximum = -1;',provider)
        self.assertIn('Groups.Count == 64',captures)
        self.assertIn('parts.Count >= 65536',captures)
        self.assertIn('declaration.Name.Length + (capture == null ? 0 : capture.Length)',captures)
        self.assertIn('tokenStart = match.Index + match.Length',relation)

    def test_queue_module_is_source_complete_with_distinct_lease_recovery_completion_paths(self):
        expected={k:v for k,v in skills.inventory(ROOT).items() if v['module_id']=='toolbelt.core.work-queue'}
        self.assertEqual(len(expected),20)
        records={k[2]:skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected}
        originals={}
        names=('USP_RenewWorkLease','USP_RecoverExpiredWork','USP_CompleteWork','USP_RequeueDeadLetter')
        for name,count in zip(names,(4,7,22,41)):
            s=records[name];path=s.metadata['source_paths'][0]
            text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_procedure_ddl(text,s),text)
            self.assertEqual(skills.project_procedure_help(text,s),text)
            original=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text));originals[name]=original
            result=s.markdown.split('## Ergebnisse\n\n',1)[1].split('\n\n## ',1)[0]
            self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',result,re.M)),count)
            self.assertLess(skills._procedure_help_return(original,s)[0],original.index('THROW'))
            self.assertIn('keine neue native',s.markdown)
        renew=originals[names[0]];recover=originals[names[1]]
        self.assertNotIn('ManagedHold',renew)
        self.assertIn('kein eigener managedhold-',records[names[0]].markdown.casefold())
        self.assertIn('ManagedReservationId IS NULL AND ManagedHold=0',recover)
        self.assertIn('TOP (@MaxItems)',recover)
        self.assertLess(recover.index('@NowUtc datetime2(7)=SYSUTCDATETIME()'),recover.index('BEGIN TRANSACTION'))
        for name in (names[0],names[1],names[3]):
            self.assertIn('@@TRANCOUNT<>0 OR XACT_STATE()<>0',originals[name])
        complete=originals[names[2]]
        self.assertIn('SAVE TRANSACTION TBX_WorkQueue_Complete',complete)
        self.assertIn('@InitialTranCount<>1 OR @ManagedCompletionNonce IS NULL',complete)
        self.assertIn('APPLOCK_MODE',complete)
        requeue=originals[names[3]]
        self.assertIn('@ExpectedRowVersion IS NULL OR RowVersion=@ExpectedRowVersion',requeue)
        self.assertGreater(requeue.index('IF @ResultTable IS NULL SELECT *'),requeue.index('  COMMIT;'))
        self.assertIn('kein materialisierter Entscheidungsreceipt',records[names[3]].markdown)

    def test_queue_producer_status_skills_keep_real_shapes_and_commit_boundaries(self):
        originals={};records={}
        names=('USP_EnqueueWork','USP_EnqueueWorkWithPolicy','USP_EnqueueBarrierWork','USP_GetWorkStatus')
        for name in names:
            skill=skills.read(skills.source_file(ROOT,'toolbelt_core',name));records[name]=skill
            path=skill.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_procedure_help(text,skill),text)
            self.assertEqual(skills.project_procedure_ddl(text,skill),text)
            original=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text));originals[name]=original
            result=skill.markdown.split('## Ergebnisse\n\n',1)[1].split('\n\n## ',1)[0]
            self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',result,re.M)),42 if name in names[1:3] else 22)
            self.assertTrue(all(not p['argument_required'] for p in skill.metadata['parameters']))
            self.assertIn('keine neue native',skill.markdown)
            self.assertLess(skills._procedure_help_return(original,skill)[0],original.index('THROW'))
        enqueue=originals[names[0]]
        self.assertIn('SCOPE_IDENTITY()',enqueue)
        self.assertIn('SAVE TRANSACTION TBX_WorkQueue_Enqueue;',enqueue)
        self.assertLess(enqueue.index('INSERT INTO #tbx_WorkQueue_StatusResult'),enqueue.index('IF @InitialTranCount = 0 COMMIT'))
        policy=originals[names[1]]
        self.assertGreater(policy.index('IF @ResultTable IS NULL SELECT @WasCreated'),policy.index('IF @Initial=0 COMMIT'))
        self.assertIn('UNKNOWN',records[names[1]].markdown)
        self.assertIn('kein materialisierter Entscheidungsreceipt',records[names[1]].markdown)
        self.assertIn('Spacepadding',records[names[1]].markdown)
        self.assertIn("IF @ExecutionMode='DRAIN_BARRIER' AND @@TRANCOUNT<>0",policy)
        barrier=originals[names[2]]
        self.assertEqual(barrier.count('EXEC toolbelt_core.USP_EnqueueWorkWithPolicy '),1)
        self.assertNotIn('SET NOCOUNT',barrier)
        status=originals[names[3]]
        self.assertNotIn('BEGIN TRANSACTION',status)
        self.assertNotIn('SAVE TRANSACTION',status)
        self.assertIn('THROW 51931',status)
        self.assertIn('keinen eigenen WorkType-Policy-/Owner-/ClaimTokenfilter',records[names[3]].markdown)

    def test_queue_claim_fail_retry_skills_distinguish_result_shapes_and_transaction_paths(self):
        names=['USP_ClaimWork','USP_ClaimWorkCore','USP_FailWork','USP_FailWorkCore','USP_ScheduleWorkRetry','USP_ScheduleWorkRetryCore']
        records={};originals={}
        for name in names:
            s=skills.read(skills.source_file(ROOT,'toolbelt_core',name));records[name]=s
            path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_procedure_help(text,s),text)
            self.assertEqual(skills.project_procedure_ddl(text,s),text)
            original=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text));originals[name]=original
            expected_count=8 if 'Claim' in name else 22 if 'Fail' in name else 41
            result=s.markdown.split('## Ergebnisse\n\n',1)[1].split('\n\n## ',1)[0]
            self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',result,re.M)),expected_count)
            self.assertIn('keine neue native',s.markdown.casefold())
        core=records['USP_ClaimWorkCore'];original=originals['USP_ClaimWorkCore']
        output=next(p for p in core.metadata['parameters'] if p['name']=='@ClaimedWorkItemId')
        self.assertTrue(output['is_output']);self.assertEqual(output['sql_default'],'NULL')
        self.assertLess(skills._procedure_help_return(original,core)[0],original.index('SET @ClaimedWorkItemId=NULL;'))
        self.assertIn('(@EmitResult=0 AND @ManagedAdmissionToken IS NULL)',original)
        self.assertIn('SAVE TRANSACTION TBX_WorkQueue_ClaimCore',original)
        self.assertIn('ORDER BY wi.Priority DESC',original)
        fail=originals['USP_FailWorkCore']
        self.assertIn('SAVE TRANSACTION TBX_WorkQueue_Fail',fail)
        self.assertIn('IF XACT_STATE()=-1',fail)
        self.assertEqual(next(p for p in records['USP_FailWorkCore'].metadata['parameters'] if p['name']=='@FailureMessage')['sql_type'],'nvarchar(max)')
        retry=originals['USP_ScheduleWorkRetryCore']
        self.assertIn('SAVE TRANSACTION TBX_WorkQueue_Retry',retry)
        self.assertNotIn("IF @Status IS NULL",retry)
        self.assertIn('fehlende WorkItemId',records['USP_ScheduleWorkRetryCore'].markdown)
        self.assertIn('Kein materialisierter Entscheidungsreceipt',records['USP_ScheduleWorkRetry'].markdown)
        self.assertGreater(retry.index('IF @EmitResult=1 SELECT *'),retry.index('IF @Initial=0 COMMIT;'))
        for family in ['ClaimWork','FailWork','ScheduleWorkRetry']:
            self.assertEqual(originals['USP_'+family].count('EXEC toolbelt_core.USP_'+family+'Core '),1)

    def test_complete_worker_module_skills_preserve_stop_fences_and_conservative_unknown(self):
        expected={k:v for k,v in skills.inventory(ROOT).items() if v['module_id']=='toolbelt.core.worker-control'}
        records=[skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected]
        self.assertEqual(skills.validate_coverage(records,expected),29)
        by_name={s.metadata['object_name']:s for s in records}
        names=['USP_ClaimWorkerWork','USP_CloseWorker','USP_StopWorkerExecution','USP_StopWorkers','USP_ReconcileWorkerExecution','USP_ReleaseHeldWork']
        bodies={}
        for name in names:
            s=by_name[name];path=s.metadata['source_paths'][0]
            text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_procedure_help(text,s),text)
            self.assertEqual(skills.project_procedure_ddl(text,s),text)
            ret,_=skills._procedure_help_return(text,s)
            self.assertLess(ret,text.index(' IF @@TRANCOUNT<>0'))
            original=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text))
            bodies[name]=original.split('-- API_PARAMETER_HELP:END',1)[1]
            self.assertIn('keine neue native',s.markdown.casefold())
        claim=bodies[names[0]]
        self.assertNotIn('BEGIN TRANSACTION',claim)
        self.assertEqual(claim.count('EXEC toolbelt_core.USP_ReserveWorkerExecution '),1)
        self.assertIn('State=\'CLOSED\'',bodies[names[1]])
        self.assertIn('IsOccupied=1',bodies[names[1]])
        stop=bodies[names[2]]
        self.assertLess(stop.index('IF @IsCompleted=1'),stop.index('FROM toolbelt_core.WorkerExecutionCommitWitness'))
        self.assertIn('bestehender Dispositions-StopStatus',by_name[names[2]].markdown)
        batch=bodies[names[3]]
        self.assertIn('SET LOCK_TIMEOUT 0;',batch)
        self.assertIn('COUNT_BIG(*) FROM #tbx_StopWorkersSelection)>1000',batch)
        self.assertIn('COUNT_BIG(*) FROM #tbx_StopWorkersReservations)>100000',batch)
        self.assertIn('ORDER BY SlotReservationId',batch)
        rec=bodies[names[4]]
        self.assertLess(rec.index("@SessionLock<0 INSERT"),rec.index('IF @Item IS NULL OR @HoldVersion'))
        self.assertIn('ERROR_NUMBER()=1222 AND XACT_STATE()=1',rec)
        self.assertNotIn('SAVE TRANSACTION',rec)
        self.assertIn('ohne Versionsprüfung',by_name[names[4]].markdown)
        release=bodies[names[5]]
        self.assertIn('WITH(READPAST,READCOMMITTEDLOCK)',release)
        self.assertIn('RetryCycleNumber=RetryCycleNumber+1,CycleAttemptCount=0',release)
        self.assertIn("@LockOwner=N'Transaction',@LockTimeout=0",release)

    def test_worker_admission_bind_finalization_contracts_preserve_private_boundary_and_outputs(self):
        names=['USP_ReserveWorkerExecution','USP_BindWorkerExecution','USP_FinalizeWorkerFailure']
        records={};bodies={}
        for name in names:
            s=skills.read(skills.source_file(ROOT,'toolbelt_core',name));records[name]=s
            path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertTrue(s.metadata['is_internal'])
            self.assertEqual(skills.project_procedure_help(text,s),text)
            self.assertEqual(skills.project_procedure_ddl(text,s),text)
            original=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text))
            self.assertEqual(original.count('RETURN 0; END;'),1)
            bodies[name]=original.split('RETURN 0; END;',1)[1]
            self.assertIn('keine neue native',s.markdown.casefold())
        reserve=bodies[names[0]]
        self.assertIn('@ClaimedWorkItemId=@CanonicalClaimId OUTPUT,@EmitResult=0',reserve)
        self.assertIn('wi.WorkItemId=@CanonicalClaimId AND wi.ManagedReservationId=@Reservation',reserve)
        self.assertNotIn('INSERT EXEC',reserve.replace('-- Fester interner Transport: kein öffentlicher ResultTable-Name und kein INSERT EXEC.',''))
        self.assertIn('Leeres Ergebnis beweist keine völlige Mutationsfreiheit',records[names[0]].markdown)
        bind=bodies[names[1]]
        self.assertIn("@LockOwner=N'Session',@LockTimeout=0",bind)
        self.assertIn('@read_only=1',bind)
        self.assertIn("r.State='RESERVED' AND r.AttemptNonce IS NULL",bind)
        self.assertIn('Kein Rebind',records[names[1]].markdown)
        final=records[names[2]]
        outcome=next(p for p in final.metadata['parameters'] if p['name']=='@Outcome')
        self.assertEqual((outcome['sql_type'],outcome['sql_default'],outcome['is_output'],outcome['business_required']),('varchar(24)','NULL',True,False))
        self.assertIn('bei reiner Hilfe nicht überschrieben',final.markdown)
        self.assertIn('@Retry=1 EXEC toolbelt_core.USP_ScheduleWorkRetryCore @EmitResult=0',bodies[names[2]])
        self.assertIn("Status IN('FAILED','RETRY_WAIT','DEAD_LETTER')",bodies[names[2]])
        self.assertIn('State bleibtROLLED_BACK',final.markdown)

    def test_worker_attempt_helpers_distinguish_outer_transaction_commit_rollback_unknown(self):
        names=['USP_BeginWorkerCompletion','USP_BeginWorkerTransactionWitness','USP_RecordWorkerCommit','USP_RecordWorkerRollback','USP_RecordWorkerUnknown']
        records={};bodies={}
        for name in names:
            s=skills.read(skills.source_file(ROOT,'toolbelt_core',name));records[name]=s
            path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertTrue(s.metadata['is_internal'])
            self.assertEqual(len(s.metadata['parameters']),5)
            self.assertEqual(skills.project_procedure_help(text,s),text)
            self.assertIn(skills.HELP_COMPACT,text)
            original=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text))
            self.assertEqual(original.count('RETURN 0; END;'),1)
            bodies[name]=original.split('RETURN 0; END;',1)[1]
            self.assertIn('keine neue native',s.markdown.casefold())
            self.assertNotIn('@ResultTable',[p['name'] for p in s.metadata['parameters']])
        for name in names[:2]:
            self.assertIn('@@TRANCOUNT<>1 OR XACT_STATE()<>1',bodies[name])
            self.assertNotIn('BEGIN TRANSACTION',bodies[name])
            self.assertIn('BoundPrincipalId=USER_ID()',bodies[name])
        self.assertIn('ManagedCompletionNonce=@CompletionNonce',bodies[names[0]])
        self.assertIn('sp_set_session_context',bodies[names[0]])
        self.assertIn('INSERT toolbelt_core.WorkerExecutionCommitWitness',bodies[names[1]])
        self.assertIn("Status='COMPLETED'",bodies[names[2]])
        self.assertIn('IsOccupied=0',bodies[names[2]])
        self.assertIn('bleiben IsOccupied und EndedAtUtc unverändert',records[names[3]].markdown)
        self.assertIn('WITH(UPDLOCK,HOLDLOCK)',bodies[names[3]])
        self.assertIn("StopStatus='ROLLED_BACK_HELD'",bodies[names[3]])
        self.assertIn('w.WorkerToken=@WorkerToken',bodies[names[4]])
        self.assertNotIn('SESSION_CONTEXT',bodies[names[4]])
        self.assertNotIn('IsOccupied=0',bodies[names[4]])
        self.assertIn('bleibt1',records[names[4]].markdown)

    def test_compact_help_projects_after_existing_result_without_changing_original_bytes(self):
        s=skills.read(skills.source_file(ROOT,'toolbelt_core','USP_SecondSessionProbe'))
        path=s.metadata['source_paths'][0]
        for spacing in ('', ' ', '  ', '\t'):
            original=('CREATE OR ALTER PROCEDURE toolbelt_core.USP_SecondSessionProbe @Hilfe bit=0\nAS\nBEGIN\n'
                      ' IF ISNULL(@Hilfe,0)=1 BEGIN\n SELECT N\'Contoso\' ExistingHelp;'+spacing+'RETURN 0; END;\n SELECT 7;\nEND;\nGO\n')
            projected=skills.project_procedure_ddl(skills.project_procedure_help(original,s),s)
            self.assertIn(skills.HELP_COMPACT,projected)
            self.assertEqual(skills.project_procedure_help(projected,s),projected)
            self.assertLess(projected.index("SELECT N'Contoso'"),projected.index(skills.HELP_BEGIN))
            self.assertNotRegex(projected,r'ExistingHelp;[ \t]+\n')
            clean=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,projected))
            self.assertEqual(clean,original)
            changed=projected.replace('SELECT 7;','SELECT 8;')
            self.assertNotEqual(skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,changed)),original)
            with self.assertRaises(ValueError):
                skills.project_procedure_help(projected.replace('=1 BEGIN','=0 BEGIN'),s)
            with self.assertRaises(ValueError):
                skills.project_procedure_help(projected.replace(skills.HELP_COMPACT,skills.HELP_COMPACT+' changed'),s)
        normal=original.replace(';\tRETURN 0;',';\n RETURN 0;')
        with self.assertRaises(ValueError):skills.project_procedure_help(normal+skills.HELP_COMPACT+'\n',s)
        with self.assertRaises(ValueError):skills.project_procedure_help(original.replace(';\tRETURN',';/*Contoso*/ RETURN'),s)

    def test_worker_identity_skills_distinguish_owner_bound_and_admin_paths(self):
        names=['USP_RegisterWorker','USP_HeartbeatWorker','USP_SetWorkerCapacity','USP_SetWorkerState']
        bodies={};records={}
        for name in names:
            s=skills.read(skills.source_file(ROOT,'toolbelt_core',name));records[name]=s
            path=s.metadata['source_paths'][0];text=(ROOT/path).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_procedure_help(text,s),text)
            self.assertEqual(skills.project_procedure_ddl(text,s),text)
            ret,_=skills._procedure_help_return(text,s)
            self.assertLess(ret,text.index(' IF @@TRANCOUNT<>0'))
            body=skills.strip_ddl_projection(ROOT,path,skills.strip_help_projection(ROOT,path,text))
            bodies[name]=body.split('-- API_PARAMETER_HELP:END',1)[1]
            self.assertTrue(all(p['sql_default'] is not None for p in s.metadata['parameters']))
            self.assertIn('keine neue native',s.markdown.casefold())
        self.assertIn('OwnerPrincipalId=USER_ID()',bodies['USP_HeartbeatWorker'])
        self.assertIn('WorkerToken=@WorkerToken',bodies['USP_HeartbeatWorker'])
        self.assertIn("State='UNREACHABLE'",bodies['USP_HeartbeatWorker'])
        self.assertFalse(any(p['name']=='@ResultTable' for p in records['USP_HeartbeatWorker'].metadata['parameters']))
        self.assertIn("AND State<>'CLOSED'",bodies['USP_SetWorkerCapacity'])
        self.assertNotIn('OwnerPrincipalId',bodies['USP_SetWorkerCapacity'])
        self.assertNotIn('DATEADD',bodies['USP_SetWorkerCapacity'])
        self.assertIn('auch eine ältere oder UNREACHABLE-Generation',records['USP_SetWorkerCapacity'].markdown)
        self.assertIn('ALLEN Generationen',records['USP_SetWorkerState'].markdown)
        self.assertIn("State IN('ACTIVE','PAUSED')",bodies['USP_RegisterWorker'])
        self.assertNotIn('ManagedEnabled',bodies['USP_RegisterWorker'])
        self.assertIn('hier nicht erhöht',records['USP_RegisterWorker'].markdown)

    def test_worker_configuration_skills_keep_early_help_and_typed_version_mutations_separate(self):
        names=['USP_EnableManagedWorkers','USP_DisableManagedWorkers','USP_SetWorkerConcurrency','USP_SetWorkerIntervals']
        for name in names:
            s=skills.read(skills.source_file(ROOT,'toolbelt_core',name))
            text=(ROOT/s.metadata['source_paths'][0]).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_procedure_help(text,s),text)
            self.assertEqual(skills.project_procedure_ddl(text,s),text)
            ret,_=skills._procedure_help_return(text,s)
            tokens=skills._ddl_tokens(text)
            pairs=[(tokens[i][0].casefold(),tokens[i+1][0].casefold(),tokens[i][1]) for i in range(len(tokens)-1)]
            first_temp=next(pos for a,b,pos in pairs if (a,b)==('create','table'))
            self.assertLess(ret,first_temp)
            body=skills.strip_ddl_projection(ROOT,s.metadata['source_paths'][0],skills.strip_help_projection(ROOT,s.metadata['source_paths'][0],text))
            self.assertIn('SET XACT_ABORT OFF;',body)
            self.assertLess(body.index('IF @@TRANCOUNT<>0'),body.index('BEGIN TRANSACTION;'))
            self.assertLess(body.index('IF @ResultTable IS NOT NULL'),body.index('COMMIT TRANSACTION;'))
            expected=next(p for p in s.metadata['parameters'] if p['name']=='@ExpectedConfigVersion')
            self.assertEqual((expected['sql_type'],expected['sql_default'],expected['business_required'],expected['nullable']),('binary(8)','NULL',True,False))
            self.assertIn('wird die eigene Mutation zurückgerollt',s.markdown)
            self.assertIn('nach Commit',s.markdown)
            self.assertIn('kein No-op' if name in names[:2] else 'ändern dennoch ConfigVersion' if name==names[3] else 'verändert dennoch ConfigVersion',s.markdown)
            if name in names[:2]:self.assertIn('54217/1',s.markdown)
            if name==names[3]:self.assertIn('Arithmetic-Overflow',s.markdown)

    def test_worker_relations_cover_real_columns_and_separate_witness_from_status(self):
        expected={k:v for k,v in skills.inventory(ROOT).items()
                  if v['module_id']=='toolbelt.core.worker-control' and v['object_type'] in ('TABLE','VIEW')}
        records=[skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected]
        self.assertEqual(skills.validate_coverage(records,expected),7)
        counts={'WorkerControlConfiguration':5,'WorkerRegistration':12,'WorkerSlotReservation':13,
                'WorkerExecutionDisposition':5,'WorkerExecutionCommitWitness':5,
                'VW_WorkerStatus':11,'VW_WorkerExecutionStatus':10}
        by_name={s.metadata['object_name']:s for s in records}
        for name,s in by_name.items():
            text=(ROOT/s.metadata['source_paths'][0]).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_relation_ddl(text,s),text)
            fields=re.findall(r'^\| `([^`]+)` \| `([^`]+)` \|',s.markdown,re.M)
            self.assertEqual(len(fields),counts[name])
            self.assertEqual(s.metadata['parameters'],[])
            self.assertIn('keine neue native',s.markdown.casefold())
            if s.metadata['object_type']=='TABLE':
                self.assertTrue(s.metadata['is_internal'])
                tokens,anchor=skills._relation_anchor(text,s)
                columns=[];depth=1;start=True
                for token,_,_ in tokens[anchor+1:]:
                    if depth==1 and start:
                        if token.casefold() not in ('constraint','primary','foreign','check','unique'):
                            columns.append(token.strip('[]'))
                        start=False
                    if token=='(':depth+=1
                    if token==')':
                        depth-=1
                        if depth==0:break
                    if token==',' and depth==1:start=True
                self.assertEqual([n for n,_ in fields],columns)
        self.assertIn('keine kryptografische Signatur',by_name['WorkerExecutionCommitWitness'].markdown)
        self.assertIn('uncommittete Zeile',by_name['WorkerExecutionCommitWitness'].markdown)
        self.assertIn('CROSS JOIN',by_name['VW_WorkerStatus'].markdown)
        self.assertIn('keine dynamische Unerreichbarkeitsberechnung',by_name['VW_WorkerStatus'].markdown)
        self.assertIn('WorkItemId UND SlotReservationId',by_name['VW_WorkerExecutionStatus'].markdown)
        self.assertIn('dortiges NONE bleibt auch bei COMMITTED NONE',by_name['VW_WorkerExecutionStatus'].markdown)

    def test_queue_relation_skills_cover_all_six_relations_and_actual_status_limits(self):
        expected = {k: v for k, v in skills.inventory(ROOT).items()
                    if v['module_id'] == 'toolbelt.core.work-queue' and v['object_type'] in ('TABLE','VIEW')}
        records = [skills.read(skills.source_file(ROOT,k[1],k[2])) for k in expected]
        self.assertEqual(skills.validate_coverage(records,expected),6)
        for s in records:
            text=(ROOT/s.metadata['source_paths'][0]).read_text(encoding='utf-8-sig')
            self.assertEqual(skills.project_relation_ddl(text,s),text)
            self.assertEqual(s.metadata['parameters'],[])
            self.assertIn('keine neue native',s.markdown.casefold())
            if s.metadata['object_type']=='TABLE':self.assertTrue(s.metadata['is_internal'])
        by_name={s.metadata['object_name']:s for s in records}
        item=by_name['WorkItem']
        fields=re.findall(r'^\| `([^`]+)` \| `([^`]+)` \|',item.markdown,re.M)
        self.assertEqual(len(fields),46)
        self.assertEqual(fields[0],('WorkItemId','bigint'))
        self.assertEqual(fields[-3:],[('ManagedReservationId','uniqueidentifier'),('ManagedHold','bit'),('ManagedCompletionNonce','uniqueidentifier')])
        self.assertIn('prüft ebenfalls nur diese Statusmenge',item.markdown)
        body='\n'.join(skills.strip_ddl_projection(ROOT,p,(ROOT/p).read_text(encoding='utf-8')) for p in item.metadata['source_paths'])
        for name,datatype in fields:
            self.assertRegex(body,r'\b'+re.escape(name)+r'\]?\s+'+re.escape(datatype)+r'(?!\w)')
        queue=by_name['VW_WorkQueue']
        view_fields=re.findall(r'^\| `([^`]+)` \| `([^`]+)` \|',queue.markdown,re.M)
        self.assertEqual(len(view_fields),41)
        self.assertEqual(dict(view_fields)['RowVersion'],'binary(8)')
        self.assertNotIn('ClaimToken',dict(view_fields))
        blocker=by_name['VW_WorkQueueBarrierBlockers']
        self.assertEqual(len(re.findall(r'^\| `([^`]+)` \|',blocker.markdown,re.M)),6)
        self.assertIn('abgelaufene Lease',blocker.markdown)

    def test_compact_table_skill_preserves_exact_original_whitespace_and_own_header(self):
        s = skills.read(skills.source_file(ROOT, "toolbelt_core", "WorkType"))
        path = s.metadata["source_paths"][0]
        for indent in ("", " ", "    ", "\t"):
            original = "CREATE TABLE toolbelt_core.WorkType\n" + indent + "(WorkTypeId bigint NOT NULL);\nGO\n"
            with self.subTest(indent=indent):
                projected = skills.project_relation_ddl(original, s)
                self.assertEqual(skills.project_relation_ddl(projected, s), projected)
                self.assertEqual(skills.strip_ddl_projection(ROOT, path, projected), original)
                self.assertEqual(skills.read_ddl_comment(projected).markdown, s.markdown)
                changed = projected.replace("bigint NOT NULL", "int NOT NULL")
                self.assertNotEqual(skills.strip_ddl_projection(ROOT, path, changed), original)
        with self.assertRaises(ValueError):
            skills.project_relation_ddl("CREATE TABLE toolbelt_core.WorkType(WorkTypeId bigint);", s)
        with self.assertRaises(ValueError):
            skills.project_relation_ddl("CREATE TABLE Contoso.Other\n(Id bigint);", s)
        moved = "CREATE TABLE toolbelt_core.WorkType\n(Id bigint);\n" + skills.render_ddl_comment(s)
        with self.assertRaises(ValueError): skills.project_relation_ddl(moved, s)

    def test_capability_skill_describes_visibility_without_invented_installation_state(self):
        s = skills.read(skills.source_file(ROOT, "toolbelt_metadata", "VW_ModuleCapabilities"))
        expected = {k: v for k, v in skills.inventory(ROOT).items()
                    if v["module_id"] == "toolbelt.metadata.capability-catalog"
                    and k[2] == "VW_ModuleCapabilities"}
        self.assertEqual(skills.validate_coverage([s], expected), 1)
        self.assertEqual(s.metadata["parameters"], [])
        path = s.metadata["source_paths"][0]
        text = (ROOT / path).read_text(encoding="utf-8-sig")
        self.assertEqual(skills.project_relation_ddl(text, s), text)
        self.assertEqual(skills.read_ddl_comment(text).markdown, s.markdown)
        body = skills.strip_ddl_projection(ROOT, path, text)
        self.assertIn("OBJECT_ID(c.ObjectName)", body)
        self.assertIn("CONVERT(varbinary(256),a.name)", body)
        self.assertIn("SELECT DISTINCT ModuleId", body)
        for term in ("Metadata Visibility", "incomplete", "immer NULL", "VW_ObjectUsageSkills", "keine neue native"):
            self.assertIn(term.casefold(), s.markdown.casefold())
        self.assertNotIn("extended_properties", body)

    def test_schema_skills_distinguish_public_facade_and_required_clr_arguments(self):
        expected = {key: value for key, value in skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.json.schema"}
        records = [skills.read(skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(skills.validate_coverage(records, expected), 3)
        facade = next(s for s in records if s.metadata["object_type"] == "USP")
        raw = next(s for s in records if s.metadata["object_type"] == "CLR_TVF")
        self.assertEqual(len(raw.metadata["parameters"]), 8)
        self.assertTrue(all(p["argument_required"] and p["sql_default"] is None
                            for p in raw.metadata["parameters"]))
        self.assertEqual(raw.metadata["parameters"][2]["sql_type"], "nvarchar(32)")
        self.assertEqual(facade.metadata["parameters"][2]["sql_type"], "varchar(32)")
        self.assertTrue(all("55600" not in p["description"] and "Default" not in p["description"].replace("Kein SQL-Default", "")
                            for p in raw.metadata["parameters"]))
        for s in (facade, raw):
            path = s.metadata["source_paths"][0]
            text = (ROOT / path).read_text(encoding="utf-8-sig")
            self.assertEqual(skills.read_ddl_comment(text).markdown, s.markdown)
            for value in ("SCHEMA_BYTES", "DOCUMENT_BYTES", "EVALUATION_LIMIT", "REF_CYCLE",
                          "INVALID_INSTANCE", "SQL_NULL", "ErrorsTruncated", "IsValid=NULL"):
                self.assertIn(value, s.markdown)
            if s is raw:
                self.assertEqual(skills.project_function_ddl(text, s), text)
                self.assertEqual(len(skills._dynamic_clr_slots(text)), 1)
            else:
                self.assertEqual(skills.project_procedure_help(text, s), text)
                self.assertEqual(skills.project_procedure_ddl(text, s), text)
                early_return, _ = skills._procedure_help_return(text, s)
                self.assertLess(early_return, text.index("THROW 55600"))

    def test_guarded_dynamic_clr_ddl_roundtrips_without_general_literal_interpretation(self):
        skill = skills.read(skills.source_file(ROOT, "toolbelt_string", "TVF_ColognePhoneticCore"))
        path = skill.metadata["source_paths"][0]
        payload = ("CREATE FUNCTION toolbelt_string.TVF_ColognePhoneticCore(@Text nvarchar(max))\n"
                   "RETURNS TABLE(PhoneticCode nvarchar(max),ErrorCode int)\n"
                   "AS EXTERNAL NAME [tlblt_String_Phonetic].[Contoso.Bridge].[Invoke];")
        def wrap(sql):
            return ("IF OBJECT_ID(N'toolbelt_string.TVF_ColognePhoneticCore') IS NULL\n"
                    " EXEC sys.sp_executesql N'" + sql.replace("'", "''") + "';\nGO\n")
        original = wrap(payload)
        projected = skills.project_function_ddl(original, skill)
        self.assertEqual(skills.project_function_ddl(projected, skill), projected)
        self.assertEqual(skills.read_ddl_comment(projected).markdown, skill.markdown)
        self.assertEqual(skills.strip_ddl_projection(ROOT, path, projected), original)
        slots = skills._dynamic_clr_slots(projected)
        self.assertEqual(len(slots), 1)
        self.assertEqual(slots[0][3], skills.project_function_ddl(payload, skill))
        # Quoting in comments is restored, not a blanket SQL-literal rewrite.
        data = "SELECT N'" + slots[0][3].replace("'", "''") + "';"
        self.assertEqual(skills.read_ddl_comments(data), [])
        self.assertEqual(skills.strip_ddl_projection(ROOT, path, data), data)
        with self.assertRaises(ValueError):
            skills.project_function_ddl(original.replace("OBJECT_ID(N'toolbelt_string.",
                                                        "OBJECT_ID(N'Contoso."), skill)
        with self.assertRaises(ValueError):
            skills.project_function_ddl(original.replace("';\nGO", "' + N'';\nGO"), skill)
        with self.assertRaises(ValueError):
            skills.project_function_ddl(original + "\n" + payload, skill)
        with self.assertRaises(ValueError):
            skills.project_function_ddl(original + original, skill)
        unconditional = original.split("\n", 1)[1]
        self.assertEqual(skills.read_ddl_comments(unconditional), [])
        self.assertEqual(skills.strip_ddl_projection(ROOT, path, unconditional), unconditional)
        with self.assertRaises(ValueError):
            skills.project_function_ddl(projected.replace("4096", "4097", 1), skill)
        changed = projected.replace("[Invoke]", "[Changed]", 1)
        self.assertNotEqual(skills.strip_ddl_projection(ROOT, path, changed), original)
        # Moving the comment behind the function still fails its own-header check.
        moved = wrap(payload + "\n" + skills.render_ddl_comment(skill))
        with self.assertRaises(ValueError):
            skills.project_function_ddl(moved, skill)


if __name__ == "__main__":
    unittest.main()
