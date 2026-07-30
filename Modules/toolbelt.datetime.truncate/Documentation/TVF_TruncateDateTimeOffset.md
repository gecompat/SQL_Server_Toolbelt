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
