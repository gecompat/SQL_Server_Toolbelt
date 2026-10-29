"""Render the V2 installer using the existing guarded T-SQL renderer."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import re

import new_ssis_standalone_tsql as legacy
from new_ssis_components_v2_package import MODULE, NAME, ROOT, require, sha
from validate_ssis_components_v2_package import validate


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
            audit["owned_database_names_absent"] == 2 and
            isinstance(audit.get("trust_states_restored"), int) and
            not isinstance(audit.get("trust_states_restored"), bool) and
            audit["trust_states_restored"] > 0 and
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
