# Transactional Work Queue

## Security-Korrektur 2026-10-14

SC-029/SC-032: Die Legacyclaim-Prüfung erfolgt erneut unter einer bis Transaktionsende gehaltenen Tabellensperre. Der Barrier-Contract weist vorzeitige Barrierclaims vor Blockerabschluss ausdrücklich ab.
[Nachweise und Grenzen](../../Documentation/Architecture/SECURITY_CORRECTIONS_2026_10.md).

## Status

Aktueller Implementierungs-, Validierungs- und Releasestatus von Version
`2.1.0` stehen im [kanonischen Modulmanifest](module.yaml) und in der daraus
abgeleiteten [Modulübersicht](../README.md). Die
[Managedintegration](#work-queue-21--neutrale-managedintegration) und ihre
offenen Providergrenzen sind getrennt von älteren Plattformnachweisen zu lesen.
Das Modul bleibt `unreleased`.

Der [zusätzliche Callerrechtebericht](../../Releases/1.0.0/QUEUE-FRONTEND-RIGHTS-QUALIFICATION.md)
prüft sechs Producer-/Status-/Viewprofile. Das ältere Enqueue benötigt
zusätzliche Handler-Metadatensicht; die Blockerview ist nur leer geprüft.
Die [Worker-Callerrechte](../../Releases/1.0.0/QUEUE-WORKER-RIGHTS-QUALIFICATION.md)
ergänzen sieben Worker-APIs und eine befüllte Blockerview auf zwölf Ziel-/CL-
Kombinationen. Direkte Callerprofile sind damit abgedeckt; Managed-/Provider-/
Workerhost-, ResultTable- und andere Betriebsvarianten behalten eigene Gates.

### Historischer Stand 2.0

Version `2.0.0` ergänzt den E1a-/E1b-Kern um
persistierte Retry-Policies, Dead Letter, Idempotency Keys sowie priorisierte
gruppenbezogene Drain-Barriers. Das Modul bleibt `unreleased`.

Die Work-Queue-v2-Suite ist auf SQL Server 2019, 2022 und 2025 unter Windows
und Linux validiert. Dieser historische Nachweis gilt für die jeweils
datierten Quellen und qualifiziert die spätere 2.1-Integration nicht.

## Zweck

Das Modul reiht Aufträge für registrierte Work Types ein, beansprucht sie
atomar für eine begrenzte Lease und schließt sie mit einem nicht erratbaren
Claim-Token als `COMPLETED` oder `FAILED` ab. Heartbeats verlängern nur eine
noch aktive Lease. Eine ausdrückliche Recovery setzt abgelaufene Claims auf
`QUEUED` zurück und invalidiert das bisherige Token. Die interne Tabelle ist
kein öffentlicher DML-Vertrag.

## Öffentliche Objekte

- `toolbelt_core.USP_EnqueueWork`
- `toolbelt_core.USP_EnqueueWorkWithPolicy`
- `toolbelt_core.USP_EnqueueBarrierWork`
- `toolbelt_core.USP_ClaimWork`
- `toolbelt_core.USP_RenewWorkLease`
- `toolbelt_core.USP_RecoverExpiredWork`
- `toolbelt_core.USP_CompleteWork`
- `toolbelt_core.USP_FailWork`
- `toolbelt_core.USP_ScheduleWorkRetry`
- `toolbelt_core.USP_RequeueDeadLetter`
- `toolbelt_core.USP_GetWorkStatus`
- `toolbelt_core.VW_WorkQueue`
- `toolbelt_core.VW_WorkQueueBarrierBlockers`

`ClaimToken` und `PayloadJson` erscheinen ausschließlich im Claim-Ergebnis,
nicht in Statusabfrage, Recovery-Ausgabe oder View. Die Queue akzeptiert
niemals Raw SQL oder einen Handlernamen aus der Payload.

## Aussagegrenzen

Recovery ist bewusst weder automatisch noch Bestandteil von Claim. Ein alter
Worker kann den fachlichen Seiteneffekt bereits ausgeführt haben, bevor seine
Lease abläuft; sein späteres Complete oder Fail wird abgewiesen. Der Vertrag
ist deshalb At-least-once-fähig, verspricht aber weder Exactly-once noch
generische Idempotenz.

Retry erfolgt ausschließlich durch Workerentscheidung oder Orphan-Recovery;
`USP_FailWork` bleibt terminal. Ein Idempotency Key ist pro Work Type über die
Lebenszeit des Items eindeutig. Barriers sperren nur ihre ExecutionGroup,
warten auf den beim Enqueue gespeicherten Claim-Snapshot und präemptieren
niemals laufende Arbeit. Cancellation, Worker-Orchestrierung, Erkennung von
Systemzuständen und Log-Shrink bleiben außerhalb des Moduls. Ein Upgrade von
`1.0.0` oder `1.1.0` ist nur ohne aktive Claims zulässig.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -QueueUpgradeOnly`
- Scope: Echte ursprüngliche Queue-2.0-Installation auf SQL Server 2019 Linux; Upgrade auf 2.1, Erhalt bestehender Queuezeilen und aktiver Claims sowie unveränderter achtspaltiger Legacyclaim.
- Ergebnis: `success; weitere Plattformkombinationen dieses Upgrades nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->


## Work Queue 2.1 – neutrale Managedintegration

2.1 ergänzt interne Claim-/Fail-/Retrykerne und den queueeigenen WorkQueueManagedGate. Öffentliche Signaturen bleiben unverändert. Managedmodus ist opt-in; dann sind direkte Claims und Holdbypässe ausgeschlossen. Admission ist transient, einmalig und an genau eine gesunde äußere Admissiontransaktion gebunden. Das Modul hat keine Rückabhängigkeit auf Worker-Control. Der Deploy-Lifecycle erlaubt einen installierten Control1.0-Consumer nur beim vollständig geprüften ruhenden Queue2.1-Repeat; andere Consumerstände, aktive Managedgates, Claims und Holds bleiben gesperrt. Der Uninstall behält seine Consumerabweisung. [Repeatgrenze](../../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md). Vorhandene 2.0-Evidenz qualifiziert diese neue Integration nicht; der echte 2.0→2.1-Upgrade bestand am 2026-10-04 auf 2019 Linux; SQL-Managedfälle bestanden auf 2019 Linux und 2025 Windows/exakt CU8. Der vollständige Providerabschluss bleibt offen.

## Freigegebene Security-Härtung 2026-10-15

Enqueue (einschließlich Policy/Barrier und Idempotency-Auskunft) verlangt ENQUEUE.
Claim/Managedclaim verlangt CLAIM und Handler-EXECUTE vor Reservierung und
Payloadausgabe. Die Worker prüfen CLAIM vor Handlerausführung erneut. Fehler
51998 bedeutet fehlende Producerautorität; 51596 entzogene Workerautorität.
DRAIN_BARRIER in Callertransaktionen wird mit 51997 vor Mutation abgewiesen.
Normales SHARED-Enqueue bleibt erlaubt. Abhängigkeit: Katalog 1.2.0 mit Policy.

Der [freigegebene Vertrag](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md)
beschreibt Scope, Migration und Grenzen. Historische Plattformnachweise gelten
weiter ausschließlich für ihre datierten Quellen.
