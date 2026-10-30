"""Offline integrity controls for the JSON Schema uninstall AppLock record."""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys_path = ROOT / "Scripts/Release/json_schema_uninstall_applock.py"
spec = importlib.util.spec_from_file_location("json_schema_uninstall_applock", sys_path)
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class JsonSchemaUninstallAppLockQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.record = json.loads((ROOT / gate.REPORT_PATH).read_bytes())

    def test_actual_public_record_and_current_sources_are_bound(self):
        record = gate.validate_record(ROOT)
        self.assertEqual(record["scope"]["operation"], "Uninstall")
        self.assertEqual(record["scope"]["target"]["patch"], "CU8")
        self.assertEqual(record["execution"]["source_commit"], gate.EXPECTED_SOURCE_COMMIT)
        self.assertEqual(record["execution"]["native_target_invocations"], 1)
        self.assertEqual(record["execution"]["independent_audits"], 1)

    def test_existing_release_suite_registers_this_gate(self):
        source = (ROOT / "Tests/Release/test_prepare_release.py").read_text(encoding="utf-8")
        self.assertIn("from test_json_schema_uninstall_applock_qualification import JsonSchemaUninstallAppLockQualificationTests", source)
        self.assertIn("tests.addTests(loader.loadTestsFromTestCase(JsonSchemaUninstallAppLockQualificationTests))", source)

    def _reject(self, record):
        with self.assertRaises(gate.QualificationError):
            gate.validate_record(ROOT, record)

    def test_target_case_and_cleanup_drift_are_rejected(self):
        altered = copy.deepcopy(self.record)
        altered["scope"]["target"]["patch"] = "base"
        self._reject(altered)
        altered = copy.deepcopy(self.record)
        altered["execution"]["cases"][0]["positive_control_uninstall_succeeded"] = False
        self._reject(altered)
        altered = copy.deepcopy(self.record)
        altered["execution"]["cases"][1]["schema_namespace_retained"] = False
        self._reject(altered)
        altered = copy.deepcopy(self.record)
        altered["execution"]["final_independent_audit"]["owned_trust_restored"] = False
        self._reject(altered)

    def test_package_and_public_source_drift_are_rejected(self):
        altered = copy.deepcopy(self.record)
        altered["inputs"]["package_qualification"]["package_sha256"] = "0" * 64
        self._reject(altered)
        altered = copy.deepcopy(self.record)
        altered["inputs"]["source_pins"]["Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1"] = "0" * 64
        self._reject(altered)
        altered = copy.deepcopy(self.record)
        altered["inputs"]["source_pins"][".runtime/private.json"] = "0" * 64
        self._reject(altered)


if __name__ == "__main__":
    unittest.main()
