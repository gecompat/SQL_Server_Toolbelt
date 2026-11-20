---
name: "toolbelt-toolbelt-toolbelt-core-tvf-executioncancellationstatus"
description: "Liest den registrierten kooperativen Abbruchstatus einer Ausführung."
skill_format_version: "1.0"
module_id: "toolbelt.core.execution-cancel"
schema_name: "toolbelt_core"
object_name: "TVF_ExecutionCancellationStatus"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@ExecutionId", "sql_type": "uniqueidentifier", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Gesuchte ID, ohne Default und ohne Fallback auf den aktuellen Kontext. Bei NULL oder fehlender Anforderung keine Zeile; bei vorhandener Anforderung genau eine nicht sensible Statuszeile."}]
source_paths: ["Modules/toolbelt.core.execution-cancel/Source/TVF_ExecutionCancellationStatus.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_ExecutionCancellationStatus

## Zweck und Einsatzfälle

Liest den registrierten kooperativen Abbruchstatus einer Ausführung.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@ExecutionId` | `uniqueidentifier` | `kein Default` | Input | SQL-uniqueidentifier, z.B. CAST('00000000-0000-0000-0000-000000000001' AS uniqueidentifier), keine frei formatierte Zeichenfolge. Gesuchte ID, ohne Default und ohne Fallback auf den aktuellen Kontext. Bei NULL oder fehlender Anforderung keine Zeile; bei vorhandener Anforderung genau eine nicht sensible Statuszeile. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_core.TVF_ExecutionCancellationStatus(NULL);
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
- `Modules/toolbelt.core.execution-cancel/Documentation/TVF_ExecutionCancellationStatus.md`

Keine Installations-, Definitions- oder Rechteattestation.
