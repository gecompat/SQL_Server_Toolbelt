"""Prüft sichtbare Fenster und Prozessvererbung der lokalen Hidden-Startkette."""
from __future__ import annotations

import ctypes
import os
import subprocess
import sys


def console_handle() -> int:
    if os.name != "nt":
        raise RuntimeError("HIDDEN_PROBE_WINDOWS_ONLY")
    kernel = ctypes.WinDLL("kernel32", use_last_error=True)
    function = kernel.GetConsoleWindow
    function.restype = ctypes.c_void_p
    return int(function() or 0)


def validate_process() -> None:
    if console_handle() != 0:
        raise RuntimeError("HIDDEN_PROBE_CONSOLE_PRESENT")
    if not getattr(subprocess.Popen, "_codex_hidden_init", False):
        raise RuntimeError("HIDDEN_PROBE_HOOK_MISSING")
    if (os.environ.get("GIT_TERMINAL_PROMPT") != "0" or
            os.environ.get("GCM_INTERACTIVE") != "Never" or
            os.environ.get("GH_PROMPT_DISABLED") != "1"):
        raise RuntimeError("HIDDEN_PROBE_NONINTERACTIVE_FLAGS")


def main() -> int:
    try:
        validate_process()
        process_type = subprocess.Popen
        child_env = os.environ.copy()
        for name in ("PYTHONPATH", "GIT_TERMINAL_PROMPT", "GCM_INTERACTIVE", "GH_PROMPT_DISABLED"):
            child_env.pop(name, None)
        process = subprocess.Popen(
            [sys.executable, __file__, "leaf"], env=child_env,
            creationflags=subprocess.CREATE_NEW_CONSOLE,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
        )
        if not isinstance(process, process_type):
            raise RuntimeError("HIDDEN_PROBE_PROCESS_CLASS_CHANGED")
        stdout, stderr = process.communicate(timeout=30)
        if process.returncode != 0 or stderr or stdout.strip() != "PASS LEAF WINDOW=0":
            raise RuntimeError("HIDDEN_PROBE_GRANDCHILD_FAILED")
        try:
            subprocess.Popen([sys.executable, "-I", "-c", "pass"])
        except RuntimeError as error:
            if str(error) != "HIDDEN_PYTHON_ISOLATED_CHILD_UNSUPPORTED":
                raise
        else:
            raise RuntimeError("HIDDEN_PROBE_ISOLATED_CHILD_ACCEPTED")
        print("PASS HIDDEN_CHAIN WINDOW=0 CHILD_ENV=REBOUND CLASS=PRESERVED ISOLATED=REJECTED")
        return 0
    except Exception:
        print("HIDDEN_PROCESS_PROBE_FAILED", file=sys.stderr)
        return 1


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "leaf":
        try:
            validate_process()
            print("PASS LEAF WINDOW=0")
            raise SystemExit(0)
        except Exception:
            raise SystemExit(1)
    raise SystemExit(main())
