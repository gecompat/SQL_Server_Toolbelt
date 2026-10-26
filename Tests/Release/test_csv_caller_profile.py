"""CSV native evidence boundaries; offline only, no credentials or SQL access."""
from pathlib import Path
import json
import re
import unittest
import sys

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import csv_metadata


class CsvCallerProfileTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.record = json.loads((ROOT / 'Releases/1.0.0/csv-caller-profile.json').read_bytes())

    def test_exact_matrix_and_fixed_probe_counts(self):
        r = self.record
        self.assertEqual(r['schema_version'], 'toolbelt-csv-caller-profile/v1')
        expected = {(p, v, cl) for p in ('linux', 'windows')
                    for v, levels in (('2019', (150,)), ('2022', (150, 160)),
                                      ('2025', (150, 160, 170))) for cl in levels}
        cases = r['native_cases']
        self.assertEqual(len(cases), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in cases}, expected)
        for c in cases:
            self.assertEqual(c['contexts'], ['local', 'direct_central'])
            self.assertEqual(c['result'], 'PASS')
            self.assertTrue(c['independent_cleanup_and_pin_audit'])
            for key, value in (('permission_states', 32), ('full_permission_profiles', 4),
                               ('positive_route_executions', 12), ('strict_sql229_denials', 56),
                               ('strict_dependency_55309_denials', 28), ('fixed_result_row_oracles', 42)):
                self.assertEqual(c[key], value)
                self.assertEqual(r[key], sum(x[key] for x in cases))
        self.assertEqual(r['positive_route_executions'] + r['strict_sql229_denials']
                         + r['strict_dependency_55309_denials'], 1152)

    def test_executed_sources_and_single_binary_driver_remain_bound(self):
        pins = self.record['source_sha256']
        required = {'Tests/Release/Invoke-CsvCallerLab.ps1', 'Tests/Release/Runtime/Csv.CallerRights.sql',
                    'Tests/Release/ClrCaller.Environment.ps1', 'Tests/CI/LabQualifiedContract.ps1',
                    'Modules/toolbelt.file.csv-memory/Source/USP_ParseCsv.sql',
                    'Modules/toolbelt.file.csv-memory/Source/USP_WriteCsv.sql'}
        self.assertTrue(required <= pins.keys())
        for path, digest in pins.items():
            self.assertFalse(Path(path).is_absolute())
            self.assertNotIn('..', Path(path).parts)
            self.assertRegex(digest, r'^[a-f0-9]{64}$')
            csv_metadata.validate_source(ROOT, path, digest)
            self.assertNotIn('ssis', path.lower())
        driver = (ROOT / 'Tests/Release/Invoke-CsvCallerLab.ps1').read_text(encoding='utf-8')
        self.assertIn("$runset.artifacts.Count -ne 1", driver)
        self.assertIn("@('toolbelt.file.csv-memory')", driver)
        self.assertIn('@@VERSION', driver)
        self.assertIn("state_desc -CNE 'ONLINE'", driver)
        for digest in self.record['offline_export_sha256'].values():
            self.assertRegex(digest, r'^[a-f0-9]{64}$')

    def test_both_intended_rejections_and_all_final_audits(self):
        r = self.record
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
        for k in ('fresh_after_all_consumers', 'separate_read_only_process_per_attempt',
                  'configuration_original_state_verified', 'source_pins_stable',
                  'owned_trust_entries_absent_and_preexisting_trust_fingerprints_preserved'):
            self.assertIs(audit[k], True)

    def test_exact_permission_profiles_and_unqualified_boundaries(self):
        r = self.record
        self.assertEqual(r['direct_object_permissions'], {
            'toolbelt_file.USP_ParseCsv': ['EXECUTE toolbelt_file.USP_ParseCsv',
                                         'SELECT toolbelt_file.TVF_InternalParseCsv'],
            'toolbelt_file.USP_WriteCsv': ['EXECUTE toolbelt_file.USP_WriteCsv',
                                         'EXECUTE toolbelt_file.SVF_InternalMeasureCsvCell',
                                         'EXECUTE toolbelt_file.SVF_InternalQuoteCsvCell']})
        self.assertEqual(r['additional_result_table_permission'], 'EXECUTE toolbelt_core.USP_PrepareResultTable')
        for k in ('publication_authorized', 'product_sql_changed', 'module_status_changed',
                  'package_payload_changed', 'genuine_crossdb_identity_qualified', 'authenticated_tls_qualified'):
            self.assertIs(r[k], False)
        self.assertIs(r['legacy_manifest_permission_wording_pending'], True)
        origin = r['artifact_origin']
        self.assertEqual(origin['assemblies'], ['Toolbelt_File_CsvMemory'])
        self.assertTrue(origin['two_isolated_builds_equal_packaged_binary'])
        self.assertTrue(origin['complete_current_compile_inputs_equal'])
        self.assertFalse(origin['unknown_or_rebuilt_binary_used'])
        self.assertFalse(origin['trust_hashes_published'])
        safety = r['configuration_safety']
        self.assertFalse(safety['parameter_values_published'])
        self.assertTrue(all(v for k, v in safety.items() if k != 'parameter_values_published'))
        text = json.dumps(r)
        self.assertIsNone(re.search(r'(?i)(password=|data source=|user id=|[a-z]:\\\\|\\\\\\\\)', text))
        self.assertGreaterEqual(len(r['remaining_gates']), 3)


if __name__ == '__main__':
    unittest.main()
