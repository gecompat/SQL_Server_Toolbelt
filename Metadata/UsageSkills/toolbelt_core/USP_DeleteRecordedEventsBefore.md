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
parameters: [{"name": "@BeforeRecordedAtUtc", "sql_type": "datetime2(7)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich RecordedAtUtc < Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung."}, {"name": "@BatchSize", "sql_type": "int", "sql_default": "1000", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/>10000 wird abgewiesen."}, {"name": "@MaxBatches", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/>100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt."}, {"name": "@DeletedRows", "sql_type": "bigint", "sql_default": "NULL", "is_output": true, "argument_required": false, "business_required": false, "nullable": true, "description": "bigint OUTPUT: Der Eingabewert wird immer auf 0 gesetzt, auch im Hilfemodus; danach Anzahl der in diesem Aufruf gelöschten Zeilen. Zum Empfangen eine bigint-Variable mit OUTPUT übergeben; Eingabe-NULL ist kein Löschlimit."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.event-log/Source/USP_DeleteRecordedEventsBefore.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_DeleteRecordedEventsBefore

## Zweck und Einsatzfälle

Nur ausdrücklich aufgerufene Retention nach RecordedAtUtc mit Index (RecordedAtUtc,EventId), deterministischen begrenzten Batches und bestehender Caller-Transaktions-/Savepointsemantik. Kein Job, keine Deploymentlöschung. Die OccurredAtUtc-Retention bleibt unverändert. Erfordert vorhandenes EXECUTE; erteilt keine Berechtigungen. Fehler 51710–51714 wie im bestehenden Retentionvertrag.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Vorhandenes SELECT auf die TVF beziehungsweise EXECUTE auf die USP; keine automatische Rechtevergabe.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@BeforeRecordedAtUtc` | `datetime2(7)` | `NULL` | Input | Fachlich erforderlicher SQL-datetime2(7)-UTC-Cutoff, z.B. CONVERT(datetime2(7),'2026-10-30T00:00:00',126). Löscht ausschließlich RecordedAtUtc &lt; Cutoff, nicht gleich. NULL (technischer Default für Hilfe) wird im Fachaufruf abgewiesen; keine automatische Zeitzonenkonvertierung. |
| `@BatchSize` | `int` | `1000` | Input | Ganzzahlige Zahl 1..10000 Zeilen je Batch, inklusive. Default/NULL = 1000; 0/negativ/&gt;10000 wird abgewiesen. |
| `@MaxBatches` | `int` | `1` | Input | Ganzzahl 1..100 Batches je Aufruf, inklusive. Default/NULL = 1; 0/negativ/&gt;100 wird abgewiesen. Kein Hintergrundjob; Grenzen werden nicht automatisch über mehrere Aufrufe fortgesetzt. |
| `@DeletedRows` | `bigint` | `NULL` | OUTPUT | bigint OUTPUT: Der Eingabewert wird immer auf 0 gesetzt, auch im Hilfemodus; danach Anzahl der in diesem Aufruf gelöschten Zeilen. Zum Empfangen eine bigint-Variable mit OUTPUT übergeben; Eingabe-NULL ist kein Löschlimit. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Kein fachliches Resultset. Anzahl über @DeletedRows OUTPUT.

## Aufrufbeispiele

```sql
DECLARE @n bigint; EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @BeforeRecordedAtUtc='2026-01-01',@BatchSize=1000,@MaxBatches=1,@DeletedRows=@n OUTPUT;
```

## Rechte

Vorhandenes EXECUTE auf der USP; keine automatische Rechtevergabe.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Grenz-, Pflichtparameter- und Transaktionsfehler.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.event-log/Documentation/USP_DeleteRecordedEventsBefore.md`

Keine Installations-, Definitions- oder Rechteattestation.
