---
name: "toolbelt-toolbelt-toolbelt-core-usp-reconcileworkerexecution"
description: "Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "USP_ReconcileWorkerExecution"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SlotReservationId", "sql_type": "uniqueidentifier", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig."}, {"name": "@ExpectedHoldVersion", "sql_type": "binary(8)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. Der Code prüft Sessionfence und Commitwitness; fehlende Beweisbarkeit bleibt UNKNOWN und ist keine Freigabe zum Replay."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.core.worker-control/Source/USP_ReconcileWorkerExecution.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# USP_ReconcileWorkerExecution

## Zweck und Einsatzfälle

Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Worker-Control 1.0 und seine separat installierten Abhängigkeiten. Vorhandene EXECUTE-Rechte für die ausgewählte administrative oder Dispatch-Schnittstelle; keine automatische Rechtevergabe.
- Das Beispiel liest den Vertrag. Mutierende Aufrufe verlangen eigene aktuelle Konfigurations-/Holdversionen beziehungsweise registrierte IDs und Tokens. Native Qualifikation der aktiven Welle steht noch aus.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SlotReservationId` | `uniqueidentifier` | `NULL` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Fachlich erforderliche SlotReservationId eines tatsächlich reservierten Versuchs, unverändert aus ClaimWorkerWork/Status übernehmen. Keine frei gewählte UUID, SPID oder WorkItemId; NULL/fehlende Reservation ist ungültig. |
| `@ExpectedHoldVersion` | `binary(8)` | `NULL` | Input | Fachlich erforderliche binary(8)-HoldVersion genau der aktuellen WorkerExecutionDisposition dieses Versuchs, aus dessen Statusausgabe übernehmen. Kein ConfigVersion-/RowVersion-Ersatz einer anderen Zeile; NULL oder Drift wird abgewiesen. Der Code prüft Sessionfence und Commitwitness; fehlende Beweisbarkeit bleibt UNKNOWN und ist keine Freigabe zum Replay. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | Standardparameter tinyint 0..255 oder NULL, Default 0. Im aktuellen öffentlichen Worker-Control-Pfad entstehen dadurch keine zusätzlichen eigenen Diagnose-Messages; insbesondere werden keine Tokens ausgegeben. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

SlotReservationId gemäß Ergebnisvertrag.

Outcome gemäß Ergebnisvertrag.

Occupied gemäß Ergebnisvertrag.

## Aufrufbeispiele

```sql
EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;
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
- `Modules/toolbelt.core.worker-control/Documentation/USP_ReconcileWorkerExecution.md`

Keine Installations-, Definitions- oder Rechteattestation.
