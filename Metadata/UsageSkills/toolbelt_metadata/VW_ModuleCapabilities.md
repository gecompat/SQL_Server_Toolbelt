---
name: "toolbelt-toolbelt-toolbelt-metadata-vw-modulecapabilities"
description: "Zeigt sichtbare bekannte Modulschnittstellenkandidaten; Version und Deployment-Modus bleiben NULL, MetadataStatus bleibt incomplete."
skill_format_version: "1.0"
module_id: "toolbelt.metadata.capability-catalog"
schema_name: "toolbelt_metadata"
object_name: "VW_ModuleCapabilities"
object_type: "VW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.metadata.capability-catalog/Source/VW_ModuleCapabilities.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# VW_ModuleCapabilities

## Zweck und Einsatzfälle

Zeigt sichtbare bekannte Modulschnittstellenkandidaten; Version und Deployment-Modus bleiben NULL, MetadataStatus bleibt incomplete.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

Keine SQL-Aufrufparameter laut aktueller Source-Deklaration.

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;
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
- `Modules/toolbelt.metadata.capability-catalog/Documentation/VW_ModuleCapabilities.md`

Keine Installations-, Definitions- oder Rechteattestation.
