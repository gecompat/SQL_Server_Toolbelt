# Worker Control – Vertragsmatrix

## Aktueller lokaler Windows-Providerumfang

Der [Abschluss der Teilmatrix](README.md#aktueller-abschluss-der-lokalen-windows-provider-teilmatrix)
belegt sechs lokale Kontexte mit tatsächlichem Windows-Workerhost:
SQL2019/CL150, SQL2022/CL150/160 und SQL2025/CL150/160/170, jeweils elf feste
Providerfälle, vollständiger Koordinator und separater frischer Audit.
Drei neue Restfälle schließen 2022/CL160 und 2025/CL150/160; drei bereits
grüne Kontexte werden wiederverwendet. Der alte 2022/CL160-Fehler bleibt
fehlgeschlagen und separat bereinigt, sein konkreter Auslöser ungemessen.
Der neue lesende Quieszenzpfad lässt den vollständigen Originalguard
unverändert. `FullProduct=false`, andere Deployment-/Rechte-/Providerumfänge
und echter Host-/Committransportverlust bleiben gesondert.

Die folgenden Abschnitte erhalten die vorherigen Zwischenstände und Risiken.

Die [weitere Windows-Providerabnahme](README.md#weitere-windows-providerkontexte-vom-2026-11-06)
belegt zusätzlich komplette Gesamtfälle auf 2019/CL150 und 2022/CL150 mit
je elf Fällen und frischen Audits. Auf 2022/CL160 bestand der Providerpfad,
der Gesamtkoordinator blieb wegen des Bereinigungsguards fehlgeschlagen;
separate Recovery und frischer Audit bestanden. 2025/CL150/160 wurden nicht
ausgeführt. Keine vollständige Providermatrix oder Aufwertung des Fehlers.

## Aktueller Windows-Providerkontext

Der [frische Nachweis vom 2026-11-06](README.md#aktueller-windows-workerprovider-vom-2026-11-06)
belegt den tatsächlichen Windows-Workerhost gegen WindowsSQL2025/CU8/CL170,
local, mit allen elf fokussierten Providerfällen und separatem frischem Audit.
Das unveränderte Providerergebnis bleibt `FullProduct=false`. Weitere
Versionen/CLs, Rechte und echter Host-/Committransportverlust werden dadurch
nicht geschlossen; historische Risiken unten behalten ihren Umfang.

## Aktuelle Windows-SQL-Ergänzung

Die [quellgebundene Teilabnahme vom 2026-11-06](README.md#aktuelle-windows-sql-gates-vom-2026-11-06)
belegt `WorkerControl.Contract.sql` und je sechs exakte, datenwahrende
Lifecycle-Abweisungen lokal auf Windows2019/CL150, Windows2022/CL150/160 und
Windows2025/CL150/160/170. Alle sechs separaten frischen Audits bestanden;
Produkt- und Fixtureorakel sind unverändert. Der genaue Quellen-, Patch-,
Adapter- und Bereinigungsbezug steht im verlinkten Nachweis.
Provider, Rechte und Transport-/Hostverlust bleiben getrennt.

## Historische risikobezogene Baseline

Die folgende Tabelle erhält die früheren abgegrenzten SQL-/Providerstände.
Die neue SQL-Teilabnahme wertet nicht pauschal sämtliche Tabellenrisiken auf.

| Vertragsrisiko | Gezielter Nachweis | Damaliger Laufzeitstatus |
|---|---|---|
| Globale Admission über zwei Supervisoren | Zwei Supervisoren mit Capacity 1, Budget 2; Senkung 1, Erhöhung 3, Nullbudget, UNKNOWN belegt | SQL-Vertrag und fokussierte Managedläufe auf 2019 Linux/2025 Windows CU8 bestanden; Windows-Workerhost |
| Stop/Hold gewinnt während Handlertransaktion | Actual Connection Cancellation/Rollback, keine Witness-Stop-Deadlocks; Stop mehrerer exakter Generationen | Einzelabbruch/Rollback/Hold im fokussierten Providerlauf bestanden; Mehrgenerationenstop separat SQL-geprüft |
| Commit gewinnt Stop | Privates Dispositiongate bis outer COMMIT und persisted Witness; Cleanupfehler kein Retry | Native Dispositionrennen und bekannter Commit gegen späteren Stop bestanden; echte Committransportfaults offen |
| Stop ist dauerhaft | Register nach Pause/Close/Unreachable bleibt AdmissionPaused; explizites ACTIVE reaktiviert | SQL-Vertrag 2019 Linux bestanden |
| Kein Replay nach Hostverlust | SessionAttemptlock + locking Witness, falsche Binding/CAS und committed-without-Complete UNKNOWN | Echter Controltimeout mit UNKNOWN/Slotbelegung/keiner Übernahme bestanden; Host-/Committransportverlust nicht nativ ausgeführt |
| Terminalhistorie monoton | FinalizeFailure → Reconcile belegt Slot nicht erneut; Folgeclaim versteckt alte Reservation nicht | NOT EXECUTED |
| Kein Holdbypass | Recovery, direkte Retry/Fail/Complete/Requeue lehnen Managed-/Heldclaims ohne private Proofbindung ab | SQL-Vertrag 2019 Linux bestanden |
| Lifecycle schützt Daten | Wiederholtes Deploy/Upgrade Queue2.0→2.1, fremde Slots/Dependencies, aktive Reservations/Holds; Uninstall AllowDataLoss und Sichtbarkeitsgate | 2019 Linux: echter Queueupgrade sowie sechs Deploy-/Uninstall-Abweisungen mit unveränderten sieben Tabellen bestanden; weitere Varianten offen |
| Ruhender Verbundrepeat | Zwei Queue2.1-/Control1.0-Repeats im vorhandenen QueueUpgradeOnly-Adapter; alle zehn Tabellen, binäre Zeilen/Tokens/Rowversions, Identitäten und semantischer Katalog; begrenzte Konkurrenz- und Rollbackabweisung | 2019 Linux am 2026-10-07 einschließlich eigenem Cleanup bestanden ([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37672934548)); weitere Verbundziele und nichtleere Benutzergrants nicht ausgeführt |
| ResultTable/Help | Exakte Spalten, Help vor Fachvalidierung, Ausgabe atomar | SQL-Vertrag 2019 Linux bestanden |

Statische Artefaktprüfungen qualifizieren ausschließlich ihre konkreten Kopplungen; Native Deploy, Runtime und Plattformqualifikation werden vom Orchestrator nach tatsächlicher Evidenz ergänzt. Eine vollständige Versionsmatrix wird durch diese risikobezogene Welle nicht vorausgesetzt.


Am 2026-10-04 bestanden auf SQL Server 2019 Linux: Basic-VorOptIn, private Admission-/Bind-/Witnessautorität, 14 Helpseiten, UNKNOWN-Release und gehaltene echte Barrier; LifecycleOccupied/Held/Dependency mit tatsächlichen SQLCMD-Aufrufen und vollständigen sieben Tabellen-Snapshots. Die erwarteten Enginefehler und unveränderten Daten wurden tatsächlich beobachtet. Die fokussierten Providerläufe bestanden am 2026-10-05 auf denselben zwei ausgewählten SQL-Zielen einschließlich Cleanup; Windows-Workerhost. Linux-Workerhost und exakte Head-CI bleiben getrennte Nachweise.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -ManagedOnly`
- Scope: Derselbe fokussierte Managedvertrag mit Windows-Workerhost gegen SQL Server 2019 Linux; zwei Supervisoren, Betriebsmodi, Stop/Rollback/Hold/anderer Worker, Dispositionrennen und Controltimeout/UNKNOWN/keine Übernahme.
- Ergebnis: `success including own cleanup; Linux-Workerhost durch aktuelle CI gesondert zu prüfen; Committransportverlust, minimale Rechte und weitere Ziele nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->

Der gleiche gezielte SQL-Vertrag einschließlich aller sechs Lifecycle-Abweisungen bestand außerdem auf SQL Server 2025 Windows, exakt CU8. Der Provider-Nachweis steht getrennt vom SQL-Nachweis in Tests/README.md.
