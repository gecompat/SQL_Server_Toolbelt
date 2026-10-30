"""Exact CSV permission/payload deltas and missing-commit recovery controls."""
from pathlib import Path
import json
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'Scripts/Release'))
import csv_metadata as metadata
import help_contract_source
import prepare_release as release
import xlsx_metadata


class CsvMetadataTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.baseline = {p: metadata.historical(ROOT, p) for p in
                        (metadata.MANIFEST, metadata.REPORT, *metadata.DOCS)}

    def fixture(self):
        previous = dict(self.baseline)
        previous['Deployment/Contoso.sql'] = b'SELECT 1;\n'
        previous['Modules/Contoso/README.md'] = b'old public guide\n'
        baseline = dict(previous)
        baseline['Modules/Contoso/README.md'] = b'current public guide\n'
        current = dict(baseline)
        current[metadata.MANIFEST] = metadata.corrected_manifest(previous[metadata.MANIFEST])
        for p in metadata.DOCS:
            current[p] = metadata.corrected_documentation(p, baseline[p])
        changed = sorted(p for p in previous if previous[p] != current[p]
                         and p.startswith(('Modules/', 'Deployment/', 'Workers/')))
        record = {'schema_version': '1.0', 'kind': 'exact_csv_caller_metadata_projection',
                  'public_baseline_commit': metadata.BASELINE, 'publication_authorized': False,
                  'automatic_grants_added': False, 'module_statuses_changed': False,
                  'metadata_preparation_commit': 'a' * 40,
                  'manifest': {'path': metadata.MANIFEST,
                               'executed_sha256': metadata.digest(previous[metadata.MANIFEST]),
                               'current_sha256': metadata.digest(current[metadata.MANIFEST])},
                  'historical_report_sha256': metadata.digest(baseline[metadata.REPORT]),
                  'changed_product_paths': changed,
                  'previous_source_sha256': {p: metadata.digest(previous[p]) for p in changed},
                  'current_source_sha256': {p: metadata.digest(current[p]) for p in changed}}
        return previous, current, baseline, record

    def test_actual_manifest_and_original_execution_report(self):
        original = self.baseline[metadata.MANIFEST]
        metadata.validate_manifest(original, (ROOT / metadata.MANIFEST).read_bytes())
        self.assertEqual((ROOT / metadata.REPORT).read_bytes(), self.baseline[metadata.REPORT])
        metadata.validate_source(ROOT, metadata.MANIFEST, metadata.digest(original))
        for p in metadata.DOCS:
            self.assertEqual((ROOT / p).read_bytes(), metadata.corrected_documentation(p, self.baseline[p]))

    def test_other_manifest_fields_and_unknown_source_exceptions_fail(self):
        old = self.baseline[metadata.MANIFEST]
        new = metadata.corrected_manifest(old)
        for before, after in ((b'unreleased', b'released'), (b'1.0.0', b'9.9.9'),
                              (b'dependencies:', b'changed_dependencies:'),
                              (b'55300-55309', b'55300-55399')):
            self.assertIn(before, new)
            with self.subTest(field=before), self.assertRaises(ValueError):
                metadata.validate_manifest(old, new.replace(before, after))
        for p in ('Deployment/Deploy-All.ps1', 'Modules/toolbelt.json.schema/module.yaml'):
            with self.assertRaises(ValueError):
                metadata.validate_source(ROOT, p, '0' * 64)
        with self.assertRaises(ValueError):
            metadata.validate_source(ROOT, metadata.MANIFEST, '0' * 64)

    def test_product_delta_rejects_runtime_unknown_metadata_and_unpublished_docs(self):
        old, new, baseline, record = self.fixture()
        self.assertEqual(metadata.validate_product_delta(old, new, record, baseline), set(record['changed_product_paths']))
        for path in ('Deployment/Contoso.sql', 'Modules/Contoso/module.yaml',
                     'Modules/toolbelt.tsql.ssis-debug/Source/Contoso.sql',
                     'Modules/Contoso/README.md', metadata.REPORT):
            broken = dict(new); broken[path] = b'unqualified change\n'
            with self.subTest(path=path), self.assertRaises(ValueError):
                metadata.validate_product_delta(old, broken, record, baseline)

    def test_clr_delta_preserves_all_executables_and_exact_overlay(self):
        _, files, _, record = self.fixture()
        original = {'Binaries/Contoso.dll': b'synthetic binary', 'SQL/Install-Contoso.sql': b'SELECT 1;',
                    'QUALIFICATION.json': b'{"synthetic":true}', 'LICENSE.md': b'synthetic license',
                    'START-HERE.md': b'synthetic guide\n'}
        original['CLR-PACKAGE.json'] = release.encoded({'source_commit': 'b' * 40, 'publication_authorized': False,
                                                       'profiles': {'synthetic': []}, 'files': {}})
        new = metadata.refreshed_clr_payload(original, files, 'a' * 40, record)
        metadata.validate_clr_delta(original, new, record, files, 'a' * 40)
        for path in (*original, 'METADATA-UPDATE.json', 'Sources/' + metadata.MANIFEST,
                     'Sources/Modules/Contoso/unknown.sql'):
            broken = dict(new); broken[path] = b'unqualified change'
            with self.subTest(path=path), self.assertRaises(ValueError):
                metadata.validate_clr_delta(original, broken, record, files, 'a' * 40)
        with self.assertRaises(ValueError):
            metadata.validate_clr_delta(original, new, record, files, 'c' * 40)

    def test_current_clr_delivery_has_exact_historical_bytes_and_proof(self):
        path = release.CLR_PACKAGE
        old = release.git('show', metadata.BASELINE + ':' + path)
        prefix = 'SQL-Server-Toolbelt-1.0.0-CLR-Install/'
        unpack = lambda b: {p[len(prefix):]: v for p, v in release.read_zip(b).items()}
        before, after = unpack(old), unpack((ROOT / path).read_bytes())
        product_source = json.loads((ROOT / 'Releases/1.0.0/product-source.json').read_bytes())
        _, product_files, product_tree = release.qualification_sources(product_source['product_commit'])
        self.assertEqual(product_tree, product_source['tree_oid'])
        xlsx_sources = {p: product_files[p]
                        for p in (*xlsx_metadata.PACKAGE_SOURCES, *xlsx_metadata.REPORTS)}
        xlsx_sources[xlsx_metadata.RECORD] = (ROOT / xlsx_metadata.RECORD).read_bytes()
        zip_record = json.loads((ROOT / 'Releases/1.0.0/zip-metadata-update.json').read_bytes())
        _, zip_files, zip_tree = release.qualification_sources(zip_record['current_product_commit'])
        self.assertEqual(zip_tree, json.loads((ROOT / 'Releases/1.0.0/product-source.json').read_bytes())['tree_oid'])
        zip_sources = {p: zip_files[p] for p in release.zip_metadata.PACKAGE_SOURCES}
        zip_sources[release.zip_metadata.RECORD] = (ROOT / release.zip_metadata.RECORD).read_bytes()
        release.validate_zip_clr_metadata(after, zip_sources)
        original_guide = metadata.historical(ROOT, metadata.GUIDE)
        csv_projection = metadata.corrected_install_guide(original_guide)
        source_delta = json.loads((ROOT / help_contract_source.RECORD).read_bytes())
        baseline_guide = help_contract_source.validate_historical_source(
            ROOT, metadata.GUIDE, source_delta['baseline_source_sha256'][metadata.GUIDE])
        self.assertEqual(baseline_guide, csv_projection)
        current_guide = help_contract_source.validate_current_source(ROOT, metadata.GUIDE)
        self.assertIn(b'## CSV-Aufrufrechte', current_guide)
        self.assertIn(b'CSV-Parser und -Writer', current_guide)
        self.assertIn(b'CSV-METADATA-UPDATE.md', current_guide)
        for p in before:
            if p.startswith(('SQL/', 'Binaries/', 'ThirdParty/')) or p in ('QUALIFICATION.json', 'LICENSE.md', 'Install-ClrPackage.ps1'):
                self.assertEqual(before[p], after[p], p)
        missing = dict(after); del missing['METADATA-UPDATE.json']
        with self.assertRaises(ValueError):
            release.validate_zip_clr_metadata(missing, zip_sources)

    def test_missing_product_commit_recovers_bound_tree_and_rejects_drift(self):
        old, current, baseline, record = self.fixture()
        record.update(previous_product_commit='a' * 40, current_product_commit='b' * 40,
                      previous_product_tree='c' * 40, current_product_tree='d' * 40)
        def sources(product):
            return ({}, old, 'c' * 40) if product == 'a' * 40 else ({}, current, 'd' * 40)
        with tempfile.TemporaryDirectory(dir=ROOT / '.runtime', prefix='csv-recovery-') as tmp:
            root = Path(tmp); target = root / metadata.RECORD; target.parent.mkdir(parents=True)
            target.write_bytes(release.encoded(record))
            with patch.object(release, 'ROOT', root), patch.object(release, 'snapshot', return_value=(metadata.BASELINE, baseline)), \
                 patch.object(release, 'qualification_sources', side_effect=sources) as recovered, \
                 patch.object(release.subprocess, 'run', return_value=subprocess.CompletedProcess([], 1)):
                release.validate_csv_product_applicability('a' * 40, 'b' * 40, current)
                self.assertEqual(release.csv_metadata_product_sources(record), current)
                self.assertIn(unittest.mock.call('b' * 40), recovered.call_args_list)
                with patch.object(release, 'qualification_sources', return_value=({}, old, 'e' * 40)):
                    with self.assertRaisesRegex(ValueError, 'product tree'):
                        release.validate_csv_product_applicability('a' * 40, 'b' * 40, current)
                    with self.assertRaisesRegex(ValueError, 'product tree'):
                        release.csv_metadata_product_sources(record)
                broken = dict(current); broken['Deployment/Contoso.sql'] += b' changed'
                with self.assertRaises(ValueError):
                    release.validate_csv_product_applicability('a' * 40, 'b' * 40, broken)


if __name__ == '__main__':
    unittest.main()
