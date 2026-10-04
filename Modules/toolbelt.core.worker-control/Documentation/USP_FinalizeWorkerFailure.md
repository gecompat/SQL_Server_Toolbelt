# USP_FinalizeWorkerFailure

Konsumiert bewiesenen Rollback und finalisiert expliziten Fail/Retry; frischer Hold oder abgelaufene Lease gewinnt.

Interner attemptgebundener Providerpfad.

## Parameter

- `@SlotReservationId uniqueidentifier=NULL`
- `@ClaimToken uniqueidentifier=NULL`
- `@ExecutionId uniqueidentifier=NULL`
- `@FailureCode varchar(64)=NULL`
- `@Retry bit=0`
- `@Outcome varchar(24) OUTPUT=NULL`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

Kein fachliches Resultset.

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.

Die exakt gebundene Queueentscheidung FAILED/RETRY_WAIT/DEAD_LETTER wird nach bewiesenem Rollback und erneuter Holdprüfung atomar von ManagedReservationId gelöst. Reservations- und Dispositionshistory bleibt erhalten; aktiver Claim, UNKNOWN oder Hold wird damit nie freigegeben. Ein bewiesen beendeter heldfreier Dead Letter kann anschließend über die bestehende manuelle Queue-Requeue-API einen neuen Retryzyklus beginnen.
