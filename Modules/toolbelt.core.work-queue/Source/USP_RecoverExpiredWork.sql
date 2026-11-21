SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RecoverExpiredWork]
(
      @MaxItems    int     = 100
    , @ResultTable sysname = NULL
    , @KeepData    bit     = 0
    , @Debug       tinyint = 0
    , @Hilfe       bit     = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-recoverexpiredwork"
-- description: "Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_RecoverExpiredWork"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@MaxItems", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/>1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_RecoverExpiredWork.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- ---
--
-- # USP_RecoverExpiredWork
--
-- ## Zweck und Einsatzfälle
--
-- Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.
--
-- ## Voraussetzungen
--
-- Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Expliziter Supervisorbatch; keine Übernahme von Managed-/Holditems. MaxItems 1..1000 begrenzt die Zahl ausgewählter Items. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@MaxItems` | `int` | `100` | Input | Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/>1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt. |
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
-- | `ClaimGeneration` | `bigint` | NOT NULL |
-- | `RecoveryCount` | `bigint` | NOT NULL |
-- | `LastRecoveredAtUtc` | `datetime2(7)` | NOT NULL |
-- | `LastRecoveredBy` | `sysname` | NOT NULL |
--
-- Null bis MaxItems materialisierte Zeilen, Status RETRY_WAIT oder DEAD_LETTER, sortiert nach LastRecoveredAtUtc und WorkItemId. Sieben Recoveryspalten. ResultTable=NULL liefert den direkten Fachresultset; sonst Routing in das lokale Callerziel über PrepareResultTable ohne zusätzlichen Fach-SELECT. Keine Payload, ClaimToken oder privaten Managedtokens in der Ausgabe. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). RETURN0 vor Fachzugriff; normaler Return ebenfalls 0, bei Requeue implizit.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;
--
-- -- Autorisierter Supervisor, ohne Caller-TX:
-- EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf den öffentlichen Einstieg, passender Datenbankzugriff und Identitätsmapping für zentrale Dreiteilnamen. Keine Rechtevergabe aus dem Skill ableiten. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Kein eigener WorkType-ENQUEUE-/CLAIM-/Handler-EXECUTEguard; die Berechtigung für diesen Supervisor-, Completion- oder Heartbeatweg gezielt vergeben. Keine Besitzer- oder Mandantentrennung allein durch diesen Aufruf. ResultTable braucht ein vorhandenes zulässiges lokales #Ziel und Helper-/Temp-DDL-/INSERT-Rechte; keine pauschale Serverrolle.
--
-- ## Ressourcenbedarf
--
-- Private Ergebnistabellen in tempdb, Item-/Scheduler-/Indexlocks, Log-/Speicherbedarf und Sperrkonkurrenz. Recovery mit READPAST kann gesperrte Items überspringen. MaxItems ist keine CPU-, Heap-, Log- oder Gesamtlaufzeitquote. Barrierrequeue erzeugt Blockersnapshots nach Gruppenbreite. Kein eigener Timeout-/Retryloop oder Host-/VM-Eingriff. Zählerüberläufe bleiben Enginefehler.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON und XACT_ABORT OFF; KeepData/Debug/Hilfe werden bei NULL zu 0. Nach früher Hilfe werden Caller-TX und MaxItems geprüft. EngineUTC-Grenzzeitpunkt und ORIGINAL_LOGIN werden vor Beginn der Transaktion erfasst. Während einer Sperrwartezeit neu ablaufende Leases sind daher nicht automatisch in dieser Auswahl enthalten. Eigene Transaktion; optionales ResultTable vor der Auswahl vorbereiten.
--
-- TOP(MaxItems) aus WorkItem mit UPDLOCK, READPAST, READCOMMITTEDLOCK, ROWLOCK und Leaseindex, geordnet nach LeaseUntilUtc und WorkItemId. Nur CLAIMED, LeaseUntilUtc<=Grenzzeitpunkt, ManagedReservationId IS NULL und ManagedHold=0. Kein WorkType-IsEnabled-, Handler-, Besitzer- oder ENQUEUE-/CLAIM-Policyfilter. Gesperrte Kandidaten können übersprungen werden.
--
-- UPDATE setzt bei CycleAttemptCount>=MaxAttempts DEAD_LETTER, sonst RETRY_WAIT. Claim-/Lease-/Heartbeatfelder werden gelöscht; RecoveryCount+1 und LastRecoveredAtUtc/By werden gesetzt. Retrytermin: EngineUTC plus min(Base*2^(Attempt-1),Cap), ohne Jitter; bei Attempt>=31 gilt der Cap. Dead-Letter-Metadaten nur beim Terminalübergang setzen. ClaimGeneration, RetryCycleNumber und CycleAttemptCount bleiben unverändert; kein zusätzlicher Fehlertext. Tatsächlich geänderte IDs aus UPDATE OUTPUT werden in sieben Ergebnisspalten kopiert und gegebenenfalls geroutet. COMMIT, im CATCH eigener ROLLBACK. Direkte Ausgabe nach Commit aus der materialisierten Temp-Tabelle, sortiert nach LastRecoveredAtUtc und WorkItemId. Keine Handlerunterbrechung oder Rücknahme bereits erfolgter fachlicher/externer Arbeit. Die alten ClaimTokens werden aus der Queueownership entfernt; keine Exactly-once-Zusage.
--
-- ## Fehlerbehandlung
--
-- 51960: Caller-TX/XACT_STATE nicht 0. 51961: MaxItems NULL oder außerhalb 1..1000. 51964: ResultTablehelper fehlt. Keine Kandidaten ergibt eine leere Ausgabe, keinen Fehler. Ursprüngliche Engine-, Constraint-, Konvertierungs-, Helper-, Sperr-, Deadlock- und Rollbackfehler bleiben sichtbar. Keine automatische Wiederholung. Spätere Message-/Ergebnistransportfehler können einen eigenen bereits ausgeführten Commit nicht zurücknehmen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Konkurrenz-/Lease-/Recoveryabnahme. Historische Nachweise behalten ihre Artefaktbindung. Kein Exactly-once, Prozess-KILL oder Nachweis für Hostausfall/Koordinatorverlust. Die Claim-/Leasevoraussetzungen gelten für über öffentliche APIs wohlgeformte Items, nicht als Reparaturvertrag für manipulierte interne Tabellen. Keine automatische Secretredaktion; Reason, Fehlertexte und Runtimebefunde privat halten. Keine Installations- oder Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData=ISNULL(@KeepData,0); SET @Debug=ISNULL(@Debug,0); SET @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RecoverExpiredWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'RETRY_WAIT oder DEAD_LETTER nach gespeicherter Policy.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Letzte invalidierte Ownership-Generation.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'RecoveryCount', N'bigint', 0, 0, NULL, CAST(N'Kumulierte Zahl kontrollierter Recoveries.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'LastRecoveredAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'Engine-Zeit der Recovery.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'LastRecoveredBy', N'sysname', 0, 0, NULL, CAST(N'Original-Login der Recovery.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51960-51964', NULL, NULL, NULL, NULL, CAST(N'Caller-Transaktions-, Batch- oder ResultTable-Fehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Recovert höchstens 100 abgelaufene Claims.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@MaxItems', N'int', 0, 0, N'100', CAST(N'Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/>1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_RecoverExpiredWork' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-recoverexpiredwork"
description: "Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_RecoverExpiredWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@MaxItems", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/>1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagno' AS nvarchar(max)) + N'se; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_RecoverExpiredWork.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_RecoverExpiredWork

## Zweck und Einsatzfälle

Plant für abgelaufene Claims nach der gespeicherten Retry-Policy RETRY_WAIT oder DEAD_LETTER. Alte ClaimTokens werden atomar invalidiert.

## Voraussetzungen

Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Expliziter Supervisorbatch; keine Übernahme von Managed-/Holditems. MaxItems 1..1000 begrenzt die Zahl ausgewählter Items. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@MaxItems` | `int` | `100` | Input | Ganzzahl 1..1000 als Batchobergrenze einschließlich, Default 100; NULL/0/negativ/>1000 wird abgewiesen. Es werden nur abgelaufene Claims bis zu dieser Anzahl bearbeitet; keine Callertransaktion erlaubt. |
| `@ResultTable` |' + N' `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL |
| `WorkTypeName` | `varchar(128)` | NOT NULL |
| `Status` | `varchar(16)` | NOT NULL |
| `ClaimGeneration` | `bigint` | NOT NULL |
| `RecoveryCount` | `bigint` | NOT NULL |
| `LastRecoveredAtUtc` | `datetime2(7)` | NOT NULL |
| `LastRecoveredBy` | `sysname` | NOT NULL |

Null bis MaxItems materialisierte Zeilen, Status RETRY_WAIT oder DEAD_LETTER, sortiert nach LastRecoveredAtUtc und WorkItemId. Sieben Recoveryspalten. ResultTable=NULL liefert den direkten Fachresultset; sonst Routing in das lokale Callerziel über PrepareResultTable ohne zusätzlichen Fach-SELECT. Keine Payload, ClaimToken oder privaten Managedtokens in der Ausgabe. Hilfe liefert die bisherige zwölfspaltige St' + N'andardhilfe plus genau eine vollständige Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). RETURN0 vor Fachzugriff; normaler Return ebenfalls 0, bei Requeue implizit.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;

-- Autorisierter Supervisor, ohne Caller-TX:
EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=100;
```

## Rechte

Vorhandenes EXECUTE auf den öffentlichen Einstieg, passender Datenbankzugriff und Identitätsmapping für zentrale Dreiteilnamen. Keine Rechtevergabe aus dem Skill ableiten. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Kein eigener WorkType-ENQUEUE-/CLAIM-/Handler-EXECUTEguard; die Berechtigung für diesen Supervisor-, Completion- oder Heartbeatweg gezielt vergeben. Keine Besitzer- oder Mandantentrennung allein durch diesen Aufruf. ResultTable braucht ein vorhandenes zulässiges lokales #Ziel und Helper-/Temp-DDL-/INSERT-Rechte; keine pauschale Serverrolle.

## Ressourcenbedarf

Private Ergebnistabellen in tempdb, Item-/Scheduler-/Indexlocks, Log-/Speicherbedarf und Sperrkonkurrenz. Recovery mit READPAST kann gesperrte Items überspringen. MaxItems ist keine CPU-, Heap-, Log- oder Gesamtlaufzeitquote. Barrierrequeue erzeugt Blockersnapshots nach Gruppenbreite. Kein eigener Timeout-/Retryloop oder Host-/VM-Eingriff. Zählerüberläufe bleiben Enginefehler.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF; KeepData/Debug/Hilfe werden bei NULL zu 0. Nach früher Hilfe werden Caller-TX und MaxItems geprüft. EngineUTC-Grenzzeitpunkt und ORIGINAL_LOGIN werden vor Beginn der Transaktion erfasst. Während einer Sperrwartezeit neu ablaufende Leases sind daher nicht automatisch in dieser Auswahl enthalten. Eigene Transaktion; optionales ResultTable vor der Auswahl vorbereiten.

TOP(MaxItems) aus WorkItem mit UPDLOCK, READPAST, READCOMMITTEDLOCK, ROWLOCK und Leaseindex, geordnet nach LeaseUntilUtc und WorkItemId. Nur CLAIMED, LeaseUntilUtc<=Gren' + N'zzeitpunkt, ManagedReservationId IS NULL und ManagedHold=0. Kein WorkType-IsEnabled-, Handler-, Besitzer- oder ENQUEUE-/CLAIM-Policyfilter. Gesperrte Kandidaten können übersprungen werden.

UPDATE setzt bei CycleAttemptCount>=MaxAttempts DEAD_LETTER, sonst RETRY_WAIT. Claim-/Lease-/Heartbeatfelder werden gelöscht; RecoveryCount+1 und LastRecoveredAtUtc/By werden gesetzt. Retrytermin: EngineUTC plus min(Base*2^(Attempt-1),Cap), ohne Jitter; bei Attempt>=31 gilt der Cap. Dead-Letter-Metadaten nur beim Terminalübergang setzen. ClaimGeneration, RetryCycleNumber und CycleAttemptCount bleiben unverändert; kein zusätzlicher Fehlertext. Tatsächlich geänderte IDs aus UPDATE OUTPUT werden in sieben Ergebnisspalten kopiert und gegebenenfalls geroutet. COMMIT, im CATCH eigener ROLLBACK. Direkte Ausgabe nach Commit aus der materialisierten Temp-Tabelle, sortiert nach LastRecoveredAtUtc und WorkItemId. Keine Handlerunterbrechung oder Rücknahme bereits erfolgter fachlicher/externer Arbeit. Die alten ClaimTokens werden aus der Queueownership entfernt; keine Exactly-once-Zusage.

## Fehlerbehandlung

51960: Caller-TX/XACT_STATE nicht 0. 51961: MaxItems NULL oder außerhalb 1..1000. 51964: ResultTablehelper fehlt. Keine Kandidaten ergibt eine leere Ausgabe, keinen Fehler. Ursprüngliche Engine-, Constraint-, Konvertierungs-, Helper-, Sperr-, Deadlock- und Rollbackfehler bleiben sichtbar. Keine automatische Wiederholung. Spätere Message-/Ergebnistransportfehler können einen eigenen bereits ausgeführten Commit nicht zurücknehmen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Konkurrenz-/Lease-/Recoveryabnahme. Historische Nachweise behalten ihre Artefaktbindung. Kein Exactly-once, Prozess-KILL oder Nachweis für Hostausfall/Koordinatorverlust. Die Claim-/Leasevoraussetzungen gelten für über öffentliche APIs wohlgeformte Items, nicht als Reparaturvertrag für manipulierte interne Tabellen. Keine automatische' + N' Secretredaktion; Reason, Fehlertexte und Runtimebefunde privat halten. Keine Installations- oder Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51960,N'USP_RecoverExpiredWork darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
    IF @MaxItems IS NULL OR @MaxItems NOT BETWEEN 1 AND 1000 THROW 51961,N'@MaxItems muss zwischen 1 und 1000 liegen.',1;

    CREATE TABLE #tbx_WorkQueue_RecoveryShape(WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,ClaimGeneration bigint NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NOT NULL,LastRecoveredBy sysname NOT NULL);
    CREATE TABLE #tbx_WorkQueue_RecoveryResult(WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,ClaimGeneration bigint NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NOT NULL,LastRecoveredBy sysname NOT NULL);
    DECLARE @Recovered TABLE(WorkItemId bigint NOT NULL PRIMARY KEY);
    DECLARE @NowUtc datetime2(7)=SYSUTCDATETIME(),@RecoveredBy sysname=ORIGINAL_LOGIN();
    BEGIN TRY
        BEGIN TRANSACTION;
        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51964,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_RecoveryShape',@KeepData=@KeepData;
        END;
        ;WITH Expired AS
        (
            SELECT TOP (@MaxItems) * FROM toolbelt_core.WorkItem WITH(UPDLOCK,READPAST,READCOMMITTEDLOCK,ROWLOCK,INDEX(IX_WorkItem_Status_LeaseUntilUtc_WorkItemId))
            WHERE Status='CLAIMED' AND LeaseUntilUtc<=@NowUtc AND ManagedReservationId IS NULL AND ManagedHold=0
            ORDER BY LeaseUntilUtc,WorkItemId
        )
        UPDATE Expired SET
              Status=CASE WHEN CycleAttemptCount>=MaxAttempts THEN 'DEAD_LETTER' ELSE 'RETRY_WAIT' END,ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL
            , LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL
            , RecoveryCount=RecoveryCount+1,LastRecoveredAtUtc=@NowUtc,LastRecoveredBy=@RecoveredBy
            , NextAttemptAtUtc=CASE WHEN CycleAttemptCount>=MaxAttempts THEN NULL ELSE DATEADD(SECOND,CASE WHEN CycleAttemptCount>=31 OR RetryBaseDelaySeconds*POWER(CONVERT(float,2),CycleAttemptCount-1)>RetryMaxDelaySeconds THEN RetryMaxDelaySeconds ELSE CONVERT(int,RetryBaseDelaySeconds*POWER(CONVERT(float,2),CycleAttemptCount-1)) END,@NowUtc) END
            , DeadLetteredAtUtc=CASE WHEN CycleAttemptCount>=MaxAttempts THEN @NowUtc ELSE DeadLetteredAtUtc END
            , DeadLetteredBy=CASE WHEN CycleAttemptCount>=MaxAttempts THEN @RecoveredBy ELSE DeadLetteredBy END
        OUTPUT inserted.WorkItemId INTO @Recovered(WorkItemId);

        INSERT INTO #tbx_WorkQueue_RecoveryResult
        SELECT wi.WorkItemId,wt.WorkTypeName,wi.Status,wi.ClaimGeneration,wi.RecoveryCount,wi.LastRecoveredAtUtc,wi.LastRecoveredBy
        FROM @Recovered r JOIN toolbelt_core.WorkItem wi ON wi.WorkItemId=r.WorkItemId
        JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId;
        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,WorkTypeName,Status,ClaimGeneration,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy) SELECT WorkItemId,WorkTypeName,Status,ClaimGeneration,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy FROM #tbx_WorkQueue_RecoveryResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
    IF @Debug>0 RAISERROR(N'USP_RecoverExpiredWork: abgelaufene Claims kontrolliert zurückgesetzt.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_RecoveryResult ORDER BY LastRecoveredAtUtc,WorkItemId;
    RETURN 0;
END;
GO
