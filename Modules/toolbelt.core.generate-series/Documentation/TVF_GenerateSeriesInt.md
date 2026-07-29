# toolbelt_core.TVF_GenerateSeriesInt

**Typ:** Inline Table-valued Function

**Status:** `implemented`

## Zweck

Erzeugt eine portable, `int`-typisierte Zahlenreihe. Die Funktion ist ein
dünner Wrapper über `TVF_GenerateSeriesBigInt` und dupliziert keine
Reihenlogik.

## Parameter

| Name | Typ | Nullable | Beschreibung |
|---|---|---:|---|
| `@Start` | `int` | ja | erster Wert der Reihe |
| `@Stop` | `int` | ja | inklusive Ober- oder Untergrenze, sofern erreichbar |
| `@Step` | `int` | ja | Schrittweite; `NULL` beziehungsweise `DEFAULT` löst die Richtung automatisch auf |

## Resultset

| Ordinal | Spalte | Typ | Beschreibung |
|---:|---|---|---|
| 1 | `Value` | `int` | erreichter Wert der Schrittfolge |

## Semantik

Die Semantik entspricht dem `bigint`-Kern:

- automatische Schrittweite `+1` oder `-1`;
- leere Menge bei falscher Richtung oder `NULL`-Grenzen;
- Enginefehler bei Schritt `0`;
- Start enthalten, Stop nur bei exakter Erreichbarkeit;
- keine garantierte Reihenfolge.

## Verwendung

```sql
SELECT Value
FROM toolbelt_core.TVF_GenerateSeriesInt(2, 10, 3)
ORDER BY Value;
```

Das synthetische Beispiel ergibt `2`, `5` und `8`.

## Rechte, Dependencies und Plattformen

Erforderlich ist `SELECT` oder `REFERENCES` auf der Funktion. Die einzige
interne Abhängigkeit ist der `bigint`-Kern desselben Moduls. Der Provider ist
für SQL Server 2019, 2022 und 2025 auf Windows und Linux vorgesehen.

## Performance und Typstabilität

Als Inline-Wrapper bleibt die Definition für den Optimizer sichtbar. Die
Rückgabespalte ist `int`, damit Joins und `CROSS APPLY` gegen `int`-Spalten
keine unnötige implizite `bigint`-Konvertierung benötigen. Es besteht keine
Plan-, Cardinality- oder Laufzeitgarantie.

## Teststatus

Der
[Generate-Series-Runtime-Lauf 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`; der Modulstatus ist `partially validated`.
