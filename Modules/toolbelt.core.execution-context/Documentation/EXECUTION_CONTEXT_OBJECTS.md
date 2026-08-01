# Öffentliche Execution-Context-Objekte

## `USP_BeginExecution`

Beginnt einen Root-Context oder erhöht bei erlaubter Verschachtelung den `ScopeDepth`. Eine explizit übergebene Execution-ID wird am Root verwendet; andernfalls wird `NEWID()` erzeugt. Die Correlation-ID erbt standardmäßig die Execution-ID.

## `USP_SetExecutionContext`

Ändert Correlation-ID, Actor oder Tenant. `@ExpectedExecutionId` muss dem aktiven Context entsprechen. Actor und Tenant besitzen getrennte Clear-Flags, damit `NULL` eindeutig als „nicht ändern“ behandelt werden kann.

## `USP_EndExecution`

Verringert den `ScopeDepth`. Bei Tiefe 1 werden alle namespaceten Sessionwerte gelöscht. Ein fehlender oder nicht passender Context ist ein Fehler und kein stiller Erfolg.

## `TVF_CurrentExecutionContext`

Inline TVF für `SELECT`, `CROSS APPLY` und `OUTER APPLY`. Ohne aktiven Context liefert sie keine Zeile.

## `SVF_CurrentExecutionId`

Komfort-Wrapper auf die inline TVF. Für mengenorientierte Abfragen bleibt die TVF vorzuziehen.
