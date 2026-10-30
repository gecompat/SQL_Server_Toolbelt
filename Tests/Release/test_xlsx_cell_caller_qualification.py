"""Bound XLSX cell caller evidence, no SQL or external resources."""
from pathlib import Path
import hashlib
import json
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tests/Release'))
from prepare_function_rights import compose
from test_xlsx_raw_caller_composer import XlsxRawCallerComposerMixin
from test_xlsx_raw_caller_evidence import XlsxRawCallerEvidenceMixin
import xlsx_metadata
import zip_metadata
import xlsx_sst_budget


class XlsxCellCallerTests(XlsxRawCallerComposerMixin, XlsxRawCallerEvidenceMixin, unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.record = json.loads((ROOT / 'Releases/1.0.0/xlsx-cell-caller-qualification.json').read_bytes())

    def test_matrix_and_fixed_counts(self):
        r = self.record
        cases = r['native_cases']
        expected = {(p, v, c) for p in ('linux', 'windows')
                    for v, levels in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170))) for c in levels}
        self.assertEqual(len(cases), 12)
        self.assertEqual({(c['platform'], c['sql_version'], c['compatibility_level']) for c in cases}, expected)
        for c in cases:
            self.assertEqual(c['contexts'], ['local', 'direct_central'])
            self.assertEqual(c['result'], 'PASS')
            self.assertTrue(c['independent_cleanup_and_pin_audit'])
            self.assertEqual((c['positive_profiles'], c['strict_sql229_denials'], c['fixed_value_null_and_shape_oracles']), (4, 56, 12))
        for k, value in [('positive_profiles', 48), ('strict_sql229_denials', 672), ('fixed_value_null_and_shape_oracles', 144)]:
            self.assertEqual(r[k], value)
            self.assertEqual(sum(c[k] for c in cases), value)

    def test_canonical_composition_and_all_executed_sources(self):
        r = self.record
        data, composition = compose(ROOT / 'Tests/Release/Runtime/XlsxCell.FunctionCases.sql')
        self.assertEqual(hashlib.sha256(data).hexdigest(), r['composed_fixture_sha256'])
        self.assertEqual(composition['composition_order'], r['composition_order'])
        for path, digest in r['source_sha256'].items():
            self.assertFalse(Path(path).is_absolute())
            self.assertNotIn('..', Path(path).parts)
            if path == xlsx_metadata.MANIFEST:
                xlsx_metadata.validate_source(ROOT, path, digest)
                continue
            if path == zip_metadata.MANIFEST:
                zip_metadata.validate_source(ROOT, path, digest)
                continue
            if path == xlsx_sst_budget.WORKBOOK:
                xlsx_sst_budget.validate_historical_source(ROOT, path, digest)
                continue
            if path in xlsx_sst_budget.XLSX_HELP_SOURCE_SHA256:
                xlsx_sst_budget.validate_historical_help_source(ROOT, path, digest)
                continue
            import parameter_help_transition
            data = parameter_help_transition.bound_source(ROOT, path, digest)
            self.assertEqual(hashlib.sha256(data).hexdigest(), digest, path)
        self.assertEqual({a['name'] for a in r['public_apis']}, {'TVF_InterpretXlsxCell', 'TVF_FormatXlsxCell'})
        self.assertTrue(all(a['permission'] == 'SELECT' for a in r['public_apis']))
        self.assertEqual(len(r['separately_denied_objects']), 11)

    def test_intended_controls_and_complete_cleanup_history(self):
        r = self.record
        self.assertEqual(r['native_attempts_consumed'], 15)
        self.assertEqual({c['synthetic_fault'] for c in r['oracle_rejection_controls']}, {'wrong-value', 'extra-grant'})
        for c in r['oracle_rejection_controls']:
            self.assertEqual(c['actual_state'], 'FAILED_CLEANED')
            self.assertTrue(c['intended_oracle_rejected'])
            self.assertTrue(c['independent_cleanup_and_pin_audit'])
        a = r['final_independent_audit']
        self.assertEqual((a['all_terminal_attempts'], a['all_database_names_absent'], a['accepted_database_names_absent']), (15, 27, 26))
        self.assertTrue(a['fresh_after_all_consumers'])
        self.assertTrue(a['source_pins_stable'])
        self.assertEqual(r['initial_fixture_failure']['corrected_input'], 'yyyy-mm-dd')
        self.assertTrue(r['initial_fixture_failure']['original_runset_journal_and_source_retained'])

    def test_binary_origins_and_unqualified_boundaries(self):
        r = self.record
        self.assertEqual(r['artifact_origin']['assemblies'], ['Toolbelt_Archive_ZipMemory', 'Toolbelt_File_XlsxMemory'])
        for k in ('two_isolated_builds_equal_packaged_binary', 'complete_current_compile_inputs_equal', 'xlsx_zip_reference_bound'):
            self.assertTrue(r['artifact_origin'][k])
        self.assertFalse(r['artifact_origin']['trust_hashes_published'])
        for k in ('publication_authorized', 'product_sql_changed', 'module_status_changed', 'package_payload_changed',
                  'genuine_crossdb_identity_qualified', 'authenticated_tls_qualified'):
            self.assertIs(r[k], False)
        self.assertEqual(r['module_versions'], {'toolbelt.core.result-table': '1.0.0', 'toolbelt.archive.zip-memory': '1.4.0',
                                               'toolbelt.file.xlsx-memory': '1.2.0'})
        self.assertIn('DECIMAL(38,10)', r['numeric_probe_scope'])
        self.assertGreaterEqual(len(r['remaining_gates']), 3)


if __name__ == '__main__':
    unittest.main()
