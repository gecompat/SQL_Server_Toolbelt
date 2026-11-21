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

Der vollständige [Usage-Skill](../../../Metadata/UsageSkills/toolbelt_core/USP_FinalizeWorkerFailure.md)
steht auch in der kanonischen DDL. `@Hilfe=1` ergänzt die Standardhilfe um
eine vollständige Skillzeile. Fachaufrufe gehören ausschließlich in den
kontrollierten Managedproviderpfad; Transaktions-, Connection-, Token- und
OUTPUT-Regeln stehen im Skill. Kein manueller Dispatch-/Recoveryersatz.

Kein fachliches Resultset.

Hilfe zuerst ohne fachliche Mutation; keine eigenen Debugmessages. Kein fachlicher Resultset und keine ResultTable-/KeepData-Option. Outcome ist ein optionaler OUTPUT; der Hilfezweig überschreibt ihn nicht. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.

Die exakt gebundene Queueentscheidung FAILED/RETRY_WAIT/DEAD_LETTER wird nach bewiesenem Rollback und erneuter Holdprüfung atomar von ManagedReservationId gelöst. Reservations- und Dispositionshistory bleibt erhalten; aktiver Claim, UNKNOWN oder Hold wird damit nie freigegeben. Ein bewiesen beendeter heldfreier Dead Letter kann anschließend über die bestehende manuelle Queue-Requeue-API einen neuen Retryzyklus beginnen.
