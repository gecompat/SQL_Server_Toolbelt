"""Vor-SQL-Gegenproben des vollständigen aktuellen SSIS-Testwegs."""
from __future__ import annotations

import hashlib
import copy
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "Modules/toolbelt.tsql.ssis-debug/Tests/Runtime"
PWSH = shutil.which("pwsh")
SPEC = importlib.util.spec_from_file_location("ssis_current_functional", ROOT / "Scripts/Release/validate_ssis_current_functional.py")
functional = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(functional)


@unittest.skipUnless(PWSH, "PowerShell 7 erforderlich; keine SQL-Verbindung")
class InputGuards(unittest.TestCase):
    def setUp(self):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=ROOT / ".runtime")
        self.directory = Path(self.temporary.name)
        self.files = []
        for path in sorted(RUNTIME.glob("*.ps1")):
            self.files.append({"path": path.relative_to(ROOT).as_posix(),
                               "sha256": hashlib.sha256(path.read_bytes()).hexdigest().upper()})

    def tearDown(self):
        self.temporary.cleanup()

    def invoke(self, files):
        manifest = self.directory / "inputs.json"
        manifest.write_text(json.dumps({"schemaVersion": 1, "profile": "ssis-debug-current",
                                        "files": files}), encoding="utf-8")
        arguments = [PWSH, "-NoProfile", "-File", str(RUNTIME / "Invoke-CurrentQualificationLab.ps1"),
                     "-Version", "2019", "-Patch", "base", "-Mode", "local",
                     "-CompatibilityLevel", "150", "-JournalDirectory", str(self.directory / "unused"),
                     "-ExpectedTargetKey", "synthetic", "-ExpectedContractSha256", "0" * 64,
                     "-SsisReleaseDirectory", "synthetic", "-ParserReleaseDirectory", "synthetic",
                     "-QualifiedProviderSha512", "0" * 128, "-CasesExpectedSha256",
                     hashlib.sha256((RUNTIME / "Invoke-CurrentQualificationAllCases.ps1").read_bytes()).hexdigest().upper(),
                     "-InputManifestPath", str(manifest), "-ExpectedInputManifestSha256",
                     hashlib.sha256(manifest.read_bytes()).hexdigest().upper(), "-ValidateOnly"]
        result = subprocess.run(arguments, cwd=ROOT, capture_output=True, text=True, timeout=30)
        self.assertFalse((self.directory / "unused").exists(), "ValidateOnly darf kein SQL-Journal anlegen")
        return result

    def test_complete_transitive_inputs_without_sql(self):
        result = self.invoke(self.files)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("SSIS_CURRENT_LAB_ADAPTER_VALIDATED; no SQL", result.stdout)

    def test_missing_semantic_oracle_is_rejected_before_sql(self):
        result = self.invoke([item for item in self.files if not item["path"].endswith("Invoke-ComponentsV2ExpressionCases.ps1")])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SSIS_CURRENT_QUALIFICATION_TRANSITIVE_INPUT_MISSING", result.stderr)

    def test_changed_input_is_rejected_before_sql(self):
        self.files[0]["sha256"] = "0" * 64
        result = self.invoke(self.files)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SSIS_CURRENT_EXECUTION_INPUT_CHANGED", result.stderr)

    def test_duplicate_input_is_rejected_before_sql(self):
        result = self.invoke(self.files + [dict(self.files[0])])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SSIS_CURRENT_INPUT_PATH", result.stderr)

    def test_escape_is_rejected_before_sql(self):
        result = self.invoke(self.files + [{"path": "../synthetic", "sha256": "0" * 64}])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SSIS_CURRENT_INPUT_PATH", result.stderr)


class EvidenceGuards(unittest.TestCase):
    def setUp(self):
        self.record = {"schema_version": "1.0", "kind": "ssis_current_functional_qualification",
                       "result": "PASS", "publication_authorized": False,
                       "functional_scope_complete": True, "scope": "current_supported_debug_contract",
                       "gates": {gate: "PASS" for gate in functional.GATES},
                       "authenticated_tls": "not executed",
                       "long_plan": {"groups": 64, "minimum_units": 17, "typed_rows": 6,
                                     "output_limit_bytes": 134217728, "limits_overridden": False},
                       "offline_framework": {"profile": "Full", "bounded_children": 26, "result": "PASS"},
                       "ssis_runtime_parity": "not applicable to debug contract", "cases": []}
        for version, level, mode in sorted(functional.EXPECTED_CONTEXTS):
            self.record["cases"].append({"sql_version": version, "compatibility_level": level,
                                         "deployment_mode": mode, "result": "PASS", "cleanup_audit": "PASS",
                                         "input_pins_unchanged": True, "current_assertions": 206,
                                         "long_plan_default_budget": level == 170,
                                         "semantic_assertions": 1, "api_assertions": 1,
                                         "rights_assertions": 1, "lifecycle_assertions": 1})

    def verify(self):
        return functional.validate(ROOT, self.record, check_files=False)

    def test_complete_fixed_scope(self):
        self.verify()

    def test_missing_context(self):
        self.record["cases"].pop()
        with self.assertRaisesRegex(ValueError, "CONTEXT_MATRIX"):
            self.verify()

    def test_duplicate_context(self):
        self.record["cases"].append(copy.deepcopy(self.record["cases"][0]))
        with self.assertRaisesRegex(ValueError, "DUPLICATE_CASE"):
            self.verify()

    def test_boolean_is_not_an_assertion_count(self):
        self.record["cases"][0]["semantic_assertions"] = True
        with self.assertRaisesRegex(ValueError, "ASSERTION_COUNT"):
            self.verify()

    def test_failed_audit_cannot_be_pass(self):
        self.record["cases"][0]["cleanup_audit"] = "FAILED"
        with self.assertRaisesRegex(ValueError, "CASE_RESULT"):
            self.verify()

    def test_missing_gate(self):
        self.record["gates"].pop("caller_rights")
        with self.assertRaisesRegex(ValueError, "GATES"):
            self.verify()

    def test_no_publication_authority(self):
        self.record["publication_authorized"] = True
        with self.assertRaisesRegex(ValueError, "AUTHORITY_SCOPE"):
            self.verify()

    def test_duplicate_json_key(self):
        with self.assertRaisesRegex(ValueError, "DUPLICATE_JSON_KEY"):
            json.loads('{"result":"FAIL","result":"PASS"}', object_pairs_hook=functional.unique)

    def test_integer_cannot_disable_long_plan_override(self):
        self.record["long_plan"]["limits_overridden"] = 0
        with self.assertRaisesRegex(ValueError, "LONG_PLAN_TYPES"):
            self.verify()

    def test_executed_record_and_current_source_bindings(self):
        self.assertEqual(len(functional.validate(ROOT)["cases"]), 12)

    def test_missing_runtime_source_cannot_reuse_record(self):
        record = json.loads((ROOT / functional.REPORT).read_text(encoding="utf-8"))
        record["source_sha256"].pop(next(key for key in record["source_sha256"] if key.endswith("Invoke-CurrentQualificationCases.ps1")))
        with self.assertRaisesRegex(ValueError, "SOURCE_CLOSURE"):
            functional.validate(ROOT, record)

    def test_omitted_historical_evidence_is_rejected(self):
        record = json.loads((ROOT / functional.REPORT).read_text(encoding="utf-8"))
        record["reused_evidence"].pop()
        with self.assertRaisesRegex(ValueError, "REUSE_CLOSURE"):
            functional.validate(ROOT, record)

    def test_wrong_delivered_binary_is_rejected(self):
        record = json.loads((ROOT / functional.REPORT).read_text(encoding="utf-8"))
        record["current_delivery"]["assembly_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "DELIVERED_BINARY_BINDING"):
            functional.validate(ROOT, record)


if __name__ == "__main__":
    (ROOT / ".runtime").mkdir(exist_ok=True)
    unittest.main()
