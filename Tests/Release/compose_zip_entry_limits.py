"""Valid fixed ZIP entry-limit fixtures; no SQL, product or quota changes."""
from pathlib import Path
import hashlib
import json
import struct
import sys
import zipfile
import zlib

ROOT = Path(__file__).resolve().parents[2]
COMPRESSED_LIMIT = 134217728
OUTPUT_LIMIT = 67108864
NAME = b'payload.txt'
EMPTY_STORED_BLOCK = b'\x00\x00\x00\xff\xff'


def compose(path: Path, *, compressed: bool, overflow: bool) -> dict:
    if compressed:
        payload = b'ab' if overflow else b'a'
        final = zlib.compress(payload, wbits=-15)
        if len(final) != (4 if overflow else 3):
            raise ValueError('Unexpected final DEFLATE encoding')
        blocks = (COMPRESSED_LIMIT - 3) // 5
        packed = blocks * 5 + len(final)
        size = len(payload)
        crc = zlib.crc32(payload)
        payload_hash = hashlib.sha256(payload).hexdigest().upper()
        method = 8
    else:
        size = OUTPUT_LIMIT + int(overflow)
        packed = size
        method = 0
        digest = hashlib.sha256()
        crc = 0
        remaining = size
        while remaining:
            block = bytes(min(65536, remaining))
            crc = zlib.crc32(block, crc)
            digest.update(block)
            remaining -= len(block)
        payload_hash = digest.hexdigest().upper()
    with path.open('xb') as stream:
        stream.write(struct.pack('<IHHHHHIIIHH', 0x04034b50, 20, 0, method,
                                 0x20a3, 0x5043, crc, packed, size, len(NAME), 0))
        stream.write(NAME)
        if compressed:
            chunk = EMPTY_STORED_BLOCK * 131072
            while blocks:
                count = min(blocks, 131072)
                stream.write(chunk[:count * 5])
                blocks -= count
            stream.write(final)
        else:
            remaining = size
            while remaining:
                count = min(65536, remaining)
                stream.write(bytes(count))
                remaining -= count
        offset = stream.tell()
        stream.write(struct.pack('<IHHHHHHIIIHHHHHII', 0x02014b50, 20, 20, 0,
                                 method, 0x20a3, 0x5043, crc, packed, size,
                                 len(NAME), 0, 0, 0, 0, 0, 0))
        stream.write(NAME)
        directory_size = stream.tell() - offset
        stream.write(struct.pack('<IHHHHIIH', 0x06054b50, 0, 0, 1, 1,
                                 directory_size, offset, 0))
    # Independent standard implementation decodes the full actual entry and CRC.
    actual_hash = hashlib.sha256()
    actual_size = 0
    with zipfile.ZipFile(path) as archive:
        if archive.namelist() != [NAME.decode()]:
            raise ValueError('Independent member mismatch')
        info = archive.infolist()[0]
        if (info.compress_size, info.file_size, info.CRC, info.compress_type) != (packed, size, crc, method):
            raise ValueError('Independent metadata mismatch')
        with archive.open(info) as source:
            for block in iter(lambda: source.read(65536), b''):
                actual_hash.update(block)
                actual_size += len(block)
    if actual_size != size or actual_hash.hexdigest().upper() != payload_hash:
        raise ValueError('Independent payload mismatch')
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1048576), b''):
            digest.update(block)
    return dict(path=str(path.resolve()), size=path.stat().st_size,
                sha256=digest.hexdigest().upper(), compressed_bytes=packed,
                output_bytes=size, payload_sha256=payload_hash, crc32=crc,
                method=method, overflow=overflow)


def main(directory: Path) -> None:
    directory = directory.resolve()
    if (ROOT / '.runtime').resolve() not in directory.parents:
        raise ValueError('Private new fixture directory required')
    directory.mkdir(exist_ok=False)
    fixtures = {}
    for compressed in (True, False):
        for overflow in (False, True):
            name = ('compressed' if compressed else 'output') + ('_overflow' if overflow else '_cap')
            fixtures[name] = compose(directory / (name + '.zip'), compressed=compressed, overflow=overflow)
    record = dict(schema_version='zip-entry-hardlimit-fixtures/v1',
                  compressed_limit_bytes=COMPRESSED_LIMIT, output_limit_bytes=OUTPUT_LIMIT,
                  limits_overridden=False, independent_zip_crc_verified=True, fixtures=fixtures)
    (directory / 'manifest.private.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    print('PASS four valid independently decoded ZIP entry boundary fixtures; no SQL')


if __name__ == '__main__':
    main(Path(sys.argv[1]))
