"""Validate the public XLSX raw-caller evidence against its actual bound inputs."""
from pathlib import Path
import hashlib
import json
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Tests/Release'))
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
from compose_xlsx_raw_caller import compose
import xlsx_metadata

REPORT_PATH = ROOT / 'Releases/1.0.0/xlsx-raw-caller-profile.json'


def validate_case_matrix(cases):
    expected = {
        (platform, version, cl)
        for platform in ('linux', 'windows')
        for version, levels in (('2019', (150,)), ('2022', (150, 160)), ('2025', (150, 160, 170)))
        for cl in levels
    }
    keys = [(c['platform'], c['sql_version'], c['compatibility_level']) for c in cases]
    if len(keys) != 12 or len(set(keys)) != 12 or set(keys) != expected:
        raise ValueError('raw caller matrix must contain each selected platform/version/CL exactly once')


POST_NATIVE_SOURCE_UPDATE_PATHS = frozenset({
    'Tests/Release/test_xlsx_cell_caller_qualification.py',
    'Tests/Release/test_xlsx_raw_caller_composer.py',
})


def validate_source_bindings(report, root):
    pins = report['source_sha256']
    updates = report.get('post_native_source_updates', [])
    by_path = {}
    for update in updates:
        relative = update.get('path')
        path = Path(relative or '')
        if (relative not in POST_NATIVE_SOURCE_UPDATE_PATHS or path.is_absolute()
                or '..' in path.parts or relative not in pins):
            raise ValueError(f'unsupported post-native source update: {relative!r}')
        if relative in by_path:
            raise ValueError(f'duplicate post-native source update: {relative}')
        if update.get('execution_sha256', '').upper() != pins[relative].upper():
            raise ValueError(f'post-native execution pin differs from native source pin: {relative}')
        for field in ('execution_sha256', 'current_sha256'):
            value = update.get(field, '')
            if len(value) != 64 or any(ch not in '0123456789abcdefABCDEF' for ch in value):
                raise ValueError(f'invalid {field} for {relative}')
        by_path[relative] = update

    for relative, digest in pins.items():
        path = Path(relative)
        if path.is_absolute() or '..' in path.parts:
            raise ValueError(f'unsafe source pin path: {relative}')
        if relative == xlsx_metadata.MANIFEST:
            xlsx_metadata.validate_source(root, relative, digest)
            continue
        if relative == xlsx_metadata.OFFLINE_SOURCE:
            xlsx_metadata.validate_source(root, relative, digest)
            continue
        current = hashlib.sha256((root / path).read_bytes()).hexdigest().upper()
        expected = by_path.get(relative, {}).get('current_sha256', digest)
        if current != expected.upper():
            raise ValueError(f'source bytes differ from bound hash: {relative}')
    for relative, digest in report.get('documentation_source_sha256', {}).items():
        path = Path(relative)
        if path.is_absolute() or '..' in path.parts:
            raise ValueError(f'unsafe documentation source path: {relative}')
        current = hashlib.sha256((root / path).read_bytes()).hexdigest().upper()
        if current != digest.upper():
            raise ValueError(f'documentation bytes differ from bound hash: {relative}')


class XlsxRawCallerEvidenceMixin:
    def setUp(self):
        self.raw_report = json.loads(REPORT_PATH.read_bytes())

    def test_public_source_hashes_match_current_repository_bytes(self):
        report = self.raw_report
        validate_source_bindings(report, ROOT)
        self.assertIn('Tests/Release/Invoke-XlsxRawCallerLab.ps1', report['source_sha256'])
        self.assertIn('Tests/Release/Runtime/XlsxRaw.CallerRights.sql', report['source_sha256'])
        self.assertIn('Tests/Release/compose_xlsx_raw_caller.py', report['source_sha256'])
        self.assertIn('Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.Composition.xlsx', report['source_sha256'])
        # A correct hash cannot authorize a runtime-fixture re-pin, and duplicate
        # post-native exceptions cannot shadow one another.
        runtime_path = 'Tests/Release/Runtime/XlsxRaw.CallerRights.sql'
        runtime_hash = hashlib.sha256((ROOT / runtime_path).read_bytes()).hexdigest().upper()
        attack = json.loads(json.dumps(report))
        attack['post_native_source_updates'].append({
            'path': runtime_path,
            'execution_sha256': report['source_sha256'][runtime_path],
            'current_sha256': runtime_hash,
            'reason': 'negative control',
        })
        with self.assertRaisesRegex(ValueError, 'unsupported post-native source update'):
            validate_source_bindings(attack, ROOT)
        duplicate = json.loads(json.dumps(report))
        duplicate['post_native_source_updates'].append(dict(duplicate['post_native_source_updates'][0]))
        with self.assertRaisesRegex(ValueError, 'duplicate post-native source update'):
            validate_source_bindings(duplicate, ROOT)

    def test_composition_and_workbook_hashes_recompute_exactly(self):
        composed, manifest = compose()
        report = self.raw_report['composition']
        self.assertEqual(manifest['inputs']['fixture_sha256'], report['source_fixture_sha256'])
        self.assertEqual(manifest['inputs']['workbook_sha256'], report['workbook_sha256'])
        self.assertEqual(manifest['output_sha256'], report['composed_fixture_sha256'])
        self.assertEqual(manifest['marker_count'], report['marker_replacements'])
        self.assertEqual(hashlib.sha256(composed).hexdigest().upper(), report['composed_fixture_sha256'].upper())

    def test_matrix_counts_and_duplicate_case_rejection(self):
        report = self.raw_report
        matrix = report['native_matrix']
        validate_case_matrix(matrix['cases'])
        self.assertEqual(matrix['case_count'] * matrix['contexts_per_case'], matrix['context_count'])
        self.assertEqual(matrix['context_count'], 24)
        altered = list(matrix['cases'])
        altered[-1] = dict(altered[0])
        with self.assertRaisesRegex(ValueError, 'exactly once'):
            validate_case_matrix(altered)
        counts = report['probe_counts']
        masks = report['tested_profiles']['total_masks_per_context']
        contexts = matrix['context_count']
        self.assertEqual(masks, 14)
        self.assertEqual(masks * contexts, report['tested_profiles']['mask_states'])
        self.assertEqual(masks * 2 * contexts, counts['api_route_calls'])
        self.assertEqual(6 * contexts, counts['positive_api_routes'])
        self.assertEqual(10 * contexts, counts['expected_51529_denials'])
        self.assertEqual(12 * contexts, counts['expected_229_api_route_denials'])
        self.assertEqual(70 * contexts, counts['additional_internal_and_counter_api_229_denials'])
        self.assertEqual(30 * contexts, counts['fixed_result_rows_total'])
        self.assertEqual(counts['expected_229_api_route_denials'] + counts['additional_internal_and_counter_api_229_denials'], counts['strict_229_denials_total'])

    def test_rights_scope_cleanup_and_unqualified_boundaries(self):
        report = self.raw_report
        self.assertEqual({x['name'] for x in report['public_apis']}, {'USP_ListXlsxWorksheets', 'USP_ReadXlsxWorksheetCells'})
        self.assertTrue(all(x['permission'] == 'EXECUTE' for x in report['public_apis']))
        self.assertEqual({x['required_internal_object']['name'] for x in report['public_apis']}, {'TVF_InternalXlsxSheets', 'TVF_InternalXlsxCells'})
        self.assertEqual(report['result_table_additional_permission']['name'], 'USP_PrepareResultTable')
        self.assertEqual(len(report['separately_denied_objects']), 5)
        self.assertIn('No claim is made that every public ZIP API', report['denial_scope_limit'])
        self.assertEqual(report['native_attempts']['total'], 15)
        self.assertEqual(report['native_attempts']['fresh_separate_final_audits_passed'], 15)
        cleanup = report['cleanup']
        self.assertEqual((cleanup['owned_database_names_from_journals'], cleanup['owned_database_names_dropped'], cleanup['owned_database_names_absent_after_fresh_audits']), (27, 27, 27))
        self.assertEqual(cleanup['owned_trust_removal_journal_events'], 30)
        self.assertTrue(cleanup['trust_removal_events_are_not_unique_hash_count'])
        self.assertIs(report['publication_authorized'], False)
        self.assertEqual(report['ci_binding']['head_and_main'], 'RECORDED_SEPARATELY_IN_INTEGRATING_PR')


class XlsxRawCallerEvidenceTests(XlsxRawCallerEvidenceMixin, unittest.TestCase):
    pass


if __name__ == '__main__':
    unittest.main()
