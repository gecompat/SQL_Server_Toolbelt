---
name: "toolbelt-toolbelt-toolbelt-core-svf-iscancellationrequested"
description: "Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-cancel"
schema_name: "toolbelt_core"
object_name: "SVF_IsCancellationRequested"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Gesuchte ID, ohne Default und ohne Kontextfallback. Rückgabe 1 bei vorhandener Anforderung, sonst 0, ausdrücklich auch bei NULL."}]
source_paths: ["Modules/toolbelt.core.execution-cancel/Source/SVF_IsCancellationRequested.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# SVF_IsCancellationRequested

## Zweck und Einsatzfälle

Prüft, ob für eine Ausführung ein kooperativer Abbruch angefordert wurde.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Gesuchte ID, ohne Default und ohne Kontextfallback. Rückgabe 1 bei vorhandener Anforderung, sonst 0, ausdrücklich auch bei NULL. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT toolbelt_core.SVF_IsCancellationRequested(NULL) AS ResultValue;
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
- `Modules/toolbelt.core.execution-cancel/Documentation/SVF_IsCancellationRequested.md`

Keine Installations-, Definitions- oder Rechteattestation.
