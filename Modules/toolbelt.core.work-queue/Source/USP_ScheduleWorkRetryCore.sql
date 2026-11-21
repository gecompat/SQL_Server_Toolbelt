-- Interner Terminalkern; fachliche Logik genau einmal.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ScheduleWorkRetryCore]
      @EmitResult bit=1,@WorkItemId bigint=NULL,@ClaimToken uniqueidentifier=NULL,@FailureCode varchar(64)=NULL,@FailureMessage nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-scheduleworkretrycore"
-- description: "Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Interner Kern."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_ScheduleWorkRetryCore"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@EmitResult", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1:direkter Fachresultset (Default);0 oderNULL:kein direkter SELECT. Keine zusätzliche Autorität. ResultTable bleibt unabhängig davon nicht unterstützt."}, {"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@FailureMessage", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetryCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- public_entrypoints: ["toolbelt_core.USP_ScheduleWorkRetry"]
-- ---
--
-- # USP_ScheduleWorkRetryCore
--
-- ## Zweck und Einsatzfälle
--
-- Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Interner Kern. Öffentlich passenden Einstieg statt direktem Kernaufruf verwenden.
--
-- ## Voraussetzungen
--
-- Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@EmitResult` | `bit` | `1` | Input | 1:direkter Fachresultset (Default);0 oderNULL:kein direkter SELECT. Keine zusätzliche Autorität. ResultTable bleibt unabhängig davon nicht unterstützt. |
-- | `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims. |
-- | `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
-- | `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
-- | `@FailureMessage` | `nvarchar(1000)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben. |
-- | `@KeepData` | `bit` | `0` | Input | bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersatzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Regeln/Bedeutung |
-- |---|---|---|
-- | `WorkItemId` | `bigint` | NOT NULL; IDENTITY(1,1), geclusterter Primärschlüssel |
-- | `WorkTypeName` | `varchar(128)` | WorkType-Katalogname, BIN2 |
-- | `Status` | `varchar(16)` | NOT NULL; BIN2, Default QUEUED |
-- | `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL; Default SYSUTCDATETIME() |
-- | `EnqueuedBy` | `sysname` | NOT NULL; Default ORIGINAL_LOGIN() |
-- | `ClaimedAtUtc` | `datetime2(7)` | NULL |
-- | `ClaimedBy` | `sysname` | NULL |
-- | `CompletedAtUtc` | `datetime2(7)` | NULL |
-- | `CompletedBy` | `sysname` | NULL |
-- | `FailedAtUtc` | `datetime2(7)` | NULL |
-- | `FailedBy` | `sysname` | NULL |
-- | `FailureCode` | `varchar(64)` | NULL; BIN2 |
-- | `FailureMessage` | `nvarchar(1000)` | NULL |
-- | `RowVersion` | `binary(8)` | Konvertierter WorkItem-Rowversionwert, keine Zeitangabe |
-- | `ClaimGeneration` | `bigint` | NOT NULL; Default0 |
-- | `LeaseDurationSeconds` | `int` | NULL |
-- | `LeaseUntilUtc` | `datetime2(7)` | NULL |
-- | `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
-- | `IsLeaseExpired` | `bit` | 1 genau bei Status CLAIMED und LeaseUntilUtc<=SYSUTCDATETIME(), sonst0 |
-- | `RecoveryCount` | `bigint` | NOT NULL; Default0 |
-- | `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
-- | `LastRecoveredBy` | `sysname` | NULL |
-- | `ExecutionGroup` | `varchar(128)` | NOT NULL; BIN2, Default default |
-- | `Priority` | `tinyint` | NOT NULL; Default0 |
-- | `ExecutionMode` | `varchar(16)` | NOT NULL; BIN2, Default SHARED |
-- | `MaxAttempts` | `tinyint` | NOT NULL; Default3 |
-- | `RetryBaseDelaySeconds` | `int` | NOT NULL; Default60 |
-- | `RetryMaxDelaySeconds` | `int` | NOT NULL; Default3600 |
-- | `RetryCycleNumber` | `bigint` | NOT NULL; Default1 |
-- | `CycleAttemptCount` | `bigint` | NOT NULL; Default0 |
-- | `NextAttemptAtUtc` | `datetime2(7)` | NULL |
-- | `LastErrorCode` | `varchar(64)` | NULL; BIN2 |
-- | `LastErrorMessage` | `nvarchar(1000)` | NULL |
-- | `LastRetryScheduledAtUtc` | `datetime2(7)` | NULL |
-- | `LastRetryScheduledBy` | `sysname` | NULL |
-- | `DeadLetteredAtUtc` | `datetime2(7)` | NULL |
-- | `DeadLetteredBy` | `sysname` | NULL |
-- | `LastRequeuedAtUtc` | `datetime2(7)` | NULL |
-- | `LastRequeuedBy` | `sysname` | NULL |
-- | `LastRequeueReason` | `nvarchar(1000)` | NULL |
-- | `BarrierEpoch` | `bigint` | NOT NULL; Default0 |
--
-- SELECT * aus VW_WorkQueue:41 Spalten in obiger Reihenfolge. Die reguläre Entscheidung ist RETRY_WAIT oder DEAD_LETTER. Ausgabe liest die aktuelle View nach eigenem Commit; parallele Arbeit kann bereits einen neueren zulässigen Queuezustand zeigen. Kein materialisierter Entscheidungsreceipt. Bei fehlender ID kann leere Ausgabe entstehen. EmitResult steuert den direkten SELECT wie beim Parameter beschrieben. Nur ResultTableNULL zulässig. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_ScheduleWorkRetryCore @Hilfe=1;
-- -- Fachpfad über öffentlichen Einstieg oder kontrollierten Managedprovider.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. ClaimToken bindet den vorhandenen aktiven Claim; der Code fordert hier keine neue WorkType-Policyentscheidung an. Gehaltene/verwaltete Arbeit verlangt zusätzlich den geschützten Managedabschluss, keinen öffentlichen Bypass. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.
--
-- ## Ressourcenbedarf
--
-- Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. Retry nutzt ISNULL nur für den Hilfezweig; KeepData/Debug haben im aktuellen Kern keine weitere Wirkung. ManagedHold oder eine ManagedReservation ohne geschützte completion_nonce/Transaction-Disposition-AppLock wird vor und nach dem Row Lock abgewehrt. Pflicht-ID/Token/FailureCode und Fehlerdaten prüfen; ResultTable mussNULL sein. Eigener TX bei@@TRANCOUNT0, sonst Savepoint TBX_WorkQueue_Retry. Der Kern liest Status/Token/Lease sowie gespeicherte Attempts-/Backoffpolicy unter UPDLOCK/HOLDLOCK und verlangt CLAIMED/passendesToken/nochaktiveLease.
--
-- Bei CycleAttemptCount>=MaxAttempts DEAD_LETTER mit aktuellem/letztem Fehler und DeadLetterzeit/ORIGINAL_LOGIN. Sonst RETRY_WAIT, Claim-/Lease-/Heartbeatfelder löschen und NextAttempt=EngineUTC+min(Base*2^(Attempt-1),Cap), ohne Jitter; LastError und LastRetryScheduled setzen. Keine sofortige Handlerausführung, keine neue Claimgeneration und kein Zurücksetzen des Retryzyklus. Andere History bleibt erhalten. Eigener Commit oder Caller-TX erhalten; CATCH eigener Rollback beziehungsweise committable Savepointrollback.
--
-- Der vorhandene Kern hat keinen eigenen positiven Existenz-/StatusISNULL-Guard für eine fehlende WorkItemId und keine abschließende Rowcountprüfung. Bei nicht existierender ID können SQL-NULL-Vergleiche zu keinem UPDATE und leerer Ausgabe führen. Eine implizite0 oder leere Ausgabe beweist deshalb keinen erfolgreichen Retry. Ausschließlich die tatsächliche eigene Claim-ID/Token verwenden. Unter Caller-TX können ursprüngliche SAVEPOINT-/Enginefehler auftreten; keinen pauschalen öffentlichen Caller-TX-Verbotsguard behaupten.
--
-- Der direkte SELECT auf VW_WorkQueue erfolgt nach eigenem Commit und wird nicht vorher als Ergebnisreceipt materialisiert. Unter paralleler Arbeit kann er einen neueren Zustand sehen. In einem weiterlaufenden Caller-TX ist dagegen noch kein äußerer Commit durch diesen Helper bewiesen. Die Zeile und eine0 ersetzen keinen gebundenen Commit-/Retrynachweis.
--
-- ## Fehlerbehandlung
--
-- 54201 geschützter Managed-/Holdpfad verletzt;51985 ID/Token/CodeNULL;51986 ungültiger Code oder Messagebreite;51989 nichtNULLResultTable;51987 nichtaktiver Status/Token/Lease nach dem vorhandenen NULL-Vergleich. Fehlende IDs werden nicht durch einen separaten positiven Existenzguard abgewiesen; leere Ausgabe ist kein Retrybeweis. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarchar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten; keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ScheduleWorkRetryCore' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Privater tokengebundener Retrykern; vorhandene Queuepolicy entscheidet Retry oder Dead Letter.',NULL),
('PARAMETER',1,N'@EmitResult',N'bit',0,0,N'1',N'0 unterdrückt das Fachresultset; keine neue Autorität.',NULL),
('PARAMETER',2,N'@WorkItemId',N'bigint',1,0,N'NULL',N'Exakter Queueclaim.',NULL),
('PARAMETER',3,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Exaktes Ownershiptoken.',NULL),
('PARAMETER',4,N'@FailureCode',N'varchar(64)',1,0,N'NULL',N'Stabiler synthetischer Fehlercode.',NULL),
('PARAMETER',5,N'@FailureMessage',N'nvarchar(1000)',0,1,N'NULL',N'Optionale bereinigte Fehlermeldung.',NULL),
('PARAMETER',6,N'@ResultTable',N'sysname',0,1,N'NULL',N'In dieser kanonischen Retryversion nicht unterstützt.',NULL),
('PARAMETER',7,N'@KeepData',N'bit',0,0,N'0',N'Standardparameter.',NULL),
('PARAMETER',8,N'@Debug',N'tinyint',0,0,N'0',N'Abstrakte Debugmeldung.',NULL),
('PARAMETER',9,N'@Hilfe',N'bit',0,0,N'0',N'1 liefert ausschließlich Help.',NULL),
('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Helpaufruf.',N'EXEC toolbelt_core.USP_ScheduleWorkRetryCore @Hilfe=1;')
 )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
-- OBJECT_USAGE_SKILL_HELP:COMPACT
 -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ScheduleWorkRetryCore' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-scheduleworkretrycore"
description: "Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Interner Kern."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_ScheduleWorkRetryCore"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@EmitResult", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1:direkter Fachresultset (Default);0 oderNULL:kein direkter SELECT. Keine zusätzliche Autorität. ResultTable bleibt unabhängig davon nicht unterstützt."}, {"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_re' AS nvarchar(max)) + N'quired": true, "nullable": false, "description": "Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@FailureMessage", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "descri' + N'ption": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetryCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql"]
review_status: "verified"
source_module_version: "2.1.0"
public_entrypoints: ["toolbelt_core.USP_ScheduleWorkRetry"]
---

# USP_ScheduleWorkRetryCore

## Zweck und Einsatzfälle

Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Interner Kern. Öffentlich passenden Einstieg statt direktem Kernaufruf verwenden.

## Voraussetzungen

Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@EmitResult` | `bit` | `1` | Input | 1:direkter Fachresultset (Default);0 oderNULL:kein direkter SELECT. Keine zusätzliche Autorität. ResultTable bleibt unabhängig davon nicht unterstützt. |
| `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für ni' + N'cht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(1000)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden. |
| `@ResultTable` | `sysname` | `NULL` | Input | Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben. |
| `@KeepData` | `bit` | `0` | Input | bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bish' + N'erige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersatzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL; IDENTITY(1,1), geclusterter Primärschlüssel |
| `WorkTypeName` | `varchar(128)` | WorkType-Katalogname, BIN2 |
| `Status` | `varchar(16)` | NOT NULL; BIN2, Default QUEUED |
| `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL; Default SYSUTCDATETIME() |
| `EnqueuedBy` | `sysname` | NOT NULL; Default ORIGINAL_LOGIN() |
| `ClaimedAtUtc` | `datetime2(7)` | NULL |
| `ClaimedBy` | `sysname` | NULL |
| `CompletedAtUtc` | `datetime2(7)` | NULL |
| `CompletedBy` | `sysname` | NULL |
| `FailedAtUtc` | `datetime2(7)` | NULL |
| `FailedBy` | `sysname` | NULL |
| `FailureCode` | `varchar(64)` | NULL; BIN2 |
| `FailureMessage` | `nvarchar(1000)` | NULL |
| `RowVersion` | `binary(8)` | Konvertierter WorkItem-Rowversionwert, keine Zeitangabe |
| `ClaimGeneration` | `bigint` | NOT NULL; Default0 |
| `LeaseDurationSeconds` | `int` | NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
| `IsLeaseExpired` | `bit` | 1 genau bei Status CLAIMED und LeaseUntilUtc<=SYSUTCDATETIME(), sonst0 |
| `RecoveryCount` | `bigint` | NOT NULL; Default0 |
| `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
| `LastRecoveredBy` | `sysname` | NULL |
| `ExecutionGroup` | `varchar(128)` | NOT NULL; BIN2, Default default |
| `Priority` | `tinyint` | NOT NULL; Default0 |
| `ExecutionMode` | `varchar(16)` | NOT NULL; BIN2, Default SHARED |
| `MaxAttempts` | `tinyint` | NOT NULL; Default3 |
| `RetryBaseDelaySeconds` | `int` | NOT NULL; D' + N'efault60 |
| `RetryMaxDelaySeconds` | `int` | NOT NULL; Default3600 |
| `RetryCycleNumber` | `bigint` | NOT NULL; Default1 |
| `CycleAttemptCount` | `bigint` | NOT NULL; Default0 |
| `NextAttemptAtUtc` | `datetime2(7)` | NULL |
| `LastErrorCode` | `varchar(64)` | NULL; BIN2 |
| `LastErrorMessage` | `nvarchar(1000)` | NULL |
| `LastRetryScheduledAtUtc` | `datetime2(7)` | NULL |
| `LastRetryScheduledBy` | `sysname` | NULL |
| `DeadLetteredAtUtc` | `datetime2(7)` | NULL |
| `DeadLetteredBy` | `sysname` | NULL |
| `LastRequeuedAtUtc` | `datetime2(7)` | NULL |
| `LastRequeuedBy` | `sysname` | NULL |
| `LastRequeueReason` | `nvarchar(1000)` | NULL |
| `BarrierEpoch` | `bigint` | NOT NULL; Default0 |

SELECT * aus VW_WorkQueue:41 Spalten in obiger Reihenfolge. Die reguläre Entscheidung ist RETRY_WAIT oder DEAD_LETTER. Ausgabe liest die aktuelle View nach eigenem Commit; parallele Arbeit kann bereits einen neueren zulässigen Queuezustand zeigen. Kein materialisierter Entscheidungsreceipt. Bei fehlender ID kann leere Ausgabe entstehen. EmitResult steuert den direkten SELECT wie beim Parameter beschrieben. Nur ResultTableNULL zulässig. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ScheduleWorkRetryCore @Hilfe=1;
-- Fachpfad über öffentlichen Einstieg oder kontrollierten Managedprovider.
```

## Rechte

Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. ClaimToken bindet den vorhandenen aktiven Claim; der Code fordert hier keine neue WorkType-Policyentscheidung an. Gehaltene/verwaltete Arbeit verlangt zusätzlich den geschützte' + N'n Managedabschluss, keinen öffentlichen Bypass. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.

## Ressourcenbedarf

Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. Retry nutzt ISNULL nur für den Hilfezweig; KeepData/Debug haben im aktuellen Kern keine weitere Wirkung. ManagedHold oder eine ManagedReservation ohne geschützte completion_nonce/Transaction-Disposition-AppLock wird vor und nach dem Row Lock abgewehrt. Pflicht-ID/Token/FailureCode und Fehlerdaten prüfen; ResultTable mussNULL sein. Eigener TX bei@@TRANCOUNT0, sonst Savepoint TBX_WorkQueue_Retry. Der Kern liest Status/Token/Lease sowie gespeicherte Attempts-/Backoffpolicy unter UPDLOCK/HOLDLOCK und verlangt CLAIMED/passendesToken/nochaktiveLease.

Bei CycleAttemptCount>=MaxAttempts DEAD_LETTER mit aktuellem/letztem Fehler und DeadLetterzeit/ORIGINAL_LOGIN. Sonst RETRY_WAIT, Claim-/Lease-/Heartbeatfelder löschen und NextAttempt=EngineUTC+min(Base*2^(Attempt-1),Cap), ohne Jitter; LastError und LastRetryScheduled setzen. Keine sofortige Handlerausführung, keine neue Claimgeneration und kein Zurücksetzen des Retryzyklus. Andere History bleibt erhalten. Eigener Commit oder Caller-TX erhalten; CATCH eigener Rollback beziehungsweise committable Savepointrollback.

Der vorhandene Kern hat keinen eigenen positiven Existenz-/StatusISNULL-Guard für eine fehlende WorkItemId und keine abschließende ' + N'Rowcountprüfung. Bei nicht existierender ID können SQL-NULL-Vergleiche zu keinem UPDATE und leerer Ausgabe führen. Eine implizite0 oder leere Ausgabe beweist deshalb keinen erfolgreichen Retry. Ausschließlich die tatsächliche eigene Claim-ID/Token verwenden. Unter Caller-TX können ursprüngliche SAVEPOINT-/Enginefehler auftreten; keinen pauschalen öffentlichen Caller-TX-Verbotsguard behaupten.

Der direkte SELECT auf VW_WorkQueue erfolgt nach eigenem Commit und wird nicht vorher als Ergebnisreceipt materialisiert. Unter paralleler Arbeit kann er einen neueren Zustand sehen. In einem weiterlaufenden Caller-TX ist dagegen noch kein äußerer Commit durch diesen Helper bewiesen. Die Zeile und eine0 ersetzen keinen gebundenen Commit-/Retrynachweis.

## Fehlerbehandlung

54201 geschützter Managed-/Holdpfad verletzt;51985 ID/Token/CodeNULL;51986 ungültiger Code oder Messagebreite;51989 nichtNULLResultTable;51987 nichtaktiver Status/Token/Lease nach dem vorhandenen NULL-Vergleich. Fehlende IDs werden nicht durch einen separaten positiven Existenzguard abgewiesen; leere Ausgabe ist kein Retrybeweis. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarchar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten;' + N' keine Installations-/Rechteattestation.
' AS SkillMarkdown;
 -- OBJECT_USAGE_SKILL_HELP:END
 RETURN 0;END;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND
       (ManagedHold=1 OR (ManagedReservationId IS NOT NULL AND
        (ManagedCompletionNonce IS NULL OR TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce')) IS NULL
         OR ManagedCompletionNonce<>TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce'))
         OR APPLOCK_MODE(N'public',N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),ManagedReservationId),N'Transaction')<>N'Exclusive'))))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
 IF @WorkItemId IS NULL OR @ClaimToken IS NULL OR @FailureCode IS NULL THROW 51985,N'Work Item, ClaimToken und FailureCode sind erforderlich.',1;
 IF @FailureCode NOT LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2 OR @FailureCode LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2 OR DATALENGTH(@FailureMessage)>2000 THROW 51986,N'Die Fehlerdaten sind ungültig.',1;
 IF @ResultTable IS NOT NULL THROW 51989,N'@ResultTable wird von dieser Version nicht unterstützt.',1;
 DECLARE @Initial int=@@TRANCOUNT,@Now datetime2(7)=SYSUTCDATETIME(),@Attempt bigint,@Max tinyint,@Base int,@Cap int,@Mode varchar(16),@Status varchar(16),@Token uniqueidentifier,@Lease datetime2(7),@Delay int,@Next datetime2(7);
 IF @Initial=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkQueue_Retry;
 BEGIN TRY
  SELECT @Status=Status,@Token=ClaimToken,@Lease=LeaseUntilUtc,@Attempt=CycleAttemptCount,@Max=MaxAttempts,@Base=RetryBaseDelaySeconds,@Cap=RetryMaxDelaySeconds,@Mode=ExecutionMode FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND
       (ManagedHold=1 OR (ManagedReservationId IS NOT NULL AND
        (ManagedCompletionNonce IS NULL OR TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce')) IS NULL
         OR ManagedCompletionNonce<>TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce'))
         OR APPLOCK_MODE(N'public',N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),ManagedReservationId),N'Transaction')<>N'Exclusive'))))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
  IF @Status<>'CLAIMED' OR @Token<>@ClaimToken OR @Lease<=@Now THROW 51987,N'Der Claim ist nicht aktiv.',1;
  IF @Attempt>=@Max
   UPDATE toolbelt_core.WorkItem SET Status='DEAD_LETTER',FailureCode=@FailureCode,FailureMessage=@FailureMessage,LastErrorCode=@FailureCode,LastErrorMessage=@FailureMessage,DeadLetteredAtUtc=@Now,DeadLetteredBy=ORIGINAL_LOGIN() WHERE WorkItemId=@WorkItemId;
  ELSE
  BEGIN
   SET @Delay=CONVERT(int,CASE WHEN @Attempt>=31 THEN @Cap WHEN POWER(CONVERT(float,2),@Attempt-1)*@Base>@Cap THEN @Cap ELSE POWER(CONVERT(float,2),@Attempt-1)*@Base END);
   SET @Next=DATEADD(SECOND,@Delay,@Now);
   UPDATE toolbelt_core.WorkItem SET Status='RETRY_WAIT',ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL,LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL,NextAttemptAtUtc=@Next,LastErrorCode=@FailureCode,LastErrorMessage=@FailureMessage,LastRetryScheduledAtUtc=@Now,LastRetryScheduledBy=ORIGINAL_LOGIN() WHERE WorkItemId=@WorkItemId;
  END;
  IF @Initial=0 COMMIT;
 END TRY BEGIN CATCH IF @Initial=0 AND XACT_STATE()<>0 ROLLBACK; ELSE IF @Initial>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_Retry; THROW; END CATCH;
 IF @EmitResult=1 SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
END;
GO
