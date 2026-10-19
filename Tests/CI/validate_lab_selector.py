#!/usr/bin/env python3
"""Führt synthetische Verhaltenstests der echten PowerShell-Labauswahl aus."""

from pathlib import Path
import shutil
import subprocess


ROOT = Path(__file__).resolve().parents[2]
pwsh = shutil.which("pwsh")
if pwsh is None:
    raise SystemExit("Lab selector tests NOT_EXECUTED: PowerShell 7 (pwsh) fehlt")

result = subprocess.run([
    pwsh, "-NoLogo", "-NoProfile", "-File",
    str(ROOT / "Tests/CI/test-lab-selector.ps1"),
], cwd=ROOT, check=False)
if result.returncode:
    raise SystemExit(result.returncode)
import sys
for test in ("test_lab_tls.py", "test_lab_cleanup.py"):
    result = subprocess.run([sys.executable, "-B", str(ROOT / "Tests/CI" / test)], cwd=ROOT, check=False)
    if result.returncode:
        raise SystemExit(result.returncode)
