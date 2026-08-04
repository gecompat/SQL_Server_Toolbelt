# Second-Session-Contract-Testmatrix

- Providerkonfiguration nur für vorhandenen Linked Server
- `rpc out = true`
- `remote proc transaction promotion = false`
- echter Probe auf dieselbe Datenbank mit anderer `@@SPID`
- keine Linked-Server-/Login-/Credential-Erzeugung im Modul-Lifecycle
- Work-Type-Auflösung ohne Raw SQL
- Handler-Modi `NONE` und `JSON_PAYLOAD`
- exakte Handler-Signaturprüfung
- Remote-Principal benötigt `EXECUTE`
- Execution-/Correlation-ID, Actor und Tenant in der Remote-Session
- synchroner Handler-Returncode
- `WITH RESULT SETS NONE`
- Remote-Transaktionsrollback bei Handlerfehler
- Remote-Commit überlebt normalen Caller-Rollback
- Remote-Commit aus `XACT_STATE() = -1`
- direkte Ausgabe in uncommittable Caller
- ResultTable Replace/Append nur in committablem Zustand
- Providerdrift wird vor Ausführung abgelehnt
- vier parallele Second-Session-Aufrufe
- Redeploy erhält Providerkonfiguration
- lokales und zentrales Deployment
- Data-Loss-geschützter Uninstall
- Windows und physische SQL-Server-2019-/2022-Läufe bleiben `not executed`

## Ausgeführte Provider-Evidenz

- SQL Server 2025 Linux Loopback-RPC-Spike: erfolgreich.
- Workflow: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703841095
- Vollständige Modulmatrix: wird mit dem produktiven Runtime-Workflow nachgeführt.
