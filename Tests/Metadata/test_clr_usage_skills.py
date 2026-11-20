"""CLR-Konstanten und Ablehnung ungeprüfter Daten, ohne SQL-/Dateisystem-Fachzugriff."""
from copy import deepcopy
import json
from pathlib import Path
import re
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Metadata"))
import usage_skills
import clr_usage_skills


def samples():
    return [usage_skills.read(ROOT / "Metadata/UsageSkills/toolbelt_core" / (name + ".md"))
            for name in ("USP_PrepareResultTable", "USP_SecondSessionProbe")]


def with_help(skill):
    metadata = deepcopy(skill.metadata)
    if not any(p["name"] == "@Hilfe" for p in metadata["parameters"]):
        metadata["parameters"].append(dict(name="@Hilfe", sql_type="bit", sql_default="0", is_output=False,
            argument_required=False, business_required=False, nullable=True, description="Frühe konstante Skillhilfe."))
    _, body = usage_skills.parse_frontmatter(skill.markdown)
    sections = {key: body.split("## " + key + "\n", 1)[1].split("\n## ", 1)[0].strip()
                for key in usage_skills.SECTIONS}
    with tempfile.TemporaryDirectory() as directory:
        return usage_skills.write(Path(directory) / "Skill.md", metadata, sections)


def prepare_record_fixture(directory: Path):
    """Neue private Eingaben für den separat kompilierten C#-Transporttest."""
    usage_skills.require(not directory.exists(), "Neues CLR-Testverzeichnis erforderlich")
    first, second = samples()
    text = first.markdown + '\nÄ𐐀 O\'Brien "quoted" \\ /\n' * 2000
    generated = clr_usage_skills.render([usage_skills.Skill(first.metadata, text), second])
    directory.mkdir(parents=True)
    (directory / "Generated.cs").write_text(generated, encoding="utf-8", newline="\n")
    (directory / "Expected.md").write_text(text, encoding="utf-8", newline="\n")


def prepare_module_fixture(directory: Path):
    """Exakte neun aktuelle Quellen zur separaten In-memory-.NET-Prüfung."""
    usage_skills.require(not directory.exists(), "Neues CLR-Testverzeichnis erforderlich")
    clr_usage_skills.generate(ROOT, "toolbelt.filesystem.windows", "Toolbelt.Metadata", directory / "Generated.cs")
    entries = []
    for path in sorted((ROOT / "Metadata/UsageSkills/toolbelt_filesystem").glob("CLR_*.md")):
        skill = usage_skills.read(path)
        name = path.name
        (directory / name).write_bytes(path.read_bytes())
        entries.append("\t".join((skill.metadata["schema_name"], skill.metadata["object_name"], name)))
    (directory / "Expected.tsv").write_text("\n".join(entries) + "\n", encoding="utf-8", newline="\n")


class ClrUsageSkillTests(unittest.TestCase):
    def test_provider_help_preserves_original_body_and_rejects_guard_drift(self):
        records = [with_help(usage_skills.read(p)) for p in sorted(
            (ROOT / "Metadata/UsageSkills/toolbelt_filesystem").glob("CLR_*.md"))]
        text = (ROOT / "Modules/toolbelt.filesystem.windows/Clr/WindowsFilesystemProvider.cs").read_text(encoding="utf-8-sig")
        original = clr_usage_skills.strip_provider_help(text, records) if clr_usage_skills.PROVIDER_PARAMETER in text else text
        output = clr_usage_skills.project_provider_help(original, records)
        self.assertEqual(clr_usage_skills.project_provider_help(output, records), output)
        self.assertEqual(clr_usage_skills.strip_provider_help(output, records), original)
        self.assertEqual(output.count(clr_usage_skills.PROVIDER_PARAMETER), 9)
        for changed in (output.replace("hilfe.IsTrue", "hilfe.IsFalse", 1),
                        output.replace("UsageSkillsGenerated.Send", "Different.Send", 1),
                        output.replace("default(SqlBoolean)", "SqlBoolean.True", 1)):
            with self.assertRaises(ValueError):
                clr_usage_skills.strip_provider_help(changed, records)

    def test_sql_clr_optional_help_parameter_keeps_original_arguments_and_body(self):
        skill = with_help(usage_skills.read(ROOT / "Metadata/UsageSkills/toolbelt_filesystem/CLR_ReadBinaryFileChunk.md"))
        text = "CREATE PROCEDURE toolbelt_filesystem.CLR_ReadBinaryFileChunk\n(\n @RootAlias sysname=NULL\n)\nAS EXTERNAL NAME [tlblt_Filesystem_Windows].[Provider].[ReadBinaryFileChunk];\nGO\n"
        projected = usage_skills.project_clr_help_parameter(text, skill)
        block = usage_skills.render_clr_help_parameter(skill)
        self.assertEqual(projected.replace(block, "", 1), text)
        self.assertEqual(usage_skills.project_clr_help_parameter(projected, skill), projected)
        for broken in (projected.replace("@Hilfe bit = 0", "@Hilfe bit = 1"),
                       projected.replace(block, "", 1) + block):
            with self.assertRaises(ValueError):
                usage_skills.project_clr_help_parameter(broken, skill)

    def test_filesystem_module_has_complete_source_contracts_including_configuration(self):
        expected = {key: value for key, value in usage_skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.filesystem.windows"}
        sources = [usage_skills.read(usage_skills.source_file(ROOT, key[1], key[2])) for key in expected]
        self.assertEqual(usage_skills.validate_coverage(sources, expected), len(expected))
        self.assertEqual({s.metadata["object_type"] for s in sources}, {"USP", "CLR_USP", "TABLE", "ASSEMBLY"})
        table = next(s for s in sources if s.metadata["object_name"] == "FileSystemRoot")
        path = table.metadata["source_paths"][0]
        text = (ROOT / path).read_text(encoding="utf-8-sig")
        self.assertEqual(usage_skills.project_relation_ddl(text, table), text)
        stripped = usage_skills.strip_ddl_projection(ROOT, path, text)
        self.assertIn("IF OBJECT_ID(N'toolbelt_filesystem.FileSystemRoot', N'U') IS NULL", stripped)
        self.assertIn("CREATE ROLE toolbelt_filesystem_service_account AUTHORIZATION dbo;", stripped)
        self.assertIn("DEFAULT(0) WITH VALUES;", stripped)

    def test_public_filesystem_skills_match_signatures_and_early_help_projection(self):
        sources = [usage_skills.read(p) for p in sorted(
            (ROOT / "Metadata/UsageSkills/toolbelt_filesystem").glob("USP_*.md"))
            if "Internal" not in p.name]
        self.assertEqual(len(sources), 9)
        sql = (ROOT / sources[0].metadata["source_paths"][0]).read_text(encoding="utf-8-sig")
        for skill in sources:
            ts, words, i, limit = usage_skills._procedure_declaration(sql, skill)
            end = next(j for j in range(i + 4, limit) if words[j] == "as")
            actual = re.findall(r"(@\w+)\s+(sysname|nvarchar\(\d+\)|nvarchar\(max\)|varbinary\(max\)|varchar\(\d+\)|bigint|tinyint|int|bit)(?:\s*=\s*(N?'[^']*'|NULL|\d+))?",
                                sql[ts[i + 3][2]:ts[end][1]])
            self.assertEqual(actual, [(p["name"], p["sql_type"], p["sql_default"] or "")
                                      for p in skill.metadata["parameters"]], skill.identity)
            self.assertFalse(skill.metadata["is_internal"])
            self.assertEqual(usage_skills.project_procedure_help(sql, skill), sql)
            self.assertEqual(usage_skills.project_procedure_ddl(sql, skill), sql)
            a, b = usage_skills._procedure_region(sql, skill)
            ret, indent = usage_skills._procedure_help_return(sql, skill)
            block = usage_skills.render_help_projection(skill, indent)
            self.assertTrue(sql[:ret].endswith(block))
            self.assertLess(ret, sql.index("CREATE TABLE #tbx_fs_result", a, b))
            self.assertNotIn("kein ResultTable-Routing", skill.markdown)

    def test_raw_filesystem_contracts_match_actual_sql_parameters_and_defaults(self):
        sources = [usage_skills.read(p) for p in sorted(
            (ROOT / "Metadata/UsageSkills/toolbelt_filesystem").glob("CLR_*.md"))]
        self.assertEqual(len(sources), 9)
        sql = (ROOT / sources[0].metadata["source_paths"][0]).read_text(encoding="utf-8-sig")
        for skill in sources:
            ts, _, i, limit = usage_skills._procedure_declaration(sql, skill)
            a, b = usage_skills._clr_procedure_anchor(sql, skill)
            parameters = sql[ts[i + 3][2]:a]
            # Comments contain Markdown parameter examples; remove them before
            # independently inspecting the actual declaration's simple syntax.
            actual = re.findall(r"(@\w+)\s+(sysname|nvarchar\(\d+\)|nvarchar\(max\)|varbinary\(max\)|bigint|int|bit)(?:\s*=\s*(N?'[^']*'|NULL|\d+))?", parameters)
            expected = [(p["name"], p["sql_type"], p["sql_default"] or "")
                        for p in skill.metadata["parameters"]]
            self.assertEqual(actual, expected, skill.identity)
            self.assertTrue(skill.metadata["is_internal"])
            self.assertEqual(skill.metadata["public_entrypoints"],
                             ["toolbelt_filesystem.USP_" + skill.metadata["object_name"][4:]])
            for parameter in skill.metadata["parameters"]:
                self.assertEqual(parameter["argument_required"], parameter["sql_default"] is None)
        remove = next(s for s in sources if s.metadata["object_name"] == "CLR_RemoveDirectory")
        self.assertIn("nur >=1", remove.markdown)
        self.assertIn("Teilentfernung", remove.markdown)

    def test_real_clr_ddl_comments_bind_each_own_external_header_and_preserve_code(self):
        sources = [usage_skills.read(p) for p in sorted(
            (ROOT / "Metadata/UsageSkills/toolbelt_filesystem").glob("CLR_*.md"))]
        self.assertEqual(len(sources), 9)
        path = sources[0].metadata["source_paths"][0]
        current = (ROOT / path).read_text(encoding="utf-8-sig")
        base = current
        for skill in sources:
            base = base.replace(usage_skills.render_ddl_comment(skill), "", 1)
        projected = base
        for skill in sources:
            projected = usage_skills.project_clr_procedure_ddl(projected, skill)
            self.assertEqual(usage_skills.project_clr_procedure_ddl(projected, skill), projected)
        for skill in sources:
            self.assertTrue(usage_skills._existing_clr_procedure_skill(projected, skill))
        without = projected
        for skill in sources:
            without = without.replace(usage_skills.render_ddl_comment(skill), "", 1)
        self.assertEqual(without, base)
        first, second = sources[:2]
        comment = usage_skills.render_ddl_comment(first)
        other = usage_skills.render_ddl_comment(second)
        swapped = projected.replace(comment, "", 1).replace(other, comment + other, 1)
        for broken in (swapped, projected.replace(comment, comment + comment, 1),
                       projected.replace(comment, comment.replace("## Rechte", "## Wrong"), 1)):
            with self.assertRaises(ValueError):
                usage_skills.project_clr_procedure_ddl(broken, first)
        # A raw CLR object must not pass the T-SQL-help guard adapter.
        with self.assertRaisesRegex(ValueError, "T-SQL"):
            usage_skills.project_procedure_help(projected, first)

    def test_complete_synthetic_module_emits_once_and_never_overwrites_output(self):
        original = samples()[1]
        metadata = deepcopy(original.metadata)
        metadata.update(module_id="toolbelt.fixture", object_type="CLR_USP", source_module_version="1.0.0")
        _, body = usage_skills.parse_frontmatter(original.markdown)
        sections = {key: body.split("## " + key + "\n", 1)[1].split("\n## ", 1)[0].strip()
                    for key in usage_skills.SECTIONS}
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            parser = root / "Scripts/Install/markerless_manifest.py"
            parser.parent.mkdir(parents=True)
            parser.write_bytes((ROOT / "Scripts/Install/markerless_manifest.py").read_bytes())
            module = root / "Modules/toolbelt.fixture"
            module.mkdir(parents=True)
            (module / "module.yaml").write_text(
                'module_id: "toolbelt.fixture"\nversion: "1.0.0"\nobjects:\n'
                '  - { type: CLR_USP, schema: toolbelt_core, name: USP_SecondSessionProbe, visibility: internal }\n'
                '  - { type: ASSEMBLY, name: tlblt_Fixture, visibility: internal }\n'
                'clr:\n  used: true\n  assembly_sql_name: "tlblt_Fixture"\n', encoding="utf-8")
            fixture = usage_skills.write(usage_skills.source_file(root, "toolbelt_core", "USP_SecondSessionProbe"),
                                         metadata, sections)
            output = root / "new/UsageSkillsGenerated.cs"
            self.assertEqual(clr_usage_skills.generate(root, "toolbelt.fixture", "Toolbelt.Fixture", output), 1)
            self.assertEqual(output.read_text(encoding="utf-8"), clr_usage_skills.render([fixture], "Toolbelt.Fixture"))
            before = output.read_bytes()
            with self.assertRaisesRegex(ValueError, "Neue CLR-Ausgabedatei"):
                clr_usage_skills.generate(root, "toolbelt.fixture", "Toolbelt.Fixture", output)
            self.assertEqual(output.read_bytes(), before)

    def test_module_generator_refuses_missing_or_draft_clr_skills_without_partial_output(self):
        expected = {key for key, value in usage_skills.inventory(ROOT).items()
                    if value["module_id"] == "toolbelt.filesystem.windows" and value["object_type"] == "CLR_USP"}
        self.assertTrue(expected)
        complete = True
        for _, schema, name in expected:
            path = usage_skills.source_file(ROOT, schema, name)
            if not path.is_file() or usage_skills.read(path, verified=False).metadata["review_status"] != "verified":
                complete = False
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "not-created" / "UsageSkillsGenerated.cs"
            if complete:
                self.assertEqual(clr_usage_skills.generate(ROOT, "toolbelt.filesystem.windows",
                                 "Toolbelt.Filesystem.Windows", output), len(expected))
            else:
                with self.assertRaises(ValueError):
                    clr_usage_skills.generate(ROOT, "toolbelt.filesystem.windows", "Toolbelt.Filesystem.Windows", output)
                self.assertFalse(output.parent.exists())

    def test_original_markdown_is_preserved_as_csharp_escaped_data(self):
        skill = samples()[0]
        text = skill.markdown + '\nÄ𐐀 O\'Brien "quoted" \\ /\n' * 1000
        source = clr_usage_skills.render([usage_skills.Skill(skill.metadata, text)])
        literal = re.search(r'markdown = ("(?:[^"\\]|\\.)*");', source)[1]
        self.assertEqual(json.loads(literal), text)
        self.assertNotIn("Ä", source)
        self.assertIn(r"\ud801\udc00", source)
        self.assertIn("SqlMetaData.Max", source)

    def test_generation_is_deterministic_and_has_exact_four_column_contract(self):
        current = samples()
        source = clr_usage_skills.render(current)
        self.assertEqual(source, clr_usage_skills.render(reversed(current)))
        self.assertEqual(source, clr_usage_skills.render(iter(current)))
        self.assertEqual(re.findall(r'new SqlMetaData\("(\w+)"', source),
                         ["SkillFormatVersion", "SchemaName", "ObjectName", "SkillMarkdown"])
        self.assertNotRegex(source, r"SqlConnection|SqlCommand|File\.|WebClient|HttpClient")
        self.assertIn('throw new ArgumentException("USAGE_SKILL_UNKNOWN_OBJECT")', source)

    def test_drafts_duplicates_functions_and_invalid_code_identifiers_are_rejected(self):
        current = samples()
        with self.assertRaisesRegex(ValueError, "Doppelte"):
            clr_usage_skills.render(current + current[:1])
        skill = current[0]
        metadata = deepcopy(skill.metadata)
        metadata["review_status"] = "draft"
        with self.assertRaisesRegex(ValueError, "Ungeprüfter"):
            clr_usage_skills.render([usage_skills.Skill(metadata, skill.markdown)])
        function = usage_skills.read(ROOT / "Metadata/UsageSkills/toolbelt_conversion/TVF_Base64Encode.md")
        with self.assertRaisesRegex(ValueError, "Prozedur"):
            clr_usage_skills.render([function])
        for namespace, name in (("Injected;class Bad", "Usage"), ("Toolbelt.Metadata", "X{}")):
            with self.assertRaises(ValueError):
                clr_usage_skills.render(current, namespace, name)


if __name__ == "__main__":
    if len(sys.argv) == 3 and sys.argv[1] == "--prepare-clr-record-fixture":
        prepare_record_fixture(Path(sys.argv[2]))
        print("CLR_RECORD_FIXTURE_READY; SQL_NOT_EXECUTED")
    elif len(sys.argv) == 3 and sys.argv[1] == "--prepare-clr-module-fixture":
        prepare_module_fixture(Path(sys.argv[2]))
        print("CLR_MODULE_FIXTURE_READY; SQL_NOT_EXECUTED; PROVIDER_NOT_INVOKED")
    else:
        unittest.main()
