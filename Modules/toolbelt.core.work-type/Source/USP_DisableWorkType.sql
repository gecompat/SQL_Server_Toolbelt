SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DisableWorkType]
(
      @WorkTypeName       varchar(128)   = NULL
    , @DisabledReason     nvarchar(1000) = NULL
    , @ExpectedRowVersion binary(8)      = NULL
    , @ResultTable        sysname        = NULL
    , @KeepData           bit            = 0
    , @Debug              tinyint        = 0
    , @Hilfe              bit            = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-usp-disableworktype"
-- description: "Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-type"
-- schema_name: "toolbelt_core"
-- object_name: "USP_DisableWorkType"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig."}, {"name": "@DisabledReason", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionales nvarchar(1000), NULL/leer erlaubt, keine Redigierung. Bei erster Deaktivierung einschließlich NULL gespeichert. Ist der Eintrag bereits deaktiviert, bewahrt NULL den Grund; nicht-NULL ändert nur bei ungleichem ISNULL(...,N'')-SQL-Textvergleich. Datenbankcollation und SQL-Padding können Groß-/Kleinschreibung oder trailing Spaces als gleich behandeln. Keine garantierte bytegenaue Textersetzung."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults."}]
-- source_paths: ["Modules/toolbelt.core.work-type/Source/USP_DisableWorkType.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql"]
-- review_status: "verified"
-- source_module_version: "1.2.0"
-- ---
--
-- # USP_DisableWorkType
--
-- ## Zweck und Einsatzfälle
--
-- Deaktiviert einen registrierten Work Type und aktualisiert gegebenenfalls seinen Auditgrund; kein KILL laufender Sessions, keine Entfernung des Handlers oder seiner bereits ausgeführten Wirkungen.
--
-- ## Voraussetzungen
--
-- WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. ExpectedRowVersion NULL deaktiviert nur den optimistischen Versionsvergleich; sonst exakte binary(8)-Bytes aus zuletzt gelesenem Katalog verwenden, keinen Hextext. Already-disabled mit NULL-Grund ist ein No-op, die optionale RowVersion-Prüfung gilt trotzdem. Jede tatsächliche Änderung erzeugt neue RowVersion und macht ältere gebundene WorkType-Policies unwirksam, bis sie ausdrücklich neu konfiguriert werden.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@WorkTypeName` | `varchar(128)` | `NULL` | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
-- | `@DisabledReason` | `nvarchar(1000)` | `NULL` | Optionales nvarchar(1000), NULL/leer erlaubt, keine Redigierung. Bei erster Deaktivierung einschließlich NULL gespeichert. Ist der Eintrag bereits deaktiviert, bewahrt NULL den Grund; nicht-NULL ändert nur bei ungleichem ISNULL(...,N'')-SQL-Textvergleich. Datenbankcollation und SQL-Padding können Groß-/Kleinschreibung oder trailing Spaces als gleich behandeln. Keine garantierte bytegenaue Textersetzung. |
-- | `@ExpectedRowVersion` | `binary(8)` | `NULL` | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | 1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |
--
-- ## Ergebnisse
--
-- | Ergebnisfeld | Typ/NULL/Collation |
-- |---|---|
-- | `WorkTypeId` | `bigint NOT NULL` |
-- | `WorkTypeName` | `varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL` |
-- | `HandlerSchema` | `sysname NOT NULL` |
-- | `HandlerProcedure` | `sysname NOT NULL` |
-- | `HandlerQualifiedName` | `nvarchar(517) NOT NULL` |
-- | `ParameterMode` | `varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL` |
-- | `PayloadContractJson` | `nvarchar(4000) NULL` |
-- | `DefaultTimeoutSeconds` | `int NOT NULL` |
-- | `IsIdempotent` | `bit NOT NULL` |
-- | `IsEnabled` | `bit NOT NULL` |
-- | `Description` | `nvarchar(1000) NULL` |
-- | `CreatedAtUtc` | `datetime2(7) NOT NULL` |
-- | `CreatedBy` | `sysname NOT NULL` |
-- | `ModifiedAtUtc` | `datetime2(7) NOT NULL` |
-- | `ModifiedBy` | `sysname NOT NULL` |
-- | `DisabledAtUtc` | `datetime2(7) NULL` |
-- | `DisabledBy` | `sysname NULL` |
-- | `DisabledReason` | `nvarchar(1000) NULL` |
-- | `RowVersion` | `binary(8) NOT NULL` |
-- | `HandlerExists` | `bit NOT NULL` |
--
-- Genau eine Katalogzeile bei erfolgreichem Fachaufruf, keine Zeilenreihenfolgegarantie. Snapshot nach Deaktivierung; bei nicht notwendiger Änderung aktueller unveränderter Stand. HandlerQualifiedName ist QUOTENAME(Schema)+Punkt+QUOTENAME(Procedure); HandlerExists beruht auf sichtbarem OBJECT_ID vom Typ P oder PC, nicht auf erfolgreicher Ausführung. PayloadContractJson ist deklarative Metadatenbeschreibung, Timeout und IsIdempotent sind kein in dieser Prozedur durchgesetzter Laufzeit-/Duplikatschutz. Bei ResultTable=NULL SELECT, sonst Routing in caller-lokale bereits bestehende #Temp über sameDB USP_PrepareResultTable; KeepData=0 ersetzt, 1 hängt kompatibel an, NULL=>0. RETURN 0, keine OUTPUT-Parameter. @Hilfe=1 liefert zuerst Standardhilfe, dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max).
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='contoso.noop',@DisabledReason=N'Synthetic maintenance';
-- -- Persistente Änderung, bestehender synthetischer Eintrag erforderlich.
-- EXEC toolbelt_core.USP_DisableWorkType @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser öffentlichen Prozedur und gültige bestehende Objekt-/Ownershiprechte auf Katalog/View. Administrativer Anwendungseinstieg; diese Prozedur führt selbst keinen zusätzlichen CONTROL-Check wie USP_SetWorkTypePermission aus. Ausreichendes EXECUTE/Ownership kann daher Katalogänderung erlauben; Grant nicht pauschal an Lesekonsumenten vergeben. Routing benötigt bestehende Helper-/Temp-Rechte. Zentraler Name ersetzt weder DBmapping noch Rechte. Kein automatisches GRANT, Rollenwechsel oder Policy-ALLOW.
--
-- ## Ressourcenbedarf
--
-- Begrenzte Einzelzeile aus dem WorkType-Katalog, zwei eigene feste Temp-Ergebnistabellen und bei Routing weitere Helperarbeit/Temp-DDL. Kein eigener globaler Lock-/Wallclock-/CPU-/Heap-/Grantdeckel. UPDLOCK,HOLDLOCK auf die ausgewählte Katalogzeile innerhalb eigener Transaktion bzw. Caller-Savepoint; Sperren können bis zu Callercommit bestehen. Die gesamte Operation ist kein Background- oder Warteschlangenjob.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON, KeepData/Debug/Hilfe NULL=>0. SET XACT_ABORT OFF. Ohne Callertransaktion eigener BEGIN/COMMIT um Katalogarbeit, sonst fester Savepoint TBX_WorkType_Disable. Fehler: eigener Rollback oder Caller-Savepoint nur bei XACT_STATE=1, kein vollständiger Callercommit/-rollback. BEGIN/SAVE steht vor TRY, Rollbackfehler werden nicht separat geschützt. Bei Enabled=1 IsEnabled=0, DisabledAtUtc/By/Reason und ModifiedAtUtc/By setzen; By=ORIGINAL_LOGIN. Bei bereits deaktiviertem Eintrag nur tatsächlich SQL-ungleichen nicht-NULL-Grund/Modified-Audit ändern. Wichtig: eigener Katalog-COMMIT liegt VOR ResultTable-Helperprüfung und Routing. Ein Routingfehler kann daher trotz Fehler bereits dauerhaft deaktivierten Katalog und veraltete Policybindungen hinterlassen. Kein pauschales atomisches Gesamt-ResultTable-Versprechen. Debug>0: abstrakte Severity-10-NOWAIT-Meldung ohne Kataloginhalte, kein zusätzlicher Resultset. Hilfe kehrt vor all diesen Fachoperationen zurück.
--
-- ## Fehlerbehandlung
--
-- 51520 Name fehlt,51521 nicht registriert,51522 RowVersionabweichung. 51518 fehlender Routinghelper erst nach erfolgreicher Katalogarbeit, gegebenenfalls bereits eigenem Commit. Kein eigener dedizierter Geschäfts-THROW für XACT_STATE=-1; Temp-/Transaktions-/Enginefehler können davor scheitern. Unerwartete technische Fehler werden nicht zu erfolgreichem No-op maskiert. SQL-Textvergleiche behalten ihre Collation-/Paddingregeln; keine generelle bytegenaue Namen-/Grundnormalisierung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechte-/Recoveryabnahme. Historische Evidenz behält ihren ursprünglichen Scope. Katalog-Metadaten und HandlerExists sind kein Ausführungs-/Idempotenz-/Gesundheitsnachweis. Hilfe/Beschreibung bestätigen weder Installation noch vorhandene Callerrechte; reale Auditdaten und freie Gründe privat behandeln.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_DisableWorkType' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Synthetischer Aufruf; Voraussetzungen siehe Objektseite.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName=''demo.noop'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'WorkTypeId', N'bigint', NULL, 0, NULL, CAST(N'WorkTypeId.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'WorkTypeName', N'varchar(128)', NULL, 0, NULL, CAST(N'WorkTypeName.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'HandlerSchema', N'sysname', NULL, 0, NULL, CAST(N'HandlerSchema.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'HandlerProcedure', N'sysname', NULL, 0, NULL, CAST(N'HandlerProcedure.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'HandlerQualifiedName', N'nvarchar(517)', NULL, 0, NULL, CAST(N'HandlerQualifiedName.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'ParameterMode', N'varchar(16)', NULL, 0, NULL, CAST(N'ParameterMode.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'PayloadContractJson', N'nvarchar(4000)', NULL, 1, NULL, CAST(N'PayloadContractJson.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'DefaultTimeoutSeconds', N'int', NULL, 0, NULL, CAST(N'DefaultTimeoutSeconds.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'IsIdempotent', N'bit', NULL, 0, NULL, CAST(N'IsIdempotent.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'IsEnabled', N'bit', NULL, 0, NULL, CAST(N'IsEnabled.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'Description', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'Description.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'CreatedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'CreatedAtUtc.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'CreatedBy', N'sysname', NULL, 0, NULL, CAST(N'CreatedBy.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 14, N'ModifiedAtUtc', N'datetime2(7)', NULL, 0, NULL, CAST(N'ModifiedAtUtc.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 15, N'ModifiedBy', N'sysname', NULL, 0, NULL, CAST(N'ModifiedBy.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 16, N'DisabledAtUtc', N'datetime2(7)', NULL, 1, NULL, CAST(N'DisabledAtUtc.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 17, N'DisabledBy', N'sysname', NULL, 1, NULL, CAST(N'DisabledBy.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 18, N'DisabledReason', N'nvarchar(1000)', NULL, 1, NULL, CAST(N'DisabledReason.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 19, N'RowVersion', N'binary(8)', NULL, 0, NULL, CAST(N'RowVersion.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 20, N'HandlerExists', N'bit', NULL, 0, NULL, CAST(N'HandlerExists.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@WorkTypeName', N'varchar(128)', 1, 0, N'NULL', CAST(N'Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@DisabledReason', N'nvarchar(1000)', 0, 1, N'NULL', CAST(N'Optionales nvarchar(1000), NULL/leer erlaubt, keine Redigierung. Bei erster Deaktivierung einschließlich NULL gespeichert. Ist der Eintrag bereits deaktiviert, bewahrt NULL den Grund; nicht-NULL ändert nur bei ungleichem ISNULL(...,N'''')-SQL-Textvergleich. Datenbankcollation und SQL-Padding können Groß-/Kleinschreibung oder trailing Spaces als gleich behandeln. Keine garantierte bytegenaue Textersetzung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ExpectedRowVersion', N'binary(8)', 0, 1, N'NULL', CAST(N'Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_DisableWorkType' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-core-usp-disableworktype"
description: "Deaktiviert einen registrierten Work Type idempotent und erhält seine Konfiguration."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-type"
schema_name: "toolbelt_core"
object_name: "USP_DisableWorkType"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig."}, {"name": "@DisabledReason", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionales nvarchar(1000), NULL/leer erlaubt, keine Redigierung. Bei erster Deaktivierung einschließlich NULL gespeichert. Ist der Eintrag bereits deaktiviert, bewahrt NULL den Grund; nicht-NULL ändert nur bei ungleichem ISNULL(...,N'''')-SQL-Textvergleich. Datenbankcollation und SQL-Padding können Groß-/Kleinschreibung oder trailing Spaces als gleich behandeln. Keine garantierte bytegenaue Textersetzung."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "desc' AS nvarchar(max)) + N'ription": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.work-type/Source/USP_DisableWorkType.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/VW_WorkTypes.sql", "Modules/toolbelt.core.work-type/Source/WorkTypePermission.sql"]
review_status: "verified"
source_module_version: "1.2.0"
---

# USP_DisableWorkType

## Zweck und Einsatzfälle

Deaktiviert einen registrierten Work Type und aktualisiert gegebenenf' + N'alls seinen Auditgrund; kein KILL laufender Sessions, keine Entfernung des Handlers oder seiner bereits ausgeführten Wirkungen.

## Voraussetzungen

WorkType-Katalog und VW_WorkTypes in derselben Datenbank, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal/zentral. Für ResultTable zusätzlich vorhandener sameDB ResultTable-Helper und gültige caller-lokale Temp. Keine automatische Dependencyinstallation. ExpectedRowVersion NULL deaktiviert nur den optimistischen Versionsvergleich; sonst exakte binary(8)-Bytes aus zuletzt gelesenem Katalog verwenden, keinen Hextext. Already-disabled mit NULL-Grund ist ein No-op, die optionale RowVersion-Prüfung gilt trotzdem. Jede tatsächliche Änderung erzeugt neue RowVersion und macht ältere gebundene WorkType-Policies unwirksam, bis sie ausdrücklich neu konfiguriert werden.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. |
| `@DisabledReason` | `nvarchar(1000)` | `NULL` | Optionales nvarchar(1000), NULL/leer erlaubt, keine Redigierung. Bei erster Deaktivierung einschließlich NULL gespeichert. Ist der Eintrag bereits deaktiviert, bewahrt NULL den Grund; nicht-NULL ändert nur bei ungleichem ISNULL(...,N'''')-SQL-Textvergleich. Datenbankcollation und SQL-Padding können Groß-/Kleinschreibung oder trailing Spaces als gleich behandeln. Keine garantierte bytegenaue Textersetzung. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. |
| `@ResultTable` | `sysname` |' + N' `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | 1: bestehende zwölfspaltige Standardhilfe und genau eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/Temp-Ergebnis/Änderung; danach RETURN 0. 0 oder NULL: Fachpfad. Alle Parameter besitzen technische Defaults. |

## Ergebnisse

| Ergebnisfeld | Typ/NULL/Collation |
|---|---|
| `WorkTypeId` | `bigint NOT NULL` |
| `WorkTypeName` | `varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `HandlerSchema` | `sysname NOT NULL` |
| `HandlerProcedure` | `sysname NOT NULL` |
| `HandlerQualifiedName` | `nvarchar(517) NOT NULL` |
| `ParameterMode` | `varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `PayloadContractJson` | `nvarchar(4000) NULL` |
| `DefaultTimeoutSeconds` | `int NOT NULL` |
| `IsIdempotent` | `bit NOT NULL` |
| `IsEnabled` | `bit NOT NULL` |
| `Description` | `nvarchar(1000) NULL` |
| `CreatedAtUtc` | `datetime2(7) NOT NULL` |
| `CreatedBy` | `sysname NOT NULL` |
| `ModifiedAtUtc` | `datetime2(7) NOT NULL` |
| `ModifiedBy` | `sysname NOT NULL` |
| `DisabledAtUtc` | `datetime2(7) NULL` |
| `DisabledBy` | `sysname NULL` |
| `DisabledReason` | `nvarc' + N'har(1000) NULL` |
| `RowVersion` | `binary(8) NOT NULL` |
| `HandlerExists` | `bit NOT NULL` |

Genau eine Katalogzeile bei erfolgreichem Fachaufruf, keine Zeilenreihenfolgegarantie. Snapshot nach Deaktivierung; bei nicht notwendiger Änderung aktueller unveränderter Stand. HandlerQualifiedName ist QUOTENAME(Schema)+Punkt+QUOTENAME(Procedure); HandlerExists beruht auf sichtbarem OBJECT_ID vom Typ P oder PC, nicht auf erfolgreicher Ausführung. PayloadContractJson ist deklarative Metadatenbeschreibung, Timeout und IsIdempotent sind kein in dieser Prozedur durchgesetzter Laufzeit-/Duplikatschutz. Bei ResultTable=NULL SELECT, sonst Routing in caller-lokale bereits bestehende #Temp über sameDB USP_PrepareResultTable; KeepData=0 ersetzt, 1 hängt kompatibel an, NULL=>0. RETURN 0, keine OUTPUT-Parameter. @Hilfe=1 liefert zuerst Standardhilfe, dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName=''contoso.noop'',@DisabledReason=N''Synthetic maintenance'';
-- Persistente Änderung, bestehender synthetischer Eintrag erforderlich.
EXEC toolbelt_core.USP_DisableWorkType @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser öffentlichen Prozedur und gültige bestehende Objekt-/Ownershiprechte auf Katalog/View. Administrativer Anwendungseinstieg; diese Prozedur führt selbst keinen zusätzlichen CONTROL-Check wie USP_SetWorkTypePermission aus. Ausreichendes EXECUTE/Ownership kann daher Katalogänderung erlauben; Grant nicht pauschal an Lesekonsumenten vergeben. Routing benötigt bestehende Helper-/Temp-Rechte. Zentraler Name ersetzt weder DBmapping noch Rechte. Kein automatisches GRANT, Rollenwechsel oder Policy-ALLOW.

## Ressourcenbedarf

Begrenzte Einzelzeile aus dem WorkType-Katalog, zwei eigene feste Temp-Ergebnistabellen und bei Routing weitere Helperarbeit/Temp-DDL. Kein eigener globaler Lock-/Wallclock-/CPU-/Heap-/Grantdeckel. UPDLO' + N'CK,HOLDLOCK auf die ausgewählte Katalogzeile innerhalb eigener Transaktion bzw. Caller-Savepoint; Sperren können bis zu Callercommit bestehen. Die gesamte Operation ist kein Background- oder Warteschlangenjob.

## Nebenwirkungen

SET NOCOUNT ON, KeepData/Debug/Hilfe NULL=>0. SET XACT_ABORT OFF. Ohne Callertransaktion eigener BEGIN/COMMIT um Katalogarbeit, sonst fester Savepoint TBX_WorkType_Disable. Fehler: eigener Rollback oder Caller-Savepoint nur bei XACT_STATE=1, kein vollständiger Callercommit/-rollback. BEGIN/SAVE steht vor TRY, Rollbackfehler werden nicht separat geschützt. Bei Enabled=1 IsEnabled=0, DisabledAtUtc/By/Reason und ModifiedAtUtc/By setzen; By=ORIGINAL_LOGIN. Bei bereits deaktiviertem Eintrag nur tatsächlich SQL-ungleichen nicht-NULL-Grund/Modified-Audit ändern. Wichtig: eigener Katalog-COMMIT liegt VOR ResultTable-Helperprüfung und Routing. Ein Routingfehler kann daher trotz Fehler bereits dauerhaft deaktivierten Katalog und veraltete Policybindungen hinterlassen. Kein pauschales atomisches Gesamt-ResultTable-Versprechen. Debug>0: abstrakte Severity-10-NOWAIT-Meldung ohne Kataloginhalte, kein zusätzlicher Resultset. Hilfe kehrt vor all diesen Fachoperationen zurück.

## Fehlerbehandlung

51520 Name fehlt,51521 nicht registriert,51522 RowVersionabweichung. 51518 fehlender Routinghelper erst nach erfolgreicher Katalogarbeit, gegebenenfalls bereits eigenem Commit. Kein eigener dedizierter Geschäfts-THROW für XACT_STATE=-1; Temp-/Transaktions-/Enginefehler können davor scheitern. Unerwartete technische Fehler werden nicht zu erfolgreichem No-op maskiert. SQL-Textvergleiche behalten ihre Collation-/Paddingregeln; keine generelle bytegenaue Namen-/Grundnormalisierung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechte-/Recoveryabnahme. Historische Evidenz behält ihren ursprünglichen Scope. Katalog-Metadaten und HandlerExists sind kein Ausführungs-/Idempotenz-/Gesundheitsnachweis. Hilfe/Beschreibung b' + N'estätigen weder Installation noch vorhandene Callerrechte; reale Auditdaten und freie Gründe privat behandeln.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51520, N'@WorkTypeName ist erforderlich.', 1;


    CREATE TABLE #tbx_Core_WorkType_ResultShape
    (
          WorkTypeId            bigint NOT NULL
        , WorkTypeName          varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , HandlerSchema         sysname NOT NULL
        , HandlerProcedure      sysname NOT NULL
        , HandlerQualifiedName  nvarchar(517) NOT NULL
        , ParameterMode         varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , PayloadContractJson   nvarchar(4000) NULL
        , DefaultTimeoutSeconds int NOT NULL
        , IsIdempotent          bit NOT NULL
        , IsEnabled             bit NOT NULL
        , Description           nvarchar(1000) NULL
        , CreatedAtUtc          datetime2(7) NOT NULL
        , CreatedBy             sysname NOT NULL
        , ModifiedAtUtc         datetime2(7) NOT NULL
        , ModifiedBy            sysname NOT NULL
        , DisabledAtUtc         datetime2(7) NULL
        , DisabledBy            sysname NULL
        , DisabledReason        nvarchar(1000) NULL
        , RowVersion            binary(8) NOT NULL
        , HandlerExists         bit NOT NULL
    );

    CREATE TABLE #tbx_Core_WorkType_Result
    (
          WorkTypeId            bigint NOT NULL
        , WorkTypeName          varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , HandlerSchema         sysname NOT NULL
        , HandlerProcedure      sysname NOT NULL
        , HandlerQualifiedName  nvarchar(517) NOT NULL
        , ParameterMode         varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , PayloadContractJson   nvarchar(4000) NULL
        , DefaultTimeoutSeconds int NOT NULL
        , IsIdempotent          bit NOT NULL
        , IsEnabled             bit NOT NULL
        , Description           nvarchar(1000) NULL
        , CreatedAtUtc          datetime2(7) NOT NULL
        , CreatedBy             sysname NOT NULL
        , ModifiedAtUtc         datetime2(7) NOT NULL
        , ModifiedBy            sysname NOT NULL
        , DisabledAtUtc         datetime2(7) NULL
        , DisabledBy            sysname NULL
        , DisabledReason        nvarchar(1000) NULL
        , RowVersion            binary(8) NOT NULL
        , HandlerExists         bit NOT NULL
    );


    DECLARE @WorkTypeId bigint;
    DECLARE @CurrentRowVersion binary(8);
    DECLARE @CurrentEnabled bit;
    DECLARE @Now datetime2(7) = SYSUTCDATETIME();
    DECLARE @Principal sysname = ORIGINAL_LOGIN();

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_WorkType_Disable;

    BEGIN TRY

    SELECT
          @WorkTypeId = wt.WorkTypeId
        , @CurrentRowVersion = CONVERT(binary(8), wt.RowVersion)
        , @CurrentEnabled = wt.IsEnabled
    FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @WorkTypeId IS NULL
        THROW 51521, N'Der Work Type ist nicht registriert.', 1;
    IF @ExpectedRowVersion IS NOT NULL AND @ExpectedRowVersion <> @CurrentRowVersion
        THROW 51522, N'@ExpectedRowVersion stimmt nicht mit dem aktuellen Work Type überein.', 1;

    IF @CurrentEnabled = 1
    BEGIN
        UPDATE toolbelt_core.WorkType
        SET
              IsEnabled = 0
            , DisabledAtUtc = @Now
            , DisabledBy = @Principal
            , DisabledReason = @DisabledReason
            , ModifiedAtUtc = @Now
            , ModifiedBy = @Principal
        WHERE WorkTypeId = @WorkTypeId;
    END
    ELSE IF @DisabledReason IS NOT NULL
    BEGIN
        UPDATE toolbelt_core.WorkType
        SET
              DisabledReason = @DisabledReason
            , ModifiedAtUtc = @Now
            , ModifiedBy = @Principal
        WHERE WorkTypeId = @WorkTypeId
          AND ISNULL(DisabledReason, N'') <> ISNULL(@DisabledReason, N'');
    END;

    INSERT INTO #tbx_Core_WorkType_Result
    SELECT *
    FROM toolbelt_core.VW_WorkTypes
    WHERE WorkTypeId = @WorkTypeId;

    IF @InitialTranCount = 0
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION TBX_WorkType_Disable;
        THROW;
    END CATCH;

    IF @Debug > 0
        RAISERROR(N'USP_DisableWorkType: Work Type ist deaktiviert.', 10, 1) WITH NOWAIT;


    IF @ResultTable IS NULL
    BEGIN
        SELECT * FROM #tbx_Core_WorkType_Result;
        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51518, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_Core_WorkType_ResultShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion, HandlerExists)'
        + N' SELECT WorkTypeId, WorkTypeName, HandlerSchema, HandlerProcedure, HandlerQualifiedName, ParameterMode, PayloadContractJson, DefaultTimeoutSeconds, IsIdempotent, IsEnabled, Description, CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy, DisabledAtUtc, DisabledBy, DisabledReason, RowVersion, HandlerExists FROM #tbx_Core_WorkType_Result;';
    EXEC sys.sp_executesql @InsertSql;
    RETURN 0;

END;
GO
