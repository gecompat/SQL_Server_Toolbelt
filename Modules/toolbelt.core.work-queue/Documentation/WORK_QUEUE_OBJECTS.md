# Work-Queue-Objekte

## Zustands- und Ownership-Modell

```text
QUEUED -> CLAIMED -> COMPLETED
   ^          |
   |          +----> FAILED
   +-- explizite Recovery einer abgelaufenen Lease
```

Jeder Claim erzeugt ein neues `ClaimToken`, erhöht `ClaimGeneration` und setzt
eine Lease anhand der Engine-Zeit. Active bedeutet ausschließlich
`Status = 'CLAIMED' AND LeaseUntilUtc > SYSUTCDATETIME()`. Eine abgelaufene
Lease kann nicht verlängert oder terminal abgeschlossen werden.

## `USP_EnqueueWork`

Parameter: `@WorkTypeName varchar(128)`, `@PayloadJson nvarchar(max)` und die
vier Standardparameter. Der Work Type muss registriert, aktiv und sein Handler
vorhanden sein. `NONE` akzeptiert nur `NULL`; `JSON_PAYLOAD` verlangt ein
JSON-Objekt bis 65.536 Bytes. Enqueue nimmt an einer Caller-Transaktion teil.

## `USP_ClaimWork`

`@LeaseDurationSeconds` besitzt den Default 300 und erlaubt 5 bis 86.400
Sekunden. Claim darf nicht in einer Caller-Transaktion laufen. Er liefert null
oder eine Zeile mit Work Item, Work Type, Payload, geheimem ClaimToken,
Claimzeit, Generation, Leasegrenze und Heartbeatzeit. Abgelaufene Claims
werden nicht implizit zurückgesetzt oder erneut beansprucht.

## `USP_RenewWorkLease`

Heartbeat verlangt `WorkItemId` und das aktuelle `ClaimToken`, läuft in einer
kurzen eigenen Transaktion und verlängert ab Engine-Zeit um die beim Claim
gespeicherte Dauer. Fremde Tokens, terminale Items und bereits abgelaufene
Leases verändern nichts. Eine Caller-Transaktion wird abgewiesen.

## `USP_RecoverExpiredWork`

Recovery ist ein ausdrücklicher Supervisor-Aufruf. `@MaxItems` begrenzt den
Batch auf 1 bis 1.000, Default 100. Nur `CLAIMED`-Items mit
`LeaseUntilUtc <= SYSUTCDATETIME()` werden geordnet gesperrt und auf `QUEUED`
gesetzt. Claim- und Leasefelder werden gelöscht, `RecoveryCount` erhöht und
die letzte Recovery protokolliert. ClaimToken und Payload erscheinen nicht im
Resultset. Eine Caller-Transaktion wird abgewiesen.

## `USP_CompleteWork` und `USP_FailWork`

Beide verlangen WorkItemId und ClaimToken. Unter demselben Row Lock werden
Status, Token und aktive Lease geprüft. Complete speichert kein fachliches
Ergebnis. Fail speichert einen stabilen ASCII-Code und optional höchstens
1.000 bereits bereinigte Unicode-Codeeinheiten. Beide behalten den E1a-
Savepoint-Vertrag für Caller-Transaktionen.

## `USP_GetWorkStatus` und `VW_WorkQueue`

Statusoberflächen liefern Audit-, Lease-, Generation- und Recovery-Metadaten.
`IsLeaseExpired` ist nur für einen aktuell `CLAIMED`-Status zeitabhängig 1.
Payload und ClaimToken bleiben verborgen. Direkte DML auf `WorkItem` ist kein
öffentlicher Vertrag.

## Garantien und Grenzen

FIFO gilt bestmöglich unter derzeit `QUEUED`, sichtbaren und handlerfähigen
Items. Recovery invalidiert technische Ownership, kann aber bereits erfolgte
fachliche Seiteneffekte nicht zurücknehmen. Exactly-once, Retry, Dead Letter,
Idempotenz, Cancellation, Worker und Scheduler sind keine E1b-Garantien.
