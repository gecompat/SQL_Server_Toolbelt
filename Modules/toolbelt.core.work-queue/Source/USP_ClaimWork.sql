SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ClaimWork]
(
      @LeaseDurationSeconds int = 300
    , @ResultTable sysname       = NULL
    , @KeepData    bit           = 0
    , @Debug       tinyint       = 0
    , @Hilfe       bit           = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-claimwork"
-- description: "Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Öffentlicher Einstieg."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_ClaimWork"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@LeaseDurationSeconds", "sql_type": "int", "sql_default": "300", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ClaimWork.sql", "Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- ---
--
-- # USP_ClaimWork
--
-- ## Zweck und Einsatzfälle
--
-- Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Öffentlicher Einstieg.
--
-- ## Voraussetzungen
--
-- Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Keine Callertransaktion im öffentlichen Claimpfad. Private Managed-Admission verlangt genau eine gesunde bestehende Transaktion und passende Gatebindung. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersatzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `WorkItemId` | `bigint` | NOT NULL; kanonische Queue-ID |
-- | `WorkTypeName` | `varchar(128)` | NOT NULL; BIN2 |
-- | `PayloadJson` | `nvarchar(max)` | NULL; vertrauliche Payload |
-- | `ClaimToken` | `uniqueidentifier` | NOT NULL; geheimes Claimtoken |
-- | `ClaimedAtUtc` | `datetime2(7)` | NOT NULL |
-- | `ClaimGeneration` | `bigint` | NOT NULL |
-- | `LeaseUntilUtc` | `datetime2(7)` | NOT NULL |
-- | `LastHeartbeatAtUtc` | `datetime2(7)` | NOT NULL |
--
-- Null oder eine Claimzeile; geheime Payload/ClaimToken privat behandeln. Kein passendes Item ergibt leeren Resultset. ResultTableNULL:direkte Ausgabe; sonst vorbereitetes lokales Ziel mit denselben Spalten und ohne zusätzlichen direkten Fachresultset. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;
--
-- EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;
-- -- Null oder eine vertrauliche tatsächliche Claimzeile sicher übernehmen.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. CLAIM-Policy,Handler-Metadatensicht und EXECUTE auf den registrierten Handler werden geprüft. Kein Handleraufruf durch den Claim selbst. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.
--
-- ## Ressourcenbedarf
--
-- Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. KeepData/Debug/Hilfe werden im Claim-/FailpfadNULL→0 normalisiert. Die Fassade besitzt eigene frühe Hilfe und delegiert den Fachpfad genau einmal an USP_ClaimWorkCore; keine zweite fachliche Implementierung. Der öffentliche Claim delegiert ohne Managedtoken an den einen kanonischen ClaimCore. Kein Caller-TX für diesen Pfad. Der Kern setzt sein privates OUTPUT zunächstNULL und validiert EmitResult, Transaktionsform und Lease5..86400. Eigene Transaktion oder im geschützten Managedpfad ein Savepoint. Gate/Scheduler werden mit UPDLOCK/HOLDLOCK gelesen. ManagedEnabled0 erlaubt keine privaten Token/Reservation; ManagedEnabled1 verlangt passende einmalige GateNonce und PendingReservation im selben gesunden Admission-TX. Bei Managed-Admission wird die Nonce verbraucht/erneuert. Reife Retrybarriers können BARRIER_WAIT werden und neue Blockersnapshots erhalten, auch wenn am Ende kein Item geclaimt wird.
--
-- Kandidat mit UPDLOCK,READPAST,READCOMMITTEDLOCK,ROWLOCK und Statusindex: aktiver WorkType, sichtbare nichtsystemeigene Handlerprocedure, CLAIM-Policy erlaubt und Handler-EXECUTE vorhanden. Kein ManagedHold. SHARED ist QUEUED oder fälliger RETRY_WAIT und durch keine wartende/laufende Gruppenbarrier blockiert. DRAIN_BARRIER muss BARRIER_WAIT sein, keine erfasste aktive Blockergeneration und keine anders priorisierte laufende Barrier derselben Gruppe haben. Reihenfolge: Priority DESC, dann Retrytermin beziehungsweise EnqueuedAtUtc, dann WorkItemId. Keine Preemption oder automatische Übernahme abgelaufener Claims.
--
-- Höchstens ein UPDATE: neuer ClaimToken/EngineUTC/ORIGINAL_LOGIN,ClaimGeneration+1,LeaseDuration/LeaseUntil/Heartbeat, CycleAttemptCount+1,NextAttemptNULL und gegebenenfalls ManagedReservationbindung. Exakte ID aus UPDATE OUTPUT, kein zweiter Claim. Zielvorbereitung/INSERT gehören zur Transaktion. Nur eigener TX wird committed; CATCH rollt eigenen TX oder committable Caller-Savepoint zurück. Debug>0 liefert danach eine abstrakte Severity10-NOWAIT-Message, kein Payload-/Tokenlogging. Ein späterer Debug-/Ergebnistransportfehler kann einen eigenen bereits erfolgten Commit nicht zurücknehmen.
--
-- ## Fehlerbehandlung
--
-- 54200/4 EmitResultNULL oder EmitResult0 ohne privaten Token.51910 unzulässige Transaktionsform;51911 LeaseNULL/außerhalb5..86400.54200/1 fehlender Managedgate, /2 private Bindung im Managedmodus fehlt/driftet, /3 private Werte bei deaktiviertem Managedmodus.51918 fehlender ResultTablehelper. Frühere OUTPUT-Initialisierung ist von Erfolg zu trennen. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarchar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten; keine Installations-/Rechteattestation.
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
            CAST(N'USP_ClaimWork' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'PayloadJson', N'nvarchar(max)', 0, 1, NULL, CAST(N'Optionale bereinigte JSON-Payload.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'ClaimToken', N'uniqueidentifier', 0, 0, NULL, CAST(N'Geheimes Ownership-Token für Heartbeat, Complete oder Fail.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'ClaimedAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'UTC-Zeitpunkt des Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Monotoner Ownership-Zähler dieses Work Items.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'LeaseUntilUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'Exklusive UTC-Grenze der Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'LastHeartbeatAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'Beim Claim identisch mit ClaimedAtUtc.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51910-51918', NULL, NULL, NULL, NULL, CAST(N'Caller-Transaktions-, Lease- oder ResultTable-Fehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beansprucht synthetische Arbeit für fünf Minuten.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@LeaseDurationSeconds', N'int', 0, 0, N'300', CAST(N'Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt.' AS nvarchar(max)), NULL),
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
 CONVERT(sysname,CAST(N'USP_ClaimWork' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-claimwork"
description: "Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Öffentlicher Einstieg."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_ClaimWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@LeaseDurationSeconds", "sql_type": "int", "sql_default": "300", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die i' AS nvarchar(max)) + N'm Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ClaimWork.sql", "Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_ClaimWork

## Zweck und Einsatzfälle

Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Öffentlicher Einstieg.

## Voraussetzungen

Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Keine Callertransaktion im öffentlichen Claimpfad. Private Managed-Admission verlangt genau eine gesunde bestehende Transaktion und passende Gatebindung. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, D' + N'efault 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersatzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL; kanonische Queue-ID |
| `WorkTypeName` | `varchar(128)` | NOT NULL; BIN2 |
| `PayloadJson` | `nvarchar(max)` | NULL; vertrauliche Payload |
| `ClaimToken` | `uniqueidentifier` | NOT NULL; geheimes Claimtoken |
| `ClaimedAtUtc` | `datetime2(7)` | NOT NULL |
| `ClaimGeneration` | `bigint` | NOT NULL |
| `LeaseUnt' + N'ilUtc` | `datetime2(7)` | NOT NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NOT NULL |

Null oder eine Claimzeile; geheime Payload/ClaimToken privat behandeln. Kein passendes Item ergibt leeren Resultset. ResultTableNULL:direkte Ausgabe; sonst vorbereitetes lokales Ziel mit denselben Spalten und ohne zusätzlichen direkten Fachresultset. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;

EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;
-- Null oder eine vertrauliche tatsächliche Claimzeile sicher übernehmen.
```

## Rechte

Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. CLAIM-Policy,Handler-Metadatensicht und EXECUTE auf den registrierten Handler werden geprüft. Kein Handleraufruf durch den Claim selbst. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.

## Ressourcenbedarf

Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. KeepData/Debug/Hilfe werden im Claim-/Failpfa' + N'dNULL→0 normalisiert. Die Fassade besitzt eigene frühe Hilfe und delegiert den Fachpfad genau einmal an USP_ClaimWorkCore; keine zweite fachliche Implementierung. Der öffentliche Claim delegiert ohne Managedtoken an den einen kanonischen ClaimCore. Kein Caller-TX für diesen Pfad. Der Kern setzt sein privates OUTPUT zunächstNULL und validiert EmitResult, Transaktionsform und Lease5..86400. Eigene Transaktion oder im geschützten Managedpfad ein Savepoint. Gate/Scheduler werden mit UPDLOCK/HOLDLOCK gelesen. ManagedEnabled0 erlaubt keine privaten Token/Reservation; ManagedEnabled1 verlangt passende einmalige GateNonce und PendingReservation im selben gesunden Admission-TX. Bei Managed-Admission wird die Nonce verbraucht/erneuert. Reife Retrybarriers können BARRIER_WAIT werden und neue Blockersnapshots erhalten, auch wenn am Ende kein Item geclaimt wird.

Kandidat mit UPDLOCK,READPAST,READCOMMITTEDLOCK,ROWLOCK und Statusindex: aktiver WorkType, sichtbare nichtsystemeigene Handlerprocedure, CLAIM-Policy erlaubt und Handler-EXECUTE vorhanden. Kein ManagedHold. SHARED ist QUEUED oder fälliger RETRY_WAIT und durch keine wartende/laufende Gruppenbarrier blockiert. DRAIN_BARRIER muss BARRIER_WAIT sein, keine erfasste aktive Blockergeneration und keine anders priorisierte laufende Barrier derselben Gruppe haben. Reihenfolge: Priority DESC, dann Retrytermin beziehungsweise EnqueuedAtUtc, dann WorkItemId. Keine Preemption oder automatische Übernahme abgelaufener Claims.

Höchstens ein UPDATE: neuer ClaimToken/EngineUTC/ORIGINAL_LOGIN,ClaimGeneration+1,LeaseDuration/LeaseUntil/Heartbeat, CycleAttemptCount+1,NextAttemptNULL und gegebenenfalls ManagedReservationbindung. Exakte ID aus UPDATE OUTPUT, kein zweiter Claim. Zielvorbereitung/INSERT gehören zur Transaktion. Nur eigener TX wird committed; CATCH rollt eigenen TX oder committable Caller-Savepoint zurück. Debug>0 liefert danach eine abstrakte Severity10-NOWAIT-Message, kein Payload-/Tokenlogging. Ein späterer Debug-/Ergebnistra' + N'nsportfehler kann einen eigenen bereits erfolgten Commit nicht zurücknehmen.

## Fehlerbehandlung

54200/4 EmitResultNULL oder EmitResult0 ohne privaten Token.51910 unzulässige Transaktionsform;51911 LeaseNULL/außerhalb5..86400.54200/1 fehlender Managedgate, /2 private Bindung im Managedmodus fehlt/driftet, /3 private Werte bei deaktiviertem Managedmodus.51918 fehlender ResultTablehelper. Frühere OUTPUT-Initialisierung ist von Erfolg zu trennen. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarchar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    EXEC toolbelt_core.USP_ClaimWorkCore @LeaseDurationSeconds=@LeaseDurationSeconds,
        @ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
END;
GO
