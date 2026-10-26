"""Begrenzte Manifest- und CLR-Paketprojektion für bereits qualifizierte XLSX-Rechte."""
from pathlib import Path
import copy
import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

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
        current[release.PRODUCT_SOURCE] = (ROOT / release.PRODUCT_SOURCE).read_bytes()
        product_commit = json.loads(current[release.PRODUCT_SOURCE])['product_commit']
        release.validate_product_applicability('5f796e599554b55668861ec0dee8d28ae663f082',
                                                product_commit, current)
        altered = dict(current)
        path = 'Modules/toolbelt.file.xlsx-memory/README.md'
        altered[path] += b'\n'
        with self.assertRaises(ValueError):
            release.validate_product_applicability('5f796e599554b55668861ec0dee8d28ae663f082',
                                                    product_commit, altered)

    def test_missing_predecessor_commit_recovers_only_from_bound_public_archive(self):
        record = json.loads((ROOT / metadata.RECORD).read_bytes())
        binding = record['historical_product_source']
        real_git = release.git
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime', prefix='xlsx-public-only-') as folder:
            public_only = Path(folder) / 'public.git'
            subprocess.run(['git', 'init', '--bare', '--quiet', str(public_only)], check=True)
            subprocess.run(['git', 'fetch', '--depth=4', str(ROOT), metadata.BASELINE],
                           cwd=public_only, check=True, capture_output=True)
            subprocess.run(['git', 'update-ref', 'refs/heads/public', metadata.BASELINE],
                           cwd=public_only, check=True, capture_output=True)
            absent = subprocess.run(['git', 'cat-file', '-e', binding['product_commit'] + '^{commit}'],
                                    cwd=public_only, capture_output=True)
            self.assertNotEqual(absent.returncode, 0, 'Fixture accidentally contains the synthetic predecessor commit.')
            objects = subprocess.run(['git', 'rev-parse', '--path-format=absolute', '--git-path', 'objects'],
                                     cwd=public_only, check=True, capture_output=True, text=True).stdout.strip()

            def public_only_objects(*args, **kwargs):
                if args and args[0] == 'rev-parse' and '--path-format=absolute' in args:
                    return (objects + '\n').encode()
                return real_git(*args, **kwargs)

            with patch.object(release, 'git', side_effect=public_only_objects):
                archive = release.qualification_archive(binding['product_commit'])
                raw = release.read_zip(archive)
                prefix = release.NAME + '/'
                manifest = json.loads(raw[prefix + 'PACKAGE-MANIFEST.json'])
                self.assertEqual(manifest['product_commit'], binding['product_commit'])
                _, _, tree = release.recovered_snapshot(raw[prefix + 'PREPARATION.bundle'],
                                                        manifest['source_commit'], binding['product_commit'])
                self.assertEqual(tree, binding['product_tree'])
                self.assertEqual(release.sha(archive), binding['archive_sha256'])

        changed_binding = dict(binding, archive_sha256='0' * 64)
        with patch.object(release.xlsx_metadata, 'predecessor_source_binding',
                          return_value=changed_binding), self.assertRaises(ValueError):
            release.qualification_archive(binding['product_commit'])

    def test_stable_sql_chain_requires_exact_xlsx_predecessor_and_current_snapshot(self):
        spec = importlib.util.spec_from_file_location(
            'stable_sql_package_for_xlsx_test', ROOT / 'Scripts/Release/prepare_stable_sql_package.py')
        package = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(package)
        record = json.loads((ROOT / metadata.RECORD).read_bytes())
        product_source = json.loads((ROOT / 'Releases/1.0.0/product-source.json').read_bytes())
        csv_record = json.loads((ROOT / metadata.csv_metadata.RECORD).read_bytes())
        plan = {'product_commit': product_source['product_commit'], 'product_snapshot': product_source}
        self.assertEqual(package.advance_xlsx_product_chain(
            ROOT, record['product_chain_predecessor'], plan, csv_record), product_source['product_commit'])
        for key in ('historical_product_source', 'current_product_tree', 'product_chain_predecessor'):
            changed = copy.deepcopy(record)
            if key == 'historical_product_source':
                changed[key]['archive_sha256'] = '0' * 64
            elif key == 'current_product_tree':
                changed[key] = '0' * 40
            else:
                changed[key] = 'f' * 40
            with patch.object(package, 'bounded_file', side_effect=lambda path: (
                    metadata.encoded(changed) if path.name == 'xlsx-metadata-update.json'
                    else (ROOT / 'Releases/1.0.0/product-source.json').read_bytes())):
                with self.subTest(field=key), self.assertRaises(ValueError):
                    package.advance_xlsx_product_chain(ROOT, record['product_chain_predecessor'],
                                                        plan, csv_record)
        forged = copy.deepcopy(record)
        forged['current_product_commit'] = 'f' * 40
        forged['current_product_tree'] = 'a' * 40
        forged_source = dict(product_source, product_commit='f' * 40, tree_oid='a' * 40)
        forged_plan = {'product_commit': 'f' * 40, 'product_snapshot': forged_source}
        with patch.object(package, 'bounded_file', side_effect=lambda path: (
                metadata.encoded(forged) if path.name == 'xlsx-metadata-update.json'
                else json.dumps(forged_source).encode('utf-8'))):
            with self.assertRaises(ValueError):
                package.advance_xlsx_product_chain(ROOT, record['product_chain_predecessor'],
                                                    forged_plan, csv_record)

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
