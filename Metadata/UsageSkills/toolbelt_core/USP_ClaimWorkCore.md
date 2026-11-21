---
name: "toolbelt-core-usp-claimworkcore"
description: "Atomarer prioritäts- und barriergesteuerter Queueclaim mit begrenzter Lease. Interner Kern."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_ClaimWorkCore"
object_type: "USP"
database_role: "toolbelt"
is_internal: true
parameters: [{"name": "@ManagedAdmissionToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL: normaler öffentlicher Queueclaim. NichtNULL: nur geschützte aktuelle GateNonce im selben gesunden Admission-TX, kein frei gewähltes Token."}, {"name": "@ManagedReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL im nicht verwalteten Pfad; bei Managed-Admission exakte aktuelle PendingReservationId derselben Gatezeile."}, {"name": "@ClaimedWorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "Privater OUTPUT der exakt per UPDATE OUTPUT geclaimten ID oderNULL. Normalpfad setzt vor ValidierungNULL; Hilfe verändert den eingehenden OUTPUT nicht. Nur nach erfolgreichem Gesamtlauf verwenden; frühe Fehler/variabler Altwert sind kein Claimbeweis."}, {"name": "@EmitResult", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "1:direktes Fachresultset (Default).0:direkte Ausgabe nur mit nichtNULL privatem ManagedAdmissionToken unterdrücken; ResultTable-Routing wird dadurch nicht ausgeschaltet. NULL ist54200/4."}, {"name": "@LeaseDurationSeconds", "sql_type": "int", "sql_default": "300", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ClaimWorkCore.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/WorkQueueManagedGate.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.work-type/Source/TVF_WorkTypeAuthorization.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
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
| `@ClaimedWorkItemId` | `bigint` | `NULL` | Input/OUTPUT | Privater OUTPUT der exakt per UPDATE OUTPUT geclaimten ID oderNULL. Normalpfad setzt vor ValidierungNULL; Hilfe verändert den eingehenden OUTPUT nicht. Nur nach erfolgreichem Gesamtlauf verwenden; frühe Fehler/variabler Altwert sind kein Claimbeweis. |
| `@EmitResult` | `bit` | `1` | Input | 1:direktes Fachresultset (Default).0:direkte Ausgabe nur mit nichtNULL privatem ManagedAdmissionToken unterdrücken; ResultTable-Routing wird dadurch nicht ausgeschaltet. NULL ist54200/4. |
| `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

Alle technischen Defaults erlauben Hilfe. Pflicht-NULLwerte sind keine gültigen fachlichen Ersatzbindungen. Typkonvertierung und gebundene Breite liegen vor dem Prozedurcode.

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

Queue-/Policy-/Barrierumfang und konkurrierende Sperren bestimmen Aufwand. Claim kann Barriersnapshots vor der Einzelauswahl mutieren; READPAST kann gesperrte Kandidaten überspringen, keine globale strikte FIFOgarantie. Keine implementierte CPU-/Heap-/Log-/Gesamtlaufzeit-/Ausgabebytequote und kein eigener Retry. ResultTable-DDL/INSERT erweitert den TXumfang; Sperr-,Deadlock-,Log-/tempdb- und Enginefehler bleiben möglich.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF stehen vor der Hilfe. KeepData/Debug/Hilfe werden im Claim-/FailpfadNULL→0 normalisiert. Der öffentliche Claim delegiert ohne Managedtoken an den einen kanonischen ClaimCore. Kein Caller-TX für diesen Pfad. Der Kern setzt sein privates OUTPUT zunächstNULL und validiert EmitResult, Transaktionsform und Lease5..86400. Eigene Transaktion oder im geschützten Managedpfad ein Savepoint. Gate/Scheduler werden mit UPDLOCK/HOLDLOCK gelesen. ManagedEnabled0 erlaubt keine privaten Token/Reservation; ManagedEnabled1 verlangt passende einmalige GateNonce und PendingReservation im selben gesunden Admission-TX. Bei Managed-Admission wird die Nonce verbraucht/erneuert. Reife Retrybarriers können BARRIER_WAIT werden und neue Blockersnapshots erhalten, auch wenn am Ende kein Item geclaimt wird.

Kandidat mit UPDLOCK,READPAST,READCOMMITTEDLOCK,ROWLOCK und Statusindex: aktiver WorkType, sichtbare nichtsystemeigene Handlerprocedure, CLAIM-Policy erlaubt und Handler-EXECUTE vorhanden. Kein ManagedHold. SHARED ist QUEUED oder fälliger RETRY_WAIT und durch keine wartende/laufende Gruppenbarrier blockiert. DRAIN_BARRIER muss BARRIER_WAIT sein, keine erfasste aktive Blockergeneration und keine anders priorisierte laufende Barrier derselben Gruppe haben. Reihenfolge: Priority DESC, dann Retrytermin beziehungsweise EnqueuedAtUtc, dann WorkItemId. Keine Preemption oder automatische Übernahme abgelaufener Claims.

Höchstens ein UPDATE: neuer ClaimToken/EngineUTC/ORIGINAL_LOGIN,ClaimGeneration+1,LeaseDuration/LeaseUntil/Heartbeat, CycleAttemptCount+1,NextAttemptNULL und gegebenenfalls ManagedReservationbindung. Exakte ID aus UPDATE OUTPUT, kein zweiter Claim. Zielvorbereitung/INSERT gehören zur Transaktion. Nur eigener TX wird committed; CATCH rollt eigenen TX oder committable Caller-Savepoint zurück. Debug>0 liefert danach eine abstrakte Severity10-NOWAIT-Message, kein Payload-/Tokenlogging. Ein späterer Debug-/Ergebnistransportfehler kann einen eigenen bereits erfolgten Commit nicht zurücknehmen.

## Fehlerbehandlung

54200/4 EmitResultNULL oder EmitResult0 ohne privaten Token.51910 unzulässige Transaktionsform;51911 LeaseNULL/außerhalb5..86400.54200/1 fehlender Managedgate, /2 private Bindung im Managedmodus fehlt/driftet, /3 private Werte bei deaktiviertem Managedmodus.51918 fehlender ResultTablehelper. Frühere OUTPUT-Initialisierung ist von Erfolg zu trennen. Ursprüngliche Engine-,Helper-,Savepoint-,Constraint- und Überlauffehler bleiben sichtbar. Eigene aktive Transaktion oder committable eigener Savepoint wird im CATCH zurückgesetzt; kein Überschreiben fremder gesamter Callertransaktionen. Rollbackfehler sind nicht separat geschützt. Keine automatische Wiederholung.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Hilfe-/Unicode-/OUTPUT-/Callerzustands-/Minimalrechte-/Installer-/Lease-/Retryabnahme. Historische Fachbelege behalten ihre Artefakt-/Zielbindung. Kein Exactly-once, Prozessstart, KILL, Host-/VM-Recovery oder automatische fremde Claimübernahme. Typkonvertierung kann vor dem Code auf die deklarierte Breite wirken; RetryMessage nvarchar(1000) kann keine ursprünglich breitere Quelle nachträglich attesten. Bereinigung von Payload/Fehlertext ist Calleraufgabe. IDs/Token/Payload/Runtimebefunde privat halten; keine Installations-/Rechteattestation.
