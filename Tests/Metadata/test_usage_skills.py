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


if __name__ == "__main__":
    unittest.main()
