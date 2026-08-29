# `toolbelt_datetime.TVF_DateSpineDay`

## Signatur

```sql
toolbelt_datetime.TVF_DateSpineDay
(
    @RangeStart date,
    @RangeEndExclusive date
)
```

## Resultset

| Spalte | Typ | NULL | Bedeutung |
|---|---|---|---|
| `Ordinal` | `int` | nein | Nullbasierte Position innerhalb der erzeugten Menge. |
| `PeriodStart` | `date` | nein | Anfang des geschnittenen Kalendertags. |

Der Bereich ist halboffen. `NULL`, leere und umgekehrte Bereiche liefern keine
Zeilen. Die Funktion garantiert ohne `ORDER BY` keine Reihenfolge.

```sql
SELECT Ordinal, PeriodStart
FROM toolbelt_datetime.TVF_DateSpineDay('20260227', '20260303')
ORDER BY Ordinal;
```
