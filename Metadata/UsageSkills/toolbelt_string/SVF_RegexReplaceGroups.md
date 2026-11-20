---
name: "toolbelt-toolbelt-toolbelt-string-svf-regexreplacegroups"
description: "Ersetzt Regex-Treffer mit dem getrennten Gruppen-Ersatzvertrag."
skill_format_version: "1.0"
module_id: "toolbelt.string.regex"
schema_name: "toolbelt_string"
object_name: "SVF_RegexReplaceGroups"
object_type: "SVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile."}, {"name": "@Pattern", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \\d/\\w/\\s, Unicode-Kategorie nur \\p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. Capturegruppen können unbenannt oder (?<Name>...) sein; Namen 1..128 ASCII-Zeichen, Beginn Buchstabe/_ danach zusätzlich Ziffern, ohne case-insensitive Namensduplikate. Maximal 64 deklarierte Gruppen und konservative Capture-History 100000."}, {"name": "@Replacement", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ersetzungstext, leer löscht den Treffer; NULL ergibt NULL vor weiterer Prüfung. Gruppenreferenzen ausschließlich $1..$64 auf vorhandene Gruppen, ${Name} auf deklarierte Namen sowie $$ für ein Dollarzeichen. $0/Gruppe 0, unbekannte Referenzen und ungültige Syntax werden auch ohne Treffer abgewiesen; höchstens 65536 Ersetzungsteile. Höchstens 1048576 UTF-16-Einheiten im Profil standard beziehungsweise 8388608 in large; auch die gesamte erzeugte Ausgabe bleibt auf dieses Profilbudget begrenzt."}, {"name": "@Start", "sql_type": "int", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer."}, {"name": "@Occurrence", "sql_type": "int", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 0..2147483647, Default 0: 0 ersetzt alle Treffer ab Start, positiv nur den n-ten Treffer ab Start. Negativ/NULL ungültig; vor Start bleibt der Text erhalten."}, {"name": "@Flags", "sql_type": "nvarchar(max)", "sql_default": "N'c'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung."}, {"name": "@Profile", "sql_type": "nvarchar(max)", "sql_default": "N'standard'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher."}]
source_paths: ["Modules/toolbelt.string.regex/Source/RegexCaptures.sql"]
review_status: "draft"
source_module_version: "1.3.0"
---

# SVF_RegexReplaceGroups

## Zweck und Einsatzfälle

Ersetzt Regex-Treffer mit dem getrennten Gruppen-Ersatzvertrag.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `kein Default` | Input | Zu durchsuchender Unicode-Text; leer ist gültig. Positionen zählen UTF-16-Einheiten, 1-basiert, ohne automatische Normalisierung. NULL ergibt NULL bei SVF bzw. keine Zeilen bei TVF vor weiterer Parameterprüfung. Maximum richtet sich nach Profile. |
| `@Pattern` | `nvarchar(max)` | `kein Default` | Input | Begrenzter Toolbelt-Regexdialekt gemäß REGEX_FUNCTIONS.md, kein beliebiges .NET-Pattern: Literale/Escapes, Punkt, ^/$, Gruppen/Alternativen, Klassen und begrenzte Quantoren; ASCII-Definitionen für \d/\w/\s, Unicode-Kategorie nur \p{L}. Lookarounds und Pattern-Backreferences sind nicht erlaubt. Leer ist gültig, NULL propagiert NULL/keine Zeilen vor anderer Prüfung. Maximum 8000 UTF-16-Einheiten, übersetztes Pattern höchstens 64000, Gruppentiefe 64, Alternativen 1024 und Quantorobergrenze 1000. Capturegruppen können unbenannt oder (?&lt;Name&gt;...) sein; Namen 1..128 ASCII-Zeichen, Beginn Buchstabe/_ danach zusätzlich Ziffern, ohne case-insensitive Namensduplikate. Maximal 64 deklarierte Gruppen und konservative Capture-History 100000. |
| `@Replacement` | `nvarchar(max)` | `kein Default` | Input | Ersetzungstext, leer löscht den Treffer; NULL ergibt NULL vor weiterer Prüfung. Gruppenreferenzen ausschließlich $1..$64 auf vorhandene Gruppen, ${Name} auf deklarierte Namen sowie $$ für ein Dollarzeichen. $0/Gruppe 0, unbekannte Referenzen und ungültige Syntax werden auch ohne Treffer abgewiesen; höchstens 65536 Ersetzungsteile. Höchstens 1048576 UTF-16-Einheiten im Profil standard beziehungsweise 8388608 in large; auch die gesamte erzeugte Ausgabe bleibt auf dieses Profilbudget begrenzt. |
| `@Start` | `int` | `1` | Input | Ganzzahl 1..2147483647, Default 1: 1-basierter Suchbeginn in UTF-16-Einheiten. NULL/0/negativ ungültig. Länge+1 lässt einen terminalen Leertreffer zu; weiter dahinter gibt es keinen Treffer. |
| `@Occurrence` | `int` | `0` | Input | Ganzzahl 0..2147483647, Default 0: 0 ersetzt alle Treffer ab Start, positiv nur den n-ten Treffer ab Start. Negativ/NULL ungültig; vor Start bleibt der Text erhalten. |
| `@Flags` | `nvarchar(max)` | `N'c'` | Input | Taxativ sind die einzelnen Flags c = case-sensitiv (Default), i = case-insensitiv/CultureInvariant, m = ^/$ je Zeile, s = Punkt auch über Zeilenumbrüche. Leer ist ebenfalls gültig und case-sensitiv. Erlaubte Mengen: leer, c, i, m, s, cm, cs, im, is, ms, cms, ims; Reihenfolge beliebig, jedes Zeichen höchstens einmal. c+i, Großbuchstaben, Spaces, andere Zeichen und NULL sind ungültig. Ein früher NULL-Input/-Pattern-Pfad überspringt die Prüfung. |
| `@Profile` | `nvarchar(max)` | `N'standard'` | Input | Taxativ, ordinal/case-sensitiv ohne Trim: standard (Default) erlaubt 1048576 Input-UTF-16-Einheiten und 500 ms kooperatives Gesamtbudget; large erlaubt 8388608 Einheiten und 2000 ms. Jede Engine-Suche bleibt auf höchstens 250 ms begrenzt. NULL/leer/andere Werte ungültig; NULL-Input/-Pattern (bei Replace auch NULL-Replacement) beendet vorher. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT toolbelt_string.SVF_RegexReplaceGroups(N'abc123 def456', N'(?<Digits>[0-9]+)', N'[${Digits}]', 1, 0, N'c', N'standard') AS ResultValue;
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
- `Modules/toolbelt.string.regex/Documentation/SVF_RegexReplaceGroups.md`

Keine Installations-, Definitions- oder Rechteattestation.
