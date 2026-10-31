"""Gegenproben für aktuelle Anmelde-Evidence und Vor-SQL-TLS-Adaptergates."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("ssis_access", ROOT / "Scripts/Release/validate_ssis_current_access.py")
access = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(access)
RUNTIME = ROOT / "Modules/toolbelt.tsql.ssis-debug/Tests/Runtime"


class AccessEvidence(unittest.TestCase):
    def setUp(self):
        self.record = json.loads((ROOT / access.REPORT).read_text(encoding="utf-8"))

    def test_actual_record_and_current_product_binding(self):
        access.validate(ROOT)

    def reject(self, mutate):
        changed = copy.deepcopy(self.record)
        mutate(changed)
        with self.assertRaises(ValueError):
            access.validate(ROOT, changed, check_files=False)

    def test_missing_context(self):
        self.reject(lambda r: r["cases"].pop())

    def test_duplicate_context(self):
        self.reject(lambda r: r["cases"].append(copy.deepcopy(r["cases"][0])))

    def test_failed_audit(self):
        self.reject(lambda r: r["cases"][0].update(cleanup_audit="FAILED"))

    def test_wrong_patch(self):
        self.reject(lambda r: r["cases"][0].update(patch="base"))

    def test_forged_count(self):
        self.reject(lambda r: r["cases"][0].update(windows_assertions=True))

    def test_rights_escalation(self):
        self.reject(lambda r: r["lowpriv_identity"].update(server_roles_granted=True))

    def test_numeric_false_is_not_boolean(self):
        self.reject(lambda r: r["lowpriv_identity"].update(trustworthy_enabled=0))

    def test_windows_does_not_imply_authenticated_tls(self):
        self.reject(lambda r: r["windows_identity"].update(authenticated_tls=True))

    def test_gui_does_not_imply_windows_login(self):
        self.reject(lambda r: r["gui"].update(authentication="NTLM"))

    def test_gui_without_visual_check(self):
        self.reject(lambda r: r["gui"].update(unicode_witness=False))

    def test_gui_original_coordinator_failure_is_retained(self):
        self.reject(lambda r: r["gui"].update(coordinator_result="PASS"))

    def test_initial_failed_audit_cannot_disappear(self):
        self.reject(lambda r: r["attempt_history"][18].update(original_audit="PASS"))

    def test_publication_is_not_authorized(self):
        self.reject(lambda r: r.update(publication_authorized=True))

    def test_missing_execution_source(self):
        self.reject(lambda r: r["source_sha256"].pop(next(iter(r["source_sha256"]))))


@unittest.skipUnless(shutil.which("pwsh"), "PowerShell 7 erforderlich; kein SQL")
class TlsPreSqlGuards(unittest.TestCase):
    def test_documented_memory_defaults_are_observed_without_restore_writes(self):
        script = r'''
$ErrorActionPreference='Stop'
$ast=[Management.Automation.Language.Parser]::ParseFile($args[0],[ref]$null,[ref]$null)
$f=@($ast.FindAll({param($n)$n -is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -ceq 'Test-SsisTlsImplicitConfigurationValue'},$true))
if($f.Count -ne 1){throw 'CLASSIFIER_MISSING'}
. ([scriptblock]::Create($f[0].Extent.Text))
foreach($case in @(
 @('min server memory (MB)',0,16,$true),@('min server memory (MB)',0,8,$true),
 @('max server memory (MB)',0,2147483647,$true),
 @('min server memory (MB)',17,16,$false),@('max server memory (MB)',1,2147483647,$false),
 @('clr enabled',0,1,$false),@('show advanced options',0,1,$false),
 @('min server memory (MB)',0,17,$false))){
 $r=[pscustomobject]@{name=$case[0];Configured=$case[1];Running=$case[2]}
 if((Test-SsisTlsImplicitConfigurationValue $r) -ne $case[3]){throw 'CLASSIFIER_WRONG'}
}
'EIGHT_MEMORY_DEFAULT_COUNTEREXAMPLES_PASS'
'''
        path = self.directory / "memory-defaults.ps1"
        path.write_text(script, encoding="utf-8")
        result = subprocess.run([shutil.which("pwsh"), "-NoProfile", "-File", str(path),
                                 str(RUNTIME / "Invoke-CurrentAuthenticatedTlsLab.ps1")],
                                cwd=ROOT, capture_output=True, text=True, timeout=30,
                                creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("EIGHT_MEMORY_DEFAULT_COUNTEREXAMPLES_PASS", result.stdout)

    def setUp(self):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(prefix="ssis-tls-guards-", dir=ROOT / ".runtime")
        self.directory = Path(self.temporary.name)
        self.lab = self.directory / "synthetic-lab"
        for folder in ("Private", "Public", "Providers", "Catalogs", "Schemas"):
            (self.lab / folder).mkdir(parents=True, exist_ok=True)
        (self.lab / "SqlServerLab.psd1").write_text("@{}", encoding="utf-8")
        (self.lab / "SqlServerLab.psm1").write_text("", encoding="utf-8")
        (self.lab / "Schemas/test-environment-authenticated.schema.json").write_text("{}", encoding="utf-8")
        self.export = self.directory / "synthetic-export.json"
        self.export.write_text("{}", encoding="utf-8")
        self.files = []
        paths = [p for d in ("Tests/Runtime", "Tests/Fixtures", "Contracts")
                 for p in (ROOT / access.MODULE / d).rglob("*") if p.is_file() and "__pycache__" not in p.parts]
        paths += [ROOT / p for p in ("Tests/CI/run-lab-local.ps1", "Tests/CI/LabQualifiedContract.ps1")]
        for p in paths:
            self.files.append({"repository": "toolbelt", "path": p.relative_to(ROOT).as_posix(), "sha256": hashlib.sha256(p.read_bytes()).hexdigest().upper()})
        for p in self.lab.rglob("*"):
            if p.is_file():
                self.files.append({"repository": "lab", "path": p.relative_to(self.lab).as_posix(), "sha256": hashlib.sha256(p.read_bytes()).hexdigest().upper()})

    def tearDown(self):
        self.assertTrue(self.directory.resolve().is_relative_to((ROOT / ".runtime").resolve()))
        self.temporary.cleanup()

    def invoke(self, files):
        manifest = self.directory / "inputs.json"
        manifest.write_text(json.dumps({"schemaVersion": 1, "profile": "ssis-current-authenticated-tls", "files": files}), encoding="utf-8")
        args = [shutil.which("pwsh"), "-NoProfile", "-File", str(RUNTIME / "Invoke-CurrentAuthenticatedTlsLab.ps1"),
                "-LabModuleFile", str(self.lab / "SqlServerLab.psd1"), "-LabTlsStateRoot", str(self.directory / "state"),
                "-LabTlsRunId", "11111111-1111-4111-8111-111111111111", "-LabTlsInstanceId", "primary",
                "-ExportPath", str(self.export), "-ExpectedExportSha256", hashlib.sha256(self.export.read_bytes()).hexdigest().upper(),
                "-InputManifestPath", str(manifest), "-ExpectedInputManifestSha256", hashlib.sha256(manifest.read_bytes()).hexdigest().upper(),
                "-SsisReleaseDirectory", "synthetic", "-ParserReleaseDirectory", "synthetic", "-QualifiedProviderSha512", "0" * 128,
                "-JournalDirectory", str(self.directory / "unused"), "-ValidateOnly"]
        result = subprocess.run(args, cwd=ROOT, capture_output=True, text=True, timeout=30)
        self.assertFalse((self.directory / "unused").exists())
        return result

    @unittest.skipUnless(__import__("sys").platform == "win32", "Windows-only TLS adapter")
    def test_composition_without_import_or_sql(self):
        result = self.invoke(self.files)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("SSIS_CURRENT_TLS_ADAPTER_VALIDATED; no SQL", result.stdout)

    def test_changed_source_rejects_before_import_or_sql(self):
        self.files[0]["sha256"] = "0" * 64
        self.assertNotEqual(self.invoke(self.files).returncode, 0)

    def test_missing_shared_reader_rejects_before_import_or_sql(self):
        self.assertNotEqual(self.invoke([f for f in self.files if f["path"] != "Tests/CI/LabQualifiedContract.ps1"]).returncode, 0)


if __name__ == "__main__":
    unittest.main()
