#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = (
    "Source/TVF_JsonPathExists.sql",
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Examples/JsonPathExists.sql",
    "README.md",
    "Documentation/TVF_JsonPathExists.md",
    "Tests/JSON_PATH_EXISTS_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/JsonPathExists.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/Central.Contract.sql",
    "module.yaml",
)
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

source = (root / "Source/TVF_JsonPathExists.sql").read_text("utf-8")
for marker in (
    "RETURNS @Result TABLE",
    "ISJSON",
    "OPENJSON",
    "Latin1_General_100_BIN2",
    "SegmentType",
    "PathExists int NULL",
):
    if marker not in source:
        raise SystemExit(f"JSON-Path-Vertragsmarker fehlt: {marker}")

if "CREATE OR ALTER FUNCTION [toolbelt_json].[SVF_" in source:
    raise SystemExit("Version 1 darf keinen Scalar-Wrapper einführen.")

print("JSON Path Exists statische Vertragsprüfung: erfolgreich")
