"""Baut ausschließlich synthetische ZIP-Grenzfixtures für den Release-Test."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'Tests/Release/Runtime/ZipEntryCount.Contract.sql'
ENTRY_PREFIX = 'e'
ENTRY_SUFFIX = '.txt'
TIMESTAMP = (2020, 2, 3, 4, 5, 6)


def _entry_name(index: int) -> str:
    return f'{ENTRY_PREFIX}{index:05d}{ENTRY_SUFFIX}'


def build_archive(count: int) -> bytes:
    if count not in (10000, 10001):
        raise ValueError('ZIP_ENTRY_COUNT_UNSUPPORTED_SIZE')
    output = io.BytesIO()
    with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_STORED, allowZip64=False) as archive:
        for index in range(count):
            info = zipfile.ZipInfo(_entry_name(index), date_time=TIMESTAMP)
            info.compress_type = zipfile.ZIP_STORED
            info.create_system = 0
            info.flag_bits = 0
            info.extra = b''
            info.comment = b''
            archive.writestr(info, b'')
    result = output.getvalue()
    _validate_archive(result, count)
    return result


def _validate_archive(data: bytes, count: int) -> None:
    if len(data) > 268435456:
        raise ValueError('ZIP_ENTRY_COUNT_ARCHIVE_BYTES')
    with zipfile.ZipFile(io.BytesIO(data), 'r') as archive:
        infos = archive.infolist()
        if len(infos) != count:
            raise ValueError('ZIP_ENTRY_COUNT_ARCHIVE_COUNT')
        for index, info in enumerate(infos):
            if (info.filename != _entry_name(index) or info.date_time != TIMESTAMP
                    or info.compress_type != zipfile.ZIP_STORED or info.CRC != 0
                    or info.file_size != 0 or info.compress_size != 0 or info.flag_bits & 1
                    or info.extra or info.comment):
                raise ValueError('ZIP_ENTRY_COUNT_ARCHIVE_METADATA')
        if archive.comment:
            raise ValueError('ZIP_ENTRY_COUNT_ARCHIVE_COMMENT')


def compose_sources(fixture: bytes, zip_10000: bytes, zip_10001: bytes) -> dict:
    _validate_archive(zip_10000, 10000)
    _validate_archive(zip_10001, 10001)
    if (fixture.count(b'USP_ListZipEntriesFromBinary') != 1
            or b'@ZipArchive = @ZipArchive' not in fixture
            or b'@MaxEntries = @MaxEntries' not in fixture):
        raise ValueError('ZIP_ENTRY_COUNT_PARAMETER_BINDING')
    if (b'@MaxEntries = 10000' in fixture or b'@MaxEntries = 10001' in fixture):
        raise ValueError('ZIP_ENTRY_COUNT_ORACLE_BINDING')
    return {
        'schema': 'zip-entry-count-composition/v1',
        'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
        'zip_10000_sha256': hashlib.sha256(zip_10000).hexdigest(),
        'zip_10000_bytes': len(zip_10000),
        'zip_10001_sha256': hashlib.sha256(zip_10001).hexdigest(),
        'zip_10001_bytes': len(zip_10001),
        'timestamp_dos': '2020-02-03 04:05:06',
        'entry_name_pattern': 'eNNNNN.txt',
        'positive_count': 10000,
        'overflow_count': 10001,
        'limits': {'archive_bytes': 268435456, 'max_entries': 10000},
    }


def validate_output_path(output: Path) -> Path:
    runtime = ROOT / '.runtime'
    if runtime.is_symlink() or runtime.resolve() != runtime.absolute():
        raise ValueError('ZIP_ENTRY_COUNT_RUNTIME_REPARSE')
    out = output.absolute()
    if out.parent.resolve() != runtime.resolve() or out.exists() or out.is_symlink():
        raise ValueError('ZIP_ENTRY_COUNT_OUTPUT_SCOPE')
    return out


def write_output(output: Path) -> dict:
    out = validate_output_path(output)
    fixture = FIXTURE.read_bytes()
    archive_10000 = build_archive(10000)
    archive_10001 = build_archive(10001)
    manifest = compose_sources(fixture, archive_10000, archive_10001)
    out.mkdir(parents=False, exist_ok=False)
    (out / 'ZipEntryCount.Contract.sql').write_bytes(fixture)
    (out / 'ZipEntryCount.10000.zip').write_bytes(archive_10000)
    (out / 'ZipEntryCount.10001.zip').write_bytes(archive_10001)
    manifest['fixture_sha256'] = hashlib.sha256((out / 'ZipEntryCount.Contract.sql').read_bytes()).hexdigest()
    (out / 'composition.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    manifest = write_output(parser.parse_args().output)
    print('PASS deterministic ZIP entry-count fixture composition')
    print(f"sha256(10000)={manifest['zip_10000_sha256']}; sha256(10001)={manifest['zip_10001_sha256']}")


if __name__ == '__main__':
    main()
