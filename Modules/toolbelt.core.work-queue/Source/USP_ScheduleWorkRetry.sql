SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ScheduleWorkRetry]
      @WorkItemId bigint=NULL,@ClaimToken uniqueidentifier=NULL,@FailureCode varchar(64)=NULL,@FailureMessage nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-scheduleworkretry"
-- description: "Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Öffentlicher Einstieg."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_ScheduleWorkRetry"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@FailureMessage", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetry.sql", "Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetryCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- ---
--
-- # USP_ScheduleWorkRetry
--
-- ## Zweck und Einsatzfälle
--
-- Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Öffentlicher Einstieg.
--
-- ## Voraussetzungen
--
-- Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
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
-- SELECT * aus VW_WorkQueue:41 Spalten in obiger Reihenfolge. Die reguläre Entscheidung ist RETRY_WAIT oder DEAD_LETTER. Ausgabe liest die aktuelle View nach eigenem Commit; parallele Arbeit kann bereits einen neueren zulässigen Queuezustand zeigen. Kein materialisierter Entscheidungsreceipt. Bei fehlender ID kann leere Ausgabe entstehen. Nur ResultTableNULL zulässig. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;
--
-- -- Tatsächliche eigene Claim-ID/Token ersetzen diese synthetischen Werte:
-- DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
-- EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=1,@ClaimToken=@Token,@FailureCode='CONTOSO.TRANSIENT';
-- -- Kein freier Replaypfad; falsche/nicht vorhandene Bindung ist kein erfolgreicher Übergang.
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
-- NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. Retry nutzt ISNULL nur für den Hilfezweig; KeepData/Debug haben im aktuellen Kern keine weitere Wirkung. Die Fassade besitzt eigene frühe Hilfe und delegiert den Fachpfad genau einmal an USP_ScheduleWorkRetryCore; keine zweite fachliche Implementierung. ManagedHold oder eine ManagedReservation ohne geschützte completion_nonce/Transaction-Disposition-AppLock wird vor und nach dem Row Lock abgewehrt. Pflicht-ID/Token/FailureCode und Fehlerdaten prüfen; ResultTable mussNULL sein. Eigener TX bei@@TRANCOUNT0, sonst Savepoint TBX_WorkQueue_Retry. Der Kern liest Status/Token/Lease sowie gespeicherte Attempts-/Backoffpolicy unter UPDLOCK/HOLDLOCK und verlangt CLAIMED/passendesToken/nochaktiveLease.
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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_ScheduleWorkRetry' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Plant anhand eines aktiven Claim-Tokens den nächsten Retry oder verschiebt nach ausgeschöpften Versuchen in Dead Letter.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51985-51989', NULL, NULL, NULL, NULL, CAST(N'Fehlende Argumente, ungültige Fehlerdaten, inaktiver Claim oder nicht unterstütztes ResultTable.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE sowie die Queue-Claim-Autorisierung des aufrufenden Pfades.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Diese Version unterstützt kein ResultTable-Routing; der Aufruf gibt eine Statuszeile aus toolbelt_core.VW_WorkQueue zurück.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beispielaufruf nach einem gültigen Claim.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=42,@ClaimToken=''00000000-0000-0000-0000-000000000001'',@FailureCode=''Transient'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'Aktueller Status aus VW_WorkQueue; reguläre Retryentscheidung: RETRY_WAIT oder DEAD_LETTER.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'EnqueuedAtUtc', N'datetime2(7)', 0, 0, NULL, CAST(N'UTC-Zeitpunkt der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'EnqueuedBy', N'sysname', 0, 0, NULL, CAST(N'Original-Login der Einreihung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ClaimedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt des Claims.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'ClaimedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Claimers.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'CompletedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt eines erfolgreichen Abschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'CompletedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des erfolgreichen Abschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'FailedAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'UTC-Zeitpunkt eines Fehlabschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'FailedBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login des Fehlabschlusses.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'FailureCode', N'varchar(64)', 0, 1, NULL, CAST(N'Optionaler stabiler Fehlercode.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'FailureMessage', N'nvarchar(1000)', 0, 1, NULL, CAST(N'Optionale bereinigte Fehlermeldung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'RowVersion', N'binary(8)', 0, 0, NULL, CAST(N'Aktueller Concurrency-Marker.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'ClaimGeneration', N'bigint', 0, 0, NULL, CAST(N'Monotoner Ownership-Zähler.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'LeaseDurationSeconds', N'int', 0, 1, NULL, CAST(N'Dauer der aktuellen oder letzten Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 17, N'LeaseUntilUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Exklusive UTC-Grenze der aktuellen oder letzten Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 18, N'LastHeartbeatAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Zeitpunkt des letzten Heartbeats.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 19, N'IsLeaseExpired', N'bit', 0, 0, NULL, CAST(N'1 nur bei aktuell CLAIMED und abgelaufener Lease.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 20, N'RecoveryCount', N'bigint', 0, 0, NULL, CAST(N'Kumulierte kontrollierte Recoveries.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 21, N'LastRecoveredAtUtc', N'datetime2(7)', 0, 1, NULL, CAST(N'Zeitpunkt der letzten Recovery.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 22, N'LastRecoveredBy', N'sysname', 0, 1, NULL, CAST(N'Original-Login der letzten Recovery.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 23, N'ExecutionGroup', N'varchar(128)', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 24, N'Priority', N'tinyint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 25, N'ExecutionMode', N'varchar(16)', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 26, N'MaxAttempts', N'tinyint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 27, N'RetryBaseDelaySeconds', N'int', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 28, N'RetryMaxDelaySeconds', N'int', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 29, N'RetryCycleNumber', N'bigint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 30, N'CycleAttemptCount', N'bigint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 31, N'NextAttemptAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 32, N'LastErrorCode', N'varchar(64)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 33, N'LastErrorMessage', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 34, N'LastRetryScheduledAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 35, N'LastRetryScheduledBy', N'sysname', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 36, N'DeadLetteredAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 37, N'DeadLetteredBy', N'sysname', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 38, N'LastRequeuedAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 39, N'LastRequeuedBy', N'sysname', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 40, N'LastRequeueReason', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 41, N'BarrierEpoch', N'bigint', NULL, 0, NULL, CAST(N'Unveränderte Statusspalte aus toolbelt_core.VW_WorkQueue.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@WorkItemId', N'bigint', 1, 0, N'NULL', CAST(N'Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ClaimToken', N'uniqueidentifier', 1, 0, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@FailureCode', N'varchar(64)', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@FailureMessage', N'nvarchar(1000)', 0, 1, N'NULL', CAST(N'Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ScheduleWorkRetry' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-scheduleworkretry"
description: "Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Öffentlicher Einstieg."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_ScheduleWorkRetry"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@Fai' AS nvarchar(max)) + N'lureMessage", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-que' + N'ue/Source/USP_ScheduleWorkRetry.sql", "Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetryCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_ScheduleWorkRetry

## Zweck und Einsatzfälle

Tokengebundene Retry-/Dead-Letter-Entscheidung nach gespeicherter Queuepolicy. Öffentlicher Einstieg.

## Voraussetzungen

Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Fachlich benötigte WorkItemId bigint des eigenen geclaimten vorhandenen Queueeintrags, unverändert aus der Claim-Ausgabe zusammen mit ClaimToken übernehmen. NULL wird ausdrücklich abgewiesen. Für nicht existierende/negative IDs besitzt der aktuelle Core keinen eigenen positiven Existenzguard; kein erfolgreicher Zustandsübergang ist dadurch belegt. Kein frei gewählter Zahlenwert oder stilles Auflösen des letzten Claims. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wi' + N'rd abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(1000)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Als nvarchar(1000) binden; Breitenkonvertierung vor dem Aufruf ist von der internen Prüfung zu unterscheiden. |
| `@ResultTable` | `sysname` | `NULL` | Input | Taxativ zulässig ist ausschließlich NULL (Default). Diese Version unterstützt kein ResultTable-Routing; jeder nicht-NULL Name wird mit 51989 abgewiesen. Eine Statuszeile wird direkt zurückgegeben. |
| `@KeepData` | `bit` | `0` | Input | bit 0/1/NULL ist als Standardparameter vorhanden, Default 0; mangels ResultTable-Routing in dieser Procedure ohne Wirkung. Kein Append/Replace-Modus für die Queue selbst. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255 oder NULL, Default 0; der aktuelle Retrykern nutzt diesen Parameter nicht für zusätzliche Diagnose-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersatzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL; IDENTITY(1,1), geclusterter' + N' Primärschlüssel |
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
| `RetryBaseDelaySeconds` | `int` | NOT NULL; Default60 |
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
| `LastRequeu' + N'edBy` | `sysname` | NULL |
| `LastRequeueReason` | `nvarchar(1000)` | NULL |
| `BarrierEpoch` | `bigint` | NOT NULL; Default0 |

SELECT * aus VW_WorkQueue:41 Spalten in obiger Reihenfolge. Die reguläre Entscheidung ist RETRY_WAIT oder DEAD_LETTER. Ausgabe liest die aktuelle View nach eigenem Commit; parallele Arbeit kann bereits einen neueren zulässigen Queuezustand zeigen. Kein materialisierter Entscheidungsreceipt. Bei fehlender ID kann leere Ausgabe entstehen. Nur ResultTableNULL zulässig. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;

-- Tatsächliche eigene Claim-ID/Token ersetzen diese synthetischen Werte:
DECLARE @Token uniqueidentifier=''00000000-0000-0000-0000-000000000001'';
EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=1,@ClaimToken=@Token,@FailureCode=''CONTOSO.TRANSIENT'';
-- Kein freier Replaypfad; falsche/nicht vorhandene Bindung ist kein erfolgreicher Übergang.
```

## Rechte

Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. ClaimToken bindet den vorhandenen aktiven Claim; der Code fordert hier keine neue WorkType-Policyentscheidung an. Gehaltene/verwaltete Arbeit verlangt zusätzlich den geschützten Managedabschluss, keinen öffentlichen Bypass. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.

## Ressourcenbedarf

Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Cla' + N'im kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. Retry nutzt ISNULL nur für den Hilfezweig; KeepData/Debug haben im aktuellen Kern keine weitere Wirkung. Die Fassade besitzt eigene frühe Hilfe und delegiert den Fachpfad genau einmal an USP_ScheduleWorkRetryCore; keine zweite fachliche Implementierung. ManagedHold oder eine ManagedReservation ohne geschützte completion_nonce/Transaction-Disposition-AppLock wird vor und nach dem Row Lock abgewehrt. Pflicht-ID/Token/FailureCode und Fehlerdaten prüfen; ResultTable mussNULL sein. Eigener TX bei@@TRANCOUNT0, sonst Savepoint TBX_WorkQueue_Retry. Der Kern liest Status/Token/Lease sowie gespeicherte Attempts-/Backoffpolicy unter UPDLOCK/HOLDLOCK und verlangt CLAIMED/passendesToken/nochaktiveLease.

Bei CycleAttemptCount>=MaxAttempts DEAD_LETTER mit aktuellem/letztem Fehler und DeadLetterzeit/ORIGINAL_LOGIN. Sonst RETRY_WAIT, Claim-/Lease-/Heartbeatfelder löschen und NextAttempt=EngineUTC+min(Base*2^(Attempt-1),Cap), ohne Jitter; LastError und LastRetryScheduled setzen. Keine sofortige Handlerausführung, keine neue Claimgeneration und kein Zurücksetzen des Retryzyklus. Andere History bleibt erhalten. Eigener Commit oder Caller-TX erhalten; CATCH eigener Rollback beziehungsweise committable Savepointrollback.

Der vorhandene Kern hat keinen eigenen positiven Existenz-/StatusISNULL-Guard für eine fehlende WorkItemId und keine abschließende Rowcountprüfung. Bei nicht existierender ID können SQL-NULL-Vergleiche zu keinem UPDATE und leerer Ausgabe führen. Eine implizite0 oder leere Ausgabe beweist deshalb keinen erfolgreichen Retry. Ausschließlich die tatsächliche eig' + N'ene Claim-ID/Token verwenden. Unter Caller-TX können ursprüngliche SAVEPOINT-/Enginefehler auftreten; keinen pauschalen öffentlichen Caller-TX-Verbotsguard behaupten.

Der direkte SELECT auf VW_WorkQueue erfolgt nach eigenem Commit und wird nicht vorher als Ergebnisreceipt materialisiert. Unter paralleler Arbeit kann er einen neueren Zustand sehen. In einem weiterlaufenden Caller-TX ist dagegen noch kein äußerer Commit durch diesen Helper bewiesen. Die Zeile und eine0 ersetzen keinen gebundenen Commit-/Retrynachweis.

## Fehlerbehandlung

54201 geschützter Managed-/Holdpfad verletzt;51985 ID/Token/CodeNULL;51986 ungültiger Code oder Messagebreite;51989 nichtNULLResultTable;51987 nichtaktiver Status/Token/Lease nach dem vorhandenen NULL-Vergleich. Fehlende IDs werden nicht durch einen separaten positiven Existenzguard abgewiesen; leere Ausgabe ist kein Retrybeweis. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarchar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
    EXEC toolbelt_core.USP_ScheduleWorkRetryCore @WorkItemId=@WorkItemId,@ClaimToken=@ClaimToken,@FailureCode=@FailureCode,@FailureMessage=@FailureMessage,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
    RETURN 0;
END;
GO
