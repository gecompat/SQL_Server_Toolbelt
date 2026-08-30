# Work-Queue-Moduldesign – E1a und E1b

## Entscheidung und Freigabe

Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope wurden am
2026-08-30 mit dem Benutzer besprochen. Der Benutzer hat anschließend mit
„lass es uns so machen“ D1, den R1a-Spike und E1a gemäß dem besprochenen
Vertrag in dieser Reihenfolge ausdrücklich freigegeben. D1 und R1a wurden vor
Beginn dieses eigenständigen E1a-Schritts jeweils über einen Pull Request in
`origin/main` integriert.

## Zweck und öffentlicher Vertrag

E1a ist der kleinste praktisch nutzbare vertikale Queue-Slice. Deshalb umfasst
er neben Claim/Complete/Fail auch Enqueue, Statusabfrage und eine Statussicht:

- `toolbelt_core.USP_EnqueueWork`
- `toolbelt_core.USP_ClaimWork`
- `toolbelt_core.USP_CompleteWork`
- `toolbelt_core.USP_FailWork`
- `toolbelt_core.USP_GetWorkStatus`
- `toolbelt_core.VW_WorkQueue`

`WorkItemId bigint` ist die stabile Identität. Jeder Claim erzeugt ein neues
`uniqueidentifier`-Token; nur dieses Token darf Complete oder Fail
autorisieren. Der Token ist eine Capability und wird daher nicht über die
Statusoberflächen offengelegt.

## Persistenz und Claim

`toolbelt_core.WorkItem` folgt DEC-2026-025 und ist intern. Explizit benannte
Constraints erzwingen das Zustandsmodell und die zusammengehörigen
Zeit-/Actor-/Fehlermetadaten. Zwei Indizes tragen FIFO-Claim und
Work-Type-Statuszugriff.

Claim verwendet innerhalb einer eigenen kurzen Transaktion eine geordnete
`TOP (1)`-Auswahl mit `UPDLOCK`, `READPAST`, `READCOMMITTEDLOCK` und `ROWLOCK`
und aktualisiert Zustand und Token in demselben Statement. FIFO ist unter den
zu diesem Zeitpunkt sichtbaren, aktiven und handlerfähigen Items bestmöglich;
Locks, Rollbacks und konkurrierende Einreicher verhindern eine absolute
Fairnesszusage.

## Work Type und Payload

Direkte Handlernamen und Raw SQL sind ausgeschlossen. Enqueue referenziert
den vorhandenen Work-Type-Katalog. Claim berücksichtigt nur aktuell aktive
Work Types mit vorhandenem Handler. `NONE` speichert keine Payload;
`JSON_PAYLOAD` speichert ein JSON-Objekt bis 64 KiB. Das deklarative
`PayloadContractJson` des Work Types wird nicht als frei interpretierbares
JSON-Schema ausgeführt.

## Transaktionsvertrag

Enqueue, Complete und Fail können Teil einer Caller-Transaktion sein und
verwenden einen eigenen Savepoint. Bei bereits uncommittable Caller-Zustand
erfolgt keine Mutation. Claim lehnt jeden aktiven Caller-Transaktionskontext
ab, damit Lock, Statuswechsel und Tokenausgabe vollständig in der Procedure
abgeschlossen werden. ResultTable-Mutationen liegen bei schreibenden USPs in
derselben Transaktionsgrenze wie die Queue-Mutation.

## Alternativen

- Service Broker oder SQL Server Agent würden Transport und Betrieb in E1a
  koppeln und wurden verworfen.
- Ein Payload-freier Claim wäre ohne sicheren Folgeschritt nicht nutzbar.
- Ein öffentliches Claim-Token in der Statussicht würde Ownership aushebeln.
- Handler oder SQL-Text in der Payload würden den kontrollierten
  Work-Type-Vertrag umgehen.
- Lease, Retry und Cancellation im selben Release würden unabhängige Fehler-
  und Zustandsverträge vermischen.

## Risiken und Aussagegrenzen

Ein Worker-Ausfall nach Claim erzeugt ohne E1b einen dauerhaften
`CLAIMED`-Zustand. E1a garantiert at-most-one erfolgreichen Claim je
Zustandsübergang, aber weder Exactly-once-Ausführung noch Recovery, Fairness
oder automatische Ausführung. Das Modul bleibt deshalb `unreleased` und darf
nicht als allein betriebsfertige Queue beworben werden.

## Ausgeschlossener Scope

Lease/Heartbeat, Orphan Recovery, Retry, Dead Letter, Idempotency Key,
Cancellation, Resultpersistenz, Worker-Orchestrierung, Service Broker, Agent,
externe Runner und automatisches `KILL` sind ausdrücklich nicht E1a.

## E1b – Entscheidung und Freigabe

Lease, Heartbeat und Orphan Recovery wurden am 2026-08-30 unmittelbar nach
E1a mit dem Benutzer besprochen. Festgelegt wurden Zweck, öffentlicher
Vertrag, Alternativen, Risiken, Migration und ausgeschlossener Scope. Der
Benutzer hat anschließend die markierte Formulierung „E1b und R1b wie
besprochen implementieren“ als ausdrückliche Freigabe übermittelt. E1b wird
vor R1b in einem eigenen Branch und Pull Request umgesetzt.

## E1b-Vertrag

Version `1.1.0` ergänzt den bestehenden Vertrag um:

- eine Claim-Lease von standardmäßig 300 Sekunden mit Grenzen 5 bis 86.400;
- `ClaimGeneration` als monotonen Ownership-Zähler je Work Item;
- `USP_RenewWorkLease` für tokengebundene Heartbeats;
- `USP_RecoverExpiredWork` für explizite Batches von 1 bis 1.000 abgelaufenen
  Claims;
- Lease-, Generation- und Recovery-Metadaten in den geschützten
  Statusoberflächen.

Engine-Zeit ist autoritativ. Eine Lease ist an ihrer exklusiven Grenze
abgelaufen. Heartbeat, Complete und Fail prüfen Status, ClaimToken und
Leasegrenze unter demselben Row Lock. Claim, Heartbeat und Recovery besitzen
kurze eigene Transaktionen und akzeptieren keine Caller-Transaktion. Recovery
ist weder automatisch noch in Claim eingebaut.

Ein abgelaufener Claim bleibt bis zur expliziten Recovery sichtbar
`CLAIMED`. Recovery löscht Token und aktuelle Claim-/Leasefelder, erhöht den
Recovery-Zähler und setzt das Item auf `QUEUED`. Der nächste Claim erzeugt
eine neue Generation und ein neues Token. Ein eigener `ORPHANED`-Status ist
nicht erforderlich, weil Orphanhood lediglich aus einer abgelaufenen Lease
abgeleitet werden kann und keine sichere Aussage über den tatsächlichen
Worker-Zustand darstellt.

## E1b-Migration

Das Upgrade von `1.0.0` auf `1.1.0` ist nur zulässig, wenn keine Zeile
`CLAIMED` ist. Der Preflight bricht andernfalls vor jeder Mutation ab. QUEUED-
Items bleiben unverändert beanspruchbar; terminale Vorgängeritems erhalten
historische Lease-Metadaten, ohne erneut ausführbar oder recoverbar zu werden.
Erstinstallation, Upgrade und Wiederholungsdeployment verwenden weiterhin
dasselbe transaktionale Deployment.

## E1b-Alternativen und Risiken

Ein persistenter `ORPHANED`-Zwischenstatus, implizite Recovery im Claim,
SessionId als Ownership-Beweis, automatische Supervisor-Ausführung und `KILL`
wurden verworfen. Eine globale feste Lease wäre zu unflexibel; eine
unbegrenzte Caller-Lease würde die Betriebsgrenze wieder öffnen. Deshalb ist
die Dauer je Claim wählbar, aber strikt begrenzt und für alle Heartbeats des
Claims unveränderlich.

Recovery kann eine fachliche Ausführung wiederholen, wenn der alte Worker den
Seiteneffekt bereits gesetzt, aber nicht mehr rechtzeitig abgeschlossen hat.
E1b garantiert daher weder Exactly-once noch generische Idempotenz. Retry,
Backoff, Dead Letter, Idempotency Key, Cancellation, vollständige Attempt-
Historie und Worker-Orchestrierung bleiben getrennte Slices.
