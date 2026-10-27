#!/usr/bin/env python3
"""Bindet die Edit-Distance-Prüfung an die unveränderte CLR-Installationslieferung."""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re
import zipfile

PACKAGE = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip"
SIDECAR = PACKAGE + ".sha256"
QUALIFICATION = "Releases/1.0.0/clr-qualification.json"
SOURCE_REPORT = "Releases/1.0.0/clr-string-caller-qualification.json"
PACKAGE_ROOT = "SQL-Server-Toolbelt-1.0.0-CLR-Install/"
MANIFEST = PACKAGE_ROOT + "CLR-PACKAGE.json"
DLL = "Toolbelt.String.EditDistance.dll"
DLL_ENTRY = PACKAGE_ROOT + "Binaries/" + DLL
MODULE_ID = "toolbelt.string.edit-distance"
PACKAGE_SHA256 = "896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287"
DLL_SHA512 = "c81e7a841dc0670b850f46d932337f55b6225d2a834d4480ae3d514875b84bf56261ff580df56155a59c0f8a56b6fe54e798d046329f4122e7228467cca90404"
SOURCE_REPORT_SHA256 = "c71cefdd5b780d3cf8ff9cd5eadff9ce4b4caddf874bf61d8318ed58bc62ec0f"
SOURCE_PATHS = (
    "Modules/toolbelt.string.edit-distance/Clr/DistanceKernel.cs",
    "Modules/toolbelt.string.edit-distance/Clr/DistanceProvider.cs",
    "Modules/toolbelt.string.edit-distance/Clr/JaroKernel.cs",
    "Modules/toolbelt.string.edit-distance/Clr/JaroProvider.cs",
    "Modules/toolbelt.string.edit-distance/Clr/Properties/AssemblyInfo.cs",
    "Modules/toolbelt.string.edit-distance/Clr/Toolbelt.String.EditDistance.csproj",
    "Modules/toolbelt.string.edit-distance/Clr/UnicodeScalar.cs",
    "Modules/toolbelt.string.edit-distance/Deployment/Add-TrustedAssembly.sql",
    "Modules/toolbelt.string.edit-distance/Deployment/Deploy.sql",
    "Modules/toolbelt.string.edit-distance/Deployment/Uninstall.sql",
    "Modules/toolbelt.string.edit-distance/module.yaml",
    "Modules/toolbelt.string.edit-distance/Source/EditDistance.sql",
    "Modules/toolbelt.string.edit-distance/Source/JaroWinkler.sql",
)
FRAMEWORK_ORACLE_SHA256 = {
    "Modules/toolbelt.string.edit-distance/Tests/Framework/reference.py": "f35f66a40bc74338c4b73530b23eaf6f445618e0c0c89d05972541cc1e5d5078",
    "Modules/toolbelt.string.edit-distance/Tests/Framework/make_goldens.py": "59793d3b7c0305b6094c6c193e65ba0312f3486b85e6e11daaf2f6f3b3cf24e4",
    "Modules/toolbelt.string.edit-distance/Tests/Framework/JaroContract.cs": "237fed560d5a04b6ba0501b4fa20db5b1c44263ac4feb449894069055a9e67ef",
    "Modules/toolbelt.string.edit-distance/Tests/Framework/DistanceContract.cs": "7cebd7bf64015860b76d7c50eb2bfa32438ebc514bc45c36b3d768fcabb95128",
}


class PackageError(ValueError):
    """Ein Paket oder eine seiner unveränderlichen Bindungen ist ungültig."""


def sha(data: bytes, algorithm: str = "sha256") -> str:
    return hashlib.new(algorithm, data).hexdigest()


def _read_archive(data: bytes) -> dict[str, bytes]:
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            infos = archive.infolist()
            if len(infos) > 10000 or sum(info.file_size for info in infos) > 256 * 1024 * 1024:
                raise PackageError("EDIT_DISTANCE_PACKAGE_LIMIT")
            seen: set[str] = set()
            entries: dict[str, bytes] = {}
            for info in infos:
                name = info.filename
                path = PurePosixPath(name.rstrip("/"))
                if (not name or "\\" in name or ":" in name or path.is_absolute()
                        or any(part in ("", ".", "..") for part in path.parts)
                        or name.casefold() in seen):
                    raise PackageError("EDIT_DISTANCE_PACKAGE_PATH")
                seen.add(name.casefold())
                if info.flag_bits & 1:
                    raise PackageError("EDIT_DISTANCE_PACKAGE_ENCRYPTED")
                if not info.is_dir():
                    entries[name] = archive.read(info)
            if archive.testzip() is not None:
                raise PackageError("EDIT_DISTANCE_PACKAGE_CRC")
            return entries
    except (OSError, zipfile.BadZipFile, RuntimeError, UnicodeError) as exc:
        raise PackageError("EDIT_DISTANCE_PACKAGE_INVALID") from exc


def inspect_bytes(archive_bytes: bytes, sidecar_bytes: bytes, qualification_bytes: bytes,
                  source_report_bytes: bytes, source_files: dict[str, bytes],
                  oracle_files: dict[str, bytes]) -> tuple[dict, bytes]:
    """Prüft Paket, Manifest und alte Binärqualifikation gegen dieselben DLL-Bytes."""
    actual_archive_sha = sha(archive_bytes)
    if actual_archive_sha != PACKAGE_SHA256:
        raise PackageError("EDIT_DISTANCE_PACKAGE_SHA256")
    expected_sidecar = f"{actual_archive_sha}  {Path(PACKAGE).name}\n".encode("ascii")
    if sidecar_bytes != expected_sidecar:
        raise PackageError("EDIT_DISTANCE_SIDECAR")

    files = _read_archive(archive_bytes)
    if sha(source_report_bytes) != SOURCE_REPORT_SHA256:
        raise PackageError("EDIT_DISTANCE_SOURCE_REPORT_PIN")
    try:
        manifest = json.loads(files[MANIFEST])
        qualification = json.loads(qualification_bytes)
        source_report = json.loads(source_report_bytes)
    except (KeyError, UnicodeError, json.JSONDecodeError) as exc:
        raise PackageError("EDIT_DISTANCE_PACKAGE_METADATA") from exc
    if manifest.get("schema_version") != "1.0" or manifest.get("publication_authorized") is not False:
        raise PackageError("EDIT_DISTANCE_PACKAGE_IDENTITY")
    artifacts = [item for item in manifest.get("artifacts", []) if item.get("module_id") == MODULE_ID]
    if len(artifacts) != 1:
        raise PackageError("EDIT_DISTANCE_PACKAGE_MODULE_COUNT")
    artifact = artifacts[0]
    if (artifact.get("file") != DLL or artifact.get("sql_name") != "Toolbelt_String_EditDistance"
            or artifact.get("origin") != "reproducible_double_build"):
        raise PackageError("EDIT_DISTANCE_PACKAGE_MODULE_IDENTITY")
    try:
        dll_bytes = files[DLL_ENTRY]
    except KeyError as exc:
        raise PackageError("EDIT_DISTANCE_PACKAGE_DLL_MISSING") from exc
    dll_sha256 = sha(dll_bytes)
    dll_sha512 = sha(dll_bytes, "sha512")
    public_pin = qualification.get("binary_sha512", {}).get("Binaries/" + DLL)
    if (dll_sha256 != artifact.get("sha256") or dll_sha512 != artifact.get("sha512")
            or dll_sha512 != DLL_SHA512 or public_pin != DLL_SHA512):
        raise PackageError("EDIT_DISTANCE_PACKAGE_BINARY_BINDING")
    pins = source_report.get("source_sha256", {})
    expected_pins = {path for path in pins if path.startswith("Modules/toolbelt.string.edit-distance/")}
    if expected_pins != set(SOURCE_PATHS) or set(source_files) != set(SOURCE_PATHS):
        raise PackageError("EDIT_DISTANCE_SOURCE_PIN_SET")
    source_digests = {}
    for path in SOURCE_PATHS:
        digest = sha(source_files[path])
        if digest != pins.get(path):
            raise PackageError("EDIT_DISTANCE_SOURCE_PIN_DRIFT")
        source_digests[path] = digest
    if set(oracle_files) != set(FRAMEWORK_ORACLE_SHA256):
        raise PackageError("EDIT_DISTANCE_ORACLE_PIN_SET")
    oracle_digests = {path: sha(oracle_files[path]) for path in FRAMEWORK_ORACLE_SHA256}
    if oracle_digests != FRAMEWORK_ORACLE_SHA256:
        raise PackageError("EDIT_DISTANCE_ORACLE_PIN_DRIFT")
    return ({"package_sha256": actual_archive_sha, "module_id": MODULE_ID,
             "module_version": "1.1.0", "assembly_file": DLL,
             "assembly_size": len(dll_bytes), "assembly_sha256": dll_sha256,
             "assembly_sha512": dll_sha512,
             "qualification_pin_sha512": public_pin,
             "source_report_sha256": SOURCE_REPORT_SHA256,
             "source_sha256": source_digests,
             "framework_oracle_sha256": oracle_digests}, dll_bytes)


def prepare(root: Path, output: Path) -> dict:
    """Prüft aktuelle Inputs und schreibt die DLL aus dem geprüften Bytepuffer."""
    root = root.resolve(strict=True)
    runtime = root / ".runtime"
    output = output if output.is_absolute() else root / output
    if output.parent != runtime or output.name in ("", ".", ".."):
        raise PackageError("EDIT_DISTANCE_OUTPUT_SCOPE")
    scope_parts = (runtime,)
    for part in scope_parts:
        if part.is_symlink() or (part.exists() and not part.is_dir()):
            raise PackageError("EDIT_DISTANCE_RUNTIME_SCOPE")
    if output.exists() or output.is_symlink():
        raise PackageError("EDIT_DISTANCE_OUTPUT_NOT_FRESH")
    package_path = root / PACKAGE
    sidecar_path = root / SIDECAR
    qualification_path = root / QUALIFICATION
    source_report_path = root / SOURCE_REPORT
    archive_bytes = package_path.read_bytes()
    sidecar_bytes = sidecar_path.read_bytes()
    qualification_bytes = qualification_path.read_bytes()
    source_report_bytes = source_report_path.read_bytes()
    source_files = {path: (root / path).read_bytes() for path in SOURCE_PATHS}
    oracle_files = {path: (root / path).read_bytes() for path in FRAMEWORK_ORACLE_SHA256}
    result, dll_bytes = inspect_bytes(archive_bytes, sidecar_bytes, qualification_bytes,
                                     source_report_bytes, source_files, oracle_files)
    runtime.mkdir(parents=True, exist_ok=True)
    for part in scope_parts:
        if part.is_symlink() or not part.is_dir():
            raise PackageError("EDIT_DISTANCE_RUNTIME_SCOPE")
    output.mkdir(parents=False, exist_ok=False)
    binary_dir = output / "package"
    binary_dir.mkdir()
    binary_path = binary_dir / DLL
    binary_path.write_bytes(dll_bytes)
    result["extracted_sha256"] = sha(binary_path.read_bytes())
    if result["extracted_sha256"] != result["assembly_sha256"]:
        raise PackageError("EDIT_DISTANCE_EXTRACTED_DRIFT")
    result["extracted_size"] = binary_path.stat().st_size
    if result["extracted_size"] != result["assembly_size"]:
        raise PackageError("EDIT_DISTANCE_EXTRACTED_SIZE")
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    result = prepare(args.root, args.output)
    print(json.dumps(result, sort_keys=True, separators=(",", ":")))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
