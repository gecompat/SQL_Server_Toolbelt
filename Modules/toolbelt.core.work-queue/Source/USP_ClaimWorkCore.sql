-- Interner kanonischer Claimkern; keine öffentliche Admissionfreigabe.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ClaimWorkCore]
(
      @ManagedAdmissionToken uniqueidentifier = NULL
    , @ManagedReservationId uniqueidentifier = NULL
    , @ClaimedWorkItemId bigint = NULL OUTPUT
    , @EmitResult bit = 1
    , @LeaseDurationSeconds int = 300
    , @ResultTable sysname       = NULL
    , @KeepData    bit           = 0
    , @Debug       tinyint       = 0
    , @Hilfe       bit           = 0
)
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-claimworkcore"
-- description: "Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Interner Kern."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.work-queue"
-- schema_name: "toolbelt_core"
-- object_name: "USP_ClaimWorkCore"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@ManagedAdmissionToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL: normaler öffentlicher Queueclaim. NichtNULL: nur geschützte aktuelle GateNonce im selben gesunden Admission-TX, kein frei gewähltes Token."}, {"name": "@ManagedReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL im nicht verwalteten Pfad; bei Managed-Admission exakte aktuelle PendingReservationId derselben Gatezeile."}, {"name": "@ClaimedWorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "Privater OUTPUT der exakt per UPDATE OUTPUT geclaimten ID oderNULL. Normalpfad setzt vor ValidierungNULL; Hilfe verändert den eingehenden OUTPUT nicht. Nur nach erfolgreichem Gesamtlauf verwenden; frühe Fehler/variabler Altwert sind kein Claimbeweis."}, {"name": "@EmitResult", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "1:direktes Fachresultset (Default).0:direkte Ausgabe nur mit nichtNULL privatem ManagedAdmissionToken unterdrücken; ResultTable-Routing wird dadurch nicht ausgeschaltet. NULL ist54200/4."}, {"name": "@LeaseDurationSeconds", "sql_type": "int", "sql_default": "300", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
-- source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "2.1.0"
-- public_entrypoints: ["toolbelt_core.USP_ClaimWork", "toolbelt_core.USP_ClaimWorkerWork"]
-- ---
--
-- # USP_ClaimWorkCore
--
-- ## Zweck und Einsatzfälle
--
-- Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Interner Kern. Öffentlich passenden Einstieg statt direktem Kernaufruf verwenden.
--
-- ## Voraussetzungen
--
-- Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Keine Callertransaktion im öffentlichen Claimpfad. Private Managed-Admission verlangt genau eine gesunde bestehende Transaktion und passende Gatebindung. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@ManagedAdmissionToken` | `uniqueidentifier` | `NULL` | Input | NULL: normaler öffentlicher Queueclaim. NichtNULL: nur geschützte aktuelle GateNonce im selben gesunden Admission-TX, kein frei gewähltes Token. |
-- | `@ManagedReservationId` | `uniqueidentifier` | `NULL` | Input | NULL im nicht verwalteten Pfad; bei Managed-Admission exakte aktuelle PendingReservationId derselben Gatezeile. |
-- | `@ClaimedWorkItemId` | `bigint` | `NULL` | Input/OUTPUT | Privater OUTPUT der exakt per UPDATE OUTPUT geclaimten ID oderNULL. Normalpfad setzt vor ValidierungNULL; Hilfe verändert den eingehenden OUTPUT nicht. Nur nach erfolgreichem Gesamtlauf verwenden; frühe Fehler/variabler Altwert sind kein Claimbeweis. |
-- | `@EmitResult` | `bit` | `1` | Input | 1:direktes Fachresultset (Default).0:direkte Ausgabe nur mit nichtNULL privatem ManagedAdmissionToken unterdrücken; ResultTable-Routing wird dadurch nicht ausgeschaltet. NULL ist54200/4. |
-- | `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
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
-- | `WorkItemId` | `bigint` | NOT NULL; kanonische Queue-ID |
-- | `WorkTypeName` | `varchar(128)` | NOT NULL; BIN2 |
-- | `PayloadJson` | `nvarchar(max)` | NULL; vertrauliche Payload |
-- | `ClaimToken` | `uniqueidentifier` | NOT NULL; geheimes Claimtoken |
-- | `ClaimedAtUtc` | `datetime2(7)` | NOT NULL |
-- | `ClaimGeneration` | `bigint` | NOT NULL |
-- | `LeaseUntilUtc` | `datetime2(7)` | NOT NULL |
-- | `LastHeartbeatAtUtc` | `datetime2(7)` | NOT NULL |
--
-- Null oder eine Claimzeile; geheime Payload/ClaimToken privat behandeln. Kein passendes Item ergibt leeren Resultset. EmitResult steuert den direkten SELECT wie beim Parameter beschrieben. ResultTableNULL:direkte Ausgabe; sonst vorbereitetes lokales Ziel mit denselben Spalten und ohne zusätzlichen direkten Fachresultset. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_ClaimWorkCore @Hilfe=1;
-- -- Fachpfad über öffentlichen Einstieg oder kontrollierten Managedprovider.
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. CLAIM-Policy,Handler-Metadatensicht und EXECUTE auf den registrierten Handler werden geprüft. Kein Handleraufruf durch den Claim selbst. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.
--
-- ## Ressourcenbedarf
--
-- Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. KeepData/Debug/Hilfe werden im Claim-/FailpfadNULL→0 normalisiert. Der öffentliche Claim delegiert ohne Managedtoken an den einen kanonischen ClaimCore. Kein Caller-TX für diesen Pfad. Der Kern setzt sein privates OUTPUT zunächstNULL und validiert EmitResult, Transaktionsform und Lease5..86400. Eigene Transaktion oder im geschützten Managedpfad ein Savepoint. Gate/Scheduler werden mit UPDLOCK/HOLDLOCK gelesen. ManagedEnabled0 erlaubt keine privaten Token/Reservation; ManagedEnabled1 verlangt passende einmalige GateNonce und PendingReservation im selben gesunden Admission-TX. Bei Managed-Admission wird die Nonce verbraucht/erneuert. Reife Retrybarriers können BARRIER_WAIT werden und neue Blockersnapshots erhalten, auch wenn am Ende kein Item geclaimt wird.
--
-- Kandidat mit UPDLOCK,READPAST,READCOMMITTEDLOCK,ROWLOCK und Statusindex: aktiver WorkType, sichtbare nichtsystemeigene Handlerprocedure, CLAIM-Policy erlaubt und Handler-EXECUTE vorhanden. Kein ManagedHold. SHARED ist QUEUED oder fälliger RETRY_WAIT und durch keine wartende/laufende Gruppenbarrier blockiert. DRAIN_BARRIER muss BARRIER_WAIT sein, keine erfasste aktive Blockergeneration und keine anders priorisierte laufende Barrier derselben Gruppe haben. Reihenfolge: Priority DESC, dann Retrytermin beziehungsweise EnqueuedAtUtc, dann WorkItemId. Keine Preemption oder automatische Übernahme abgelaufener Claims.
--
-- Höchstens ein UPDATE: neuer ClaimToken/EngineUTC/ORIGINAL_LOGIN,ClaimGeneration+1,LeaseDuration/LeaseUntil/Heartbeat, CycleAttemptCount+1,NextAttemptNULL und gegebenenfalls ManagedReservationbindung. Exakte ID aus UPDATE OUTPUT, kein zweiter Claim. Zielvorbereitung/INSERT gehören zur Transaktion. Nur eigener TX wird committed; CATCH rollt eigenen TX oder committable Caller-Savepoint zurück. Debug>0 liefert danach eine abstrakte Severity10-NOWAIT-Message, kein Payload-/Tokenlogging. Ein späterer Debug-/Ergebnistransportfehler kann einen eigenen bereits erfolgten Commit nicht zurücknehmen.
--
-- ## Fehlerbehandlung
--
-- 54200/4 EmitResultNULL oder EmitResult0 ohne privaten Token.51910 unzulässige Transaktionsform;51911 LeaseNULL/außerhalb5..86400.54200/1 fehlender Managedgate, /2 private Bindung im Managedmodus fehlt/driftet, /3 private Werte bei deaktiviertem Managedmodus.51918 fehlender ResultTablehelper. Frühere OUTPUT-Initialisierung ist von Erfolg zu trennen. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.
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
        SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ClaimWorkCore' AS sysname) ObjectName,
               v.Section,v.Ordinal,v.ItemName,v.SqlDataType,v.IsRequired,v.IsNullable,v.DefaultValue,v.Description,v.ExampleSql
        FROM (VALUES
          (CAST('DESCRIPTION' AS varchar(32)),1,CAST(NULL AS sysname),CAST(NULL AS varchar(256)),CAST(NULL AS bit),CAST(NULL AS bit),CAST(NULL AS nvarchar(4000)),CAST(N'Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen.' AS nvarchar(max)),CAST(NULL AS nvarchar(max))),
          ('PARAMETER',1,N'@ManagedAdmissionToken','uniqueidentifier',0,1,NULL,N'Einmalige im selben Admission-TX persistierte private Nonce; kein öffentliches Dispatchrecht.',NULL),
          ('PARAMETER',2,N'@ManagedReservationId','uniqueidentifier',0,1,NULL,N'Im selben Admission-TX reservierte exakte Attempt-ID.',NULL),
          ('PARAMETER',3,N'@ClaimedWorkItemId','bigint',0,1,N'NULL',N'Privater OUTPUT: exakte kanonisch geclaimte ID oder NULL; keine freie Admission.',NULL),
          ('PARAMETER',4,N'@EmitResult','bit',0,0,N'1',N'0 unterdrückt nur bei geschützter Managed-Admission das direkte Fachresultset.',NULL),
          ('PARAMETER',5,N'@LeaseDurationSeconds','int',0,0,N'300',N'Lease-Dauer von 5 bis 86400 Sekunden.',NULL),
          ('PARAMETER',6,N'@ResultTable','sysname',0,1,NULL,N'Optionale lokale Temp-Tabelle für die Claim-Zeile.',NULL),
          ('PARAMETER',7,N'@KeepData','bit',0,0,N'0',N'Steuert die ResultTable-Vorbereitung.',NULL),
          ('PARAMETER',8,N'@Debug','tinyint',0,0,N'0',N'Erzeugt eine abstrakte Informationsmeldung.',NULL),
          ('PARAMETER',9,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich dieses Help-Resultset aus.',NULL),
          ('RESULT_COLUMN',1,N'WorkItemId','bigint',0,0,NULL,N'Eindeutige Queue-ID.',NULL),
          ('RESULT_COLUMN',2,N'WorkTypeName','varchar(128)',0,0,NULL,N'Kanonischer Work-Type-Name.',NULL),
          ('RESULT_COLUMN',3,N'PayloadJson','nvarchar(max)',0,1,NULL,N'Optionale bereinigte JSON-Payload.',NULL),
          ('RESULT_COLUMN',4,N'ClaimToken','uniqueidentifier',0,0,NULL,N'Geheimes Ownership-Token für Heartbeat, Complete oder Fail.',NULL),
          ('RESULT_COLUMN',5,N'ClaimedAtUtc','datetime2(7)',0,0,NULL,N'UTC-Zeitpunkt des Claims.',NULL),
          ('RESULT_COLUMN',6,N'ClaimGeneration','bigint',0,0,NULL,N'Monotoner Ownership-Zähler dieses Work Items.',NULL),
          ('RESULT_COLUMN',7,N'LeaseUntilUtc','datetime2(7)',0,0,NULL,N'Exklusive UTC-Grenze der Lease.',NULL),
          ('RESULT_COLUMN',8,N'LastHeartbeatAtUtc','datetime2(7)',0,0,NULL,N'Beim Claim identisch mit ClaimedAtUtc.',NULL),
          ('ERROR',1,N'51910-51918',NULL,NULL,NULL,NULL,N'Caller-Transaktions-, Lease- oder ResultTable-Fehler.',NULL),
          ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Beansprucht synthetische Arbeit für fünf Minuten.',N'EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;')
        )v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END,v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ClaimWorkCore' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-claimworkcore"
description: "Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Interner Kern."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_ClaimWorkCore"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ManagedAdmissionToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL: normaler öffentlicher Queueclaim. NichtNULL: nur geschützte aktuelle GateNonce im selben gesunden Admission-TX, kein frei gewähltes Token."}, {"name": "@ManagedReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL im nicht verwalteten Pfad; bei Managed-Admission exakte aktuelle PendingReservationId derselben Gatezeile."}, {"name": "@ClaimedWorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "Privater OUTPUT der exakt per UPDATE OUTPUT geclaimten ID oderNULL. Normalpfad setzt vor ValidierungNULL; Hilfe verändert den eingehenden OUTPUT nicht. Nur nach erfolgreichem Gesamtlauf verwenden; frühe Fehler/variabler Altwert sind kein Claimbeweis."}, {"name": "@EmitResult", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "1:direktes Fachresultset (Default).0:direkte Ausgabe nur mit nichtNULL privatem ManagedAdmissionToken unterdrücken; ResultTable-Routing wird dadurch nicht ausgeschaltet. NULL ist54200/4."}, {"name": "@LeaseDurationSeconds", "sql_type": "int", "sql_default": "300", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "descripti' AS nvarchar(max)) + N'on": "Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
' + N'source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "2.1.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWork", "toolbelt_core.USP_ClaimWorkerWork"]
---

# USP_ClaimWorkCore

## Zweck und Einsatzfälle

Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Interner Kern. Öffentlich passenden Einstieg statt direktem Kernaufruf verwenden.

## Voraussetzungen

Passende Queue2.1.0 mit WorkType-/ResultTable-Abhängigkeiten derselben Moduldatenbank. SQL2019/2022/2025 Windows/Linux mit zulässigem CL150/160/170,lokal/zentral. Tatsächliche aktuelle IDs/Token aus autorisierten Claim-/Statusausgaben verwenden. Keine Callertransaktion im öffentlichen Claimpfad. Private Managed-Admission verlangt genau eine gesunde bestehende Transaktion und passende Gatebindung. Hilfe ignoriert Fachargumente und kehrt vor Datenzugriff/Mutation zurück; SQL-Typkonvertierung liegt vorher.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@ManagedAdmissionToken` | `uniqueidentifier` | `NULL` | Input | NULL: normaler öffentlicher Queueclaim. NichtNULL: nur geschützte aktuelle GateNonce im selben gesunden Admission-TX, kein frei gewähltes Token. |
| `@ManagedReservationId` | `uniqueidentifier` | `NULL` | Input | NULL im nicht verwalteten Pfad; bei Managed-Admission exakte aktuelle PendingReservationId derselben Gatezeile. |
| `@ClaimedWorkItemId` | `bigint` | `NULL` | Input/OUTPUT | Privater OUTPUT der exakt per UPDATE OUTPUT geclaimten ID oderNULL. Normalpfad setzt vo' + N'r ValidierungNULL; Hilfe verändert den eingehenden OUTPUT nicht. Nur nach erfolgreichem Gesamtlauf verwenden; frühe Fehler/variabler Altwert sind kein Claimbeweis. |
| `@EmitResult` | `bit` | `1` | Input | 1:direktes Fachresultset (Default).0:direkte Ausgabe nur mit nichtNULL privatem ManagedAdmissionToken unterdrücken; ResultTable-Routing wird dadurch nicht ausgeschaltet. NULL ist54200/4. |
| `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersa' + N'tzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL; kanonische Queue-ID |
| `WorkTypeName` | `varchar(128)` | NOT NULL; BIN2 |
| `PayloadJson` | `nvarchar(max)` | NULL; vertrauliche Payload |
| `ClaimToken` | `uniqueidentifier` | NOT NULL; geheimes Claimtoken |
| `ClaimedAtUtc` | `datetime2(7)` | NOT NULL |
| `ClaimGeneration` | `bigint` | NOT NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NOT NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NOT NULL |

Null oder eine Claimzeile; geheime Payload/ClaimToken privat behandeln. Kein passendes Item ergibt leeren Resultset. EmitResult steuert den direkten SELECT wie beim Parameter beschrieben. ResultTableNULL:direkte Ausgabe; sonst vorbereitetes lokales Ziel mit denselben Spalten und ohne zusätzlichen direkten Fachresultset. Hilfe liefert bisherige Standardhilfe plus genau eine vollständige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max). Erfolgs-/Help-Return0; bei Retry ist normaler Abschluss ohne explizites RETURN0 im Core (implizite0), kein separater Erfolgsbeweis durch das allein.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ClaimWorkCore @Hilfe=1;
-- Fachpfad über öffentlichen Einstieg oder kontrollierten Managedprovider.
```

## Rechte

Vorhandenes EXECUTE auf den benötigten öffentlichen Einstieg; interne Kerne nur im bereits autorisierten Providerpfad nutzen, keine zusätzlichen Grants aus dem Skill ableiten. CLAIM-Policy,Handler-Metadatensicht und EXECUTE auf den registrierten Handler werden geprüft. Kein Handleraufruf durch den Claim selbst. Zentraler Dreiteilname braucht gültigen DBzugriff/Identitätsmapping; Basisobjektzugriff folgt tatsächlichen Ownership-Chains/Objektrechten. ResultTable verlangt passende vorhandene Temp-/Helperrechte, kein pauschales Serverrecht.

## Ressourcenbedarf

Queue-/Policy-/Barrierumfang und ko' + N'nkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. KeepData/Debug/Hilfe werden im Claim-/FailpfadNULL→0 normalisiert. Der öffentliche Claim delegiert ohne Managedtoken an den einen kanonischen ClaimCore. Kein Caller-TX für diesen Pfad. Der Kern setzt sein privates OUTPUT zunächstNULL und validiert EmitResult, Transaktionsform und Lease5..86400. Eigene Transaktion oder im geschützten Managedpfad ein Savepoint. Gate/Scheduler werden mit UPDLOCK/HOLDLOCK gelesen. ManagedEnabled0 erlaubt keine privaten Token/Reservation; ManagedEnabled1 verlangt passende einmalige GateNonce und PendingReservation im selben gesunden Admission-TX. Bei Managed-Admission wird die Nonce verbraucht/erneuert. Reife Retrybarriers können BARRIER_WAIT werden und neue Blockersnapshots erhalten, auch wenn am Ende kein Item geclaimt wird.

Kandidat mit UPDLOCK,READPAST,READCOMMITTEDLOCK,ROWLOCK und Statusindex: aktiver WorkType, sichtbare nichtsystemeigene Handlerprocedure, CLAIM-Policy erlaubt und Handler-EXECUTE vorhanden. Kein ManagedHold. SHARED ist QUEUED oder fälliger RETRY_WAIT und durch keine wartende/laufende Gruppenbarrier blockiert. DRAIN_BARRIER muss BARRIER_WAIT sein, keine erfasste aktive Blockergeneration und keine anders priorisierte laufende Barrier derselben Gruppe haben. Reihenfolge: Priority DESC, dann Retrytermin beziehungsweise EnqueuedAtUtc, dann WorkItemId. Keine Preemption oder automatische Übernahme abgelaufener Claims.

Höchstens ein UPDATE: neuer ClaimToken/EngineUTC/ORIGINAL_LOGIN,ClaimGeneration+1,LeaseDuration/LeaseUntil/Heartbeat, CycleAttemptCount+1,NextAttemptNUL' + N'L und gegebenenfalls ManagedReservationbindung. Exakte ID aus UPDATE OUTPUT, kein zweiter Claim. Zielvorbereitung/INSERT gehören zur Transaktion. Nur eigener TX wird committed; CATCH rollt eigenen TX oder committable Caller-Savepoint zurück. Debug>0 liefert danach eine abstrakte Severity10-NOWAIT-Message, kein Payload-/Tokenlogging. Ein späterer Debug-/Ergebnistransportfehler kann einen eigenen bereits erfolgten Commit nicht zurücknehmen.

## Fehlerbehandlung

54200/4 EmitResultNULL oder EmitResult0 ohne privaten Token.51910 unzulässige Transaktionsform;51911 LeaseNULL/außerhalb5..86400.54200/1 fehlender Managedgate, /2 private Bindung im Managedmodus fehlt/driftet, /3 private Werte bei deaktiviertem Managedmodus.51918 fehlender ResultTablehelper. Frühere OUTPUT-Initialisierung ist von Erfolg zu trennen. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarchar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
    END;

    SET @ClaimedWorkItemId=NULL;
    IF @EmitResult IS NULL OR (@EmitResult=0 AND @ManagedAdmissionToken IS NULL) THROW 54200,N'Privater Claimtransport verlangt die geschützte Admission.',4;
    IF (@ManagedAdmissionToken IS NULL AND @@TRANCOUNT<>0) OR (@ManagedAdmissionToken IS NOT NULL AND (@@TRANCOUNT<>1 OR XACT_STATE()<>1))
        THROW 51910,N'USP_ClaimWork darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
    IF @LeaseDurationSeconds IS NULL OR @LeaseDurationSeconds NOT BETWEEN 5 AND 86400
        THROW 51911,N'@LeaseDurationSeconds muss zwischen 5 und 86400 liegen.',1;

    CREATE TABLE #tbx_WorkQueue_ClaimShape
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,PayloadJson nvarchar(max) NULL,ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL);
    CREATE TABLE #tbx_WorkQueue_ClaimResult
    (WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,PayloadJson nvarchar(max) NULL,ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL);
    DECLARE @Claimed TABLE(WorkItemId bigint NOT NULL PRIMARY KEY);
    DECLARE @NowUtc datetime2(7)=SYSUTCDATETIME(),@ClaimToken uniqueidentifier=NEWID(),@ClaimedBy sysname=ORIGINAL_LOGIN();

    DECLARE @InitialTransactionCount int=@@TRANCOUNT,@ManagedEnabled bit,@GateToken uniqueidentifier,@PendingReservationId uniqueidentifier;
    IF @InitialTransactionCount=0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION TBX_WorkQueue_ClaimCore;
    BEGIN TRY
        SELECT @ManagedEnabled=ManagedEnabled,@GateToken=AdmissionToken,@PendingReservationId=PendingReservationId
        FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
        IF @ManagedEnabled IS NULL THROW 54200,N'Der neutrale Managed-Gate fehlt.',1;
        IF @ManagedEnabled=1 AND (@ManagedAdmissionToken IS NULL OR @ManagedAdmissionToken<>@GateToken OR @ManagedReservationId IS NULL OR @PendingReservationId IS NULL OR @ManagedReservationId<>@PendingReservationId)
            THROW 54200,N'Managed-Betrieb verlangt den geschützten Admissionpfad.',2;
        IF @ManagedEnabled=0 AND (@ManagedAdmissionToken IS NOT NULL OR @ManagedReservationId IS NOT NULL)
            THROW 54200,N'Managed-Betrieb ist nicht aktiviert.',3;
        /* Der Scheduler-Lock schließt das Rennen zwischen Claim und Barrier-Snapshot. */
        DECLARE @SchedulerId int; SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH (UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
        IF @ManagedAdmissionToken IS NOT NULL UPDATE toolbelt_core.WorkQueueManagedGate SET PendingReservationId=NULL,AdmissionToken=NEWID() WHERE GateId=1;
        SET @NowUtc=SYSUTCDATETIME();
        DECLARE @ArmedBarrier TABLE(WorkItemId bigint NOT NULL,BarrierEpoch bigint NOT NULL,ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Priority tinyint NOT NULL);
        UPDATE wi SET Status='BARRIER_WAIT',BarrierEpoch=BarrierEpoch+1,NextAttemptAtUtc=NULL
        OUTPUT inserted.WorkItemId,inserted.BarrierEpoch,inserted.ExecutionGroup,inserted.Priority INTO @ArmedBarrier
        FROM toolbelt_core.WorkItem wi
        WHERE wi.ManagedHold=0 AND wi.Status='RETRY_WAIT' AND wi.ExecutionMode='DRAIN_BARRIER' AND wi.NextAttemptAtUtc<=@NowUtc;
        INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration)
        SELECT armed.WorkItemId,armed.BarrierEpoch,blocker.WorkItemId,blocker.ClaimGeneration
        FROM @ArmedBarrier armed
        JOIN toolbelt_core.WorkItem blocker ON blocker.Status='CLAIMED' AND blocker.ExecutionGroup=armed.ExecutionGroup
        WHERE NOT(blocker.ExecutionMode='DRAIN_BARRIER' AND blocker.Priority=armed.Priority);
        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51918,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_ClaimShape',@KeepData=@KeepData;
        END;

        SET @NowUtc=SYSUTCDATETIME();
        ;WITH Candidate AS
        (
            SELECT TOP (1) wi.*
            FROM toolbelt_core.WorkItem wi WITH (UPDLOCK, READPAST, READCOMMITTEDLOCK, ROWLOCK, INDEX(IX_WorkItem_Status_WorkItemId))
            JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId AND wt.IsEnabled=1
            JOIN sys.schemas hs ON hs.name=wt.HandlerSchema
            JOIN sys.procedures hp ON hp.schema_id=hs.schema_id AND hp.name=wt.HandlerProcedure AND hp.is_ms_shipped=0
            CROSS APPLY toolbelt_core.TVF_WorkTypeAuthorization(wt.WorkTypeId,'CLAIM') authority
            WHERE authority.IsAllowed=1
            AND ISNULL(HAS_PERMS_BY_NAME(QUOTENAME(wt.HandlerSchema)+N'.'+QUOTENAME(wt.HandlerProcedure),N'OBJECT',N'EXECUTE'),0)=1
            AND wi.ManagedHold=0 AND
            (
            (
                (wi.Status='QUEUED' OR (wi.Status='RETRY_WAIT' AND wi.NextAttemptAtUtc<=@NowUtc))
                AND wi.ExecutionMode='SHARED'
                AND NOT EXISTS
                (
                    SELECT 1 FROM toolbelt_core.WorkItem barrier
                    WHERE barrier.ExecutionGroup=wi.ExecutionGroup
                      AND barrier.ExecutionMode='DRAIN_BARRIER'
                      AND barrier.Status IN('BARRIER_WAIT','CLAIMED')
                )
            )
            OR
            (
                wi.Status='BARRIER_WAIT' AND wi.ExecutionMode='DRAIN_BARRIER'
                AND NOT EXISTS
                (
                    SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker b
                    JOIN toolbelt_core.WorkItem blocker ON blocker.WorkItemId=b.BlockingWorkItemId
                    WHERE b.BarrierWorkItemId=wi.WorkItemId AND b.BarrierEpoch=wi.BarrierEpoch
                      AND blocker.Status='CLAIMED' AND blocker.ClaimGeneration=b.BlockingClaimGeneration
                )
                AND NOT EXISTS
                (
                    SELECT 1 FROM toolbelt_core.WorkItem otherBarrier
                    WHERE otherBarrier.ExecutionGroup=wi.ExecutionGroup AND otherBarrier.ExecutionMode='DRAIN_BARRIER'
                      AND otherBarrier.Status='CLAIMED' AND otherBarrier.Priority<>wi.Priority
                )
            )
            )
            ORDER BY wi.Priority DESC,CASE WHEN wi.Status='RETRY_WAIT' THEN wi.NextAttemptAtUtc ELSE wi.EnqueuedAtUtc END,wi.WorkItemId
        )
        UPDATE Candidate SET
              ManagedReservationId=@ManagedReservationId,ManagedCompletionNonce=NULL,Status='CLAIMED',ClaimedAtUtc=@NowUtc,ClaimedBy=@ClaimedBy,ClaimToken=@ClaimToken
            , ClaimGeneration=ClaimGeneration+1,LeaseDurationSeconds=@LeaseDurationSeconds
            , LeaseUntilUtc=DATEADD(SECOND,@LeaseDurationSeconds,@NowUtc),LastHeartbeatAtUtc=@NowUtc
            , CycleAttemptCount=CycleAttemptCount+1,NextAttemptAtUtc=NULL
        OUTPUT inserted.WorkItemId INTO @Claimed(WorkItemId);

        SELECT @ClaimedWorkItemId=WorkItemId FROM @Claimed;

        INSERT INTO #tbx_WorkQueue_ClaimResult
        SELECT wi.WorkItemId,wt.WorkTypeName,wi.PayloadJson,wi.ClaimToken,wi.ClaimedAtUtc,
               wi.ClaimGeneration,wi.LeaseUntilUtc,wi.LastHeartbeatAtUtc
        FROM @Claimed claimed JOIN toolbelt_core.WorkItem wi ON wi.WorkItemId=claimed.WorkItemId
        JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId;

        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' (WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc) SELECT WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc FROM #tbx_WorkQueue_ClaimResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;
        IF @InitialTransactionCount=0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTransactionCount=0 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
        ELSE IF @InitialTransactionCount>0 AND XACT_STATE()=1 ROLLBACK TRANSACTION TBX_WorkQueue_ClaimCore;
        THROW;
    END CATCH;
    IF @Debug>0 RAISERROR(N'USP_ClaimWork: atomarer Lease-Claim abgeschlossen.',10,1) WITH NOWAIT;
    IF @ResultTable IS NULL AND @EmitResult=1 SELECT WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc FROM #tbx_WorkQueue_ClaimResult;
    RETURN 0;
END;
GO
