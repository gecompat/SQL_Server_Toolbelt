# Queue-Worker starten und steuern

Beginne mit dem [Queue-Lernweg](../../Modules/toolbelt.core.work-queue/Documentation/USAGE.md),
wenn Work Type, Claim, Lease und Retry noch nicht vertraut sind. Hier geht es
um die tatsächliche Ausführung bereits eingereihter Arbeit und um ihren Betrieb.
Der Provider ist teilweise validiert; aktuelle Grenzen stehen in
[README](README.md) und [Testnachweisen](Tests/README.md). SQL-Ziel und
Worker-Betriebssystem sind getrennte Nachweisscopes.

## Betriebsart wählen

| Betriebsart | Wann sinnvoll? | Grenze |
|---|---|---|
| Begrenzter Standardlauf, ohne `-Managed` | Ein ausdrücklich gestarteter Worker soll vorhandene SQL-Arbeit abarbeiten | 1–8 lokale Slots, keine gemeinsame Kapazitätsgrenze mehrerer Supervisoren; leere beanspruchbare Queue beendet den Lauf nach aktiven Slots |
| Managed `BOUNDED` | Zentral zugelassene Arbeit mit begrenzter Laufzeit/Claimzahl | SQL-Worker-Control separat installieren und aktivieren; Limits stoppen neue Admission, nicht abrupt laufende Handler |
| Managed `CONTINUOUS` | Ein gestarteter Prozess soll auch auf später eintreffende Arbeit warten | Pollt bei leerer Queue bis Drain; kein Dienstinstaller und keine automatische Neustartgarantie |

Ein bloßes Startskript installiert keine SQL-Module oder Dienste. Die
[Voraussetzungen](README.md#voraussetzungen-und-zulassung) umfassen PowerShell 7,
`System.Data.SqlClient`, Work Queue/Work Type, Execution Context, Cancellation
und deren Dependencies in derselben Datenbank. Für Managed kommt Worker
Control hinzu. Der [Deploymentrunner](../../Deployment/README.md) ergänzt
transitive Dependencies, beispielsweise beim Planen mit
`-ModuleId toolbelt.core.worker-control -DeploymentMode local -PlanOnly`.

## Handler prüfen und Verbindung bereitstellen

Ein zugelassener Handler ist eine registrierte Procedure im Modus `NONE`
oder `JSON_PAYLOAD`. Er liefert keine Resultsets, verwaltet keine eigenen
Commits/Rollbacks, hat keine externen Seiteneffekte und arbeitet in begrenzten
Schritten mit kooperativen Cancellation-Checkpoints. Der Provider besitzt die
Transaktion. Ein einzelner kurzer Demohandler aus dem Queue-Lernweg erklärt
SQL-Idempotenz, ersetzt aber keinen Entwurf für langlaufende Arbeit.

Ein kooperativer Checkpoint gehört **in** den zugelassenen Handler zwischen
seine begrenzten Arbeitsschritte, etwa:

```sql
-- Innerhalb eines vom Worker gestarteten Handlers, nicht als Stopbefehl in SSMS:
DECLARE @ExecutionId uniqueidentifier =
    TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.worker.execution_id'));
IF @ExecutionId IS NOT NULL
   AND toolbelt_core.SVF_IsCancellationRequested(@ExecutionId)=1
    THROW 50001,N'WORKER.CANCELLED',1;
```

Die readonly Workerzuordnung verwenden; keine eigene ExecutionId erfinden oder
den Context während des Laufs austauschen. Im Standardpfad kann ein berechtigter
Operator über [USP_RequestExecutionCancellation](../../Modules/toolbelt.core.execution-cancel/Documentation/USP_RequestExecutionCancellation.md)
mit der aus der privaten aktiven Workerzuordnung übernommenen ExecutionId
Cancellation anfordern. Der Handler muss sie am Checkpoint bestätigen;
der Provider rollt zurück und meldet `FAILED`/`WORKER.CANCELLED`.
Die Queuezustandsview allein enthält diese aktive ExecutionId nicht.

`WorkerEligibleWorkTypes` muss jeden exakten registrierten Namen ausdrücklich
enthalten. **Diese Liste ist kein SQL-Claimfilter.** Ein dennoch beanspruchter,
nicht zugelassener Typ wird ohne Handlerausführung terminal abgewiesen. Daher
Queuebelegung, CLAIM-Policies und Workerzulassung gemeinsam planen.
Der Provider prüft die CLAIM-Policy erneut unmittelbar vor dem Handlerstart.

Die Verbindung privat in der Prozessumgebungsvariable `TBX_WORKER_CONNECTION`
bereitstellen, beispielsweise durch den vorgesehenen lokalen Secret-/Startprozess.
Der Wert ist ein gültiger `System.Data.SqlClient`-Connection-String zur
gewählten Datenbank. `Encrypt=True` ist erforderlich. Den für die Umgebung
bewusst festgelegten Zertifikats-/Trustwert verwenden; kein automatischer
Wechsel nach Fehlern. Credentials nicht im Skript, in der Shellhistorie oder
im Repository ablegen. Das Startskript erhält nur den Variablennamen.
SSMS-Anmeldung setzt diese PowerShell-Variable nicht automatisch.

## Begrenzter Lauf und Retry

Nach passender Installation, Handlerzulassung, ENQUEUE-/CLAIM-Policies und
privater Verbindungskonfiguration im Repository-Hauptverzeichnis:

```powershell
./Workers/ExternalQueue/Start-ExternalQueueWorker.ps1 `
    -ConnectionStringEnvironmentVariable TBX_WORKER_CONNECTION `
    -WorkerEligibleWorkTypes 'demo.queue-guide' `
    -Slots 1 -MaxRunSeconds 300 -MaxClaims 10
```

Der Worker führt verfügbare zugelassene Aufträge aus. Handler und Complete
teilen eine SQL-Transaktion; nur ein bestätigter Commit zählt als Erfolg.
Eine leere Claimantwort beendet den Standardlauf nach Abschluss aktiver Slots.
Die Queue bleibt bestehen. Nicht zugleich das manuelle SSMS-Claimbeispiel
in dieser Datenbank betreiben.

Retry ist standardmäßig aus. Erst nach Prüfung fachlicher Wiederholbarkeit
und ausdrücklicher Fehlerklassifikation aktivieren, beispielsweise:

```powershell
./Workers/ExternalQueue/Start-ExternalQueueWorker.ps1 `
    -ConnectionStringEnvironmentVariable TBX_WORKER_CONNECTION `
    -WorkerEligibleWorkTypes 'demo.queue-guide' `
    -RetryEligibleWorkTypes 'demo.queue-guide' -TransientSqlNumbers 1205 `
    -MaxClaims 10 -MaxRunSeconds 300
```

Hier wird SQL-Fehler 1205 ausdrücklich für diesen Lauf als transient
eingeordnet. Zulassung plus Fehlernummer allein ersetzen keinen bestätigten
Rollback. Cancellation, verlorene Ownership, dauerhafte Fehler und unbekannte
Transaktionsausgänge erhalten keinen Retry. Die Queue entscheidet anhand der
am Item gespeicherten Policy zwischen `RETRY_WAIT` und `DEAD_LETTER`.
Ein begrenzter Lauf kann enden, bevor der Retry fällig wird; später erneut
starten oder bewusst Managed-Dauerbetrieb einsetzen.

### Alle Startparameter

| Parameter | Bedeutung, Default und zulässige Auswahl |
|---|---|
| `ConnectionStringEnvironmentVariable` | Pflicht; Name einer vorhandenen nichtleeren Prozessvariable, Identifier aus Buchstaben/Ziffern/Unterstrich, kein führendes Digit; niemals der Connection-String selbst |
| `WorkerEligibleWorkTypes` | Pflicht; 1–1000 eindeutige kanonische Work-Type-Namen; ausdrückliche Handlerzulassung |
| `RetryEligibleWorkTypes` | Default leer; eindeutige Teilmenge der zugelassenen Namen mit explizit erlaubten Wiederholungen |
| `TransientSqlNumbers` | Default leer; höchstens 32 eindeutige positive SQL-Fehlernummern, für diesen Lauf bewusst als transient klassifiziert |
| `Slots` | Standardpfad: 1–8, Default 1; Managed verwendet stattdessen `Capacity` |
| `MaxRunSeconds` | 1–86400 Sekunden, Default 300; stoppt neue Arbeit im Standard-/Managed-BOUNDED-Lauf; keine harte Gesamtlaufzeitgarantie |
| `MaxClaims` | 1–100000, Default 1000; Claimlimit im Standard-/BOUNDED-Lauf, keine reine Erfolgsanzahl |
| `ControlTimeoutSeconds` | 1–30 Sekunden, Default 5; Zeitlimit der Steuerbefehle, kein Handler-Timeout |
| `ConnectTimeoutSeconds` | 1–30 Sekunden, Default 5; Verbindungsaufbau |
| `PollSeconds` | 0,1–10 Sekunden, Default 1; Pollintervall |
| `GraceSeconds` | 1–3600 Sekunden, Default 30; Standardpfad meldet nach Drain-Grace noch aktive Arbeit und wartet weiter; kein Kill, kein zugesagtes Managed-Abbruchbudget |
| `StopFile` | Default leer; optionaler privater Dateipfad, dessen Existenz Drain anfordert; Worker erzeugt die Datei nicht |
| `Managed` | Switch, Default aus; ausdrücklich zentral gesteuerter Pfad |
| `WorkerId` | Managed: stabile, nichtleere GUID je Supervisor; über Neustarts beibehalten, nicht gleichzeitig für verschiedene Supervisoren nutzen |
| `Capacity` | Managed: 1–2147483647, Default 1; lokale Zulassungsgrenze; Zahlenbereich ist keine Ressourcenempfehlung |
| `RunMode` | `BOUNDED` (Default) oder `CONTINUOUS`; im Dauerbetrieb greifen MaxRunSeconds/MaxClaims nicht als Endgrenzen |

Ohne `Managed` werden eine nichtleere WorkerId, Capacity ungleich 1 oder ein
anderer RunMode als `BOUNDED` abgewiesen. Im Standardpfad beträgt die Claimlease
300 Sekunden, ihr Heartbeatintervall 60 Sekunden. Der Work-Type-Defaulttimeout
fordert kooperative Cancellation an; ein unkooperativer Handler kann darüber
hinaus laufen. Drain hält aktive Arbeit und ihre Heartbeats aufrecht.

Die Summary unterscheidet `Claims`, `Completed`, `Failed`, `Retried`,
`DeadLetter`, `Unresolved`. `Status=COMPLETED` bedeutet Ende des Supervisorlaufs,
**nicht** „alle Aufträge waren erfolgreich“. `OUTCOME_UNKNOWN` verlangt Klärung;
ein Fehler im späteren Cleanup darf einen bestätigten Commit nicht in einen
Retry verwandeln.

## Managed aktivieren und starten

Aktivierung ist ein administrativer Vorgang außerhalb einer Callertransaktion.
Vorher Claims, belegte Reservations und Holds abwickeln. `ExpectedConfigVersion`
ist immer eine **frisch gelesene** `binary(8)`-Version, kein geschätzter Zähler.
Die erste Version erhält man über eine Registrierung; diese muss keine Arbeit
beanspruchen und funktioniert bereits vor Aktivierung:

```sql
-- Nur in der bewusst vorbereiteten Demo, Worker Control bereits installiert.
-- Berechtigter Administrator, keine laufenden Claims/Holds/Reservations.
CREATE TABLE #Bootstrap (Placeholder bit);
DECLARE @BootstrapId uniqueidentifier=NEWID(), @Generation bigint,
        @Token uniqueidentifier, @Config binary(8);
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@BootstrapId,
    @Capacity=1, @RunMode='BOUNDED', @ResultTable=N'#Bootstrap';
EXEC sys.sp_executesql
    N'SELECT @G=WorkerGeneration,@T=WorkerToken,@V=ConfigVersion FROM #Bootstrap;',
    N'@G bigint OUTPUT,@T uniqueidentifier OUTPUT,@V binary(8) OUTPUT',
    @G=@Generation OUTPUT,@T=@Token OUTPUT,@V=@Config OUTPUT;
-- Keine Claims reserviert: die reine Bootstrapgeneration sofort schließen.
EXEC toolbelt_core.USP_CloseWorker @WorkerId=@BootstrapId,
    @WorkerGeneration=@Generation,@WorkerToken=@Token;
EXEC toolbelt_core.USP_EnableManagedWorkers @ExpectedConfigVersion=@Config;
DROP TABLE #Bootstrap;
```

Erwartung: geschlossene Bootstrapgeneration, `ManagedEnabled=1` und neue
ConfigVersion. Keine Tokens anzeigen. Nun verwendet SQL ausschließlich die
geschützte Managedzulassung; direktes `USP_ClaimWork` wird abgewiesen.

```powershell
# GUID einmalig pro eigenem Supervisor wählen und danach stabil beibehalten.
$queueWorkerId = [guid]'44444444-4444-4444-8444-444444444444'
./Workers/ExternalQueue/Start-ExternalQueueWorker.ps1 `
    -ConnectionStringEnvironmentVariable TBX_WORKER_CONNECTION `
    -WorkerEligibleWorkTypes 'demo.queue-guide' `
    -Managed -WorkerId $queueWorkerId -Capacity 2 -RunMode BOUNDED `
    -MaxRunSeconds 300 -MaxClaims 10
```

Zum bewussten Dauerbetrieb `-RunMode CONTINUOUS` wählen und vorher den
Drain-/Stopweg festlegen. Providerstart registriert eine neue Generation,
erhöht aber nicht die globale Parallelität. Globale Vorgabe ist zunächst 1;
Capacity 2 allein erzeugt daher keine zwei gleichzeitigen Ausführungen.
Neuregistrierung übernimmt keine alten Claims oder Tokens. Eine administrative
Pause der stabilen Identität wird auch durch Neuregistrierung nicht umgangen.

### Parallelität, Intervalle und Pause ändern

```sql
-- Datenbank der Queue/Workersteuerung. Aktuelle Version aus öffentlicher Sicht.
DECLARE @Config binary(8);
SELECT TOP (1) @Config=ConfigVersion FROM toolbelt_core.VW_WorkerStatus;
IF @Config IS NULL THROW 50000,N'Zuerst Bootstrap/Registrierung durchführen.',1;
EXEC toolbelt_core.USP_SetWorkerConcurrency
    @MaxConcurrentExecutions=2, @ExpectedConfigVersion=@Config;
```

Das globale Budget gilt über alle Supervisoren dieser Installation. Erhöhen
erlaubt zusätzliche Starts; Reduzieren oder 0 bricht nichts ab, sondern sperrt
neue Starts, bis wieder Platz ist. `UNKNOWN` bleibt belegt. Heartbeats und
Abschlussbearbeitung laufen unabhängig davon weiter.

Nach **jeder** Änderung Version frisch lesen. Für den oben gestarteten Worker:

```sql
DECLARE @Worker uniqueidentifier='44444444-4444-4444-8444-444444444444';
DECLARE @Generation bigint,@Config binary(8);
SELECT TOP (1) @Generation=WorkerGeneration,@Config=ConfigVersion
FROM toolbelt_core.VW_WorkerStatus WHERE WorkerId=@Worker ORDER BY WorkerGeneration DESC;
IF @Generation IS NULL THROW 50000,N'Den eigenen Worker zuerst starten.',1;
EXEC toolbelt_core.USP_SetWorkerState @WorkerId=@Worker,
    @WorkerGeneration=@Generation,@RequestedState='PAUSED',@ExpectedConfigVersion=@Config;
```

`PAUSED` sperrt neue Starts reversibel, `ACTIVE` nimmt sie wieder auf,
`DRAINING` lässt vorhandene Arbeit auslaufen. Keiner dieser Werte bedeutet
Rollback. Mit frischer ConfigVersion ändert `USP_SetWorkerCapacity` die lokale
Capacity der exakten Generation; mit `USP_SetWorkerIntervals` ändern
`HeartbeatSeconds` (1–3600) und `UnreachableSeconds` (3–86400, mindestens
dreifacher Heartbeat) die Defaults **künftiger** Generationen. Bestehende
Generationen behalten ihre bei Registrierung kopierten Intervalle, standardmäßig
15/60 Sekunden. Eine abgelaufene Generation wird nicht durch späten Heartbeat
wiederbelebt. [Parameterreferenzen](#alle-öffentlichen-steuerfunktionen).

Konkrete Kapazitäts- und Intervalländerung für den vorhandenen Demo-Worker:

```sql
DECLARE @Worker uniqueidentifier='44444444-4444-4444-8444-444444444444';
DECLARE @Generation bigint,@Config binary(8);
SELECT TOP (1) @Generation=WorkerGeneration,@Config=ConfigVersion
FROM toolbelt_core.VW_WorkerStatus WHERE WorkerId=@Worker ORDER BY WorkerGeneration DESC;
IF @Generation IS NULL THROW 50000,N'Demo-Worker fehlt.',1;
EXEC toolbelt_core.USP_SetWorkerCapacity @WorkerId=@Worker,
    @WorkerGeneration=@Generation,@Capacity=2,@ExpectedConfigVersion=@Config;
SELECT TOP (1) @Config=ConfigVersion FROM toolbelt_core.VW_WorkerStatus;
EXEC toolbelt_core.USP_SetWorkerIntervals @HeartbeatSeconds=10,
    @UnreachableSeconds=30,@ExpectedConfigVersion=@Config;
```

Erwartung: Capacity 2 für diese Generation, neue Defaults 10/30 Sekunden für
künftige Registrierungen. Die laufende Generation behält ihre vorherigen
Heartbeatintervalle. Diese Beispielwerte sind keine Kapazitätsplanung.

## Stop, Hold und Wiederfreigabe

Ein Stop ist eine Anforderung, keine Bestätigung eines Rollbacks. Erhält der
Commit zuerst seine wirksame Abschlussentscheidung, bleibt er committed.
Bestätigter Rollback hält das Item dauerhaft zurück; ein anderer Worker darf
es erst nach bewusster Freigabe übernehmen. Ein unbekannter Ausgang bleibt
`UNKNOWN`, auch nach Zeitablauf oder neuem Workerstart.

Die aktuelle Ausführung eines bestimmten eigenen Items zuerst über die Views
ermitteln. Das folgende Beispiel wählt die aktive Ausführung des Demo-Workers:

```sql
DECLARE @Worker uniqueidentifier='44444444-4444-4444-8444-444444444444';
DECLARE @Reservation uniqueidentifier,@ClaimGeneration bigint;
SELECT TOP (1) @Reservation=SlotReservationId,@ClaimGeneration=ClaimGeneration
FROM toolbelt_core.VW_WorkerExecutionStatus
WHERE WorkerId=@Worker AND State IN ('RESERVED','RUNNING')
ORDER BY WorkerGeneration DESC,ClaimGeneration DESC;
IF @Reservation IS NULL THROW 50000,N'Keine passende aktive Demoausführung.',1;
EXEC toolbelt_core.USP_StopWorkerExecution
    @SlotReservationId=@Reservation,@ExpectedClaimGeneration=@ClaimGeneration;
SELECT * FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Reservation;
```

Der kurze Demo-Handler kann bereits abgeschlossen sein; dann ist diese
Voraussetzung nicht erfüllt. Keine vermeintliche Stop-Erfolgsmeldung erfinden.
Für einen echten Langläufer muss dessen zugelassener Handler Checkpoints besitzen.
Im Managedpfad versucht der unabhängige Guardian zusätzlich, die exakt gebundene
Commandinstanz abzubrechen. Cancellation allein beweist dennoch kein SQL-Ende.

Mehrere eigene Generationen gemeinsam stoppen:

```sql
CREATE TABLE #SelectedWorkers
(WorkerId uniqueidentifier NOT NULL, WorkerGeneration bigint NOT NULL);
INSERT #SelectedWorkers
SELECT WorkerId,WorkerGeneration FROM toolbelt_core.VW_WorkerStatus
WHERE WorkerId='44444444-4444-4444-8444-444444444444' AND State<>'CLOSED';
EXEC toolbelt_core.USP_StopWorkers @WorkersTable=N'#SelectedWorkers';
DROP TABLE #SelectedWorkers;
```

Die Tabelle enthält exakt diese zwei Spalten, maximal 1000 eindeutige Paare.
Leere Auswahl ist ein No-op. Die Generationenauswahl wird eingefroren;
gleichzeitig später entstehende Generationen werden nicht nachträglich in die
Stopauswahl gezogen. Die stabile ausgewählte Workeridentität wird pausiert.

### Unbekannten Ausgang klären, dann bewusst freigeben

```sql
-- Aktuelle gehaltene Demoausführung auswählen; keine beliebigen IDs erfinden.
DECLARE @Reservation uniqueidentifier,@Version binary(8);
SELECT TOP (1) @Reservation=SlotReservationId,@Version=HoldVersion
FROM toolbelt_core.VW_WorkerExecutionStatus
WHERE WorkerId='44444444-4444-4444-8444-444444444444' AND IsHeld=1
ORDER BY WorkerGeneration DESC,ClaimGeneration DESC;
IF @Reservation IS NULL THROW 50000,N'Keine gehaltene Demoausführung.',1;
EXEC toolbelt_core.USP_ReconcileWorkerExecution
    @SlotReservationId=@Reservation,@ExpectedHoldVersion=@Version;
SELECT * FROM toolbelt_core.VW_WorkerExecutionStatus WHERE SlotReservationId=@Reservation;
```

Reconcile prüft tatsächliche Session-/Commitzeugen. `COMMITTED` bedeutet
bestätigten Commit, `ROLLED_BACK_HELD` bestätigten Rollback mit Hold;
`ROLLED_BACK` kann bereits abgewickelte Terminalhistorie bezeichnen.
`UNKNOWN` bleibt belegt. Bei Konflikt oder weiterhin laufendem Handler zuerst
den Zustand klären; keine internen Tabellen korrigieren und keinen Nachweis
durch ein manuelles Boolean ersetzen.

Nur nach Ursachenbehebung und bewusst gewählter Wiederaufnahme:

```sql
DECLARE @Item bigint,@Hold binary(8);
SELECT TOP (1) @Item=WorkItemId,@Hold=HoldVersion
FROM toolbelt_core.VW_WorkerExecutionStatus
WHERE WorkerId='44444444-4444-4444-8444-444444444444'
  AND State='ROLLED_BACK' AND IsHeld=1
ORDER BY WorkerGeneration DESC,ClaimGeneration DESC;
IF @Item IS NULL THROW 50000,N'Keine bewiesen zurückgerollte gehaltene Demoarbeit.',1;
EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@Item,@ExpectedHoldVersion=@Hold;
```

Der Server prüft zusätzlich, dass keine belegte Reservation/Commitwirkung
verblieben ist. Erfolg öffnet einen neuen Retryzyklus (`QUEUED` beziehungsweise
`BARRIER_WAIT`), entfernt den Hold und erlaubt einem geeigneten Worker den
nächsten Claim. Release reaktiviert keinen pausierten Worker. `UNKNOWN` und
committed Arbeit werden abgewiesen. Dead-Letter-Requeue, Lease-Recovery und
Retry ersetzen diese Holdfreigabe nicht.

## Alle öffentlichen Steuerfunktionen

Die folgenden Namen liegen in `toolbelt_core`; Links führen zu vollständigen
Parameterverträgen. Interne Reserve-/Witness-/Completionroutinen sind keine
manuellen Betriebsbefehle.

| API | Zweck / Anwendung |
|---|---|
| [USP_RegisterWorker](../../Modules/toolbelt.core.worker-control/Documentation/USP_RegisterWorker.md) | Neue principalgebundene Generation; gibt geheimes WorkerToken aus; Provider oder Bootstrapbeispiel |
| [USP_HeartbeatWorker](../../Modules/toolbelt.core.worker-control/Documentation/USP_HeartbeatWorker.md) | Lebenszeichen für aktuelle Generation/Token; wird unabhängig von Handlerarbeit durch den Provider gesendet |
| [USP_CloseWorker](../../Modules/toolbelt.core.worker-control/Documentation/USP_CloseWorker.md) | Eigene Generation ohne belegte/ungeklärte Reservations schließen; kein Prozess-Kill |
| [USP_ClaimWorkerWork](../../Modules/toolbelt.core.worker-control/Documentation/USP_ClaimWorkerWork.md) | Atomare Managedzulassung und Claim für autorisierte Generation; als Teil des vollständigen Providerprotokolls, nicht als manueller Ersatz für Standardclaim |
| [USP_EnableManagedWorkers](../../Modules/toolbelt.core.worker-control/Documentation/USP_EnableManagedWorkers.md) | Versionsgebundenes Opt-in im ruhenden Zustand |
| [USP_DisableManagedWorkers](../../Modules/toolbelt.core.worker-control/Documentation/USP_DisableManagedWorkers.md) | Bewusster Wechsel zurück nach vollständiger Abwicklung von Claims/Reservations/Holds, kein Fallback bei Fehlern |
| [USP_SetWorkerConcurrency](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerConcurrency.md) | Globales Admissionbudget einschließlich 0 ändern, keine Präemption |
| [USP_SetWorkerCapacity](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerCapacity.md) | Kapazität einer exakten Generation ändern |
| [USP_SetWorkerIntervals](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerIntervals.md) | Heartbeat-/Unerreichbarkeitsdefaults zukünftiger Generationen ändern |
| [USP_SetWorkerState](../../Modules/toolbelt.core.worker-control/Documentation/USP_SetWorkerState.md) | Aktuelle Generation ACTIVE, PAUSED oder DRAINING setzen |
| [USP_StopWorkerExecution](../../Modules/toolbelt.core.worker-control/Documentation/USP_StopWorkerExecution.md) | Exakte Reservation/Claimgeneration stoppen und Hold setzen, soweit noch nicht committed |
| [USP_StopWorkers](../../Modules/toolbelt.core.worker-control/Documentation/USP_StopWorkers.md) | Ausgewählte Generationen gemeinsam stoppen und stabile Identitäten pausieren |
| [USP_ReconcileWorkerExecution](../../Modules/toolbelt.core.worker-control/Documentation/USP_ReconcileWorkerExecution.md) | Ungeklärten Ausgang anhand tatsächlicher Zeugen abgleichen |
| [USP_ReleaseHeldWork](../../Modules/toolbelt.core.worker-control/Documentation/USP_ReleaseHeldWork.md) | Bewiesen zurückgerollte gehaltene Arbeit versionsgebunden wieder zulassen |
| [VW_WorkerStatus](../../Modules/toolbelt.core.worker-control/Documentation/VW_WorkerStatus.md) | Generation, State, Capacity, OccupiedSlots, Intervalle und ConfigVersion lesen, ohne Token |
| [VW_WorkerExecutionStatus](../../Modules/toolbelt.core.worker-control/Documentation/VW_WorkerExecutionStatus.md) | Reservation, WorkItemId, Generation, State, IsHeld, HoldVersion und StopStatus lesen |

Providerzustände sind `ACTIVE`, `PAUSED`, `DRAINING`, `UNREACHABLE`, `CLOSED`;
nur ACTIVE nimmt neue Arbeit an. Reservationszustände sind `RESERVED`,
`RUNNING`, `STOP_REQUESTED`, `STOPPING`, `UNKNOWN`, `COMMITTED`, `ROLLED_BACK`,
`CLOSED`. Diese sind nicht mit Queuezuständen wie `COMPLETED`/`FAILED`
gleichzusetzen. Auch `ROLLED_BACK` bedeutet vor der finalen Queueentscheidung
nicht zwangsläufig bereits einen freien Slot.

## Fehlerklärung und Betriebsende

| Beobachtung | Nächster Schritt |
|---|---|
| `WORKER.CONNECTION_UNAVAILABLE` / abstraktes `RUN_FAILED` | Private Umgebungsvariable, Treiber, verschlüsselte Verbindung und Modulvoraussetzungen prüfen; keine Secrets ausgeben |
| 54212 | ConfigVersion fehlt oder veraltet: neue Ausgabe lesen, Änderung bewusst neu entscheiden |
| 54215 | Falsche/alte Generation oder fehlende Identitätsautorität; keine fremden Tokens übernehmen |
| 54217 | Claims, Reservations oder Holds blockieren den Moduswechsel; regulär abwickeln |
| 54225 / 54227 | Holdversion/Reservation passt nicht oder Ausgang ungeklärt; Status und Reconciliation prüfen |
| Globale Slots scheinbar frei, dennoch kein Start | PAUSED/DRAINING, lokales Capacitylimit, UNKNOWN/noch belegte Slots, Handlerpolicy und Queue-Barriers prüfen |
| Worker nicht erreichbar | Heartbeatverlust beweist kein Handlerende; niemals automatisch alten Claim wiederholen |

Für ein Betriebsende zuerst Drain auslösen, Endzustände und Summary prüfen,
ungeklärte Ausgänge behandeln. Der Provider schließt seine Generation selbst,
sobald dies zulässig ist. Managed anschließend nur auf bewussten Wunsch mit
frischer ConfigVersion über `USP_DisableManagedWorkers` deaktivieren; die
Serverprüfung darf bei verbliebenen Claims/Holds/Reservations abbrechen.
Nach beendetem eigenem Provider und abgewickelten Zuständen lautet der Aufruf:

```sql
DECLARE @Config binary(8);
SELECT TOP (1) @Config=ConfigVersion FROM toolbelt_core.VW_WorkerStatus;
IF @Config IS NULL THROW 50000,N'Keine aktuelle Konfigurationsversion verfügbar.',1;
EXEC toolbelt_core.USP_DisableManagedWorkers @ExpectedConfigVersion=@Config;
```

Erwartung: `ManagedEnabled=0`; erst dann ist der direkte Standardclaim wieder
zulässig. Die Registrierungshistorie bleibt erhalten.

Keine Zustände durch direkte DML zurücksetzen. Demoressourcen werden wie im
[Queue-Lernweg](../../Modules/toolbelt.core.work-queue/Documentation/USAGE.md#bereinigung-und-wartung)
beschrieben entfernt.

Technische Details: [Worker-Control-Vertrag](../../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md),
[Providervertrag](../../Documentation/Architecture/EXTERNAL_QUEUE_WORKER_CONTRACT.md)
und [Implementierungsweg](../../Documentation/Reference/IMPLEMENTATION_GUIDE.md#worker).
