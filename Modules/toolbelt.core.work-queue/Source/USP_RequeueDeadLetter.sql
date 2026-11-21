SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RequeueDeadLetter]
      @WorkItemId bigint=NULL,@ExpectedRowVersion binary(8)=NULL,@RequeueReason nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-requeuedeadletter"
-- description: "Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_RequeueDeadLetter"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung."}, {"name": "@RequeueReason", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_RequeueDeadLetter.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- ---
--
-- # USP_RequeueDeadLetter
--
-- ## Zweck und Einsatzfälle
--
-- Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.
--
-- ## Voraussetzungen
--
-- Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Aktuell DEAD_LETTER, nicht gehalten und nicht Managed. Aktuelle RowVersion für optionales CAS; NULL deaktiviert CAS. Keine freie Freigabe unbekannter Ownership. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt. |
-- | `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung. |
-- | `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
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
-- Eine Zeile bei erfolgreichem Übergang. 41 Viewspalten; ohne ResultTable live nach Commit gelesen. ResultTable=NULL liefert den direkten Fachresultset; sonst Routing in das lokale Callerziel über PrepareResultTable ohne zusätzlichen Fach-SELECT. Keine Payload, ClaimToken oder privaten Managedtokens in der Ausgabe. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). RETURN0 vor Fachzugriff; normaler Return ebenfalls 0, bei Requeue implizit.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;
--
-- -- Synthetische ID/RowVersion durch das eigene tatsächliche DEAD_LETTER-Item ersetzen.
-- EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=1,
--  @ExpectedRowVersion=0x0000000000000001,@RequeueReason=N'Contoso: Ursache behoben';
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
-- NOCOUNT ON und XACT_ABORT OFF vor früher Hilfe. Keine Callertransaktion; ManagedHold oder ManagedReservation werden vor und unter dem Lock abgewiesen. Positive ID ist erforderlich. EngineUTC wird vor der Transaktion erfasst. Eigene Transaktion; optionales ResultTable vor Itemprüfung vorbereiten. SchedulerId=1 mit UPDLOCK/HOLDLOCK lesen, ohne eigenen Seed-Existenzguard. WorkItem mit UPDLOCK/HOLDLOCK im Status DEAD_LETTER und optional passender ExpectedRowVersion lesen; fehlt die passende Mode, folgt 51991. Kein WorkType-Aktivitäts-, Handler-, ENQUEUE- oder CLAIM-Policyfilter.
--
-- UPDATE beginnt RetryCycleNumber+1, setzt CycleAttemptCount=0 und NextAttemptAtUtc=NULL. Status ist QUEUED für SHARED oder BARRIER_WAIT für DRAIN_BARRIER. Claim-/Lease-/Heartbeat-/Failed-/DeadLetterfelder werden gelöscht. LastRequeuedAtUtc/ORIGINAL_LOGIN und der gebundene freie Reason werden gespeichert. ClaimGeneration, RecoveryCount, gespeicherte Policy, IdempotencyKey und LastErrorhistorie bleiben erhalten. BarrierEpoch wird nur für eine Barrier erhöht. Neue Blockersnapshots erfassen bereits CLAIMED Items derselben Gruppe, außer Barriers gleicher Priority; alte Epochsnapshots bleiben gespeichert. Kein Claim oder Handlerstart.
--
-- Mit ResultTable werden die 41 Spalten innerhalb der Transaktion materialisiert und geroutet. COMMIT, im CATCH eigener ROLLBACK. Ohne Ziel folgt SELECT * aus VW_WorkQueue nach Commit: live Ausgabe, kein materialisierter Entscheidungsreceipt. Ein konkurrierender Claim kann bereits einen neueren Status zeigen. Keine eigene Debug-Message; Debug/KeepData werden nur bei vorhandenem Ziel an den Helper übergeben. Kein eigener expliziter normaler RETURN; die implizite 0 beweist keinen Handlererfolg.
--
-- ## Fehlerbehandlung
--
-- 51993: Caller-TX/XACT_STATE nicht 0. 54201/1: früher Managed-/Holdguard; /2: Guard unter Lock. 51990: ID NULL/nicht positiv. 51991: Item fehlt, ist nicht DEAD_LETTER oder RowVersion weicht ab. 51908: ResultTablehelper fehlt. Kein separater Fehlercode für CAS-Abweichung. Ursprüngliche Engine-, Constraint-, Konvertierungs-, Helper-, Sperr-, Deadlock- und Rollbackfehler bleiben sichtbar. Keine automatische Wiederholung. Spätere Message-/Ergebnistransportfehler können einen eigenen bereits ausgeführten Commit nicht zurücknehmen.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Konkurrenz-/Lease-/Recoveryabnahme. Historische Nachweise behalten ihre Artefaktbindung. Kein Exactly-once, Prozess-KILL oder Nachweis für Hostausfall/Koordinatorverlust. Die Claim-/Leasevoraussetzungen gelten für über öffentliche APIs wohlgeformte Items, nicht als Reparaturvertrag für manipulierte interne Tabellen. Keine automatische Secretredaktion; Reason, Fehlertexte und Runtimebefunde privat halten. Keine Installations- oder Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1
 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RequeueDeadLetter' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus. Callertransaktionen sind nicht erlaubt; verwaltete/gehaltene Arbeit benötigt den geschützten Freigabepfad.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51908,51990-51993', NULL, NULL, NULL, NULL, CAST(N'Fehlende ResultTable-Dependency, ungültige ID, nicht requeuebarer Zustand oder Callertransaktion.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE und die vorgesehenen Queue-Autorisierungen; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Bei Fehlern entsteht keine fachliche Statuszeile. Managed-Holds benötigen den geschützten Freigabepfad.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Requeue eines Dead-Letter-Items mit Rowversion-Schutz.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=42,@ExpectedRowVersion=0x0000000000000001;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'WorkItemId', N'bigint', 0, 0, NULL, CAST(N'Eindeutige Queue-ID.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', 0, 0, NULL, CAST(N'Kanonischer Work-Type-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'Status', N'varchar(16)', 0, 0, NULL, CAST(N'QUEUED, CLAIMED, COMPLETED oder FAILED.' AS nvarchar(max)), NULL),
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
        (N'PARAMETER', 1, N'@WorkItemId', N'bigint', 1, 0, N'NULL', CAST(N'Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@ExpectedRowVersion', N'binary(8)', 0, 1, N'NULL', CAST(N'Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@RequeueReason', N'nvarchar(1000)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_RequeueDeadLetter' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-requeuedeadletter"
description: "Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_RequeueDeadLetter"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung."}, {"name": "@RequeueReason", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert de' AS nvarchar(max)) + N'n fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_RequeueDeadLetter.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
s' + N'ource_module_version: "2.1.0"
---

# USP_RequeueDeadLetter

## Zweck und Einsatzfälle

Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.

## Voraussetzungen

Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Aktuell DEAD_LETTER, nicht gehalten und nicht Managed. Aktuelle RowVersion für optionales CAS; NULL deaktiviert CAS. Keine freie Freigabe unbekannter Ownership. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung. |
| `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten e' + N'inschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

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
| `Cl' + N'aimGeneration` | `bigint` | NOT NULL; Default0 |
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
| `LastRequeuedBy` | `sysname` | NULL |
| `LastRequeueReason` | `nvarchar(1000)` | NULL |
| `BarrierEpoch` | `bigint` | NOT NULL; Default0 |

Eine Zeile bei erfolgreichem Übergang. 41 Viewspalten; ohne ResultTable live nach Commit gelesen. ResultTable=NULL liefert den direkten Fachresultset; sonst Routing in das lokale Callerziel über PrepareResultTable ohne zusätzlichen Fach-SELECT. Keine Payload, ClaimToken oder privaten Managedtokens in der Ausgabe. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). RETURN0 vor Fachzugriff; normaler Return ebenfalls 0, bei Requeue im' + N'plizit.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;

-- Synthetische ID/RowVersion durch das eigene tatsächliche DEAD_LETTER-Item ersetzen.
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=1,
 @ExpectedRowVersion=0x0000000000000001,@RequeueReason=N''Contoso: Ursache behoben'';
```

## Rechte

Vorhandenes EXECUTE auf den öffentlichen Einstieg, passender Datenbankzugriff und Identitätsmapping für zentrale Dreiteilnamen. Keine Rechtevergabe aus dem Skill ableiten. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Kein eigener WorkType-ENQUEUE-/CLAIM-/Handler-EXECUTEguard; die Berechtigung für diesen Supervisor-, Completion- oder Heartbeatweg gezielt vergeben. Keine Besitzer- oder Mandantentrennung allein durch diesen Aufruf. ResultTable braucht ein vorhandenes zulässiges lokales #Ziel und Helper-/Temp-DDL-/INSERT-Rechte; keine pauschale Serverrolle.

## Ressourcenbedarf

Private Ergebnistabellen in tempdb, Item-/Scheduler-/Indexlocks, Log-/Speicherbedarf und Sperrkonkurrenz. Recovery mit READPAST kann gesperrte Items überspringen. MaxItems ist keine CPU-, Heap-, Log- oder Gesamtlaufzeitquote. Barrierrequeue erzeugt Blockersnapshots nach Gruppenbreite. Kein eigener Timeout-/Retryloop oder Host-/VM-Eingriff. Zählerüberläufe bleiben Enginefehler.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF vor früher Hilfe. Keine Callertransaktion; ManagedHold oder ManagedReservation werden vor und unter dem Lock abgewiesen. Positive ID ist erforderlich. EngineUTC wird vor der Transaktion erfasst. Eigene Transaktion; optionales ResultTable vor Itemprüfung vorbereiten. SchedulerId=1 mit UPDLOCK/HOLDLOCK lesen, ohne eigenen Seed-Existenzguard. WorkItem mit UPDLOCK/HOLDLOCK im Status DEAD_LETTER und optional passender ExpectedRowVersion lesen; fehlt die passende Mode, folgt 51991. Kein WorkType-Aktivitäts-, Handler-, ENQUEUE- oder CLAIM-Policyfilter.

UPDATE beginnt RetryCycleNumber+1, setzt CycleAttemptCount=0 und NextAttemptAtUtc=NU' + N'LL. Status ist QUEUED für SHARED oder BARRIER_WAIT für DRAIN_BARRIER. Claim-/Lease-/Heartbeat-/Failed-/DeadLetterfelder werden gelöscht. LastRequeuedAtUtc/ORIGINAL_LOGIN und der gebundene freie Reason werden gespeichert. ClaimGeneration, RecoveryCount, gespeicherte Policy, IdempotencyKey und LastErrorhistorie bleiben erhalten. BarrierEpoch wird nur für eine Barrier erhöht. Neue Blockersnapshots erfassen bereits CLAIMED Items derselben Gruppe, außer Barriers gleicher Priority; alte Epochsnapshots bleiben gespeichert. Kein Claim oder Handlerstart.

Mit ResultTable werden die 41 Spalten innerhalb der Transaktion materialisiert und geroutet. COMMIT, im CATCH eigener ROLLBACK. Ohne Ziel folgt SELECT * aus VW_WorkQueue nach Commit: live Ausgabe, kein materialisierter Entscheidungsreceipt. Ein konkurrierender Claim kann bereits einen neueren Status zeigen. Keine eigene Debug-Message; Debug/KeepData werden nur bei vorhandenem Ziel an den Helper übergeben. Kein eigener expliziter normaler RETURN; die implizite 0 beweist keinen Handlererfolg.

## Fehlerbehandlung

51993: Caller-TX/XACT_STATE nicht 0. 54201/1: früher Managed-/Holdguard; /2: Guard unter Lock. 51990: ID NULL/nicht positiv. 51991: Item fehlt, ist nicht DEAD_LETTER oder RowVersion weicht ab. 51908: ResultTablehelper fehlt. Kein separater Fehlercode für CAS-Abweichung. Ursprüngliche Engine-, Constraint-, Konvertierungs-, Helper-, Sperr-, Deadlock- und Rollbackfehler bleiben sichtbar. Keine automatische Wiederholung. Spätere Message-/Ergebnistransportfehler können einen eigenen bereits ausgeführten Commit nicht zurücknehmen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Konkurrenz-/Lease-/Recoveryabnahme. Historische Nachweise behalten ihre Artefaktbindung. Kein Exactly-once, Prozess-KILL oder Nachweis für Hostausfall/Koordinatorverlust. Die Claim-/Leasevoraussetzungen gelten für über öffentliche APIs wohlgeformte Items, nicht als Re' + N'paraturvertrag für manipulierte interne Tabellen. Keine automatische Secretredaktion; Reason, Fehlertexte und Runtimebefunde privat halten. Keine Installations- oder Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51993,N'USP_RequeueDeadLetter darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND (ManagedHold=1 OR ManagedReservationId IS NOT NULL))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
 IF @WorkItemId IS NULL OR @WorkItemId<=0 THROW 51990,N'@WorkItemId ist erforderlich.',1;
 DECLARE @Now datetime2(7)=SYSUTCDATETIME(),@Mode varchar(16),@Group varchar(128),@Priority tinyint,@Epoch bigint,@InsertResultSql nvarchar(max);
 SELECT TOP (0) v.* INTO #tbx_WorkQueue_RequeueResult FROM toolbelt_core.VW_WorkQueue AS v;
 BEGIN TRANSACTION;
 BEGIN TRY
  IF @ResultTable IS NOT NULL
  BEGIN
   IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51908,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
   EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_RequeueResult',@KeepData=@KeepData,@Debug=@Debug;
  END;
  DECLARE @SchedulerId tinyint; SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
  SELECT @Mode=ExecutionMode,@Group=ExecutionGroup,@Priority=Priority,@Epoch=BarrierEpoch FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND Status='DEAD_LETTER' AND (@ExpectedRowVersion IS NULL OR RowVersion=@ExpectedRowVersion);
  IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND (ManagedHold=1 OR ManagedReservationId IS NOT NULL)) THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Freigabepfad.',2;
  IF @Mode IS NULL THROW 51991,N'Das Item ist nicht requeuebar.',1;
  SET @Epoch=CASE WHEN @Mode='DRAIN_BARRIER' THEN @Epoch+1 ELSE @Epoch END;
  UPDATE toolbelt_core.WorkItem SET Status=CASE WHEN @Mode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,RetryCycleNumber=RetryCycleNumber+1,CycleAttemptCount=0,NextAttemptAtUtc=NULL,BarrierEpoch=@Epoch,ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL,LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL,FailedAtUtc=NULL,FailedBy=NULL,FailureCode=NULL,FailureMessage=NULL,DeadLetteredAtUtc=NULL,DeadLetteredBy=NULL,LastRequeuedAtUtc=@Now,LastRequeuedBy=ORIGINAL_LOGIN(),LastRequeueReason=@RequeueReason WHERE WorkItemId=@WorkItemId;
  IF @Mode='DRAIN_BARRIER' INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration) SELECT @WorkItemId,@Epoch,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@Group AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
  IF @ResultTable IS NOT NULL
  BEGIN
   INSERT #tbx_WorkQueue_RequeueResult SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
   SET @InsertResultSql=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' SELECT * FROM #tbx_WorkQueue_RequeueResult;';
   EXEC sys.sp_executesql @InsertResultSql;
  END;
  COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
END;
GO
