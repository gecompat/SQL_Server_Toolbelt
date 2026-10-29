"""Render the V2 installer using the existing guarded T-SQL renderer."""
from __future__ import annotations

import argparse
import json
from pathlib import Path, PurePosixPath
import re

import new_ssis_standalone_tsql as legacy
from new_ssis_components_v2_package import MODULE, NAME, ROOT, require, sha
from validate_ssis_components_v2_package import validate


RUNTIME_QUALIFICATION = Path("Releases/1.0.0/ssis-components-v2-standalone-installer-runtime-qualification.json")
RUNTIME_PIN_PATHS = (
    "Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Contracts/Api.json",
    "Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-ComponentsV2-1.0.0-Install-Windows.zip",
    "Modules/toolbelt.tsql.ssis-debug/InstallPackages/SSIS-Debug-ComponentsV2-1.0.0-Install-Windows.zip.sha256",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Fixtures/synthetic-8.dtsx",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/ComponentsV2.InstallPackage.20261028.json",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-ApiCases.ps1",
    "Modules/toolbelt.tsql.ssis-debug/Tests/Runtime/Invoke-LabContract.ps1",
    "Releases/1.0.0/SSIS-COMPONENTS-V2-INSTALL-TSQL.sql",
    "Releases/1.0.0/ssis-components-v2-standalone-installer.json",
    "Tests/CI/LabQualifiedContract.ps1",
    "Tests/CI/run-csv-memory-lab.ps1",
    "Tests/CI/run-lab-local.ps1",
    "Tests/Release/Invoke-ComponentsV2StandaloneTsqlInstallerLab.ps1",
    "Tests/Release/Invoke-StablePackageLab.ps1",
    "Tests/Release/Prepare-ComponentsV2StandaloneTsqlInstallerRunset.ps1",
)


def _bound_file(root: Path, relative: str, maximum: int) -> bytes:
    path = PurePosixPath(relative)
    require(not path.is_absolute() and "\\" not in relative and
            all(part not in ("", ".", "..") for part in path.parts),
            "runtime input pin path")
    return legacy.read_regular_bounded(root.joinpath(*path.parts), maximum)


def validate_install_runtime_qualification(record_bytes, root=ROOT):
    """Validate the executed installer record and its narrowly declared LF bridge."""
    try:
        record = json.loads(record_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("SSIS_V2_RUNTIME_QUALIFICATION_INVALID: JSON") from error
    require(isinstance(record, dict) and record.get("schema_version") == "1.0" and
            record.get("kind") == "ssis_components_v2_standalone_tsql_runtime_qualification" and
            record.get("profile") == "ssis-debug-components-v2" and
            record.get("result") == "PASS" and record.get("publication_authorized") is False,
            "runtime qualification schema/status")

    installer_path = "Releases/1.0.0/SSIS-COMPONENTS-V2-INSTALL-TSQL.sql"
    provenance_path = "Releases/1.0.0/ssis-components-v2-standalone-installer.json"
    qualification_path = MODULE + "Tests/Qualification/ComponentsV2.InstallPackage.20261028.json"
    package_path = MODULE + "InstallPackages/" + NAME + ".zip"
    installer = _bound_file(root, installer_path, 32 * 1024 * 1024)
    provenance_bytes = _bound_file(root, provenance_path, 1024 * 1024)
    qualification_bytes = _bound_file(root, qualification_path, 1024 * 1024)
    package_bytes = _bound_file(root, package_path, legacy.MAX_PACKAGE_BYTES)
    installer_sha = legacy.sha(installer)
    provenance_sha = legacy.sha(provenance_bytes)
    qualification_sha = legacy.sha(qualification_bytes)
    package_sha = legacy.sha(package_bytes)

    installer_record = record.get("installer")
    provenance_record = record.get("provenance")
    qualified_package = record.get("qualified_package")
    require(installer_record == {"sha256": installer_sha, "path": installer_path},
            "exact runtime installer binding")
    require(isinstance(provenance_record, dict) and provenance_record.get("path") == provenance_path and
            re.fullmatch(r"[0-9A-F]{64}", str(provenance_record.get("sha256", ""))) is not None,
            "runtime provenance binding")
    require(isinstance(qualified_package, dict) and
            qualified_package.get("path") == package_path and qualified_package.get("sha256") == package_sha and
            qualified_package.get("qualification") == qualification_path and
            qualified_package.get("qualification_result") == "PASS",
            "runtime qualified package binding")

    bridge = record.get("integration_binding")
    require(isinstance(bridge, dict) and bridge.get("kind") == "ssis_components_v2_lf_metadata_binding" and
            bridge.get("native_execution_inputs_preserved") is True and
            bridge.get("installer_bytes_unchanged") is True and
            bridge.get("qualification_semantics_unchanged") is True,
            "runtime LF integration binding")
    changes = bridge.get("changes")
    require(isinstance(changes, list) and len(changes) == 2,
            "runtime LF integration change count")
    expected_changes = {
        qualification_path: {
            "execution_sha256": "DAE7644BAAD8C3573106D0F298E2DAAC1BF198BDFE2543D8E588F9CA74C64D1A",
            "integrated_sha256": "D9183E85753D9B011B54DB971B52FCE2D13EEC6B20F57A70D66ABB0AED50CA29",
            "transform": "internal-crlf-final-lf-to-lf",
        },
        provenance_path: {
            "execution_sha256": "9B553854DA778E49402A2F4DDFD331D209C93F67B1FF67140F87FCE3E42452FC",
            "integrated_sha256": "41C5BE238D7BC83F0008949CE03A16BA72C1847085C94B8B7932890FA82754BE",
            "transform": "qualification-sha256-field-only",
        },
    }
    indexed_changes = {entry.get("path"): entry for entry in changes if isinstance(entry, dict)}
    require(set(indexed_changes) == set(expected_changes), "runtime LF integration paths")
    for path, expected in expected_changes.items():
        entry = indexed_changes[path]
        require(all(entry.get(key) == value for key, value in expected.items()),
                "exact runtime LF integration transformation")

    integrated_qualification = _bound_file(root, qualification_path, 1024 * 1024)
    require(qualification_sha == expected_changes[qualification_path]["integrated_sha256"] and
            integrated_qualification.endswith(b"\n") and not integrated_qualification.endswith(b"\r\n") and
            b"\r" not in integrated_qualification,
            "integrated qualification line endings")
    execution_qualification = integrated_qualification[:-1].replace(b"\n", b"\r\n") + b"\n"
    require(legacy.sha(execution_qualification) == expected_changes[qualification_path]["execution_sha256"] and
            json.loads(execution_qualification.decode("utf-8")) == json.loads(integrated_qualification.decode("utf-8")),
            "qualification semantics and execution bytes")

    provenance_change = indexed_changes[provenance_path]
    old_value = provenance_change.get("execution_value")
    new_value = provenance_change.get("integrated_value")
    require(provenance_change.get("field") == "source_package.qualification_sha256" and
            old_value == expected_changes[qualification_path]["execution_sha256"] and
            new_value == expected_changes[qualification_path]["integrated_sha256"] and
            qualification_sha == new_value,
            "exact provenance qualification binding")
    provenance_token = b'"qualification_sha256": "' + str(new_value).encode("ascii") + b'"'
    require(provenance_bytes.count(provenance_token) == 1,
            "single provenance qualification field")
    execution_provenance = provenance_bytes.replace(
        provenance_token,
        b'"qualification_sha256": "' + str(old_value).encode("ascii") + b'"',
        1,
    )
    require(legacy.sha(execution_provenance) == expected_changes[provenance_path]["execution_sha256"] and
            legacy.sha(provenance_bytes) == expected_changes[provenance_path]["integrated_sha256"],
            "provenance single-field execution bridge")
    try:
        provenance = json.loads(provenance_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("SSIS_V2_RUNTIME_PROVENANCE_INVALID") from error
    source = provenance.get("source_package", {})
    require(source.get("path") == package_path and source.get("sha256") == package_sha and
            source.get("qualification") == qualification_path and
            source.get("qualification_sha256") == qualification_sha and
            source.get("qualification_result") == "PASS" and
            provenance.get("component_profile") == "ssis-debug-components-v2" and
            provenance.get("publication_authorized") is False and
            provenance.get("output", {}).get("path") == installer_path and
            provenance.get("output", {}).get("sha256") == installer_sha and
            provenance.get("output", {}).get("bytes") == len(installer),
            "integrated installer provenance content")
    validate( root / package_path)
    legacy.validate_installer_guards(installer)

    pins = record.get("execution_input_pins")
    require(isinstance(pins, list) and len(pins) == len(RUNTIME_PIN_PATHS) and
            [pin.get("path") for pin in pins if isinstance(pin, dict)] == list(RUNTIME_PIN_PATHS),
            "exact runtime input pin set and order")
    for pin in pins:
        path = pin["path"]
        expected_sha = pin.get("sha256")
        require(isinstance(expected_sha, str) and re.fullmatch(r"[0-9A-F]{64}", expected_sha) is not None,
                "runtime input pin hash format")
        if path == qualification_path:
            actual = legacy.sha(execution_qualification)
        elif path == provenance_path:
            actual = legacy.sha(execution_provenance)
        else:
            actual = legacy.sha(_bound_file(root, path, legacy.MAX_PACKAGE_BYTES))
        require(actual == expected_sha, "current runtime input pin bytes")

    require(qualified_package.get("qualification_sha256") == expected_changes[qualification_path]["execution_sha256"] and
            legacy.sha(execution_provenance) == provenance_record["sha256"],
            "native execution package and provenance pins")
    mode_bindings = record.get("execution", {}).get("mode_bindings", {})
    local = mode_bindings.get("local", {})
    central = mode_bindings.get("central", {})
    require(local.get("header_override_count") == 0 and local.get("command_sha256") == installer_sha and
            central.get("header_override") == {
                "from": "DECLARE @DeploymentMode nvarchar(16)=N'local';",
                "to": "DECLARE @DeploymentMode nvarchar(16)=N'central';",
                "count": 1,
            }, "runtime local/central binding")
    header_from = central["header_override"]["from"].encode("utf-8")
    header_to = central["header_override"]["to"].encode("utf-8")
    require(installer.count(header_from) == 1 and
            legacy.sha(installer.replace(header_from, header_to, 1)) == central.get("command_sha256"),
            "runtime central installer derivation")

    scope = record.get("scope", {})
    final_audit = record.get("final_audit", {})
    require(scope.get("deployment_modes") == ["local", "central"] and
            scope.get("installed_mode_contexts") == 4 and scope.get("case_count") == 2 and
            scope.get("results", {}).get("case_count_passed") == 2 and
            scope.get("results", {}).get("cleanup_audits") == "PASS" and
            scope.get("results", {}).get("target_cases") == "PASS" and
            scope.get("results", {}).get("v2_optin_contexts_passed") == 4 and
            scope.get("results", {}).get("cleanup_audits_passed") == 2 and
            scope.get("targets") == [
                {"platform": "windows", "sql_server": "2019", "compatibility_level": 150},
                {"platform": "windows", "sql_server": "2025", "compatibility_level": 170},
            ] and
            final_audit.get("case_audits") == 2 and
            final_audit.get("owned_database_names_absent") == 4 and
            final_audit.get("trust_states_restored") == 6 and
            final_audit.get("configuration_baselines_restored") is True and
            final_audit.get("input_pins_unchanged") is True and
            final_audit.get("failed_installer_attempts") == 0 and
            record.get("functional_transport", {}).get("authenticated_tls") == "not executed" and
            record.get("functional_transport", {}).get("fallback") is False and
            record.get("functional_transport", {}).get("encrypt_required") is True,
            "runtime scope and independent cleanup audits")
    return record


def validate_install_package_qualification(record_bytes, expected_sha256, package_sha256):
    require(sha(record_bytes) == expected_sha256,
            "exact package qualification source")
    try:
        record = json.loads(record_bytes.decode("utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError("SSIS_V2_PACKAGE_QUALIFICATION_INVALID: JSON") from error
    require(isinstance(record, dict) and
            record.get("schema_version") == "1.0" and
            record.get("kind") == "ssis_components_v2_install_package_qualification" and
            record.get("profile") == "ssis-debug-components-v2" and
            record.get("result") == "PASS" and
            record.get("publication_authorized") is False,
            "package qualification schema/status")
    require(isinstance(record.get("package_sha256"), str) and
            re.fullmatch(r"[0-9a-f]{64}", record["package_sha256"]) is not None and
            record["package_sha256"] == package_sha256.lower(),
            "exact qualified package hash")
    expected_cases = {("2019", 150, "local"), ("2025", 170, "central")}
    cases = record.get("cases")
    require(isinstance(cases, list) and len(cases) == len(expected_cases),
            "local/central qualification case count")
    actual_cases = set()
    for case in cases:
        require(isinstance(case, dict) and case.get("platform") == "windows" and
                case.get("result") == "PASS" and
                case.get("final_independent_audit") == "PASS",
                "qualified local/central case and independent audit")
        key = (case.get("sql_version"), case.get("compatibility_level"),
               case.get("deployment_mode"))
        require(key in expected_cases and key not in actual_cases,
                "exact local/central qualification scope")
        actual_cases.add(key)
    require(actual_cases == expected_cases, "complete local/central qualification")
    audit = record.get("final_audit")
    require(isinstance(audit, dict) and
            isinstance(audit.get("case_audits"), int) and not isinstance(audit.get("case_audits"), bool) and
            audit["case_audits"] == 2 and
            isinstance(audit.get("owned_database_names_absent"), int) and not isinstance(audit.get("owned_database_names_absent"), bool) and
            audit["owned_database_names_absent"] == 4 and
            isinstance(audit.get("trust_states_restored"), int) and
            not isinstance(audit.get("trust_states_restored"), bool) and
            audit["trust_states_restored"] == 8 and
            audit.get("configuration_baselines_restored") is True and
            audit.get("input_pins_unchanged") is True and
            isinstance(audit.get("failed_package_attempts"), int) and
            not isinstance(audit.get("failed_package_attempts"), bool) and
            audit["failed_package_attempts"] == 0,
            "final independent cleanup audit")
    return record


def main(args):
    archive = Path(MODULE + "InstallPackages/" + NAME + ".zip")
    qualification = Path(MODULE + "Tests/Qualification/ComponentsV2.InstallPackage.20261028.json")
    record_bytes = legacy.read_regular_bounded(ROOT / qualification, 1024 * 1024)
    package_bytes = legacy.read_regular_bounded(ROOT / archive, legacy.MAX_PACKAGE_BYTES)
    validate_install_package_qualification(record_bytes, args.qualification_sha256,
                                           legacy.sha(package_bytes))
    validate(ROOT / archive)
    legacy.PACKAGE = archive
    legacy.PACKAGE_SIDECAR = Path(str(archive) + ".sha256")
    legacy.PACKAGE_QUALIFICATION = qualification
    legacy.PACKAGE_QUALIFICATION_SHA256 = args.qualification_sha256
    legacy.ARCHIVE_ROOT = NAME + "/"
    legacy.OUTPUT = Path("Releases/1.0.0/SSIS-COMPONENTS-V2-INSTALL-TSQL.sql")
    legacy.PROVENANCE = Path("Releases/1.0.0/ssis-components-v2-standalone-installer.json")
    legacy.LICENSE_COPY = Path("Releases/1.0.0/SSIS-COMPONENTS-V2-INSTALL-TSQL-LICENSE.md")
    legacy.SCRIPTDOM_NOTICE = Path("Releases/1.0.0/ThirdParty/SSIS-Components-V2/ScriptDom-180.117.0")
    original_render = legacy.render

    def render(payloads, hashes):
        result = original_render(payloads, hashes)
        # Only comments change; all transaction, ownership and binary guards
        # and the bounded chunk/group SQL rendering remain in the old renderer.
        result = result.replace(
            "Toolbelt SSIS-Debug 1.0.0 – eigenständiger T-SQL-Installer.".encode("utf-8"),
            "Toolbelt SSIS-Debug Components V2 – eigenständiger T-SQL-Installer.".encode("utf-8"))
        result = result.replace(b"SSIS-INSTALL-TSQL-LICENSE.md",
                                b"SSIS-COMPONENTS-V2-INSTALL-TSQL-LICENSE.md")
        legacy.validate_installer_guards(result)
        return result

    legacy.render = render
    result = legacy.main()
    path = ROOT / legacy.PROVENANCE
    provenance = json.loads(path.read_text(encoding="utf-8"))
    provenance["component_profile"] = "ssis-debug-components-v2"
    provenance["limits"].append(
        "V2 analysis is explicitly selected by ProjectContext schemaVersion 2 or bindings-template-v2; V1 defaults remain available")
    path.write_text(json.dumps(provenance, indent=2, ensure_ascii=False) + "\n",
                    encoding="utf-8", newline="\n")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qualification-sha256", required=True,
                        type=lambda value: value.upper())
    options = parser.parse_args()
    require(len(options.qualification_sha256) == 64 and
            all(char in "0123456789ABCDEF" for char in options.qualification_sha256),
            "qualification hash format")
    raise SystemExit(main(options))
