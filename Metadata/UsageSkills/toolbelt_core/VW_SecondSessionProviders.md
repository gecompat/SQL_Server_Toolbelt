---
name: "toolbelt-toolbelt-toolbelt-core-vw-secondsessionproviders"
description: "Zeigt konfigurierte Second-Session-Provider."
skill_format_version: "1.0"
module_id: "toolbelt.core.second-session"
schema_name: "toolbelt_core"
object_name: "VW_SecondSessionProviders"
object_type: "VIEW"
database_role: "toolbelt"
is_internal: false
parameters: []
source_paths: ["Modules/toolbelt.core.second-session/Source/VW_SecondSessionProviders.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# VW_SecondSessionProviders

## Zweck und Einsatzfälle

Zeigt konfigurierte Second-Session-Provider.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

Keine SQL-Aufrufparameter laut aktueller Source-Deklaration.

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT TOP (20) * FROM toolbelt_core.VW_SecondSessionProviders;
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
- `Modules/toolbelt.core.second-session/Documentation/VW_SecondSessionProviders.md`

Keine Installations-, Definitions- oder Rechteattestation.
