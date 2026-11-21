"""Generate small descriptors and ZIPs for native physical-limit tests."""
import argparse
from io import BytesIO
from pathlib import Path
from struct import pack
from zipfile import ZipFile, ZipInfo
import zlib

ENTRY_MAX = 64 * 1024 * 1024
ARCHIVE_MAX = 256 * 1024 * 1024


def entry_headers(name, method, crc, compressed, expanded, offset):
    fields = (20, 0, method, 0, 33, crc, compressed, expanded)
    local = pack("<I5H3I2H", 0x04034B50, *fields, len(name), 0) + name
    central = pack("<I6H3I5H2I", 0x02014B50, 20, *fields, len(name), 0, 0, 0, 0, 0, offset) + name
    return local, central


def end_of_directory(count, size, offset):
    return pack("<I4H2IH", 0x06054B50, 0, 0, count, count, size, offset, 0)


def stored_layout(entries):
    local_headers = []
    directory = []
    offset = 0
    for name, length in entries:
        name = name.encode("ascii")
        block = b"A" * (1024 * 1024)
        crc = 0
        full_blocks, tail = divmod(length, len(block))
        for _ in range(full_blocks):
            crc = zlib.crc32(block, crc)
        crc = zlib.crc32(block[:tail], crc)
        header, record = entry_headers(name, 0, crc, length, length, offset)
        local_headers.append(header)
        directory.append(record)
        offset += len(header) + length
    central = b"".join(directory)
    eocd = end_of_directory(len(entries), len(central), offset)
    return local_headers, central + eocd


def member_path(length):
    prefix = ("p" * 200 + "/") * 5
    return prefix + "n" * (length - len(prefix) - len(".bin")) + ".bin"


def zip_bytes(names):
    stream = BytesIO()
    with ZipFile(stream, "w", allowZip64=False) as archive:
        for name in names:
            archive.writestr(ZipInfo(name), b"")
    return stream.getvalue()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    output = parser.parse_args().output
    output.mkdir(parents=True, exist_ok=True)

    names = [f"volume{i}.bin" for i in range(4)]
    overhead = 22 + sum(76 + 2 * len(name) for name in names)
    lengths = [ENTRY_MAX, ENTRY_MAX, ENTRY_MAX, ENTRY_MAX - overhead]
    headers, suffix = stored_layout(list(zip(names, lengths)))
    assert sum(map(len, headers)) + sum(lengths) + len(suffix) == ARCHIVE_MAX
    for index, header in enumerate(headers):
        (output / f"VolumeHeader{index}.bin").write_bytes(header)
    (output / "VolumeSuffix.bin").write_bytes(suffix)
    headers, suffix = stored_layout([("oversize.bin", ENTRY_MAX + 1)])
    (output / "EntryHeader.bin").write_bytes(headers[0])
    (output / "EntrySuffix.bin").write_bytes(suffix)
    for count in (10000, 10001):
        (output / f"Count{count}.bin").write_bytes(zip_bytes(f"c{i:05}.bin" for i in range(count)))
    for length in (1024, 1025):
        name = member_path(length)
        assert len(name) == length
        (output / f"Path{length}.bin").write_bytes(zip_bytes([name]))

    for label, payload in (("Max", b"A"), ("Above", b"AA")):
        compressed = 128 * 1024 * 1024 + len(payload) - 1
        header, central = entry_headers(b"first.bin", 8, zlib.crc32(payload), compressed, len(payload), 0)
        eocd = end_of_directory(1, len(central), len(header) + compressed)
        (output / f"{label}Header.bin").write_bytes(header)
        (output / f"{label}Suffix.bin").write_bytes(central + eocd)


if __name__ == "__main__":
    main()
