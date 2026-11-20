---
name: "toolbelt-toolbelt-toolbelt-string-tvf-trimdirectionalnvarchar"
description: "Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem Unicode-Text."
skill_format_version: "1.0"
module_id: "toolbelt.string.directional-trim"
schema_name: "toolbelt_string"
object_name: "TVF_TrimDirectionalNvarchar"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Unicode-Text als nvarchar(max); Positionen zählen UTF-16-Codeeinheiten. Leer bleibt leer; NULL ergibt NULL. NUL wird nicht entfernt; Zeichenvergleiche verwenden die Installationscollation."}, {"name": "@Characters", "sql_type": "nvarchar(4000)", "sql_default": "N' '", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Bis 4000 UTF-16-Codeeinheiten als nvarchar(4000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt."}, {"name": "@Direction", "sql_type": "varchar(8)", "sql_default": "'BOTH'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang."}]
source_paths: ["Modules/toolbelt.string.directional-trim/Source/TVF_TrimDirectionalNvarchar.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_TrimDirectionalNvarchar

## Zweck und Einsatzfälle

Entfernt ausgewählte Zeichen links, rechts oder beidseitig aus einem Unicode-Text.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `nvarchar(max)` | `kein Default` | Input | Unicode-Text als nvarchar(max); Positionen zählen UTF-16-Codeeinheiten. Leer bleibt leer; NULL ergibt NULL. NUL wird nicht entfernt; Zeichenvergleiche verwenden die Installationscollation. |
| `@Characters` | `nvarchar(4000)` | `N' '` | Input | Bis 4000 UTF-16-Codeeinheiten als nvarchar(4000) als Menge einzelner zu entfernender Zeichen, kein Suchstring/Pattern. Default ist genau ein Space; leer entfernt nichts, NULL ergibt NULL. %, [ usw. sind literal; NUL wird nicht getrimmt. |
| `@Direction` | `varchar(8)` | `'BOTH'` | Input | Taxativ: LEADING entfernt Zeichen nur links; TRAILING nur rechts; BOTH an beiden Rändern (Default). UPPER normalisiert die Groß-/Kleinschreibung, Vergleich erfolgt nach SQL-Gleichheitsregeln einschließlich Space-Padding; kein Trim der führenden Spaces. Andere Werte und NULL erzeugen einen Enginefehler, außer NULL bei Value/Characters hat Vorrang. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_TrimDirectionalNvarchar(N'  Contoso-123  ', N' ', 'BOTH');
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
- `Modules/toolbelt.string.directional-trim/Documentation/TVF_TrimDirectionalNvarchar.md`

Keine Installations-, Definitions- oder Rechteattestation.
