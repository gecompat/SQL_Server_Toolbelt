"""Bind the complete current SSIS install-package matrix to its exact sources."""
from __future__ import annotations

import io
import json
from pathlib import Path
import zipfile

from new_ssis_current_package import ROOT, MODULE, NAME, require, sha
from new_ssis_standalone_tsql import read_regular_bounded, MAX_PACKAGE_BYTES
import validate_ssis_current_package as package_guard


ORIGINAL_REPORT = MODULE + "Tests/Qualification/Current.InstallPackage.20261029.json"
ORIGINAL_REPORT_SHA256 = "05D88E2ED0C168D025BA5139C8E965613C049E1B2F88041A016EBF0AB30656D2"
MATRIX_REPORT = MODULE + "Tests/Qualification/Current.InstallPackage.Matrix.20261029.json"
PACKAGE_ARCHIVE = ROOT / MODULE / "InstallPackages" / (NAME + ".zip")
CURRENT_CASES = MODULE + "Tests/Runtime/Invoke-CurrentCases.ps1"
PROTECTED_LAB_DRIVER = MODULE + "Tests/Runtime/Invoke-LabContract.ps1"
REQUIRED_CASE_FIELDS = ("platform", "sql_version", "compatibility_level", "deployment_mode")


def _matrix():
    return {
        (version, level, mode)
        for version, levels in (("2019", (150,)), ("2022", (150, 160)), ("2025", (150, 160, 170)))
        for level in levels
        for mode in ("local", "central")
    }


def _case_key(case):
    require(isinstance(case, dict), "case object")
    require(all(key in case for key in REQUIRED_CASE_FIELDS), "case identity fields")
    require(case["platform"] == "windows" and case["sql_version"] in ("2019", "2022", "2025") and
            type(case["compatibility_level"]) is int and case["deployment_mode"] in ("local", "central"),
            "case identity values")
    return case["sql_version"], case["compatibility_level"], case["deployment_mode"]


def _successful_cases(cases, label):
    require(isinstance(cases, list), label + " list")
    keys = [_case_key(case) for case in cases]
    require(len(keys) == len(set(keys)), label + " duplicates")
    require(all(case.get("result") == "PASS" and case.get("final_independent_audit") == "PASS"
                for case in cases), label + " audits")
    return dict(zip(keys, cases))


def _package_payload(package_bytes):
    with zipfile.ZipFile(io.BytesIO(package_bytes)) as archive:
        payload = {}
        for entry in archive.infolist():
            if entry.is_dir():
                continue
            prefix = NAME + "/"
            require(entry.filename.startswith(prefix), "qualified package entry boundary")
            relative = entry.filename[len(prefix):]
            require(relative and relative not in payload, "qualified package entry uniqueness")
            payload[relative] = archive.read(entry)
    return payload


def _validate_artifact_bindings(record, payload):
    binding = record.get("artifact_bindings")
    expected_keys = {"assembly_sha256", "deploy_sql_sha256", "uninstall_sql_sha256",
                     "trust_manifest_sha256", "cases_sha256", "protected_lab_driver_sha256"}
    require(isinstance(binding, dict) and set(binding) == expected_keys,
            "artifact binding fields")
    manifest = json.loads(payload["PACKAGE-MANIFEST.json"])
    native_path = manifest["nativeBinaryQualification"]
    native = json.loads(payload[native_path])
    artifacts = {
        "assembly_sha256": MODULE + "Artifacts/Toolbelt.Tsql.SsisDebug.dll",
        "deploy_sql_sha256": MODULE + "Artifacts/Deploy.WithAssembly.sql",
        "uninstall_sql_sha256": MODULE + "Artifacts/Uninstall.Expanded.sql",
        "trust_manifest_sha256": MODULE + "Artifacts/Toolbelt.Tsql.SsisDebug.trust-manifest.json",
        "cases_sha256": CURRENT_CASES,
        "protected_lab_driver_sha256": PROTECTED_LAB_DRIVER,
    }
    for key, path in artifacts.items():
        require(path in payload and binding[key].lower() == sha(payload[path]).lower(),
                "artifact bytes " + key)
    native_source = native["native_source_sha256"]
    require(native_source.get(CURRENT_CASES) == sha(payload[CURRENT_CASES]).lower() and
            native_source.get(PROTECTED_LAB_DRIVER) == sha(payload[PROTECTED_LAB_DRIVER]).lower(),
            "native-qualified case and driver sources")
    require(binding["assembly_sha256"].lower() == native["qualified_assembly_sha256"].lower() and
            binding["deploy_sql_sha256"].lower() == native["qualified_deploy_sql_sha256"].lower() and
            binding["uninstall_sql_sha256"].lower() == native["qualified_uninstall_sql_sha256"].lower() and
            binding["trust_manifest_sha256"].lower() == native["qualified_trust_manifest_sha256"].lower(),
            "native-qualified artifact provenance")


def validate_record(record, original, actual_package_sha256, package_payload=None):
    """Validate the record composition without invoking any SQL-facing code."""
    require(isinstance(record, dict) and record.get("schema_version") == "1.0" and
            record.get("date") == "2026-10-29" and
            record.get("kind") == "ssis_current_install_package_matrix_qualification" and
            record.get("profile") == "ssis-debug-current" and record.get("result") == "PASS" and
            record.get("publication_authorized") is False, "matrix record identity")
    source = record.get("original_package_qualification")
    require(isinstance(source, dict) and source.get("path") == ORIGINAL_REPORT and
            source.get("sha256", "").lower() == ORIGINAL_REPORT_SHA256.lower() and
            source.get("package_sha256", "").lower() == original.get("package_sha256", "").lower(),
            "original package qualification pin")
    original_package_sha = original.get("package_sha256", "").lower()
    package_sha = record.get("package_sha256", "").lower()
    require(package_sha == actual_package_sha256.lower() == original_package_sha,
            "qualified current package SHA-256")
    original_cases = _successful_cases(original.get("cases"), "original cases")
    baseline = {("2019", 150, "local"), ("2025", 170, "central")}
    require(set(original_cases) == baseline, "original two-case source scope")

    additional_cases = _successful_cases(record.get("additional_cases"), "additional cases")
    expected_additional = _matrix() - baseline
    require(set(additional_cases) == expected_additional and len(additional_cases) == 10,
            "additional ten-case matrix")
    cases = _successful_cases(record.get("cases"), "composed cases")
    require(set(cases) == _matrix() and len(cases) == 12, "complete twelve-case matrix")
    for key, source in original_cases.items():
        composed = cases[key]
        require(composed == source,
                "original case composition")
    for key, addition in additional_cases.items():
        composed = cases[key]
        require(composed == addition,
                "additional case composition")
        require(addition.get("assertions") == 206 and
                addition.get("fresh_repeat_uninstall_and_absent_repeat") is True and
                addition.get("exact_extracted_sql_via_direct_sqlclient") is True,
                "additional case package execution evidence")
    audit = record.get("final_audit")
    require(isinstance(audit, dict) and audit.get("case_audits") == 10 and
            audit.get("owned_database_names_absent") == 20 and audit.get("trust_states_restored") == 30 and
            audit.get("configuration_baselines_restored") is True and audit.get("input_pins_unchanged") is True,
            "matrix final audit")
    if package_payload is not None:
        _validate_artifact_bindings(record, package_payload)
    return True


def validate():
    record_bytes = read_regular_bounded(ROOT / MATRIX_REPORT, 1024 * 1024)
    record = json.loads(record_bytes.decode("utf-8"))
    original_bytes = read_regular_bounded(ROOT / ORIGINAL_REPORT, 1024 * 1024)
    require(sha(original_bytes) == ORIGINAL_REPORT_SHA256, "original package qualification source bytes")
    original = json.loads(original_bytes.decode("utf-8"))
    package_bytes = read_regular_bounded(PACKAGE_ARCHIVE, MAX_PACKAGE_BYTES)
    package_sha256 = sha(package_bytes)
    original_package_sha256 = original.get("package_sha256")
    record_package_sha256 = record.get("package_sha256")
    require(isinstance(original_package_sha256, str) and isinstance(record_package_sha256, str) and
            package_sha256.lower() == original_package_sha256.lower() == record_package_sha256.lower(),
            "qualified current package SHA-256")
    # Keep the existing complete package/manifest/dependency validator authoritative.
    package_guard.validate(PACKAGE_ARCHIVE)
    validate_record(record, original, package_sha256, _package_payload(package_bytes))
    print("SSIS_CURRENT_MATRIX_VALIDATION_PASS; exact current package and 12 Windows contexts; no SQL")
    return record


if __name__ == "__main__":
    validate()
