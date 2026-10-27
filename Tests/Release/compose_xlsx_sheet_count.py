"""Komponiert zwei kleine synthetische XLSX-Workbooks mit 32 oder 33 Sheets."""
from __future__ import annotations

from pathlib import Path
import hashlib
import io
import json
import os
import stat
import argparse
import zipfile

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'Tests/Release/Runtime/Xlsx.SheetCount.sql'
POSITIVE_COUNT = 32
OVERFLOW_COUNT = 33
TIMESTAMP = (2020, 2, 3, 4, 5, 6)
SHEET_NS = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
OFFICE_REL_NS = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
PACKAGE_REL_NS = 'http://schemas.openxmlformats.org/package/2006/relationships'
CONTENT_TYPES_NS = 'http://schemas.openxmlformats.org/package/2006/content-types'


def _workbook(sheet_count: int) -> bytes:
    if sheet_count not in (POSITIVE_COUNT, OVERFLOW_COUNT):
        raise ValueError('XLSX_SHEET_COUNT_UNSUPPORTED')
    sheets = ''.join(
        f'<sheet name="Sheet{ordinal:02d}" sheetId="{ordinal}" r:id="rId{ordinal}"/>'
        for ordinal in range(1, sheet_count + 1)
    )
    workbook = (f'<workbook xmlns="{SHEET_NS}" xmlns:r="{OFFICE_REL_NS}">'
                '<workbookPr date1904="0"/><sheets>' + sheets + '</sheets></workbook>')
    root_rels = (f'<Relationships xmlns="{PACKAGE_REL_NS}"><Relationship Id="rId1" '
                 f'Type="{OFFICE_REL_NS}/officeDocument" Target="xl/workbook.xml"/></Relationships>')
    workbook_rels = '<Relationships xmlns="' + PACKAGE_REL_NS + '">' + ''.join(
        f'<Relationship Id="rId{ordinal}" Type="{OFFICE_REL_NS}/worksheet" '
        f'Target="worksheets/sheet{ordinal}.xml"/>'
        for ordinal in range(1, sheet_count + 1)
    ) + '</Relationships>'
    content_types = (f'<Types xmlns="{CONTENT_TYPES_NS}">'
                     '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                     '<Default Extension="xml" ContentType="application/xml"/>'
                     '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
                     + ''.join(
                         f'<Override PartName="/xl/worksheets/sheet{ordinal}.xml" '
                         'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
                         for ordinal in range(1, sheet_count + 1)
                     ) + '</Types>')
    parts = {
        '[Content_Types].xml': content_types,
        '_rels/.rels': root_rels,
        'xl/workbook.xml': workbook,
        'xl/_rels/workbook.xml.rels': workbook_rels,
    }
    for ordinal in range(1, sheet_count + 1):
        parts[f'xl/worksheets/sheet{ordinal}.xml'] = (
            f'<worksheet xmlns="{SHEET_NS}"><sheetData/></worksheet>')
    output = io.BytesIO()
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_STORED, strict_timestamps=True) as archive:
        for name, content in parts.items():
            info = zipfile.ZipInfo(name, TIMESTAMP)
            info.compress_type = zipfile.ZIP_STORED
            info.create_system = 0
            info.external_attr = 0
            archive.writestr(info, content.encode('utf-8'))
    return output.getvalue()


def compose_sources(fixture: bytes) -> tuple[dict[str, bytes], dict]:
    if fixture.count(b'toolbelt_file.USP_ListXlsxWorksheets') != 1:
        raise ValueError('XLSX_SHEET_FIXTURE_API_BINDING')
    if b'@MaxSheets' in fixture:
        raise ValueError('XLSX_SHEET_FIXTURE_MUST_USE_DEFAULT_LIMIT')
    if b'USP_ReadXlsxWorksheetCells' in fixture:
        raise ValueError('XLSX_SHEET_FIXTURE_SCOPE')
    outputs = {
        'Xlsx.Sheets.32.xlsx': _workbook(POSITIVE_COUNT),
        'Xlsx.Sheets.33.xlsx': _workbook(OVERFLOW_COUNT),
    }
    metadata = {
        'schema': 'xlsx-sheet-count-composition/v1',
        'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
        'fixture_bytes': len(fixture),
        'counts': {'positive': POSITIVE_COUNT, 'overflow': OVERFLOW_COUNT},
        'names': [f'Sheet{ordinal:02d}' for ordinal in range(1, POSITIVE_COUNT + 1)],
        'overflow_name': 'Sheet33',
        'visibility': 'visible',
        'date1904': False,
        'zip_method': 'stored',
        'timestamp_dos': '2020-02-03 04:05:06',
        'outputs': {name: {'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data)}
                    for name, data in outputs.items()},
    }
    return outputs, metadata


def validate_output_path(output: Path) -> Path:
    runtime = ROOT / '.runtime'
    if not runtime.exists():
        runtime.mkdir()
    attributes = getattr(runtime.lstat(), 'st_file_attributes', 0)
    if runtime.is_symlink() or stat.S_ISLNK(runtime.lstat().st_mode) or attributes & 0x400:
        raise ValueError('XLSX_SHEET_RUNTIME_REPARSE')
    runtime_path = runtime.resolve(strict=True)
    resolved = output.absolute()
    if runtime_path != runtime.absolute() or resolved.parent != runtime.absolute() or os.path.lexists(resolved):
        raise ValueError('XLSX_SHEET_OUTPUT_SCOPE')
    return resolved


def write_output(output: Path) -> dict:
    destination = validate_output_path(output)
    fixture = FIXTURE.read_bytes()
    outputs, metadata = compose_sources(fixture)
    destination.mkdir(parents=True, exist_ok=False)
    for name, data in outputs.items():
        (destination / name).write_bytes(data)
    (destination / 'Xlsx.SheetCount.sql').write_bytes(fixture)
    (destination / 'composition.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    print(json.dumps(write_output(parser.parse_args().output), sort_keys=True))


if __name__ == '__main__':
    main()
