# toolbelt_core.TVF_GenerateSeriesBigInt

**Typ:** Inline Table-valued Function

**Status:** `implemented`

## Zweck

Erzeugt eine portable `bigint`-Zahlenreihe. Diese Funktion ist zugleich der
gemeinsame Fachkern des Moduls.

## Parameter

<!-- API_PARAMETERS:BEGIN -->
| Parameter | SQL-Typ | Default | Richtung | Erklärung / Werte |
|---|---|---|---|---|
| `@Start` | `bigint` | `kein Default` | Input | Erster Wert im gesamten SQL-bigint-Bereich; Start wird bei gültiger Richtung eingeschlossen. NULL ergibt keine Zeilen; ein zusätzlich übergebener Schritt 0 bleibt ein Enginefehler. |
| `@Stop` | `bigint` | `kein Default` | Input | Inklusive Zielgrenze im SQL-bigint-Bereich; nur tatsächlich durch ganze Schritte erreichbare Werte werden ausgegeben, kein künstlicher Endwert. NULL ergibt keine Zeilen, außer dem ausdrücklich ungültigen Schritt-0-Fall. |
| `@Step` | `bigint` | `NULL` | Input | Ganzzahlige Schrittweite als bigint. Default/NULL: +1 bei Start &lt;= Stop, sonst -1. Positive Werte laufen aufwärts, negative abwärts; zur Richtung unpassende Grenzen ergeben keine Zeilen. 0 ergibt einen SQL-Engine-Divisionsfehler.Die berechnete Zeilenzahl muss in bigint passen; keine feste kleine Ausgabelimitierung. |
<!-- API_PARAMETERS:END -->

## Resultset

| Ordinal | Spalte | Typ | Beschreibung |
|---:|---|---|---|
| 1 | `Value` | `bigint` | erreichter Wert der Schrittfolge |

## Semantik

- Start kleiner oder gleich Stop: Defaultschritt `+1`.
- Start größer Stop: Defaultschritt `-1`.
- Falsche Richtung oder `NULL` bei Start/Stop: leere Menge.
- Schritt `0`: unveränderter SQL-Enginefehler.
- Der Stopwert wird nicht erzwungen; er erscheint nur bei exakter
  Erreichbarkeit.
- Die Ausgabe besitzt ohne `ORDER BY` keine garantierte Reihenfolge.

Bei gleichzeitiger Schrittweite `0` und `NULL` bei Start oder Stop hat der
Schrittfehler Vorrang.

## Verwendung

```sql
SELECT Value
FROM toolbelt_core.TVF_GenerateSeriesBigInt
(
    CONVERT(bigint, 10),
    CONVERT(bigint, 1),
    DEFAULT
)
ORDER BY Value DESC;
```

## Rechte, Dependencies und Plattformen

Für SELECT-Aufrufe ist `SELECT` auf der Funktion erforderlich. Es gibt keine
Dependency zu einem anderen Toolbelt-Modul. Der T-SQL-Provider ist für SQL
Server 2019, 2022 und 2025 auf Windows und Linux vorgesehen.

## Performance und Grenzen

Binär gestapelte konstante Rowsets und ein `TOP`-Row-Goal begrenzen die
tatsächlich angeforderte Menge. Der Vertrag garantiert keinen konkreten
Execution Plan. Eine mathematische Zeilenzahl größer als `bigint` wird nicht
still gekürzt, sondern löst einen Engine-Overflow aus. Sehr große gültige
Reihen sind vor produktivem Einsatz mit repräsentativen synthetischen oder
ausdrücklich freigegebenen Daten zu messen.

## Teststatus

Der
[Generate-Series-Runtime-Lauf 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`; der Modulstatus ist `partially validated`.

## Technischer Lösungsweg

[Grundlage, Verarbeitungsschritte und Designgründe](../../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#zahlenreihen).
