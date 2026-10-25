"""Verify the source binding and bounds of the native JSON Schema caller evidence."""
from pathlib import Path
import hashlib
import json
import unittest

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'Releases/1.0.0/json-schema-caller-profile.json'


class JsonSchemaCallerProfileTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = json.loads(REPORT.read_bytes())

    def test_exact_rights_and_target_coverage(self):
        r = self.report
        self.assertEqual(r['result'], 'PASS')
        self.assertEqual(r['required_object_rights'], [
            {'schema': 'toolbelt_json', 'name': 'USP_ValidateJsonSchema', 'permission': 'EXECUTE'},
            {'schema': 'toolbelt_core', 'name': 'USP_PrepareResultTable', 'permission': 'EXECUTE'},
            {'schema': 'toolbelt_json', 'name': 'FT_ValidateJsonSchemaInternal', 'permission': 'SELECT'}])
        expected = {(p, v, cl) for p in ('windows', 'linux') for v, levels in
                    [('2019', [150]), ('2022', [150, 160]), ('2025', [150, 160, 170])] for cl in levels}
        cases = r['native_cases']
        self.assertEqual(len(cases), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in cases}, expected)
        for c in cases:
            self.assertEqual(c['result'], 'PASS')
            self.assertEqual(c['contexts'], ['local', 'direct_central'])
            self.assertTrue(c['independent_cleanup_and_pin_audit'])
        for field, total in [('permission_states', 168), ('positive_profiles', 24),
                             ('fixed_semantic_cases', 240), ('strict_sql229_denials', 96),
                             ('strict_dependency_55601_denials', 48)]:
            self.assertEqual(r[field], total)
            self.assertEqual(sum(c[field] for c in cases), total)

    def test_current_execution_inputs(self):
        pins = self.report['source_sha256']
        self.assertIn('Tests/Release/Invoke-JsonSchemaCallerLab.ps1', pins)
        self.assertIn(self.report['fixture'], pins)
        self.assertIn('Tests/Release/ClrCaller.Environment.ps1', pins)
        for relative, digest in pins.items():
            self.assertFalse(Path(relative).is_absolute())
            self.assertNotIn('..', Path(relative).parts)
            self.assertNotIn('.runtime', Path(relative).parts)
            self.assertEqual(hashlib.sha256((ROOT / relative).read_bytes()).hexdigest(), digest, relative)

    def test_controls_and_terminal_cleanup(self):
        r = self.report
        self.assertEqual(r['native_attempts_consumed'], 14)
        controls = r['oracle_rejection_controls']
        self.assertEqual({c['synthetic_fault'] for c in controls}, {'wrong-value', 'extra-grant'})
        self.assertEqual(len(controls), 2)
        for c in controls:
            self.assertEqual(c['actual_state'], 'FAILED_CLEANED')
            self.assertTrue(c['intended_oracle_rejected'])
            self.assertTrue(c['independent_cleanup_and_pin_audit'])
        audit = r['final_independent_audit']
        self.assertEqual(audit['all_terminal_attempts'], 14)
        self.assertEqual(audit['passed_terminal_attempts'], 14)
        self.assertEqual(audit['all_database_names_absent'], 26)
        for field in ['fresh_after_all_consumers', 'separate_read_only_process_per_attempt',
                      'owned_trust_entries_absent_and_preexisting_trust_fingerprints_preserved',
                      'configuration_original_state_verified', 'source_pins_stable']:
            self.assertTrue(audit[field], field)

        history = r['audit_diagnostic_history']
        self.assertEqual(history['initial_failed_read_only_audits'], 1)
        self.assertEqual(history['bounded_failed_followup_audits'], 6)
        self.assertEqual(history['failed_private_diagnostics'], 1)
        self.assertTrue(history['coordinated_fresh_final_audit_succeeded'])
        self.assertTrue(history['human_authorized_exclusive_window_coordination'])
        self.assertFalse(history['state_mutated_to_satisfy_audit'])
        self.assertFalse(history['original_functional_tests_repeated'])

    def test_artifact_and_release_boundaries(self):
        r = self.report
        a = r['artifact_origin']
        self.assertEqual(a['assemblies'], ['Toolbelt_JsonCore', 'Toolbelt_JsonSchema'])
        for field in ['two_isolated_builds_equal_packaged_binaries',
                      'complete_current_compile_inputs_equal', 'json_schema_reference_bound_to_exact_core']:
            self.assertTrue(a[field], field)
        self.assertFalse(a['unknown_or_rebuilt_binaries_used'])
        self.assertFalse(a['trust_hashes_published'])
        for field in ['publication_authorized', 'product_sql_changed', 'module_status_changed',
                      'package_payload_changed', 'genuine_crossdb_identity_qualified', 'authenticated_tls_qualified']:
            self.assertIs(r[field], False, field)
        self.assertTrue(r['legacy_manifest_permission_wording_pending'])
        for field, value in r['configuration_safety'].items():
            self.assertIs(value, field != 'parameter_values_published', field)


if __name__ == '__main__':
    unittest.main()
