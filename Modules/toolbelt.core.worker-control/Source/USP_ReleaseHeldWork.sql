-- Objekt: toolbelt_core.USP_ReleaseHeldWork
-- Zweck: Beginnt ausschließlich nach bewiesenem Rollback eine explizite neue Retryphase; UNKNOWN und COMPLETED bleiben gesperrt.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_ReleaseHeldWork
 @WorkItemId bigint=NULL,
 @ExpectedHoldVersion binary(8)=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-releaseheldwork"
-- description: "Gibt einen nachgewiesen zurückgerollten gehaltenen Queueauftrag versionsgebunden für einen neuen Retryzyklus frei."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_ReleaseHeldWork"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen."}, {"name": "@ExpectedHoldVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReleaseHeldWork.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_ReleaseHeldWork
--
-- ## Zweck und Einsatzfälle
--
-- Gibt einen nachgewiesen zurückgerollten gehaltenen Queueauftrag versionsgebunden für einen neuen Retryzyklus frei.
--
-- ## Voraussetzungen
--
-- Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@WorkItemId` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen. |
-- | `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
--
-- SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.
--
-- ## Ergebnisse
--
-- Eine Zeile:WorkItemId bigint NOT NULL,ClaimGeneration bigint NOT NULL,Status varchar(16) NOT NULL,HoldVersion binary(8) NOT NULL. Status QUEUED fürSHARED oderBARRIER_WAIT fürDRAIN_BARRIER. ClaimGeneration bleibt bis zum späteren Claim erhalten; neue HoldVersion ist keine neue Claimgeneration. Kein OUTPUT-Parameter; RETURN0 nach Erfolg/Hilfe. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;
--
-- -- Nur nach bewiesenem Rollback und mit frisch gelesener HoldVersion:
-- DECLARE @Item bigint=1,@Hold binary(8)=0x0000000000000001;
-- EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Hold;
-- -- Synthetische/stale Werte werden abgewiesen; UNKNOWN ist keine Freigabe.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Getrennte administrative EXECUTE-Freigabeautorität,keine WorkerToken-/Owner-/WorkTypeAuthorizationprüfung in diesem Code. Exakte aktuelle HoldVersion nach Stop/Reconcile frisch übernehmen, kein ConfigVersionersatz. SELECT oder UNKNOWN allein autorisiert keine Freigabe. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.
--
-- ## Ressourcenbedarf
--
-- Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. Privater Disposition-AppLock mit Timeout0; weitere Sperren folgen dem Engine-/Caller-Locktimeout. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. Hilfe kehrt vor Ergebnistemp, Fachprüfung und Mutation zurück. Fachpfad: eigene Transaktion mit globalen Gate-/Scheduler-/Konfigurationssperren. Disposition zunächst mit READPAST/READCOMMITTEDLOCK lesen; gesperrte Zeilen können übersprungen werden und als fehlender/staler Hold scheitern. Held1 und exakte ExpectedHoldVersion sind Pflicht. Privaten Transaction-Disposition-AppLock mit Timeout0/public gewinnen, dann Hold/Version locking erneut prüfen. Reservation muss ROLLED_BACK/IsOccupied0 sein, ein Witness darf nicht existieren. Das WorkItem muss FAILED mit derselben ManagedReservationId/Claimgeneration sein.
--
-- Erst dann RetryCycleNumber um1 erhöhen, CycleAttemptCount0 und NextAttemptNULL setzen. SHARED wird QUEUED; DRAIN_BARRIER wird BARRIER_WAIT mit neuer BarrierEpoch und neuem Snapshot aktueller CLAIMED-Blocker derselben Gruppe außer gleichprioriger Barrier. Claim-, Lease-, Failed- und Deadlettermetadaten werden geleert. LastRequeue erhält EngineUTC,ORIGINAL_LOGIN und den festen Grund Explicit held-work release. ManagedReservationId/ManagedCompletionNonce werden NULL, ManagedHold0. IdempotencyKey,ClaimGeneration,Recovery-/Attempt-/Executionhistory sowie letzte Fehler-/Retryhistorie bleiben erhalten. Disposition IsHeld0/StopStatusNONE erzeugt neue HoldVersion; globale ConfigVersion unverändert.
--
-- Keine Löschung der Reservation/History, kein sofortiger neuer Claim/Handlerstart und keine Zusage eines aktiven WorkTypes. Routing liegt vor Commit. Ein ungeklärter oder committeter Attempt wird nicht automatisch wiederholt. Überlauf von RetryCycle/BarrierEpoch und technische Fehler rollen die eigene aktive Transaktion zurück. Kein eigener Debugpfad; Fehler nach Commit oder beim Ergebnistransport machen einen erfolgten Commit nicht rückgängig.
--
-- ## Fehlerbehandlung
--
-- 54210/1 CallerTX;54211/1 Pflichtintegrationszeile fehlt.54225/1 fehlender/übersprungener/nichtgehaltener/staler erwarteterHold;54222/3 privaterDispositionlock nichtohneWarten verfügbar;54225/4 frischgelesenerHold geändert;54225/2 ReservationnichtROLLED_BACK/frei oderWitnessvorhanden;54225/3 keinunveränderterFAILED-Queuezustand. Überlauf vonRetryCycle/BarrierEpoch undHelper-/Enginefehler bleiben sichtbar;aktiveeigeneTX wird zurückgerollt. Kein automatischesRetry. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_ReleaseHeldWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beginnt ausschließlich nach bewiesenem Rollback eine explizite neue Retryphase; UNKNOWN und COMPLETED bleiben gesperrt.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'WorkItemId gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'ClaimGeneration gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'Status gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'HoldVersion', N'binary(8)', 0, 0, NULL, CAST(N'HoldVersion gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkItemId', N'bigint', 1, 0, N'NULL', CAST(N'Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ExpectedHoldVersion', N'binary(8)', 1, 0, N'NULL', CAST(N'Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ReleaseHeldWork' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-releaseheldwork"
description: "Gibt einen nachgewiesen zurückgerollten gehaltenen Queueauftrag versionsgebunden für einen neuen Retryzyklus frei."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_ReleaseHeldWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen."}, {"name": "@ExpectedHoldVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "' AS nvarchar(max)) + N'description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReleaseHeldWork.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_ReleaseHeldWork

## Zweck und Einsatzfälle

Gibt einen nachgewiesen zurückgerollten gehaltenen Queueauftrag versionsgebunden für einen neuen Retryzyklus frei.

## Voraussetzungen

Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoint' + N's. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-ID einer tatsächlich gehaltenen Queuezeile. Freigabe erst nach nachgewiesenem Rollback des zugehörigen Versuchs; UNKNOWN oder COMPLETED ist nicht freigebbar. NULL/fehlende oder nicht passende Zeile wird abgewiesen. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transakti' + N'ons-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

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

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Getrennte administrative EXECUTE-Freigabeautorität,keine WorkerToken-/Owner-/WorkTypeAuthorizationprüfung in diesem Code. Exakte aktuelle HoldVersion nach Stop/Reconcile frisch übernehmen, kein ConfigVersion' + N'ersatz. SELECT oder UNKNOWN allein autorisiert keine Freigabe. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.

## Ressourcenbedarf

Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. Privater Disposition-AppLock mit Timeout0; weitere Sperren folgen dem Engine-/Caller-Locktimeout. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. Hilfe kehrt vor Ergebnistemp, Fachprüfung und Mutation zurück. Fachpfad: eigene Transaktion mit globalen Gate-/Scheduler-/Konfigurationssperren. Disposition zunächst mit READPAST/READCOMMITTEDLOCK lesen; gesperrte Zeilen können übersprungen werden und als fehlender/staler Hold scheitern. Held1 und exakte ExpectedHoldVersion sind Pflicht. Privaten Transaction-Disposition-AppLock mit Timeout0/public gewinnen, dann Hold/Version locking erneut prüfen. Reservation muss ROLLED_BACK/IsOccupied0 sein, ein Witness darf nicht existieren. Das WorkItem muss FAILED mit derselben ManagedReservationId/Claimgeneration sein.

Erst dann RetryCycleNumber um1 erhöhen, CycleAttemptCount0 und NextAttemptNULL setzen. SHARED wird QUEUED; DRAIN_BARRIER wird BARRIER_WAIT mit neuer BarrierEpoch und neuem Snapshot aktueller CLAIMED-Blocker derselben Gruppe außer gleichprioriger Barrier. Claim-, Lease-, Failed- und Deadlettermetadaten werden geleert. LastRequeue erhält EngineUTC,ORIGINAL_LOGIN und den festen Grund Explicit held-work release. ManagedReservationId/ManagedCompletionNonce werden NULL, ManagedHold0. IdempotencyKey,ClaimGeneration,Recovery-/Attempt-/Executionhistory sowie letzte Fehler-/Retryhi' + N'storie bleiben erhalten. Disposition IsHeld0/StopStatusNONE erzeugt neue HoldVersion; globale ConfigVersion unverändert.

Keine Löschung der Reservation/History, kein sofortiger neuer Claim/Handlerstart und keine Zusage eines aktiven WorkTypes. Routing liegt vor Commit. Ein ungeklärter oder committeter Attempt wird nicht automatisch wiederholt. Überlauf von RetryCycle/BarrierEpoch und technische Fehler rollen die eigene aktive Transaktion zurück. Kein eigener Debugpfad; Fehler nach Commit oder beim Ergebnistransport machen einen erfolgten Commit nicht rückgängig.

## Fehlerbehandlung

54210/1 CallerTX;54211/1 Pflichtintegrationszeile fehlt.54225/1 fehlender/übersprungener/nichtgehaltener/staler erwarteterHold;54222/3 privaterDispositionlock nichtohneWarten verfügbar;54225/4 frischgelesenerHold geändert;54225/2 ReservationnichtROLLED_BACK/frei oderWitnessvorhanden;54225/3 keinunveränderterFAILED-Queuezustand. Überlauf vonRetryCycle/BarrierEpoch undHelper-/Enginefehler bleiben sichtbar;aktiveeigeneTX wird zurückgerollt. Kein automatischesRetry. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 CREATE TABLE #tbx_USP_ReleaseHeldWork_Result(WorkItemId bigint NOT NULL,ClaimGeneration bigint NOT NULL,Status varchar(16) NOT NULL,HoldVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 DECLARE @SlotReservationId uniqueidentifier,@Generation bigint,@Version binary(8),@Held bit,@State varchar(24),@Occupied bit,@Mode varchar(16),@Group varchar(128),@Priority tinyint,@Epoch bigint;
 SELECT @SlotReservationId=SlotReservationId,@Version=HoldVersion,@Held=IsHeld FROM toolbelt_core.WorkerExecutionDisposition WITH(READPAST,READCOMMITTEDLOCK) WHERE WorkItemId=@WorkItemId;
 IF @Held<>1 OR @Held IS NULL OR @ExpectedHoldVersion IS NULL OR @ExpectedHoldVersion<>@Version THROW 54225,N'Der erwartete Hold fehlt oder ist veraltet.',1;
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@DispositionLock int;
 EXEC @DispositionLock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @DispositionLock<0 THROW 54222,N'Die Holdfreigabe wartet nicht unter globalem Gate auf einen Completionpfad.',3;
 SELECT @Held=IsHeld,@Version=HoldVersion FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND SlotReservationId=@SlotReservationId;
 IF @Held IS NULL OR @Held<>1 OR @Version<>@ExpectedHoldVersion THROW 54225,N'Der Hold hat sich seit Auswahl verändert.',4;
 SELECT @Generation=ClaimGeneration,@State=State,@Occupied=IsOccupied FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @State<>'ROLLED_BACK' OR @Occupied<>0 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId) THROW 54225,N'Ungeklärte oder committed Ausführung darf nicht freigegeben werden.',2;
 SELECT @Mode=ExecutionMode,@Group=ExecutionGroup,@Priority=Priority,@Epoch=BarrierEpoch FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND Status='FAILED' AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation;
 IF @Mode IS NULL THROW 54225,N'Der bewiesene Hold besitzt keinen unveränderten Queuezustand.',3;
 SET @Epoch=CASE WHEN @Mode='DRAIN_BARRIER' THEN @Epoch+1 ELSE @Epoch END;
 UPDATE toolbelt_core.WorkItem SET Status=CASE WHEN @Mode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,RetryCycleNumber=RetryCycleNumber+1,CycleAttemptCount=0,NextAttemptAtUtc=NULL,BarrierEpoch=@Epoch,
 ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL,LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL,FailedAtUtc=NULL,FailedBy=NULL,FailureCode=NULL,FailureMessage=NULL,DeadLetteredAtUtc=NULL,DeadLetteredBy=NULL,
 LastRequeuedAtUtc=SYSUTCDATETIME(),LastRequeuedBy=ORIGINAL_LOGIN(),LastRequeueReason=N'Explicit held-work release',ManagedReservationId=NULL,ManagedHold=0,ManagedCompletionNonce=NULL WHERE WorkItemId=@WorkItemId;
 IF @Mode='DRAIN_BARRIER' INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration) SELECT @WorkItemId,@Epoch,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@Group AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=0,StopStatus='NONE' WHERE WorkItemId=@WorkItemId;
 INSERT #tbx_USP_ReleaseHeldWork_Result SELECT wi.WorkItemId,wi.ClaimGeneration,wi.Status,d.HoldVersion FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkerExecutionDisposition d ON d.WorkItemId=wi.WorkItemId WHERE wi.WorkItemId=@WorkItemId;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_ReleaseHeldWork_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkItemId,ClaimGeneration,Status,HoldVersion) SELECT WorkItemId,ClaimGeneration,Status,HoldVersion FROM #tbx_USP_ReleaseHeldWork_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkItemId,ClaimGeneration,Status,HoldVersion FROM #tbx_USP_ReleaseHeldWork_Result;
 RETURN 0;
END;
GO
