"""Validate the bounded JSON Schema deploy-collision qualification."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path, PurePosixPath

REPORT_PATH = "Releases/1.0.0/json-schema-deploy-collision-qualification.json"
PACKAGE_REPORT_PATH = "Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json"
PACKAGE_PATH = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip"
SOURCE_COMMIT = "6344a220b1c56ae5166ca2ff3a36eb925e959ae1"
PIN_COUNT = 66
CASES = (
    ("reserved_temp", 55633, "JSON Schema lifecycle: reservierter Callerzustand belegt."),
    ("public_slot", 55634, "JSON Schema lifecycle: unregistrierter oder fremder Zielslot."),
    ("internal_slot", 55634, "JSON Schema lifecycle: unregistrierter oder fremder Zielslot."),
    ("orphan_mode", 55634, "JSON Schema lifecycle: unregistrierter oder fremder Zielslot."),
)
CASE_FLAGS = {
    "exact_error_message_matched", "blocked_before_mutation", "module_snapshot_unchanged",
    "fixture_preserved", "fixture_removed", "core_unchanged", "contender_session_unchanged",
    "transaction_absent", "application_locks_absent",
}
REQUIRED_SOURCE_PINS = {
    "Tests/Release/Prepare-JsonSchemaDeployCollisionRunset.ps1",
    "Tests/Release/Invoke-JsonSchemaDeployCollisionLab.ps1",
    "Tests/Release/Test-JsonSchemaDeployCollisionOffline.ps1",
    "Tests/Release/Prepare-JsonSchemaCallerTransactionRunset.ps1",
    "Tests/Release/Invoke-JsonSchemaCallerTransactionLab.ps1",
    "Tests/Release/Test-JsonSchemaCallerTransactionOffline.ps1",
    "Tests/Release/Invoke-JsonSchemaUninstallAppLockLab.ps1",
    "Tests/Release/Test-JsonSchemaUninstallAppLockOffline.ps1",
    "Tests/Release/Invoke-JsonSchemaAppLockLab.ps1",
    "Tests/Release/Invoke-StablePackageLab.ps1",
    "Tests/Release/Invoke-ApiQualificationLab.ps1",
    "Tests/Release/ClrCaller.Environment.ps1",
    "Tests/CI/run-lab-local.ps1",
    "Tests/CI/LabQualifiedContract.ps1",
    "Modules/toolbelt.json.schema/Deployment/Deploy.sql",
    "Modules/toolbelt.json.schema/Deployment/Preflight.sql",
    "Modules/toolbelt.json.core/Deployment/Deploy.sql",
    "Modules/toolbelt.core.result-table/Deployment/Deploy.sql",
}


class QualificationError(ValueError):
    """Raised when the public record or its bindings drift."""


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
    if (relative.is_absolute() or not relative.parts or
            any(part in {".", "..", ".runtime"} for part in relative.parts)):
        raise QualificationError("source path escapes public repository inputs")
    path = root.joinpath(*relative.parts)
    if not path.is_file() or path.is_symlink() or not path.resolve(strict=True).is_relative_to(root):
        raise QualificationError("source input is unavailable or not regular")
    return path


def _require_keys(value, expected, label):
    if not isinstance(value, dict) or set(value) != expected:
        raise QualificationError(f"{label} shape mismatch")


def _require_int(value, expected):
    if type(value) is not int or value != expected:
        raise QualificationError("integer oracle mismatch")


def validate_record(root: Path, record: dict | None = None) -> dict:
    """Validate the one executed deployment scope, fixed oracles, and public pins."""
    root = Path(root).resolve(strict=True)
    if record is None:
        record = _read_json(root / REPORT_PATH)
    _require_keys(record, {"schema_version", "date", "kind", "profile", "result",
                           "publication_authorized", "scope", "inputs", "execution", "not_qualified"}, "report")
    if (record["schema_version"] != "1.0" or record["date"] != "2026-10-30" or
            record["kind"] != "json_schema_deploy_collision_qualification" or
            record["profile"] != "toolbelt.json.schema" or record["result"] != "PASS" or
            record["publication_authorized"] is not False):
        raise QualificationError("qualification identity/status mismatch")

    scope = record["scope"]
    _require_keys(scope, {"module", "purpose", "target", "deployment_mode", "initial_state",
                          "case_count", "positive_control"}, "scope")
    _require_keys(scope["target"], {"platform", "sql_server_version", "patch", "compatibility_level"}, "target")
    if (scope["module"] != "toolbelt.json.schema" or scope["purpose"] != "Functional" or
            scope["target"] != {"platform": "windows", "sql_server_version": "2025",
                                "patch": "CU8", "compatibility_level": 170} or
            scope["deployment_mode"] != "local" or
            scope["initial_state"] != "Schema module absent; owned empty toolbelt_json namespace created after the baseline" or
            type(scope["case_count"]) is not int or scope["case_count"] != 4 or
            scope["positive_control"] != "one Deploy after all four owned fixtures were removed"):
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
    package_report = _relative_file(root, package["path"])
    package_archive = _relative_file(root, package["package_path"])
    if _sha256(package_report) != package["sha256"] or _sha256(package_archive) != package["package_sha256"]:
        raise QualificationError("package input pin drift")
    qualified = _read_json(package_report)
    if (qualified.get("status") != "PASS" or qualified.get("publication_authorized") is not False or
            qualified.get("package", {}).get("sha256") != package["package_sha256"]):
        raise QualificationError("qualified package report mismatch")

    pins = inputs["source_pins"]
    if not isinstance(pins, dict) or len(pins) != PIN_COUNT or not REQUIRED_SOURCE_PINS.issubset(pins):
        raise QualificationError("public native source pin set mismatch")
    for relative, digest in pins.items():
        if not isinstance(digest, str) or re.fullmatch(r"[a-f0-9]{64}", digest) is None:
            raise QualificationError("source hash shape mismatch")
        if _sha256(_relative_file(root, relative)) != digest:
            import parameter_help_transition
            try:
                parameter_help_transition.bound_source(root, relative, digest)
            except ValueError as error:
                raise QualificationError("public source pin drift") from error

    execution = record["execution"]
    _require_keys(execution, {"source_commit", "target_invocations", "failed_cleaned_attempts",
                              "successful_target_invocations", "independent_audits", "all_audits_pass",
                              "cases", "positive_control", "fixtures_removed_before_positive_control",
                              "final_independent_audit"}, "execution")
    if (execution["source_commit"] != SOURCE_COMMIT or type(execution["target_invocations"]) is not int or
            execution["target_invocations"] != 1 or type(execution["failed_cleaned_attempts"]) is not int or
            execution["failed_cleaned_attempts"] != 0 or type(execution["successful_target_invocations"]) is not int or
            execution["successful_target_invocations"] != 1 or type(execution["independent_audits"]) is not int or
            execution["independent_audits"] != 1 or execution["all_audits_pass"] is not True or
            execution["fixtures_removed_before_positive_control"] is not True):
        raise QualificationError("execution totals or source commit mismatch")

    cases = execution["cases"]
    if not isinstance(cases, list) or len(cases) != len(CASES):
        raise QualificationError("case count mismatch")
    case_keys = {"ordinal", "kind", "expected_error_number", "expected_error_state", "expected_message",
                 *CASE_FLAGS}
    for ordinal, (case, (kind, number, message)) in enumerate(zip(cases, CASES, strict=True)):
        _require_keys(case, case_keys, "case")
        if (type(case["ordinal"]) is not int or case["ordinal"] != ordinal or case["kind"] != kind or
                type(case["expected_error_number"]) is not int or case["expected_error_number"] != number or
                type(case["expected_error_state"]) is not int or case["expected_error_state"] != 1 or
                case["expected_message"] != message or any(case[key] is not True for key in CASE_FLAGS)):
            raise QualificationError("deploy collision case oracle mismatch")

    positive = execution["positive_control"]
    _require_keys(positive, {"count", "after_all_fixtures_removed", "deploy_succeeded", "schema_installed",
                             "core_unchanged"}, "positive control")
    if positive != {"count": 1, "after_all_fixtures_removed": True, "deploy_succeeded": True,
                    "schema_installed": True, "core_unchanged": True}:
        raise QualificationError("positive Deploy control mismatch")

    audit = execution["final_independent_audit"]
    _require_keys(audit, {"status", "complete_attempt", "owned_database_absent", "owned_trust_restored",
                          "configuration_restored", "source_pins_unchanged"}, "final audit")
    if audit != {"status": "PASS", "complete_attempt": True, "owned_database_absent": True,
                 "owned_trust_restored": True, "configuration_restored": True, "source_pins_unchanged": True}:
        raise QualificationError("final independent audit mismatch")

    if record["not_qualified"] != [
            "Other SQL Server versions, compatibility levels, platforms, or deployment modes",
            "The complete JSON Schema ownership, marker, slot, lifecycle, API, rights, and resource matrices",
            "Authenticated TLS identity or release/publication authorization"]:
        raise QualificationError("qualification boundary mismatch")
    return record
