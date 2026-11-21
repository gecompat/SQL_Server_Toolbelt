SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_core].[SVF_CurrentExecutionId]()
RETURNS uniqueidentifier
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-svf-currentexecutionid"
-- description: "Skalarer Komfortzugriff auf die ID des aktuellen Ausführungskontexts; relationaler Kern ist TVF_CurrentExecutionContext."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.execution-context"
-- schema_name: "toolbelt_core"
-- object_name: "SVF_CurrentExecutionId"
-- object_type: "SVF"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: []
-- source_paths: ["Modules/toolbelt.core.execution-context/Source/SVF_CurrentExecutionId.sql", "Modules/toolbelt.core.execution-context/Source/TVF_CurrentExecutionContext.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # SVF_CurrentExecutionId
--
-- ## Zweck und Einsatzfälle
--
-- Skalarer Komfortzugriff auf die ID des aktuellen Ausführungskontexts; relationaler Kern ist TVF_CurrentExecutionContext.
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
-- Ein uniqueidentifier-Rückgabewert oder SQL NULL. Der Wrapper liest ExecutionId aus der TVF; wenn diese keine Zeile liefert, bleibt die lokale Variable NULL. Kein eigener Resultset und keine OUTPUT-Parameter.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT toolbelt_core.SVF_CurrentExecutionId() AS ExecutionId;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser Prozedur/Funktion im tatsächlichen Datenbankkontext und vorhandene Rechte der internen Abhängigkeitskette. Keine Rechteerteilung, kein Serverstatus-/fremder-Session-Zugriff und kein EXECUTE-AS-Wechsel. Bestehende Enginegrenzen für SESSION_CONTEXT bleiben wirksam; Kontextlabels verleihen keine Berechtigung.
--
-- ## Ressourcenbedarf
--
-- Skalarer T-SQL-Wrapper über eine null-/einzeilige TVF, keine eigene zusätzliche Datenquelle oder Cache. Keine pauschale Zusage skalaren Inlinings oder bestimmter Plankosten.
--
-- ## Nebenwirkungen
--
-- Rein lesend über den relationalen Sessionkontextkern, kein Session-/Datenbankzustand wird geschrieben.
--
-- ## Fehlerbehandlung
--
-- Kein eigener Validierungs- oder THROW-Code; fehlender Kontext ergibt NULL. Konvertierungs-/Enginefehler des relationalen Kerns bleiben sichtbar.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag. Keine neue native Skill-/Callerzustandsabnahme aus passiven Beschreibungen ableiten; historische Fachbelege nur bei passender Bindung verwenden. Actor/Tenant und sämtliche SESSION_CONTEXT-Werte sind callerbeeinflussbare Metadaten, keine Authentifizierung, Mandantentrennung oder Sicherheitsgrenze. Kein automatischer Kontexttransport in andere Verbindungen und keine Garantie gegen fremde direkte Keyänderungen oder Pooling-/MARS-Effekte.
-- OBJECT_USAGE_SKILL:END
AS
BEGIN
    DECLARE @ExecutionId uniqueidentifier;
    SELECT @ExecutionId = c.ExecutionId
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;
    RETURN @ExecutionId;
END;
GO
