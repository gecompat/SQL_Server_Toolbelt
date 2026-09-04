# Contract-Testmatrix `toolbelt.metadata.identifier`

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Zielmatrix

| Bereich | SQL Server 2019 | SQL Server 2022 | SQL Server 2025 |
|---|---|---|---|
| Compatibility Level 150 | erfolgreich | erfolgreich | erfolgreich |
| Compatibility Level 160 | nicht anwendbar | erfolgreich | erfolgreich |
| Compatibility Level 170 | nicht anwendbar | nicht anwendbar | erfolgreich |
| Windows | erfolgreich | erfolgreich | erfolgreich |
| Linux | erfolgreich | erfolgreich | erfolgreich |

## Pflichtfälle

- öffentliche Objekttypen, Parameter und Resultspalten;
- ein- bis vierteilige Namen und rechtsbündige Zuordnung;
- alle freigegebenen Auslassungsformen;
- Punkte in `[...]` und `]]`-Escape;
- `NULL`, leere Eingabe, äußere Leerzeichen und Steuerzeichen;
- unvollständige/fehlerhafte Klammern und Text nach schließender Klammer;
- mehr als vier Teile sowie 128-/129-Zeichen-Grenze;
- unquoted Metazeichen;
- collation-unabhängige Semantik;
- Scalar-Wrapper und Parserparität;
- lokales/zentrales Deployment, Wiederholung, Kollision und Uninstall.

## Aktuelle Evidenz

Der
[Identifier-Runtime-Lauf 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834)
war auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Prüfungen bleiben
`not executed`; der Modulstatus ist deshalb `partially validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter mit lokalem und zentralem Deployment, Vertrags-, Lifecycle-, Kollisions- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
