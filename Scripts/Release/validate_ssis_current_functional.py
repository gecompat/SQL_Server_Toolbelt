"""Prüft die endliche aktuelle SSIS-Funktionsabnahme und ihre Quellbindungen."""
from __future__ import annotations

import hashlib
import json
import io
from pathlib import Path, PurePosixPath
import re
import zipfile

ROOT = Path(__file__).resolve().parents[2]
MODULE = "Modules/toolbelt.tsql.ssis-debug/"
REPORT = MODULE + "Tests/Qualification/Current.Functional.20261031.json"
HELP_PACKAGE = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Parameter-Help.zip"
CURRENT_PACKAGE = MODULE + "InstallPackages/SSIS-Debug-Current-Install-Windows.zip"
REUSED_EVIDENCE = {MODULE + "Tests/Qualification/Current.InstallPackage.Matrix.20261029.json",
                   "Releases/1.0.0/ssis-current-standalone-installer-matrix.json",
                   MODULE + "Tests/Qualification/Current.SnapshotCoherence.20261030.json",
                   "Releases/1.0.0/parameter-help-qualification.json"}
EXPECTED_CONTEXTS = {(version, level, mode) for version, levels in
                     [("2019", [150]), ("2022", [150, 160]), ("2025", [150, 160, 170])]
                     for level in levels for mode in ("local", "central")}
GATES = {"current_api", "component_expression", "api_metadata", "caller_rights",
         "lifecycle", "resources", "catalog_safety", "cross_database", "offline_framework"}
# Diese nachträglich ergänzten separaten Anmelde-/Transportmethoden wurden
# vom ursprünglichen Functional-Harness nicht aufgerufen. Dessen Originalpins
# bleiben unverändert; ihre eigenen Nachweise werden separat validiert.
SEPARATE_ACCESS_METHODS = {MODULE + "Tests/Runtime/" + name for name in (
    "CurrentWindowsAccess.sql", "Invoke-CurrentAccessAudit.ps1", "Invoke-CurrentAccessCases.ps1",
    "Invoke-CurrentAccessLab.ps1", "Invoke-CurrentGuiAccessCase.ps1",
    "Invoke-CurrentWindowsAccessCases.ps1", "Invoke-CurrentAuthenticatedTlsLab.ps1")}


def require(condition, message):
    if not condition:
        raise ValueError("SSIS_CURRENT_FUNCTIONAL_" + message)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "DUPLICATE_JSON_KEY")
        result[key] = value
    return result


def semantic_api(value):
    if isinstance(value, dict):
        return {key: semantic_api(item) for key, item in value.items() if key != "description"}
    if isinstance(value, list):
        return [semantic_api(item) for item in value]
    return value


def read(root, relative):
    require(isinstance(relative, str) and "\\" not in relative and
            not PurePosixPath(relative).is_absolute() and
            all(part not in ("", ".", "..") for part in relative.split("/")), "PATH")
    path = root / relative
    require(path.resolve().is_relative_to(root.resolve()), "PATH_ESCAPE")
    require(path.is_file() and not path.is_symlink() and path.stat().st_size <= 134217728, "FILE")
    return path.read_bytes()


def reuse_binding(root):
    """Nur der generierte Hilfetext unterscheidet sich vom Current-Vorgänger."""
    data = read(root, CURRENT_PACKAGE)
    unchanged = {}
    prefix = "SSIS-Debug-Current-Install-Windows/"
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        candidates = {name[len(prefix):]: name for name in archive.namelist()
                      if name.startswith(prefix + MODULE) and
                      (("/Clr/" in name and name.endswith((".cs", ".csproj"))) or
                       ("/Exchange/Core/" in name and name.endswith(".cs")))}
        local = {path.relative_to(root).as_posix() for folder in ("Clr", "Exchange/Core")
                 for path in (root / MODULE / folder).rglob("*")
                 if path.is_file() and path.suffix in (".cs", ".csproj") and
                 not {"bin", "obj"}.intersection(path.parts)}
        require(local == set(candidates), "SEMANTIC_SOURCE_INVENTORY")
        for relative, entry in sorted(candidates.items()):
            current = read(root, relative)
            if relative == MODULE + "Clr/HelpContract.Generated.cs":
                continue
            require(current == archive.read(entry), "SEMANTIC_SOURCE_CHANGED")
            unchanged[relative] = sha(current)
        guard = "Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs"
        require(read(root, guard) == archive.read(prefix + guard), "SHARED_GUARD_CHANGED")
        unchanged[guard] = sha(read(root, guard))
        api = MODULE + "Contracts/Api.json"
        require(semantic_api(json.loads(read(root, api), object_pairs_hook=unique)) ==
                semantic_api(json.loads(archive.read(prefix + api), object_pairs_hook=unique)),
                "FUNCTIONAL_API_CHANGED")
    return {"archive": CURRENT_PACKAGE, "archive_sha256": sha(data),
            "unchanged_semantic_sources": unchanged,
            "api_unchanged_except_descriptions": True,
            "changed_help_source": MODULE + "Clr/HelpContract.Generated.cs"}


def validate(root=ROOT, report=None, *, check_files=True):
    root = Path(root)
    if report is None:
        report = json.loads(read(root, REPORT), object_pairs_hook=unique)
    require(report.get("kind") == "ssis_current_functional_qualification" and
            report.get("schema_version") == "1.0" and report.get("result") == "PASS", "KIND_RESULT")
    require(report.get("publication_authorized") is False and
            report.get("functional_scope_complete") is True, "AUTHORITY_SCOPE")
    require(report.get("scope") == "current_supported_debug_contract", "SCOPE")
    require(set(report.get("gates", {})) == GATES and
            all(value == "PASS" for value in report["gates"].values()), "GATES")
    contexts = set()
    for case in report.get("cases", []):
        require(isinstance(case, dict) and type(case.get("compatibility_level")) is int,
                "CASE_TYPES")
        key = (case.get("sql_version"), case["compatibility_level"], case.get("deployment_mode"))
        require(key not in contexts, "DUPLICATE_CASE")
        contexts.add(key)
        require(case.get("result") == "PASS" and case.get("cleanup_audit") == "PASS" and
                case.get("input_pins_unchanged") is True, "CASE_RESULT")
        require(case.get("long_plan_default_budget") is (case["compatibility_level"] == 170), "LONG_PLAN_SCOPE")
        for field in ("current_assertions", "semantic_assertions", "api_assertions", "rights_assertions", "lifecycle_assertions"):
            require(type(case.get(field)) is int and case[field] > 0, "ASSERTION_COUNT")
    require(contexts == EXPECTED_CONTEXTS, "CONTEXT_MATRIX")
    require(report.get("long_plan") == {"groups": 64, "minimum_units": 17, "typed_rows": 6,
                                        "output_limit_bytes": 134217728, "limits_overridden": False}, "LONG_PLAN_CONTRACT")
    require(report["long_plan"]["limits_overridden"] is False, "LONG_PLAN_TYPES")
    require(report.get("offline_framework") == {"profile": "Full", "bounded_children": 26, "result": "PASS"}, "OFFLINE_FRAMEWORK")
    require(report.get("authenticated_tls") == "not executed" and
            report.get("ssis_runtime_parity") == "not applicable to debug contract", "BOUNDARIES")
    if check_files:
        required = {path.relative_to(root).as_posix()
                    for folder in ("Tests/Runtime", "Tests/Fixtures", "Contracts")
                    for path in (root / MODULE / folder).rglob("*")
                    if path.is_file() and "__pycache__" not in path.parts}
        required.difference_update(SEPARATE_ACCESS_METHODS)
        required.update({"Tests/CI/run-lab-local.ps1", "Tests/CI/LabQualifiedContract.ps1"})
        require(isinstance(report.get("source_sha256"), dict) and
                required.issubset(report["source_sha256"]), "SOURCE_CLOSURE")
        require(report["reuse_binding"] == reuse_binding(root), "REUSE_BINDING")
        for relative, expected in report["source_sha256"].items():
            require(sha(read(root, relative)) == expected, "SOURCE_PIN")
        require(len(report.get("reused_evidence", [])) == len(REUSED_EVIDENCE) and
                {record.get("path") for record in report["reused_evidence"]} == REUSED_EVIDENCE, "REUSE_CLOSURE")
        for record in report["reused_evidence"]:
            require(sha(read(root, record["path"])) == record["sha256"], "EVIDENCE_PIN")
            previous = json.loads(read(root, record["path"]), object_pairs_hook=unique)
            require(previous.get("result") == "PASS", "REUSED_RESULT")
            if record["path"].endswith("Current.InstallPackage.Matrix.20261029.json"):
                require(previous["package_sha256"].lower() == report["reuse_binding"]["archive_sha256"], "REUSED_ARCHIVE")
        package = read(root, HELP_PACKAGE)
        require(sha(package) == report["current_delivery"]["package_sha256"], "HELP_PACKAGE_PIN")
        with zipfile.ZipFile(io.BytesIO(package)) as archive:
            build = json.loads(archive.read("SSIS-BUILD.json"), object_pairs_hook=unique)
            require(build["sourceFingerprintSha256"] == report["current_delivery"]["source_fingerprint_sha256"] and
                    build["deploymentArtifactSha256"] == report["current_delivery"]["deployment_sha256"], "BUILD_BINDING")
            binaries = [bytes.fromhex(match.group(1)) for match in
                        re.finditer(r"0x([0-9A-Fa-f]{4096,})", archive.read("Install-Windows-local.sql").decode("utf-8-sig"))]
            matches = [binary for binary in binaries
                       if hashlib.sha512(binary).hexdigest().upper() == build["sha512"]]
            require(len(matches) == 1 and sha(matches[0]) == report["current_delivery"]["assembly_sha256"],
                    "DELIVERED_BINARY_BINDING")
    return report


if __name__ == "__main__":
    validate()
    print("SSIS_CURRENT_FUNCTIONAL_QUALIFICATION_PASS; fixed current scope; no SQL")
