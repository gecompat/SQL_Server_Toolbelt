# Contract-Testmatrix `toolbelt.metadata.identifier`

## Zielmatrix

| Bereich | SQL Server 2019 | SQL Server 2022 | SQL Server 2025 |
|---|---|---|---|
| Compatibility Level 150 | `not executed` | `not executed` | geplant |
| Compatibility Level 160 | nicht anwendbar | `not executed` | geplant |
| Compatibility Level 170 | nicht anwendbar | nicht anwendbar | geplant |
| Windows | `not executed` | `not executed` | `not executed` |
| Linux | `not executed` | `not executed` | geplant |

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

Der Workflow
[Identifier Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/identifier-runtime.yml)
und die synthetischen Contract-Tests sind vorhanden. Eine Runtime-Ausführung
hat für diesen Stand noch nicht stattgefunden; der Status bleibt
`not executed`.
