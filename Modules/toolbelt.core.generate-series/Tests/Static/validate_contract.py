#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.core.generate-series."""

from __future__ import annotations

import re
import sys
from pathlib import Path


MODULE_ROOT = Path(__file__).resolve().parents[2]


class ContractError(AssertionError):
    """Meldet eine statische Vertragsabweichung."""


def read(relative: str) -> str:
    path = MODULE_ROOT / relative
    if not path.is_file():
        raise ContractError(f"Pflichtartefakt fehlt: {relative}")
    return path.read_text(encoding="utf-8")


def require(text: str, pattern: str, description: str) -> None:
    if re.search(pattern, text, re.IGNORECASE | re.MULTILINE) is None:
        raise ContractError(f"Vertrag fehlt: {description}")


def main() -> int:
    bigint_source = read("Source/TVF_GenerateSeriesBigInt.sql")
    int_source = read("Source/TVF_GenerateSeriesInt.sql")
    deploy = read("Deployment/Deploy.sql")
    uninstall = read("Deployment/Uninstall.sql")
    manifest = read("module.yaml")
    module_documentation = read("README.md")
    matrix = read("Tests/GENERATE_SERIES_CONTRACT_TEST_MATRIX.md")
    runtime = read("Tests/Runtime/GenerateSeries.Contract.sql")

    combined = "\n".join(
        (
            bigint_source,
            int_source,
            deploy,
            uninstall,
            manifest,
            module_documentation,
        )
    )
    if "{{" in combined or "}}" in combined or "NICHT AUSFÜHRBAR" in combined:
        raise ContractError("Ausführbare Artefakte enthalten Template-Reste.")

    require(
        bigint_source,
        r"CREATE\s+OR\s+ALTER\s+FUNCTION\s+\[toolbelt_core\]"
        r"\.\[TVF_GenerateSeriesBigInt\]",
        "bigint-Objektname",
    )
    for parameter in ("@Start", "@Stop", "@Step"):
        require(
            bigint_source,
            rf"{parameter}\s+bigint",
            f"bigint-Parameter {parameter}",
        )
    require(bigint_source, r"@Step\s+bigint\s*=\s*NULL", "bigint-Default")
    require(bigint_source, r"RETURNS\s+TABLE", "bigint Inline-TVF")
    for marker in (
        "E64",
        "TOP",
        "ROW_NUMBER",
        "decimal(38, 0)",
        "RequestedRows",
        "1 / parameters.StepValue",
    ):
        if marker not in bigint_source:
            raise ContractError(f"bigint-Kernbestandteil fehlt: {marker}")
    if re.search(r",\s*RowCount\s*=", bigint_source, re.IGNORECASE):
        raise ContractError(
            "Der unquotierte Alias RowCount kollidiert mit dem ROWCOUNT-Keyword."
        )

    require(
        int_source,
        r"CREATE\s+OR\s+ALTER\s+FUNCTION\s+\[toolbelt_core\]"
        r"\.\[TVF_GenerateSeriesInt\]",
        "int-Objektname",
    )
    for parameter in ("@Start", "@Stop", "@Step"):
        require(int_source, rf"{parameter}\s+int", f"int-Parameter {parameter}")
    require(int_source, r"@Step\s+int\s*=\s*NULL", "int-Default")
    require(int_source, r"RETURNS\s+TABLE", "int Inline-TVF")
    require(
        int_source,
        r"\[toolbelt_core\]\.\[TVF_GenerateSeriesBigInt\]",
        "gemeinsamer bigint-Kern",
    )
    if "E64" in int_source or "ROW_NUMBER" in int_source:
        raise ContractError("Der int-Wrapper dupliziert Reihenlogik.")

    if re.search(
        r"\bGENERATE_SERIES\s*\(",
        bigint_source + int_source,
        re.IGNORECASE,
    ):
        raise ContractError("Portable Source darf die native Funktion nicht nutzen.")
    if "WITH RECURSIVE" in combined.upper() or "MAXRECURSION" in combined.upper():
        raise ContractError("Rekursive Provider sind im freigegebenen Scope unzulässig.")

    for source in (
        "TVF_GenerateSeriesBigInt.sql",
        "TVF_GenerateSeriesInt.sql",
    ):
        if deploy.count(f":r ../Source/{source}") != 1:
            raise ContractError(f"Deploy bindet {source} nicht exakt einmal ein.")

    if deploy.index(":r ../Source/TVF_GenerateSeriesBigInt.sql") > deploy.index(
        ":r ../Source/TVF_GenerateSeriesInt.sql"
    ):
        raise ContractError("Deploy muss den bigint-Kern vor dem int-Wrapper anlegen.")

    require(
        uninstall,
        r"VALUES\s*\(\s*N'TVF_GenerateSeriesInt'\s*\)\s*,\s*"
        r"\(\s*N'TVF_GenerateSeriesBigInt'\s*\)",
        "Uninstall-Reihenfolge Wrapper vor Kern",
    )

    if re.search(r"PropertyOrdinal\s+int\s+IDENTITY", deploy, re.IGNORECASE):
        raise ContractError(
            "Objektproperties dürfen keine schleifenübergreifende IDENTITY "
            "als Ordinal verwenden."
        )
    for ordinal, property_name in enumerate(
        (
            "Toolbelt.ModuleId",
            "Toolbelt.ModuleVersion",
            "Toolbelt.ContractVersion",
            "Toolbelt.DeploymentMode",
            "Toolbelt.SourceHash",
        ),
        start=1,
    ):
        require(
            deploy,
            rf"\(\s*{ordinal}\s*,\s*N'{re.escape(property_name)}'",
            f"deterministisches Property-Ordinal {ordinal}",
        )

    for object_name in (
        "TVF_GenerateSeriesBigInt",
        "TVF_GenerateSeriesInt",
    ):
        for text, location in (
            (manifest, "Manifest"),
            (deploy, "Deploy"),
            (uninstall, "Uninstall"),
            (module_documentation, "Moduldokumentation"),
        ):
            if object_name not in text:
                raise ContractError(f"{location} kennt {object_name} nicht.")

    for level in ("150", "160", "170"):
        if level not in matrix or level not in runtime:
            raise ContractError(f"Compatibility Level {level} fehlt.")

    for marker in (
        "1000000",
        "9223372036854775807",
        "CROSS APPLY",
        "GENERATE_SERIES",
        "DEFAULT",
    ):
        if marker not in runtime:
            raise ContractError(f"Runtime-Contract-Fall fehlt: {marker}")

    if "../../.github/workflows/generate-series-runtime.yml" not in manifest:
        raise ContractError("Runtime-Workflow ist im Manifest nicht gekoppelt.")

    print("Generate-Series statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(
            f"Generate-Series statische Vertragsprüfung: FEHLER: {error}",
            file=sys.stderr,
        )
        raise SystemExit(1)
