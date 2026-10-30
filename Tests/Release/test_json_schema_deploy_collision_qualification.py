"""Offline integrity checks for the JSON Schema deploy-collision record."""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    "json_schema_deploy_collision", ROOT / "Scripts/Release/json_schema_deploy_collision.py")
gate = importlib.util.module_from_spec(spec)
spec.loader.exec_module(gate)


class JsonSchemaDeployCollisionQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.record = json.loads((ROOT / gate.REPORT_PATH).read_bytes())

    def test_actual_record_binds_one_target_four_rejections_and_one_control(self):
        record = gate.validate_record(ROOT)
        self.assertEqual(record["scope"]["target"], {
            "platform": "windows", "sql_server_version": "2025", "patch": "CU8",
            "compatibility_level": 170,
        })
        cases = record["execution"]["cases"]
        self.assertEqual([item["kind"] for item in cases], [
            "reserved_temp", "public_slot", "internal_slot", "orphan_mode",
        ])
        self.assertEqual([item["expected_error_number"] for item in cases], [55633, 55634, 55634, 55634])
        self.assertEqual(record["execution"]["target_invocations"], 1)
        self.assertEqual(record["execution"]["positive_control"]["count"], 1)
        self.assertEqual(len(record["inputs"]["source_pins"]), gate.PIN_COUNT)

    def _reject(self, record):
        with self.assertRaises(gate.QualificationError):
            gate.validate_record(ROOT, record)

    def test_scope_case_and_positive_control_drift_are_rejected(self):
        for change in (
            lambda r: r["scope"]["target"].update(patch="base"),
            lambda r: r["execution"]["cases"][1].update(expected_error_number=55633),
            lambda r: r["execution"]["cases"][3].update(fixture_removed=False),
            lambda r: r["execution"]["positive_control"].update(schema_installed=False),
        ):
            altered = copy.deepcopy(self.record)
            change(altered)
            self._reject(altered)

    def test_package_and_public_source_pin_drift_are_rejected(self):
        changes = (
            lambda r: r["inputs"]["package_qualification"].update(package_sha256="0" * 64),
            lambda r: r["inputs"]["source_pins"].update({".runtime/private.json": "0" * 64}),
            lambda r: r["inputs"]["source_pins"].update({
                "Tests/Release/Invoke-JsonSchemaDeployCollisionLab.ps1": "0" * 64,
            }),
        )
        for change in changes:
            altered = copy.deepcopy(self.record)
            change(altered)
            self._reject(altered)

    def test_execution_audit_and_publication_boundary_are_rejected_on_drift(self):
        for change in (
            lambda r: r["execution"].update(failed_cleaned_attempts=1),
            lambda r: r["execution"]["final_independent_audit"].update(owned_database_absent=False),
            lambda r: r.update(publication_authorized=True),
        ):
            altered = copy.deepcopy(self.record)
            change(altered)
            self._reject(altered)

    def test_existing_release_suite_registers_the_record_gate(self):
        source = (ROOT / "Tests/Release/test_prepare_release.py").read_text(encoding="utf-8")
        self.assertIn(
            "test_json_schema_deploy_collision_qualification import JsonSchemaDeployCollisionQualificationTests",
            source,
        )
        self.assertIn(
            "tests.addTests(loader.loadTestsFromTestCase(JsonSchemaDeployCollisionQualificationTests))",
            source,
        )


if __name__ == "__main__":
    unittest.main()
