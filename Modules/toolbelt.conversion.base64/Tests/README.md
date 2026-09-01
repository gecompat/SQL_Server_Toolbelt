# Base64-Testevidenz

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

## Aktueller Stand

| Datum | Prüfung | Scope | Ergebnis | Einschränkung |
|---|---|---|---|---|
| 2026-08-29 | lokales SQL_Server_Lab | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | Windows-Läufe bleiben `not executed` |
| 2026-07-30 | [Run 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837) | Version `1.1.0`; Compatibility 150/160/170; SVF-/TVF-Parität, `APPLY`, Fehler, Größen bis 1 MiB, Upgrade, lokale/zentrale Nutzung, Kollision und Lifecycle | `success` | Physische 2019-/2022- und Windows-Läufe bleiben `not executed` |
| 2026-07-29 | [Base64 Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/base64-runtime.yml) | Workflow, statische und Runtime-Contract-Artefakte angelegt | `not executed` | Ein vorhandener Workflow ist kein Runtime-Nachweis |
| 2026-07-29 | [Run 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673) | SQL Server 2025 Linux; Compatibility 150/160/170; RFC-4648, Fehler, Größen bis 1 MiB, lokale/zentrale Nutzung und Lifecycle | `success` | Physische 2019-/2022- und Windows-Läufe bleiben `not executed` |

Der Modulstatus ist damit `partially validated`, nicht vollständig
`validated`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/base64-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; vollständiger Moduladapter je Zielversion mit den dort zulässigen Compatibility Levels
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
