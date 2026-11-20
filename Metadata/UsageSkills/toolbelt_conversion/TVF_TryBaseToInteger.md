---
name: "toolbelt-toolbelt-toolbelt-conversion-tvf-trybasetointeger"
description: "Decodiert einen Text anhand des angegebenen Alphabets in bigint."
skill_format_version: "1.0"
module_id: "toolbelt.conversion.integer-base"
schema_name: "toolbelt_conversion"
object_name: "TVF_TryBaseToInteger"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@EncodedValue", "sql_type": "varchar(65)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL."}, {"name": "@Alphabet", "sql_type": "varchar(93)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL."}]
source_paths: ["Modules/toolbelt.conversion.integer-base/Source/TVF_TryBaseToInteger.sql"]
review_status: "draft"
source_module_version: "1.1.0"
---

# TVF_TryBaseToInteger

## Zweck und Einsatzfälle

Decodiert einen Text anhand des angegebenen Alphabets in bigint.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@EncodedValue` | `varchar(65)` | `kein Default` | Input | Zahlentext aus dem angegebenen Alphabet, höchstens 65 varchar-Bytes; optional genau ein führendes - als Vorzeichen. Keine führenden Nullziffern bei mehrstelligen Werten, kein negatives Null und keine Leerzeichen-Normalisierung. Alle Zeichen müssen Alphabetziffern sein; Betrag muss in bigint passen. Leer, NULL, ungültige Lexik oder Überlauf ergibt NULL. |
| `@Alphabet` | `varchar(93)` | `kein Default` | Input | 2..93 verschiedene einbyteige ASCII-Zeichen aus Codes 33..126, ohne Minuszeichen -. Reihenfolge definiert die Ziffernwerte ab 0; das erste Zeichen ist die Nullziffer. Binärer, case-sensitiver Vergleich; keine Duplikate oder Leerzeichen. NULL/ungültiges Alphabet ergibt NULL. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_conversion.TVF_TryBaseToInteger('FF', '0123456789ABCDEF');
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
- `Modules/toolbelt.conversion.integer-base/Documentation/TVF_TryBaseToInteger.md`

Keine Installations-, Definitions- oder Rechteattestation.
