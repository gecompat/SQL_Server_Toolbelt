---
name: "toolbelt-toolbelt-toolbelt-tsql-tvf-parsescriptnodeproperties"
description: "Liefert Eigenschaften der geparsten T-SQL-AST-Knoten."
skill_format_version: "1.0"
module_id: "toolbelt.tsql.script-parser"
schema_name: "toolbelt_tsql"
object_name: "TVF_ParseScriptNodeProperties"
object_type: "CLR_TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@SqlText", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Zu parsende T-SQL-Quelle als Unicode-Text, kein Objektname/Pfad und keine Ausführung. Leer ist zulässig. NULL liefert keine Zeilen vor jeder anderen Argumentprüfung. MaxInputBytes sowie vorgelagerte Struktur-/Token- und jeweilige Ausgabelimits gelten; Syntaxfehler über TVF_ParseScriptErrors untersuchen, nicht mit fehlenden AST-Zeilen verwechseln."}, {"name": "@TSqlVersion", "sql_type": "int", "sql_default": "160", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ: 80 = SQL2000-Grammatik, 90 = 2005, 100 = 2008, 110 = 2012, 120 = 2014, 130 = 2016, 140 = 2017, 150 = 2019, 160 = 2022 (Default), 170 = 2025. Wählt den ScriptDom-Parser, nicht die installierte Engine/DB-Compatibility. NULL wirkt wie 160; alle anderen int-Werte werden abgewiesen."}, {"name": "@QuotedIdentifiers", "sql_type": "bit", "sql_default": "1", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ im gebundenen bit: 1 interpretiert doppelte Anführungszeichen als Identifier (Default), 0 als Stringliterale gemäß Parsermodus. NULL wirkt wie 1. Kein automatisches Auslesen des Session-SET-Zustands."}, {"name": "@MaxInputBytes", "sql_type": "int", "sql_default": "2097152", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..2097152 UTF-16-Bytes, Default 2097152; explizites NULL übernimmt diesen Default. 0/negativ/größer ungültig; Überschreitung des gewählten Budgets wirft TBX_TSQLPARSE_INPUT_TOO_LARGE. Bei SqlText=NULL greift vorher der No-op."}, {"name": "@MaxNestingDepth", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..256, Default 100; NULL übernimmt 100. Begrenzt den Struktur-/AST-Pfad, nicht nur Klammerzeichen. Weitere unabhängige Vorabgrenzen (512 Atome, 32 Strukturebenen, 16 Kommentarverschachtelungen) und Ausgabelimits bleiben wirksam; ein höherer Wert hebt sie nicht auf."}]
source_paths: ["Modules/toolbelt.tsql.script-parser/Source/TVF_ParseScriptNodeProperties.sql"]
review_status: "draft"
source_module_version: "2.0.1"
---

# TVF_ParseScriptNodeProperties

## Zweck und Einsatzfälle

Liefert Eigenschaften der geparsten T-SQL-AST-Knoten.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@SqlText` | `nvarchar(max)` | `kein Default` | Input | Zu parsende T-SQL-Quelle als Unicode-Text, kein Objektname/Pfad und keine Ausführung. Leer ist zulässig. NULL liefert keine Zeilen vor jeder anderen Argumentprüfung. MaxInputBytes sowie vorgelagerte Struktur-/Token- und jeweilige Ausgabelimits gelten; Syntaxfehler über TVF_ParseScriptErrors untersuchen, nicht mit fehlenden AST-Zeilen verwechseln. |
| `@TSqlVersion` | `int` | `160` | Input | Taxativ: 80 = SQL2000-Grammatik, 90 = 2005, 100 = 2008, 110 = 2012, 120 = 2014, 130 = 2016, 140 = 2017, 150 = 2019, 160 = 2022 (Default), 170 = 2025. Wählt den ScriptDom-Parser, nicht die installierte Engine/DB-Compatibility. NULL wirkt wie 160; alle anderen int-Werte werden abgewiesen. |
| `@QuotedIdentifiers` | `bit` | `1` | Input | Taxativ im gebundenen bit: 1 interpretiert doppelte Anführungszeichen als Identifier (Default), 0 als Stringliterale gemäß Parsermodus. NULL wirkt wie 1. Kein automatisches Auslesen des Session-SET-Zustands. |
| `@MaxInputBytes` | `int` | `2097152` | Input | Ganzzahl 1..2097152 UTF-16-Bytes, Default 2097152; explizites NULL übernimmt diesen Default. 0/negativ/größer ungültig; Überschreitung des gewählten Budgets wirft TBX_TSQLPARSE_INPUT_TOO_LARGE. Bei SqlText=NULL greift vorher der No-op. |
| `@MaxNestingDepth` | `int` | `100` | Input | Ganzzahl 1..256, Default 100; NULL übernimmt 100. Begrenzt den Struktur-/AST-Pfad, nicht nur Klammerzeichen. Weitere unabhängige Vorabgrenzen (512 Atome, 32 Strukturebenen, 16 Kommentarverschachtelungen) und Ausgabelimits bleiben wirksam; ein höherer Wert hebt sie nicht auf. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_tsql.TVF_ParseScriptNodeProperties(N'SELECT 1 AS SyntheticValue;', 160, 1, 2097152, 256);
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
- `Modules/toolbelt.tsql.script-parser/Documentation/TVF_ParseScriptNodeProperties.md`

Keine Installations-, Definitions- oder Rechteattestation.
