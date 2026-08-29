# `toolbelt_datetime.TVF_DateSpineMonth`

## Signatur

```sql
toolbelt_datetime.TVF_DateSpineMonth
(
    @RangeStart date,
    @RangeEndExclusive date
)
```

## Resultset

| Spalte | Typ | NULL | Bedeutung |
|---|---|---|---|
| `Ordinal` | `int` | nein | Nullbasierte Position innerhalb der erzeugten Menge. |
| `PeriodStart` | `date` | nein | Erster Tag des geschnittenen Kalendermonats. |

Alle Kalendermonate, die den halboffenen Bereich schneiden, werden geliefert.
Der erste Periodenanfang kann vor `@RangeStart` liegen. Ohne `ORDER BY` besteht
keine Reihenfolgegarantie.

```sql
SELECT Ordinal, PeriodStart
FROM toolbelt_datetime.TVF_DateSpineMonth('20260115', '20260402')
ORDER BY Ordinal;
```
