# USP_ClaimWorkerWork

Fachliche Fassade der privaten atomaren Managed-Admission.

Öffentliche Steuerfassade.

## Parameter

- `@WorkerId uniqueidentifier=NULL`
- `@WorkerGeneration bigint=NULL`
- `@WorkerToken uniqueidentifier=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

WorkItemId bigint NOT NULL; WorkTypeName varchar(128) NOT NULL; PayloadJson nvarchar(max) NULL; ClaimToken uniqueidentifier NOT NULL; ClaimedAtUtc datetime2(7) NOT NULL; ClaimGeneration bigint NOT NULL; LeaseUntilUtc datetime2(7) NOT NULL; LastHeartbeatAtUtc datetime2(7) NOT NULL; SlotReservationId uniqueidentifier NOT NULL; ExecutionId uniqueidentifier NOT NULL

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.
