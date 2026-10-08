# Work-Queue-Testevidenz

## Genuine Queue1.1: gespeicherte Definitionsform

Die vorhandenen Tests für andere Queueversionen bleiben getrennte Evidenz. Für den neuen genuine1.1-Fall korrigiert [ExportQueue11.Assert.sql](../../../Deployment/Tests/Runtime/ExportQueue11.Assert.sql) sechzehn vollständige UTF16LE-Erwartungen durch sourcefeste objektspezifische Headerabbildungen aus gepinnten Original1.1-/aktuellen Quellen. Zwei einmalige lokale SQL2019-/Linux-Metadatenproben bestätigten die private Erfassung der acht Definitionen und eigene DBbereinigung, zunächst nach sauberer Original1.1-Installation und danach nach einmaligem aktuellem Neunmodul-Export. Kein Fixture-Seed, Claim, Worker oder Repeat war Teil dieser Proben.

Strict-IF, fünf Modulflagprädikate, States und Verbatimdiagnosen bleiben unverändert; kein allgemeiner Normalizer, Runtimehashkopieren, zusätzlicher Akzeptanzhash oder Produkt-/APIwechsel. Die zuvor unveränderten Goldenwerte gehören zu den historischen Diagnose-Quellenständen. Alle acht Fehlprüfstände bleiben FAILED; f2a6/SQL55012/100 klassifiziert lediglich den damaligen festen Hashleaf `VW_WorkQueue`. Neue Dateibereinigung bleibt DEFERRED/RETAINED_UNPROVEN; die drei bisherigen Exportbereinigungen und Containercleanup sind davon getrennt. Keine rückwirkende Ursachenqualifikation.

Befüllte Queue1.1-Migration, neue Fixture-/Head-/Main-CI, zentraler Modus, Windows, weitere Versionen, Minimalrechte, Matrix und Release sind damit nicht qualifiziert. Neue gekoppelte Prüfungen und vollständiger Abschluss bleiben offen; Queue1.1 NOT_QUALIFIED. Definitionen und tatsächliche Runtime-/Labwerte werden ausschließlich privat gehalten.

Der `QueueUpgradeOnly`-Scope des externen Workeradapters prüft zusätzlich zum
echten Upgrade 2.0→2.1 zwei Wiederholungsdeployments auf Queue2.1 ohne
installierten Worker Control. `RepeatCurrent.Setup.sql` ergänzt synthetische
Zeilen mit allen sieben Statuswerten; `RepeatCurrent.Verify.sql` vergleicht
vollständige binär serialisierte Zeilen aus fünf persistenten Tabellen,
Tabellenidentität, Identitydefinition/-stand und vertrauenswürdige Checks/FKs.
Die Zustände sind eine direkte isolierte Datenfixture, kein Handler- oder
Schedulernachweis. PR283 qualifizierte diese Queueprüfung auf 2019 Linux;
der erweiterte Adapterstand bestand am 2026-10-07 auf 2019 Linux am Commit
`91507c65ac24051890a1775cc4264c8c119f549f`
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37672934548)).
Der gemeinsame Queue-/Control-Repeat wurde anschließend als eigene Fixture
ergänzt. Der gleiche Adapter schließt zuvor seine Legacyclaims ab, installiert
Control1.0 und prüft zwei ruhende Verbundrepeats mit allen zehn Tabellen.
Der [Controlnachweis](../../toolbelt.core.worker-control/Tests/README.md)
grenzt Zeilen-/Katalogvergleich, Fehlerfälle und offene Rechtekontexte ab.

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

2.1 ergänzt interne Claim-/Fail-/Retrykerne und den queueeigenen WorkQueueManagedGate. Öffentliche Signaturen bleiben unverändert. Managedmodus ist opt-in; dann sind direkte Claims und Holdbypässe ausgeschlossen. Admission ist transient, einmalig und an genau eine gesunde äußere Admissiontransaktion gebunden. Das Modul hat keine Rückabhängigkeit auf Worker-Control. Deploy prüft die enge ruhende Control1.0-Repeat-Ausnahme vor und unter Lifecycle-/Tabellenlocks; andere Consumerstände und Uninstall bleiben gesperrt. Vorhandene 2.0-Evidenz qualifiziert diese neue Integration nicht; der echte 2.0→2.1-Upgrade bestand am 2026-10-04 auf 2019 Linux; SQL-Managedfälle bestanden auf 2019 Linux und 2025 Windows/exakt CU8. Der vollständige parallele Providerlauf bleibt offen.


Genuine2.0→2.1: `Runtime/UpgradeFrom2_0.Setup.sql` wird nach tatsächlichem historischem Deployment aus Commit `62e7b06588b28c45c58f7ec335e4e5c45f120e3e` ausgeführt. Danach aktuelles2.1Deployment und `Runtime/UpgradeFrom2_0.Verify.sql` auf derselben Connection. Der explizite Snapshot enthält alle43Legacyspalten, drei Original-API-Zustände und Identitymetadaten. Private Extraktions-/Zieljournale gehören ausschließlich zum Orchestrator. Am 2026-10-04 bestand der fokussierte Lauf mit `Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -QueueUpgradeOnly`; weitere Upgrade-Plattformen nicht ausgeführt.
