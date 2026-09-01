# Contract-Testmatrix `toolbelt.metadata.identifier`

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

## Zielmatrix

| Bereich | SQL Server 2019 | SQL Server 2022 | SQL Server 2025 |
|---|---|---|---|
| Compatibility Level 150 | `not executed` | `not executed` | erfolgreich |
| Compatibility Level 160 | nicht anwendbar | `not executed` | erfolgreich |
| Compatibility Level 170 | nicht anwendbar | nicht anwendbar | erfolgreich |
| Windows | `not executed` | `not executed` | `not executed` |
| Linux | `not executed` | `not executed` | `partially validated` |

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
- Datum: `2026-08-29`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Lokales SQL_Server_Lab; physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter mit lokalen, zentralen, Lifecycle- und Uninstall-Verträgen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
