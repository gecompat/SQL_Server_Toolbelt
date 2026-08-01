# Execution Context

## Status

`toolbelt.core.execution-context` Version `1.0.0` ist implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise validiert.

## Vertrag

Ein Root-Aufruf von `USP_BeginExecution` setzt Execution-ID, Correlation-ID, Actor, Tenant, UTC-Startzeit und `ScopeDepth = 1`. Verschachtelte Aufrufe behalten dieselbe Identität und erhöhen nur die Tiefe. `USP_EndExecution` verringert die Tiefe und löscht bei der letzten Ebene alle Toolbelt-Sessionwerte.

`TVF_CurrentExecutionContext` ist die primäre, inline lesbare Schnittstelle. `SVF_CurrentExecutionId` ist nur ein Komfort-Wrapper. Actor und Tenant können über `USP_SetExecutionContext` geändert oder explizit gelöscht werden. Die erwartete Execution-ID schützt vor dem Ändern oder Beenden eines fremden beziehungsweise veralteten Sessionzustands.

Connection-Pooling-Aufrufer müssen jedes erfolgreiche Begin mit End paaren. Das Modul persistiert keinen Zustand außerhalb der Session.

Evidenz: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948
