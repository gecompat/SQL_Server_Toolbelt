# Worker Control – Testnachweise

Der Stand ist **partially validated**. Am 2026-10-04 bestand `Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -ManagedSqlOnly` auf einem schema-validierten, ausdrücklich ausgewählten SQL-Server-2019-Linux-Ziel. Statische Kopplung und Offlineparser sind keine zusätzliche SQL-Laufzeitqualifikation. Die gezielten parallelen Providerläufe sind unten getrennt belegt; die exakte Head-CI bleibt ein separates Mergegate.

`Static/validate_contract.py` prüft die Source-/Manifest-/Lifecyclekopplung, getrennten Completiontest vor Witnesszugriff, nonblocking GroupStop und Sessionfence bis Reconcile-Commit. `Runtime/WorkerControl.Contract.sql` prüft synthetisch Admission, Livebudget und pausenerhaltende Generationen auf einer isolierten Modulinstallation. Die parallelen Guardian-/Transaction-/Stop-/Commitnachweise liegen in `Workers/ExternalQueue/Tests/Runtime/Invoke-ManagedContract.ps1` und werden getrennt bewertet.

Vor Abnahme erforderlich: tatsächlich ausgeführte gezielte SQL- und Providerfälle, unabhängiges Review und grüne erforderliche CI. Fehlende Laufzeitfälle bleiben NOT EXECUTED. Keine Zielinventare, Connectionstrings oder realen Runtimeausgaben in Repositoryartefakten.


## Fokussierte Negativwelle – bestanden auf SQL Server 2019 Linux

Basic prüft vor Opt-in, falsche private Admission-/Bind-/Witnessautorität, die14 öffentlichen Helpobjekte und gehaltene SHARED-/Barrierarbeit (Recovery, Retry, Requeue, Complete, Fail, UNKNOWN-Release). Synthetische Leasealterung spart Wartezeit und ist kein tatsächlicher Handlerrollbacknachweis. Aktuelle Sourceorakel ändern keine öffentlichen APIs.

Lifecycle auf derselben isolierten, gejournalten DB nach erfolgreicher Basicfixture, ohne Actors oder konkurrierende Verbraucher:

| Vorbereitung | Snapshot | Tatsächliches Deploy | Tatsächliches Uninstall mit ConfirmNoExternalConsumers=1/AllowDataLoss=1 |
|---|---|---|---|
| Runtime/LifecycleOccupied.Setup.sql | Runtime/Lifecycle.Snapshot.sql | Fehler54242, State1 | Fehler54246, State2 |
| Runtime/LifecycleHeld.Setup.sql | Snapshot erneut | Fehler54242, State1 | Fehler54246, State2 |
| Runtime/LifecycleDependency.Setup.sql | Snapshot erneut | Fehler54243, State1 | Fehler54243, State1 |

Jeder tatsächliche Lifecycleaufruf verwendet eine eigene kurzlebige Connection derselben eindeutig eigenen DB. Die Snapshotconnection bleibt offen. SQLCMD-Includes und Variablen werden durch den vorhandenen privaten Adapter aufgelöst; es wird kein Produktcheck nachgebaut. Nach jedem beobachteten erwarteten Fehler führt die Snapshotconnection Runtime/Lifecycle.Verify.sql aus: alle sieben persistierenden Tabellen und Modulversionen müssen unverändert sein. Dieses Verify allein beweist ausschließlich Datenintegrität, keine Ausführung oder Ablehnung des Lifecycle.

Occupied wird durch explizite Holdfreigabe, Reactivation und echten Claim vorbereitet. Held entsteht durch echten Stop vor Dispatch und Reconcile mit LateDispatchfence, ohne fingierte Handlerrollbackbestätigung. Für die Fremdabhängigkeit werden vorhandene Holds ausdrücklich freigegeben und Managedmodus kontrolliert deaktiviert; die sichtbare synthetische View referenziert die öffentliche Statussicht. Root koordiniert alle Consumer und Cleanup. Keine weiteren Versionen-/Plattformläufe durch diese Fixtures.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-external-queue-worker-lab.ps1 -Platform linux -Version 2019 -Patch latest -ManagedOnly`
- Scope: Derselbe fokussierte Managedvertrag mit Windows-Workerhost gegen SQL Server 2019 Linux; zwei Supervisoren, Betriebsmodi, Stop/Rollback/Hold/anderer Worker, Dispositionrennen und Controltimeout/UNKNOWN/keine Übernahme.
- Ergebnis: `success including own cleanup; Linux-Workerhost durch aktuelle CI gesondert zu prüfen; Committransportverlust, minimale Rechte und weitere Ziele nicht ausgeführt`
<!-- END GENERATED:MODULE_EVIDENCE -->

Am selben Datum bestand der gleiche gezielte SQL-Vertrag mit `-Platform windows -Version 2025 -Patch CU8 -ManagedSqlOnly`. Diese Evidenz umfasst die SQL-Gates und Lifecycle-Abweisungen; sie ersetzt den vollständigen Providerlauf nicht.

## Fokussierter Windows-Providerlauf

Am 2026-10-05 bestand `Tests/CI/run-external-queue-worker-lab.ps1 -Platform windows -Version 2025 -Patch CU8 -ManagedOnly`, einschließlich eigenem Datenbank- und Datei-Cleanup. Zwei tatsächliche Supervisoren mit kleinen Budgets, leere BOUNDED-/CONTINUOUS-Modi, tatsächlicher Handlerstart und Abbruch/Rollback, persistenter Hold, Handlerkorrektur und Übernahme nach expliziter Freigabe durch den anderen Worker sowie der beobachtete Completion-/Stop-Wettlauf sind geprüft.

Ein gezielter eigener Zeilenlock erzeugte einen tatsächlichen Controltimeout: Guardianfehler, physischer Rollback und beendete Ressourcen wurden beobachtet; der ursprüngliche Ausgang blieb UNKNOWN und belegte den Slot. Ein anderer geeigneter Worker übernahm vorhandene QUEUED-Arbeit nicht. Erst ausdrückliche Admin-Reconciliation klassifizierte den Hold; die Wiederfreigabe blieb bis zum getrennten Endnachweis abgewiesen. Das beweist keinen Hostverlust oder Committransportverlust. Reale Minimalrechte und die vollständige Zielmatrix sind nicht ausgeführt; die exakte Head-CI bleibt ein separates Mergegate. Frühere fehlgeschlagene Läufe werden durch diesen Nachweis nicht rückwirkend aufgewertet.

Am selben Datum bestand der unveränderte fokussierte Managedadapter mit `-Platform linux -Version 2019 -Patch latest -ManagedOnly`, einschließlich eigenem Cleanup. Der Workerhost war Windows; ein Linux-SQL-Ziel qualifiziert allein keinen Linux-Workerhost.
