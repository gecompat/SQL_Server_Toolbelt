# TVF_CalendarDifference

`toolbelt_datetime.TVF_CalendarDifference(@StartDate date, @EndDate date)` liefert eine Zeile mit `Sign`, `Years`, `Months` und `Days`. Der Betrag der drei Komponenten ist nicht negativ; nur `Sign` drückt die Richtung aus.

Die Komponenten werden vom früheren zum späteren Datum bestimmt. Eine negative Eingabereihenfolge ändert ausschließlich `Sign`. Bei `NULL` sind alle Spalten `NULL`. Vollständige Einheiten verwenden die Anniversary-Regel: Ein Zielmonat ohne entsprechenden Kalendertag wird auf dessen Monatsende geklammert.

Der Vertrag akzeptiert nur `date`; Uhrzeit, Zeitzone und andere Kalendersysteme gehören nicht zum Scope.

Quelle: [DATEDIFF (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver17).
