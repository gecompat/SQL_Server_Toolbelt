---
name: "toolbelt-core-usp-finalizeworkerfailure"
description: "Finalisiert nach bewiesenem Rollback eine Fail-/Retryentscheidung oder einen gehaltenen Abbruch."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_FinalizeWorkerFailure"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. Geheim, nicht protokollieren."}, {"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Exakte uniqueidentifier aus derselben tatsächlichen Worker-/Claim-/Reservationsbindung. Technischer NULL-Default nur Hilfe; keine synthetische Ersatzautorität. "}, {"name": "@FailureCode", "sql_type": "varchar(64)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich nichtNULL. Im heldfreien Fail-/Retrykern stabiler ASCII-Code:beginnt A-Z/a-z,danach nurBuchstaben/Ziffern/Punkt/Unterstrich/Bindestrich,bis64Zeichen. Held-/Leaseablaufzweig benutzt stattdessen WORKER.STOP_HELD und prüft hier nur NichtNULL; keine uniforme vollständige Syntaxprüfung vor beiden Zweigen behaupten."}, {"name": "@Retry", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "0:heldfrei FAILED über FailCore (Default);1:gespeicherte Retrypolicy entscheidet RETRY_WAIT oder DEAD_LETTER.NULL ungültig. Hold oder Leaseablauf gewinnt unabhängig vom Wert."}, {"name": "@Outcome", "sql_type": "varchar(24)", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler OUTPUT,kein Eingabesteuerwert. Erfolg:ROLLED_BACK_HELD,FAILED,RETRY_WAIT oder DEAD_LETTER. Caller für Übernahme ausdrücklich OUTPUT angeben. Vor Hilfe/Frühfehlern keine Initialisierung; ein vorgefundener Variablenwert ist kein Erfolgbeweis. Zuweisung erfolgt vor Commit, bei SQL-Fehler keine erfolgreiche Finalisierung daraus ableiten."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0..255 oder NULL; Default0, hier keine eigenen Messages und nicht an die delegierten Kerne weitergereicht."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende Standardhilfe plus genau eine vollständige Skillzeile, RETURN0 vor Fachprüfungen/-abfragen/-mutationen;0 oderNULL Fachpfad. Technische Defaults ermöglichen reinen Hilfeaufruf."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_FinalizeWorkerFailure.sql", "Modules/toolbelt.core.worker-control/Source/WorkerControlTables.sql", "Modules/toolbelt.core.work-queue/Source/USP_FailWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/USP_ScheduleWorkRetryCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql"]
review_status: "verified"
source_module_version: "1.0.0"
public_entrypoints: ["toolbelt_core.USP_ClaimWorkerWork", "toolbelt_core.USP_ReconcileWorkerExecution"]
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
| `@FailureCode` | `varchar(64)` | `NULL` | Input | Fachlich nichtNULL. Im heldfreien Fail-/Retrykern stabiler ASCII-Code:beginnt A-Z/a-z,danach nurBuchstaben/Ziffern/Punkt/Unterstrich/Bindestrich,bis64Zeichen. Held-/Leaseablaufzweig benutzt stattdessen WORKER.STOP_HELD und prüft hier nur NichtNULL; keine uniforme vollständige Syntaxprüfung vor beiden Zweigen behaupten. |
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

Nur vorhandene autorisierte interne EXECUTE-/Objekt-/Ownership-Chainrechte im kontrollierten Providerpfad nutzen; keine Rechte erteilen oder aus diesem Skill ableiten. Worker-/Claimtoken sind vertraulich und nicht austauschbar. Principalbindungen verwenden USER_ID der Moduldatenbank,keine Host-/Serveridentitätsattestation. AppLock-DbPrincipal public beschreibt hier den Locknamespace,keinen neuen Grant. Sessioncontext allein ist keine vollständige Autorität.

## Ressourcenbedarf

Keine CLR-/Datei-/Netzwerk-/LLM-Operation dieser Prozedur. Transaktionale Sperren,Queue-/Reservationumfang und delegierte SQL-Pläne bestimmen Aufwand; keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeitquote. Disposition-AppLock-Timeout5000ms ist kein Timeout für die gesamte Finalisierung. Kein eigener Retry; Deadlocks,Blockierung,Log-/tempdb-/Enginefehler bleiben möglich.

## Nebenwirkungen

SET NOCOUNT ON und SET XACT_ABORT OFF im Code vor positivem Hilfezweig. Hilfe ignoriert Fachwerte und kehrt vor Daten-/Kontextmutationen zurück; keine eigenen Debugmessages. Neutrales CallerTX vor eigener BEGIN. Exklusiver Session-Attempt-AppLock,konvertierbare Sessionattemptnonce sowie exaktes belegtes Slot/Claim/Execution/Nonce/BoundPrincipalId=USER_ID-Tupel erforderlich. Transaction-Disposition-AppLock5000ms/public,FailureCode/Retry nichtNULL. Locking Prüfung:Reservation ROLLED_BACK/IsOccupied1 und kein Witness zu diesem Slot; passende Disposition muss existieren. Hold1 ODER WorkItem-Lease<=EngineUTC gewinnt: exakt unverändertes CLAIMED-Item wird FAILED mit WORKER.STOP_HELD,FailureMessageNULL,ManagedHold1,ManagedCompletionNonceNULL; Reservation bleibtROLLED_BACK,wirdfrei/EndedAtUTC; Disposition bleibtheld/ROLLED_BACK_HELD; OutcomeROLLED_BACK_HELD. Sonst neue completion_nonce im Sessioncontext und exakt gebundener WorkItem.ManagedCompletionNonce; FailCore oder RetryCore mit EmitResult0/FailureCode und sonstDefaults aufrufen. Kerne prüfen erneut geschützte Terminalautorität und aktuelle Lease/Token; Lease kann zwischen Prüfungen ablaufen und dann einen ursprünglichen Queuefehler auslösen. Fail:FAILED; Retry:bei verbrauchten MaxAttempts DEAD_LETTER,sonst RETRY_WAIT mit min(Base*2^(CycleAttemptCount-1),MaxDelay),keinJitter. Outcome aus tatsächlichem Status lesen; nur heldfreie FAILED/RETRY_WAIT/DEAD_LETTER-Zeile mit exakter Reservation/Generation wird von ManagedCompletionNonce/ManagedReservationId gelöst. Reservation IsOccupied0/EndedAtUTC,State bleibtROLLED_BACK; Attempt-/Execution-/Claimhistory und Disposition werden nicht gelöscht. Keine Handlertransaktion durch diesen Aufruf zurückrollen oder erneut ausführen. Kontextnonce wird hier nicht zurückgesetzt. Outcome-Zuweisung erfolgt vor eigener COMMIT; CATCH rollt eigene aktive Buchung zurück und wirft, ohne einen beliebigen OUTPUT-Wert als Commitbeweis zu legitimieren.

## Fehlerbehandlung

54210/1 nichtneutraler Caller.54220/1 fehlende IDs/Nonce/Sessionattemptlock;54220/2 fehlende exakte belegte Principalbindung.54222/2 negativer Disposition-AppLock-Rückgabecode.54213/6 FailureCodeNULL oder RetryNULL.54223/2 keine ROLLED_BACK/IsOccupied1-Reservation oder irgendein Witness vorhanden;54223/3 passende Disposition fehlt.54220/5 heldgebundener Claim verändert;54220/7 heldfreier Terminalclaim verändert;54220/8 keine exakt heldfrei gelöste terminale Queueentscheidung. Delegierte Fehler bleiben sichtbar:geschützter Managedpfad54201,Fail51925..51929/Retry51985..51989 und technische Enginefehler. TypedParameterkonvertierung kann vor diesen Prüfungen wirken. In eigenen TRY/CATCH-Pfaden wird aktive eigene Transaktion zurückgerollt und erneut geworfen; Rollback-/Cleanupfehler sind nicht separat geschützt. Fehlende Tabellen/Prozeduren,Typkonvertierung oder beschädigte fremde Definitionen bleiben ursprüngliche Enginefehler. Kein generisches PASS-/Cleanup-Attest durch RETURN0.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag,keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Recoveryabnahme. Historische Fachbelege behalten ihre ursprüngliche Artefakt-/Zielbindung. Keine Exactly-once-,KILL-,Host-/VM-Ausfall-,Commit-/Rollback- oder Transportgesamtqualifikation allein durch Status/Token/OUTPUT. IDs/Token/Nonce/Payloads und reale Runtimebefunde privat halten. Native Caller-/OUTPUTsemantik bleibt separat abzunehmen. Keine Installations-/Rechteattestation.
