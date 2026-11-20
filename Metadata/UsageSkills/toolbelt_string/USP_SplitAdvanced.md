---
name: "toolbelt-toolbelt-toolbelt-string-usp-splitadvanced"
description: "Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting."
skill_format_version: "1.0"
module_id: "toolbelt.string.split-advanced"
schema_name: "toolbelt_string"
object_name: "USP_SplitAdvanced"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Input", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden."}, {"name": "@SeparatorsJson", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. [\"::\",\",\"]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig."}, {"name": "@Quote", "sql_type": "nvarchar(max)", "sql_default": "N'\"'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax."}, {"name": "@Escape", "sql_type": "nvarchar(max)", "sql_default": "N'\\'", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt."}, {"name": "@KeepEmpty", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden."}]
source_paths: ["Modules/toolbelt.string.split-advanced/Source/USP_SplitAdvanced.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# USP_SplitAdvanced

## Zweck und Einsatzfälle

Originaltokens aus kanonischer TVF; Geschäftsfehler vor Zielmutation, kein Unquoting.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Input` | `nvarchar(max)` | `NULL` | Input | Text mit maximal 65536 UTF-16-Einheiten, NUL verboten; leer ist gültig. NULL ist ein früher No-op ohne Zeilen, selbst bei ungültiger Konfiguration. Tokens bleiben im Original einschließlich Quotes/Escapes; zum Entfernen TVF_UnquoteToken verwenden. |
| `@SeparatorsJson` | `nvarchar(max)` | `NULL` | Input | JSON-Array aus 1..16 verschiedenen nicht leeren Strings, z.B. ["::",","]; kein Objekt, keine JSON-null-/Zahlen-/Boolean-Elemente. Je Separator 1..64 UTF-16-Einheiten, Gesamt-JSON höchstens 16384 Einheiten. Binäre Gleichheit einschließlich Spaces; NUL und die aktivierten Quote-/Escape-Zeichen verboten. Längster passender Separator gewinnt. NULL ist außerhalb des frühen Input-NULL-Pfads ungültig. |
| `@Quote` | `nvarchar(max)` | `N'"'` | Input | Genau eine UTF-16-Einheit (Default Doppelquote) aktiviert Quotegruppen; leer deaktiviert sie. NULL, NUL und Surrogate ungültig. Muss sich vom aktiven Escape unterscheiden und darf in keinem Separator vorkommen; keine automatische mehrzeichige Quote-Syntax. |
| `@Escape` | `nvarchar(max)` | `N'\'` | Input | Genau eine UTF-16-Einheit (Default Backslash) schützt das nächste Zeichen vor Parserwirkung; leer deaktiviert Escaping. NULL, NUL und Surrogate ungültig. Darf weder aktives Quote noch Bestandteil eines Separators sein. Ein finales Escape ohne Folgezeichen ist ein Parserfehler; Ausgabe bleibt unentschlüsselt. |
| `@KeepEmpty` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 behält leere Tokens einschließlich leerem Input (Default); 0 entfernt sie. NULL wird wie 1 behandelt. |
| `@ResultTable` | `sysname` | `NULL` | Input | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. |
| `@KeepData` | `bit` | `0` | Input | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | Input | tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. |
| `@Hilfe` | `bit` | `0` | Input | Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden. |

## Ergebnisse

Originaltoken, Latin1_General_100_BIN2.

1-basiert, nach Leerfilter lückenlos; Tabellen garantieren keine physische Reihenfolge.

## Aufrufbeispiele

```sql
EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b', @SeparatorsJson=N'[";"]', @Quote=N'', @Escape=N'';
```

```sql
EXEC toolbelt_string.USP_SplitAdvanced
    @Input=N'a;"b;c";d', @SeparatorsJson=N'[";"]';
EXEC toolbelt_string.USP_SplitAdvanced @Hilfe=1;
```

## Rechte

EXECUTE auf USP; ResultTable-Pfad benötigt Helper-EXECUTE und Sichtbarkeit der caller-lokalen Temp-Tabelle; keine Rechteausweitung.

## Ressourcenbedarf

Noch gegen tatsächliche Grenzen/Algorithmen zu prüfen; keine Kapazitäts- oder Laufzeitwerte erfinden.

## Nebenwirkungen

Noch am tatsächlichen Ausführungspfad zu prüfen; dieser Entwurf erteilt keine Ausführungsautorität.

## Fehlerbehandlung

TVF-Geschäftscode und Originalposition ohne Inputinhalt; keine Teilausgabe.

Registrierte same-database ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.

## Aussagegrenzen

NULL Input: leeres SELECT oder Ziel vollständig unverändert. Enginefehler bleiben Originalfehler; doomed Caller benötigt Callerrollback.

Ursprüngliche Objektverträge:
- `Modules/toolbelt.string.split-advanced/Documentation/USP_SplitAdvanced.md`

Keine Installations-, Definitions- oder Rechteattestation.
