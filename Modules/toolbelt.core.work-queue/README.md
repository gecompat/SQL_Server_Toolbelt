# Transactional Work Queue

## Status

`toolbelt.core.work-queue` Version `2.0.0` ergänzt den E1a-/E1b-Kern um
persistierte Retry-Policies, Dead Letter, Idempotency Keys sowie priorisierte
gruppenbezogene Drain-Barriers. Das Modul bleibt `unreleased`.

Evidenz: `local: Tests/CI/run-lab-local.ps1`.

## Zweck

Das Modul reiht Aufträge für registrierte Work Types ein, beansprucht sie
atomar für eine begrenzte Lease und schließt sie mit einem nicht erratbaren
Claim-Token als `COMPLETED` oder `FAILED` ab. Heartbeats verlängern nur eine
noch aktive Lease. Eine ausdrückliche Recovery setzt abgelaufene Claims auf
`QUEUED` zurück und invalidiert das bisherige Token. Die interne Tabelle ist
kein öffentlicher DML-Vertrag.

## Öffentliche Objekte

- `toolbelt_core.USP_EnqueueWork`
- `toolbelt_core.USP_EnqueueWorkWithPolicy`
- `toolbelt_core.USP_EnqueueBarrierWork`
- `toolbelt_core.USP_ClaimWork`
- `toolbelt_core.USP_RenewWorkLease`
- `toolbelt_core.USP_RecoverExpiredWork`
- `toolbelt_core.USP_CompleteWork`
- `toolbelt_core.USP_FailWork`
- `toolbelt_core.USP_ScheduleWorkRetry`
- `toolbelt_core.USP_RequeueDeadLetter`
- `toolbelt_core.USP_GetWorkStatus`
- `toolbelt_core.VW_WorkQueue`
- `toolbelt_core.VW_WorkQueueBarrierBlockers`

`ClaimToken` und `PayloadJson` erscheinen ausschließlich im Claim-Ergebnis,
nicht in Statusabfrage, Recovery-Ausgabe oder View. Die Queue akzeptiert
niemals Raw SQL oder einen Handlernamen aus der Payload.

## Aussagegrenzen

Recovery ist bewusst weder automatisch noch Bestandteil von Claim. Ein alter
Worker kann den fachlichen Seiteneffekt bereits ausgeführt haben, bevor seine
Lease abläuft; sein späteres Complete oder Fail wird abgewiesen. Der Vertrag
ist deshalb At-least-once-fähig, verspricht aber weder Exactly-once noch
generische Idempotenz.

Retry erfolgt ausschließlich durch Workerentscheidung oder Orphan-Recovery;
`USP_FailWork` bleibt terminal. Ein Idempotency Key ist pro Work Type über die
Lebenszeit des Items eindeutig. Barriers sperren nur ihre ExecutionGroup,
warten auf den beim Enqueue gespeicherten Claim-Snapshot und präemptieren
niemals laufende Arbeit. Cancellation, Worker-Orchestrierung, Erkennung von
Systemzuständen und Log-Shrink bleiben außerhalb des Moduls. Ein Upgrade von
`1.0.0` oder `1.1.0` ist nur ohne aktive Claims zulässig.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-08-30`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: E1b auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest; Lease, Heartbeat, explizite Recovery, abgelaufene Ownership, Upgrade 1.0.0 auf 1.1.0, blockierter Upgrade-Preflight bei aktivem Claim, Transaktionen, vier Sessions, ResultTable, Dependency, Kollision, Redeployment, Central, Datenverlustschutz, Uninstall und Cleanup
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
