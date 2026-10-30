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

## Aufrufparameter

| Parameter | SQL-Typ | Default | Richtung | Bedeutung |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | Einschließliche untere Intervallgrenze. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | Ausschließliche obere Intervallgrenze. |

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_DateSpineDay.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
