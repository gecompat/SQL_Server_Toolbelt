-- Objekt: toolbelt_core.USP_ReconcileWorkerExecution
-- Zweck: Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_ReconcileWorkerExecution
 @SlotReservationId uniqueidentifier=NULL,
 @ExpectedHoldVersion binary(8)=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-reconcileworkerexecution"
-- description: "Klassifiziert eine exakte aktuelle Disposition anhand von Connectionfence und locking Witness-/Absencebelegen."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_ReconcileWorkerExecution"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig."}, {"name": "@ExpectedHoldVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen Disposition dieses Slots, als Bytes aus aktueller Statusausgabe übernehmen; kein ConfigVersion-/anderer Rowversion-Ersatz. NULL wird vor Gates mit54227/1 abgewiesen. Exakte Driftprüfung erst nach beiden gewonnenen Gates; dortige Drift ergibt54227/2. Bei Gatekonflikt kann UNKNOWN/Occupied1 ohne Versionsprüfung zurückkommen. Dieser Wert ist konservativ, keine aktuelle Belegungsmessung und keine Replayfreigabe."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReconcileWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_ReconcileWorkerExecution
--
-- ## Zweck und Einsatzfälle
--
-- Klassifiziert eine exakte aktuelle Disposition anhand von Connectionfence und locking Witness-/Absencebelegen.
--
-- ## Voraussetzungen
--
-- Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@SlotReservationId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
-- | `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen Disposition dieses Slots, als Bytes aus aktueller Statusausgabe übernehmen; kein ConfigVersion-/anderer Rowversion-Ersatz. NULL wird vor Gates mit54227/1 abgewiesen. Exakte Driftprüfung erst nach beiden gewonnenen Gates; dortige Drift ergibt54227/2. Bei Gatekonflikt kann UNKNOWN/Occupied1 ohne Versionsprüfung zurückkommen. Dieser Wert ist konservativ, keine aktuelle Belegungsmessung und keine Replayfreigabe. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
--
-- SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.
--
-- ## Ergebnisse
--
-- Eine Zeile:SlotReservationId uniqueidentifier NOT NULL,Outcome varchar(24) NOT NULL,Occupied bit NOT NULL. Outcome COMMITTED,ROLLED_BACK,ROLLED_BACK_HELD oder UNKNOWN. Kein OUTPUT-Parameter und keine neue HoldVersion im Ergebnis; vor Folgefreigabe aktuelle HoldVersion frisch lesen. UNKNOWN/Occupied1 bei Gatekonflikt ist konservativer Ergebniswert, keine Messung bereits gelesener Datenbankbelegung oder erfolgreiche Versionsprüfung. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;
--
-- -- Nur aktuelle exakte Reservation/Disposition verwenden:
-- DECLARE @Slot uniqueidentifier='00000000-0000-0000-0000-000000000001',@Hold binary(8)=0x0000000000000001;
-- EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@Hold;
-- -- Nach echter Reconciliation HoldVersion aus VW_WorkerExecutionStatus neu lesen.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Administrative EXECUTE-Autorität und exakte aktuelle HoldVersion; keine Worker-/Claimtoken- oder Ownerprüfung dieses Kontrollpfads. Statusleserecht ist keine Reconcile-/Freigabeautorität. Reconcile allein erlaubt kein Replay. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.
--
-- ## Ressourcenbedarf
--
-- Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. LOCK_TIMEOUT5000 und AppLock-Timeout0 betreffen getrennte Prüfschritte und begrenzen nicht die gesamte Laufzeit. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe; Hilfe kehrt vor Fachprüfung, Routing und Mutation zurück. Der Fachpfad verlangt neutralen Callerzustand und startet eine eigene Transaktion mit LOCK_TIMEOUT5000 im TRY. Slot und ExpectedHoldVersion müssen nichtNULL sein. Session-Attempt-AppLock mit Timeout0/public: Konflikt ergibt konservativ UNKNOWN/Occupied1. Bei Erfolg den eigenen Lockanteil merken und den Transaction-Disposition-AppLock ebenfalls ohne Warten gewinnen. Auch dessen Konflikt ergibt UNKNOWN/Occupied1. In diesen Konfliktzweigen wird die tatsächliche Disposition/Version nicht frisch geprüft.
--
-- Erst nach beiden Gates Reservation und aktuelle Disposition unter UPDLOCK/HOLDLOCK frisch lesen und die Holdversion vergleichen. Witnessexistenz wird ebenfalls locking geprüft; exakter Match bindet gespeicherte Attemptnonce,ExecutionId und Claimgeneration. Freie terminale COMMITTED/ROLLED_BACK/CLOSED-History wird nur klassifiziert: COMMITTED oder bei Held1 ROLLED_BACK_HELD, sonst ROLLED_BACK. Das ist keine zusätzliche Freigabeautorität.
--
-- Passender Witness plus COMPLETED-Queuezustand derselben Reservation/Generation: Reservation COMMITTED/frei, Disposition ALREADY_COMMITTED/held0 und WorkItem.ManagedHold0. Kein Witness plus Held1 und Stop-/Unknown-/Rollbackstate: den exakten CLAIMED-Queueauftrag FAILED/WORKER.STOP_HELD/ManagedHold1 buchen, Reservation ROLLED_BACK/frei und Disposition ROLLED_BACK_HELD/held1. Sonst Reservation UNKNOWN/IsOccupied1/EndedAtNULL, Disposition held1/UNKNOWN und passenden WorkItem-Hold setzen. Kein Handlercommit, Handlerrollback, KILL oder Replay.
--
-- Ein innerer1222 bei committable Transaktion wird konservativ als UNKNOWN/Occupied1 ausgegeben und die äußere Transaktion fortgeführt. Es gibt keinen inneren Savepointrollback: UNKNOWN beweist deshalb weder völlige Mutationsfreiheit noch eine frisch gemessene physische Belegung. Routing liegt vor Commit. Danach eigenen Sessionlockanteil freigeben; der äußere CATCH rollt aktive eigene Transaktion zurück und gibt den eigenen Lockanteil frei. Cleanupfehler sind nicht separat geschützt. Das Ergebnis enthält keine neue HoldVersion; für spätere Schritte frisch lesen. Keine eigenen Debugmessages. Fehler nach Commit oder bei Ausgabe machen einen erfolgten Commit nicht rückgängig.
--
-- ## Fehlerbehandlung
--
-- 54210/1 CallerTX;54227/1 Slot/HoldversionNULL;54227/2 nach gewonnenen Gates keine exakte aktuelle Disposition oder Versionsdrift;54227/3 kein unveränderter Queueclaim für Rollbackklassifikation. Negative AppLock-Rückgaben sind hier normaleUNKNOWN1 statt gezielter Retry. Innerer Witness-/Klassifikations-1222 wird nur bei XACT_STATE1 konservativ abgefangen, übrige Engine-/Routing-/Sperrfehler bleiben geworfene Fehler. Veraltete nichtNULL-Version kann bei Gatekonflikt ungeprüftUNKNOWN zurückbekommen. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.
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
            CAST(N'USP_ReconcileWorkerExecution' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'SlotReservationId', N'uniqueidentifier', 0, 0, NULL, CAST(N'SlotReservationId gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'Outcome', N'varchar(24)', 0, 0, NULL, CAST(N'Outcome gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Occupied', N'bit', 0, 0, NULL, CAST(N'Occupied gemäß Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@SlotReservationId', N'uniqueidentifier', 1, 0, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ExpectedHoldVersion', N'binary(8)', 1, 0, N'NULL', CAST(N'Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen Disposition dieses Slots, als Bytes aus aktueller Statusausgabe übernehmen; kein ConfigVersion-/anderer Rowversion-Ersatz. NULL wird vor Gates mit54227/1 abgewiesen. Exakte Driftprüfung erst nach beiden gewonnenen Gates; dortige Drift ergibt54227/2. Bei Gatekonflikt kann UNKNOWN/Occupied1 ohne Versionsprüfung zurückkommen. Dieser Wert ist konservativ, keine aktuelle Belegungsmessung und keine Replayfreigabe.' AS nvarchar(max)), NULL),
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
 CONVERT(sysname,CAST(N'USP_ReconcileWorkerExecution' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-reconcileworkerexecution"
description: "Klassifiziert eine exakte aktuelle Disposition anhand von Connectionfence und locking Witness-/Absencebelegen."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_ReconcileWorkerExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig."}, {"name": "@ExpectedHoldVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen Disposition dieses Slots, als Bytes aus aktueller Statusausgabe übernehmen; kein ConfigVersion-/anderer Rowversion-Ersatz. NULL wird vor Gates mit54227/1 abgewiesen. Exakte Driftprüfung erst nach beiden gewonnenen Gates; dortige Drift ergibt54227/2. Bei Gatekonflikt kann UNKNOWN/Occupied1 ohne Versionsprüfung zurückkommen. Dieser Wert ist konservativ, keine aktuelle Belegungsmessung und keine Replayfreigabe."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen ' AS nvarchar(max)) + N'#Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReconcileWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_ReconcileWorkerExecution

## Zweck und Einsatzfälle

Klassifiziert eine exakte aktuelle Disposition anhand ' + N'von Connectionfence und locking Witness-/Absencebelegen.

## Voraussetzungen

Worker-Control 1.0.0 mit passender Queue 2.1.0 sowie Context-, Cancellation- und ResultTable-Integration derselben Moduldatenbank. SQL Server 2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral. Der Fachpfad verlangt @@TRANCOUNT=0 und XACT_STATE()=0; keine Caller-Savepoints. Bestehende IDs, Generationen und Versionen aus tatsächlichen autorisierten Ausgaben übernehmen. Hostnamen, SPIDs oder frei gewählte UUIDs ersetzen diese Bindungen nicht. Hilfe ist mit technischen Defaults ohne Fachwerte aufrufbar.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen Disposition dieses Slots, als Bytes aus aktueller Statusausgabe übernehmen; kein ConfigVersion-/anderer Rowversion-Ersatz. NULL wird vor Gates mit54227/1 abgewiesen. Exakte Driftprüfung erst nach beiden gewonnenen Gates; dortige Drift ergibt54227/2. Bei Gatekonflikt kann UNKNOWN/Occupied1 ohne Versionsprüfung zurückkommen. Dieser Wert ist konservativ, keine aktuelle Belegungsmessung und keine Replayfreigabe. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper mus' + N's verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen Fachersatzwerte. Prüfreihenfolge und konservative UNKNOWN-Ausnahmen stehen in der Fehler-/Nebenwirkungsbeschreibung.

## Ergebnisse

Eine Zeile:SlotReservationId uniqueidentifier NOT NULL,Outcome varchar(24) NOT NULL,Occupied bit NOT NULL. Outcome COMMITTED,ROLLED_BACK,ROLLED_BACK_HELD oder UNKNOWN. Kein OUTPUT-Parameter und keine neue HoldVersion im Ergebnis; vor Folgefreigabe aktuelle HoldVersion frisch lesen. UNKNOWN/Occupied1 bei Gatekonflikt ist konservativer Ergebniswert, keine Messung bereits gelesener Datenbankbelegung oder erfolgreiche Versionsprüfung. Bei nicht-NULL ResultTable erfolgen Formvorbereitung und explizites INSERT in derselben Mutationstransaktion, ohne weiteren direkten Fachresultset. Die direkte Ausgabe erfolgt erst nach Commit. KeepData wird an den kanonischen Helper übergeben; dessen Zieltemp- und Rechteverträge gelten. Hilfe liefert die bestehende zwölfspaltige Standardhilfe plus genau eine Skillzeile mit SkillFormatVersion varchar(16), SchemaNa' + N'me sysname, ObjectName sysname und SkillMarkdown nvarchar(max); danach RETURN0 vor Fachprüfungen.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;

-- Nur aktuelle exakte Reservation/Disposition verwenden:
DECLARE @Slot uniqueidentifier=''00000000-0000-0000-0000-000000000001'',@Hold binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@Hold;
-- Nach echter Reconciliation HoldVersion aus VW_WorkerExecutionStatus neu lesen.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur; passender Datenbankzugriff und Identitätsmapping bei zentralem Dreiteilaufruf. Administrative EXECUTE-Autorität und exakte aktuelle HoldVersion; keine Worker-/Claimtoken- oder Ownerprüfung dieses Kontrollpfads. Statusleserecht ist keine Reconcile-/Freigabeautorität. Reconcile allein erlaubt kein Replay. Keine Rechtevergabe, automatische Impersonation oder pauschalen internen Tabellenrechte. Basiszugriff folgt den tatsächlichen Objekt-/Ownership-Chains; Caller-, Zieltemp- und Metadatenrechte bleiben pfadabhängig.

## Ressourcenbedarf

Keine CLR-, Datei-, Netzwerk- oder LLM-Aktion dieser Prozedur. Datenbankumfang, Indizes, globale/private Gates und konkurrierende Schreiber bestimmen den Aufwand. LOCK_TIMEOUT5000 und AppLock-Timeout0 betreffen getrennte Prüfschritte und begrenzen nicht die gesamte Laufzeit. Keine implementierte CPU-, Heap-, Log-, Gesamtlaufzeit- oder Ausgabebytequote und keine eigene Retryschleife. Deadlocks, Blockierung sowie Log-/tempdbfehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe; Hilfe kehrt vor Fachprüfung, Routing und Mutation zurück. Der Fachpfad verlangt neutralen Callerzustand und startet eine eigene Transaktion mit LOCK_TIMEOUT5000 im TRY. Slot und ExpectedHoldVersion müssen nichtNULL sein. Session-Attempt-AppLock mit Timeout0/public: Konflikt ergibt konservativ UNKNOWN/Occupied1. Bei Erfolg den eige' + N'nen Lockanteil merken und den Transaction-Disposition-AppLock ebenfalls ohne Warten gewinnen. Auch dessen Konflikt ergibt UNKNOWN/Occupied1. In diesen Konfliktzweigen wird die tatsächliche Disposition/Version nicht frisch geprüft.

Erst nach beiden Gates Reservation und aktuelle Disposition unter UPDLOCK/HOLDLOCK frisch lesen und die Holdversion vergleichen. Witnessexistenz wird ebenfalls locking geprüft; exakter Match bindet gespeicherte Attemptnonce,ExecutionId und Claimgeneration. Freie terminale COMMITTED/ROLLED_BACK/CLOSED-History wird nur klassifiziert: COMMITTED oder bei Held1 ROLLED_BACK_HELD, sonst ROLLED_BACK. Das ist keine zusätzliche Freigabeautorität.

Passender Witness plus COMPLETED-Queuezustand derselben Reservation/Generation: Reservation COMMITTED/frei, Disposition ALREADY_COMMITTED/held0 und WorkItem.ManagedHold0. Kein Witness plus Held1 und Stop-/Unknown-/Rollbackstate: den exakten CLAIMED-Queueauftrag FAILED/WORKER.STOP_HELD/ManagedHold1 buchen, Reservation ROLLED_BACK/frei und Disposition ROLLED_BACK_HELD/held1. Sonst Reservation UNKNOWN/IsOccupied1/EndedAtNULL, Disposition held1/UNKNOWN und passenden WorkItem-Hold setzen. Kein Handlercommit, Handlerrollback, KILL oder Replay.

Ein innerer1222 bei committable Transaktion wird konservativ als UNKNOWN/Occupied1 ausgegeben und die äußere Transaktion fortgeführt. Es gibt keinen inneren Savepointrollback: UNKNOWN beweist deshalb weder völlige Mutationsfreiheit noch eine frisch gemessene physische Belegung. Routing liegt vor Commit. Danach eigenen Sessionlockanteil freigeben; der äußere CATCH rollt aktive eigene Transaktion zurück und gibt den eigenen Lockanteil frei. Cleanupfehler sind nicht separat geschützt. Das Ergebnis enthält keine neue HoldVersion; für spätere Schritte frisch lesen. Keine eigenen Debugmessages. Fehler nach Commit oder bei Ausgabe machen einen erfolgten Commit nicht rückgängig.

## Fehlerbehandlung

54210/1 CallerTX;54227/1 Slot/HoldversionNULL;54227/2 nach gewonnenen Gates kei' + N'ne exakte aktuelle Disposition oder Versionsdrift;54227/3 kein unveränderter Queueclaim für Rollbackklassifikation. Negative AppLock-Rückgaben sind hier normaleUNKNOWN1 statt gezielter Retry. Innerer Witness-/Klassifikations-1222 wird nur bei XACT_STATE1 konservativ abgefangen, übrige Engine-/Routing-/Sperrfehler bleiben geworfene Fehler. Veraltete nichtNULL-Version kann bei Gatekonflikt ungeprüftUNKNOWN zurückbekommen. Ursprüngliche Helper-, Konvertierungs-, Engine- und Constraintfehler bleiben getrennt. Aktive eigene Transaktion im äußeren CATCH zurückrollen und weiterwerfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Die Claim-Fassade delegiert ihre Transaktion an Reserve.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-, Unicode-, Callerzustands-, Minimalrechte-, Installer-, Recovery-, Stop- oder Commitabnahme. Historische Nachweise behalten ihre ursprüngliche Artefakt-/Zielbindung. Kein Exactly-once, KILL, Host-/VM-Wiederaufbau oder automatischer Replay. UNKNOWN ist keine Wiederholungsfreigabe. Nach einer Dispositionsmutation die aktuelle Holdversion frisch lesen. Payloads, Token, IDs und reale Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 CREATE TABLE #tbx_USP_ReconcileWorkerExecution_Result(SlotReservationId uniqueidentifier NOT NULL,Outcome varchar(24) NOT NULL,Occupied bit NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @OwnSessionLock bit=0;
 -- Prozedurscope: SQL Server restauriert SET-Optionen bei Return/THROW.
 -- Kein dynamisches SET kann den Aufruferkontext restaurieren.
 SET LOCK_TIMEOUT 5000;
 DECLARE @AttemptResource nvarchar(255)=N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),@SessionLock int,@Item bigint,@Execution uniqueidentifier,@Generation bigint,@Nonce uniqueidentifier,@HoldVersion binary(8),@Held bit,@Occupied bit,@State varchar(24),@Outcome varchar(24),@WitnessExists bit=0,@WitnessMatches bit=0;
 IF @SlotReservationId IS NULL OR @ExpectedHoldVersion IS NULL THROW 54227,N'Reconcile verlangt exakte Reservation und Holdversion.',1;
 EXEC @SessionLock=sys.sp_getapplock @Resource=@AttemptResource,@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';
 IF @SessionLock<0 INSERT #tbx_USP_ReconcileWorkerExecution_Result VALUES(@SlotReservationId,'UNKNOWN',1);
 ELSE
 BEGIN
 SET @OwnSessionLock=1;
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@DispositionLock int;
 EXEC @DispositionLock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @DispositionLock<0 INSERT #tbx_USP_ReconcileWorkerExecution_Result VALUES(@SlotReservationId,'UNKNOWN',1);
 ELSE
 BEGIN
 -- Nach beiden Gates sämtliche attemptgebundenen Fakten frisch einlesen; keine
 -- vor dem Lock eingefrorene Holdversion kann einen parallelen Stop überholen.
 SELECT @Item=WorkItemId,@Execution=ExecutionId,@Generation=ClaimGeneration,@Nonce=AttemptNonce,@Occupied=IsOccupied,@State=State FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 SELECT @HoldVersion=HoldVersion,@Held=IsHeld FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @Item IS NULL OR @HoldVersion<>@ExpectedHoldVersion OR @HoldVersion IS NULL THROW 54227,N'Die exakte aktuelle Disposition fehlt oder ist veraltet.',2;
 BEGIN TRY
 -- SERIALIZABLE-HOLDLOCK erzwingt auch unter RCSI echten Witness-/Absence-Range-Lock;
 -- READCOMMITTEDLOCK wäre ein widersprechender Isolationshint (SQL1047).
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId) SET @WitnessExists=1;
 IF @WitnessExists=1 AND EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WHERE SlotReservationId=@SlotReservationId AND AttemptNonce=@Nonce AND ExecutionId=@Execution AND ClaimGeneration=@Generation) SET @WitnessMatches=1;
IF @Occupied=0 AND @State IN('COMMITTED','ROLLED_BACK','CLOSED')
 BEGIN
 SET @Outcome=CASE WHEN @State='COMMITTED' THEN 'COMMITTED' WHEN @Held=1 THEN 'ROLLED_BACK_HELD' ELSE 'ROLLED_BACK' END;
 END
 ELSE  IF @WitnessMatches=1 AND EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@Item AND Status='COMPLETED' AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation)
 BEGIN
 UPDATE toolbelt_core.WorkerSlotReservation SET State='COMMITTED',IsOccupied=0,EndedAtUtc=ISNULL(EndedAtUtc,SYSUTCDATETIME()) WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=0,StopStatus='ALREADY_COMMITTED' WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkItem SET ManagedHold=0 WHERE WorkItemId=@Item AND Status='COMPLETED';
 SET @Outcome='COMMITTED';SET @Occupied=0;
 END
 ELSE IF @WitnessExists=0 AND @Held=1 AND @State IN('STOP_REQUESTED','STOPPING','UNKNOWN','ROLLED_BACK')
 BEGIN
 IF NOT(@State='ROLLED_BACK' AND @Occupied=0 AND EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='FAILED' AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ManagedHold=1))
 BEGIN
 UPDATE toolbelt_core.WorkItem SET Status='FAILED',FailedAtUtc=SYSUTCDATETIME(),FailedBy=ORIGINAL_LOGIN(),FailureCode='WORKER.STOP_HELD',FailureMessage=NULL,ManagedHold=1,ManagedCompletionNonce=NULL WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND Status='CLAIMED';
 IF @@ROWCOUNT<>1 THROW 54227,N'Kein unveränderter Queueclaim für den Rollbacknachweis.',3;
 END;
 UPDATE toolbelt_core.WorkerSlotReservation SET State='ROLLED_BACK',IsOccupied=0,EndedAtUtc=ISNULL(EndedAtUtc,SYSUTCDATETIME()) WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus='ROLLED_BACK_HELD' WHERE SlotReservationId=@SlotReservationId;
 SET @Outcome='ROLLED_BACK_HELD';SET @Occupied=0;
 END
 ELSE
 BEGIN
 UPDATE toolbelt_core.WorkerSlotReservation SET State='UNKNOWN',IsOccupied=1,EndedAtUtc=NULL WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus='UNKNOWN' WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkItem SET ManagedHold=1 WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId;
 SET @Outcome='UNKNOWN';SET @Occupied=1;
 END;
 INSERT #tbx_USP_ReconcileWorkerExecution_Result VALUES(@SlotReservationId,@Outcome,@Occupied);
 END TRY BEGIN CATCH
 IF ERROR_NUMBER()=1222 AND XACT_STATE()=1 INSERT #tbx_USP_ReconcileWorkerExecution_Result VALUES(@SlotReservationId,'UNKNOWN',1);
 ELSE THROW;
 END CATCH;
 END;
 END;

 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_ReconcileWorkerExecution_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(SlotReservationId,Outcome,Occupied) SELECT SlotReservationId,Outcome,Occupied FROM #tbx_USP_ReconcileWorkerExecution_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 IF @OwnSessionLock=1 EXEC sys.sp_releaseapplock @Resource=@AttemptResource,@LockOwner=N'Session',@DbPrincipal=N'public';

 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; IF @OwnSessionLock=1 EXEC sys.sp_releaseapplock @Resource=@AttemptResource,@LockOwner=N'Session',@DbPrincipal=N'public';  THROW; END CATCH;
 IF @ResultTable IS NULL SELECT SlotReservationId,Outcome,Occupied FROM #tbx_USP_ReconcileWorkerExecution_Result;
 RETURN 0;
END;
GO
