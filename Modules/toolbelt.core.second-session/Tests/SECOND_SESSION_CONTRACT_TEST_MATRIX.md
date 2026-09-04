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
- physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest

## Ausgeführte Provider-Evidenz

- SQL Server 2025 Linux Loopback-RPC-Spike: erfolgreich.
- Workflow: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703841095
- Vollständige Modulmatrix: wird mit dem produktiven Runtime-Workflow nachgeführt.

- SQL Server 2025 Windows, manuelle lokale Validierung vom 2026-08-04: erfolgreich; lokale und zentrale Bereitstellung, Collation-übergreifender Abgleich, Provider-Probe, Contract-, Concurrency-, Central- und Lifecycle-Tests sowie geschützter und vollständiger Uninstall.

- Version 1.1.0 / `@SuppressResult`: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; Provider-Probe, separate SPID, Caller-Rollback, uncommittable Caller, Fehlerrollback, Konkurrenz, zentrales Deployment, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
