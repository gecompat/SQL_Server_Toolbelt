# Externer Queue-Worker – erster Providervertrag

## Autorität, Scope und Status

Die ausdrückliche Einzelfreigabe vom 2026-10-01 steht im Abschnitt
„Bestätigter Worker-Vertrag und Abschlussauftrag“ in
[BACKLOG.md](../../.ai/BACKLOG.md). Dieses Dokument konkretisiert vor Source
den ersten, manuell gestarteten Windows-/Linux-Provider. Es führt keine neue
öffentliche SQL-API, fachliche Handlerfreigabe oder Queuezustandsmaschine ein.
Implementierung: `implemented`; Runtime-Validierung: `partially validated`;
Veröffentlichung: `unreleased`.

Nachweise und offene Workerhost-/SQL-Zielkombinationen stehen getrennt in
der [Worker-Testmatrix](../../Workers/ExternalQueue/Tests/README.md).
Die Windows-Host-Labprüfung vom 2026-10-02 besteht gegen SQL Server 2019
Linux/latest und ausgewählte bereite SQL-Server-2025-Windows-Ziele.
Echte Commit-Transportfaults, Minimalrechte, Recoveryrennen und zentraler
Deploymentmodus sind dadurch nicht vollständig qualifiziert.

PowerShell 7 und `System.Data.SqlClient` verwenden vorhandene Projektmittel.
Die konkrete Windows-/Linux-Treiberfunktion wird im Runtime-Test nachgewiesen;
vorhandener Testcode oder ein Windows-Typeprobe belegt keinen Linux-Support.
Fehlende Runtime wird gemeldet, ohne Installation oder Providerfallback.

Wiederverwendete Verträge:
[Work Queue](WORK_QUEUE_MODULE_DESIGN.md),
[Work Types](WORK_TYPE_MODULE_DESIGN.md),
[Execution Cancellation](EXECUTION_CANCELLATION_MODULE_DESIGN.md) und die
[Execution-Context-Objekte](../../Modules/toolbelt.core.execution-context/Documentation/EXECUTION_CONTEXT_OBJECTS.md).
Der interne Second-Session-Dispatcher wird nicht zum neuen öffentlichen
Workervertrag umgedeutet.

## Laufparameter und Budgets

| Parameter | Default | Zulässiger Bereich / Bedeutung |
|---|---|---|
| `Slots` | 1 | Ganzzahl 1–8, innerhalb eines Supervisors |
| `MaxRunSeconds` | 300 | Ganzzahl 1–86400; danach keine neuen Claims |
| `MaxClaims` | 1000 | Ganzzahl 1–100000; supervisorweiter Claimzähler |
| `ControlTimeoutSeconds` | 5 | Ganzzahl 1–30; kurze Steuercommands |
| `ConnectTimeoutSeconds` | 5 | Ganzzahl 1–30 |
| `PollSeconds` | 1 | 0,1–10 Sekunden |
| `GraceSeconds` | 30 | Ganzzahl 1–3600; erste aktive Drain-Meldung |
| Lease | 300 Sekunden | Fest für diese Welle |
| Heartbeat | 60 Sekunden | Fest; unabhängig vom Handlercommand |
| Handlercommand-Timeout | 0 | Kein treibergetriebener Zwangsabbruch |

Der erste erreichte Laufgrenzwert beendet neue Claims und startet Drain.
Ein vollständiger Claim-Durchlauf ohne beanspruchbare Arbeit und ohne aktive
Slots beendet den Lauf; zukünftige Retry-Fälligkeit bedeutet keinen
unbegrenzten Pollbetrieb. `MaxRunSeconds` begrenzt die Annahme neuer Arbeit,
nicht die maximale Lebensdauer eines unkooperativen laufenden Handlers.
Ein Supervisor vervielfacht sich nicht selbst; eine supervisorübergreifende
Slotgarantie gehört nicht zu dieser Welle.

Der Work-Type-Wert `DefaultTimeoutSeconds` ist ein kooperatives Laufbudget.
Bei Überschreitung fordert der Watchdog über die separate Control-Verbindung
einmal Cancellation für diese ExecutionId an. Ein fehlgeschlagener Request
wird als Controlfehler sichtbar; er gilt nicht als bestätigter Abbruch.
Kein `KILL`, `SqlCommand.Cancel`, erzwungenes Verbindungsclose oder fingierter
terminaler Queuezustand folgt aus Budget oder Grace.

## Authentifizierung und Zulassung

Die Verbindungskonfiguration wird ausschließlich vom Aufrufer privat
bereitgestellt und im Speicher verwendet. Keine Credentials, vollständigen
Connection Strings, privaten Endpoints oder Laufzeitpfade werden gespeichert
oder ausgegeben. Vorhandene Authentifizierung und Berechtigungen bleiben
maßgeblich; der Worker erteilt keine Rechte und verwaltet keine Dienste,
Jobs, Linked Server oder Lab-Ressourcen.

Authentifizierung nutzt die vom SqlClient unterstützte SQL-Anmeldung oder
bereits eingerichtete Integrated Security der privaten Konfiguration.
`Encrypt=true` ist vor Verbindungsaufbau erforderlich; der Worker aktiviert
keinen Zertifikats-Bypass. Ein ausdrücklich konfiguriertes
`TrustServerCertificate` bleibt die Entscheidung des Aufrufers und wird
nicht stillschweigend verändert. Ungeeignete Konfiguration scheitert mit
abstraktem Code, ohne Credential- oder Endpointausgabe.

Eine lokale explizite Liste exakter `WorkTypeName`-Werte erklärt die
Worker-Eignung der ausgewählten Handler. Die Liste ist keine eigene
Registrierung: Jeder Name muss zugleich im vorhandenen Katalog registriert,
enabled, vorhanden und vom Handlerprincipal ausführbar sein. Registrierung
oder `IsIdempotent` allein genügt nicht. Raw SQL und Hostscriptpayloads sind
ausgeschlossen. Ein Claim eines nicht zugelassenen Work Types führt ohne
Handlerausführung zu einem tokengebundenen terminalen Fail mit
`WORKER.UNSUPPORTED_HANDLER`. Dies nutzt die bestätigte Unsupported-Regel;
der Worker ergänzt keine alternative Claimauswahl oder Queue.

`USP_ResolveWorkType` wird auf der Handlerverbindung mit
`@RequireEnabled=1` und `@RequireExecutableByCaller=1` verwendet. Anschließend
wird die tatsächliche aktuelle Procedure-Signatur über Catalog Views geprüft:

- `NONE`: keine Eingabe- oder Ausgabeparameter; keine Payload.
- `JSON_PAYLOAD`: genau ein nicht-output Eingabeparameter
  `@PayloadJson nvarchar(max)`; JSON-Objekt im bestehenden Queue-Payloadlimit.

Handleridentifikatoren stammen ausschließlich aus dem aufgelösten Katalog
und werden sicher gequotet; Nutzdaten werden parametergebunden. Die
Ausführungsform verwendet `WITH RESULT SETS NONE`. Ein integer
Handlerreturncode bleibt informativ, soweit der konkrete freigegebene
Handlervertrag keine andere Interpretation festlegt. Nichtnull ist kein
generischer SQL-Fehler.

## Claimzuordnung und Verbindungen

Jeder Slot besitzt voneinander unabhängige Control- und Handlerverbindungen.
Handlerverbindungen werden pro Claim neu eröffnet. Alle Workerverbindungen
verwenden `ConnectRetryCount=0`, `Enlist=false`, `Pooling=false` und
`MultipleActiveResultSets=false`; automatische Wiederverbindung und
implizite Ambient-Transaktion sind ausgeschlossen. Controlcommands laufen außerhalb
einer Caller-Transaktion. Heartbeat erhält keinen Handlercommandlock.

Der Supervisor hält nur im Speicher die Zuordnung
`WorkItemId`, `ClaimGeneration`, `ExecutionId` und das geheime `ClaimToken`.
Jede neue Claim-Generation erhält eine neue ExecutionId. Token bleiben
außerhalb der Statusausgabe; Session-IDs sind kein Ownership-Beweis.
Nach Supervisorverlust besteht keine persistente Workerregistrierung oder
automatische Wiederaufnahme. Explizite Recovery bleibt eine separate,
bewusste Operation über `USP_RecoverExpiredWork`.

Der Parser liest sämtliche Claim-Resultsets. `USP_ClaimWork` liefert im
aktuellen Kern auch ein vorgeschaltetes `SchedulerId`-Resultset. Ein Parser
nimmt daher nicht das erste Resultset als Claim an, sondern identifiziert
genau die bestehende achtspaltige Claimform und akzeptiert höchstens eine
Claimzeile. Fehlende, widersprüchliche oder doppelte Claimformen führen zu
einem ungeklärten Controlausgang ohne Handlerdispatch oder Blindretry.

## Transaktion und Checkpoints

Der Worker startet auf der frischen Handlerverbindung mit
`USP_BeginExecution @AllowNested=0` den bestehenden Execution-Context.
Zusätzlich setzt er ausschließlich die privaten technischen Sessionkeys
`toolbelt.worker.work_item_id`, `toolbelt.worker.claim_generation` und
`toolbelt.worker.execution_id` über
`sys.sp_set_session_context` mit `@read_only=1`. Sie enthalten keine Tokens.
Sie sind bis zum Ende dieser nicht wiederverwendeten Verbindung unveränderbar.

Die Worker-Zulassung verlangt für diese Ausführung:

- Handler committen oder rollbacken die umschließende Transaktion nicht und
  verändern deren Isolation nicht. Zulässige innere Savepoints behalten die
  Eigentümerschaft des äußeren Workers bei.
- Keine unabhängigen externen oder autonomen Seiteneffekte; gesondert
  freigegebene Sonderhandler erfordern einen eigenen Vertrag.
- Begrenzte fachliche Schritte und kooperative Checkpoints vor weiteren
  Seiteneffekten; keine Handlerresultsets.

Diese Voraussetzungen ändern den allgemeinen Work-Type-Katalog oder den
bestehenden Second-Session-Vertrag nicht rückwirkend. Der Worker kontrolliert
vor Abschluss `@@TRANCOUNT` und `XACT_STATE()`; unerwartete Transaktionsdrift
ist kein nachweislich erfolgreicher Rollback und erhält keinen Retry.

Die eigene Handlertransaktion verwendet `READ COMMITTED`. Handlercheckpoints
lesen auf ihrer Verbindung aus `toolbelt_core.VW_WorkQueue` genau ihr
WorkItemId: `Status='CLAIMED'`, exakte `ClaimGeneration` aus dem unveränderbaren
Sessionkey und `IsLeaseExpired=0`. Zusätzlich prüfen sie
`toolbelt_core.SVF_IsCancellationRequested` für die immutable ExecutionId
aus dem privaten Workerkey. Die bestehende mutable Execution-Context-ID
muss mit ihr übereinstimmen; Drift führt zu ungeklärtem Ausgang ohne Retry.
Vor Start und vor Commit werden dieselben Bedingungen geprüft.
`SNAPSHOT` kann neue Cancellation oder Generationen verdecken;
`REPEATABLE READ`/`SERIALIZABLE` können Heartbeats blockieren. Deshalb sind
sie für diesen Handlervertrag ausgeschlossen. Statusbeobachtung ersetzt
keine tokengebundene Abschlussberechtigung.

Nach erfolgreichem Handler und letztem Checkpoint führt der Worker
`USP_CompleteWork` mit WorkItemId und ClaimToken in derselben
Handlertransaktion aus. Danach erfolgt der explizite Commit durch den Worker.
SQL-Seiteneffekt und Queue-Abschluss können so gemeinsam committen.
Handlercommands verwenden `SqlCommand.ExecuteNonQueryAsync`; der Supervisor
beobachtet Tasks ohne Runspaces. `SqlTransaction.Commit` bleibt eine
synchrone Providergrenze ohne konfigurierbaren Command-Timeout. Die
5-Sekunden-Steuergrenze ist daher keine Commit- oder Laufzeitgarantie.
Vor jeder synchronen terminalen Commit-/Rollback-Grenze erneuert der
Supervisor die Leases aktiver Slots;
Lange synchrone Startup-/Controlcommands und ein blockierender Commit können
dennoch deren nächste Heartbeats
verzögern. Eine durchgehend gesicherte Leasefähigkeit wird deshalb nicht
behauptet. Ein unbekanntes Transportergebnis bleibt ungeklärt.
Die Cancellation ist kooperativ: Eine Anforderung nach dem letzten Checkpoint
kann mit dem bereits begonnenen Abschluss konkurrieren.

`USP_EndExecution @ExpectedExecutionId` folgt als Cleanup nach bestätigtem
Commit beziehungsweise Rollback. Ein nach bestätigtem Commit fehlschlagender
Cleanup wird separat gemeldet und verwandelt Erfolg nicht in Fail oder Retry.
Die private Readonly-Zuordnung endet mit der verworfenen Handlerverbindung.

## Fehler, Retry und ungeklärter Ausgang

Eine bloß gesetzte Cancellation-Anforderung beweist keinen Handlerabbruch.
Ein zugelassener kooperativer Handler verwendet erst nach Beobachtung der
Cancellation seiner gebundenen ExecutionId an einem eigenen Checkpoint
`THROW 50001, N'Cooperative cancellation', 1`. Dieser numerische Wert ist
eine lokale Opt-in-Handlerkonvention und keine neue öffentliche
Toolbelt-SQL-Fehlerrange. Die Zulassung verbietet seine andere Verwendung.
Alternativ erkennt der Worker die Cancellation selbst am Vor-/Nachcheckpoint
und führt den kontrollierten Rollback aus. Der Handler verwendet dafür die
immutable Worker-ExecutionId und prüft die Übereinstimmung des bestehenden
Execution-Contexts. Nur nach solcher Bestätigung
und bestätigtem Rollback wird `USP_FailWork` terminal als `FAILED` mit
`WORKER.CANCELLED` ausgeführt.
Validierungs-, Rechte-, Unsupported- und andere permanente Fehler sind
terminal; nur abstrakte stabile Codes werden übertragen.

Retry ist Default aus. Er benötigt zugleich eine explizite Teilmenge der
lokal zugelassenen exakten Work-Type-Namen, eine explizite begrenzte Liste
numerischer transienter SQL-Fehler sowie nachgewiesenen Rollback ohne
Handlercommit. Die Fehlerliste ist standardmäßig leer, erlaubt höchstens
32 eindeutige positive Ganzzahlen und schließt Parameter-, Rechte-,
Unsupported-, Cancellation- und unbekannte Commitfehler aus.
Fehlermeldungstext und `IsIdempotent` allein entscheiden niemals Retry.
Der Worker verwendet ausschließlich `USP_ScheduleWorkRetry`; Backoff und
Dead Letter bleiben im Queue-Kern.

Ein verlorener Commit-Acknowledge, beschädigte Transaktionsdisziplin,
fehlgeschlagener Rollback oder verlorene Ownership wird als
`WORKER_OUTCOME_UNKNOWN` sichtbar. Der Worker führt dafür weder Fail noch
Retry oder automatische Recovery aus. Ein bereits gestarteter unbekannter
Controlcommand wird ebenfalls nicht blind wiederholt. Sichere Statusabfrage
kann Evidenz liefern; fehlende Evidenz bleibt ungeklärt. Die lokale Meldung
ist keine neue persistente Queuezustandsmaschine oder Exactly-once-Garantie.

## Shutdown und sichere Ausgabe

Optional signalisiert eine vom Aufrufer angegebene private Stopdatei Drain;
der Worker prüft nur deren Existenz und schreibt keine Pfadangabe in Ausgaben.
Ctrl-C ist nur dort ein gleichwertiger kooperativer Trigger, wo der Host dies
ohne Unterbrechen des Handlercommands zuverlässig implementiert und testet.

Drain stoppt neue Claims, hält Heartbeats laufender Claims aufrecht und wartet
auf deren kontrolliertes Ende. Nach `GraceSeconds` meldet der Supervisor
aktive beziehungsweise ungeklärte Arbeit und wartet weiter. Er behauptet
weder Cancellation noch Rollback allein aufgrund eines Stoprequests.
Verliert ein Slot seine Heartbeatfähigkeit, bleibt der Ausgang sichtbar
ungeklärt; keine verdeckte Wiederbelebung einer abgelaufenen Lease.

Ausgabe enthält nur Status, Counts, abstrakte Fehlercodes und nötigenfalls
WorkItemId/ClaimGeneration/ExecutionId als geschützte lokale Zuordnung.
Keine Handlerresultsets, Payloads, ClaimTokens, Verbindungsdaten,
Audit-Principals oder unveränderten SQL-Fehlermeldungen werden persistiert.
Öffentliche Testevidenz verwendet ausschließlich synthetische/redigierte
Angaben; private Runtime-Ausgabe wird nicht ins Repository oder PR kopiert.

## Testorakel vor Merge

Ausführungsstand je Scope: [Worker-Testmatrix](../../Workers/ExternalQueue/Tests/README.md).
Die nachfolgenden Orakel sind der Vertrag und keine pauschale PASS-Zusage.

1. Parameterdefaults und Grenzen; supervisorweites Claimlimit; maximal acht
   Slots; Stopannahme an Zeit-/Anzahllimit und leerer Queue.
2. Vorgeschaltetes Scheduler-Resultset, korrekte achtspaltige Claimform,
   leere Claims, doppelte/defekte Resultsets und unbekannter Claim-Acknowledge.
3. NONE-/JSON-Handler, Signaturdrift, Disabled/Missing/Permission/Payload,
   lokale Zulassung, Resultsetverletzung und informative Returncodes.
4. Synthetischer Handler länger als 60 Sekunden: unabhängige Sessions und
   Heartbeat, unveränderte Generation und verlängerte Lease.
5. Atomarer SQL-Seiteneffekt mit Complete/Commit, bestätigter Rollback bei
   Fehler, Cleanupfehler nach Commit ohne Retry und Transaktionsdrift.
6. Falsches Token, Leaseablauf, alte Generation, Generation nach Recovery,
   Context-/Readonly-Isolation und frische ExecutionId je Attempt.
7. Cancellation vor Start, zwischen begrenzten Schritten und vor Commit;
   terminaler Cancellationcode nur nach bestätigtem Rollback.
8. Retry opt-in/opt-out und Fehler-Allowlist; permanente Fehler, Dead Letter,
   bestätigter Rollback und Verbindungsverlust um Commit ohne Replay.
9. Watchdog, Stopdatei, Graceablauf mit unkooperativem Handler: weiterhin
   aktiv/heartbeating, kein forcierter Abbruch und kein erfundener Status.
10. Bestehende Drain-Barriers und explizite Recovery; lokales und zentrales
    Deployment; Sichtschutz und fehlende Fähigkeiten ohne Fallback.

Runtime-Adapter verwenden ausgewählte schema-validierte SQL_Server_Lab-Ziele
gemäß `AGENTS.md`. Windows und Linux werden getrennt belegt; weitere
SQL-Versionen folgen dem betroffenen Risiko. Vor Merge sind reproduzierbare
statische Prüfung, unabhängiger Review und erforderliche grüne CI nötig.
Persistenter Betrieb, supervisorübergreifende Slotgrenze, kontrollierter
Neustart, Agent/Broker-Provider und Dienst-/Jobinstallation bleiben Folge-Scope.

## Primärquellen

Die API-Signaturen und Providergrenzen stützen sich auf Microsoft Learn:
[ExecuteNonQueryAsync](https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqlcommand.executenonqueryasync?view=netframework-4.8.1)
und [SqlTransaction.Commit](https://learn.microsoft.com/en-us/dotnet/api/system.data.sqlclient.sqltransaction.commit?view=netframework-4.8.1).
Die Isolation und Lockauswirkungen werden gegen
[Table Hints](https://learn.microsoft.com/en-us/sql/t-sql/queries/hints-transact-sql-table?view=sql-server-ver17)
geprüft. Quellenprüfung am 2026-10-02; die Dokumentation ersetzt nicht die
ausstehende konkrete PowerShell-/SqlClient-/SQL-Server-Runtimequalifikation.
