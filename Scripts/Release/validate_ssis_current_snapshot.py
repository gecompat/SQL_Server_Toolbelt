"""Validate the bounded current SSIS materialized-snapshot qualification."""
from __future__ import annotations

import copy
import json
from pathlib import Path, PurePosixPath

from new_ssis_current_package import ROOT, MODULE, NAME, require, sha
from new_ssis_standalone_tsql import read_regular_bounded, MAX_PACKAGE_BYTES
import new_ssis_current_standalone_tsql as current_installer
import validate_ssis_current_package as package_guard


REPORT = MODULE + "Tests/Qualification/Current.SnapshotCoherence.20261030.json"
PACKAGE_REPORT = MODULE + "Tests/Qualification/Current.InstallPackage.20261029.json"
PACKAGE = ROOT / MODULE / "InstallPackages" / (NAME + ".zip")
PACKAGE_REPORT_SHA256 = "05D88E2ED0C168D025BA5139C8E965613C049E1B2F88041A016EBF0AB30656D2"
PACKAGE_SHA256 = "6E83F4B534339E106B42C8911178BD09CB82001167A356D5A5D63BF69A15F4D7"
NATIVE_REPORT = MODULE + "Tests/Qualification/Current.Windows.CL.20261029.json"
NATIVE_REPORT_SHA256 = "0582DD492D635E45DC2478A173A2FEDB926D12827B6ED4078E5C1EDF16AA3B5D"
NATIVE_COMMIT = "e776ded0151b93ad7f096d90ea96a96e42907ed3"
FIXTURE = MODULE + "Tests/Fixtures/components-v2-rowcount.dtsx"
FIXTURE_EXECUTION_SHA256, FIXTURE_INTEGRATED_SHA256 = current_installer.XML_LINE_ENDINGS[FIXTURE]
FIXTURE_CHECKOUT_BINDING = {
    "kind": "ssis_current_xml_line_endings_binding",
    "native_execution_inputs_preserved": True,
    "package_bytes_unchanged": True,
    "qualification_semantics_unchanged": True,
    "changes": [{
        "path": FIXTURE,
        "execution_sha256": FIXTURE_EXECUTION_SHA256,
        "integrated_sha256": FIXTURE_INTEGRATED_SHA256,
        "transform": "lf-to-crlf-exact-reconstruction",
    }],
}

EXPECTED_SOURCE_PATHS = frozenset({
    "Modules/toolbelt.core.result-table/Deployment/Deploy.sql",
    "Modules/toolbelt.core.result-table/Deployment/Uninstall.sql",
    "Modules/toolbelt.core.result-table/Source/SchemaTrustPreflight.sql",
    "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql",
    "Modules/toolbelt.tsql.script-parser/Clr/PreparseGuardCore.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/AssemblyInfo.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/Bindings.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/CacheSql.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/Core.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/DependencyPins.Generated.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/Engine.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/Expressions.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/HelpContract.Generated.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/PackageModel.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/Projection.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/ResourceOptions.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/SqlAdapter.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/SqlParameters.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/SqlSafety.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/SqlTypeRules.cs",
    "Modules/toolbelt.tsql.ssis-debug/Clr/Toolbelt.Tsql.SsisDebug.csproj",
    "Modules/toolbelt.tsql.ssis-debug/Clr/Translator.cs",
    "Modules/toolbelt.tsql.ssis-debug/Contracts/Api.json",
    "Modules/toolbelt.tsql.ssis-debug/Contracts/ComponentsV2.json",
    "Modules/toolbelt.tsql.ssis-debug/Contracts/ComponentsV2.schema.json",
    "Modules/toolbelt.tsql.ssis-debug/Contracts/DependencyPins.json",
    "Modules/toolbelt.tsql.ssis-debug/Contracts/ReleaseObjects.1.0.0.json",
    "Modules/toolbelt.tsql.ssis-debug/Deployment/Add-TrustedAssembly.sql",
    "Modules/toolbelt.tsql.ssis-debug/Deployment/DependencyPreflight.sql",
    "Modules/toolbelt.tsql.ssis-debug/Deployment/Deploy.sql",
    "Modules/toolbelt.tsql.ssis-debug/Deployment/OwnershipPreflight.sql",
    "Modules/toolbelt.tsql.ssis-debug/Deployment/Uninstall.sql",
    "Modules/toolbelt.tsql.ssis-debug/Exchange/Core/ComponentProfiles.cs",
    "Modules/toolbelt.tsql.ssis-debug/Exchange/Core/ExecutionScopes.cs",
    "Modules/toolbelt.tsql.ssis-debug/Exchange/Core/PackageDocument.cs",
    "Modules/toolbelt.tsql.ssis-debug/Exchange/Core/PipelineIdentities.cs",
    "Modules/toolbelt.tsql.ssis-debug/Exchange/Core/ResourceLimits.cs",
    "Modules/toolbelt.tsql.ssis-debug/Scripts/New-ClrReleaseArtifacts.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Scripts/New-ContractSources.py",
    "Modules/toolbelt.tsql.ssis-debug/Scripts/New-DependencyPins.py",
    "Modules/toolbelt.tsql.ssis-debug/Source/USP_ExplainSsisDataFlow.sql",
    "Modules/toolbelt.tsql.ssis-debug/Source/USP_ExplainSsisDataFlowInternal.sql",
    FIXTURE,
    MODULE + "Tests/Fixtures/synthetic-8.dtsx",
    NATIVE_REPORT,
    MODULE + "Tests/Runtime/CurrentSnapshotHelpers.ps1",
    MODULE + "Tests/Runtime/Invoke-ApiCases.ps1",
    MODULE + "Tests/Runtime/Invoke-ComponentsV2Audit.ps1",
    MODULE + "Tests/Runtime/Invoke-CurrentSnapshotCases.ps1",
    MODULE + "Tests/Runtime/Invoke-CurrentSnapshotLab.ps1",
    MODULE + "Tests/Runtime/Invoke-LabContract.ps1",
    "Tests/CI/LabQualifiedContract.ps1",
    "Tests/CI/run-lab-local.ps1",
})


def _require_exact(actual, expected, label):
    """Compare JSON values without Python's bool/int/float equality coercions."""
    require(type(actual) is type(expected), label + " type")
    if isinstance(expected, dict):
        require(set(actual) == set(expected), label + " keys")
        for key, value in expected.items():
            _require_exact(actual[key], value, label + "." + key)
    elif isinstance(expected, list):
        require(len(actual) == len(expected), label + " length")
        for index, value in enumerate(expected):
            _require_exact(actual[index], value, label + "[" + str(index) + "]")
    else:
        require(actual == expected, label + " value")


def _load_json(data, label):
    def no_duplicates(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, label + " duplicate key")
            result[key] = value
        return result
    return json.loads(data.decode("utf-8"), object_pairs_hook=no_duplicates)


def _expected_record(package_sha, package_report_sha, native_sha, source_bindings):
    cases = []
    for mode in ("local", "central"):
        cases.append({
            "platform": "windows",
            "sql_version": "2025",
            "patch": "CU8",
            "compatibility_level": 170,
            "deployment_mode": mode,
            "database_collation": "Latin1_General_100_BIN2",
            "api_sql_dialect_default": 150,
            "result": "PASS",
            "assertions": 272,
            "independent_cleanup_audit": "PASS",
            "fresh_debug_sessions": 2,
            "returned_debugscript_validated_and_ordered": True,
            "all_plan_units_prepared_before_reads": True,
            "source_insert_after_materialization_before_first_read": True,
            "source_insert_from_separate_controller_connection": True,
            "target_columns": [
                {"name": "KeyA", "sql_type": "int32"},
                {"name": "KeyB", "sql_type": "int32"},
                {"name": "Adjusted", "sql_type": "int32"},
                {"name": "Score", "sql_type": "int32"},
            ],
            "first_materialized_snapshot": {
                "row_count_bigint": 2,
                "fits_target_variable": True,
                "row_order": "not asserted; values are listed in canonical fixture order",
                "rows": [
                    {"KeyA": 1, "KeyB": 10, "Adjusted": 101, "Score": 7},
                    {"KeyA": 2, "KeyB": 10, "Adjusted": 201, "Score": 2},
                ],
                "inserted_row_absent": True,
            },
            "changed_source_fresh_snapshot": {
                "row_count_bigint": 3,
                "fits_target_variable": True,
                "row_order": "not asserted; values are listed in canonical fixture order",
                "rows": [
                    {"KeyA": 1, "KeyB": 10, "Adjusted": 101, "Score": 7},
                    {"KeyA": 2, "KeyB": 10, "Adjusted": 201, "Score": 2},
                    {"KeyA": 2, "KeyB": 10, "Adjusted": 202, "Score": 2},
                ],
                "original_rows_preserved": True,
            },
        })
    return {
        "schema_version": "1.0",
        "date": "2026-10-30",
        "kind": "ssis_current_snapshot_coherence_qualification",
        "profile": "ssis-debug-current",
        "result": "PASS",
        "publication_authorized": False,
        "source_commit": NATIVE_COMMIT,
        "package_qualification": {
            "path": PACKAGE_REPORT,
            "sha256": package_report_sha,
            "package_sha256": package_sha,
        },
        "native_binary_qualification": {
            "path": NATIVE_REPORT,
            "sha256": native_sha,
        },
        "integration_binding": copy.deepcopy(FIXTURE_CHECKOUT_BINDING),
        "artifact_bindings": {
            "assembly_sha256": "F5838193795521943E511EBDE9D22BA9AA1431EA94D7F368AC6364C97DD30760",
            "deploy_sql_sha256": "E660514A1F5BC761B66306AA1D81BF2B5BF6FCC6EBFC723C7994309AE99AD46A",
            "uninstall_sql_sha256": "7C0205E5046253493B2FD130AF8734CFB5B97F25B88CD9B504B02FA09CFC124F",
            "trust_manifest_sha256": "D1EB3D6D0088316F8B1417E64F5A99AD31A2E2FA7EF0E8570FD188428202AE41",
        },
        "scope": {
            "platform": "windows",
            "sql_version": "2025",
            "patch": "CU8",
            "compatibility_level": 170,
            "deployment_modes": ["local", "central"],
            "database_collation": "Latin1_General_100_BIN2",
            "api_sql_dialect_default": 150,
            "fixture": FIXTURE,
            "functional_claim": "A source insert from a separate controller connection after materializing one plan does not alter that plan's shared TargetSql/RowCountSql snapshot; a new DebugScript execution sees the changed source.",
            "not_qualified": [
                "Other Windows targets, SQL Server versions, compatibility levels, collations, or deployment modes",
                "Source changes during plan-unit materialization, arbitrary concurrent source activity, or an atomic snapshot across unrelated source objects",
                "Real SSIS runtime execution",
                "Authenticated TLS",
                "Windows authentication or SSMS GUI",
                "Other SSIS components, API operations, or package shapes",
                "Publication",
            ],
        },
        "cases": cases,
        "execution": {
            "successful_target_invocations": 2,
            "successful_independent_audits": 2,
            "total_assertions": 544,
            "source_bindings": source_bindings,
            "attempt_history": {
                "target_invocations": 4,
                "successful_contexts": 2,
                "failed_target_invocations": 2,
                "directly_failed_cleaned_attempts": 1,
                "recovery_required_target_attempts": 1,
                "own_safety_recovery_completed": 1,
                "independent_audits": 5,
                "passed_independent_audits": 4,
                "retained_failed_audits": 1,
                "safety_processes": 5,
                "read_only_probe_errors": 2,
                "read_only_probe_passes": 1,
                "partial_cleanup_or_trust_probe_errors": 1,
                "trust_continuation_passes": 1,
                "total_process_attempts": 14,
                "final_owned_resource_recovery": "PASS",
                "failed_history_preserved": True,
            },
        },
        "final_audit": {
            "successful_context_audits": 2,
            "input_pins_unchanged": True,
            "owned_databases_absent": True,
            "trust_and_configuration_restored": True,
        },
    }


def validate_record(record, *, actual_source_bindings=None, package_report=None,
                    native_report=None, package_payload=None):
    require(isinstance(record, dict), "snapshot record object")
    require(set(record.get("execution", {}).get("source_bindings", {})) == EXPECTED_SOURCE_PATHS,
            "public source pin closure")
    source_bindings = record["execution"]["source_bindings"]
    require(all(type(path) is str and type(digest) is str and
                digest == digest.upper() and len(digest) == 64 and
                all(c in "0123456789ABCDEF" for c in digest)
                for path, digest in source_bindings.items()), "public source pin shape")
    if actual_source_bindings is not None:
        _require_exact(source_bindings, actual_source_bindings, "source bindings")
    require(type(record.get("execution", {}).get("total_assertions")) is int,
            "total assertions type")
    require(type(record.get("execution", {}).get("attempt_history", {}).get("target_invocations")) is int,
            "attempt count type")
    if package_report is None:
        package_report_bytes = read_regular_bounded(ROOT / PACKAGE_REPORT, 1024 * 1024)
        package_report = _load_json(package_report_bytes, "package report")
        package_report_sha = sha(package_report_bytes)
    else:
        package_report_sha = sha(read_regular_bounded(ROOT / PACKAGE_REPORT, 1024 * 1024))
    require(package_report_sha == PACKAGE_REPORT_SHA256, "frozen package qualification report")
    if native_report is None:
        native_report_bytes = read_regular_bounded(ROOT / NATIVE_REPORT, 2 * 1024 * 1024)
        native_report = _load_json(native_report_bytes, "native report")
        native_report_sha = sha(native_report_bytes)
    else:
        native_report_sha = sha(read_regular_bounded(ROOT / NATIVE_REPORT, 2 * 1024 * 1024))
    require(native_report_sha == NATIVE_REPORT_SHA256, "frozen native qualification report")
    package_sha = sha(read_regular_bounded(PACKAGE, MAX_PACKAGE_BYTES))
    expected = _expected_record(package_sha, package_report_sha, native_report_sha, source_bindings)
    _require_exact(record, expected, "snapshot qualification")
    require(package_report.get("kind") == "ssis_current_install_package_qualification" and
            package_report.get("profile") == "ssis-debug-current" and
            package_report.get("result") == "PASS" and
            package_report.get("publication_authorized") is False and
            type(package_report.get("package_sha256")) is str and
            package_report.get("package_sha256", "").upper() == PACKAGE_SHA256 and
            package_sha == PACKAGE_SHA256, "qualified package source")
    require(native_report.get("kind") == "ssis_current_native_qualification" and
            native_report.get("profile") == "ssis-debug-current" and
            native_report.get("result") == "PASS" and
            native_report.get("publication_authorized") is False and
            native_report.get("qualified_assembly_sha256", "").upper() == expected["artifact_bindings"]["assembly_sha256"] and
            native_report.get("qualified_deploy_sql_sha256", "").upper() == expected["artifact_bindings"]["deploy_sql_sha256"] and
            native_report.get("qualified_uninstall_sql_sha256", "").upper() == expected["artifact_bindings"]["uninstall_sql_sha256"] and
            native_report.get("qualified_trust_manifest_sha256", "").upper() == expected["artifact_bindings"]["trust_manifest_sha256"],
            "qualified native artifacts")
    require(actual_source_bindings is not None, "current source binding bytes required")
    if package_payload is not None:
        package_guard.validate(PACKAGE)
    return True


def _current_source_bindings():
    result = {}
    for relative in sorted(EXPECTED_SOURCE_PATHS):
        path = PurePosixPath(relative)
        require(not path.is_absolute() and ".." not in path.parts and
                "\\" not in relative and not path.parts[0].startswith("."),
                "public source path boundary")
        data = read_regular_bounded(ROOT.joinpath(*path.parts), 64 * 1024 * 1024)
        result[relative] = _source_checkout_sha(relative, data)
    return result


def _source_checkout_sha(relative, data):
    """Native Pins erhalten; nur die bestehende exakte XML-Checkout-Brücke zulassen."""
    if relative != FIXTURE:
        return sha(data)
    actual = sha(data)
    if actual == FIXTURE_EXECUTION_SHA256:
        return actual
    require(actual == FIXTURE_INTEGRATED_SHA256 and b"\r" not in data and
            sha(data.replace(b"\n", b"\r\n")) == FIXTURE_EXECUTION_SHA256,
            "exact row-count fixture checkout transformation")
    return FIXTURE_EXECUTION_SHA256


def validate():
    raw = read_regular_bounded(ROOT / REPORT, 1024 * 1024)
    record = _load_json(raw, "snapshot report")
    validate_record(record, actual_source_bindings=_current_source_bindings())
    package_guard.validate(PACKAGE)
    print("SSIS_CURRENT_SNAPSHOT_VALIDATION_PASS; exact current package and two snapshot contexts; no SQL")
    return record


if __name__ == "__main__":
    validate()
