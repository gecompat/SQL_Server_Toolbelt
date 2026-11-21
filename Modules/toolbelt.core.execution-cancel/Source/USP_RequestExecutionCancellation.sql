SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RequestExecutionCancellation]
      @ExecutionId uniqueidentifier = NULL
    , @CancellationReason nvarchar(512) = NULL
    , @Debug tinyint = 0
    , @Hilfe bit = 0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-core-usp-requestexecutioncancellation"
-- description: "Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.execution-cancel"
-- schema_name: "toolbelt_core"
-- object_name: "USP_RequestExecutionCancellation"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL verwendet SVF_CurrentExecutionId; fehlt auch dort eine ID, Fehler 52601. Null-GUID ist 52602. Eine vorhandene ID bleibt unverändert. Technischer Default NULL."}, {"name": "@CancellationReason", "sql_type": "nvarchar(512)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler nicht sensibler Audittext im gebundenen nvarchar(512), NULL erlaubt. LEN=0 einschließlich ausschließlich gewöhnlicher Spaces wird NULL; sonst bleibt der Text einschließlich trailing Spaces erhalten. Keine zusätzliche Prüfung einer vor Parameterbindung längeren Eingabe. Bei vorhandener ID kein Überschreiben des ursprünglichen Grundes."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: zuerst bestehende zwölfspaltige Hilfe, zusätzlich genau eine vollständige vier-spaltige Skillzeile, dann RETURN 0 vor Transaktions-/Kontext-/Quotenprüfung. 0 oder NULL: Fachpfad. Alle USP-Argumente besitzen Defaults."}]
-- source_paths: ["Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql", "Modules/toolbelt.core.execution-cancel/Source/ExecutionCancellation.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_RequestExecutionCancellation
--
-- ## Zweck und Einsatzfälle
--
-- Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.
--
-- ## Voraussetzungen
--
-- SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@ExecutionId` | `uniqueidentifier` | `NULL` | NULL verwendet SVF_CurrentExecutionId; fehlt auch dort eine ID, Fehler 52601. Null-GUID ist 52602. Eine vorhandene ID bleibt unverändert. Technischer Default NULL. |
-- | `@CancellationReason` | `nvarchar(512)` | `NULL` | Optionaler nicht sensibler Audittext im gebundenen nvarchar(512), NULL erlaubt. LEN=0 einschließlich ausschließlich gewöhnlicher Spaces wird NULL; sonst bleibt der Text einschließlich trailing Spaces erhalten. Keine zusätzliche Prüfung einer vor Parameterbindung längeren Eingabe. Bei vorhandener ID kein Überschreiben des ursprünglichen Grundes. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | 1: zuerst bestehende zwölfspaltige Hilfe, zusätzlich genau eine vollständige vier-spaltige Skillzeile, dann RETURN 0 vor Transaktions-/Kontext-/Quotenprüfung. 0 oder NULL: Fachpfad. Alle USP-Argumente besitzen Defaults. |
--
-- ## Ergebnisse
--
-- Keine fachlichen Resultsets und keine OUTPUT-Parameter. RETURN 0 auch bei idempotentem No-op. Anschließend Status über TVF lesen. @Hilfe=1 liefert zuerst zwölfspaltige Standardhilfe und danach genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max).
--
-- ## Aufrufbeispiele
--
-- ```sql
-- DECLARE @Id uniqueidentifier=NEWID();
-- EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id,@CancellationReason=N'Synthetic checkpoint';
-- SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(@Id);
-- EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
-- -- Nur Testidentität in autorisiertem Scope; die Anforderung persistiert.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser öffentlichen Request-USP und funktionierende bestehende Objekt-/Ownershiprechte auf Tabelle und Kontextfunktion. Sichtbarkeit der eigenen Zeile in sys.database_principals und Berechtigung zum transaktionsgebundenen public-AppLock müssen bestehen; keine automatische Rechtevergabe. Zentrale Nutzung erfordert gültige Datenbankauthentifizierung/Mapping und passende Rechte im Toolbelt-Ziel; ein Dreiteilname allein erteilt diese nicht. Keine Serverrollen oder Identitätsumschaltung durch diese Objekte.
--
-- ## Ressourcenbedarf
--
-- Kurze eigene Transaktion mit exklusivem DBweitem AppLock bis Commit/Rollback. Quoten zählen Gesamtzeilen und aktuellen Requester; keine Volltabellen-Löschung. Wartende Anforderer können bis zum AppLocktimeout blockieren. Neue IDs: höchstens 100000 Tabellenzeilen insgesamt und 10000 je exaktem Tupel des tatsächlichen DBprincipals (ID/SID/create_date). Ein transaktionsgebundener exklusiver AppLock im public-Kontext serialisiert Quotenprüfung und Insert, Timeout 10000 ms; eine bereits vorhandene ExecutionId ist vor Quotenprüfung ein No-op. Kein automatisches Löschen abgelaufener Anforderungen. Direktes privilegiertes DML wird durch diese Anwendungsquoten nicht als Tabellenconstraint verhindert. Keine feste CPU-/Heap-/Durchsatz-/Latenzgarantie.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON, SET XACT_ABORT ON, Debug/Hilfe NULL nach 0. Fachaufruf verbietet jede aktive Callertransaktion. Eigene Transaktion umfasst AppLock, Existenz-/Quotenprüfung und gegebenenfalls einmaliges Insert. Bei Fehler Rollback falls XACT_STATE ungleich 0; Rollbackfehler werden nicht separat geschützt. Wiederholte ID ändert weder Timestamp, Grund, Identitäten noch RowVersion. Debug>0: abstrakte Severity-10-NOWAIT-Meldung mit neu=0/1, keine ID oder Audittexte. Hilfe kehrt vor Kontextfunktion/Katalog/Tabelle/Transaktion zurück. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.
--
-- ## Fehlerbehandlung
--
-- 52600 aktive Callertransaktion; 52601 explizite/aktuelle ID fehlt; 52602 Null-GUID; 52604 DBprincipal-SID/create_date nicht bindbar; 52603 negativer AppLock-Rückgabewert; 52605 Gesamtquote; 52606 Principalquote. Prüfung in dieser tatsächlichen Reihenfolge, Quoten nur für neue IDs und zuerst Gesamtquote. Technische Engine-/Kontext-/Berechtigungsfehler bleiben erhalten; keine pauschale Erfolgsmaskierung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechteabnahme. Historische Fach-/Repeat-/Quotenbelege behalten ihre ursprüngliche Bindung. Keine Installations-/Rechteattestation, kein Echtzeit-/Unterbrechungsversprechen. Eine ExecutionId ist kein Authentifizierungsgeheimnis und diese APIs prüfen keine fachliche Eigentümerschaft einer ID. Kontextwerte sind keine Sicherheitsgrenze.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_core' AS sysname) AS SchemaName,
            CAST(N'USP_RequestExecutionCancellation' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'52600-52606', NULL, NULL, NULL, NULL, CAST(N'Parameter-, Context-, Transaktions- oder Quotenfehler: 52605 bei 100000 DBrequests, 52606 bei 10000 je Principal; bestehende IDs bleiben idempotent.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Kein fachliches Resultset; den Status liefert TVF_ExecutionCancellationStatus.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Fordert Cancellation für die aktuelle Ausführung an.' AS nvarchar(max)), CAST(N'EXEC toolbelt_core.USP_RequestExecutionCancellation @CancellationReason=N''planned maintenance'';' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@ExecutionId', N'uniqueidentifier', 0, 1, N'NULL', CAST(N'SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Explizite Ziel-ID darf nicht die Null-GUID sein. NULL/Default verwendet den aktiven Execution Context; fehlt dann eine ID, entsteht ein Fehler. Keine aktive Callertransaktion zulässig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@CancellationReason', N'nvarchar(512)', 0, 1, N'NULL', CAST(N'Optionaler Unicode-Grund nvarchar(512), keine Ausführung und keine automatische Redigierung; keine Secrets übergeben. NULL/leer bzw. LEN=0 (reine Spaces) wird NULL. Bei wiederholter Anforderung derselben ID bleiben erster Grund und Zeitpunkt erhalten.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_RequestExecutionCancellation' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-core-usp-requestexecutioncancellation"
description: "Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-cancel"
schema_name: "toolbelt_core"
object_name: "USP_RequestExecutionCancellation"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL verwendet SVF_CurrentExecutionId; fehlt auch dort eine ID, Fehler 52601. Null-GUID ist 52602. Eine vorhandene ID bleibt unverändert. Technischer Default NULL."}, {"name": "@CancellationReason", "sql_type": "nvarchar(512)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler nicht sensibler Audittext im gebundenen nvarchar(512), NULL erlaubt. LEN=0 einschließlich ausschließlich gewöhnlicher Spaces wird NULL; sonst bleibt der Text einschließlich trailing Spaces erhalten. Keine zusätzliche Prüfung einer vor Parameterbindung längeren Eingabe. Bei vorhandener ID kein Überschreiben des ursprünglichen Grundes."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: zuerst bestehende zwölfspaltige Hilfe, zusätzlich genau eine vollständige vier-spaltige Skillzeile, dann RETURN 0 vor Tran' AS nvarchar(max)) + N'saktions-/Kontext-/Quotenprüfung. 0 oder NULL: Fachpfad. Alle USP-Argumente besitzen Defaults."}]
source_paths: ["Modules/toolbelt.core.execution-cancel/Source/USP_RequestExecutionCancellation.sql", "Modules/toolbelt.core.execution-cancel/Source/ExecutionCancellation.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_RequestExecutionCancellation

## Zweck und Einsatzfälle

Persistiert eine irreversible kooperative Cancellation-Anforderung. Die Procedure beendet keine Session und verändert keine Work-Queue-Einträge. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.

## Voraussetzungen

SQL Server 2019/2022/2025 Windows/Linux gemäß Modulmatrix, unterstützte CL150/160/170, lokal oder zentral. Modul ExecutionCancellation und seine passenden Quellobjekte installiert. Request benötigt execution-context >=1.0.0, für implizite ID einen gültigen aktuellen Kontext; Statusfunktionen benötigen keinen aktiven Kontext. Tabelle/Quoten sind pro installierender Datenbank, nicht serverweit oder pro Session.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `NULL` | NULL verwendet SVF_CurrentExecutionId; fehlt auch dort eine ID, Fehler 52601. Null-GUID ist 52602. Eine vorhandene ID bleibt unverändert. Technischer Default NULL. |
| `@CancellationReason` | `nvarchar(512)` | `NULL` | Optionaler nicht sensibler Audittext im gebundenen nvarchar(512), NULL erlaubt. LEN=0 einschließlich ausschließlich gewöhnlicher Spaces wird NULL; sonst bleibt der Text einschließlich trailing Spaces erhalten. Keine zusätzliche Prüfung einer vor Parameterbindung längeren Eingabe. Bei vorhandener ID kein Überschreiben des ursprünglichen Grundes. |
| `@Debug` | `tinyint` | ' + N'`0` | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | 1: zuerst bestehende zwölfspaltige Hilfe, zusätzlich genau eine vollständige vier-spaltige Skillzeile, dann RETURN 0 vor Transaktions-/Kontext-/Quotenprüfung. 0 oder NULL: Fachpfad. Alle USP-Argumente besitzen Defaults. |

## Ergebnisse

Keine fachlichen Resultsets und keine OUTPUT-Parameter. RETURN 0 auch bei idempotentem No-op. Anschließend Status über TVF lesen. @Hilfe=1 liefert zuerst zwölfspaltige Standardhilfe und danach genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
DECLARE @Id uniqueidentifier=NEWID();
EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@Id,@CancellationReason=N''Synthetic checkpoint'';
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(@Id);
EXEC toolbelt_core.USP_RequestExecutionCancellation @Hilfe=1;
-- Nur Testidentität in autorisiertem Scope; die Anforderung persistiert.
```

## Rechte

Vorhandenes EXECUTE auf dieser öffentlichen Request-USP und funktionierende bestehende Objekt-/Ownershiprechte auf Tabelle und Kontextfunktion. Sichtbarkeit der eigenen Zeile in sys.database_principals und Berechtigung zum transaktionsgebundenen public-AppLock müssen bestehen; keine automatische Rechtevergabe. Zentrale Nutzung erfordert gültige Datenbankauthentifizierung/Mapping und passende Rechte im Toolbelt-Ziel; ein Dreiteilname allein erteilt diese nicht. Keine Serverrollen oder Identitätsumschaltung durch diese Objekte.

## Ressourcenbedarf

Kurze eigene Transaktion mit exklusivem DBweitem AppLock bis Commit/Rollback. Quoten zählen Gesamtzeilen und aktuellen Requester; keine Volltabellen-Löschung. Wartende Anforderer können bis zum AppLocktimeout blockieren. Neue IDs: höchstens 100000 Tabellenzeilen insgesamt und 10000 je exaktem Tu' + N'pel des tatsächlichen DBprincipals (ID/SID/create_date). Ein transaktionsgebundener exklusiver AppLock im public-Kontext serialisiert Quotenprüfung und Insert, Timeout 10000 ms; eine bereits vorhandene ExecutionId ist vor Quotenprüfung ein No-op. Kein automatisches Löschen abgelaufener Anforderungen. Direktes privilegiertes DML wird durch diese Anwendungsquoten nicht als Tabellenconstraint verhindert. Keine feste CPU-/Heap-/Durchsatz-/Latenzgarantie.

## Nebenwirkungen

SET NOCOUNT ON, SET XACT_ABORT ON, Debug/Hilfe NULL nach 0. Fachaufruf verbietet jede aktive Callertransaktion. Eigene Transaktion umfasst AppLock, Existenz-/Quotenprüfung und gegebenenfalls einmaliges Insert. Bei Fehler Rollback falls XACT_STATE ungleich 0; Rollbackfehler werden nicht separat geschützt. Wiederholte ID ändert weder Timestamp, Grund, Identitäten noch RowVersion. Debug>0: abstrakte Severity-10-NOWAIT-Meldung mit neu=0/1, keine ID oder Audittexte. Hilfe kehrt vor Kontextfunktion/Katalog/Tabelle/Transaktion zurück. Persistenter kooperativer Abbruchindikator je ExecutionId. Keine Sessionbeendigung, keine Rücknahme von Fachwirkungen, kein Requeue oder Terminalisieren eines Workitems. Worker müssen den Indikator selbst an geeigneten Checkpoints auswerten. Kein Revoke-/Purge-Einstieg in diesem Modul.

## Fehlerbehandlung

52600 aktive Callertransaktion; 52601 explizite/aktuelle ID fehlt; 52602 Null-GUID; 52604 DBprincipal-SID/create_date nicht bindbar; 52603 negativer AppLock-Rückgabewert; 52605 Gesamtquote; 52606 Principalquote. Prüfung in dieser tatsächlichen Reihenfolge, Quoten nur für neue IDs und zuerst Gesamtquote. Technische Engine-/Kontext-/Berechtigungsfehler bleiben erhalten; keine pauschale Erfolgsmaskierung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Installer-/Minimalrechteabnahme. Historische Fach-/Repeat-/Quotenbelege behalten ihre ursprüngliche Bindung. Keine Installations-/Rechteattestation, kein Echtzeit-/Unterbrechungsversprechen. Eine E' + N'xecutionId ist kein Authentifizierungsgeheimnis und diese APIs prüfen keine fachliche Eigentümerschaft einer ID. Kontextwerte sind keine Sicherheitsgrenze.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;

    IF @@TRANCOUNT <> 0
        THROW 52600, N'Eine Cancellation-Anforderung benötigt eine Session ohne aktive Caller-Transaktion.', 1;

    SET @ExecutionId = COALESCE(@ExecutionId, toolbelt_core.SVF_CurrentExecutionId());
    IF @ExecutionId IS NULL
        THROW 52601, N'@ExecutionId fehlt und in dieser Session ist kein Execution Context aktiv.', 1;
    IF @ExecutionId = '00000000-0000-0000-0000-000000000000'
        THROW 52602, N'@ExecutionId darf nicht die Null-GUID sein.', 1;
    IF @CancellationReason IS NOT NULL AND LEN(@CancellationReason) = 0
        SET @CancellationReason = NULL;

    DECLARE @WasCreated bit = 0, @LockResult int,
            @PrincipalId int = USER_ID(), @PrincipalSid varbinary(85), @PrincipalCreatedAt datetime;
    SELECT @PrincipalSid=sid,@PrincipalCreatedAt=create_date
    FROM sys.database_principals WHERE principal_id=@PrincipalId;
    IF @PrincipalSid IS NULL OR @PrincipalCreatedAt IS NULL
        THROW 52604,N'Anfordernder Datenbankprincipal konnte nicht gebunden werden.',1;
    BEGIN TRANSACTION;
    BEGIN TRY
        EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.execution-cancellation.quota',
            @LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=10000,@DbPrincipal=N'public';
        IF @LockResult<0 THROW 52603,N'Cancellationquote konnte nicht atomar geprüft werden.',1;
        IF NOT EXISTS
        (
            SELECT 1 FROM toolbelt_core.ExecutionCancellation WITH (UPDLOCK, HOLDLOCK)
            WHERE ExecutionId = @ExecutionId
        )
        BEGIN
            IF (SELECT COUNT_BIG(*) FROM toolbelt_core.ExecutionCancellation)>=100000
                THROW 52605,N'Die Datenbankquote von 100000 Cancellation-Anforderungen ist erreicht.',1;
            IF (SELECT COUNT_BIG(*) FROM toolbelt_core.ExecutionCancellation
                WHERE RequestedByPrincipalId=@PrincipalId AND RequestedByPrincipalSid=@PrincipalSid
                  AND RequestedByPrincipalCreatedAt=@PrincipalCreatedAt)>=10000
                THROW 52606,N'Die Principalquote von 10000 Cancellation-Anforderungen ist erreicht.',1;
            INSERT INTO toolbelt_core.ExecutionCancellation
                (ExecutionId, RequestedBy, CancellationReason, RequestedByPrincipalId, RequestedByPrincipalSid, RequestedByPrincipalCreatedAt)
            VALUES
                (@ExecutionId, ORIGINAL_LOGIN(), @CancellationReason, @PrincipalId, @PrincipalSid, @PrincipalCreatedAt);
            SET @WasCreated = 1;
        END;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    IF @Debug > 0
    BEGIN
        DECLARE @WasCreatedForMessage int = CONVERT(int, @WasCreated);
        RAISERROR(N'USP_RequestExecutionCancellation: Anforderung verarbeitet; neu=%d.', 10, 1, @WasCreatedForMessage) WITH NOWAIT;
    END;
    RETURN 0;
END;
GO
