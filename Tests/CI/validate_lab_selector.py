#!/usr/bin/env python3
"""Static safeguards for the local SQL_Server_Lab target-selection policy."""

from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
RUNNER = ROOT / "Tests" / "CI" / "run-lab-local.ps1"
AGENTS = ROOT / "AGENTS.md"
README = ROOT / "Tests" / "CI" / "README.md"


def require(text: str, fragment: str, source: Path) -> None:
    if fragment not in text:
        raise SystemExit(f"Missing selector safeguard in {source}: {fragment!r}")


runner = RUNNER.read_text(encoding="utf-8")
agents = AGENTS.read_text(encoding="utf-8")
readme = README.read_text(encoding="utf-8")

require(runner, "function Get-LabTargetsForSelector", RUNNER)
require(runner, "[string]$Selector.Patch -ceq 'base'", RUNNER)
require(runner, "-match '^CU[0-9]+$'", RUNNER)
require(runner, "Sort-Object", RUNNER)
require(runner, "return @($baseTargets + $cuTargets)", RUNNER)
require(runner, "[string]$_.patch -ceq [string]$Selector.Patch", RUNNER)
require(agents, "Windows-Tests mit\n`patch = base`", AGENTS)
require(agents, "deterministisch gemeinsam ausgeführt", AGENTS)
require(readme, "Patchäquivalenz", README)
require(readme, "explizit angefordertes `CU<n>` bleibt exakt", README)

print("Local SQL_Server_Lab selector static safeguards: passed")
