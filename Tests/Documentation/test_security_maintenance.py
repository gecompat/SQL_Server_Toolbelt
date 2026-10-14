"""Security-Korrekturen mit synthetischen Inputs, ohne SQL oder Netzwerk."""
from pathlib import Path
import importlib.util
import sys
import tempfile
import unittest
import subprocess
import shutil
from unittest.mock import patch

import validate_documentation as documentation

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("security_budget", ROOT / ".ai/foundation/runtime/processing_efficiency.py")
budget = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = budget
spec.loader.exec_module(budget)


class SecurityMaintenance(unittest.TestCase):
    @unittest.skipUnless(shutil.which('pwsh'), 'PowerShell unavailable')
    def test_git_log_containment(self):
        completed = subprocess.run(['pwsh', '-NoProfile', '-File', str(ROOT / 'Tests/Documentation/test_security_paths.ps1')],
                                   capture_output=True, text=True, timeout=20)
        self.assertEqual(completed.returncode, 0, completed.stdout + completed.stderr)

    def test_exact_budget_boundaries(self):
        for unit in ("TOKENS", "CREDITS", "USD"):
            for count, action in ((8, "ALLOW_NEW_WORK"), (9, "STOP_NEW_WORK"), (10, "STOP_NEW_WORK")):
                request = dict(schema_version=1, contract="foundation-processing-budget/v1",
                               wave_id="synthetic", unit=unit, soft_limit=None, hard_limit=0.1,
                               next_reservation=0.01, entries=[dict(invocation_id=str(i), actor="synthetic",
                               consumed=0.01, reserved=0, provenance="MEASURED") for i in range(count)])
                self.assertEqual(budget.budget_decision(request)["action"], action)
                request["entries"] += request["entries"][:1]
                self.assertEqual(budget.budget_decision(request)["action"], action)

    def test_all_evidence_targets_precede_any_write(self):
        with tempfile.TemporaryDirectory() as temporary:
            outer = Path(temporary)
            root = outer / "repository"
            module_root = root / "module"
            module_root.mkdir(parents=True)
            first = module_root / "first.md"
            first.write_text("synthetic-original", encoding="utf-8")
            outside = outer / "outside.md"
            outside.write_text("synthetic-outside", encoding="utf-8")
            git = root / ".git"
            git.mkdir()
            protected = git / "config.md"
            protected.write_text("synthetic-git", encoding="utf-8")
            for bad in (str(outside), "../../outside.md", "../.git/config.md", "first.txt"):
                modules = [dict(root=module_root, documentation={"evidence": "first.md"}, evidence_entries=[{}]),
                           dict(root=module_root, documentation={"evidence": bad}, evidence_entries=[])]
                with patch.object(documentation, "REPOSITORY_ROOT", root), patch.object(documentation, "module_evidence_block", return_value="synthetic"):
                    with self.assertRaises(documentation.ValidationError):
                        documentation.validate_generated_module_evidence(modules, True)
                self.assertEqual(first.read_text(), "synthetic-original")
                self.assertEqual(outside.read_text(), "synthetic-outside")
                self.assertEqual(protected.read_text(), "synthetic-git")
            with patch.object(documentation, "REPOSITORY_ROOT", root):
                self.assertEqual(documentation.evidence_documents(modules[0]), [first.resolve()])


if __name__ == "__main__":
    unittest.main()
