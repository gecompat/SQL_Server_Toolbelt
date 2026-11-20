---
name: "toolbelt-toolbelt-toolbelt-pseudonymization-tvf-determi-42345642"
description: "Verschiebt einen synthetischen 2D-Geography-Point im SRID 4326 deterministisch innerhalb eines Radius."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "TVF_DeterministicGeoJitter"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "geography", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Gültiger nicht leerer zweidimensionaler geography-Point mit SRID 4326, ohne Z/M, serialisierte Größe höchstens 128 Bytes; keine Linien/Polygone/anderen SRIDs. Beispielsweise geography::Point(48.2,16.3,4326). Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Fehlern; ungeeignete Geometrie Code 15. Ausgabe ist ein deterministisch versetzter Punkt, kein Anonymisierungsnachweis."}, {"name": "@Key", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@RadiusMeters", "sql_type": "int", "sql_default": "100", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..10000 Meter, Default 100. Obergrenze des radialen Jitters; Richtung und flächentreuer Radius werden aus dem Mappingkontext abgeleitet. NULL/0/negativ/größer ergibt Code 14. Keine Nullverschiebungsoption mit Radius 0."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/DeterministicGeoJitter.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# TVF_DeterministicGeoJitter

## Zweck und Einsatzfälle

Verschiebt einen synthetischen 2D-Geography-Point im SRID 4326 deterministisch innerhalb eines Radius.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `geography` | `kein Default` | Input | Gültiger nicht leerer zweidimensionaler geography-Point mit SRID 4326, ohne Z/M, serialisierte Größe höchstens 128 Bytes; keine Linien/Polygone/anderen SRIDs. Beispielsweise geography::Point(48.2,16.3,4326). Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Fehlern; ungeeignete Geometrie Code 15. Ausgabe ist ein deterministisch versetzter Punkt, kein Anonymisierungsnachweis. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@RadiusMeters` | `int` | `100` | Input | Ganzzahl 1..10000 Meter, Default 100. Obergrenze des radialen Jitters; Richtung und flächentreuer Radius werden aus dem Mappingkontext abgeleitet. NULL/0/negativ/größer ergibt Code 14. Keine Nullverschiebungsoption mit Radius 0. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicGeoJitter(geography::Point(48.2,16.3,4326), 0x01020304, 1, 42, 25);
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
- `Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicGeoJitter.md`

Keine Installations-, Definitions- oder Rechteattestation.
