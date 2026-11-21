SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EndExecution]
(
      @ExpectedExecutionId uniqueidentifier
    , @Debug               tinyint = 0
    , @Hilfe               bit = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-endexecution"
-- description: "Beendet genau eine Ebene des aktiven Ausführungskontexts unter Prüfung der erwarteten ExecutionId."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.execution-context"
-- schema_name: "toolbelt_core"
-- object_name: "USP_EndExecution"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@ExpectedExecutionId", "sql_type": "uniqueidentifier", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten."}]
-- source_paths: ["Modules/toolbelt.core.execution-context/Source/USP_EndExecution.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_EndExecution
--
-- ## Zweck und Einsatzfälle
--
-- Beendet genau eine Ebene des aktiven Ausführungskontexts unter Prüfung der erwarteten ExecutionId.
--
-- ## Voraussetzungen
--
-- Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |
--
-- ## Ergebnisse
--
-- Kein fachlicher Resultset oder OUTPUT-Parameter, RETURN 0 bei Erfolg. Bei Tiefe>1 nur um 1 reduzieren; bei Tiefe=1 alle sechs Toolbelt-Keys löschen. Das Lesen des Kontexts liefert danach keine Zeile. Andere Sessionkeys bleiben unberührt. End prüft nur positive Tiefe, keine eigene 32767-Obergrenze für extern veränderte Werte. Hilfe=1 liefert stattdessen bisherige Standardhilfe und genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); RETURN 0 vor fachlichen Kontextzugriffen.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
-- -- Nur den eigenen zuvor begonnenen Scope beenden:
-- EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- -- Help benötigt das Pflichtargument, aber keinen aktiven Context:
-- EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL,@Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser Prozedur/Funktion im tatsächlichen Datenbankkontext und vorhandene Rechte der internen Abhängigkeitskette. Keine Rechteerteilung, kein Serverstatus-/fremder-Session-Zugriff und kein EXECUTE-AS-Wechsel. Bestehende Enginegrenzen für SESSION_CONTEXT bleiben wirksam; Kontextlabels verleihen keine Berechtigung.
--
-- ## Ressourcenbedarf
--
-- Feste Anzahl Kontextzugriffe, eine Dekrementierung oder sechs Löschaufrufe. Keine Rekursion und kein eigener gespeicherter Scope-Stack, keine Datei-/Tabellen-/Netzwerkressource.
--
-- ## Nebenwirkungen
--
-- Ändert depth oder löscht die sechs Keys sequentiell. Keine eigene Transaktion, kein Stack-Restore alter Labels und keine Kompensation bereits gelöschter Keys bei einem späteren Enginefehler. Debug>0 erzeugt eine abstrakte Severity-10-Nachricht WITH NOWAIT. Schlüssel anderer Namespaces werden nicht gelöscht.
--
-- ## Fehlerbehandlung
--
-- 51430: keine gültige aktive ID; 51431: ExpectedExecutionId NULL oder abweichend; 51432: Tiefe fehlt oder <1. Der Pflichtparameter ohne SQL-Default bleibt auch beim Hilfeaufruf anzugeben, dann darf NULL übergeben werden. Read_only-Key-, Konvertierungs- und Enginefehler werden nicht unterdrückt; kein automatischer Cleanup fremder oder inkonsistenter Sessionwerte.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag. Keine neue native Skill-/Callerzustandsabnahme aus passiven Beschreibungen ableiten; historische Fachbelege nur bei passender Bindung verwenden. Actor/Tenant und sämtliche SESSION_CONTEXT-Werte sind callerbeeinflussbare Metadaten, keine Authentifizierung, Mandantentrennung oder Sicherheitsgrenze. Kein automatischer Kontexttransport in andere Verbindungen und keine Garantie gegen fremde direkte Keyänderungen oder Pooling-/MARS-Effekte.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_EndExecution' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Verringert den ScopeDepth eines aktiven Contexts und löscht bei Tiefe 1 alle Toolbelt-Sessionwerte.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'-- Voraussetzung: aktiver Context in derselben Session.
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; Rückgaben über OUTPUT beziehungsweise Sessionkontext gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@ExpectedExecutionId', N'uniqueidentifier', 1, 0, NULL, CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_EndExecution' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-endexecution"
description: "Beendet genau eine Ebene des aktiven Ausführungskontexts unter Prüfung der erwarteten ExecutionId."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-context"
schema_name: "toolbelt_core"
object_name: "USP_EndExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExpectedExecutionId", "sql_type": "uniqueidentifier", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten."}]
source_paths: ["Modules/toolbelt.core.execution-context/Source/USP_EndExecution.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_EndExecution

## Zweck ' AS nvarchar(max)) + N'und Einsatzfälle

Beendet genau eine Ebene des aktiven Ausführungskontexts unter Prüfung der erwarteten ExecutionId.

## Voraussetzungen

Installiertes reines T-SQL-Modul auf SQL Server 2019/2022/2025 unter Windows/Linux, lokal oder zentral. Die sechs festen SESSION_CONTEXT-Keys gehören zur aktuellen SQL-Verbindung und sind nicht nach Datenbank getrennt: toolbelt.execution.id, toolbelt.execution.correlation_id, toolbelt.execution.actor, toolbelt.execution.tenant, toolbelt.execution.started_at_utc und toolbelt.execution.depth. Keine CLR-, Datei-, Netzwerk- oder Benutzertabellenabhängigkeit. Nicht gleichzeitig per MARS/anderen Aufrufen oder direkt über sp_set_session_context manipulieren; Enginebeschränkungen und extern read_only gesetzte Keys können Schreibaufrufe blockieren.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ExpectedExecutionId` | `uniqueidentifier` | `kein Default` | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Muss im Fachaufruf nicht-NULL und gleich der aktiven Session-ExecutionId sein; fehlender Kontext/abweichende ID wird abgewiesen. Pflichtargument ohne technischen Default; für @Hilfe=1 darf explizit NULL übergeben werden. Verringert einen eigenen Scope; am letzten Scope werden die namespaceten Kontextwerte entfernt. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Optionaler bit, Default 0. 1 liefert die bisherige zwölfspaltige Standardhilfe und genau eine zusätzliche vierkolumnige Skillzeile vor fachlichem SESSION_CONTEXT-Lesen oder -Schreiben. 0 oder NULL führt den Normalpfad aus. SQL-Typbindung und syntaktisch erforderliche Argumente bleiben erhalten. |

## Ergebnisse

Kein fachlicher Resultset oder OUTPUT-Parameter, RETURN 0 bei Erf' + N'olg. Bei Tiefe>1 nur um 1 reduzieren; bei Tiefe=1 alle sechs Toolbelt-Keys löschen. Das Lesen des Kontexts liefert danach keine Zeile. Andere Sessionkeys bleiben unberührt. End prüft nur positive Tiefe, keine eigene 32767-Obergrenze für extern veränderte Werte. Hilfe=1 liefert stattdessen bisherige Standardhilfe und genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); RETURN 0 vor fachlichen Kontextzugriffen.

## Aufrufbeispiele

```sql
DECLARE @Id uniqueidentifier=toolbelt_core.SVF_CurrentExecutionId();
-- Nur den eigenen zuvor begonnenen Scope beenden:
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
-- Help benötigt das Pflichtargument, aber keinen aktiven Context:
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=NULL,@Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser Prozedur/Funktion im tatsächlichen Datenbankkontext und vorhandene Rechte der internen Abhängigkeitskette. Keine Rechteerteilung, kein Serverstatus-/fremder-Session-Zugriff und kein EXECUTE-AS-Wechsel. Bestehende Enginegrenzen für SESSION_CONTEXT bleiben wirksam; Kontextlabels verleihen keine Berechtigung.

## Ressourcenbedarf

Feste Anzahl Kontextzugriffe, eine Dekrementierung oder sechs Löschaufrufe. Keine Rekursion und kein eigener gespeicherter Scope-Stack, keine Datei-/Tabellen-/Netzwerkressource.

## Nebenwirkungen

Ändert depth oder löscht die sechs Keys sequentiell. Keine eigene Transaktion, kein Stack-Restore alter Labels und keine Kompensation bereits gelöschter Keys bei einem späteren Enginefehler. Debug>0 erzeugt eine abstrakte Severity-10-Nachricht WITH NOWAIT. Schlüssel anderer Namespaces werden nicht gelöscht.

## Fehlerbehandlung

51430: keine gültige aktive ID; 51431: ExpectedExecutionId NULL oder abweichend; 51432: Tiefe fehlt oder <1. Der Pflichtparameter ohne SQL-Default bleibt auch beim Hilfeaufruf anzugeben, dann darf NULL übergeben werden. Read_only-Key-, Konvertierungs- und' + N' Enginefehler werden nicht unterdrückt; kein automatischer Cleanup fremder oder inkonsistenter Sessionwerte.

## Aussagegrenzen

Quellgeprüfter Vertrag. Keine neue native Skill-/Callerzustandsabnahme aus passiven Beschreibungen ableiten; historische Fachbelege nur bei passender Bindung verwenden. Actor/Tenant und sämtliche SESSION_CONTEXT-Werte sind callerbeeinflussbare Metadaten, keine Authentifizierung, Mandantentrennung oder Sicherheitsgrenze. Kein automatischer Kontexttransport in andere Verbindungen und keine Garantie gegen fremde direkte Keyänderungen oder Pooling-/MARS-Effekte.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    DECLARE @CurrentExecutionId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));
    DECLARE @CurrentDepth int = TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth'));
    IF @CurrentExecutionId IS NULL
        THROW 51430, N'In dieser Session ist kein Execution Context aktiv.', 1;
    IF @ExpectedExecutionId IS NULL OR @ExpectedExecutionId <> @CurrentExecutionId
        THROW 51431, N'@ExpectedExecutionId stimmt nicht mit dem aktiven Context überein.', 1;
    IF @CurrentDepth IS NULL OR @CurrentDepth < 1
        THROW 51432, N'Der aktive Context besitzt einen ungültigen ScopeDepth.', 1;

    IF @CurrentDepth > 1
    BEGIN
        DECLARE @NewDepth int = @CurrentDepth - 1;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=@NewDepth;
    END
    ELSE
    BEGIN
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.started_at_utc', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=NULL;
    END;

    IF @Debug > 0
        RAISERROR(N'USP_EndExecution: Execution Scope wurde beendet.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
