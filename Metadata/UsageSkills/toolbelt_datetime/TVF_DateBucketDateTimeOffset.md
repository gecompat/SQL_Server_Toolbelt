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
parameters: [{"name": "@DatePart", "sql_type": "varchar(16)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern."}, {"name": "@Width", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode."}, {"name": "@Value", "sql_type": "datetimeoffset(7)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder."}, {"name": "@Origin", "sql_type": "datetimeoffset(7)", "sql_default": "'1900-01-01 00:00:00 +00:00'", "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Referenz für die Bucketgrenzen. Default ist 1900-01-01 00:00:00+00:00; das Ergebnis verwendet den Offset des Origins. Explizites NULL ist kein Default und ergibt NULL-Resultfelder."}]
source_paths: ["Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketDateTimeOffset.sql", "Modules/toolbelt.datetime.bucket/Source/TVF_DateBucketCore.sql"]
review_status: "verified"
source_module_version: "1.0.0"
---

# TVF_DateBucketDateTimeOffset

## Zweck und Einsatzfälle

Ordnet einen datetimeoffset-Wert einem originbezogenen Zeit-Bucket zu. Für originbezogene Zeit-/Kalendergruppierungen; keine Rundung auf die nächste Grenze.

## Voraussetzungen

SQL Server 2019/2022/2025, Windows/Linux, unterstützte CL150/160/170. Modul installiert; kein CLR oder externer Datenzugriff. Alle vier Funktionsargumentpositionen angeben. DEFAULT für Origin wählt den deklarierten Bezugspunkt; explizites NULL wählt ihn nicht.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Eine nicht darstellbare berechnete Bucketgrenze löst einen Engine-Bereichsfehler aus; dafür existiert kein eigener ValidationCode. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `datetimeoffset(7)` | `'1900-01-01 00:00:00 +00:00'` | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Referenz für die Bucketgrenzen. Default ist 1900-01-01 00:00:00+00:00; das Ergebnis verwendet den Offset des Origins. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |

## Ergebnisse

Genau eine Zeile mit Value datetimeoffset(7), IsValid bit und ValidationCode tinyint. NULL in irgendeiner Eingabe: drei NULL-Werte. Erfolg: Value als berechneter Bucketanfang, IsValid=1, Code=0. Unbekannter Datepart: Value=NULL, IsValid=0, Code=10. Breite <=0: Value=NULL, IsValid=0, Code=11. Unbekannter Datepart hat Vorrang vor ungültiger Width. Kein eigener Status für arithmetischen Bereichsüberlauf.

## Aufrufbeispiele

```sql
SELECT * FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset
 ('day',2,CONVERT(datetimeoffset(7),'2026-01-04T12:00:00+00:00'),
 CONVERT(datetimeoffset(7),'2026-01-01T00:00:00+00:00'));
-- Bucketanfang 2026-01-03 00:00:00 (bei date ohne Uhrzeit); gültig, Code=0.
```

## Rechte

Vorhandenes SELECT für SELECT-Aufrufe; REFERENCES für entsprechende Referenzverwendungen. Interne Aufrufrechte und Cross-Database-Zuordnung bleiben projektgemäß erforderlich. Kein Rechtegrant oder Identitätswechsel.

## Ressourcenbedarf

Einzeilige Multistatement-TVF als bewusste Optimizer-Grenze gegen übergroße Inline-Ausdrucksbäume; die datetime2-/datetimeoffset-Fassaden sind dünne Inline-Wrapper. Keine Schleife oder Serienexpansion. Konstante Kalender-/Zeitberechnung je Eingabezeile. Plan und Gesamtkosten hängen von aufrufender Abfrage und Eingabemenge ab.

## Nebenwirkungen

Rein lesend ohne persistente DML-, Datei-, Netzwerk-, Konfigurations- oder Truständerungen. Der interne Multistatement-Kern befüllt ausschließlich seine lokale Rückgabetabelle.

## Fehlerbehandlung

NULL und fachlich ungültige Dateparts/Breiten liefern die oben beschriebenen Ergebniszustände. Typbindung sowie DATEADD-/CONVERT-Bereichsüberläufe bleiben Enginefehler; keine pauschale Umdeutung in ValidationCode und kein Retry.

## Aussagegrenzen

Der Algorithmus bildet DATEDIFF_BIG vom Origin, teilt mit Abrundung bei negativen Abständen durch Width, addiert ganze Bucketbreiten zum Origin und korrigiert einen zu großen Kandidaten um eine Breite. Kalenderaddition folgt SQL-Monatsendklammerung; Zeitanteil des Origins bleibt Bezug. week benutzt die DATEDIFF-Wochengrenzen, nicht die DATEFIRST-abhängige Truncate-Wochenlogik. datetimeoffset-Ausgabe behält den Origin-Offset; keine Zeitzonen-/Sommerzeitdatenbank und keine Garantie eines Value-Offsets im Ergebnis. datetime2 wird intern mit +00:00 gebunden. Extreme Breiten nahe Datumsgrenzen können vor oder bei der abschließenden Korrektur außerhalb des SQL-Wertebereichs liegen. Keine iso_week-, microsecond- oder nanosecond-Unterstützung.
