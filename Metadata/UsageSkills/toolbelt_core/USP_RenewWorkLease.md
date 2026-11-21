---
name: "toolbelt-core-usp-renewworklease"
description: "Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_RenewWorkLease"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkItemId", "sql_type": "bigint", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig."}, {"name": "@ClaimToken", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_RenewWorkLease.sql", "Modules/toolbelt.core.work-queue/Source/WorkItem.sql", "Modules/toolbelt.core.work-queue/Source/VW_WorkQueue.sql", "Modules/toolbelt.core.work-type/Source/WorkType.sql", "Modules/toolbelt.core.result-table/Source/USP_PrepareResultTable.sql"]
review_status: "verified"
source_module_version: "2.1.0"
---

# USP_RenewWorkLease

## Zweck und Einsatzfälle

Verlängert eine noch aktive Lease mit passendem ClaimToken um ihre beim Claim festgelegte Dauer ab Engine-Zeit. Eine abgelaufene Lease wird nicht wiederbelebt.

## Voraussetzungen

Queue 2.1.0 mit WorkType-/ResultTableabhängigkeiten derselben Datenbank. SQL2019/2022/2025 auf Windows/Linux mit zulässigem CL150/160/170 gemäß Modulmatrix. Keine Callertransaktion. Nur eigene aktuelle Claim-ID/Token verwenden; die Lease muss noch aktiv sein. Clientzeiten verlängern keine Enginelease. Alle Argumente haben technische Defaults für Hilfe; erforderliche NULL-Fachwerte bleiben ungültig. SQL-Typbindung und Breitenkonvertierung liegen vor dem Code.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@WorkItemId` | `bigint` | `NULL` | Input | Positive bigint-ID eines tatsächlich vorhandenen Queue-Items, aus Enqueue/Status/Claim übernehmen; keine frei erfundene Beispiel-ID als gültigen Claim verwenden. Technischer Default NULL dient nur Hilfe; NULL/<=0 ist im Fachaufruf ungültig. |
| `@ClaimToken` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Geheimes Ownership-Token genau des aktuellen aktiven Claims dieses WorkItemId, unverändert aus Claim übernehmen; NULL/abweichendes Token oder abgelaufene Lease wird abgewiesen. Nie in Logs/öffentlichen Beispielen reale Tokens speichern. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bisherige Standardhilfe plus genau eine vollständige Skillzeile, danach RETURN0 vor Fachprüfungen, Tabellenzugriff oder Mutation. 0 oder NULL: Fachpfad. Alle Argumente haben technische Defaults; erforderliche fachliche NULL-Defaults sind keine gültigen Ersatzwerte. |

## Ergebnisse

| Spalte | SQL-Typ | Vertrag |
|---|---|---|
| `WorkItemId` | `bigint` | NOT NULL |
| `ClaimGeneration` | `bigint` | NOT NULL |
| `LeaseUntilUtc` | `datetime2(7)` | NOT NULL |
| `LastHeartbeatAtUtc` | `datetime2(7)` | NOT NULL |

Eine Zeile bei erfolgreichem Übergang. Vier exakte UPDATE-OUTPUT-Spalten. ResultTable=NULL liefert den direkten Fachresultset; sonst Routing in das lokale Callerziel über PrepareResultTable ohne zusätzlichen Fach-SELECT. Keine Payload, ClaimToken oder privaten Managedtokens in der Ausgabe. Hilfe liefert die bisherige zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile: SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). RETURN0 vor Fachzugriff; normaler Return ebenfalls 0, bei Requeue implizit.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;

-- Eigene aktive Claim-ID/Token einsetzen, keine fremden Bindings.
DECLARE @Token uniqueidentifier='00000000-0000-0000-0000-000000000001';
EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=1,@ClaimToken=@Token;
```

## Rechte

Vorhandenes EXECUTE auf den öffentlichen Einstieg, passender Datenbankzugriff und Identitätsmapping für zentrale Dreiteilnamen. Keine Rechtevergabe aus dem Skill ableiten. Basiszugriff folgt tatsächlichen Ownership-Chains/Objektrechten. Kein eigener WorkType-ENQUEUE-/CLAIM-/Handler-EXECUTEguard; die Berechtigung für diesen Supervisor-, Completion- oder Heartbeatweg gezielt vergeben. ClaimToken ist eine zusätzliche Bindung; ManagedCompletion ist wie oben beschrieben geschützt. ResultTable braucht ein vorhandenes zulässiges lokales #Ziel und Helper-/Temp-DDL-/INSERT-Rechte; keine pauschale Serverrolle.

## Ressourcenbedarf

Private Ergebnistabellen in tempdb, Item-/Scheduler-/Indexlocks, Log-/Speicherbedarf und Sperrkonkurrenz. Recovery mit READPAST kann gesperrte Items überspringen. MaxItems ist keine CPU-, Heap-, Log- oder Gesamtlaufzeitquote. Barrierrequeue erzeugt Blockersnapshots nach Gruppenbreite. Kein eigener Timeout-/Retryloop oder Host-/VM-Eingriff. Zählerüberläufe bleiben Enginefehler.

## Nebenwirkungen

NOCOUNT ON und XACT_ABORT OFF; KeepData/Debug/Hilfe werden bei NULL zu 0. Nach früher Hilfe werden Caller-TX und ID/Token geprüft. Eigene Transaktion, WorkItem mit UPDLOCK/HOLDLOCK lesen. Das Item muss existieren, CLAIMED sein und das passende Token besitzen. EngineUTC wird nach dem Lock erfasst; die Lease muss noch strikt in der Zukunft liegen.

Optionales ResultTable vorbereiten. UPDATE setzt LastHeartbeatAtUtc auf EngineUTC und LeaseUntilUtc auf EngineUTC plus gespeicherte LeaseDurationSeconds. Dauer, ClaimGeneration, Token und Status bleiben unverändert. Genau eine UPDATE-OUTPUT-Zeile ist erforderlich. Routing und UPDATE gehören zur eigenen Transaktion; COMMIT, im CATCH eigener ROLLBACK. Debug>0 liefert anschließend eine abstrakte Severity10-NOWAIT-Message; direkte Ausgabe nur ohne ResultTable. Kein eigener ManagedHold-/ManagedReservation-/WorkType-Policyguard, keine Slot- oder Handler-Lebenszeichenprüfung. Ein aktuelles Token ersetzt keine Autorisierung für diesen Aufruf.

## Fehlerbehandlung

51950: Caller-TX/XACT_STATE nicht 0. 51951: ID NULL/nicht positiv oder Token NULL. 51952/1: Item fehlt; /2: Status/Token passt nicht; /3: nicht genau ein UPDATE. 51953: Lease abgelaufen. 51954: ResultTablehelper fehlt. Ursprüngliche Engine-, Constraint-, Konvertierungs-, Helper-, Sperr-, Deadlock- und Rollbackfehler bleiben sichtbar. Keine automatische Wiederholung. Spätere Message-/Ergebnistransportfehler können einen eigenen bereits ausgeführten Commit nicht zurücknehmen.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag; keine neue native Hilfe-/Unicode-/Callerzustands-/Minimalrechte-/Installer-/Konkurrenz-/Lease-/Recoveryabnahme. Historische Nachweise behalten ihre Artefaktbindung. Kein Exactly-once, Prozess-KILL oder Nachweis für Hostausfall/Koordinatorverlust. Die Claim-/Leasevoraussetzungen gelten für über öffentliche APIs wohlgeformte Items, nicht als Reparaturvertrag für manipulierte interne Tabellen. Keine automatische Secretredaktion; Reason, Fehlertexte und Runtimebefunde privat halten. Keine Installations- oder Rechteattestation.
