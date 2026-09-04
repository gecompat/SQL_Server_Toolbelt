#!/usr/bin/env python3

from __future__ import annotations

import pathlib
import sys


MODULE_ROOT = pathlib.Path(__file__).resolve().parents[2]
REPOSITORY_ROOT = MODULE_ROOT.parents[1]


class ContractError(RuntimeError):
    pass


def read(relative_path: str) -> str:
    return (MODULE_ROOT / relative_path).read_text(encoding="utf-8")


def require(text: str, markers: tuple[str, ...], context: str) -> None:
    for marker in markers:
        if marker not in text:
            raise ContractError(f"{context}: Pflichtmarker fehlt: {marker}")


def main() -> int:
    source = read("Source/TVF_SplitByCharacters.sql")
    deploy = read("Deployment/Deploy.sql")
    uninstall = read("Deployment/Uninstall.sql")
    manifest = read("module.yaml")
    runtime = read("Tests/Runtime/SplitCharacters.Contract.sql")
    lifecycle = read("Tests/Runtime/Lifecycle.Contract.sql")
    central = read("Tests/Runtime/Central.Contract.sql")
    ci_adapter = (
        REPOSITORY_ROOT / "Tests" / "CI" / "run-split-characters-linux.sh"
    ).read_text(encoding="utf-8")
    workflow = (
        REPOSITORY_ROOT
        / ".github"
        / "workflows"
        / "split-characters-runtime.yml"
    ).read_text(encoding="utf-8")

    require(
        source,
        (
            "CREATE OR ALTER FUNCTION [toolbelt_string].[TVF_SplitByCharacters]",
            "@Input      nvarchar(max)",
            "@Separators nvarchar(4000)",
            "@KeepEmpty  bit = 1",
            "Value",
            "Ordinal",
            "toolbelt_core.TVF_GenerateSeriesBigInt",
            "DATALENGTH(@Input) / 2",
            "DATALENGTH(@Separators) / 2",
            "Latin1_General_100_BIN2",
            "LEAD(BoundaryPosition)",
            "ROW_NUMBER() OVER",
        ),
        "Source",
    )

    for prohibited in (
        "STRING_SPLIT(",
        "REGEXP_SPLIT_TO_TABLE(",
        "WITH XMLNAMESPACES",
        "sys.all_objects",
        "sys.columns",
        "recursive",
    ):
        if prohibited.lower() in source.lower():
            raise ContractError(f"Source enthält verbotenen Provider: {prohibited}")

    if deploy.count(":r ../Source/TVF_SplitByCharacters.sql") != 1:
        raise ContractError("Deploy muss den Source genau einmal einbinden.")

    require(
        deploy,
        (
            "Toolbelt.Module.toolbelt.string.split-characters.Version",
            "Toolbelt.Module.toolbelt.core.generate-series.Version",
            "TVF_GenerateSeriesBigInt",
            "THROW 51079",
            "sp_getapplock",
            "TVF_SplitByCharacters",
        ),
        "Deploy",
    )
    require(
        uninstall,
        (
            "Toolbelt.Module.toolbelt.string.split-characters.Version",
            "ConfirmNoExternalConsumers",
            "TVF_SplitByCharacters",
            "sys.sql_expression_dependencies",
        ),
        "Uninstall",
    )

    require(
        manifest,
        (
            'module_id: "toolbelt.string.split-characters"',
            'module_id: "toolbelt.core.generate-series"',
            'minimum_version: "1.0.0"',
            '"Value nvarchar(max)"',
            '"Ordinal bigint"',
            'lifecycle_error_range: "51070-51079"',
        ),
        "Manifest",
    )
    if (
        'validation_status: "not executed"' not in manifest
        and 'validation_status: "partially validated"' not in manifest
        and "validation_status: validated" not in manifest
    ):
        raise ContractError("Manifest enthält keinen zulässigen Validierungsstatus.")

    for level in ("150", "160", "170"):
        if level not in runtime or level not in ci_adapter:
            raise ContractError(f"Compatibility Level {level} fehlt.")

    require(
        runtime,
        (
            "N'A,B;C|D'",
            "N',A;;'",
            "@NullSeparator",
            "N'AaÁá'",
            "@LargeInput",
            "CROSS APPLY",
            "REGEXP_SPLIT_TO_TABLE",
            "COLLATE DATABASE_DEFAULT",
        ),
        "Runtime",
    )
    require(
        lifecycle,
        (
            "sys.sql_expression_dependencies",
            "TVF_GenerateSeriesBigInt",
            "Toolbelt.SourceHash",
        ),
        "Lifecycle",
    )
    require(central, ("[$(ToolbeltDatabase)]", "TVF_SplitByCharacters"), "Central")
    require(
        ci_adapter,
        (
            "tbx_split_characters_missing_dependency",
            "Modules/toolbelt.core.generate-series/Deployment",
            "Modules/toolbelt.string.split-characters/Deployment",
        ),
        "CI adapter",
    )

    for prohibited in (
        '"Documentation/Architecture/**"',
        '"Documentation/Standards/**"',
        '"Modules/toolbelt.string.split-characters/Documentation/**"',
        '"Modules/toolbelt.string.split-characters/Tests/**/*.md"',
    ):
        if prohibited in workflow:
            raise ContractError(
                f"Runtime-Workflow wird durch reine Dokumentation ausgelöst: {prohibited}"
            )

    print("Split-Characters statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(
            f"Split-Characters statische Vertragsprüfung: FEHLER: {error}",
            file=sys.stderr,
        )
        raise SystemExit(1)
