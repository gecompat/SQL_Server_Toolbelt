# toolbelt_datetime.TVF_DateBucketDateTime2

Ermittelt den Bucket-Start für `datetime2(7)`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_DateBucketDateTime2
     ('minute', 15, '2026-07-30T12:34:56.1234567', DEFAULT);
```

Parameter:

- `@DatePart varchar(16)`;
- `@Width int`;
- `@Value datetime2(7)`;
- `@Origin datetime2(7) = '19000101'`.

Das Resultset besteht aus `Value datetime2(7)`, `IsValid bit` und
`ValidationCode tinyint`. Werte vor Origin werden nicht Richtung null,
sondern zum früheren Bucket-Start abgerundet.

Details:
[DATETIME_BUCKET_MODULE_DESIGN.md](../../../Documentation/Architecture/DATETIME_BUCKET_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche; weekday/dw/w = ebenfalls Kalendertag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde. Keine weiteren Dateparts, insbesondere kein iso_week, microsecond oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Width` | `int` | `kein Default` | Input | Ganzzahl 1..2147483647 als int: Anzahl der in DatePart gewählten Einheiten pro Bucket. 0/negativ ist ungültig; NULL ergibt NULL-Resultfelder. Nicht darstellbare Grenzen werden über den Validierungsvertrag gemeldet. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Einzuordnender Wert, auch vor Origin zulässig; NULL ergibt NULL-Resultfelder. |
| `@Origin` | `datetime2(7)` | `'19000101'` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Referenz für die Bucketgrenzen. Default ist 1900-01-01 um 00:00:00, soweit der Typ eine Uhrzeit besitzt. Explizites NULL ist kein Default und ergibt NULL-Resultfelder. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#kalenderarithmetik).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_DateBucketDateTime2.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
