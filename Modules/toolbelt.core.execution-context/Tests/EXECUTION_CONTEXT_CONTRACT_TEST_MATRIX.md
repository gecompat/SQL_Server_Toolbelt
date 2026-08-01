# Execution-Context-Contract-Testmatrix

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

