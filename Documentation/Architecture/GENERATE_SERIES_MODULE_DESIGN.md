# Moduldesign für portable Ganzzahlreihen

## Status und Freigabe

| Feld | Wert |
|---|---|
| Kandidat | `TC-2026-006` |
| Modul | `toolbelt.core.generate-series` |
| Version | `1.0.0` |
| Vertrag besprochen | 2026-07-30 |
| Implementierung freigegeben | 2026-07-30 durch ausdrückliches `.` des Benutzers |
| Provider | portable T-SQL Inline TVFs |

## Zweck und Grenze

Das Modul stellt auf SQL Server 2019, 2022 und 2025 denselben Vertrag für
Ganzzahlreihen bereit. Typische Einsätze sind Kalendergrundlagen,
Datenexpansion, synthetische Tests, Joins und `CROSS APPLY`.

Version `1.0.0` unterstützt ausschließlich `int` und `bigint`. Dezimaltypen,
Datumsreihen, persistente Numbers-Tabellen, SQL CLR und eine garantierte
Sortierung liegen außerhalb des Scopes.

## Öffentlicher Vertrag

```text
TVF_GenerateSeriesInt(@Start int, @Stop int, @Step int = NULL)
    -> TABLE(Value int)

TVF_GenerateSeriesBigInt(@Start bigint, @Stop bigint, @Step bigint = NULL)
    -> TABLE(Value bigint)
```

- `NULL` beziehungsweise `DEFAULT` für `@Step` ergibt `+1`, wenn
  `@Start <= @Stop`, sonst `-1`.
- Der Startwert ist enthalten.
- Der Stopwert ist nur enthalten, wenn ihn die Schrittfolge exakt erreicht.
- Eine Schrittweite mit falscher Richtung liefert eine leere Menge.
- `NULL` bei `@Start` oder `@Stop` liefert eine leere Menge.
- Schrittweite `0` erzeugt einen unveränderten SQL-Enginefehler. Dieser Fehler
  hat Vorrang vor dem leeren `NULL`-Vertrag.
- Die Funktion verspricht keine Ergebnisreihenfolge. Aufrufer verwenden
  `ORDER BY Value`, wenn eine Reihenfolge erforderlich ist.
- Es gibt kein konfiguriertes oder stilles Row-Limit.

User-defined Functions verlangen beim Aufruf eines Defaultparameters das
Schlüsselwort `DEFAULT`; der dritte Parameter kann nicht einfach entfallen.

## Provider- und Typentscheidung

`TVF_GenerateSeriesBigInt` enthält den einzigen fachlichen Kern. Binär
gestapelte konstante Rowsets stellen die logische Quellmenge bereit; ein
zeilenzahlgesteuerter `TOP` erzeugt den Row Goal. Die Zwischenmenge wird nicht
materialisiert. `decimal(38,0)` schützt ausschließlich interne Differenz-,
Betrags- und Multiplikationsschritte vor `bigint`-Überlauf.

`TVF_GenerateSeriesInt` ist ein dünner Inline-Wrapper. Er verwendet den
`bigint`-Kern und konvertiert das Resultset kontrolliert zu `int`. Damit bleibt
die Fachlogik einmalig, während Joins gegen `int`-Spalten keine unnötige
implizite `bigint`-Konvertierung erhalten.

Eine rekursive CTE wurde wegen `MAXRECURSION`- und Skalierungsgrenzen
verworfen. Systemkataloge sind keine stabile Zahlenquelle. Eine persistente
Numbers-Tabelle würde Speicher, Kapazitätsplanung, Pflege und erstmals eine
Tabellennamensentscheidung erfordern. SQL CLR besitzt für diesen rein
relationalen Vertrag keinen belegten Vorteil.

## Größen-, Overflow- und Performancevertrag

Das Modul kürzt Reihen nicht. Wenn die mathematische Zeilenzahl selbst den
positiven `bigint`-Bereich überschreitet, erzeugt die interne Konvertierung
einen unveränderten Engine-Overflow, bevor eine unvollständige Reihe geliefert
werden kann. Diese Enginegrenze ist kein konfigurierbares Modul-Limit.

Sehr große gültige Reihen bleiben Verantwortung des Aufrufers. Inline TVFs
halten die relationale Definition für den Optimizer sichtbar, garantieren aber
weder einen konkreten Execution Plan noch eine feste Cardinality Estimate,
Parallelität, Laufzeit oder Speicherbelegung. Ein erfolgreicher Lauf mit einer
Million Zeilen ist Contract-Evidenz, kein Produktionsbenchmark.

## Native Referenz und Portabilität

SQL Server 2022 und 2025 stellen `GENERATE_SERIES` grundsätzlich ab
Compatibility Level 160 bereit. Die dokumentierte Database-scoped
Configuration `ALLOW_BUILTIN_TVF_IN_ALL_COMPAT_LEVELS` kann diese Grenze
derzeit in Azure SQL Database und Fabric SQL Database aufheben; sie ist keine
SQL-Server-2025-Capability und erweitert nicht den Supportscope dieses Moduls.
Die native Funktion wird im regulären Testscope nur bei Levels 160 und 170 als
Semantikorakel verwendet. Der Runtime-Provider des Moduls bleibt auf allen
Zielversionen und Compatibility Levels derselbe portable T-SQL-Code.

## Abhängigkeiten und Lifecycle

Das Modul besitzt keine Dependency zu anderen Toolbelt-Modulen.
`TVF_GenerateSeriesInt` hängt innerhalb desselben Release-Manifests vom
`bigint`-Kern ab. Deploy legt deshalb zuerst den Kern und dann den Wrapper an;
Uninstall entfernt sie in umgekehrter Reihenfolge.

Lokales und zentrales Deployment verwenden dieselben Source-Artefakte.
Zentrale Aufrufe erfolgen mit dreiteiligem Namen.

## Primärquellen

- [GENERATE_SERIES (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/generate-series-transact-sql?view=sql-server-ver17)
- [CREATE FUNCTION (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver17)
- [Create user-defined functions](https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine?view=sql-server-ver17)
- [TOP (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/queries/top-transact-sql?view=sql-server-ver17)
