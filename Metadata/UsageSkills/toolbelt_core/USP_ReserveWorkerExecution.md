---
name: "toolbelt-core-usp-reserveworkerexecution"
description: "Interne atomare Managed-Admission mit genau einem kanonischen Queueclaim und neuer Slot-/Executionidentität."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_ReserveWorkerExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@WorkerId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerGeneration", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@WorkerToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL:direkte Ausgabe. Sonst bereits vom Caller angelegte lokale #Temp mit einfachem Namen2..116 UTF16-Einheiten; keine ##Temp/persistente/mehrteilige Tabelle. Der kanonische Helper prüft und bereitet die Form. Auch leere Ausgabe kann Zielzeilen bei KeepData0 ersetzen."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0:Zieldaten ersetzen,1:bei kompatibler Form anhängen,NULL gemäß Helper wie0. Nur für ResultTable; keine eigene Admission-/Claimoption."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReserveWorkerExecution.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
---

# USP_ReserveWorkerExecution

## Zweck und Einsatzfälle

Interne atomare Managed-Admission mit genau einem kanonischen Queueclaim und neuer Slot-/Executionidentität. Internes Objekt;kein manuelles Fachaufrufbeispiel als Ersatzprovider.

## Voraussetzungen

Interner Managedproviderhelfer, kein öffentlicher manueller Dispatch-/Recovery-/Replayweg. Kontrollierten Workerablauf mit öffentlichen Admission-/Status-/Reconcile-Einstiegen verwenden; diese Nennung behauptet keinen direkten Aufruf jedes Helpers durch jeden öffentlichen Einstieg. Worker-Control1.0.0,Queue2.1.0 und passende Context-/Cancellation-/ResultTable-Abhängigkeiten derselben Moduldatenbank; SQL2019/2022/2025 Windows/Linux, zulässigesCL150/160/170 lokal/zentral. Fachaufruf verlangt @@TRANCOUNT0 und XACT_STATE0; keine Caller-Savepoints oder frei erfundenen IDs/Tokens.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkerId` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@WorkerGeneration` | `bigint` | `NULL` | Input | Exakte bigint aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität.  |
| `@WorkerToken` | `uniqueidentifier` | `NULL` | Input | Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL:direkte Ausgabe. Sonst bereits vom Caller angelegte lokale #Temp mit einfachem Namen2..116 UTF16-Einheiten; keine ##Temp/persistente/mehrteilige Tabelle. Der kanonische Helper prüft und bereitet die Form. Auch leere Ausgabe kann Zielzeilen bei KeepData0 ersetzen. |
| `@KeepData` | `bit` | `0` | Input | 0:Zieldaten ersetzen,1:bei kompatibler Form anhängen,NULL gemäß Helper wie0. Nur für ResultTable; keine eigene Admission-/Claimoption. |
| `@Debug` | `tinyint` | `0` | Input | 0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf. |

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

Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Globales/lokales Budget zählt IsOccupied1,keine physische Kapazitätsgarantie; Claim kann WorkType-/Policy-/Barrier-/Retrydaten lesen und mutieren. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Eigene private #tbx_-Ergebnistemp vor Callertransaktionsguard; dann eigene Transaktion und UPDLOCK/HOLDLOCK Gate→Scheduler→Konfiguration. WorkerId/Generation/Token/OwnerPrincipalId=USER_ID mit State<>CLOSED prüfen; ManagedEnabled muss1 sein. Nur bei AdmissionPaused0,StateACTIVE,noch frischem Heartbeat und belegten Slots unter lokaler Capacity UND globalem MaxConcurrentExecutions wird Claim versucht. Sonst leeres normales Ergebnis, kein automatisches Reconcile/Revive. Bei Versuch neue Reservation/Execution/Admission-UUIDs; GateNonce/PendingReservation setzen, dann genau ein USP_ClaimWorkCore mit privater Admission,Reservation,OUTPUTCanonicalClaimId und EmitResult0, übrige Defaults (Lease300Sekunden,Debug0,kein ResultTable). Core verbraucht die GateNonce im selben gesunden Admission-TX und kann reife Retrybarriers armieren, auch ohne späteren Claim. Auswahl respektiert aktive WorkTypes, CLAIM-Policy, Handler-Metadatensicht/EXECUTE, ManagedHold und Gruppenbarriers; Priorität absteigend, dann Retrytermin/Enqueuezeit und WorkItemId. Keine Handlerausführung. Fester interner Transport liest ausschließlich die OUTPUTCanonicalClaimId mit exakter ManagedReservationId/CLAIMED, keine zweite Claimauswahl und kein INSERT EXEC. Nur bei Claim neue RESERVED/IsOccupied1-Reservation plus aktuelle Disposition NONE/IsHeld0; vorhandene Disposition wird nur wenn heldfrei auf neue Reservation bezogen. Keine neue globale ConfigVersion. Leeres Ergebnis beweist keine völlige Mutationsfreiheit: Nonce/Barrierzustände sowie ResultTable können sich ändern. Helperform/INSERT und Admissionmutationen liegen vor Commit, Fehler rollen eigene Transaktion zurück. Direkter Ergebnistransport erst nach Commit; Transportfehler machen eine erfolgte Reservation nicht rückgängig.

## Fehlerbehandlung

54210/1 Callertransaktion/nichtneutraler XACT_STATE;54211/1 fehlende Pflichtzeilen Gate/Scheduler/Konfiguration.54215/1 NULL oder fehlende Worker-/Token-/Principalautorität.54217/2 ManagedEnabled nicht1.54218/1 kanonische OUTPUTClaimId vorhanden, aber keine exakt reservierungsgebundene Transportzeile. Pausiert,unreachable/heartbeatabgelaufen,volle Capacity/globalesBudget oder kein passendes WorkItem ergeben regulär leere Ausgabe. QueueCore-/Policy-/Lease-/Helper-/Enginefehler bleiben getrennt; fehlende Tabellen können bereits Enginefehler statt54211 ergeben. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
