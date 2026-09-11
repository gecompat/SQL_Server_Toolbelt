# Öffentliche Objekte: Cooperative Execution Cancellation

## `TVF_ExecutionCancellationStatus`

Liefert für eine `ExecutionId` keine oder genau eine sichere Statuszeile mit
`ExecutionId`, `IsCancellationRequested` und `RequestedAtUtc`. Grund,
anfordernde Identität, Claim-Tokens, Payloads, Sessions und Fehlerdaten sind
nicht sichtbar.

## `SVF_IsCancellationRequested`

Liefert `1`, wenn für die übergebene `ExecutionId` eine persistierte
Cancellation-Anforderung existiert, andernfalls `0`. Der Wrapper eignet sich
für kleine Worker-Checkpoints.

## `USP_RequestExecutionCancellation`

Nimmt optional eine `ExecutionId` und einen höchstens 512 Zeichen langen,
nicht sensiblen Grund entgegen. Ohne ID verwendet die Procedure die aktuelle
ExecutionId aus `toolbelt.core.execution-context`. Wiederholte Anforderungen
lassen den ersten Auditzeitpunkt und Grund unverändert. Die Procedure liefert
kein fachliches Resultset; der Status wird über die TVF abgefragt.

Der Aufruf benötigt eine Session ohne aktive Transaktion. Fehler `52600` bis
`52604` bezeichnen Parameter-, Context- oder Transaktionsfehler. Die Procedure
führt weder `KILL` aus noch requeued oder terminalisiert sie Work-Queue-Items.

```sql
EXEC toolbelt_core.USP_RequestExecutionCancellation
    @CancellationReason = N'planned maintenance';

SELECT *
FROM toolbelt_core.TVF_ExecutionCancellationStatus
    (toolbelt_core.SVF_CurrentExecutionId());
```
