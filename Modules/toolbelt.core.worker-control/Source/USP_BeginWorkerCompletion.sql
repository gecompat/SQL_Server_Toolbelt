-- Objekt: toolbelt_core.USP_BeginWorkerCompletion
-- Zweck: Verifiziert den Witness und hält den privaten Completion-Gate bis zum äußeren Commit/Rollback.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_BeginWorkerCompletion
 @SlotReservationId uniqueidentifier=NULL,
 @ClaimToken uniqueidentifier=NULL,
 @ExecutionId uniqueidentifier=NULL,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-beginworkercompletion"
-- description: "Prüft im gesunden Handlertransaktionsrahmen den Witness und reserviert den Completion-Gate."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_BeginWorkerCompletion"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier der eigenen Slotreservation; Pflicht im Fachpfad, technischer NULL-Default nur für Hilfe. Keine WorkerId oder WorkItemId."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Geheimes ClaimToken derselben Reservation und Claimgeneration. Kein WorkerToken; NULL oder fremde Bindung kann nicht erfolgreich verwendet werden. Nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier der gebundenen Execution; Pflicht im Fachpfad, kein frei erfundener Replay-/Recoverywert. NULL-Default nur Hilfe."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL, Default0; im aktuellen Helper kein eigener Diagnose-/Messagepfad und kein Tokenoutput."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Transaktions-/Bindungs-/Fachprüfungen oder Mutationen. 0 oder NULL: Fachpfad. Technische Defaults erlauben reinen Hilfeaufruf."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_BeginWorkerCompletion.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
-- ---
--
-- # USP_BeginWorkerCompletion
--
-- ## Zweck und Einsatzfälle
--
-- Prüft im gesunden Handlertransaktionsrahmen den Witness und reserviert den Completion-Gate. Internes Objekt; öffentliche Nutzungswege siehe Frontmatter.
--
-- ## Voraussetzungen
--
-- Interner Providerhelfer, kein manueller öffentlicher Recovery-/Replayweg. Regulär den kontrollierten Managed-Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet nicht, dass jeder öffentliche Einstieg den Helper direkt aufruft. Worker-Control1.0.0 mit passender Queue2.1.0/Context-/Cancellationintegration derselben DB; SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170 lokal/zentral. Vor dem Fachaufruf exakt @@TRANCOUNT1 und XACT_STATE1 auf derselben gebundenen Handlerconnection; Witness/Completion sind Teil des äußeren Transaktionsrahmens.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@SlotReservationId` | `uniqueidentifier` | `NULL` | Exakte uniqueidentifier der eigenen Slotreservation; Pflicht im Fachpfad, technischer NULL-Default nur für Hilfe. Keine WorkerId oder WorkItemId. |
-- | `@ClaimToken` | `uniqueidentifier` | `NULL` | Geheimes ClaimToken derselben Reservation und Claimgeneration. Kein WorkerToken; NULL oder fremde Bindung kann nicht erfolgreich verwendet werden. Nicht protokollieren. |
-- | `@ExecutionId` | `uniqueidentifier` | `NULL` | Exakte uniqueidentifier der gebundenen Execution; Pflicht im Fachpfad, kein frei erfundener Replay-/Recoverywert. NULL-Default nur Hilfe. |
-- | `@Debug` | `tinyint` | `0` | 0..255 oder NULL, Default0; im aktuellen Helper kein eigener Diagnose-/Messagepfad und kein Tokenoutput. |
-- | `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Transaktions-/Bindungs-/Fachprüfungen oder Mutationen. 0 oder NULL: Fachpfad. Technische Defaults erlauben reinen Hilfeaufruf. |
--
-- SQL-Parametertypkonvertierung erfolgt vor Ausführung. Alle Werte gehören zu derselben tatsächlichen Attemptbindung; synthetische Werte sind keine ausführbare Recoveryfreigabe.
--
-- ## Ergebnisse
--
-- Kein fachlicher Resultset, keine OUTPUT-Parameter, keine ResultTable-/KeepData-Option. RETURN0 bei erfolgreichem Helperpfad oder Hilfe; ursprüngliche fachliche SQL-Operationen werden dadurch weder wiederholt noch allgemein als erfolgreich attestiert. Hilfe liefert bisherigen zwölfspaltigen Standardhelp plus genau eine vier-spaltige Skillzeile: SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max).
--
-- ## Aufrufbeispiele
--
-- ```sql
-- -- Sicherer Referenzaufruf ohne Attemptmutation:
-- EXEC toolbelt_core.USP_BeginWorkerCompletion @Hilfe=1;
-- -- Fachaufruf ausschließlich im kontrollierten Managedprovider, nicht manuell nachstellen.
-- ```
--
-- ## Rechte
--
-- Nur bereits autorisierte interne Provider-/Handlerausführung mit vorhandenen EXECUTE-Rechten und passenden tatsächlichen Objekt-/Ownership-Chains verwenden. Keine Rechte aus diesem Skill ableiten oder erteilen. Tabellen-DML/SESSION_CONTEXT allein ist keine öffentliche Ersatzschnittstelle. Exklusiver Session-Attempt-AppLock und Sessionnonce ersetzen nicht die zusätzlich geprüfte Datenbankprincipal-/Claim-/Executionbindung. Lockprincipal public ist hier ein AppLock-Namespace, keine Rechtevergabe.
--
-- ## Ressourcenbedarf
--
-- Kein CLR-/Datei-/Netzwerk-/LLM-Aufruf. Datenbank-/Zeilen-/Schlüsselsperren, vorhandene Indizes und konkurrierende Providersteuerung bestimmen Aufwand. Disposition-AppLock wartet höchstens5000ms; das ist kein Gesamtlaufzeitlimit für alle SQL-Operationen. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote oder Retryschleife; Sperr-/Deadlock-/Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe kehrt vor allen beschriebenen Fachaktionen zurück, prüft keine Pflichtbindungen und schreibt keine fachlichen Daten. Nimmt einen exklusiven Transaction-AppLock Toolbelt.Worker.Disposition.<SlotReservationId>,@DbPrincipal public,@LockTimeout5000. Prüft Hold mit UPDLOCK/HOLDLOCK und den exakten Slot/Nonce/Execution/Claimgeneration-Witness. Erst dann neues NEWID()-CompletionNonce in SESSION_CONTEXT(toolbelt.worker.completion_nonce), danach UPDATE WorkItem.ManagedCompletionNonce nur am exakt gebundenen CLAIMED-Item ohne ManagedHold. Kein Wechsel auf COMPLETED durch diese Prozedur. Der Gate bleibt bis zum äußeren Commit/Rollback; hier kein eigener Commit/Rollback, kein TRY/CATCH und kein Lockrelease/Sessioncontextreset. Ein späterer THROW nach Sessioncontextsetzung enthält hier keinen Sessioncontext-Cleanup. Der Runner muss den Gesamtpfad inklusive Cleanup führen.
--
-- ## Fehlerbehandlung
--
-- 54221/2 nicht genau eine gesunde Transaktion.54220/1 fehlende ID/Token/Execution/Sessionnonce oder nichtExklusiver Session-Attempt-AppLock;54220/2 kein passendes belegtes Tupel mit Nonce/BoundPrincipalId=USER_ID.54222/1 negativer Disposition-AppLock-Rückgabecode.54219/3 persistierter Hold gewinnt.54221/3 exakter Witness fehlt.54220/3 keine unveränderte CLAIMED-Zeile für Item/Reservation/Generation/ClaimToken/ManagedHold0. Ursprüngliche Constraint-/PK-/Konvertierungs-/AppLock-/Enginefehler bleiben technisch. Kein eigener CATCH/Rollback: der kontrollierte Aufrufer muss den noch laufenden äußeren Transaktionsrahmen und Kontext beenden.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Commit-/Rollback-/Hostverlustabnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Kein kryptografischer Nachweis, Exactly-once, automatischer KILL, Host-/VM-Wiederaufbau oder allgemeiner Beweis externer fachlicher Seiteneffekte. Die erwartete Verbindung/Transaktionsordnung wird durch den vertrauenswürdigen Providerpfad hergestellt, nicht von einer KI durch Einzelaufrufe improvisiert. IDs/Tokens/Nonces und Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_BeginWorkerCompletion' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Verifiziert den Witness und hält den privaten Completion-Gate bis zum äußeren Commit/Rollback.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@ClaimToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ClaimToken',NULL),
 ('PARAMETER',3,N'@ExecutionId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExecutionId',NULL),
 ('PARAMETER',4,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',5,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_BeginWorkerCompletion @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
-- OBJECT_USAGE_SKILL_HELP:COMPACT
 -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_BeginWorkerCompletion' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-beginworkercompletion"
description: "Prüft im gesunden Handlertransaktionsrahmen den Witness und reserviert den Completion-Gate."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_BeginWorkerCompletion"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier der eigenen Slotreservation; Pflicht im Fachpfad, technischer NULL-Default nur für Hilfe. Keine WorkerId oder WorkItemId."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Geheimes ClaimToken derselben Reservation und Claimgeneration. Kein WorkerToken; NULL oder fremde Bindung kann nicht erfolgreich verwendet werden. Nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier der gebundenen Execution; Pflicht im Fachpfad, kein frei erfundener Replay-/Recoverywert. NULL-Default nur Hilfe."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL, Default0; im aktuellen Helper kein eigener Diagnose-/Messagepfad und kein Tokenoutput."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Transaktions-/Bindungs-/Fachprüfungen oder Mutationen' AS nvarchar(max)) + N'. 0 oder NULL: Fachpfad. Technische Defaults erlauben reinen Hilfeaufruf."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_BeginWorkerCompletion.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
---

# USP_BeginWorkerCompletion

## Zweck und Einsatzfälle

Prüft im gesunden Handlertransaktionsrahmen den Witness und reserviert den Completion-Gate. Internes Objekt; öffentliche Nutzungswege siehe Frontmatter.

## Voraussetzungen

Interner Providerhelfer, kein manueller öffentlicher Recovery-/Replayweg. Regulär den kontrollierten Managed-Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet nicht, dass jeder öffentliche Einstieg den Helper direkt aufruft. Worker-Control1.0.0 mit passender Queue2.1.0/Context-/Cancellationintegration derselben DB; SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170 lokal/zentral. Vor dem Fachaufruf exakt @@TRANCOUNT1 und XACT_STATE1 auf derselben gebundenen Handlerconnection; Witness/Completion sind Teil des äußeren Transaktionsrahmens.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Exakte uniqueidentifier der eigenen Slotreservation; Pflicht im Fachpfad, technischer NULL-Default nur für Hilfe. Keine WorkerId oder WorkItemId. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Geheimes ClaimToken derselben Reservation und Claimgeneration. Kein WorkerToken; NULL oder fremde Bindung kann nicht erfolgreich verwendet werden. Nicht protokollieren. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Exakte uniqueidentifier der gebundenen Execution; Pflicht im Fachpfad, kein frei erfundener Replay-/Recoverywert. NULL-Default nur Hilfe. |' + N'
| `@Debug` | `tinyint` | `0` | 0..255 oder NULL, Default0; im aktuellen Helper kein eigener Diagnose-/Messagepfad und kein Tokenoutput. |
| `@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Transaktions-/Bindungs-/Fachprüfungen oder Mutationen. 0 oder NULL: Fachpfad. Technische Defaults erlauben reinen Hilfeaufruf. |

SQL-Parametertypkonvertierung erfolgt vor Ausführung. Alle Werte gehören zu derselben tatsächlichen Attemptbindung; synthetische Werte sind keine ausführbare Recoveryfreigabe.

## Ergebnisse

Kein fachlicher Resultset, keine OUTPUT-Parameter, keine ResultTable-/KeepData-Option. RETURN0 bei erfolgreichem Helperpfad oder Hilfe; ursprüngliche fachliche SQL-Operationen werden dadurch weder wiederholt noch allgemein als erfolgreich attestiert. Hilfe liefert bisherigen zwölfspaltigen Standardhelp plus genau eine vier-spaltige Skillzeile: SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
-- Sicherer Referenzaufruf ohne Attemptmutation:
EXEC toolbelt_core.USP_BeginWorkerCompletion @Hilfe=1;
-- Fachaufruf ausschließlich im kontrollierten Managedprovider, nicht manuell nachstellen.
```

## Rechte

Nur bereits autorisierte interne Provider-/Handlerausführung mit vorhandenen EXECUTE-Rechten und passenden tatsächlichen Objekt-/Ownership-Chains verwenden. Keine Rechte aus diesem Skill ableiten oder erteilen. Tabellen-DML/SESSION_CONTEXT allein ist keine öffentliche Ersatzschnittstelle. Exklusiver Session-Attempt-AppLock und Sessionnonce ersetzen nicht die zusätzlich geprüfte Datenbankprincipal-/Claim-/Executionbindung. Lockprincipal public ist hier ein AppLock-Namespace, keine Rechtevergabe.

## Ressourcenbedarf

Kein CLR-/Datei-/Netzwerk-/LLM-Aufruf. Datenbank-/Zeilen-/Schlüsselsperren, vorhandene Indizes und konkurrierende Providersteuerung bestimmen Aufwand. Disposition-AppLock wartet höchstens5000ms; das ist kein Gesamtlaufze' + N'itlimit für alle SQL-Operationen. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote oder Retryschleife; Sperr-/Deadlock-/Enginefehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe kehrt vor allen beschriebenen Fachaktionen zurück, prüft keine Pflichtbindungen und schreibt keine fachlichen Daten. Nimmt einen exklusiven Transaction-AppLock Toolbelt.Worker.Disposition.<SlotReservationId>,@DbPrincipal public,@LockTimeout5000. Prüft Hold mit UPDLOCK/HOLDLOCK und den exakten Slot/Nonce/Execution/Claimgeneration-Witness. Erst dann neues NEWID()-CompletionNonce in SESSION_CONTEXT(toolbelt.worker.completion_nonce), danach UPDATE WorkItem.ManagedCompletionNonce nur am exakt gebundenen CLAIMED-Item ohne ManagedHold. Kein Wechsel auf COMPLETED durch diese Prozedur. Der Gate bleibt bis zum äußeren Commit/Rollback; hier kein eigener Commit/Rollback, kein TRY/CATCH und kein Lockrelease/Sessioncontextreset. Ein späterer THROW nach Sessioncontextsetzung enthält hier keinen Sessioncontext-Cleanup. Der Runner muss den Gesamtpfad inklusive Cleanup führen.

## Fehlerbehandlung

54221/2 nicht genau eine gesunde Transaktion.54220/1 fehlende ID/Token/Execution/Sessionnonce oder nichtExklusiver Session-Attempt-AppLock;54220/2 kein passendes belegtes Tupel mit Nonce/BoundPrincipalId=USER_ID.54222/1 negativer Disposition-AppLock-Rückgabecode.54219/3 persistierter Hold gewinnt.54221/3 exakter Witness fehlt.54220/3 keine unveränderte CLAIMED-Zeile für Item/Reservation/Generation/ClaimToken/ManagedHold0. Ursprüngliche Constraint-/PK-/Konvertierungs-/AppLock-/Enginefehler bleiben technisch. Kein eigener CATCH/Rollback: der kontrollierte Aufrufer muss den noch laufenden äußeren Transaktionsrahmen und Kontext beenden.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Commit-/Rollback-/Hostverlustabnahme. Historische Nachweise behalten ihre urspr' + N'üngliche Bindung. Kein kryptografischer Nachweis, Exactly-once, automatischer KILL, Host-/VM-Wiederaufbau oder allgemeiner Beweis externer fachlicher Seiteneffekte. Die erwartete Verbindung/Transaktionsordnung wird durch den vertrauenswürdigen Providerpfad hergestellt, nicht von einer KI durch Einzelaufrufe improvisiert. IDs/Tokens/Nonces und Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
 -- OBJECT_USAGE_SKILL_HELP:END
 RETURN 0; END;
 IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 54221,N'Completion benötigt die eigene gesunde Handlertransaktion.',2;
 DECLARE @Resource nvarchar(255)=N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),@Nonce uniqueidentifier=TRY_CONVERT(uniqueidentifier,SESSION_CONTEXT(N'toolbelt.worker.attempt_nonce')),@Item bigint,@Generation bigint;
 IF @SlotReservationId IS NULL OR @ClaimToken IS NULL OR @ExecutionId IS NULL OR @Nonce IS NULL OR APPLOCK_MODE(N'public',@Resource,N'Session')<>N'Exclusive' THROW 54220,N'Die tatsächliche Handlerconnection besitzt den Attempt nicht.',1;
 SELECT @Item=WorkItemId,@Generation=ClaimGeneration FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@SlotReservationId AND ClaimToken=@ClaimToken AND ExecutionId=@ExecutionId AND AttemptNonce=@Nonce AND BoundPrincipalId=USER_ID() AND IsOccupied=1;
 IF @Item IS NULL THROW 54220,N'Die Attemptbindung ist veraltet oder widersprüchlich.',2;
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=5000,@DbPrincipal=N'public';
 IF @Lock<0 THROW 54222,N'Der Completion-Gate ist nicht verfügbar.',1;
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId AND IsHeld=1) THROW 54219,N'Stop gewinnt gegen Completion.',3;
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WHERE SlotReservationId=@SlotReservationId AND AttemptNonce=@Nonce AND ExecutionId=@ExecutionId AND ClaimGeneration=@Generation) THROW 54221,N'Der exakte Transaktionswitness fehlt.',3;
 DECLARE @CompletionNonce uniqueidentifier=NEWID();
 EXEC sys.sp_set_session_context @key=N'toolbelt.worker.completion_nonce',@value=@CompletionNonce;
 UPDATE toolbelt_core.WorkItem SET ManagedCompletionNonce=@CompletionNonce WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND Status='CLAIMED' AND ClaimGeneration=@Generation AND ClaimToken=@ClaimToken AND ManagedHold=0;
 IF @@ROWCOUNT<>1 THROW 54220,N'Der verwaltete Claim ist nicht mehr gültig.',3;
 RETURN 0;
END;
GO
