# Work-Queue-Testevidenz

Der `QueueUpgradeOnly`-Scope des externen Workeradapters prüft zusätzlich zum
echten Upgrade 2.0→2.1 zwei Wiederholungsdeployments auf Queue2.1 ohne
installierten Worker Control. `RepeatCurrent.Setup.sql` ergänzt synthetische
Zeilen mit allen sieben Statuswerten; `RepeatCurrent.Verify.sql` vergleicht
vollständige binär serialisierte Zeilen aus fünf persistenten Tabellen,
Tabellenidentität, Identitydefinition/-stand und vertrauenswürdige Checks/FKs.
Die Zustände sind eine direkte isolierte Datenfixture, kein Handler- oder
Schedulernachweis. Die neue Prüfung ist bis zur aktuellen CI `not executed`;
der gemeinsame Queue-/Control-Repeat bleibt ein eigener Umsetzungsscope.

Die Runtime-Suite verwendet ausschließlich synthetische Work Types, Payloads
und Datenbanken. Sie prüft Vertrag, Parallelität, Redeployment, zentrale
Installation, Datenverlustschutz und vollständigen Uninstall. Claim-Token und
Payloadwerte werden nicht als Repository-Evidenz persistiert.

Am 2026-09-10 lief die Work-Queue-v2-Suite auf synthetischen SQL-Server-2019-,
2022- und 2025-Linux-Zielen erfolgreich. Der lokale Adapter bestand am
2026-09-11 auf physischen Windows-Zielen derselben Versionen. Der Scope deckt
Retry/Dead Letter, Idempotenz, Barrier-Snapshot und -Parallelität, Upgrade,
Central, Lifecycle sowie Cleanup ab. Alle synthetischen Testdatenbanken werden
durch den Adapter entfernt.

Evidenzquelle: `GitHub Actions: Work-Queue Runtime #34533724721`.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-04`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -QueueUpgradeOnly`
- Scope: Echte ursprüngliche Queue-2.0-Installation auf SQL Server 2019 Linux; Upgrade auf 2.1, Erhalt bestehender Queuezeilen und aktiver Claims sowie unveränderter achtspaltiger Legacyclaim.
- Ergebnis: `success; weitere Plattformkombinationen dieses Upgrades nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->


## Work Queue 2.1 – neutrale Managedintegration

2.1 ergänzt interne Claim-/Fail-/Retrykerne und den queueeigenen WorkQueueManagedGate. Öffentliche Signaturen bleiben unverändert. Managedmodus ist opt-in; dann sind direkte Claims und Holdbypässe ausgeschlossen. Admission ist transient, einmalig und an genau eine gesunde äußere Admissiontransaktion gebunden. Das Modul hat keine Rückabhängigkeit auf Worker-Control. Lifecycle lehnt dessen installierten Consumer sowie Managedclaims und Holds vor und unter AppLock ab. Vorhandene 2.0-Evidenz qualifiziert diese neue Integration nicht; Der echte 2.0→2.1-Upgrade bestand am 2026-10-04 auf 2019 Linux; SQL-Managedfälle bestanden auf 2019 Linux und 2025 Windows/exakt CU8. Der vollständige parallele Providerlauf bleibt offen.


Genuine2.0→2.1: `Runtime/UpgradeFrom2_0.Setup.sql` wird nach tatsächlichem historischem Deployment aus Commit `62e7b06588b28c45c58f7ec335e4e5c45f120e3e` ausgeführt. Danach aktuelles2.1Deployment und `Runtime/UpgradeFrom2_0.Verify.sql` auf derselben Connection. Der explizite Snapshot enthält alle43Legacyspalten, drei Original-API-Zustände und Identitymetadaten. Private Extraktions-/Zieljournale gehören ausschließlich zum Orchestrator. Am 2026-10-04 bestand der fokussierte Lauf mit `Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -QueueUpgradeOnly`; weitere Upgrade-Plattformen nicht ausgeführt.
