#!/usr/bin/env python3
"""Bindet eine gelieferte CLR-DLL an ein festes vorhandenes Framework-Harness."""

from __future__ import annotations

import argparse
import hashlib
import io
import json
import os
from pathlib import Path
import stat
import zipfile


PACKAGE_REL = Path("Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip")
PACKAGE_SHA256 = "896989d546ae7396b4b698e3228ec4c55fd49857f4d2408e125904faf6471287"
QUALIFICATION_REL = Path("Releases/1.0.0/qualification.json")
QUALIFICATION_SHA256 = "48e89b12dccf6fd936547729c6344c03b6e059007cbe3aa20d9d7a979890082d"
ARCHIVE_PREFIX = "SQL-Server-Toolbelt-1.0.0-CLR-Install/"

PROFILES = {
    "phonetic": {
        "module_id": "toolbelt.string.phonetic",
        "runner": "Modules/toolbelt.string.phonetic/Tests/Framework/run-framework-phonetic.ps1",
        "harness": "Modules/toolbelt.string.phonetic/Tests/Framework/PhoneticHarness.cs",
        "owned_process": "Modules/toolbelt.string.phonetic/Scripts/Invoke-OwnedProcess.ps1",
        "dll": "Toolbelt.String.Phonetic.dll",
        "dll_sha256": "8309e0b8defeea9e0586fd0e264c784f2fd1662bc8624b08229a4e43af839f88",
    },
    "csv": {
        "module_id": "toolbelt.file.csv-memory",
        "runner": "Modules/toolbelt.file.csv-memory/Tests/Framework/run-framework-csv.ps1",
        "harness": "Modules/toolbelt.file.csv-memory/Tests/Framework/CsvHarness.cs",
        "owned_process": "Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1",
        "dll": "Toolbelt.File.CsvMemory.dll",
        "dll_sha256": "8e925d5627235b154c81cb4d85fa01550aa96e89d90fe045e4a627dda7a40201",
    },
}


def fail(message: str) -> None:
    raise ValueError(message)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def unique_object(pairs: list[tuple[str, object]]) -> dict[str, object]:
    result: dict[str, object] = {}
    for key, value in pairs:
        if key in result:
            fail("PACKAGE_JSON_DUPLICATE_KEY")
        result[key] = value
    return result


def pin(path: Path) -> dict[str, str]:
    resolved = path.resolve(strict=True)
    if not resolved.is_file() or is_reparse(path):
        fail("PINNED_INPUT_NOT_REGULAR_FILE")
    return {"path": path.as_posix(), "sha256": sha256(resolved.read_bytes())}


def is_reparse(path: Path) -> bool:
    info = path.lstat()
    reparse = getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
    return stat.S_ISLNK(info.st_mode) or bool(getattr(info, "st_file_attributes", 0) & reparse)


def main() -> int:
    parser = argparse.ArgumentParser(description="Bindet ein CLR-Paketbinary an ein begrenztes vorhandenes Harness.")
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--runtime-root", required=True, type=Path)
    parser.add_argument("--profile", required=True, choices=sorted(PROFILES))
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    root = args.root.resolve(strict=True)
    profile = PROFILES[args.profile]
    runtime = args.runtime_root.absolute()
    if (runtime.name != ".runtime" or is_reparse(runtime) or not runtime.is_dir()
            or runtime.resolve(strict=True) != runtime):
        fail("PRIVATE_RUNTIME_DIRECTORY_REQUIRED")
    output = args.output.absolute()
    if (runtime == root or runtime.is_relative_to(root) or root.is_relative_to(runtime)
            or output.parent.resolve(strict=True) != runtime
            or os.path.lexists(output)):
        fail("PRIVATE_OUTPUT_MUST_BE_FRESH_RUNTIME_CHILD")

    package_path = root / PACKAGE_REL
    sidecar_path = Path(str(package_path) + ".sha256")
    qualification_path = root / QUALIFICATION_REL
    runner_path = root / profile["runner"]
    harness_path = root / profile["harness"]
    owned_process_path = root / profile["owned_process"]
    source_paths = (package_path, sidecar_path, qualification_path, runner_path, harness_path,
                    owned_process_path, Path(__file__).resolve(strict=True))
    for path in source_paths:
        if not path.resolve(strict=True).is_relative_to(root):
            fail("PINNED_INPUT_OUTSIDE_REPOSITORY")
    before = [pin(path) for path in source_paths]

    package_bytes = package_path.read_bytes()
    package_hash = sha256(package_bytes)
    if package_hash != PACKAGE_SHA256:
        fail("PACKAGE_SHA256_MISMATCH")
    sidecar = sidecar_path.read_bytes().decode("ascii")
    expected_sidecar = f"{PACKAGE_SHA256}  {package_path.name}\n"
    if sidecar != expected_sidecar:
        fail("PACKAGE_SIDECAR_MISMATCH")
    qualification_bytes = qualification_path.read_bytes()
    if sha256(qualification_bytes) != QUALIFICATION_SHA256:
        fail("HISTORICAL_QUALIFICATION_SHA256_MISMATCH")
    qualification = json.loads(qualification_bytes, object_pairs_hook=unique_object)
    candidate_record = qualification.get("clr_framework_candidates", {})
    selected = [item for item in candidate_record.get("suites", [])
                if item.get("module_id") == profile["module_id"] and item.get("method") == profile["runner"]]
    if (candidate_record.get("result") != "success" or candidate_record.get("scope") != "SELECTED_FRAMEWORK_ONLY"
            or candidate_record.get("sql_executed") is not False or len(selected) != 1):
        fail("HISTORICAL_QUALIFICATION_SCOPE_MISMATCH")

    entry_name = ARCHIVE_PREFIX + "Binaries/" + profile["dll"]
    manifest_name = ARCHIVE_PREFIX + "CLR-PACKAGE.json"
    with zipfile.ZipFile(io.BytesIO(package_bytes)) as archive:
        dll_entries = [item for item in archive.infolist() if item.filename == entry_name]
        manifest_entries = [item for item in archive.infolist() if item.filename == manifest_name]
        if len(dll_entries) != 1 or len(manifest_entries) != 1:
            fail("PACKAGE_CANONICAL_ENTRY_COUNT")
        if stat.S_ISLNK(dll_entries[0].external_attr >> 16):
            fail("PACKAGE_ENTRY_NOT_REGULAR_FILE")
        manifest = json.loads(archive.read(manifest_entries[0]), object_pairs_hook=unique_object)
        artifacts = [item for item in manifest.get("artifacts", []) if item.get("module_id") == profile["module_id"]]
        file_record = manifest.get("files", {}).get("Binaries/" + profile["dll"])
        if (manifest.get("schema_version") != "1.0" or manifest.get("publication_authorized") is not False
                or len(artifacts) != 1 or artifacts[0].get("origin") != "reproducible_double_build"
                or artifacts[0].get("file") != profile["dll"]
                or file_record is None):
            fail("PACKAGE_MANIFEST_PROFILE_MISMATCH")
        dll_bytes = archive.read(dll_entries[0])
    dll_hash = sha256(dll_bytes)
    if (dll_hash != profile["dll_sha256"] or artifacts[0].get("sha256") != dll_hash
            or file_record.get("sha256") != dll_hash or file_record.get("size") != len(dll_bytes)):
        fail("PACKAGE_DLL_BINDING_MISMATCH")

    output.mkdir()
    extracted = output / profile["dll"]
    with extracted.open("xb") as stream:
        stream.write(dll_bytes)
        stream.flush()
        os.fsync(stream.fileno())
    if sha256(extracted.read_bytes()) != dll_hash:
        fail("EXTRACTED_DLL_BINDING_MISMATCH")
    after = [pin(path) for path in source_paths]
    if before != after:
        fail("SOURCE_INPUT_DRIFT")
    record = {
        "schema": "clr-framework-package-binding/v1",
        "profile": args.profile,
        "module_id": profile["module_id"],
        "scope": "EXISTING_FRAMEWORK_HARNESS_ON_DELIVERED_DLL",
        "package_sha256": package_hash,
        "qualification_sha256": QUALIFICATION_SHA256,
        "entry": entry_name,
        "dll_sha256": dll_hash,
        "dll_size": len(dll_bytes),
        "input_pins_before": before,
        "input_pins_after": after,
    }
    with (output / "binding.private.json").open("xb") as stream:
        stream.write((json.dumps(record, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8"))
        stream.flush()
        os.fsync(stream.fileno())
    print("PASS CLR_FRAMEWORK_PACKAGE_BINDING")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
