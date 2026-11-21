SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_WriteEventInternal]
    @PayloadJson nvarchar(max) = NULL,
    @Hilfe bit = 0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-event-log-internal-write"
-- description: "Interner JSON-Handler für den registrierten Second-Session-Eventschreibpfad."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.event-log"
-- schema_name: "toolbelt_core"
-- object_name: "USP_WriteEventInternal"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vertrauenswürdige gebundene JSON-Objektpayload der Fassade, nicht ein DTSX/XML-/Dateipfad oder beliebiger SQL-Text. Höchstens 131072 UTF-16-Bytes. NULL/leer/ungültig oder nach LTRIM normaler Spaces kein { ergibt 51720. Feldvertrag siehe Voraussetzungen; ID/Actor/Tenant stammen aus dem aktiven Remote-Kontext, nicht aus JSON. Technischer Default NULL dient Hilfe."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Hilfe plus genau eine vollständige Skillzeile vor Payload-/Kontextprüfung/INSERT; 0 oder NULL: interner Fachpfad. Kein generischer öffentlicher Schreibzugriff."}]
-- source_paths: ["Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_WriteEvent"]
-- ---
--
-- # USP_WriteEventInternal
--
-- ## Zweck und Einsatzfälle
--
-- Schreibt genau einen validierten gebundenen Eventdatensatz in der aktuellen Handlersession; regulärer Consumer-Einstieg ausschließlich USP_WriteEvent.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025 Windows/Linux, passende CL150/160/170, lokal/zentral. EventLog und execution-context installiert. Payloadfelder: eventName, eventLevel, category, message, data (JSON-Objekt oder NULL), occurredAtUtc (Stil127), sourceDatabaseName, sourceSchemaName, sourceObjectName, callerSessionId, callerXactState, callerTransactionCount sowie errorNumber/errorSeverity/errorState/errorProcedure/errorLine. Pflichtdaten: Name, Ereigniszeit, Quell-DB, Caller-SPID/-XactState/-TranCount und aktiver Kontext mit ExecutionId/CorrelationId. Actor/Tenant und IDs werden ausschließlich aus TVF_CurrentExecutionContext gelesen. JSON_VALUE/TRY_CONVERT/gebundene Ziellängen bilden den internen Transport; das ist kein vollständiger verlustfreier Validator beliebiger Fremdpayloads: lange/fehlende/unpassende Felder können konvertiert, gekürzt, zu NULL oder zu Tabellen-/Enginefehlern werden. Öffentliche Fassade für fachliche Eingaben nutzen.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Vertrauenswürdige gebundene JSON-Objektpayload der Fassade, nicht ein DTSX/XML-/Dateipfad oder beliebiger SQL-Text. Höchstens 131072 UTF-16-Bytes. NULL/leer/ungültig oder nach LTRIM normaler Spaces kein { ergibt 51720. Feldvertrag siehe Voraussetzungen; ID/Actor/Tenant stammen aus dem aktiven Remote-Kontext, nicht aus JSON. Technischer Default NULL dient Hilfe. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bestehende Hilfe plus genau eine vollständige Skillzeile vor Payload-/Kontextprüfung/INSERT; 0 oder NULL: interner Fachpfad. Kein generischer öffentlicher Schreibzugriff. |
--
-- ## Ergebnisse
--
-- Kein fachlicher oder infrastruktureller SELECT-Resultset und keine OUTPUT-Parameter; RETURN 0 bei Erfolg. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Standardhilfe und dann genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). Anschließend RETURN 0 vor Fachvalidierung, Katalog-/Tabellenzugriff und Schreib-/Lösch-/Transportoperationen. SQL-Typbindung und die vor dem Hilfezweig ausdrücklich beschriebenen lokalen Initialisierungen bleiben wirksam. Der interne Handler startet/committet keine eigene Transaktion. Direkter Return 0 beweist nur erfolgreiches INSERT im aktuellen Scope; der Dispatcher verantwortet dessen Commit.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Interner Fachaufruf nur durch registrierten Dispatcher.
-- EXEC toolbelt_core.USP_WriteEvent @EventName='contoso.example',@EventLevel='INFO',@Message=N'Synthetic event',@DataJson=N'{"rows":1}';
-- -- Persistiert über den zuvor autorisierten/konfigurierten Provider.
-- EXEC toolbelt_core.USP_WriteEventInternal @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Nur vorhandene administrative Dispatch-/Handlerrechte im ausgewählten internen Pfad und gültige Objekt-/Ownershiprechte auf Kontextfunktion und EventLog. Kein empfohlener direkter Consumergrant auf diesen internen Kern. Keine neuen Rollen/Grants, kein automatisches Abschalten von Sicherheitsregeln. Quellnamen, Actor/Tenant und Context IDs verleihen keine Rechte.
--
-- ## Ressourcenbedarf
--
-- Payload hart maximal 131072 UTF-16-Bytes, eingebettetes data maximal 65536 Bytes und Objektroot. JSON_VALUE-skalarer Feldzugriff ist kein nvarchar(max)-Textimport; Message-Ziel nvarchar(4000). Persistente Tabellen-/Indexkosten ohne globale Zeilenquote oder automatische Retention. Keine eigene Transport-Wartezeitregel im Handler.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und XACT_ABORT ON, keine eigene BEGIN/COMMIT/CATCH-Transaktion. INSERT nutzt aktuelle Transaktion; RecordedAtUtc vom Tabellendefault, RemoteSessionId=@@SPID. Die öffentlichen Auditfelder werden aus Payload und Remote-Kontext zusammengeführt. Keine Dispatch- oder Second-Session-Erzeugung durch direkten Handleraufruf. Gespeicherte Message/DataJson und Auditwerte werden nicht automatisch redigiert; keine Secrets oder vertraulichen Inhalte übergeben.
--
-- ## Fehlerbehandlung
--
-- 51720 Payload fehlt/zu groß/kein Objekt; 51721 unvollständige Pflichtdaten/Kontext; 51722 ungültiger Level; 51723 data zu groß/kein Objekt; 51724 Severity,51725 State,51726 positive ErrorLine. SQL-NULL-Dreierlogik bedeutet bei einzelnen fehlenden Feldern keinen garantierten 51721/51722: NOT-NULL/CHECK-/Konvertierungsfehler der Tabelle bleiben möglich. Nichtstring-/überlange JSON_VALUE-Felder sind kein freigegebener generischer Eingabeweg. Kein Catch oder pauschales Mapping technischer Fehler.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Transportabnahme. Historische Belege bleiben an ihre ursprünglichen Bytes und ihren Scope gebunden. Kontext-, Actor-, Tenant- und Quellnamen sind callerbeeinflussbare Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Keine Installations- oder Rechteattestation; Beispiele ausschließlich in einem autorisierten synthetischen Scope ausführen.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@Hilfe, 0) = 1
    BEGIN
        SELECT CONVERT(varchar(16),'1.0') HelpContractVersion, CONVERT(sysname,N'toolbelt_core') SchemaName,
            CONVERT(sysname,N'USP_WriteEventInternal') ObjectName, v.Section, v.Ordinal, v.ItemName,
            v.SqlDataType, v.IsRequired, v.IsNullable, v.DefaultValue, v.Description, v.ExampleSql
        FROM (VALUES
            (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Interner Schreibkern für das Event-Log. Wird nur von freigegebenen Fassaden mit vollständig gebundener Ereignis-Payload aufgerufen.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
            ('PARAMETER',1,N'@PayloadJson','nvarchar(max)',1,1,N'NULL',N'Begrenztes JSON-Objekt mit Ereignis, Quelle und Caller-Kontext.',NULL),
            ('PARAMETER',2,N'@Hilfe','bit',0,0,N'0',N'1 liefert ausschließlich die interne Hilfe; Payload wird nicht geprüft oder gespeichert.',NULL),
            ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; der Kern schreibt genau einen validierten Eventdatensatz.',NULL),
            ('ERROR',1,N'51720-51726',NULL,NULL,NULL,NULL,N'Ungültiges oder unvollständiges Ereignisobjekt und feldspezifische Werte.',NULL),
            ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Kein direkter Callerzugriff; Aufruf über die vorgesehene Event-Log-Fassade.',NULL),
            ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Keine direkte öffentliche Diagnose- oder Schreibschnittstelle.',NULL),
            ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetisches Ereignis über die öffentliche Fassade schreiben; der interne Kern bleibt deren Implementierungsdetail.',N'EXEC toolbelt_core.USP_WriteEvent @EventName=''contoso.helpexample'',@EventLevel=''INFO'',@Message=N''Synthetic example'';')
        ) v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_WriteEventInternal' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-event-log-internal-write"
description: "Interner JSON-Handler für den registrierten Second-Session-Eventschreibpfad."
skill_format_version: "1.0"
module_id: "toolbelt.core.event-log"
schema_name: "toolbelt_core"
object_name: "USP_WriteEventInternal"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vertrauenswürdige gebundene JSON-Objektpayload der Fassade, nicht ein DTSX/XML-/Dateipfad oder beliebiger SQL-Text. Höchstens 131072 UTF-16-Bytes. NULL/leer/ungültig oder nach LTRIM normaler Spaces kein { ergibt 51720. Feldvertrag siehe Voraussetzungen; ID/Actor/Tenant stammen aus dem aktiven Remote-Kontext, nicht aus JSON. Technischer Default NULL dient Hilfe."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Hilfe plus genau eine vollständige Skillzeile vor Payload-/Kontextprüfung/INSERT; 0 oder NULL: interner Fachpfad. Kein generischer öffentlicher Schreibzugriff."}]
source_paths: ["Modules/toolbelt.core.event-log/Source/USP_WriteEventInternal.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_WriteEvent"]
---

# USP_WriteEventInternal

## Zweck und Einsatzfälle

Schreibt genau einen validierten gebundenen Eventdatensatz in der aktuellen Handlersession; regulärer Consumer-Einstieg ausschließlich USP_WriteEvent.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux, passende CL150/160/170, lokal/zentral. EventLog und execution-context installiert. Payloadfelder: eventName, eventLevel, category, message, data (JSON-Objekt oder NULL), occurredAtUtc (Stil127), sourceDatabaseName, sourceSchemaName, so' AS nvarchar(max)) + N'urceObjectName, callerSessionId, callerXactState, callerTransactionCount sowie errorNumber/errorSeverity/errorState/errorProcedure/errorLine. Pflichtdaten: Name, Ereigniszeit, Quell-DB, Caller-SPID/-XactState/-TranCount und aktiver Kontext mit ExecutionId/CorrelationId. Actor/Tenant und IDs werden ausschließlich aus TVF_CurrentExecutionContext gelesen. JSON_VALUE/TRY_CONVERT/gebundene Ziellängen bilden den internen Transport; das ist kein vollständiger verlustfreier Validator beliebiger Fremdpayloads: lange/fehlende/unpassende Felder können konvertiert, gekürzt, zu NULL oder zu Tabellen-/Enginefehlern werden. Öffentliche Fassade für fachliche Eingaben nutzen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Vertrauenswürdige gebundene JSON-Objektpayload der Fassade, nicht ein DTSX/XML-/Dateipfad oder beliebiger SQL-Text. Höchstens 131072 UTF-16-Bytes. NULL/leer/ungültig oder nach LTRIM normaler Spaces kein { ergibt 51720. Feldvertrag siehe Voraussetzungen; ID/Actor/Tenant stammen aus dem aktiven Remote-Kontext, nicht aus JSON. Technischer Default NULL dient Hilfe. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende Hilfe plus genau eine vollständige Skillzeile vor Payload-/Kontextprüfung/INSERT; 0 oder NULL: interner Fachpfad. Kein generischer öffentlicher Schreibzugriff. |

## Ergebnisse

Kein fachlicher oder infrastruktureller SELECT-Resultset und keine OUTPUT-Parameter; RETURN 0 bei Erfolg. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Standardhilfe und dann genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). Anschließend RETURN 0 vor Fachvalidierung, Katalog-/Tabellenzugriff und Schreib-/Lösch-/Transportoperationen. SQL-Typbindung und die vor dem Hilfezweig ausdrücklich beschriebenen lokalen Initialisierungen bleiben wirksam. Der interne Handler startet/committet keine' + N' eigene Transaktion. Direkter Return 0 beweist nur erfolgreiches INSERT im aktuellen Scope; der Dispatcher verantwortet dessen Commit.

## Aufrufbeispiele

```sql
-- Interner Fachaufruf nur durch registrierten Dispatcher.
EXEC toolbelt_core.USP_WriteEvent @EventName=''contoso.example'',@EventLevel=''INFO'',@Message=N''Synthetic event'',@DataJson=N''{"rows":1}'';
-- Persistiert über den zuvor autorisierten/konfigurierten Provider.
EXEC toolbelt_core.USP_WriteEventInternal @Hilfe=1;
```

## Rechte

Nur vorhandene administrative Dispatch-/Handlerrechte im ausgewählten internen Pfad und gültige Objekt-/Ownershiprechte auf Kontextfunktion und EventLog. Kein empfohlener direkter Consumergrant auf diesen internen Kern. Keine neuen Rollen/Grants, kein automatisches Abschalten von Sicherheitsregeln. Quellnamen, Actor/Tenant und Context IDs verleihen keine Rechte.

## Ressourcenbedarf

Payload hart maximal 131072 UTF-16-Bytes, eingebettetes data maximal 65536 Bytes und Objektroot. JSON_VALUE-skalarer Feldzugriff ist kein nvarchar(max)-Textimport; Message-Ziel nvarchar(4000). Persistente Tabellen-/Indexkosten ohne globale Zeilenquote oder automatische Retention. Keine eigene Transport-Wartezeitregel im Handler.

## Nebenwirkungen

SET NOCOUNT ON und XACT_ABORT ON, keine eigene BEGIN/COMMIT/CATCH-Transaktion. INSERT nutzt aktuelle Transaktion; RecordedAtUtc vom Tabellendefault, RemoteSessionId=@@SPID. Die öffentlichen Auditfelder werden aus Payload und Remote-Kontext zusammengeführt. Keine Dispatch- oder Second-Session-Erzeugung durch direkten Handleraufruf. Gespeicherte Message/DataJson und Auditwerte werden nicht automatisch redigiert; keine Secrets oder vertraulichen Inhalte übergeben.

## Fehlerbehandlung

51720 Payload fehlt/zu groß/kein Objekt; 51721 unvollständige Pflichtdaten/Kontext; 51722 ungültiger Level; 51723 data zu groß/kein Objekt; 51724 Severity,51725 State,51726 positive ErrorLine. SQL-NULL-Dreierlogik bedeutet bei einzelnen fehlenden Feldern keinen garantierten 51721' + N'/51722: NOT-NULL/CHECK-/Konvertierungsfehler der Tabelle bleiben möglich. Nichtstring-/überlange JSON_VALUE-Felder sind kein freigegebener generischer Eingabeweg. Kein Catch oder pauschales Mapping technischer Fehler.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Transportabnahme. Historische Belege bleiben an ihre ursprünglichen Bytes und ihren Scope gebunden. Kontext-, Actor-, Tenant- und Quellnamen sind callerbeeinflussbare Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Keine Installations- oder Rechteattestation; Beispiele ausschließlich in einem autorisierten synthetischen Scope ausführen.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;

    IF @PayloadJson IS NULL OR DATALENGTH(@PayloadJson) > 131072 OR ISJSON(@PayloadJson) <> 1 OR LEFT(LTRIM(@PayloadJson), 1) <> N'{'
        THROW 51720, N'Die interne Event-Payload muss ein begrenztes JSON-Objekt sein.', 1;

    DECLARE
          @EventName varchar(128) = CONVERT(varchar(128), JSON_VALUE(@PayloadJson, '$.eventName'))
        , @EventLevel varchar(16) = CONVERT(varchar(16), JSON_VALUE(@PayloadJson, '$.eventLevel'))
        , @Category varchar(128) = CONVERT(varchar(128), JSON_VALUE(@PayloadJson, '$.category'))
        , @Message nvarchar(4000) = CONVERT(nvarchar(4000), JSON_VALUE(@PayloadJson, '$.message'))
        , @DataJson nvarchar(max) = JSON_QUERY(@PayloadJson, '$.data')
        , @OccurredAtUtc datetime2(7) = TRY_CONVERT(datetime2(7), JSON_VALUE(@PayloadJson, '$.occurredAtUtc'), 127)
        , @SourceDatabaseName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceDatabaseName'))
        , @SourceSchemaName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceSchemaName'))
        , @SourceObjectName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceObjectName'))
        , @CallerSessionId int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.callerSessionId'))
        , @CallerXactState smallint = TRY_CONVERT(smallint, JSON_VALUE(@PayloadJson, '$.callerXactState'))
        , @CallerTransactionCount int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.callerTransactionCount'))
        , @ErrorNumber int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorNumber'))
        , @ErrorSeverity int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorSeverity'))
        , @ErrorState int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorState'))
        , @ErrorProcedure sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.errorProcedure'))
        , @ErrorLine int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorLine'));

    DECLARE
          @ExecutionId uniqueidentifier
        , @CorrelationId uniqueidentifier
        , @Actor nvarchar(256)
        , @Tenant nvarchar(256);
    SELECT
          @ExecutionId = c.ExecutionId
        , @CorrelationId = c.CorrelationId
        , @Actor = c.Actor
        , @Tenant = c.Tenant
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;

    IF NULLIF(@EventName, '') IS NULL OR @OccurredAtUtc IS NULL OR NULLIF(@SourceDatabaseName, N'') IS NULL
       OR @CallerSessionId IS NULL OR @CallerXactState NOT IN (-1,0,1) OR @CallerTransactionCount IS NULL
       OR @ExecutionId IS NULL OR @CorrelationId IS NULL
        THROW 51721, N'Die interne Event-Payload ist unvollständig.', 1;
    IF @EventLevel NOT IN ('TRACE','DEBUG','INFO','WARNING','ERROR','CRITICAL')
        THROW 51722, N'Die interne Event-Level-Angabe ist ungültig.', 1;
    IF @DataJson IS NOT NULL AND (DATALENGTH(@DataJson) > 65536 OR LEFT(LTRIM(@DataJson), 1) <> N'{')
        THROW 51723, N'Die interne Data-Payload verletzt den JSON-Objekt- oder Größenvertrag.', 1;
    IF @ErrorSeverity IS NOT NULL AND @ErrorSeverity NOT BETWEEN 0 AND 25
        THROW 51724, N'ErrorSeverity liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorState IS NOT NULL AND @ErrorState NOT BETWEEN 0 AND 255
        THROW 51725, N'ErrorState liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorLine IS NOT NULL AND @ErrorLine <= 0
        THROW 51726, N'ErrorLine muss positiv sein.', 1;

    INSERT INTO toolbelt_core.EventLog
    (
          OccurredAtUtc, EventName, EventLevel, Category, Message, DataJson
        , ExecutionId, CorrelationId, Actor, Tenant
        , SourceDatabaseName, SourceSchemaName, SourceObjectName
        , CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId
        , ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine
    )
    VALUES
    (
          @OccurredAtUtc, @EventName, @EventLevel, @Category, @Message, @DataJson
        , @ExecutionId, @CorrelationId, @Actor, @Tenant
        , @SourceDatabaseName, @SourceSchemaName, @SourceObjectName
        , @CallerSessionId, @CallerXactState, @CallerTransactionCount, @@SPID
        , @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine
    );

    RETURN 0;
END;
GO
