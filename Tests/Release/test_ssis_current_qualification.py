"""Vor-SQL-Gegenproben des vollständigen aktuellen SSIS-Testwegs."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
RUNTIME = ROOT / "Modules/toolbelt.tsql.ssis-debug/Tests/Runtime"
PWSH = shutil.which("pwsh")


@unittest.skipUnless(PWSH, "PowerShell 7 erforderlich; keine SQL-Verbindung")
class InputGuards(unittest.TestCase):
    def setUp(self):
        (ROOT / ".runtime").mkdir(exist_ok=True)
        self.temporary = tempfile.TemporaryDirectory(dir=ROOT / ".runtime")
        self.directory = Path(self.temporary.name)
        self.files = []
        for path in sorted(RUNTIME.glob("*.ps1")):
            self.files.append({"path": path.relative_to(ROOT).as_posix(),
                               "sha256": hashlib.sha256(path.read_bytes()).hexdigest().upper()})

    def tearDown(self):
        self.temporary.cleanup()

    def invoke(self, files):
        manifest = self.directory / "inputs.json"
        manifest.write_text(json.dumps({"schemaVersion": 1, "profile": "ssis-debug-current",
                                        "files": files}), encoding="utf-8")
        arguments = [PWSH, "-NoProfile", "-File", str(RUNTIME / "Invoke-CurrentQualificationLab.ps1"),
                     "-Version", "2019", "-Patch", "base", "-Mode", "local",
                     "-CompatibilityLevel", "150", "-JournalDirectory", str(self.directory / "unused"),
                     "-ExpectedTargetKey", "synthetic", "-ExpectedContractSha256", "0" * 64,
                     "-SsisReleaseDirectory", "synthetic", "-ParserReleaseDirectory", "synthetic",
                     "-QualifiedProviderSha512", "0" * 128, "-CasesExpectedSha256",
                     hashlib.sha256((RUNTIME / "Invoke-CurrentQualificationAllCases.ps1").read_bytes()).hexdigest().upper(),
                     "-InputManifestPath", str(manifest), "-ExpectedInputManifestSha256",
                     hashlib.sha256(manifest.read_bytes()).hexdigest().upper(), "-ValidateOnly"]
        result = subprocess.run(arguments, cwd=ROOT, capture_output=True, text=True, timeout=30)
        self.assertFalse((self.directory / "unused").exists(), "ValidateOnly darf kein SQL-Journal anlegen")
        return result

    def test_complete_transitive_inputs_without_sql(self):
        result = self.invoke(self.files)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("SSIS_CURRENT_LAB_ADAPTER_VALIDATED; no SQL", result.stdout)

    def test_missing_semantic_oracle_is_rejected_before_sql(self):
        result = self.invoke([item for item in self.files if not item["path"].endswith("Invoke-ComponentsV2ExpressionCases.ps1")])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SSIS_CURRENT_QUALIFICATION_TRANSITIVE_INPUT_MISSING", result.stderr)

    def test_changed_input_is_rejected_before_sql(self):
        self.files[0]["sha256"] = "0" * 64
        result = self.invoke(self.files)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SSIS_CURRENT_EXECUTION_INPUT_CHANGED", result.stderr)

    def test_duplicate_input_is_rejected_before_sql(self):
        result = self.invoke(self.files + [dict(self.files[0])])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SSIS_CURRENT_INPUT_PATH", result.stderr)

    def test_escape_is_rejected_before_sql(self):
        result = self.invoke(self.files + [{"path": "../synthetic", "sha256": "0" * 64}])
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("SSIS_CURRENT_INPUT_PATH", result.stderr)


if __name__ == "__main__":
    (ROOT / ".runtime").mkdir(exist_ok=True)
    unittest.main()
