"""Test the frozen SSIS evidence at the last revision to which it applies."""
from functools import lru_cache
import os
from pathlib import Path
import subprocess

BASELINE = "763d46d4eafa79394399d51aec7d3ab90d0dad0c"
FROZEN_PATHS = (
    "Modules/toolbelt.tsql.ssis-debug/Tests/Qualification",
    "Modules/toolbelt.tsql.ssis-debug/InstallPackages",
    "Releases/1.0.0/ssis-*",
    "Releases/1.0.0/SSIS-INSTALL-TSQL*",
    "Releases/1.0.0/parameter-help-qualification.json",
    "Releases/1.0.0/InstallPackages/SQL-Server-Toolbelt-1.0.0-Parameter-Help.zip*",
)


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True, timeout=120)


def is_reparse_point(path):
    return path.is_symlink() or bool(getattr(path.stat(), "st_file_attributes", 0) & 0x400)


@lru_cache(maxsize=1)
def historical_root(root):
    root = Path(root).resolve()
    paths = [path for path in git(root, "ls-tree", "-r", "--name-only", BASELINE, "--", *FROZEN_PATHS[:2]).splitlines()
             if path.endswith((".json", ".zip", ".zip.sha256"))]
    paths.extend(path for path in git(root, "ls-tree", "-r", "--name-only", BASELINE, "--",
                                      "Releases/1.0.0").splitlines()
                 if any(Path(path).match(pattern) for pattern in FROZEN_PATHS[2:]))
    if not paths:
        raise ValueError("SSIS historical evidence inventory missing")
    git(root, "diff", "--quiet", BASELINE, "--", *paths)
    runtime = root / ".runtime"
    runtime.mkdir(exist_ok=True)
    if is_reparse_point(runtime):
        raise ValueError("SSIS historical worktree parent is redirected")
    checkout = runtime / ("ssis-historical-" + BASELINE[:8])
    if not os.path.lexists(checkout):
        git(root, "worktree", "add", "--detach", "--quiet", str(checkout), BASELINE)
    if (is_reparse_point(checkout) or Path(git(checkout, "rev-parse", "--show-toplevel").strip()).resolve() != checkout
            or git(checkout, "rev-parse", "HEAD").strip() != BASELINE
            or git(checkout, "status", "--porcelain", "--untracked-files=all")):
        raise ValueError("SSIS historical worktree differs from its baseline")
    return checkout
