---
name: "toolbelt-toolbelt-toolbelt-string-tvf-splitadvanced"
description: "Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht."
skill_format_version: "1.0"
module_id: "toolbelt.string.split-advanced"
schema_name: "toolbelt_string"
object_name: "TVF_SplitAdvanced"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden."}, {"name": "@SeparatorsJson", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. [\"::\",\",\"]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig."}, {"name": "@Quote", "sql_type": "nvarchar(max)", "sql_default": "N'\"'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax."}, {"name": "@Escape", "sql_type": "nvarchar(max)", "sql_default": "N'\\'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt."}]
source_paths: ["Modules/toolbelt.string.split-advanced/Source/TVF_SplitAdvanced.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# TVF_SplitAdvanced

## Zweck und Einsatzfälle

Zerlegt Originaltokens mit mehreren Separatoren, Quotes und Escape-Regeln; entquotiert sie nicht.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. |
| `@SeparatorsJson` | `nvarchar(max)` | `kein Default` | Input | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_SplitAdvanced(N'a,b;;c', N'[",",";"]', N'"', N'\', 1);
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
- `Modules/toolbelt.string.split-advanced/Documentation/TVF_SplitAdvanced.md`

Keine Installations-, Definitions- oder Rechteattestation.
