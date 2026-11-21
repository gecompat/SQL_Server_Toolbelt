---
name: "toolbelt-core-usp-stopworkerexecution"
description: "Persistiert versionsgebunden Stop/Hold einer exakten Reservation oder erkennt deren vorherigen Commit."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_StopWorkerExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig."}, {"name": "@ExpectedClaimGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche exakte positive bigint-ClaimGeneration der ausgewählten Reservation, aus ihrer Ausführungs-/Claimstatuszeile übernehmen. Kein WorkerGeneration-Wert; NULL oder Abweichung wird abgewiesen. Ein bereits gewinnender Commit wird nicht durch Retry wiederholt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_StopWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_StopWorkerExecution

## Zweck und Einsatzfälle

Persistiert versionsgebunden Stop/Hold einer exakten Reservation oder erkennt deren vorherigen Commit.

## Voraussetzungen

Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedClaimGeneration` | `bigint` | `NULL` | Fachlich erforderliche exakte positive bigint-ClaimGeneration der ausgewählten Reservation, aus ihrer Ausführungs-/Claimstatuszeile übernehmen. Kein WorkerGeneration-Wert; NULL oder Abweichung wird abgewiesen. Ein bereits gewinnender Commit wird nicht durch Retry wiederholt. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.

## Ergebnisse

Eine Zeile:SlotReservationId uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL,StopStatus varchar(24) NOT NULL,HoldVersion binary(8) NOT NULL. Kein OUTPUT-Parameter. StopStatus aus der tatsächlichen aktuellen Disposition, keine freie zusätzliche Outcome-Spalte. RETURN0 ist kein Rollback-/Slotfreigabenachweis. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_StopWorkerExecution @Hilfe=1;

-- Reservation und Claimgeneration aus tatsächlicher Claim-/Statuszeile:
DECLARE @Slot uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_StopWorkerExecution @SlotReservationId=@Slot,@ExpectedClaimGeneration=1;
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Getrennte administrative EXECUTE-Autorität; keine WorkerToken-/Ownerprüfung in diesem Aufruf. ExpectedClaimGeneration muss genau zur ausgewählten Reservation gehören und ist keine WorkerGeneration. Sichtbare IDs oder SELECT allein erlauben keinen Stop. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.

## Ressourcenbedarf

Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. Disposition-AppLock wartet maximal5000ms. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor dem positiven Hilfezweig. Hilfe ignoriert Fachwerte, erzeugt keine fachlichen Mutationen oder eigenen Debugmessages und kehrt vor Ergebnistemp/Routing zurück. Eigene Transaktion ohne globale Gate-/Scheduler-/Configprüfung. Exklusiver Transaction-Disposition-AppLock5000ms/public, Reservation und zugehörige aktuelle Disposition unter UPDLOCK/HOLDLOCK lesen. Exakte ExpectedClaimGeneration erforderlich. Erst wenn WorkItem separat COMPLETED mit derselben ManagedReservationId/Generation gelesen wird, CommitWitness per READCOMMITTEDLOCK mit Slot/Execution/Generation prüfen; kein unbedingtes Lesen eines möglicherweise uncommitteten laufenden Witness unter dem Stopgate. Freie ROLLED_BACK-Reservation mit IsHeld0 bleibt unverändert; bestehender Dispositions-StopStatus wird ausgegeben (lokales OutcomeNONE ist kein Resultfeld). Bei passendem COMPLETED+Witness:ReservationCOMMITTED/frei,EndedAt nur fallsNULL;DispositionALREADY_COMMITTED/IsHeld0. Sonst DispositionIsHeld1,StopStatus ROLLED_BACK_HELD bei vorherROLLED_BACK, sonstREQUESTED; WorkItem.ManagedHold1 bei passender Reservation; noch belegte Reservation STOP_REQUESTED außer bereitsROLLED_BACK. Kein KILL/SqlCommand.Cancel, kein Handlerrollback und keine automatische Queue-/Slotfinalisierung durch bloßen StopStatus. Ohne geworfenen Fehler RETURN0; dies beweist über die beschriebene Mutation hinaus keinen erfolgreich beendeten Handler. Technische Fehler nach Commit, bei Sessionlockrelease oder Ergebnistransport können eine bereits begangene Mutation nicht zurücknehmen.

## Fehlerbehandlung

54210/1 Callertransaktion/nichtneutral;54222/2 negativer Disposition-AppLock-Rückgabecode;54224/1 Reservation fehlt oder ExpectedClaimGenerationNULL/abweichend;54224/2 aktuelle Disposition gehört nicht mehr zu dieser Reservation. NULL-/AppLock-Resource-/Konvertierungsfehler können vorher technische Enginefehler sein. Nicht verifizierbarer Commit wird nicht erfunden. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
