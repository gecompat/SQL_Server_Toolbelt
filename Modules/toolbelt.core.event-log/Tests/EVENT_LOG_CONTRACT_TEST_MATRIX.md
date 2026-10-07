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
- zusätzlicher befüllter `RepeatCurrent` mit zwei echten Deploys: `not executed`
- alle 24 Eventspalten einschließlich NULL/Leerstring, Unicode/Padding und 100-ns-Auditwerten
- gelöschter Identityhöchstwert und nächster regulärer Insert ohne Reseed
- EventLog ohne rowversion; fremde WorkType-Zeilen einschließlich Rowversion unverändert
- explizite öffentliche Register-/Disable-Fixture: erste kanonische Reaktivierung mit neuer Rowversion, zweiter exakter No-op
- stabile eigene WorkType-ID/Created-Audits, kanonische Konfiguration und erwartete Modified-/Disabled-Audits
- ausgewählte Katalog-/Definitions-/Parametermetadaten und vorhandene Permissions ohne neue Grants
- typisierte Tabellen-/Spaltenannotation und `MS_Description` unverändert, Cleanup nur eigener Fixtureartefakte
- lokale und zentrale Installation
- Uninstall verweigert stillen Datenverlust und entfernt den eigenen Work Type
- physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; Provider-Probe, Caller-Rollback, uncommittable Caller, Kontext, Validierung, Retention, Konkurrenz, zentrales Deployment, Lifecycle und Uninstall
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
