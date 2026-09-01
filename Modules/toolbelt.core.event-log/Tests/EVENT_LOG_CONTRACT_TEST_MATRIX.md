# Event-Log-Contract-Testmatrix

- kanonischer EventName und erlaubte Level
- begrenztes JSON-Objekt, Message- und Fehlerwerte
- resultsetfreier synchroner Write-Vertrag
- getrennte Remote-Session
- expliziter und aktiver Execution Context
- Remote-Commit überlebt Caller-Rollback
- Remote-Commit aus `XACT_STATE() = -1`
- Handler- und Providerfehler werden weitergegeben
- begrenzte Retention mit Savepoint-Vertrag
- vier parallele Caller-Sessions
- Redeploy erhält Events und Work-Type-Registrierung
- lokale und zentrale Installation
- Uninstall verweigert stillen Datenverlust und entfernt den eigenen Work Type
- Windows und physische SQL-Server-2019-/2022-Läufe bleiben `not executed`

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/workflows/w5b-event-log-runtime.yml`
- Scope: GitHub-hosted Linux-Matrix SQL Server 2019, 2022 und 2025; erstmals auf allen drei Zielversionen erfolgreich, nachdem der Testadapter den Loopback-Provider versionsabhängig konfiguriert
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
