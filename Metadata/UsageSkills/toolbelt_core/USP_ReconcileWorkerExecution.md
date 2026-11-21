---
name: "toolbelt-core-usp-reconcileworkerexecution"
description: "Klassifiziert eine exakte aktuelle Disposition anhand von Connectionfence und locking Witness-/Absencebelegen."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_ReconcileWorkerExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig."}, {"name": "@ExpectedHoldVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen Disposition dieses Slots, als Bytes aus aktueller Statusausgabe übernehmen; kein ConfigVersion-/anderer Rowversion-Ersatz. NULL wird vor Gates mit54227/1 abgewiesen. Exakte Driftprüfung erst nach beiden gewonnenen Gates; dortige Drift ergibt54227/2. Bei Gatekonflikt kann UNKNOWN/Occupied1 ohne Versionsprüfung zurückkommen. Dieser Wert ist konservativ, keine aktuelle Belegungsmessung und keine Replayfreigabe."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReconcileWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_ReconcileWorkerExecution

## Zweck und Einsatzfälle

Klassifiziert eine exakte aktuelle Disposition anhand von Connectionfence und locking Witness-/Absencebelegen.

## Voraussetzungen

Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen Disposition dieses Slots, als Bytes aus aktueller Statusausgabe übernehmen; kein ConfigVersion-/anderer Rowversion-Ersatz. NULL wird vor Gates mit54227/1 abgewiesen. Exakte Driftprüfung erst nach beiden gewonnenen Gates; dortige Drift ergibt54227/2. Bei Gatekonflikt kann UNKNOWN/Occupied1 ohne Versionsprüfung zurückkommen. Dieser Wert ist konservativ, keine aktuelle Belegungsmessung und keine Replayfreigabe. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.

## Ergebnisse

Eine Zeile:SlotReservationId uniqueidentifier NOT NULL,Outcome varchar(24) NOT NULL,Occupied bit NOT NULL. Outcome COMMITTED,ROLLED_BACK,ROLLED_BACK_HELD oder UNKNOWN. Kein OUTPUT-Parameter und keine neue HoldVersion im Ergebnis; vor Folgefreigabe aktuelle HoldVersion frisch lesen. UNKNOWN/Occupied1 bei Gatekonflikt ist konservativer Ergebniswert, keine Messung bereits gelesener Datenbankbelegung oder erfolgreiche Versionsprüfung. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;

-- Nur aktuelle exakte Reservation/Disposition verwenden:
DECLARE @Slot uniqueidentifier='00000000-0000-0000-0000-000000000001',@Hold binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@Hold;
-- Nach echter Reconciliation HoldVersion aus VW_WorkerExecutionStatus neu lesen.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Administrative EXECUTE-Autorität und exakte aktuelle HoldVersion; keine Worker-/Claimtoken- oder Ownerprüfung dieses Kontrollpfads. Statusleserecht ist keine Reconcile-/Freigabeautorität. Reconcile allein erlaubt kein Replay. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.

## Ressourcenbedarf

Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. LOCK_TIMEOUT5000 und AppLock-Timeout0 betreffen getrennte Prüfschritte und begrenzen nicht die gesamte Laufzeit. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe; Hilfe kehrt vor Fachprüfung, Routing und Mutation zurück. Der Fachpfad verlangt neutralen Callerzustand und startet eine eigene Transaktion mit LOCK_TIMEOUT5000 im TRY. Slot und ExpectedHoldVersion müssen nichtNULL sein. Session-Attempt-AppLock mit Timeout0/public: Konflikt ergibt konservativ UNKNOWN/Occupied1. Bei Erfolg den eigenen Lockanteil merken und den Transaction-Disposition-AppLock ebenfalls ohne Warten gewinnen. Auch dessen Konflikt ergibt UNKNOWN/Occupied1. In diesen Konfliktzweigen wird die tatsächliche Disposition/Version nicht frisch geprüft.

Erst nach beiden Gates Reservation und aktuelle Disposition unter UPDLOCK/HOLDLOCK frisch lesen und die Holdversion vergleichen. Witnessexistenz wird ebenfalls locking geprüft; exakter Match bindet gespeicherte Attemptnonce,ExecutionId und Claimgeneration. Freie terminale COMMITTED/ROLLED_BACK/CLOSED-History wird nur klassifiziert: COMMITTED oder bei Held1 ROLLED_BACK_HELD, sonst ROLLED_BACK. Das ist keine zusätzliche Freigabeautorität.

Passender Witness plus COMPLETED-Queuezustand derselben Reservation/Generation: Reservation COMMITTED/frei, Disposition ALREADY_COMMITTED/held0 und WorkItem.ManagedHold0. Kein Witness plus Held1 und Stop-/Unknown-/Rollbackstate: den exakten CLAIMED-Queueauftrag FAILED/WORKER.STOP_HELD/ManagedHold1 buchen, Reservation ROLLED_BACK/frei und Disposition ROLLED_BACK_HELD/held1. Sonst Reservation UNKNOWN/IsOccupied1/EndedAtNULL, Disposition held1/UNKNOWN und passenden WorkItem-Hold setzen. Kein Handlercommit, Handlerrollback, KILL oder Replay.

Ein innerer1222 bei committable Transaktion wird konservativ als UNKNOWN/Occupied1 ausgegeben und die äußere Transaktion fortgeführt. Es gibt keinen inneren Savepointrollback: UNKNOWN beweist deshalb weder völlige Mutationsfreiheit noch eine frisch gemessene physische Belegung. Routing liegt vor Commit. Danach eigenen Sessionlockanteil freigeben; der äußere CATCH rollt aktive eigene Transaktion zurück und gibt den eigenen Lockanteil frei. Cleanupfehler sind nicht separat geschützt. Das Ergebnis enthält keine neue HoldVersion; für spätere Schritte frisch lesen. Keine eigenen Debugmessages. Fehler nach Commit oder bei Ausgabe machen einen erfolgten Commit nicht rückgängig.

## Fehlerbehandlung

54210/1 CallerTX;54227/1 Slot/HoldversionNULL;54227/2 nach gewonnenen Gates keine exakte aktuelle Disposition oder Versionsdrift;54227/3 kein unveränderter Queueclaim für Rollbackklassifikation. Negative AppLock-Rückgaben sind hier normaleUNKNOWN1 statt gezielter Retry. Innerer Witness-/Klassifikations-1222 wird nur bei XACT_STATE1 konservativ abgefangen, übrige Engine-/Routing-/Sperrfehler bleiben geworfene Fehler. Veraltete nichtNULL-Version kann bei Gatekonflikt ungeprüftUNKNOWN zurückbekommen. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
