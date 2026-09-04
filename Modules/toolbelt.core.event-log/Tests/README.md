# Event-Log-Testevidenz

Statischer Vertrag sowie SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Caller-Rollback, uncommittable Caller, Context, Validierung, Retention, Concurrency, Redeploy, Central und Uninstall sind erfolgreich.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

Der lokale physische Linux-Lauf vom 2026-08-29 war auf SQL Server 2025
erfolgreich, scheiterte aber auf SQL Server 2019 und 2022 im gemeinsamen
W5-Vertrag. Windows-Läufe bleiben `not executed`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; Provider-Probe, Caller-Rollback, uncommittable Caller, Kontext, Validierung, Retention, Konkurrenz, zentrales Deployment, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
