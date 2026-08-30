#!/usr/bin/env python3
from pathlib import Path

root = Path(__file__).resolve().parents[2]
required = [
    "Source/WorkItem.sql",
    "Source/VW_WorkQueue.sql",
    "Source/USP_EnqueueWork.sql",
    "Source/USP_ClaimWork.sql",
    "Source/USP_RenewWorkLease.sql",
    "Source/USP_RecoverExpiredWork.sql",
    "Source/USP_CompleteWork.sql",
    "Source/USP_FailWork.sql",
    "Source/USP_GetWorkStatus.sql",
    "Deployment/Deploy.sql",
    "Deployment/Uninstall.sql",
    "Documentation/WORK_QUEUE_OBJECTS.md",
    "Examples/WorkQueue.sql",
    "Tests/WORK_QUEUE_CONTRACT_TEST_MATRIX.md",
    "Tests/README.md",
    "Tests/Runtime/WorkQueue.Contract.sql",
    "Tests/Runtime/Lifecycle.Contract.sql",
    "Tests/Runtime/Central.Contract.sql",
    "Tests/Runtime/Concurrency.Contract.sql",
    "Tests/Runtime/Concurrency.Verify.sql",
    "Tests/Runtime/UpgradeFrom1_0.Setup.sql",
    "Tests/Runtime/UpgradeFrom1_0.Verify.sql",
    "module.yaml",
    "README.md",
]
missing = [path for path in required if not (root / path).is_file()]
if missing:
    raise SystemExit("Fehlende Artefakte: " + ", ".join(missing))

sql_paths = [path for path in required if path.startswith(("Source/", "Deployment/"))]
sql = "\n".join((root / path).read_text(encoding="utf-8") for path in sql_paths)
for marker in (
    "CREATE TABLE [toolbelt_core].[WorkItem]",
    "PK_WorkItem",
    "FK_WorkItem_WorkType",
    "CK_WorkItem_StateMetadata",
    "IX_WorkItem_Status_WorkItemId",
    "USP_EnqueueWork",
    "USP_ClaimWork",
    "USP_RenewWorkLease",
    "USP_RecoverExpiredWork",
    "USP_CompleteWork",
    "USP_FailWork",
    "USP_GetWorkStatus",
    "VW_WorkQueue",
    "UPDLOCK, READPAST, READCOMMITTEDLOCK, ROWLOCK",
    "ClaimToken",
    "ClaimGeneration",
    "LeaseUntilUtc",
    "LastHeartbeatAtUtc",
    "RecoveryCount",
    "IX_WorkItem_Status_LeaseUntilUtc_WorkItemId",
    "DATALENGTH(@PayloadJson) > 65536",
    "ConfirmNoExternalConsumers",
    "AllowDataLoss",
):
    if marker not in sql:
        raise SystemExit("Vertragsmarker fehlt: " + marker)

view = (root / "Source/VW_WorkQueue.sql").read_text(encoding="utf-8")
for forbidden_view_column in ("ClaimToken", "PayloadJson"):
    if forbidden_view_column in view:
        raise SystemExit("Statussicht legt geschützte Spalte offen: " + forbidden_view_column)

for forbidden in (
    "sp_addlinkedserver",
    "sp_addlinkedsrvlogin",
    "TRUSTWORTHY ON",
    "xp_cmdshell",
    "sp_start_job",
    "KILL ",
):
    if forbidden.lower() in sql.lower():
        raise SystemExit("Verbotener Provider-/Security-Marker: " + forbidden)

print("Work Queue statische Vertragsprüfung: erfolgreich")
