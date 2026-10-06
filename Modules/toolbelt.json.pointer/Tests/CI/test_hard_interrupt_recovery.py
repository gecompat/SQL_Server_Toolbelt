#!/usr/bin/env python3
"""Manual, isolated owner-label cleanup probe after killing its container-owning child."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import secrets
import shutil
import subprocess
import sys
import tempfile
import time


IMAGE = "mcr.microsoft.com/mssql/server:2019-latest"
LABEL = "tbx.pointer.recovery.owner"
CASES = ("before-cid", "after-cid")


class ProbeError(Exception):
    pass


def docker(args: list[str], timeout: int = 20) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            ["docker", *args], text=True, errors="replace",
            capture_output=True, timeout=timeout, check=False,
        )
    except (OSError, subprocess.TimeoutExpired) as error:
        raise ProbeError("Docker-Aufruf unbestätigt") from error


def label_for(name: str) -> str | None:
    result = docker([
        "container", "inspect", "--format",
        '{{index .Config.Labels "' + LABEL + '"}}', name,
    ])
    return result.stdout.strip() if result.returncode == 0 else None


def absent(name: str) -> bool:
    result = docker([
        "container", "ls", "--all", "--filter", f"name=^{name}$",
        "--format", "{{.ID}}",
    ])
    if result.returncode != 0:
        raise ProbeError("Docker-Abwesenheitsaudit unbestätigt")
    return not result.stdout.strip()


def recover(name: str, owner: str) -> bool:
    if label_for(name) != owner:
        return False
    removed = docker(["rm", "-f", name], timeout=30)
    if removed.returncode != 0:
        raise ProbeError("Eigene Containerentfernung unbestätigt")
    return absent(name)


def child(journal: Path, case: str) -> int:
    record = json.loads(journal.read_text(encoding="utf-8"))
    name, owner = record["name"], record["owner"]
    private = journal.parent
    args = [
        "run", "--detach", "--pull", "never", "--network", "none",
        "--name", name, "--label", f"{LABEL}={owner}",
        "--entrypoint", "/bin/sh",
    ]
    if case == "after-cid":
        args += ["--cidfile", str(private / "cid")]
    args += [IMAGE, "-c", "sleep 300"]
    result = docker(args, timeout=40)
    if result.returncode != 0:
        return 1
    if case == "after-cid" and not (private / "cid").is_file():
        return 1
    if case == "before-cid" and (private / "cid").exists():
        return 1
    (private / "ready").write_text("ready", encoding="ascii")
    # Der Elternprozess beendet uns hart. Keine lokale finally-/Trap-Bereinigung.
    while True:
        time.sleep(1)


def one_case(case: str) -> None:
    owner = secrets.token_hex(16)
    name = f"tbx-pointer-recovery-{owner}"
    private = Path(tempfile.mkdtemp(prefix="tbx-pointer-recovery-"))
    journal = private / "owner.json"
    journal.write_text(json.dumps({"owner": owner, "name": name}), encoding="utf-8")
    process: subprocess.Popen[str] | None = None
    cleaned = False
    try:
        process = subprocess.Popen([
            sys.executable, str(Path(__file__).resolve()), "--child",
            "--journal", str(journal), "--case", case,
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        deadline = time.monotonic() + 50
        while not (private / "ready").is_file():
            if process.poll() is not None:
                raise ProbeError("Kindprozess vor Abbruch ausgefallen")
            if time.monotonic() >= deadline:
                raise ProbeError("Kindprozess nicht bereit")
            time.sleep(0.2)
        if label_for(name) != owner:
            raise ProbeError("Containeridentität vor Abbruch unbestätigt")
        if case == "before-cid" and (private / "cid").exists():
            raise ProbeError("Vor-CID-Fall verletzt")
        if case == "after-cid" and not (private / "cid").is_file():
            raise ProbeError("Nach-CID-Fall verletzt")
        process.kill()
        process.wait(timeout=10)
        if process.returncode == 0:
            raise ProbeError("Kindprozess wurde nicht hart beendet")
        if recover(name, "wrong-owner") or label_for(name) != owner:
            raise ProbeError("Fremd-Owner-Kontrolle fehlgeschlagen")
        cleaned = recover(name, owner)
        if not cleaned or not absent(name):
            raise ProbeError("Frischer Cleanup-Audit fehlgeschlagen")
        print(f"PASS: Pointer {case} local hard-child-kill owner recovery")
    finally:
        if process is not None and process.poll() is None:
            process.kill()
            process.wait(timeout=10)
        if not cleaned:
            # Fehlerpfad darf nur den zuvor eindeutig eigenen Container anfassen.
            try:
                cleaned = recover(name, owner) or absent(name)
            except ProbeError:
                cleaned = False
        if cleaned:
            shutil.rmtree(private)
        else:
            print("INCONCLUSIVE: privates Owner-Journal für manuelle Zuordnung erhalten",
                  file=sys.stderr)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--child", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--journal", type=Path, help=argparse.SUPPRESS)
    parser.add_argument("--case", choices=CASES, help=argparse.SUPPRESS)
    options = parser.parse_args()
    if options.child:
        if options.journal is None or options.case is None:
            parser.error("Kindprozess benötigt Journal und Fall")
        return child(options.journal, options.case)
    if options.journal is not None or options.case is not None:
        parser.error("Journal und Fall sind interne Kindprozessparameter")
    if os.environ.get("TBX_SQL_TARGET", "runner") != "runner":
        parser.error("Nur eigene flüchtige Container sind zulässig")
    if shutil.which("docker") is None or docker(["image", "inspect", IMAGE]).returncode != 0:
        raise ProbeError("Lokales Docker oder bereits vorhandenes Testimage fehlt")
    for case in CASES:
        one_case(case)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ProbeError as error:
        print(f"INCONCLUSIVE: {error}", file=sys.stderr)
        sys.exit(2)
