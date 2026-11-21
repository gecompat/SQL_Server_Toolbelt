-- ============================================================================
-- Objekt: toolbelt_core.USP_SetWorkerState
-- Zweck: Steuert ACTIVE, PAUSED oder DRAINING einer exakten lebenden Workergeneration.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene Rechte, keine Grants.
-- Sichtbarkeit: public
-- Transaktion: eigene kurze Steuertransaktion
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_SetWorkerState
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @RequestedState varchar(16)=NULL,
 @ExpectedConfigVersion binary(8)=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-setworkerstate"
-- description: "Steuert versionsgebunden die neueste noch lebende Worker-generation auf ACTIVE,PAUSED oder DRAINING."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_SetWorkerState"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID."}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Für diesen administrativen Übergang muss es die neueste lebende Generation der stabilen WorkerId sein."}, {"name": "@RequestedState", "sql_type": "varchar(16)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ und binär/case-sensitiv, ohne nachgestellte Spaces: ACTIVE = neue Admission wieder zulassen; PAUSED = neue Admission pausieren; DRAINING = Auslaufen ohne neue Admission anfordern. Laufende Arbeit wird dadurch nicht abgebrochen. CLOSED/UNREACHABLE sind keine setzbaren Eingabewerte; NULL/leer/andere Werte ungültig."}, {"name": "@ExpectedConfigVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_SetWorkerState.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_SetWorkerState
--
-- ## Zweck und Einsatzfälle
--
-- Steuert versionsgebunden die neueste noch lebende Worker-generation auf ACTIVE,PAUSED oder DRAINING.
--
-- ## Voraussetzungen
--
-- Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@WorkerId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
-- | `@WorkerGeneration` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Für diesen administrativen Übergang muss es die neueste lebende Generation der stabilen WorkerId sein. |
-- | `@RequestedState` | `varchar(16)` | `NULL` | Taxativ und binär/case-sensitiv, ohne nachgestellte Spaces: ACTIVE = neue Admission wieder zulassen; PAUSED = neue Admission pausieren; DRAINING = Auslaufen ohne neue Admission anfordern. Laufende Arbeit wird dadurch nicht abgebrochen. CLOSED/UNREACHABLE sind keine setzbaren Eingabewerte; NULL/leer/andere Werte ungültig. |
-- | `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
--
-- SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen fachlichen Ersatzidentitäten. Quelle und Effekte unterscheiden admin- und tokengebundene Pfade ausdrücklich.
--
-- ## Ergebnisse
--
-- WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,State varchar(16) NOT NULL,ConfigVersion binary(8) NOT NULL Bei normalem Erfolg RETURN0; keine OUTPUT-Parameter. NULLResultTable:direkte eine Zeile nach Commit. Sonst Formvorbereitung und INSERT in die vom Caller bereits angelegte lokale #Temp innerhalb derselben Mutationstransaktion; kein weiterer direkter Fachresultset. KeepData unverändert zum kanonischen Helper. Hilfe: bisheriger zwölfspaltiger Standardhelp-Resultset plus genau eine zusätzliche Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max); RETURN0 vor Fachprüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;
--
-- -- Nur mit neuester lebender Workeridentität und frischer globaler Version:
-- DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',@Version binary(8)=0x0000000000000001;
-- EXEC toolbelt_core.USP_SetWorkerState @WorkerId=@Id,@WorkerGeneration=1,@RequestedState='PAUSED',@ExpectedConfigVersion=@Version;
-- -- Synthetische/veraltete Werte werden abgewiesen.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf genau diese öffentliche Prozedur. Dies ist ein administrativer Steuerpfad ohne Owner-/WorkerTokenprüfung; dafür getrennte passende EXECUTE-Rechte voraussetzen, nicht aus einem Statusleserecht ableiten. Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Keine Rechtevergabe, Serverrolle, Hostauthentifizierung oder pauschalen direkten Tabellenrechte. Für ResultTable-/Statuslese-/CrossDB-Zugriffe jeweils bestehende passende Rechte und Identitätsmapping; ein Dreiteilname überträgt keine Autorität.
--
-- ## Ressourcenbedarf
--
-- Kurze eigene Transaktion, globale Gate-/Scheduler-/Konfigurationssperren und Workerregistrationszugriffe; Register liest neueste Generation und aktualisiert gegebenenfalls mehrere Vorgänger, SetState mehrere AdmissionPaused-Zeilen. Keine implementierte CPU-/Zeit-/Log-/Heap-/Ausgabebytequote oder eigener Locktimeout. Blockierung/Deadlock/Log-/tempdbdruck bleibt möglich. Technische Token-/Principalwerte niemals in öffentliche Testnachweise übernehmen.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und SET XACT_ABORT OFF im Prozedurcode vor dem positiven Hilfezweig; dort keine fachlichen Prüfungen, temporären Ergebnisobjekte oder Mutationen und keine eigenen Debugmessages. Private feste #tbx_-Ergebnistemp vor Callertransaktionsguard. Fachpfad verlangt @@TRANCOUNT0/XACT_STATE0, danach eigene BEGIN TRANSACTION und TRY. Reihenfolge UPDLOCK/HOLDLOCK Gate→Scheduler→Konfigurationszeile. Setzt zunächst AdmissionPaused auf ALLEN Generationen derselben WorkerId:0 für ACTIVE,1 für PAUSED/DRAINING. Dann State ausschließlich für die angeforderte neueste Generation, wenn weder CLOSED noch UNREACHABLE und LastHeartbeat+gespeicherterUnreachableSeconds>EngineUTC. Scheitert diese Prüfung, wird auch das erste UPDATE in derselben eigenen Transaktion zurückgerollt. Keine WorkerToken-/Ownerprüfung in diesem administrativen Aufruf. Bereits laufende Arbeit wird nicht abgebrochen und Claims/Reservations werden nicht übernommen. Selbstupdate der globalen Konfiguration erzeugt neue ConfigVersion auch bei identischem RequestedState. Kein beliebiges Setzen von CLOSED oder UNREACHABLE und kein Wiederbeleben abgelaufener Generationen. Direkte Ergebnisausgabe erfolgt erst nach Commit. Ein späterer Client-/Transportfehler kann einen bereits erfolgreichen Commit nicht rückgängig machen. ResultTable-Helper und INSERT liegen vor Commit; bei Fehlern rollt die eigene aktive Transaktion zurück. Keine Savepointunterstützung für Callertransaktionen und kein eigener Retry. @Debug erzeugt keine eigenen Messages; nicht an den ResultTable-Helper weitergereicht.
--
-- ## Fehlerbehandlung
--
-- 54210/1 Callertransaktion bzw.nichtneutraler XACT_STATE.54211/1 fehlender Gate-/Scheduler-/Konfigurationsvertrag; fehlende Tabellen/kompilierte Abhängigkeiten können bereits als ursprüngliche Enginefehler auftreten. 54212/1 NULL/veraltete globale ConfigVersion.54213/5 RequestedStateNULL/andersalsACTIVE,PAUSED,DRAINING/nachgestellteSpaces.54215/5 irgendeine höhere Generation zur WorkerId.54215/4 nicht genau eine adressierte nichtCLOSED/nichtUNREACHABLE/noch-frische Generation. Fehlende IDs/Generationen binden keine Zeile; nicht als generelle54213-Argumentprüfung darstellen. Ursprüngliche Sperr-, Constraint-, Arithmetic-, Helper-, INSERT- und Enginefehler bleiben sichtbar. CATCH rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine fachliche Fehlerstatuszeile.
--
-- ## Aussagegrenzen
--
-- Getrennte administrative EXECUTE-Autorität, kein WorkerToken- oder SID-Besitzbeweis. ACTIVE erlaubt neue Admission nur nach den übrigen Provider-/Queue-/Kapazitätsprüfungen. Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Bindung. Keine Exactly-once-/Hostverlust-/Kill- oder vollständige Betriebsqualifikation allein aus Status/Token/Registrierung. Zusätzliche Skillhilfe wird nicht durch alte Standardhilfe-Nachweise qualifiziert.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_SetWorkerState' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Steuert ACTIVE, PAUSED oder DRAINING einer exakten lebenden Workergeneration.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkerId', N'uniqueidentifier', 0, 0, NULL, CAST(N'WorkerId gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkerGeneration', N'bigint', 0, 0, NULL, CAST(N'WorkerGeneration gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'State', N'varchar(16)', 0, 0, NULL, CAST(N'State gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ConfigVersion', N'binary(8)', 0, 0, NULL, CAST(N'ConfigVersion gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ausschließlich synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkerId', N'uniqueidentifier', 1, 0, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@WorkerGeneration', N'bigint', 1, 0, N'NULL', CAST(N'Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Für diesen administrativen Übergang muss es die neueste lebende Generation der stabilen WorkerId sein.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@RequestedState', N'varchar(16)', 1, 0, N'NULL', CAST(N'Taxativ und binär/case-sensitiv, ohne nachgestellte Spaces: ACTIVE = neue Admission wieder zulassen; PAUSED = neue Admission pausieren; DRAINING = Auslaufen ohne neue Admission anfordern. Laufende Arbeit wird dadurch nicht abgebrochen. CLOSED/UNREACHABLE sind keine setzbaren Eingabewerte; NULL/leer/andere Werte ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ExpectedConfigVersion', N'binary(8)', 1, 0, N'NULL', CAST(N'Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_SetWorkerState' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-setworkerstate"
description: "Steuert versionsgebunden die neueste noch lebende Worker-generation auf ACTIVE,PAUSED oder DRAINING."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_SetWorkerState"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID."}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Für diesen administrativen Übergang muss es die neueste lebende Generation der stabilen WorkerId sein."}, {"name": "@RequestedState", "sql_type": "varchar(16)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Taxativ und binär/case-sensitiv, ohne nachgestellte Spaces: ACTIVE = neue Admission wieder zulassen; PAUSED = neue Admission pausieren; DRAINING = Auslaufen ohne neue Admission anfordern. Laufende Arbeit wird dadurch nicht abgebrochen. CLOSED/UNREACHABLE sind keine setzbaren Eingabewerte; NULL/leer/andere Werte ungültig."}, {"name": "@ExpectedConfigVersion", "sql_type": "binary(8)", "sq' AS nvarchar(max)) + N'l_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: b' + N'isherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_SetWorkerState.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_SetWorkerState

## Zweck und Einsatzfälle

Steuert versionsgebunden die neueste noch lebende Worker-generation auf ACTIVE,PAUSED oder DRAINING.

## Voraussetzungen

Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; N' + N'ULL/fehlende oder unpassende Generation wird abgewiesen. Für diesen administrativen Übergang muss es die neueste lebende Generation der stabilen WorkerId sein. |
| `@RequestedState` | `varchar(16)` | `NULL` | Taxativ und binär/case-sensitiv, ohne nachgestellte Spaces: ACTIVE = neue Admission wieder zulassen; PAUSED = neue Admission pausieren; DRAINING = Auslaufen ohne neue Admission anfordern. Laufende Arbeit wird dadurch nicht abgebrochen. CLOSED/UNREACHABLE sind keine setzbaren Eingabewerte; NULL/leer/andere Werte ungültig. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transakti' + N'ons-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen fachlichen Ersatzidentitäten. Quelle und Effekte unterscheiden admin- und tokengebundene Pfade ausdrücklich.

## Ergebnisse

WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,State varchar(16) NOT NULL,ConfigVersion binary(8) NOT NULL Bei normalem Erfolg RETURN0; keine OUTPUT-Parameter. NULLResultTable:direkte eine Zeile nach Commit. Sonst Formvorbereitung und INSERT in die vom Caller bereits angelegte lokale #Temp innerhalb derselben Mutationstransaktion; kein weiterer direkter Fachresultset. KeepData unverändert zum kanonischen Helper. Hilfe: bisheriger zwölfspaltiger Standardhelp-Resultset plus genau eine zusätzliche Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max); RETURN0 vor Fachprüfung.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_SetWorkerState @Hilfe=1;

-- Nur mit neuester lebender Workeridentität und frischer globaler Version:
DECLARE @Id uniqueidentifier=''00000000-0000-0000-0000-000000000001'',@Version binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerState @WorkerId=@Id,@WorkerGeneration=1,@RequestedState=''PAUSED'',@ExpectedConfigVersion=@Version;
-- Synthetische/veraltete Werte werden abgewiesen.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur. Dies ist ein administrativer Steuerpfad ohne Owner-/WorkerTokenprüfung; dafür getrennte passende EXECUTE-Rechte voraussetzen, nicht aus einem Statusleserecht ableiten. Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Keine Rechtevergabe, Serverrolle, Hostauthentifizierung oder pauschalen direkten Tabellenrechte. Für ResultTable-/Statuslese-/CrossDB-Zugriffe jeweils bestehende passende Rechte und' + N' Identitätsmapping; ein Dreiteilname überträgt keine Autorität.

## Ressourcenbedarf

Kurze eigene Transaktion, globale Gate-/Scheduler-/Konfigurationssperren und Workerregistrationszugriffe; Register liest neueste Generation und aktualisiert gegebenenfalls mehrere Vorgänger, SetState mehrere AdmissionPaused-Zeilen. Keine implementierte CPU-/Zeit-/Log-/Heap-/Ausgabebytequote oder eigener Locktimeout. Blockierung/Deadlock/Log-/tempdbdruck bleibt möglich. Technische Token-/Principalwerte niemals in öffentliche Testnachweise übernehmen.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Prozedurcode vor dem positiven Hilfezweig; dort keine fachlichen Prüfungen, temporären Ergebnisobjekte oder Mutationen und keine eigenen Debugmessages. Private feste #tbx_-Ergebnistemp vor Callertransaktionsguard. Fachpfad verlangt @@TRANCOUNT0/XACT_STATE0, danach eigene BEGIN TRANSACTION und TRY. Reihenfolge UPDLOCK/HOLDLOCK Gate→Scheduler→Konfigurationszeile. Setzt zunächst AdmissionPaused auf ALLEN Generationen derselben WorkerId:0 für ACTIVE,1 für PAUSED/DRAINING. Dann State ausschließlich für die angeforderte neueste Generation, wenn weder CLOSED noch UNREACHABLE und LastHeartbeat+gespeicherterUnreachableSeconds>EngineUTC. Scheitert diese Prüfung, wird auch das erste UPDATE in derselben eigenen Transaktion zurückgerollt. Keine WorkerToken-/Ownerprüfung in diesem administrativen Aufruf. Bereits laufende Arbeit wird nicht abgebrochen und Claims/Reservations werden nicht übernommen. Selbstupdate der globalen Konfiguration erzeugt neue ConfigVersion auch bei identischem RequestedState. Kein beliebiges Setzen von CLOSED oder UNREACHABLE und kein Wiederbeleben abgelaufener Generationen. Direkte Ergebnisausgabe erfolgt erst nach Commit. Ein späterer Client-/Transportfehler kann einen bereits erfolgreichen Commit nicht rückgängig machen. ResultTable-Helper und INSERT liegen vor Commit; bei Fehlern rollt die eigene aktive Transaktion zurück. Keine Savepointunterstützung für Caller' + N'transaktionen und kein eigener Retry. @Debug erzeugt keine eigenen Messages; nicht an den ResultTable-Helper weitergereicht.

## Fehlerbehandlung

54210/1 Callertransaktion bzw.nichtneutraler XACT_STATE.54211/1 fehlender Gate-/Scheduler-/Konfigurationsvertrag; fehlende Tabellen/kompilierte Abhängigkeiten können bereits als ursprüngliche Enginefehler auftreten. 54212/1 NULL/veraltete globale ConfigVersion.54213/5 RequestedStateNULL/andersalsACTIVE,PAUSED,DRAINING/nachgestellteSpaces.54215/5 irgendeine höhere Generation zur WorkerId.54215/4 nicht genau eine adressierte nichtCLOSED/nichtUNREACHABLE/noch-frische Generation. Fehlende IDs/Generationen binden keine Zeile; nicht als generelle54213-Argumentprüfung darstellen. Ursprüngliche Sperr-, Constraint-, Arithmetic-, Helper-, INSERT- und Enginefehler bleiben sichtbar. CATCH rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine fachliche Fehlerstatuszeile.

## Aussagegrenzen

Getrennte administrative EXECUTE-Autorität, kein WorkerToken- oder SID-Besitzbeweis. ACTIVE erlaubt neue Admission nur nach den übrigen Provider-/Queue-/Kapazitätsprüfungen. Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Bindung. Keine Exactly-once-/Hostverlust-/Kill- oder vollständige Betriebsqualifikation allein aus Status/Token/Registrierung. Zusätzliche Skillhilfe wird nicht durch alte Standardhilfe-Nachweise qualifiziert.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 CREATE TABLE #tbx_USP_SetWorkerState_Result(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,State varchar(16) NOT NULL,ConfigVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @ExpectedConfigVersion IS NULL OR @ExpectedConfigVersion<>@Config THROW 54212,N'Die erwartete Konfigurationsversion ist veraltet oder fehlt.',1;
 IF @RequestedState IS NULL OR @RequestedState COLLATE Latin1_General_100_BIN2 NOT IN('ACTIVE','PAUSED','DRAINING') OR DATALENGTH(@RequestedState)<>LEN(@RequestedState) THROW 54213,N'Der angeforderte Zustand ist ungültig.',5;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@WorkerId AND WorkerGeneration>@WorkerGeneration) THROW 54215,N'Adminsteuerung benötigt die aktuellste stabile Workergeneration.',5;
 UPDATE toolbelt_core.WorkerRegistration SET AdmissionPaused=CASE WHEN @RequestedState='ACTIVE' THEN 0 ELSE 1 END WHERE WorkerId=@WorkerId;
 UPDATE toolbelt_core.WorkerRegistration SET State=@RequestedState WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND State NOT IN('CLOSED','UNREACHABLE') AND DATEADD(SECOND,UnreachableSeconds,LastHeartbeatAtUtc)>SYSUTCDATETIME();
 IF @@ROWCOUNT<>1 THROW 54215,N'Die gewählte Generation ist nicht lebend.',4;
 UPDATE toolbelt_core.WorkerControlConfiguration SET MaxConcurrentExecutions=MaxConcurrentExecutions WHERE ConfigurationId=1;
 INSERT #tbx_USP_SetWorkerState_Result SELECT w.WorkerId,w.WorkerGeneration,w.State,c.ConfigVersion FROM toolbelt_core.WorkerRegistration w CROSS JOIN toolbelt_core.WorkerControlConfiguration c WHERE w.WorkerId=@WorkerId AND w.WorkerGeneration=@WorkerGeneration AND c.ConfigurationId=1;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_SetWorkerState_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkerId,WorkerGeneration,State,ConfigVersion) SELECT WorkerId,WorkerGeneration,State,ConfigVersion FROM #tbx_USP_SetWorkerState_Result';
 EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkerId,WorkerGeneration,State,ConfigVersion FROM #tbx_USP_SetWorkerState_Result;
 RETURN 0;
END;
GO
