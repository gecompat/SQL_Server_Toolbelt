#!/usr/bin/env python3
"""Prüft den öffentlichen Safe-Cast-Vertrag und gekoppelte Artefakte, keine SQL-Runtime."""
from pathlib import Path
import re
import sys
import subprocess

ROOT = Path(__file__).resolve().parents[2]
TARGETS = {"BigInt": "bigint", "Decimal": "decimal(38,18)", "Date": "date", "DateTime2": "datetime2(7)", "Bit": "bit", "UniqueIdentifier": "uniqueidentifier"}

def require(condition, label):
    if not condition:
        raise AssertionError(label)

def read(path):
    target = ROOT / path
    require(target.is_file(), "Pflichtartefakt fehlt: " + path)
    return target.read_text(encoding="utf-8-sig")

def main():
    manifest = read("module.yaml")
    deploy = read("Deployment/Deploy.sql")
    uninstall = read("Deployment/Uninstall.sql")
    lifecycle = "\n".join(p.read_text(encoding="utf-8-sig") for p in (ROOT / "Deployment").glob("*.sql"))
    actual = sorted(p.name for p in (ROOT / "Source").glob("*.sql"))
    expected = sorted("TVF_TryCast" + name + ".sql" for name in TARGETS)
    require(actual == expected, "Genau sechs öffentliche Source-Artefakte, keine Helperfassade")
    for name, sql_type in TARGETS.items():
        object_name = "TVF_TryCast" + name
        source = read("Source/" + object_name + ".sql")
        normalized = re.sub(r"\s+", "", source).lower()
        require(re.search(r"CREATE\s+(?:OR\s+ALTER\s+)?FUNCTION\s+(?:\[?toolbelt_conversion\]?\.)\[?" + object_name + r"\]?\s*\(", source, re.I), object_name + " Objektname")
        require(re.search(r"@Text\s+nvarchar\(max\)\s*,\s*@MaxInputBytes\s+int\s*=\s*8192", source, re.I), object_name + " Parameter/Default")
        require(re.search(r"RETURNS\s+TABLE\s+WITH\s+SCHEMABINDING\s+AS\s+RETURN\s*\(", source, re.I), object_name + " echter Inlinekern")
        require("datalength(" in normalized and "latin1_general_100_bin2" in normalized, object_name + " Byte-/Codeeinheitenvertrag")
        require(sql_type in normalized, object_name + " fester Zieltyp")
        require("varchar(16)" in normalized and "varchar(32)" in normalized and "isnull(" in normalized, object_name + " explizite Status-/Code-/NOTNULL-Projektion")
        for field in ("Objekt:", "Zweck:", "Vertrag:", "Parameter:", "Resultset:", "Dependencies:", "Rechte:", "Versionen:", "Plattformen:", "Fehlerverhalten:", "Performance:", "Einschränkungen:"):
            require(field in source, object_name + " Header " + field)
        # Keine Scalar-/CLR-/Hostfassade, mutierenden Statements oder Rekursionsabhängigkeit.
        executable = re.sub(r"--[^\n]*", "", source)
        # Projektionsterne sind mit SCHEMABINDING unzulässig; arithmetische Produkte bleiben erlaubt.
        projection_star = r"(?:\bSELECT|,)\s*(?:DISTINCT\s+|ALL\s+)?(?:(?:\[[^\]]+\]|\w+)\s*\.\s*)?\*(?=\s*(?:,|\bFROM|\bAS|\)))"
        require(not re.search(projection_star, executable, re.I), object_name + " explizite schemagebundene Spaltenprojektionen")
        require(not re.search(r"\b(?:EXEC(?:UTE)?|OPENROWSET|OPENQUERY|xp_\w+|SVF_\w+|INSERT|UPDATE|DELETE|MERGE|THROW|RAISERROR)\b", executable, re.I), object_name + " reine relationale Source")
        require(not re.search(r"(?<!TRY_)\bCONVERT\s*\(\s*(?:bigint|decimal\s*\(\s*38\s*,\s*18\s*\)|date|datetime2\s*\(\s*7\s*\)|bit|uniqueidentifier)\s*,\s*@Text\b", executable, re.I), object_name + " keine gefährliche direkte Zielkonversion des Rohinputs")
        require(object_name in manifest and object_name in lifecycle, object_name + " Manifest/Lifecycle-Slots gekoppelt")
        # Die atomaren CREATE-Batches sind generierte SQL-Literale, keine zweite Fachimplementierung.
        require(object_name + ".sql" in read("Deployment/CreateObjects.sql"), object_name + " generierter Sourcepayload")
        read("Documentation/" + object_name + ".md")
    for fixture in ("Contract.Tests.sql", "Lifecycle.Tests.sql", "Metadata.Tests.ps1"):
        require(fixture in manifest, "Manifest-Testkopplung " + fixture)
        read("Tests/Runtime/" + fixture)
    require(not re.search(r"QUOTENAME\s*\(\s*@Collation\s*\)", read("Tests/Runtime/Contract.Tests.sql"), re.I),
            "COLLATE verwendet ausschließlich die festen unquotierten Fixturecollations")
    for status in ("OK", "SQL_NULL", "EMPTY", "INVALID_ARGUMENT", "INVALID_FORMAT", "OUT_OF_RANGE", "LOSSY", "LIMIT"):
        require(status in read("Tests/Runtime/Contract.Tests.sql"), "Unabhängiger Statusoracle " + status)
    require("clr:" in manifest and re.search(r"used:\s*false", manifest), "Kein CLR-Provider")
    subprocess.run([sys.executable, str(ROOT / "Scripts/generate-deployment.py")], check=True, timeout=30)
    print("Safe Cast statischer Vertrag PASS; keine Runtimequalifikation.")
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except (AssertionError, OSError, subprocess.SubprocessError) as error:
        print("Safe Cast statischer Vertrag FAIL: " + str(error), file=sys.stderr)
        sys.exit(1)
