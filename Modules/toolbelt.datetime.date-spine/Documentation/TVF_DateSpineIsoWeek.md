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

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@RangeStart` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Inklusive Untergrenze; auch die diesen Tag enthaltende Periode wird ausgegeben. NULL oder Start &gt;= Ende liefert keine Zeilen. |
| `@RangeEndExclusive` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Exklusive Obergrenze; ausgegeben werden nur Perioden, die [Start,Ende) schneiden. NULL, gleiche oder umgekehrte Grenzen liefern keine Zeilen. Kein unbegrenztes Ende und kein Datum jenseits 9999-12-31. |
<!-- API_PARAMETERS:END -->

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#kalenderarithmetik).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_DateSpineIsoWeek.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
