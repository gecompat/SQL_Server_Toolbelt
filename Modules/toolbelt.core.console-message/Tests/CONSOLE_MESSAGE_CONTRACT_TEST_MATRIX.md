# Contract-Testmatrix: Console Message

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Bereich | Pflichtfall | Status |
|---|---|---|
| API | Objektart, Parameter, Reihenfolge und Typen | `success` – Run 30573135975 |
| Help | vollständige Sections; keine Payload- oder Debug-Ausgabe | `success` – Run 30573135975 |
| Resultset | normale Ausführung ohne fachliches Resultset | `success` – Run 30573135975 |
| NULL/Leertext | keine Ausgabe, `RETURN 0` | `success` – Run 30573135975 |
| PRINT | mehr als 8.000 Unicode-Zeichen vollständig gechunked | `success` – Run 30573135975 |
| NOWAIT | mehr als 4.000 Unicode-Zeichen, `%` als Payload | `success` – Run 30573135975 |
| Unicode | Supplementary Character an Chunkgrenze | `success` – Run 30573135975 |
| Zeilen | CRLF-Reihenfolge im Payload | `success` – Run 30573135975 |
| Lifecycle | Erstinstallation, Wiederholung, Central, Uninstall | `success` – Run 30573135975 |
| Project Adapter 0.1 | Install, versionsgleiches Update, Modul-/Help-Validierung, markergebundener Cleanup | `success` – `local: SQL_Server_Lab Project Adapter 0.1`; SQL Server 2025 Linux unter Docker und Podman, 2026-08-30 |
| Matrix | SQL Server 2025 Linux, Compatibility 150/160/170 | `success` – [Run 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975) |
| Release | physische SQL Server 2019/2022 und Windows | `not executed` |

Client-Pufferung und optische Frame-Darstellung werden nicht allein durch
einen erfolgreichen Engine-Test als plattformübergreifend bewiesen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-30`
- Nachweis: `local: SQL_Server_Lab Project Adapter 0.1`
- Scope: SQL Server 2025 Linux unter Docker und Podman; Installation, versionsgleiches Update, Modul-/Help-Validierung, markergebundener Uninstall und vollständiger scopegebundener Cleanup
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
