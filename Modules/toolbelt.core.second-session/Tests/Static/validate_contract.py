#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = [
    "Source/SecondSessionProvider.sql",
    "Source/VW_SecondSessionProviders.sql",
    "Source/USP_SecondSessionProbe.sql",
    "Source/USP_DispatchWorkType.sql",
    "Source/USP_ConfigureSecondSessionLoopback.sql",
    "Source/USP_ExecuteWorkTypeInNewSession.sql",
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "README.md",
    "Documentation/SECOND_SESSION_OBJECTS.md",
    "Tests/SECOND_SESSION_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/SecondSession.Contract.sql",
    "Tests/Runtime/Concurrency.Contract.sql",
    "Tests/Runtime/Concurrency.Verify.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/Central.Contract.sql",
    "Tests/Runtime/RepeatCurrent.Contract.sql",
    "Tests/Runtime/RepeatCurrent.Capture.sql",
    "Tests/Runtime/RepeatCurrent.Assert.sql",
    "module.yaml",
]
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

source = "\n".join(
    (root / path).read_text(encoding="utf-8")
    for path in required
    if path.startswith("Source/")
)
for marker in (
    "CREATE TABLE [toolbelt_core].[SecondSessionProvider]",
    "PK_SecondSessionProvider",
    "USP_ConfigureSecondSessionLoopback",
    "USP_ExecuteWorkTypeInNewSession",
    "USP_DispatchWorkType",
    "USP_SecondSessionProbe",
    "remote proc transaction promotion",
    "is_remote_proc_transaction_promotion_enabled",
    "WITH RESULT SETS NONE",
    "TVF_CurrentExecutionContext",
    "USP_BeginExecution",
    "USP_EndExecution",
    "JSON_PAYLOAD",
    "HAS_PERMS_BY_NAME",
    "@SuppressResult",
):
    if marker not in source:
        raise SystemExit("Vertragsmarker fehlt: " + marker)

module_text = "\n".join(
    (root / path).read_text(encoding="utf-8")
    for path in required
    if path.startswith("Source/") or path.startswith("Deployment/")
)
for forbidden in (
    "sp_addlinkedserver",
    "sp_addlinkedsrvlogin",
    "@rmtpassword",
    "TRUSTWORTHY ON",
    "clr strict security",
):
    if forbidden.lower() in module_text.lower():
        raise SystemExit("Verbotener Lifecycle-/Security-Marker: " + forbidden)

execute_source = (root / "Source/USP_ExecuteWorkTypeInNewSession.sql").read_text(encoding="utf-8")
if "@Sql" in execute_source or "@Command" in execute_source:
    raise SystemExit("Die öffentliche Second-Session-API darf keinen Raw-SQL-Parameter anbieten.")

manifest = (root / "module.yaml").read_text(encoding="utf-8")
if manifest.count("\nvalidation_evidence:\n") != 1:
    raise SystemExit("Das Second-Session-Manifest muss genau einen validation_evidence-Block besitzen.")
for dependency_contract in (
    'module_id: "toolbelt.core.result-table"\n    minimum_version: "1.0.0"',
    'module_id: "toolbelt.core.execution-context"\n    minimum_version: "1.0.0"',
    'module_id: "toolbelt.core.work-type"\n    minimum_version: "1.1.0"',
):
    if dependency_contract not in manifest:
        raise SystemExit("Second-Session-Abhängigkeitsvertrag fehlt oder ist falsch: " + dependency_contract.replace("\n", " / "))

view_source = (root / "Source/VW_SecondSessionProviders.sql").read_text(encoding="utf-8")
configure_source = (root / "Source/USP_ConfigureSecondSessionLoopback.sql").read_text(encoding="utf-8")
for marker, text in (
    ("s.name COLLATE Latin1_General_100_BIN2", view_source),
    ("p.[LinkedServerName] COLLATE Latin1_General_100_BIN2", view_source),
    ("s.name COLLATE Latin1_General_100_BIN2", configure_source),
    ("@LinkedServerName COLLATE Latin1_General_100_BIN2", configure_source),
):
    if marker not in text:
        raise SystemExit("Cross-Database-Collation-Vertrag fehlt: " + marker)

repeat = (root / "Tests/Runtime/RepeatCurrent.Contract.sql").read_text("utf-8")
capture = (root / "Tests/Runtime/RepeatCurrent.Capture.sql").read_text("utf-8")
assertion = (root / "Tests/Runtime/RepeatCurrent.Assert.sql").read_text("utf-8")
for include, count in ((":r Deploy.sql", 2),
                       (":r ../Tests/Runtime/RepeatCurrent.Capture.sql", 3),
                       (":r ../Tests/Runtime/RepeatCurrent.Assert.sql", 2)):
    if repeat.count(include) != count:
        raise SystemExit("Befüllter Provider-Repeat benötigt zwei echte Deploys mit identischen Orakeln.")
for marker in ("CONVERT(varbinary(max), ProviderName)", "CONVERT(varbinary(max), LinkedServerName)",
               "IsEnabled", "CreatedAtUtc", "CONVERT(varbinary(max), CreatedBy)",
               "ModifiedAtUtc", "CONVERT(varbinary(max), ModifiedBy)", "CONVERT(binary(8), RowVersion)",
               "sys.objects", "sys.schemas", "sys.tables", "sys.columns", "sys.indexes",
               "sys.index_columns", "sys.key_constraints", "sys.default_constraints",
               "sys.check_constraints", "sys.foreign_keys", "sys.foreign_key_columns",
               "sys.triggers", "sys.database_permissions", "sys.extended_properties"):
    if marker not in capture:
        raise SystemExit("Provider-Repeat-Snapshot fehlt: " + marker)
if assertion.count("EXCEPT") != 2 or "@@TRANCOUNT <> 0" not in assertion or "XACT_STATE() <> 0" not in assertion:
    raise SystemExit("Provider-Repeat muss bidirektional vergleichen und den Sessionabschluss prüfen.")
if repeat.count("sys.sp_addextendedproperty @name = N'MS_Description'") != 2 or repeat.count(
        "sys.sp_dropextendedproperty @name = N'MS_Description'") != 2:
    raise SystemExit("Provider-Repeat muss eigene Tabellen-/Spaltenbeschreibungen prüfen und bereinigen.")
for forbidden in ("EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback",
                  "EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession", "sp_addlinkedserver",
                  "sp_addlinkedsrvlogin", "sp_serveroption", "sp_configure"):
    if forbidden.lower() in repeat.lower():
        raise SystemExit("Der Tabellenrepeat darf keine Providerverwaltung oder RPC ausführen: " + forbidden)

print("Second Session statische Vertragsprüfung: erfolgreich")
