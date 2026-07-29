#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.core.result-table.

Die Prüfung verwendet ausschließlich die Python-Standardbibliothek. Sie ersetzt
keinen SQL-Server-Runtime-Test, verhindert aber erkennbare Drift zwischen
Source, Manifest, Lifecycle, Dokumentation und dem freigegebenen API-Vertrag.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path


MODULE_ROOT = Path(__file__).resolve().parents[2]
SOURCE = MODULE_ROOT / "Source" / "USP_PrepareResultTable.sql"
MANIFEST = MODULE_ROOT / "module.yaml"
README = MODULE_ROOT / "README.md"
OBJECT_DOC = MODULE_ROOT / "Documentation" / "USP_PrepareResultTable.md"
INSTALL = MODULE_ROOT / "Deployment" / "Install.sql"
UPGRADE = MODULE_ROOT / "Deployment" / "Upgrade.sql"
UNINSTALL = MODULE_ROOT / "Deployment" / "Uninstall.sql"
EXAMPLE = MODULE_ROOT / "Examples" / "PrepareResultTable.sql"
RUNTIME_CONTRACT = (
    MODULE_ROOT / "Tests" / "Runtime" / "USP_PrepareResultTable.Contract.sql"
)
LIFECYCLE_CONTRACT = MODULE_ROOT / "Tests" / "Runtime" / "Lifecycle.Contract.sql"


def read(path: Path) -> str:
    if not path.is_file():
        raise AssertionError(f"Pflichtartefakt fehlt: {path.relative_to(MODULE_ROOT)}")
    return path.read_text(encoding="utf-8")


def normalize_sql(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip().lower()


def check_balanced_sql_strings(value: str, path: Path) -> None:
    """Prüft einfache T-SQL-Stringgrenzen einschließlich verdoppelter Quotes."""

    in_string = False
    line = 1
    opened_at = 0
    index = 0

    while index < len(value):
        character = value[index]
        if character == "\n":
            line += 1
        if character == "'":
            if in_string and index + 1 < len(value) and value[index + 1] == "'":
                index += 2
                continue
            in_string = not in_string
            if in_string:
                opened_at = line
        index += 1

    if in_string:
        raise AssertionError(
            f"Nicht geschlossener SQL-String in {path.name}, begonnen in Zeile "
            f"{opened_at}."
        )


def require(pattern: str, value: str, message: str, flags: int = 0) -> None:
    if re.search(pattern, value, flags) is None:
        raise AssertionError(message)


def main() -> int:
    files = {
        path: read(path)
        for path in (
            SOURCE,
            MANIFEST,
            README,
            OBJECT_DOC,
            INSTALL,
            UPGRADE,
            UNINSTALL,
            EXAMPLE,
            RUNTIME_CONTRACT,
            LIFECYCLE_CONTRACT,
        )
    }

    for path, value in files.items():
        if path.suffix == ".sql":
            check_balanced_sql_strings(value, path)
        if "\r" in value:
            raise AssertionError(
                f"{path.relative_to(MODULE_ROOT)} verwendet nicht ausschließlich LF."
            )

    source = files[SOURCE]
    normalized_source = normalize_sql(source)
    signature = normalize_sql(
        """
        CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_PrepareResultTable]
        (
              @ResultTableToAlter sysname       = NULL
            , @LikeTable          nvarchar(776) = NULL
            , @KeepData           bit           = 0
            , @Debug              tinyint       = 0
            , @Hilfe              bit           = 0
        )
        """
    )
    if signature not in normalized_source:
        raise AssertionError(
            "Objektname, Parameter, Reihenfolge, Typen oder Defaults weichen ab."
        )

    if re.search(r"@CreateStmt\b", source, re.IGNORECASE):
        raise AssertionError("@CreateStmt ist in Contract-Version 1.0 unzulässig.")
    if re.search(r"\bINSERT\s+(?:INTO\s+)?[^;\n]+\s+EXEC(?:UTE)?\b", source, re.IGNORECASE):
        raise AssertionError("Die Source enthält ein unzulässiges INSERT ... EXEC.")

    for help_column in (
        "HelpContractVersion",
        "SchemaName",
        "ObjectName",
        "Section",
        "Ordinal",
        "ItemName",
        "SqlDataType",
        "IsRequired",
        "IsNullable",
        "DefaultValue",
        "Description",
        "ExampleSql",
    ):
        require(
            rf"\b{re.escape(help_column)}\b",
            source,
            f"Help-Spalte fehlt: {help_column}",
        )

    for section in ("DESCRIPTION", "PARAMETER", "RESULT_COLUMN", "EXAMPLE"):
        require(
            rf"'{section}'",
            source,
            f"Help-Pflichtsection fehlt: {section}",
        )

    throw_numbers = {
        int(number)
        for number in re.findall(r"\bTHROW\s+(51\d{3})\s*,", source, re.IGNORECASE)
    }
    if not throw_numbers:
        raise AssertionError("Keine Modulfehler mit THROW gefunden.")
    if min(throw_numbers) < 51020 or max(throw_numbers) > 51029:
        raise AssertionError(
            f"Procedure-Fehler außerhalb 51020-51029: {sorted(throw_numbers)}"
        )
    if set(range(51020, 51030)) - throw_numbers:
        missing = sorted(set(range(51020, 51030)) - throw_numbers)
        raise AssertionError(f"Vorgesehene Procedure-Fehler fehlen: {missing}")

    for required_source_marker in (
        "OBJECT_ID(N'tempdb..' + @TargetQuotedName, N'U')",
        "Latin1_General_100_BIN2",
        "QUOTENAME(@ResultTableToAlter)",
        "SAVE TRANSACTION @SavepointName",
        "ROLLBACK TRANSACTION @SavepointName",
        "RAISERROR(N'%s', 10, 1, @DebugChunk) WITH NOWAIT",
        "@DropColumnBeforeAnchor",
        "@AddColumnAfterAnchor",
        "RETURN 0",
    ):
        if required_source_marker not in source:
            raise AssertionError(
                f"Verbindlicher Source-Marker fehlt: {required_source_marker}"
            )

    manifest = files[MANIFEST]
    require(
        r'module_id:\s*"toolbelt\.core\.result-table"',
        manifest,
        "Manifest-Modul-ID fehlt.",
    )
    require(r'version:\s*"1\.0\.0"', manifest, "Manifestversion ist nicht 1.0.0.")
    require(r"status:\s*implemented", manifest, "Manifeststatus ist nicht implemented.")
    require(
        r"validation_status:\s*\"not executed\"",
        manifest,
        "Manifest behauptet einen nicht belegten Validierungsstatus.",
    )
    if len(re.findall(r"^\s+- type:\s+USP\s*$", manifest, re.MULTILINE)) != 1:
        raise AssertionError("Das Manifest muss genau ein persistentes USP-Objekt führen.")

    for lifecycle_path in (INSTALL, UPGRADE):
        lifecycle = files[lifecycle_path]
        if lifecycle.count(":r ../Source/USP_PrepareResultTable.sql") != 1:
            raise AssertionError(
                f"{lifecycle_path.name} bindet die kanonische Source nicht exakt einmal ein."
            )
        for marker in (
            "Toolbelt.ModuleId",
            "Toolbelt.ModuleVersion",
            "Toolbelt.ContractVersion",
            "Toolbelt.SourceHash",
        ):
            if marker not in lifecycle:
                raise AssertionError(
                    f"{lifecycle_path.name} pflegt Ownership-Marker {marker} nicht."
                )

    uninstall = files[UNINSTALL]
    for marker in (
        "ConfirmNoExternalConsumers",
        "sys.sql_expression_dependencies",
        "DROP PROCEDURE [toolbelt_core].[USP_PrepareResultTable]",
        "DROP SCHEMA [toolbelt_core]",
    ):
        if marker not in uninstall:
            raise AssertionError(f"Uninstall-Gate fehlt: {marker}")

    documentation_scope = "\n".join(
        (files[README], files[OBJECT_DOC], files[EXAMPLE])
    )
    for public_name in (
        "@ResultTableToAlter",
        "@LikeTable",
        "@KeepData",
        "@Debug",
        "@Hilfe",
    ):
        if public_name not in documentation_scope:
            raise AssertionError(f"Öffentlicher Parameter undokumentiert: {public_name}")

    print("Statische ResultTable-Vertragsprüfung: erfolgreich")
    print(f"Geprüfte Artefakte: {len(files)}")
    print("Runtime-Evidenz: not executed")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except AssertionError as error:
        print(f"Statische ResultTable-Vertragsprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
