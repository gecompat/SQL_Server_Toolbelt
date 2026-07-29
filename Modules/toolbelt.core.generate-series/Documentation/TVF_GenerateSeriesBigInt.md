# toolbelt_core.TVF_GenerateSeriesBigInt

**Typ:** Inline Table-valued Function

**Status:** `implemented`

## Zweck

Erzeugt eine portable `bigint`-Zahlenreihe. Diese Funktion ist zugleich der
gemeinsame Fachkern des Moduls.

## Parameter

| Name | Typ | Nullable | Beschreibung |
|---|---|---:|---|
| `@Start` | `bigint` | ja | erster Wert der Reihe |
| `@Stop` | `bigint` | ja | inklusive Ober- oder Untergrenze, sofern erreichbar |
| `@Step` | `bigint` | ja | Schrittweite; `NULL` beziehungsweise `DEFAULT` löst die Richtung automatisch auf |

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

Erforderlich ist `SELECT` oder `REFERENCES` auf der Funktion. Es gibt keine
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

Die Runtime-Artefakte sind vorhanden, aber noch `not executed`.
