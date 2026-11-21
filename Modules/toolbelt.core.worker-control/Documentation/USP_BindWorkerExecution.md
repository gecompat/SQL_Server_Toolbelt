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

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_BindWorkerExecution.md)
steht auch in der kanonischen DDL. `@Hilfe=1` ergänzt die Standardhilfe um
eine vollständige Skillzeile. Fachaufrufe gehören ausschließlich in den
kontrollierten Managedproviderpfad; Transaktions-, Connection-, Token- und
OUTPUT-Regeln stehen im Skill. Kein manueller Dispatch-/Recoveryersatz.

Kein fachliches Resultset.

Hilfe zuerst ohne fachliche Mutation; keine eigenen Debugmessages. Kein fachlicher Resultset und keine ResultTable-/KeepData-Option. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.
