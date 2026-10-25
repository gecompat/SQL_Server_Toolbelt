"""Prüft CLR-spezifische Scope-, Wiederverwendungs- und Datenschutzgrenzen."""
from pathlib import Path
import hashlib
import json
import unittest

ROOT = Path(__file__).resolve().parents[2]


class ClrCallerQualificationTests(unittest.TestCase):
    def test_current_clr_scope_and_restoration_evidence(self):
        r = json.loads((ROOT / 'Releases/1.0.0/clr-string-caller-qualification.json').read_bytes())
        self.assertEqual(r['result'], 'PASS')
        self.assertEqual({a['name'] for a in r['public_apis']}, {
            'TVF_ColognePhonetic', 'TVF_DoubleMetaphone', 'TVF_LevenshteinDistance',
            'TVF_OsaDistance', 'TVF_JaroWinklerSimilarity'})
        self.assertTrue(all(a['permission'] == 'SELECT' for a in r['public_apis']))
        self.assertEqual(r['positive_profiles'], 120)
        self.assertEqual(r['strict_sql229_denials'], 1440)
        self.assertEqual(r['fixed_value_null_and_shape_oracles'], 480)
        self.assertEqual(len(r['native_cases']), 12)
        self.assertEqual(r['native_attempts_consumed'], 18)
        self.assertFalse(r['safe_preflight_stop']['qualified_as_success'])
        self.assertFalse(r['safe_preflight_stop']['database_trust_and_configuration_mutations'])
        reuse = r['reuse_proof']
        self.assertTrue(reuse['start_and_restore_preexisting_prefixes_identical'])
        self.assertTrue(reuse['original_runsets_and_journals_unchanged'])
        self.assertEqual(reuse['ownership_guard_tightening']['current_native_master_scope_targets'], 3)
        self.assertTrue(reuse['ownership_guard_tightening']['matching_physical_target_and_identical_configuration_snapshots_for_other_cls'])
        self.assertEqual(r['configuration_safety']['independent_safety_checks'], 10)
        for flag in ('strict_security_maintained', 'no_restart_or_override',
                     'no_server_or_login_grants', 'no_memory_option_writes',
                     'own_state_restored_or_preexisting_state_preserved'):
            self.assertTrue(r['configuration_safety'][flag], flag)
        audit = r['final_independent_audit']
        self.assertEqual(audit['accepted_database_names_absent'], 26)
        self.assertEqual(audit['all_database_names_absent'], 32)
        self.assertEqual(audit['all_terminal_attempts'], 18)
        for flag in ('fresh_after_all_consumers', 'owned_configuration_restoration_verified',
                     'owned_trust_entries_removed', 'preexisting_trust_fingerprints_preserved'):
            self.assertTrue(audit[flag], flag)
        self.assertFalse(r['artifact_origin']['trust_hashes_published'])
        self.assertFalse(r['configuration_safety']['parameter_values_published'])
        self.assertNotIn('sha512', json.dumps(r).lower())
        for path, digest in r['source_sha256'].items():
            self.assertFalse(Path(path).is_absolute())
            self.assertEqual(hashlib.sha256((ROOT / path).read_bytes()).hexdigest(), digest, path)
        for flag in ('publication_authorized', 'product_sql_changed', 'module_status_changed',
                     'package_payload_changed', 'genuine_crossdb_identity_qualified',
                     'authenticated_tls_qualified'):
            self.assertIs(r[flag], False)


if __name__ == '__main__':
    unittest.main()
