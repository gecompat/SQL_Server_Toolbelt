"""Startet Python-Kindprozesse mit prozesslokaler Fensterunterdrückung."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--python", required=True)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = list(args.arguments)
    if command and command[0] == "--":
        command.pop(0)
    if not command:
        raise SystemExit("HIDDEN_PYTHON_ARGUMENTS_REQUIRED")
    for token in command:
        if token == "--":
            break
        if token.startswith("-") and (any(flag in token[1:] for flag in "IES") or
                                        token.split("=", 1)[0] in ("--isolated", "--ignore-environment", "--no-site")):
            raise SystemExit("HIDDEN_PYTHON_ISOLATED_MODE_UNSUPPORTED")
        if not token.startswith("-"):
            break

    root = args.root.resolve(strict=True)
    runtime = root / ".runtime"
    for part in (runtime,):
        if part.is_symlink() or (part.exists() and not part.is_dir()):
            raise SystemExit("HIDDEN_PYTHON_RUNTIME_SCOPE")
    runtime.mkdir(parents=True, exist_ok=True)
    for part in (runtime,):
        if part.is_symlink() or not part.is_dir():
            raise SystemExit("HIDDEN_PYTHON_RUNTIME_SCOPE")
    with tempfile.TemporaryDirectory(prefix="hidden-python-", dir=runtime) as temp:
        site = Path(temp) / "sitecustomize.py"
        source = (
            "import os, subprocess\n"
            "if os.name == 'nt':\n"
            "    import inspect\n"
            "    _class = subprocess.Popen\n"
            "    if not getattr(_class, '_codex_hidden_init', False):\n"
            "        _original_init = _class.__init__\n"
            "        _signature = inspect.signature(_original_init)\n"
            "        def _hidden_init(self, *popen_args, **kwargs):\n"
            "            bound = _signature.bind_partial(self, *popen_args, **kwargs)\n"
            "            command = bound.arguments.get('args', popen_args[0] if popen_args else ())\n"
            "            if bound.arguments.get('shell', False) or isinstance(command, str):\n"
            "                raise RuntimeError('HIDDEN_PYTHON_UNSAFE_COMMAND')\n"
            "            executable = bound.arguments.get('executable')\n"
            "            if executable is None and isinstance(command, (list, tuple)) and command:\n"
            "                executable = command[0]\n"
            "            if executable and os.path.basename(os.fspath(executable)).lower().startswith('python') and isinstance(command, (list, tuple)):\n"
            "                for token in command[1:]:\n"
            "                    if token in ('-c', '-m') or not str(token).startswith('-'):\n"
            "                        break\n"
            "                    if (any(flag in str(token)[1:] for flag in 'IES') or\n"
            "                        str(token).split('=', 1)[0] in ('--isolated', '--ignore-environment', '--no-site')):\n"
            "                        raise RuntimeError('HIDDEN_PYTHON_ISOLATED_CHILD_UNSUPPORTED')\n"
            "            child_env = bound.arguments.get('env')\n"
            "            child_env = os.environ.copy() if child_env is None else child_env.copy()\n"
            "            site_dir = os.path.dirname(__file__)\n"
            "            inherited = child_env.get('PYTHONPATH', '')\n"
            "            child_env['PYTHONPATH'] = site_dir + os.pathsep + inherited\n"
            "            child_env['GIT_TERMINAL_PROMPT'] = '0'\n"
            "            child_env['GCM_INTERACTIVE'] = 'Never'\n"
            "            child_env['GH_PROMPT_DISABLED'] = '1'\n"
            "            bound.arguments['env'] = child_env\n"
            "            flags = bound.arguments.get('creationflags', 0)\n"
            "            flags &= ~getattr(subprocess, 'CREATE_NEW_CONSOLE', 0)\n"
            "            bound.arguments['creationflags'] = flags | subprocess.CREATE_NO_WINDOW\n"
            "            startup = bound.arguments.get('startupinfo')\n"
            "            if startup is None:\n"
            "                startup = subprocess.STARTUPINFO()\n"
            "            startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW\n"
            "            startup.wShowWindow = 0\n"
            "            bound.arguments['startupinfo'] = startup\n"
            "            return _original_init(*bound.args, **bound.kwargs)\n"
            "        _class.__init__ = _hidden_init\n"
            "        _class._codex_hidden_init = True\n"
            "os.environ['GIT_TERMINAL_PROMPT'] = '0'\n"
            "os.environ['GCM_INTERACTIVE'] = 'Never'\n"
            "os.environ['GH_PROMPT_DISABLED'] = '1'\n"
        )
        with site.open("w", encoding="utf-8", newline="\n") as stream:
            stream.write(source)
        env = os.environ.copy()
        env["PYTHONPATH"] = str(Path(temp)) + os.pathsep + env.get("PYTHONPATH", "")
        env["GIT_TERMINAL_PROMPT"] = "0"
        env["GCM_INTERACTIVE"] = "Never"
        env["GH_PROMPT_DISABLED"] = "1"
        flags = getattr(subprocess, "CREATE_NO_WINDOW", 0) if os.name == "nt" else 0
        startupinfo = None
        if os.name == "nt":
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 0
        completed = subprocess.run(
            [args.python, *command], cwd=root, env=env, capture_output=True,
            creationflags=flags, startupinfo=startupinfo, check=False,
        )
        sys.stdout.buffer.write(completed.stdout)
        sys.stderr.buffer.write(completed.stderr)
        return completed.returncode


if __name__ == "__main__":
    raise SystemExit(main())
