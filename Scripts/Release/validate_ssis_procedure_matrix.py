"""Bind the full Windows V1 matrix to the unchanged, executed installation ZIP."""
import json

from validate_ssis_current_package import (
    ROOT, MODULE, PROCEDURE_DELIVERY, PROCEDURE_METHODS,
    read_regular_bounded, require, sha, validate_procedure_delivery,
)

REPORT = MODULE + "Tests/Qualification/ProcedureV1.InstallPackage.Matrix.Windows.20261104.json"
MATRIX_METHODS = PROCEDURE_METHODS | {
    MODULE + "Tests/Runtime/Invoke-ProcedureDefinitionMatrixLab.ps1",
    MODULE + "Tests/Runtime/Invoke-ProcedureDefinitionMatrixCases.ps1",
}
PATCHES = {"2019": "CU32", "2022": "CU26", "2025": "CU8"}
CONTEXTS = {
    (version, level, mode)
    for version, levels in (("2019", (150,)), ("2022", (150, 160)), ("2025", (150, 160, 170)))
    for level in levels for mode in ("local", "central")
}


def validate(report=None, *, check_files=True, source_root=ROOT):
    if report is None:
        report = json.loads(read_regular_bounded(ROOT / REPORT, 1024 * 1024))
    basis_bytes = read_regular_bounded(ROOT / PROCEDURE_DELIVERY, 1024 * 1024)
    basis = json.loads(basis_bytes)
    require(report.get("kind") == "ssis_procedure_v1_windows_matrix_qualification" and
            report.get("schema_version") == "1.0" and report.get("result") == "PASS" and
            report.get("publication_authorized") is False, "V1 matrix identity")
    require(report.get("package") == basis["package"] and
            report.get("reused_evidence") == {"path": PROCEDURE_DELIVERY, "sha256": sha(basis_bytes)},
            "V1 matrix exact ZIP and reused evidence")
    cases = report.get("cases", [])
    require(len(cases) == 12 and all(
        type(case.get("compatibility_level")) is int and type(case.get("dialect_level")) is int and
        type(case.get("central_consumer")) is bool and type(case.get("package_assertions")) is int and
        type(case.get("procedure_assertions")) is int for case in cases),
            "V1 matrix case types and count")
    require({(case.get("sql_version"), case["compatibility_level"], case.get("deployment_mode"))
             for case in cases} == CONTEXTS, "V1 matrix complete unique contexts")
    for case in cases:
        context = (case["sql_version"], case["compatibility_level"], case["deployment_mode"])
        reused = context == ("2025", 150, "local")
        require(case == {
            "platform": "windows", "sql_version": context[0], "patch": PATCHES[context[0]],
            "compatibility_level": context[1], "dialect_level": context[1], "deployment_mode": context[2],
            "test_purpose": "Functional", "authenticated_tls": "not executed",
            "package_assertions": 8, "procedure_assertions": 91, "result": "PASS", "cleanup_audit": "PASS",
            "central_consumer": context[2] == "central", "evidence": "reused" if reused else "new",
        }, "V1 matrix case scope or audit")
    history = report.get("attempt_history", {})
    require(all(type(value) is int for value in history.values()) and history == {
        "pass_cleaned": 11, "failed_cleaned": 1, "target_invocations": 12,
        "independent_audits": 12, "native_invocations": 24, "owned_databases_removed": 19,
    },
            "V1 matrix attempt history")
    require(report.get("failed_attempts") == [{
        "sql_version": "2025", "compatibility_level": 150, "deployment_mode": "central",
        "result": "FAILED_CLEANED", "cleanup_audit": "PASS", "sql_error": 2714,
        "cause": "parallel_named_temp_deployment_constraint", "product_pass_claimed": False,
    }], "V1 matrix original failure retained")
    require(report.get("total_package_assertions") == 96 and
            type(report.get("total_package_assertions")) is int and
            report.get("total_procedure_assertions") == 1092 and
            type(report.get("total_procedure_assertions")) is int, "V1 matrix assertion totals")
    inputs = report.get("execution_inputs", {})
    require(set(inputs) == MATRIX_METHODS, "V1 matrix input closure")
    if check_files:
        validate_procedure_delivery(source_root=source_root)
        for path, digest in inputs.items():
            require(sha(read_regular_bounded(ROOT / path, 1024 * 1024)) == digest,
                    "V1 matrix changed input: " + path)
    return report


if __name__ == "__main__":
    validate()
    print("SSIS_PROCEDURE_V1_WINDOWS_MATRIX_PASS; 12 contexts and bound cleanup audits")
