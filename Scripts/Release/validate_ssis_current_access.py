"""Aggregierte Anmelde-Evidence; keine SQL-Verbindung und keine privaten Journale."""
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
MODULE = "Modules/toolbelt.tsql.ssis-debug/"
REPORT = MODULE + "Tests/Qualification/Current.Access.Windows.CL.20261031.json"
FUNCTIONAL = MODULE + "Tests/Qualification/Current.Functional.20261031.json"
TLS_REPORT = MODULE + "Tests/Qualification/Current.AuthenticatedTls.Windows.20261031.json"
METHODS = {MODULE + "Tests/Runtime/" + name for name in (
    "Invoke-CurrentAccessLab.ps1", "Invoke-CurrentAccessCases.ps1", "Invoke-CurrentWindowsAccessCases.ps1",
    "CurrentWindowsAccess.sql", "Invoke-CurrentAccessAudit.ps1", "Invoke-CurrentGuiAccessCase.ps1")}
CONTEXTS = {(v, level, mode) for v, levels in (("2019", [150]), ("2022", [150, 160]), ("2025", [150, 160, 170]))
            for level in levels for mode in ("local", "central")}


def require(value, code):
    if not value:
        raise ValueError("SSIS_CURRENT_ACCESS_" + code)


def unique(pairs):
    result = {}
    for key, value in pairs:
        require(key not in result, "DUPLICATE_JSON_KEY")
        result[key] = value
    return result


def read(root, relative):
    require(isinstance(relative, str) and "\\" not in relative and
            not Path(relative).is_absolute() and all(p not in ("", ".", "..") for p in relative.split("/")), "PATH")
    path = root / relative
    require(path.resolve().is_relative_to(root.resolve()) and path.is_file() and not path.is_symlink(), "FILE")
    return path.read_bytes()


def validate(root=ROOT, report=None, *, check_files=True):
    root = Path(root)
    if report is None:
        report = json.loads(read(root, REPORT), object_pairs_hook=unique)
    require(report.get("schema_version") == "1.0" and report.get("kind") == "ssis_current_access_qualification" and
            report.get("result") == "PASS" and report.get("publication_authorized") is False, "KIND_AUTHORITY")
    actual = set()
    for case in report.get("cases", []):
        key = (case.get("sql_version"), case.get("compatibility_level"), case.get("deployment_mode"))
        require(key not in actual and key in CONTEXTS and type(case.get("compatibility_level")) is int, "CONTEXT")
        actual.add(key)
        require(case.get("patch") == {"2019": "cu32", "2022": "cu26", "2025": "cu8"}[key[0]], "PATCH")
        require(case.get("database_collation") == {"2019": "Latin1_General_100_BIN2", "2022": "Latin1_General_100_CS_AS", "2025": "Latin1_General_100_CI_AS_SC_UTF8"}[key[0]], "COLLATION")
        require(case.get("result") == "PASS" and case.get("cleanup_audit") == "PASS" and case.get("execution_input_pins_unchanged") is True, "CASE_RESULT")
        for name, count in (("access_assertions", 118), ("windows_assertions", 15)):
            require(type(case.get(name)) is int and case[name] == count, "ASSERTIONS")
    require(actual == CONTEXTS and type(report.get("assertions")) is int and report["assertions"] == 1596, "MATRIX_TOTAL")
    identity = report.get("lowpriv_identity", {})
    require(identity == {"authentication": "actual SQL network login", "cross_database_users": "exact login SID in both databases",
                         "server_roles_granted": False, "server_permissions_granted": False, "trustworthy_enabled": False,
                         "database_chaining_enabled": False, "source_select": "only three synthetic fixture tables"} and
            all(identity[k] is False for k in ("server_roles_granted", "server_permissions_granted", "trustworthy_enabled", "database_chaining_enabled")), "LOWPRIV_SCOPE")
    windows = report.get("windows_identity", {})
    require(windows.get("authentication") == "actual Windows login through bound Lab guest" and windows.get("authenticated_tls") is False and
            windows.get("generated_script_origin") == "current API under the actual lowpriv SQL identity" and
            windows.get("scope") == "current analysis and both unchanged DebugScripts", "WINDOWS_SCOPE")
    gui = report.get("gui", {})
    require(gui == {"result": "PASS_SQL_AND_VISUAL", "sql_version": "2025", "patch": "cu8", "compatibility_level": 170,
                    "deployment_mode": "central", "authentication": "SQL", "application": "SSMS", "current_parameters": 38,
                    "debug_script_artifacts": 2, "synthetic_target_rows": 2, "unicode_witness": True, "messages_success": True,
                    "cleanup_audit": "PASS", "coordinator_result": "FAILED_CLEANED", "coordinator_failure": "SSIS_GUI_CLIENT_CONNECTIONS_REMAIN",
                    "own_tab_closed": True, "force_or_kill": False}, "GUI_SCOPE_AND_ORIGINAL_FAILURE")
    require(all(gui[k] is True for k in ("unicode_witness", "messages_success", "own_tab_closed")) and gui["force_or_kill"] is False, "GUI_TYPES")
    attempts = report.get("attempt_history", [])
    require(len(attempts) == 22 and sum(a.get("result") == "PASS" for a in attempts) == 13 and
            sum(a.get("result") == "FAILED" for a in attempts) == 9 and all(a.get("cleanup_audit") == "PASS" for a in attempts), "HISTORY")
    require(sum(a.get("original_audit") == "FAILED" and a.get("recovery_audit") == "PASS" for a in attempts) == 2 and
            attempts[20].get("result") == "FAILED" and attempts[20].get("original_audit") == "PASS", "RECOVERY_HISTORY")
    require(report.get("authenticated_tls") == "not executed; separate current TLS qualification required", "TLS_SEPARATION")
    require(set(report.get("source_sha256", {})) == METHODS and all(re.fullmatch(r"[0-9a-f]{64}", h) for h in report["source_sha256"].values()), "METHOD_CLOSURE")
    if check_files:
        for path, expected in report["source_sha256"].items():
            require(hashlib.sha256(read(root, path)).hexdigest() == expected, "METHOD_PIN")
        binding = report.get("functional_evidence", {})
        require(binding.get("path") == FUNCTIONAL and hashlib.sha256(read(root, FUNCTIONAL)).hexdigest() == binding.get("sha256"), "FUNCTIONAL_BINDING")
        spec = importlib.util.spec_from_file_location("ssis_functional_for_access", root / "Scripts/Release/validate_ssis_current_functional.py")
        functional = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(functional)
        functional.validate(root)
    return report


if __name__ == "__main__":
    validate()
    print("SSIS_CURRENT_ACCESS_QUALIFICATION_PASS; actual lowpriv/Windows and separately observed SSMS; no SQL")
