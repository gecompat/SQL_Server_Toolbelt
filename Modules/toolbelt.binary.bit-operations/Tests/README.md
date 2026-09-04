# Teststatus: Bigint Bit Operations

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

| Datum | Scope | Ergebnis | Einschränkung |
|---|---|---|---|
| 2026-07-30 | SQL Server 2025 Linux; Compatibility 150/160/170; alle fünf Operationen, native Parität, Wiederholungsdeployment, Lifecycle, Central und Uninstall | `success` | Physische 2019-/2022- und Windows-Läufe offen |
| 2026-08-29 | Physische SQL-Server-2019-, 2022- und 2025-Linux-Ziele; vollständiger Moduladapter | `success` | Windows-Läufe offen |

Workflow:
[W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509)

Windows-Läufe bleiben bis zur tatsächlichen Ausführung `not executed`. Der
Binary-Slice ist nicht Teil dieses Moduls.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger Moduladapter einschließlich nativer Parität, Kollisionsschutz, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
