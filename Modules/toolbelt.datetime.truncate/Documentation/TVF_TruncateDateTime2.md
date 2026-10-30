# toolbelt_datetime.TVF_TruncateDateTime2

Trunkiert einen `datetime2(7)`-Wert bis hinunter zu `microsecond`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_TruncateDateTime2
     ('millisecond', '2026-07-30T12:34:56.1234567');
```

`@DatePart varchar(16)` unterstützt die dokumentierten `DATETRUNC`-Dateparts
und Aliasse von `year` bis `microsecond`. `@Value` ist `datetime2(7)`.

Das Resultset besteht aus `Value datetime2(7)`, `IsValid bit` und
`ValidationCode tinyint`. Die Funktion ist ein dünner Inline-TVF-Typ-Wrapper
über den gemeinsamen `datetimeoffset(7)`-Kern. Sie ändert keine Zeitzone und
führt keine lokale Zeitzoneninterpretation aus.

Validation Codes und Grenzen:
[Moduldesign](../../../Documentation/Architecture/DATETIME_TRUNCATE_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `datetime2(7)` | `kein Default` | Input | SQL-datetime2(7) (0001-01-01..9999-12-31, bis sieben Nachkommastellen), etwa CONVERT(datetime2(7),'2026-10-30T12:34:56.1234567',126); keine Zeitzone. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |
<!-- API_PARAMETERS:END -->

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TruncateDateTime2.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
