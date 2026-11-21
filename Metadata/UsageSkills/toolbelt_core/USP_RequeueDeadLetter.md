---
name: "toolbelt-core-usp-requeuedeadletter"
description: "Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_RequeueDeadLetter"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt."}, {"name": "@ExpectedRowVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung."}, {"name": "@RequeueReason", "sql_type": "nvarchar(1000)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_RequeueDeadLetter.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_RequeueDeadLetter

## Zweck und Einsatzfälle

Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.

## Voraussetzungen

Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Aktuell DEAD_LETTER, nicht gehalten und nicht Managed. Aktuelle RowVersion für optionales CAS; NULL deaktiviert CAS. Keine freie Freigabe unbekannter Ownership. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. Muss im Zustand DEAD_LETTER sein; gehaltene/managed Items verlangen den geschützten Freigabepfad. Keine Callertransaktion erlaubt. |
| `@ExpectedRowVersion` | `binary(8)` | `NULL` | Input | Optionaler binary(8)-Wert aus der zuletzt gelesenen RowVersion der betreffenden Zeile, als Bytes/SQL-Hexliteral (nicht als Hextext). NULL schaltet diese optionale Vergleichsprüfung aus; bei Abweichung wird die Änderung abgewiesen. Eine Abweichung führt wie ein nicht requeuebarer Zustand zur Ablehnung. |
| `@RequeueReason` | `nvarchar(1000)` | `NULL` | Input | Optionaler Unicode-Freitext nvarchar(1000), NULL (Default) und leer sind zulässig; wird als LastRequeueReason gespeichert, nicht ausgeführt oder automatisch bereinigt. Keine JSON-Struktur und kein festes Wertevokabular. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

## Ergebnisse

| Spalte | SQL-Typ | Regeln/Bedeutung |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL; IDENTITY(1,1), geclusterter Primärschlüssel |
| `WorkTypeName` | `varchar(128)` | WorkType-Katalogname, BIN2 |
| `Status` | `varchar(16)` | NOT NULL; BIN2, Default QUEUED |
| `EnqueuedAtUtc` | `datetime2(7)` | NOT NULL; Default SYSUTCDATETIME() |
| `EnqueuedBy` | `sysname` | NOT NULL; Default ORIGINAL_LOGIN() |
| `ClaimedAtUtc` | `datetime2(7)` | NULL |
| `ClaimedBy` | `sysname` | NULL |
| `CompletedAtUtc` | `datetime2(7)` | NULL |
| `CompletedBy` | `sysname` | NULL |
| `FailedAtUtc` | `datetime2(7)` | NULL |
| `FailedBy` | `sysname` | NULL |
| `FailureCode` | `varchar(64)` | NULL; BIN2 |
| `FailureMessage` | `nvarchar(1000)` | NULL |
| `RowVersion` | `binary(8)` | Konvertierter WorkItem-Rowversionwert, keine Zeitangabe |
| `ClaimGeneration` | `bigint` | NOT NULL; Default0 |
| `LeaseDurationSeconds` | `int` | NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NULL |
| `IsLeaseExpired` | `bit` | 1 genau bei Status CLAIMED und LeaseUntilUtc<=SYSUTCDATETIME(), sonst0 |
| `RecoveryCount` | `bigint` | NOT NULL; Default0 |
| `LastRecoveredAtUtc` | `datetime2(7)` | NULL |
| `LastRecoveredBy` | `sysname` | NULL |
| `ExecutionGroup` | `varchar(128)` | NOT NULL; BIN2, Default default |
| `Priority` | `tinyint` | NOT NULL; Default0 |
| `ExecutionMode` | `varchar(16)` | NOT NULL; BIN2, Default SHARED |
| `MaxAttempts` | `tinyint` | NOT NULL; Default3 |
| `RetryBaseDelaySeconds` | `int` | NOT NULL; Default60 |
| `RetryMaxDelaySeconds` | `int` | NOT NULL; Default3600 |
| `RetryCycleNumber` | `bigint` | NOT NULL; Default1 |
| `CycleAttemptCount` | `bigint` | NOT NULL; Default0 |
| `NextAttemptAtUtc` | `datetime2(7)` | NULL |
| `LastErrorCode` | `varchar(64)` | NULL; BIN2 |
| `LastErrorMessage` | `nvarchar(1000)` | NULL |
| `LastRetryScheduledAtUtc` | `datetime2(7)` | NULL |
| `LastRetryScheduledBy` | `sysname` | NULL |
| `DeadLetteredAtUtc` | `datetime2(7)` | NULL |
| `DeadLetteredBy` | `sysname` | NULL |
| `LastRequeuedAtUtc` | `datetime2(7)` | NULL |
| `LastRequeuedBy` | `sysname` | NULL |
| `LastRequeueReason` | `nvarchar(1000)` | NULL |
| `BarrierEpoch` | `bigint` | NOT NULL; Default0 |

Eine Zeile bei erfolgreichem Übergang. 41 Viewspalten; ohne ResultTable live nach Commit gelesen. ResultTable=NULL liefert den direkten Fachresultset; sonst Routing in das lokale Callerziel über PrepareResultTable ohne zusätzlichen Fach-SELECT. Keine Payload, ClaimToken oder privaten Managedtokens in der Ausgabe. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). RETURN0 vor Fachzugriff; normaler Return ebenfalls 0, bei Requeue implizit.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;

-- Synthetische ID/RowVersion durch das eigene tatsächliche DEAD_LETTER-Item ersetzen.
EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=1,
 @ExpectedRowVersion=0x0000000000000001,@RequeueReason=N'Contoso: Ursache behoben';
```

## Rechte

Vorhandenes EXECUTE auf den öffentlichen Einstieg, passender Datenbankzugriff und Identitätsmapping für zentrale Dreiteilnamen. Keine Rechtevergabe aus dem Skill ableiten. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Kein eigener WorkType-ENQUEUE-/CLAIM-/Handler-EXECUTEguard; die Berechtigung für diesen Supervisor-, Completion- oder Heartbeatweg gezielt vergeben. Keine Besitzer- oder Mandantentrennung allein durch diesen Aufruf. ResultTable braucht ein vorhandenes zulässiges lokales #Ziel und Helper-/Temp-DDL-/INSERT-Rechte; keine pauschale Serverrolle.

## Ressourcenbedarf

Private Ergebnistabellen in tempdb, Item-/Scheduler-/Indexlocks, Log-/Speicherbedarf und Sperrkonkurrenz. Recovery mit READPAST kann gesperrte Items überspringen. MaxItems ist keine CPU-, Heap-, Log- oder Gesamtlaufzeitquote. Barrierrequeue erzeugt Blockersnapshots nach Gruppenbreite. Kein eigener Timeout-/Retryloop oder Host-/VM-Eingriff. Zählerüberläufe bleiben Enginefehler.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF vor früher Hilfe. Keine Callertransaktion; ManagedHold oder ManagedReservation werden vor und unter dem Lock abgewiesen. Positive ID ist erforderlich. EngineUTC wird vor der Transaktion erfasst. Eigene Transaktion; optionales ResultTable vor Itemprüfung vorbereiten. SchedulerId=1 mit UPDLOCK/HOLDLOCK lesen, ohne eigenen Seed-Existenzguard. WorkItem mit UPDLOCK/HOLDLOCK im Status DEAD_LETTER und optional passender ExpectedRowVersion lesen; fehlt die passende Mode, folgt 51991. Kein WorkType-Aktivitäts-, Handler-, ENQUEUE- oder CLAIM-Policyfilter.

UPDATE beginnt RetryCycleNumber+1, setzt CycleAttemptCount=0 und NextAttemptAtUtc=NULL. Status ist QUEUED für SHARED oder BARRIER_WAIT für DRAIN_BARRIER. Claim-/Lease-/Heartbeat-/Failed-/DeadLetterfelder werden gelöscht. LastRequeuedAtUtc/ORIGINAL_LOGIN und der gebundene freie Reason werden gespeichert. ClaimGeneration, RecoveryCount, gespeicherte Policy, IdempotencyKey und LastErrorhistorie bleiben erhalten. BarrierEpoch wird nur für eine Barrier erhöht. Neue Blockersnapshots erfassen bereits CLAIMED Items derselben Gruppe, außer Barriers gleicher Priority; alte Epochsnapshots bleiben gespeichert. Kein Claim oder Handlerstart.

Mit ResultTable werden die 41 Spalten innerhalb der Transaktion materialisiert und geroutet. COMMIT, im CATCH eigener ROLLBACK. Ohne Ziel folgt SELECT * aus VW_WorkQueue nach Commit: live Ausgabe, kein materialisierter Entscheidungsreceipt. Ein konkurrierender Claim kann bereits einen neueren Status zeigen. Keine eigene Debug-Message; Debug/KeepData werden nur bei vorhandenem Ziel an den Helper übergeben. Kein eigener expliziter normaler RETURN; die implizite 0 beweist keinen Handlererfolg.

## Fehlerbehandlung

51993: Caller-TX/XACT_STATE nicht 0. 54201/1: früher Managed-/Holdguard; /2: Guard unter Lock. 51990: ID NULL/nicht positiv. 51991: Item fehlt, ist nicht DEAD_LETTER oder RowVersion weicht ab. 51908: ResultTablehelper fehlt. Kein separater Fehlercode für CAS-Abweichung. Ursprüngliche Engine-, Constraint-, Konvertierungs-, Helper-, Sperr-, Deadlock- und Rollbackfehler bleiben sichtbar. Keine automatische Wiederholung. Spätere Message-/Ergebnistransportfehler können einen eigenen bereits ausgeführten Commit nicht zurücknehmen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Konkurrenz-/Lease-/Recoveryabnahme. Historische Nachweise behalten ihre Artefaktbindung. Kein Exactly-once, Prozess-KILL oder Nachweis für Hostausfall/Koordinatorverlust. Die Claim-/Leasevoraussetzungen gelten für über öffentliche APIs wohlgeformte Items, nicht als Reparaturvertrag für manipulierte interne Tabellen. Keine automatische Secretredaktion; Reason, Fehlertexte und Runtimebefunde privat halten. Keine Installations- oder Rechteattestation.
