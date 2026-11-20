---
name: "toolbelt-toolbelt-toolbelt-pseudonymization-tvf-determi-066b2af2"
description: "Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "TVF_DeterministicRange"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Key", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@Min", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und <=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen."}, {"name": "@Max", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und >=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicRange.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# TVF_DeterministicRange

## Zweck und Einsatzfälle

Ordnet einen Schlüssel deterministisch einem ganzzahligen Zielbereich zu.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@Min` | `bigint` | `kein Default` | Input | Inklusive Untergrenze im gesamten bigint-Bereich; muss nicht NULL und &lt;=Max sein. Min=Max ist gültig und liefert diesen Wert. NULL/vertauschte Grenzen ergeben Code 3 nach früheren NULL-/Konfigurationsprüfungen. |
| `@Max` | `bigint` | `kein Default` | Input | Inklusive Obergrenze im gesamten bigint-Bereich; nicht NULL und &gt;=Min. Auch der volle vorzeichenbehaftete 64-Bit-Bereich ist zulässig; kein exklusives Ende. NULL/vertauscht ergibt Code 3. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x01020304, 1, 42, 1, 100);
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
- `Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicRange.md`

Keine Installations-, Definitions- oder Rechteattestation.
