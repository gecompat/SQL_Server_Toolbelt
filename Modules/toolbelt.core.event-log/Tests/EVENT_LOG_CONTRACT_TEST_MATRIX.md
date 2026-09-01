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
- Datum: `2026-08-05`
- Nachweis: `https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410`
- Scope: SQL Server 2025 Linux CL150/160/170; Caller-Rollback, uncommittable Caller, Context, Validation, Retention, Concurrency, Redeploy, Central und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
