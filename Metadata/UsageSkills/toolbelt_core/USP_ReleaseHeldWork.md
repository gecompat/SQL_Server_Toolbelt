---
name: "toolbelt-core-usp-releaseheldwork"
description: "Gibt einen nachgewiesen zurückgerollten gehaltenen Queueauftrag versionsgebunden für einen neuen Retryzyklus frei."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_ReleaseHeldWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen."}, {"name": "@ExpectedHoldVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReleaseHeldWork.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_ReleaseHeldWork

## Zweck und Einsatzfälle

Gibt einen nachgewiesen zurückgerollten gehaltenen Queueauftrag versionsgebunden für einen neuen Retryzyklus frei.

## Voraussetzungen

Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.

## Ergebnisse

Eine Zeile:WorkItemId bigint NOT NULL,ClaimGeneration bigint NOT NULL,Status varchar(16) NOT NULL,HoldVersion binary(8) NOT NULL. Status QUEUED fürSHARED oderBARRIER_WAIT fürDRAIN_BARRIER. ClaimGeneration bleibt bis zum späteren Claim erhalten; neue HoldVersion ist keine neue Claimgeneration. Kein OUTPUT-Parameter; RETURN0 nach Erfolg/Hilfe. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;

-- Nur nach bewiesenem Rollback und mit frisch gelesener HoldVersion:
DECLARE @Item bigint=1,@Hold binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Hold;
-- Synthetische/stale Werte werden abgewiesen; UNKNOWN ist keine Freigabe.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Getrennte administrative EXECUTE-Freigabeautorität,keine WorkerToken-/Owner-/WorkTypeAuthorizationprüfung in diesem Code. Exakte aktuelle HoldVersion nach Stop/Reconcile frisch übernehmen, kein ConfigVersionersatz. SELECT oder UNKNOWN allein autorisiert keine Freigabe. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.

## Ressourcenbedarf

Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. Privater Disposition-AppLock mit Timeout0; weitere Sperren folgen dem Engine-/Caller-Locktimeout. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. Hilfe kehrt vor Ergebnistemp, Fachprüfung und Mutation zurück. Fachpfad: eigene Transaktion mit globalen Gate-/Scheduler-/Konfigurationssperren. Disposition zunächst mit READPAST/READCOMMITTEDLOCK lesen; gesperrte Zeilen können übersprungen werden und als fehlender/staler Hold scheitern. Held1 und exakte ExpectedHoldVersion sind Pflicht. Privaten Transaction-Disposition-AppLock mit Timeout0/public gewinnen, dann Hold/Version locking erneut prüfen. Reservation muss ROLLED_BACK/IsOccupied0 sein, ein Witness darf nicht existieren. Das WorkItem muss FAILED mit derselben ManagedReservationId/Claimgeneration sein.

Erst dann RetryCycleNumber um1 erhöhen, CycleAttemptCount0 und NextAttemptNULL setzen. SHARED wird QUEUED; DRAIN_BARRIER wird BARRIER_WAIT mit neuer BarrierEpoch und neuem Snapshot aktueller CLAIMED-Blocker derselben Gruppe außer gleichprioriger Barrier. Claim-, Lease-, Failed- und Deadlettermetadaten werden geleert. LastRequeue erhält EngineUTC,ORIGINAL_LOGIN und den festen Grund Explicit held-work release. ManagedReservationId/ManagedCompletionNonce werden NULL, ManagedHold0. IdempotencyKey,ClaimGeneration,Recovery-/Attempt-/Executionhistory sowie letzte Fehler-/Retryhistorie bleiben erhalten. Disposition IsHeld0/StopStatusNONE erzeugt neue HoldVersion; globale ConfigVersion unverändert.

Keine Löschung der Reservation/History, kein sofortiger neuer Claim/Handlerstart und keine Zusage eines aktiven WorkTypes. Routing liegt vor Commit. Ein ungeklärter oder committeter Attempt wird nicht automatisch wiederholt. Überlauf von RetryCycle/BarrierEpoch und technische Fehler rollen die eigene aktive Transaktion zurück. Kein eigener Debugpfad; Fehler nach Commit oder beim Ergebnistransport machen einen erfolgten Commit nicht rückgängig.

## Fehlerbehandlung

54210/1 CallerTX;54211/1 Pflichtintegrationszeile fehlt.54225/1 fehlender/übersprungener/nichtgehaltener/staler erwarteterHold;54222/3 privaterDispositionlock nichtohneWarten verfügbar;54225/4 frischgelesenerHold geändert;54225/2 ReservationnichtROLLED_BACK/frei oderWitnessvorhanden;54225/3 keinunveränderterFAILED-Queuezustand. Überlauf vonRetryCycle/BarrierEpoch undHelper-/Enginefehler bleiben sichtbar;aktiveeigeneTX wird zurückgerollt. Kein automatischesRetry. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
