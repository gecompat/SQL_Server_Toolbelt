-- ============================================================================
-- Objekt: toolbelt_core.USP_SetWorkerConcurrency
-- Zweck: Ändert das globale Live-Admissionbudget versionsgebunden ohne laufende Arbeit abzubrechen.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene Rechte, keine Grants.
-- Sichtbarkeit: public
-- Transaktion: eigene kurze Steuertransaktion
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_SetWorkerConcurrency
 @MaxConcurrentExecutions int=NULL,
 @ExpectedConfigVersion binary(8)=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-setworkerconcurrency"
-- description: "Ändert das globale Live-Admissionbudget ohne laufende Arbeit abzubrechen."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_SetWorkerConcurrency"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@MaxConcurrentExecutions", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal."}, {"name": "@ExpectedConfigVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_SetWorkerConcurrency.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_SetWorkerConcurrency
--
-- ## Zweck und Einsatzfälle
--
-- Ändert das globale Live-Admissionbudget ohne laufende Arbeit abzubrechen.
--
-- ## Voraussetzungen
--
-- Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale ConfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@MaxConcurrentExecutions` | `int` | `NULL` | Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal. |
-- | `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
--
-- NULL-Defaults erforderlicher Fachwerte dienen nur dem Hilfeaufruf. Eingabekonvertierung auf die SQL-Parametertypen geschieht vor dem Prozedurcode; zu lange Namen/Bytes nicht als eigene Validierung behandeln.
--
-- ## Ergebnisse
--
-- Bei direkter Ausgabe genau eine Zeile mit ConfigVersion binary(8) NOT NULL, MaxConcurrentExecutions int NOT NULL, OccupiedSlots bigint NOT NULL. Kein OUTPUT-Parameter; RETURN0. Bei nicht-NULL ResultTable wird die Zeile innerhalb derselben Mutationstransaktion über USP_PrepareResultTable und explizites dynamisches INSERT geroutet, ohne zusätzlichen direkten Fachresultset. KeepData wird unverändert an den Helper übergeben. Keine Tokens oder Payloads im Ergebnis. Neue ConfigVersion ist nach jedem erfolgreichen UPDATE neu, auch bei identischen Werten. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine Zeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max).
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;
--
-- -- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- -- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
-- DECLARE @Expected binary(8)=0x0000000000000001;
-- EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=2,@ExpectedConfigVersion=@Expected;
-- -- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf genau diese öffentliche Steuerprozedur; fachliche Mutation ist getrennt von bloßem SELECT auf Statusviews berechtigt. Zugriff auf interne Tabellen folgt den tatsächlichen Ownership-Chains/Objektrechten; keine automatische Rechtevergabe, Identitätsumschaltung, Serverrolle oder serverweite Sichtbarkeit. Für die vorherige Versionsabfrage sind Rechte auf die gewählte lesende Oberfläche separat nötig. ResultTable-Routing verlangt die tatsächlichen Caller-/Helper-/Temp-Rechte, kein pauschales direktes Tabellen-SELECT als neue Vorgabe.
--
-- ## Ressourcenbedarf
--
-- Eigene kurze Transaktion mit UPDLOCK/HOLDLOCK auf Gate, Scheduler und globaler Konfigurationszeile; Sperren bleiben bis Commit/Rollback. Keine implementierte CPU-/Zeit-/Ausgabebytequote oder eigener Locktimeout. Eine globale COUNT_BIG-Abfrage über belegte Reservations liefert die Budgetbelegung. Optionale Helper-DDL/INSERT erhöht Transaktionsumfang. Deadlocks, Sperr-/Log-/tempdb-/Speicherdruck bleiben möglich.
--
-- ## Nebenwirkungen
--
-- Im Prozedurcode SET NOCOUNT ON und SET XACT_ABORT OFF bereits vor dem positiven Hilfezweig. Die Hilfe kehrt vor CREATE TABLE, Datenabfragen oder fachlichen Mutationen zurück; keine fachlichen Callerwertevalidierung oder eigenen Debugmessages. Fachpfad legt eine private feste #tbx_-Ergebnistemp an, prüft anschließend Callertransaktion, startet eigene Transaktion und sperrt Gate→Scheduler→Konfiguration. Keine Savepoints/Commit/Rollback einer erlaubten Callertransaktion, da Callertransaktionen abgewiesen werden. Aktualisiert nur MaxConcurrentExecutions. 0 oder ein Budget unter bereits belegten Slots beendet keine laufende Arbeit und gibt keine unbekannten Reservations frei. OccupiedSlots zählt global ausschließlich IsOccupied1 unabhängig von State. Wiederholter gleicher Budgetwert verändert dennoch ConfigVersion. Ein Selbstupdate der globalen Konfiguration erzeugt die neue Version auch beim Moduswechsel. ResultTable-Form/Zeilen werden vor Commit in derselben Transaktion vorbereitet/eingefügt; bei Helper-/INSERTfehlern wird die eigene Mutation zurückgerollt. Direkte Ergebnisausgabe erfolgt erst nach Commit; ein späterer Transport-/Clientfehler kann bereits begangene Mutation nicht zurücknehmen. @Debug erzeugt keine eigenen zusätzlichen Messages und wird hier nicht an den Helper weitergereicht.
--
-- ## Fehlerbehandlung
--
-- 54210/State1 bei Callertransaktion oder nichtneutralem XACT_STATE, vor eigener BEGIN TRANSACTION. Innerhalb TRY:54211/1 fehlendes Gate/Scheduler-/Konfigurationsobjekt bzw. fehlende Pflichtzeile,54212/1 NULL/veraltete ExpectedConfigVersion; tatsächliche fehlende Tabellen können bereits als technische Kompilierungs-/Enginefehler auftreten, keine universelle54211-Abbildung. 54213/1 bei NULL/negativem MaxConcurrentExecutions; int-Maximum2147483647 ist zulässig. Helper-/Tempnamespace-/DDL-/INSERT-/Sperr-/Deadlockfehler bleiben Engine-/Helperfehler. Catch rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler sind nicht separat geschützt. Kein eingebauter Retry. Return0 nur nach Erfolg oder Hilfe; keine fachlichen Fehlerstatuszeilen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Fach-/Hilfevertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installerabnahme. Historische unveränderte Fachbelege qualifizieren nur ihre ursprünglichen Artefakte, nicht die zusätzliche Skillausgabe. Kein automatisches Enable CLR/Trust/Serverneustart, kein Workerstart oder Abbruch laufender Handler. ConfigVersion ist ein SQL-Concurrencytoken, keine globale Betriebsgesundheit oder Ausführungsautorität. Hilfeprojektion und alte Bootstrap-Parameterreferenzen müssen bei der abschließenden Einquellenmigration konsistent abgeglichen werden.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_SetWorkerConcurrency' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ändert das globale Live-Admissionbudget versionsgebunden ohne laufende Arbeit abzubrechen.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'ConfigVersion', N'binary(8)', 0, 0, NULL, CAST(N'ConfigVersion gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'MaxConcurrentExecutions', N'int', 0, 0, NULL, CAST(N'MaxConcurrentExecutions gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'OccupiedSlots', N'bigint', 0, 0, NULL, CAST(N'OccupiedSlots gemäß stabilem Ergebnisvertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ausschließlich synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@MaxConcurrentExecutions', N'int', 1, 1, N'NULL', CAST(N'Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ExpectedConfigVersion', N'binary(8)', 1, 1, N'NULL', CAST(N'Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung.' AS nvarchar(max)), NULL),
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
 CONVERT(sysname,CAST(N'USP_SetWorkerConcurrency' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-setworkerconcurrency"
description: "Ändert das globale Live-Admissionbudget ohne laufende Arbeit abzubrechen."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_SetWorkerConcurrency"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@MaxConcurrentExecutions", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal."}, {"name": "@ExpectedConfigVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_re' AS nvarchar(max)) + N'quired": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_SetWorkerConcurrency.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_SetWorkerConcurrency

## Zweck und Einsatzfälle

Ändert das globale Live-Admissionbudget ohne laufende Arbeit abzubrechen.

## Voraussetzungen

Worker-Control1.0.0 mit passender Queue2.1.0, WorkerControlConfiguration, WorkQueueManagedGate und WorkQueueScheduler in derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0. Frische exakte globale Co' + N'nfigVersion aus autorisierter Ausgabe übernehmen, kein erfundener Default. Optionales ResultTable-Routing benötigt den installierten Helper und eine geeignete vom Caller angelegte lokale Temp. Hilfe benötigt keine gültigen Fachwerte oder Tabellenabfragen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@MaxConcurrentExecutions` | `int` | `NULL` | Fachlich erforderliche Ganzzahl 0..2147483647 als globales Live-Slotbudget. 0 pausiert neue Admission; laufende Arbeit wird dadurch nicht abgebrochen. Technischer Default NULL ist ungültig und kein Wert-beibehalten-Signal. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe p' + N'lus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

NULL-Defaults erforderlicher Fachwerte dienen nur dem Hilfeaufruf. Eingabekonvertierung auf die SQL-Parametertypen geschieht vor dem Prozedurcode; zu lange Namen/Bytes nicht als eigene Validierung behandeln.

## Ergebnisse

Bei direkter Ausgabe genau eine Zeile mit ConfigVersion binary(8) NOT NULL, MaxConcurrentExecutions int NOT NULL, OccupiedSlots bigint NOT NULL. Kein OUTPUT-Parameter; RETURN0. Bei nicht-NULL ResultTable wird die Zeile innerhalb derselben Mutationstransaktion über USP_PrepareResultTable und explizites dynamisches INSERT geroutet, ohne zusätzlichen direkten Fachresultset. KeepData wird unverändert an den Helper übergeben. Keine Tokens oder Payloads im Ergebnis. Neue ConfigVersion ist nach jedem erfolgreichen UPDATE neu, auch bei identischen Werten. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine Zeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_SetWorkerConcurrency @Hilfe=1;

-- Synthetischer Versionswert: durch frische Ausgabe eines autorisierten
-- Konfigurations-/Registrierungsaufrufs ersetzen; kein Rowversion-Zahlentext.
DECLARE @Expected binary(8)=0x0000000000000001;
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=2,@ExpectedConfigVersion=@Expected;
-- Ein veralteter Beispielwert wird ausdrücklich mit54212 abgewiesen.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Steuerprozedur; fachliche Mutation ist getrennt von bloßem SELECT auf Statusviews berechtigt. Zugriff auf interne Tabellen folgt den tatsächlichen Ownership-Chains/Objektrechten; keine automatische Rechtevergabe, Identitätsumschaltung, Serverrolle' + N' oder serverweite Sichtbarkeit. Für die vorherige Versionsabfrage sind Rechte auf die gewählte lesende Oberfläche separat nötig. ResultTable-Routing verlangt die tatsächlichen Caller-/Helper-/Temp-Rechte, kein pauschales direktes Tabellen-SELECT als neue Vorgabe.

## Ressourcenbedarf

Eigene kurze Transaktion mit UPDLOCK/HOLDLOCK auf Gate, Scheduler und globaler Konfigurationszeile; Sperren bleiben bis Commit/Rollback. Keine implementierte CPU-/Zeit-/Ausgabebytequote oder eigener Locktimeout. Eine globale COUNT_BIG-Abfrage über belegte Reservations liefert die Budgetbelegung. Optionale Helper-DDL/INSERT erhöht Transaktionsumfang. Deadlocks, Sperr-/Log-/tempdb-/Speicherdruck bleiben möglich.

## Nebenwirkungen

Im Prozedurcode SET NOCOUNT ON und SET XACT_ABORT OFF bereits vor dem positiven Hilfezweig. Die Hilfe kehrt vor CREATE TABLE, Datenabfragen oder fachlichen Mutationen zurück; keine fachlichen Callerwertevalidierung oder eigenen Debugmessages. Fachpfad legt eine private feste #tbx_-Ergebnistemp an, prüft anschließend Callertransaktion, startet eigene Transaktion und sperrt Gate→Scheduler→Konfiguration. Keine Savepoints/Commit/Rollback einer erlaubten Callertransaktion, da Callertransaktionen abgewiesen werden. Aktualisiert nur MaxConcurrentExecutions. 0 oder ein Budget unter bereits belegten Slots beendet keine laufende Arbeit und gibt keine unbekannten Reservations frei. OccupiedSlots zählt global ausschließlich IsOccupied1 unabhängig von State. Wiederholter gleicher Budgetwert verändert dennoch ConfigVersion. Ein Selbstupdate der globalen Konfiguration erzeugt die neue Version auch beim Moduswechsel. ResultTable-Form/Zeilen werden vor Commit in derselben Transaktion vorbereitet/eingefügt; bei Helper-/INSERTfehlern wird die eigene Mutation zurückgerollt. Direkte Ergebnisausgabe erfolgt erst nach Commit; ein späterer Transport-/Clientfehler kann bereits begangene Mutation nicht zurücknehmen. @Debug erzeugt keine eigenen zusätzlichen Messages und wird hier nicht' + N' an den Helper weitergereicht.

## Fehlerbehandlung

54210/State1 bei Callertransaktion oder nichtneutralem XACT_STATE, vor eigener BEGIN TRANSACTION. Innerhalb TRY:54211/1 fehlendes Gate/Scheduler-/Konfigurationsobjekt bzw. fehlende Pflichtzeile,54212/1 NULL/veraltete ExpectedConfigVersion; tatsächliche fehlende Tabellen können bereits als technische Kompilierungs-/Enginefehler auftreten, keine universelle54211-Abbildung. 54213/1 bei NULL/negativem MaxConcurrentExecutions; int-Maximum2147483647 ist zulässig. Helper-/Tempnamespace-/DDL-/INSERT-/Sperr-/Deadlockfehler bleiben Engine-/Helperfehler. Catch rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler sind nicht separat geschützt. Kein eingebauter Retry. Return0 nur nach Erfolg oder Hilfe; keine fachlichen Fehlerstatuszeilen.

## Aussagegrenzen

Quellgeprüfter aktueller Fach-/Hilfevertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installerabnahme. Historische unveränderte Fachbelege qualifizieren nur ihre ursprünglichen Artefakte, nicht die zusätzliche Skillausgabe. Kein automatisches Enable CLR/Trust/Serverneustart, kein Workerstart oder Abbruch laufender Handler. ConfigVersion ist ein SQL-Concurrencytoken, keine globale Betriebsgesundheit oder Ausführungsautorität. Hilfeprojektion und alte Bootstrap-Parameterreferenzen müssen bei der abschließenden Einquellenmigration konsistent abgeglichen werden.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 CREATE TABLE #tbx_USP_SetWorkerConcurrency_Result(ConfigVersion binary(8) NOT NULL,MaxConcurrentExecutions int NOT NULL,OccupiedSlots bigint NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @ExpectedConfigVersion IS NULL OR @ExpectedConfigVersion<>@Config THROW 54212,N'Die erwartete Konfigurationsversion ist veraltet oder fehlt.',1;
 IF @MaxConcurrentExecutions IS NULL OR @MaxConcurrentExecutions<0 THROW 54213,N'Das globale Budget muss nichtnegativ sein.',1;
 UPDATE toolbelt_core.WorkerControlConfiguration SET MaxConcurrentExecutions=@MaxConcurrentExecutions WHERE ConfigurationId=1;
 INSERT #tbx_USP_SetWorkerConcurrency_Result SELECT ConfigVersion,MaxConcurrentExecutions,(SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1) FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_SetWorkerConcurrency_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(ConfigVersion,MaxConcurrentExecutions,OccupiedSlots) SELECT ConfigVersion,MaxConcurrentExecutions,OccupiedSlots FROM #tbx_USP_SetWorkerConcurrency_Result';
 EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT ConfigVersion,MaxConcurrentExecutions,OccupiedSlots FROM #tbx_USP_SetWorkerConcurrency_Result;
 RETURN 0;
END;
GO
