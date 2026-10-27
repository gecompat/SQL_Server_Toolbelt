"""Prüft und extrahiert die zwei DLLs für den JSON-Constructor-Releasegate."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import zipfile


PACKAGE_REL = Path("Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip")
PACKAGE_NAME = PACKAGE_REL.name
PREFIX = "SQL-Server-Toolbelt-1.0.0-CLR-Install/"
MANIFEST = PREFIX + "CLR-PACKAGE.json"
DLLS = {
    "Binaries/Toolbelt.JsonConstructors.dll": "Toolbelt.JsonConstructors.dll",
    "Binaries/Toolbelt.JsonCore.dll": "Toolbelt.JsonCore.dll",
}
SIDECAR_LINE = re.compile(r"([0-9a-f]{64})  " + re.escape(PACKAGE_NAME) + r"\n\Z")


class PackageBindingError(ValueError):
    pass


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _validate_archive(data: bytes, expected_archive_sha256: str) -> tuple[dict, dict[str, bytes]]:
    if not re.fullmatch(r"[0-9a-f]{64}", expected_archive_sha256):
        raise PackageBindingError("PACKAGE_EXPECTED_HASH_INVALID")
    archive_sha256 = sha256(data)
    if archive_sha256 != expected_archive_sha256:
        raise PackageBindingError("PACKAGE_ARCHIVE_HASH_MISMATCH")
    try:
        from io import BytesIO

        with zipfile.ZipFile(BytesIO(data), "r") as archive:
            names = archive.namelist()
            if len(names) != len(set(names)):
                raise PackageBindingError("PACKAGE_DUPLICATE_ENTRY")
            if any(name.startswith("/") or "\\" in name or ".." in Path(name).parts for name in names):
                raise PackageBindingError("PACKAGE_UNSAFE_ENTRY")
            if any(not name.startswith(PREFIX) for name in names):
                raise PackageBindingError("PACKAGE_ENTRY_OUTSIDE_ROOT")
            if MANIFEST not in names:
                raise PackageBindingError("PACKAGE_MANIFEST_MISSING")
            manifest = json.loads(archive.read(MANIFEST))
            files = manifest.get("files")
            if not isinstance(files, dict):
                raise PackageBindingError("PACKAGE_FILE_MAP_INVALID")
            expected_names = {PREFIX + path for path in files} | {MANIFEST}
            if set(names) != expected_names:
                raise PackageBindingError("PACKAGE_FILE_SET_MISMATCH")
            extracted: dict[str, bytes] = {}
            pins: dict[str, dict[str, object]] = {}
            for inner, output_name in DLLS.items():
                entry = files.get(inner)
                if not isinstance(entry, dict) or set(entry) != {"sha256", "size"}:
                    raise PackageBindingError("PACKAGE_DLL_MANIFEST_INVALID")
                payload = archive.read(PREFIX + inner)
                digest = sha256(payload)
                if entry["sha256"] != digest or entry["size"] != len(payload):
                    raise PackageBindingError("PACKAGE_DLL_CONTENT_MISMATCH")
                extracted[output_name] = payload
                pins[output_name] = {"sha256": digest, "size": len(payload)}
            return {"archive_sha256": archive_sha256, "files": pins}, extracted
    except (zipfile.BadZipFile, KeyError, json.JSONDecodeError, AttributeError, TypeError) as exc:
        raise PackageBindingError("PACKAGE_ARCHIVE_INVALID") from exc


def inspect_package(root: Path) -> tuple[dict, dict[str, bytes]]:
    root = root.resolve()
    package = root / PACKAGE_REL
    sidecar = Path(str(package) + ".sha256")
    try:
        sidecar_text = sidecar.read_text(encoding="ascii")
    except OSError as exc:
        raise PackageBindingError("PACKAGE_SIDECAR_MISSING") from exc
    match = SIDECAR_LINE.fullmatch(sidecar_text)
    if not match:
        raise PackageBindingError("PACKAGE_SIDECAR_INVALID")
    return _validate_archive(package.read_bytes(), match.group(1))


def extract_package(root: Path, output: Path) -> dict:
    root = root.resolve()
    output = output.resolve()
    private = (root / ".runtime").resolve()
    if output == private or not output.is_relative_to(private):
        raise PackageBindingError("PACKAGE_OUTPUT_SCOPE_INVALID")
    if output.exists():
        raise PackageBindingError("PACKAGE_OUTPUT_EXISTS")
    record, binaries = inspect_package(root)
    output.mkdir(parents=True, exist_ok=False)
    for name, payload in binaries.items():
        (output / name).write_bytes(payload)
    return record


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    try:
        record = extract_package(args.root, args.output)
    except PackageBindingError as exc:
        print(str(exc))
        return 2
    print(json.dumps(record, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
