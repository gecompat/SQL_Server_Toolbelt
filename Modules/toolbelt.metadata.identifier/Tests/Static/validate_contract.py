#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.metadata.identifier."""

from __future__ import annotations

import re
import sys
from pathlib import Path


MODULE_ROOT = Path(__file__).resolve().parents[2]
REPOSITORY_ROOT = MODULE_ROOT.parents[1]


class ContractError(AssertionError):
    """Meldet eine statisch nachweisbare Vertragsabweichung."""


def read(relative: str) -> str:
    path = MODULE_ROOT / relative
    if not path.is_file():
        raise ContractError(f"Pflichtartefakt fehlt: {relative}")
    return path.read_text(encoding="utf-8")


def require(text: str, pattern: str, description: str) -> None:
    if re.search(pattern, text, re.IGNORECASE | re.DOTALL) is None:
        raise ContractError(f"Vertrag fehlt: {description}")


def main() -> int:
    parser = read("Source/TVF_ParseMultipartName.sql")
    quote = read("Source/SVF_QuoteMultipartName.sql")
    manifest = read("module.yaml")
    deploy = read("Deployment/Deploy.sql")
    uninstall = read("Deployment/Uninstall.sql")
    runtime = read("Tests/Runtime/Identifier.Contract.sql")
    matrix = read("Tests/IDENTIFIER_CONTRACT_TEST_MATRIX.md")
    module_documentation = read("README.md")
    ci_adapter = (
        REPOSITORY_ROOT / "Tests" / "CI" / "run-identifier-linux.sh"
    ).read_text(encoding="utf-8")

    require(
        parser,
        r"CREATE\s+OR\s+ALTER\s+FUNCTION\s+\[toolbelt_metadata\]\.\[TVF_ParseMultipartName\]",
        "öffentliche Parser-Funktion",
    )
    require(parser, r"@MultipartName\s+nvarchar\(1035\)", "Parserparameter")
    for column in (
        "IsValid",
        "ValidationCode",
        "PartCount",
        "ServerName",
        "DatabaseName",
        "SchemaName",
        "ObjectName",
        "QuotedName",
    ):
        if column not in parser or column not in runtime:
            raise ContractError(f"Parser-Resultspalte fehlt: {column}")

    require(
        quote,
        r"CREATE\s+OR\s+ALTER\s+FUNCTION\s+\[toolbelt_metadata\]\.\[SVF_QuoteMultipartName\]",
        "öffentliche Quote-Funktion",
    )
    if "[TVF_ParseMultipartName]" not in quote:
        raise ContractError("Der Quote-Wrapper verwendet nicht den Parserkern.")

    for marker in (
        "@NextCharacter = N']'",
        "UNCLOSED_DELIMITER",
        "TEXT_AFTER_DELIMITER",
        "INVALID_OMISSION",
        "PART_TOO_LONG",
        "Latin1_General_100_BIN2",
    ):
        if marker not in parser:
            raise ContractError(f"Parser-Vertragsmarker fehlt: {marker}")

    if "OBJECT_ID" in parser or "sys.objects" in parser:
        raise ContractError("Der Parser darf keine Objektauflösung durchführen.")

    for object_name in ("TVF_ParseMultipartName", "SVF_QuoteMultipartName"):
        for text, location in (
            (manifest, "Manifest"),
            (deploy, "Deploy"),
            (uninstall, "Uninstall"),
            (module_documentation, "Moduldokumentation"),
        ):
            if object_name not in text:
                raise ContractError(f"{location} kennt {object_name} nicht.")

    for level in ("150", "160", "170"):
        if level not in matrix or level not in runtime or level not in ci_adapter:
            raise ContractError(f"Compatibility Level {level} fehlt.")

    for marker in (
        "Server...Object",
        "[Archive.Db]",
        "[Db]]Name]",
        "PART_TOO_LONG",
        "UNQUOTED_META_CHARACTER",
        "CROSS APPLY",
    ):
        if marker not in runtime:
            raise ContractError(f"Runtime-Contract-Fall fehlt: {marker}")

    if "SET COMPATIBILITY_LEVEL" in runtime:
        raise ContractError(
            "Der Contract-Test darf seinen Compilation-Context nicht selbst ändern."
        )

    if "../../.github/workflows/identifier-runtime.yml" not in manifest:
        raise ContractError("Runtime-Workflow ist im Manifest nicht gekoppelt.")

    print("Identifier statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(
            f"Identifier statische Vertragsprüfung: FEHLER: {error}",
            file=sys.stderr,
        )
        raise SystemExit(1)
