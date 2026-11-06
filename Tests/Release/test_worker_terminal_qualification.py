"""Falsche Aufwertung eines nativen Windows-Teilscope verhindern."""
from pathlib import Path
import copy
import json
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import worker_terminal_qualification as gate


class WorkerTerminalQualificationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.record = json.loads((ROOT / gate.REPORT).read_bytes())

    def reject(self, mutate):
        record = copy.deepcopy(self.record)
        mutate(record)
        with self.assertRaises(ValueError):
            gate.validate(record)

    def test_original_scope_and_current_source_applicability_are_separate(self):
        result = gate.validate(self.record)
        self.assertTrue(result['historical_integrity'])
        self.assertEqual(result['current_native_qualification'], 'not established by source integrity')

    def test_failed_parent_is_not_overridden_by_green_audit(self):
        self.reject(lambda r: r['execution'].update(run_exit_code=1))

    def test_managed_sql_is_not_full_provider_qualification(self):
        self.reject(lambda r: r['execution'].update(full_product_qualified=True))
        self.reject(lambda r: r['execution'].update(provider_cases=11))

    def test_other_version_and_central_are_not_qualified(self):
        self.reject(lambda r: r['scope'].update(sql_version='2019'))
        self.reject(lambda r: r['scope'].update(deployment_mode='central'))

    def test_witnesses_cannot_be_missing_or_duplicated(self):
        for key in ('managed_sql_witness_count', 'terminal_history_witness_count'):
            for count in (0, 2):
                with self.subTest(key=key, count=count):
                    self.reject(lambda r: r['execution'].update({key: count}))

    def test_fresh_audit_and_unchanged_foreign_state_are_required(self):
        self.reject(lambda r: r['audit'].update(fresh_separate_connection=False))
        self.reject(lambda r: r['audit'].update(foreign_state_unchanged=False))

    def test_budget_counts_and_numeric_types_are_exact(self):
        self.reject(lambda r: r['budget'].update(target_and_audit_calls=2))
        self.reject(lambda r: r['budget'].update(run_count=True))

    def test_retries_and_expired_execution_are_not_pass(self):
        self.reject(lambda r: r['budget'].update(retries=1))
        self.reject(lambda r: r['budget'].update(completed_within_original_deadline=False))

    def test_original_windows_failure_stays_failed(self):
        self.reject(lambda r: r['history'].update(original_windows_sql208='PASS'))
        self.reject(lambda r: r['history'].update(prior_budget_unchanged=False))

    def test_original_source_pin_must_match_executed_git_tree(self):
        key = next(iter(self.record['public_input_sha256']))
        self.reject(lambda r: r['public_input_sha256'].update({key: '0' * 64}))

    def test_missing_and_private_source_paths_are_rejected(self):
        key = next(iter(self.record['public_input_sha256']))
        self.reject(lambda r: r['public_input_sha256'].pop(key))
        self.reject(lambda r: r['public_input_sha256'].update({'.runtime/private-input': '0' * 64}))

    def test_limits_cannot_claim_additional_platform_or_identity_proof(self):
        self.reject(lambda r: r['limits'].__setitem__(0, 'All Windows identities and TLS qualified'))

    def test_publication_and_execution_identity_cannot_be_relabelled(self):
        self.reject(lambda r: r.update(publication_authorized=True))
        self.reject(lambda r: r.update(source_commit='0' * 40))


if __name__ == '__main__':
    unittest.main()
