---
name: "toolbelt-toolbelt-toolbelt-core-usp-enqueueworkwithpolicy"
description: "Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_EnqueueWorkWithPolicy"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkTypeName", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein."}, {"name": "@PayloadJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{\"value\":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder."}, {"name": "@IdempotencyKey", "sql_type": "varchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung."}, {"name": "@Priority", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 0..255 als tinyint, Default 0; höhere Werte werden bevorzugt. Explizites NULL ist unzulässig. Keine Zusage einer global strikt seriellen FIFO-Reihenfolge unter Konkurrenz."}, {"name": "@ExecutionGroup", "sql_type": "varchar(128)", "sql_default": "'default'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Default ist der konkrete Name default."}, {"name": "@MaxAttempts", "sql_type": "tinyint", "sql_default": "3", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen."}, {"name": "@RetryBaseDelaySeconds", "sql_type": "int", "sql_default": "60", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss <= RetryMaxDelaySeconds sein."}, {"name": "@RetryMaxDelaySeconds", "sql_type": "int", "sql_default": "3600", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung."}, {"name": "@ExecutionMode", "sql_type": "varchar(16)", "sql_default": "'SHARED'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Taxativ in kanonischer Schreibweise: SHARED = normale Queuearbeit (Default); DRAIN_BARRIER = gruppengebundene Barrierarbeit mit Blocker-Snapshot und zusätzlichen Schedulerregeln. DRAIN_BARRIER verlangt @@TRANCOUNT=0. Kein automatisches UPPER; NULL/leer/andere Modi unzulässig."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_EnqueueWorkWithPolicy.sql"]
review_status: "draft"
source_module_version: "2.1.0"
---

# USP_EnqueueWorkWithPolicy

## Zweck und Einsatzfälle

Reiht je nach ExecutionMode SHARED- oder DRAIN_BARRIER-Arbeit mit unveränderlicher Retry-Policy und optionalem Idempotency Key ein.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkTypeName` | `varchar(128)` | `NULL` | Input | Kanonischer registrierter WorkTypeName als varchar(128), kein SQL-Text oder Handler-Aufruf. Verfügbare Namen über toolbelt_core.VW_WorkTypes ermitteln; der Eintrag muss für diese Operation freigegeben sein. NULL/leer ist im Fachaufruf ungültig. Muss aktiviert und für ENQUEUE autorisiert sein. |
| `@PayloadJson` | `nvarchar(max)` | `NULL` | Input | Bei Work-Type-ParameterMode NONE ausschließlich NULL (Default); bei JSON_PAYLOAD erforderlicher JSON-Objekttext gemäß konkretem Handlervertrag, z.B. N'{"value":1}'. Höchstens 65536 UTF-16-Bytes (64 KiB); kein Array/Scalarroot. Nach LTRIM normaler Spaces muss { folgen, daher keine führenden Tabs/CR/LF. Leer/ungültig wird abgewiesen; keine allgemeine automatische Prüfung der deklarativen PayloadContractJson-Felder. |
| `@IdempotencyKey` | `varchar(128)` | `NULL` | Input | Optionaler varchar(128)-Schlüssel innerhalb genau eines Work Types; NULL (Default) deaktiviert Idempotency-Key-Wiederverwendung. Leerer Text ist ein expliziter Schlüssel, kein NULL-Ersatz. Vergleich gemäß binärer SQL-Collation, kein Normalisieren. Solange das Item besteht, liefert dieselbe Payload-/Policykonfiguration das bestehende Item; abweichende Konfiguration wird abgewiesen. Kein Beweis einer Exactly-once-Handlerwirkung. |
| `@Priority` | `tinyint` | `0` | Input | Ganzzahl 0..255 als tinyint, Default 0; höhere Werte werden bevorzugt. Explizites NULL ist unzulässig. Keine Zusage einer global strikt seriellen FIFO-Reihenfolge unter Konkurrenz. |
| `@ExecutionGroup` | `varchar(128)` | `'default'` | Input | Nichtleerer varchar(128)-Gruppenname, binär/case-sensitiv gemäß SQL-Namensvergleich; keine feste Werteliste und keine separate Gruppenregistrierung. NULL/leer/reine Spaces ungültig; keine automatische Normalisierung. Die Gruppe bestimmt den Geltungsbereich der Barriers. Default ist der konkrete Name default. |
| `@MaxAttempts` | `tinyint` | `3` | Input | Ganzzahl 1..10 Versuche pro Retryzyklus einschließlich, Default 3; explizites NULL ist kein Default und unzulässig. Die Policy wird am Item gespeichert und später nicht aus einer geänderten Konfiguration nachgelesen. |
| `@RetryBaseDelaySeconds` | `int` | `60` | Input | Ganzzahl 1..86400 Sekunden einschließlich, Default 60; NULL/0/negativ/zu groß unzulässig. Basis des exponentiellen Retry-Backoffs; muss &lt;= RetryMaxDelaySeconds sein. |
| `@RetryMaxDelaySeconds` | `int` | `3600` | Input | Ganzzahl von RetryBaseDelaySeconds bis 86400 Sekunden einschließlich, Default 3600; NULL oder kleiner als Basis unzulässig. Begrenzt den exponentiellen Backoff; keine Zufallsstreuung. |
| `@ExecutionMode` | `varchar(16)` | `'SHARED'` | Input | Taxativ in kanonischer Schreibweise: SHARED = normale Queuearbeit (Default); DRAIN_BARRIER = gruppengebundene Barrierarbeit mit Blocker-Snapshot und zusätzlichen Schedulerregeln. DRAIN_BARRIER verlangt @@TRANCOUNT=0. Kein automatisches UPPER; NULL/leer/andere Modi unzulässig. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255, Default 0; NULL wie 0 beim Helper. Nur bei nicht-NULL ResultTable an den kanonischen Vorbereitungshelper übergeben: 1..255 kann dessen Diagnose erzeugen. Ohne ResultTable erzeugt dieser Pfad keine zusätzlichen eigenen Debug-Messages. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

1 bei neu angelegter Arbeit, 0 bei idempotenter Wiederverwendung.

## Aufrufbeispiele

```sql
-- Voraussetzung: aktiver, ausführbarer Work Type demo.noop.
EXEC toolbelt_core.USP_EnqueueWorkWithPolicy
 @WorkTypeName='demo.noop', @PayloadJson=NULL, @IdempotencyKey=N'example-1',
 @Priority=10, @ExecutionGroup=N'example-group', @MaxAttempts=3,
 @RetryBaseDelaySeconds=60, @RetryMaxDelaySeconds=3600, @ExecutionMode='SHARED';
```

## Rechte

EXECUTE und explizite ENQUEUE-Autorisierung für den registrierten Work Type; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Fehlende ResultTable-Dependency, ungültige Policy oder Payload, inaktiver Work Type oder fehlende ENQUEUE-Autorisierung.

## Aussagegrenzen

Payload höchstens 64 KiB. Ein Barrier-Aufruf benötigt @@TRANCOUNT=0.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.work-queue/Documentation/USP_EnqueueWorkWithPolicy.md`

Keine Installations-, Definitions- oder Rechteattestation.
