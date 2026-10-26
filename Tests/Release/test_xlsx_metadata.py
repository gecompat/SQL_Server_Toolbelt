"""Begrenzte Manifest- und CLR-Paketprojektion für bereits qualifizierte XLSX-Rechte."""
from pathlib import Path
import copy
import json
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import prepare_release as release
import xlsx_metadata as metadata


def split_package(data):
    outer = release.read_zip(data)
    result = {}
    for path, payload in outer.items():
        if path.startswith(metadata.PACKAGE_PREFIX):
            result[path[len(metadata.PACKAGE_PREFIX):]] = payload
    if not result or len(result) != len(outer):
        raise ValueError('XLSX CLR package root prefix drifted.')
    return result


def build_candidate():
    previous_package = metadata.historical(ROOT, metadata.PACKAGE)
    previous_payload = split_package(previous_package)
    _, previous_files = release.snapshot(metadata.BASELINE)
    _, transition_previous_files = release.snapshot(metadata.DOCUMENTATION_TRANSITION_START)
    _, transition_current_files = release.snapshot(metadata.BASELINE)
    current_files = dict(previous_files)
    current_files[metadata.MANIFEST] = (ROOT / metadata.MANIFEST).read_bytes()
    current_sources = dict(current_files)
    for path in metadata.REPORTS:
        current_sources[path] = (ROOT / path).read_bytes()
    record = metadata.make_record(ROOT, previous_package, previous_payload,
                                  current_sources, previous_files, current_files,
                                  transition_previous_files, transition_current_files)
    current_sources[metadata.RECORD] = metadata.encoded(record)
    current_payload = metadata.refreshed_clr_payload(previous_payload, current_sources, record)
    metadata.validate_clr_delta(ROOT, previous_package, previous_payload, current_payload,
                                record, current_sources)
    return previous_package, previous_payload, current_payload, current_sources, record


class XlsxMetadataMixin:
    def test_manifest_is_exactly_supported_by_the_two_native_profiles(self):
        original = metadata.historical(ROOT, metadata.MANIFEST)
        current = (ROOT / metadata.MANIFEST).read_bytes()
        metadata.validate_manifest(original, current)
        record = json.loads((ROOT / metadata.RECORD).read_bytes())
        reports = [json.loads((ROOT / p).read_bytes()) for p in metadata.REPORTS]
        self.assertEqual(record['native_manifest_pins'][metadata.RAW_REPORT],
                         reports[0]['source_sha256'][metadata.MANIFEST])
        self.assertEqual(record['native_manifest_pins'][metadata.CELL_REPORT],
                         reports[1]['source_sha256'][metadata.MANIFEST])
        for before, after in ((b'partially validated', b'validated'),
                              (b'1.2.0', b'9.9.9'),
                              (b'dependencies:', b'changed_dependencies:')):
            with self.subTest(field=before), self.assertRaises(ValueError):
                metadata.validate_manifest(original, current.replace(before, after, 1))

    def test_clr_package_overlay_preserves_sql_dll_and_csv_provenance(self):
        previous_package, previous, current, sources, record = build_candidate()
        self.assertEqual(record['previous_clr_zip_sha256'], metadata.digest(previous_package))
        self.assertEqual(current['METADATA-UPDATE.json'], previous['METADATA-UPDATE.json'])
        self.assertEqual(json.loads(current['CLR-PACKAGE.json'])['metadata_update_evidence'],
                         'Releases/1.0.0/csv-metadata-update.json')
        self.assertEqual(json.loads(current['CLR-PACKAGE.json'])['xlsx_metadata_update_evidence'],
                         metadata.RECORD)
        for path, value in previous.items():
            if path.startswith(('SQL/', 'Binaries/')):
                self.assertEqual(current[path], value, path)
        self.assertEqual(release.sha(previous_package), record['previous_clr_zip_sha256'])
        release.validate_xlsx_clr_metadata(current, sources)

    def test_payload_rejects_runtime_or_unknown_package_changes(self):
        previous_package, previous, current, sources, record = build_candidate()
        for path in ('SQL/Install-Windows-Local.sql', 'Binaries/Toolbelt_File_XlsxMemory.dll',
                     'Sources/Modules/toolbelt.file.xlsx-memory/Source/USP_InternalXlsxRead.sql',
                     'Unexpected/extra.txt'):
            altered = dict(current)
            altered[path] = altered.get(path, b'') + b'\nchanged'
            with self.subTest(path=path), self.assertRaises(ValueError):
                metadata.validate_clr_delta(ROOT, previous_package, previous, altered, record, sources)

    def test_product_delta_and_proof_reject_unselected_fields(self):
        _, _, _, _, record = build_candidate()
        _, baseline = release.snapshot(metadata.BASELINE)
        current = dict(baseline)
        current[metadata.MANIFEST] = (ROOT / metadata.MANIFEST).read_bytes()
        changed = metadata.validate_product_delta(baseline, current, record, baseline)
        self.assertEqual(changed, {metadata.MANIFEST})
        for path, value in (('Modules/toolbelt.file.xlsx-memory/README.md',
                             current['Modules/toolbelt.file.xlsx-memory/README.md'] + b'\n'),
                            (metadata.MANIFEST,
                             current[metadata.MANIFEST].replace(b'validation_status: "partially validated"',
                                                                b'validation_status: "validated"'))):
            altered = dict(current)
            altered[path] = value
            with self.subTest(path=path), self.assertRaises(ValueError):
                metadata.validate_product_delta(baseline, altered, record, baseline)
        mutated = copy.deepcopy(record)
        mutated['publication_authorized'] = True
        with self.assertRaises(ValueError):
            metadata.validate_record(mutated, baseline[metadata.MANIFEST], current[metadata.MANIFEST],
                                     metadata.historical(ROOT, metadata.PACKAGE),
                                     split_package(metadata.historical(ROOT, metadata.PACKAGE)),
                                     current, metadata.historical(ROOT, metadata.RAW_REPORT),
                                     metadata.historical(ROOT, metadata.CELL_REPORT))

    def test_offline_source_hook_and_transitive_product_chain_are_exact(self):
        record = json.loads((ROOT / metadata.RECORD).read_bytes())
        original_test = metadata.historical(ROOT, metadata.OFFLINE_SOURCE)
        current_test = (ROOT / metadata.OFFLINE_SOURCE).read_bytes()
        self.assertEqual(metadata.corrected_offline_source(original_test), current_test)
        self.assertNotEqual(metadata.corrected_offline_source(original_test),
                            current_test.replace(b'continue', b'pass', 1))

        _, baseline = release.snapshot(metadata.BASELINE)
        current = dict(baseline)
        current[metadata.MANIFEST] = (ROOT / metadata.MANIFEST).read_bytes()
        release.validate_product_applicability('5f796e599554b55668861ec0dee8d28ae663f082',
                                                'f' * 40, current)
        altered = dict(current)
        path = 'Modules/toolbelt.file.xlsx-memory/README.md'
        altered[path] += b'\n'
        with self.assertRaises(ValueError):
            release.validate_product_applicability('5f796e599554b55668861ec0dee8d28ae663f082',
                                                    'f' * 40, altered)

    def test_record_rejects_drifted_claims_and_unknown_fields(self):
        previous_package, previous, _, sources, record = build_candidate()
        original = metadata.historical(ROOT, metadata.MANIFEST)
        current = (ROOT / metadata.MANIFEST).read_bytes()
        raw = metadata.historical(ROOT, metadata.RAW_REPORT)
        cell = metadata.historical(ROOT, metadata.CELL_REPORT)
        mutations = []
        for key, value in (
            ('module_status', 'validated'),
            ('executable_package_payload_changed', True),
            ('unrecognized_claim', False),
        ):
            changed = copy.deepcopy(record)
            changed[key] = value
            mutations.append(changed)
        changed_pins = copy.deepcopy(record)
        changed_pins['native_manifest_pins'][metadata.RAW_REPORT] = '0' * 64
        mutations.append(changed_pins)
        for changed in mutations:
            with self.subTest(keys=set(changed) - set(record)), self.assertRaises(ValueError):
                metadata.validate_record(changed, original, current, previous_package,
                                         previous, sources, raw, cell)


class XlsxMetadataTests(XlsxMetadataMixin, unittest.TestCase):
    pass


if __name__ == '__main__':
    unittest.main()
