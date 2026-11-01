"""Gebundene Abnahme des öffentlichen SSIS-Trustschritts; kein SQL-Zugriff."""
from __future__ import annotations

import hashlib
import importlib.util
import io
import json
from pathlib import Path
import re
import zipfile

ROOT = Path(__file__).resolve().parents[2]
MODULE = "Modules/toolbelt.tsql.ssis-debug/"
REPORT = MODULE + "Tests/Qualification/AdministrativeTrust.Windows.20261101.json"
METHOD = MODULE + "Tests/InstallerTrust/Invoke-LabTrust.ps1"
SCRIPT = MODULE + "Deployment/Add-TrustedAssembly.sql"
FUNCTIONAL = MODULE + "Tests/Qualification/Current.Functional.20261031.json"
PACKAGE = "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Parameter-Help.zip"
HISTORICAL_PACKAGE = MODULE + "InstallPackages/SSIS-Debug-Current-Install-Windows.zip"
HISTORICAL_PACKAGE_SHA256 = "6E83F4B534339E106B42C8911178BD09CB82001167A356D5A5D63BF69A15F4D7"
HISTORICAL_SCRIPT_SHA256 = "A31385F7BD0E32BA762AA6CB9E9F49B37EAE66BA07C8FED5AB2E803FA969BC24"
NATIVE_METHOD_SHA256 = "78C3B35350677E138A910845AD5442F4F5339C199774C5EC3B9874959650CC5C"
NATIVE_IMPORT = b". (Join-Path $root 'Tests/CI/LabQualifiedContract.ps1')"
INTEGRATED_IMPORT = b"$repoRoot=$root\n. (Join-Path $repoRoot 'Tests/CI/LabQualifiedContract.ps1')"
CHECKS = (
    "database_guest_has_no_server_trust_authority", "guest_did_not_add_entry",
    "exact_approved_hash_present", "existing_entry_preserved", "no_other_hash_added",
    "public_opt_in_repeat", "repeat_preserves_descriptor", "empty_rejected_by_public_guard",
    "empty_entry_unchanged", "empty_other_hashes_unchanged", "null_rejected_by_public_guard",
    "null_entry_unchanged", "null_other_hashes_unchanged", "overlong_rejected_by_public_guard",
    "overlong_entry_unchanged", "overlong_other_hashes_unchanged", "configuration_unchanged",
    "other_trust_unchanged",
)
HISTORY = {"target_driver_calls": 9, "pre_sql_failed": 1, "failed_cleaned": 2,
           "earlier_pass_cleaned": 3, "final_pass_cleaned": 3,
           "independent_audits": 8, "passed_independent_audits": 8,
           "total_driver_calls": 17, "original_failures_retained": True,
           "unknown_hash_trusted": False}
LIMITS = ["Full Windows-authenticated Install-Local workflow", "PrepareServer configuration example",
          "SSMS Windows authentication and full script transport", "Hard interruption recovery",
          "Authenticated TLS in this trust test", "Publication"]


def require(condition, code):
    if not condition:
        raise ValueError("SSIS_ADMINISTRATIVE_TRUST_" + code)


def sha(data):
    return hashlib.sha256(data).hexdigest().upper()


def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "DUPLICATE_KEY")
        result[key] = value
    return result


def validate(root=ROOT, report=None, *, check_files=True):
    root = Path(root)
    if report is None:
        report = json.loads((root / REPORT).read_text("utf-8"), object_pairs_hook=unique)
    require(type(report) is dict and set(report) == {"contract", "date", "result", "test_purpose",
            "authentication", "binary_reference", "scope", "cases", "assertions", "source_sha256",
            "attempt_history", "separate_boundaries", "method_integration"}, "SCHEMA")
    require(report["contract"] == "ssis-administrative-trust-qualification/1" and
            report["date"] == "2026-11-01" and report["result"] == "PASS" and
            report["test_purpose"] == "Functional" and report["authentication"] == "SQL" and
            report["binary_reference"] == FUNCTIONAL, "IDENTITY")
    require(report["scope"] == {"public_script": SCRIPT, "sqlcmd_expansion": "exact approved literal and directive only",
            "database": "master", "configuration_changes": False, "permission_grants": False,
            "lab_infrastructure_changes": False, "guest_context": "EXECUTE AS USER guest; no network-login claim"} and
            all(report["scope"][key] is False for key in ("configuration_changes", "permission_grants", "lab_infrastructure_changes")), "SCOPE")
    require(type(report["assertions"]) is int and report["assertions"] == 54, "ASSERTIONS")
    require(type(report["attempt_history"]) is dict and report["attempt_history"].keys() == HISTORY.keys() and
            all(type(report["attempt_history"][k]) is type(v) and report["attempt_history"][k] == v for k, v in HISTORY.items()), "HISTORY")
    require(report["separate_boundaries"] == LIMITS, "BOUNDARIES")
    cases = report["cases"]
    require(type(cases) is list and len(cases) == 3, "CASES")
    for case, version, patch in zip(cases, ("2019", "2022", "2025"), ("CU32", "CU26", "CU8")):
        require(type(case) is dict and set(case) == {"platform", "sql_version", "patch", "result", "assertions",
                "checks", "insert_executed", "independent_audit", "trust_restored", "other_trust_unchanged",
                "configuration_unchanged"}, "CASE_SCHEMA")
        require(case["platform"] == "windows" and case["sql_version"] == version and case["patch"] == patch and
                case["result"] == "PASS_CLEANED" and type(case["assertions"]) is int and case["assertions"] == 18 and
                case["independent_audit"] == "PASS" and all(case[k] is True for k in
                ("insert_executed", "trust_restored", "other_trust_unchanged", "configuration_unchanged")), "CASE_RESULT")
        require(type(case["checks"]) is dict and tuple(case["checks"]) == CHECKS and
                all(value is True for value in case["checks"].values()), "CASE_ORACLES")
    pins = report["source_sha256"]
    required = {METHOD, SCRIPT, FUNCTIONAL, PACKAGE, "Tests/CI/LabQualifiedContract.ps1", "Tests/CI/run-lab-local.ps1"}
    require(type(pins) is dict and set(pins) == required and all(type(value) is str and
            re.fullmatch(r"[0-9A-F]{64}", value) for value in pins.values()), "SOURCE_CLOSURE")
    integration = report["method_integration"]
    require(type(integration) is dict and set(integration) == {"kind", "native_sha256", "integrated_sha256", "sql_logic_changed"}
            and integration["kind"] == "canonical_repository_root_alias_only" and
            integration["native_sha256"] == pins[METHOD] == NATIVE_METHOD_SHA256 and
            type(integration["integrated_sha256"]) is str and re.fullmatch(r"[0-9A-F]{64}", integration["integrated_sha256"]) and
            integration["sql_logic_changed"] is False, "METHOD_INTEGRATION")
    if check_files:
        for relative, expected in pins.items():
            path = root / relative
            require(path.is_file() and not path.is_symlink(), "SOURCE_FILE")
            data = path.read_bytes()
            if relative == METHOD:
                require(sha(data) == integration["integrated_sha256"] and data.count(INTEGRATED_IMPORT) == 1 and
                        sha(data.replace(INTEGRATED_IMPORT, NATIVE_IMPORT)) == expected, "EXACT_ROOT_ALIAS_BINDING")
            else:
                require(sha(data) == expected, "SOURCE_PIN")
        # Die aktuelle Fachabnahme bindet den identischen unveränderten Binary
        # an seinen öffentlichen Lieferursprung. Keine Runtime-Trusthashes ausgeben.
        spec = importlib.util.spec_from_file_location("ssis_functional_trust_input", root / "Scripts/Release/validate_ssis_current_functional.py")
        functional = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(functional)
        functional.validate(root)
    return report


def snapshot_predecessor_source(root, relative, current):
    """Genau den historischen administrativen Input aus dem gebundenen ZIP lesen.

    Der Snapshotbeleg bleibt an seinen ursprünglichen Artefakten. Der später
    geänderte öffentliche Trustschritt erhält oben seine eigene native Abnahme;
    Generator, Snapshotfälle und deren übrige Inputs bleiben separat gepinnt.
    """
    require(relative == SCRIPT, "SNAPSHOT_PATH")
    report = validate(root)
    require(sha(current) == report["source_sha256"][SCRIPT], "SNAPSHOT_CURRENT_GUARD")
    archive_bytes = (Path(root) / HISTORICAL_PACKAGE).read_bytes()
    require(sha(archive_bytes) == HISTORICAL_PACKAGE_SHA256, "SNAPSHOT_ARCHIVE")
    with zipfile.ZipFile(io.BytesIO(archive_bytes)) as archive:
        original = archive.read("SSIS-Debug-Current-Install-Windows/" + SCRIPT)
    require(sha(original) == HISTORICAL_SCRIPT_SHA256, "SNAPSHOT_ORIGINAL_SCRIPT")
    return original


if __name__ == "__main__":
    validate()
    print("SSIS_ADMINISTRATIVE_TRUST_EVIDENCE_PASS 3 Windows versions; 54 assertions; no SQL")
