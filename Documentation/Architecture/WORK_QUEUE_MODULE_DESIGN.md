# Work-Queue-Moduldesign – E1a

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
