SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW [toolbelt_core].[VW_Events]
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-event-log-vw-events"
-- description: "Öffentliche ungefilterte Projektion aller persistierten Ereignis- und Auditspalten."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.event-log"
-- schema_name: "toolbelt_core"
-- object_name: "VW_Events"
-- object_type: "VIEW"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.event-log/Source/VW_Events.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # VW_Events
--
-- ## Zweck und Einsatzfälle
--
-- Öffentliche ungefilterte Projektion aller persistierten Ereignis- und Auditspalten. Analyse der eigenen strukturierten Ereignisse und gezielte Suche nach ExecutionId/CorrelationId, keine Serverdiagnose oder Fehlerdatenmaskierung.
--
-- ## Voraussetzungen
--
-- Installiertes Modul toolbelt.core.event-log in der gewählten Datenbank, SQL2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170. View benötigt die Tabelle. Für das reine SELECT ist keine aktive Second-Session-Verbindung nötig; die getrennte öffentliche Schreibfassade benötigt ihren konfigurierten Second-Session-/Work-Type-/Execution-Context-Vertrag. Kein automatisches Einrichten dieser Infrastruktur.
--
-- ## Parameter und Zugriff
--
-- Keine Aufrufparameter. Anwendungen lesen gezielt über VW_Events und schreiben über USP_WriteEvent; der interne Handler USP_WriteEventInternal ist kein generischer Consumer-Einstieg. Retention ausdrücklich über die passenden Prozeduren nach OccurredAtUtc oder RecordedAtUtc. Direkte privilegierte DML und das einfache Viewlayout können die Fassade umgehen: die View ist der vorgesehene Leseweg, kein technisch erzwungenes SQL-DML-Verbot. Nicht mit Schreibrechten an Lesekonsumenten ausliefern.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | NULL/Generierung |
-- |---|---|---|
-- | `EventId` | `bigint` | IDENTITY(1,1) NOT NULL |
-- | `OccurredAtUtc` | `datetime2(7)` | NOT NULL |
-- | `RecordedAtUtc` | `datetime2(7)` | NOT NULL CONSTRAINT [DF_EventLog_RecordedAtUtc] DEFAULT (SYSUTCDATETIME()) |
-- | `EventName` | `varchar(128)` | COLLATE Latin1_General_100_BIN2 NOT NULL |
-- | `EventLevel` | `varchar(16)` | COLLATE Latin1_General_100_BIN2 NOT NULL |
-- | `Category` | `varchar(128)` | COLLATE Latin1_General_100_BIN2 NULL |
-- | `Message` | `nvarchar(4000)` | NULL |
-- | `DataJson` | `nvarchar(max)` | NULL |
-- | `ExecutionId` | `uniqueidentifier` | NOT NULL |
-- | `CorrelationId` | `uniqueidentifier` | NOT NULL |
-- | `Actor` | `nvarchar(256)` | NULL |
-- | `Tenant` | `nvarchar(256)` | NULL |
-- | `SourceDatabaseName` | `sysname` | NOT NULL |
-- | `SourceSchemaName` | `sysname` | NULL |
-- | `SourceObjectName` | `sysname` | NULL |
-- | `CallerSessionId` | `int` | NOT NULL |
-- | `CallerXactState` | `smallint` | NOT NULL |
-- | `CallerTransactionCount` | `int` | NOT NULL |
-- | `RemoteSessionId` | `int` | NOT NULL |
-- | `ErrorNumber` | `int` | NULL |
-- | `ErrorSeverity` | `int` | NULL |
-- | `ErrorState` | `int` | NULL |
-- | `ErrorProcedure` | `sysname` | NULL |
-- | `ErrorLine` | `int` | NULL |
--
-- Die View projiziert alle 24 Spalten unverändert und ohne Filter, DISTINCT, JOIN oder ORDER BY. Keine Tenant-/Actor-/ExecutionId-Zeilenisolation, Maskierung oder Kürzung. Message/DataJson und Actor/Tenant sowie Session-/Fehlerdaten können sensible Inhalte tragen; SELECT bewusst begrenzen. EventId ist eine datenbanklokale IDENTITY(1,1), keine lückenlose oder serverweit globale Reihenfolge. RecordedAtUtc hat beim Insert den UTC-Serverdefault; OccurredAtUtc ist ein separat zugeführter Ereigniszeitpunkt. Kein automatischer Zeitzonenumrechner. EventName/EventLevel/Category haben Latin1_General_100_BIN2, andere Textspalten keine separat deklarierte Collation.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT TOP (100) EventId,RecordedAtUtc,EventName,EventLevel
-- FROM toolbelt_core.VW_Events
-- ORDER BY RecordedAtUtc DESC,EventId DESC;
-- -- Explizite Reihenfolge; keine ungefilterte Ausgabe von Message/DataJson.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf VW_Events und funktionierende bestehende Ownership-/Abhängigkeitsrechte für die Tabelle. Keine pauschale Empfehlung von direkten EventLog- oder View-Schreibrechten. Direkter Tabellenzugriff ist ein interner administrativer Kontext und sieht dieselben unmaskierten Daten. Zentrale Nutzung erfordert gültige Ziel-DB-Authentifizierung und Rechte; keine automatische Rechteerteilung, Identitätsumschaltung oder Mandantenabgrenzung.
--
-- ## Ressourcenbedarf
--
-- Persistenter unbefristeter Speicher einschließlich nvarchar(max)-Payloads; Tabellen-DDL enthält keine globale Zeilen-/Bytequote. Clustered-PK EventId, Indexe (OccurredAtUtc,EventId), (CorrelationId,OccurredAtUtc) und (ExecutionId,OccurredAtUtc) jeweils mit EventName/EventLevel/Category als INCLUDE bei den letzten beiden, sowie (RecordedAtUtc,EventId). Filter, Sortierung, Selectivität und Caller-Isolation bestimmen Plan, I/O und Sperren. Kein garantierter Seek/Parallelplan/Memory-Grant oder Produktionsdurchsatz, kein automatischer Retentionsjob.
--
-- ## Nebenwirkungen
--
-- SELECT ändert keine Events, legt keine Second Session an und startet keinen Retentionslauf. Normale SQL-Isolation/Sperren gelten; kein NOLOCK oder unabhängiger Snapshot eingebaut. Keine Aufrufparameter. Anwendungen lesen gezielt über VW_Events und schreiben über USP_WriteEvent; der interne Handler USP_WriteEventInternal ist kein generischer Consumer-Einstieg. Retention ausdrücklich über die passenden Prozeduren nach OccurredAtUtc oder RecordedAtUtc. Direkte privilegierte DML und das einfache Viewlayout können die Fassade umgehen: die View ist der vorgesehene Leseweg, kein technisch erzwungenes SQL-DML-Verbot. Nicht mit Schreibrechten an Lesekonsumenten ausliefern.
--
-- ## Fehlerbehandlung
--
-- Keine eigenen Statusresultsets oder Geschäftsfehlercodes an Tabelle/View. Fehlende Objekte, Rechte, Konvertierungs-/Constraint-/Enginefehler bleiben SQL-Fehler. EventName: LEN 3..128, gleich LOWER unter BIN2, beginnt a..z, nur a..z/0..9/Punkt/Unterstrich/Bindestrich. EventLevel-CHECK über TRACE,DEBUG,INFO,WARNING,ERROR,CRITICAL mit SQL-Textvergleich einschließlich dessen Paddingsemantik. DataJson NULL oder ISJSON=1 und LEFT(LTRIM(DataJson),1)=N'{'; dies ist keine beliebige Array-/Skalar-JSON-Schnittstelle und kein allgemeines Entfernen aller JSON-Whitespacezeichen. CallerXactState in -1/0/1; ErrorSeverity NULL oder 0..25, ErrorState NULL oder 0..255, ErrorLine NULL oder >0. Andere fachliche Validierungen der Schreibfassade sind nicht durch zusätzliche Tabellenconstraints garantiert.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag nur dieser Tabelle/View, keine neue Abnahme aller Event-Schreib-/Retentionprozeduren oder der neuen Gesamtinstallation. Historische Nachweise bleiben an ihre ursprünglichen Artefakte gebunden. Bekannte Objektbeschreibung bestätigt weder Installation noch ausreichende Rechte. Die View ist keine redigierte oder sicherheitsgefilterte Auditoberfläche.
-- OBJECT_USAGE_SKILL:END
SELECT
      EventId, OccurredAtUtc, RecordedAtUtc, EventName, EventLevel, Category
    , Message, DataJson, ExecutionId, CorrelationId, Actor, Tenant
    , SourceDatabaseName, SourceSchemaName, SourceObjectName
    , CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId
    , ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine
FROM toolbelt_core.EventLog;
GO
