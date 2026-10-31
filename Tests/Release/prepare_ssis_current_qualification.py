"""Projiziert private SSIS-Läufe auf öffentliche, quellengebundene Abnahmedaten.

Ziele, Journale, Trustzustände, Laufzeitpfade und Originalausgaben werden nicht
übernommen. Die eigentliche Ausführung und ihr separater Audit bleiben privat.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("ssis_current_functional", ROOT / "Scripts/Release/validate_ssis_current_functional.py")
functional = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(functional)


def load(path):
    return json.loads(path.read_text(encoding="utf-8-sig"), object_pairs_hook=functional.unique)


def prepare(private):
    private = private.resolve(strict=True)
    functional.require(private.is_relative_to((ROOT / ".runtime").resolve()), "PRIVATE_RUNSET_BOUNDARY")
    ledger = load(private / "ledger.json")
    if isinstance(ledger, dict):
        ledger = [ledger]
    functional.require(len(ledger) * 2 <= 72, "ATTEMPT_BUDGET")
    selected = {}
    history = []
    for attempt in ledger:
        directory = Path(attempt["runPath"]).resolve(strict=True)
        functional.require(directory.is_relative_to(private), "PRIVATE_CASE_BOUNDARY")
        if attempt["state"] == "NO_SQL":
            continue
        functional.require(attempt["audit"] == "PASS" and
                           "SSIS_V2_INDEPENDENT_CLEANUP_AUDIT_PASS" in (directory / "audit.log").read_text(encoding="utf-8-sig"),
                           "INDEPENDENT_AUDIT")
        journal = load(directory / "journals/target-1.json")
        functional.require(journal["state"] in ("PASS_CLEANED", "FAILED_CLEANED"), "CLEANUP_STATE")
        history.append({"attempt": attempt["ordinal"], "method_source_commit": attempt["commit"],
                        "qualification_scope": attempt.get("qualificationPhase", "Full"),
                        "sql_version": attempt["version"], "compatibility_level": attempt["level"],
                        "deployment_mode": attempt["mode"], "result": journal["state"], "cleanup_audit": "PASS"})
        if attempt["state"] != "PASS":
            continue
        log = (directory / "target.log").read_text(encoding="utf-8-sig")
        if attempt.get("qualificationPhase", "Full") != "Full":
            functional.require("SSIS_CURRENT_QUALIFICATION_FOCUSED_PASS;" in log, "FOCUSED_SCOPE_RECORD")
            continue
        functional.require("SSIS_CURRENT_QUALIFICATION_ALL_PASS; no legacy API execution" in log,
                           "FULL_CASE_REQUIRED")
        manifest_path = directory / "inputs.json"
        functional.require(hashlib.sha256(manifest_path.read_bytes()).hexdigest().upper() == attempt["inputHash"], "INPUT_MANIFEST_PIN")
        inputs = load(manifest_path)["files"]
        case = {"sql_version": attempt["version"], "patch": attempt["patch"],
                "compatibility_level": attempt["level"], "deployment_mode": attempt["mode"],
                "database_collation": attempt["collation"], "method_source_commit": attempt["commit"],
                "result": "PASS", "cleanup_audit": "PASS", "input_pins_unchanged": True}
        case["long_plan_default_budget"] = attempt["level"] == 170
        functional.require(("SSIS_V2_NATIVE_VARIABLE_CASE LONG_TYPED_TERNARY_PLAN" in log) ==
                           case["long_plan_default_budget"], "LONG_PLAN_SCOPE")
        for field, token in [("current_assertions", "SSIS_CURRENT_NATIVE_PASS"),
                             ("semantic_assertions", "SSIS_CURRENT_QUALIFICATION_SEMANTICS_PASS"),
                             ("api_assertions", "SSIS_NATIVE_API_PASS"),
                             ("rights_assertions", "SSIS_RELEASE_RIGHTS_PASS"),
                             ("lifecycle_assertions", "SSIS_NATIVE_LIFECYCLE_PASS")]:
            matches = re.findall(re.escape(token) + r" ([0-9]+) assertions", log)
            functional.require(len(matches) == 1, "ASSERTION_RECORD")
            case[field] = int(matches[0])
        selected[(attempt["version"], attempt["level"], attempt["mode"])] = (case, inputs)
    functional.require(set(selected) == functional.EXPECTED_CONTEXTS, "NATIVE_MATRIX_INCOMPLETE")
    sources = {}
    for _, inputs in selected.values():
        functional.require(all(functional.sha(functional.read(ROOT, item["path"])).upper() == item["sha256"]
                               for item in inputs), "CURRENT_INPUT_APPLICABILITY")
        for item in inputs:
            expected = item["sha256"].lower()
            functional.require(item["path"] not in sources or sources[item["path"]] == expected,
                               "MIXED_EXECUTION_SOURCES")
            sources[item["path"]] = expected
    build = load(private / "current-build/Toolbelt.Tsql.SsisDebug.trust-manifest.json")
    for item in build["sourceFiles"]:
        path, expected = item.rsplit(":", 1)
        relative = (ROOT / functional.MODULE / path).resolve().relative_to(ROOT).as_posix()
        functional.require(functional.sha(functional.read(ROOT, relative)).upper() == expected, "BUILD_SOURCE_PIN")
        sources[relative] = expected.lower()
    framework = load(private / "framework.json")
    functional.require(framework["result"] == "PASS" and framework["profile"] == "Full" and
                       framework["cases"] == 26 and framework["sqlExecuted"] is False and
                       framework["providerSha512"] == build["sha512"] and
                       framework["scriptDomSha512"] == build["scriptDomSha512"],
                       "CURRENT_FRAMEWORK")
    for relative in [functional.MODULE + "Tests/Framework/ContractTests.cs",
                     functional.MODULE + "Tests/Framework/Invoke-Contract.ps1",
                     "Modules/toolbelt.string.edit-distance/Scripts/Invoke-OwnedProcess.ps1"]:
        sources[relative] = functional.sha(functional.read(ROOT, relative))
    reused = [functional.MODULE + "Tests/Qualification/Current.InstallPackage.Matrix.20261029.json",
              "Releases/1.0.0/ssis-current-standalone-installer-matrix.json",
              functional.MODULE + "Tests/Qualification/Current.SnapshotCoherence.20261030.json",
              "Releases/1.0.0/parameter-help-qualification.json"]
    record = {"schema_version": "1.0", "kind": "ssis_current_functional_qualification",
              "date": "2026-10-31", "result": "PASS", "publication_authorized": False,
              "functional_scope_complete": True, "scope": "current_supported_debug_contract",
              "gates": {gate: "PASS" for gate in sorted(functional.GATES)},
              "cases": [item[0] for _, item in sorted(selected.items())], "attempt_history": history,
              "source_sha256": dict(sorted(sources.items())), "reuse_binding": functional.reuse_binding(ROOT),
              "reused_evidence": [{"path": path, "sha256": functional.sha(functional.read(ROOT, path))} for path in reused],
              "current_delivery": {"package": functional.HELP_PACKAGE,
                                   "package_sha256": functional.sha(functional.read(ROOT, functional.HELP_PACKAGE)),
                                   "source_fingerprint_sha256": build["sourceFingerprintSha256"],
                                   "deployment_sha256": build["deploymentArtifactSha256"],
                                   "assembly_sha256": functional.sha((private / "current-build/Toolbelt.Tsql.SsisDebug.dll").read_bytes())},
              "offline_framework": {"profile": "Full", "bounded_children": 26, "result": "PASS"},
              "long_plan": {"groups": 64, "minimum_units": 17, "typed_rows": 6,
                            "output_limit_bytes": 134217728, "limits_overridden": False},
              "authenticated_tls": "not executed", "ssis_runtime_parity": "not applicable to debug contract",
              "separate_boundaries": ["SSMS GUI and Windows authentication", "Administrative installer trust opt-in",
                                      "Hard transport/host interruption recovery", "Linux export host qualification",
                                      "Production capacity or performance commitments", "Publication"],
              "cost_tokens": "UNKNOWN"}
    functional.validate(ROOT, record)
    output = ROOT / functional.REPORT
    functional.require(not output.exists(), "NEW_REPORT_REQUIRED")
    output.write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return record


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("private_runset", type=Path)
    arguments = parser.parse_args()
    result = prepare(arguments.private_runset)
    print("SSIS_CURRENT_FUNCTIONAL_RECORD_CREATED contexts=" + str(len(result["cases"])))
