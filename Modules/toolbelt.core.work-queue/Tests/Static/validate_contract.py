#!/usr/bin/env python3
from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
required = [
    "Source/WorkItem.sql",
    "Source/WorkQueueManagedGate.sql",
    "Source/USP_ClaimWorkCore.sql",
    "Source/USP_FailWorkCore.sql",
    "Source/USP_ScheduleWorkRetryCore.sql",
    "Source/VW_WorkQueue.sql",
    "Source/USP_EnqueueWork.sql",
    "Source/USP_ClaimWork.sql",
    "Source/USP_RenewWorkLease.sql",
    "Source/USP_RecoverExpiredWork.sql",
    "Source/USP_CompleteWork.sql",
    "Source/USP_FailWork.sql",
    "Source/USP_GetWorkStatus.sql",
    "Deployment/Deploy.sql",
    "Deployment/RepeatInstalledControl.Preflight.sql",
    "Deployment/RepeatInstalledControl.Cleanup.sql",
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
    "Tests/Runtime/UpgradeFrom2_0.Setup.sql",
    "Tests/Runtime/UpgradeFrom2_0.Verify.sql",
    "Tests/Runtime/RepeatCurrent.Setup.sql",
    "Tests/Runtime/RepeatCurrent.Verify.sql",
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


# Extracted cores remain private, and public wrappers cannot expose admission tokens.
for wrapper, core in (("USP_ClaimWork", "USP_ClaimWorkCore"), ("USP_FailWork", "USP_FailWorkCore"), ("USP_ScheduleWorkRetry", "USP_ScheduleWorkRetryCore")):
    text = (root / ("Source/" + wrapper + ".sql")).read_text(encoding="utf-8")
    if "EXEC toolbelt_core." + core not in text or "@ManagedAdmissionToken" in text:
        raise SystemExit("Öffentlicher Wrapper/Kern widerspricht dem privaten Admissionvertrag: " + wrapper)
claim = (root / "Source/USP_ClaimWorkCore.sql").read_text(encoding="utf-8")
for required_binding in ("PendingReservationId", "@@TRANCOUNT", "@ManagedReservationId", "AdmissionToken=NEWID()"):
    if required_binding not in claim:
        raise SystemExit("Transiente Admissionkopplung fehlt: " + required_binding)
for lifecycle in ("Deploy.sql", "Uninstall.sql"):
    text = (root / ("Deployment/" + lifecycle)).read_text(encoding="utf-8")
    if lifecycle == "Uninstall.sql" and text.count("Worker-Control-Consumer blockiert Queue-Lifecycle") != 2:
        raise SystemExit("Lifecycle muss Consumergrenze vor und unter Lifecyclelock prüfen: " + lifecycle)

deploy = (root / "Deployment/Deploy.sql").read_text(encoding="utf-8")
guard = (root / "Deployment/RepeatInstalledControl.Preflight.sql").read_text(encoding="utf-8")
cleanup = (root / "Deployment/RepeatInstalledControl.Cleanup.sql").read_text(encoding="utf-8")
if deploy.count("@RepeatGuard,N'@Fence bit',@Fence=0") != 2 or deploy.count("@RepeatGuard,N'@Fence bit',@Fence=1") != 1:
    raise SystemExit("Installierter Control-Repeat benötigt Preflight plus gefencten vollständigen Repeatguard")
if deploy.index("toolbelt.deploy.toolbelt.core.worker-control") > deploy.index("toolbelt.deploy.toolbelt.core.work-queue"):
    raise SystemExit("Lifecyclelockreihenfolge muss Control vor Queue bleiben")
if deploy.index("RAISERROR(N'Lifecycle") > deploy.index("SET NOCOUNT ON;") or "(@@OPTIONS&2)=2" not in deploy:
    raise SystemExit("Caller-/Implicittransaction muss vor SET-/Tempmutation abgewiesen werden")
fenced = re.findall(r"SELECT TOP\(1\) @FenceValue=1 FROM toolbelt_core\.(\w+) WITH\(TABLOCKX,HOLDLOCK\)", guard)
expected_fences = ["WorkQueueManagedGate", "WorkQueueScheduler", "WorkerControlConfiguration", "WorkerRegistration", "WorkerSlotReservation", "WorkerExecutionDisposition", "WorkerExecutionCommitWitness", "WorkItem", "WorkQueueBarrierBlocker"]
if fenced != expected_fences or "SET LOCK_TIMEOUT 0" not in guard or "TOP(0)" in guard or "NOWAIT" in guard:
    raise SystemExit("Repeat benötigt alle neun bounded physischen Tabellenfences in kanonischer Reihenfolge")
for table in expected_fences:
    if f"DROP TABLE IF EXISTS #tbx_Repeat_{table};" not in cleanup:
        raise SystemExit("Repeat hinterlässt erwartete Tempform: " + table)
for marker in ("SQL_VARIANT_PROPERTY", "DATALENGTH(required.ExpectedValue)", "c.user_type_id", "c.is_computed", "c.is_identity", "c.collation_name", "f.is_not_trusted=0", "c.is_not_trusted=1", "ColumnSignature", "@Quoted=1", "@Quoted=1-@Quoted", "State NOT IN(''COMMITTED'',''ROLLED_BACK'',''CLOSED'')", "PendingReservationId IS NULL", "Status=''CLAIMED'' OR ManagedHold=1", "WITH(READCOMMITTEDLOCK)"):
    if marker not in guard.replace("''", "'"):
        raise SystemExit("Installierter Repeatguard verliert Metadaten-/Literal-/Zustandsvertrag: " + marker)
for name in ("IX_WorkItem_Status_WorkItemId", "IX_WorkItem_WorkTypeId_Status_WorkItemId", "IX_WorkItem_Status_LeaseUntilUtc_WorkItemId", "UX_WorkItem_WorkType_IdempotencyKey", "IX_WorkItem_Scheduling"):
    if f"INDEX {name} ON #tbx_Repeat_WorkItem" not in guard:
        raise SystemExit("Kanonische WorkItem-Indexform fehlt im Repeatgate: "+name)
if deploy.count("IF @@LOCK_TIMEOUT<>-1")!=1 or deploy.count("SET LOCK_TIMEOUT 5000;")!=1 or deploy.count("SET LOCK_TIMEOUT -1;")!=3:
    raise SystemExit("Installierter Repeat muss Standardtimeout verlangen, Source-DDL begrenzen und verfügbare Pfade wiederherstellen")

# Missing singleton must not be mistaken for a disabled managed gate.
for lifecycle in ("Deploy.sql", "Uninstall.sql"):
    text=(root / "Deployment" / lifecycle).read_text(encoding="utf-8")
    if "DECLARE @QueueManagedActive bit=NULL" not in text or "SET @QueueManagedActive=NULL" not in text:
        raise SystemExit("Fehlender Singleton könnte als disabled durchlaufen")

# Regression: the extracted private terminal kernels must declare their emission
# switch, rather than merely referring to it (native SQL137).
import re
for name in ("USP_FailWorkCore", "USP_ScheduleWorkRetryCore"):
    text=(root / "Source" / (name+".sql")).read_text(encoding="utf-8")
    signature=re.search(r"CREATE OR ALTER PROCEDURE[\s\S]*?\bAS\b",text,re.I).group(0)
    if not re.search(r"@EmitResult\s+bit\s*=\s*1",signature,re.I):
        raise SystemExit("Private EmitResult-Deklaration fehlt: "+name)

print("Work Queue statische Vertragsprüfung: erfolgreich")

# Die V1-Neuanlage gilt nur für die neue Basistabelle. Im bestehenden Pfad
# darf kein Zwischencheck die drei gültigen W6c-Zustände ausschließen.
item = (root / "Source/WorkItem.sql").read_text(encoding="utf-8")
existing_path = item.split("ELSE\nBEGIN", 1)[1]
if "ADD CONSTRAINT CK_WorkItem_StateMetadata" in existing_path.partition("/* W6c ergänzt")[0]:
    raise SystemExit("Repeat validiert bestehende Queue gegen veralteten V1-Zustandscheck")
adapter = (root.parents[1] / "Workers/ExternalQueue/Tests/Runtime/Invoke-Contract.ps1").read_text(encoding="utf-8")
for repeat_artifact in ("RepeatCurrent.Setup.sql", "RepeatCurrent.Verify.sql"):
    if repeat_artifact not in adapter or repeat_artifact not in (root / "module.yaml").read_text(encoding="utf-8"):
        raise SystemExit("Befüllter Repeatnachweis nicht im Adapter/Manifest gekoppelt")

claim=(root / "Source/USP_ClaimWorkCore.sql").read_text(encoding="utf-8")
if "@ClaimedWorkItemId bigint = NULL OUTPUT" not in claim or "SELECT @ClaimedWorkItemId=WorkItemId FROM @Claimed" not in claim:
    raise SystemExit("Privater Claimtransport muss aus kanonischem UPDATE OUTPUT entstehen")
if "IF @ResultTable IS NOT NULL" not in claim or "USP_PrepareResultTable @ResultTableToAlter=@ResultTable" not in claim:
    raise SystemExit("Öffentliche ResultTable-Validierung darf nicht umgangen werden")
