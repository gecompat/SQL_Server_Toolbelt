---
name: "toolbelt-toolbelt-toolbelt-string-tvf-splitbycharacters"
description: "Zerlegt einen Text an jedem Zeichen der angegebenen Separatormenge."
skill_format_version: "1.0"
module_id: "toolbelt.string.split-characters"
schema_name: "toolbelt_string"
object_name: "TVF_SplitByCharacters"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung."}, {"name": "@Separators", "sql_type": "nvarchar(4000)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt."}]
source_paths: ["Modules/toolbelt.string.split-characters/Source/TVF_SplitByCharacters.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_SplitByCharacters

## Zweck und Einsatzfälle

Zerlegt einen Text an jedem Zeichen der angegebenen Separatormenge.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Bytes; leer ist gültig. NULL in Input oder Separators ergibt SQL_NULL im Statuskern und keine Zeilen in der Wertfassade. Höchstens 10000 Ausgabetokens, keine Teilveröffentlichung bei Überschreitung. |
| `@Separators` | `nvarchar(4000)` | `kein Default` | Input | Menge einzelner UTF-16-Einheiten als nvarchar(4000), z.B. N',;'; keine Separatorstrings/JSON-/Quote-Syntax. Höchstens 64 verschiedene Einheiten, Duplikate zählen einmal, NUL verboten. Leer bedeutet keine Trennung; NULL ergibt SQL_NULL/keine Zeilen. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_SplitByCharacters(N'a,b;;c', N',;', 1);
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
- `Modules/toolbelt.string.split-characters/Documentation/TVF_SplitByCharacters.md`

Keine Installations-, Definitions- oder Rechteattestation.
