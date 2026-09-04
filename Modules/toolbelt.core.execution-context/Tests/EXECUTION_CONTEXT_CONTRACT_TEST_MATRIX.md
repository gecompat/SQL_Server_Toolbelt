# Execution-Context-Contract-Testmatrix

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

- Help ohne Mutation
- Root-Begin mit generierter und expliziter Identität
- Standard-Correlation-ID und explizite Correlation-ID
- Actor/Tenant lesen, ändern und löschen
- verschachtelter Begin mit stabiler Identität und steigendem ScopeDepth
- Ablehnung fremder Execution- oder Correlation-IDs
- End reduziert Tiefe und löscht auf der letzten Ebene alle Sessionwerte
- inline TVF und SVF-Wrapper
- mehrere echte Sessions mit unabhängigen Contexts
- lokales und zentrales Deployment, Wiederholung und Uninstall
- Windows base und Linux latest auf SQL Server 2019/2022/2025 erfolgreich

## Ausgeführte Evidenz

- SQL Server 2025 Linux, Compatibility Levels 150, 160 und 170: erfolgreich.
- Workflow: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948
- Windows und physische SQL-Server-2019-/2022-Läufe: `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Transaktions-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
