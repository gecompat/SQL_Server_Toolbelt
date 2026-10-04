# USP_RecordWorkerUnknown

Persistiert Unsicherheit und lässt die Reservation belegt; kein Replay oder Slotfreigabe.

Interner attemptgebundener Providerpfad.

## Parameter

- `@SlotReservationId uniqueidentifier=NULL`
- `@WorkerToken uniqueidentifier=NULL`
- `@ExecutionId uniqueidentifier=NULL`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

Kein fachliches Resultset.

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.
