SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_BeginExecution]
(
      @ExecutionId   uniqueidentifier = NULL OUTPUT
    , @CorrelationId uniqueidentifier = NULL
    , @Actor         nvarchar(256)    = NULL
    , @Tenant        nvarchar(256)    = NULL
    , @AllowNested   bit              = 1
    , @Debug         tinyint          = 0
    , @Hilfe         bit              = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-beginexecution"
-- description: "Beginnt einen Toolbelt-Ausführungskontext in dieser Verbindung oder erhöht seine ScopeDepth bei zulässiger Verschachtelung."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.execution-context"
-- schema_name: "toolbelt_core"
-- object_name: "USP_BeginExecution"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt."}, {"name": "@AllowNested", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten."}]
-- source_paths: ["Modules/toolbelt.core.execution-context/Source/USP_BeginExecution.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_BeginExecution
--
-- ## Zweck und Einsatzfälle
--
-- Beginnt einen Toolbelt-Ausführungskontext in dieser Verbindung oder erhöht seine ScopeDepth bei zulässiger Verschachtelung.
--
-- ## Voraussetzungen
--
-- Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@ExecutionId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben. |
-- | `@CorrelationId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen. |
-- | `@Actor` | `nvarchar(256)` | `NULL` | Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
-- | `@Tenant` | `nvarchar(256)` | `NULL` | Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
-- | `@AllowNested` | `bit` | `1` | Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |
--
-- ## Ergebnisse
--
-- Kein fachlicher Resultset. RETURN 0 bei Erfolg; @ExecutionId ist INPUT/OUTPUT und enthält die gewählte aktive ID. Ohne gültige aktuelle ID wird die übergebene ID oder NEWID verwendet, CorrelationId standardmäßig gleichgesetzt, Zeit neu erfasst und Tiefe 1 gesetzt. Im Nested-Pfad bleibt die ID gleich und nur die Tiefe wächst; vorhandene Correlation-/Actor-/Tenant-Werte und Startzeit werden nicht neu geschrieben. Bei Hilfe keine Änderung des bereits übergebenen OUTPUT-Werts. Hilfe=1 liefert stattdessen bisherige Standardhilfe und genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); RETURN 0 vor fachlichen Kontextzugriffen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Eigene Sitzung ohne vorher aktiven Context verwenden.
-- DECLARE @Id uniqueidentifier;
-- EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Actor=N'Contoso example';
-- SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
-- EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- -- Hilfe liest/schreibt keinen Context und erhält einen vorhandenen OUTPUT-Wert:
-- EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser Prozedur/Funktion im tatsächlichen Datenbankkontext und vorhandene Rechte der internen Abhängigkeitskette. Keine Rechteerteilung, kein Serverstatus-/fremder-Session-Zugriff und kein EXECUTE-AS-Wechsel. Bestehende Enginegrenzen für SESSION_CONTEXT bleiben wirksam; Kontextlabels verleihen keine Berechtigung.
--
-- ## Ressourcenbedarf
--
-- Feste Anzahl Keylese-/Schreibaufrufe, begrenzte Labels nvarchar(256) und ISO-Zeittext nvarchar(33). Tiefe nach regulärem Begin maximal 32767; kein persistenter Stack mit gespeicherten Vorgängerwerten. Die Engine verwaltet Sessionkontextspeicher, kein eigener Heap-/Laufzeitvertrag.
--
-- ## Nebenwirkungen
--
-- Root schreibt die sechs Sessionkeys sequentiell, Nested nur depth. Keine eigene Transaktion, keine Kompensations-/Rollbackklammer und kein automatisches End bei Fehlern. Ein späterer Schreibfehler kann nach bereits erfolgreichen Keyänderungen auftreten; kein atomarer Mehrkey-Vertrag. Debug>0 erzeugt erst nach erfolgreichem Fachpfad eine abstrakte Severity-10-Nachricht WITH NOWAIT ohne Payload.
--
-- ## Fehlerbehandlung
--
-- 51420: aktiver Kontext bei AllowNested=0; 51421: Nested-Tiefe fehlt, <1 oder >=32767; 51422: explizite ExecutionId weicht ab; 51423: explizite CorrelationId nach SQL-<> abweichend; 51424/51425: Actor/Tenant nach SQL-Vergleich abweichend. Ein extern beschädigter Kontext mit NULL-CorrelationId besitzt SQL-NULL-Vergleichssemantik; keine Reparatur-/Authentizitätsprüfung daraus ableiten. Typbindungs-, Konvertierungs-, read_only-Key- und andere Enginefehler bleiben sichtbar. Ohne aktive gültige ID wird ein neuer Root gesetzt, nicht ein beliebiger Restzustand vollständig validiert.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag. Keine neue native Skill-/Callerzustandsabnahme aus passiven Beschreibungen ableiten; historische Fachbelege nur bei passender Bindung verwenden. Actor/Tenant und sämtliche SESSION_CONTEXT-Werte sind callerbeeinflussbare Metadaten, keine Authentifizierung, Mandantentrennung oder Sicherheitsgrenze. Kein automatischer Kontexttransport in andere Verbindungen und keine Garantie gegen fremde direkte Keyänderungen oder Pooling-/MARS-Effekte.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET @AllowNested = ISNULL(@AllowNested, 1);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_BeginExecution' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'DECLARE @Id uniqueidentifier; EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@ExecutionId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@CorrelationId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Actor', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Tenant', N'nvarchar(256)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@AllowNested', N'bit', 0, 1, N'1', CAST(N'Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_BeginExecution' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-beginexecution"
description: "Beginnt einen Toolbelt-Ausführungskontext in dieser Verbindung oder erhöht seine ScopeDepth bei zulässiger Verschachtelung."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-context"
schema_name: "toolbelt_core"
object_name: "USP_BeginExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Default) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in die' AS nvarchar(max)) + N'ser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt."}, {"name": "@AllowNested", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schrei' + N'ben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten."}]
source_paths: ["Modules/toolbelt.core.execution-context/Source/USP_BeginExecution.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_BeginExecution

## Zweck und Einsatzfälle

Beginnt einen Toolbelt-Ausführungskontext in dieser Verbindung oder erhöht seine ScopeDepth bei zulässiger Verschachtelung.

## Voraussetzungen

Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. INPUT/OUTPUT: Ohne aktiven Kontext wird die übergebene ID verwendet oder bei NULL (Default) NEWID erzeugt; bei Verschachtelung muss eine explizite ID der aktiven ID entsprechen. OUTPUT enthält anschließend die aktive ID. Im Hilfezweig wird dieser INPUT/OUTPUT-Parameter nicht initialisiert oder geändert; ein bereits übergebener Wert bleibt erhalten. Für Rückgabe an eine Callervariable OUTPUT am EXEC angeben. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Am Root ist NULL (Defau' + N'lt) gleich der ExecutionId; eine explizite ID wird gespeichert. Bei Verschachtelung bedeutet NULL übernehmen, eine explizite ID muss übereinstimmen. |
| `@Actor` | `nvarchar(256)` | `NULL` | Optionaler Unicode-Kontexttext nvarchar(256), keine geprüfte Identität/Authentifizierung. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; kein Login-Fallback in dieser Procedure. Bei Verschachtelung übernimmt NULL den aktiven Wert; expliziter Text darf ihn nicht verändern. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Optionaler Unicode-Kontexttext nvarchar(256), keine Existenz-/Berechtigungsprüfung eines Mandanten. Am Root entfernt NULL den Key und leerer Text wird als leerer Wert gesetzt; bei Verschachtelung bedeutet NULL übernehmen, expliziter Text muss zum aktiven Wert passen. Verschachtelte Gleichheitsprüfung verwendet normale SQL-Vergleichs-/Padding-/Collationsemantik, keine binäre Identitätsprüfung; bestehende Werte werden dort nicht ersetzt. |
| `@AllowNested` | `bit` | `1` | Taxativ für bit: 1 erlaubt bei aktivem Kontext eine weitere Verschachtelung (Default und NULL); 0 lehnt einen erneuten Begin ab. Tiefe höchstens 32767; bei Root-Neuanlage ohne Kontext hat das Flag keine sperrende Wirkung. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |

## Ergebnisse

Kein fachlicher Resultset. RETURN 0 bei Erfolg; @Ex' + N'ecutionId ist INPUT/OUTPUT und enthält die gewählte aktive ID. Ohne gültige aktuelle ID wird die übergebene ID oder NEWID verwendet, CorrelationId standardmäßig gleichgesetzt, Zeit neu erfasst und Tiefe 1 gesetzt. Im Nested-Pfad bleibt die ID gleich und nur die Tiefe wächst; vorhandene Correlation-/Actor-/Tenant-Werte und Startzeit werden nicht neu geschrieben. Bei Hilfe keine Änderung des bereits übergebenen OUTPUT-Werts. Hilfe=1 liefert stattdessen bisherige Standardhilfe und genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); RETURN 0 vor fachlichen Kontextzugriffen.

## Aufrufbeispiele

```sql
-- Eigene Sitzung ohne vorher aktiven Context verwenden.
DECLARE @Id uniqueidentifier;
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Actor=N''Contoso example'';
SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- Hilfe liest/schreibt keinen Context und erhält einen vorhandenen OUTPUT-Wert:
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT,@Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser Prozedur/Funktion im tatsächlichen Datenbankkontext und vorhandene Rechte der internen Abhängigkeitskette. Keine Rechteerteilung, kein Serverstatus-/fremder-Session-Zugriff und kein EXECUTE-AS-Wechsel. Bestehende Enginegrenzen für SESSION_CONTEXT bleiben wirksam; Kontextlabels verleihen keine Berechtigung.

## Ressourcenbedarf

Feste Anzahl Keylese-/Schreibaufrufe, begrenzte Labels nvarchar(256) und ISO-Zeittext nvarchar(33). Tiefe nach regulärem Begin maximal 32767; kein persistenter Stack mit gespeicherten Vorgängerwerten. Die Engine verwaltet Sessionkontextspeicher, kein eigener Heap-/Laufzeitvertrag.

## Nebenwirkungen

Root schreibt die sechs Sessionkeys sequentiell, Nested nur depth. Keine eigene Transaktion, keine Kompensations-/Rollbackklammer und kein automatisches End bei Fehlern. Ein späterer Schre' + N'ibfehler kann nach bereits erfolgreichen Keyänderungen auftreten; kein atomarer Mehrkey-Vertrag. Debug>0 erzeugt erst nach erfolgreichem Fachpfad eine abstrakte Severity-10-Nachricht WITH NOWAIT ohne Payload.

## Fehlerbehandlung

51420: aktiver Kontext bei AllowNested=0; 51421: Nested-Tiefe fehlt, <1 oder >=32767; 51422: explizite ExecutionId weicht ab; 51423: explizite CorrelationId nach SQL-<> abweichend; 51424/51425: Actor/Tenant nach SQL-Vergleich abweichend. Ein extern beschädigter Kontext mit NULL-CorrelationId besitzt SQL-NULL-Vergleichssemantik; keine Reparatur-/Authentizitätsprüfung daraus ableiten. Typbindungs-, Konvertierungs-, read_only-Key- und andere Enginefehler bleiben sichtbar. Ohne aktive gültige ID wird ein neuer Root gesetzt, nicht ein beliebiger Restzustand vollständig validiert.

## Aussagegrenzen

Quellgeprüfter Vertrag. Keine neue native Skill-/Callerzustandsabnahme aus passiven Beschreibungen ableiten; historische Fachbelege nur bei passender Bindung verwenden. Actor/Tenant und sämtliche SESSION_CONTEXT-Werte sind callerbeeinflussbare Metadaten, keine Authentifizierung, Mandantentrennung oder Sicherheitsgrenze. Kein automatischer Kontexttransport in andere Verbindungen und keine Garantie gegen fremde direkte Keyänderungen oder Pooling-/MARS-Effekte.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    DECLARE @CurrentExecutionId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));
    DECLARE @CurrentCorrelationId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.correlation_id'));
    DECLARE @CurrentDepth int = TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth'));
    DECLARE @CurrentActor nvarchar(256) = CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.actor'));
    DECLARE @CurrentTenant nvarchar(256) = CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.tenant'));

    IF @CurrentExecutionId IS NULL
    BEGIN
        SET @ExecutionId = ISNULL(@ExecutionId, NEWID());
        SET @CorrelationId = ISNULL(@CorrelationId, @ExecutionId);
        DECLARE @StartedAtUtc nvarchar(33) = CONVERT(nvarchar(33), SYSUTCDATETIME(), 126);
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id', @value=@ExecutionId;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id', @value=@CorrelationId;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=@Actor;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=@Tenant;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.started_at_utc', @value=@StartedAtUtc;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=1;
    END
    ELSE
    BEGIN
        IF @AllowNested = 0
            THROW 51420, N'In dieser Session ist bereits ein Execution Context aktiv.', 1;
        IF @CurrentDepth IS NULL OR @CurrentDepth < 1 OR @CurrentDepth >= 32767
            THROW 51421, N'Der vorhandene Execution Context besitzt einen ungültigen ScopeDepth.', 1;
        IF @ExecutionId IS NOT NULL AND @ExecutionId <> @CurrentExecutionId
            THROW 51422, N'Die angeforderte Execution-ID stimmt nicht mit dem aktiven Context überein.', 1;
        IF @CorrelationId IS NOT NULL AND @CorrelationId <> @CurrentCorrelationId
            THROW 51423, N'Die angeforderte Correlation-ID stimmt nicht mit dem aktiven Context überein.', 1;
        IF @Actor IS NOT NULL AND ISNULL(@CurrentActor, N'') <> @Actor
            THROW 51424, N'Ein verschachtelter Begin-Aufruf darf Actor nicht ändern.', 1;
        IF @Tenant IS NOT NULL AND ISNULL(@CurrentTenant, N'') <> @Tenant
            THROW 51425, N'Ein verschachtelter Begin-Aufruf darf Tenant nicht ändern.', 1;
        SET @ExecutionId = @CurrentExecutionId;
        DECLARE @NewDepth int = @CurrentDepth + 1;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=@NewDepth;
    END;

    IF @Debug > 0
        RAISERROR(N'USP_BeginExecution: Execution Context ist aktiv.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
