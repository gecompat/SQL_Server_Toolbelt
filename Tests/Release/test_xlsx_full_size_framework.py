"""Quellenbindung und Gegenproben des begrenzten XLSX-Frameworknachweises."""
import hashlib
import json
from pathlib import Path
import unittest
import zipfile

ROOT = Path(__file__).resolve().parents[2]
REPORT = 'Releases/1.0.0/XLSX-FULL-SIZE-FRAMEWORK.json'
KINDS = ('archive', 'part', 'total', 'parts')
LIMITS = dict(archive_bytes=16777216, part_bytes=16777216, total_bytes=67108864, parts=256)
METRICS = dict(zip(KINDS, LIMITS))
SOURCE_PATHS = {
    'Modules/toolbelt.file.xlsx-memory/Clr/' + name for name in
    ('AssemblyInfo.cs', 'Workbook.cs', 'XlsxCellDisplay.cs', 'XlsxCellDisplayBridge.cs', 'XlsxCellType.cs', 'XlsxEntryPoints.cs')
} | {
    'Modules/toolbelt.archive.zip-memory/Clr/' + name for name in
    ('ArchiveSession.cs', 'Properties/AssemblyInfo.cs', 'Toolbelt.Archive.ZipMemory.csproj', 'ZipEntryProvider.cs', 'ZipWriter.cs')
} | {
    'Tests/Release/Invoke-XlsxFullSizeFramework.ps1', 'Tests/Release/compose_xlsx_full_size.py',
    'Tests/Release/Runtime/XlsxFullSize.Framework.cs',
    'Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1',
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def validate(record, read=lambda name: (ROOT / name).read_bytes()):
    def require(condition):
        if not condition:
            raise ValueError('XLSX full-size framework evidence differs')
    require(record['schema_version'] == 'toolbelt-xlsx-full-size-framework/v1')
    require(record['status'] == 'PASS_FRAMEWORK_ONLY')
    require(record['scope'] == 'unchanged-sst-candidate-core-and-status-tvf-net48')
    require(record['limits'] == LIMITS)
    require(record['not_executed'] == ['native_sql', 'deployment', 'rights', 'authenticated_tls', 'heap_peak', 'production_capacity'])
    require(record['product_changed'] is False and record['package_changed'] is False and record['publication_authorized'] is False)
    require(record['attempts'] == dict(preflight_failures=1, compile_failures=1, successful_framework_runs=1))
    require(record['positive_rows'] == 4 and record['atomic_error_rows'] == 4)
    require(set(record['source_sha256']) == SOURCE_PATHS)
    require(set(record['historical_report_sha256']) == {
        'Releases/1.0.0/xlsx-sst-budget-correction.json',
        'Releases/1.0.0/xlsx-boundary-qualification.json',
        'Releases/1.0.0/XLSX-ZIP-PACKAGE-FRAMEWORK-QUALIFICATION.json',
    })
    for path, expected in {**record['source_sha256'], **record['historical_report_sha256']}.items():
        require(not Path(path).is_absolute() and '..' not in Path(path).parts)
        require(sha(read(path).replace(b'\r\n', b'\n')) == expected)
    old = json.loads(read('Releases/1.0.0/xlsx-sst-budget-correction.json'))
    require(record['candidate_bundle'] == old['candidate_bundle']['path'])
    require(record['candidate_bundle_sha256'] == old['candidate_bundle']['sha256'])
    require(sha(read(record['candidate_bundle'])) == record['candidate_bundle_sha256'])
    require(record['xlsx_dll_sha256'] == old['candidate_dll_sha256'])
    require(record['zip_dll_sha256'] == old['zip_dependency_sha256'])
    require([case['name'] for case in record['cases']] ==
            [f'{kind}-{suffix}' for kind in KINDS for suffix in ('exact', 'plus-one')])
    for case in record['cases']:
        kind, suffix = case['name'].split('-', 1)
        over = suffix == 'plus-one'
        metric = METRICS[kind]
        require(case[metric] == LIMITS[metric] + int(over))
        require(all(case[key] <= cap for key, cap in LIMITS.items() if key != metric))
        require(len(case['sha256']) == 64 and all(c in '0123456789abcdef' for c in case['sha256']))
        expected = ('TBX_XLSX_ARCHIVE_LIMIT' if kind == 'archive' else 'TBX_XLSX_CONTAINER_INVALID') if over else 'NONE'
        technical = ('ZIP_ARCHIVE_LIMIT' if kind == 'archive' else 'ZIP_PART_LIMIT' if kind == 'parts' else 'ZIP_PART_OR_SUM_LIMIT') if over else 'NONE'
        require(case['expected_error'] == expected and case['technical_error'] == technical)
    return record


class XlsxFullSizeFrameworkTests(unittest.TestCase):
    def record(self):
        return json.loads((ROOT / REPORT).read_bytes())

    def test_current_evidence(self):
        validate(self.record())

    def test_no_upgrade_to_native_or_package_pass(self):
        for change in ({'status': 'PASS'}, {'not_executed': []}, {'package_changed': True}, {'publication_authorized': True}):
            record = self.record()
            record.update(change)
            with self.assertRaises(ValueError):
                validate(record)

    def test_missing_and_reduced_boundary_rejected(self):
        for mode in ('missing', 'reduced', 'wrong-category'):
            record = self.record()
            if mode == 'missing':
                record['cases'].pop()
            elif mode == 'reduced':
                record['cases'][0]['archive_bytes'] -= 1
            else:
                record['cases'][3]['expected_error'] = 'TBX_XLSX_BUDGET_EXCEEDED'
            with self.assertRaises(ValueError):
                validate(record)

    def test_changed_source_rejected(self):
        record = self.record()
        changed = 'Tests/Release/Runtime/XlsxFullSize.Framework.cs'
        with self.assertRaises(ValueError):
            validate(record, lambda path: (ROOT / path).read_bytes() + (b'// drift' if path == changed else b''))
        record['source_sha256'].pop(changed)
        with self.assertRaises(ValueError):
            validate(record)

    def test_bundle_contains_exact_executed_dlls(self):
        record = validate(self.record())
        with zipfile.ZipFile(ROOT / record['candidate_bundle']) as archive:
            for module, key in (('File.XlsxMemory', 'xlsx_dll_sha256'), ('Archive.ZipMemory', 'zip_dll_sha256')):
                self.assertEqual(sha(archive.read('Binaries/Toolbelt.' + module + '.dll')), record[key])

    def test_adapter_uses_fixed_product_limits(self):
        source = (ROOT / 'Tests/Release/Runtime/XlsxFullSize.Framework.cs').read_text(encoding='utf-8')
        self.assertIn('16777216, 16777216, 67108864, 256, 32, 100000, 50000, 8388608,', source)
        self.assertIn('64, new SqlDecimal(200), 5000', source)
        self.assertIn('new Workbook(binary, null).ReadCells(1)', source)
        self.assertIn('Require(count == 1', source)


if __name__ == '__main__':
    unittest.main()
