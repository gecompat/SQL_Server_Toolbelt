-- Objekt: toolbelt_core.USP_RecordWorkerUnknown
-- Zweck: Persistiert Unsicherheit und lässt die Reservation belegt; kein Replay oder Slotfreigabe.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_RecordWorkerUnknown
 @SlotReservationId uniqueidentifier=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @ExecutionId uniqueidentifier=NULL,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-core-usp-recordworkerunknown"
-- description: "Persistiert eine unsichere Attemptausführung ohne Slotfreigabe oder Replay."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.core.worker-control"
-- schema_name: "toolbelt_core"
-- object_name: "USP_RecordWorkerUnknown"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier der eigenen Slotreservation; Pflicht im Fachpfad, technischer NULL-Default nur für Hilfe. Keine WorkerId oder WorkItemId."}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Geheimes WorkerToken derselben Workerregistration; zusammen mit Slot/Execution und USER_ID geprüft. Kein ClaimToken; nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier der gebundenen Execution; Pflicht im Fachpfad, kein frei erfundener Replay-/Recoverywert. NULL-Default nur Hilfe."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL, Default0; im aktuellen Helper kein eigener Diagnose-/Messagepfad und kein Tokenoutput."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Transaktions-/Bindungs-/Fachprüfungen oder Mutationen. 0 oder NULL: Fachpfad. Technische Defaults erlauben reinen Hilfeaufruf."}]
-- source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_RecordWorkerUnknown.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
-- ---
--
-- # USP_RecordWorkerUnknown
--
-- ## Zweck und Einsatzfälle
--
-- Persistiert eine unsichere Attemptausführung ohne Slotfreigabe oder Replay. Internes Objekt; öffentliche Nutzungswege siehe Frontmatter.
--
-- ## Voraussetzungen
--
-- Interner Providerhelfer, kein manueller öffentlicher Recovery-/Replayweg. Regulär den kontrollierten Managed-Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet nicht, dass jeder öffentliche Einstieg den Helper direkt aufruft. Worker-Control1.0.0 mit passender Queue2.1.0/Context-/Cancellationintegration derselben DB; SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170 lokal/zentral. Vor dem Fachaufruf @@TRANCOUNT0 und XACT_STATE0; eigener kurzer Buchungstransaktionsrahmen. Dies ersetzt nicht das zuvor tatsächlich beendete Handlertransaktionsgeschehen.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@SlotReservationId` | `uniqueidentifier` | `NULL` | Exakte uniqueidentifier der eigenen Slotreservation; Pflicht im Fachpfad, technischer NULL-Default nur für Hilfe. Keine WorkerId oder WorkItemId. |
-- | `@WorkerToken` | `uniqueidentifier` | `NULL` | Geheimes WorkerToken derselben Workerregistration; zusammen mit Slot/Execution und USER_ID geprüft. Kein ClaimToken; nicht protokollieren. |
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
-- EXEC toolbelt_core.USP_RecordWorkerUnknown @Hilfe=1;
-- -- Fachaufruf ausschließlich im kontrollierten Managedprovider, nicht manuell nachstellen.
-- ```
--
-- ## Rechte
--
-- Nur bereits autorisierte interne Provider-/Handlerausführung mit vorhandenen EXECUTE-Rechten und passenden tatsächlichen Objekt-/Ownership-Chains verwenden. Keine Rechte aus diesem Skill ableiten oder erteilen. Tabellen-DML/SESSION_CONTEXT allein ist keine öffentliche Ersatzschnittstelle. WorkerToken plus OwnerPrincipalId=USER_ID autorisieren diesen Kontrollpfad; keine Sessionlock-/Nonce-Voraussetzung hinzufügen.
--
-- ## Ressourcenbedarf
--
-- Kein CLR-/Datei-/Netzwerk-/LLM-Aufruf. Datenbank-/Zeilen-/Schlüsselsperren, vorhandene Indizes und konkurrierende Providersteuerung bestimmen Aufwand. Kein eigener AppLock-Warteparameter in diesem Helper. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote oder Retryschleife; Sperr-/Deadlock-/Enginefehler bleiben möglich.
--
-- ## Nebenwirkungen
--
-- SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe kehrt vor allen beschriebenen Fachaktionen zurück, prüft keine Pflichtbindungen und schreibt keine fachlichen Daten. Verwendet WorkerToken, nicht ClaimToken. JOIN Reservation→WorkerRegistration nach WorkerId/Generation, exakte SlotReservationId/ExecutionId und aktueller USER_ID. Kein Session-Attempt-AppLock, keine Sessionnonce und keine Witnessprüfung erforderlich; ein Kontrollconnectionpfad ist möglich. Kein Filter auf WorkerRegistration.State oder jüngste Generation. Setzt ausschließlich Reservations-State UNKNOWN, solangeIsOccupied1; IsOccupied bleibt1 und EndedAtUtc bleibt unverändert. Keine WorkItem-/Disposition-/Witnessmutation, kein Stop, keine automatische Recovery oder Freigabe. RETURN0 bestätigt die Unsicherheitsbuchung, keinen Commit/Rollback des Handlers.
--
-- ## Fehlerbehandlung
--
-- 54210/1 nichtneutraler Transaktionszustand.54220/4 kein Tupel aus Slot/Execution und zugehöriger Workerregistration mit WorkerToken,OwnerPrincipalId=USER_ID und IsOccupied1. NULL-/abweichende Bindungen erfüllen diese Autorität nicht. Ursprüngliche Constraint-/PK-/Konvertierungs-/AppLock-/Enginefehler bleiben technisch. TRY/CATCH rollt die eigene noch aktive Buchungstransaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine Caller-Savepoints.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Commit-/Rollback-/Hostverlustabnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Kein kryptografischer Nachweis, Exactly-once, automatischer KILL, Host-/VM-Wiederaufbau oder allgemeiner Beweis externer fachlicher Seiteneffekte. Die erwartete Verbindung/Transaktionsordnung wird durch den vertrauenswürdigen Providerpfad hergestellt, nicht von einer KI durch Einzelaufrufe improvisiert. IDs/Tokens/Nonces und Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_RecordWorkerUnknown' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Persistiert Unsicherheit und lässt die Reservation belegt; kein Replay oder Slotfreigabe.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@WorkerToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerToken',NULL),
 ('PARAMETER',3,N'@ExecutionId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExecutionId',NULL),
 ('PARAMETER',4,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',5,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,NULL,NULL,NULL,NULL,NULL,N'Kein fachliches Resultset; OUTPUT und Returncode siehe Parametervertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_RecordWorkerUnknown @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql);
-- OBJECT_USAGE_SKILL_HELP:COMPACT
 -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_core' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_RecordWorkerUnknown' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-core-usp-recordworkerunknown"
description: "Persistiert eine unsichere Attemptausführung ohne Slotfreigabe oder Replay."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_RecordWorkerUnknown"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier der eigenen Slotreservation; Pflicht im Fachpfad, technischer NULL-Default nur für Hilfe. Keine WorkerId oder WorkItemId."}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Geheimes WorkerToken derselben Workerregistration; zusammen mit Slot/Execution und USER_ID geprüft. Kein ClaimToken; nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier der gebundenen Execution; Pflicht im Fachpfad, kein frei erfundener Replay-/Recoverywert. NULL-Default nur Hilfe."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL, Default0; im aktuellen Helper kein eigener Diagnose-/Messagepfad und kein Tokenoutput."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Transaktions-/Bindungs-/Fachprüfungen oder Mutationen. 0 oder NULL: Fachpfad. Technische Defaults erla' AS nvarchar(max)) + N'uben reinen Hilfeaufruf."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_RecordWorkerUnknown.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
---

# USP_RecordWorkerUnknown

## Zweck und Einsatzfälle

Persistiert eine unsichere Attemptausführung ohne Slotfreigabe oder Replay. Internes Objekt; öffentliche Nutzungswege siehe Frontmatter.

## Voraussetzungen

Interner Providerhelfer, kein manueller öffentlicher Recovery-/Replayweg. Regulär den kontrollierten Managed-Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet nicht, dass jeder öffentliche Einstieg den Helper direkt aufruft. Worker-Control1.0.0 mit passender Queue2.1.0/Context-/Cancellationintegration derselben DB; SQL2019/2022/2025 Windows/Linux, zulässiges CL150/160/170 lokal/zentral. Vor dem Fachaufruf @@TRANCOUNT0 und XACT_STATE0; eigener kurzer Buchungstransaktionsrahmen. Dies ersetzt nicht das zuvor tatsächlich beendete Handlertransaktionsgeschehen.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Exakte uniqueidentifier der eigenen Slotreservation; Pflicht im Fachpfad, technischer NULL-Default nur für Hilfe. Keine WorkerId oder WorkItemId. |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Geheimes WorkerToken derselben Workerregistration; zusammen mit Slot/Execution und USER_ID geprüft. Kein ClaimToken; nicht protokollieren. |
| `@ExecutionId` | `uniqueidentifier` | `NULL` | Exakte uniqueidentifier der gebundenen Execution; Pflicht im Fachpfad, kein frei erfundener Replay-/Recoverywert. NULL-Default nur Hilfe. |
| `@Debug` | `tinyint` | `0` | 0..255 oder NULL, Default0; im aktuellen Helper kein eigener Diagnose-/Messagepfad und kein Tokenoutput. |
| `' + N'@Hilfe` | `bit` | `0` | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Transaktions-/Bindungs-/Fachprüfungen oder Mutationen. 0 oder NULL: Fachpfad. Technische Defaults erlauben reinen Hilfeaufruf. |

SQL-Parametertypkonvertierung erfolgt vor Ausführung. Alle Werte gehören zu derselben tatsächlichen Attemptbindung; synthetische Werte sind keine ausführbare Recoveryfreigabe.

## Ergebnisse

Kein fachlicher Resultset, keine OUTPUT-Parameter, keine ResultTable-/KeepData-Option. RETURN0 bei erfolgreichem Helperpfad oder Hilfe; ursprüngliche fachliche SQL-Operationen werden dadurch weder wiederholt noch allgemein als erfolgreich attestiert. Hilfe liefert bisherigen zwölfspaltigen Standardhelp plus genau eine vier-spaltige Skillzeile: SkillFormatVersion varchar(16),SchemaName sysname,ObjectName sysname,SkillMarkdown nvarchar(max).

## Aufrufbeispiele

```sql
-- Sicherer Referenzaufruf ohne Attemptmutation:
EXEC toolbelt_core.USP_RecordWorkerUnknown @Hilfe=1;
-- Fachaufruf ausschließlich im kontrollierten Managedprovider, nicht manuell nachstellen.
```

## Rechte

Nur bereits autorisierte interne Provider-/Handlerausführung mit vorhandenen EXECUTE-Rechten und passenden tatsächlichen Objekt-/Ownership-Chains verwenden. Keine Rechte aus diesem Skill ableiten oder erteilen. Tabellen-DML/SESSION_CONTEXT allein ist keine öffentliche Ersatzschnittstelle. WorkerToken plus OwnerPrincipalId=USER_ID autorisieren diesen Kontrollpfad; keine Sessionlock-/Nonce-Voraussetzung hinzufügen.

## Ressourcenbedarf

Kein CLR-/Datei-/Netzwerk-/LLM-Aufruf. Datenbank-/Zeilen-/Schlüsselsperren, vorhandene Indizes und konkurrierende Providersteuerung bestimmen Aufwand. Kein eigener AppLock-Warteparameter in diesem Helper. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote oder Retryschleife; Sperr-/Deadlock-/Enginefehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe kehrt vor allen besc' + N'hriebenen Fachaktionen zurück, prüft keine Pflichtbindungen und schreibt keine fachlichen Daten. Verwendet WorkerToken, nicht ClaimToken. JOIN Reservation→WorkerRegistration nach WorkerId/Generation, exakte SlotReservationId/ExecutionId und aktueller USER_ID. Kein Session-Attempt-AppLock, keine Sessionnonce und keine Witnessprüfung erforderlich; ein Kontrollconnectionpfad ist möglich. Kein Filter auf WorkerRegistration.State oder jüngste Generation. Setzt ausschließlich Reservations-State UNKNOWN, solangeIsOccupied1; IsOccupied bleibt1 und EndedAtUtc bleibt unverändert. Keine WorkItem-/Disposition-/Witnessmutation, kein Stop, keine automatische Recovery oder Freigabe. RETURN0 bestätigt die Unsicherheitsbuchung, keinen Commit/Rollback des Handlers.

## Fehlerbehandlung

54210/1 nichtneutraler Transaktionszustand.54220/4 kein Tupel aus Slot/Execution und zugehöriger Workerregistration mit WorkerToken,OwnerPrincipalId=USER_ID und IsOccupied1. NULL-/abweichende Bindungen erfüllen diese Autorität nicht. Ursprüngliche Constraint-/PK-/Konvertierungs-/AppLock-/Enginefehler bleiben technisch. TRY/CATCH rollt die eigene noch aktive Buchungstransaktion zurück und wirft erneut; Rollbackfehler nicht separat geschützt. Keine Caller-Savepoints.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Commit-/Rollback-/Hostverlustabnahme. Historische Nachweise behalten ihre ursprüngliche Bindung. Kein kryptografischer Nachweis, Exactly-once, automatischer KILL, Host-/VM-Wiederaufbau oder allgemeiner Beweis externer fachlicher Seiteneffekte. Die erwartete Verbindung/Transaktionsordnung wird durch den vertrauenswürdigen Providerpfad hergestellt, nicht von einer KI durch Einzelaufrufe improvisiert. IDs/Tokens/Nonces und Runtimebefunde privat behandeln; keine Installations-/Rechteattestation.
' AS SkillMarkdown;
 -- OBJECT_USAGE_SKILL_HELP:END
 RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation r JOIN toolbelt_core.WorkerRegistration w ON w.WorkerId=r.WorkerId AND w.WorkerGeneration=r.WorkerGeneration WHERE r.SlotReservationId=@SlotReservationId AND r.ExecutionId=@ExecutionId AND w.WorkerToken=@WorkerToken AND w.OwnerPrincipalId=USER_ID() AND r.IsOccupied=1) THROW 54220,N'Der Unknownpfad besitzt keine Attemptautorität.',4;
 UPDATE toolbelt_core.WorkerSlotReservation SET State='UNKNOWN' WHERE SlotReservationId=@SlotReservationId AND IsOccupied=1;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 RETURN 0;
END;
GO
