#!/usr/bin/env python3
"""Temporäre Normalisierung für den W4b-Generator und seine Ausgabe."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: erwartet genau einen Treffer, gefunden {count}")
    return text.replace(old, new, 1)


def patch_generator() -> None:
    path = Path("Tests/Documentation/generate_w4b_work_type.py")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "OR LEFT(LTRIM(@PayloadContractJson), 1) <> N'{'",
        "OR LEFT(LTRIM(@PayloadContractJson), 1) <> N'{{'",
        "f-String-Klammer",
    )
    text = replace_once(
        text,
        '"# Changelog\\n\\n"',
        '"# CHANGELOG\\n\\n"',
        "CHANGELOG-Überschrift",
    )
    path.write_text(text, encoding="utf-8", newline="\n")


def patch_table() -> None:
    path = Path("Modules/toolbelt.core.work-type/Source/WorkType.sql")
    text = path.read_text(encoding="utf-8")
    defaults = {
        "        , [ParameterMode]          varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL":
            "        , [ParameterMode]          varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL CONSTRAINT [DF_WorkType_ParameterMode] DEFAULT ('NONE')",
        "        , [DefaultTimeoutSeconds]  int NOT NULL":
            "        , [DefaultTimeoutSeconds]  int NOT NULL CONSTRAINT [DF_WorkType_DefaultTimeoutSeconds] DEFAULT (300)",
        "        , [IsIdempotent]           bit NOT NULL":
            "        , [IsIdempotent]           bit NOT NULL CONSTRAINT [DF_WorkType_IsIdempotent] DEFAULT (0)",
        "        , [IsEnabled]              bit NOT NULL":
            "        , [IsEnabled]              bit NOT NULL CONSTRAINT [DF_WorkType_IsEnabled] DEFAULT (1)",
        "        , [CreatedAtUtc]           datetime2(7) NOT NULL":
            "        , [CreatedAtUtc]           datetime2(7) NOT NULL CONSTRAINT [DF_WorkType_CreatedAtUtc] DEFAULT (SYSUTCDATETIME())",
        "        , [CreatedBy]              sysname NOT NULL":
            "        , [CreatedBy]              sysname NOT NULL CONSTRAINT [DF_WorkType_CreatedBy] DEFAULT (ORIGINAL_LOGIN())",
        "        , [ModifiedAtUtc]          datetime2(7) NOT NULL":
            "        , [ModifiedAtUtc]          datetime2(7) NOT NULL CONSTRAINT [DF_WorkType_ModifiedAtUtc] DEFAULT (SYSUTCDATETIME())",
        "        , [ModifiedBy]             sysname NOT NULL":
            "        , [ModifiedBy]             sysname NOT NULL CONSTRAINT [DF_WorkType_ModifiedBy] DEFAULT (ORIGINAL_LOGIN())",
    }
    for old, new in defaults.items():
        text = replace_once(text, old, new, old.strip())
    text, removed = re.subn(
        r"\n        , CONSTRAINT \[DF_WorkType_[^\]]+\]\n            DEFAULT \([^\n]+\) FOR \[[^\]]+\]",
        "",
        text,
    )
    if removed != 8:
        raise RuntimeError(f"DEFAULT-Normalisierung: erwartet 8, gefunden {removed}")
    path.write_text(text, encoding="utf-8", newline="\n")


def add_savepoint_contract(path_text: str, savepoint: str) -> None:
    path = Path(path_text)
    source = path.read_text(encoding="utf-8")
    source = replace_once(
        source,
        "    SET XACT_ABORT ON;\n",
        "    SET XACT_ABORT OFF;\n",
        f"{path.name}: XACT_ABORT",
    )
    source = replace_once(
        source,
        "    BEGIN TRANSACTION;\n\n    SELECT\n",
        (
            "    DECLARE @InitialTranCount int = @@TRANCOUNT;\n"
            "    IF @InitialTranCount = 0\n"
            "        BEGIN TRANSACTION;\n"
            "    ELSE\n"
            f"        SAVE TRANSACTION {savepoint};\n\n"
            "    BEGIN TRY\n\n"
            "    SELECT\n"
        ),
        f"{path.name}: Transaktionsbeginn",
    )
    source = replace_once(
        source,
        "    COMMIT TRANSACTION;\n\n    IF @Debug",
        (
            "    IF @InitialTranCount = 0\n"
            "        COMMIT TRANSACTION;\n"
            "    END TRY\n"
            "    BEGIN CATCH\n"
            "        IF @InitialTranCount = 0 AND XACT_STATE() <> 0\n"
            "            ROLLBACK TRANSACTION;\n"
            "        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1\n"
            f"            ROLLBACK TRANSACTION {savepoint};\n"
            "        THROW;\n"
            "    END CATCH;\n\n"
            "    IF @Debug"
        ),
        f"{path.name}: Transaktionsende",
    )
    path.write_text(source, encoding="utf-8", newline="\n")


def patch_register_debug() -> None:
    path = Path("Modules/toolbelt.core.work-type/Source/USP_RegisterWorkType.sql")
    text = path.read_text(encoding="utf-8")
    text = replace_once(
        text,
        "    IF @Debug > 0\n        RAISERROR(N'USP_RegisterWorkType: Registrierung verarbeitet; Änderung=%d.', 10, 1, @Changed) WITH NOWAIT;\n",
        (
            "    IF @Debug > 0\n"
            "    BEGIN\n"
            "        DECLARE @ChangedForMessage int = CONVERT(int, @Changed);\n"
            "        RAISERROR(N'USP_RegisterWorkType: Registrierung verarbeitet; Änderung=%d.', 10, 1, @ChangedForMessage) WITH NOWAIT;\n"
            "    END;\n"
        ),
        "Register-Debugmeldung",
    )
    path.write_text(text, encoding="utf-8", newline="\n")


def patch_transaction_test() -> None:
    path = Path("Modules/toolbelt.core.work-type/Tests/Runtime/WorkType.Contract.sql")
    text = path.read_text(encoding="utf-8")
    marker = (
        "BEGIN CATCH\n"
        "    IF ERROR_NUMBER() <> 51511 THROW;\n"
        "END CATCH;\n\n"
        "DELETE FROM @First;\n"
        "INSERT INTO @First\n"
        "EXEC toolbelt_core.USP_RegisterWorkType"
    )
    replacement = (
        "BEGIN CATCH\n"
        "    IF ERROR_NUMBER() <> 51511 THROW;\n"
        "END CATCH;\n\n"
        "IF @@TRANCOUNT <> 0 OR XACT_STATE() <> 0\n"
        "    THROW 52514, N'Validierungsfehler hinterließ einen offenen oder uncommittable Transaktionszustand.', 1;\n\n"
        "DELETE FROM @First;\n"
        "INSERT INTO @First\n"
        "EXEC toolbelt_core.USP_RegisterWorkType"
    )
    text = replace_once(text, marker, replacement, "Transaktionszustands-Test")
    path.write_text(text, encoding="utf-8", newline="\n")


def patch_generated() -> None:
    patch_table()
    patch_register_debug()
    add_savepoint_contract(
        "Modules/toolbelt.core.work-type/Source/USP_RegisterWorkType.sql",
        "TBX_WorkType_Register",
    )
    add_savepoint_contract(
        "Modules/toolbelt.core.work-type/Source/USP_DisableWorkType.sql",
        "TBX_WorkType_Disable",
    )
    patch_transaction_test()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("generator", "generated"))
    args = parser.parse_args()
    if args.mode == "generator":
        patch_generator()
    else:
        patch_generated()


if __name__ == "__main__":
    main()
