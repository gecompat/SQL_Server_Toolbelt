---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-integertobase"
description: "Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.integer-base"
schema_name: "toolbelt_conversion"
object_name: "TVF_IntegerToBase"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-bigint im gesamten Bereich -9223372036854775808..9223372036854775807; negative Werte erhalten ein führendes -. 0 wird als erstes Alphabetzeichen ausgegeben. NULL ergibt NULL."}, {"name": "@Alphabet", "sql_type": "varchar(93)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL."}]
source_paths: ["Modules/toolbelt.conversion.integer-base/Source/TVF_IntegerToBase.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# TVF_IntegerToBase

## Zweck und Einsatzfälle

Codiert einen bigint-Wert in einem frei festgelegten Zahlensystem.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `bigint` | `kein Default` | Input | SQL-bigint im gesamten Bereich -9223372036854775808..9223372036854775807; negative Werte erhalten ein führendes -. 0 wird als erstes Alphabetzeichen ausgegeben. NULL ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_IntegerToBase(255, '0123456789ABCDEF');
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
- `Modules/toolbelt.conversion.integer-base/Documentation/TVF_IntegerToBase.md`

Keine Installations-, Definitions- oder Rechteattestation.
