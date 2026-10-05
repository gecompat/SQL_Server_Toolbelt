#!/usr/bin/env python3
"""Prüft Pointer-Artefaktkopplung und öffentliche Grenzen; kein Runtimebeweis."""
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def require(condition, label):
    if not condition:
        raise AssertionError(label)


def read(relative):
    path = ROOT / relative
    require(path.is_file(), "Pflichtartefakt fehlt: " + relative)
    return path.read_text(encoding="utf-8-sig")


def main():
    source = read("Source/TVF_ResolveJsonPointer.sql")
    executable = re.sub(r"--[^\n]*", "", source)
    require(sorted(p.name for p in (ROOT / "Source").rglob("*.sql")) == ["TVF_ResolveJsonPointer.sql"], "Genau ein kanonischer Sourcekern")
    require(len(re.findall(r"\bCREATE\s+(?:OR\s+ALTER\s+)?FUNCTION\b", executable, re.I)) == 1, "Genau eine Function, kein Helper")
    signature = r"CREATE\s+FUNCTION\s+toolbelt_json\.TVF_ResolveJsonPointer\s*\(\s*@Json\s+nvarchar\(max\)\s*,\s*@Pointer\s+nvarchar\(max\)\s*,\s*@MaxInputBytes\s+bigint\s*=\s*16777216\s*,\s*@MaxDepth\s+int\s*=\s*128\s*\)"
    require(re.search(signature, executable, re.I), "Öffentliche Vierparameter-Signatur/Defaults")
    columns = r"RETURNS\s+@\w+\s+TABLE\s*\(\s*Status\s+varchar\(16\)\s+COLLATE\s+Latin1_General_100_BIN2\s+NOT\s+NULL\s*,\s*JsonType\s+varchar\(8\)\s+COLLATE\s+Latin1_General_100_BIN2\s+NULL\s*,\s*Value\s+nvarchar\(max\)\s+COLLATE\s+Latin1_General_100_BIN2\s+NULL\s*,\s*ErrorCode\s+varchar\(32\)\s+COLLATE\s+Latin1_General_100_BIN2\s+NULL\s*\)"
    require(re.search(columns, executable, re.I), "MSTVF mit genau vier typisierten BIN2-Spalten")
    require(not re.search(r"\b(?:EXEC(?:UTE)?|OPENROWSET|OPENQUERY|EXTERNAL\s+NAME|CREATE\s+ASSEMBLY|SVF_\w+|THROW|RAISERROR|WAITFOR)\b", executable, re.I), "Keine neue Ausführungs-/CLR-/Helpergrenze")
    require("ISJSON(" in executable.upper() and "OPENJSON(" in executable.upper(), "Kanonischer nativer Parserpfad")
    require("DATALENGTH(" in executable.upper() and "16777216" in executable and "4000" in executable and "128" in executable, "Öffentliche Byte-/Pointer-/Tiefengrenzen vorhanden")
    require(not re.search(r"TRY_(?:CAST|CONVERT)\s*\([^\n]*(?:float|decimal|bigint)", executable, re.I), "Kein Zahlen-/Indexoverflowpfad durch native numerische Rohkonversion")
    manifest = read("module.yaml")
    for filename in ("Contract.Tests.sql", "Safety.Tests.sql", "Lifecycle.Tests.sql", "Metadata.Tests.ps1"):
        require(filename in manifest, "Manifest-Testkopplung " + filename)
        fixture = read("Tests/Runtime/" + filename)
        if filename.endswith(".sql"):
            require("$(ToolbeltDatabase)" in fixture, "Direkter lokaler/zentraler Fixtureparameter " + filename)
            require(not re.search(r"\bINSERT\s+[^;]*\bEXEC\b", fixture, re.I), "Kein INSERT EXEC " + filename)
    require(re.search(r"clr:\s*\n\s*used:\s*false", manifest), "Kein CLR-Provider")
    require("TVF_ResolveJsonPointer" in manifest, "Öffentlicher Slot im Manifest")
    contract = read("Tests/Runtime/Contract.Tests.sql")
    safety = read("Tests/Runtime/Safety.Tests.sql")
    for status in ("FOUND", "MISSING", "JSON_NULL", "SQL_NULL", "INVALID"):
        require(status in contract + safety, "Fester Statusoracle " + status)
    for code in ("PARAMETER", "INPUT_LIMIT", "POINTER_LIMIT", "POINTER_SYNTAX", "JSON_SYNTAX", "DEPTH_LIMIT", "UNICODE", "DUPLICATE_KEY", "ARRAY_INDEX"):
        require(code in contract + safety, "Fester Fehleroracle " + code)
    require("0x3DD800DE" in safety and "@Deep128" in safety and "@Deep129" in safety, "Unabhängige UTF16-/Tiefenfixtures")
    require(not re.search(r"QUOTENAME\s*\(\s*@Collation\s*\)", contract + safety, re.I), "Feste Fixturecollations werden nicht als Identifier geklammert")
    read("Deployment/Deploy.sql")
    read("Deployment/Uninstall.sql")
    read("Deployment/CreateObjects.sql")
    subprocess.run([sys.executable, str(ROOT / "Scripts/generate-deployment.py")], check=True, timeout=30)
    print("Pointer statischer Vertrag PASS; keine Runtimequalifikation.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (AssertionError, OSError, subprocess.SubprocessError) as error:
        print("Pointer statischer Vertrag FAIL: " + str(error), file=sys.stderr)
        sys.exit(1)
