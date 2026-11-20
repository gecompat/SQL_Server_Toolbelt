---
name: "toolbelt-toolbelt-toolbelt-core-usp-setworkerintervals"
description: "Ändert Intervalldefaults ausschließlich für künftig registrierte Generationen."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_SetWorkerIntervals"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@HeartbeatSeconds", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Fachlich erforderliche Ganzzahl 1..3600 Sekunden. NULL ist ungültig; der technische NULL-Default bedeutet nicht den ursprünglichen Konfigurationswert 15. Wirkt als Registrierungsdefault nur für künftig erzeugte Generationen."}, {"name": "@UnreachableSeconds", "sql_type": "int", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Fachlich erforderliche Ganzzahl 3..86400 Sekunden und mindestens 3*HeartbeatSeconds. NULL ist ungültig, nicht der ursprüngliche Konfigurationswert 60. Bestehende Generationen behalten die bei Registrierung kopierten Intervalle."}, {"name": "@ExpectedConfigVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": true, "description": "Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_SetWorkerIntervals.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_SetWorkerIntervals

## Zweck und Einsatzfälle

Ändert Intervalldefaults ausschließlich für künftig registrierte Generationen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@HeartbeatSeconds` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 1..3600 Sekunden. NULL ist ungültig; der technische NULL-Default bedeutet nicht den ursprünglichen Konfigurationswert 15. Wirkt als Registrierungsdefault nur für künftig erzeugte Generationen. |
| `@UnreachableSeconds` | `int` | `NULL` | Input | Fachlich erforderliche Ganzzahl 3..86400 Sekunden und mindestens 3*HeartbeatSeconds. NULL ist ungültig, nicht der ursprüngliche Konfigurationswert 60. Bestehende Generationen behalten die bei Registrierung kopierten Intervalle. |
| `@ExpectedConfigVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche exakte binary(8)-ConfigVersion der globalen WorkerControlConfiguration, aus einer aktuellen Konfigurationsausgabe/RegisterWorker übernehmen. Als Bytes/0x-Literal, kein Zahlentext. NULL (technischer Help-Default) oder veralteter Wert wird abgewiesen; keine optionale ausgeschaltete Konkurrenzprüfung. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

ConfigVersion gemäß stabilem Ergebnisvertrag.

HeartbeatSeconds gemäß stabilem Ergebnisvertrag.

UnreachableSeconds gemäß stabilem Ergebnisvertrag.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_SetWorkerIntervals @Hilfe=1;
```

## Rechte

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aussagegrenzen

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerIntervals.md`

Keine Installations-, Definitions- oder Rechteattestation.
