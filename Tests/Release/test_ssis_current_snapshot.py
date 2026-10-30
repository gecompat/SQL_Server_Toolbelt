"""Bounded evidence checks for current SSIS DebugScript snapshot coherence; no SQL."""
from __future__ import annotations

import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import new_ssis_current_package as package
import validate_ssis_current_snapshot as snapshot
from new_ssis_standalone_tsql import read_regular_bounded


class CurrentSnapshotEvidence(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.package_report_bytes = read_regular_bounded(ROOT / snapshot.PACKAGE_REPORT, 1024 * 1024)
        cls.native_report_bytes = read_regular_bounded(ROOT / snapshot.NATIVE_REPORT, 2 * 1024 * 1024)
        cls.package_report = json.loads(cls.package_report_bytes)
        cls.native_report = json.loads(cls.native_report_bytes)
        cls.package_sha = package.sha(read_regular_bounded(snapshot.PACKAGE, snapshot.MAX_PACKAGE_BYTES))
        cls.package_report_sha = package.sha(cls.package_report_bytes)
        cls.native_report_sha = package.sha(cls.native_report_bytes)
        cls.source_bindings = snapshot._current_source_bindings()

    def record(self):
        return snapshot._expected_record(
            self.package_sha, self.package_report_sha, self.native_report_sha,
            copy.deepcopy(self.source_bindings))

    def test_committed_record_and_package_qualification(self):
        self.assertTrue(snapshot.validate())

    def test_exact_case_values_and_batch_coherence(self):
        record = self.record()
        self.assertTrue(snapshot.validate_record(
            record, actual_source_bindings=self.source_bindings,
            package_report=self.package_report, native_report=self.native_report))
        self.assertEqual([case["deployment_mode"] for case in record["cases"]], ["local", "central"])
        self.assertEqual(record["execution"]["total_assertions"], 544)

    def test_fixture_line_endings_reuse_exact_reversible_checkout_binding(self):
        path = ROOT / snapshot.FIXTURE
        checkout = read_regular_bounded(path, 64 * 1024 * 1024)
        lf = checkout.replace(b"\r\n", b"\n")
        crlf = lf.replace(b"\n", b"\r\n")
        execution, integrated = snapshot.FIXTURE_EXECUTION_SHA256, snapshot.FIXTURE_INTEGRATED_SHA256
        self.assertEqual(package.sha(crlf), execution)
        self.assertEqual(package.sha(lf), integrated)
        self.assertEqual(snapshot._source_checkout_sha(snapshot.FIXTURE, crlf), execution)
        self.assertEqual(snapshot._source_checkout_sha(snapshot.FIXTURE, lf), execution)
        record = self.record()
        self.assertEqual(record["execution"]["source_bindings"][snapshot.FIXTURE], execution)
        self.assertEqual(record["integration_binding"], snapshot.FIXTURE_CHECKOUT_BINDING)

    def test_fixture_bridge_rejects_mixed_edited_and_unbound_line_endings(self):
        checkout = read_regular_bounded(ROOT / snapshot.FIXTURE, 64 * 1024 * 1024)
        lf = checkout.replace(b"\r\n", b"\n")
        mixed = lf.replace(b"\n", b"\r\n", 1)
        for changed in (mixed, lf + b"synthetic-change"):
            with self.subTest(size=len(changed)), self.assertRaisesRegex(ValueError, "exact row-count fixture checkout transformation"):
                snapshot._source_checkout_sha(snapshot.FIXTURE, changed)
        other_path_bytes = b"line1\nline2\r\n"
        self.assertEqual(snapshot._source_checkout_sha(
            "Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-CurrentCases.ps1",
            other_path_bytes), package.sha(other_path_bytes))

    def test_fixture_bridge_record_rejects_wrong_digest_path_or_transform(self):
        for mutate in (
            lambda r: r["integration_binding"]["changes"][0].update(path="unsupported/fixture.dtsx"),
            lambda r: r["integration_binding"]["changes"][0].update(execution_sha256="0" * 64),
            lambda r: r["integration_binding"]["changes"][0].update(integrated_sha256="0" * 64),
            lambda r: r["integration_binding"]["changes"][0].update(transform="generic-normalization"),
            lambda r: r["integration_binding"]["changes"].append(copy.deepcopy(r["integration_binding"]["changes"][0])),
        ):
            changed = self.record()
            mutate(changed)
            with self.assertRaisesRegex(ValueError, "snapshot qualification.integration_binding"):
                snapshot.validate_record(changed, actual_source_bindings=self.source_bindings,
                                         package_report=self.package_report, native_report=self.native_report)

    def test_python_bool_integer_and_float_coercions_are_rejected(self):
        mutations = (
            (lambda r: r["cases"][0].update(compatibility_level=True), "compatibility_level type"),
            (lambda r: r["cases"][0].update(assertions=272.0), "assertions type"),
            (lambda r: r["cases"][0]["first_materialized_snapshot"].update(row_count_bigint=True),
             "row_count_bigint type"),
            (lambda r: r["cases"][0].update(fresh_debug_sessions=True), "fresh_debug_sessions type"),
            (lambda r: r["execution"].update(total_assertions=544.0), "total assertions type"),
            (lambda r: r["execution"]["attempt_history"].update(target_invocations=True), "attempt count type"),
            (lambda r: r["execution"]["attempt_history"].update(recovery_required_target_attempts=False), "recovery_required_target_attempts type"),
            (lambda r: r["execution"]["attempt_history"].update(total_process_attempts=True), "total_process_attempts type"),
            (lambda r: r["final_audit"].update(input_pins_unchanged=1), "snapshot qualification.final_audit.input_pins_unchanged type"),
            (lambda r: r.update(publication_authorized=0), "snapshot qualification.publication_authorized type"),
        )
        for mutate, expected in mutations:
            changed = self.record()
            mutate(changed)
            with self.subTest(expected=expected), self.assertRaisesRegex(ValueError, expected.replace(".", r"\.")):
                snapshot.validate_record(changed, actual_source_bindings=self.source_bindings,
                                         package_report=self.package_report, native_report=self.native_report)

    def test_source_pin_closure_and_package_provenance_are_strict(self):
        for mutate, expected in (
            (lambda r: r["execution"]["source_bindings"].pop(next(iter(r["execution"]["source_bindings"]))),
             "public source pin closure"),
            (lambda r: r["execution"]["source_bindings"].update({".runtime/private.json": "A" * 64}),
             "public source pin closure"),
            (lambda r: r["package_qualification"].update(package_sha256="0" * 64),
             "snapshot qualification.package_qualification.package_sha256 value"),
            (lambda r: r["cases"][0].update(source_insert_after_materialization_before_first_read=False),
             "source_insert_after_materialization_before_first_read value"),
        ):
            changed = self.record()
            mutate(changed)
            with self.subTest(expected=expected), self.assertRaisesRegex(ValueError, expected.replace(".", r"\.")):
                snapshot.validate_record(changed, actual_source_bindings=self.source_bindings,
                                         package_report=self.package_report, native_report=self.native_report)

    def test_duplicate_json_properties_are_rejected(self):
        with self.assertRaisesRegex(ValueError, "duplicate key"):
            snapshot._load_json(b'{"result":"PASS","result":"FAIL"}', "synthetic")


if __name__ == "__main__":
    unittest.main()
