SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW [toolbelt_core].[VW_WorkQueueBarrierBlockers]
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-vw-workqueuebarrierblockers"
-- description: "Öffentliche Barrier-Snapshotprojektion mit aktuellem Claimgenerationsvergleich."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "VW_WorkQueueBarrierBlockers"
-- object_type: "VIEW"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/VW_WorkQueueBarrierBlockers.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- ---
--
-- # VW_WorkQueueBarrierBlockers
--
-- ## Zweck und Einsatzfälle
--
-- Öffentliche Barrier-Snapshotprojektion mit aktuellem Claimgenerationsvergleich. Vorgesehener Leseweg, keine fachliche Mutation über diese View.
--
-- ## Voraussetzungen
--
-- SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170, lokal oder zentral in der Moduldatenbank; WorkType- und Queue-Objekte installiert. Keine CLR-/Datei-/Netzwerkabhängigkeit dieser Relation. Der aktuelle gemeinsame Installer ist markerfrei/create-only; keine eigenständige Ausführung alter Upgradezweige oder automatische Reparatur aus diesem Skill. Bestehende Objekte werden erhalten, daher setzt der hier beschriebene Vertrag eine passende aktuelle Definition voraus.
--
-- ## Parameter und Zugriff
--
-- Keine Aufrufparameter, Defaults, OUTPUT-Parameter oder ResultTable-Option. SELECT mit eigenem Filter auf BarrierWorkItemId/BarrierEpoch und ORDER BY. Sechs Felder in aufgeführter Reihenfolge. Lesen erfasst keine neuen Blocker und verändert keinen Snapshot.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Regeln/Bedeutung |
-- |---|---|---|
-- | `BarrierWorkItemId` | `bigint` | NOT NULL; FK WorkItem, Barrierauftrag |
-- | `BarrierEpoch` | `bigint` | NOT NULL; Snapshotepoch |
-- | `BlockingWorkItemId` | `bigint` | NOT NULL; FK WorkItem, Blockerauftrag |
-- | `BlockingClaimGeneration` | `bigint` | NOT NULL; erfasste Claimgeneration |
-- | `CapturedAtUtc` | `datetime2(7)` | NOT NULL; Default SYSUTCDATETIME() |
-- | `IsResolved` | `bit` | 0 genau wenn Blocking-WorkItem weiterhin CLAIMED mit erfasster Generation ist; sonst1 |
--
-- Inner Join des gespeicherten Blockersnapshots mit dem blockierenden WorkItem. Keine zusätzliche Prüfung des Barrierauftrags, seiner aktuellen Epoch oder seines Status. IsResolved vergleicht ausschließlich Status CLAIMED und Claimgeneration: auch eine bereits abgelaufene Lease bleibt bei unverändertem Claim unresolved. 1 beweist keinen erfolgreichen fachlichen Abschluss; Requeue, Failure oder Generationwechsel können ebenfalls auflösen. Fehlendes Joinziel erscheint nicht; regulär schützt der FK. Keine Payload/Claim-/Admissiontokens in dieser View, keine automatische Snapshotbereinigung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration,IsResolved
-- FROM toolbelt_core.VW_WorkQueueBarrierBlockers
-- ORDER BY BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId;
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
SELECT b.BarrierWorkItemId,b.BarrierEpoch,b.BlockingWorkItemId,b.BlockingClaimGeneration,b.CapturedAtUtc,
       CONVERT(bit,CASE WHEN wi.Status='CLAIMED' AND wi.ClaimGeneration=b.BlockingClaimGeneration THEN 0 ELSE 1 END) AS IsResolved
FROM toolbelt_core.WorkQueueBarrierBlocker b
JOIN toolbelt_core.WorkItem wi ON wi.WorkItemId=b.BlockingWorkItemId;
GO
