SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_DispatchWorkType]
(
      @WorkTypeName       varchar(128) = NULL
    , @PayloadJson        nvarchar(max) = NULL
    , @ExecutionId        uniqueidentifier = NULL
    , @CorrelationId      uniqueidentifier = NULL
    , @Actor              nvarchar(256) = NULL
    , @Tenant             nvarchar(256) = NULL
    , @RemoteSessionId    int = NULL OUTPUT
    , @HandlerReturnCode  int = NULL OUTPUT
    , @StartedAtUtc       datetime2(7) = NULL OUTPUT
    , @CompletedAtUtc     datetime2(7) = NULL OUTPUT
    , @Hilfe              bit = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-second-session-dispatch"
-- description: "Interner Remote-Dispatcher für registrierte Work Types, Kontextbindung und transaktionalen Handleraufruf."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.second-session"
-- schema_name: "toolbelt_core"
-- object_name: "USP_DispatchWorkType"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Registrierter Remote-WorkType in derselben Datenbank; NULL/nicht gefunden ergibt 51631, kein freier SQL-Text."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NONE akzeptiert ausschließlich NULL; JSON_PAYLOAD erfordert nicht-NULL Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces. Höchstens 1048576 UTF-16-Bytes; konkrete Felder nach Handlervertrag, keine allgemeine JSON-Schema-Auswertung."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Gebundene nicht-NULL Ausführungs-ID vom autorisierten Transport; keine eigene Fallback-ID. Erforderlich außerhalb Hilfe."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Gebundene nicht-NULL Korrelations-ID vom Transport; kein eigener Kontextfallback. Erforderlich außerhalb Hilfe."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Autorisierung."}, {"name": "@Tenant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Tenant-Rechteerteilung."}, {"name": "@RemoteSessionId", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird im Fachpfad vor Validierung auf @@SPID gesetzt. Bei Hilfe bleibt bereits übergebener Wert unverändert."}, {"name": "@HandlerReturnCode", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird vor Fachvalidierung NULL, danach tatsächlicher Handler-Returncode. Nichtzero wird hier nicht automatisch als Fehler behandelt oder rollbackt. Hilfe lässt den Eingangswert unverändert."}, {"name": "@StartedAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird vor Fachvalidierung SYSUTCDATETIME; damit Start der Dispatchbearbeitung, nicht ausschließlich Handlerzeit. Hilfe lässt Eingangswert unverändert."}, {"name": "@CompletedAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT im Fachpfad zuerst NULL, nach Handler und COMMIT SYSUTCDATETIME, aber vor abschließendem Kontextcleanup. Bei späterem Fehler kann bereits ein Zeitpunkt gesetzt sein. Hilfe lässt Eingangswert unverändert."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Hilfe plus vollständige Skillzeile ohne Änderung irgendeines OUTPUT-Werts; 0/NULL: Fachpfad."}]
-- source_paths: ["Modules/toolbelt.core.second-session/Source/USP_DispatchWorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
-- review_status: "verified"
-- source_module_version: "1.1.0"
-- public_entrypoints: ["toolbelt_core.USP_ExecuteWorkTypeInNewSession"]
-- ---
--
-- # USP_DispatchWorkType
--
-- ## Zweck und Einsatzfälle
--
-- Interner Handlerdispatch im bestehenden Remoteprozess; regulärer Einstieg ausschließlich USP_ExecuteWorkTypeInNewSession. Führt nur registrierte P-/PC-Prozeduren aus, keinen frei übergebenen SQL-Text.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Remote-WorkType muss registriert/aktiv sein, Kontextmodule vorhanden, Handler sichtbar mit EXECUTE für den tatsächlichen Remoteprincipal und gültige App-Policy EXECUTE_NEW_SESSION. Vorgesehener Pfad ist eine frische separate Session ohne aktive Callertransaktion. NONE verlangt exakt null SQL-Parameter am Handler. JSON_PAYLOAD verlangt exakt einen nicht-OUTPUT @PayloadJson nvarchar(max), außer kanonischer Event-Handler toolbelt.event-log.write -> toolbelt_core.USP_WriteEventInternal mit exakt zweitem @Hilfe bit; nur dort wird explizit Hilfe=0 gebunden. Keine allgemeine Freigabe zusätzlicher optionaler Parameter. Keine automatische Handler-/WorkType-/Policyanlage.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Registrierter Remote-WorkType in derselben Datenbank; NULL/nicht gefunden ergibt 51631, kein freier SQL-Text. |
-- | `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | NONE akzeptiert ausschließlich NULL; JSON_PAYLOAD erfordert nicht-NULL Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces. Höchstens 1048576 UTF-16-Bytes; konkrete Felder nach Handlervertrag, keine allgemeine JSON-Schema-Auswertung. |
-- | `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Gebundene nicht-NULL Ausführungs-ID vom autorisierten Transport; keine eigene Fallback-ID. Erforderlich außerhalb Hilfe. |
-- | `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Gebundene nicht-NULL Korrelations-ID vom Transport; kein eigener Kontextfallback. Erforderlich außerhalb Hilfe. |
-- | `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Autorisierung. |
-- | `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Tenant-Rechteerteilung. |
-- | `@RemoteSessionId` | `int` | `NULL` | INPUT/OUTPUT | OUTPUT wird im Fachpfad vor Validierung auf @@SPID gesetzt. Bei Hilfe bleibt bereits übergebener Wert unverändert. |
-- | `@HandlerReturnCode` | `int` | `NULL` | INPUT/OUTPUT | OUTPUT wird vor Fachvalidierung NULL, danach tatsächlicher Handler-Returncode. Nichtzero wird hier nicht automatisch als Fehler behandelt oder rollbackt. Hilfe lässt den Eingangswert unverändert. |
-- | `@StartedAtUtc` | `datetime2(7)` | `NULL` | INPUT/OUTPUT | OUTPUT wird vor Fachvalidierung SYSUTCDATETIME; damit Start der Dispatchbearbeitung, nicht ausschließlich Handlerzeit. Hilfe lässt Eingangswert unverändert. |
-- | `@CompletedAtUtc` | `datetime2(7)` | `NULL` | INPUT/OUTPUT | OUTPUT im Fachpfad zuerst NULL, nach Handler und COMMIT SYSUTCDATETIME, aber vor abschließendem Kontextcleanup. Bei späterem Fehler kann bereits ein Zeitpunkt gesetzt sein. Hilfe lässt Eingangswert unverändert. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bestehende Hilfe plus vollständige Skillzeile ohne Änderung irgendeines OUTPUT-Werts; 0/NULL: Fachpfad. |
--
-- ## Ergebnisse
--
-- Kein fachliches SELECT-Resultset. Normale Kommunikation ausschließlich über vier optionale OUTPUT-Parameter und RETURN 0 nach erfolgreichem Dispatchabschluss. RemoteSessionId/HandlerReturnCode/StartedAtUtc/CompletedAtUtc siehe Parameter. Handler-Returncode ungleich 0 führt NICHT automatisch zu THROW oder ROLLBACK; fehlendes THROW des Handlers erlaubt den COMMITpfad. Diese Semantik nicht mit Dispatcher-Returncode verwechseln. Hilfe liefert zuerst die vorhandene zwölfspaltige Standardhilfe und genau eine zusätzliche vollständige Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); danach RETURN 0 vor fachlichen Prüfungen, Katalog-/Kontextlesen, RPC oder Mutation. SQL-Typbindung und ausdrücklich genannte lokale Initialisierung bleiben erhalten. Der Hilfezweig steht vor sämtlicher OUTPUT-Initialisierung, bestehende Werte bleiben unverändert.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Fachlichen Dispatch nur über die öffentliche Fassade aufrufen.
-- EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName='contoso.noop';
-- -- Registrierter erlaubter NONE-Handler und konfigurierter Loopback nötig.
-- DECLARE @Spid int=123,@Code int=456,@Start datetime2(7)='2000-01-01',@End datetime2(7)='2000-01-02';
-- EXEC toolbelt_core.USP_DispatchWorkType @RemoteSessionId=@Spid OUTPUT,@HandlerReturnCode=@Code OUTPUT,@StartedAtUtc=@Start OUTPUT,@CompletedAtUtc=@End OUTPUT,@Hilfe=1;
-- -- Alle vier synthetischen Eingangswerte bleiben im Hilfemodus unverändert.
-- ```
--
-- ## Rechte
--
-- Bestehende Remote-EXECUTE-Rechte auf Dispatcher und Handler sowie lokale Katalog-/Kontext-/Ownershiprechte des Remoteprincipals. App-Policy EXECUTE_NEW_SESSION wird im tatsächlichen Remote-DBtoken mit DENY-Vorrang geprüft. Handler-EXECUTE wird durch HAS_PERMS_BY_NAME ausdrücklich geprüft. Benötigte sys.parameters/TYPE_NAME/Objektmetadaten müssen sichtbar sein. Keine Empfehlung direkter Consumergrants auf diesen internen Einstieg; Actor/Tenant ersetzen keine Rechte.
--
-- ## Ressourcenbedarf
--
-- Payload maximal 1048576 UTF-16-Bytes, vollständige JSONobjektprüfung bei JSON_PAYLOAD; Felder nach Handlervertrag. Registrierung/PayloadContractJson wird hier nicht als JSON-Schema ausgeführt. Synchroner Handler und eigene Handlertransaktion, keine eigene CPU-/Heap-/Lock-/Wallclockgrenze und keine Durchsetzung von DefaultTimeoutSeconds/IsIdempotent. Handlerkosten können darüber hinausgehen; keine automatische Wiederholung oder Deduplikation.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON,XACT_ABORT ON. Hilfe vor OUTPUT-Zuweisungen. Im Fachpfad RemoteSPID/Startzeit setzen, Handlercode/Endzeit NULL; danach Vorprüfungen. BeginExecution mit gebundenen IDs/Actor/Tenant und AllowNested=0, dann BEGIN TRANSACTION, gebundener Handleraufruf WITH RESULT SETS NONE, COMMIT ohne Prüfung auf Handlercode0, Endzeit und EndExecution. Kein fachlicher Handlerresultset zugelassen. Kontextcleanup kann nach Commit fehlschlagen; Fehler bedeutet dann nicht zwingend zurückgerollte Handlerwirkung. CATCH rollt bei XACT_STATE ungleich0 vollständig zurück, danach best-effort Kontextcleanup mit unterdrücktem sekundärem Cleanupfehler; Rollback selbst hat keinen zusätzlichen Schutz. Direktaufruf in einer fremden Callertransaktion ist kein sicherer Consumerpfad: BEGIN/COMMIT kann verschachtelt sein, CATCH kann den gesamten vorhandenen Scope rollbacken. Erfolgs-/Commitinterpretation setzt den vorgesehenen frischen Remote-/Handlervertrag voraus.
--
-- ## Fehlerbehandlung
--
-- 51630 fehlende ExecutionId/CorrelationId;51631 WorkType fehlt;51632 deaktiviert;51628 Payload>1MiB;51633 Payload bei NONE;51634 ungültiges JSONobjekt;51629 Remote-Policy fehlt;51635 Handler fehlt/unsichtbar;51636 Handler-EXECUTE fehlt;51637 NONE-Signatur nicht parameterlos;51638 JSON-Signatur falsch, in dieser tatsächlichen Priorität. Kontext-/Handler-/Enginefehler bleiben erhalten. Nichtzero HandlerReturnCode allein ist kein implementierter Fehler und kein Rollbackkriterium.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter Vertrag, keine neue native Skill-/Caller-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. IDs/Actor/Tenant und Quellnamen sind Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Ein Katalogeintrag/Probe/Returncode ist kein universeller Exactly-once-/Serveridentitäts-/Gesundheitsnachweis; reale Metadaten privat behandeln.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF ISNULL(@Hilfe,0)=1
    BEGIN
        SELECT CONVERT(varchar(16),'1.0') HelpContractVersion,CONVERT(sysname,N'toolbelt_core') SchemaName,
            CONVERT(sysname,N'USP_DispatchWorkType') ObjectName,v.Section,v.Ordinal,v.ItemName,v.SqlDataType,
            v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Interner Second-Session-Dispatcher. Führt den registrierten Handler mit gebundenem Execution-Kontext aus; Hilfe liest keine Work-Type- oder Sessiondaten.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@WorkTypeName','varchar(128)',1,0,N'NULL',N'Exakter registrierter Work Type.',NULL),
          ('PARAMETER',2,N'@PayloadJson','nvarchar(max)',0,1,N'NULL',N'JSON-Objekt nur bei ParameterMode JSON_PAYLOAD.',NULL),
          ('PARAMETER',3,N'@ExecutionId','uniqueidentifier',1,0,N'NULL',N'Vom Caller gebundene Ausführungs-ID.',NULL),
          ('PARAMETER',4,N'@CorrelationId','uniqueidentifier',1,0,N'NULL',N'Vom Caller gebundene Korrelations-ID.',NULL),
          ('PARAMETER',5,N'@Actor','nvarchar(256)',0,1,N'NULL',N'Optionaler Actor des Remote-Kontexts.',NULL),
          ('PARAMETER',6,N'@Tenant','nvarchar(256)',0,1,N'NULL',N'Optionaler Tenant des Remote-Kontexts.',NULL),
          ('PARAMETER',7,N'@RemoteSessionId','int OUTPUT',0,1,N'NULL',N'OUTPUT-SPID der zweiten Session.',NULL),
          ('PARAMETER',8,N'@HandlerReturnCode','int OUTPUT',0,1,N'NULL',N'Returncode des registrierten Handlers.',NULL),
          ('PARAMETER',9,N'@StartedAtUtc','datetime2(7) OUTPUT',0,1,N'NULL',N'Startzeit des Remote-Kontexts in UTC.',NULL),
          ('PARAMETER',10,N'@CompletedAtUtc','datetime2(7) OUTPUT',0,1,N'NULL',N'Abschlusszeit nach erfolgreicher Handlerausführung.',NULL),
          ('PARAMETER',11,N'@Hilfe','bit',0,0,N'0',N'1 liefert ausschließlich diese Hilfe; alle OUTPUT-Werte bleiben unberührt.',NULL),
          ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; Status und Zeitwerte werden über OUTPUT-Parameter geliefert.',NULL),
          ('ERROR',1,N'51628-51638',NULL,NULL,NULL,NULL,N'Payload-, Work-Type-, Berechtigungs- oder Handlervertrag ist ungültig.',NULL),
          ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'Nur über den autorisierten Dispatchpfad; Handler-EXECUTE wird vor Ausführung geprüft.',NULL),
          ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Payload höchstens 1 MiB; ParameterMode ist NONE oder JSON_PAYLOAD.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Fachlicher Aufruf über die öffentliche Fassade; registrierter JSON-Work-Type und konfigurierter Loopback sind Voraussetzung.',N'EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName=''registered-json-type'',@PayloadJson=N''{"value":1}'';')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_DispatchWorkType' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-second-session-dispatch"
description: "Interner Remote-Dispatcher für registrierte Work Types, Kontextbindung und transaktionalen Handleraufruf."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "USP_DispatchWorkType"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Registrierter Remote-WorkType in derselben Datenbank; NULL/nicht gefunden ergibt 51631, kein freier SQL-Text."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NONE akzeptiert ausschließlich NULL; JSON_PAYLOAD erfordert nicht-NULL Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces. Höchstens 1048576 UTF-16-Bytes; konkrete Felder nach Handlervertrag, keine allgemeine JSON-Schema-Auswertung."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Gebundene nicht-NULL Ausführungs-ID vom autorisierten Transport; keine eigene Fallback-ID. Erforderlich außerhalb Hilfe."}, {"name": "@CorrelationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Gebundene nicht-NULL Korrelations-ID vom Transport; kein eigener Kontextfallback. Erforderlich außerhalb Hilfe."}, {"name": "@Actor", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Autorisierung."}, {"name": "@Te' AS nvarchar(max)) + N'nant", "sql_type": "nvarchar(256)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Tenant-Rechteerteilung."}, {"name": "@RemoteSessionId", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird im Fachpfad vor Validierung auf @@SPID gesetzt. Bei Hilfe bleibt bereits übergebener Wert unverändert."}, {"name": "@HandlerReturnCode", "sql_type": "int", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird vor Fachvalidierung NULL, danach tatsächlicher Handler-Returncode. Nichtzero wird hier nicht automatisch als Fehler behandelt oder rollbackt. Hilfe lässt den Eingangswert unverändert."}, {"name": "@StartedAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT wird vor Fachvalidierung SYSUTCDATETIME; damit Start der Dispatchbearbeitung, nicht ausschließlich Handlerzeit. Hilfe lässt Eingangswert unverändert."}, {"name": "@CompletedAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "OUTPUT im Fachpfad zuerst NULL, nach Handler und COMMIT SYSUTCDATETIME, aber vor abschließendem Kontextcleanup. Bei späterem Fehler kann bereits ein Zeitpunkt gesetzt sein. Hilfe lässt Eingangswert unverändert."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Hilfe plus vollständige Skillzeile ohne Änderung irgendeines OUTPUT-Werts; 0/NULL: Fachpfad."}]
source_paths: ["Modules/toolbelt.core' + N'.second-session/Source/USP_DispatchWorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql"]
review_status: "verified"
source_module_version: "1.1.0"
public_entrypoints: ["toolbelt_core.USP_ExecuteWorkTypeInNewSession"]
---

# USP_DispatchWorkType

## Zweck und Einsatzfälle

Interner Handlerdispatch im bestehenden Remoteprozess; regulärer Einstieg ausschließlich USP_ExecuteWorkTypeInNewSession. Führt nur registrierte P-/PC-Prozeduren aus, keinen frei übergebenen SQL-Text.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, passende CL150/160/170, lokal/zentral. Diese Prozedur läuft im Toolbelt-Zielkatalog. Remote-WorkType muss registriert/aktiv sein, Kontextmodule vorhanden, Handler sichtbar mit EXECUTE für den tatsächlichen Remoteprincipal und gültige App-Policy EXECUTE_NEW_SESSION. Vorgesehener Pfad ist eine frische separate Session ohne aktive Callertransaktion. NONE verlangt exakt null SQL-Parameter am Handler. JSON_PAYLOAD verlangt exakt einen nicht-OUTPUT @PayloadJson nvarchar(max), außer kanonischer Event-Handler toolbelt.event-log.write -> toolbelt_core.USP_WriteEventInternal mit exakt zweitem @Hilfe bit; nur dort wird explizit Hilfe=0 gebunden. Keine allgemeine Freigabe zusätzlicher optionaler Parameter. Keine automatische Handler-/WorkType-/Policyanlage.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Registrierter Remote-WorkType in derselben Datenbank; NULL/nicht gefunden ergibt 51631, kein freier SQL-Text. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | NONE akzeptiert ausschließlich NULL; JSON_PAYLOAD erfordert nicht-NULL Objekt nach ISJSON und { nach LTRIM gewöhnlicher Spaces. Höchstens 1048576 UTF-16-Bytes; konkrete Felder nach Handlervertrag, keine allgemeine JSON-Schema-Auswertung. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Gebundene nicht-NULL Ausführungs-' + N'ID vom autorisierten Transport; keine eigene Fallback-ID. Erforderlich außerhalb Hilfe. |
| `@CorrelationId` | `uniqueidentifier` | `NULL` | Input | Gebundene nicht-NULL Korrelations-ID vom Transport; kein eigener Kontextfallback. Erforderlich außerhalb Hilfe. |
| `@Actor` | `nvarchar(256)` | `NULL` | Input | Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Autorisierung. |
| `@Tenant` | `nvarchar(256)` | `NULL` | Input | Optionaler gebundener Remote-Kontexttext, NULL erlaubt, keine Tenant-Rechteerteilung. |
| `@RemoteSessionId` | `int` | `NULL` | INPUT/OUTPUT | OUTPUT wird im Fachpfad vor Validierung auf @@SPID gesetzt. Bei Hilfe bleibt bereits übergebener Wert unverändert. |
| `@HandlerReturnCode` | `int` | `NULL` | INPUT/OUTPUT | OUTPUT wird vor Fachvalidierung NULL, danach tatsächlicher Handler-Returncode. Nichtzero wird hier nicht automatisch als Fehler behandelt oder rollbackt. Hilfe lässt den Eingangswert unverändert. |
| `@StartedAtUtc` | `datetime2(7)` | `NULL` | INPUT/OUTPUT | OUTPUT wird vor Fachvalidierung SYSUTCDATETIME; damit Start der Dispatchbearbeitung, nicht ausschließlich Handlerzeit. Hilfe lässt Eingangswert unverändert. |
| `@CompletedAtUtc` | `datetime2(7)` | `NULL` | INPUT/OUTPUT | OUTPUT im Fachpfad zuerst NULL, nach Handler und COMMIT SYSUTCDATETIME, aber vor abschließendem Kontextcleanup. Bei späterem Fehler kann bereits ein Zeitpunkt gesetzt sein. Hilfe lässt Eingangswert unverändert. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende Hilfe plus vollständige Skillzeile ohne Änderung irgendeines OUTPUT-Werts; 0/NULL: Fachpfad. |

## Ergebnisse

Kein fachliches SELECT-Resultset. Normale Kommunikation ausschließlich über vier optionale OUTPUT-Parameter und RETURN 0 nach erfolgreichem Dispatchabschluss. RemoteSessionId/HandlerReturnCode/StartedAtUtc/CompletedAtUtc siehe Parameter. Handler-Returncode ungleich 0 führt NICHT automatisch zu THROW oder ROLLBACK; fehlendes THROW des Handlers erlaubt den COMMITpfad. Diese Semantik nicht ' + N'mit Dispatcher-Returncode verwechseln. Hilfe liefert zuerst die vorhandene zwölfspaltige Standardhilfe und genau eine zusätzliche vollständige Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max); danach RETURN 0 vor fachlichen Prüfungen, Katalog-/Kontextlesen, RPC oder Mutation. SQL-Typbindung und ausdrücklich genannte lokale Initialisierung bleiben erhalten. Der Hilfezweig steht vor sämtlicher OUTPUT-Initialisierung, bestehende Werte bleiben unverändert.

## Aufrufbeispiele

```sql
-- Fachlichen Dispatch nur über die öffentliche Fassade aufrufen.
EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName=''contoso.noop'';
-- Registrierter erlaubter NONE-Handler und konfigurierter Loopback nötig.
DECLARE @Spid int=123,@Code int=456,@Start datetime2(7)=''2000-01-01'',@End datetime2(7)=''2000-01-02'';
EXEC toolbelt_core.USP_DispatchWorkType @RemoteSessionId=@Spid OUTPUT,@HandlerReturnCode=@Code OUTPUT,@StartedAtUtc=@Start OUTPUT,@CompletedAtUtc=@End OUTPUT,@Hilfe=1;
-- Alle vier synthetischen Eingangswerte bleiben im Hilfemodus unverändert.
```

## Rechte

Bestehende Remote-EXECUTE-Rechte auf Dispatcher und Handler sowie lokale Katalog-/Kontext-/Ownershiprechte des Remoteprincipals. App-Policy EXECUTE_NEW_SESSION wird im tatsächlichen Remote-DBtoken mit DENY-Vorrang geprüft. Handler-EXECUTE wird durch HAS_PERMS_BY_NAME ausdrücklich geprüft. Benötigte sys.parameters/TYPE_NAME/Objektmetadaten müssen sichtbar sein. Keine Empfehlung direkter Consumergrants auf diesen internen Einstieg; Actor/Tenant ersetzen keine Rechte.

## Ressourcenbedarf

Payload maximal 1048576 UTF-16-Bytes, vollständige JSONobjektprüfung bei JSON_PAYLOAD; Felder nach Handlervertrag. Registrierung/PayloadContractJson wird hier nicht als JSON-Schema ausgeführt. Synchroner Handler und eigene Handlertransaktion, keine eigene CPU-/Heap-/Lock-/Wallclockgrenze und keine Durchsetzung von DefaultTimeoutSeconds/IsIdempotent. Handlerkosten können darüber hi' + N'nausgehen; keine automatische Wiederholung oder Deduplikation.

## Nebenwirkungen

SET NOCOUNT ON,XACT_ABORT ON. Hilfe vor OUTPUT-Zuweisungen. Im Fachpfad RemoteSPID/Startzeit setzen, Handlercode/Endzeit NULL; danach Vorprüfungen. BeginExecution mit gebundenen IDs/Actor/Tenant und AllowNested=0, dann BEGIN TRANSACTION, gebundener Handleraufruf WITH RESULT SETS NONE, COMMIT ohne Prüfung auf Handlercode0, Endzeit und EndExecution. Kein fachlicher Handlerresultset zugelassen. Kontextcleanup kann nach Commit fehlschlagen; Fehler bedeutet dann nicht zwingend zurückgerollte Handlerwirkung. CATCH rollt bei XACT_STATE ungleich0 vollständig zurück, danach best-effort Kontextcleanup mit unterdrücktem sekundärem Cleanupfehler; Rollback selbst hat keinen zusätzlichen Schutz. Direktaufruf in einer fremden Callertransaktion ist kein sicherer Consumerpfad: BEGIN/COMMIT kann verschachtelt sein, CATCH kann den gesamten vorhandenen Scope rollbacken. Erfolgs-/Commitinterpretation setzt den vorgesehenen frischen Remote-/Handlervertrag voraus.

## Fehlerbehandlung

51630 fehlende ExecutionId/CorrelationId;51631 WorkType fehlt;51632 deaktiviert;51628 Payload>1MiB;51633 Payload bei NONE;51634 ungültiges JSONobjekt;51629 Remote-Policy fehlt;51635 Handler fehlt/unsichtbar;51636 Handler-EXECUTE fehlt;51637 NONE-Signatur nicht parameterlos;51638 JSON-Signatur falsch, in dieser tatsächlichen Priorität. Kontext-/Handler-/Enginefehler bleiben erhalten. Nichtzero HandlerReturnCode allein ist kein implementierter Fehler und kein Rollbackkriterium.

## Aussagegrenzen

Quellgeprüfter Vertrag, keine neue native Skill-/Caller-/Installations-/Transport-/TLS-Abnahme. Historische Nachweise behalten ihre ursprünglichen Bytes und ihren Scope. IDs/Actor/Tenant und Quellnamen sind Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Ein Katalogeintrag/Probe/Returncode ist kein universeller Exactly-once-/Serveridentitäts-/Gesundheitsnachweis; reale Metadaten privat behandeln.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;

    SET @RemoteSessionId = @@SPID;
    SET @HandlerReturnCode = NULL;
    SET @StartedAtUtc = SYSUTCDATETIME();
    SET @CompletedAtUtc = NULL;

    IF @ExecutionId IS NULL OR @CorrelationId IS NULL
        THROW 51630, N'ExecutionId und CorrelationId sind für den Remote-Dispatcher erforderlich.', 1;

    DECLARE
          @HandlerSchema sysname
        , @HandlerProcedure sysname
        , @ParameterMode varchar(16)
        , @IsEnabled bit;

    SELECT
          @HandlerSchema = wt.HandlerSchema
        , @HandlerProcedure = wt.HandlerProcedure
        , @ParameterMode = wt.ParameterMode
        , @IsEnabled = wt.IsEnabled
    FROM toolbelt_core.WorkType AS wt
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @HandlerSchema IS NULL
        THROW 51631, N'Der Work Type ist in der Remote-Datenbank nicht registriert.', 1;
    IF @IsEnabled = 0
        THROW 51632, N'Der Work Type ist in der Remote-Datenbank deaktiviert.', 1;

    IF DATALENGTH(@PayloadJson)>1048576 THROW 51628,N'Payload überschreitet 1 MiB.',1;
    IF @ParameterMode = 'NONE' AND @PayloadJson IS NOT NULL
        THROW 51633, N'Der Work Type akzeptiert keine JSON-Payload.', 1;
    IF @ParameterMode = 'JSON_PAYLOAD'
       AND
       (
           @PayloadJson IS NULL
           OR ISJSON(@PayloadJson) <> 1
           OR LEFT(LTRIM(@PayloadJson), 1) <> N'{'
       )
        THROW 51634, N'Der Work Type benötigt eine JSON-Objekt-Payload.', 1;

    DECLARE @WorkTypeId bigint=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName=@WorkTypeName);
    IF NOT EXISTS(SELECT 1 FROM toolbelt_core.TVF_WorkTypeAuthorization(@WorkTypeId,'EXECUTE_NEW_SESSION') WHERE IsAllowed=1)
        THROW 51629,N'Keine Remote-Startberechtigung für diesen Work Type.',1;
    DECLARE @HandlerQualifiedName nvarchar(517) =
        QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure);
    DECLARE @HandlerObjectId int = COALESCE
    (
          OBJECT_ID(@HandlerQualifiedName, N'P')
        , OBJECT_ID(@HandlerQualifiedName, N'PC')
    );

    IF @HandlerObjectId IS NULL
        THROW 51635, N'Die registrierte Remote-Zielprocedure existiert nicht.', 1;
    IF ISNULL(HAS_PERMS_BY_NAME(@HandlerQualifiedName, N'OBJECT', N'EXECUTE'), 0) <> 1
        THROW 51636, N'Der Remote-Principal besitzt kein EXECUTE auf die Zielprocedure.', 1;

    DECLARE @InputParameterCount int =
    (
        SELECT COUNT(*)
        FROM sys.parameters AS p
        WHERE p.object_id = @HandlerObjectId
          AND p.parameter_id > 0
    );

    DECLARE @IsCanonicalEventLogHandler bit = 0;
    IF @WorkTypeName COLLATE Latin1_General_100_BIN2 = 'toolbelt.event-log.write'
       AND @HandlerSchema COLLATE Latin1_General_100_BIN2 = N'toolbelt_core'
       AND @HandlerProcedure COLLATE Latin1_General_100_BIN2 = N'USP_WriteEventInternal'
       AND @ParameterMode COLLATE Latin1_General_100_BIN2 = 'JSON_PAYLOAD'
       AND @InputParameterCount = 2
       AND EXISTS
       (
           SELECT 1
           FROM sys.parameters AS p
           WHERE p.object_id = @HandlerObjectId
             AND p.parameter_id = 1
             AND p.name COLLATE Latin1_General_100_BIN2 = N'@PayloadJson'
             AND TYPE_NAME(p.user_type_id) COLLATE Latin1_General_100_BIN2 = N'nvarchar'
             AND p.max_length = -1
             AND p.is_output = 0
       )
       AND EXISTS
       (
           SELECT 1
           FROM sys.parameters AS p
           WHERE p.object_id = @HandlerObjectId
             AND p.parameter_id = 2
             AND p.name COLLATE Latin1_General_100_BIN2 = N'@Hilfe'
             AND TYPE_NAME(p.user_type_id) COLLATE Latin1_General_100_BIN2 = N'bit'
             AND p.max_length = 1
             AND p.is_output = 0
       )
        SET @IsCanonicalEventLogHandler = 1;

    IF @ParameterMode = 'NONE' AND @InputParameterCount <> 0
        THROW 51637, N'Ein NONE-Handler darf keine Eingabe- oder Ausgabeparameter besitzen.', 1;

    IF @ParameterMode = 'JSON_PAYLOAD'
       AND @IsCanonicalEventLogHandler = 0
       AND
       (
           @InputParameterCount <> 1
           OR NOT EXISTS
              (
                  SELECT 1
                  FROM sys.parameters AS p
                  WHERE p.object_id = @HandlerObjectId
                    AND p.parameter_id = 1
                    AND p.name = N'@PayloadJson'
                    AND TYPE_NAME(p.user_type_id) = N'nvarchar'
                    AND p.max_length = -1
                    AND p.is_output = 0
              )
       )
        THROW 51638, N'Ein JSON_PAYLOAD-Handler muss exakt @PayloadJson nvarchar(max) als einzigen Eingabeparameter besitzen.', 1;

    DECLARE @RemoteExecutionId uniqueidentifier = @ExecutionId;
    DECLARE @ContextStarted bit = 0;

    BEGIN TRY
        EXEC toolbelt_core.USP_BeginExecution
              @ExecutionId = @RemoteExecutionId OUTPUT
            , @CorrelationId = @CorrelationId
            , @Actor = @Actor
            , @Tenant = @Tenant
            , @AllowNested = 0;
        SET @ContextStarted = 1;

        BEGIN TRANSACTION;

        DECLARE @HandlerSql nvarchar(max);
        IF @ParameterMode = 'NONE'
            SET @HandlerSql =
                N'EXEC @HandlerReturnCode = ' + @HandlerQualifiedName
                + N' WITH RESULT SETS NONE;';
        ELSE IF @IsCanonicalEventLogHandler = 1
            SET @HandlerSql =
                N'EXEC @HandlerReturnCode = ' + @HandlerQualifiedName
                + N' @PayloadJson = @PayloadJson, @Hilfe = 0 WITH RESULT SETS NONE;';
        ELSE
            SET @HandlerSql =
                N'EXEC @HandlerReturnCode = ' + @HandlerQualifiedName
                + N' @PayloadJson = @PayloadJson WITH RESULT SETS NONE;';

        EXEC sys.sp_executesql
              @HandlerSql
            , N'@PayloadJson nvarchar(max), @HandlerReturnCode int OUTPUT'
            , @PayloadJson = @PayloadJson
            , @HandlerReturnCode = @HandlerReturnCode OUTPUT;

        COMMIT TRANSACTION;
        SET @CompletedAtUtc = SYSUTCDATETIME();

        EXEC toolbelt_core.USP_EndExecution
            @ExpectedExecutionId = @ExecutionId;
        SET @ContextStarted = 0;

        RETURN 0;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        IF @ContextStarted = 1
        BEGIN
            BEGIN TRY
                EXEC toolbelt_core.USP_EndExecution
                    @ExpectedExecutionId = @ExecutionId;
            END TRY
            BEGIN CATCH
                -- Der ursprüngliche Handler-/Providerfehler behält Vorrang.
            END CATCH;
        END;

        THROW;
    END CATCH;
END;
GO
