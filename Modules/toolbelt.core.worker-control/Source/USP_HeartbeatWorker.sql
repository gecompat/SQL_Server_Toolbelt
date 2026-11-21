-- ============================================================================
-- Objekt: toolbelt_core.USP_HeartbeatWorker
-- Zweck: Erneuert ausschließlich die aktuelle lebende Workergeneration ohne Claims zu übernehmen.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene Rechte, keine Grants.
-- Sichtbarkeit: public
-- Transaktion: eigene kurze Steuertransaktion
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_HeartbeatWorker
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-heartbeatworker"
-- description: "Erneuert die Heartbeatzeit einer token-/principalgebundenen, noch nicht abgelaufenen Generation."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_HeartbeatWorker"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID."}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine abgelaufene/UNREACHABLE-Generation darf nicht wiederbelebt werden."}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_HeartbeatWorker.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_HeartbeatWorker
--
-- ## Zweck und Einsatzfälle
--
-- Erneuert die Heartbeatzeit einer token-/principalgebundenen, noch nicht abgelaufenen Generation.
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
-- | `@WorkerGeneration` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine abgelaufene/UNREACHABLE-Generation darf nicht wiederbelebt werden. |
-- | `@WorkerToken` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
-- | `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |
--
-- SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen fachlichen Ersatzidentitäten. Quelle und Effekte unterscheiden admin- und tokengebundene Pfade ausdrücklich.
--
-- ## Ergebnisse
--
-- Kein fachlicher Resultset, keine OUTPUT-Parameter, keine ResultTable-Option. Erfolg RETURN0. Hilfe: bisheriger zwölfspaltiger Standardhelp-Resultset plus genau eine zusätzliche Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max); RETURN0 vor Fachprüfung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;
--
-- -- Synthetische Identitäten ersetzen durch tatsächliches eigenes Registrierungsresultat:
-- DECLARE @Id uniqueidentifier='00000000-0000-0000-0000-000000000001',
--  @Token uniqueidentifier='00000000-0000-0000-0000-000000000002';
-- EXEC toolbelt_core.USP_HeartbeatWorker @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
-- -- Beispielwerte ohne passende Registrierung ergeben54215.
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
-- SET NOCOUNT ON und SET XACT_ABORT OFF im Prozedurcode vor dem positiven Hilfezweig; dort keine fachlichen Prüfungen, temporären Ergebnisobjekte oder Mutationen und keine eigenen Debugmessages. Kein privates Ergebnistemp und kein ResultTable-Routing. Fachpfad verlangt @@TRANCOUNT0/XACT_STATE0, danach eigene BEGIN TRANSACTION und TRY. Reihenfolge UPDLOCK/HOLDLOCK Gate→Scheduler→Konfigurationszeile. Erneuert ausschließlich LastHeartbeatAtUtc für das exakt gebundene Tupel. Kein Wechsel von State/AdmissionPaused, kein Reclaim, keine neue Generation und kein Update der globalen ConfigVersion. Auch PAUSED/DRAINING können bei noch gesunder Heartbeatfrist erneuert werden. Kein expliziter Latest-Generationfilter: entscheidend sind die exakte Autorität und die zwei Zustands-/Zeitprüfungen. Eine bereits abgelaufene oder UNREACHABLE-Generation darf nicht wiederbelebt werden. Kein Claim-/Leaseheartbeat des WorkItem; dafür besteht ein getrennter Queuepfad. Keine Savepointunterstützung für Callertransaktionen und kein eigener Retry. @Debug erzeugt keine eigenen Messages; nicht an den ResultTable-Helper weitergereicht.
--
-- ## Fehlerbehandlung
--
-- 54210/1 Callertransaktion bzw.nichtneutraler XACT_STATE.54211/1 fehlender Gate-/Scheduler-/Konfigurationsvertrag; fehlende Tabellen/kompilierte Abhängigkeiten können bereits als ursprüngliche Enginefehler auftreten. 54215/1 NULLIdentitätswert oder kein Tupel mit WorkerId/Generation/Token/USER_ID und State<>CLOSED.54215/2 UNREACHABLE oder LastHeartbeat+gespeicherterUnreachableSeconds<=EngineUTC. Ursprüngliche Sperr-, Constraint-, Arithmetic-, Helper-, INSERT- und Enginefehler bleiben sichtbar. CATCH rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine fachliche Fehlerstatuszeile.
--
-- ## Aussagegrenzen
--
-- WorkerToken ist kein ClaimToken; Kenntnis allein reicht nicht ohne passenden aktuellen Datenbankprincipal. Kein serverweiter Principal-/Hostidentitätsnachweis. Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Bindung. Keine Exactly-once-/Hostverlust-/Kill- oder vollständige Betriebsqualifikation allein aus Status/Token/Registrierung. Zusätzliche Skillhilfe wird nicht durch alte Standardhilfe-Nachweise qualifiziert.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_HeartbeatWorker' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Erneuert ausschließlich die aktuelle lebende Workergeneration ohne Claims zu übernehmen.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; OUTPUT-Parameter und Returncode siehe Parametervertrag.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Ausschließlich synthetischer Help-Aufruf.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@WorkerId', N'uniqueidentifier', 1, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@WorkerGeneration', N'bigint', 1, 1, N'NULL', CAST(N'Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine abgelaufene/UNREACHABLE-Generation darf nicht wiederbelebt werden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@WorkerToken', N'uniqueidentifier', 1, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_HeartbeatWorker' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-heartbeatworker"
description: "Erneuert die Heartbeatzeit einer token-/principalgebundenen, noch nicht abgelaufenen Generation."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_HeartbeatWorker"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID."}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine abgelaufene/UNREACHABLE-Generation darf nicht wiederbelebt werden."}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren."}, {"name": "@Debug", "sql_type": "tinyint", "sql_de' AS nvarchar(max)) + N'fault": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_HeartbeatWorker.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_HeartbeatWorker

## Zweck und Einsatzfälle

Erneuert die Heartbeatzeit einer token-/principalgebundenen, noch nicht abgelaufenen Generation.

## Voraussetzungen

Passendes Worker-Control1.0.0 mit Queue2.1.0 und seinen Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170, lokal/zentral. Fachaufruf benötigt neutralen Callertransaktionszustand sowie Gate1,Scheduler1,Konfiguration1. Hilfe ist mit technischen Defaults ohne Fachargumente möglich. Keine CLR-/Datei-/Netzwerkabhängigkeit dieses Aufrufs.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfol' + N'ge. Fachlich erforderliche stabile Workeridentität; NULL ist nur technischer Help-Default und im Fachaufruf ungültig. Bei Folgeaufrufen die eigene tatsächlich registrierte WorkerId verwenden, keine Session-ID. |
| `@WorkerGeneration` | `bigint` | `NULL` | Fachlich erforderliche positive bigint-WorkerGeneration aus der konkreten Registrierung, exakt zusammen mit WorkerId verwenden. Keine automatische Wahl der neuesten Generation; NULL/fehlende oder unpassende Generation wird abgewiesen. Eine abgelaufene/UNREACHABLE-Generation darf nicht wiederbelebt werden. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes WorkerToken aus derselben Registrierung; muss zu WorkerId, Generation und aktuellem Datenbankprincipal passen. NULL/abweichendes Token ungültig; kein ClaimToken und kein Token aus einer Vorgängergeneration. Nicht protokollieren. |
| `@Debug` | `tinyint` | `0` | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus eine vollständige vier-spaltige Skillzeile, danach RETURN0 vor Tempresult, Transaktions-/Versions-/Fachprüfung und Mutation. 0 oder NULL: Fachpfad. Alle Parameter haben technische Defaults; im Fachpfad sind die als erforderlich beschriebenen NULL-Defaults ungültig. |

SQL-Typkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults sind keine gültigen fachlichen Ersatzidentitäten. Quelle und Effekte unterscheiden admin- und tokengebundene Pfade ausdrücklich.

## Ergebnisse

Kein fachlicher Resultset, keine OUTPUT-Parameter, keine ResultTable-Option. Erfolg RETURN0. Hilfe: bisheriger zwölfspaltiger Standardhelp-Resultset plus genau eine zusätzliche Skillzeile mit SkillFormatVersion varchar(16),S' + N'chemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max); RETURN0 vor Fachprüfung.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_HeartbeatWorker @Hilfe=1;

-- Synthetische Identitäten ersetzen durch tatsächliches eigenes Registrierungsresultat:
DECLARE @Id uniqueidentifier=''00000000-0000-0000-0000-000000000001'',
 @Token uniqueidentifier=''00000000-0000-0000-0000-000000000002'';
EXEC toolbelt_core.USP_HeartbeatWorker @WorkerId=@Id,@WorkerGeneration=1,@WorkerToken=@Token;
-- Beispielwerte ohne passende Registrierung ergeben54215.
```

## Rechte

Vorhandenes EXECUTE auf genau diese öffentliche Prozedur. Register/Heartbeat verwenden USER_ID der aktuellen Datenbank als Ownerbindung; keine automatische Impersonation oder neuen Principalrechte. Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Keine Rechtevergabe, Serverrolle, Hostauthentifizierung oder pauschalen direkten Tabellenrechte. Für ResultTable-/Statuslese-/CrossDB-Zugriffe jeweils bestehende passende Rechte und Identitätsmapping; ein Dreiteilname überträgt keine Autorität.

## Ressourcenbedarf

Kurze eigene Transaktion, globale Gate-/Scheduler-/Konfigurationssperren und Workerregistrationszugriffe; Register liest neueste Generation und aktualisiert gegebenenfalls mehrere Vorgänger, SetState mehrere AdmissionPaused-Zeilen. Keine implementierte CPU-/Zeit-/Log-/Heap-/Ausgabebytequote oder eigener Locktimeout. Blockierung/Deadlock/Log-/tempdbdruck bleibt möglich. Technische Token-/Principalwerte niemals in öffentliche Testnachweise übernehmen.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Prozedurcode vor dem positiven Hilfezweig; dort keine fachlichen Prüfungen, temporären Ergebnisobjekte oder Mutationen und keine eigenen Debugmessages. Kein privates Ergebnistemp und kein ResultTable-Routing. Fachpfad verlangt @@TRANCOUNT0/XACT_STATE0, danach eigene BEGIN TRANSACTION und TRY. Reihenfolge UPDLOCK/HOLDLOCK Gate→Scheduler→Konfigurationszeile. Erneuert ausschließlich LastH' + N'eartbeatAtUtc für das exakt gebundene Tupel. Kein Wechsel von State/AdmissionPaused, kein Reclaim, keine neue Generation und kein Update der globalen ConfigVersion. Auch PAUSED/DRAINING können bei noch gesunder Heartbeatfrist erneuert werden. Kein expliziter Latest-Generationfilter: entscheidend sind die exakte Autorität und die zwei Zustands-/Zeitprüfungen. Eine bereits abgelaufene oder UNREACHABLE-Generation darf nicht wiederbelebt werden. Kein Claim-/Leaseheartbeat des WorkItem; dafür besteht ein getrennter Queuepfad. Keine Savepointunterstützung für Callertransaktionen und kein eigener Retry. @Debug erzeugt keine eigenen Messages; nicht an den ResultTable-Helper weitergereicht.

## Fehlerbehandlung

54210/1 Callertransaktion bzw.nichtneutraler XACT_STATE.54211/1 fehlender Gate-/Scheduler-/Konfigurationsvertrag; fehlende Tabellen/kompilierte Abhängigkeiten können bereits als ursprüngliche Enginefehler auftreten. 54215/1 NULLIdentitätswert oder kein Tupel mit WorkerId/Generation/Token/USER_ID und State<>CLOSED.54215/2 UNREACHABLE oder LastHeartbeat+gespeicherterUnreachableSeconds<=EngineUTC. Ursprüngliche Sperr-, Constraint-, Arithmetic-, Helper-, INSERT- und Enginefehler bleiben sichtbar. CATCH rollt die eigene noch aktive Transaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine fachliche Fehlerstatuszeile.

## Aussagegrenzen

WorkerToken ist kein ClaimToken; Kenntnis allein reicht nicht ohne passenden aktuellen Datenbankprincipal. Kein serverweiter Principal-/Hostidentitätsnachweis. Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Bindung. Keine Exactly-once-/Hostverlust-/Kill- oder vollständige Betriebsqualifikation allein aus Status/Token/Registrierung. Zusätzliche Skillhilfe wird nicht durch alte Standardhilfe-Nachweise qualifiziert.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @WorkerId IS NULL OR @WorkerGeneration IS NULL OR @WorkerToken IS NULL OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WITH(UPDLOCK,HOLDLOCK) WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND WorkerToken=@WorkerToken AND OwnerPrincipalId=USER_ID() AND State<>'CLOSED') THROW 54215,N'Die Workergeneration besitzt keine gültige Autorität.',1;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND (State='UNREACHABLE' OR DATEADD(SECOND,UnreachableSeconds,LastHeartbeatAtUtc)<=SYSUTCDATETIME())) THROW 54215,N'Die abgelaufene Workergeneration darf nicht wiederbelebt werden.',2;
 UPDATE toolbelt_core.WorkerRegistration SET LastHeartbeatAtUtc=SYSUTCDATETIME() WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 RETURN 0;
END;
GO
