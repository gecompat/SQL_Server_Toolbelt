-- Objekt: toolbelt_core.USP_ReserveWorkerExecution
-- Zweck: Reserviert global und lokal atomar genau einen kanonischen Queueclaim; keine zweite Claimauswahl.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_ReserveWorkerExecution
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-reserveworkerexecution"
-- description: "Interne atomare Managed-Admission mit genau einem kanonischen Queueclaim und neuer Slot-/Executionidentität."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_ReserveWorkerExecution"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL:direkte Ausgabe. Sonst bereits vom Caller angelegte lokale #Temp mit einfachem Namen2..116 UTF16-Einheiten; keine ##Temp/persistente/mehrteilige Tabelle. Der kanonische Helper prüft und bereitet die Form. Auch leere Ausgabe kann Zielzeilen bei KeepData0 ersetzen."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0:Zieldaten ersetzen,1:bei kompatibler Form anhängen,NULL gemäß Helper wie0. Nur für ResultTable; keine eigene Admission-/Claimoption."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReserveWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
-- ---
--
-- # USP_ReserveWorkerExecution
--
-- ## Zweck und Einsatzfälle
--
-- Interne atomare Managed-Admission mit genau einem kanonischen Queueclaim und neuer Slot-/Executionidentität. Internes Objekt;kein manuelles Fachaufrufbeispiel als Ersatzprovider.
--
-- ## Voraussetzungen
--
-- Interner Managedproviderhelfer, kein öffentlicher manueller Dispatch-/Recovery-/Replayweg. Kontrollierten Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet keinen direkten Aufruf jedes Helpers durch jeden öffentlichen Einstieg. Worker-Control1.0.0,Queue2.1.0 und passende Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank; SQL2019/2022/2025 Windows/Linux, zulässigesCL150/160/170 lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0; keine Caller-Savepoints oder frei erfundenen IDs/Tokens.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
-- |---|---|---|---|---|
-- | `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
-- | `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
-- | `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
-- | `@ResultTable` | `sysname` | `NULL` | Input | NULL:direkte Ausgabe. Sonst bereits vom Caller angelegte lokale #Temp mit einfachem Namen2..116 UTF16-Einheiten; keine ##Temp/persistente/mehrteilige Tabelle. Der kanonische Helper prüft und bereitet die Form. Auch leere Ausgabe kann Zielzeilen bei KeepData0 ersetzen. |
-- | `@KeepData` | `bit` | `0` | Input | 0:Zieldaten ersetzen,1:bei kompatibler Form anhängen,NULL gemäß Helper wie0. Nur für ResultTable; keine eigene Admission-/Claimoption. |
-- | `@Debug` | `tinyint` | `0` | Input | 0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht. |
-- | `@Hilfe` | `bit` | `0` | Input | 1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf. |
--
-- SQL-Parametertypkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults dienen der Hilfe,keiner erfolgreichen Fachbindung.
--
-- ## Ergebnisse
--
-- Null oder eine Zeile, feste Reihenfolge:WorkItemId bigint NOT NULL,WorkTypeName varchar(128) BIN2 NOT NULL,PayloadJson nvarchar(max) NULL,ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL,SlotReservationId uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL. Keine OUTPUT-Parameter. NullResultTable:SELECT nach Commit; sonst Helperform+explizites INSERT vor Commit ohne zusätzlichen direkten Fachresultset. RETURN0 auch bei leerer Admission. Payload/ClaimToken sind vertraulich. Hilfe: bestehender zwölfspaltiger Standardhelp plus genau eine vollständige vier-spaltige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),danach RETURN0. Alle Parameter besitzen technische Defaults.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- EXEC toolbelt_core.USP_ReserveWorkerExecution @Hilfe=1;
-- -- Fachpfad ausschließlich über kontrollierten Managedprovider mit tatsächlicher Bindung.
-- ```
--
-- ## Rechte
--
-- Nur vorhandene autorisierte interne EXECUTE-/Objekt-/Ownership-Chainrechte im kontrollierten Providerpfad nutzen; keine Rechte erteilen oder aus diesem Skill ableiten. Worker-/Claimtoken sind vertraulich und nicht austauschbar. Principalbindungen verwenden USER_ID der Moduldatenbank,keine Host-/Serveridentitätsattestation. Claimdelegation verlangt außerdem WorkType-CLAIM-Policy,Handler-Metadatensicht und EXECUTE auf registrierten Handler; reine Reservation startet ihn nicht.
--
-- ## Ressourcenbedarf
--
-- Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Globales/lokales Budget zählt IsOccupied1,keine physische Kapazitätsgarantie; Claim kann WorkType-/Policy-/Barrier-/Retrydaten lesen und mutieren. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Eigene private #tbx_-Ergebnistemp vor Callertransaktionsguard; dann eigene Transaktion und UPDLOCK/HOLDLOCK Gate→Scheduler→Konfiguration. WorkerId/Generation/Token/OwnerPrincipalId=USER_ID mit State<>CLOSED prüfen; ManagedEnabled muss1 sein. Nur bei AdmissionPaused0,StateACTIVE,noch frischem Heartbeat und belegten Slots unter lokaler Capacity UND globalem MaxConcurrentExecutions wird Claim versucht. Sonst leeres normales Ergebnis, kein automatisches Reconcile/Revive. Bei Versuch neue Reservation/Execution/Admission-UUIDs; GateNonce/PendingReservation setzen, dann genau ein USP_ClaimWorkCore mit privater Admission,Reservation,OUTPUTCanonicalClaimId und EmitResult0, übrige Defaults (Lease300Sekunden,Debug0,kein ResultTable). Core verbraucht die GateNonce im selben gesunden Admission-TX und kann reife Retrybarriers armieren, auch ohne späteren Claim. Auswahl respektiert aktive WorkTypes, CLAIM-Policy, Handler-Metadatensicht/EXECUTE, ManagedHold und Gruppenbarriers; Priorität absteigend, dann Retrytermin/Enqueuezeit und WorkItemId. Keine Handlerausführung. Fester interner Transport liest ausschließlich die OUTPUTCanonicalClaimId mit exakter ManagedReservationId/CLAIMED, keine zweite Claimauswahl und kein INSERT EXEC. Nur bei Claim neue RESERVED/IsOccupied1-Reservation plus aktuelle Disposition NONE/IsHeld0; vorhandene Disposition wird nur wenn heldfrei auf neue Reservation bezogen. Keine neue globale ConfigVersion. Leeres Ergebnis beweist keine völlige Mutationsfreiheit: Nonce/Barrierzustände sowie ResultTable können sich ändern. Helperform/INSERT und Admissionmutationen liegen vor Commit, Fehler rollen eigene Transaktion zurück. Direkter Ergebnistransport erst nach Commit; Transportfehler machen eine erfolgte Reservation nicht rückgängig.
--
-- ## Fehlerbehandlung
--
-- 54210/1 Callertransaktion/nichtneutraler XACT_STATE;54211/1 fehlende Pflichtzeilen Gate/Scheduler/Konfiguration.54215/1 NULL oder fehlende Worker-/Token-/Principalautorität.54217/2 ManagedEnabled nicht1.54218/1 kanonische OUTPUTClaimId vorhanden, aber keine exakt reservierungsgebundene Transportzeile. Pausiert,unreachable/heartbeatabgelaufen,volle Capacity/globalesBudget oder kein passendes WorkItem ergeben regulär leere Ausgabe. QueueCore-/Policy-/Lease-/Helper-/Enginefehler bleiben getrennt; fehlende Tabellen können bereits Enginefehler statt54211 ergeben. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ReserveWorkerExecution' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Reserviert global und lokal atomar genau einen kanonischen Queueclaim; keine zweite Claimauswahl.',NULL),
 ('PARAMETER',1,N'@WorkerId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerId',NULL),
 ('PARAMETER',2,N'@WorkerGeneration',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerGeneration',NULL),
 ('PARAMETER',3,N'@WorkerToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerToken',NULL),
 ('PARAMETER',4,N'@ResultTable',N'sysname',0,1,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',5,N'@KeepData',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',6,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',7,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'WorkItemId',N'bigint',0,0,NULL,N'WorkItemId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'WorkTypeName',N'varchar(128)',0,0,NULL,N'WorkTypeName gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'PayloadJson',N'nvarchar(max)',0,1,NULL,N'PayloadJson gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',4,N'ClaimToken',N'uniqueidentifier',0,0,NULL,N'ClaimToken gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',5,N'ClaimedAtUtc',N'datetime2(7)',0,0,NULL,N'ClaimedAtUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',6,N'ClaimGeneration',N'bigint',0,0,NULL,N'ClaimGeneration gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',7,N'LeaseUntilUtc',N'datetime2(7)',0,0,NULL,N'LeaseUntilUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',8,N'LastHeartbeatAtUtc',N'datetime2(7)',0,0,NULL,N'LastHeartbeatAtUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',9,N'SlotReservationId',N'uniqueidentifier',0,0,NULL,N'SlotReservationId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',10,N'ExecutionId',N'uniqueidentifier',0,0,NULL,N'ExecutionId gemäß Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_ReserveWorkerExecution @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
-- OBJECT_USAGE_SKILL_HELP:COMPACT
 -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ReserveWorkerExecution' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-reserveworkerexecution"
description: "Interne atomare Managed-Admission mit genau einem kanonischen Queueclaim und neuer Slot-/Executionidentität."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_ReserveWorkerExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL:direkte Ausgabe. Sonst bereits vom Caller angelegte lokale #Temp mit einfachem Namen2..116 UTF16-Einheiten; keine ##Temp/persistente/mehrteilige Tabelle. Der kanonische Helper prüft und bereitet die Form. Auch leere Ausgabe kann Zielzeilen bei KeepData0 ersetzen."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false,' AS nvarchar(max)) + N' "argument_required": false, "business_required": false, "nullable": true, "description": "0:Zieldaten ersetzen,1:bei kompatibler Form anhängen,NULL gemäß Helper wie0. Nur für ResultTable; keine eigene Admission-/Claimoption."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReserveWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
---

# USP_ReserveWorkerExecution

## Zweck und Einsatzfälle

Interne atomare Managed-Admission mit genau einem kanonischen Queueclaim und neuer Slot-/Executionidentität. Internes Objekt;kein manuelles Fachaufrufbeispiel als Ersatzprovider.

## Voraussetzungen

Interner Managedproviderhelfer, kein öffentlicher manueller Dispatch-/Recovery-/Replayweg. Kontrollierten Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet keinen direkte' + N'n Aufruf jedes Helpers durch jeden öffentlichen Einstieg. Worker-Control1.0.0,Queue2.1.0 und passende Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank; SQL2019/2022/2025 Windows/Linux, zulässigesCL150/160/170 lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0; keine Caller-Savepoints oder frei erfundenen IDs/Tokens.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL:direkte Ausgabe. Sonst bereits vom Caller angelegte lokale #Temp mit einfachem Namen2..116 UTF16-Einheiten; keine ##Temp/persistente/mehrteilige Tabelle. Der kanonische Helper prüft und bereitet die Form. Auch leere Ausgabe kann Zielzeilen bei KeepData0 ersetzen. |
| `@KeepData` | `bit` | `0` | Input | 0:Zieldaten ersetzen,1:bei kompatibler Form anhängen,NULL gemäß Helper wie0. Nur für ResultTable; keine eigene Admission-/Claimoption. |
| `@Debug` | `tinyint` | `0` | Input | 0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufru' + N'f. |

SQL-Parametertypkonvertierung erfolgt vor dem Prozedurcode. Technische NULL-Defaults dienen der Hilfe,keiner erfolgreichen Fachbindung.

## Ergebnisse

Null oder eine Zeile, feste Reihenfolge:WorkItemId bigint NOT NULL,WorkTypeName varchar(128) BIN2 NOT NULL,PayloadJson nvarchar(max) NULL,ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL,SlotReservationId uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL. Keine OUTPUT-Parameter. NullResultTable:SELECT nach Commit; sonst Helperform+explizites INSERT vor Commit ohne zusätzlichen direkten Fachresultset. RETURN0 auch bei leerer Admission. Payload/ClaimToken sind vertraulich. Hilfe: bestehender zwölfspaltiger Standardhelp plus genau eine vollständige vier-spaltige Skillzeile mit SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max),danach RETURN0. Alle Parameter besitzen technische Defaults.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ReserveWorkerExecution @Hilfe=1;
-- Fachpfad ausschließlich über kontrollierten Managedprovider mit tatsächlicher Bindung.
```

## Rechte

Nur vorhandene autorisierte interne EXECUTE-/Objekt-/Ownership-Chainrechte im kontrollierten Providerpfad nutzen; keine Rechte erteilen oder aus diesem Skill ableiten. Worker-/Claimtoken sind vertraulich und nicht austauschbar. Principalbindungen verwenden USER_ID der Moduldatenbank,keine Host-/Serveridentitätsattestation. Claimdelegation verlangt außerdem WorkType-CLAIM-Policy,Handler-Metadatensicht und EXECUTE auf registrierten Handler; reine Reservation startet ihn nicht.

## Ressourcenbedarf

Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Globales/lokales Budget zählt IsOccupied1,keine physisch' + N'e Kapazitätsgarantie; Claim kann WorkType-/Policy-/Barrier-/Retrydaten lesen und mutieren. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Eigene private #tbx_-Ergebnistemp vor Callertransaktionsguard; dann eigene Transaktion und UPDLOCK/HOLDLOCK Gate→Scheduler→Konfiguration. WorkerId/Generation/Token/OwnerPrincipalId=USER_ID mit State<>CLOSED prüfen; ManagedEnabled muss1 sein. Nur bei AdmissionPaused0,StateACTIVE,noch frischem Heartbeat und belegten Slots unter lokaler Capacity UND globalem MaxConcurrentExecutions wird Claim versucht. Sonst leeres normales Ergebnis, kein automatisches Reconcile/Revive. Bei Versuch neue Reservation/Execution/Admission-UUIDs; GateNonce/PendingReservation setzen, dann genau ein USP_ClaimWorkCore mit privater Admission,Reservation,OUTPUTCanonicalClaimId und EmitResult0, übrige Defaults (Lease300Sekunden,Debug0,kein ResultTable). Core verbraucht die GateNonce im selben gesunden Admission-TX und kann reife Retrybarriers armieren, auch ohne späteren Claim. Auswahl respektiert aktive WorkTypes, CLAIM-Policy, Handler-Metadatensicht/EXECUTE, ManagedHold und Gruppenbarriers; Priorität absteigend, dann Retrytermin/Enqueuezeit und WorkItemId. Keine Handlerausführung. Fester interner Transport liest ausschließlich die OUTPUTCanonicalClaimId mit exakter ManagedReservationId/CLAIMED, keine zweite Claimauswahl und kein INSERT EXEC. Nur bei Claim neue RESERVED/IsOccupied1-Reservation plus aktuelle Disposition NONE/IsHeld0; vorhandene Disposition wird nur wenn heldfrei auf neue Reservation bezogen. Keine neue globale ConfigVersion. Leeres Ergebnis beweist keine völlige Mutationsfreiheit: Nonce/Barrierzustände sowie ResultTable können sich ändern. Helperform/INSERT und Admissionmutationen liegen vor Commit, Fehler rollen eig' + N'ene Transaktion zurück. Direkter Ergebnistransport erst nach Commit; Transportfehler machen eine erfolgte Reservation nicht rückgängig.

## Fehlerbehandlung

54210/1 Callertransaktion/nichtneutraler XACT_STATE;54211/1 fehlende Pflichtzeilen Gate/Scheduler/Konfiguration.54215/1 NULL oder fehlende Worker-/Token-/Principalautorität.54217/2 ManagedEnabled nicht1.54218/1 kanonische OUTPUTClaimId vorhanden, aber keine exakt reservierungsgebundene Transportzeile. Pausiert,unreachable/heartbeatabgelaufen,volle Capacity/globalesBudget oder kein passendes WorkItem ergeben regulär leere Ausgabe. QueueCore-/Policy-/Lease-/Helper-/Enginefehler bleiben getrennt; fehlende Tabellen können bereits Enginefehler statt54211 ergeben. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
' AS SkillMarkdown;
 -- OBJECT_USAGE_SKILL_HELP:END
 RETURN 0; END;
 CREATE TABLE #tbx_USP_ReserveWorkerExecution_Result(WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,PayloadJson nvarchar(max) NULL,ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL,SlotReservationId uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @WorkerId IS NULL OR @WorkerGeneration IS NULL OR @WorkerToken IS NULL OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WITH(UPDLOCK,HOLDLOCK) WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND WorkerToken=@WorkerToken AND OwnerPrincipalId=USER_ID() AND State<>'CLOSED') THROW 54215,N'Die Workergeneration besitzt keine gültige Autorität.',1;
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=1) THROW 54217,N'Managed-Betrieb ist nicht aktiviert.',2;
 DECLARE @Capacity int,@Global int,@CurrentSlots bigint,@TotalSlots bigint,@Paused bit,@WorkerState varchar(16),@Heartbeat datetime2(7),@Unreachable int;
 SELECT @Capacity=Capacity,@Paused=AdmissionPaused,@WorkerState=State,@Heartbeat=LastHeartbeatAtUtc,@Unreachable=UnreachableSeconds FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration;
 SELECT @Global=MaxConcurrentExecutions FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;
 SELECT @CurrentSlots=COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND IsOccupied=1;
 SELECT @TotalSlots=COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1;
 IF @Paused=0 AND @WorkerState='ACTIVE' AND DATEADD(SECOND,@Unreachable,@Heartbeat)>SYSUTCDATETIME() AND @CurrentSlots<@Capacity AND @TotalSlots<@Global
 BEGIN
  DECLARE @Reservation uniqueidentifier=NEWID(),@Execution uniqueidentifier=NEWID(),@Admission uniqueidentifier=NEWID();
  CREATE TABLE #tbx_ManagedClaim(WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,PayloadJson nvarchar(max) NULL,ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL);
  UPDATE toolbelt_core.WorkQueueManagedGate SET AdmissionToken=@Admission,PendingReservationId=@Reservation WHERE GateId=1;
  DECLARE @CanonicalClaimId bigint;
  EXEC toolbelt_core.USP_ClaimWorkCore @ManagedAdmissionToken=@Admission,@ManagedReservationId=@Reservation,@ClaimedWorkItemId=@CanonicalClaimId OUTPUT,@EmitResult=0;
  -- Fester interner Transport: kein öffentlicher ResultTable-Name und kein INSERT EXEC.
  INSERT #tbx_ManagedClaim(WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc)
  SELECT wi.WorkItemId,wt.WorkTypeName,wi.PayloadJson,wi.ClaimToken,wi.ClaimedAtUtc,wi.ClaimGeneration,wi.LeaseUntilUtc,wi.LastHeartbeatAtUtc
  FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId
  WHERE wi.WorkItemId=@CanonicalClaimId AND wi.ManagedReservationId=@Reservation AND wi.Status='CLAIMED';
  IF @CanonicalClaimId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM #tbx_ManagedClaim) THROW 54218,N'Der kanonische Claimtransport besitzt keine exakte Reservationbindung.',1;
  IF EXISTS(SELECT 1 FROM #tbx_ManagedClaim)
  BEGIN
   INSERT toolbelt_core.WorkerSlotReservation(SlotReservationId,WorkerId,WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,ExecutionId,State,IsOccupied,CreatedAtUtc)
   SELECT @Reservation,@WorkerId,@WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,@Execution,'RESERVED',1,SYSUTCDATETIME() FROM #tbx_ManagedClaim;
   DECLARE @Item bigint; SELECT @Item=WorkItemId FROM #tbx_ManagedClaim;
   IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE WorkItemId=@Item)
    UPDATE toolbelt_core.WorkerExecutionDisposition SET SlotReservationId=@Reservation,StopStatus='NONE' WHERE WorkItemId=@Item AND IsHeld=0;
   ELSE INSERT toolbelt_core.WorkerExecutionDisposition(WorkItemId,SlotReservationId,IsHeld,StopStatus) VALUES(@Item,@Reservation,0,'NONE');
   INSERT #tbx_USP_ReserveWorkerExecution_Result SELECT WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc,@Reservation,@Execution FROM #tbx_ManagedClaim;
  END;
 END;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_ReserveWorkerExecution_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc,SlotReservationId,ExecutionId) SELECT WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc,SlotReservationId,ExecutionId FROM #tbx_USP_ReserveWorkerExecution_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc,SlotReservationId,ExecutionId FROM #tbx_USP_ReserveWorkerExecution_Result;
 RETURN 0;
END;
GO
