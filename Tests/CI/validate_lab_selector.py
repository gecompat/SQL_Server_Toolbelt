#!/usr/bin/env python3
"""Führt synthetische Verhaltenstests der echten PowerShell-Labauswahl aus."""

from pathlib import Path
import shutil
import subprocess
import sys


def run_hidden(*args, **kwargs):
    """Preserve subprocess results while suppressing Windows console creation."""
    if sys.platform == "win32":
        kwargs["creationflags"] = kwargs.get("creationflags", 0) | subprocess.CREATE_NO_WINDOW
    return subprocess.run(*args, **kwargs)



ROOT = Path(__file__).resolve().parents[2]
pwsh = shutil.which("pwsh")
if pwsh is None:
    raise SystemExit("Lab selector tests NOT_EXECUTED: PowerShell 7 (pwsh) fehlt")

result = run_hidden([
    pwsh, "-NoLogo", "-NoProfile", "-File",
    str(ROOT / "Tests/CI/test-lab-selector.ps1"),
], cwd=ROOT, check=False)
if result.returncode:
    raise SystemExit(result.returncode)
result = run_hidden([
    pwsh, "-NoLogo", "-NoProfile", "-File",
    str(ROOT / "Tests/CI/test-lab-qualified-contract.ps1"),
], cwd=ROOT, check=False)
if result.returncode:
    raise SystemExit(result.returncode)
for test in ("test_lab_tls.py", "test_lab_cleanup.py"):
    result = run_hidden([sys.executable, "-B", str(ROOT / "Tests/CI" / test)], cwd=ROOT, check=False)
    if result.returncode:
        raise SystemExit(result.returncode)
