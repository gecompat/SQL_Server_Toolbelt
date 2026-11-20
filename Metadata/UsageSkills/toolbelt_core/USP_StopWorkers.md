---
name: "toolbelt-toolbelt-toolbelt-core-usp-stopworkers"
description: "Pausiert stabile ausgewählte Workeridentitäten und persistiert atomaren Stop/Hold ihrer eingefrorenen exakten Generationen."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_StopWorkers"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@WorkersTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderlicher sysname einer vorhandenen caller-lokalen #Temp-Tabelle, keine ##Temp/persistente oder mehrteilige Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten: WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. 0..1000 eindeutige (WorkerId,WorkerGeneration)-Paare, Generation >0, jede exakte Generation muss existieren. Doppelpaare werden abgewiesen; leere Auswahl ist ein No-op. Die Auswahl wird vor Stop eingefroren, maximal 100000 Reservations; Beispiel CREATE TABLE #Workers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL)."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_StopWorkers.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_StopWorkers

## Zweck und Einsatzfälle

Pausiert stabile ausgewählte Workeridentitäten und persistiert atomaren Stop/Hold ihrer eingefrorenen exakten Generationen.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@WorkersTable` | `sysname` | `NULL` | Input | Fachlich erforderlicher sysname einer vorhandenen caller-lokalen #Temp-Tabelle, keine ##Temp/persistente oder mehrteilige Tabelle. Exakt zwei NOT-NULL-Basistyp-Spalten: WorkerId uniqueidentifier und WorkerGeneration bigint; keine Zusatzspalten oder Aliasdatentypen. 0..1000 eindeutige (WorkerId,WorkerGeneration)-Paare, Generation &gt;0, jede exakte Generation muss existieren. Doppelpaare werden abgewiesen; leere Auswahl ist ein No-op. Die Auswahl wird vor Stop eingefroren, maximal 100000 Reservations; Beispiel CREATE TABLE #Workers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL). |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

WorkerId gemäß Ergebnisvertrag.

WorkerGeneration gemäß Ergebnisvertrag.

SlotReservationId gemäß Ergebnisvertrag.

StopStatus gemäß Ergebnisvertrag.

HoldVersion gemäß Ergebnisvertrag.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_StopWorkers @Hilfe=1;
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
- `Modules/toolbelt.core.worker-control/Documentation/USP_StopWorkers.md`

Keine Installations-, Definitions- oder Rechteattestation.
