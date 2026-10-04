# USP_BindWorkerExecution

Bindet genau eine frische tatsächliche Handlerconnection vor Dispatch; kein Rebind.

Interner attemptgebundener Providerpfad.

## Parameter

- `@SlotReservationId uniqueidentifier=NULL`
- `@WorkerId uniqueidentifier=NULL`
- `@WorkerGeneration bigint=NULL`
- `@WorkerToken uniqueidentifier=NULL`
- `@ClaimGeneration bigint=NULL`
- `@ClaimToken uniqueidentifier=NULL`
- `@ExecutionId uniqueidentifier=NULL`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

Kein fachliches Resultset.

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.
