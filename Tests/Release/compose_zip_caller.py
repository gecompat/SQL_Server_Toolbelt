"""Komponiert feste Stored-ZIP-Callerfixtures ohne SQL- oder Produktzugriff."""
from pathlib import Path
import argparse
import hashlib
import io
import json
import struct
import zlib
import zipfile

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'Tests/Release/Runtime/ZipMemory.CallerRights.sql'
READER_MARKER = b'$(ZIP_READER_FIXTURE_HEX)'
WRITER_MARKER = b'$(ZIP_WRITER_GOLDEN_HEX)'
GRANT_MARKER = b'$(ZIP_EXTRA_SCHEMA_GRANT)'
ENTRY_NAME = b'hello.txt'
PAYLOAD = b'Hello'
CRC32 = 0xF7D18982
# Writer contract: UTF-8 flag, Stored, no extra/comment/attributes,
# DOS date 1980-01-01 and zero time. Payload and CRC are literal contract pins.
WRITER_GOLDEN_HEX = (
    '504B0304140000080000000021008289D1F7050000000500000009000000'
    '68656C6C6F2E74787448656C6C6F'
    '504B01021400140000080000000021008289D1F7050000000500000009000000'
    '000000000000000000000000000068656C6C6F2E747874'
    '504B05060000000001000100370000002C0000000000'
)


def _stored_zip(name: bytes, payload: bytes, dos_time: int, dos_date: int) -> bytes:
    crc = zlib.crc32(payload) & 0xFFFFFFFF
    if crc != CRC32:
        raise ValueError('Pinned payload CRC does not match the fixed golden')
    flags = 0x0800  # UTF-8 names, as emitted by the existing writer contract.
    local = struct.pack('<IHHHHHIIIHH', 0x04034B50, 20, flags, 0,
                        dos_time, dos_date, crc, len(payload), len(payload), len(name), 0)
    local += name + payload
    central = struct.pack('<IHHHHHHIIIHHHHHII', 0x02014B50, 20, 20, flags, 0,
                          dos_time, dos_date, crc, len(payload), len(payload),
                          len(name), 0, 0, 0, 0, 0, 0)
    central += name
    eocd = struct.pack('<IHHHHIIH', 0x06054B50, 0, 0, 1, 1,
                       len(central), len(local), 0)
    return local + central + eocd


def reader_fixture() -> bytes:
    # DOS 2020-02-03 04:05:06 (seconds stored in two-second units).
    return _stored_zip(ENTRY_NAME, PAYLOAD, 0x20A3, 0x5043)


def writer_golden() -> bytes:
    return bytes.fromhex(WRITER_GOLDEN_HEX)


def _validate_golden() -> None:
    reader = reader_fixture()
    writer = writer_golden()
    if len(reader) != 121 or len(writer) != 121:
        raise ValueError('Fixed one-entry Stored ZIP must be 121 bytes')
    if zlib.crc32(PAYLOAD) & 0xFFFFFFFF != CRC32:
        raise ValueError('Fixed payload CRC mismatch')
    # Distinct date fields are deliberate; the reader input is 2020 while the
    # public writer contract fixes its own output timestamp at 1980.
    if struct.unpack_from('<HH', reader, 10) != (0x20A3, 0x5043):
        raise ValueError('Reader fixture timestamp drifted')
    if struct.unpack_from('<HH', writer, 10) != (0, 0x21):
        raise ValueError('Writer golden timestamp drifted')
    if writer[30:39] != ENTRY_NAME or writer[39:44] != PAYLOAD:
        raise ValueError('Writer golden entry bytes drifted')
    for archive, expected_date in ((reader, (2020, 2, 3, 4, 5, 6)),
                                   (writer, (1980, 1, 1, 0, 0, 0))):
        with zipfile.ZipFile(io.BytesIO(archive)) as opened:
            entries = opened.infolist()
            if len(entries) != 1 or entries[0].filename != ENTRY_NAME.decode('ascii'):
                raise ValueError('Fixed ZIP must contain exactly the pinned entry name')
            entry = entries[0]
            if (entry.compress_type != zipfile.ZIP_STORED or entry.date_time != expected_date
                    or entry.CRC != CRC32 or opened.read(entry) != PAYLOAD):
                raise ValueError('Fixed ZIP entry metadata or payload drifted')


def compose_sources(fixture: bytes, fault: str | None = None) -> tuple[bytes, dict]:
    _validate_golden()
    markers = (READER_MARKER, WRITER_MARKER, GRANT_MARKER)
    counts = {marker: fixture.count(marker) for marker in markers}
    if counts != {marker: 1 for marker in markers}:
        raise ValueError('Expected exactly one marker for each ZIP input, golden, and control')
    if fault not in (None, 'wrong-golden', 'extra-schema-grant'):
        raise ValueError('Unknown synthetic control')
    writer_hex = WRITER_GOLDEN_HEX
    extra_grant = b''
    if fault == 'wrong-golden':
        writer_hex = writer_hex[:-2] + ('01' if writer_hex[-2:] != '01' else '02')
    elif fault == 'extra-schema-grant':
        extra_grant = b'GRANT SELECT ON SCHEMA::toolbelt_archive TO ContosoZipCaller;'
    replacements = {
        READER_MARKER: reader_fixture().hex().upper().encode('ascii'),
        WRITER_MARKER: writer_hex.encode('ascii'),
        GRANT_MARKER: extra_grant,
    }
    sql = fixture
    for marker, value in replacements.items():
        sql = sql.replace(marker, value)
    manifest = {
        'schema': 'zip-caller-composition/v1',
        'fixture_sha256': hashlib.sha256(fixture).hexdigest(),
        'reader_fixture_sha256': hashlib.sha256(reader_fixture()).hexdigest(),
        'reader_fixture_bytes': len(reader_fixture()),
        'reader_timestamp_dos': '2020-02-03 04:05:06',
        'writer_golden_sha256': hashlib.sha256(writer_golden()).hexdigest(),
        'writer_golden_bytes': len(writer_golden()),
        'writer_timestamp_dos': '1980-01-01 00:00:00',
        'fault': fault,
        'entry_name': ENTRY_NAME.decode('ascii'),
        'payload_sha256': hashlib.sha256(PAYLOAD).hexdigest(),
        'payload_bytes': len(PAYLOAD),
        'crc32_hex': f'{CRC32:08X}',
        'output_sha256': hashlib.sha256(sql).hexdigest(),
        'output_bytes': len(sql),
        'marker_counts': {key.decode('ascii'): value for key, value in counts.items()},
    }
    return sql, manifest


def compose() -> tuple[bytes, dict]:
    return compose_sources(FIXTURE.read_bytes())


def validate_output_path(output: Path) -> Path:
    runtime = (ROOT / '.runtime').resolve()
    out = output.resolve()
    if out == runtime or not out.is_relative_to(runtime) or out.exists():
        raise ValueError('Output must be a fresh child path below repository .runtime')
    return out


def write_output(output: Path, fault: str | None = None) -> dict:
    out = validate_output_path(output)
    fixture_bytes = FIXTURE.read_bytes()
    sql, manifest = compose_sources(fixture_bytes, fault)
    out.mkdir(parents=True, exist_ok=False)
    (out / 'ZipMemory.CallerRights.sql').write_bytes(sql)
    (out / 'composition.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True, type=Path)
    parser.add_argument('--fault', choices=('wrong-golden', 'extra-schema-grant'))
    args = parser.parse_args()
    manifest = write_output(args.output, args.fault)
    print(f"PASS fixed ZIP caller composition; sha256={manifest['output_sha256']}")


if __name__ == '__main__':
    main()
