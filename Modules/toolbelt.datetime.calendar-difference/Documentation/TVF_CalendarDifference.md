# TVF_CalendarDifference

`toolbelt_datetime.TVF_CalendarDifference(@StartDate date, @EndDate date)` liefert eine Zeile mit `Sign`, `Years`, `Months` und `Days`. Der Betrag der drei Komponenten ist nicht negativ; nur `Sign` drückt die Richtung aus.

Die Komponenten werden vom früheren zum späteren Datum bestimmt. Eine negative Eingabereihenfolge ändert ausschließlich `Sign`. Bei `NULL` sind alle Spalten `NULL`. Vollständige Einheiten verwenden die Anniversary-Regel: Ein Zielmonat ohne entsprechenden Kalendertag wird auf dessen Monatsende geklammert.

Der Vertrag akzeptiert nur `date`; Uhrzeit, Zeitzone und andere Kalendersysteme gehören nicht zum Scope.

Quelle: [DATEDIFF (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver17).

## Aufrufparameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@StartDate` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Anfang des Vergleichs. Beide Reihenfolgen und gleiche Daten sind zulässig; die Richtung steht nur in Sign. NULL ergibt NULL in allen Ergebnisspalten. |
| `@EndDate` | `date` | `kein Default` | Input | SQL-date (0001-01-01..9999-12-31), etwa CONVERT(date,'20261030',112); kein Uhrzeit-/Offsetanteil. Zweites Datum. Vollständige Jahre/Monate folgen der Anniversary-Regel einschließlich Monatsendklammerung. NULL ergibt NULL in allen Ergebnisspalten. |
<!-- API_PARAMETERS:END -->

## Beispielaufruf

```sql
SELECT * FROM toolbelt_datetime.TVF_CalendarDifference(CONVERT(date,'2024-01-31'), CONVERT(date,'2025-03-02'));
```

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#kalenderarithmetik).

## Weiterführende Referenzen

- [Modul, Installation und Testgrenzen](../README.md)
- [SQL-Definition](../Source/TVF_CalendarDifference.sql)
- [Objektübersicht](../../../Documentation/Reference/API_CATALOG.md)
