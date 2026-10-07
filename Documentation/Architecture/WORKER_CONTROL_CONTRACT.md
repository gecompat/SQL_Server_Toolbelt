# Worker Control – verwalteter externer Queueprovider, Welle 2

Stand: 2026-10-04, Codex. Technischer Vor-Source-Vertrag für den ausdrücklich
freigegebenen Queue2-Scope. Implementierung vorhanden; Runtime-Nachweis
`partially validated`. Der SQL-Vertrag bestand auf 2019 Linux und 2025
Windows/CU8; Linux-Workerhost-Nachweis über exakte Head-CI bleiben offen.
Dieses Dokument selbst ist kein Produkt-PASS.
Einzelfreigaben und deren Grenzen stehen in [BACKLOG.md](../../.ai/BACKLOG.md)
und der [Entscheidungsvorbereitung](../Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md).
Dieser Vertrag präzisiert die bestätigte Semantik; er behauptet keine weitere
Benutzerentscheidung für seine technischen Namen oder Implementierungsdetails.

## Zweck und Grenzen

Der externe Windows-/Linux-Provider erhält persistente Registrierung,
providerübergreifende dynamische Admission, zentralen Dauerbetrieb, Stop mit
Rollback und dauerhaften Hold sowie explizite Wiederfreigabe für einen beliebigen
geeigneten Worker. Agent, Broker, SSIS, Dienstinstallation, Hostscripts, Raw SQL,
externe Handlerseiteneffekte und automatische Rechtevergabe bleiben ausgeschlossen.
Der [erste Worker-Vertrag](EXTERNAL_QUEUE_WORKER_CONTRACT.md) bleibt für
Handlerzulassung, Authentifizierung, atomare SQL-Seiteneffekte und Privacy gültig;
seine feste Acht-Slot-Grenze und rein kooperative Stopsteuerung werden ausschließlich
im explizit aktivierten Managed-Betrieb durch diesen Vertrag ersetzt.

Stop ist eine persistente Anforderung mit beobachtbarem Abschluss, keine harte
Zeitgarantie. Bereits committed Effekte lassen sich nicht rückwirkend rollbacken.
Fehlende Transportbestätigung, verlorener Host und ungeklärter Commit bleiben
ungeklärt; weder Timer noch Confirm-Boolean ersetzen den erforderlichen Nachweis.

## Module, Ownership und zyklusfreier Lifecycle

`toolbelt.core.worker-control` Version 1.0.0 ist eine neue T-SQL-Lifecycleeinheit
mit Abhängigkeit zur integrationsfähigen Folgeversion von
`toolbelt.core.work-queue` und den bereits verwendeten Execution-Context-/
Cancellationmodulen. Versionen werden vor Source im Manifest exakt festgelegt;
die vorhandene Queue 2.0.0 allein erfüllt den Managed-Integrationsvertrag nicht.
ResultTable-Nutzung benötigt die vorhandene ResultTable-Runtime. Keine automatische
Installation oder neue Assembly. Providerzustände und Queuezustände bleiben getrennt.

Die Queue besitzt die neutrale Admission-/Dispositionintegration einschließlich
einer internen ManagedGate-Konfiguration und generischer Claim-/Terminalschutzlogik.
Worker Control besitzt Registrierung, Reservation und Steuerungsfassaden.
Queue hängt nicht zurück an Worker Control: fehlt bei aktivem ManagedGate der
konform installierte Controlprovider, lehnen Mutationen vor Änderungen ab.
Ein manifestierter Compatibilityvertrag ersetzt keine zweite Claimauswahl.
Der kanonische Queue-Claimkern wird einmal extrahiert und sowohl im Legacy- als
Managed-Pfad verwendet; kein Kopieren oder implizites Umgehen des Gates.

Alle Tabellen sind interne, singulär benannte `CamelCase`-Objekte im Schema
`toolbelt_core`, ohne öffentlich freigegebenes DML. Benötigte technische Tabellen:
`WorkerControlConfiguration`, `WorkerRegistration`, `WorkerSlotReservation`,
`WorkerExecutionDisposition`, `WorkerExecutionCommitWitness` und queueeigene
`WorkQueueManagedGate`.
PK/UQ/FK/CK/DF/IX folgen den vorhandenen Namenskonventionen. Fremde Objekte
werden nicht adoptiert. Keine Cross-module-FK-Richtung, die den Lifecycle zyklisch macht.

Upgrade, Deaktivierung und Uninstall scheitern bei aktiven Reservations,
STOP_REQUESTED/STOPPING/UNKNOWN, ungeklärten Claims oder nicht abgewickelten Holds.
Persistente Aufträge/Historie werden nicht automatisch gelöscht. Reihenfolge:
Controlprovider datenwahrend abbauen, danach Queue; keine Entfernung des wirksamen
Gates bei verbliebenem Managed-Zustand. Vollständiger Preflight vor Mutationen und
erneut unter Lifecycle-AppLock, einschließlich sichtbarer fremder Abhängigkeiten.
Eine Deaktivierungsfreigabe ist aus dem Aktivierungs-Opt-in allein nicht ableitbar.
Der später ausdrücklich bestätigte kontrollierte Übergang umfasst nun Deaktivierung
ohne belegte Reservations/Claims, offene Holds oder UNKNOWN; kein automatisches Fallback.

## Persistente Identitäten und Zustände

### Datenwahrender Repeat im ruhenden Verbund

Der Wartungsauftrag vom 2026-10-07 zum aktuellen datenwahrenden Gesamtdeployment
umfasst einen engen Repeatpfad für bereits vollständig installierte Queue2.1
und Control1.0. Er ersetzt keine öffentliche Workerfunktion und autorisiert
keine Deaktivierung. Vor Mutation und erneut unter eigenen Lifecyclelocks
werden bekannte Eigentumsslots, Tabellenformen und Steuerzustände geprüft.
Ein unbekannter oder partieller Consumer wird nicht adoptiert oder repariert.
Routine-SourceHashes bleiben diagnostisch; der Tabellenvertrag ist ein eigenes
Compatibilitygate.

Der Pfad verlangt ein vorhandenes deaktiviertes Managedgate mit leerem
PendingReservationId, keine CLAIMED-Queuezeile und keinen ManagedHold.
Controlreservations müssen terminal und unbelegt sein; Holds und ungeklärte
oder laufende Ausführungen bleiben gesperrt. Registrierung, Generationen,
Konfiguration, Tokens, Rowversions, Dispositionen und Commitzeugen bleiben
erhalten. Der Installer setzt keine Zustände zurück, löscht keine Historie
und baut keine persistenten Controltabellen ab. Der Queue-Uninstall behält
seine Consumerabweisung. Der bisherige Genuine2.0→2.1-Upgrade ohne Control
und sein ausdrücklich erhaltener Legacyclaim sind ein anderer Pfad.

Beide Installer erwerben Lifecycle-AppLocks in der Reihenfolge Control→Queue.
Danach werden Gate, Scheduler und sämtliche beteiligten Control-/Queuetabellen
bis Commit gegen Schreibzugriffe gesperrt. Damit sind auch private Attempt- und
Dispositionpfade abgegrenzt, die keinen globalen Schedulerlock verwenden.
Der installierte Repeat verlangt eine frische exklusive Session mit
`@@LOCK_TIMEOUT = -1`. Andere Anfangswerte, eine Callertransaktion oder
IMPLICIT_TRANSACTIONS werden vor SET-/Temp-DDL abgewiesen. Die dynamischen
Vorprüfungen und Tabellensperren verwenden LOCK_TIMEOUT0; die anschließenden
Source-DDL-Batches sind durch LOCK_TIMEOUT5000 begrenzt. Nach Erfolg und in den
eigenen Fehlerpfaden wird der erlaubte Anfangswert -1 wiederhergestellt.
Ein Fehler in einem separaten Source-Batch verlangt den Abbruch der exklusiven
Deploymentsession; SQLCMD beendet sie, während der Testadapter ausschließlich
seine eigene frisch geöffnete Session zurückrollt. Das ist keine allgemeine
Wiederherstellung einer Callersession.
Es gibt keine neuen globalen Locks in Handler- oder Completionroutinen.

Dieser Pfad ist kein allgemeiner Schema-Repair und keine erfolgreiche
Gesamtdeployment- oder Plattformqualifikation. Die gezielten Nachweise und
offenen Grenzen stehen in der [Testmatrix](../../Modules/toolbelt.core.worker-control/Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md).

`WorkerId uniqueidentifier` ist technische stabile Supervisoridentität;
`WorkerGeneration bigint` steigt bei jeder Neuregistrierung, niemals wiederverwendet.
`WorkerToken uniqueidentifier` ist eine geheime Capability der Generation und wird
nur an ihren bereits berechtigten Callerprincipal ausgegeben. Gleiche Worker-ID
autorisiert keinen fremden Principal. Generationenüberlauf scheitert vor Änderung.
Neue Generation übernimmt keine Claims, Tokens, Connectionobjekte oder Slots.

Supervisorzustände: ACTIVE, PAUSED, DRAINING, UNREACHABLE, CLOSED.
Nur ACTIVE nimmt neue Arbeit an. PAUSED ist reversibel; DRAINING lässt bestehende
Arbeit fertiglaufen. UNREACHABLE ist keine Aussage zum Ende ihrer Handler.
CLOSED erst ohne aktive oder ungeklärte Reservations. Eine abgelaufene Generation
wird durch verspäteten Heartbeat nicht wiederbelebt.
Administrative PAUSED-/DRAINING-Disposition ist zusätzlich an die stabile
WorkerId gebunden. Nach Mehrfachstop oder administrativer Pause erbt eine neue
Generation derselben WorkerId die Admissionsperre bis ausdrücklicher Reaktivierung;
Neuregistrierung umgeht sie nicht. Die konkrete Stopauswahl der Ausführungen
bleibt trotzdem auf die ausgewählten Generationen begrenzt und trifft keine
späteren fremden Claims. Eine neu erzeugte WorkerId erfordert eigenständige
berechtigte Registrierung und darf keine Wiederaufnahme fremder Holds erklären.

Jede Reservation bindet `SlotReservationId uniqueidentifier`, Worker-ID/-Generation,
WorkItem-ID, Claimgeneration und neue `ExecutionId uniqueidentifier` an den
Claimtoken. Reserviert wird bereits vor Dispatch; Ackverlust zählt weiterhin.
Reservationzustände: RESERVED, RUNNING, STOP_REQUESTED, STOPPING, UNKNOWN,
COMMITTED, ROLLED_BACK, CLOSED. Terminale Fakten sind monoton. COMMITTED und
ROLLED_BACK sind Nachweise, UNKNOWN kein terminaler Frei-Slot-Zustand.

`WorkerExecutionDisposition` hält Stoprequest und Item-Hold außerhalb der
langlaufenden Handlertransaktion. `HoldVersion binary(8)` schützt explizite
Wiederfreigabe gegen konkurrierende Stoprequests. Hold bleibt über Workerwechsel,
Leaseablauf, Rollback, Fail, Retryplanung und Prozessneustart erhalten.
Ein WorkItem erhält dadurch keine zweite konkurrierende Queuezustandsmaschine:
sein vorhandener Status wird mit der kontrollierenden Disposition gelesen.

## Dynamische Budgets, Intervalle und Modus

Gesamtbudget pro Installations-/Queue-Datenbank: `MaxConcurrentExecutions int`,
0..2147483647, Default 1. Jeder Supervisor zusätzlich `Capacity int`,
1..2147483647, Default 1. Keine Acht-Slot-Grenze; Integerbereich ist keine
Ressourcen-/Kapazitätszusage. Keine CPU-/Inventarheuristik. Keine Vorallokation
des gesamten Budgets, nur Ressourcen für tatsächlich zugelassene Ausführungen.

Belegung wird durch persistentes IsOccupied bit unabhängig vom Evidenzstatus
bestimmt. RESERVED/RUNNING/STOP_REQUESTED/STOPPING/UNKNOWN sowie ROLLED_BACK
ohne committed finale Queueentscheidung zählen gegen globales und lokales Budget.
Erst nach Handlerende und committed Terminal-/Retry-/Heldentscheidung wird
IsOccupied=0 gesetzt; kein implizites Freiwerden nur durch Proofstatuswechsel.
Erhöhung erlaubt neue Admission; Reduktion beendet keine Arbeit
und sperrt neue Starts solange die belegte Anzahl nicht unter dem Budget liegt.
Budget 0 pausiert Admission, nicht Heartbeats, Rollback oder Stopbearbeitung.
Neue Registrierung erhöht niemals das globale Budget.

Konfiguration hat `ConfigVersion binary(8)`; mutierende Steuerung verlangt exakte
ExpectedVersion. CAS-Verlust liefert stabilen Konflikt ohne Teiländerung.
Heartbeat-/Nichterreichbarkeitsintervalle sind SQL-seitig konfigurierbar, Default
15/60 Sekunden. Technische konservative Auswahl: Heartbeat 1..3600 Sekunden,
Timeout 3..86400 Sekunden und Timeout >= 3*Heartbeat. Kein neuer Benutzerbeschluss
über diese numerischen Grenzen behauptet. Budgets gelten vor jeder Admission.
Heartbeat-/Timeouteinstellungen werden bei Registrierung einmal in die Generation
kopiert und persistent gebunden; Änderungen gelten nur für neue Generationen,
bestehende behalten ihre Intervalle. Timeout berechnet sich aus persistenter
SQL-UTC-Zeit, nicht Hostuhr.
WorkItem-Lease bleibt eigene Queuegrenze und wird nicht mit Registrierung verwechselt.

`RunMode varchar(16)` ist BOUNDED oder CONTINUOUS. BOUNDED erhält explizite
Run-/Claimbudgets; CONTINUOUS pollt bei leerer Queue weiter. Kein automatischer
Dienststart. Drain beendet Admission, wartet auf eigene Ausgänge und meldet
UNKNOWN ohne diese freizugeben. Konfigurations-/Steuerungspolls dürfen nicht durch
synchrone Handler-, Commit- oder Rollbackarbeit anderer Slots blockiert werden.

## Öffentliche SQL-Oberflächen

Alle Namen gehören zu `toolbelt_core`. Fachliche Parameter erhalten technische
NULL-Defaults, soweit Hilfe ohne Eingaben möglich sein muss. Bit-/Timingdefaults
sind unten explizit. Fachliche NULL ist außerhalb Hilfe nicht implizit gültig.
Jede USP hat Debug tinyint=0, Hilfe bit=0. Tabellenliefernde USPs erhalten exakt
den unveränderten Tail ResultTable sysname=NULL, KeepData bit=0, Debug, Hilfe.
Hilfe validiert keine Fachinputs, verändert nichts und ignoriert ResultTable/Debug.
Keine unerwarteten zusätzlichen Schedulerresultsets im Managed-Pfad.

| USP | Fachliche Parameter in Reihenfolge | Fachliches Ergebnis |
|---|---|---|
| USP_SetWorkerConcurrency | MaxConcurrentExecutions int=NULL, ExpectedConfigVersion binary(8)=NULL | ConfigVersion binary(8), MaxConcurrentExecutions int, OccupiedSlots bigint |
| USP_SetWorkerIntervals | HeartbeatSeconds int=NULL, UnreachableSeconds int=NULL, ExpectedConfigVersion binary(8)=NULL | ConfigVersion binary(8), HeartbeatSeconds int, UnreachableSeconds int |
| USP_RegisterWorker | WorkerId uniqueidentifier=NULL, Capacity int=NULL, RunMode varchar(16)='BOUNDED' | WorkerId uniqueidentifier, WorkerGeneration bigint, WorkerToken uniqueidentifier, ConfigVersion binary(8) |
| USP_HeartbeatWorker | WorkerId uniqueidentifier=NULL, WorkerGeneration bigint=NULL, WorkerToken uniqueidentifier=NULL | Kein fachliches Resultset |
| USP_SetWorkerState | WorkerId uniqueidentifier=NULL, WorkerGeneration bigint=NULL, RequestedState varchar(16)=NULL, ExpectedConfigVersion binary(8)=NULL | WorkerId uniqueidentifier, WorkerGeneration bigint, State varchar(16), ConfigVersion binary(8) |
| USP_SetWorkerCapacity | WorkerId uniqueidentifier=NULL, WorkerGeneration bigint=NULL, Capacity int=NULL, ExpectedConfigVersion binary(8)=NULL | WorkerId uniqueidentifier, WorkerGeneration bigint, Capacity int, ConfigVersion binary(8) |
| USP_ClaimWorkerWork | WorkerId uniqueidentifier=NULL, WorkerGeneration bigint=NULL, WorkerToken uniqueidentifier=NULL | Bestehende acht Claimfelder plus SlotReservationId uniqueidentifier und ExecutionId uniqueidentifier |
| USP_CloseWorker | WorkerId uniqueidentifier=NULL, WorkerGeneration bigint=NULL, WorkerToken uniqueidentifier=NULL | Kein fachliches Resultset |
| USP_EnableManagedWorkers | ExpectedConfigVersion binary(8)=NULL | ConfigVersion binary(8), ManagedEnabled bit |
| USP_DisableManagedWorkers | ExpectedConfigVersion binary(8)=NULL | ConfigVersion binary(8), ManagedEnabled bit |
| USP_StopWorkerExecution | SlotReservationId uniqueidentifier=NULL, ExpectedClaimGeneration bigint=NULL | SlotReservationId uniqueidentifier, ExecutionId uniqueidentifier, StopStatus varchar(24), HoldVersion binary(8) |
| USP_StopWorkers | WorkersTable sysname=NULL | WorkerId uniqueidentifier, WorkerGeneration bigint, SlotReservationId uniqueidentifier NULL, StopStatus varchar(24), HoldVersion binary(8) NULL |
| USP_ReleaseHeldWork | WorkItemId bigint=NULL, ExpectedHoldVersion binary(8)=NULL | WorkItemId bigint, ClaimGeneration bigint, Status varchar(16), HoldVersion binary(8) |
| USP_ReconcileWorkerExecution | SlotReservationId uniqueidentifier=NULL, ExpectedHoldVersion binary(8)=NULL | SlotReservationId uniqueidentifier, Outcome varchar(24), Occupied bit |

Sämtliche Resultspalten sind NOT NULL außer den angegebenen Ausnahmen und
dem unverändert nullable PayloadJson der bestehenden Claimform. Leerer Claim
liefert keine Zeile. Stopstatus REQUESTED, STOPPING, ROLLED_BACK_HELD,
ALREADY_COMMITTED oder UNKNOWN beschreibt Evidenz, keine synchron garantierte
Rollbackvollendung. Stoprequests sind generationgebunden idempotent; ein
erneuter Aufruf löst keinen zweiten Kill und keine neue Claimfreigabe aus.

WorkersTable ist ausschließlich vorhandene caller-lokale Temp-Tabelle mit
WorkerId uniqueidentifier NOT NULL, WorkerGeneration bigint NOT NULL, eindeutig
und höchstens 1000 Zeilen. Gesamtselektionslimit 100000 Reservations; Überschreitung
bricht vor Änderungen ab. Die Auswahl adressiert exakte Generationen; spätere
Generationen werden nicht getroffen. Jeder ausgewählte Supervisor erhält atomar
PAUSED und Hold/Stop für seine zum Linearisationpunkt belegten Reservations.
Diese WorkerId-Pause bleibt über Neuregistrierung erhalten; neue Generationen
werden nicht als zusätzliche physisch zu stoppende Ausführungen mitselektiert.
Leere Generation ohne Reservation liefert eine Zeile ohne Slot/Holdversion.
Keine implizite Wildcard nach Host, Principal oder Provider. Andere Supervisoren
können nicht gehaltene Arbeit weiter annehmen; kein globaler Shutdown.

Release benötigt bewiesenen Rollback/keinen Commit und nicht mehr laufende alte
Ausführung. Es entfernt den Hold und beginnt einen ausdrücklichen neuen Retryzyklus
unter vorhandener Queuepolicy, mit neuer Admission/Claim-/Executiongeneration.
Handler wird beim neuen Dispatch erneut aus aktuellem Work-Type-Katalog aufgelöst
und geprüft; keine automatische Handleränderung oder Raw-SQL-Einführung.
COMPLETED wird niemals requeued. UNKNOWN wird niemals per Confirm freigegeben.
Reconcile akzeptiert keinen willkürlichen Outcomeparameter und kein Confirmbit:
es liest nur persistierte beweiskräftige, exakt attemptgebundene Abschlussfakten.
Unzureichende Evidenz ergibt UNKNOWN/Occupied=1 ohne Mutationen am Claim.

VW_WorkerStatus liefert WorkerId, WorkerGeneration, ProviderKind, State, Capacity,
RunMode, HeartbeatSeconds, UnreachableSeconds, LastHeartbeatAtUtc, OccupiedSlots
und ConfigVersion. Beide Intervalle sind die persistent kopierten Werte genau
dieser Generation, nicht der inzwischen geänderte globale Default. Der Provider
liest sie nach Registration und verwendet sie für seine Controlplanung.
VW_WorkerExecutionStatus liefert SlotReservationId, WorkItemId, ClaimGeneration,
ExecutionId, WorkerId, WorkerGeneration, State, IsHeld, HoldVersion und StopStatus.
Alle Reservations bleiben sichtbar; die Disposition wird per LEFT JOIN ausschließlich
über die exakte WorkItemId und SlotReservationId zugeordnet. Nach Ablösung dieser
Disposition durch einen Folgeclaim ist HoldVersion NULL. IsHeld = 0 und StopStatus =
NONE (bei State = COMMITTED: ALREADY_COMMITTED) bedeuten dann ausschließlich,
dass keine aktuelle Disposition zu diesem historischen Attempt gehört; sie sind
kein Nachweis, dass dieser Attempt nie gestoppt oder gehalten wurde. Der eigene
persistierte Reservation-State bleibt als Endfakt erhalten. Eine historische
HoldVersion darf niemals aus der Disposition eines Folgeclaims übernommen werden.
Views veröffentlichen keine Tokens, Principals, Hostnamen, Pfade, Payloads oder
Verbindungsdaten. Objekt-/Spaltennamen, Collations und vollständige Outputs sind
in Headern/Help vor Source gekoppelt festzuhalten, nicht durch SELECT * abzuleiten.

## Atomare Admission und Lockreihenfolge

Verbindliche kurze Steuerlockreihenfolge: queueeigener Scheduler/ManagedGate,
Controlconfiguration, WorkerRegistration (nach WorkerId/Generation geordnet),
Reservation/Disposition (nach SlotReservationId geordnet), WorkItem.
Mutationen verwenden dieselbe Reihenfolge; ResultTable-Vorbereitung ist in dieselbe
atomare Operation integriert. Kein Controlpoll hält diese Locks während Handler-
oder Provider-Wait. Wo ein Pfad keine vorgelagerten Objekte benötigt, darf er
keinen später erworbenen Lock durch rückwärts gerichtete Steuerung ergänzen.

Admission überprüft aktuelle Konfiguration, ACTIVE-Generation/Principal/Token,
lokales und globales Occupiedbudget, Hold und Handlergeeignetheit; Reservation und
kanonischer Queueclaim committen in derselben kurzen SQL-Transaktion oder gar nicht.
Configänderung/Stop kann Admission nicht zwischen Prüfung und Commit überholen.
USP_ClaimWorkerWork verlangt @@TRANCOUNT=0/XACT_STATE=0 wie der bisherige
öffentliche Claim; nur sein geschützter neutraler Queuekern erhält die eigene
Admissiontransaktion. Ein vorgeschaltetes fachliches Resultset oder INSERT EXEC
ist kein zulässiger Weg, diesen Kern zu komponieren.
Handler wird erst nach bestätigtem Admissioncommit gestartet. Ackverlust bleibt
RESERVED/UNKNOWN, kein zweiter Claimversuch zum Reparieren eines unbekannten Ausgangs.

Aktivierung ist Opt-in, nur bei nachgewiesen claimfreiem Übergang unter demselben
Scheduler-Gate. Bereits gestartete Legacyclaims sind keine Managedgenerationen.
Nach Aktivierung lehnt direkte unverwaltete USP_ClaimWork vor Mutation ab.
Fehlender Controlprovider oder unklare Gate-/Versionsintegrität scheitert geschlossen.
Keine Sessioncontext-Boolean-Fassade als interne Autorisierung; Caller kann einen
Sessionkey setzen. Interner Kern wird nur durch geschützte verifizierte Pfade benutzt.

## Stop, Commitrennen und ownerunabhängiger Steuerpfad

SQL-Steuerung benötigt weder lebenden Supervisor noch dessen WorkerToken, wohl
aber vorhandene explizite Steuerberechtigung. Sie persistiert Stop+Hold zuerst
außerhalb der Handlertransaktion. Unterbrochener Steuercaller oder verlorenes
Ack lässt den bereits committed Request wirksam; Statusreconcile statt blindem
Retry unbekannter mutierender Commands. Mehrfachstopselection wird vor Mutation
eingefroren und atomar verarbeitet, nicht nachträglich dynamisch erweitert.
Der atomare Mehrfachstopp darf keinen globalen Scheduler-/Konfigurationslock
halten, während er auf einen privaten Completiongate wartet. Konforme Auswahl:
unter kurzer SQL-Transaktion sämtliche benötigten privaten Gates ohne Wartezeit
erwerben; sobald einer belegt ist, all-or-none ohne persistierte Teiländerung
abbrechen und sichtbaren Konflikt melden. Gleichwertig ist ein eigener vor Source
explizit dokumentierter eingefrorener Batch mit einzeln beobachtbaren Resultaten;
dieser darf keinen atomaren Gesamtabschluss behaupten. Der Sourcepfad muss genau
eine Variante wählen und seine Help-/Result-/Fehlersemantik daran binden.

Der externe Provider trennt Supervisor und proAusführung ExecutionGuardian.
Guardian besitzt die tatsächliche frische, ungepoolte Handlerconnection,
Transaction und Commandreferenz. Sein unabhängiger Controlpoll liest genau seine
Reservation/Executiongeneration und verarbeitet persistenten Stop auch nach
Supervisorverlust. Eine separate Steuerlane bleibt während async Handlercommand
und synchronem Commit/Rollback verfügbar; PowerShellcallback oder Supervisorloop
allein ist dafür kein Nachweis. Konkretes Thread-/Prozessmodell ist vor Runtime
zu belegen; Guardian darf keinen Handlerconnectionzugriff mit anderem SQLcommand
überlappen. Cancel ist gezielt auf das tatsächliche Commandobjekt gerichtet.

Bei beobachtetem Stop vor Dispatch startet kein Handler. Während des Commands
versucht Guardian SqlCommand.Cancel; nach Taskende führt er expliziten Rollback
aus und bestätigt Transaktionsende auf derselben Connection. Cancel-Rückkehr,
Connectionclose oder Fehlernummer allein beweisen keinen Rollback. Fehlender
Guardian/Host bleibt Stop UNKNOWN; keine garantierte physische Terminierung
eines nicht mehr erreichbaren Providers, kein automatischer Replay.

Completion und Stop serialisieren über die private Disposition dieser Reservation.
Der Completionpfad nimmt deren Gate erst im kurzen Abschlussabschnitt, prüft kein
Stop/Hold, exakte Generation/Token, Lease und Transaktionsdisziplin und hält es bis
zum äußeren Commit/Rollback. Stop gewinnt zuerst: Completion ist gesperrt, Handler
rollt zurück. Completion gewinnt zuerst: Stop wartet auf dessen echten Ausgang;
COMPLETED bleibt abgeschlossen und wird als ALREADY_COMMITTED gemeldet.
Kein globaler Scheduler-/Configlock bleibt über diesen Commit gehalten: dessen
Dispositiongate ist separat und darf nie nachträglich globale Locks anfordern.
Admission reserviert unter globalen Locks, prüft terminale Dispositionen aber
ohne Warten auf langlaufenden Abschluss; Konflikt scheitert/bleibt sichtbar.
Deadlocks sind Fehler, kein Stop-/Rollback-PASS, und dürfen keine Replayable-Facts erfinden.

Hold wird nie in derselben langen Handlertransaktion geschrieben und deshalb
nicht durch deren Rollback verworfen. Nach bestätigtem Rollback wird sein
Abschlussbeweis und die konsistente Queue-Fail/held-Disposition atomar separat
gespeichert. Lostack bleibt über exakt versionsgebundene Statusabfrage auflösbar.
Rollbacks können lange dauern; Admission zählt STOPPING weiter. Registrierungs-
oder Leaseablauf überschreibt diesen Zustand nicht.

Kein KILL nach gespeicherter SPID, kein DMVcheck-then-KILL und keine neuen
Serverrechte. Session-ID-Reuse ist kein beherrschtes Identityfencing.
Der vorhandene Cancellationrequest bleibt kooperatives Signal; er wird nicht als
bewiesener Sofortabbruch oder als alleinige Commitbarriere verwendet.

## Geschützte interne APIs und Rechte

Interne T-SQL-USPs mit Debug/Hilfe, ohne öffentliche Dispatchfreigabe:
USP_ReserveWorkerExecution (WorkerId, WorkerGeneration, WorkerToken),
USP_BindWorkerExecution (SlotReservationId, WorkerId, WorkerGeneration,
WorkerToken, ClaimGeneration, ClaimToken, ExecutionId),
USP_BeginWorkerTransactionWitness (SlotReservationId, ClaimToken, ExecutionId),
USP_BeginWorkerCompletion (SlotReservationId, ClaimToken, ExecutionId),
USP_RecordWorkerCommit (SlotReservationId, ClaimToken, ExecutionId),
USP_RecordWorkerRollback (SlotReservationId, ClaimToken, ExecutionId),
USP_RecordWorkerUnknown (SlotReservationId, WorkerToken, ExecutionId).
Zusätzlich USP_FinalizeWorkerFailure (SlotReservationId uniqueidentifier=NULL,
ClaimToken uniqueidentifier=NULL, ExecutionId uniqueidentifier=NULL,
FailureCode varchar(64)=NULL, Retry bit=0, Outcome varchar(24)=NULL OUTPUT,
Debug tinyint=0, Hilfe bit=0), ohne fachliches Resultset. Der OUTPUT-Status
enthält die bewiesene finale Entscheidung, keine neue öffentliche Fehler-API.
Identitytypen entsprechen den öffentlichen Feldern. Reserve ist der private
Kern von ClaimWorkerWork und erzeugt keine zusätzliche fachliche Claimlogik.
Bind prüft die gesamte Reservation-/Worker-/Claim-/Executionbindung und
persistiert RUNNING vor Handlerdispatch. Bind erwirbt auf der tatsächlichen
Handlerconnection vor RUNNING einen session-owned exklusiven AppLock mit frisch
geminteter Attemptnonce und niemals wiederverwendetem Attemptresource, gebunden
an Reservation/Executiongeneration. RUNNING-Bindung ist
einmalig; kein beliebiger Rebind auf eine andere Connection. Der Guardian hält
diesen Sessionlock bis nach bestätigtem Commit/Rollback und persistierter Enddisposition.
Frei setzbarer Sessioncontext, bekannte Nonce oder SPID sind kein Ersatz für
diesen serverseitig überprüften exklusiven Sessionbesitz.

BeginWorkerTransactionWitness verlangt diese Bindung, Sessionlockbesitz sowie
die eigene gesunde Handlertransaktion mit @@TRANCOUNT=1/XACT_STATE=1. Vor Handlerstart
wird genau eine eindeutig attemptgebundene Witnesszeile innerhalb dieser
Transaktion geschrieben. Ihre uncommitted Existenz bleibt mit allen SQL-Effekten
und Complete in derselben Transaktion; beim Rollback verschwindet sie, beim
Commit persistiert sie. Der Handler bekommt keine alternative API zum Löschen
oder unabhängigen Schreiben dieses Witness. Keine SQL-Seiteneffekte vor Witness.

BeginCompletion ist nur mit verifizierter Bindung, eigenem Sessionlock und eigener
Witnesszeile auf dieser Handlertransaktion zulässig. Es erwirbt zusätzlich den
transaction-owned privaten Completiongate bis äußeren Commit/Rollback. Bereits
persistierter Witness ohne konsistenten COMPLETED-Abschluss belegt möglichen
unerlaubten Handlercommit, nicht gesunden Erfolg: UNKNOWN und Hold, kein Retry.

RecordWorkerCommit ist eine private Dispatch-Endroutine ohne fachliches Resultset,
mit Debug/Hilfe und den oben definierten Identitytypen. Nach bekanntem erfolgreichem
äußeren Commit wird sie auf derselben tatsächlichen Handlerconnection mit
@@TRANCOUNT=0/XACT_STATE=0 und weiterhin eigenem Attempt-Sessionlock ausgeführt.
Sie prüft den exakten persistierten Witness und den konsistent atomar COMMITTED-
WorkItemabschluss (Queuezustand COMPLETED), persistiert COMMITTED/IsOccupied=0
und endet vor EndExecution/Connectiondispose. Der normale Dispatch benötigt
dafür keinen ADMIN-Reconcile-Aufruf oder dessen zusätzliche Steuerberechtigung.
Die öffentliche Reconcileroutine bleibt ein Ausnahmeweg mit den beschriebenen
End-/Commitnachweisen, kein notwendiger Bestandteil des normalen Workerabschlusses.

Geht das Endrecord-Acknowledge verloren, bleibt der bereits bestätigte SQL-Commit
eine bekannte Tatsache: kein Fail und kein Retry. Die Slotdisposition bleibt bis
zur sicheren versions-/attemptgebundenen Statusabfrage oder Reconcile ungeklärt,
falls deren Commit nicht nachgewiesen ist. Späte Guardian-, EndExecution- oder
Disposefehler sind sekundäre Control-/Cleanupfehler; sie überschreiben diesen
primären Commitfakt nicht und erfinden keine Rollback-/Replayberechtigung.

RecordRollback verlangt @@TRANCOUNT=0/XACT_STATE=0, persistierte Attemptbindung,
aktuellen exklusiven Sessionlockbesitz, bestätigten Providerrollback und eine
locking Abfrage, die das Fehlen des exakten Witness beweist. Nie SNAPSHOT,
READPAST oder READUNCOMMITTED für diesen Nachweis. Erst dann endet die Reservation
als ROLLED_BACK_HELD mit persistentem FAILED und erhaltenem Hold, sobald diese
terminalen Fakten atomar committed sind. Ohne Stop speichert RecordRollback
zunächst nur ROLLED_BACK als bestätigten SQL-Rollbackbeweis. Diese Reservation
zählt weiterhin, solange das Queueitem CLAIMED und die terminale Queueentscheidung
nicht committed ist. Boolesche Providerbehauptung oder Nonce allein genügt nicht.
RecordUnknown darf nur sichere Evidenz vermindern, niemals Slot freigeben.

FinalizeWorkerFailure konsumiert diesen attemptgebundenen Rollbackbeweis unter
demselben privaten Dispositiongate, prüft frisch Stop/Hold, Claimownership und
Lease und nutzt den kanonischen vorhandenen Fail-/Retrykern. Er bestätigt keinen
Rollback aus Eingabeparametern. Frischer Stop/Hold gewinnt über einen zuvor lokal
entschiedenen transienten Retry: FAILED mit Hold, kein RETRY_WAIT ohne explizite
Wiederfreigabe. Ohne Stop bleiben die bereits genehmigten transienten Retries
mit vorhandener Eignungs-/Fehlerallowlist und Queuebackoff/DeadLetter erhalten;
Retry=1 allein ersetzt diese Zulassung nicht. Bei nachgewiesenem Rollback und
abgelaufener Lease bleibt das Item gehalten zur expliziten Klärung, kein blinder
Retry über den alten Recoverypfad. Slotfreigabe erst nach committed terminaler
Queueentscheidung und tatsächlichem Handlerende; RecordProof allein genügt nicht.

Hostverlust-Reconcile versucht den exklusiven Attemptsessionlock ohne Wartezeit
und prüft darunter die genaue Witnesszeile mit UPDLOCK/HOLDLOCK auf einer frischen
gesunden READ-COMMITTED-Controlconnection mit begrenztem Lock-/Commandtimeout.
LateDispatch muss zuvor
durch persistierten Stop/Hold und einmalige Bindung ausgeschlossen sein. Die
Witnessabfrage wartet auf Abschluss einer gegebenenfalls noch rollbackenden alten
SQL-Transaktion; Sessionlockfreiheit allein beweist das nicht. Blockierung, Timeout,
fehlende Sicht oder widersprüchliche Bindung liefern UNKNOWN mit belegtem Slot.
Witness vorhanden plus atomar COMPLETED ergibt COMMITTED; Witness vorhanden ohne
COMPLETED ergibt UNKNOWN. Witness fehlt erst nach aufgelöster alter Transaktion
und nachgewiesen ausgeschlossener Ausführung ergibt ROLLED_BACK beziehungsweise
bewiesenes NoDispatch, jeweils Hold ohne automatische Wiederfreigabe.

Steuerrecht und Dispatchrecht bleiben getrennt: ADMIN kann Budget/State/Stop/
Release steuern, benötigt keinen fremden Workertoken. Dispatch muss Generation,
Principal und Token nachweisen. Attemptresources sind technische Identitäten,
keine geheimen Capabilitys. Schutz gegen direkte Aufrufe basiert auf vorhandenen
EXECUTE-Rechten plus Principal-/Capability-/serverseitiger Sessionlockbindung; keine Vertrauen-
in-Namenspräfixregel, kein frei setzbarer Sessioncontext als alleiniger Nachweis.
Module erstellen keine Benutzer, Logins oder Rechte. Fehlende Rechte liefern
vor Mutation nachvollziehbaren Fehler; Server-DMV-Rechte sind kein Pflichtpfad.
Keine neue Signatur-/EXECUTE-AS-/Ownerwechselgrenze ohne gesonderte Prüfung.

Managedclaims müssen bei vorhandenen Complete/Fail/Retry/Recovery/Requeue-USPs
denselben privaten Gate respektieren. Legacy-RecoverExpiredWork verändert keinen
Managed-/UNKNOWN-Claim nur aufgrund Leaseablaufs. Fail macht Hold nicht weg;
ScheduleWorkRetry macht gehaltene Arbeit nicht automatisch claimbar;
RequeueDeadLetter ersetzt nicht ReleaseHeldWork. Barrierclaims prüfen Hold vor
Admission; ihre bestehenden Gruppen-/Snapshotregeln werden nicht umgangen.
Ein gehaltenes Barrieritem darf seine Gruppe weiterhin blockieren; Status macht
diesen Grund sichtbar, keine automatische Barrierauflösung.

## Fehler, Privacy und begrenzte Abnahme

Fehlerklassen: Parameter/Configkonflikt, stale Generation/Token, Gate disabled/
unavailable, Occupied/Claimkonflikt, held/unknown Outcome, Rights/Visibility und
Providerfault. Stabile modulbezogene Codes/SQL-Ranges werden vor Source auf
Kollision geprüft; keine erfundene reservierte Fehlernummer in diesem Vertrag.
Ausgaben zeigen nur technische IDs, Zustände und Counts. Keine Fehlermeldungs-
oder Payloadkopie in Persistenz, Repository oder PR; Tokens/Nonce bleiben privat.
Alle Testdaten synthetisch. Lab-Konfiguration nur im AGENTS-Rahmen mit privaten
Restorejournalen, keine Pflichtinstallation/Serverrechteausweitung.

Erforderliche gezielte Orakel vor Merge:

1. Zwei Supervisoren, kleines Gesamtbudget; Live-Erhöhung/Reduktion/0 und
   lokale Capacityänderung ohne Überbuchung oder erzwungenen Abbruch.
2. CONTINUOUS wartet bei leerer Queue, BOUNDED bleibt begrenzt; Timingänderung,
   Generationsverlust und getrennte Heartbeats während blockiertem Commit/Rollback.
3. Claimfreier Opt-in und Legacy-Claim-Abweisung; falsche/private APIaufrufe
   scheitern; Version-/Dependency-/Lifecycle-/Uninstall-Schutz datenwahrend.
4. Stop vor Dispatch und im Handler; beide linearisierten Commit-vs-Stop-Ausgänge,
   bestätigter Rollback ohne synthetischen Effekt und dauerhafter Hold.
5. Mehrere Generationen in Stopauswahl, parallel neue Registration, keine
   unbeabsichtigt getroffenen späteren Generationen; andere Arbeit bleibt möglich.
6. Supervisorverlust bei lebendem Guardian, Guardian-/Transportverlust,
   Cancellation ohne Bestätigung und Controlackverlust bleiben ehrlich UNKNOWN.
7. Alte Recovery/Retry/Requeue/Barrierpfade umgehen Hold nicht; explicit Release
   nach Handlerkorrektur auf anderem geeigneten Worker, UNKNOWN-Release abgewiesen.
8. Vollständiger Hilfe-/ResultTable-/Clientmetadatenvertrag; atomare Ausgabe,
   keine privaten Werte; echte Rechtekontexte gesondert dokumentieren.

Große Budgetzahlen offline prüfen, nicht große Ressourcen auf kleinen Labzielen
erzwingen. Bestehende unveränderte Qualifikation wird nicht vollumfänglich wiederholt.
Unabhängiger Review und exakte erforderliche Head-CI sind separate Mergegates.

## Primärquellen und Evidenzgrenzen

Microsofts [SqlCommand.Cancel](https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlcommand.cancel?view=netframework-4.8.1)
beschreibt einen Abbruchversuch, keinen bestätigten Rollback; misslungene Cancellation
kann ohne Exception bleiben. [KILL](https://learn.microsoft.com/en-us/sql/t-sql/language-elements/kill-transact-sql?view=sql-server-ver17)
beschreibt Session-ID-Wiederverwendung und potenziell lange Rollbacks.
Quellen am 2026-10-04 geprüft. Guardian-/Controlmodell und SQL-Lockintegration
sind technische Designentscheidungen, keine aus diesen Quellen abgeleitete
Runtimegarantie. Die tatsächlichen Nachweise und offenen Grenzen stehen in der
[Vertragsmatrix](../../Modules/toolbelt.core.worker-control/Tests/WORKER_CONTROL_CONTRACT_TEST_MATRIX.md);
aus den Quellen allein folgt kein Stop-, Managed-, Recovery- oder Kapazitätsnachweis.
