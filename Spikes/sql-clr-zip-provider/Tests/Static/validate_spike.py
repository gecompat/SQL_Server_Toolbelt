#!/usr/bin/env python3
"""Statische Schutz- und Kopplungspruefung des SQL-CLR-ZIP-Spikes."""

from pathlib import Path
import sys


ROOT = Path(__file__).resolve().parents[2]


def read(relative_path: str) -> str:
    return (ROOT / relative_path).read_text(encoding="utf-8")


def require(content: str, marker: str, source: str) -> None:
    if marker not in content:
        raise RuntimeError(f"{source}: erforderlicher Marker fehlt: {marker}")


def forbid(content: str, marker: str, source: str) -> None:
    if marker.lower() in content.lower():
        raise RuntimeError(f"{source}: unzulaessiger Marker gefunden: {marker}")


def main() -> int:
    project = read("Source/Toolbelt.ZipClr.Spike.csproj")
    probe = read("Source/ZipClrProbe.cs")
    trust = read("Deployment/Add-TrustedAssembly.sql")
    deploy = read("Deployment/Deploy-TestDatabase.sql")
    uninstall = read("Deployment/Uninstall-TestDatabase.sql")
    invoker = read("Scripts/Invoke-DeploymentSpike.ps1")

    require(project, "<TargetFrameworkVersion>v4.8</TargetFrameworkVersion>", "Projekt")
    require(project, '<Reference Include="System.IO.Compression" />', "Projekt")
    require(probe, "new ZipArchive(", "Probe")
    require(probe, "MemoryStream", "Probe")
    require(probe, "[SqlProcedure]", "Probe")
    require(trust, "sys.sp_add_trusted_assembly", "Trust-Skript")
    require(trust, "clr strict security", "Trust-Skript")
    require(deploy, "WITH PERMISSION_SET = SAFE", "Deployment")
    require(uninstall, "DROP ASSEMBLY", "Uninstall")
    require(invoker, "New-TrustManifest.ps1", "Invoker")
    require(invoker, "-Database $TestDatabase", "Invoker")

    for name, content in {
        "Probe": probe,
        "Trust-Skript": trust,
        "Deployment": deploy,
        "Uninstall": uninstall,
        "Invoker": invoker,
    }.items():
        for marker in ("TRUSTWORTHY ON", "EXTERNAL_ACCESS", "PERMISSION_SET = UNSAFE", "sp_configure"):
            forbid(content, marker, name)

    print("SQL-CLR-ZIP-Spike statische Pruefung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f"SQL-CLR-ZIP-Spike statische Pruefung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
