---
name: "toolbelt-toolbelt-toolbelt-datetime-tvf-datebucketdatetimeoffset"
description: "Ordnet einen datetimeoffset-Wert einem originbezogenen Zeit-Bucket zu."
skill_format_version: "1.0"
module_id: "toolbelt.datetime.bucket"
schema_name: "toolbelt_datetime"
object_name: "TVF_DateBucketDateTimeOffset"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@DatePart", "sql_type": "varchar(16)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern."}, {"name": "@Width", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Nicht darstellbare Grenzen werden über den Validierungsvertrag gemeldet."}, {"name": "@Value", "sql_type": "datetimeoffset(7)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder."}, {"name": "@Origin", "sql_type": "datetimeoffset(7)", "sql_default": "'1900-01-01 00:00:00 +00:00'", "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Referenz für die Bucketgrenzen. Default ist 1900-01-01 00:00:00+00:00; das Ergebnis verwendet den Offset des Origins. Explizites NULL ist kein Default und ergibt NULL-Resultfelder."}]
source_paths: ["Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDateTimeOffset.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_DateBucketDateTimeOffset

## Zweck und Einsatzfälle

Ordnet einen datetimeoffset-Wert einem originbezogenen Zeit-Bucket zu.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Nicht darstellbare Grenzen werden über den Validierungsvertrag gemeldet. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `datetimeoffset(7)` | `'1900-01-01 00:00:00 +00:00'` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Referenz für die Bucketgrenzen. Default ist 1900-01-01 00:00:00+00:00; das Ergebnis verwendet den Offset des Origins. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset('day', 7, CONVERT(datetimeoffset(7),'2024-07-19T14:35:42+02:00'), CONVERT(datetimeoffset(7),'2024-01-01'));
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
- `Modules/toolbelt.datetime.bucket/Documentation/TVF_DateBucketDateTimeOffset.md`

Keine Installations-, Definitions- oder Rechteattestation.
