"""Deterministische gültige ZIPs an der bestehenden 256-MiB-Archivgrenze."""
from pathlib import Path
import hashlib
import json
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[2]
ARCHIVE_LIMIT = 268435456
PAYLOAD = b'abc'
PAYLOAD_NAME = 'payload.txt'
FILLER_NAME = 'filler.bin'
DATE = (2020, 2, 3, 4, 5, 6)


def compose(path: Path, length: int) -> dict:
    """Nur ein gültiges Stored-Archiv; kleine Größen dienen der Strukturgegenprobe."""
    overhead = 22 + sum(30 + 46 + 2 * len(name.encode('ascii')) for name in (PAYLOAD_NAME, FILLER_NAME))
    filler = length - overhead - len(PAYLOAD)
    if filler < 0 or length >= 2**31:
        raise ValueError('Unsupported synthetic archive length')
    with path.open('xb') as stream, zipfile.ZipFile(stream, 'w', allowZip64=False) as archive:
        for name, size in ((PAYLOAD_NAME, len(PAYLOAD)), (FILLER_NAME, filler)):
            info = zipfile.ZipInfo(name, DATE)
            info.compress_type = zipfile.ZIP_STORED
            info.create_system = 0
            with archive.open(info, 'w') as entry:
                if name == PAYLOAD_NAME:
                    entry.write(PAYLOAD)
                else:
                    block = bytes(65536)
                    while size:
                        chunk = min(size, len(block))
                        entry.write(block[:chunk])
                        size -= chunk
    if path.stat().st_size != length:
        raise ValueError('Synthetic archive length mismatch')
    # Unabhängiger Standardreader prüft das ganze Archiv, nicht nur Headerwerte.
    with zipfile.ZipFile(path) as archive:
        if archive.testzip() is not None or archive.read(PAYLOAD_NAME) != PAYLOAD:
            raise ValueError('Independent ZIP CRC/payload verification failed')
        if archive.namelist() != [PAYLOAD_NAME, FILLER_NAME]:
            raise ValueError('Independent ZIP member verification failed')
        entries = [dict(name=i.filename, size=i.file_size, crc32=i.CRC) for i in archive.infolist()]
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return dict(path=str(path), size=length, sha256=digest.hexdigest().upper(), entries=entries)


def main(directory: Path) -> None:
    directory = directory.resolve()
    if (ROOT / '.runtime').resolve() not in directory.parents:
        raise ValueError('Private new output directory required')
    directory.mkdir(exist_ok=False)
    fixtures = {key: compose(directory / (key + '.zip'), size) for key, size in (
        ('at_limit', ARCHIVE_LIMIT), ('overflow', ARCHIVE_LIMIT + 1))}
    record = dict(schema_version='zip-archive-hardlimit-fixtures/v1', archive_limit_bytes=ARCHIVE_LIMIT,
                  limits_overridden=False, payload_hex=PAYLOAD.hex(), payload_name=PAYLOAD_NAME,
                  independent_zip_crc_verified=True, fixtures=fixtures)
    (directory / 'manifest.private.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    print('PASS two valid synthetic ZIPs at original archive cap/cap+1; CRC/size/payload independently verified; no SQL')


if __name__ == '__main__':
    main(Path(sys.argv[1]))
