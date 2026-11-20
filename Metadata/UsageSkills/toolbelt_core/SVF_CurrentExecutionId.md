---
name: "toolbelt-toolbelt-toolbelt-core-svf-currentexecutionid"
description: "Liest die Execution-ID der aktuellen Session."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-context"
schema_name: "toolbelt_core"
object_name: "SVF_CurrentExecutionId"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.core.execution-context/Source/SVF_CurrentExecutionId.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# SVF_CurrentExecutionId

## Zweck und Einsatzfälle

Liest die Execution-ID der aktuellen Session.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

Keine SQL-Aufrufparameter laut aktueller Source-Deklaration.

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ResultValue;
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
- `Modules/toolbelt.core.execution-context/Documentation/SVF_CurrentExecutionId.md`

Keine Installations-, Definitions- oder Rechteattestation.
