"""Build a separate V2 development package from a qualified candidate.

The original V1 ZIP is read and verified, never replaced. Parser binaries,
their historical build-source closure and third-party notices remain exact.
Only the explicitly qualified SSIS candidate and its source closure change.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
import posixpath
import stat
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]
MODULE = "Modules/toolbelt.tsql.ssis-debug/"
NAME = "SSIS-Debug-ComponentsV2-1.0.0-Install-Windows"
LEGACY = "SSIS-Debug-1.0.0-Install-Windows"
PREDECESSOR_SHA256 = "A256929FF32DAEE4087DC61C70BB8D4DFFEBB55772878BE53C658088F4E33049"


def sha(data, algorithm="sha256"):
    return hashlib.new(algorithm, data).hexdigest().upper()


def require(value, reason):
    if not value:
        raise ValueError("SSIS_V2_PACKAGE_INVALID: " + reason)


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def load_legacy_guard():
    path = ROOT / MODULE / "Tests/Static/validate_install_package.py"
    spec = importlib.util.spec_from_file_location("ssis_v1_package_guard", path)
    guard = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(guard)
    return guard


def validate_output(path):
    path = Path(os.path.abspath(path))
    require(path.suffix == ".zip", "ZIP output suffix")
    require(path.is_relative_to(ROOT), "output repository boundary")
    sidecar = path.with_suffix(".zip.sha256")
    for target in (path, sidecar):
        try:
            target.lstat()
        except FileNotFoundError:
            pass
        else:
            require(False, "output already exists")
        require(target.parent.is_dir(), "output parent missing")
        for parent in (target.parent, *target.parent.parents):
            info = parent.lstat()
            require(not stat.S_ISLNK(info.st_mode) and
                    not getattr(info, "st_file_attributes", 0) & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400),
                    "output parent reparse point")
    require(path.resolve(strict=False).is_relative_to(ROOT.resolve()),
            "resolved output repository boundary")
    return path, sidecar


def build(args):
    output, sidecar = validate_output(args.output)
    guard = load_legacy_guard()
    require(sha(guard.ARCHIVE.read_bytes()) == PREDECESSOR_SHA256,
            "frozen previously qualified predecessor")
    commit = subprocess.check_output(
        ["git", "rev-parse", args.source_commit], cwd=ROOT, text=True).strip()
    names = set(subprocess.check_output(
        ["git", "ls-tree", "-r", "--name-only", commit], cwd=ROOT,
        text=True).splitlines())

    def source(path):
        require(path in names, "committed source missing: " + path)
        return subprocess.check_output(["git", "show", commit + ":" + path], cwd=ROOT)

    qualification_path = args.qualification.as_posix()
    require(qualification_path.startswith(MODULE + "Tests/Qualification/") and
            ".." not in PurePosixPath(qualification_path).parts,
            "qualification source boundary")
    qualification_bytes = source(qualification_path)
    record = json.loads(qualification_bytes)
    require(record.get("kind") == "ssis_components_v2_native_qualification" and
            record.get("result") == "PASS" and
            record.get("publication_authorized") is False,
            "explicit completed V2 qualification")
    require(record.get("profile") == "ssis-debug-components-v2",
            "qualified profile")
    expected = {(v, cl, mode) for v, levels in
                (("2019", (150,)), ("2022", (150, 160)),
                 ("2025", (150, 160, 170)))
                for cl in levels for mode in ("local", "central")}
    cases = record.get("cases", [])
    actual = {(case["sql_version"], case["compatibility_level"],
               case["deployment_mode"]) for case in cases}
    require(actual == expected and len(cases) == len(expected) and
            all(case.get("result") == "PASS" and
                case.get("cleanup_audit") == "PASS" and
                case.get("legacy_baseline") == "PASS" for case in cases),
            "complete finite Windows version/CL/mode qualification")
    with zipfile.ZipFile(guard.ARCHIVE) as archive:
        payload = {name[len(LEGACY) + 1:]: archive.read(name)
                   for name in archive.namelist() if not name.endswith("/")}
    for name in list(payload):
        if name.startswith(MODULE) and "/Artifacts/" not in name:
            del payload[name]
    for path in sorted(names):
        navigation = path in (MODULE + "InstallPackages/README.md", MODULE + "InstallPackages/START-HERE.txt")
        if path.startswith(MODULE) and ("/InstallPackages/" not in path or navigation) and "/Artifacts/" not in path:
            payload[path] = source(path)
    # The build launcher is a build-time shared dependency, not a runtime module.
    helper = "Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1"
    payload[helper] = source(helper)
    contract = "Documentation/Architecture/SSIS_COMPONENTS_V2_CONTRACT.md"
    payload[contract] = source(contract)
    manifest_file = "Toolbelt.Tsql.SsisDebug.trust-manifest.json"
    manifest_bytes = (args.ssis_release / manifest_file).read_bytes()
    manifest = json.loads(manifest_bytes)
    require(sha(manifest_bytes) == record["qualified_trust_manifest_sha256"],
            "native-qualified original trust manifest")
    require(manifest["moduleId"] == "toolbelt.tsql.ssis-debug" and
            manifest["moduleVersion"] == "1.0.0" and
            manifest["reproducedBuild"] is True,
            "reproducible candidate identity")
    artifacts = ("Toolbelt.Tsql.SsisDebug.dll", "Deploy.WithAssembly.sql",
                 "Uninstall.Expanded.sql", manifest_file)
    for name in artifacts:
        payload[MODULE + "Artifacts/" + name] = (args.ssis_release / name).read_bytes()
    binary = payload[MODULE + "Artifacts/Toolbelt.Tsql.SsisDebug.dll"]
    deploy = payload[MODULE + "Artifacts/Deploy.WithAssembly.sql"]
    require(sha(binary, "sha512") == manifest["sha512"] and
            sha(binary).lower() == record["qualified_assembly_sha256"] and
            sha(deploy) == manifest["deploymentArtifactSha256"] and
            sha(deploy).lower() == record["qualified_deploy_sql_sha256"] and
            sha(payload[MODULE + "Artifacts/Uninstall.Expanded.sql"]).lower() == record["qualified_uninstall_sql_sha256"],
            "native-qualified candidate bytes")
    guard.no_codeview(binary)
    for key in ("sourceFiles", "deploymentFiles"):
        for entry in manifest[key]:
            relative, expected_hash = entry.split(":", 1)
            path = posixpath.normpath(MODULE + relative)
            require(path.startswith("Modules/") and
                    ".." not in PurePosixPath(path).parts, "build source boundary")
            data = source(path).replace(b"\r\n", b"\n")
            variants = {variant for variant in (data, data.replace(b"\n", b"\r\n"))
                        if sha(variant) == expected_hash}
            require(len(variants) == 1, "native-bound source differs: " + path)
            payload[path] = variants.pop()
    dependency = json.loads(payload[MODULE + "Contracts/DependencyPins.json"])
    parser = json.loads(payload["Modules/toolbelt.tsql.script-parser/Artifacts/Toolbelt.Tsql.ScriptParser.trust-manifest.json"])
    require(manifest["parserSha512"] == parser["sha512"] == dependency["parserSha512"] and
            manifest["scriptDomSha512"] == parser["scriptDomSha512"] == dependency["scriptDomSha512"],
            "unchanged parser closure")
    payload[qualification_path] = qualification_bytes
    legacy_start = payload["START-HERE.txt"]
    payload["START-HERE.txt"] = (
        "SSIS Components V2 development/test installation; unreleased.\n"
        "Read Modules/toolbelt.tsql.ssis-debug/README.md and the V2 contract.\n"
        "Windows SQL Server only; no file parsing/writes or package execution.\n"
        "V1 API remains available; V2 requires explicit opt-in.\n"
        "Source commit: " + commit + "\n\n"
        "The preserved installation guide below remains applicable. Select the V2 context explicitly.\n\n").encode("utf-8") + legacy_start
    old_manifest = json.loads(payload["PACKAGE-MANIFEST.json"])
    output_manifest = dict(old_manifest)
    output_manifest.update(
        packageName=NAME, packageDate="2026-10-28", sourceCommit=commit,
        componentProfile="ssis-debug-components-v2", publicationAuthorized=False,
        nativeBinaryQualification=qualification_path,
        nativeQualificationSha256=sha(qualification_bytes),
        predecessorPackageSha256=sha(guard.ARCHIVE.read_bytes()),
        validationScope="Separately qualified V2 candidate; V1 historical package preserved.")
    output_manifest["files"] = [
        {"path": path, "bytes": len(data), "sha256": sha(data)}
        for path, data in sorted(payload.items())
        if path not in ("PACKAGE-MANIFEST.json", "SHA256SUMS.txt")]
    payload["PACKAGE-MANIFEST.json"] = encoded(output_manifest)
    payload["SHA256SUMS.txt"] = "".join(
        sha(data) + "  " + path + "\n" for path, data in sorted(payload.items())
        if path != "SHA256SUMS.txt").encode("ascii")
    validate_output(output)
    with zipfile.ZipFile(output, "x", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path, data in sorted(payload.items()):
            info = zipfile.ZipInfo(NAME + "/" + path, (2026, 10, 28, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data)
    with sidecar.open("x", encoding="ascii", newline="\n") as stream:
        stream.write(sha(output.read_bytes()) + "  " + output.name + "\n")
    print("SSIS_V2_PACKAGE_BUILD_PASS; qualified bytes and source closure; no SQL")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-commit", default="HEAD")
    parser.add_argument("--ssis-release", required=True, type=Path)
    parser.add_argument("--qualification", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    build(parser.parse_args())
