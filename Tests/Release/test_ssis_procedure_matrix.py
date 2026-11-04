"""Negative controls for context coverage, reuse and central execution claims."""
import copy
import json
from pathlib import Path
import sys
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "Scripts/Release"))
import validate_ssis_procedure_matrix as matrix


class ProcedureMatrix(unittest.TestCase):
    def setUp(self):
        self.record = json.loads((ROOT / matrix.REPORT).read_bytes())

    def test_actual_matrix_and_current_sources(self):
        matrix.validate()

    def test_missing_duplicate_and_unsupported_contexts(self):
        for change in (
            lambda r: r["cases"].pop(),
            lambda r: r["cases"].__setitem__(1, copy.deepcopy(r["cases"][0])),
            lambda r: r["cases"][0].update(compatibility_level=170),
            lambda r: r["cases"][0].update(compatibility_level=150.0),
        ):
            changed = copy.deepcopy(self.record)
            change(changed)
            with self.subTest(change=change), self.assertRaises(ValueError):
                matrix.validate(changed, check_files=False)

    def test_matrix_cannot_claim_unexecuted_scope_or_skip_cleanup(self):
        central = next(i for i, case in enumerate(self.record["cases"]) if case["deployment_mode"] == "central")
        for field, value in (("central_consumer", False), ("cleanup_audit", "not executed"),
                             ("patch", "base"), ("dialect_level", 150.0), ("evidence", "reused"),
                             ("test_purpose", "AuthenticatedTls")):
            changed = copy.deepcopy(self.record)
            changed["cases"][central][field] = value
            with self.subTest(field=field), self.assertRaises(ValueError):
                matrix.validate(changed, check_files=False)

    def test_package_input_history_and_counter_drift_are_rejected(self):
        for change in (
            lambda r: r["package"].update(sha256="0" * 64),
            lambda r: r["reused_evidence"].update(sha256="0" * 64),
            lambda r: r["execution_inputs"].pop(next(iter(r["execution_inputs"]))),
            lambda r: r["attempt_history"].update(independent_audits=0),
            lambda r: r["attempt_history"].update(failed_cleaned=True),
            lambda r: r["failed_attempts"].clear(),
            lambda r: r.update(total_procedure_assertions=True),
        ):
            changed = copy.deepcopy(self.record)
            change(changed)
            with self.subTest(change=change), self.assertRaises(ValueError):
                matrix.validate(changed, check_files=False)

    def test_adapter_rejects_wrong_cl_or_inputs_before_sql(self):
        runtime = ROOT / ".runtime"
        runtime.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="procedure-matrix-guards-", dir=runtime) as temporary:
            directory = Path(temporary)
            (directory / "PACKAGE-MANIFEST.json").write_text("{}", encoding="utf-8")
            driver = ROOT / matrix.MODULE / "Tests/Runtime/Invoke-ProcedureDefinitionMatrixLab.ps1"
            method = ROOT / matrix.MODULE / "Tests/Runtime/Invoke-ProcedureDefinitionMatrixCases.ps1"

            def quote(value):
                return "'" + str(value).replace("'", "''") + "'"

            for level, digest, reason in (
                (170, "0" * 64, "SSIS_PROCEDURE_MATRIX_UNSUPPORTED_CL"),
                (150, "0" * 64, "SSIS_PROCEDURE_MATRIX_CASES_CHANGED"),
                (150, matrix.sha(method.read_bytes()), "SSIS_PROCEDURE_PACKAGE_BINDING"),
            ):
                closure = {}
                for name in ("Invoke-ProcedureDefinitionCases.ps1", "Invoke-CurrentCases.ps1", "../Fixtures/procedure-8.dtsx"):
                    file = driver.parent / name
                    closure[name] = matrix.sha(file.read_bytes())
                bindings = ";".join(quote(name) + "=" + quote(value) for name, value in closure.items())
                command = (
                    "$ErrorActionPreference='Stop'; & " + quote(driver) +
                    " -Mode Run -Version 2019 -Patch CU32 -DeploymentMode local" +
                    " -CompatibilityLevel " + str(level) +
                    " -ExpectedTargetKey unused -ExpectedContractSha256 " + quote("0" * 64) +
                    " -JournalDirectory " + quote(directory / "journal") +
                    " -InstallationPackageRoot " + quote(directory) +
                    " -ExpectedPackageManifestSha256 " + quote("0" * 64) +
                    " -QualifiedProviderSha512 " + quote("0" * 128) +
                    " -CaseInputSha256 @{" + bindings + "}" +
                    " -MatrixCasesExpectedSha256 " + quote(digest)
                )
                result = subprocess.run(["pwsh", "-NoProfile", "-NonInteractive", "-Command", command],
                                        cwd=ROOT, capture_output=True, text=True, timeout=20,
                                        creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
                with self.subTest(reason=reason):
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn(reason, result.stdout + result.stderr)
                    self.assertFalse((directory / "journal").exists())


if __name__ == "__main__":
    unittest.main()
