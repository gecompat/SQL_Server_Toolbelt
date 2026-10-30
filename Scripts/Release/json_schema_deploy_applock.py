"""Validate the narrowly scoped JSON Schema deployment AppLock evidence."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path, PurePosixPath

REPORT_PATH = "Releases/1.0.0/json-schema-deploy-lock-qualification.json"
PACKAGE_REPORT_PATH = "Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json"
PACKAGE_PATH = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip"
EXPECTED_RESOURCES = (
    "toolbelt.deploy.json.shared-core",
    "toolbelt.deploy.toolbelt.json.schema",
)
REQUIRED_SOURCE_PINS = {
    "Modules/toolbelt.core.result-table/Deployment/Deploy.sql",
    "Modules/toolbelt.json.core/Deployment/Deploy.sql",
    "Modules/toolbelt.json.schema/Deployment/Deploy.sql",
    "Modules/toolbelt.json.schema/Deployment/Uninstall.sql",
    "Tests/CI/LabQualifiedContract.ps1",
    "Tests/CI/run-json-schema-lab.ps1",
    "Tests/CI/run-lab-local.ps1",
    "Tests/Release/ClrCaller.Environment.ps1",
    "Tests/Release/Invoke-JsonSchemaAppLockLab.ps1",
    "Tests/Release/Invoke-StablePackageLab.ps1",
    "Tests/Release/Prepare-JsonSchemaAppLockRunset.ps1",
    "Tests/Release/Test-JsonSchemaAppLockOffline.ps1",
}
REPORT_KEYS = {
    "schema_version", "date", "kind", "profile", "result", "publication_authorized",
    "scope", "inputs", "execution", "not_qualified",
}


class QualificationError(ValueError):
    """Raised when public evidence or its current source bindings drift."""


def _unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise QualificationError("duplicate JSON property")
        result[key] = value
    return result


def _read_json(path: Path):
    try:
        return json.loads(path.read_bytes(), object_pairs_hook=_unique_object)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise QualificationError("qualification JSON unavailable or invalid") from exc


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while chunk := stream.read(1024 * 1024):
            digest.update(chunk)
    return digest.hexdigest()


def _relative_file(root: Path, value: str) -> Path:
    if not isinstance(value, str) or "\\" in value:
        raise QualificationError("source path is not repository relative")
    relative = PurePosixPath(value)
    if relative.is_absolute() or not relative.parts or any(part in {".", "..", ".runtime"} for part in relative.parts):
        raise QualificationError("source path escapes public repository inputs")
    path = root.joinpath(*relative.parts)
    if not path.is_file() or path.is_symlink():
        raise QualificationError("source input is unavailable or not regular")
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(root.resolve(strict=True)):
        raise QualificationError("source input escapes repository")
    return path


def _require_keys(value, expected, label):
    if not isinstance(value, dict) or set(value) != expected:
        raise QualificationError(f"{label} shape mismatch")


def validate_record(root: Path, record: dict | None = None) -> dict:
    """Check the fixed scope, aggregate outcomes, package identity and public source pins."""
    root = Path(root).resolve(strict=True)
    if record is None:
        record = _read_json(root / REPORT_PATH)
    _require_keys(record, REPORT_KEYS, "report")
    if (record["schema_version"] != "1.0" or record["kind"] != "json_schema_deploy_applock_qualification" or
            record["profile"] != "toolbelt.json.schema" or record["result"] != "PASS" or
            record["publication_authorized"] is not False or record["date"] != "2026-10-30"):
        raise QualificationError("qualification identity/status mismatch")

    scope = record["scope"]
    _require_keys(scope, {"module", "purpose", "target", "deployment_mode", "baseline", "resources", "case_count"}, "scope")
    _require_keys(scope["target"], {"platform", "sql_server_version", "compatibility_level"}, "target")
    _require_keys(scope["baseline"], {"result_table", "json_core", "schema_namespace_absent_initially"}, "baseline")
    if (scope["module"] != "toolbelt.json.schema" or scope["purpose"] != "Functional" or
            scope["target"] != {"platform": "windows", "sql_server_version": "2025", "compatibility_level": 170} or
            scope["deployment_mode"] != "local" or scope["case_count"] != 2 or
            scope["baseline"] != {"result_table": True, "json_core": True, "schema_namespace_absent_initially": True} or
            scope["resources"] != list(EXPECTED_RESOURCES)):
        raise QualificationError("qualification scope mismatch")

    inputs = record["inputs"]
    _require_keys(inputs, {"package_qualification", "source_pins"}, "inputs")
    package = inputs["package_qualification"]
    _require_keys(package, {"path", "sha256", "package_path", "package_sha256"}, "package binding")
    if package["path"] != PACKAGE_REPORT_PATH or package["package_path"] != PACKAGE_PATH:
        raise QualificationError("package qualification path mismatch")
    for key in ("sha256", "package_sha256"):
        if not isinstance(package[key], str) or re.fullmatch(r"[a-f0-9]{64}", package[key]) is None:
            raise QualificationError("package hash shape mismatch")
    package_report_path = _relative_file(root, package["path"])
    package_archive_path = _relative_file(root, package["package_path"])
    if _sha256(package_report_path) != package["sha256"] or _sha256(package_archive_path) != package["package_sha256"]:
        raise QualificationError("package input pin drift")
    package_report = _read_json(package_report_path)
    if (package_report.get("status") != "PASS" or package_report.get("publication_authorized") is not False or
            package_report.get("package", {}).get("sha256") != package["package_sha256"]):
        raise QualificationError("qualified package report mismatch")

    pins = inputs["source_pins"]
    if not isinstance(pins, dict) or not REQUIRED_SOURCE_PINS.issubset(pins):
        raise QualificationError("required public source pins missing")
    for relative, digest in pins.items():
        if not isinstance(digest, str) or re.fullmatch(r"[a-f0-9]{64}", digest) is None:
            raise QualificationError("source hash shape mismatch")
        if _sha256(_relative_file(root, relative)) != digest:
            raise QualificationError("public source pin drift")

    execution = record["execution"]
    _require_keys(execution, {"source_commit", "native_target_invocations", "failed_cleaned_attempts",
                              "successful_target_invocations", "independent_audits", "all_audits_pass",
                              "cases", "final_independent_audit"}, "execution")
    if (not isinstance(execution["source_commit"], str) or re.fullmatch(r"[a-f0-9]{40}", execution["source_commit"]) is None or
            execution["source_commit"] != "19cd830f6beddb3f5ece2ecef5ecd41ac6d5a85b" or
            execution["native_target_invocations"] != 6 or execution["failed_cleaned_attempts"] != 5 or
            execution["successful_target_invocations"] != 1 or execution["independent_audits"] != 6 or
            execution["all_audits_pass"] is not True):
        raise QualificationError("execution totals or source commit mismatch")
    cases = execution["cases"]
    if not isinstance(cases, list) or len(cases) != 2:
        raise QualificationError("case count mismatch")
    case_keys = {"resource", "expected_error_number", "expected_error_state", "holder_lock_granted",
                 "exact_block_message_matched", "blocked", "isolated_contender_transaction_absent",
                 "external_contender_transactions_and_locks_absent", "positive_control_after_release",
                 "failed_deploy_snapshot_unchanged"}
    for case, resource in zip(cases, EXPECTED_RESOURCES, strict=True):
        _require_keys(case, case_keys, "case")
        if (case["resource"] != resource or case["expected_error_number"] != 55637 or
                case["expected_error_state"] != 1 or any(case[key] is not True for key in (
                    "holder_lock_granted", "exact_block_message_matched", "blocked",
                    "isolated_contender_transaction_absent", "external_contender_transactions_and_locks_absent",
                    "positive_control_after_release", "failed_deploy_snapshot_unchanged"))):
            raise QualificationError("case oracle mismatch")
    audit = execution["final_independent_audit"]
    _require_keys(audit, {"status", "complete_attempt", "owned_database_absent", "owned_trust_restored",
                          "configuration_restored", "source_pins_unchanged"}, "final audit")
    if audit != {"status": "PASS", "complete_attempt": True, "owned_database_absent": True,
                 "owned_trust_restored": True, "configuration_restored": True, "source_pins_unchanged": True}:
        raise QualificationError("final independent audit mismatch")

    expected_not_qualified = [
        "Other SQL Server versions, compatibility levels, platforms, or deployment modes",
        "Full JSON Schema API, rights, lifecycle, performance, and resource matrices",
        "Authenticated TLS identity or publication authorization",
    ]
    if record["not_qualified"] != expected_not_qualified:
        raise QualificationError("qualification boundary mismatch")
    return record
