# Portable Integer Series

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

**Modul-ID:** `toolbelt.core.generate-series`

**Version:** `1.0.0`

**Implementierung:** `implemented`

**Validierung:** `partially validated`

**Release:** `unreleased`

## Zweck

Das Modul schließt auf SQL Server 2019 und in Datenbanken unter Compatibility
Level 150 die Lücke zur nativen Funktion `GENERATE_SERIES`. Es stellt
portable, typstabile Inline TVFs für `int` und `bigint` bereit.

## Öffentliche Objekte

| Objekt | Typ | Schema | Zweck |
|---|---|---|---|
| `TVF_GenerateSeriesBigInt` | Inline TVF | `toolbelt_core` | gemeinsamer Kern für `bigint`-Reihen |
| `TVF_GenerateSeriesInt` | Inline TVF | `toolbelt_core` | typstabiler `int`-Wrapper über dem Kern |

## Vertrag

- `DEFAULT` oder `NULL` für `@Step`: `+1` aufsteigend, `-1` absteigend.
- Der Startwert wird eingeschlossen.
- Der Stopwert erscheint nur, wenn ihn die Schrittfolge erreicht.
- Eine widersprüchliche Schrittrichtung liefert keine Zeile.
- `NULL` bei Start oder Stop liefert keine Zeile.
- Schritt `0` erzeugt einen unveränderten Enginefehler.
- Es gibt keine garantierte Ergebnisreihenfolge und keine stille Kürzung.
- Version `1.0.0` unterstützt ausschließlich `int` und `bigint`.

Bei User-defined Functions muss für den Defaultparameter ausdrücklich
`DEFAULT` übergeben werden:

```sql
SELECT Value
FROM toolbelt_core.TVF_GenerateSeriesInt(1, 10, DEFAULT)
ORDER BY Value;
```

## Implementierung

Der gemeinsame `bigint`-Kern verwendet binär gestapelte konstante Rowsets und
einen durch die berechnete Zeilenzahl begrenzten Row Goal. Er benötigt weder
rekursive CTEs noch Systemkataloge, persistente Tabellen oder SQL CLR.
`decimal(38,0)` wird nur intern eingesetzt, um Arithmetik an
`bigint`-Grenzen sicher zu berechnen.

Die `int`-Funktion enthält keine zweite Reihenlogik. Sie ruft den Kern auf und
konvertiert dessen bereits typgültige Werte zu `int`.

## Deployment

Aus `Deployment/` im SQLCMD-Modus:

```sql
:setvar DeploymentMode local
:r .\Deploy.sql
```

`DeploymentMode` unterstützt `local` und `central`. Bei zentraler Installation
werden die Funktionen mit dreiteiligem Namen aufgerufen.

## Performance und Größen

Inline TVFs bleiben für den Optimizer sichtbar. Der Vertrag garantiert jedoch
weder einen bestimmten Execution Plan noch feste Cardinality Estimates,
Parallelität oder Laufzeit. Sehr große Reihen können erhebliche CPU-, Speicher-
und Clientkosten erzeugen und bleiben Verantwortung des Aufrufers.

Eine mathematische Zeilenzahl außerhalb des positiven `bigint`-Bereichs wird
nicht gekürzt, sondern führt zu einem unveränderten Engine-Overflow.

## Plattform- und Teststatus

Der
[Generate-Series-Runtime-Lauf 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Er deckt Semantik, native Parität bei 160/170, Fehler und
Typgrenzen, eine Million Werte, einen äußeren Row Goal, Joins, `CROSS APPLY`
sowie lokale, zentrale und Lifecycle-Verträge ab. Der vollständige Adapter
ist am 2026-08-29 zusätzlich auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen
erfolgreich. Windows-Läufe bleiben offen. Der aktuelle Status ist daher
`partially validated`.

## Dokumentation

- [Moduldesign](../../Documentation/Architecture/GENERATE_SERIES_MODULE_DESIGN.md)
- [TVF_GenerateSeriesBigInt](./Documentation/TVF_GenerateSeriesBigInt.md)
- [TVF_GenerateSeriesInt](./Documentation/TVF_GenerateSeriesInt.md)
- [Contract-Testmatrix](./Tests/GENERATE_SERIES_CONTRACT_TEST_MATRIX.md)
- [Test-Evidenz](./Tests/README.md)

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/generate-series-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; vollständiger Moduladapter je Zielversion mit den dort zulässigen Compatibility Levels
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
