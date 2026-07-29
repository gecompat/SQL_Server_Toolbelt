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
REPOSITORY_ROOT = MODULE_ROOT.parents[1]
SOURCE = MODULE_ROOT / "Source" / "USP_PrepareResultTable.sql"
MANIFEST = MODULE_ROOT / "module.yaml"
README = MODULE_ROOT / "README.md"
OBJECT_DOC = MODULE_ROOT / "Documentation" / "USP_PrepareResultTable.md"
DEPLOY = MODULE_ROOT / "Deployment" / "Deploy.sql"
UNINSTALL = MODULE_ROOT / "Deployment" / "Uninstall.sql"
EXAMPLE = MODULE_ROOT / "Examples" / "PrepareResultTable.sql"
RUNTIME_CONTRACT = (
    MODULE_ROOT / "Tests" / "Runtime" / "USP_PrepareResultTable.Contract.sql"
)
LIFECYCLE_CONTRACT = MODULE_ROOT / "Tests" / "Runtime" / "Lifecycle.Contract.sql"
COMPATIBILITY_SMOKE = MODULE_ROOT / "Tests" / "Runtime" / "Compatibility.Smoke.sql"
CENTRAL_CONTRACT = MODULE_ROOT / "Tests" / "Runtime" / "Central.Contract.sql"
RUNTIME_WORKFLOW = REPOSITORY_ROOT / ".github" / "workflows" / "result-table-runtime.yml"
LINUX_RUNNER = REPOSITORY_ROOT / "Tests" / "CI" / "run-result-table-linux.sh"


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
            DEPLOY,
            UNINSTALL,
            EXAMPLE,
            RUNTIME_CONTRACT,
            LIFECYCLE_CONTRACT,
            COMPATIBILITY_SMOKE,
            CENTRAL_CONTRACT,
            RUNTIME_WORKFLOW,
            LINUX_RUNNER,
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
    if re.search(r"@DeleteSql\b|\bDELETE\s+FROM\s+[\"'+@]", source, re.IGNORECASE):
        raise AssertionError("Die Source enthält einen unzulässigen DELETE-Fallback.")

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
        "@SourceIsLocal = 1 AND @SourceObjectId = @TargetObjectId",
        "IF @Debug >= 3",
        "SET @TruncateSql = N'TRUNCATE TABLE '",
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

    workflow = files[RUNTIME_WORKFLOW]
    for marker in (
        "runs-on: ubuntu-latest",
        "mcr.microsoft.com/mssql/server:2019-latest",
        "mcr.microsoft.com/mssql/server:2022-latest",
        "mcr.microsoft.com/mssql/server:2025-latest",
        "Tests/CI/run-result-table-linux.sh",
    ):
        if marker not in workflow:
            raise AssertionError(f"Runtime-Workflow-Marker fehlt: {marker}")
    if "self-hosted" in workflow:
        raise AssertionError("Der ResultTable-Workflow darf keinen Remote-Runner verwenden.")

    runtime_contract = files[RUNTIME_CONTRACT]
    if "(5, N'CreatedAt', N'datetime2', 7, 23, 3, 0)" not in runtime_contract:
        raise AssertionError(
            "Der Runtime-Vertrag erwartet für datetime2(3) nicht Precision 23."
        )

    deploy = files[DEPLOY]
    if re.search(r"^\s*:setvar\b", deploy, re.MULTILINE | re.IGNORECASE):
        raise AssertionError(
            "Deploy.sql darf SQLCMD-Kommandozeilenparameter nicht mit :setvar überschreiben."
        )
    if deploy.count(":r ../Source/USP_PrepareResultTable.sql") != 1:
        raise AssertionError(
            "Deploy.sql bindet die kanonische Source nicht exakt einmal ein."
        )
    for marker in (
        "#tbx_ResultTableReleaseObjects",
        "SET QUOTED_IDENTIFIER ON;",
        "o.type COLLATE Latin1_General_100_BIN2",
        "Toolbelt.ModuleId",
        "Toolbelt.ModuleVersion",
        "Toolbelt.ContractVersion",
        "Toolbelt.SourceHash",
        "Toolbelt.Module.toolbelt.core.result-table.Version",
        "sp_getapplock",
        "CREATE OR ALTER",
    ):
        if marker not in deploy and marker != "CREATE OR ALTER":
            raise AssertionError(f"Deploy.sql enthält den Pflichtmarker nicht: {marker}")
        if marker == "CREATE OR ALTER" and marker not in source:
            raise AssertionError("Die kanonische Source verwendet kein CREATE OR ALTER.")

    for obsolete_path in (
        MODULE_ROOT / "Deployment" / "Install.sql",
        MODULE_ROOT / "Deployment" / "Upgrade.sql",
    ):
        if obsolete_path.exists():
            raise AssertionError(
                f"Veraltetes separates Lifecycle-Skript vorhanden: {obsolete_path.name}"
            )

    uninstall = files[UNINSTALL]
    if re.search(r"^\s*:setvar\b", uninstall, re.MULTILINE | re.IGNORECASE):
        raise AssertionError(
            "Uninstall.sql darf SQLCMD-Kommandozeilenparameter nicht mit :setvar überschreiben."
        )
    for marker in (
        "ConfirmNoExternalConsumers",
        "sys.sql_expression_dependencies",
        "DROP PROCEDURE [toolbelt_core].[USP_PrepareResultTable]",
        "Toolbelt.Module.toolbelt.core.result-table.Version",
        "sp_getapplock",
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
