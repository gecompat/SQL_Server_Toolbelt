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
MSBUILD_NS = {"msb": "http://schemas.microsoft.com/developer/msbuild/2003"}


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise RuntimeError(f"Pflichtartefakt fehlt: {relative}")
    return path.read_text(encoding="utf-8")


def require(content: str, marker: str, source: str) -> None:
    if marker not in content:
        raise RuntimeError(f"{source}: erforderlicher Marker fehlt: {marker}")


def forbid(content: str, marker: str, source: str) -> None:
    if marker.lower() in content.lower():
        raise RuntimeError(f"{source}: unzulässiger Marker gefunden: {marker}")


def validate_project() -> None:
    project = ET.parse(ROOT / "Clr/Toolbelt.Archive.ZipMemory.csproj").getroot()
    framework = project.findtext(
        ".//msb:TargetFrameworkVersion",
        namespaces=MSBUILD_NS,
    )
    if framework != "v4.8":
        raise RuntimeError("CLR-Projekt muss .NET Framework 4.8 verwenden.")

    references = {
        element.attrib.get("Include", "").split(",", 1)[0]
        for element in project.findall(".//msb:Reference", MSBUILD_NS)
    }
    if references != {"System", "System.Data"}:
        raise RuntimeError(
            "Direkte CLR-Referenzen müssen exakt System und System.Data sein; "
            f"gefunden: {sorted(references)}"
        )

    compile_files = {
        element.attrib.get("Include")
        for element in project.findall(".//msb:Compile", MSBUILD_NS)
    }
    if compile_files != {"Properties\\AssemblyInfo.cs", "ZipEntryProvider.cs"}:
        raise RuntimeError("CLR-Projekt enthält ein unerwartetes Compile-Inventar.")


def validate_zip_fixtures(relative: str) -> None:
    fixtures = re.findall(r"0x([0-9A-Fa-f]+)", read(relative))
    archives = [value for value in fixtures if value.upper().startswith("504B0304")]
    if not archives:
        raise RuntimeError(f"Synthetische ZIP-Fixture fehlt: {relative}")

    for hex_value in archives:
        if len(hex_value) % 2:
            raise RuntimeError(f"ZIP-Fixture besitzt ungerade Hexlänge: {relative}")
        archive = bytes.fromhex(hex_value)
        eocd = archive.rfind(b"PK\x05\x06")
        if eocd < 0 or eocd + 22 > len(archive):
            raise RuntimeError(f"ZIP-Fixture besitzt kein vollständiges EOCD: {relative}")
        comment_length = struct.unpack_from("<H", archive, eocd + 20)[0]
        central_size, central_offset = struct.unpack_from("<II", archive, eocd + 12)
        if eocd + 22 + comment_length != len(archive):
            raise RuntimeError(f"EOCD-Länge ist inkonsistent: {relative}")
        if central_offset + central_size != eocd:
            raise RuntimeError(f"Central-Directory-Grenzen sind inkonsistent: {relative}")
        if archive[central_offset : central_offset + 4] != b"PK\x01\x02":
            raise RuntimeError(f"Central-Directory-Header fehlt: {relative}")


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
        raise RuntimeError("Fehlende Artefakte: " + ", ".join(missing))

    validate_project()

    provider = read("Clr/ZipEntryProvider.cs")
    for marker in (
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
        "entry.CompressionMethod != 0",
        "entry.CompressionMethod != 8",
        "payload.LongLength != entry.UncompressedBytes",
        "actualCrc32 != entry.Crc32",
        "compressed.Remaining != 0",
        "51320",
        "51321",
        "51322",
        "51323",
        "51324",
        "51325",
        "51326",
        "51327",
        "51328",
    ):
        require(provider, marker, "CLR-Provider")

    for marker in (
        "new ZipArchive(",
        "System.IO.File",
        "FileStream",
        "Directory.",
        "System.Diagnostics",
        "Process.",
        "System.Net",
        "HttpClient",
        "WebRequest",
        "Socket",
        "Microsoft.Win32",
        "Registry.",
    ):
        forbid(provider, marker, "CLR-Provider")

    internal_tvf = read("Source/TVF_InternalExtractZipEntryClr.sql")
    for marker in (
        "CREATE FUNCTION [toolbelt_archive].[TVF_InternalExtractZipEntryClr]",
        "RETURNS TABLE",
        "AS EXTERNAL NAME",
        "[Toolbelt_Archive_ZipMemory]",
        "[Toolbelt.Archive.ZipMemory.ZipEntryProvider]",
        "[ExtractZipEntry]",
    ):
        require(internal_tvf, marker, "interne CLR-Tabellefunktion")

    source = read("Source/USP_ExtractZipEntryFromBinary.sql")
    for marker in (
        "CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ExtractZipEntryFromBinary]",
        "@ZipArchive          varbinary(max) = NULL",
        "@MaxEntryBytes       bigint         = 104857600",
        "@MaxCompressionRatio decimal(9,2)   = 200.00",
        "TVF_InternalExtractZipEntryClr",
        "THROW @ProviderErrorNumber",
        "BETWEEN 51320 AND 51329",
        "toolbelt_core.USP_PrepareResultTable",
        "#tbx_ZipMemory_ResultSource",
        "#tbx_ZipMemory_ResultShape",
        "Methods 0 und 8",
        "ZIP64",
        "RETURN 0",
    ):
        require(source, marker, "öffentliche Procedure")
    for marker in ("OPENROWSET", "xp_cmdshell"):
        forbid(source, marker, "öffentliche Procedure")

    deploy = read("Deployment/Deploy.sql")
    if deploy.count("$(AssemblyBits)") != 1:
        raise RuntimeError("Deploy.sql muss genau einen AssemblyBits-Platzhalter enthalten.")
    for marker in (
        "HASHBYTES(N'SHA2_512', @AssemblyBits)",
        "sys.trusted_assemblies",
        "CREATE ASSEMBLY [Toolbelt_Archive_ZipMemory]",
        "ALTER ASSEMBLY [Toolbelt_Archive_ZipMemory]",
        "WITH PERMISSION_SET = SAFE",
        ":r ../Source/TVF_InternalExtractZipEntryClr.sql",
        ":r ../Source/USP_ExtractZipEntryFromBinary.sql",
        "@InstalledVersion NOT IN (N'1.0.0', N'1.1.0')",
        "@value = N'1.1.0'",
        "sp_getapplock",
    ):
        require(deploy, marker, "Deployment")
    for marker in (
        "sp_add_trusted_assembly",
        "sp_configure",
        "TRUSTWORTHY ON",
        "EXTERNAL_ACCESS",
        "PERMISSION_SET = UNSAFE",
    ):
        forbid(deploy, marker, "Deployment")

    trust = read("Deployment/Add-TrustedAssembly.sql")
    for marker in (
        "sys.sp_add_trusted_assembly",
        "sys.trusted_assemblies",
        "clr strict security",
        "clr enabled",
        "SHA2-512",
    ):
        require(trust, marker, "Trust-Opt-in")
    for marker in ("sp_configure", "TRUSTWORTHY ON", "EXTERNAL_ACCESS", "UNSAFE"):
        forbid(trust, marker, "Trust-Opt-in")

    uninstall = read("Deployment/Uninstall.sql")
    for marker in (
        "DROP PROCEDURE IF EXISTS",
        "DROP FUNCTION IF EXISTS",
        "DROP ASSEMBLY [Toolbelt_Archive_ZipMemory]",
        "sys.assembly_modules",
        "sys.assembly_references",
        "ConfirmNoExternalConsumers",
    ):
        require(uninstall, marker, "Uninstall")
    forbid(uninstall, "sp_drop_trusted_assembly", "Uninstall")

    build_script = read("Scripts/New-ClrReleaseArtifacts.ps1")
    for marker in (
        "Toolbelt.Archive.ZipMemory.csproj",
        "Get-FileHash -Algorithm SHA512",
        "Deploy.WithAssembly.sql",
        "Toolbelt.Archive.ZipMemory.trust-manifest.json",
        "directFrameworkReferences",
        "@('System', 'System.Data')",
        "$deployTemplate.Split($marker).Count",
    ):
        require(build_script, marker, "Release-Artefaktskript")

    manifest = read("module.yaml")
    for marker in (
        'module_id: "toolbelt.archive.zip-memory"',
        'version: "1.1.0"',
        "implementation_status: implemented",
        'validation_status: "not executed"',
        "id: clr-zip-memory",
        "type: CLR_TVF",
        'name: "TVF_InternalExtractZipEntryClr"',
        "type: ASSEMBLY",
        'name: "Toolbelt_Archive_ZipMemory"',
        'permission_set: "SAFE"',
        'trust_method: "SHA2-512 via sys.sp_add_trusted_assembly"',
        'error_range: "51320-51329"',
        'trust_error_range: "51340-51349"',
    ):
        require(manifest, marker, "Manifest")

    runtime = read("Tests/Runtime/ZipMemory.Contract.sql")
    for marker in (
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
        "ERROR_NUMBER() <> 51320",
        "ERROR_NUMBER() <> 51321",
        "ERROR_NUMBER() <> 51322",
        "ERROR_NUMBER() <> 51323",
        "ERROR_NUMBER() <> 51324",
        "ERROR_NUMBER() <> 51325",
        "ERROR_NUMBER() <> 51326",
        "ERROR_NUMBER() <> 51327",
        "ERROR_NUMBER() <> 51328",
    ):
        require(runtime, marker, "Runtime-Contract")

    encoding = read("Tests/Runtime/Encoding.Contract.sql")
    for marker in ("0x477281E1652E747874", "N'Grüße.txt'", "CP437"):
        require(encoding, marker, "Encoding-Contract")

    for fixture_path in (
        "Tests/Runtime/ZipMemory.Contract.sql",
        "Tests/Runtime/Encoding.Contract.sql",
        "Tests/Runtime/Central.Contract.sql",
        "Examples/ExtractZipEntryFromBinary.sql",
    ):
        validate_zip_fixtures(fixture_path)

    workflow = (REPO / ".github/workflows/zip-memory-runtime.yml").read_text(
        encoding="utf-8"
    )
    if "Documentation/**" in workflow:
        raise RuntimeError("Runtime-Workflow darf nicht auf reine Dokumentation triggern.")
    for marker in (
        "mcr.microsoft.com/mssql/server:2019-latest",
        "mcr.microsoft.com/mssql/server:2022-latest",
        "mcr.microsoft.com/mssql/server:2025-latest",
        "compatibility_level: 150",
        "compatibility_level: 160",
        "compatibility_level: 170",
        "New-ClrReleaseArtifacts.ps1",
    ):
        require(workflow, marker, "Runtime-Workflow")

    print("ZIP-Memory CLR statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(
            f"ZIP-Memory CLR statische Vertragsprüfung: FEHLER: {error}",
            file=sys.stderr,
        )
        raise SystemExit(1)
