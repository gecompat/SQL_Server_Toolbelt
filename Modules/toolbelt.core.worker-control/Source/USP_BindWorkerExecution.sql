-- Objekt: toolbelt_core.USP_BindWorkerExecution
-- Zweck: Bindet genau eine frische tatsächliche Handlerconnection vor Dispatch; kein Rebind.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_BindWorkerExecution
 @SlotReservationId uniqueidentifier=NULL,
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @ClaimGeneration bigint=NULL,
 @ClaimToken uniqueidentifier=NULL,
 @ExecutionId uniqueidentifier=NULL,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-bindworkerexecution"
-- description: "Bindet eine frische tatsächliche Handlerconnection einmalig an eine exakte Reservation."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_BindWorkerExecution"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ClaimGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_BindWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
-- ---
--
-- # USP_BindWorkerExecution
--
-- ## Zweck und Einsatzfälle
--
-- Bindet eine frische tatsächliche Handlerconnection einmalig an eine exakte Reservation. Internes Objekt;kein manuelles Fachaufrufbeispiel als Ersatzprovider.
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
-- | `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
-- | `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
-- | `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
-- | `@ClaimGeneration` | `bigint` | `NULL` | Input | Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
-- | `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
-- | `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
-- | `@Debug` | `tinyint` | `0` | Input | 0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf. |
--
-- SQL-Parametertypkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults dienen der Hilfe,keiner erfolgreichen Fachbindung.
--
-- ## Ergebnisse
--
-- Kein fachlicher Resultset und keine OUTPUT-/ResultTable-/KeepData-Option. RETURN0 bedeutet erfolgreiche Bindungsbuchung, keinen Handlerstart oder Commitbeweis. Hilfe: bestehender zwölfspaltiger Standardhelp plus genau eine vollständige vier-spaltige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),danach RETURN0. Alle Parameter besitzen technische Defaults.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_BindWorkerExecution @Hilfe=1;
-- -- Fachpfad ausschließlich über kontrollierten Managedprovider mit tatsächlicher Bindung.
-- ```
--
-- ## Rechte
--
-- Nur vorhandene autorisierte interne EXECUTE-/Objekt-/Ownership-Chainrechte im kontrollierten Providerpfad nutzen; keine Rechte erteilen oder aus diesem Skill ableiten. Worker-/Claimtoken sind vertraulich und nicht austauschbar. Principalbindungen verwenden USER_ID der Moduldatenbank,keine Host-/Serveridentitätsattestation. AppLock-DbPrincipal public beschreibt hier den Locknamespace,keinen neuen Grant. Sessioncontext allein ist keine vollständige Autorität.
--
-- ## Ressourcenbedarf
--
-- Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Bind verwendet Session-AppLock-Timeout0. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Vor Handlertransaktion neutraler Caller erforderlich. Exklusiver Session-AppLock Toolbelt.Worker.Attempt.<SlotReservationId> mit DbPrincipalpublic und LockTimeout0, kein Warten/Retry. Negative Rückgabe wirft vor TRY. Danach eigene Transaktion: exaktes RESERVED/AttemptNonceNULL/IsOccupied1-Tupel mit Slot,WorkerId/Generation,WorkerToken/OwnerPrincipalId=USER_ID,ClaimGeneration/ClaimToken/ExecutionId unter UPDLOCK/HOLDLOCK prüfen. Bestehender Hold blockiert Dispatch. Neue Attemptnonce in SESSION_CONTEXT(toolbelt.worker.attempt_nonce) mit read_only1 setzen; Reservation bekommt dieselbe Nonce,BoundPrincipalId USER_ID und StateRUNNING. Danach Commit; Session-Attempt-AppLock bleibt absichtlich gehalten. Kein Rebind, kein Handler-SQL und keine neue Claim-/Executionidentität. CATCH rollt aktive eigene Transaktion zurück und ruft sp_releaseapplock für den Sessionlock; Cleanupfehler sind nicht separat geschützt. Kein Reset des read-only-Kontextschlüssels im Code, auch nicht nach späterem Fehler. Frische isolierte tatsächliche Connection pro Attempt verwenden und Lebensdauer durch den kontrollierten Provider führen; nicht allein neue SQL-Variablen auf einer alten Connection verwenden.
--
-- ## Fehlerbehandlung
--
-- 54210/3 nichtneutraler Caller vor Handlertransaktion.54218/1 negativer Session-AppLock-Rückgabecode;54218/2 keine exakte frische RESERVED-/Worker-/Claim-/Principalbindung.54219/1 Hold vor Dispatch. NULL-/Konvertierungs-/AppLock-Resource-/read-only-Sessioncontextfehler können ursprüngliche Enginefehler erzeugen; keine universelle54218-Abbildung aller ungültigen Werte. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_BindWorkerExecution' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Bindet genau eine frische tatsächliche Handlerconnection vor Dispatch; kein Rebind.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@WorkerId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerId',NULL),
 ('PARAMETER',3,N'@WorkerGeneration',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerGeneration',NULL),
 ('PARAMETER',4,N'@WorkerToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerToken',NULL),
 ('PARAMETER',5,N'@ClaimGeneration',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ClaimGeneration',NULL),
 ('PARAMETER',6,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ClaimToken',NULL),
 ('PARAMETER',7,N'@ExecutionId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExecutionId',NULL),
 ('PARAMETER',8,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',9,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_BindWorkerExecution @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
-- OBJECT_USAGE_SKILL_HELP:COMPACT
 -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_BindWorkerExecution' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-bindworkerexecution"
description: "Bindet eine frische tatsächliche Handlerconnection einmalig an eine exakte Reservation."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_BindWorkerExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ClaimGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint au' AS nvarchar(max)) + N's derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_BindWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
---

# USP_BindWorkerExecution

## Zweck und Einsatzfälle

Bindet eine frische tatsächliche Handlerconnec' + N'tion einmalig an eine exakte Reservation. Internes Objekt;kein manuelles Fachaufrufbeispiel als Ersatzprovider.

## Voraussetzungen

Interner Managedproviderhelfer, kein öffentlicher manueller Dispatch-/Recovery-/Replayweg. Kontrollierten Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet keinen direkten Aufruf jedes Helpers durch jeden öffentlichen Einstieg. Worker-Control1.0.0,Queue2.1.0 und passende Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank; SQL2019/2022/2025 Windows/Linux, zulässigesCL150/160/170 lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0; keine Caller-Savepoints oder frei erfundenen IDs/Tokens.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
| `@ClaimGeneration` | `bigint` | `NULL` | Input | Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentif' + N'ier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@Debug` | `tinyint` | `0` | Input | 0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf. |

SQL-Parametertypkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults dienen der Hilfe,keiner erfolgreichen Fachbindung.

## Ergebnisse

Kein fachlicher Resultset und keine OUTPUT-/ResultTable-/KeepData-Option. RETURN0 bedeutet erfolgreiche Bindungsbuchung, keinen Handlerstart oder Commitbeweis. Hilfe: bestehender zwölfspaltiger Standardhelp plus genau eine vollständige vier-spaltige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),danach RETURN0. Alle Parameter besitzen technische Defaults.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_BindWorkerExecution @Hilfe=1;
-- Fachpfad ausschließlich über kontrollierten Managedprovider mit tatsächlicher Bindung.
```

## Rechte

Nur vorhandene autorisierte interne EXECUTE-/Objekt-/Ownership-Chainrechte im kontrollierten Providerpfad nutzen; keine Rechte erteilen oder aus diesem Skill ableiten. Worker-/Claimtoken sind vertraulich und nicht austauschbar. Principalbindungen verwenden USER_ID der Moduldatenbank,keine Host-/Serveridentitätsattestation. AppLock-DbPrincipal public beschreibt hier den Locknamespace,keinen neuen Grant. Sessioncontext allein ist keine vollständige Autorität.

## Ress' + N'ourcenbedarf

Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Bind verwendet Session-AppLock-Timeout0. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Vor Handlertransaktion neutraler Caller erforderlich. Exklusiver Session-AppLock Toolbelt.Worker.Attempt.<SlotReservationId> mit DbPrincipalpublic und LockTimeout0, kein Warten/Retry. Negative Rückgabe wirft vor TRY. Danach eigene Transaktion: exaktes RESERVED/AttemptNonceNULL/IsOccupied1-Tupel mit Slot,WorkerId/Generation,WorkerToken/OwnerPrincipalId=USER_ID,ClaimGeneration/ClaimToken/ExecutionId unter UPDLOCK/HOLDLOCK prüfen. Bestehender Hold blockiert Dispatch. Neue Attemptnonce in SESSION_CONTEXT(toolbelt.worker.attempt_nonce) mit read_only1 setzen; Reservation bekommt dieselbe Nonce,BoundPrincipalId USER_ID und StateRUNNING. Danach Commit; Session-Attempt-AppLock bleibt absichtlich gehalten. Kein Rebind, kein Handler-SQL und keine neue Claim-/Executionidentität. CATCH rollt aktive eigene Transaktion zurück und ruft sp_releaseapplock für den Sessionlock; Cleanupfehler sind nicht separat geschützt. Kein Reset des read-only-Kontextschlüssels im Code, auch nicht nach späterem Fehler. Frische isolierte tatsächliche Connection pro Attempt verwenden und Lebensdauer durch den kontrollierten Provider führen; nicht allein neue SQL-Variablen auf einer alten Connection verwenden.

## Fehlerbehandlung

54210/3 nichtneutraler Caller vor Handlertransaktion.54218/1 negativer Session-AppLock-Rückgabecode;54218/2 keine exakte frische RESERVED-/Worker-/Claim-/Principalbindung.54219/1 Hold vor Dispatch. NULL-/Konvertierungs-/AppLock-Resource-/read-' + N'only-Sessioncontextfehler können ursprüngliche Enginefehler erzeugen; keine universelle54218-Abbildung aller ungültigen Werte. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
' AS SkillMarkdown;
 -- OBJECT_USAGE_SKILL_HELP:END
 RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Bind erfolgt vor der Handlertransaktion.',3;
 DECLARE @Resource nvarchar(255)=N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),@Lock int,@Nonce uniqueidentifier=NEWID();
 EXEC @Lock=sys.sp_getapplock @Resource=@Resource,@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';
 IF @Lock<0 THROW 54218,N'Die Ausführung ist bereits an eine Handlerconnection gebunden.',1;
 BEGIN TRY
 BEGIN TRANSACTION;
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation r WITH(UPDLOCK,HOLDLOCK) JOIN toolbelt_core.WorkerRegistration w ON w.WorkerId=r.WorkerId AND w.WorkerGeneration=r.WorkerGeneration
 WHERE r.SlotReservationId=@SlotReservationId AND r.WorkerId=@WorkerId AND r.WorkerGeneration=@WorkerGeneration AND w.WorkerToken=@WorkerToken AND w.OwnerPrincipalId=USER_ID()
 AND r.ClaimGeneration=@ClaimGeneration AND r.ClaimToken=@ClaimToken AND r.ExecutionId=@ExecutionId AND r.State='RESERVED' AND r.AttemptNonce IS NULL AND r.IsOccupied=1)
 THROW 54218,N'Die exakte Reservation besitzt keine frische Bindungsautorität.',2;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE SlotReservationId=@SlotReservationId AND IsHeld=1) THROW 54219,N'Stop/Hold verhindert Dispatch.',1;
 EXEC sys.sp_set_session_context @key=N'toolbelt.worker.attempt_nonce',@value=@Nonce,@read_only=1;
 UPDATE toolbelt_core.WorkerSlotReservation SET AttemptNonce=@Nonce,BoundPrincipalId=USER_ID(),State='RUNNING' WHERE SlotReservationId=@SlotReservationId;
 COMMIT;
 END TRY BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 EXEC sys.sp_releaseapplock @Resource=@Resource,@LockOwner=N'Session',@DbPrincipal=N'public'; THROW;
 END CATCH;
 RETURN 0;
END;
GO
