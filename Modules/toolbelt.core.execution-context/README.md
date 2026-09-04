# Execution Context

Vollständige Plattform-Evidenz 2026-09-01: `local: Tests/CI/run-lab-local.ps1` belegt den erfolgreichen Moduladapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. Dieser Nachweis ersetzt frühere offene oder `not executed`-Aussagen; datierte ältere Einträge bleiben als historische Evidenz erhalten.

## Status

`toolbelt.core.execution-context` Version `1.0.0` ist implementiert und auf SQL Server 2019/2022/2025 unter Windows base und Linux latest `validated`.

## Vertrag

Ein Root-Aufruf von `USP_BeginExecution` setzt Execution-ID, Correlation-ID, Actor, Tenant, UTC-Startzeit und `ScopeDepth = 1`. Verschachtelte Aufrufe behalten dieselbe Identität und erhöhen nur die Tiefe. `USP_EndExecution` verringert die Tiefe und löscht bei der letzten Ebene alle Toolbelt-Sessionwerte.

`TVF_CurrentExecutionContext` ist die primäre, inline lesbare Schnittstelle. `SVF_CurrentExecutionId` ist nur ein Komfort-Wrapper. Actor und Tenant können über `USP_SetExecutionContext` geändert oder explizit gelöscht werden. Die erwartete Execution-ID schützt vor dem Ändern oder Beenden eines fremden beziehungsweise veralteten Sessionzustands.

Connection-Pooling-Aufrufer müssen jedes erfolgreiche Begin mit End paaren. Das Modul persistiert keinen Zustand außerhalb der Session.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948
sowie der erfolgreiche physische Linux-Lauf 2019/2022/2025 vom 2026-08-29.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-09-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL-Server-2019-, 2022- und 2025-Ziele unter Windows base und Linux latest; vollständiger W4-Moduladapter mit lokalem und zentralem Deployment, Transaktions-, Lifecycle- und Uninstall-Tests
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
