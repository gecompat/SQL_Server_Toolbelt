#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.conversion.integer-base."""

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
    encode = read("Source/SVF_IntegerToBase.sql")
    decode = read("Source/SVF_TryBaseToInteger.sql")
    deploy = read("Deployment/Deploy.sql")
    uninstall = read("Deployment/Uninstall.sql")
    manifest = read("module.yaml")
    documentation = read("README.md")
    matrix = read("Tests/INTEGER_BASE_CONTRACT_TEST_MATRIX.md")
    runtime = read("Tests/Runtime/IntegerBase.Contract.sql")

    combined = "\n".join((encode, decode, deploy, uninstall, manifest, documentation))
    if "{{" in combined or "}}" in combined or "xs:base64Binary" in combined:
        raise ContractError("Ausführbare Artefakte enthalten Template-Reste.")

    require(
        encode,
        r"CREATE\s+OR\s+ALTER\s+FUNCTION\s+\[toolbelt_conversion\]"
        r"\.\[SVF_IntegerToBase\]",
        "Encode-Objektname",
    )
    require(encode, r"@Value\s+bigint", "Encode-bigint-Eingabe")
    require(encode, r"@Alphabet\s+varchar\(93\)", "Encode-Alphabet")
    require(encode, r"RETURNS\s+varchar\(65\)", "Encode-Rückgabetyp")
    require(encode, r"decimal\(38\s*,\s*0\)", "sichere Encode-Arithmetik")
    require(encode, r"END;\s*GO\s*$", "Encode-Batchabschluss")

    require(
        decode,
        r"CREATE\s+OR\s+ALTER\s+FUNCTION\s+\[toolbelt_conversion\]"
        r"\.\[SVF_TryBaseToInteger\]",
        "Decode-Objektname",
    )
    require(decode, r"@EncodedValue\s+varchar\(65\)", "Decode-Eingabe")
    require(decode, r"@Alphabet\s+varchar\(93\)", "Decode-Alphabet")
    require(decode, r"RETURNS\s+bigint", "Decode-Rückgabetyp")
    require(decode, r"END;\s*GO\s*$", "Decode-Batchabschluss")
    for marker in (
        "Latin1_General_100_BIN2",
        "9223372036854775808",
        "FLOOR((@Limit - @Digit) / @Base)",
    ):
        if marker not in decode:
            raise ContractError(f"Decode-Grenzschutz fehlt: {marker}")

    for source in ("SVF_IntegerToBase.sql", "SVF_TryBaseToInteger.sql"):
        if deploy.count(f":r ../Source/{source}") != 1:
            raise ContractError(f"Deploy bindet {source} nicht exakt einmal ein.")

    if "SET QUOTED_IDENTIFIER ON;" not in deploy:
        raise ContractError("Deploy enthält keine kanonische QUOTED_IDENTIFIER-Option.")

    for object_name in ("SVF_IntegerToBase", "SVF_TryBaseToInteger"):
        for text, location in (
            (manifest, "Manifest"),
            (deploy, "Deploy"),
            (uninstall, "Uninstall"),
            (documentation, "Moduldokumentation"),
        ):
            if object_name not in text:
                raise ContractError(f"{location} kennt {object_name} nicht.")

    for marker in (
        '"51090-51099"',
        "tsql-decimal-loop",
        "implementation_status: implemented",
    ):
        if marker not in manifest:
            raise ContractError(f"Manifestvertrag fehlt: {marker}")

    for level in ("150", "160", "170"):
        if level not in matrix or level not in runtime:
            raise ContractError(f"Compatibility Level {level} fehlt.")

    for vector in (
        "7FFFFFFFFFFFFFFF",
        "-8000000000000000",
        "9223372036854775808",
        "-9223372036854775809",
        "@Base93",
    ):
        if vector not in runtime:
            raise ContractError(f"Contract-Vektor fehlt: {vector}")

    print("Integer-Base statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(f"Integer-Base statische Vertragsprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
