"""Offline integrity checks for the central JSON Schema uninstall report."""
from __future__ import annotations

import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]

sys.path.insert(0, str(ROOT / "Scripts/Release"))
import json_schema_uninstall_confirmation as gate


class JsonSchemaUninstallConfirmationQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.record = json.loads((ROOT / gate.REPORT_PATH).read_bytes())

    def test_actual_record_binds_the_narrow_central_scope(self):
        record = gate.validate_record(ROOT)
        self.assertEqual(record["scope"]["target"]["patch"], "CU8")
        self.assertEqual(record["scope"]["deployment_mode"], "central")
        self.assertEqual(record["scope"]["start_session_profile"]["quoted_identifier"], "ON")
        self.assertEqual([case["confirmation"] for case in record["execution"]["cases"]], ["01", "0"])
        self.assertEqual(len(record["inputs"]["source_pins"]), 60)

    def test_exact_rejections_and_positive_uninstall_are_bound(self):
        checked = gate.validate_record(ROOT)
        cases = checked["execution"]["cases"]
        self.assertEqual([case["expected_error_number"] for case in cases], [55635, 55635])
        self.assertEqual([case["expected_error_state"] for case in cases], [1, 1])
        self.assertTrue(all(case["exact_error_message_matched"] and case["module_unchanged"]
                            and case["core_unchanged"] and case["transaction_unchanged"] for case in cases))
        self.assertEqual(checked["execution"]["positive_control"]["confirmation"], "1")
        self.assertTrue(checked["execution"]["positive_control"]["namespace_retained"])

    def _reject(self, record):
        with self.assertRaises(gate.QualificationError):
            gate.validate_record(ROOT, record)

    def test_scope_oracle_and_audit_drift_fail_closed(self):
        for change in (
            lambda r: r["scope"]["target"].update(patch="base"),
            lambda r: r["scope"]["start_session_profile"].update(transaction_count=False),
            lambda r: r["scope"]["start_session_profile"].update(transaction_count=0.0),
            lambda r: r["scope"].update(deployment_mode="local"),
            lambda r: r["execution"]["cases"][0].update(ordinal=False),
            lambda r: r["execution"]["cases"][0].update(expected_message="different"),
            lambda r: r["execution"]["cases"][1].update(expected_error_state=True),
            lambda r: r["execution"]["cases"][1].update(transaction_unchanged=False),
            lambda r: r["execution"]["positive_control"].update(namespace_retained=False),
            lambda r: r["execution"]["positive_control"].update(uninstall_succeeded=1),
            lambda r: r["execution"]["final_independent_audit"].update(complete_attempt=1),
            lambda r: r["execution"]["final_independent_audit"].update(owned_database_absent=False),
        ):
            altered = copy.deepcopy(self.record)
            change(altered)
            self._reject(altered)

    def test_private_paths_unexpected_pins_and_source_drift_fail_closed(self):
        for change in (
            lambda r: r["inputs"]["source_pins"].update({".runtime/private.json": "0" * 64}),
            lambda r: r["inputs"]["source_pins"].update({"Tests/Release/Invoke-JsonSchemaUninstallConfirmationLab.ps1": "0" * 64}),
            lambda r: r["inputs"]["package_qualification"].update(package_sha256="0" * 64),
            lambda r: r["execution"].update(failed_cleaned_attempts=0),
        ):
            altered = copy.deepcopy(self.record)
            change(altered)
            self._reject(altered)

    def test_existing_release_suite_registers_report_guard_locally(self):
        source = (ROOT / "Tests/Release/test_prepare_release.py").read_text(encoding="utf-8")
        self.assertIn("test_json_schema_uninstall_confirmation_qualification import JsonSchemaUninstallConfirmationQualificationTests", source)
        self.assertIn("tests.addTests(loader.loadTestsFromTestCase(JsonSchemaUninstallConfirmationQualificationTests))", source)


if __name__ == "__main__":
    unittest.main()
