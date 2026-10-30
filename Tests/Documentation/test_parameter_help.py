"""Complete manifest/signature/notes coupling and closed Help-only delta tests."""
from pathlib import Path
import copy
import json
import sys
import unittest
from unittest import mock

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Documentation"))
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import generate_parameter_help as generator
import parameter_help_transition as transition


class ParameterHelp(unittest.TestCase):
    def test_all_public_usps_have_every_exact_parameter_description(self):
        self.assertEqual(generator.generate(), 73)
        notes = generator.parameter_notes()
        files = transition.ssis_files(ROOT)
        prefix = ROOT / "Modules/toolbelt.tsql.ssis-debug"
        for path, content in files.items():
            self.assertEqual((prefix / path).read_text(encoding="utf-8"), content, path)
        api = json.loads(files["Contracts/Api.json"])
        for p in api["parameters"]:
            self.assertEqual(p["description"], notes["toolbelt_tsql.USP_ExplainSsisDataFlow"]["parameter_notes"][p["name"]])
        public = [i for i in generator.catalog.objects(ROOT) if i["type"] == "USP"]
        self.assertEqual(len(public), 74)
        self.assertEqual(sum(len(generator.catalog.signature(i)[1]) for i in public), 670)

    def test_business_sources_are_unchanged_outside_generated_help(self):
        for path in transition.snapshot(ROOT):
            with self.subTest(path=path):
                transition.predecessor_source(ROOT, path)

    def test_changed_business_body_and_noncanonical_help_are_rejected(self):
        path = "Modules/toolbelt.core.execution-context/Source/USP_BeginExecution.sql"
        target = ROOT / path
        original = Path.read_bytes
        for delta in (b"\n-- changed outside help\n", None):
            def read(p):
                data = original(p)
                if p == target:
                    return data + delta if delta else data.replace(b"API_PARAMETER_HELP:BEGIN", b"API_PARAMETER_HELP:WRONG", 1)
                return data
            with self.subTest(delta=delta), mock.patch.object(Path,"read_bytes",read), self.assertRaises(ValueError):
                transition.predecessor_source(ROOT,path)

    def test_historical_verifiers_accept_only_the_exact_reviewed_read_adapters(self):
        pins = transition.verifier_pins()
        for path in transition.VERIFIER_PATHS:
            with self.subTest(path=path):
                original = transition.restore_verifier_source(ROOT,path)
                self.assertEqual(__import__("hashlib").sha256(original).hexdigest(),pins[path]["before"])
                with self.assertRaises(ValueError):
                    transition.restore_verifier_source(ROOT,path,(ROOT/path).read_bytes()+b"\n# changed oracle\n")

    def test_missing_extra_or_invalid_parameter_metadata_is_rejected(self):
        item = next(i for i in generator.catalog.objects(ROOT) if i["name"] == "USP_BeginExecution")
        _, params = generator.catalog.signature(item)
        key = item["schema"] + "." + item["name"]
        metadata = json.loads((ROOT / generator.METADATA).read_text(encoding="utf-8"))[key]
        for mode in ("missing", "extra", "invalid"):
            changed = copy.deepcopy(metadata)
            if mode == "missing": changed["parameters"].pop("@Hilfe")
            elif mode == "extra": changed["parameters"]["@Unknown"] = [False, True]
            else: changed["parameters"]["@Hilfe"] = [0, True]
            with self.subTest(mode=mode), self.assertRaises(ValueError):
                generator.help_rows(item, params, changed, generator.parameter_notes())

    def test_unicode_quotes_and_long_descriptions_keep_max_from_first_operand(self):
        literal = generator.literal("ä'😀" * 2001)
        self.assertTrue(literal.startswith("CAST(N'"))
        self.assertIn(" AS nvarchar(max)) + N'", literal)
        self.assertIn("ä''😀", literal)
        pieces = []
        for match in __import__("re").finditer(r"N'((?:[^']|'')*)'", literal):
            piece = match[1].replace("''", "'")
            self.assertLessEqual(len(piece.encode("utf-16-le")) // 2, 2000)
            pieces.append(piece)
        self.assertEqual("".join(pieces), "ä'😀" * 2001)

    def test_branch_matching_ignores_quoted_begin_end_and_nested_case(self):
        text = "CREATE OR ALTER PROCEDURE x.USP_Demo @Hilfe bit=0 AS BEGIN IF @Hilfe=1 BEGIN SELECT N'END BEGIN', CASE WHEN 1=1 THEN N'CASE' END; RETURN; END; SELECT 1; END"
        a, b = generator.help_span(text, {"name": "USP_Demo"})
        self.assertEqual(text[a:b], " SELECT N'END BEGIN', CASE WHEN 1=1 THEN N'CASE' END; RETURN; ")


if __name__ == "__main__": unittest.main()
