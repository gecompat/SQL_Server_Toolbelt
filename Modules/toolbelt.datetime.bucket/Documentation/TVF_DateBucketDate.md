# toolbelt_datetime.TVF_DateBucketDate

Ermittelt den Bucket-Start für `date`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_DateBucketDate
     ('week', 2, '2026-07-30', DEFAULT);
```

Parameter sind `@DatePart varchar(16)`, `@Width int`, `@Value date` und
`@Origin date = '19000101'`. `DEFAULT` aktiviert den dokumentierten
Default-Origin; ein explizites `NULL` wird weitergegeben.

Das Resultset enthält `Value date`, `IsValid bit` und
`ValidationCode tinyint`. Zeit-Dateparts sind mit Code `12` ungültig.
Unbekannte Dateparts verwenden Code `10`, nicht positive Widths Code `11`.

Details:
[DATETIME_BUCKET_MODULE_DESIGN.md](../../../Documentation/Architecture/DATETIME_BUCKET_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Nicht darstellbare Grenzen werden über den Validierungsvertrag gemeldet. |
| `@Value` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `date` | `'19000101'` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Referenz für die Bucketgrenzen. Default ist 1900-01-01 um 00:00:00, soweit der Typ eine Uhrzeit besitzt. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#kalenderarithmetik).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_DateBucketDate.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
