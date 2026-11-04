"""Offline integrity checks for the separately qualified current API ZIP."""
from __future__ import annotations

from collections import Counter
import io
import json
from pathlib import Path, PurePosixPath
import posixpath
import stat
import zipfile

from new_ssis_current_package import (
    ROOT, MODULE, LEGACY, PREDECESSOR_SHA256, PROFILES, CURRENT_PROFILE, PROCEDURE_PROFILE, PROCEDURE_NAME,
    load_legacy_guard, require, sha, validate_native_record,
)
from new_ssis_standalone_tsql import read_regular_bounded, MAX_PACKAGE_BYTES, MAX_UNCOMPRESSED_BYTES


def validate(path, *, profile=CURRENT_PROFILE):
    path = Path(path)
    name, _, _ = PROFILES[profile]
    data = read_regular_bounded(path, MAX_PACKAGE_BYTES)
    checksum = read_regular_bounded(path.with_suffix(".zip.sha256"), 256).decode("ascii").split()
    require(len(checksum) == 2 and checksum == [sha(data), path.name], "ZIP checksum")
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        entries = archive.infolist()
        require(sum(entry.file_size for entry in entries) <= MAX_UNCOMPRESSED_BYTES,
                "expanded size")
        require(all(value == 1 for value in Counter(entry.filename.casefold() for entry in entries).values()),
                "duplicate ZIP path")
        for entry in entries:
            parts = entry.filename.split("/")
            mode = entry.external_attr >> 16
            require(parts[0] == name and len(parts) > 1 and
                    all(part not in ("", ".", "..") for part in parts) and
                    "\\" not in entry.filename and ":" not in entry.filename and
                    (not mode or stat.S_ISREG(mode)), "unsafe ZIP path")
        require(archive.testzip() is None, "ZIP CRC")
        payload = {entry.filename[len(name) + 1:]: archive.read(entry) for entry in entries}
    manifest = json.loads(payload["PACKAGE-MANIFEST.json"])
    require(manifest["schemaVersion"] == 1 and manifest["packageName"] == name and
            manifest["componentProfile"] == profile and
            manifest["publicationAuthorized"] is False, "current package identity")
    listed = manifest["files"]
    require(len({item["path"] for item in listed}) == len(listed) and
            {item["path"] for item in listed} | {"PACKAGE-MANIFEST.json", "SHA256SUMS.txt"} == set(payload),
            "complete manifest")
    for item in listed:
        require(item["bytes"] == len(payload[item["path"]]) and
                item["sha256"] == sha(payload[item["path"]]), "payload hash")
    sums = {}
    for line in payload["SHA256SUMS.txt"].decode("ascii").splitlines():
        digest, name = line.split("  ", 1)
        require(name not in sums and name in payload and digest == sha(payload[name]), "file checksum")
        sums[name] = digest
    require(set(sums) == set(payload) - {"SHA256SUMS.txt"}, "complete checksums")
    qualification = manifest["nativeBinaryQualification"]
    require(qualification.startswith(MODULE + "Tests/Qualification/") and
            ".." not in PurePosixPath(qualification).parts, "qualification boundary")
    canonical = read_regular_bounded(ROOT / qualification, 1024 * 1024)
    require(payload[qualification] == canonical and sha(canonical) == manifest["nativeQualificationSha256"],
            "canonical native qualification")
    record = json.loads(canonical)
    validate_native_record(record, profile)
    release_bytes = payload[MODULE + "Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json"]
    require(sha(release_bytes) == record["qualified_trust_manifest_sha256"],
            "native-qualified original trust manifest")
    release = json.loads(release_bytes)
    binary = payload[MODULE + "Artifacts/Toolbelt.Tsql.SsisDebug.dll"]
    deploy = payload[MODULE + "Artifacts/Deploy.WithAssembly.sql"]
    require(sha(binary, "sha512") == release["sha512"] and
            sha(binary).lower() == record["qualified_assembly_sha256"] and
            sha(deploy) == release["deploymentArtifactSha256"] and
            sha(deploy).lower() == record["qualified_deploy_sql_sha256"] and
            sha(payload[MODULE + "Artifacts/Uninstall.Expanded.sql"]).lower() == record["qualified_uninstall_sql_sha256"] and
            release["reproducedBuild"] is True, "qualified candidate bytes")
    for key in ("sourceFiles", "deploymentFiles"):
        for entry in release[key]:
            relative, digest = entry.split(":", 1)
            source = posixpath.normpath(MODULE + relative)
            require(source.startswith("Modules/") and ".." not in PurePosixPath(source).parts,
                    "build source boundary")
            require(source in payload and sha(payload[source]) == digest, "qualified source bytes")
    legacy = load_legacy_guard()
    require(sha(legacy.ARCHIVE.read_bytes()) == PREDECESSOR_SHA256,
            "frozen previously qualified predecessor")
    legacy.no_codeview(binary)
    require(manifest["predecessorPackageSha256"] == sha(legacy.ARCHIVE.read_bytes()),
            "predecessor package")
    with zipfile.ZipFile(legacy.ARCHIVE) as archive:
        original_notice = archive.read(LEGACY + "/START-HERE.txt").splitlines(keepends=True)[1]
        require(payload["START-HERE.txt"].count(original_notice) == 1,
                "protected original attribution")
        for name in archive.namelist():
            relative = name[len(LEGACY) + 1:]
            if relative.startswith(MODULE) or relative in ("PACKAGE-MANIFEST.json", "SHA256SUMS.txt", "START-HERE.txt"):
                continue
            # The parser's frozen reproducible sources remain in BuildSources/.
            # This root-level shared file is also a native-bound SSIS compiler
            # input; its exact new bytes were checked against release.sourceFiles
            # above. It does not replace the parser binary or its build closure.
            if relative == "Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs":
                require(any(posixpath.normpath(MODULE + entry.split(":", 1)[0]) == relative
                            for entry in release["sourceFiles"]),
                        "shared SSIS guard source is native-bound")
                continue
            require(relative in payload and archive.read(name) == payload[relative],
                    "unchanged predecessor dependency")
    print("SSIS_CURRENT_PACKAGE_VALIDATION_PASS; exact qualified candidate and preserved dependencies; no SQL")
    return manifest, release, payload


PROCEDURE_DELIVERY = MODULE + "Tests/Qualification/ProcedureV1.InstallPackage.Windows2025.20261104.json"
PROCEDURE_ARCHIVE = MODULE + "InstallPackages/" + PROCEDURE_NAME + ".zip"
PROCEDURE_METHODS = {
    MODULE + "Tests/Runtime/" + name for name in (
        "Invoke-ProcedureDefinitionLab.ps1", "Invoke-ProcedureDefinitionCases.ps1",
        "Invoke-CurrentCases.ps1", "Invoke-LabContract.ps1", "Invoke-PackageInstallCases.ps1",
        "Invoke-ComponentsV2Audit.ps1", "Invoke-CurrentQualificationLab.ps1",
    )
} | {MODULE + "Tests/Fixtures/procedure-8.dtsx",
     "Tests/CI/run-lab-local.ps1", "Tests/CI/LabQualifiedContract.ps1"}


def validate_procedure_delivery(*, source_root=ROOT):
    path = ROOT / PROCEDURE_ARCHIVE
    _, release, payload = validate(path, profile=PROCEDURE_PROFILE)
    record = json.loads(read_regular_bounded(ROOT / PROCEDURE_DELIVERY, 1024 * 1024))
    require(record.get("kind") == "ssis_procedure_v1_package_qualification" and
            record.get("schema_version") == "1.0" and record.get("publication_authorized") is False and
            record.get("package") == {"path": PROCEDURE_ARCHIVE, "sha256": sha(read_regular_bounded(path, MAX_PACKAGE_BYTES)),
                                      "manifest_sha256": sha(payload["PACKAGE-MANIFEST.json"])},
            "V1 exact executed ZIP")
    require(record.get("case") == {
        "platform": "windows", "sql_version": "2025", "patch": "CU8", "compatibility_level": 150,
        "deployment_mode": "local", "test_purpose": "Functional", "authenticated_tls": "not executed",
        "package_assertions": 8, "procedure_assertions": 91, "result": "PASS", "cleanup_audit": "PASS",
    }, "V1 package execution scope")
    inputs = record["execution_inputs"]
    require(set(inputs) == PROCEDURE_METHODS, "V1 package execution input closure")
    for source, digest in inputs.items():
        require(sha(read_regular_bounded(ROOT / source, 1024 * 1024)) == digest,
                "V1 package execution input changed: " + source)
        if source in payload:
            require(sha(payload[source]) == digest, "V1 packaged test input changed: " + source)
    for key in ("sourceFiles", "deploymentFiles"):
        for entry in release[key]:
            relative, digest = entry.split(":", 1)
            source = posixpath.normpath(MODULE + relative)
            current = read_regular_bounded(source_root / source, MAX_PACKAGE_BYTES)
            require(sha(current) == digest, "V1 product source changed: " + source)
    print("SSIS_PROCEDURE_V1_DELIVERY_PASS; exact ZIP, source and scoped Windows lifecycle")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--profile", choices=PROFILES, default=CURRENT_PROFILE)
    args = parser.parse_args()
    validate(args.archive, profile=args.profile)
