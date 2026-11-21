-- Objekt: toolbelt_core.USP_FinalizeWorkerFailure
-- Zweck: Konsumiert bewiesenen Rollback und finalisiert expliziten Fail/Retry; frischer Hold oder abgelaufene Lease gewinnt.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_FinalizeWorkerFailure
 @SlotReservationId uniqueidentifier=NULL,
 @ClaimToken uniqueidentifier=NULL,
 @ExecutionId uniqueidentifier=NULL,
 @FailureCode varchar(64)=NULL,
 @Retry bit=0,
 @Outcome varchar(24)=NULL OUTPUT,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-finalizeworkerfailure"
-- description: "Finalisiert nach bewiesenem Rollback eine Fail-/Retryentscheidung oder einen gehaltenen Abbruch."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_FinalizeWorkerFailure"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich nichtNULL. Im heldfreien Fail-/Retrykern stabiler ASCII-Code:beginnt A-Z/a-z,danach nurBuchstaben/Ziffern/Punkt/Unterstrich/Bindestrich,bis64Zeichen. Held-/Leaseablaufzweig benutzt stattdessen WORKER.STOP_HELD und prüft hier nur NichtNULL; keine uniforme vollständige Syntaxprüfung vor beiden Zweigen behaupten."}, {"name": "@Retry", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "0:heldfrei FAILED über FailCore (Default);1:gespeicherte Retrypolicy entscheidet RETRY_WAIT oder DEAD_LETTER.NULL ungültig. Hold oder Leaseablauf gewinnt unabhängig vom Wert."}, {"name": "@Outcome", "sql_type": "varchar(24)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler OUTPUT,kein Eingabesteuerwert. Erfolg:ROLLED_BACK_HELD,FAILED,RETRY_WAIT oder DEAD_LETTER. Caller für Übernahme ausdrücklich OUTPUT angeben. Vor Hilfe/Frühfehlern keine Initialisierung; ein vorgefundener Variablenwert ist kein Erfolgbeweis. Zuweisung erfolgt vor Commit, bei SQL-Fehler keine erfolgreiche Finalisierung daraus ableiten."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_FinalizeWorkerFailure.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/USP_FailWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetryCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
-- ---
--
-- # USP_FinalizeWorkerFailure
--
-- ## Zweck und Einsatzfälle
--
-- Finalisiert nach bewiesenem Rollback eine Fail-/Retryentscheidung oder einen gehaltenen Abbruch. Internes Objekt;kein manuelles Fachaufrufbeispiel als Ersatzprovider.
--
-- ## Voraussetzungen
--
-- Interner Managedproviderhelfer, kein öffentlicher manueller Dispatch-/Recovery-/Replayweg. Kontrollierten Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet keinen direkten Aufruf jedes Helpers durch jeden öffentlichen Einstieg. Worker-Control1.0.0,Queue2.1.0 und passende Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank; SQL2019/2022/2025 Windows/Linux, zulässigesCL150/160/170 lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0; keine Caller-Savepoints oder frei erfundenen IDs/Tokens.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
-- | `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
-- | `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
-- | `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich nichtNULL. Im heldfreien Fail-/Retrykern stabiler ASCII-Code:beginnt A-Z/a-z,danach nurBuchstaben/Ziffern/Punkt/Unterstrich/Bindestrich,bis64Zeichen. Held-/Leaseablaufzweig benutzt stattdessen WORKER.STOP_HELD und prüft hier nur NichtNULL; keine uniforme vollständige Syntaxprüfung vor beiden Zweigen behaupten. |
-- | `@Retry` | `bit` | `0` | Input | 0:heldfrei FAILED über FailCore (Default);1:gespeicherte Retrypolicy entscheidet RETRY_WAIT oder DEAD_LETTER.NULL ungültig. Hold oder Leaseablauf gewinnt unabhängig vom Wert. |
-- | `@Outcome` | `varchar(24)` | `NULL` | Input/OUTPUT | Optionaler OUTPUT,kein Eingabesteuerwert. Erfolg:ROLLED_BACK_HELD,FAILED,RETRY_WAIT oder DEAD_LETTER. Caller für Übernahme ausdrücklich OUTPUT angeben. Vor Hilfe/Frühfehlern keine Initialisierung; ein vorgefundener Variablenwert ist kein Erfolgbeweis. Zuweisung erfolgt vor Commit, bei SQL-Fehler keine erfolgreiche Finalisierung daraus ableiten. |
-- | `@Debug` | `tinyint` | `0` | Input | 0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf. |
--
-- SQL-Parametertypkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults dienen der Hilfe,keiner erfolgreichen Fachbindung.
--
-- ## Ergebnisse
--
-- Kein fachlicher Resultset und keine ResultTable-/KeepData-Option. RETURN0 sowie optional OutcomeOUTPUT nach erfolgreicher Finalisierung. @Outcome wird bei reiner Hilfe nicht überschrieben. Helper-/Enginefehler statt fachlicher Fehlerstatuszeilen. Hilfe: bestehender zwölfspaltiger Standardhelp plus genau eine vollständige vier-spaltige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),danach RETURN0. Alle Parameter besitzen technische Defaults.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_FinalizeWorkerFailure @Hilfe=1;
-- -- Fachpfad ausschließlich über kontrollierten Managedprovider mit tatsächlicher Bindung.
-- ```
--
-- ## Rechte
--
-- Nur vorhandene autorisierte interne EXECUTE-/Objekt-/Ownership-Chainrechte im kontrollierten Providerpfad nutzen; keine Rechte erteilen oder aus diesem Skill ableiten. Worker-/Claimtoken sind vertraulich und nicht austauschbar. Principalbindungen verwenden USER_ID der Moduldatenbank,keine Host-/Serveridentitätsattestation. AppLock-DbPrincipal public beschreibt hier den Locknamespace,keinen neuen Grant. Sessioncontext allein ist keine vollständige Autorität.
--
-- ## Ressourcenbedarf
--
-- Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Disposition-AppLock-Timeout5000ms ist kein Timeout für die gesamte Finalisierung. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Neutrales CallerTX vor eigener BEGIN. Exklusiver Session-Attempt-AppLock,konvertierbare Sessionattemptnonce sowie exaktes belegtes Slot/Claim/Execution/Nonce/BoundPrincipalId=USER_ID-Tupel erforderlich. Transaction-Disposition-AppLock5000ms/public,FailureCode/Retry nichtNULL. Locking Prüfung:Reservation ROLLED_BACK/IsOccupied1 und kein Witness zu diesem Slot; passende Disposition muss existieren. Hold1 ODER WorkItem-Lease<=EngineUTC gewinnt: exakt unverändertes CLAIMED-Item wird FAILED mit WORKER.STOP_HELD,FailureMessageNULL,ManagedHold1,ManagedCompletionNonceNULL; Reservation bleibtROLLED_BACK,wirdfrei/EndedAtUTC; Disposition bleibtheld/ROLLED_BACK_HELD; OutcomeROLLED_BACK_HELD. Sonst neue completion_nonce im Sessioncontext und exakt gebundener WorkItem.ManagedCompletionNonce; FailCore oder RetryCore mit EmitResult0/FailureCode und sonstDefaults aufrufen. Kerne prüfen erneut geschützte Terminalautorität und aktuelle Lease/Token; Lease kann zwischen Prüfungen ablaufen und dann einen ursprünglichen Queuefehler auslösen. Fail:FAILED; Retry:bei verbrauchten MaxAttempts DEAD_LETTER,sonst RETRY_WAIT mit min(Base*2^(CycleAttemptCount-1),MaxDelay),keinJitter. Outcome aus tatsächlichem Status lesen; nur heldfreie FAILED/RETRY_WAIT/DEAD_LETTER-Zeile mit exakter Reservation/Generation wird von ManagedCompletionNonce/ManagedReservationId gelöst. Reservation IsOccupied0/EndedAtUTC,State bleibtROLLED_BACK; Attempt-/Execution-/Claimhistory und Disposition werden nicht gelöscht. Keine Handlertransaktion durch diesen Aufruf zurückrollen oder erneut ausführen. Kontextnonce wird hier nicht zurückgesetzt. Outcome-Zuweisung erfolgt vor eigener COMMIT; CATCH rollt eigene aktive Buchung zurück und wirft, ohne einen beliebigen OUTPUT-Wert als Commitbeweis zu legitimieren.
--
-- ## Fehlerbehandlung
--
-- 54210/1 nichtneutraler Caller.54220/1 fehlende IDs/Nonce/Sessionattemptlock;54220/2 fehlende exakte belegte Principalbindung.54222/2 negativer Disposition-AppLock-Rückgabecode.54213/6 FailureCodeNULL oder RetryNULL.54223/2 keine ROLLED_BACK/IsOccupied1-Reservation oder irgendein Witness vorhanden;54223/3 passende Disposition fehlt.54220/5 heldgebundener Claim verändert;54220/7 heldfreier Terminalclaim verändert;54220/8 keine exakt heldfrei gelöste terminale Queueentscheidung. Delegierte Fehler bleiben sichtbar:geschützter Managedpfad54201,Fail51925..51929/Retry51985..51989 und technische Enginefehler. TypedParameterkonvertierung kann vor diesen Prüfungen wirken. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_FinalizeWorkerFailure' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Konsumiert bewiesenen Rollback und finalisiert expliziten Fail/Retry; frischer Hold oder abgelaufene Lease gewinnt.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ClaimToken',NULL),
 ('PARAMETER',3,N'@ExecutionId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExecutionId',NULL),
 ('PARAMETER',4,N'@FailureCode',N'varchar(64)',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: FailureCode',NULL),
 ('PARAMETER',5,N'@Retry',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Retry',NULL),
 ('PARAMETER',6,N'@Outcome',N'varchar(24)',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Outcome',NULL),
 ('PARAMETER',7,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',8,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_FinalizeWorkerFailure @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
-- OBJECT_USAGE_SKILL_HELP:COMPACT
 -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_FinalizeWorkerFailure' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-finalizeworkerfailure"
description: "Finalisiert nach bewiesenem Rollback eine Fail-/Retryentscheidung oder einen gehaltenen Abbruch."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_FinalizeWorkerFailure"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich nichtNULL. Im heldfreien Fail-/Retrykern stabiler ASCII-Code:beginnt A-Z/a-z,danach nurBuchstaben/Ziffern/Punkt/Unterstrich/Bindestrich,bis64Zeichen. Held-/Leaseablaufzweig benutzt stattdessen WORKER.STOP_HELD und prüft hier nur NichtNULL; keine uniforme vollständige Syntaxprüfung vor beiden Zweigen behaupten."}, {"name": "@Retr' AS nvarchar(max)) + N'y", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "0:heldfrei FAILED über FailCore (Default);1:gespeicherte Retrypolicy entscheidet RETRY_WAIT oder DEAD_LETTER.NULL ungültig. Hold oder Leaseablauf gewinnt unabhängig vom Wert."}, {"name": "@Outcome", "sql_type": "varchar(24)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler OUTPUT,kein Eingabesteuerwert. Erfolg:ROLLED_BACK_HELD,FAILED,RETRY_WAIT oder DEAD_LETTER. Caller für Übernahme ausdrücklich OUTPUT angeben. Vor Hilfe/Frühfehlern keine Initialisierung; ein vorgefundener Variablenwert ist kein Erfolgbeweis. Zuweisung erfolgt vor Commit, bei SQL-Fehler keine erfolgreiche Finalisierung daraus ableiten."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_FinalizeWorkerFailure.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/USP_FailWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetryCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_Recon' + N'cileWorkerExecution"]
---

# USP_FinalizeWorkerFailure

## Zweck und Einsatzfälle

Finalisiert nach bewiesenem Rollback eine Fail-/Retryentscheidung oder einen gehaltenen Abbruch. Internes Objekt;kein manuelles Fachaufrufbeispiel als Ersatzprovider.

## Voraussetzungen

Interner Managedproviderhelfer, kein öffentlicher manueller Dispatch-/Recovery-/Replayweg. Kontrollierten Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet keinen direkten Aufruf jedes Helpers durch jeden öffentlichen Einstieg. Worker-Control1.0.0,Queue2.1.0 und passende Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank; SQL2019/2022/2025 Windows/Linux, zulässigesCL150/160/170 lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0; keine Caller-Savepoints oder frei erfundenen IDs/Tokens.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich nichtNULL. Im heldfreien Fail-/Retrykern stabiler ASCII-Code:beginnt A-Z/a-z,danach nurBuchstaben/Ziffern/Punkt/Unterstrich/Bindestrich,bis64Zeichen. Held-/Leaseablaufzweig benutzt stattdessen WORKER.STOP_HELD und prüft hier nur NichtNULL; keine uniforme vollständige Syntaxprüfung vo' + N'r beiden Zweigen behaupten. |
| `@Retry` | `bit` | `0` | Input | 0:heldfrei FAILED über FailCore (Default);1:gespeicherte Retrypolicy entscheidet RETRY_WAIT oder DEAD_LETTER.NULL ungültig. Hold oder Leaseablauf gewinnt unabhängig vom Wert. |
| `@Outcome` | `varchar(24)` | `NULL` | Input/OUTPUT | Optionaler OUTPUT,kein Eingabesteuerwert. Erfolg:ROLLED_BACK_HELD,FAILED,RETRY_WAIT oder DEAD_LETTER. Caller für Übernahme ausdrücklich OUTPUT angeben. Vor Hilfe/Frühfehlern keine Initialisierung; ein vorgefundener Variablenwert ist kein Erfolgbeweis. Zuweisung erfolgt vor Commit, bei SQL-Fehler keine erfolgreiche Finalisierung daraus ableiten. |
| `@Debug` | `tinyint` | `0` | Input | 0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf. |

SQL-Parametertypkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults dienen der Hilfe,keiner erfolgreichen Fachbindung.

## Ergebnisse

Kein fachlicher Resultset und keine ResultTable-/KeepData-Option. RETURN0 sowie optional OutcomeOUTPUT nach erfolgreicher Finalisierung. @Outcome wird bei reiner Hilfe nicht überschrieben. Helper-/Enginefehler statt fachlicher Fehlerstatuszeilen. Hilfe: bestehender zwölfspaltiger Standardhelp plus genau eine vollständige vier-spaltige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),danach RETURN0. Alle Parameter besitzen technische Defaults.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_FinalizeWorkerFailure @Hilfe=1;
-- Fachpfad ausschließlich über kontrollierten Managedprovider mit tatsächlicher Bindung.
```

## Rechte

Nur vorhandene autorisierte interne EXECUTE-/Objekt-/Ownership-Chainrechte im kontrollierten Providerpfad nutzen; keine Rechte ' + N'erteilen oder aus diesem Skill ableiten. Worker-/Claimtoken sind vertraulich und nicht austauschbar. Principalbindungen verwenden USER_ID der Moduldatenbank,keine Host-/Serveridentitätsattestation. AppLock-DbPrincipal public beschreibt hier den Locknamespace,keinen neuen Grant. Sessioncontext allein ist keine vollständige Autorität.

## Ressourcenbedarf

Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Disposition-AppLock-Timeout5000ms ist kein Timeout für die gesamte Finalisierung. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Neutrales CallerTX vor eigener BEGIN. Exklusiver Session-Attempt-AppLock,konvertierbare Sessionattemptnonce sowie exaktes belegtes Slot/Claim/Execution/Nonce/BoundPrincipalId=USER_ID-Tupel erforderlich. Transaction-Disposition-AppLock5000ms/public,FailureCode/Retry nichtNULL. Locking Prüfung:Reservation ROLLED_BACK/IsOccupied1 und kein Witness zu diesem Slot; passende Disposition muss existieren. Hold1 ODER WorkItem-Lease<=EngineUTC gewinnt: exakt unverändertes CLAIMED-Item wird FAILED mit WORKER.STOP_HELD,FailureMessageNULL,ManagedHold1,ManagedCompletionNonceNULL; Reservation bleibtROLLED_BACK,wirdfrei/EndedAtUTC; Disposition bleibtheld/ROLLED_BACK_HELD; OutcomeROLLED_BACK_HELD. Sonst neue completion_nonce im Sessioncontext und exakt gebundener WorkItem.ManagedCompletionNonce; FailCore oder RetryCore mit EmitResult0/FailureCode und sonstDefaults aufrufen. Kerne prüfen erneut geschützte Terminalautorität und aktuelle Lease/Token; Lease kann zwischen Prüfungen ablaufen und dann einen ursprünglichen Queuefehler auslösen. Fail:FAILED; Retry:bei verbrauchten Ma' + N'xAttempts DEAD_LETTER,sonst RETRY_WAIT mit min(Base*2^(CycleAttemptCount-1),MaxDelay),keinJitter. Outcome aus tatsächlichem Status lesen; nur heldfreie FAILED/RETRY_WAIT/DEAD_LETTER-Zeile mit exakter Reservation/Generation wird von ManagedCompletionNonce/ManagedReservationId gelöst. Reservation IsOccupied0/EndedAtUTC,State bleibtROLLED_BACK; Attempt-/Execution-/Claimhistory und Disposition werden nicht gelöscht. Keine Handlertransaktion durch diesen Aufruf zurückrollen oder erneut ausführen. Kontextnonce wird hier nicht zurückgesetzt. Outcome-Zuweisung erfolgt vor eigener COMMIT; CATCH rollt eigene aktive Buchung zurück und wirft, ohne einen beliebigen OUTPUT-Wert als Commitbeweis zu legitimieren.

## Fehlerbehandlung

54210/1 nichtneutraler Caller.54220/1 fehlende IDs/Nonce/Sessionattemptlock;54220/2 fehlende exakte belegte Principalbindung.54222/2 negativer Disposition-AppLock-Rückgabecode.54213/6 FailureCodeNULL oder RetryNULL.54223/2 keine ROLLED_BACK/IsOccupied1-Reservation oder irgendein Witness vorhanden;54223/3 passende Disposition fehlt.54220/5 heldgebundener Claim verändert;54220/7 heldfreier Terminalclaim verändert;54220/8 keine exakt heldfrei gelöste terminale Queueentscheidung. Delegierte Fehler bleiben sichtbar:geschützter Managedpfad54201,Fail51925..51929/Retry51985..51989 und technische Enginefehler. TypedParameterkonvertierung kann vor diesen Prüfungen wirken. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/' + N'Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
' AS SkillMarkdown;
 -- OBJECT_USAGE_SKILL_HELP:END
 RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @Resource nvarchar(255)=N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),@Nonce uniqueidentifier=TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.attempt_nonce')),@Item bigint,@Generation bigint;
 IF @SlotReservationId IS NULL OR @ClaimToken IS NULL OR @ExecutionId IS NULL OR @Nonce IS NULL OR APPLOCK_MODE(N'public',@Resource,N'Session')<>N'Exclusive' THROW 54220,N'Die tatsächliche Handlerconnection besitzt den Attempt nicht.',1;
 SELECT @Item=WorkItemId,@Generation=ClaimGeneration FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@SlotReservationId AND ClaimToken=@ClaimToken AND ExecutionId=@ExecutionId AND AttemptNonce=@Nonce AND BoundPrincipalId=USER_ID() AND IsOccupied=1;
 IF @Item IS NULL THROW 54220,N'Die Attemptbindung ist veraltet oder widersprüchlich.',2;
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=5000,@DbPrincipal=N'public';
 IF @Lock<0 THROW 54222,N'Der private Disposition-Gate ist nicht verfügbar.',2;
 IF @FailureCode IS NULL OR @Retry IS NULL THROW 54213,N'Die Terminalentscheidung verlangt gültige Fehlerdaten.',6;
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId AND State='ROLLED_BACK' AND IsOccupied=1)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId) THROW 54223,N'Der atomare Rollbacknachweis fehlt.',2;
 DECLARE @Held bit;SELECT @Held=IsHeld FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @Held IS NULL THROW 54223,N'Die exakte Disposition fehlt.',3;
 IF @Held=1 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND LeaseUntilUtc<=SYSUTCDATETIME())
 BEGIN
 UPDATE toolbelt_core.WorkItem SET Status='FAILED',FailedAtUtc=SYSUTCDATETIME(),FailedBy=ORIGINAL_LOGIN(),FailureCode='WORKER.STOP_HELD',FailureMessage=NULL,ManagedHold=1,ManagedCompletionNonce=NULL
 WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ClaimToken=@ClaimToken AND Status='CLAIMED';
 IF @@ROWCOUNT<>1 THROW 54220,N'Der bewiesene Rollback gehört keinem unveränderten Claim.',5;
 UPDATE toolbelt_core.WorkerSlotReservation SET State='ROLLED_BACK',IsOccupied=0,EndedAtUtc=SYSUTCDATETIME() WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus='ROLLED_BACK_HELD' WHERE SlotReservationId=@SlotReservationId;
 SET @Outcome='ROLLED_BACK_HELD';
 END
 ELSE
 BEGIN
  DECLARE @TerminalNonce uniqueidentifier=NEWID();
  EXEC sys.sp_set_session_context @key=N'toolbelt.worker.completion_nonce',@value=@TerminalNonce;
  UPDATE toolbelt_core.WorkItem SET ManagedCompletionNonce=@TerminalNonce WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ClaimToken=@ClaimToken AND Status='CLAIMED' AND ManagedHold=0;
  IF @@ROWCOUNT<>1 THROW 54220,N'Der Terminalclaim ist verändert.',7;
  IF @Retry=1 EXEC toolbelt_core.USP_ScheduleWorkRetryCore @EmitResult=0,@WorkItemId=@Item,@ClaimToken=@ClaimToken,@FailureCode=@FailureCode;
  ELSE EXEC toolbelt_core.USP_FailWorkCore @EmitResult=0,@WorkItemId=@Item,@ClaimToken=@ClaimToken,@FailureCode=@FailureCode;
  SELECT @Outcome=Status FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item;
  -- Nur bewiesen beendete, heldfreie exakte Queueentscheidung lösen; Attempt/History bleiben.
  UPDATE toolbelt_core.WorkItem SET ManagedCompletionNonce=NULL,ManagedReservationId=NULL
  WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ManagedHold=0 AND Status IN('FAILED','RETRY_WAIT','DEAD_LETTER');
  IF @@ROWCOUNT<>1 THROW 54220,N'Die heldfreie Terminalentscheidung ist nicht exakt.',8;
  UPDATE toolbelt_core.WorkerSlotReservation SET IsOccupied=0,EndedAtUtc=SYSUTCDATETIME() WHERE SlotReservationId=@SlotReservationId;
 END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 RETURN 0;
END;
GO
