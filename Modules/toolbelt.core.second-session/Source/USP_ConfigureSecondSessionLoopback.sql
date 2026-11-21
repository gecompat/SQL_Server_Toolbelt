SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ConfigureSecondSessionLoopback]
(
      @LinkedServerName   sysname = NULL
    , @Enabled            bit = 1
    , @ExpectedRowVersion binary(8) = NULL
    , @ResultTable        sysname = NULL
    , @KeepData           bit = 0
    , @Debug              tinyint = 0
    , @Hilfe              bit = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-usp-configuresecondsess-1d3283c6"
-- description: "Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.second-session"
-- schema_name: "toolbelt_core"
-- object_name: "USP_ConfigureSecondSessionLoopback"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@LinkedServerName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an."}, {"name": "@Enabled", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults."}]
-- source_paths: ["Modules/toolbelt.core.second-session/Source/USP_ConfigureSecondSessionLoopback.sql", "Modules/toolbelt.core.second-session/Source/SecondSessionProvider.sql", "Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql", "Modules/toolbelt.core.second-session/Source/USP_SecondSessionProbe.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- ---
--
-- # USP_ConfigureSecondSessionLoopback
--
-- ## Zweck und Einsatzfälle
--
-- Bindet einen vorhandenen administrativ vorbereiteten Linked Server als Loopback-Provider und prüft dessen sichtbare Flags sowie eine synchrone Probe. Erstellt/ändert keinen Linked Server, Provider oder Loginmapping.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Vorhandener sichtbarer is_linked=1-Eintrag in master.sys.servers, RPC OUT=1, Remote-Proc-Transaction-Promotion=0. Remote-Ziel muss unter DB_NAME() den kanonischen USP_SecondSessionProbe mit passenden Rechten erreichen. Probe gilt auch für Enabled=0 und vor der Providerzeilenänderung. Name und SQL-Typ sind kein Connection String; QUOTENAME schützt die dynamischen Objektidentifier. Datenbankname/SPID der Probe sind Rückgabedaten, kein kryptografischer Nachweis derselben physischen SQLinstanz; das tatsächliche Loopbackziel ist administrativ festzulegen.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@LinkedServerName` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an. |
-- | `@Enabled` | `bit` | `1` | Input | Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server. |
-- | `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults. |
--
-- ## Ergebnisse
--
-- Unterstütztes ResultTable-Zielschema:
--
-- | Feld | Typ/NULL/Collation |
-- |---|---|
-- | `ProviderName` | `varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL` |
-- | `LinkedServerName` | `sysname NOT NULL` |
-- | `IsEnabled` | `bit NOT NULL` |
-- | `RowVersion` | `binary(8) NOT NULL` |
-- | `LinkedServerExists` | `bit NOT NULL` |
-- | `RpcOutEnabled` | `bit NOT NULL` |
-- | `RemoteProcTransactionPromotionEnabled` | `bit NOT NULL` |
-- | `ProbeRemoteSessionId` | `int NOT NULL` |
-- | `ProbeDatabaseName` | `sysname NOT NULL` |
--
-- Direkter SELECT verwendet Ausdrücke und Variablen; physische Nullable-/Collation-Metadaten können vom festen Temp-Zielschema abweichen. Kein ORDER-BY-Vertrag für die Einzelzeile. Bei ResultTable=NULL direktes Ergebnis, sonst vorhandene caller-lokale #Temp über sameDB USP_PrepareResultTable (KeepData=0 ersetzt,1 hängt kompatibel an,NULL=>0). RETURN 0; keine OUTPUT-Parameter. Hilfe liefert zuerst die vorhandene zwölfspaltige Standardhilfe und genau eine zusätzliche vollständige Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); danach RETURN 0 vor fachlichen Prüfungen, Katalog-/Kontextlesen, RPC oder Mutation. SQL-Typbindung und ausdrücklich genannte lokale Initialisierung bleiben erhalten. Ausgegeben werden gespeicherter Provider/Enabled/RowVersion und Flags/DBname/SPID der vorherigen Probe. Kein stabiler Snapshot des späteren Verbindungszustands und kein TLS-/Treiber-/Authentifizierungszertifikat.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Vorhandener administrativ korrekter synthetischer Loopback vorausgesetzt.
-- EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N'ContosoLoopback',@Enabled=1;
-- -- Führt Probe-RPC aus und kann Konfigurationsdaten ändern.
-- EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser administrativen Konfigurations-USP und funktionierende bestehende Katalog-/Ownershiprechte. Sichtbarkeit von master.sys.servers und gültige Linked-Server-Anmeldung sowie Remote-EXECUTE auf USP_SecondSessionProbe nötig. Kein automatisches Serverrecht oder Loginmapping. Ergebnisrouting benötigt zusätzlich vorhandene Helper-/Temp-Rechte; keine allgemeine CONTROL-Prüfung in dieser Prozedur.
--
-- ## Ressourcenbedarf
--
-- Ein synchroner RPC-Probeaufruf vor Transaktionsänderung und eine einzelne Providerzeile unter UPDLOCK,HOLDLOCK, danach gegebenenfalls Temp-/Helperarbeit. Kein eigener Probe-/Lock-/CPU-/Heap-/Wallclocktimeout. Sperren der lokalen Konfigurationszeile können bis zu einem bestehenden Callercommit bleiben; keine Streaming- oder Kapazitätszusage.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON,XACT_ABORT OFF; Enabled=NULL=>1,KeepData/Debug/Hilfe NULL=>0. Probe kommt auch bei Deaktivierung und identischer Konfiguration vor der lokalen Transaktion. Eigener BEGIN/COMMIT oder Caller-Savepoint TBX_SecondSession_Config; vorhandene RowVersion optional prüfen, Neuanlage ignoriert ExpectedRowVersion als Existenzfence. Insert ProviderName=loopback und Audit von SYSUTCDATETIME/ORIGINAL_LOGIN. Nur abweichender LinkedServerName oder Enabled führt zum Update/Modified-Audit; Namevergleich der lokalen Variablen behält DBcollation/SQL-Padding. Keine automatische Reparatur anderer Providerzustände. Eigener Fehler-Rollback oder Caller-Savepoint nur bei XACT_STATE=1, kein vollständiger Callercommit/-rollback; BEGIN/SAVE vor TRY, Rollbackfehler nicht separat geschützt. Wichtig: eigener Konfigurations-COMMIT liegt VOR Ergebnistemp/Routing. Späterer Output-/Helperfehler kann bereits persistente Konfiguration hinterlassen. Debugmessage nur am Ende des ResultTable-Pfads; direkter SELECT kehrt vorher zurück. Keine Serveroption, Rechte- oder Truständerung.
--
-- ## Fehlerbehandlung
--
-- 51600 uncommittable Caller vor allen übrigen Fachprüfungen; 51601 Name fehlt/QUOTENAME ungültig;51602 Linked Server fehlt/unsichtbar;51603 RPC OUT aus;51604 Promotion an; RPC-Engine-/Loginfehler bleiben original;51605 Probe-Returncode NULL/nicht0;51606 abweichender zurückgegebener DBname;51607 SPID NULL oder gleich lokaler @@SPID;51608 vorhandene RowVersionabweichung;51609 Routinghelper fehlt nach Konfigurationsarbeit. DBnameprüfung ist SQL-Textungleichheit, keine generelle NOT-NULL-/Endpoint-Identitätsprüfung gegen manipulierte Probeobjekte. Kanonischer Probe liefert die tatsächlichen Werte.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag, keine neue native Skill-/Caller-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. IDs/Actor/Tenant und Quellnamen sind Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Ein Katalogeintrag/Probe/Returncode ist kein universeller Exactly-once-/Serveridentitäts-/Gesundheitsnachweis; reale Metadaten privat behandeln.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    SET @Enabled = ISNULL(@Enabled, 1);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_ConfigureSecondSessionLoopback' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51600-51609', NULL, NULL, NULL, NULL, CAST(N'Konfigurations-, Probe-, Concurrency- und ResultTable-Fehler.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Konfiguriert den administrativ vorbereiteten Provider.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N''TBX_LOOPBACK'';' AS nvarchar(max))),
        (N'RESULT_COLUMN', 1, N'ProviderName', N'varchar(32)', NULL, 0, NULL, CAST(N'ProviderName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'LinkedServerName', N'sysname', NULL, 0, NULL, CAST(N'LinkedServerName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'IsEnabled', N'bit', NULL, 0, NULL, CAST(N'IsEnabled: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'RowVersion', N'binary(8)', NULL, 0, NULL, CAST(N'RowVersion: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'LinkedServerExists', N'bit', NULL, 0, NULL, CAST(N'LinkedServerExists: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'RpcOutEnabled', N'bit', NULL, 0, NULL, CAST(N'RpcOutEnabled: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'RemoteProcTransactionPromotionEnabled', N'bit', NULL, 0, NULL, CAST(N'RemoteProcTransactionPromotionEnabled: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'ProbeRemoteSessionId', N'int', NULL, 0, NULL, CAST(N'ProbeRemoteSessionId: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'ProbeDatabaseName', N'sysname', NULL, 0, NULL, CAST(N'ProbeDatabaseName: fachliche Ergebnis-/Statusspalte gemäß Objektvertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 1, N'@LinkedServerName', N'sysname', 1, 0, N'NULL', CAST(N'Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Enabled', N'bit', 0, 1, N'1', CAST(N'Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ExpectedRowVersion', N'binary(8)', 0, 1, N'NULL', CAST(N'Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ConfigureSecondSessionLoopback' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-core-usp-configuresecondsess-1d3283c6"
description: "Verknüpft das Modul mit einem bereits administrativ eingerichteten Loopback-Linked-Server. Das Modul legt weder Linked Server noch Login-Mappings oder Credentials an."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "USP_ConfigureSecondSessionLoopback"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@LinkedServerName", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an."}, {"name": "@Enabled", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert."},' AS nvarchar(max)) + N' {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.second-session/Source/USP_ConfigureSecondSessionLoopback.sql", "Modules/toolbelt.core.second-session/Source/SecondSessionProvider.sql", "Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql", "Modules/toolbelt.core.second-session/Source/USP_SecondSessionPro' + N'be.sql"]
review_status: "verified"
source_module_version: "1.1.0"
---

# USP_ConfigureSecondSessionLoopback

## Zweck und Einsatzfälle

Bindet einen vorhandenen administrativ vorbereiteten Linked Server als Loopback-Provider und prüft dessen sichtbare Flags sowie eine synchrone Probe. Erstellt/ändert keinen Linked Server, Provider oder Loginmapping.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Vorhandener sichtbarer is_linked=1-Eintrag in master.sys.servers, RPC OUT=1, Remote-Proc-Transaction-Promotion=0. Remote-Ziel muss unter DB_NAME() den kanonischen USP_SecondSessionProbe mit passenden Rechten erreichen. Probe gilt auch für Enabled=0 und vor der Providerzeilenänderung. Name und SQL-Typ sind kein Connection String; QUOTENAME schützt die dynamischen Objektidentifier. Datenbankname/SPID der Probe sind Rückgabedaten, kein kryptografischer Nachweis derselben physischen SQLinstanz; das tatsächliche Loopbackziel ist administrativ festzulegen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@LinkedServerName` | `sysname` | `NULL` | Input | Fachlich erforderlicher vorhandener Loopback-Linked-Server-Name als sysname, kein Connection String. Binärer Namensvergleich; rpc out muss an und remote proc transaction promotion aus sein. Der Probe muss dieselbe Datenbank mit anderer SPID erreichen, auch wenn Enabled=0 gesetzt wird. NULL/leer ist nur im Hilfemodus zulässig; die Procedure legt keine Infrastruktur an. |
| `@Enabled` | `bit` | `1` | Input | Taxativ für bit: 1 aktiviert die gespeicherte Loopbackkonfiguration (Default und NULL); 0 deaktiviert sie. Vorbedingungen und Probe gelten in beiden Fällen; 0 ist kein Bypass für einen fehlenden/ungeeigneten Linked Server. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betref' + N'fenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Der Vergleich erfolgt nur, wenn eine Konfigurationszeile bereits existiert; er verhindert keine Erstregistrierung mit angegebenem Wert. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: vorhandene Standardhilfe plus eine vollständige vier-spaltige Skillzeile vor Fachprüfung/Katalog/RPC/Mutation; 0 oder NULL: Fachpfad. Alle Argumente besitzen technische Defaults. |

## Ergebnisse

Unterstütztes ResultTable-Zielschema:

| Feld | Typ/NULL/Collation |
|---|---|
| `ProviderName` | `varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL` |
| `LinkedServerName` | `sysname NOT NULL` |
| `IsEnabled` | `bit NOT NULL` |
| `RowVersion` | `binary(8) NOT NULL` |
| `LinkedServerExists` | `bit NOT NULL` |
| `RpcOutEnabled` | `bit NOT NULL` |
| `RemoteProcTransactionPromotionEnabled` | `bit NOT NULL` |
| `ProbeRemoteSessionId` | `int NOT NULL` |
| `ProbeDatabaseName` | `sysname NOT NULL` |

Direkter SELECT verwendet Ausdrücke und' + N' Variablen; physische Nullable-/Collation-Metadaten können vom festen Temp-Zielschema abweichen. Kein ORDER-BY-Vertrag für die Einzelzeile. Bei ResultTable=NULL direktes Ergebnis, sonst vorhandene caller-lokale #Temp über sameDB USP_PrepareResultTable (KeepData=0 ersetzt,1 hängt kompatibel an,NULL=>0). RETURN 0; keine OUTPUT-Parameter. Hilfe liefert zuerst die vorhandene zwölfspaltige Standardhilfe und genau eine zusätzliche vollständige Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); danach RETURN 0 vor fachlichen Prüfungen, Katalog-/Kontextlesen, RPC oder Mutation. SQL-Typbindung und ausdrücklich genannte lokale Initialisierung bleiben erhalten. Ausgegeben werden gespeicherter Provider/Enabled/RowVersion und Flags/DBname/SPID der vorherigen Probe. Kein stabiler Snapshot des späteren Verbindungszustands und kein TLS-/Treiber-/Authentifizierungszertifikat.

## Aufrufbeispiele

```sql
-- Vorhandener administrativ korrekter synthetischer Loopback vorausgesetzt.
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @LinkedServerName=N''ContosoLoopback'',@Enabled=1;
-- Führt Probe-RPC aus und kann Konfigurationsdaten ändern.
EXEC toolbelt_core.USP_ConfigureSecondSessionLoopback @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser administrativen Konfigurations-USP und funktionierende bestehende Katalog-/Ownershiprechte. Sichtbarkeit von master.sys.servers und gültige Linked-Server-Anmeldung sowie Remote-EXECUTE auf USP_SecondSessionProbe nötig. Kein automatisches Serverrecht oder Loginmapping. Ergebnisrouting benötigt zusätzlich vorhandene Helper-/Temp-Rechte; keine allgemeine CONTROL-Prüfung in dieser Prozedur.

## Ressourcenbedarf

Ein synchroner RPC-Probeaufruf vor Transaktionsänderung und eine einzelne Providerzeile unter UPDLOCK,HOLDLOCK, danach gegebenenfalls Temp-/Helperarbeit. Kein eigener Probe-/Lock-/CPU-/Heap-/Wallclocktimeout. Sperren der lokalen Konfigurationszeile können bis zu einem bestehenden ' + N'Callercommit bleiben; keine Streaming- oder Kapazitätszusage.

## Nebenwirkungen

SET NOCOUNT ON,XACT_ABORT OFF; Enabled=NULL=>1,KeepData/Debug/Hilfe NULL=>0. Probe kommt auch bei Deaktivierung und identischer Konfiguration vor der lokalen Transaktion. Eigener BEGIN/COMMIT oder Caller-Savepoint TBX_SecondSession_Config; vorhandene RowVersion optional prüfen, Neuanlage ignoriert ExpectedRowVersion als Existenzfence. Insert ProviderName=loopback und Audit von SYSUTCDATETIME/ORIGINAL_LOGIN. Nur abweichender LinkedServerName oder Enabled führt zum Update/Modified-Audit; Namevergleich der lokalen Variablen behält DBcollation/SQL-Padding. Keine automatische Reparatur anderer Providerzustände. Eigener Fehler-Rollback oder Caller-Savepoint nur bei XACT_STATE=1, kein vollständiger Callercommit/-rollback; BEGIN/SAVE vor TRY, Rollbackfehler nicht separat geschützt. Wichtig: eigener Konfigurations-COMMIT liegt VOR Ergebnistemp/Routing. Späterer Output-/Helperfehler kann bereits persistente Konfiguration hinterlassen. Debugmessage nur am Ende des ResultTable-Pfads; direkter SELECT kehrt vorher zurück. Keine Serveroption, Rechte- oder Truständerung.

## Fehlerbehandlung

51600 uncommittable Caller vor allen übrigen Fachprüfungen; 51601 Name fehlt/QUOTENAME ungültig;51602 Linked Server fehlt/unsichtbar;51603 RPC OUT aus;51604 Promotion an; RPC-Engine-/Loginfehler bleiben original;51605 Probe-Returncode NULL/nicht0;51606 abweichender zurückgegebener DBname;51607 SPID NULL oder gleich lokaler @@SPID;51608 vorhandene RowVersionabweichung;51609 Routinghelper fehlt nach Konfigurationsarbeit. DBnameprüfung ist SQL-Textungleichheit, keine generelle NOT-NULL-/Endpoint-Identitätsprüfung gegen manipulierte Probeobjekte. Kanonischer Probe liefert die tatsächlichen Werte.

## Aussagegrenzen

Quellgeprüfter Vertrag, keine neue native Skill-/Caller-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. IDs/Actor/Tenant und Quellnamen si' + N'nd Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Ein Katalogeintrag/Probe/Returncode ist kein universeller Exactly-once-/Serveridentitäts-/Gesundheitsnachweis; reale Metadaten privat behandeln.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF XACT_STATE() = -1
        THROW 51600, N'Die Providerkonfiguration ist in einer uncommittable Caller-Transaktion nicht zulässig.', 1;
    IF NULLIF(@LinkedServerName, N'') IS NULL OR QUOTENAME(@LinkedServerName) IS NULL
        THROW 51601, N'@LinkedServerName ist erforderlich und muss ein gültiger SQL-Identifier sein.', 1;

    DECLARE
          @LinkedServerExists bit = 0
        , @RpcOutEnabled bit = 0
        , @PromotionEnabled bit = 1;

    SELECT
          @LinkedServerExists = 1
        , @RpcOutEnabled = CONVERT(bit, s.is_rpc_out_enabled)
        , @PromotionEnabled = CONVERT(bit, s.is_remote_proc_transaction_promotion_enabled)
    FROM master.sys.servers AS s
    WHERE s.name COLLATE Latin1_General_100_BIN2
        = @LinkedServerName COLLATE Latin1_General_100_BIN2
      AND s.is_linked = 1;

    IF @LinkedServerExists = 0
        THROW 51602, N'Der angegebene Linked Server existiert nicht.', 1;
    IF @RpcOutEnabled = 0
        THROW 51603, N'Der Linked Server benötigt rpc out = true.', 1;
    IF @PromotionEnabled = 1
        THROW 51604, N'Der Linked Server benötigt remote proc transaction promotion = false.', 1;

    DECLARE @DatabaseName sysname = DB_NAME();
    DECLARE @ProbeSql nvarchar(max) =
        N'EXEC @ProbeReturnCode = '
        + QUOTENAME(@LinkedServerName) + N'.' + QUOTENAME(@DatabaseName)
        + N'.[toolbelt_core].[USP_SecondSessionProbe]'
        + N' @RemoteSessionId=@RemoteSessionId OUTPUT,'
        + N' @RemoteDatabaseName=@RemoteDatabaseName OUTPUT WITH RESULT SETS NONE;';
    DECLARE @ProbeReturnCode int;
    DECLARE @RemoteSessionId int;
    DECLARE @RemoteDatabaseName sysname;

    EXEC sys.sp_executesql
          @ProbeSql
        , N'@RemoteSessionId int OUTPUT, @RemoteDatabaseName sysname OUTPUT, @ProbeReturnCode int OUTPUT'
        , @RemoteSessionId = @RemoteSessionId OUTPUT
        , @RemoteDatabaseName = @RemoteDatabaseName OUTPUT
        , @ProbeReturnCode = @ProbeReturnCode OUTPUT;

    IF ISNULL(@ProbeReturnCode, -1) <> 0
        THROW 51605, N'Der Remote-Probe lieferte keinen erfolgreichen Returncode.', 1;
    IF @RemoteDatabaseName <> @DatabaseName
        THROW 51606, N'Der Loopback-Provider erreicht nicht dieselbe Toolbelt-Datenbank.', 1;
    IF @RemoteSessionId IS NULL OR @RemoteSessionId = @@SPID
        THROW 51607, N'Der Provider erzeugt keine getrennte SQL-Server-Session.', 1;

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    IF @InitialTranCount = 0
        BEGIN TRANSACTION;
    ELSE
        SAVE TRANSACTION TBX_SecondSession_Config;

    BEGIN TRY
        DECLARE @CurrentRowVersion binary(8);
        SELECT @CurrentRowVersion = CONVERT(binary(8), p.RowVersion)
        FROM toolbelt_core.SecondSessionProvider AS p WITH (UPDLOCK, HOLDLOCK)
        WHERE p.ProviderName = 'loopback';

        IF @CurrentRowVersion IS NOT NULL
           AND @ExpectedRowVersion IS NOT NULL
           AND @ExpectedRowVersion <> @CurrentRowVersion
            THROW 51608, N'@ExpectedRowVersion stimmt nicht mit der aktuellen Providerkonfiguration überein.', 1;

        IF @CurrentRowVersion IS NULL
        BEGIN
            INSERT INTO toolbelt_core.SecondSessionProvider
            (
                  ProviderName, LinkedServerName, IsEnabled
                , CreatedAtUtc, CreatedBy, ModifiedAtUtc, ModifiedBy
            )
            VALUES
            (
                  'loopback', @LinkedServerName, @Enabled
                , SYSUTCDATETIME(), ORIGINAL_LOGIN(), SYSUTCDATETIME(), ORIGINAL_LOGIN()
            );
        END
        ELSE
        BEGIN
            UPDATE toolbelt_core.SecondSessionProvider
            SET
                  LinkedServerName = @LinkedServerName
                , IsEnabled = @Enabled
                , ModifiedAtUtc = SYSUTCDATETIME()
                , ModifiedBy = ORIGINAL_LOGIN()
            WHERE ProviderName = 'loopback'
              AND
              (
                  LinkedServerName <> @LinkedServerName
                  OR IsEnabled <> @Enabled
              );
        END;

        IF @InitialTranCount = 0
            COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0
            ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1
            ROLLBACK TRANSACTION TBX_SecondSession_Config;
        THROW;
    END CATCH;

    CREATE TABLE #tbx_SecondSessionProviderShape
    (
          ProviderName varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL
        , LinkedServerName sysname NOT NULL
        , IsEnabled bit NOT NULL
        , RowVersion binary(8) NOT NULL
        , LinkedServerExists bit NOT NULL
        , RpcOutEnabled bit NOT NULL
        , RemoteProcTransactionPromotionEnabled bit NOT NULL
        , ProbeRemoteSessionId int NOT NULL
        , ProbeDatabaseName sysname NOT NULL
    );

    IF @ResultTable IS NULL
    BEGIN
        SELECT
              p.ProviderName
            , p.LinkedServerName
            , p.IsEnabled
            , CONVERT(binary(8), p.RowVersion) AS RowVersion
            , @LinkedServerExists AS LinkedServerExists
            , @RpcOutEnabled AS RpcOutEnabled
            , @PromotionEnabled AS RemoteProcTransactionPromotionEnabled
            , @RemoteSessionId AS ProbeRemoteSessionId
            , @RemoteDatabaseName AS ProbeDatabaseName
        FROM toolbelt_core.SecondSessionProvider AS p
        WHERE p.ProviderName = 'loopback';
        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51609, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_SecondSessionProviderShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (ProviderName, LinkedServerName, IsEnabled, RowVersion, LinkedServerExists, RpcOutEnabled, RemoteProcTransactionPromotionEnabled, ProbeRemoteSessionId, ProbeDatabaseName)'
        + N' SELECT ProviderName, LinkedServerName, IsEnabled, CONVERT(binary(8), RowVersion), @LinkedServerExists, @RpcOutEnabled, @PromotionEnabled, @RemoteSessionId, @RemoteDatabaseName'
        + N' FROM toolbelt_core.SecondSessionProvider WHERE ProviderName=''loopback'';';
    EXEC sys.sp_executesql
          @InsertSql
        , N'@LinkedServerExists bit, @RpcOutEnabled bit, @PromotionEnabled bit, @RemoteSessionId int, @RemoteDatabaseName sysname'
        , @LinkedServerExists = @LinkedServerExists
        , @RpcOutEnabled = @RpcOutEnabled
        , @PromotionEnabled = @PromotionEnabled
        , @RemoteSessionId = @RemoteSessionId
        , @RemoteDatabaseName = @RemoteDatabaseName;

    IF @Debug > 0
        RAISERROR(N'USP_ConfigureSecondSessionLoopback: Providerkonfiguration ist gültig.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
