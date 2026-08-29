# Teststatus: Date/Time Truncation

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

| Datum | Scope | Ergebnis | Einschränkung |
|---|---|---|---|
| 2026-07-30 | SQL Server 2025 Linux; Compatibility 150/160/170; Contract, native Parität, Wiederholungsdeployment, Lifecycle, Central und Uninstall | `success` | Physische 2019-/2022- und Windows-Läufe offen |
| 2026-08-29 | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | Windows-Läufe offen |

Workflow:
[W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)

Windows-Läufe bleiben bis zur tatsächlichen Ausführung `not executed`.
