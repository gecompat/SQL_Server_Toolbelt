-- ============================================================================
-- Objekt: toolbelt_core.USP_RegisterWorker
-- Zweck: Registriert eine neue principal- und generationgebundene Workeridentität; übernimmt keine alten Reservations.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene Rechte, keine Grants.
-- Sichtbarkeit: public
-- Transaktion: eigene kurze Steuertransaktion
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_RegisterWorker
 @WorkerId uniqueidentifier=NULL,
 @Capacity int=NULL,
 @RunMode varchar(16)='BOUNDED',
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-registerworker"
-- description: "Erzeugt eine neue principalgebundene Generation einer stabilen WorkerId ohne Übernahme alter Reservations."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_RegisterWorker"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderlich, NULL ist ungültig trotz technischem Default NULL. Eine neue stabile ID erzeugt der Caller vor dem Aufruf, etwa mit NEWID(). Wiederverwendung ist nur für denselben Principal erlaubt und erzeugt eine neue Generation; alte aktive Generationen werden DRAINING."}, {"name": "@Capacity", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Slotobergrenze. Technischer Default NULL ist kein konfigurierter Capacity-Default, sondern im Fachaufruf ungültig. Keine Garantie physischer Parallelleistung; globale Concurrency begrenzt zusätzlich."}, {"name": "@RunMode", "sql_type": "varchar(16)", "sql_default": "'BOUNDED'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ und binär/case-sensitiv, ohne Normalisierung oder abschließende Spaces: BOUNDED = deklarierter begrenzter Laufmodus (Default); CONTINUOUS = ausdrücklich gewählter Dauerlaufmodus. NULL/leer/andere Werte ungültig. Registrierung startet selbst keinen Workerprozess."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_RegisterWorker.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_RegisterWorker
--
-- ## Zweck und Einsatzfälle
--
-- Erzeugt eine neue principalgebundene Generation einer stabilen WorkerId ohne Übernahme alter Reservations.
--
-- ## Voraussetzungen
--
-- Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@WorkerId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderlich, NULL ist ungültig trotz technischem Default NULL. Eine neue stabile ID erzeugt der Caller vor dem Aufruf, etwa mit NEWID(). Wiederverwendung ist nur für denselben Principal erlaubt und erzeugt eine neue Generation; alte aktive Generationen werden DRAINING. |
-- | `@Capacity` | `int` | `NULL` | Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Slotobergrenze. Technischer Default NULL ist kein konfigurierter Capacity-Default, sondern im Fachaufruf ungültig. Keine Garantie physischer Parallelleistung; globale Concurrency begrenzt zusätzlich. |
-- | `@RunMode` | `varchar(16)` | `'BOUNDED'` | Taxativ und binär/case-sensitiv, ohne Normalisierung oder abschließende Spaces: BOUNDED = deklarierter begrenzter Laufmodus (Default); CONTINUOUS = ausdrücklich gewählter Dauerlaufmodus. NULL/leer/andere Werte ungültig. Registrierung startet selbst keinen Workerprozess. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
--
-- SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen fachlichen Ersatzidentitäten. Quelle und Effekte unterscheiden admin- und tokengebundene Pfade ausdrücklich.
--
-- ## Ergebnisse
--
-- WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,WorkerToken uniqueidentifier NOT NULL,ConfigVersion binary(8) NOT NULL Bei normalem Erfolg RETURN0; keine OUTPUT-Parameter. NULLResultTable:direkte eine Zeile nach Commit. Sonst Formvorbereitung und INSERT in die vom Caller bereits angelegte lokale #Temp innerhalb derselben Mutationstransaktion; kein weiterer direkter Fachresultset. KeepData unverändert zum kanonischen Helper. Hilfe: bisheriger zwölfspaltiger Standardhelp-Resultset plus genau eine zusätzliche Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max); RETURN0 vor Fachprüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;
--
-- DECLARE @Id uniqueidentifier=NEWID();
-- EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@Id,@Capacity=1,@RunMode='BOUNDED';
-- -- Registrierungsresultat einschließlich geheimem WorkerToken sicher übernehmen.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf genau diese öffentliche Prozedur. Register/Heartbeat verwenden USER_ID der aktuellen Datenbank als Ownerbindung; keine automatische Impersonation oder neuen Principalrechte. Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Keine Rechtevergabe, Serverrolle, Hostauthentifizierung oder pauschalen direkten Tabellenrechte. Für ResultTable-/Statuslese-/CrossDB-Zugriffe jeweils bestehende passende Rechte und Identitätsmapping; ein Dreiteilname überträgt keine Autorität.
--
-- ## Ressourcenbedarf
--
-- Kurze eigene Transaktion, globale Gate-/Scheduler-/Konfigurationssperren und Workerregistrationszugriffe; Register liest neueste Generation und aktualisiert gegebenenfalls mehrere Vorgänger, SetState mehrere AdmissionPaused-Zeilen. Keine implementierte CPU-/Zeit-/Log-/Heap-/Ausgabebytequote oder eigener Locktimeout. Blockierung/Deadlock/Log-/tempdbdruck bleibt möglich. Technische Token-/Principalwerte niemals in öffentliche Testnachweise übernehmen.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und SET XACT_ABORT OFF im Prozedurcode vor dem positiven Hilfezweig; dort keine fachlichen Prüfungen, temporären Ergebnisobjekte oder Mutationen und keine eigenen Debugmessages. Private feste #tbx_-Ergebnistemp vor Callertransaktionsguard. Fachpfad verlangt @@TRANCOUNT0/XACT_STATE0, danach eigene BEGIN TRANSACTION und TRY. Reihenfolge UPDLOCK/HOLDLOCK Gate→Scheduler→Konfigurationszeile. Neue WorkerId:Generation1. Bestehende ID: nur gleicher aktueller USER_ID wie der gespeicherte Owner der letzten Generation, dann letzteGeneration+1 und neues NEWID()-WorkerToken. Frühere ACTIVE/PAUSED-Generationen werden DRAINING, andere Zustände bleiben. AdmissionPaused der neuesten Vorgängergeneration wird übernommen; wenn1 startet die neue Generation PAUSED, sonst ACTIVE. ProviderKind EXTERNAL,OwnerPrincipalId USER_ID(),LastHeartbeat aktuelle Engine-UTC; Intervalle werden aus globaler Konfiguration kopiert. Kein Test ManagedEnabled=1 in diesem Registrierungsaufruf; der Aufruf startet keinen Prozess und ermöglicht allein noch keinen Claim. Keine alte Reservation/Claim-/Executionidentität wird übernommen. Die globale ConfigVersion wird gelesen/ausgegeben, hier nicht erhöht. Direkte Ergebnisausgabe erfolgt erst nach Commit. Ein späterer Client-/Transportfehler kann einen bereits erfolgreichen Commit nicht rückgängig machen. ResultTable-Helper und INSERT liegen vor Commit; bei Fehlern rollt die eigene aktive Transaktion zurück. Keine Savepointunterstützung für Callertransaktionen und kein eigener Retry. @Debug erzeugt keine eigenen Messages; nicht an den ResultTable-Helper weitergereicht.
--
-- ## Fehlerbehandlung
--
-- 54210/1 Callertransaktion bzw.nichtneutraler XACT_STATE.54211/1 fehlender Gate-/Scheduler-/Konfigurationsvertrag; fehlende Tabellen/kompilierte Abhängigkeiten können bereits als ursprüngliche Enginefehler auftreten. 54213/3 WorkerIdNULL/CapacityNULL-oder<1/RunModeNULL-oder-nichtBOUNDED/CONTINUOUS-oder-nachgestellteSpaces.54214/1 abweichender OwnerPrincipalId der neuesten vorhandenen Generation;54214/2 bigint-Generation am Maximum9223372036854775807. Ursprüngliche Sperr-, Constraint-, Arithmetic-, Helper-, INSERT- und Enginefehler bleiben sichtbar. CATCH rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine fachliche Fehlerstatuszeile.
--
-- ## Aussagegrenzen
--
-- WorkerToken im Ergebnis ist vertraulich und nur für diese ID/Generation/Principalbindung bestimmt. Nicht protokollieren, veröffentlichen oder aus einer Statusview rekonstruieren. Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Bindung. Keine Exactly-once-/Hostverlust-/Kill- oder vollständige Betriebsqualifikation allein aus Status/Token/Registrierung. Zusätzliche Skillhilfe wird nicht durch alte Standardhilfe-Nachweise qualifiziert.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RegisterWorker' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Registriert eine neue principal- und generationgebundene Workeridentität; übernimmt keine alten Reservations.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkerId', N'uniqueidentifier', 0, 0, NULL, CAST(N'WorkerId gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkerGeneration', N'bigint', 0, 0, NULL, CAST(N'WorkerGeneration gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'WorkerToken', N'uniqueidentifier', 0, 0, NULL, CAST(N'WorkerToken gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ConfigVersion', N'binary(8)', 0, 0, NULL, CAST(N'ConfigVersion gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ausschließlich synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkerId', N'uniqueidentifier', 1, 0, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderlich, NULL ist ungültig trotz technischem Default NULL. Eine neue stabile ID erzeugt der Caller vor dem Aufruf, etwa mit NEWID(). Wiederverwendung ist nur für denselben Principal erlaubt und erzeugt eine neue Generation; alte aktive Generationen werden DRAINING.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Capacity', N'int', 1, 0, N'NULL', CAST(N'Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Slotobergrenze. Technischer Default NULL ist kein konfigurierter Capacity-Default, sondern im Fachaufruf ungültig. Keine Garantie physischer Parallelleistung; globale Concurrency begrenzt zusätzlich.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@RunMode', N'varchar(16)', 0, 0, N'''BOUNDED''', CAST(N'Taxativ und binär/case-sensitiv, ohne Normalisierung oder abschließende Spaces: BOUNDED = deklarierter begrenzter Laufmodus (Default); CONTINUOUS = ausdrücklich gewählter Dauerlaufmodus. NULL/leer/andere Werte ungültig. Registrierung startet selbst keinen Workerprozess.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_RegisterWorker' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-registerworker"
description: "Erzeugt eine neue principalgebundene Generation einer stabilen WorkerId ohne Übernahme alter Reservations."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_RegisterWorker"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderlich, NULL ist ungültig trotz technischem Default NULL. Eine neue stabile ID erzeugt der Caller vor dem Aufruf, etwa mit NEWID(). Wiederverwendung ist nur für denselben Principal erlaubt und erzeugt eine neue Generation; alte aktive Generationen werden DRAINING."}, {"name": "@Capacity", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Slotobergrenze. Technischer Default NULL ist kein konfigurierter Capacity-Default, sondern im Fachaufruf ungültig. Keine Garantie physischer Parallelleistung; globale Concurrency begrenzt zusätzlich."}, {"name": "@RunMode", "sql_type": "varchar(16)", "sql_default": "''BOUNDED''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ und binär/case-sensitiv, ohne Normalisierung oder abschließende Spaces: BOUNDED = deklarierter begrenzter Laufmodus (Default); CONTINUOUS = ausdrücklich gewählter Dauerlaufmodus. NULL/leer/andere Werte ungültig. Registrierung startet selbst keinen Workerprozess."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business' AS nvarchar(max)) + N'_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_RegisterWorker.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Module' + N's/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_RegisterWorker

## Zweck und Einsatzfälle

Erzeugt eine neue principalgebundene Generation einer stabilen WorkerId ohne Übernahme alter Reservations.

## Voraussetzungen

Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderlich, NULL ist ungültig trotz technischem Default NULL. Eine neue stabile ID erzeugt der Caller vor dem Aufruf, etwa mit NEWID(). Wiederverwendung ist nur für denselben Principal erlaubt und erzeugt eine neue Generation; alte aktive Generationen werden DRAINING. |
| `@Capacity` | `int` | `NULL` | Fachlich erforderliche Ganzzahl 1..2147483647 als lokale Slotobergrenze. Technischer Default NULL ist kein konfigurierter Capacity-Default, sondern im Fachaufruf ungültig. Keine Garantie physischer Parallelleistung; globale Concurrency begrenzt zusätzlich. |
| `@RunMode` | `varchar(16)` | `''BOUNDED''` | Taxativ und binär/case-sensitiv, ohne Normalisierung oder abschließende Spaces: BOUNDED = deklarierter begrenzter Laufmodus (Default); CONTINUOUS = ausdrücklich gewählter Dauerlaufmodus. NULL/leer/andere Werte ungültig. Registrierung startet selbst keinen Workerprozess. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner ' + N'sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen fachlichen Ersatzidentitäten. Quelle und Effekte unterscheiden admin- und tokengebundene Pfade ausdrücklich.

## Ergebnisse

WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,WorkerToken uniqueidentifier NOT NULL,ConfigVersion binary(8) NOT NULL Bei normalem Erfolg RETURN0; keine OUTPUT-Parameter. NULLResultTable:direkte eine Zeile nach Commit. Sonst Formvorbereitung und INSERT in die vom Caller bereits angelegte lokale #Temp innerhalb derselben Mutationstransaktion; kein weiterer direkter Fachresultset. KeepData unverändert zum kanonischen Helper. Hilfe: bisheriger zwölfspaltiger Standardhelp-Resultset plus genau eine zusätzliche Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,Skill' + N'Markdown nvarchar(max); RETURN0 vor Fachprüfung.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_RegisterWorker @Hilfe=1;

DECLARE @Id uniqueidentifier=NEWID();
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@Id,@Capacity=1,@RunMode=''BOUNDED'';
-- Registrierungsresultat einschließlich geheimem WorkerToken sicher übernehmen.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur. Register/Heartbeat verwenden USER_ID der aktuellen Datenbank als Ownerbindung; keine automatische Impersonation oder neuen Principalrechte. Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Keine Rechtevergabe, Serverrolle, Hostauthentifizierung oder pauschalen direkten Tabellenrechte. Für ResultTable-/Statuslese-/CrossDB-Zugriffe jeweils bestehende passende Rechte und Identitätsmapping; ein Dreiteilname überträgt keine Autorität.

## Ressourcenbedarf

Kurze eigene Transaktion, globale Gate-/Scheduler-/Konfigurationssperren und Workerregistrationszugriffe; Register liest neueste Generation und aktualisiert gegebenenfalls mehrere Vorgänger, SetState mehrere AdmissionPaused-Zeilen. Keine implementierte CPU-/Zeit-/Log-/Heap-/Ausgabebytequote oder eigener Locktimeout. Blockierung/Deadlock/Log-/tempdbdruck bleibt möglich. Technische Token-/Principalwerte niemals in öffentliche Testnachweise übernehmen.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Prozedurcode vor dem positiven Hilfezweig; dort keine fachlichen Prüfungen, temporären Ergebnisobjekte oder Mutationen und keine eigenen Debugmessages. Private feste #tbx_-Ergebnistemp vor Callertransaktionsguard. Fachpfad verlangt @@TRANCOUNT0/XACT_STATE0, danach eigene BEGIN TRANSACTION und TRY. Reihenfolge UPDLOCK/HOLDLOCK Gate→Scheduler→Konfigurationszeile. Neue WorkerId:Generation1. Bestehende ID: nur gleicher aktueller USER_ID wie der gespeicherte Owner der letzten Generation, dann letzteGeneration+1 und neues NEWID()-WorkerToken. Frühere ACTIVE/PAUSED-Generationen werden DRAINING, andere Zu' + N'stände bleiben. AdmissionPaused der neuesten Vorgängergeneration wird übernommen; wenn1 startet die neue Generation PAUSED, sonst ACTIVE. ProviderKind EXTERNAL,OwnerPrincipalId USER_ID(),LastHeartbeat aktuelle Engine-UTC; Intervalle werden aus globaler Konfiguration kopiert. Kein Test ManagedEnabled=1 in diesem Registrierungsaufruf; der Aufruf startet keinen Prozess und ermöglicht allein noch keinen Claim. Keine alte Reservation/Claim-/Executionidentität wird übernommen. Die globale ConfigVersion wird gelesen/ausgegeben, hier nicht erhöht. Direkte Ergebnisausgabe erfolgt erst nach Commit. Ein späterer Client-/Transportfehler kann einen bereits erfolgreichen Commit nicht rückgängig machen. ResultTable-Helper und INSERT liegen vor Commit; bei Fehlern rollt die eigene aktive Transaktion zurück. Keine Savepointunterstützung für Callertransaktionen und kein eigener Retry. @Debug erzeugt keine eigenen Messages; nicht an den ResultTable-Helper weitergereicht.

## Fehlerbehandlung

54210/1 Callertransaktion bzw.nichtneutraler XACT_STATE.54211/1 fehlender Gate-/Scheduler-/Konfigurationsvertrag; fehlende Tabellen/kompilierte Abhängigkeiten können bereits als ursprüngliche Enginefehler auftreten. 54213/3 WorkerIdNULL/CapacityNULL-oder<1/RunModeNULL-oder-nichtBOUNDED/CONTINUOUS-oder-nachgestellteSpaces.54214/1 abweichender OwnerPrincipalId der neuesten vorhandenen Generation;54214/2 bigint-Generation am Maximum9223372036854775807. Ursprüngliche Sperr-, Constraint-, Arithmetic-, Helper-, INSERT- und Enginefehler bleiben sichtbar. CATCH rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine fachliche Fehlerstatuszeile.

## Aussagegrenzen

WorkerToken im Ergebnis ist vertraulich und nur für diese ID/Generation/Principalbindung bestimmt. Nicht protokollieren, veröffentlichen oder aus einer Statusview rekonstruieren. Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/R' + N'ecoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Bindung. Keine Exactly-once-/Hostverlust-/Kill- oder vollständige Betriebsqualifikation allein aus Status/Token/Registrierung. Zusätzliche Skillhilfe wird nicht durch alte Standardhilfe-Nachweise qualifiziert.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 CREATE TABLE #tbx_USP_RegisterWorker_Result(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL,WorkerToken uniqueidentifier NOT NULL,ConfigVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @WorkerId IS NULL OR @Capacity IS NULL OR @Capacity<1 OR @RunMode IS NULL OR @RunMode COLLATE Latin1_General_100_BIN2 NOT IN('BOUNDED','CONTINUOUS') OR DATALENGTH(@RunMode)<>LEN(@RunMode) THROW 54213,N'Die Workerregistrierung ist ungültig.',3;
 DECLARE @Generation bigint,@Token uniqueidentifier=NEWID(),@PreviousState varchar(16),@AdmissionPaused bit,@Owner int;
 SELECT TOP(1) @Generation=WorkerGeneration,@PreviousState=State,@AdmissionPaused=AdmissionPaused,@Owner=OwnerPrincipalId FROM toolbelt_core.WorkerRegistration WITH(UPDLOCK,HOLDLOCK) WHERE WorkerId=@WorkerId ORDER BY WorkerGeneration DESC;
 IF @Owner IS NOT NULL AND @Owner<>USER_ID() THROW 54214,N'Die stabile Workeridentität gehört einem anderen Principal.',1;
 IF @Generation=9223372036854775807 THROW 54214,N'Die Workergeneration ist erschöpft.',2;
 UPDATE toolbelt_core.WorkerRegistration SET State='DRAINING' WHERE WorkerId=@WorkerId AND State IN('ACTIVE','PAUSED');
 SET @Generation=ISNULL(@Generation,0)+1;
 INSERT toolbelt_core.WorkerRegistration SELECT @WorkerId,@Generation,@Token,USER_ID(),'EXTERNAL',CASE WHEN @AdmissionPaused=1 THEN 'PAUSED' ELSE 'ACTIVE' END,ISNULL(@AdmissionPaused,0),@Capacity,@RunMode,SYSUTCDATETIME(),HeartbeatSeconds,UnreachableSeconds FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;
 INSERT #tbx_USP_RegisterWorker_Result VALUES(@WorkerId,@Generation,@Token,@Config);
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_RegisterWorker_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkerId,WorkerGeneration,WorkerToken,ConfigVersion) SELECT WorkerId,WorkerGeneration,WorkerToken,ConfigVersion FROM #tbx_USP_RegisterWorker_Result';
 EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkerId,WorkerGeneration,WorkerToken,ConfigVersion FROM #tbx_USP_RegisterWorker_Result;
 RETURN 0;
END;
GO
