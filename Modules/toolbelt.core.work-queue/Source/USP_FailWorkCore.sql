-- Interner Terminalkern; fachliche Logik genau einmal.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_FailWorkCore]
(
      @EmitResult    bit              = 1
    , @WorkItemId    bigint           = NULL
    , @ClaimToken    uniqueidentifier = NULL
    , @FailureCode   varchar(64)      = NULL
    , @FailureMessage nvarchar(max)   = NULL
    , @ResultTable   sysname          = NULL
    , @KeepData      bit              = 0
    , @Debug         tinyint          = 0
    , @Hilfe         bit              = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-failworkcore"
-- description: "Tokengebundener endgültiger FAILED-Abschluss eines aktiven Queueclaims. Interner Kern."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_FailWorkCore"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@EmitResult", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1:direkter Fachresultset (Default);0 oderNULL:kein direkter SELECT. Keine zusätzliche Autorität. ResultTable-Routing bleibt bei Fail unabhängig davon möglich."}, {"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@FailureMessage", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Der Parameter ist nvarchar(max); die Prozedur prüft die tatsächliche Länge vor Speicherung und weist größere Werte ab."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_FailWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- public_entrypoints: ["toolbelt_core.USP_FailWork"]
-- ---
--
-- # USP_FailWorkCore
--
-- ## Zweck und Einsatzfälle
--
-- Tokengebundener endgültiger FAILED-Abschluss eines aktiven Queueclaims. Interner Kern. Öffentlich passenden Einstieg statt direktem Kernaufruf verwenden.
--
-- ## Voraussetzungen
--
-- Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@EmitResult` | `bit` | `1` | Input | 1:direkter Fachresultset (Default);0 oderNULL:kein direkter SELECT. Keine zusätzliche Autorität. ResultTable-Routing bleibt bei Fail unabhängig davon möglich. |
-- | `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. |
-- | `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
-- | `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
-- | `@FailureMessage` | `nvarchar(max)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Der Parameter ist nvarchar(max); die Prozedur prüft die tatsächliche Länge vor Speicherung und weist größere Werte ab. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
-- | `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |
--
-- Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersatzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.
--
-- ## Ergebnisse
--
-- | Spalte | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `WorkItemId` | `bigint` | NOT NULL |
-- | `WorkTypeName` | `varchar(128)` | NOT NULL |
-- | `Status` | `varchar(16)` | NOT NULL |
-- | `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL |
-- | `EnqueuedBy` | `sysname` | NOT NULL |
-- | `ClaimedAtUtc` | `datetime2(7)` | NULL |
-- | `ClaimedBy` | `sysname` | NULL |
-- | `CompletedAtUtc` | `datetime2(7)` | NULL |
-- | `CompletedBy` | `sysname` | NULL |
-- | `FailedAtUtc` | `datetime2(7)` | NULL |
-- | `FailedBy` | `sysname` | NULL |
-- | `FailureCode` | `varchar(64)` | NULL |
-- | `FailureMessage` | `nvarchar(1000)` | NULL |
-- | `RowVersion` | `binary(8)` | NOT NULL |
-- | `ClaimGeneration` | `bigint` | NOT NULL |
-- | `LeaseDurationSeconds` | `int` | NULL |
-- | `LeaseUntilUtc` | `datetime2(7)` | NULL |
-- | `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
-- | `IsLeaseExpired` | `bit` | NOT NULL |
-- | `RecoveryCount` | `bigint` | NOT NULL |
-- | `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
-- | `LastRecoveredBy` | `sysname` | NULL |
--
-- Bei gültigem aktuellen Claim genau eine Statuszeile. Fail liefert die22 expliziten privaten Ergebnisspalten, nicht alle41 Viewfelder. EmitResult steuert den direkten SELECT wie beim Parameter beschrieben. ResultTableNULL:direkte Ausgabe; sonst vorbereitetes lokales Ziel mit denselben Spalten und ohne zusätzlichen direkten Fachresultset. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_FailWorkCore @Hilfe=1;
-- -- Fachpfad über öffentlichen Einstieg oder kontrollierten Managedprovider.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. ClaimToken bindet den vorhandenen aktiven Claim; der Code fordert hier keine neue WorkType-Policyentscheidung an. Gehaltene/verwaltete Arbeit verlangt zusätzlich den geschützten Managedabschluss, keinen öffentlichen Bypass. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.
--
-- ## Ressourcenbedarf
--
-- Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. KeepData/Debug/Hilfe werden im Claim-/FailpfadNULL→0 normalisiert. ManagedHold oder eine ManagedReservation ohne passende completion_nonce und exklusiven Transaction-Disposition-AppLock wird vor und unter dem Row Lock mit54201 abgewehrt. Danach Pflicht-ID/Token, stabilen ASCII-FailureCode und tatsächliche Messagebreite prüfen; doomed Caller wird abgewiesen. Gesunder Caller-TX ist zulässig: eigener TX bei@@TRANCOUNT0, sonst Savepoint TBX_WorkQueue_Fail. Row UPDLOCK/HOLDLOCK: Item muss existieren,CLAIMED sein,Token passen und Lease noch strikt in der Zukunft liegen.
--
-- Optionales ResultTable wird vor dem UPDATE vorbereitet. UPDATE macht exakt dasselbe aktive Token-/Lease-Item FAILED, setzt FailedAt/By,Code und eine auf nvarchar(1000) gebundene bereits bereinigte Message. Kein Retry und keine automatische Secretbereinigung. Ergebnis wird vor Commit in private Tabelle kopiert und gegebenenfalls geroutet. Eigener Commit oder Erhalt des Caller-TX; CATCH eigener Rollback beziehungsweise committable Savepointrollback. Debug>0 abstrakte Severity10-NOWAIT-Message danach. Claim-/Lease-/Recoveryhistorie bleibt im FAILED-Status erhalten; keine Slot-/Holdfreigabe eines Managedattempts allein durch direkten Fail.
--
-- ## Fehlerbehandlung
--
-- 54201 vor/unter Lock für gehaltenen oder ungeschützt verwalteten Claim.51925 fehlende/nichtpositive ID oder TokenNULL;51926 ungültiger ASCII-Code;51927 Message>2000Bytes;51929/1 doomedCaller, /2 fehlender ResultTablehelper.51928/1 Item fehlt,/2 nichtCLAIMED,/3 falschesToken,/5 Lease abgelaufen,/4 konkurrierend nicht genau ein UPDATE. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarchar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten; keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;
    SET @KeepData=ISNULL(@KeepData,0); SET @Debug=ISNULL(@Debug,0); SET @Hilfe=ISNULL(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_FailWorkCore' AS sysname) ObjectName,
               v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Schließt genau ein CLAIMED Work Item mit passendem ClaimToken als FAILED ab. Gespeichert werden nur ein stabiler Code und eine optionale bereinigte Kurzmeldung.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@EmitResult','bit',0,0,N'1',N'Privater Terminalkern: 0 unterdrückt das Fachresultset; keine Autoritätsfreigabe.',NULL),
          ('PARAMETER',2,N'@WorkItemId','bigint',1,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('PARAMETER',3,N'@ClaimToken','uniqueidentifier',1,0,NULL,N'Vom Claim zurückgegebenes Ownership-Token.',NULL),
          ('PARAMETER',4,N'@FailureCode','varchar(64)',1,0,NULL,N'Case-sensitiver ASCII-Code aus Buchstaben, Ziffern, Punkt, Unterstrich und Bindestrich.',NULL),
          ('PARAMETER',5,N'@FailureMessage','nvarchar(max)',0,1,NULL,N'Vom Aufrufer bereinigte Meldung mit höchstens 1000 Unicode-Codeeinheiten; keine Logs oder Stack Traces.',NULL),
          ('PARAMETER',6,N'@ResultTable','sysname',0,1,NULL,N'Optionale lokale Temp-Tabelle für die Statuszeile.',NULL),
          ('PARAMETER',7,N'@KeepData','bit',0,0,N'0',N'Steuert die ResultTable-Vorbereitung.',NULL),
          ('PARAMETER',8,N'@Debug','tinyint',0,0,N'0',N'Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung.',NULL),
          ('PARAMETER',9,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich dieses Help-Resultset aus.',NULL),
          ('RESULT_COLUMN',1,N'WorkItemId','bigint',0,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('RESULT_COLUMN',2,N'WorkTypeName','varchar(128)',0,0,NULL,N'Kanonischer Work-Type-Name.',NULL),
          ('RESULT_COLUMN',3,N'Status','varchar(16)',0,0,NULL,N'Nach Erfolg stets FAILED.',NULL),
          ('RESULT_COLUMN',4,N'EnqueuedAtUtc','datetime2(7)',0,0,NULL,N'UTC-Zeitpunkt der Einreihung.',NULL),
          ('RESULT_COLUMN',5,N'EnqueuedBy','sysname',0,0,NULL,N'Original-Login der Einreihung.',NULL),
          ('RESULT_COLUMN',6,N'ClaimedAtUtc','datetime2(7)',0,1,NULL,N'UTC-Zeitpunkt des Claims.',NULL),
          ('RESULT_COLUMN',7,N'ClaimedBy','sysname',0,1,NULL,N'Original-Login des Claimers.',NULL),
          ('RESULT_COLUMN',8,N'CompletedAtUtc','datetime2(7)',0,1,NULL,N'Bei FAILED NULL.',NULL),
          ('RESULT_COLUMN',9,N'CompletedBy','sysname',0,1,NULL,N'Bei FAILED NULL.',NULL),
          ('RESULT_COLUMN',10,N'FailedAtUtc','datetime2(7)',0,1,NULL,N'UTC-Zeitpunkt des Fehlabschlusses.',NULL),
          ('RESULT_COLUMN',11,N'FailedBy','sysname',0,1,NULL,N'Original-Login des Fail-Aufrufs.',NULL),
          ('RESULT_COLUMN',12,N'FailureCode','varchar(64)',0,1,NULL,N'Stabiler case-sensitiver Fehlercode.',NULL),
          ('RESULT_COLUMN',13,N'FailureMessage','nvarchar(1000)',0,1,NULL,N'Optionale bereinigte Fehlermeldung.',NULL),
          ('RESULT_COLUMN',14,N'RowVersion','binary(8)',0,0,NULL,N'Aktueller Concurrency-Marker.',NULL),
          ('RESULT_COLUMN',15,N'ClaimGeneration','bigint',0,0,NULL,N'Ownership-Generation des fehlgeschlagenen Claims.',NULL),
          ('RESULT_COLUMN',16,N'LeaseDurationSeconds','int',0,1,NULL,N'Lease-Dauer des fehlgeschlagenen Claims.',NULL),
          ('RESULT_COLUMN',17,N'LeaseUntilUtc','datetime2(7)',0,1,NULL,N'Lease-Grenze des fehlgeschlagenen Claims.',NULL),
          ('RESULT_COLUMN',18,N'LastHeartbeatAtUtc','datetime2(7)',0,1,NULL,N'Letzter Heartbeat des fehlgeschlagenen Claims.',NULL),
          ('RESULT_COLUMN',19,N'IsLeaseExpired','bit',0,0,NULL,N'Bei FAILED stets 0.',NULL),
          ('RESULT_COLUMN',20,N'RecoveryCount','bigint',0,0,NULL,N'Kumulierte Recoveries vor diesem Abschluss.',NULL),
          ('RESULT_COLUMN',21,N'LastRecoveredAtUtc','datetime2(7)',0,1,NULL,N'Zeitpunkt der letzten Recovery.',NULL),
          ('RESULT_COLUMN',22,N'LastRecoveredBy','sysname',0,1,NULL,N'Original-Login der letzten Recovery.',NULL),
          ('ERROR',1,N'51925-51929',NULL,NULL,NULL,NULL,N'Parameter-, Zustands-, Token-, Transaktions- oder ResultTable-Fehler.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Markiert einen synthetischen Auftrag als fehlgeschlagen.',N'EXEC toolbelt_core.USP_FailWork @WorkItemId=1,@ClaimToken=''00000000-0000-0000-0000-000000000001'',@FailureCode=''DEMO.ERROR'';')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END,v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_FailWorkCore' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-failworkcore"
description: "Tokengebundener endgültiger FAILED-Abschluss eines aktiven Queueclaims. Interner Kern."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_FailWorkCore"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@EmitResult", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1:direkter Fachresultset (Default);0 oderNULL:kein direkter SELECT. Keine zusätzliche Autorität. ResultTable-Routing bleibt bei Fail unabhängig davon möglich."}, {"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindes' AS nvarchar(max)) + N'trich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen."}, {"name": "@FailureMessage", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Der Parameter ist nvarchar(max); die Prozedur prüft die tatsächliche Länge vor Speicherung und weist größere Werte ab."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_def' + N'ault": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_FailWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "2.1.0"
public_entrypoints: ["toolbelt_core.USP_FailWork"]
---

# USP_FailWorkCore

## Zweck und Einsatzfälle

Tokengebundener endgültiger FAILED-Abschluss eines aktiven Queueclaims. Interner Kern. Öffentlich passenden Einstieg statt direktem Kernaufruf verwenden.

## Voraussetzungen

Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Eigene Transaktion oder gesunder Caller-TX mit Savepoint ist im vorhandenen Kern möglich; nicht pauschal als verboten beschreiben. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@EmitResult` | `bit` | `1` | Input | 1:direkter Fachresultset (Default);0 oderNULL:kein direkter SELECT. Keine zusätzliche Autorität. ResultTable-Routing bleibt bei Fail unabhängig davon möglich. |
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vor' + N'handenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST(''00000000-0000-0000-0000-000000000001'' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich erforderlicher stabiler ASCII-Code als varchar(64): 1..64 Zeichen, erstes A-Z/a-z, danach ausschließlich A-Z/a-z/0-9/Punkt/Unterstrich/Bindestrich. Case bleibt erhalten; kein Nachrichtentext oder Stacktrace. NULL/leer/ungültige Lexik wird abgewiesen. |
| `@FailureMessage` | `nvarchar(max)` | `NULL` | Input | Optionaler bereits vom Caller bereinigter Unicode-Fehlertext; NULL/leer ist zulässig, keine automatische Secretbereinigung oder JSON-Interpretation. Höchstens 1000 UTF-16-Codeeinheiten (2000 Bytes). Der Parameter ist nvarchar(max); die Prozedur prüft die tatsächliche Länge vor Speicherung und weist größere Werte ab. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen d' + N'em kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersatzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL |
| `WorkTypeName` | `varchar(128)` | NOT NULL |
| `Status` | `varchar(16)` | NOT NULL |
| `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL |
| `EnqueuedBy` | `sysname` | NOT NULL |
| `ClaimedAtUtc` | `datetime2(7)` | NULL |
| `ClaimedBy` | `sysname` | NULL |
| `CompletedAtUtc` | `datetime2(7)` | NULL |
| `CompletedBy` | `sysname` | NULL |
| `FailedAtUtc` | `datetime2(7)` | NULL |
| `FailedBy` | `sysname` | NULL |
| `FailureCode` | `varchar(64)` | NULL |
| `FailureMessage` | `nvarchar(1000)` | NULL |
| `RowVersion` | `binary(8)` | NOT NULL |
| `ClaimGeneration` | `bigint` | NOT NULL |
| `LeaseDurationSeconds` | `int` | NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
| `IsLeaseExpired` | `bit` | NOT NULL |
| `RecoveryCount` | `bigint` | NOT NULL |
| `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
| `LastRecoveredBy` | `sysname` | NULL |

Bei gültigem aktuellen Claim genau eine Statuszeile. Fail liefert die22 expliziten privaten Ergebnisspalten, nicht alle41 Viewfelder. EmitResult steuert den direkten SELECT wie beim Parameter beschrieben. ResultTableNULL:direkte Ausgabe; sonst vorbereitetes lokales Ziel mit den' + N'selben Spalten und ohne zusätzlichen direkten Fachresultset. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_FailWorkCore @Hilfe=1;
-- Fachpfad über öffentlichen Einstieg oder kontrollierten Managedprovider.
```

## Rechte

Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. ClaimToken bindet den vorhandenen aktiven Claim; der Code fordert hier keine neue WorkType-Policyentscheidung an. Gehaltene/verwaltete Arbeit verlangt zusätzlich den geschützten Managedabschluss, keinen öffentlichen Bypass. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.

## Ressourcenbedarf

Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. KeepData/Debug/Hilfe werden im Claim-/FailpfadNULL→0 normalisiert. ManagedHold oder eine ManagedReservation ohne passende completion_nonce und exklusiven Transaction-Disposition-AppLock wird vor und unter dem Row Lock mit54201 abgewehrt. Danach Pflicht-ID/Token, stabilen ASCII-FailureCode und t' + N'atsächliche Messagebreite prüfen; doomed Caller wird abgewiesen. Gesunder Caller-TX ist zulässig: eigener TX bei@@TRANCOUNT0, sonst Savepoint TBX_WorkQueue_Fail. Row UPDLOCK/HOLDLOCK: Item muss existieren,CLAIMED sein,Token passen und Lease noch strikt in der Zukunft liegen.

Optionales ResultTable wird vor dem UPDATE vorbereitet. UPDATE macht exakt dasselbe aktive Token-/Lease-Item FAILED, setzt FailedAt/By,Code und eine auf nvarchar(1000) gebundene bereits bereinigte Message. Kein Retry und keine automatische Secretbereinigung. Ergebnis wird vor Commit in private Tabelle kopiert und gegebenenfalls geroutet. Eigener Commit oder Erhalt des Caller-TX; CATCH eigener Rollback beziehungsweise committable Savepointrollback. Debug>0 abstrakte Severity10-NOWAIT-Message danach. Claim-/Lease-/Recoveryhistorie bleibt im FAILED-Status erhalten; keine Slot-/Holdfreigabe eines Managedattempts allein durch direkten Fail.

## Fehlerbehandlung

54201 vor/unter Lock für gehaltenen oder ungeschützt verwalteten Claim.51925 fehlende/nichtpositive ID oder TokenNULL;51926 ungültiger ASCII-Code;51927 Message>2000Bytes;51929/1 doomedCaller, /2 fehlender ResultTablehelper.51928/1 Item fehlt,/2 nichtCLAIMED,/3 falschesToken,/5 Lease abgelaufen,/4 konkurrierend nicht genau ein UPDATE. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarch' + N'ar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND
       (ManagedHold=1 OR (ManagedReservationId IS NOT NULL AND
        (ManagedCompletionNonce IS NULL OR TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce')) IS NULL
         OR ManagedCompletionNonce<>TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce'))
         OR APPLOCK_MODE(N'public',N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),ManagedReservationId),N'Transaction')<>N'Exclusive'))))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
    IF @WorkItemId IS NULL OR @WorkItemId<=0 OR @ClaimToken IS NULL THROW 51925,N'@WorkItemId und @ClaimToken sind erforderlich.',1;
    IF @FailureCode IS NULL OR LEN(@FailureCode) NOT BETWEEN 1 AND 64 OR @FailureCode NOT LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2 OR @FailureCode LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2 THROW 51926,N'@FailureCode ist kein gültiger stabiler ASCII-Code.',1;
    IF DATALENGTH(@FailureMessage)>2000 THROW 51927,N'@FailureMessage darf höchstens 1000 Unicode-Codeeinheiten enthalten.',1;
    IF XACT_STATE()=-1 THROW 51929,N'Ein Work Item kann in einer uncommittable Caller-Transaktion nicht fehlgeschlagen gesetzt werden.',1;

    CREATE TABLE #tbx_WorkQueue_StatusShape
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,IsLeaseExpired bit NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname NULL);
    CREATE TABLE #tbx_WorkQueue_StatusResult
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,IsLeaseExpired bit NOT NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname NULL);
    DECLARE @InitialTranCount int=@@TRANCOUNT,@CurrentStatus varchar(16),@CurrentToken uniqueidentifier,@LeaseUntilUtc datetime2(7),@NowUtc datetime2(7);
    IF @InitialTranCount=0 BEGIN TRANSACTION; ELSE SAVE TRANSACTION TBX_WorkQueue_Fail;
    BEGIN TRY
        SELECT @CurrentStatus=Status,@CurrentToken=ClaimToken,@LeaseUntilUtc=LeaseUntilUtc FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND
       (ManagedHold=1 OR (ManagedReservationId IS NOT NULL AND
        (ManagedCompletionNonce IS NULL OR TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce')) IS NULL
         OR ManagedCompletionNonce<>TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.completion_nonce'))
         OR APPLOCK_MODE(N'public',N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),ManagedReservationId),N'Transaction')<>N'Exclusive'))))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
        IF @CurrentStatus IS NULL THROW 51928,N'Das Work Item existiert nicht.',1;
        IF @CurrentStatus<>'CLAIMED' THROW 51928,N'Nur ein CLAIMED Work Item kann fehlgeschlagen gesetzt werden.',2;
        IF @CurrentToken<>@ClaimToken THROW 51928,N'@ClaimToken besitzt das Work Item nicht.',3;
        SET @NowUtc=SYSUTCDATETIME();
        IF @LeaseUntilUtc<=@NowUtc THROW 51928,N'Die Lease ist abgelaufen; nur Recovery darf den Claim verändern.',5;
        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51929,N'Für @ResultTable fehlt toolbelt.core.result-table.',2;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_StatusShape',@KeepData=@KeepData;
        END;
        UPDATE toolbelt_core.WorkItem SET Status='FAILED',FailedAtUtc=@NowUtc,FailedBy=ORIGINAL_LOGIN(),FailureCode=@FailureCode,FailureMessage=CONVERT(nvarchar(1000),@FailureMessage) WHERE WorkItemId=@WorkItemId AND Status='CLAIMED' AND ClaimToken=@ClaimToken AND LeaseUntilUtc>@NowUtc;
        IF @@ROWCOUNT<>1 THROW 51928,N'Der Claim-Zustand hat sich konkurrierend verändert.',4;
        INSERT INTO #tbx_WorkQueue_StatusResult SELECT WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy) SELECT WorkItemId,WorkTypeName,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,IsLeaseExpired,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy FROM #tbx_WorkQueue_StatusResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;
        IF @InitialTranCount=0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount=0 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_Fail;
        THROW;
    END CATCH;
    IF @Debug>0 RAISERROR(N'USP_FailWork: Work Item als FAILED abgeschlossen.',10,1) WITH NOWAIT;
    IF @EmitResult=1 AND @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_StatusResult;
    RETURN 0;
END;
GO
