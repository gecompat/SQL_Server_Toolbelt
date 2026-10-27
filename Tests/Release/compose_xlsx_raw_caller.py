"""Compose the fixed synthetic XLSX rights probe; never connects to SQL Server."""
from pathlib import Path
import argparse
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'Tests/Release/Runtime/XlsxRaw.CallerRights.sql'
WORKBOOK = ROOT / 'Modules/toolbelt.file.xlsx-memory/Tests/Runtime/Types.Composition.xlsx'
MARKER = b'$(XLSX_WORKBOOK_HEX)'
ZIP_HEADER = b'PK\x03\x04'


def compose_sources(fixture: bytes, workbook: bytes) -> tuple[bytes, dict]:
    """Pure composer separated for negative controls over synthetic byte inputs."""
    count = fixture.count(MARKER)
    if count != 1:
        raise ValueError('Expected exactly one binary insertion marker')
    if not workbook.startswith(ZIP_HEADER):
        raise ValueError('Pinned XLSX input is not a ZIP workbook')
    sql = fixture.replace(MARKER, workbook.hex().upper().encode('ascii'))
    manifest = {
        'schema': 'xlsx-raw-caller-composition/v1',
        'inputs': {
            'fixture': FIXTURE.relative_to(ROOT).as_posix(),
            'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
            'workbook': WORKBOOK.relative_to(ROOT).as_posix(),
            'workbook_sha256': hashlib.sha256(workbook).hexdigest(),
            'workbook_bytes': len(workbook),
        },
        'output_sha256': hashlib.sha256(sql).hexdigest(),
        'output_bytes': len(sql),
        'marker_count': count,
        'composition': 'replace marker with uppercase hex of exact workbook bytes',
    }
    return sql, manifest


def compose() -> tuple[bytes, dict]:
    return compose_sources(FIXTURE.read_bytes(), WORKBOOK.read_bytes())


def validate_output_path(output: Path) -> Path:
    runtime = (ROOT / '.runtime').resolve()
    out = output.resolve()
    if out == runtime or not out.is_relative_to(runtime) or out.exists():
        raise ValueError('Output must be a fresh child path below repository .runtime')
    return out


def write_output(output: Path) -> dict:
    out = validate_output_path(output)
    sql, manifest = compose()
    out.mkdir(parents=True, exist_ok=False)
    (out / 'XlsxRaw.CallerRights.sql').write_bytes(sql)
    (out / 'composition.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return manifest


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--output', required=True, type=Path)
    manifest = write_output(ap.parse_args().output)
    print(f"PASS deterministic XLSX raw caller composition; sha256={manifest['output_sha256']}")


if __name__ == '__main__':
    main()
