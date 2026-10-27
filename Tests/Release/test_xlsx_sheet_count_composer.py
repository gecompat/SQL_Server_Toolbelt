"""Offline-Orakel für die feste 32/33-Worksheetgrenze."""
from pathlib import Path
import hashlib
import json
import shutil
import unittest
import uuid
import xml.etree.ElementTree as ET
import zipfile
import io

from compose_xlsx_sheet_count import (
    FIXTURE,
    OVERFLOW_COUNT,
    POSITIVE_COUNT,
    ROOT,
    compose_sources,
    validate_output_path,
    write_output,
)

NS = {'m': 'http://schemas.openxmlformats.org/spreadsheetml/2006/main',
      'r': 'http://schemas.openxmlformats.org/package/2006/relationships'}


class XlsxSheetCountComposerMixin:
    def test_xlsx_sheet_count_composes_exact_counts_and_fixed_names(self):
        outputs, metadata = compose_sources(FIXTURE.read_bytes())
        self.assertEqual(metadata['counts'], {'positive': 32, 'overflow': 33})
        self.assertEqual(metadata['names'], [f'Sheet{i:02d}' for i in range(1, 33)])
        self.assertEqual(metadata['overflow_name'], 'Sheet33')
        self.assertEqual(metadata['visibility'], 'visible')
        self.assertIs(metadata['date1904'], False)
        self.assertEqual(set(outputs), {'Xlsx.Sheets.32.xlsx', 'Xlsx.Sheets.33.xlsx'})

        for filename, count in (('Xlsx.Sheets.32.xlsx', POSITIVE_COUNT),
                                ('Xlsx.Sheets.33.xlsx', OVERFLOW_COUNT)):
            data = outputs[filename]
            self.assertLess(len(data), 16 * 1024 * 1024)
            self.assertEqual(hashlib.sha256(data).hexdigest(), metadata['outputs'][filename]['sha256'])
            with zipfile.ZipFile(io.BytesIO(data)) as archive:
                self.assertIsNone(archive.testzip())
                workbook = ET.fromstring(archive.read('xl/workbook.xml'))
                sheets = workbook.findall('m:sheets/m:sheet', NS)
                self.assertEqual(len(sheets), count)
                self.assertEqual([s.get('name') for s in sheets],
                                 [f'Sheet{i:02d}' for i in range(1, count + 1)])
                self.assertEqual([s.get('{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id')
                                  for s in sheets], [f'rId{i}' for i in range(1, count + 1)])
                self.assertEqual(workbook.find('m:workbookPr', NS).get('date1904'), '0')
                rels = ET.fromstring(archive.read('xl/_rels/workbook.xml.rels'))
                relationships = rels.findall('r:Relationship', NS)
                self.assertEqual(len(relationships), count)
                self.assertEqual([r.get('Target') for r in relationships],
                                 [f'worksheets/sheet{i}.xml' for i in range(1, count + 1)])
                self.assertEqual(len(archive.namelist()), count + 4)
                self.assertNotIn('xl/sharedStrings.xml', archive.namelist())
                for i in range(1, count + 1):
                    sheet = ET.fromstring(archive.read(f'xl/worksheets/sheet{i}.xml'))
                    self.assertIsNotNone(sheet.find('m:sheetData', NS))
                self.assertTrue(all(info.compress_type == zipfile.ZIP_STORED and
                                    info.file_size == info.compress_size and
                                    info.date_time == (2020, 2, 3, 4, 5, 6)
                                    for info in archive.infolist()))

    def test_xlsx_sheet_count_rejects_wrong_api_or_parameter_oracle(self):
        fixture = FIXTURE.read_bytes()
        with self.assertRaisesRegex(ValueError, 'XLSX_SHEET_FIXTURE_API_BINDING'):
            compose_sources(fixture.replace(b'toolbelt_file.USP_ListXlsxWorksheets',
                                            b'toolbelt_file.USP_ReadXlsxWorksheetCells'))
        with self.assertRaisesRegex(ValueError, 'XLSX_SHEET_FIXTURE_MUST_USE_DEFAULT_LIMIT'):
            compose_sources(fixture.replace(b'@XlsxBinary=@XlsxBinary',
                                            b'@XlsxBinary=@XlsxBinary,@MaxSheets=32'))
        with self.assertRaisesRegex(ValueError, 'XLSX_SHEET_FIXTURE_SCOPE'):
            compose_sources(fixture + b'-- USP_ReadXlsxWorksheetCells')

    def test_xlsx_sheet_count_output_is_fresh_and_runtime_scoped(self):
        runtime = ROOT / '.runtime'
        runtime.mkdir(exist_ok=True)
        output = runtime / ('xlsx-sheet-count-test-' + uuid.uuid4().hex)
        try:
            manifest = write_output(output)
            saved = json.loads((output / 'composition.json').read_bytes())
            self.assertEqual(saved, manifest)
            for name, record in manifest['outputs'].items():
                path = output / name
                self.assertEqual(path.stat().st_size, record['bytes'])
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), record['sha256'])
            with self.assertRaisesRegex(ValueError, 'XLSX_SHEET_OUTPUT_SCOPE'):
                write_output(output)
            with self.assertRaisesRegex(ValueError, 'XLSX_SHEET_OUTPUT_SCOPE'):
                validate_output_path(ROOT / ('outside-' + uuid.uuid4().hex))
        finally:
            if output.exists() and output.resolve().parent == runtime.resolve() and output.name.startswith('xlsx-sheet-count-test-'):
                shutil.rmtree(output)


class XlsxSheetCountComposerTests(XlsxSheetCountComposerMixin, unittest.TestCase):
    pass
