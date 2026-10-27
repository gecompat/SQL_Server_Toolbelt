"""Componiert zwei synthetische XLSX-Dateien für das SST-Limit."""
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
FIXTURE = ROOT / 'Tests/Release/Runtime/Xlsx.SharedStringCount.sql'
POSITIVE_COUNT = 50_000
OVERFLOW_COUNT = 50_001
REFERENCES = (0, 24_999, 49_999)
TIMESTAMP = (2020, 2, 3, 4, 5, 6)
SHEET_NS = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main'
OFFICE_REL_NS = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships'
PACKAGE_REL_NS = 'http://schemas.openxmlformats.org/package/2006/relationships'
CONTENT_TYPES_NS = 'http://schemas.openxmlformats.org/package/2006/content-types'


def _text(value: int) -> str:
    return f'v{value:05d}'


def _workbook(shared_string_count: int) -> bytes:
    if shared_string_count not in (POSITIVE_COUNT, OVERFLOW_COUNT):
        raise ValueError('XLSX_SST_UNSUPPORTED_COUNT')
    shared = (f'<sst xmlns="{SHEET_NS}">'
              + ''.join(f'<si><t>{_text(index)}</t></si>' for index in range(shared_string_count))
              + '</sst>')
    cells = ''.join(
        f'<c r="{column}1" t="s"><v>{index}</v></c>'
        for column, index in zip(('A', 'B', 'C'), REFERENCES)
    )
    sheet = f'<worksheet xmlns="{SHEET_NS}"><sheetData><row r="1">{cells}</row></sheetData></worksheet>'
    workbook = (f'<workbook xmlns="{SHEET_NS}" xmlns:r="{OFFICE_REL_NS}"><sheets>'
                '<sheet name="Boundary" sheetId="1" r:id="rId1"/></sheets></workbook>')
    root_rels = (f'<Relationships xmlns="{PACKAGE_REL_NS}"><Relationship Id="rId1" '
                 f'Type="{OFFICE_REL_NS}/officeDocument" Target="xl/workbook.xml"/></Relationships>')
    workbook_rels = (f'<Relationships xmlns="{PACKAGE_REL_NS}">'
                     f'<Relationship Id="rId1" Type="{OFFICE_REL_NS}/worksheet" Target="worksheets/sheet1.xml"/>'
                     f'<Relationship Id="rId2" Type="{OFFICE_REL_NS}/sharedStrings" Target="sharedStrings.xml"/>'
                     '</Relationships>')
    content_types = (f'<Types xmlns="{CONTENT_TYPES_NS}">'
                     '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
                     '<Default Extension="xml" ContentType="application/xml"/>'
                     '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
                     '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
                     '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>'
                     '</Types>')
    parts = {
        '[Content_Types].xml': content_types,
        '_rels/.rels': root_rels,
        'xl/workbook.xml': workbook,
        'xl/_rels/workbook.xml.rels': workbook_rels,
        'xl/sharedStrings.xml': shared,
        'xl/worksheets/sheet1.xml': sheet,
    }
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
    if fixture.count(b'toolbelt_file.USP_ReadXlsxWorksheetCells') != 1:
        raise ValueError('XLSX_SST_FIXTURE_API_BINDING')
    if b'@MaxSharedStrings' in fixture:
        raise ValueError('XLSX_SST_FIXTURE_MUST_USE_DEFAULT_LIMIT')
    if b'USP_ListXlsxWorksheets' in fixture or b'USP_ReadXlsxWorksheetCells' not in fixture:
        raise ValueError('XLSX_SST_FIXTURE_SCOPE')
    outputs = {
        'Xlsx.SharedStrings.50000.xlsx': _workbook(POSITIVE_COUNT),
        'Xlsx.SharedStrings.50001.xlsx': _workbook(OVERFLOW_COUNT),
    }
    hashes = {name: hashlib.sha256(data).hexdigest() for name, data in outputs.items()}
    metadata = {
        'schema': 'xlsx-shared-string-count-composition/v1',
        'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
        'fixture_bytes': len(fixture),
        'counts': {'positive': POSITIVE_COUNT, 'overflow': OVERFLOW_COUNT},
        'references': list(REFERENCES),
        'positive_expected_texts': [_text(index) for index in REFERENCES],
        'overflow_references_remain_valid': True,
        'zip_method': 'stored',
        'timestamp_dos': '2020-02-03 04:05:06',
        'outputs': {name: {'sha256': hashes[name], 'bytes': len(data)} for name, data in outputs.items()},
    }
    return outputs, metadata


def validate_output_path(output: Path) -> Path:
    runtime = ROOT / '.runtime'
    if not runtime.exists():
        runtime.mkdir()
    attributes = getattr(runtime.lstat(), 'st_file_attributes', 0)
    if runtime.is_symlink() or stat.S_ISLNK(runtime.lstat().st_mode) or attributes & 0x400:
        raise ValueError('XLSX_SST_RUNTIME_REPARSE')
    runtime_path = runtime.resolve(strict=True)
    resolved = output.absolute()
    if runtime_path != runtime.absolute() or resolved.parent != runtime.absolute() or os.path.lexists(resolved):
        raise ValueError('XLSX_SST_OUTPUT_SCOPE')
    return resolved


def write_output(output: Path) -> dict:
    destination = validate_output_path(output)
    fixture = FIXTURE.read_bytes()
    outputs, metadata = compose_sources(fixture)
    destination.mkdir(parents=True, exist_ok=False)
    for name, data in outputs.items():
        (destination / name).write_bytes(data)
    (destination / 'Xlsx.SharedStringCount.sql').write_bytes(fixture)
    (destination / 'composition.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    print(json.dumps(write_output(parser.parse_args().output), sort_keys=True))


if __name__ == '__main__':
    main()
