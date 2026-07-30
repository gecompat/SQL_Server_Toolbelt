#!/usr/bin/env python3
"""Statische Vertragspruefung fuer toolbelt.archive.zip-memory."""

from __future__ import annotations

import re
import struct
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPO = ROOT.parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    if not path.is_file():
        raise RuntimeError(f"Pflichtartefakt fehlt: {relative}")
    return path.read_text(encoding="utf-8")


def validate_zip_fixtures(relative: str) -> None:
    """Prueft die EOCD-/Central-Directory-Beziehung synthetischer ZIP-BLOBs."""
    fixtures = re.findall(r"0x([0-9A-Fa-f]+)", read(relative))
    zip_fixtures = [value for value in fixtures if value.upper().startswith("504B0304")]
    if not zip_fixtures:
        raise RuntimeError(f"Synthetische ZIP-Fixture fehlt: {relative}")

    for hex_value in zip_fixtures:
        archive = bytes.fromhex(hex_value)
        eocd_start = archive.rfind(b"PK\x05\x06")
        if eocd_start < 0 or eocd_start + 22 > len(archive):
            raise RuntimeError(f"Synthetische ZIP-Fixture hat kein vollstaendiges EOCD: {relative}")

        comment_length = struct.unpack_from("<H", archive, eocd_start + 20)[0]
        central_size, central_offset = struct.unpack_from("<II", archive, eocd_start + 12)

        if eocd_start + 22 + comment_length != len(archive):
            raise RuntimeError(f"Synthetische ZIP-Fixture hat eine inkonsistente EOCD-Laenge: {relative}")
        if central_offset + central_size != eocd_start:
            raise RuntimeError(f"Synthetische ZIP-Fixture hat ein inkonsistentes Central Directory: {relative}")
        if archive[central_offset : central_offset + 4] != b"PK\x01\x02":
            raise RuntimeError(f"Synthetische ZIP-Fixture beginnt nicht mit einem Central-Directory-Header: {relative}")


def main() -> int:
    required = (
        "Source/USP_ExtractZipEntryFromBinary.sql",
        "Deployment/Deploy.sql",
        "Deployment/Uninstall.sql",
        "Examples/ExtractZipEntryFromBinary.sql",
        "README.md",
        "Documentation/USP_ExtractZipEntryFromBinary.md",
        "Tests/ZIP_MEMORY_CONTRACT_TEST_MATRIX.md",
        "Tests/README.md",
        "Tests/Runtime/ZipMemory.Contract.sql",
        "Tests/Runtime/Lifecycle.Contract.sql",
        "Tests/Runtime/Central.Contract.sql",
        "module.yaml",
    )
    missing = [path for path in required if not (ROOT / path).is_file()]
    if missing:
        raise RuntimeError("Fehlende Artefakte: " + ", ".join(missing))

    source = read("Source/USP_ExtractZipEntryFromBinary.sql")
    for marker in (
        "CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ExtractZipEntryFromBinary]",
        "@ZipArchive          varbinary(max) = NULL",
        "@EntryName           nvarchar(1024) = NULL",
        "@MaxEntryBytes       bigint         = 104857600",
        "@MaxCompressionRatio decimal(9,2)   = 200.00",
        "@FailIfEncrypted     bit            = 1",
        "@ResultTable         sysname        = NULL",
        "@KeepData            bit            = 0",
        "@Debug               tinyint        = 0",
        "@Hilfe               bit            = 0",
        "Latin1_General_100_BIN2",
        "0x504B0506",
        "0x504B0102",
        "0x504B0304",
        "THROW 51322",
        "THROW 51323",
        "THROW 51324",
        "THROW 51325",
        "THROW 51326",
        "THROW 51327",
        "THROW 51328",
        "toolbelt_core.USP_PrepareResultTable",
        "#tbx_ZipMemory_ResultSource",
        "RETURN 0",
    ):
        if marker not in source:
            raise RuntimeError(f"ZIP-Memory-Vertragsmarker fehlt: {marker}")

    if "OPENROWSET" in source or "xp_cmdshell" in source:
        raise RuntimeError("Dateisystem- oder Shell-Zugriff ist im V1A-Scope unzulaessig.")

    if "@ResultSource TABLE" in source:
        raise RuntimeError(
            "Der ResultTable-Pfad darf keine Table Variable als dynamischen Tabellenparameter verwenden."
        )

    for fixture_path in (
        "Tests/Runtime/ZipMemory.Contract.sql",
        "Tests/Runtime/Central.Contract.sql",
        "Examples/ExtractZipEntryFromBinary.sql",
    ):
        validate_zip_fixtures(fixture_path)

    manifest = read("module.yaml")
    for marker in (
        'module_id: "toolbelt.archive.zip-memory"',
        'version: "1.0.0"',
        'implementation_status: implemented',
        'validation_status: "not executed"',
        'module_id: "toolbelt.core.result-table"',
        'error_range: "51320-51329"',
    ):
        if marker not in manifest:
            raise RuntimeError(f"Manifest-Vertrag fehlt: {marker}")

    workflow = (
        REPO / ".github" / "workflows" / "zip-memory-runtime.yml"
    ).read_text(encoding="utf-8")
    if "Documentation/**" in workflow:
        raise RuntimeError("Runtime-Workflow darf nicht auf reine Dokumentation triggern.")

    print("ZIP-Memory statische Vertragspruefung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except RuntimeError as error:
        print(f"ZIP-Memory statische Vertragspruefung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
