#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.string.regex."""

from __future__ import annotations

import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
NS = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}


class ContractError(RuntimeError):
    pass


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise ContractError(f"Pflichtartefakt fehlt: {relative}")
    return path.read_text(encoding="utf-8")


def require(content: str, source: str, *markers: str) -> None:
    for marker in markers:
        if marker not in content:
            raise ContractError(f"{source}: Marker fehlt: {marker}")


def forbid(content: str, source: str, *markers: str) -> None:
    lowered = content.lower()
    for marker in markers:
        if marker.lower() in lowered:
            raise ContractError(f"{source}: unzulässiger Marker: {marker}")


def validate_project() -> None:
    project = ET.parse(ROOT / "Clr/Toolbelt.String.Regex.csproj").getroot()
    framework = project.findtext(".//m:TargetFrameworkVersion", namespaces=NS)
    if framework != "v4.8":
        raise ContractError("CLR-Projekt muss .NET Framework 4.8 verwenden.")
    references = {
        item.attrib.get("Include", "").split(",", 1)[0]
        for item in project.findall(".//m:Reference", NS)
    }
    if references != {"System", "System.Data"}:
        raise ContractError(f"Unerwartete direkte Referenzen: {sorted(references)}")


def main() -> int:
    required = (
        "Clr/Toolbelt.String.Regex.csproj",
        "Clr/Properties/AssemblyInfo.cs",
        "Clr/RegexProvider.cs",
        "Source/RegexFunctions.sql",
        "Deployment/Add-TrustedAssembly.sql",
        "Deployment/Deploy.sql",
        "Deployment/Uninstall.sql",
        "Scripts/New-ClrReleaseArtifacts.ps1",
        "Documentation/REGEX_FUNCTIONS.md",
        "Examples/Regex.sql",
        "Tests/Runtime/Regex.Contract.sql",
        "Tests/Runtime/Lifecycle.Contract.sql",
        "Tests/Runtime/Central.Contract.sql",
        "Tests/REGEX_CONTRACT_TEST_MATRIX.md",
        "Tests/README.md",
        "README.md",
        "module.yaml",
    )
    for relative in required:
        read(relative)
    validate_project()

    provider = read("Clr/RegexProvider.cs")
    require(
        provider,
        "CLR-Provider",
        "TimeSpan.FromMilliseconds(250)",
        "MaxInputCodeUnits = 1048576",
        "MaxPatternBytes = 8000",
        "MaxQuantifier = 1000",
        "TranslatePattern",
        "AppendCharacterClass",
        "AppendBoundedQuantifier",
        '"[0-9]"',
        '"[A-Za-z0-9_]"',
        '"\\\\p{L}"',
        "RegexOptions.CultureInvariant",
        "RegexMatchTimeoutException",
        "TBX_REGEX_INVALID_PATTERN",
        "TBX_REGEX_TIMEOUT",
    )
    forbid(
        provider,
        "CLR-Provider",
        "System.IO.",
        "System.Net.",
        "System.Diagnostics.Process",
        "Microsoft.Win32.Registry",
        "RegexOptions.Compiled",
        "DllImport",
    )

    source = read("Source/RegexFunctions.sql")
    require(
        source,
        "SQL-Funktionen",
        "SVF_RegexIsMatch",
        "SVF_RegexInstr",
        "SVF_RegexCount",
        "CALLED ON NULL INPUT",
        "[Toolbelt_String_Regex]",
        "[Toolbelt.String.Regex.RegexProvider]",
        "@Pattern nvarchar(max)",
        "@Flags   nvarchar(4) = N'c'",
    )

    deploy = read("Deployment/Deploy.sql")
    if deploy.count("$(AssemblyBits)") != 1:
        raise ContractError("Deploy.sql benötigt genau einen AssemblyBits-Platzhalter.")
    require(
        deploy,
        "Deployment",
        "HASHBYTES(N'SHA2_512', @AssemblyBits)",
        "sys.trusted_assemblies",
        "WITH PERMISSION_SET = SAFE",
        ":r ../Source/RegexFunctions.sql",
        "sp_getapplock",
        "Toolbelt.ModuleVersion",
    )
    forbid(deploy, "Deployment", "sp_configure", "TRUSTWORTHY ON", "UNSAFE", "EXTERNAL_ACCESS")

    trust = read("Deployment/Add-TrustedAssembly.sql")
    require(trust, "Trust", "sys.sp_add_trusted_assembly", "SHA2-512", "clr strict security")
    forbid(trust, "Trust", "sp_configure", "TRUSTWORTHY ON")

    uninstall = read("Deployment/Uninstall.sql")
    require(uninstall, "Uninstall", "DROP FUNCTION IF EXISTS", "DROP ASSEMBLY", "ConfirmNoExternalConsumers")
    forbid(uninstall, "Uninstall", "sp_drop_trusted_assembly")

    build = read("Scripts/New-ClrReleaseArtifacts.ps1")
    require(build, "Build", "Get-FileHash -Algorithm SHA512", "Deploy.WithAssembly.sql", "Toolbelt.String.Regex.trust-manifest.json", "@('System', 'System.Data')")

    manifest = read("module.yaml")
    require(manifest, "Manifest", 'version: "1.0.0"', "validation_status: validated", 'permission_set: "SAFE"', "third_party_dependencies: []", 'workflow: "local: Tests/CI/run-lab-local.ps1"')

    runtime = read("Tests/Runtime/Regex.Contract.sql")
    require(runtime, "Runtime", "TBX_REGEX_INVALID_PATTERN", "TBX_REGEX_TIMEOUT", "1048577", "4001", "N'^(a|aa)+$'")
    print("Regex statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(f"Regex statische Vertragsprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
