# Generate-Series-Testevidenz

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

## Aktueller Stand

| Datum | Prüfung | Scope | Ergebnis | Einschränkung |
|---|---|---|---|---|
| 2026-08-29 | lokales SQL_Server_Lab | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | Windows-Läufe bleiben `not executed` |
| 2026-07-30 | [Generate-Series Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/generate-series-runtime.yml) | Workflow, statische und Runtime-Contract-Artefakte angelegt | `not executed` | Ein vorhandener Workflow ist kein Runtime-Nachweis |
| 2026-07-30 | [Generate-Series Runtime Run 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324) | SQL Server 2025 Linux; Compatibility Levels 150/160/170; Semantik, native Parität, Fehler, Grenzen, eine Million Werte, Row Goal, Join, `CROSS APPLY`, lokale, zentrale und Lifecycle-Contracts | `success` | Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben offen |

Die erfolgreiche physische Linux-Matrix belässt den Modulstatus auf
`partially validated`. Für `validated` fehlen weiterhin die gezielten
Windows-Läufe und modulspezifischen Releasefälle.
