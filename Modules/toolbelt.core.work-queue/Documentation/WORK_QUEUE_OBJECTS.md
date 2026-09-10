# Work-Queue-Objekte

## Zustands- und Ownership-Modell

```text
QUEUED -------> CLAIMED -------> COMPLETED
  |                |  |
  |                |  +--------> FAILED
  |                +-----------> RETRY_WAIT -> QUEUED
  |                                      |
  +--------------------------------------+-> DEAD_LETTER

BARRIER_WAIT -> CLAIMED
DEAD_LETTER -> QUEUED oder BARRIER_WAIT (explizites Requeue)
```

`BARRIER_WAIT` ist der wartende Zustand eines gruppenexklusiven `DRAIN_BARRIER`-Items. `RETRY_WAIT` wird erst bei Fälligkeit wieder beanspruchbar. `DEAD_LETTER` ist terminal, bis ein berechtigter Aufrufer das Item ausdrücklich in einen neuen Retry-Zyklus überführt.

Jeder Claim erzeugt ein neues `ClaimToken`, erhöht `ClaimGeneration` und setzt eine Lease anhand der Engine-Zeit. Active bedeutet ausschließlich `Status = 'CLAIMED' AND LeaseUntilUtc > SYSUTCDATETIME()`.

## `USP_EnqueueWork` und `USP_EnqueueWorkWithPolicy`

`USP_EnqueueWork` behält den V1-Vertrag und reiht mit Gruppe `default`, Priorität `0`, Modus `SHARED` und der Retry-Policy drei Versuche, 60 Sekunden Basis- sowie 3.600 Sekunden Maximalverzögerung ein. Der erweiterte öffentliche Vertrag `USP_EnqueueWorkWithPolicy` ergänzt Idempotency Key, Priority, ExecutionGroup, Retry-Policy und ExecutionMode. Gruppen und Keys werden binär verglichen; ein Key ist je Work Type eindeutig, solange das Item existiert. Gleiche Payload und Policy liefern das vorhandene Item, Abweichungen werden abgewiesen.

`USP_EnqueueBarrierWork` ist die getrennt berechtigte Kurzform für `DRAIN_BARRIER`. Beim Enqueue speichert sie unter dem Scheduler-Mutex die zugehörigen aktiven Claim-Generationen als Blocker-Snapshot. Die öffentliche Sicht `VW_WorkQueueBarrierBlockers` zeigt diese Blocker ohne Payload oder Claim-Token.

## `USP_ClaimWork`

`@LeaseDurationSeconds` besitzt den Default 300 und erlaubt 5 bis 86.400 Sekunden. Claim darf nicht in einer Caller-Transaktion laufen. Er liefert null oder eine Zeile mit Work Item, Work Type, Payload, geheimem ClaimToken, Claimzeit, Generation, Leasegrenze und Heartbeatzeit.

Prioritäten von `0` bis `255` werden absteigend gereiht. Eine Barrier sperrt nur normale Claims ihrer ExecutionGroup. Gleichpriorige Barriers derselben Gruppe können gleichzeitig laufen; unterschiedlich priorige Barriers laufen nicht gleichzeitig. Laufende Arbeit wird nie präemptiert.

## `USP_RenewWorkLease`

Heartbeat verlangt `WorkItemId` und das aktuelle `ClaimToken`, läuft in einer kurzen eigenen Transaktion und verlängert ab Engine-Zeit um die beim Claim gespeicherte Dauer. Fremde Tokens, terminale Items und bereits abgelaufene Leases verändern nichts.

## `USP_RecoverExpiredWork` und `USP_ScheduleWorkRetry`

Recovery ist ein ausdrücklicher Supervisor-Aufruf. `@MaxItems` begrenzt den Batch auf 1 bis 1.000, Default 100. Abgelaufene Claims wechseln nach ihrer gespeicherten Retry-Policy entweder in `RETRY_WAIT` oder `DEAD_LETTER`. `USP_ScheduleWorkRetry` trifft dieselbe tokengebundene Entscheidung für einen aktiven Worker-Claim. Der Backoff ist `min(Basis × 2^(Versuch−1), Maximum)` ohne Jitter. Claim- und Leasefelder werden gelöscht; eine Barrier gibt dadurch ihre Gruppe frei. Beide Procedures lehnen eine Caller-Transaktion ab.

## `USP_CompleteWork` und `USP_FailWork`

Beide verlangen WorkItemId und ClaimToken. Unter demselben Row Lock werden Status, Token und aktive Lease geprüft. Complete speichert kein fachliches Ergebnis. Fail speichert einen stabilen ASCII-Code und optional höchstens 1.000 bereits bereinigte Unicode-Codeeinheiten. `USP_FailWork` bleibt terminal; einen Retry plant nur `USP_ScheduleWorkRetry`.

## `USP_RequeueDeadLetter`

`USP_RequeueDeadLetter` beginnt für ein `DEAD_LETTER`-Item einen neuen Retry-Zyklus. Es unterstützt eine optionale `rowversion`-Prüfung und speichert den Requeue-Grund. Lifetime-Attempts, bereinigte letzte Fehlerdaten und der Idempotency Key bleiben erhalten. Eine Barrier erzeugt dabei einen neuen Claim-Snapshot.

## `USP_GetWorkStatus` und `VW_WorkQueue`

Statusoberflächen liefern Audit-, Lease-, Generation-, Retry-, Dead-Letter-, Prioritäts-, Gruppen- und Barrier-Metadaten. Payload und ClaimToken bleiben verborgen. Direkte DML auf `WorkItem` ist kein öffentlicher Vertrag.

## Garantien und Grenzen

Die Reihenfolge gilt bestmöglich unter fälligen, sichtbaren und handlerfähigen Items gleicher Priorität. Recovery und Retry invalidieren technische Ownership, können aber bereits erfolgte fachliche Seiteneffekte nicht zurücknehmen. Idempotency Keys verhindern nur doppelte Enqueue-Annahmen, nicht generische Exactly-once-Ausführung. Cancellation, Worker-Orchestrierung und automatische Systemzustandserkennung bleiben außerhalb des Moduls.
