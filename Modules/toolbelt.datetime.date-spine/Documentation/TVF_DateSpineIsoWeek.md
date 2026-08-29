# `toolbelt_datetime.TVF_DateSpineIsoWeek`

## Signatur

```sql
toolbelt_datetime.TVF_DateSpineIsoWeek
(
    @RangeStart date,
    @RangeEndExclusive date
)
```

## Resultset

| Spalte | Typ | NULL | Bedeutung |
|---|---|---|---|
| `Ordinal` | `int` | nein | Nullbasierte Position innerhalb der erzeugten Menge. |
| `PeriodStart` | `date` | nein | Montag der geschnittenen ISO-Woche. |

Alle ISO-Wochen, die den halboffenen Bereich schneiden, werden geliefert. Der
erste Periodenanfang kann vor `@RangeStart` liegen. Das Ergebnis ist unabhängig
von `SET DATEFIRST`; ohne `ORDER BY` besteht keine Reihenfolgegarantie.

```sql
SELECT Ordinal, PeriodStart
FROM toolbelt_datetime.TVF_DateSpineIsoWeek('20251231', '20260108')
ORDER BY Ordinal;
```
