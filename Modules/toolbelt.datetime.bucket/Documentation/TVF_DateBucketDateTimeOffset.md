# toolbelt_datetime.TVF_DateBucketDateTimeOffset

Kanonischer Bucket-Kern für `datetimeoffset(7)`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_DateBucketDateTimeOffset
     (
           'hour'
         , 6
         , '2026-07-30T12:34:56.1234567+02:00'
         , '2026-01-01T00:00:00.0000000+02:00'
     );
```

Value und Origin besitzen denselben SQL-Typ. Der Default-Origin ist
`1900-01-01 00:00:00 +00:00`. Der resultierende Offset folgt dem
Origin-basierten Rechenpfad; die native Paritätsmatrix prüft auch
unterschiedliche Offsets.

Das Resultset enthält `Value datetimeoffset(7)`, `IsValid bit` und
`ValidationCode tinyint`.

Details:
[DATETIME_BUCKET_MODULE_DESIGN.md](../../../Documentation/Architecture/DATETIME_BUCKET_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Nicht darstellbare Grenzen werden über den Validierungsvertrag gemeldet. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `datetimeoffset(7)` | `'1900-01-01 00:00:00 +00:00'` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Referenz für die Bucketgrenzen. Default ist 1900-01-01 00:00:00+00:00; das Ergebnis verwendet den Offset des Origins. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#kalenderarithmetik).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_DateBucketDateTimeOffset.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
