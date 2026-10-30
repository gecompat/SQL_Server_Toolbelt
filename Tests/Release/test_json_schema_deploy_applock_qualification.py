"""Offline integrity controls for the JSON Schema deployment AppLock record."""
from __future__ import annotations

import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import json_schema_deploy_applock as gate


class JsonSchemaDeployAppLockQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.record = json.loads((ROOT / gate.REPORT_PATH).read_bytes())

    def test_actual_public_record_and_current_sources_are_bound(self):
        record = gate.validate_record(ROOT)
        self.assertEqual(record["execution"]["cases"][0]["resource"], gate.EXPECTED_RESOURCES[0])
        self.assertEqual(record["execution"]["cases"][1]["resource"], gate.EXPECTED_RESOURCES[1])
        self.assertEqual(record["execution"]["failed_cleaned_attempts"], 5)
        self.assertEqual(record["execution"]["independent_audits"], 6)

    def test_existing_release_suite_registers_this_gate(self):
        source = (ROOT / "Tests/Release/test_prepare_release.py").read_text(encoding="utf-8")
        self.assertIn("from test_json_schema_deploy_applock_qualification import JsonSchemaDeployAppLockQualificationTests", source)
        self.assertIn("tests.addTests(loader.loadTestsFromTestCase(JsonSchemaDeployAppLockQualificationTests))", source)

    def _reject(self, record):
        with self.assertRaises(gate.QualificationError):
            gate.validate_record(ROOT, record)

    def test_scope_and_outcome_drift_are_rejected(self):
        cases = []
        altered = copy.deepcopy(self.record)
        altered["scope"]["resources"].reverse()
        cases.append(altered)
        altered = copy.deepcopy(self.record)
        altered["scope"]["target"]["patch"] = "base"
        cases.append(altered)
        altered = copy.deepcopy(self.record)
        altered["execution"]["cases"].pop()
        cases.append(altered)
        altered = copy.deepcopy(self.record)
        altered["execution"]["cases"][0]["positive_control_after_release"] = False
        cases.append(altered)
        altered = copy.deepcopy(self.record)
        altered["execution"]["cases"][0]["exact_block_message_matched"] = False
        cases.append(altered)
        altered = copy.deepcopy(self.record)
        altered["execution"]["failed_cleaned_attempts"] = 4
        cases.append(altered)
        altered = copy.deepcopy(self.record)
        altered["execution"]["final_independent_audit"]["owned_database_absent"] = False
        cases.append(altered)
        for index, case in enumerate(cases):
            with self.subTest(record=index):
                self._reject(case)

    def test_package_and_source_drift_are_rejected(self):
        altered = copy.deepcopy(self.record)
        altered["inputs"]["package_qualification"]["sha256"] = "0" * 64
        self._reject(altered)
        altered = copy.deepcopy(self.record)
        altered["inputs"]["source_pins"]["Tests/Release/Invoke-JsonSchemaAppLockLab.ps1"] = "0" * 64
        self._reject(altered)
        altered = copy.deepcopy(self.record)
        altered["inputs"]["source_pins"][".runtime/private.json"] = "0" * 64
        self._reject(altered)


if __name__ == "__main__":
    unittest.main()
