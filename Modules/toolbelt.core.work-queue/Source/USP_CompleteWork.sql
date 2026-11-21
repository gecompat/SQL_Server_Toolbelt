SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_CompleteWork]
(
      @WorkItemId bigint           = NULL
    , @ClaimToken uniqueidentifier = NULL
    , @ResultTable sysname         = NULL
    , @KeepData    bit             = 0
    , @Debug       tinyint         = 0
    , @Hilfe       bit             = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-completework"
-- description: "Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_CompleteWork"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_CompleteWork.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- ---
--
-- # USP_CompleteWork
--
-- ## Zweck und Einsatzfälle
--
-- Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert.
--
-- ## Voraussetzungen
--
-- Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Ein gesunder Caller-TX ist zulässig. ManagedCompletion verlangt den geschützten äußeren TX, Nonce und AppLock. Ein einfacher aktiver Claim darf einen eigenen TX verwenden. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. |
-- | `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `WorkItemId` | `bigint` | NOT NULL |
-- | `WorkTypeName` | `varchar(128)` | NOT NULL |
-- | `Status` | `varchar(16)` | NOT NULL |
-- | `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL |
-- | `EnqueuedBy` | `sysname` | NOT NULL |
-- | `ClaimedAtUtc` | `datetime2(7)` | NULL |
-- | `ClaimedBy` | `sysname` | NULL |
-- | `CompletedAtUtc` | `datetime2(7)` | NULL |
-- | `CompletedBy` | `sysname` | NULL |
-- | `FailedAtUtc` | `datetime2(7)` | NULL |
-- | `FailedBy` | `sysname` | NULL |
-- | `FailureCode` | `varchar(64)` | NULL |
-- | `FailureMessage` | `nvarchar(1000)` | NULL |
-- | `RowVersion` | `binary(8)` | NOT NULL |
-- | `ClaimGeneration` | `bigint` | NOT NULL |
-- | `LeaseDurationSeconds` | `int` | NULL |
-- | `LeaseUntilUtc` | `datetime2(7)` | NULL |
-- | `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
-- | `IsLeaseExpired` | `bit` | NOT NULL |
-- | `RecoveryCount` | `bigint` | NOT NULL |
-- | `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
-- | `LastRecoveredBy` | `sysname` | NULL |
--
-- Eine Zeile bei erfolgreichem Übergang. 22 feste Statusspalten, nicht alle 41 Viewfelder. ResultTable=NULL liefert den direkten Fachresultset; sonst Routing in das lokale Callerziel über PrepareResultTable ohne zusätzlichen Fach-SELECT. Keine Payload, ClaimToken oder privaten Managedtokens in der Ausgabe. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). RETURN0 vor Fachzugriff; normaler Return ebenfalls 0, bei Requeue implizit.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;
--
-- -- Eigene aktive Claim-ID/Token einsetzen, keine fremden Bindings.
-- DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
-- EXEC toolbelt_core.USP_CompleteWork @WorkItemId=1,@ClaimToken=@Token;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf den öffentlichen Einstieg, passender Datenbankzugriff und Identitätsmapping für zentrale Dreiteilnamen. Keine Rechtevergabe aus dem Skill ableiten. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Kein eigener WorkType-ENQUEUE-/CLAIM-/Handler-EXECUTEguard; die Berechtigung für diesen Supervisor-, Completion- oder Heartbeatweg gezielt vergeben. ClaimToken ist eine zusätzliche Bindung; ManagedCompletion ist wie oben beschrieben geschützt. ResultTable braucht ein vorhandenes zulässiges lokales #Ziel und Helper-/Temp-DDL-/INSERT-Rechte; keine pauschale Serverrolle.
--
-- ## Ressourcenbedarf
--
-- Private Ergebnistabellen in tempdb, Item-/Scheduler-/Indexlocks, Log-/Speicherbedarf und Sperrkonkurrenz. Recovery mit READPAST kann gesperrte Items überspringen. MaxItems ist keine CPU-, Heap-, Log- oder Gesamtlaufzeitquote. Barrierrequeue erzeugt Blockersnapshots nach Gruppenbreite. Kein eigener Timeout-/Retryloop oder Host-/VM-Eingriff. Zählerüberläufe bleiben Enginefehler.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON und XACT_ABORT OFF; KeepData/Debug/Hilfe werden bei NULL zu 0. Nach früher Hilfe werden positive ID/Token und doomed Caller geprüft. Eigener TX bei @@TRANCOUNT=0, sonst Savepoint TBX_WorkQueue_Complete. WorkItem mit UPDLOCK/HOLDLOCK lesen: Existenz, CLAIMED und Token prüfen. ManagedHold=1 ergibt 54201/2.
--
-- Bei einer ManagedReservation muss der ursprüngliche @@TRANCOUNT exakt 1 sein. ManagedCompletionNonce darf nicht NULL sein; SESSION_CONTEXT(toolbelt.worker.completion_nonce) muss exakt passen und der reservationsgebundene Transaction-Disposition-AppLock muss Exclusive sein. Sonst 54201/3. Kein öffentlicher Nonce-/Holdbypass. EngineUTC wird nach dem Lock erfasst; die Lease muss noch aktiv sein.
--
-- Optionales ResultTable vorbereiten. Ein UPDATE setzt COMPLETED und CompletedAtUtc/ORIGINAL_LOGIN, begrenzt auf ID, CLAIMED, Token und aktive Lease; Rowcount muss 1 sein. Die 22-Spalten-Statuszeile wird vor Commit kopiert und gegebenenfalls geroutet. Claim-/Leasehistorie und sonstige Metadaten bleiben erhalten. Keine eigenständige Bereinigung von ManagedReservation, Slot oder Nonce. Eigener COMMIT oder Erhalt des Caller-TX; im CATCH eigener ROLLBACK beziehungsweise committable Savepointrollback. Anschließend abstrakte Debug-Message und gegebenenfalls direkte materialisierte Ausgabe. Der Aufruf führt keinen Handler aus und attestiert keine tatsächliche fachliche Handlerwirkung.
--
-- ## Fehlerbehandlung
--
-- 51920: ID NULL/nicht positiv oder Token NULL. 51924/1: doomed Caller; /2: ResultTablehelper fehlt. 51921: Item fehlt. 51922/1: nicht CLAIMED; /2: Lease abgelaufen. 51923/1: Tokenabweichung; /2: nicht genau ein UPDATE. 54201/2: ManagedHold; /3: fehlender geschützter Completionpfad. Ursprüngliche Engine-, Constraint-, Konvertierungs-, Helper-, Sperr-, Deadlock- und Rollbackfehler bleiben sichtbar. Keine automatische Wiederholung. Spätere Message-/Ergebnistransportfehler können einen eigenen bereits ausgeführten Commit nicht zurücknehmen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Konkurrenz-/Lease-/Recoveryabnahme. Historische Nachweise behalten ihre Artefaktbindung. Kein Exactly-once, Prozess-KILL oder Nachweis für Hostausfall/Koordinatorverlust. Die Claim-/Leasevoraussetzungen gelten für über öffentliche APIs wohlgeformte Items, nicht als Reparaturvertrag für manipulierte interne Tabellen. Keine automatische Secretredaktion; Reason, Fehlertexte und Runtimebefunde privat halten. Keine Installations- oder Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_CompleteWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'Nach Erfolg stets COMPLETED.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EnqueuedAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'UTC-Zeitpunkt der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'EnqueuedBy', N'sysname', 0, 0, NULL, CAST(N'Original-Login der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ClaimedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt des Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'ClaimedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Claimers.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'CompletedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt des Abschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'CompletedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Abschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'FailedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Bei COMPLETED NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'FailedBy', N'sysname', 0, 1, NULL, CAST(N'Bei COMPLETED NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'FailureCode', N'varchar(64)', 0, 1, NULL, CAST(N'Bei COMPLETED NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'FailureMessage', N'nvarchar(1000)', 0, 1, NULL, CAST(N'Bei COMPLETED NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'RowVersion', N'binary(8)', 0, 0, NULL, CAST(N'Aktueller Concurrency-Marker.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Ownership-Generation des abgeschlossenen Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'LeaseDurationSeconds', N'int', 0, 1, NULL, CAST(N'Lease-Dauer des abgeschlossenen Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 17, N'LeaseUntilUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Lease-Grenze des abgeschlossenen Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 18, N'LastHeartbeatAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Letzter Heartbeat des abgeschlossenen Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 19, N'IsLeaseExpired', N'bit', 0, 0, NULL, CAST(N'Bei COMPLETED stets 0.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 20, N'RecoveryCount', N'bigint', 0, 0, NULL, CAST(N'Kumulierte Recoveries vor diesem Abschluss.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 21, N'LastRecoveredAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Zeitpunkt der letzten Recovery.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 22, N'LastRecoveredBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login der letzten Recovery.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51920-51924', NULL, NULL, NULL, NULL, CAST(N'Parameter-, Zustands-, Token- oder Transaktionsfehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Schließt einen zuvor beanspruchten synthetischen Auftrag ab.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_CompleteWork @WorkItemId=1, @ClaimToken=''00000000-0000-0000-0000-000000000001'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkItemId', N'bigint', 1, 0, N'NULL', CAST(N'Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ClaimToken', N'uniqueidentifier', 1, 0, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_CompleteWork' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-completework"
description: "Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_CompleteWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData",' AS nvarchar(max)) + N' "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_CompleteWork.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_CompleteWork

## Zweck und Einsatzfälle

Schließt genau ein CLAIMED Work Item mit dem passenden ClaimToken als COMPLETED ab. Ein fachliches Arbeitsergebnis wird in E1a nicht gespeichert.

## Voraussetzungen

Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Ein gesunder Caller-TX ist zulässig. ManagedCompletion verlangt den geschützten äußer' + N'en TX, Nonce und AppLock. Ein einfacher aktiver Claim darf einen eigenen TX verwenden. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `' + N'@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL |
| `WorkTypeName` | `varchar(128)` | NOT NULL |
| `Status` | `varchar(16)` | NOT NULL |
| `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL |
| `EnqueuedBy` | `sysname` | NOT NULL |
| `ClaimedAtUtc` | `datetime2(7)` | NULL |
| `ClaimedBy` | `sysname` | NULL |
| `CompletedAtUtc` | `datetime2(7)` | NULL |
| `CompletedBy` | `sysname` | NULL |
| `FailedAtUtc` | `datetime2(7)` | NULL |
| `FailedBy` | `sysname` | NULL |
| `FailureCode` | `varchar(64)` | NULL |
| `FailureMessage` | `nvarchar(1000)` | NULL |
| `RowVersion` | `binary(8)` | NOT NULL |
| `ClaimGeneration` | `bigint` | NOT NULL |
| `LeaseDurationSeconds` | `int` | NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
| `IsLeaseExpired` | `bit` | NOT NULL |
| `RecoveryCount` | `bigint` | NOT NULL |
| `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
| `LastRecoveredBy` | `sysname` | NULL |

Eine Zeile bei erfolgreichem Übergang. 22 feste Statusspalten, nicht alle 41 Viewfelder. ResultTable=NULL liefert den direkten Fachresultset; sonst Routing in das lokale Callerziel über PrepareResultTable ohne zusätzlichen Fach-SELECT. Keine Payload, ClaimToken oder privaten Managedtokens in der Ausgabe. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). RETURN0 vor Fachzugriff; normaler Return ebenfalls 0, bei Requeue implizit.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;

-- Eigene aktive Claim-ID/Token einsetzen, keine ' + N'fremden Bindings.
DECLARE @Token uniqueidentifier=''00000000-0000-0000-0000-000000000001'';
EXEC toolbelt_core.USP_CompleteWork @WorkItemId=1,@ClaimToken=@Token;
```

## Rechte

Vorhandenes EXECUTE auf den öffentlichen Einstieg, passender Datenbankzugriff und Identitätsmapping für zentrale Dreiteilnamen. Keine Rechtevergabe aus dem Skill ableiten. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Kein eigener WorkType-ENQUEUE-/CLAIM-/Handler-EXECUTEguard; die Berechtigung für diesen Supervisor-, Completion- oder Heartbeatweg gezielt vergeben. ClaimToken ist eine zusätzliche Bindung; ManagedCompletion ist wie oben beschrieben geschützt. ResultTable braucht ein vorhandenes zulässiges lokales #Ziel und Helper-/Temp-DDL-/INSERT-Rechte; keine pauschale Serverrolle.

## Ressourcenbedarf

Private Ergebnistabellen in tempdb, Item-/Scheduler-/Indexlocks, Log-/Speicherbedarf und Sperrkonkurrenz. Recovery mit READPAST kann gesperrte Items überspringen. MaxItems ist keine CPU-, Heap-, Log- oder Gesamtlaufzeitquote. Barrierrequeue erzeugt Blockersnapshots nach Gruppenbreite. Kein eigener Timeout-/Retryloop oder Host-/VM-Eingriff. Zählerüberläufe bleiben Enginefehler.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF; KeepData/Debug/Hilfe werden bei NULL zu 0. Nach früher Hilfe werden positive ID/Token und doomed Caller geprüft. Eigener TX bei @@TRANCOUNT=0, sonst Savepoint TBX_WorkQueue_Complete. WorkItem mit UPDLOCK/HOLDLOCK lesen: Existenz, CLAIMED und Token prüfen. ManagedHold=1 ergibt 54201/2.

Bei einer ManagedReservation muss der ursprüngliche @@TRANCOUNT exakt 1 sein. ManagedCompletionNonce darf nicht NULL sein; SESSION_CONTEXT(toolbelt.worker.completion_nonce) muss exakt passen und der reservationsgebundene Transaction-Disposition-AppLock muss Exclusive sein. Sonst 54201/3. Kein öffentlicher Nonce-/Holdbypass. EngineUTC wird nach dem Lock erfasst; die Lease muss noch aktiv sein.

Optionales ResultTable vorbereiten. Ein UPDATE setzt COMPLETED und CompletedAtU' + N'tc/ORIGINAL_LOGIN, begrenzt auf ID, CLAIMED, Token und aktive Lease; Rowcount muss 1 sein. Die 22-Spalten-Statuszeile wird vor Commit kopiert und gegebenenfalls geroutet. Claim-/Leasehistorie und sonstige Metadaten bleiben erhalten. Keine eigenständige Bereinigung von ManagedReservation, Slot oder Nonce. Eigener COMMIT oder Erhalt des Caller-TX; im CATCH eigener ROLLBACK beziehungsweise committable Savepointrollback. Anschließend abstrakte Debug-Message und gegebenenfalls direkte materialisierte Ausgabe. Der Aufruf führt keinen Handler aus und attestiert keine tatsächliche fachliche Handlerwirkung.

## Fehlerbehandlung

51920: ID NULL/nicht positiv oder Token NULL. 51924/1: doomed Caller; /2: ResultTablehelper fehlt. 51921: Item fehlt. 51922/1: nicht CLAIMED; /2: Lease abgelaufen. 51923/1: Tokenabweichung; /2: nicht genau ein UPDATE. 54201/2: ManagedHold; /3: fehlender geschützter Completionpfad. Ursprüngliche Engine-, Constraint-, Konvertierungs-, Helper-, Sperr-, Deadlock- und Rollbackfehler bleiben sichtbar. Keine automatische Wiederholung. Spätere Message-/Ergebnistransportfehler können einen eigenen bereits ausgeführten Commit nicht zurücknehmen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Konkurrenz-/Lease-/Recoveryabnahme. Historische Nachweise behalten ihre Artefaktbindung. Kein Exactly-once, Prozess-KILL oder Nachweis für Hostausfall/Koordinatorverlust. Die Claim-/Leasevoraussetzungen gelten für über öffentliche APIs wohlgeformte Items, nicht als Reparaturvertrag für manipulierte interne Tabellen. Keine automatische Secretredaktion; Reason, Fehlertexte und Runtimebefunde privat halten. Keine Installations- oder Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @WorkItemId IS NULL OR @WorkItemId <= 0 OR @ClaimToken IS NULL
        THROW 51920, N'@WorkItemId und @ClaimToken sind erforderlich.', 1;
    IF XACT_STATE() = -1
        THROW 51924, N'Ein Work Item kann in einer uncommittable Caller-Transaktion nicht abgeschlossen werden.', 1;

    CREATE TABLE #tbx_WorkQueue_StatusShape
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,IsLeaseExpired bit NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname NULL);
    CREATE TABLE #tbx_WorkQueue_StatusResult
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,IsLeaseExpired bit NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname NULL);

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    DECLARE @CurrentStatus varchar(16);
    DECLARE @CurrentToken uniqueidentifier,@LeaseUntilUtc datetime2(7),@NowUtc datetime2(7);
    IF @InitialTranCount = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION TBX_WorkQueue_Complete;
    BEGIN TRY
        SELECT @CurrentStatus=Status,@CurrentToken=ClaimToken,@LeaseUntilUtc=LeaseUntilUtc
        FROM toolbelt_core.WorkItem WITH (UPDLOCK,HOLDLOCK)
        WHERE WorkItemId=@WorkItemId;
        IF @CurrentStatus IS NULL THROW 51921,N'Das Work Item existiert nicht.',1;
        IF @CurrentStatus<>'CLAIMED' THROW 51922,N'Nur ein CLAIMED Work Item kann abgeschlossen werden.',1;
        IF @CurrentToken<>@ClaimToken THROW 51923,N'@ClaimToken besitzt das Work Item nicht.',1;
        -- Die geheime Completionnonce entsteht erst im verifizierten Handlerabschluss.
        -- Der reservationsbezogene Transaktionslock bleibt bis zum äußeren Commit.
        DECLARE @ManagedReservationId uniqueidentifier,@ManagedCompletionNonce uniqueidentifier,@ManagedHold bit;
        SELECT @ManagedReservationId=ManagedReservationId,@ManagedCompletionNonce=ManagedCompletionNonce,@ManagedHold=ManagedHold
        FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId;
        IF @ManagedHold=1 THROW 54201,N'Der Claim steht unter persistentem Hold.',2;
        IF @ManagedReservationId IS NOT NULL AND
           (@InitialTranCount<>1 OR @ManagedCompletionNonce IS NULL
            OR TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce')) IS NULL
            OR TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce'))<>@ManagedCompletionNonce
            OR APPLOCK_MODE(N'public',N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@ManagedReservationId),N'Transaction')<>N'Exclusive')
            THROW 54201,N'Der verwaltete Claim besitzt keinen verifizierten Completionpfad.',3;
        SET @NowUtc=SYSUTCDATETIME();
        IF @LeaseUntilUtc<=@NowUtc THROW 51922,N'Die Lease ist abgelaufen; nur Recovery darf den Claim verändern.',2;

        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51924,N'Für @ResultTable fehlt toolbelt.core.result-table.',2;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_StatusShape',@KeepData=@KeepData;
        END;

        UPDATE toolbelt_core.WorkItem
        SET Status='COMPLETED',CompletedAtUtc=@NowUtc,CompletedBy=ORIGINAL_LOGIN()
        WHERE WorkItemId=@WorkItemId AND Status='CLAIMED' AND ClaimToken=@ClaimToken AND LeaseUntilUtc>@NowUtc;
        IF @@ROWCOUNT<>1 THROW 51923,N'Der Claim-Zustand hat sich konkurrierend verändert.',2;

        INSERT INTO #tbx_WorkQueue_StatusResult SELECT WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy) SELECT WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy FROM #tbx_WorkQueue_StatusResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;
        IF @InitialTranCount=0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount=0 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_Complete;
        THROW;
    END CATCH;
    IF @Debug>0 RAISERROR(N'USP_CompleteWork: Work Item abgeschlossen.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_StatusResult;
    RETURN 0;
END;
GO
