---
name: "toolbelt-toolbelt-toolbelt-string-tvf-regexsplit"
description: "Zerlegt einen Text an Regex-Treffern."
skill_format_version: "1.0"
module_id: "toolbelt.string.regex"
schema_name: "toolbelt_string"
object_name: "TVF_RegexSplit"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \\d/\\w/\\s, Unicode-Kategorie nur \\p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000."}, {"name": "@Flags", "sql_type": "nvarchar(max)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher."}, {"name": "@MaxRows", "sql_type": "int", "sql_default": "10000", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..100000, Default 10000; NULL/0/negativ/größer ungültig. Begrenzt die vollständig materialisierte Ausgabe; Überschreitung verwirft den gesamten Aufruf ohne gültiges Teilpräfix. Bei Split zählen auch leere Tokens."}]
source_paths: ["Modules/toolbelt.string.regex/Source/RegexRelations.sql"]
review_status: "draft"
source_module_version: "1.3.0"
---

# TVF_RegexSplit

## Zweck und Einsatzfälle

Zerlegt einen Text an Regex-Treffern.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |
| `@MaxRows` | `int` | `10000` | Input | Ganzzahl 1..100000, Default 10000; NULL/0/negativ/größer ungültig. Begrenzt die vollständig materialisierte Ausgabe; Überschreitung verwirft den gesamten Aufruf ohne gültiges Teilpräfix. Bei Split zählen auch leere Tokens. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_string.TVF_RegexSplit(N'a,b;;c', N'[0-9]+', N'c', N'standard', 1000);
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
- `Modules/toolbelt.string.regex/Documentation/TVF_RegexSplit.md`

Keine Installations-, Definitions- oder Rechteattestation.
