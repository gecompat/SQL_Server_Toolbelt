"""Validate the bounded JSON Schema central uninstall confirmation qualification."""
from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path, PurePosixPath

REPORT_PATH = "Releases/1.0.0/json-schema-uninstall-confirmation-qualification.json"
PACKAGE_REPORT_PATH = "Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json"
PACKAGE_PATH = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip"
EXPECTED_SOURCE_COMMIT = "6b99d6dccfaa3af7091210d95dd7761a7283178e"
EXPECTED_CASES = (
    (0, "01", "JSON Schema lifecycle: ungültige Consumer-Bestätigung."),
    (1, "0", "JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt."),
)
REQUIRED_SOURCE_PINS = {
    "Tests/Release/Prepare-JsonSchemaAppLockRunset.ps1",
    "Tests/Release/Invoke-JsonSchemaAppLockLab.ps1",
    "Tests/Release/Prepare-JsonSchemaUninstallConfirmationRunset.ps1",
    "Tests/Release/Invoke-JsonSchemaUninstallConfirmationLab.ps1",
    "Tests/Release/Test-JsonSchemaUninstallConfirmationOffline.ps1",
    "Modules/toolbelt.json.schema/Deployment/Uninstall.sql",
    "Modules/toolbelt.json.schema/Deployment/Deploy.sql",
    "Modules/toolbelt.json.core/Deployment/Deploy.sql",
    "Modules/toolbelt.core.result-table/Deployment/Deploy.sql",
}
EXPECTED_SOURCE_PATHS = {
    "Tests/Release/Prepare-JsonSchemaAppLockRunset.ps1",
    "Tests/Release/Invoke-JsonSchemaAppLockLab.ps1",
    "Tests/CI/run-json-schema-lab.ps1",
    "Releases/1.0.0/JSON-SCHEMA-PACKAGE-QUALIFICATION.json",
    "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-CLR-Install.zip",
    "Tests/Release/Test-JsonSchemaAppLockOffline.ps1",
    "Tests/Release/Invoke-ApiQualificationLab.ps1",
    "Tests/Release/Invoke-StablePackageLab.ps1",
    "Tests/Release/ClrCaller.Environment.ps1",
    "Tests/CI/run-lab-local.ps1",
    "Tests/CI/LabQualifiedContract.ps1",
    "Tests/CI/run-csv-memory-lab.ps1",
    "Modules/toolbelt.json.core/Scripts/New-JsonClosureRelease.ps1",
    "Modules/toolbelt.json.core/Scripts/Expand-JsonClosureSql.ps1",
    "Modules/toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json",
    "Modules/toolbelt.core.result-table/Deployment/Deploy.sql",
    "Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql",
    "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql",
    "Modules/toolbelt.json.core/Deployment/Deploy.sql",
    "Modules/toolbelt.json.schema/Deployment/Deploy.sql",
    "Modules/toolbelt.json.core/Deployment/Uninstall.sql",
    "Modules/toolbelt.json.core/Deployment/KnownArtifact.sql",
    "Modules/toolbelt.json.core/Deployment/Preflight.sql",
    "Modules/toolbelt.json.constructors/Deployment/Deploy.sql",
    "Modules/toolbelt.json.constructors/Deployment/Uninstall.sql",
    "Modules/toolbelt.json.constructors/Deployment/KnownArtifact.sql",
    "Modules/toolbelt.json.constructors/Deployment/KnownArtifact1_3.sql",
    "Modules/toolbelt.json.constructors/Deployment/ClrPreflight.sql",
    "Modules/toolbelt.json.constructors/Source/JsonEntryEvaluate.sql",
    "Modules/toolbelt.json.constructors/Source/JsonAggregates.sql",
    "Modules/toolbelt.json.constructors/Source/USP_JsonConstructInternal.sql",
    "Modules/toolbelt.json.constructors/Source/USP_JsonArray.sql",
    "Modules/toolbelt.json.constructors/Source/USP_JsonObject.sql",
    "Modules/toolbelt.json.constructors/Source/USP_JsonArraysByGroup.sql",
    "Modules/toolbelt.json.constructors/Source/USP_JsonObjectsByGroup.sql",
    "Modules/toolbelt.json.schema/Deployment/Uninstall.sql",
    "Modules/toolbelt.json.schema/Deployment/KnownArtifact.sql",
    "Modules/toolbelt.json.schema/Deployment/State.sql",
    "Modules/toolbelt.json.schema/Deployment/Preflight.sql",
    "Modules/toolbelt.json.schema/Source/JsonSchemaBridge.sql",
    "Modules/toolbelt.json.schema/Source/USP_ValidateJsonSchema.sql",
    "Modules/toolbelt.json.core/Clr/Toolbelt.JsonCore.csproj",
    "Modules/toolbelt.json.core/Clr/JsonCanonicalCore.cs",
    "Modules/toolbelt.json.core/Clr/JsonWorkBudget.cs",
    "Modules/toolbelt.json.core/Clr/JsonTokenDocument.cs",
    "Modules/toolbelt.json.core/Clr/JsonOrdinalComparer.cs",
    "Modules/toolbelt.json.core/Clr/JsonSyntaxScanner.cs",
    "Modules/toolbelt.json.core/Clr/Properties/AssemblyInfo.cs",
    "Modules/toolbelt.json.schema/Clr/Toolbelt.JsonSchema.csproj",
    "Modules/toolbelt.json.schema/Clr/SignedDecimalDigits.cs",
    "Modules/toolbelt.json.schema/Clr/ExactJsonNumber.cs",
    "Modules/toolbelt.json.schema/Clr/SchemaTree.cs",
    "Modules/toolbelt.json.schema/Clr/LocalSchemaReference.cs",
    "Modules/toolbelt.json.schema/Clr/SchemaPreflight.cs",
    "Modules/toolbelt.json.schema/Clr/SchemaValidator.cs",
    "Modules/toolbelt.json.schema/Clr/JsonSchemaBridge.cs",
    "Modules/toolbelt.json.schema/Clr/Properties/AssemblyInfo.cs",
    "Tests/Release/Prepare-JsonSchemaUninstallConfirmationRunset.ps1",
    "Tests/Release/Invoke-JsonSchemaUninstallConfirmationLab.ps1",
    "Tests/Release/Test-JsonSchemaUninstallConfirmationOffline.ps1",
}
CASE_KEYS = {
    "ordinal", "confirmation", "expected_error_number", "expected_error_severity",
    "expected_error_state", "expected_message", "blocked_before_mutation",
    "exact_error_message_matched", "session_unchanged", "options_unchanged",
    "transaction_unchanged", "module_unchanged", "core_unchanged",
}
CASE_BOOLEANS = CASE_KEYS - {
    "ordinal", "confirmation", "expected_error_number", "expected_error_severity",
    "expected_error_state", "expected_message",
}


class QualificationError(ValueError):
    """Raised when the report or its public source bindings drift."""


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
        raise QualificationError("source input unavailable or not regular")
    return path


def _require_keys(value, expected, label):
    if not isinstance(value, dict) or set(value) != expected:
        raise QualificationError(f"{label} shape mismatch")


def _typed_equal(actual, expected) -> bool:
    """Compare JSON structures without Python bool/int or int/float coercion."""
    if type(actual) is not type(expected):
        return False
    if isinstance(expected, dict):
        return actual.keys() == expected.keys() and all(
            _typed_equal(actual[key], value) for key, value in expected.items())
    if isinstance(expected, list):
        return len(actual) == len(expected) and all(
            _typed_equal(left, right) for left, right in zip(actual, expected, strict=True))
    return actual == expected


def validate_record(root: Path, record: dict | None = None) -> dict:
    """Validate exact target, confirmations, outcomes, audit, and public pins."""
    root = Path(root).resolve(strict=True)
    if record is None:
        record = _read_json(root / REPORT_PATH)
    _require_keys(record, {"schema_version", "date", "kind", "profile", "result",
                           "publication_authorized", "scope", "inputs", "execution", "not_qualified"}, "report")
    if (record["schema_version"] != "1.0" or record["date"] != "2026-10-30" or
            record["kind"] != "json_schema_uninstall_confirmation_qualification" or
            record["profile"] != "toolbelt.json.schema" or record["result"] != "PASS" or
            record["publication_authorized"] is not False):
        raise QualificationError("qualification identity/status mismatch")

    scope = record["scope"]
    _require_keys(scope, {"module", "purpose", "target", "deployment_mode", "initial_state",
                          "start_session_profile", "negative_case_count", "positive_control_count"}, "scope")
    _require_keys(scope["target"], {"platform", "sql_server_version", "patch", "compatibility_level"}, "target")
    profile = {"quoted_identifier": "ON", "nocount": "ON", "xact_abort": "ON",
               "implicit_transactions": "OFF", "transaction_count": 0,
               "options_unchanged_across_rejection": True}
    if (scope["module"] != "toolbelt.json.schema" or scope["purpose"] != "Functional" or
            not _typed_equal(scope["target"], {"platform": "windows", "sql_server_version": "2025",
                                                 "patch": "CU8", "compatibility_level": 170}) or
            scope["deployment_mode"] != "central" or
            scope["initial_state"] != "Schema module 1.0.1 installed in central mode; toolbelt_json namespace present" or
            not _typed_equal(scope["start_session_profile"], profile) or
            type(scope["negative_case_count"]) is not int or scope["negative_case_count"] != 2 or
            type(scope["positive_control_count"]) is not int or scope["positive_control_count"] != 1):
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
    if (not isinstance(pins, dict) or set(pins) != EXPECTED_SOURCE_PATHS or
            not REQUIRED_SOURCE_PINS.issubset(pins) or PACKAGE_REPORT_PATH not in pins or PACKAGE_PATH not in pins):
        raise QualificationError("public native source pin set mismatch")
    for relative, digest in pins.items():
        if not isinstance(digest, str) or re.fullmatch(r"[a-f0-9]{64}", digest) is None:
            raise QualificationError("source hash shape mismatch")
        if _sha256(_relative_file(root, relative)) != digest:
            raise QualificationError("public source pin drift")
    if (pins[PACKAGE_REPORT_PATH] != package["sha256"] or
            pins[PACKAGE_PATH] != package["package_sha256"]):
        raise QualificationError("package and source bindings differ")

    execution = record["execution"]
    _require_keys(execution, {"source_commit", "target_invocations", "failed_cleaned_attempts",
                              "successful_target_invocations", "independent_audits", "all_audits_pass",
                              "cases", "positive_control", "final_independent_audit"}, "execution")
    counters = {"target_invocations": 4, "failed_cleaned_attempts": 3,
                "successful_target_invocations": 1, "independent_audits": 4}
    if (execution["source_commit"] != EXPECTED_SOURCE_COMMIT or
            any(type(execution[key]) is not int or execution[key] != expected
                for key, expected in counters.items()) or execution["all_audits_pass"] is not True):
        raise QualificationError("execution totals or source commit mismatch")
    cases = execution["cases"]
    if not isinstance(cases, list) or len(cases) != len(EXPECTED_CASES):
        raise QualificationError("case count mismatch")
    for case, (ordinal, confirmation, message) in zip(cases, EXPECTED_CASES, strict=True):
        _require_keys(case, CASE_KEYS, "case")
        if (type(case["ordinal"]) is not int or case["ordinal"] != ordinal or
                case["confirmation"] != confirmation or
                type(case["expected_error_number"]) is not int or case["expected_error_number"] != 55635 or
                type(case["expected_error_severity"]) is not int or case["expected_error_severity"] != 16 or
                type(case["expected_error_state"]) is not int or case["expected_error_state"] != 1 or
                case["expected_message"] != message or
                any(case[key] is not True for key in CASE_BOOLEANS)):
            raise QualificationError("uninstall confirmation case oracle mismatch")
    positive = execution["positive_control"]
    _require_keys(positive, {"confirmation", "uninstall_succeeded", "module_absent",
                             "namespace_retained", "core_unchanged"}, "positive control")
    if not _typed_equal(positive, {"confirmation": "1", "uninstall_succeeded": True, "module_absent": True,
                                   "namespace_retained": True, "core_unchanged": True}):
        raise QualificationError("positive control mismatch")
    audit = execution["final_independent_audit"]
    _require_keys(audit, {"status", "complete_attempt", "owned_database_absent", "owned_trust_restored",
                          "configuration_restored", "source_pins_unchanged"}, "final audit")
    if not _typed_equal(audit, {"status": "PASS", "complete_attempt": True, "owned_database_absent": True,
                                "owned_trust_restored": True, "configuration_restored": True,
                                "source_pins_unchanged": True}):
        raise QualificationError("final independent audit mismatch")
    if record["not_qualified"] != [
            "Other SQL Server versions, compatibility levels, platforms, deployment modes, or session profiles",
            "Full JSON Schema API, rights, lifecycle, performance, and resource matrices",
            "Authenticated TLS identity or release/publication authorization"]:
        raise QualificationError("qualification boundary mismatch")
    return record
