---
name: "toolbelt-toolbelt-toolbelt-core-vw-workerstatus"
description: "Öffentliche technische Statussicht; explizite Spalten, keine Tokens oder Payloads."
skill_format_version: "1.0"
module_id: "toolbelt.core.worker-control"
schema_name: "toolbelt_core"
object_name: "VW_WorkerStatus"
object_type: "VIEW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.core.worker-control/Source/VW_WorkerStatus.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# VW_WorkerStatus

## Zweck und Einsatzfälle

Öffentliche technische Statussicht; explizite Spalten, keine Tokens oder Payloads.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

- Worker-Control 1.0 ist vorhanden; bestehendes SELECT-Recht auf die Sicht.

## Parameter und Zugriff

Keine SQL-Aufrufparameter laut aktueller Source-Deklaration.

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_WorkerStatus;
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
- `Modules/toolbelt.core.worker-control/Documentation/VW_WorkerStatus.md`

Keine Installations-, Definitions- oder Rechteattestation.
