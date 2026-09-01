# Execution-Context-Contract-Testmatrix

V0a-Evidenz 2026-08-29: `local: Tests/CI/run-lab-local.ps1` belegt
ausschließlich den im Modulmanifest genannten physischen Linux-Scope; offene
Windows- und modulspezifische Fälle bleiben unberührt.

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
- Windows bleibt bis zu einer tatsächlichen Ausführung `not executed`

## Ausgeführte Evidenz

- SQL Server 2025 Linux, Compatibility Levels 150, 160 und 170: erfolgreich.
- Workflow: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948
- Windows und physische SQL-Server-2019-/2022-Läufe: `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w4a-execution-foundations-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; vollständiger W4a-Moduladapter je Zielversion mit den dort zulässigen Compatibility Levels
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
