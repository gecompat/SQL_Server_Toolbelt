---
name: "toolbelt-toolbelt-toolbelt-core-usp-claimwork"
description: "Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen."
skill_format_version: "1.0"
module_id: "toolbelt.core.work-queue"
schema_name: "toolbelt_core"
object_name: "USP_ClaimWork"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@LeaseDurationSeconds", "sql_type": "int", "sql_default": "300", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.work-queue/Source/USP_ClaimWork.sql"]
review_status: "draft"
source_module_version: "2.1.0"
---

# USP_ClaimWork

## Zweck und Einsatzfälle

Beansprucht atomar höchstens das älteste beanspruchbare Work Item und eröffnet eine zeitlich begrenzte Lease. Abgelaufene Claims werden nicht implizit übernommen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Registrierter ausführbarer Handler bzw. eigener Work Item/Claim erforderlich. Beispiele mit IDs/Tokens sind Vorlagen; echte eigene Werte aus dem vorherigen Aufruf verwenden. Queue-/Katalogaufrufe können persistenten Zustand ändern.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@LeaseDurationSeconds` | `int` | `300` | Input | Ganzzahl 5..86400 Sekunden einschließlich, Default 300; explizites NULL wird abgewiesen, nicht auf den Default ersetzt. Dauer wird am Claim gespeichert und bei Heartbeats weiterverwendet; keine Callertransaktion erlaubt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Eindeutige Queue-ID.

Kanonischer Work-Type-Name.

Optionale bereinigte JSON-Payload.

Geheimes Ownership-Token für Heartbeat, Complete oder Fail.

UTC-Zeitpunkt des Claims.

Monotoner Ownership-Zähler dieses Work Items.

Exklusive UTC-Grenze der Lease.

Beim Claim identisch mit ClaimedAtUtc.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Caller-Transaktions-, Lease- oder ResultTable-Fehler.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.work-queue/Documentation/USP_ClaimWork.md`

Keine Installations-, Definitions- oder Rechteattestation.
