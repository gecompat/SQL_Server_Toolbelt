# Transactional Work Queue

## Status

`toolbelt.core.work-queue` Version `1.1.0` erweitert den freigegebenen E1a-
Kern um E1b Lease, Heartbeat und explizite Orphan Recovery. Die vollständige
physische Matrix SQL Server 2019, 2022 und 2025 ist unter Windows base und
Linux latest einschließlich Upgrade, Parallelität und Lifecycle erfolgreich.
Das Modul ist `validated`, bleibt aber `unreleased`.

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
- `toolbelt_core.USP_ClaimWork`
- `toolbelt_core.USP_RenewWorkLease`
- `toolbelt_core.USP_RecoverExpiredWork`
- `toolbelt_core.USP_CompleteWork`
- `toolbelt_core.USP_FailWork`
- `toolbelt_core.USP_GetWorkStatus`
- `toolbelt_core.VW_WorkQueue`

`ClaimToken` und `PayloadJson` erscheinen ausschließlich im Claim-Ergebnis,
nicht in Statusabfrage, Recovery-Ausgabe oder View. Die Queue akzeptiert
niemals Raw SQL oder einen Handlernamen aus der Payload.

## Aussagegrenzen

Recovery ist bewusst weder automatisch noch Bestandteil von Claim. Ein alter
Worker kann den fachlichen Seiteneffekt bereits ausgeführt haben, bevor seine
Lease abläuft; sein späteres Complete oder Fail wird abgewiesen. Der Vertrag
ist deshalb At-least-once-fähig, verspricht aber weder Exactly-once noch
generische Idempotenz.

Retry, Backoff, Dead Letter, Idempotency Keys, Cancellation, vollständige
Attempt-Historie, Worker-Orchestrierung und automatisches `KILL` bleiben
außerhalb von E1b. Ein Upgrade von `1.0.0` ist nur ohne aktive E1a-Claims
zulässig und bricht sonst vor der ersten Mutation ab.
