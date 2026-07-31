#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.archive.zip-memory."""

from __future__ import annotations

import re
import struct
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPO = ROOT.parents[1]
NS = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}


class ContractError(RuntimeError):
    """Meldet eine belastbare Vertragsabweichung."""


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
    project = ET.parse(ROOT / "Clr/Toolbelt.Archive.ZipMemory.csproj").getroot()
    framework = project.findtext(".//m:TargetFrameworkVersion", namespaces=NS)
    if framework != "v4.8":
        raise ContractError("CLR-Projekt muss .NET Framework 4.8 verwenden.")

    references = {
        item.attrib.get("Include", "").split(",", 1)[0]
        for item in project.findall(".//m:Reference", NS)
    }
    if references != {"System", "System.Data"}:
        raise ContractError(
            "Direkte CLR-Referenzen müssen exakt System und System.Data sein: "
            f"{sorted(references)}"
        )

    compile_files = {
        item.attrib.get("Include")
        for item in project.findall(".//m:Compile", NS)
    }
    expected = {"Properties\\AssemblyInfo.cs", "ZipEntryProvider.cs"}
    if compile_files != expected:
        raise ContractError("CLR-Projekt enthält ein unerwartetes Compile-Inventar.")


def validate_zip_fixtures(relative: str) -> None:
    values = re.findall(r"0x([0-9A-Fa-f]+)", read(relative))
    archives = [value for value in values if value.upper().startswith("504B0304")]
    if not archives:
        raise ContractError(f"Synthetische ZIP-Fixture fehlt: {relative}")

    for value in archives:
        archive = bytes.fromhex(value)
        eocd = archive.rfind(b"PK\x05\x06")
        if eocd < 0 or eocd + 22 > len(archive):
            raise ContractError(f"Unvollständiges EOCD: {relative}")
        comment_length = struct.unpack_from("<H", archive, eocd + 20)[0]
        central_size, central_offset = struct.unpack_from("<II", archive, eocd + 12)
        if eocd + 22 + comment_length != len(archive):
            raise ContractError(f"Inkonsistente EOCD-Länge: {relative}")
        if central_offset + central_size != eocd:
            raise ContractError(f"Inkonsistente Central-Directory-Grenzen: {relative}")
        if archive[central_offset : central_offset + 4] != b"PK\x01\x02":
            raise ContractError(f"Central-Directory-Header fehlt: {relative}")


def main() -> int:
    required = (
        "Clr/Toolbelt.Archive.ZipMemory.csproj",
        "Clr/Properties/AssemblyInfo.cs",
        "Clr/ZipEntryProvider.cs",
        "Source/TVF_InternalExtractZipEntryClr.sql",
        "Source/USP_ExtractZipEntryFromBinary.sql",
        "Deployment/Add-TrustedAssembly.sql",
        "Deployment/Deploy.sql",
        "Deployment/Uninstall.sql",
        "Scripts/New-ClrReleaseArtifacts.ps1",
        "Examples/ExtractZipEntryFromBinary.sql",
        "README.md",
        "Documentation/USP_ExtractZipEntryFromBinary.md",
        "Tests/ZIP_MEMORY_CONTRACT_TEST_MATRIX.md",
        "Tests/README.md",
        "Tests/Runtime/ZipMemory.Contract.sql",
        "Tests/Runtime/Encoding.Contract.sql",
        "Tests/Runtime/Lifecycle.Contract.sql",
        "Tests/Runtime/Central.Contract.sql",
        "module.yaml",
    )
    missing = [path for path in required if not (ROOT / path).is_file()]
    if missing:
        raise ContractError("Fehlende Artefakte: " + ", ".join(missing))

    validate_project()

    provider = read("Clr/ZipEntryProvider.cs")
    require(
        provider,
        "CLR-Provider",
        "[SqlFunction(",
        'FillRowMethodName = "FillRow"',
        "new DeflateStream(",
        "CompressionMode.Decompress",
        "ComputeCrc32",
        "CentralHeaderSignature",
        "LocalHeaderSignature",
        "EndOfCentralDirectorySignature",
        "MaxArchiveBytes = 268435456L",
        "MaxCompressedBytes = 134217728L",
        "MaxEntries = 10000",
        "StringComparison.Ordinal",
        "new UTF8Encoding(false, true)",
        "Encoding.GetEncoding(",
        "payload.LongLength != entry.UncompressedBytes",
        "actualCrc32 != entry.Crc32",
        "compressed.Remaining != 0",
    )
    for number in range(51320, 51329):
        require(provider, "CLR-Provider", str(number))
    forbid(
        provider,
        "CLR-Provider",
        "new ZipArchive(",
        "System.IO.File.",
        "new FileStream(",
        "System.IO.Directory.",
        "System.Diagnostics.Process",
        "System.Net.",
        "Microsoft.Win32.Registry",
    )

    internal_tvf = read("Source/TVF_InternalExtractZipEntryClr.sql")
    require(
        internal_tvf,
        "interner CLR-TVF",
        "CREATE FUNCTION [toolbelt_archive].[TVF_InternalExtractZipEntryClr]",
        "RETURNS TABLE",
        "AS EXTERNAL NAME",
        "[Toolbelt_Archive_ZipMemory]",
        "[Toolbelt.Archive.ZipMemory.ZipEntryProvider]",
        "[ExtractZipEntry]",
    )

    source = read("Source/USP_ExtractZipEntryFromBinary.sql")
    require(
        source,
        "öffentliche Procedure",
        "CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ExtractZipEntryFromBinary]",
        "@ZipArchive          varbinary(max) = NULL",
        "@MaxEntryBytes       bigint         = 104857600",
        "@MaxCompressionRatio decimal(9,2)   = 200.00",
        "TVF_InternalExtractZipEntryClr",
        "THROW @ProviderErrorNumber",
        "BETWEEN 51320 AND 51329",
        "toolbelt_core.USP_PrepareResultTable",
        "Methods 0 und 8",
        "ZIP64",
    )
    forbid(source, "öffentliche Procedure", "OPENROWSET", "xp_cmdshell")

    deploy = read("Deployment/Deploy.sql")
    if deploy.count("$(AssemblyBits)") != 1:
        raise ContractError("Deploy.sql muss genau einen AssemblyBits-Platzhalter enthalten.")
    require(
        deploy,
        "Deployment",
        "HASHBYTES(N'SHA2_512', @AssemblyBits)",
        "@InstalledAssemblyHash",
        "sys.assembly_files",
        "sys.trusted_assemblies",
        "CREATE ASSEMBLY [Toolbelt_Archive_ZipMemory]",
        "ALTER ASSEMBLY [Toolbelt_Archive_ZipMemory]",
        "WITH PERMISSION_SET = SAFE",
        ":r ../Source/TVF_InternalExtractZipEntryClr.sql",
        ":r ../Source/USP_ExtractZipEntryFromBinary.sql",
        "@InstalledVersion NOT IN (N'1.0.0', N'1.1.0')",
        "@value = N'1.1.0'",
        "sp_getapplock",
    )
    forbid(
        deploy,
        "Deployment",
        "sp_add_trusted_assembly",
        "sp_configure",
        "TRUSTWORTHY ON",
        "EXTERNAL_ACCESS",
        "PERMISSION_SET = UNSAFE",
    )

    trust = read("Deployment/Add-TrustedAssembly.sql")
    require(
        trust,
        "Trust-Opt-in",
        "sys.sp_add_trusted_assembly",
        "sys.trusted_assemblies",
        "clr strict security",
        "clr enabled",
        "SHA2-512",
    )
    forbid(trust, "Trust-Opt-in", "sp_configure", "TRUSTWORTHY ON")

    uninstall = read("Deployment/Uninstall.sql")
    require(
        uninstall,
        "Uninstall",
        "DROP PROCEDURE IF EXISTS",
        "DROP FUNCTION IF EXISTS",
        "DROP ASSEMBLY [Toolbelt_Archive_ZipMemory]",
        "sys.assembly_modules",
        "sys.assembly_references",
        "ConfirmNoExternalConsumers",
    )
    forbid(uninstall, "Uninstall", "sp_drop_trusted_assembly")

    build = read("Scripts/New-ClrReleaseArtifacts.ps1")
    require(
        build,
        "Release-Artefaktskript",
        "Toolbelt.Archive.ZipMemory.csproj",
        "Get-FileHash -Algorithm SHA512",
        "Deploy.WithAssembly.sql",
        "Toolbelt.Archive.ZipMemory.trust-manifest.json",
        "@('System', 'System.Data')",
    )

    manifest = read("module.yaml")
    require(
        manifest,
        "Manifest",
        'version: "1.1.0"',
        'validation_status: "partially validated"',
        'linux: "partially validated"',
        'windows: "not executed"',
        "id: clr-zip-memory",
        "type: CLR_TVF",
        'name: "Toolbelt_Archive_ZipMemory"',
        'permission_set: "SAFE"',
        'workflow: "https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206"',
    )

    runtime = read("Tests/Runtime/ZipMemory.Contract.sql")
    require(
        runtime,
        "Runtime-Contract",
        "CompressionMethod = 0",
        "CompressionMethod = 8",
        "descriptor.txt",
        "Grüße.txt",
        "@ZipDuplicate",
        "@ZipEncrypted",
        "@ZipBadCrc",
        "@ZipUnsupported",
        "@Zip64Sentinel",
        "@ZipLocalNameMismatch",
        "@ZipRatio",
    )
    for number in range(51320, 51329):
        require(runtime, "Runtime-Contract", f"ERROR_NUMBER() <> {number}")

    encoding = read("Tests/Runtime/Encoding.Contract.sql")
    require(encoding, "Encoding-Contract", "0x477281E1652E747874", "N'Grüße.txt'", "CP437")

    for fixture in (
        "Tests/Runtime/ZipMemory.Contract.sql",
        "Tests/Runtime/Encoding.Contract.sql",
        "Tests/Runtime/Central.Contract.sql",
        "Examples/ExtractZipEntryFromBinary.sql",
    ):
        validate_zip_fixtures(fixture)

    workflow = (REPO / ".github/workflows/zip-memory-runtime.yml").read_text(encoding="utf-8")
    require(
        workflow,
        "Runtime-Workflow",
        "mcr.microsoft.com/mssql/server:2019-latest",
        "mcr.microsoft.com/mssql/server:2022-latest",
        "mcr.microsoft.com/mssql/server:2025-latest",
        "compatibility_level: 150",
        "compatibility_level: 160",
        "compatibility_level: 170",
        "New-ClrReleaseArtifacts.ps1",
    )
    if "Documentation/**" in workflow:
        raise ContractError("Runtime-Workflow darf nicht auf reine Dokumentation triggern.")

    print("ZIP-Memory CLR statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (ContractError, ValueError) as error:
        print(f"ZIP-Memory CLR statische Vertragsprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
