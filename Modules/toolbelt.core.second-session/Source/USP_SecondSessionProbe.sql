SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_SecondSessionProbe]
      @RemoteSessionId   int     = NULL OUTPUT
    , @RemoteDatabaseName sysname = NULL OUTPUT
    , @Hilfe bit = 0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-core-usp-secondsessionprobe"
-- description: "Interne Probe für den tatsächlich aufrufenden Session-/Datenbankkontext; keine eigenständige Remote-Ausführung."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.second-session"
-- schema_name: "toolbelt_core"
-- object_name: "USP_SecondSessionProbe"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@RemoteSessionId", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT: im Normalpfad @@SPID der tatsächlich aufrufenden Session. SQL-Default NULL; ein vorhandener Eingabewert wird im Normalpfad überschrieben. Der vorhandene Help-Pfad verändert den OUTPUT-Wert nicht."}, {"name": "@RemoteDatabaseName", "sql_type": "sysname", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT: im Normalpfad DB_NAME() der tatsächlich aufrufenden Session. SQL-Default NULL; vorhandener Wert wird im Normalpfad überschrieben. Im Help-Pfad unverändert."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit, Default 0; gebundenes 1 liefert Hilfe vor Sessionabfragen und kehrt zurück. NULL wird wie 0 behandelt. 0 führt die interne Probe aus; keine neue Session wird hier erstellt."}]
-- source_paths: ["Modules/toolbelt.core.second-session/Source/USP_SecondSessionProbe.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- public_entrypoints: ["toolbelt_core.USP_ConfigureSecondSessionLoopback", "toolbelt_core.USP_ExecuteWorkTypeInNewSession"]
-- ---
--
-- # USP_SecondSessionProbe
--
-- ## Zweck und Einsatzfälle
--
-- Interner Bestandteil des administrierten Second-Session-Vertrags. Erfasst Session-ID und Datenbankname der Session, in der die Procedure tatsächlich ausgeführt wird.
--
-- ## Voraussetzungen
--
-- Nur im bereits autorisierten Kontext des Second-Session-Moduls verwenden. Der Helper erstellt weder einen Linked Server noch eine andere Session. Die öffentlichen Einstiege sind USP_ConfigureSecondSessionLoopback und USP_ExecuteWorkTypeInNewSession.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
-- |---|---|---|---|---|
-- | `@RemoteSessionId` | `int` | `NULL` | OUTPUT | OUTPUT: im Normalpfad @@SPID der tatsächlich aufrufenden Session. SQL-Default NULL; ein vorhandener Eingabewert wird im Normalpfad überschrieben. Der vorhandene Help-Pfad verändert den OUTPUT-Wert nicht. |
-- | `@RemoteDatabaseName` | `sysname` | `NULL` | OUTPUT | OUTPUT: im Normalpfad DB_NAME() der tatsächlich aufrufenden Session. SQL-Default NULL; vorhandener Wert wird im Normalpfad überschrieben. Im Help-Pfad unverändert. |
-- | `@Hilfe` | `bit` | `0` | Input | bit, Default 0; gebundenes 1 liefert Hilfe vor Sessionabfragen und kehrt zurück. NULL wird wie 0 behandelt. 0 führt die interne Probe aus; keine neue Session wird hier erstellt. |
--
-- ## Ergebnisse
--
-- Kein fachliches Resultset; RemoteSessionId und RemoteDatabaseName werden im Normalpfad per OUTPUT gesetzt, RETURN 0. Hilfe kehrt vor diesen Zuweisungen zurück; bestehende OUTPUT-Werte bleiben dabei erhalten. Nach dem bisherigen Help-Resultset folgt genau ein zusätzliches Skill-Resultset mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); eine Zeile mit dem vollständigen kanonischen Skill.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Nur Metadaten; keine Remote-Session wird erzeugt.
-- EXEC toolbelt_core.USP_SecondSessionProbe @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Kein allgemeiner öffentlicher Fachaufruf. Vorhandene EXECUTE-/Providerrechte im bereits administrierten Second-Session-Vertrag nutzen; keine Rechtevergabe oder Änderung von Login-Mappings durch diesen Helper.
--
-- ## Ressourcenbedarf
--
-- Konstante Session-/Datenbankkontextabfrage im Normalpfad. Kein Tabellen- oder Dateizugriff, keine Kapazitäts-/Remoteverfügbarkeitsgarantie.
--
-- ## Nebenwirkungen
--
-- Normalpfad setzt ausschließlich die zwei OUTPUT-Werte. Kein DML, keine Sessionerzeugung und keine Serverkonfigurationsänderung.
--
-- ## Fehlerbehandlung
--
-- Der Helper definiert keine eigenen Vertragsfehler; fehlende Objekt-/Ausführungsrechte oder unerwartete Engineprobleme bleiben Enginefehler.
--
-- ## Aussagegrenzen
--
-- Ein direkter lokaler Aufruf belegt keinen funktionierenden Remote-/Linked-Server-Pfad. OUTPUT beschreibt nur den wirklichen Ausführungskontext, keine Transportidentität, TLS- oder Rechteabnahme.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;

    IF ISNULL(@Hilfe,0)=1
    BEGIN
        SELECT CONVERT(varchar(16),'1.0') HelpContractVersion,CONVERT(sysname,N'toolbelt_core') SchemaName,
            CONVERT(sysname,N'USP_SecondSessionProbe') ObjectName,v.Section,v.Ordinal,v.ItemName,v.SqlDataType,
            v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Interner Kontextprobe für einen kontrollierten Second-Session-Aufruf; liefert OUTPUT-Metadaten der tatsächlich aufrufenden Session.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@RemoteSessionId','int OUTPUT',0,1,N'NULL',N'OUTPUT-Wert @@SPID der aufrufenden Session.',NULL),
          ('PARAMETER',2,N'@RemoteDatabaseName','sysname OUTPUT',0,1,N'NULL',N'OUTPUT-Wert DB_NAME() der aufrufenden Session.',NULL),
          ('PARAMETER',3,N'@Hilfe','bit',0,0,N'0',N'1 gibt Hilfe vor jeder Sessionabfrage aus.',NULL),
          ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; die beiden Werte werden ausschließlich über OUTPUT-Parameter geliefert.',NULL),
          ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Kein allgemeiner öffentlicher Aufruf; nur über den freigegebenen Second-Session-Vertrag.',NULL),
          ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Keine eigenständige Ausführung oder beliebige Remote-Session-Erzeugung.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Interne Probe im bereits autorisierten Aufrufkontext; liefert ausschließlich OUTPUT-Werte.',N'DECLARE @SessionId int,@DatabaseName sysname; EXEC toolbelt_core.USP_SecondSessionProbe @RemoteSessionId=@SessionId OUTPUT,@RemoteDatabaseName=@DatabaseName OUTPUT; SELECT @SessionId AS SessionId,@DatabaseName AS DatabaseName;')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_SecondSessionProbe' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-core-usp-secondsessionprobe"
description: "Interne Probe für den tatsächlich aufrufenden Session-/Datenbankkontext; keine eigenständige Remote-Ausführung."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "USP_SecondSessionProbe"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@RemoteSessionId", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT: im Normalpfad @@SPID der tatsächlich aufrufenden Session. SQL-Default NULL; ein vorhandener Eingabewert wird im Normalpfad überschrieben. Der vorhandene Help-Pfad verändert den OUTPUT-Wert nicht."}, {"name": "@RemoteDatabaseName", "sql_type": "sysname", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT: im Normalpfad DB_NAME() der tatsächlich aufrufenden Session. SQL-Default NULL; vorhandener Wert wird im Normalpfad überschrieben. Im Help-Pfad unverändert."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "bit, Default 0; gebundenes 1 liefert Hilfe vor Sessionabfragen und kehrt zurück. NULL wird wie 0 behandelt. 0 führt die interne Probe aus; keine neue Session wird hier erstellt."}]
source_paths: ["Modules/toolbelt.core.second-session/Source/USP_SecondSessionProbe.sql"]
review_status: "verified"
source_module_version: "1.1.0"
public_entrypoints: ["toolbelt_core.USP_ConfigureSecondSessionLoopback", "toolbelt_core.USP_ExecuteWorkTypeInNewSession"]
---

# USP_SecondSessionProbe

## Zweck und Einsatzfälle

Interner Bestandteil des administrierten Second-Session-Vertrags. Erfasst Session-ID und Datenbankname der Session, in der die Procedure tatsächlich ausgeführt wird.

## Voraussetzungen
' AS nvarchar(max)) + N'
Nur im bereits autorisierten Kontext des Second-Session-Moduls verwenden. Der Helper erstellt weder einen Linked Server noch eine andere Session. Die öffentlichen Einstiege sind USP_ConfigureSecondSessionLoopback und USP_ExecuteWorkTypeInNewSession.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RemoteSessionId` | `int` | `NULL` | OUTPUT | OUTPUT: im Normalpfad @@SPID der tatsächlich aufrufenden Session. SQL-Default NULL; ein vorhandener Eingabewert wird im Normalpfad überschrieben. Der vorhandene Help-Pfad verändert den OUTPUT-Wert nicht. |
| `@RemoteDatabaseName` | `sysname` | `NULL` | OUTPUT | OUTPUT: im Normalpfad DB_NAME() der tatsächlich aufrufenden Session. SQL-Default NULL; vorhandener Wert wird im Normalpfad überschrieben. Im Help-Pfad unverändert. |
| `@Hilfe` | `bit` | `0` | Input | bit, Default 0; gebundenes 1 liefert Hilfe vor Sessionabfragen und kehrt zurück. NULL wird wie 0 behandelt. 0 führt die interne Probe aus; keine neue Session wird hier erstellt. |

## Ergebnisse

Kein fachliches Resultset; RemoteSessionId und RemoteDatabaseName werden im Normalpfad per OUTPUT gesetzt, RETURN 0. Hilfe kehrt vor diesen Zuweisungen zurück; bestehende OUTPUT-Werte bleiben dabei erhalten. Nach dem bisherigen Help-Resultset folgt genau ein zusätzliches Skill-Resultset mit SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname und SkillMarkdown nvarchar(max); eine Zeile mit dem vollständigen kanonischen Skill.

## Aufrufbeispiele

```sql
-- Nur Metadaten; keine Remote-Session wird erzeugt.
EXEC toolbelt_core.USP_SecondSessionProbe @Hilfe=1;
```

## Rechte

Kein allgemeiner öffentlicher Fachaufruf. Vorhandene EXECUTE-/Providerrechte im bereits administrierten Second-Session-Vertrag nutzen; keine Rechtevergabe oder Änderung von Login-Mappings durch diesen Helper.

## Ressourcenbedarf

Konstante Session-/Datenbankkontextabfrage im Normalpfad. Kein Tabellen- oder Dateizugriff, keine K' + N'apazitäts-/Remoteverfügbarkeitsgarantie.

## Nebenwirkungen

Normalpfad setzt ausschließlich die zwei OUTPUT-Werte. Kein DML, keine Sessionerzeugung und keine Serverkonfigurationsänderung.

## Fehlerbehandlung

Der Helper definiert keine eigenen Vertragsfehler; fehlende Objekt-/Ausführungsrechte oder unerwartete Engineprobleme bleiben Enginefehler.

## Aussagegrenzen

Ein direkter lokaler Aufruf belegt keinen funktionierenden Remote-/Linked-Server-Pfad. OUTPUT beschreibt nur den wirklichen Ausführungskontext, keine Transportidentität, TLS- oder Rechteabnahme.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;

    SET @RemoteSessionId = @@SPID;
    SET @RemoteDatabaseName = DB_NAME();
    RETURN 0;
END;
GO
