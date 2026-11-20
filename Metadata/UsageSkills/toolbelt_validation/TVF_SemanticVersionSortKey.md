---
name: "toolbelt-toolbelt-toolbelt-validation-tvf-semanticversionsortkey"
description: "Erzeugt einen binären Sortierschlüssel für eine gültige SemVer-Version."
skill_format_version: "1.0"
module_id: "toolbelt.validation.semantic-version"
schema_name: "toolbelt_validation"
object_name: "TVF_SemanticVersionSortKey"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Version", "sql_type": "varchar(8000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht."}]
source_paths: ["Modules/toolbelt.validation.semantic-version/Source/TVF_SemanticVersionSortKey.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# TVF_SemanticVersionSortKey

## Zweck und Einsatzfälle

Erzeugt einen binären Sortierschlüssel für eine gültige SemVer-Version.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Version` | `varchar(8000)` | `kein Default` | Input | ASCII-SemVer-2.0.0-Text als varchar(8000): Major.Minor.Patch, optional -PreRelease und +BuildMetadata. Core-Zahlen und numerische Pre-release-Identifier ohne führende Nullen; Pre-release/Build als nichtleere punktgetrennte Identifier aus ASCII-Buchstaben, Ziffern und -. Keine Spaces, kein v-Präfix oder Normalisieren; ASCII-Case bleibt relevant. NULL/leer/ungültig ergibt beim Parser IsValid=0 mit Grund, bei Vergleich/Sortierung NULL; Build-Metadaten beeinflussen die Präzedenz nicht. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_validation.TVF_SemanticVersionSortKey(N'1.2.3-alpha.1+build.7');
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
- `Modules/toolbelt.validation.semantic-version/Documentation/TVF_SemanticVersionSortKey.md`

Keine Installations-, Definitions- oder Rechteattestation.
