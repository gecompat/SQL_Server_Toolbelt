"""Verify the bounded TextPairs caller evidence and retained failed attempt."""
from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[2]


class TextPairsCallerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = json.loads((ROOT / 'Releases/1.0.0/text-pairs-caller-qualification.json').read_bytes())

    def test_exact_api_algorithms_and_value_scope(self):
        r = self.report
        self.assertEqual(r['result'], 'PASS')
        self.assertEqual(r['public_apis'], [{'schema': 'toolbelt_string', 'name': 'USP_CompareTextPairs', 'permission': 'EXECUTE'}])
        self.assertEqual(len(r['separately_denied_objects']), 7)
        self.assertEqual(r['algorithms'], ['levenshtein', 'osa', 'jaro-winkler'])
        self.assertEqual(r['result_routes'], ['typed_insert_exec', 'caller_local_result_table'])
        for field, total in [('positive_profiles', 24), ('strict_sql229_denials', 216), ('fixed_value_null_and_shape_oracles', 1008)]:
            self.assertEqual(r[field], total)
            self.assertEqual(sum(c[field] for c in r['native_cases']), total)

    def test_failed_fixture_remains_failure_and_cleanup_is_complete(self):
        r = self.report
        self.assertEqual(r['native_attempts_consumed'], 15)
        f = r['retained_failed_fixture_attempt']
        self.assertFalse(f['qualified_as_success'])
        self.assertEqual(f['stage'], 'CONTRACT_local')
        for field in ['original_runset_and_journal_unchanged', 'original_executed_case_bytes_preserved',
                      'same_digest_original_content_audit_projection_only', 'independent_cleanup_and_final_audit_passed']:
            self.assertTrue(f[field], field)
        audit = r['final_independent_audit']
        self.assertEqual(audit['accepted_database_names_absent'], 26)
        self.assertEqual(audit['all_database_names_absent'], 27)
        self.assertEqual(audit['all_terminal_attempts'], 15)
        self.assertTrue(audit['fresh_after_all_consumers'])
        for c in r['oracle_rejection_controls']:
            self.assertTrue(c['intended_oracle_rejected'])
            self.assertEqual(c['actual_state'], 'FAILED_CLEANED')

    def test_single_artifact_and_unchanged_release_boundaries(self):
        r = self.report
        a = r['artifact_origin']
        self.assertEqual(a['assemblies'], ['Toolbelt_String_EditDistance'])
        self.assertTrue(a['two_isolated_builds_equal_packaged_binary'])
        self.assertTrue(a['complete_current_compile_inputs_equal'])
        self.assertFalse(a['unknown_or_rebuilt_binary_used'])
        self.assertFalse(a['trust_hashes_published'])
        self.assertTrue(r['configuration_safety']['shared_environment_guard_reused_unchanged'])
        for field in ['publication_authorized', 'product_sql_changed', 'module_status_changed',
                      'package_payload_changed', 'genuine_crossdb_identity_qualified', 'authenticated_tls_qualified']:
            self.assertIs(r[field], False, field)


if __name__ == '__main__':
    unittest.main()
