---
name: "toolbelt-toolbelt-toolbelt-pseudonymization-tvf-determi-87f07795"
description: "Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage."
skill_format_version: "1.0"
module_id: "toolbelt.pseudonymization.deterministic"
schema_name: "toolbelt_pseudonymization"
object_name: "TVF_DeterministicDateShift"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Value", "sql_type": "datetime2(7)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "datetime2(7) im nativen Bereich 0001-01-01..9999-12-31; Uhrzeit/Präzision bleiben beim ganzzahligen Tagesoffset erhalten. Keine Zeitzone/DST-Konvertierung. Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Konfigurationsfehlern. Überlauf des gezogenen Offsets ergibt Code 8, kein Clamp/Wrap."}, {"name": "@Key", "sql_type": "varbinary(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag."}, {"name": "@MappingVersion", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert."}, {"name": "@Seed", "sql_type": "bigint", "sql_default": "0", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad."}, {"name": "@MaxDays", "sql_type": "int", "sql_default": "365", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 0..3652058 Tage, Default 365. Offset wird deterministisch aus dem geschlossenen Intervall [-MaxDays,+MaxDays] gewählt; 0 lässt das Datum unverändert. NULL/außerhalb ergibt Code 7; Datumsoverflow wird zusätzlich geprüft."}]
source_paths: ["Modules/toolbelt.pseudonymization.deterministic/Source/TVF_DeterministicDateShift.sql"]
review_status: "draft"
source_module_version: "1.2.0"
---

# TVF_DeterministicDateShift

## Zweck und Einsatzfälle

Verschiebt ein Datum deterministisch um eine begrenzte Anzahl Tage.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Value` | `datetime2(7)` | `kein Default` | Input | datetime2(7) im nativen Bereich 0001-01-01..9999-12-31; Uhrzeit/Präzision bleiben beim ganzzahligen Tagesoffset erhalten. Keine Zeitzone/DST-Konvertierung. Value=NULL oder Key=NULL liefert NULL/Code 0 vor anderen Konfigurationsfehlern. Überlauf des gezogenen Offsets ergibt Code 8, kein Clamp/Wrap. |
| `@Key` | `varbinary(max)` | `kein Default` | Input | Binärer Entity-Key varbinary(max) mit 1..8000 Bytes, z.B. 0x010203; keine automatische Textkodierung/Normalisierung. NULL ist ein früher NULL-Ergebnispfad mit ErrorCode 0; leer/größer ergibt Code 4. Gleichheit meint dieselben Bytes, nicht einen Darstellungsstring. Kein Geheimschlüsselvertrag. |
| `@MappingVersion` | `int` | `kein Default` | Input | Positive Ganzzahl 1..2147483647 als explizite Mappingkontextversion. NULL/0/negativ ergibt ErrorCode 1, sofern kein früher NULL-Eingabepfad greift. Keine automatische aktuelle Version; Änderung verändert das Mapping, garantiert aber nicht jeden Einzelwert. |
| `@Seed` | `bigint` | `0` | Input | Jeder nicht-NULL-bigint (-9223372036854775808..9223372036854775807), Default 0. Deterministischer Variantenkontext, kein Zufall je Aufruf und kein Secret. NULL ergibt Code 2 nach dem frühen NULL-Eingabepfad. |
| `@MaxDays` | `int` | `365` | Input | Ganzzahl 0..3652058 Tage, Default 365. Offset wird deterministisch aus dem geschlossenen Intervall [-MaxDays,+MaxDays] gewählt; 0 lässt das Datum unverändert. NULL/außerhalb ergibt Code 7; Datumsoverflow wird zusätzlich geprüft. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2024-07-19T14:35:42'), 0x01020304, 1, 42, 7);
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
- `Modules/toolbelt.pseudonymization.deterministic/Documentation/TVF_DeterministicDateShift.md`

Keine Installations-, Definitions- oder Rechteattestation.
