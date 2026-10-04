# USP_ReleaseHeldWork

Beginnt ausschließlich nach bewiesenem Rollback eine explizite neue Retryphase; UNKNOWN und COMPLETED bleiben gesperrt.

Öffentliche Steuerfassade.

## Parameter

- `@WorkItemId bigint=NULL`
- `@ExpectedHoldVersion binary(8)=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

WorkItemId bigint NOT NULL; ClaimGeneration bigint NOT NULL; Status varchar(16) NOT NULL; HoldVersion binary(8) NOT NULL

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.
