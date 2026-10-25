"""Prüft additive Evidenz: keine Doppelzählung oder stillschweigende Teilabnahme."""
from pathlib import Path
import hashlib
import json
import unittest

ROOT = Path(__file__).resolve().parents[2]


class AdditiveDateMathQualificationTests(unittest.TestCase):
    def test_exact_additive_matrix_and_retained_baseline(self):
        report = json.loads((ROOT / 'Releases/1.0.0/date-math-cl-completion.json').read_bytes())
        binding = report['prior_selected_report']
        previous_path = ROOT / binding['path']
        previous = json.loads(previous_path.read_bytes())
        self.assertEqual(hashlib.sha256(previous_path.read_bytes()).hexdigest(), binding['sha256'])
        self.assertEqual(previous['result'], 'PASS_SELECTED_SCOPE')
        self.assertIs(previous['full_target_cl_matrix_qualified'], False)
        self.assertEqual(report['result'], 'PASS')
        self.assertIs(report['full_target_cl_matrix_qualified'], True)
        self.assertEqual(report['remaining_unexecuted_cases'], [])
        key = lambda c: (c['platform'], c['sql_version'], c['compatibility_level'])
        reused = {key(c) for c in report['native_cases'] if c['qualification_origin'] == 'reused-highest-cl'}
        added = {key(c) for c in report['native_cases'] if c['qualification_origin'] == 'new-lower-cl'}
        self.assertEqual(reused, {key(c) for c in previous['native_cases']})
        self.assertEqual(added, {key(c) for c in previous['remaining_unexecuted_cases']})
        self.assertFalse(reused & added)
        self.assertEqual(len(report['native_cases']), 12)
        self.assertEqual(len(reused | added), 12)
        self.assertEqual(report['new_native_target_attempts_consumed'], 6)
        self.assertTrue(binding['exact_fixture_exports_cases_and_current_pins_verified'])
        for field in ('composition_order', 'composed_fixture_sha256', 'source_sha256',
                      'offline_export_sha256', 'public_apis', 'oracle_rejection_controls'):
            self.assertEqual(report[field], previous[field])
        for path, digest in report['source_sha256'].items():
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        self.assertEqual(report['positive_profiles'], 96)
        self.assertEqual(report['strict_sql229_denials'], 672)
        self.assertEqual(report['final_independent_audit']['accepted_database_names_absent'], 26)
        self.assertTrue(report['final_independent_audit']['fresh_after_all_consumers'])
        for flag in ('publication_authorized', 'product_sql_changed', 'module_status_changed',
                     'package_payload_changed', 'genuine_crossdb_identity_qualified', 'authenticated_tls_qualified'):
            self.assertIs(report[flag], False)


if __name__ == '__main__':
    unittest.main()
