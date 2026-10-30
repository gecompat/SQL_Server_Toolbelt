"""Offline integrity checks for the JSON Schema caller-transaction report."""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "json_schema_caller_transaction", ROOT / "Scripts/Release/json_schema_caller_transaction.py")
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class JsonSchemaCallerTransactionQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.record = json.loads((ROOT / gate.REPORT_PATH).read_bytes())

    def test_actual_report_binds_exact_scope_and_public_sources(self):
        record = gate.validate_record(ROOT)
        self.assertEqual(record["scope"]["target"]["patch"], "CU8")
        self.assertEqual(record["scope"]["start_session_profile"]["quoted_identifier"], "ON")
        self.assertEqual([item["operation"] for item in record["execution"]["cases"]], ["Deploy", "Uninstall"])
        self.assertEqual(record["execution"]["cases"][0]["witness_values"], [100, 200, 300, 300, 200, 100])
        self.assertEqual(len(record["inputs"]["source_pins"]), 63)

    def test_existing_release_suite_registers_the_gate(self):
        source = (ROOT / "Tests/Release/test_prepare_release.py").read_text(encoding="utf-8")
        self.assertIn("test_json_schema_caller_transaction_qualification import JsonSchemaCallerTransactionQualificationTests", source)
        self.assertIn("tests.addTests(loader.loadTestsFromTestCase(JsonSchemaCallerTransactionQualificationTests))", source)

    def _reject(self, record):
        with self.assertRaises(gate.QualificationError):
            gate.validate_record(ROOT, record)

    def test_target_session_profile_or_case_drift_is_rejected(self):
        for change in (
            lambda r: r["scope"]["target"].update(patch="base"),
            lambda r: r["scope"]["start_session_profile"].update(quoted_identifier="OFF"),
            lambda r: r["execution"]["cases"][0].update(expected_error_severity=17),
            lambda r: r["execution"]["cases"][1].update(witness_values=[100, 200, 300, 301, 200, 100]),
            lambda r: r["execution"]["cases"][0].update(caller_transaction_preserved=False),
        ):
            altered = copy.deepcopy(self.record)
            change(altered)
            self._reject(altered)

    def test_package_source_and_execution_drift_are_rejected(self):
        for change in (
            lambda r: r["inputs"]["package_qualification"].update(package_sha256="0" * 64),
            lambda r: r["inputs"]["source_pins"].update({".runtime/private.json": "0" * 64}),
            lambda r: r["inputs"]["source_pins"].update({
                "Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1": "0" * 64}),
            lambda r: r["execution"].update(failed_cleaned_attempts=0),
            lambda r: r["execution"]["final_independent_audit"].update(owned_database_absent=False),
        ):
            altered = copy.deepcopy(self.record)
            change(altered)
            self._reject(altered)


if __name__ == "__main__":
    unittest.main()
