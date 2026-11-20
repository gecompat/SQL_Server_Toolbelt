---
name: "toolbelt-toolbelt-toolbelt-datetime-tvf-truncatedatetimeoffset"
description: "Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset."
skill_format_version: "1.0"
module_id: "toolbelt.datetime.truncate"
schema_name: "toolbelt_datetime"
object_name: "TVF_TruncateDateTimeOffset"
object_type: "TVF"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@DatePart", "sql_type": "varchar(16)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern."}, {"name": "@Value", "sql_type": "datetimeoffset(7)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": null, "nullable": null, "description": "SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Der ursprüngliche Offset bleibt erhalten. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler."}]
source_paths: ["Modules/toolbelt.datetime.truncate/Source/TVF_TruncateDateTimeOffset.sql"]
review_status: "draft"
source_module_version: "1.0.0"
---

# TVF_TruncateDateTimeOffset

## Zweck und Einsatzfälle

Kürzt einen datetimeoffset-Wert auf die gewählte Zeiteinheit und erhält den Offset.

Reviewentwurf: vorhandene Beschreibung mit der Implementierung abgleichen.

## Voraussetzungen

Noch gegen den Code zu prüfen.

## Parameter und Zugriff

| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Der ursprüngliche Offset bleibt erhalten. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |

## Ergebnisse

Noch am Code zu prüfen; aus vorhandenen Unterlagen nicht automatisch als verifiziert übernommen.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_datetime.TVF_TruncateDateTimeOffset('day', CONVERT(datetimeoffset(7),'2024-07-19T14:35:42+02:00'));
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
- `Modules/toolbelt.datetime.truncate/Documentation/TVF_TruncateDateTimeOffset.md`

Keine Installations-, Definitions- oder Rechteattestation.
