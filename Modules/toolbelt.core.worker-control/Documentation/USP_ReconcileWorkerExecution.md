# USP_ReconcileWorkerExecution

Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay.

Öffentliche Steuerfassade.

## Parameter

- `@SlotReservationId uniqueidentifier=NULL`
- `@ExpectedHoldVersion binary(8)=NULL`
- `@ResultTable sysname=NULL`
- `@KeepData bit=0`
- `@Debug tinyint=0`
- `@Hilfe bit=0`

## Ergebnis

SlotReservationId uniqueidentifier NOT NULL; Outcome varchar(24) NOT NULL; Occupied bit NOT NULL

Hilfe zuerst ohne Mutation, Debug nur Messages. ResultTable atomar nach kanonischem Vertrag. Bestehende Rechte, keine Grants. Fehler54210..54239 und unveränderte Engine-/Queuefehler. Sourcevorbereitung: not executed, unreleased.

Der Witnessnachweis verwendet UPDLOCK und HOLDLOCK (serialisierbarer Schlüssel-/Absencebereich) innerhalb der kurzen Reconciletransaktion. Dadurch wird auch bei RCSI keine ältere Snapshotversion als Rollbacknachweis verwendet. Der Attemptsessionlock und dieser Bereichsschutz bleiben bis zum Commit bestehen. READCOMMITTEDLOCK wird nicht zusätzlich kombiniert, weil er HOLDLOCK widerspricht.

Der interne Locktimeout wird mit einem SQL2019-kompatiblen Literal ausschließlich im Stored-Procedure-Scope gesetzt. SQL Server restauriert die SET-Option beim Return oder THROW im Aufruferkontext; variable Restore-SETs und dynamische Restoreversuche werden nicht verwendet. Die Basicfixture prüft tatsächlich Caller1234 nach Erfolg und Fehler. Grundlage: [Microsoft SET Statements](https://learn.microsoft.com/en-us/sql/t-sql/statements/set-statements-transact-sql?view=sql-server-ver17). Laufzeitqualifikation dieser USPs bleibt bis erfolgreichem Test offen.
