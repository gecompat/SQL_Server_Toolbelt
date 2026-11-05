"""Validate aggregate claims; private run journals remain private."""
import copy
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
RECORD = ROOT / "Tests/Qualification/Current.Build.20261105.json"
REPOSITORY = ROOT.parents[1]
METHOD_PATHS = [
    "Tests/CI/run-script-parser-lab.ps1", "Tests/CI/Invoke-ScriptParserCurrentLab.ps1",
    "Tests/CI/ParserCurrentSnapshot.ps1", "Tests/Release/Test-ParserCurrentLab.ps1",
] + ["Modules/toolbelt.tsql.script-parser/Tests/" + name for name in (
    "Framework/ProviderTests.cs", "Framework/TestInputs.cs", "Framework/Invoke-Contract.ps1",
    "Framework/Test-OutputDominance.ps1", "Runtime/Lifecycle.Contract.sql",
    "Runtime/MinimalRights.Contract.sql", "Runtime/OutputCeilings.Contract.sql",
    "Static/validate_contract.py", "Static/validate_output_invariants.py", "Static/validate_qualification.py",
)]
EXPECTED = {"2019": ("CU32", [150], 12), "2022": ("CU26", [150, 160], 24), "2025": ("CU8", [150, 160, 170], 36)}
UNEXECUTED = ["Nodes:32767/32768/32769", "Properties:16MiB transition", "Errors:257 quota-overflow branch"]


def validate(record: dict) -> None:
    def require(condition, label):
        if not condition:
            raise ValueError("PARSER_QUALIFICATION_" + label)

    require(record["schema"] == "parser-current-qualification/v1" and record["moduleVersion"] == "2.0.1", "SCHEMA")
    require(record["publicationAuthorized"] is False and record["productCodeChanged"] is False, "AUTHORITY")
    require(record["historicalFailuresPreserved"] is True, "HISTORY")
    require(record["apiMatrix"] == "PASS" and record["minimalRights"] == "PASS_FOR_DATABASE_SCOPED_IDENTITY", "SCOPE")
    require(record["publicBoundaryCallsNotExecuted"] == UNEXECUTED, "NATIVE_SCOPE")
    require(record["fullNativeBoundaryCoverage"] is False, "NO_NATIVE_UPGRADE")
    require(len(record["cases"]) == 3 and {c["sqlVersion"] for c in record["cases"]} == set(EXPECTED), "MATRIX")
    total = 0
    for case in record["cases"]:
        patch, levels, suites = EXPECTED[case["sqlVersion"]]
        require(case["patch"] == patch and case["levels"] == levels and case["modes"] == ["local", "central"], "CONTEXT")
        require(case["completedSuites"] == suites and case["nativeResult"] == "PASS_CLEANED", "NATIVE")
        require(case["freshParserAudit"] == "PASS" and case["configurationFinalAudit"] == "PASS", "AUDIT")
        require(case["minimalRights"] == "DB_USER_WITHOUT_LOGIN_SELECT_ONLY_PASS", "RIGHTS")
        require(not case["originalCallerRestoreBlocked"] or case["guardedRecoveryPerformed"], "RECOVERY")
        require(case["tokenCeiling"] == "NATIVE_PASS", "TOKEN_BOUNDARY")
        expected_error = "NOT_EXECUTED" if case["sqlVersion"] == "2019" else "NATIVE_PASS_AT_256_THEN_PREPARSE_REJECTION"
        require(case["errorAdmission"] == expected_error, "ERROR_BOUNDARY")
        total += suites
    require(total == record["totalCompletedSuites"] == 72 and record["frameworkFinalCases"] == 248, "COUNTS")
    require(record["binaryBudgetTests"] == "PASS_ACTUAL_FIXED_LIMITS" and record["sourceInvariant"] == "PASS_REVIEWED_BODY" and record["dominanceProof"] == "PASS_PINNED_CATALOG", "COMBINED_COMPONENTS")
    acceptance = record["quotaAcceptance"]
    require(acceptance in ("PENDING", "APPROVED_COMBINED_EVIDENCE"), "ACCEPTANCE")
    if acceptance == "PENDING":
        require(record["result"] == "PARTIAL_PENDING_QUOTA_ACCEPTANCE", "PENDING_RESULT")
    else:
        require(record["result"] == "PASS_FOR_APPROVED_COMBINED_SCOPE", "APPROVED_RESULT")
        agreement = (ROOT / "Tests/OUTPUT_QUOTA_ACCEPTANCE_PROPOSAL.md").read_text(encoding="utf-8")
        require("Status: **Freigegeben durch ausdrückliche Benutzerentscheidung vom 2026-11-05.**" in agreement, "EXPLICIT_APPROVAL")
    files = []
    for directory in ("Clr", "Source", "Deployment"):
        files += [p for p in (ROOT / directory).rglob("*") if p.is_file() and p.suffix in (".cs", ".csproj", ".sql") and not {"bin", "obj"}.intersection(p.relative_to(ROOT).parts)]
    require(set(record["productSources"]) == {p.relative_to(ROOT).as_posix() for p in files}, "SOURCE_CLOSURE")
    for file in files:
        # Drift detection across checkout line endings; exact runtime binary/raw-source binding stays in the private protected receipts.
        actual = hashlib.sha256(file.read_text(encoding="utf-8").encode("utf-8")).hexdigest().upper()
        require(record["productSources"][file.relative_to(ROOT).as_posix()] == actual, "SOURCE_DRIFT")
    require(set(record["methodSources"]) == set(METHOD_PATHS), "METHOD_CLOSURE")
    for path in METHOD_PATHS:
        actual = hashlib.sha256((REPOSITORY / path).read_text(encoding="utf-8").encode("utf-8")).hexdigest().upper()
        require(record["methodSources"][path] == actual, "METHOD_DRIFT")


def main() -> None:
    record = json.loads(RECORD.read_text(encoding="utf-8"))
    validate(record)
    mutations = [
        lambda r: r.update(publicationAuthorized=True),
        lambda r: r.update(historicalFailuresPreserved=False),
        lambda r: r.update(publicBoundaryCallsNotExecuted=[]),
        lambda r: r.update(fullNativeBoundaryCoverage=True),
        lambda r: r["cases"][0].update(freshParserAudit="FAIL"),
        lambda r: r["cases"][0].update(nativeResult="FAILED_REQUIRES_AUDIT"),
        lambda r: r["cases"][1].update(levels=[150, 160, 170]),
        lambda r: r["cases"][2].update(guardedRecoveryPerformed=False),
        lambda r: r.update(result="PASS"),
        lambda r: r.update(frameworkFinalCases=245),
        lambda r: r.update(binaryBudgetTests="NOT_EXECUTED"),
        lambda r: r["productSources"].update({next(iter(r["productSources"])): "0" * 64}),
    ]
    for mutate in mutations:
        bad = copy.deepcopy(record)
        mutate(bad)
        try:
            validate(bad)
        except (ValueError, KeyError):
            continue
        raise AssertionError("PARSER_QUALIFICATION_MUTANT_ACCEPTED")
    print("PARSER_QUALIFICATION_PASS 12 rejected false-claim/drift mutants")


if __name__ == "__main__":
    main()
