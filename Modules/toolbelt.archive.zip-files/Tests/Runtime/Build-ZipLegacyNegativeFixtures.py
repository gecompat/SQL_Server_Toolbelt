"""Make synthetic inputs for the legacy single-entry file facade tests."""
import argparse
from io import BytesIO
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZIP_STORED, ZipFile, ZipInfo
import warnings


def archive(payload, method=ZIP_STORED, duplicate=False):
    stream = BytesIO()
    with ZipFile(stream, "w") as writer:
        writer.writestr(ZipInfo("first.bin"), payload, compress_type=method)
        if duplicate:
            with warnings.catch_warnings():
                warnings.simplefilter("ignore", UserWarning)
                writer.writestr(ZipInfo("first.bin"), b"second")
    return stream.getvalue()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path)
    output = parser.parse_args().output
    output.mkdir(parents=True, exist_ok=True)
    clear = archive(b"\x04\x05")
    encrypted = bytearray(clear)
    encrypted[6] |= 1
    encrypted[encrypted.index(b"PK\x01\x02") + 8] |= 1
    fixtures = {
        "ClearZip": clear,
        "EncryptedFlagZip": encrypted,
        "DuplicateZip": archive(b"first", duplicate=True),
        "DeflateZip": archive(b"A" * 128, ZIP_DEFLATED),
    }
    for name, payload in fixtures.items():
        (output / f"{name}.bin").write_bytes(payload)


if __name__ == "__main__":
    main()
