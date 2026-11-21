SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EnqueueWork]
(
      @WorkTypeName varchar(128)  = NULL
    , @PayloadJson  nvarchar(max) = NULL
    , @ResultTable  sysname       = NULL
    , @KeepData     bit           = 0
    , @Debug        tinyint       = 0
    , @Hilfe        bit           = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-enqueuework"
-- description: "Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_EnqueueWork"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser einfache Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{\"value\":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- ---
--
-- # USP_EnqueueWork
--
-- ## Zweck und Einsatzfälle
--
-- Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.
--
-- ## Voraussetzungen
--
-- Kanonische Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. Gesunder Caller-TX ist möglich; keine pauschale Caller-TX-Sperre. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser einfache Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler. |
-- | `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
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
-- 22 feste Statusspalten, nicht alle41 VW_WorkQueue-Felder. Genau eine Zeile bei erfolgreichem Aufruf, vor Ausgabe in eigener #Temp materialisiert. Payload,ClaimToken,IdempotencyKey und private Managedtokens fehlen absichtlich. ResultTableNULL:direkter Fachresultset; sonst kompatibles lokales #Ziel über PrepareResultTable und kein zusätzlicher direkter Fachresultset. Hilfe: bisherige zwölfspaltige Standardhilfe plus genau eine vier-spaltige Skillzeile (SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)); RETURN0 vor Fachzugriff. Normaler Erfolgsreturn0.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;
--
-- -- Voraussetzung: tatsächlich registrierter autorisierter NONE-Handler.
-- EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='contoso.noop';
-- -- Erneuter Aufruf erzeugt ein weiteres Item, keine Idempotency-Replaygarantie.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf den gewählten öffentlichen Einstieg und erforderlicher Datenbankzugriff/Identitätsmapping. Keine neuen Rechte aus diesem Skill ableiten. TVF_WorkTypeAuthorization prüft ENQUEUE im tatsächlichen Aufruferkontext. Einfaches Enqueue benötigt Handler-Metadatensicht; Policy/Barrier prüfen sie nicht. Handler-EXECUTE ist hier nicht Voraussetzung, bleibt aber im Claim-/Ausführungspfad separat nötig. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten; ResultTable braucht bereits zulässige lokale #Tabelle und vorhandene Helper-/Temp-DDL-/INSERT-Rechte. Keine Serverrolle pauschal erforderlich.
--
-- ## Ressourcenbedarf
--
-- Aufwand abhängig von Queue-,Policy-,Idempotency- und Barrierblockerumfang sowie Sperrkonkurrenz. Private tempdb-Ergebnisobjekte und optionales Callerziel; DRAIN_BARRIER benötigt Scheduler-/Itemlocks und kann viele Blockergenerationen speichern. Kein eigener CPU-/Heap-/Log-/Gesamtlaufzeit-/Ergebnisbyte-Limiter, keine automatische Wiederholung. Nur Payload ist auf65536Bytes begrenzt; das ist keine gesamte Laufzeit- oder Ausgabegarantie.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON,XACT_ABORT OFF;KeepData/Debug/HilfeNULL→0. Frühe Hilfe vor Fachargumenten. Pflichtname,65536Byte-Payloadgrenze und doomed Caller werden geprüft. Eigener TX oder gesunder Savepoint TBX_WorkQueue_Enqueue. WorkType UPDLOCK/HOLDLOCK: registriert,aktiv,Handler als P/PC durch OBJECT_ID sichtbar und ENQUEUE-Policy erlaubt; kein Handler-EXECUTE-Test oder Aufruf. NONE verlangtNULL, JSON_PAYLOAD ein JSON-Objekt. Optionales ResultTable wird vor INSERT vorbereitet. INSERT nur WorkTypeId/PayloadJson; übrige Werte kommen aus kanonischen WorkItem-Defaults: QUEUED,Gruppe default,Priority0,SHARED,MaxAttempts3,Base60,Cap3600,Cycle1,Attempt0,Epoch0,IdempotencyKeyNULL. Jeder erfolgreiche Aufruf legt neu an.22-Spalten-Ergebnis vor Commit kopieren/optional routen. Nur eigener TX commit; CATCH eigener Rollback oder committable Savepointrollback. Debug>0 Severity10 NOWAIT nach Commit, danach direkterSELECT nur ohne Ziel. Ein späterer Transport-/Messagefehler nimmt eigenen Commit nicht zurück. RETURN0.
--
-- ## Fehlerbehandlung
--
-- 51900 Name fehlt oder WorkType nicht registriert;51901 deaktiviert;51902 Handler P/PC nicht sichtbar/verfügbar;51998 ENQUEUE verboten;51903 Payload beiNONE;51904 ungültiger JSON_PAYLOAD;51905 Payload>65536Bytes;51906 doomedCaller;51908 ResultTablehelper fehlt. Ursprüngliche Engine-,Constraint-,Helper-,Temp-/Lock-/Deadlock-/Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung; eigene bereits committete Arbeit wird durch einen späteren Ergebnistransportfehler nicht zurückgenommen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Idempotency-/Konkurrenzabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Kein Exactly-once, Handler-/Hoststart, automatische Recovery oder fremde Claimübernahme. Standard-Statusfelder enthalten Namen/Zeit-/Fehlerdaten; vertrauliche Eingaben/Runtimebefunde nicht öffentlich loggen. Kein Redaktions-/Secretfilter. Erfolgsreturn/WasCreated/Status allein attestieren keine tatsächliche Handlerwirkung oder Installation/Rechte.
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
            CAST(N'USP_EnqueueWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'Nach Enqueue stets QUEUED.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EnqueuedAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'UTC-Zeitpunkt der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'EnqueuedBy', N'sysname', 0, 0, NULL, CAST(N'Original-Login der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ClaimedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt des Claims; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'ClaimedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Claimers; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'CompletedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Abschlusszeit; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'CompletedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Abschlusses; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'FailedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Fehlerzeit; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'FailedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Fail-Aufrufs; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'FailureCode', N'varchar(64)', 0, 1, NULL, CAST(N'Stabiler Fehlercode; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'FailureMessage', N'nvarchar(1000)', 0, 1, NULL, CAST(N'Optionale bereinigte Fehlermeldung; nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'RowVersion', N'binary(8)', 0, 0, NULL, CAST(N'Aktueller Concurrency-Marker.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Nach Enqueue 0; wird bei jedem Claim erhöht.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'LeaseDurationSeconds', N'int', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 17, N'LeaseUntilUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 18, N'LastHeartbeatAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 19, N'IsLeaseExpired', N'bit', 0, 0, NULL, CAST(N'Nach Enqueue 0.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 20, N'RecoveryCount', N'bigint', 0, 0, NULL, CAST(N'Nach Enqueue 0.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 21, N'LastRecoveredAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 22, N'LastRecoveredBy', N'sysname', 0, 1, NULL, CAST(N'Nach Enqueue NULL.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51900-51908,51998', NULL, NULL, NULL, NULL, CAST(N'Work-Type-, Payload-, Transaktions- oder ResultTable-Fehler. 51998: explizites ENQUEUE fehlt oder DENY gewinnt; Prüfung vor Insert und Idempotencyauskunft.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Reiht synthetische JSON-Arbeit ein.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName=''demo.json'', @PayloadJson=N''{"value":1}'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser ältere Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@PayloadJson', N'nvarchar(max)', 0, 1, N'NULL', CAST(N'Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N''{"value":1}''. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder.' AS nvarchar(max)), NULL),
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
 CONVERT(sysname,CAST(N'USP_EnqueueWork' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-enqueuework"
description: "Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_EnqueueWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser einfache Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N''{\"value\":1}''. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, pers' AS nvarchar(max)) + N'istente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_EnqueueWork.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_EnqueueWork

## Zweck und Einsatzfälle

Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.

## Voraussetzungen

Kanonische ' + N'Queue2.1.0 einschließlich WorkType/ResultTable derselben Datenbank. SQL2019/2022/2025 unter Windows/Linux mit geeignetem CL150/160/170 gemäß Modulmatrix. Tatsächlich registrierter aktiver WorkType mit ENQUEUE-Policy und passendem ParameterMode. Nur einfaches Enqueue verlangt zusätzlich sichtbaren P/PC-Handler; kein Handleraufruf. Gesunder Caller-TX ist möglich; keine pauschale Caller-TX-Sperre. Alle Parameter haben technische Defaults für Hilfe; fachliche NULL-Pflichtwerte sind keine gültigen Ersatzwerte. SQL-Typbindung passiert vor dem Prozedurcode.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Erfordert aktiven Eintrag und ENQUEUE-Policy; dieser einfache Enqueue-Pfad benötigt zusätzlich Metadatensicht auf den Handler. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N''{"value":1}''. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresul' + N'tsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

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

22 feste Statusspalten, nicht alle41 VW_WorkQueue-Felder. Genau eine Zeile bei erfolgreichem Aufruf, vor Ausgabe in eigener #Temp materialisiert. Payload,ClaimToken,IdempotencyKey und private Managedtokens f' + N'ehlen absichtlich. ResultTableNULL:direkter Fachresultset; sonst kompatibles lokales #Ziel über PrepareResultTable und kein zusätzlicher direkter Fachresultset. Hilfe: bisherige zwölfspaltige Standardhilfe plus genau eine vier-spaltige Skillzeile (SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max)); RETURN0 vor Fachzugriff. Normaler Erfolgsreturn0.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;

-- Voraussetzung: tatsächlich registrierter autorisierter NONE-Handler.
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName=''contoso.noop'';
-- Erneuter Aufruf erzeugt ein weiteres Item, keine Idempotency-Replaygarantie.
```

## Rechte

Vorhandenes EXECUTE auf den gewählten öffentlichen Einstieg und erforderlicher Datenbankzugriff/Identitätsmapping. Keine neuen Rechte aus diesem Skill ableiten. TVF_WorkTypeAuthorization prüft ENQUEUE im tatsächlichen Aufruferkontext. Einfaches Enqueue benötigt Handler-Metadatensicht; Policy/Barrier prüfen sie nicht. Handler-EXECUTE ist hier nicht Voraussetzung, bleibt aber im Claim-/Ausführungspfad separat nötig. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten; ResultTable braucht bereits zulässige lokale #Tabelle und vorhandene Helper-/Temp-DDL-/INSERT-Rechte. Keine Serverrolle pauschal erforderlich.

## Ressourcenbedarf

Aufwand abhängig von Queue-,Policy-,Idempotency- und Barrierblockerumfang sowie Sperrkonkurrenz. Private tempdb-Ergebnisobjekte und optionales Callerziel; DRAIN_BARRIER benötigt Scheduler-/Itemlocks und kann viele Blockergenerationen speichern. Kein eigener CPU-/Heap-/Log-/Gesamtlaufzeit-/Ergebnisbyte-Limiter, keine automatische Wiederholung. Nur Payload ist auf65536Bytes begrenzt; das ist keine gesamte Laufzeit- oder Ausgabegarantie.

## Nebenwirkungen

NOCOUNT ON,XACT_ABORT OFF;KeepData/Debug/HilfeNULL→0. Frühe Hilfe vor Fachargumenten. Pflichtname,65536Byte-Payloadgrenze und doomed Caller werden geprüft. Eigener TX oder gesunder Savepoin' + N't TBX_WorkQueue_Enqueue. WorkType UPDLOCK/HOLDLOCK: registriert,aktiv,Handler als P/PC durch OBJECT_ID sichtbar und ENQUEUE-Policy erlaubt; kein Handler-EXECUTE-Test oder Aufruf. NONE verlangtNULL, JSON_PAYLOAD ein JSON-Objekt. Optionales ResultTable wird vor INSERT vorbereitet. INSERT nur WorkTypeId/PayloadJson; übrige Werte kommen aus kanonischen WorkItem-Defaults: QUEUED,Gruppe default,Priority0,SHARED,MaxAttempts3,Base60,Cap3600,Cycle1,Attempt0,Epoch0,IdempotencyKeyNULL. Jeder erfolgreiche Aufruf legt neu an.22-Spalten-Ergebnis vor Commit kopieren/optional routen. Nur eigener TX commit; CATCH eigener Rollback oder committable Savepointrollback. Debug>0 Severity10 NOWAIT nach Commit, danach direkterSELECT nur ohne Ziel. Ein späterer Transport-/Messagefehler nimmt eigenen Commit nicht zurück. RETURN0.

## Fehlerbehandlung

51900 Name fehlt oder WorkType nicht registriert;51901 deaktiviert;51902 Handler P/PC nicht sichtbar/verfügbar;51998 ENQUEUE verboten;51903 Payload beiNONE;51904 ungültiger JSON_PAYLOAD;51905 Payload>65536Bytes;51906 doomedCaller;51908 ResultTablehelper fehlt. Ursprüngliche Engine-,Constraint-,Helper-,Temp-/Lock-/Deadlock-/Konvertierungsfehler bleiben sichtbar. Keine automatische Wiederholung; eigene bereits committete Arbeit wird durch einen späteren Ergebnistransportfehler nicht zurückgenommen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Idempotency-/Konkurrenzabnahme. Historische Nachweise bleiben an ihre Artefakte gebunden. Kein Exactly-once, Handler-/Hoststart, automatische Recovery oder fremde Claimübernahme. Standard-Statusfelder enthalten Namen/Zeit-/Fehlerdaten; vertrauliche Eingaben/Runtimebefunde nicht öffentlich loggen. Kein Redaktions-/Secretfilter. Erfolgsreturn/WasCreated/Status allein attestieren keine tatsächliche Handlerwirkung oder Installation/Rechte.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51900, N'@WorkTypeName ist erforderlich.', 1;
    IF DATALENGTH(@PayloadJson) > 65536
        THROW 51905, N'@PayloadJson darf höchstens 64 KiB umfassen.', 1;
    IF XACT_STATE() = -1
        THROW 51906, N'Ein Work Item kann in einer uncommittable Caller-Transaktion nicht eingereiht werden.', 1;

    CREATE TABLE #tbx_WorkQueue_StatusShape
    (
          WorkItemId bigint NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , EnqueuedAtUtc datetime2(7) NOT NULL
        , EnqueuedBy sysname NOT NULL
        , ClaimedAtUtc datetime2(7) NULL
        , ClaimedBy sysname NULL
        , CompletedAtUtc datetime2(7) NULL
        , CompletedBy sysname NULL
        , FailedAtUtc datetime2(7) NULL
        , FailedBy sysname NULL
        , FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL
        , FailureMessage nvarchar(1000) NULL
        , RowVersion binary(8) NOT NULL
        , ClaimGeneration bigint NOT NULL
        , LeaseDurationSeconds int NULL
        , LeaseUntilUtc datetime2(7) NULL
        , LastHeartbeatAtUtc datetime2(7) NULL
        , IsLeaseExpired bit NOT NULL
        , RecoveryCount bigint NOT NULL
        , LastRecoveredAtUtc datetime2(7) NULL
        , LastRecoveredBy sysname NULL
    );
    CREATE TABLE #tbx_WorkQueue_StatusResult
    (
          WorkItemId bigint NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , EnqueuedAtUtc datetime2(7) NOT NULL
        , EnqueuedBy sysname NOT NULL
        , ClaimedAtUtc datetime2(7) NULL
        , ClaimedBy sysname NULL
        , CompletedAtUtc datetime2(7) NULL
        , CompletedBy sysname NULL
        , FailedAtUtc datetime2(7) NULL
        , FailedBy sysname NULL
        , FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL
        , FailureMessage nvarchar(1000) NULL
        , RowVersion binary(8) NOT NULL
        , ClaimGeneration bigint NOT NULL
        , LeaseDurationSeconds int NULL
        , LeaseUntilUtc datetime2(7) NULL
        , LastHeartbeatAtUtc datetime2(7) NULL
        , IsLeaseExpired bit NOT NULL
        , RecoveryCount bigint NOT NULL
        , LastRecoveredAtUtc datetime2(7) NULL
        , LastRecoveredBy sysname NULL
    );

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    DECLARE @WorkTypeId bigint;
    DECLARE @ParameterMode varchar(16);
    DECLARE @IsEnabled bit;
    DECLARE @HandlerSchema sysname;
    DECLARE @HandlerProcedure sysname;
    DECLARE @WorkItemId bigint;

    IF @InitialTranCount = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION TBX_WorkQueue_Enqueue;

    BEGIN TRY
        SELECT
              @WorkTypeId = wt.WorkTypeId
            , @ParameterMode = wt.ParameterMode
            , @IsEnabled = wt.IsEnabled
            , @HandlerSchema = wt.HandlerSchema
            , @HandlerProcedure = wt.HandlerProcedure
        FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
        WHERE wt.WorkTypeName = @WorkTypeName;

        IF @WorkTypeId IS NULL
            THROW 51900, N'Der angeforderte Work Type ist nicht registriert.', 1;
        IF @IsEnabled <> 1
            THROW 51901, N'Der angeforderte Work Type ist deaktiviert.', 1;
        IF COALESCE
           (
               OBJECT_ID(QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure), N'P'),
               OBJECT_ID(QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure), N'PC')
           ) IS NULL
            THROW 51902, N'Der registrierte Work-Type-Handler ist nicht verfügbar.', 1;
        IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_WorkTypeAuthorization(@WorkTypeId,'ENQUEUE') WHERE IsAllowed=1)
            THROW 51998,N'Keine Einreihberechtigung für diesen Work Type.',1;
        IF @ParameterMode = 'NONE' AND @PayloadJson IS NOT NULL
            THROW 51903, N'Für einen Work Type mit ParameterMode NONE muss @PayloadJson NULL sein.', 1;
        IF @ParameterMode = 'JSON_PAYLOAD'
           AND (@PayloadJson IS NULL OR ISJSON(@PayloadJson) <> 1 OR LEFT(LTRIM(@PayloadJson), 1) <> N'{')
            THROW 51904, N'Für JSON_PAYLOAD muss @PayloadJson ein JSON-Objekt sein.', 1;

        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
                THROW 51908, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;
            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = @ResultTable
                , @LikeTable = N'#tbx_WorkQueue_StatusShape'
                , @KeepData = @KeepData;
        END;

        INSERT INTO toolbelt_core.WorkItem (WorkTypeId, PayloadJson)
        VALUES (@WorkTypeId, @PayloadJson);
        SET @WorkItemId = SCOPE_IDENTITY();

        INSERT INTO #tbx_WorkQueue_StatusResult
        SELECT WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy
        FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId = @WorkItemId;

        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max) =
                N'INSERT INTO ' + QUOTENAME(@ResultTable)
                + N' (WorkItemId, WorkTypeName, Status, EnqueuedAtUtc, EnqueuedBy, ClaimedAtUtc, ClaimedBy, CompletedAtUtc, CompletedBy, FailedAtUtc, FailedBy, FailureCode, FailureMessage, RowVersion, ClaimGeneration, LeaseDurationSeconds, LeaseUntilUtc, LastHeartbeatAtUtc, IsLeaseExpired, RecoveryCount, LastRecoveredAtUtc, LastRecoveredBy)'
                + N' SELECT WorkItemId, WorkTypeName, Status, EnqueuedAtUtc, EnqueuedBy, ClaimedAtUtc, ClaimedBy, CompletedAtUtc, CompletedBy, FailedAtUtc, FailedBy, FailureCode, FailureMessage, RowVersion, ClaimGeneration, LeaseDurationSeconds, LeaseUntilUtc, LastHeartbeatAtUtc, IsLeaseExpired, RecoveryCount, LastRecoveredAtUtc, LastRecoveredBy FROM #tbx_WorkQueue_StatusResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;

        IF @InitialTranCount = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION TBX_WorkQueue_Enqueue;
        THROW;
    END CATCH;

    IF @Debug > 0
        RAISERROR(N'USP_EnqueueWork: ein Work Item wurde eingereiht.', 10, 1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_StatusResult;
    RETURN 0;
END;
GO
