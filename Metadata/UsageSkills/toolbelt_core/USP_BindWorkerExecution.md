---
name: "toolbelt-core-usp-bindworkerexecution"
description: "Bindet eine frische tatsächliche Handlerconnection einmalig an eine exakte Reservation."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_BindWorkerExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ClaimGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_BindWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
---

# USP_BindWorkerExecution

## Zweck und Einsatzfälle

Bindet eine frische tatsächliche Handlerconnection einmalig an eine exakte Reservation. Internes Objekt;kein manuelles Fachaufrufbeispiel als Ersatzprovider.

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
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
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

## Ressourcenbedarf

Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Bind verwendet Session-AppLock-Timeout0. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Vor Handlertransaktion neutraler Caller erforderlich. Exklusiver Session-AppLock Toolbelt.Worker.Attempt.<SlotReservationId> mit DbPrincipalpublic und LockTimeout0, kein Warten/Retry. Negative Rückgabe wirft vor TRY. Danach eigene Transaktion: exaktes RESERVED/AttemptNonceNULL/IsOccupied1-Tupel mit Slot,WorkerId/Generation,WorkerToken/OwnerPrincipalId=USER_ID,ClaimGeneration/ClaimToken/ExecutionId unter UPDLOCK/HOLDLOCK prüfen. Bestehender Hold blockiert Dispatch. Neue Attemptnonce in SESSION_CONTEXT(toolbelt.worker.attempt_nonce) mit read_only1 setzen; Reservation bekommt dieselbe Nonce,BoundPrincipalId USER_ID und StateRUNNING. Danach Commit; Session-Attempt-AppLock bleibt absichtlich gehalten. Kein Rebind, kein Handler-SQL und keine neue Claim-/Executionidentität. CATCH rollt aktive eigene Transaktion zurück und ruft sp_releaseapplock für den Sessionlock; Cleanupfehler sind nicht separat geschützt. Kein Reset des read-only-Kontextschlüssels im Code, auch nicht nach späterem Fehler. Frische isolierte tatsächliche Connection pro Attempt verwenden und Lebensdauer durch den kontrollierten Provider führen; nicht allein neue SQL-Variablen auf einer alten Connection verwenden.

## Fehlerbehandlung

54210/3 nichtneutraler Caller vor Handlertransaktion.54218/1 negativer Session-AppLock-Rückgabecode;54218/2 keine exakte frische RESERVED-/Worker-/Claim-/Principalbindung.54219/1 Hold vor Dispatch. NULL-/Konvertierungs-/AppLock-Resource-/read-only-Sessioncontextfehler können ursprüngliche Enginefehler erzeugen; keine universelle54218-Abbildung aller ungültigen Werte. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
