---
name: "toolbelt-toolbelt-toolbelt-string-svf-regexinstr"
description: "Liefert eine UTF-16-Position eines ausgewählten Regex-Treffers."
skill_format_version: "1.0"
module_id: "toolbelt.string.regex"
schema_name: "toolbelt_string"
object_name: "SVF_RegexInstr"
object_type: "CLR_SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum 1048576 UTF-16-Einheiten (2097152 Bytes)."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \\d/\\w/\\s, Unicode-Kategorie nur \\p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Bytes, also 4000 Einheiten."}, {"name": "@Start", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. Ein Beginn nach Länge+1 liefert 0 vor Pattern-/Flagprüfung."}, {"name": "@Occurrence", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..2147483647, Default 1: n-ter Treffer ab Start; 0/negativ/NULL ungültig."}, {"name": "@ReturnOption", "sql_type": "int", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ: 0 = 1-basierter Trefferbeginn (Default); 1 = 1-basierte exklusive Endposition. NULL/andere int-Werte ungültig. Kein Treffer ergibt 0."}, {"name": "@Flags", "sql_type": "nvarchar(4)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung."}]
source_paths: ["Modules/toolbelt.string.regex/Source/RegexFunctions.sql"]
review_status: "draft"
source_module_version: "1.3.0"
---

# SVF_RegexInstr

## Zweck und Einsatzfälle

Liefert eine UTF-16-Position eines ausgewählten Regex-Treffers.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum 1048576 UTF-16-Einheiten (2097152 Bytes). |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Bytes, also 4000 Einheiten. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. Ein Beginn nach Länge+1 liefert 0 vor Pattern-/Flagprüfung. |
| `@Occurrence` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: n-ter Treffer ab Start; 0/negativ/NULL ungültig. |
| `@ReturnOption` | `int` | `0` | Input | Taxativ: 0 = 1-basierter Trefferbeginn (Default); 1 = 1-basierte exklusive Endposition. NULL/andere int-Werte ungültig. Kein Treffer ergibt 0. |
| `@Flags` | `nvarchar(4)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT toolbelt_string.SVF_RegexInstr(N'abc123 def456', N'[0-9]+', 1, 1, 0, N'c') AS ResultValue;
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
- `Modules/toolbelt.string.regex/Documentation/SVF_RegexInstr.md`

Keine Installations-, Definitions- oder Rechteattestation.
