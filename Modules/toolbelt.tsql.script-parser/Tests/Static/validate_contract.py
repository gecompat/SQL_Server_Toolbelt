#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.tsql.script-parser."""

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
    project = ET.parse(ROOT / "Clr/Toolbelt.Tsql.ScriptParser.csproj").getroot()
    framework = project.findtext(".//m:TargetFrameworkVersion", namespaces=NS)
    if framework != "v4.8":
        raise ContractError("CLR-Projekt muss .NET Framework 4.8 verwenden.")
    references = {
        item.attrib.get("Include", "").split(",", 1)[0]
        for item in project.findall(".//m:Reference", NS)
    }
    expected = {"System", "System.Core", "System.Data", "System.Xml", "Microsoft.SqlServer.TransactSql.ScriptDom"}
    if references != expected:
        raise ContractError(f"Unerwartete direkte Referenzen: {sorted(references)}")


def main() -> int:
    required = (
        "Clr/Toolbelt.Tsql.ScriptParser.csproj",
        "Clr/Properties/AssemblyInfo.cs",
        "Clr/ScriptParserProvider.cs",
        "Source/TVF_ParseScriptNodes.sql",
        "Source/TVF_ParseScriptNodeProperties.sql",
        "Source/TVF_TokenizeScript.sql",
        "Source/TVF_ParseScriptErrors.sql",
        "Deployment/Add-TrustedAssembly.sql",
        "Deployment/Deploy.sql",
        "Deployment/Uninstall.sql",
        "Scripts/New-ClrReleaseArtifacts.ps1",
        "Documentation/TVF_ParseScriptNodes.md",
        "Documentation/TVF_ParseScriptNodeProperties.md",
        "Documentation/TVF_TokenizeScript.md",
        "Documentation/TVF_ParseScriptErrors.md",
        "Examples/ScriptParser.sql",
        "Tests/Runtime/ScriptParser.Contract.sql",
        "Tests/Runtime/Lifecycle.Contract.sql",
        "Tests/Runtime/Central.Contract.sql",
        "Tests/TSQL_SCRIPT_PARSER_CONTRACT_TEST_MATRIX.md",
        "Tests/README.md",
        "README.md",
        "module.yaml",
    )
    for relative in required:
        read(relative)
    validate_project()

    provider = read("Clr/ScriptParserProvider.cs")
    require(
        provider,
        "CLR-Provider",
        "DefaultMaxNestingDepth",
        "ParseScriptNodes",
        "ParseScriptNodeProperties",
        "TokenizeScript",
        "ParseScriptErrors",
        "FillNodeRow",
        "FillPropertyRow",
        "FillTokenRow",
        "FillErrorRow",
        "TSql160Parser",
        "TBX_TSQLPARSE_MAX_DEPTH_EXCEEDED",
        "TBX_TSQLPARSE_INPUT_TOO_LARGE",
    )
    forbid(
        provider,
        "CLR-Provider",
        "System.Net.",
        "System.Diagnostics.Process",
        "Microsoft.Win32.Registry",
        "DllImport",
    )

    deploy = read("Deployment/Deploy.sql")
    require(
        deploy,
        "Deploy-Skript",
        ":On Error exit",
        "SET XACT_ABORT ON;",
        "sp_getapplock",
        "Toolbelt.Module.toolbelt.tsql.script-parser.Version",
        "Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode",
        "WITH PERMISSION_SET = UNSAFE;",
        ":r ../Source/TVF_ParseScriptNodes.sql",
        ":r ../Source/TVF_ParseScriptNodeProperties.sql",
        ":r ../Source/TVF_TokenizeScript.sql",
        ":r ../Source/TVF_ParseScriptErrors.sql",
    )
    if deploy.count("$(AssemblyBits)") != 1:
        raise ContractError("Deploy.sql muss genau einen $(AssemblyBits)-Platzhalter enthalten.")

    trust = read("Deployment/Add-TrustedAssembly.sql")
    require(
        trust,
        "Trust-Skript",
        ":On Error exit",
        "sys.sp_add_trusted_assembly",
        "clr enabled",
        "clr strict security",
        "IS_SRVROLEMEMBER(N'sysadmin')",
    )

    uninstall = read("Deployment/Uninstall.sql")
    require(
        uninstall,
        "Uninstall-Skript",
        ":On Error exit",
        "$(ConfirmNoExternalConsumers)",
        "DROP ASSEMBLY [Toolbelt_Tsql_ScriptParser];",
        "sys.sql_expression_dependencies",
    )
    forbid(
        uninstall,
        "Uninstall-Skript",
        "sp_drop_trusted_assembly",
    )

    manifest = read("module.yaml")
    require(
        manifest,
        "module.yaml",
        'module_id: "toolbelt.tsql.script-parser"',
        'schema: "toolbelt_tsql"',
        'name: "TVF_ParseScriptNodes"',
        'name: "TVF_ParseScriptNodeProperties"',
        'name: "TVF_TokenizeScript"',
        'name: "TVF_ParseScriptErrors"',
        'permission_set: "UNSAFE"',
    )

    print("toolbelt.tsql.script-parser: statische Vertragsprüfung erfolgreich.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ContractError as error:
        print(f"toolbelt.tsql.script-parser: FEHLER: {error}", file=sys.stderr)
        sys.exit(1)
