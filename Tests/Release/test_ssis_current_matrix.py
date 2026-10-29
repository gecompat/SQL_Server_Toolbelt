"""Offline checks for exact current SSIS install-package matrix composition."""
import contextlib
import copy
import io
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import new_ssis_current_package as composer
import validate_ssis_current_matrix as matrix_guard
from new_ssis_standalone_tsql import read_regular_bounded, MAX_PACKAGE_BYTES


class CurrentInstallPackageMatrix(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original_bytes = read_regular_bounded(ROOT / matrix_guard.ORIGINAL_REPORT, 1024 * 1024)
        cls.original = json.loads(cls.original_bytes)
        cls.package_sha = cls.original["package_sha256"]
        cls.package_path = matrix_guard.PACKAGE_ARCHIVE
        cls.package_bytes = read_regular_bounded(cls.package_path, MAX_PACKAGE_BYTES)
        cls.package_payload = matrix_guard._package_payload(cls.package_bytes)
        baseline_keys = {("2019", 150, "local"), ("2025", 170, "central")}
        cls.expected = matrix_guard._matrix()
        cls.additional = cls.expected - baseline_keys

    def _case(self, key):
        version, level, mode = key
        return {"platform": "windows", "sql_version": version, "compatibility_level": level,
                "deployment_mode": mode, "result": "PASS", "assertions": 206,
                "fresh_repeat_uninstall_and_absent_repeat": True,
                "exact_extracted_sql_via_direct_sqlclient": True, "final_independent_audit": "PASS"}

    def _record(self):
        original_cases = {matrix_guard._case_key(case): case for case in self.original["cases"]}
        cases = dict(original_cases)
        cases.update({key: self._case(key) for key in self.additional})
        binding_paths = {
            "assembly_sha256": "Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.dll",
            "deploy_sql_sha256": "Modules/toolbelt.tsql.ssis-debug/Artifacts/Deploy.WithAssembly.sql",
            "uninstall_sql_sha256": "Modules/toolbelt.tsql.ssis-debug/Artifacts/Uninstall.Expanded.sql",
            "trust_manifest_sha256": "Modules/toolbelt.tsql.ssis-debug/Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json",
            "cases_sha256": matrix_guard.CURRENT_CASES,
            "protected_lab_driver_sha256": matrix_guard.PROTECTED_LAB_DRIVER,
        }
        artifact_bindings = {key: composer.sha(self.package_payload[path]) for key, path in binding_paths.items()}
        return {
            "schema_version": "1.0",
            "date": "2026-10-29",
            "kind": "ssis_current_install_package_matrix_qualification",
            "profile": "ssis-debug-current",
            "result": "PASS",
            "publication_authorized": False,
            "package_sha256": self.package_sha,
            "original_package_qualification": {
                "path": matrix_guard.ORIGINAL_REPORT,
                "sha256": matrix_guard.ORIGINAL_REPORT_SHA256,
                "package_sha256": self.package_sha,
            },
            "additional_cases": [self._case(key) for key in sorted(self.additional)],
            "cases": [cases[key] for key in sorted(cases)],
            "artifact_bindings": artifact_bindings,
            "final_audit": {"case_audits": 10, "owned_database_names_absent": 20,
                            "trust_states_restored": 30, "configuration_baselines_restored": True,
                            "input_pins_unchanged": True},
        }

    def test_valid_exact_matrix_composition(self):
        self.assertTrue(matrix_guard.validate_record(self._record(), self.original, self.package_sha, self.package_payload))

    def test_wrong_source_package_or_publication_claim_is_rejected(self):
        for name, mutate, reason in (
            ("original report", lambda r: r["original_package_qualification"].update(sha256="0" * 64), "original package qualification pin"),
            ("original report path", lambda r: r["original_package_qualification"].update(path="unsupported/report.json"), "original package qualification pin"),
            ("current ZIP", lambda r: r.update(package_sha256="0" * 64), "qualified current package SHA-256"),
            ("publication", lambda r: r.update(publication_authorized=True), "matrix record identity"),
        ):
            changed = self._record()
            mutate(changed)
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, reason):
                matrix_guard.validate_record(changed, self.original, self.package_sha, self.package_payload)

    def test_missing_duplicate_or_failed_additional_case_is_rejected(self):
        for name, mutate, reason in (
            ("missing", lambda r: r["additional_cases"].pop(), "additional ten-case matrix"),
            ("duplicate", lambda r: r["additional_cases"].append(copy.deepcopy(r["additional_cases"][0])), "additional cases duplicates"),
            ("audit", lambda r: r["additional_cases"][0].update(final_independent_audit="FAIL"), "additional cases audits"),
            ("mode", lambda r: r["additional_cases"][0].update(deployment_mode="other"), "case identity values"),
        ):
            changed = self._record()
            mutate(changed)
            with self.subTest(name=name), self.assertRaisesRegex(ValueError, reason):
                matrix_guard.validate_record(changed, self.original, self.package_sha, self.package_payload)

    def test_frozen_zip_artifact_bindings_are_not_replaceable(self):
        changed = self._record()
        changed["artifact_bindings"]["protected_lab_driver_sha256"] = "0" * 64
        with self.assertRaisesRegex(ValueError, "artifact bytes protected_lab_driver_sha256"):
            matrix_guard.validate_record(changed, self.original, self.package_sha, self.package_payload)

    def test_composed_matrix_must_match_both_sources_exactly(self):
        changed = self._record()
        changed["cases"][0]["result"] = "FAIL"
        with self.assertRaisesRegex(ValueError, "composed cases audits"):
            matrix_guard.validate_record(changed, self.original, self.package_sha)
        changed = self._record()
        changed["cases"].pop()
        with self.assertRaisesRegex(ValueError, "complete twelve-case matrix"):
            matrix_guard.validate_record(changed, self.original, self.package_sha)

    def test_committed_matrix_record_and_package_guard(self):
        # The native matrix record is supplied only after the separately budgeted
        # local/central qualification; this integration check is mandatory in CI.
        with contextlib.redirect_stdout(io.StringIO()):
            result = matrix_guard.validate()
        self.assertEqual(result["package_sha256"].lower(), self.package_sha.lower())


if __name__ == "__main__":
    unittest.main()
