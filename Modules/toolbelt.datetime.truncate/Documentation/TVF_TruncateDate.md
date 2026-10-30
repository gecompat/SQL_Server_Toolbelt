# toolbelt_datetime.TVF_TruncateDate

Trunkiert einen `date`-Wert nach dem portablen W2a-Vertrag.

```sql
SELECT Value, IsValid, ValidationCode
FROM toolbelt_datetime.TVF_TruncateDate('month', '2026-07-30');
```

## Parameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |
<!-- API_PARAMETERS:END -->

## Ergebnis

| Spalte | Typ | Beschreibung |
|---|---|---|
| `Value` | `date` | truncierter Wert oder `NULL` |
| `IsValid` | `bit` | `1`, `0` oder bei NULL-Propagation `NULL` |
| `ValidationCode` | `tinyint` | `0`, `10`, `11`, `12` oder `NULL` |

Zeit-Dateparts liefern Code `11`. `week` folgt `@@DATEFIRST`; `iso_week`
beginnt am Montag. Details und Codes stehen im
[Moduldesign](../../../Documentation/Architecture/DATETIME_TRUNCATE_MODULE_DESIGN.md).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TruncateDate.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
