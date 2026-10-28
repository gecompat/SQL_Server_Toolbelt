#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
required = (
    "Source/FileContentRootAllowlist.sql",
    "Source/FileContentRootPredicate.sql",
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
    "Tests/Runtime/RootBoundary.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/RepeatCurrent.Contract.sql",
    "Tests/Runtime/RepeatCurrent.Capture.sql",
    "Tests/Runtime/RepeatCurrent.Assert.sql",
    "module.yaml",
)
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

binary_source = (root / "Source/USP_LoadBinaryFile.sql").read_text("utf-8")
allowlist_source = (root / "Source/FileContentRootAllowlist.sql").read_text("utf-8")
for marker in (
    "IF OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U') IS NULL",
    "sys.sp_updateextendedproperty",
    "sys.sp_addextendedproperty",
):
    if marker not in allowlist_source:
        raise SystemExit(f"Allowlist-Lifecycle-Marker fehlt: {marker}")
for marker in (
    "CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadBinaryFile]",
    "@FilePath  nvarchar(4000) = NULL",
    "@MaxBytes  bigint       = NULL",
    "@Debug     tinyint      = 0",
    "@Hilfe     bit          = 0",
    "@ResultTable sysname    = NULL",
    "@KeepData bit           = 0",
    "toolbelt_core.USP_PrepareResultTable",
    "OPENROWSET(BULK",
    "SINGLE_BLOB",
    "51320",
    "51321",
    "51322",
    "51323",
    "51326",
    "IsValid",
    "ValidationCode",
    "ValidationMessage",
):
    if marker not in binary_source:
        raise SystemExit(f"LoadBinaryFile-Vertragsmarker fehlt: {marker}")

text_source = (root / "Source/USP_LoadTextFile.sql").read_text("utf-8")
for name, source in (("LoadBinaryFile", binary_source), ("LoadTextFile", text_source)):
    signature = re.search(r"CREATE OR ALTER PROCEDURE[^\(]*\((.*?)\)\s*AS", source, re.S | re.I)
    if not signature or re.findall(r"@([A-Za-z]\w*)", signature.group(1))[-4:] != [
        "ResultTable", "KeepData", "Debug", "Hilfe"
    ]:
        raise SystemExit(f"{name}: Standardparameter-Reihenfolge verletzt USP_CONTRACT.")
for marker in (
    "CREATE OR ALTER PROCEDURE [toolbelt_file].[USP_LoadTextFile]",
    "@FilePath          nvarchar(4000) = NULL",
    "@FallbackEncoding  nvarchar(128) = N'Windows-1252'",
    "@MaxBytes          bigint        = NULL",
    "@Debug             tinyint       = 0",
    "@Hilfe             bit           = 0",
    "@ResultTable       sysname       = NULL",
    "@KeepData          bit           = 0",
    "toolbelt_core.USP_PrepareResultTable",
    "OPENROWSET(BULK",
    "SINGLE_BLOB",
    "EncodingDetected",
    "BomPresent",
    "51324",
    "51325",
    "51326",
    "IsValid",
    "ValidationCode",
    "ValidationMessage",
):
    if marker not in text_source:
        raise SystemExit(f"LoadTextFile-Vertragsmarker fehlt: {marker}")

predicate_source = (root / "Source/FileContentRootPredicate.sql").read_text("utf-8")
runtime_source = (root / "Tests/Runtime/FileContent.Contract.sql").read_text("utf-8")
boundary_source = (root / "Tests/Runtime/RootBoundary.Contract.sql").read_text("utf-8")
if runtime_source.count(":r RootBoundary.Contract.sql") != 1 or boundary_source.count(
        ":r ../../Source/FileContentRootPredicate.sql") != 1:
    raise SystemExit("Native Grenztests müssen eingebunden sein und das echte Prädikat verwenden.")
for marker in ("DATALENGTH(normalized.NormalizedRoot) > 0",
               "CAST(normalized.NormalizedRoot AS nvarchar(max))",
               "DATALENGTH(@NormalizedPath) = DATALENGTH(normalized.NormalizedRoot)",
               "LEFT(@NormalizedPath COLLATE Latin1_General_100_BIN2",
               "DATALENGTH(boundary.DirectoryPrefix) / 2"):
    if marker not in predicate_source:
        raise SystemExit(f"Root-Grenzvertrag fehlt: {marker}")
if "LIKE" in predicate_source.upper() or "CREATE " in predicate_source.upper():
    raise SystemExit("Root-Prädikat muss literal sein und darf kein SQL-Objekt anlegen.")
for source in (binary_source, text_source):
    if source.count(":r ../Source/FileContentRootPredicate.sql") != 1:
        raise SystemExit("Beide Fassaden müssen dasselbe kanonische Root-Prädikat verwenden.")
    if "FROM [toolbelt_file].[FileContentRootAllowlist]" in source:
        raise SystemExit("Kein paralleles Root-Prädikat in einer Fassade.")
    preflight = re.search(r"(?m)^\s*EXEC toolbelt_core\.USP_PrepareResultTable\b", source)
    sql_assignment = source.find("SET @Sql = N")
    file_read = source.find("OPENROWSET(BULK", sql_assignment)
    if preflight is None or sql_assignment < 0 or file_read < 0 or preflight.start() > file_read:
        raise SystemExit("ResultTable-Preflight muss vor Datei-I/O erfolgen.")
    if "ROLLBACK TRANSACTION @SavepointName" not in source or "ROLLBACK TRANSACTION;" not in source:
        raise SystemExit("ResultTable-Fehlerpfad muss eigene Transaktion und Savepoint kontrolliert zurückrollen.")
    if "@SavepointCreated bit = 0" not in source or source.count("SET @SavepointCreated = 1;") != 1:
        raise SystemExit("Savepoint-Rollback benötigt einen expliziten Nachweis des erfolgreich angelegten Savepoints.")
    if source.count("ELSE IF @SavepointCreated = 1 AND XACT_STATE() = 1 ROLLBACK TRANSACTION @SavepointName") != 2:
        raise SystemExit("Beide ResultTable-CATCH-Pfade müssen nur einen tatsächlich angelegten Savepoint zurückrollen.")
    if "IF @ResultTable IS NOT NULL AND @InitialTransactionCount > 0 AND XACT_STATE() <> 1" not in source:
        raise SystemExit("Ein uncommittable Callerzustand muss vor dem ResultTable-Tempobjekt abgewiesen werden.")
    if "Datei konnte nicht ueber OPENROWSET gelesen werden. Engine-Meldung:" not in source:
        raise SystemExit("OPENROWSET-Fehler muss einen Kontext vor der Engine-Meldung ausgeben.")
if "@HeaderProviderError" not in text_source or "@ContentProviderError" not in text_source:
    raise SystemExit("Die beiden OPENROWSET-Fehlerpfade müssen eindeutige Variablen im Procedure-Scope verwenden.")

repeat_source = (root / "Tests/Runtime/RepeatCurrent.Contract.sql").read_text("utf-8")
repeat_capture = (root / "Tests/Runtime/RepeatCurrent.Capture.sql").read_text("utf-8")
repeat_assert = (root / "Tests/Runtime/RepeatCurrent.Assert.sql").read_text("utf-8")
for include, count in ((":r Deploy.sql", 2),
                       (":r ../Tests/Runtime/RepeatCurrent.Capture.sql", 3),
                       (":r ../Tests/Runtime/RepeatCurrent.Assert.sql", 2)):
    if repeat_source.count(include) != count:
        raise SystemExit("Befüllter Repeat muss zweimal das echte Deployment mit denselben Orakeln ausführen.")
for marker in ("CONVERT(varbinary(max), RootPath)", "CONVERT(varbinary(max), Description)",
               "CreatedAt", "sys.identity_columns", "last_value", "IDENT_CURRENT",
               "sys.columns", "sys.indexes", "sys.index_columns", "sys.key_constraints",
               "sys.default_constraints", "sys.check_constraints", "sys.foreign_keys",
               "sys.foreign_key_columns", "sys.triggers", "sys.database_permissions",
               "sys.extended_properties"):
    if marker not in repeat_capture:
        raise SystemExit(f"Repeat-Snapshot-Vertrag fehlt: {marker}")
if repeat_assert.count("EXCEPT") != 2 or "N'MS_Description'" not in repeat_assert:
    raise SystemExit("Repeat muss bidirektional vergleichen und die kanonische Beschreibung separat prüfen.")

print("File Content statische Vertragsprüfung: erfolgreich")

if text_source.count("FROM OPENROWSET(BULK") != 1 or "SINGLE_CLOB" in text_source or "SINGLE_NCLOB" in text_source:
    raise SystemExit("Textloader muss ausschließlich einen SINGLE_BLOB-Snapshot dekodieren.")
for token in ("@Snapshot", "@Payload", "Latin1_General_100_BIN2_UTF8"):
    if token not in text_source: raise SystemExit("Snapshotdecoder fehlt: " + token)
