# USP_StopWorkerExecution

Persistiert generationgebunden Stop und Hold vor Providerabbruch; Completiongewinner bleibt committed.

Öffentliche Steuerfassade.

## Parameter

- `@SlotReservationId uniqueidentifier=NULL`
- `@ExpectedClaimGeneration bigint=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

SlotReservationId uniqueidentifier NOT NULL; ExecutionId uniqueidentifier NOT NULL; StopStatus varchar(24) NOT NULL; HoldVersion binary(8) NOT NULL

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.
