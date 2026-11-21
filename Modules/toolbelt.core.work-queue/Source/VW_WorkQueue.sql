SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER VIEW [toolbelt_core].[VW_WorkQueue]
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-vw-workqueue"
-- description: "Öffentliche Queue-Statusprojektion ohne PayloadJson, ClaimToken und Managedtoken."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "VW_WorkQueue"
-- object_type: "VIEW"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- ---
--
-- # VW_WorkQueue
--
-- ## Zweck und Einsatzfälle
--
-- Öffentliche Queue-Statusprojektion ohne PayloadJson, ClaimToken und Managedtoken. Vorgesehener Leseweg, keine fachliche Mutation über diese View.
--
-- ## Voraussetzungen
--
-- SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.
--
-- ## Parameter und Zugriff
--
-- Keine Parameter, Defaults oder OUTPUT-Parameter. SELECT mit eigenen Filtern/ORDER BY. Die41 Felder stehen in der aufgeführten Reihenfolge; keine garantierte Sortierung, Pagination, MaxItems- oder ResultTable-Option. Für gezielten Status auch USP_GetWorkStatus verwenden.
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
-- Inner Join WorkItem zu WorkType über WorkTypeId; kein Filter auf WorkType.IsEnabled oder Status und keine Caller-/Owner-/Policyzeilenfilterung. Bei durchgesetztem FK passt jeder vorhandene WorkItem; abweichende/fremde Definitionen werden von der View nicht repariert. IsLeaseExpired ist ein lesender Vergleich mit aktueller Engine-UTC-Zeit, kein Recovery oder Tokenwiderruf. NULL-Lease, terminaler Status oder anderer Status ergibt0. Kein Snapshot einer gesamten Workertransaktion und keine Garantie, dass gelesener Status nach dem SELECT noch aktuell ist. IdempotencyKey sowie ManagedReservationId,ManagedHold,ManagedCompletionNonce und WorkTypeId fehlen ebenfalls in der View.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT WorkItemId,WorkTypeName,Status,IsLeaseExpired
-- FROM toolbelt_core.VW_WorkQueue ORDER BY WorkItemId;
-- ```
--
-- ## Rechte
--
-- SELECT auf diese View; bei zentralem Dreiteilaufruf vorhandener Datenbankzugriff/Identitätsmapping. Keine automatische Rechtevergabe oder Policyfilterung. Nicht mit SELECT auf den internen Tabellen verwechseln; Ownership-Chaining und tatsächlich vorhandene Rechte bestimmen den Enginezugriff. Kein EXECUTE/Hilfeparameter für die View.
--
-- ## Ressourcenbedarf
--
-- Persistente Queuegröße, Indizes, Join-/Filterplan und konkurrierende Sperren bestimmen den Aufwand. Keine implementierte Maximalzeilen-, Byte-, CPU-, Speicher- oder Laufzeitquote dieser Relation. Begrenzte Feldtypen schützen keine unbegrenzte Auftragsanzahl; kein automatischer Retentions-/Purgeauftrag. Sperren, Log-/tempdb-/Speicherdruck und Timeouts bleiben möglich.
--
-- ## Nebenwirkungen
--
-- SELECT führt keine DML, Claims, Leaseverlängerung, Recovery, Rechtevergabe oder eigene Transaktionen aus. Der vorgesehene Leseweg ist keine zusätzliche DML-Sicherheitsschranke: vorhandene UPDATE-Rechte und SQL-Viewregeln können andere Operationen ermöglichen; keine solchen Rechte aus diesem Skill ableiten.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen THROW-/Validierungscodes. Keine passenden Zeilen ergibt leeres Resultset. Fehlende Rechte/Abhängigkeiten, ungültige eigene Filter oder technische SQL-Fehler bleiben Enginefehler. Lesende Statusflags ersetzen keinen erfolgreichen verändernden API-Aufruf.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Objektvertrag, keine neue native Skill-/Installer-/Minimalrechte-/Recoveryabnahme. Historische unveränderte Fachbelege behalten ausschließlich ihre ursprüngliche Bindung. Kein Exactly-once-, Atomizitäts- oder vollständiger Worker-Recoverynachweis allein durch gespeicherte Statuswerte. Personen-/Payload-/Fehlerdaten privat behandeln; keine Installation, Rechte oder gesunde Gesamtkonfiguration attestieren.
-- OBJECT_USAGE_SKILL:END
    SELECT
          wi.WorkItemId
        , wt.WorkTypeName
        , wi.Status
        , wi.EnqueuedAtUtc
        , wi.EnqueuedBy
        , wi.ClaimedAtUtc
        , wi.ClaimedBy
        , wi.CompletedAtUtc
        , wi.CompletedBy
        , wi.FailedAtUtc
        , wi.FailedBy
        , wi.FailureCode
        , wi.FailureMessage
        , CONVERT(binary(8), wi.RowVersion) AS RowVersion
        , wi.ClaimGeneration
        , wi.LeaseDurationSeconds
        , wi.LeaseUntilUtc
        , wi.LastHeartbeatAtUtc
        , CONVERT
          (
              bit,
              CASE
                  WHEN wi.Status = 'CLAIMED' AND wi.LeaseUntilUtc <= SYSUTCDATETIME() THEN 1
                  ELSE 0
              END
          ) AS IsLeaseExpired
        , wi.RecoveryCount
        , wi.LastRecoveredAtUtc
        , wi.LastRecoveredBy
        , wi.ExecutionGroup
        , wi.Priority
        , wi.ExecutionMode
        , wi.MaxAttempts
        , wi.RetryBaseDelaySeconds
        , wi.RetryMaxDelaySeconds
        , wi.RetryCycleNumber
        , wi.CycleAttemptCount
        , wi.NextAttemptAtUtc
        , wi.LastErrorCode
        , wi.LastErrorMessage
        , wi.LastRetryScheduledAtUtc
        , wi.LastRetryScheduledBy
        , wi.DeadLetteredAtUtc
        , wi.DeadLetteredBy
        , wi.LastRequeuedAtUtc
        , wi.LastRequeuedBy
        , wi.LastRequeueReason
        , wi.BarrierEpoch
    FROM toolbelt_core.WorkItem AS wi
    JOIN toolbelt_core.WorkType AS wt
      ON wt.WorkTypeId = wi.WorkTypeId;
GO
