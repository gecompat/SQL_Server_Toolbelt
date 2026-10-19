# Contract-Testmatrix: Console Message

Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` war auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest erfolgreich; zusätzliche Client-/Treiber-, Buffering- und Framing-Evidenz war damals offen. Der damalige Modulstatus war `partially validated`. Dieser Nachweis ersetzt frühere offene Windows-Aussagen; datierte ältere Einträge bleiben historische Evidenz.

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
| Release-Fachmatrix | physische SQL Server 2019/2022/2025 unter Windows und Linux | `success` – Nachqualifikation 2026-10-19; Veröffentlichung `unreleased` |

Client-Pufferung und optische Frame-Darstellung werden nicht allein durch
einen erfolgreichen Engine-Test als plattformübergreifend bewiesen.

Nachtrag 2026-10-19: Die zusätzliche ADO.NET-`InfoMessage`-Prüfung auf allen
sechs Windows-/Linux-Zielkombinationen ist erfolgreich; Details und Aufruf
stehen in [Tests/README.md](./README.md#clientprüfung-2026-10-19).
NOWAIT-Empfang wird als Beobachtung erfasst, nicht als garantierte
Clientlatenz. Die zusätzliche Clientprüfung ist für ADO.NET und ODBC/sqlcmd
abgedeckt; weitere Clients und visuelle SSMS-Darstellung sind nicht belegt
und werden nicht als allgemeine Enginezusage ausgegeben.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-19`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019/2022/2025 unter Windows mit freigegebenen CU-Äquivalenten zu base und Linux latest; vollständiger lokaler/zentraler Moduladapter, versionsabhängige CL150/160/170, Lifecycle und Uninstall; Security-Grenzen und ODBC/sqlcmd-Ausgabe; zusätzlich run-console-clients-lab.ps1 mit ADO.NET-Frames, Unicode, atomarer Ablehnung und NOWAIT-Beobachtung auf allen sechs Zielen
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
