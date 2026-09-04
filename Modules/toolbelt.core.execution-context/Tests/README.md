# Execution-Context-Testevidenz

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

Der statische Vertrag sowie Root-/Nested-Context, Ownership, Actor/Tenant-Änderung, Multi-Session-Isolation, Lifecycle, Central und Uninstall sind auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948

Windows und die physischen SQL-Server-2019-/2022-Releaseprüfungen bleiben bis zur tatsächlichen Ausführung `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Transaktions-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
