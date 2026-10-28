#!/usr/bin/env python3
"""Statische Vertragsprüfung für toolbelt.conversion.base64."""

from __future__ import annotations

import re
import sys
from pathlib import Path


MODULE_ROOT = Path(__file__).resolve().parents[2]
REPOSITORY_ROOT = MODULE_ROOT.parents[1]


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


def require_ddl_help(source: str, object_name: str, markers: tuple[str, ...]) -> None:
    """Prüft, dass die Funktionshilfe Bestandteil des gespeicherten CREATE-DDL ist."""
    pattern = (
        r"(?is)CREATE\s+OR\s+ALTER\s+FUNCTION\s+"
        r"\[toolbelt_conversion\]\.\["
        + re.escape(object_name)
        + r"\]"
    )
    matches = list(re.finditer(pattern, source))
    if len(matches) != 1:
        raise ContractError(f"CREATE-DDL fehlt oder ist doppelt: {object_name}")
    start = matches[0].start()
    end = source.find("\nGO", start)
    definition = source[start:] if end < 0 else source[start:end]
    help_match = re.search(r"/\*\s*DDL-Hilfe:(.*?)\*/", definition, re.DOTALL)
    if help_match is None:
        raise ContractError(f"DDL-interne Hilfe fehlt: {object_name}")
    help_text = help_match.group(1)
    for marker in markers:
        if marker not in help_text:
            raise ContractError(f"DDL-Hilfe für {object_name} lässt {marker} aus.")


def main() -> int:
    encode_tvf = read("Source/TVF_Base64Encode.sql")
    decode_tvf = read("Source/TVF_Base64Decode.sql")
    encode_svf = read("Source/SVF_Base64Encode.sql")
    decode_svf = read("Source/SVF_Base64Decode.sql")
    deploy = read("Deployment/Deploy.sql")
    uninstall = read("Deployment/Uninstall.sql")
    manifest = read("module.yaml")
    module_documentation = read("README.md")
    matrix = read("Tests/BASE64_CONTRACT_TEST_MATRIX.md")
    runtime = read("Tests/Runtime/Base64.Contract.sql")
    read("Tests/Runtime/Load.Contract.sql")
    performance_workload = read("Tests/Runtime/Performance.Workload.sql")
    ci_adapter = (
        MODULE_ROOT.parents[1] / "Tests" / "CI" / "run-base64-linux.sh"
    ).read_text(encoding="utf-8")

    if "Load.Contract.sql" not in ci_adapter or "load:" not in manifest:
        raise ContractError("Der Pflicht-Lastfall muss im Adapter und Manifest gekoppelt sein.")
    for marker in ("OBJECT_DEFINITION", "DDL-Hilfe:", "Beispiel:", "52317"):
        if marker not in runtime:
            raise ContractError(f"Gespeicherte DDL-Hilfe wird nicht geprüft: {marker}")

    for source, object_name, markers in (
        (encode_tvf, "TVF_Base64EncodeStatus", ("Parameter:", "varbinary(max)", "@UrlSafe", "16777216", "EncodedValue", "Status", "Beispiel:", "SELECT erforderlich")),
        (encode_tvf, "TVF_Base64Encode", ("Parameter:", "varbinary(max)", "@UrlSafe", "16777216", "EncodedValue", "Beispiel:", "SELECT erforderlich", "Größen-LIMIT NULL")),
        (decode_tvf, "TVF_Base64DecodeStatus", ("Parameter:", "varchar(max)", "25165824", "16777216", "DecodedValue", "Status", "Beispiel:", "SELECT erforderlich")),
        (decode_tvf, "TVF_Base64Decode", ("Parameter:", "varchar(max)", "25165824", "16777216", "DecodedValue", "Beispiel:", "SELECT erforderlich", "Größen-LIMIT NULL")),
        (encode_svf, "SVF_Base64Encode", ("Parameter:", "varbinary(max)", "@UrlSafe", "16777216", "Rückgabe:", "Beispiel:", "EXECUTE")),
        (decode_svf, "SVF_Base64Decode", ("Parameter:", "varchar(max)", "25165824", "16777216", "Rückgabe:", "Größenüberschreitung NULL", "Beispiel:", "EXECUTE")),
    ):
        require_ddl_help(source, object_name, markers)
    if ci_adapter.index("Load.Contract.sql") > ci_adapter.index('if [[ "${run_performance_workload}" == "1" ]]'):
        raise ContractError("Der Pflicht-Lastfall darf nicht vom Performance-Opt-in abhängen.")

    combined = "\n".join(
        (
            encode_tvf,
            decode_tvf,
            encode_svf,
            decode_svf,
            deploy,
            uninstall,
            manifest,
            module_documentation,
        )
    )
    if "{{" in combined or "}}" in combined or "NICHT AUSFÜHRBAR" in combined:
        raise ContractError("Ausführbare Artefakte enthalten Template-Reste.")

    for marker in (
        "PerformanceBaselineMedianMilliseconds",
        "PerformanceMaxMedianRegressionPercent",
        "PerformanceMaxBatchMedianVariancePercent",
        "4194304",
        "@Decoded IS NULL OR @Decoded <> @Synthetic",
        "@SampleOrdinal < 6",
        "@BatchOrdinal <= 3",
        "52352",
        "52453",
    ):
        if marker not in performance_workload:
            raise ContractError(f"Large-LOB-Performance-Workload fehlt: {marker}")

    if performance_workload.index("52453") > performance_workload.index("52352"):
        raise ContractError("Das Stabilitäts-Gate muss vor dem Regressionsvergleich liegen.")
    for marker in (
        "TBX_PERFORMANCE_MAX_BATCH_MEDIAN_VARIANCE_PERCENT",
        "PERFORMANCE_STABILITY_UNAVAILABLE",
        "exit 75",
    ):
        if marker not in ci_adapter:
            raise ContractError(f"CI-Adapter kennt das Stabilitäts-Gate nicht: {marker}")

    require(
        encode_tvf,
        r"CREATE\s+OR\s+ALTER\s+FUNCTION\s+\[toolbelt_conversion\]"
        r"\.\[TVF_Base64Encode\]",
        "Encode-Objektname",
    )
    require(encode_tvf, r"@Value\s+varbinary\(max\)", "Encode-Binäreingabe")
    require(encode_tvf, r"@UrlSafe\s+bit\s*=\s*0", "Encode-Default")
    require(encode_tvf, r"RETURNS\s+TABLE", "Encode-inline-TVF")
    require(encode_tvf, r"xs:base64Binary", "XML-Provider für Encode")

    require(
        decode_tvf,
        r"CREATE\s+OR\s+ALTER\s+FUNCTION\s+\[toolbelt_conversion\]"
        r"\.\[TVF_Base64Decode\]",
        "Decode-Objektname",
    )
    require(decode_tvf, r"@Value\s+varchar\(max\)", "Decode-Texteingabe")
    require(decode_tvf, r"RETURNS\s+TABLE", "Decode-inline-TVF")
    for marker in ("CHAR(32)", "CHAR(9)", "CHAR(13)", "CHAR(10)"):
        if marker not in decode_tvf:
            raise ContractError(f"Whitespace-Normalisierung fehlt: {marker}")
    for marker in (
        "Latin1_General_100_BIN2",
        "FirstPadding",
        "PaddingCount",
        "LengthRemainder",
        "toolbelt.invalid.base64",
        'xs:base64Binary(sql:variable("@Canonical"))',
        "InvalidFormat",
    ):
        if marker not in decode_tvf:
            raise ContractError(f"Decode-Strukturvalidierung fehlt: {marker}")
    if "SVF_" in encode_tvf or "SVF_" in decode_tvf:
        raise ContractError("Eine inline TVF darf nicht die zugehörige SVF aufrufen.")
    require(encode_svf, r"TVF_Base64Encode\s*\(", "Encode-SVF-Wrapper")
    require(decode_svf, r"TVF_Base64Decode\s*\(", "Decode-SVF-Wrapper")
    if "WITH SCHEMABINDING" in encode_svf + decode_svf:
        raise ContractError(
            "SVF-Wrapper dürfen das Wiederholungsdeployment der TVF-Kerne "
            "nicht durch SCHEMABINDING blockieren."
        )
    if re.search(
        r"\bBASE64_(?:ENCODE|DECODE)\s*\(",
        encode_tvf + decode_tvf + encode_svf + decode_svf,
        re.I,
    ):
        raise ContractError("Portable Source darf native 2025-Funktionen nicht nutzen.")

    for source in (
        "TVF_Base64Encode.sql",
        "TVF_Base64Decode.sql",
        "SVF_Base64Encode.sql",
        "SVF_Base64Decode.sql",
    ):
        if deploy.count(f":r ../Source/{source}") != 1:
            raise ContractError(f"Deploy bindet {source} nicht exakt einmal ein.")

    if re.search(r"PropertyOrdinal\s+int\s+IDENTITY", deploy, re.I):
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
        "TVF_Base64Encode",
        "TVF_Base64Decode",
        "SVF_Base64Encode",
        "SVF_Base64Decode",
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

    required_vectors = ("Zg==", "Zm8=", "Zm9v", "yv7K/g==", "yv7K_g")
    for vector in required_vectors:
        if vector not in runtime:
            raise ContractError(f"Contract-Vektor fehlt: {vector}")
    for marker in ("SVF-/inline-TVF-Parität", "OUTER APPLY", "N'IF'"):
        if marker not in runtime and marker != "N'IF'":
            raise ContractError(f"Inline-TVF-Runtimevertrag fehlt: {marker}")
    if "'IF'" not in read("Tests/Runtime/Lifecycle.Contract.sql"):
        raise ContractError("Lifecycle prüft den inline-TVF-Objekttyp nicht.")
    if "SET QUOTED_IDENTIFIER ON;" not in runtime:
        raise ContractError(
            "Der direkte XML-basierte inline-TVF-Vertrag muss "
            "QUOTED_IDENTIFIER einschalten."
        )

    if "../../.github/workflows/base64-runtime.yml" not in manifest:
        raise ContractError("Runtime-Workflow ist im Manifest nicht gekoppelt.")

    print("Base64 statische Vertragsprüfung: erfolgreich")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ContractError as error:
        print(f"Base64 statische Vertragsprüfung: FEHLER: {error}", file=sys.stderr)
        raise SystemExit(1)
