"""Offline-Oracle für die feste XLSX-Shared-String-Anzahlgrenze."""
from pathlib import Path
import hashlib
import json
import shutil
import unittest
import uuid
import xml.etree.ElementTree as ET
import zipfile
import io

from compose_xlsx_shared_string_count import (
    FIXTURE,
    OVERFLOW_COUNT,
    POSITIVE_COUNT,
    REFERENCES,
    ROOT,
    compose_sources,
    validate_output_path,
    write_output,
)

NS = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'}


class XlsxSharedStringCountComposerMixin:
    def test_xlsx_shared_string_count_composes_exact_counts_and_fixed_references(self):
        outputs, metadata = compose_sources(FIXTURE.read_bytes())
        self.assertEqual(metadata['counts'], {'positive': 50000, 'overflow': 50001})
        self.assertEqual(metadata['references'], [0, 24999, 49999])
        self.assertEqual(metadata['positive_expected_texts'], ['v00000', 'v24999', 'v49999'])
        self.assertTrue(metadata['overflow_references_remain_valid'])
        self.assertEqual(set(outputs), {'Xlsx.SharedStrings.50000.xlsx', 'Xlsx.SharedStrings.50001.xlsx'})

        for filename, count in (('Xlsx.SharedStrings.50000.xlsx', POSITIVE_COUNT),
                                ('Xlsx.SharedStrings.50001.xlsx', OVERFLOW_COUNT)):
            data = outputs[filename]
            self.assertLess(len(data), 16 * 1024 * 1024)
            self.assertEqual(hashlib.sha256(data).hexdigest(), metadata['outputs'][filename]['sha256'])
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                self.assertIsNone(archive.testzip())
                strings = ET.fromstring(archive.read('xl/sharedStrings.xml'))
                items = strings.findall('m:si', NS)
                self.assertEqual(len(items), count)
                self.assertIsNone(strings.get('count'))
                self.assertIsNone(strings.get('uniqueCount'))
                self.assertEqual([items[index].find('m:t', NS).text for index in REFERENCES],
                                 ['v00000', 'v24999', 'v49999'])
                sheet = ET.fromstring(archive.read('xl/worksheets/sheet1.xml'))
                cells = sheet.findall('.//m:c', NS)
                self.assertEqual([(cell.get('r'), cell.find('m:v', NS).text) for cell in cells],
                                 [('A1', '0'), ('B1', '24999'), ('C1', '49999')])
                self.assertTrue(all(info.compress_type == zipfile.ZIP_STORED and
                                    info.file_size == info.compress_size and
                                    info.date_time == (2020, 2, 3, 4, 5, 6)
                                    for info in archive.infolist()))

    def test_xlsx_shared_string_count_rejects_wrong_oracle_fixture(self):
        fixture = FIXTURE.read_bytes()
        with self.assertRaisesRegex(ValueError, 'XLSX_SST_FIXTURE_API_BINDING'):
            compose_sources(fixture.replace(b'toolbelt_file.USP_ReadXlsxWorksheetCells', b'toolbelt_file.USP_ListXlsxWorksheets'))
        with self.assertRaisesRegex(ValueError, 'XLSX_SST_FIXTURE_MUST_USE_DEFAULT_LIMIT'):
            compose_sources(fixture.replace(b'@SheetOrdinal=1', b'@SheetOrdinal=1,@MaxSharedStrings=50000'))

    def test_xlsx_shared_string_count_output_is_fresh_and_runtime_scoped(self):
        runtime = ROOT / '.runtime'
        runtime.mkdir(exist_ok=True)
        output = runtime / ('xlsx-shared-string-count-test-' + uuid.uuid4().hex)
        try:
            manifest = write_output(output)
            saved = json.loads((output / 'composition.json').read_bytes())
            self.assertEqual(saved, manifest)
            for name, record in manifest['outputs'].items():
                path = output / name
                self.assertEqual(path.stat().st_size, record['bytes'])
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), record['sha256'])
            with self.assertRaisesRegex(ValueError, 'XLSX_SST_OUTPUT_SCOPE'):
                write_output(output)
            with self.assertRaisesRegex(ValueError, 'XLSX_SST_OUTPUT_SCOPE'):
                validate_output_path(ROOT / ('outside-' + uuid.uuid4().hex))
        finally:
            if output.exists() and output.resolve().parent == runtime.resolve() and output.name.startswith('xlsx-shared-string-count-test-'):
                shutil.rmtree(output)


class XlsxSharedStringCountComposerTests(XlsxSharedStringCountComposerMixin, unittest.TestCase):
    pass
