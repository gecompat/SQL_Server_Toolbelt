---
name: "toolbelt-toolbelt-toolbelt-core-usp-deleterecordedeventsbefore"
description: "Nur ausdrücklich aufgerufene Retention nach RecordedAtUtc mit Index (RecordedAtUtc,EventId), deterministischen begrenzten Batches und bestehender Caller-Transaktions-/Savepointsemantik. Kein Job, keine Deploymentlöschung. Die OccurredAtUtc-Retention bleibt unverändert. Erfordert vorhandenes EXECUTE; erteilt keine Berechtigungen. Fehler 51710–51714 wie im bestehenden Retentionvertrag."
skill_format_version: "1.0"
module_id: "toolbelt.core.event-log"
schema_name: "toolbelt_core"
object_name: "USP_DeleteRecordedEventsBefore"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@BeforeRecordedAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich RecordedAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung."}, {"name": "@BatchSize", "sql_type": "int", "sql_default": "1000", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen."}, {"name": "@MaxBatches", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt."}, {"name": "@DeletedRows", "sql_type": "bigint", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults."}]
source_paths: ["Modules/toolbelt.core.event-log/Source/USP_DeleteRecordedEventsBefore.sql", "Modules/toolbelt.core.event-log/Source/EventLog.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_DeleteRecordedEventsBefore

## Zweck und Einsatzfälle

Explizite begrenzte Retention ausschließlich nach RecordedAtUtc < @BeforeRecordedAtUtc. Gleichheit bleibt erhalten. Serverseitige Aufzeichnungszeit; kein Ersatz durch fachlichen Ereigniszeitpunkt.

## Voraussetzungen

Installiertes EventLog, SQL Server 2019/2022/2025 Windows/Linux mit passenden CL150/160/170, lokal oder zentral. Gültiger datetime2(7)-Cutoff als UTC-Konvention ohne automatische Zeitzonenkonvertierung. Kein Second-Session-Provider für Retention erforderlich. Fehlender Cutoff wird im Fachpfad abgewiesen. Committable Callertransaktion erlaubt, uncommittable nicht.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Richtung | Vertrag |
|---|---|---|---|---|
| `@BeforeRecordedAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich RecordedAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | INPUT/OUTPUT | bigint OUTPUT, Eingabewert wird auch bei Hilfe auf 0 gesetzt. Nach Erfolg Zahl der Löschungen dieses Aufrufs. Bei Fehler sind eventuell bereits gezählte, anschließend zurückgerollte Batches kein Beweis persistenter Löschung; nur erfolgreichen Aufruf als Ergebnis auswerten. Zum Empfang Callervariable mit OUTPUT übergeben; kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | 1: bestehende zwölfspaltige Standardhilfe plus genau eine vollständige Skillzeile vor dem Fachpfad; 0 oder NULL: Fachaufruf. Alle Parameter besitzen technische Defaults. |

## Ergebnisse

Kein fachliches SELECT-Resultset. RETURN 0 bei Erfolg. @DeletedRows bigint OUTPUT enthält die Summe tatsächlich gelöschter Zeilen des erfolgreichen Aufrufs; bei Hilfe 0. Ein OUTPUT-Wert nach Fehler beweist keine committed Löschung. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Standardhilfe und dann genau eine zusätzliche Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max). Anschließend RETURN 0 vor Fachvalidierung, Katalog-/Tabellenzugriff und Schreib-/Lösch-/Transportoperationen. SQL-Typbindung und die vor dem Hilfezweig ausdrücklich beschriebenen lokalen Initialisierungen bleiben wirksam.

## Aufrufbeispiele

```sql
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @BeforeRecordedAtUtc='2000-01-01T00:00:00',@BatchSize=100,@MaxBatches=1,@DeletedRows=@Deleted OUTPUT;
SELECT @Deleted AS DeletedRows;
-- Nur im autorisierten synthetischen Scope; persistente Löschung.
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser administrativen Retention-USP und funktionierende bestehende Ownership-/Objektrechte auf EventLog. Keine Empfehlung einer pauschalen DELETE-Berechtigung für Lesekonsumenten. Zentraler Aufruf benötigt gültige Ziel-DB-Identität/Mapping und Rechte; die Prozedur erteilt sie nicht. Kein Serverstatusrecht, kein direkter Zugriff auf Second-Session-Transport nötig.

## Ressourcenbedarf

BatchSize 1..10000, MaxBatches 1..100: höchstens 1000000 Löschungen je Aufruf. NULL-BatchSize=1000, NULL-MaxBatches=1. Schleife stoppt zusätzlich beim ersten Batch mit 0 Treffern; kein Hintergrundjob oder automatisches Fortsetzen. Deterministische Auswahl je Batch ORDER BY RecordedAtUtc,EventId mit vorhandenem Index (RecordedAtUtc,EventId). Alle Batches gehören zu EINER Transaktion; Log/Sperren können trotz kleiner Batches bis zum gesamten Commit bzw. Callercommit bestehen. Keine READPAST-/NOLOCK- oder stabile Gesamtsnapshotgarantie, keine feste CPU-/Heap-/Latenzquote.

## Nebenwirkungen

SET NOCOUNT ON, SET XACT_ABORT OFF; BatchSize/MaxBatches/Debug/Hilfe normalisiert und @DeletedRows=0 bereits vor Hilfe. Ohne Callertransaktion eigener BEGIN/COMMIT um die gesamte Schleife, sonst fester SAVEPOINT TBX_EventLog_RecordedRetention. Fehler: eigener Scope Rollback, bestehender Caller nur bei XACT_STATE()=1 zum Savepoint; niemals vollständiger Callercommit/-rollback. Ein späterer Callerrollback kann erfolgreiche Retention zurücknehmen. BEGIN/SAVE steht vor TRY, etwa fehlende Distributed-Savepoint-Unterstützung bleibt Enginefehler. Rollbackfehler werden nicht separat abgefangen. Debug 1..255: erst nach Erfolg Severity-10-NOWAIT-Meldung mit Löschzahl, ohne Eventdaten; 0/NULL ohne Diagnose. Keine automatische Planung, kein Purge bei Installation.

## Fehlerbehandlung

51710 fehlender Cutoff, 51711 ungültige BatchSize, 51712 ungültige MaxBatches, 51713 XACT_STATE=-1, in dieser Priorität. Hilfe kehrt davor zurück. Die gelegentlich dokumentierte Bereichsobergrenze 51714 bedeutet keinen implementierten eigenen THROW 51714 in dieser Prozedur. Unerwartete Engine-/Berechtigungs-/Sperr-/Rollbackfehler bleiben sichtbar.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Skill-/Installer-/Minimalrechte-/Transportabnahme. Historische Belege bleiben an ihre ursprünglichen Bytes und ihren Scope gebunden. Kontext-, Actor-, Tenant- und Quellnamen sind callerbeeinflussbare Auditmetadaten, keine Authentifizierung oder Tenant-Isolation. Keine Installations- oder Rechteattestation; Beispiele ausschließlich in einem autorisierten synthetischen Scope ausführen.
