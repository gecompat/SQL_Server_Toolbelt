SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_CurrentExecutionContext]()
RETURNS TABLE
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-tvf-currentexecutioncontext"
-- description: "Liest den aktuellen Toolbelt-Ausführungskontext als relationale null- oder einzeilige Projektion; geeigneter Einstieg für APPLY und Diagnose."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.execution-context"
-- schema_name: "toolbelt_core"
-- object_name: "TVF_CurrentExecutionContext"
-- object_type: "TVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.execution-context/Source/TVF_CurrentExecutionContext.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # TVF_CurrentExecutionContext
--
-- ## Zweck und Einsatzfälle
--
-- Liest den aktuellen Toolbelt-Ausführungskontext als relationale null- oder einzeilige Projektion; geeigneter Einstieg für APPLY und Diagnose.
--
-- ## Voraussetzungen
--
-- Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.
--
-- ## Parameter und Zugriff
--
-- Keine Aufrufparameter; die aktuelle Verbindung ist der Datenkontext.
--
-- ## Ergebnisse
--
-- Null oder genau eine Zeile: ExecutionId uniqueidentifier, CorrelationId uniqueidentifier, Actor nvarchar(256), Tenant nvarchar(256), StartedAtUtc datetime2(7), ScopeDepth int. Nur eine per TRY_CONVERT lesbare nicht-NULL ExecutionId erzeugt eine Zeile. Fehlende/ungültige übrige Werte können NULL sein, Textwerte werden auf 256 und der Zeittext vor Konvertierung auf 33 Zeichen gebunden. Keine Vollständigkeits-/Konsistenzprüfung der sechs Keys. Ohne gültige ID bleiben vorhandene andere Keys unsichtbar; OUTER APPLY erhält dann die Callerzeile, CROSS APPLY nicht.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
-- -- Ohne gültige aktive ExecutionId: keine Zeile.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf dieser TVF im tatsächlichen Datenbankkontext und vorhandene Rechte der internen Abhängigkeitskette. Keine Rechteerteilung, kein Serverstatus-/fremder-Session-Zugriff und kein EXECUTE-AS-Wechsel. Bestehende Enginegrenzen für SESSION_CONTEXT bleiben wirksam; Kontextlabels verleihen keine Berechtigung.
--
-- ## Ressourcenbedarf
--
-- Inline-TVF mit fester Anzahl Sessionwert-/Konvertierungsausdrücke; keine eigenen Schleifen oder Temp-Objekte. Optimizer kann Ausdrücke mehrfach auswerten; keine Zusage genau eines physischen Keylesens oder bestimmter Parallelitäts-/Planqualität.
--
-- ## Nebenwirkungen
--
-- Nur SESSION_CONTEXT lesen, keine Änderungen. Nicht deterministisch bezüglich wechselndem Sessionzustand, keine persistenten Resultate oder Snapshotgarantie bei parallelen Änderungen.
--
-- ## Fehlerbehandlung
--
-- TRY_CONVERT bildet fehlende/nicht parsebare IDs, Tiefe oder Zeit auf NULL beziehungsweise keine Zeile ab. Explizit unzulässige Konvertierungen, Engine-/Sessionfehler werden nicht allgemein abgefangen; kein fachlicher THROW-Code und keine Statusspalte.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag. Keine neue native Skill-/Callerzustandsabnahme aus passiven Beschreibungen ableiten; historische Fachbelege nur bei passender Bindung verwenden. Actor/Tenant und sämtliche SESSION_CONTEXT-Werte sind callerbeeinflussbare Metadaten, keine Authentifizierung, Mandantentrennung oder Sicherheitsgrenze. Kein automatischer Kontexttransport in andere Verbindungen und keine Garantie gegen fremde direkte Keyänderungen oder Pooling-/MARS-Effekte.
-- OBJECT_USAGE_SKILL:END
AS
RETURN
(
    SELECT
          TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id')) AS ExecutionId
        , TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.correlation_id')) AS CorrelationId
        , CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.actor')) AS Actor
        , CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.tenant')) AS Tenant
        , TRY_CONVERT(datetime2(7), CONVERT(nvarchar(33), SESSION_CONTEXT(N'toolbelt.execution.started_at_utc')), 126) AS StartedAtUtc
        , TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth')) AS ScopeDepth
    WHERE TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id')) IS NOT NULL
);
GO
