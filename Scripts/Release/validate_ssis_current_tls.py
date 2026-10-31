"""Gebundene Windows-TLS-Abnahme; keine Verbindung und keine privaten Journale."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
MODULE = "Modules/toolbelt.tsql.ssis-debug/"
REPORT = MODULE + "Tests/Qualification/Current.AuthenticatedTls.Windows.20261031.json"
FUNCTIONAL = MODULE + "Tests/Qualification/Current.Functional.20261031.json"
METHODS = {MODULE + "Tests/Runtime/" + name for name in (
    "Invoke-CurrentAuthenticatedTlsLab.ps1", "Invoke-LabContract.ps1",
    "Invoke-CurrentCases.ps1", "Invoke-ComponentsV2Audit.ps1",
    "Invoke-CurrentQualificationLab.ps1")}
METHODS |= {"Tests/CI/LabQualifiedContract.ps1", "Tests/CI/run-lab-local.ps1"}
TRANSPORT = {"test_purpose": "AuthenticatedTls", "authentication": "SQL",
             "encrypt": True, "trust_server_certificate": False, "pooling": False,
             "connect_retry_count": 0, "signed_v2": True, "same_export_bytes": True,
             "fresh_lab_reader_before_every_open": True, "fallback": False,
             "wire_certificate_fingerprint": "NOT_OBSERVED"}
CLEANUP = {"sql_independent_audit": "PASS", "own_vm_absent": True,
           "protected_vms_unchanged": True, "host_root_trust_unchanged": True,
           "temporary_activation_adapter": "CLEANED"}
HISTORY = {"new_windows_runs": 2, "first_run": "offline Mount-VHD failed; removed and audited",
           "second_run": "ExistingOnly activation failed; same owned run resumed with EvaluationOnline/AllowTemporary",
           "uninterrupted_public_create_pass_claimed": False,
           "original_failures_retained": True, "additional_vm_created_for_resume": False,
           "first_tls_controller": "412 assertions passed; configuration restore and audit failed",
           "first_tls_recovery_audit": "PASS", "final_tls_controller": "PASS_CLEANED"}
LIMITS = ["administrative installer trust", "hard host/transport interruption",
          "Linux export host", "production capacity", "SSIS runtime parity"]


def require(condition, code):
    if not condition:
        raise ValueError("SSIS_CURRENT_TLS_" + code)


def exact(actual, expected, code):
    # JSON numeric zero/one must never satisfy a Boolean evidence claim.
    require(type(actual) is dict and actual.keys() == expected.keys() and
            all(type(actual[k]) is type(v) and actual[k] == v for k, v in expected.items()), code)


def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "DUPLICATE_KEY")
        result[key] = value
    return result


def read(root, path):
    require(isinstance(path, str) and "\\" not in path and not Path(path).is_absolute() and
            all(p not in ("", ".", "..") for p in path.split("/")), "PATH")
    full = root / path
    require(full.is_file() and not full.is_symlink() and
            full.resolve().is_relative_to(root.resolve()), "FILE")
    return full.read_bytes()


def validate(root=ROOT, report=None, *, check_files=True):
    root = Path(root)
    if report is None:
        report = json.loads(read(root, REPORT), object_pairs_hook=unique)
    require(set(report) == {"schema_version", "kind", "date", "result", "publication_authorized",
                           "functional_evidence", "source_sha256", "lab", "transport", "cases",
                           "assertions", "guarded_connections", "cleanup", "attempt_history",
                           "separate_gates"}, "CLOSED_RECORD")
    require(report["schema_version"] == "1.0" and report["kind"] == "ssis_current_authenticated_tls_qualification" and
            report["date"] == "2026-10-31" and report["result"] == "PASS" and
            report["publication_authorized"] is False, "RESULT_AUTHORITY")
    exact(report["transport"], TRANSPORT, "TRANSPORT")
    exact(report["cleanup"], CLEANUP, "CLEANUP")
    exact(report["attempt_history"], HISTORY, "ORIGINAL_FAILURES")
    require(report["separate_gates"] == LIMITS, "SUPPORT_BOUNDARY")
    lab = report["lab"]
    require(set(lab) == {"provider", "platform", "sql_version", "patch", "sql_build", "qualification_version",
                         "strict_client_results", "source_sha256", "source_closure_count", "source_closure_sha256"}, "LAB_RECORD")
    exact({k: lab[k] for k in ("provider", "platform", "sql_version", "patch", "sql_build", "qualification_version", "strict_client_results")},
          {"provider": "hyperv", "platform": "windows", "sql_version": "2025", "patch": "base",
           "sql_build": "17.0.1000.7", "qualification_version": "SqlServerLab.TlsQualification/0.3",
           "strict_client_results": 8}, "LAB_PROFILE")
    require(type(lab["source_closure_count"]) is int and lab["source_closure_count"] > 100 and
            re.fullmatch(r"[0-9a-f]{64}", lab["source_closure_sha256"]), "LAB_CLOSURE")
    require(set(lab["source_sha256"]) == {"Private/AuthenticatedTlsWindowsLab.ps1", "Private/AuthenticatedTlsLab.ps1",
            "Private/AuthenticatedTlsQualification.ps1", "Private/AuthenticatedTlsLiveQualification.ps1",
            "Public/New-SqlServerLab.ps1", "Public/Test-SqlServerLabTlsQualification.ps1"} and
            all(re.fullmatch(r"[0-9a-f]{64}", v) for v in lab["source_sha256"].values()), "LAB_METHODS")
    expected = [{"sql_version": "2025", "patch": "base", "sql_build": "17.0.1000.7",
                 "compatibility_level": 170, "deployment_mode": mode, "assertions": 206,
                 "result": "PASS", "input_pins_unchanged": True} for mode in ("local", "central")]
    require(type(report["cases"]) is list and len(report["cases"]) == 2, "CONTEXT_COUNT")
    for actual, wanted in zip(report["cases"], expected):
        exact(actual, wanted, "CURRENT_CASE")
    require(type(report["assertions"]) is int and report["assertions"] == 412, "ASSERTIONS")
    guarded = report["guarded_connections"]
    exact(guarded, {"target": 3, "audit": 1}, "PER_OPEN_GUARD")
    pins = report["source_sha256"]
    require(set(pins) == METHODS and all(re.fullmatch(r"[0-9a-f]{64}", v) for v in pins.values()), "METHOD_CLOSURE")
    require(set(report["functional_evidence"]) == {"path", "sha256"} and
            report["functional_evidence"]["path"] == FUNCTIONAL and
            re.fullmatch(r"[0-9a-f]{64}", report["functional_evidence"]["sha256"]), "FUNCTIONAL_BINDING")
    if check_files:
        for path, digest in pins.items():
            require(hashlib.sha256(read(root, path)).hexdigest() == digest, "METHOD_PIN")
        require(hashlib.sha256(read(root, FUNCTIONAL)).hexdigest() == report["functional_evidence"]["sha256"], "FUNCTIONAL_PIN")
        spec = importlib.util.spec_from_file_location("ssis_tls_functional", root / "Scripts/Release/validate_ssis_current_functional.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        module.validate(root)
    return report


if __name__ == "__main__":
    validate()
    print("SSIS_CURRENT_AUTHENTICATED_TLS_QUALIFICATION_PASS; separate Windows TLS scope; no SQL")
