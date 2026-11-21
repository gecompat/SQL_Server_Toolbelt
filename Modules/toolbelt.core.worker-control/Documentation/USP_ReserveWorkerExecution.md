# USP_ReserveWorkerExecution

Reserviert global und lokal atomar genau einen kanonischen Queueclaim; keine zweite Claimauswahl.

Interner attemptgebundener Providerpfad.

## Parameter

- `@WorkerId uniqueidentifier=NULL`
- `@WorkerGeneration bigint=NULL`
- `@WorkerToken uniqueidentifier=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_ReserveWorkerExecution.md)
steht auch in der kanonischen DDL. `@Hilfe=1` ergänzt die Standardhilfe um
eine vollständige Skillzeile. Fachaufrufe gehören ausschließlich in den
kontrollierten Managedproviderpfad; Transaktions-, Connection-, Token- und
OUTPUT-Regeln stehen im Skill. Kein manueller Dispatch-/Recoveryersatz.

WorkItemId bigint NOT NULL; WorkTypeName varchar(128) NOT NULL; PayloadJson nvarchar(max) NULL; ClaimToken uniqueidentifier NOT NULL; ClaimedAtUtc datetime2(7) NOT NULL; ClaimGeneration bigint NOT NULL; LeaseUntilUtc datetime2(7) NOT NULL; LastHeartbeatAtUtc datetime2(7) NOT NULL; SlotReservationId uniqueidentifier NOT NULL; ExecutionId uniqueidentifier NOT NULL

Hilfe zuerst ohne fachliche Mutation; keine eigenen Debugmessages. Null oder eine geheime Claim-/Reservationszeile; optionales ResultTable-Routing liegt in derselben Admissiontransaktion. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.

Der private Managedclaimtransport verwendet ausschließlich die aus dem kanonischen UPDATE OUTPUT entstandene Claim-ID. Reserve liest diese ID mit exakter ManagedReservationId im selben Admission-TX in den festen internen Transport. Öffentliche ResultTable-Namen bleiben unverändert validiert; kein SkipValidation und kein INSERT EXEC wird verwendet.
