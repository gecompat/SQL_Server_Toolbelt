# Base64-Testevidenz

## Aktueller Stand

| Datum | Prüfung | Scope | Ergebnis | Einschränkung |
|---|---|---|---|---|
| 2026-07-30 | [Run 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837) | Version `1.1.0`; Compatibility 150/160/170; SVF-/TVF-Parität, `APPLY`, Fehler, Größen bis 1 MiB, Upgrade, lokale/zentrale Nutzung, Kollision und Lifecycle | `success` | Physische 2019-/2022- und Windows-Läufe bleiben `not executed` |
| 2026-07-29 | [Base64 Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/base64-runtime.yml) | Workflow, statische und Runtime-Contract-Artefakte angelegt | `not executed` | Ein vorhandener Workflow ist kein Runtime-Nachweis |
| 2026-07-29 | [Run 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673) | SQL Server 2025 Linux; Compatibility 150/160/170; RFC-4648, Fehler, Größen bis 1 MiB, lokale/zentrale Nutzung und Lifecycle | `success` | Physische 2019-/2022- und Windows-Läufe bleiben `not executed` |

Der Modulstatus ist damit `partially validated`, nicht vollständig
`validated`.
