#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = (
    "Source/FileContentRootAllowlist.sql",
    "Source/USP_LoadBinaryFile.sql",
    "Source/USP_LoadTextFile.sql",
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Examples/FileContent.sql",
    "README.md",
    "Documentation/USP_LoadBinaryFile.md",
    "Documentation/USP_LoadTextFile.md",
    "Tests/FILE_CONTENT_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/FileContent.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "module.yaml",
)
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

binary_source = (root / "Source/USP_LoadBinaryFile.sql").read_text("utf-8")
for marker in (
    "CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadBinaryFile]",
    "@FilePath  nvarchar(4000)",
    "@MaxBytes  bigint       = NULL",
    "@Debug     tinyint      = 0",
    "@Hilfe     bit          = 0",
    "OPENROWSET(BULK",
    "SINGLE_BLOB",
    "Latin1_General_100_BIN2",
    "51320",
    "51321",
    "51322",
    "51323",
    "IsValid",
    "ValidationCode",
    "ValidationMessage",
):
    if marker not in binary_source:
        raise SystemExit(f"LoadBinaryFile-Vertragsmarker fehlt: {marker}")

text_source = (root / "Source/USP_LoadTextFile.sql").read_text("utf-8")
for marker in (
    "CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadTextFile]",
    "@FilePath          nvarchar(4000)",
    "@FallbackEncoding  nvarchar(128) = N'Windows-1252'",
    "@MaxBytes          bigint        = NULL",
    "@Debug             tinyint       = 0",
    "@Hilfe             bit           = 0",
    "OPENROWSET(BULK",
    "SINGLE_BLOB",
    "CODEPAGE",
    "EncodingDetected",
    "BomPresent",
    "51324",
    "IsValid",
    "ValidationCode",
    "ValidationMessage",
):
    if marker not in text_source:
        raise SystemExit(f"LoadTextFile-Vertragsmarker fehlt: {marker}")

print("File Content statische Vertragsprüfung: erfolgreich")
