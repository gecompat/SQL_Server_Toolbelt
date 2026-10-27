"""Begrenzte Manifest- und CLR-Paketprojektion für bereits qualifizierte XLSX-Rechte."""
from pathlib import Path
import copy
import hashlib
import importlib.util
import io
import json
import subprocess
import sys
import tempfile
import unittest
import zipfile
from functools import lru_cache
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import prepare_release as release
import xlsx_metadata as metadata

_ORIGINAL_SNAPSHOT = release.snapshot
_ORIGINAL_RECOVERED_SNAPSHOT = release.recovered_snapshot
_BASELINE_COMMITS = frozenset((metadata.BASELINE, metadata.DOCUMENTATION_TRANSITION_START))


def _load_baseline_snapshot(root, commit):
    if root != str(ROOT.resolve()) or commit not in _BASELINE_COMMITS:
        raise ValueError('Only the exact XLSX metadata baseline snapshots may be shared.')
    resolved, files = _ORIGINAL_SNAPSHOT(commit)
    if resolved != commit:
        raise ValueError('The immutable baseline snapshot resolved to another commit.')
    return resolved, tuple(sorted((path, bytes(data)) for path, data in files.items()))


@lru_cache(maxsize=6)
def _immutable_baseline_snapshot(root, commit):
    if len(commit) != 40 or any(character not in '0123456789abcdef' for character in commit):
        raise ValueError('A complete lowercase commit OID is required for a shared baseline.')
    return _load_baseline_snapshot(root, commit)


def _baseline_snapshot(root, commit):
    resolved, frozen_files = _immutable_baseline_snapshot(str(Path(root).resolve()), commit)
    return resolved, dict(frozen_files)


def _snapshot_with_test_fixture(commit, repository=None, env=None):
    root = Path(repository).resolve() if repository is not None else ROOT.resolve()
    if env is None and root == ROOT.resolve() and commit in _BASELINE_COMMITS:
        return _baseline_snapshot(root, commit)
    return _ORIGINAL_SNAPSHOT(commit, repository=repository, env=env)


def _load_recovered_fixture(root, bundle_sha256, commit, product_commit, bundle_bytes):
    if root != str(ROOT.resolve()):
        raise ValueError('Only this test repository may reuse a recovered bundle fixture.')
    if hashlib.sha256(bundle_bytes).hexdigest() != bundle_sha256:
        raise ValueError('Recovered bundle fixture hash mismatch.')
    sources, product, tree = _ORIGINAL_RECOVERED_SNAPSHOT(bundle_bytes, commit, product_commit)
    return (tuple(sorted((path, bytes(data)) for path, data in sources.items())),
            tuple(sorted((path, bytes(data)) for path, data in product.items())), tree)


@lru_cache(maxsize=6)
def _immutable_recovered_fixture(root, bundle_sha256, commit, product_commit, bundle_bytes):
    for value in (commit, product_commit):
        if not isinstance(value, str) or len(value) != 40 \
                or any(character not in '0123456789abcdef' for character in value):
            raise ValueError('Recovered fixture requires exact lowercase commit OIDs.')
    if not isinstance(bundle_bytes, bytes) or len(bundle_bytes) > 16 * 1024 * 1024:
        raise ValueError('Recovered fixture bundle exceeds its immutable input bound.')
    return _load_recovered_fixture(root, bundle_sha256, commit, product_commit, bundle_bytes)


def _recovered_snapshot_with_test_fixture(bundle_bytes, commit, product_commit):
    root = str(ROOT.resolve())
    bundle_sha256 = hashlib.sha256(bundle_bytes).hexdigest()
    sources, product, tree = _immutable_recovered_fixture(
        root, bundle_sha256, commit, product_commit, bundle_bytes)
    return dict(sources), dict(product), tree


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
    _, previous_files = _baseline_snapshot(ROOT, metadata.BASELINE)
    _, transition_previous_files, _ = release.qualification_sources(metadata.DOCUMENTATION_TRANSITION_START)
    _, transition_current_files = _baseline_snapshot(ROOT, metadata.BASELINE)
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
    def setUp(self):
        self._snapshot_fixture_patch = patch.object(release, 'snapshot', side_effect=_snapshot_with_test_fixture)
        self._snapshot_fixture_patch.start()
        self.addCleanup(self._snapshot_fixture_patch.stop)
        self._recovered_fixture_patch = patch.object(
            release, 'recovered_snapshot', side_effect=_recovered_snapshot_with_test_fixture)
        self._recovered_fixture_patch.start()
        self.addCleanup(self._recovered_fixture_patch.stop)

    def test_recovered_bundle_fixture_uses_exact_hash_oids_root_and_fresh_mappings(self):
        _immutable_recovered_fixture.cache_clear()
        self.addCleanup(_immutable_recovered_fixture.cache_clear)
        bundle = b'fixed immutable synthetic bundle'
        bundle_hash = hashlib.sha256(bundle).hexdigest()
        calls = []

        def load(root, digest, commit, product, data):
            calls.append((root, digest, commit, product, data))
            return ((('source.sql', b'source'),), (('module.yaml', b'product'),), 'c' * 40)

        with patch(__name__ + '._load_recovered_fixture', side_effect=load):
            root_a = str((ROOT / '.runtime' / 'recovered-root-a').resolve())
            root_b = str((ROOT / '.runtime' / 'recovered-root-b').resolve())
            sources, product, _ = _immutable_recovered_fixture(
                root_a, bundle_hash, metadata.BASELINE, metadata.BASELINE, bundle)
            sources = dict(sources); sources['caller-only'] = b'mutation'
            again, _, _ = _immutable_recovered_fixture(
                root_a, bundle_hash, metadata.BASELINE, metadata.BASELINE, bundle)
            _immutable_recovered_fixture(root_b, bundle_hash, metadata.BASELINE, metadata.BASELINE, bundle)
            changed = bundle + b'!'
            _immutable_recovered_fixture(
                root_a, hashlib.sha256(changed).hexdigest(), metadata.BASELINE, metadata.BASELINE, changed)
            _immutable_recovered_fixture(
                root_a, bundle_hash, metadata.DOCUMENTATION_TRANSITION_START, metadata.BASELINE, bundle)
            _immutable_recovered_fixture(
                root_a, bundle_hash, metadata.BASELINE, metadata.DOCUMENTATION_TRANSITION_START, bundle)
            wrapped_sources, _, _ = _recovered_snapshot_with_test_fixture(
                bundle, metadata.BASELINE, metadata.BASELINE)
            wrapped_sources['caller-only'] = b'mutation'
            fresh_sources, _, _ = _recovered_snapshot_with_test_fixture(
                bundle, metadata.BASELINE, metadata.BASELINE)
        self.assertNotIn('caller-only', dict(again))
        self.assertNotIn('caller-only', fresh_sources)
        self.assertEqual(product, (('module.yaml', b'product'),))
        self.assertEqual(len(calls), 6)
        self.assertEqual(_immutable_recovered_fixture.cache_info().maxsize, 6)
        with self.assertRaises(ValueError):
            _immutable_recovered_fixture(str(ROOT.resolve()), '0' * 64,
                                          metadata.BASELINE, metadata.BASELINE, bundle)
        with self.assertRaises(ValueError):
            _immutable_recovered_fixture(root_a, bundle_hash, 'A' * 40, metadata.BASELINE, bundle)
        _immutable_recovered_fixture.cache_clear()

    def test_git_baseline_snapshot_fixture_is_bounded_and_returns_fresh_mappings(self):
        _immutable_baseline_snapshot.cache_clear()
        self.addCleanup(_immutable_baseline_snapshot.cache_clear)
        loader = lambda root, commit: (commit, ((f'{root}/{commit}', b'fixed'),))
        with patch(__name__ + '._load_baseline_snapshot', side_effect=loader) as load:
            first_root = str((ROOT / '.runtime' / 'snapshot-root-a').resolve())
            second_root = str((ROOT / '.runtime' / 'snapshot-root-b').resolve())
            first, files = _baseline_snapshot(first_root, metadata.BASELINE)
            files['mutated'] = b'caller-local'
            again, clean_files = _baseline_snapshot(first_root, metadata.BASELINE)
            _baseline_snapshot(second_root, metadata.BASELINE)
            _baseline_snapshot(first_root, metadata.DOCUMENTATION_TRANSITION_START)
            for digit in 'cdef':
                _baseline_snapshot(first_root, digit * 40)
            _baseline_snapshot(first_root, metadata.BASELINE)
        self.assertEqual(first, metadata.BASELINE)
        self.assertEqual(again, metadata.BASELINE)
        self.assertNotIn('mutated', clean_files)
        self.assertEqual(_immutable_baseline_snapshot.cache_info().maxsize, 6)
        self.assertEqual(load.call_count, 8)
        with self.assertRaises(ValueError):
            _baseline_snapshot(first_root, 'A' * 40)
        _immutable_baseline_snapshot.cache_clear()

    def test_historical_archive_cache_is_bounded_and_uses_exact_root_commit_path(self):
        first = 'a' * 40
        second = 'b' * 40
        manifest_path = 'SQL-Server-Toolbelt-1.0.0-candidate-source/PACKAGE-MANIFEST.json'

        def make_archive(product, root):
            output = io.BytesIO()
            with zipfile.ZipFile(output, 'w') as archive:
                archive.writestr(manifest_path,
                                 json.dumps({'product_commit': product, 'root': root}).encode())
            return output.getvalue()

        calls = []
        def run(args, cwd, **kwargs):
            oid, path = args[2].split(':', 1)
            calls.append((str(Path(cwd).resolve()), oid, path))
            payload = make_archive(oid, str(Path(cwd).resolve()))
            return subprocess.CompletedProcess(args, 0, stdout=payload, stderr=b'')

        metadata._historical_source_archive.cache_clear()
        self.addCleanup(metadata._historical_source_archive.cache_clear)
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime', prefix='xlsx-zip-cache-') as folder:
            root_a = Path(folder) / 'a'
            root_b = Path(folder) / 'b'
            for path in (root_a, root_b):
                path.mkdir()
            with patch.object(metadata.subprocess, 'run', side_effect=run):
                original, header = metadata.historical_source_archive(root_a, first,
                                                                       metadata.HISTORICAL_SOURCE_ARCHIVE)
                again, header_again = metadata.historical_source_archive(root_a, first,
                                                                          metadata.HISTORICAL_SOURCE_ARCHIVE)
                other_root, _ = metadata.historical_source_archive(root_b, first,
                                                                     metadata.HISTORICAL_SOURCE_ARCHIVE)
                other_oid, _ = metadata.historical_source_archive(root_a, second,
                                                                    metadata.HISTORICAL_SOURCE_ARCHIVE)
            self.assertEqual((original, header), (again, header_again))
            self.assertNotEqual(original, other_root)
            self.assertNotEqual(original, other_oid)
            self.assertEqual(len(calls), 3)
            self.assertEqual(metadata._historical_source_archive.cache_info().maxsize, 2)
            for bad_commit, bad_path in (('c' * 39, metadata.HISTORICAL_SOURCE_ARCHIVE),
                                         (first, '../candidate-source.zip')):
                with self.assertRaises(ValueError):
                    metadata.historical_source_archive(root_a, bad_commit, bad_path)

            current_proof_root = Path(folder) / 'mutable-proof'
            csv_record_path = current_proof_root / metadata.csv_metadata.RECORD
            csv_record_path.parent.mkdir(parents=True)
            csv_record = json.loads((ROOT / metadata.csv_metadata.RECORD).read_bytes())
            csv_record_path.write_bytes(metadata.encoded(csv_record))
            proof_calls = []
            def proof_run(args, cwd, **kwargs):
                proof_calls.append(args[2])
                return subprocess.CompletedProcess(args, 0,
                    stdout=make_archive(metadata.DOCUMENTATION_TRANSITION_START,
                                        str(Path(cwd).resolve())), stderr=b'')
            with patch.object(metadata.subprocess, 'run', side_effect=proof_run):
                before = metadata.predecessor_source_binding(current_proof_root)
                changed_csv = json.loads(csv_record_path.read_bytes())
                changed_csv['current_product_tree'] = 'c' * 40
                csv_record_path.write_bytes(metadata.encoded(changed_csv))
                after = metadata.predecessor_source_binding(current_proof_root)
            self.assertEqual(before['archive_sha256'], after['archive_sha256'])
            self.assertNotEqual(before['product_tree'], after['product_tree'])
            self.assertEqual(len(proof_calls), 1,
                             'Mutable CSV proof should be reread while immutable archive is cached.')

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
        _, baseline = _baseline_snapshot(ROOT, metadata.BASELINE)
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
        expected_test = metadata.corrected_offline_source(original_test)
        if (ROOT / 'Releases/1.0.0/zip-metadata-update.json').is_file():
            import zip_metadata
            expected_test = zip_metadata.corrected_xlsx_offline_source(expected_test)
        import xlsx_sst_budget
        expected_test = xlsx_sst_budget.project_cell_test(expected_test)
        self.assertEqual(expected_test, current_test)
        self.assertNotEqual(expected_test,
                            current_test.replace(b'continue', b'pass', 1))

        xlsx_product = record['current_product_commit']
        _, current, _ = release.qualification_sources(xlsx_product)
        release.validate_product_applicability(record['product_chain_predecessor'],
                                                xlsx_product, current)
        altered = dict(current)
        path = 'Modules/toolbelt.file.xlsx-memory/README.md'
        altered[path] += b'\n'
        with self.assertRaises(ValueError):
            release.validate_product_applicability(record['product_chain_predecessor'],
                                                    xlsx_product, altered)

    def test_missing_predecessor_commit_recovers_only_from_bound_public_archive(self):
        record = json.loads((ROOT / metadata.RECORD).read_bytes())
        binding = record['historical_product_source']
        real_git = release.git
        # This case must cold-reconstruct from the real public-only object
        # database; no immutable test fixture may satisfy it.
        _immutable_baseline_snapshot.cache_clear()
        _immutable_recovered_fixture.cache_clear()
        recovered_cache_before = _immutable_recovered_fixture.cache_info()
        metadata._historical_source_archive.cache_clear()
        cache_before = metadata._historical_source_archive.cache_info()
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
                recovery_calls = []
                actual_recovery = release.recovered_snapshot
                def count_recovery(*args, **kwargs):
                    recovery_calls.append(args[2])
                    return actual_recovery(*args, **kwargs)
                with patch.object(release, 'recovered_snapshot', side_effect=count_recovery):
                    _, product_files, tree = release.qualification_sources(binding['product_commit'])
                    archive = release.qualification_archive(binding['product_commit'])
                self.assertEqual(tree, binding['product_tree'])
                self.assertEqual(release.sha(archive), binding['archive_sha256'])
                self.assertEqual(recovery_calls, [binding['product_commit']])
                self.assertTrue(product_files)
        cache_after = metadata._historical_source_archive.cache_info()
        self.assertEqual(cache_after.misses - cache_before.misses, 1)
        self.assertGreaterEqual(cache_after.hits - cache_before.hits, 1)
        recovered_cache_after = _immutable_recovered_fixture.cache_info()
        self.assertEqual(recovered_cache_after.misses - recovered_cache_before.misses, 1)
        self.assertEqual(recovered_cache_after.hits - recovered_cache_before.hits, 0,
                         'Public-only predecessor must cold-recover from its bound bundle.')

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
        changed_history = copy.deepcopy(record)
        changed_history['documentation_transition']['previous_source_sha256'][
            metadata.DOCUMENTATION_TRANSITION_PATHS[0]] = '0' * 64
        mutations.append(changed_history)
        for changed in mutations:
            with self.subTest(keys=set(changed) - set(record)), self.assertRaises(ValueError):
                metadata.validate_record(changed, original, current, previous_package,
                                         previous, sources, raw, cell)


class XlsxMetadataTests(XlsxMetadataMixin, unittest.TestCase):
    pass


if __name__ == '__main__':
    unittest.main()
