#!/usr/bin/env python3
"""Scopebezogene Artefakt-/Sicherheitskopplung; kein Runtime-PASS."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[2]
sources={p.stem:p.read_text(encoding="utf-8") for p in (root/"Source").glob("*.sql")}
manifest=(root/"module.yaml").read_text(encoding="utf-8")
for name,text in sources.items():
    if name.startswith("USP_"):
        if name not in manifest or f"../Source/{name}.sql" not in (root/"Deployment/Deploy.sql").read_text(encoding="utf-8"):
            raise SystemExit("Fehlende Manifest/Lifecycle-Kopplung: "+name)
        for parameter in ("@Debug", "@Hilfe"):
            if parameter not in text: raise SystemExit("USP-Standard fehlt: "+name+parameter)
    if re.search(r"\b(?:KILL|GRANT)\s",text,re.I): raise SystemExit("Verbotene Rechte-/Provideroperation: "+name)
# A commit witness must be written before handler execution within the actual caller TX.
witness=sources["USP_BeginWorkerTransactionWitness"]
if "@@TRANCOUNT<>1" not in witness or "INSERT toolbelt_core.WorkerExecutionCommitWitness" not in witness:
    raise SystemExit("Prehandler-Transaktionswitnessvertrag fehlt")
# Stop must test completed queue state separately before reading an uncommitted witness.
stop=sources["USP_StopWorkerExecution"]
if stop.index("@IsCompleted") > stop.index("WorkerExecutionCommitWitness"):
    raise SystemExit("Stop liest Witness vor isoliertem Completiontest")
group=sources["USP_StopWorkers"]
if "SET LOCK_TIMEOUT 0" not in group or re.search(r"SET\s+LOCK_TIMEOUT\s+@",group,re.I):
    raise SystemExit("GroupStop muss SQL-Operationen mit gültigem Literal im Prozedurscope nonblocking ausführen")
reconcile=sources["USP_ReconcileWorkerExecution"]
if reconcile.index("COMMIT TRANSACTION") > reconcile.index("IF @OwnSessionLock=1 EXEC sys.sp_releaseapplock"):
    raise SystemExit("Reconcile gibt Sessionfence vor Commit frei")
for lifecycle in ("Deploy.sql","Uninstall.sql"):
    text=(root/"Deployment"/lifecycle).read_text(encoding="utf-8")
    if re.search(r"(?<!ISNULL\()HAS_PERMS_BY_NAME",text): raise SystemExit("Lifecycle-Rechteprüfung nicht NULL-failclosed")
    names=re.findall(r"DECLARE\s+(@\w+)",text,re.I)
    if len(names)!=len(set(n.lower() for n in names)): raise SystemExit("Doppeltes DECLARE im Lifecyclebatch")

finalize=sources["USP_FinalizeWorkerFailure"]
if "ManagedReservationId=NULL" not in finalize or "AND ManagedHold=0 AND Status IN('FAILED','RETRY_WAIT','DEAD_LETTER')" not in finalize:
    raise SystemExit("Bewiesene heldfreie Terminalentscheidung muss exakte aktuelle Queuebindung lösen")

# SQL468 regression: catalog type and temp-owned type must not depend on the
# implicit catalog/tempdb collations, even on an empty installation.
for lifecycle in ("Deploy.sql","Uninstall.sql"):
    text=(root / "Deployment" / lifecycle).read_text(encoding="utf-8")
    if text.count("actual.type COLLATE Latin1_General_100_BIN2<>expected.ObjectType COLLATE Latin1_General_100_BIN2")!=2:
        raise SystemExit("Katalog/Temp-Objekttypvergleich ist nicht collation-safe: "+lifecycle)

# Native SQL1047 regression: do not combine contradictory isolation hints.
for name,text in sources.items():
    for hint in re.findall(r"WITH\s*\(([^)]*)\)",text,re.I):
        if "HOLDLOCK" in hint.upper() and "READCOMMITTEDLOCK" in hint.upper():
            raise SystemExit("Widersprüchliche Witness-Isolationshints: "+name)
if "WorkerExecutionCommitWitness WITH(UPDLOCK,HOLDLOCK)" not in sources["USP_ReconcileWorkerExecution"]:
    raise SystemExit("Reconcile muss serializierbaren Witness-/Absence-Rangelock erhalten")


for name,text in sources.items():
    if re.search(r"SET\s+LOCK_TIMEOUT\s+@",text,re.I):
        raise SystemExit("SQL2019 verbietet variablenwertiges SET LOCK_TIMEOUT: "+name)

# Real SQL2019 probe proved plain rowversion->binary conversion nullable.
if "ISNULL(CONVERT(binary(8),c.ConfigVersion),CONVERT(binary(8),0x0))" not in sources["VW_WorkerStatus"]:
    raise SystemExit("ConfigVersion muss den bereits zugesagten NOTNULL-Binaryvertrag explizit erhalten")


view=sources["VW_WorkerExecutionStatus"]
if "ISNULL(d.IsHeld,CONVERT(bit,0))" not in view or "ISNULL(d.StopStatus,CASE" not in view or "CONVERT(varchar(24),ISNULL(d.StopStatus" in view:
    raise SystemExit("Statusview muss outermost NOTNULL-Typannotation erhalten")

print("Worker Control statische Kopplung erfolgreich; Runtime nicht bewertet")

reserve=sources["USP_ReserveWorkerExecution"]
if "@ResultTable=N'#tbx_ManagedClaim'" in reserve or "@ClaimedWorkItemId=@CanonicalClaimId OUTPUT,@EmitResult=0" not in reserve or "wi.ManagedReservationId=@Reservation" not in reserve:
    raise SystemExit("Privater Reservetransport darf canonicalResultTable-Namensschutz nicht umgehen")
