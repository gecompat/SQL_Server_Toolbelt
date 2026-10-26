"""Offline binding checks for the ZIP caller-rights evidence projection."""
from pathlib import Path
import hashlib
import copy
import json
import sys
import unittest
import zipfile
import io

ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / 'Releases/1.0.0/zip-caller-profile.json'
sys.path.insert(0, str(ROOT / 'Tests/Release'))
import compose_zip_caller as composer
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import zip_metadata
import prepare_release as release


class ZipCallerProfileMixin:
    def test_matrix_and_probe_totals_are_arithmetically_bound(self):
        report = json.loads(REPORT.read_bytes())
        matrix = report['native_matrix']
        probes = report['probe_counts']
        self.assertEqual(matrix['case_count'], 12)
        self.assertEqual(matrix['context_count'], matrix['case_count'] * 2)
        self.assertEqual(len(matrix['cases']), matrix['case_count'])
        expected = {
            (platform, version, cl)
            for platform in ('linux', 'windows')
            for version, levels in (('2019', (150,)),
                                    ('2022', (150, 160)),
                                    ('2025', (150, 160, 170)))
            for cl in levels
        }
        actual = {(x['platform'], x['sql_version'], x['compatibility_level'])
                  for x in matrix['cases']}
        self.assertEqual(actual, expected)
        states = matrix['context_count'] * 3 * report['tested_profiles']['per_api_masks']
        routes = states * 2
        self.assertEqual(report['tested_profiles']['mask_states'], states)
        self.assertEqual(probes['api_route_calls'], routes)
        self.assertEqual(probes['positive_api_routes'], matrix['context_count'] * 8)
        self.assertEqual(probes['expected_dependency_denials'], matrix['context_count'] * 16)
        self.assertEqual(probes['expected_229_api_route_denials'], matrix['context_count'] * 12)
        self.assertEqual(probes['additional_internal_and_counter_api_229_denials'],
                         matrix['context_count'] * 105)
        self.assertEqual(probes['strict_229_denials_total'],
                         probes['expected_229_api_route_denials'] +
                         probes['additional_internal_and_counter_api_229_denials'])
        self.assertEqual(probes['fixed_result_rows_total'], matrix['context_count'] * 8)

    def test_public_source_pins_match_current_synthetic_inputs(self):
        report = json.loads(REPORT.read_bytes())
        pins = report['source_sha256']
        self.assertEqual(len(pins), 32)
        for relative, expected in pins.items():
            path = Path(relative)
            self.assertFalse(path.is_absolute())
            self.assertNotIn('..', path.parts)
            self.assertNotIn('.runtime', path.parts)
            self.assertRegex(expected, r'^[0-9A-F]{64}$')
            actual = hashlib.sha256((ROOT / path).read_bytes()).hexdigest().upper()
            with self.subTest(path=relative):
                if relative == zip_metadata.MANIFEST:
                    zip_metadata.validate_source(ROOT, relative, expected)
                else:
                    self.assertEqual(actual, expected)
        self.assertIn('Tests/Release/Runtime/ZipMemory.CallerRights.sql', pins)
        self.assertIn('Tests/Release/Invoke-ZipCallerLab.ps1', pins)
        self.assertIn('Tests/Release/compose_zip_caller.py', pins)
        artifact = json.loads(REPORT.read_bytes())['artifact_binding']
        package_path = artifact['package_path']
        self.assertEqual(package_path, 'Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip')
        old_package = zip_metadata.historical(ROOT, package_path)
        package_hash = hashlib.sha256(old_package).hexdigest().upper()
        self.assertEqual(package_hash, artifact['executed_package_sha256'])

    def test_zip_manifest_overlay_rejects_every_other_byte_and_wrong_pin(self):
        original = zip_metadata.historical(ROOT, zip_metadata.MANIFEST)
        current = (ROOT / zip_metadata.MANIFEST).read_bytes()
        zip_metadata.validate_manifest(original, current)
        with self.assertRaises(ValueError):
            zip_metadata.validate_source(ROOT, zip_metadata.MANIFEST, '0' * 64)
        with self.assertRaises(ValueError):
            zip_metadata.validate_manifest(original, current + b'\n# extra')

    def test_zip_metadata_record_binds_public_xlsx_predecessor_and_exact_product_delta(self):
        record = json.loads((ROOT / zip_metadata.RECORD).read_bytes())
        source = json.loads((ROOT / release.PRODUCT_SOURCE).read_bytes())
        _, previous, previous_tree = release.qualification_sources(record['product_chain_predecessor'])
        _, current = release.snapshot(source['source_commit'])
        _, baseline = release.snapshot(zip_metadata.BASELINE)
        package = release.git('show', zip_metadata.BASELINE + ':' + release.CLR_PACKAGE)
        self.assertEqual(previous_tree, record['previous_product_tree'])
        self.assertEqual(source['product_commit'], record['current_product_commit'])
        changed = zip_metadata.validate_product_delta(ROOT, previous, current, record, baseline, package)
        self.assertEqual(changed, {zip_metadata.MANIFEST, *zip_metadata.DOCS})
        release.validate_product_applicability(
            '5f796e599554b55668861ec0dee8d28ae663f082', record['current_product_commit'], current)
        for field, value in (('module_status', 'validated'),
                             ('previous_source_zip_sha256', '0' * 64),
                             ('executable_package_payload_changed', True)):
            altered = copy.deepcopy(record)
            altered[field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                zip_metadata.validate_record(ROOT, altered, previous, current, package)
        altered = copy.deepcopy(record)
        altered['unreviewed_claim'] = True
        with self.assertRaises(ValueError):
            zip_metadata.validate_record(ROOT, altered, previous, current, package)

    def test_fixed_reader_and_writer_goldens_are_independent(self):
        report = json.loads(REPORT.read_bytes())
        oracle = report['fixed_oracles']
        reader = composer.reader_fixture()
        writer = composer.writer_golden()
        self.assertEqual(len(reader), oracle['reader_zip_bytes'])
        self.assertEqual(hashlib.sha256(reader).hexdigest(), oracle['reader_zip_sha256'])
        self.assertEqual(len(writer), oracle['writer_golden_bytes'])
        self.assertEqual(hashlib.sha256(writer).hexdigest(), oracle['writer_golden_sha256'])
        self.assertNotEqual(reader, writer)
        with zipfile.ZipFile(io.BytesIO(reader)) as archive:
            entry = archive.infolist()[0]
            self.assertEqual((entry.filename, archive.read(entry), entry.CRC,
                              entry.date_time),
                             (oracle['reader_entry_name'], b'Hello', 0xF7D18982,
                              (2020, 2, 3, 4, 5, 6)))
        with zipfile.ZipFile(io.BytesIO(writer)) as archive:
            entry = archive.infolist()[0]
            self.assertEqual((entry.filename, archive.read(entry), entry.CRC,
                              entry.date_time),
                             (oracle['reader_entry_name'], b'Hello', 0xF7D18982,
                              (1980, 1, 1, 0, 0, 0)))

    def test_expected_controls_and_retained_v1_failure_are_distinct(self):
        report = json.loads(REPORT.read_bytes())
        attempts = report['native_attempts']
        self.assertEqual(attempts['total'], 15)
        self.assertEqual(attempts['positive_pass'], 12)
        self.assertEqual(attempts['expected_control_failed_cleaned'], 2)
        self.assertEqual(attempts['retained_v1_fixture_failure'], 1)
        self.assertEqual(attempts['fresh_separate_final_audits_passed'], 15)
        self.assertEqual(attempts['wrong_golden_control_expected_diagnostic'],
                         'ZIP writer fixed 121-byte golden mismatch.')
        self.assertEqual(attempts['broad_schema_select_control_expected_diagnostic'],
                         'Broad caller role or schema/database permission detected.')
        self.assertIn('physical tempdb column_id',
                      attempts['original_v1_attempt_note'])
        self.assertFalse(report['product_sql_changed'])
        self.assertFalse(report['product_clr_changed'])
        self.assertFalse(report['manifest_or_package_changed'])
        self.assertFalse(report['publication_authorized'])
        self.assertIn('No claim is made', report['denial_scope_limit'])


class ZipCallerProfileTests(ZipCallerProfileMixin, unittest.TestCase):
    pass


if __name__ == '__main__':
    unittest.main()
