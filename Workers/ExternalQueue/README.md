# Externer Queue-Worker

Manuell gestarteter erster Provider für die einzeln freigegebene
Queue-Verarbeitung. Der [verbindliche Vertrag](../../Documentation/Architecture/EXTERNAL_QUEUE_WORKER_CONTRACT.md)
steht vor Source im Commit `1872985`. Der Worker verwendet den bestehenden
Work-Queue-2.0-Kern; er installiert keine SQL-Objekte oder Dienste.

## Voraussetzungen und Zulassung

PowerShell 7 mit funktionierendem `System.Data.SqlClient`; in derselben
Datenbank vorhandene Module `toolbelt.core.work-queue` 2.0.0,
`toolbelt.core.work-type` 1.1.0, `toolbelt.core.execution-context` 1.0.0 und
`toolbelt.core.execution-cancel` 1.0.0 samt deren Dependencies.
Vorhandene Rechte gelten; der Worker vergibt keine Berechtigungen.

Die Connection-Konfiguration wird privat in einer Prozess-Umgebungsvariablen
bereitgestellt. Das Startskript erhält ausschließlich deren Namen. Beispiele
enthalten keine Connection Strings, Credentials oder privaten Endpoints.

`WorkerEligibleWorkTypes` bestätigt die Eignung jedes exakten registrierten
Namens für diese Ausführung: NONE oder JSON_PAYLOAD, keine Resultsets,
keine eigenständigen Commits/Rollbacks oder externen Seiteneffekte, begrenzte
Schritte mit kooperativen Checkpoints. Registrierung allein genügt nicht.
Die bestehende Claim-API filtert diese Liste nicht: Ein dennoch beanspruchter
unzulässiger Work Type wird ohne Handlerausführung terminal abgewiesen.

## Start, Laufgrenzen und Drain

Nach privater Bereitstellung der Prozessvariable `TBX_WORKER_CONNECTION`:

```powershell
./Workers/ExternalQueue/Start-ExternalQueueWorker.ps1 `
    -ConnectionStringEnvironmentVariable TBX_WORKER_CONNECTION `
    -WorkerEligibleWorkTypes 'demo.noop' `
    -MaxRunSeconds 300 -MaxClaims 1000 -Slots 1
```

Default ein Slot, maximal acht. Lease 300 Sekunden, Heartbeat alle 60 Sekunden
auf separater Verbindung. Laufzeit oder Claimlimit stoppen neue Arbeit;
eine leere beanspruchbare Queue beendet den Lauf, sobald aktive Slots enden.
`StopFile` kann zusätzlich die Existenz einer privaten Stopdatei beobachten.
Der Worker legt diese Datei nicht an und gibt ihren Pfad nicht aus.

Drain hält laufende Arbeit und Heartbeats aufrecht. Nach der Gracefrist meldet
er aktive Arbeit und wartet weiter. `DefaultTimeoutSeconds` des Work Types
fordert kooperative Cancellation an; es ist kein harter Command-Timeout.
Die vollständige Laufzeit eines unkooperativen Handlers ist damit unbegrenzt.
Ein Hostabbruch kann diese Zusagen nicht aufrechterhalten.

## Abschluss, Cancellation und Fehler

Der Handler und `USP_CompleteWork` laufen in derselben eigenen SQL-Transaktion.
Nur ein bestätigter Commit gilt als erfolgreicher Abschluss. Ein späterer
Context-Cleanupfehler ändert dieses Ergebnis nicht. Unsichere Commit-,
Rollback- oder Controlausgänge bleiben `WORKER.OUTCOME_UNKNOWN` und werden
weder automatisch wiederholt noch recovered.

Die flüchtige lokale Statuszuordnung zeigt WorkItemId, ClaimGeneration und
ExecutionId ohne ClaimToken oder Payload. Manuelle Cancellation verwendet
`USP_RequestExecutionCancellation` für die aktuelle ExecutionId. Handler
bestätigen an eigenen Checkpoints gemäß Vertrag mit `THROW 50001`; eine
bloße Anforderung ist kein bestätigter Abbruch. Checkpoints verwenden die
Readonly-Sessionzuordnung `toolbelt.worker.execution_id`; eine abweichende
mutable Execution-Context-ID ist Drift und erhält keinen Retry.
Bestätigter Rollback führt
zu `FAILED` mit `WORKER.CANCELLED`.

Retry ist standardmäßig aus. `RetryEligibleWorkTypes` muss eine explizite
Teilmenge der Workerzulassung sein; `TransientSqlNumbers` klassifiziert
höchstens 32 Fehlernummern ausdrücklich als transient. Dauerhafte Fehler,
Cancellation, verlorene Ownership und ungeklärte Transaktionen erhalten
keinen Retry. Die bestehende Queue steuert Backoff und Dead Letter.

## Nachweise und Grenzen

Implementierung und Tests sind vorhanden; Runtime `partially validated`.
Die [Testmatrix](Tests/README.md) nennt ausgeführte und offene Kombinationen.
Windows-/Linux-Workerhosts und SQL-Ziele werden getrennt
bewertet. Die validierte Queue-Matrix beweist den neuen Worker nicht.

Die Summary unterscheidet `Claims`, `Completed`, `Failed`, `Retried`,
`DeadLetter` und `Unresolved`. Ihr `Status=COMPLETED` bezeichnet das Ende
des Supervisorlaufs und ist keine Zusage, dass jeder Claim erfolgreich war.
Ein ungeklärter Ausgang führt zu `Status=OUTCOME_UNKNOWN`.

Deterministische Fault-Prüfung:

```powershell
./Workers/ExternalQueue/Tests/Worker.Contract.ps1
```

Ausgewählte lokale Labprüfung:

```powershell
./Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest
./Tests/CI/run-external-queue-worker-lab.ps1 -Platform windows -Version 2025 -Patch base
```

Diese Befehle verwenden ausschließlich schema-validierte bereite Ziele und
eigene synthetische Datenbanken. Der direkte
[Runtime-Adapter](Tests/Runtime/Invoke-Contract.ps1) verwendet dieselben
Fixtures in CI. Testcode ist kein Ausführungsnachweis. Transportverlust bei
Commit verlangt belastbare Fault-Evidenz; künstliche Timeouts beweisen ihn
nicht automatisch.

Keine Veröffentlichung, Exactly-once-Zusage, dauerhafte Workerregistrierung,
supervisorübergreifende Slotgarantie, Dienstinstallation oder Agent-/Broker-
Implementierung aus diesem ersten Provider ableiten.
