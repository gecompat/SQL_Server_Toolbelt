# toolbelt_datetime.TVF_TruncateDateTimeOffset

Kanonischer Truncation-Kern für `datetimeoffset(7)`.

```sql
SELECT Value
FROM toolbelt_datetime.TVF_TruncateDateTimeOffset
     ('hour', '2026-07-30T12:34:56.1234567+02:00');
```

Die Funktion erhält den im Eingabewert gespeicherten Offset. `week` folgt dem
Sessionwert `@@DATEFIRST`, während `iso_week` Montag verwendet.

| Resultspalte | Typ |
|---|---|
| `Value` | `datetimeoffset(7)` |
| `IsValid` | `bit` |
| `ValidationCode` | `tinyint` |

Für unbekannte Dateparts wird Code `10`, für einen `week`-Unterlauf Code `12`
geliefert. Erforderliche NULL-Parameter werden als vollständig typisierte
NULL-Zeile weitergegeben.

Vollständiger Vertrag:
[DATETIME_TRUNCATE_MODULE_DESIGN.md](../../../Documentation/Architecture/DATETIME_TRUNCATE_MODULE_DESIGN.md).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@DatePart` | `varchar(16)` | `kein Default` | Input | Taxativ, jeweils gleiche Bedeutung innerhalb einer Aliasgruppe: year/yy/yyyy = Kalenderjahr; quarter/qq/q = Quartal; month/mm/m = Monat; dayofyear/dy/y/day/dd/d = Kalendertag; week/wk/ww = Woche (abhängig von SET DATEFIRST); iso_week/isowk/isoww = ISO-Woche ab Montag; hour/hh = Stunde; minute/mi/n = Minute; second/ss/s = Sekunde; millisecond/ms = Millisekunde; microsecond/mcs = Mikrosekunde. Keine weiteren Dateparts, insbesondere kein weekday, tzoffset oder nanosecond. Groß-/Kleinschreibung wird durch LOWER normalisiert; nachgestellte Spaces folgen SQL-Gleichheitsvergleich, führende werden nicht getrimmt. Leer/unbekannt ist ungültig; NULL führt zu NULL-Resultfeldern. |
| `@Value` | `datetimeoffset(7)` | `kein Default` | Input | SQL-datetimeoffset(7), etwa CONVERT(datetimeoffset(7),'2026-10-30T12:34:56.1234567+02:00',127); Offset -14:00..+14:00 und gültiger lokaler/UTC-SQL-Wertebereich, keine Zeitzonen-/Sommerzeitdatenbank. Zu kürzender Wert; NULL ergibt NULL-Resultfelder. Der ursprüngliche Offset bleibt erhalten. Ein Wochenanfang außerhalb des SQL-Datumsbereichs ist ein Validierungsfehler. |
<!-- API_PARAMETERS:END -->

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_TruncateDateTimeOffset.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
