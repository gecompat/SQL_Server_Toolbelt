# Worker-Qualifikation

## Flüchtiges CI-Ziel: Ownership und Bereinigung

Der bestehende Linux-Workerworkflow verwendet einen validierten Run-/Attempt-
Namen und ein eigenes zufälliges Ownerlabel. Name und Owner werden vor dem
Dockerstart an den getrennten `always()`-Cleanupstep übergeben. Eine gemeinsame
Inspection bindet vollständige Container-ID und Owner; nur diese eigene ID
wird entfernt. Fremder Bestand, fehlende Sicht oder fehlgeschlagene frische
Namensabwesenheit scheitern mit `WORKER_CI_CLEANUP_UNVERIFIED`. Erfolgreich
bestätigte Bereinigung meldet `WORKER_CI_CLEANUP_VERIFIED`. Ein zuvor
fehlgeschlagener GitHub-Step bleibt fehlgeschlagen.

`python -B Workers/ExternalQueue/Tests/CiTarget.Contract.py` bestand am
2026-10-07 lokal auf Windows 20 synthetische Fälle an den tatsächlich
extrahierten Startup-/Cleanupsteps: genaue Dockerargumente, Run/Attempt,
Ownererzeugung, Startupfehler mit vorheriger Identitätsübergabe, volle ID,
fremder/ersetzter Name, fehlende Sicht, Removefehler und frische Abwesenheit.
Die Prüfung ist auf 45 Sekunden insgesamt und fünf Sekunden je Prozess
begrenzt; zwei Sourcepins werden vor und nach dem Lauf geprüft. Sie verwendet
Git-Bash ohne echte OpenSSL-/Docker-/SQL- oder Labaktionen. Beide vorhandenen
Faultjobs führen diese Offlineprüfung aus. Exakte Head-/Main-CI steht separat
im jeweiligen Pull Request; dies qualifiziert keine harte Hostunterbrechung,
Minimalrechte oder breitere Zielmatrix. Der Labadapter ist nicht betroffen.

## Welle 2: isolierte Ausführungsakteure

Am 2026-10-04 besteht die gezielte Offlineprüfung
`pwsh -NoProfile -File Workers/ExternalQueue/Tests/ExecutionActors.Contract.ps1`.
Tatsächliche getrennte Runspaces prüfen Guardianfortschritt während eines
synthetisch blockierten Executorabschlusses, Cancellation der exakt gebundenen
Instanz, Abweisung veralteter Command-Epochen, unbekannten Ausgang ohne
Rollbacknachweis sowie Guardian-/Executorverlust. Eigene Runspaces werden erst
nach ihrem tatsächlichen Ende entsorgt. CancellationTokenSource dient nur als
synthetischer Instanzzeuge; dies ist kein SQL-Abbruch- oder Commitfaultnachweis.

Der ausdrücklich gewählte `-Managed`-Pfad bindet jetzt SQL-Admission,
sessiongebundenen Reservation-AppLock, Transaktionswitness, Stop/Hold und
tokengebundenen Abschluss an den Worker-Control-Vertrag. Der Default bleibt
Welle 1. `ManagedWorker.Contract.ps1` prüft echte typisierte Reader und
SqlCommand-Parameter ohne Netzwerk. Die Actorprüfung belegt zusätzlich einen
gelatchten Stop vor Taskstart, die Readerlease während eines blockierten Cancel
und bestätigten Commit trotz nachfolgendem Cleanupfehler.

Der fokussierte Runtimeeinstieg ist `Tests/Runtime/Invoke-Contract.ps1
-ManagedOnly`. Er verwendet eine eigene frische Testdatenbank und die
synthetischen Fälle in `Invoke-ManagedContract.ps1`: Budget 0/2/1,
Cancellation/Rollback/Hold, explizite Wiederfreigabe, Legacy-Claim-Abweisung
und Completion-/Stop-Rendezvous. Quellcode ist kein Laufnachweis.
Die gezielten aktuellen SQL-/Managedläufe sind weiter unten dokumentiert.
Die unten verlinkte Head-CI belegt einen tatsächlichen Linux-Workerhost im
begrenzten synthetischen SQL-2019-Scope; weitere Host-/Zielkombinationen bleiben
getrennte Nachweise.

Der synthetische Controltimeout-Fall hält den eigenen Reservation-Zeilenlock
erst dann über die fünfsekündige Controlfrist, wenn ein wartender Request auf
genau dieser Lockressource beobachtet wurde. Ein nicht erreichter Rendezvous
scheitert als Fixturefehler; die UNKNOWN-/Rollback-/No-Replay-Orakel bleiben
unverändert.

Am 2026-10-06 bestand `pwsh -NoProfile -File
Workers/ExternalQueue/Tests/ManagedWorker.Contract.ps1` auf Windows zusätzlich
mit acht Offline-Summary-Orakeln: Registrierungsverlust ohne Claims und nach
bestätigtem Commit, unbekanntes Lane-Ende, verbliebener Actor sowie Vorrang
von ungeklärtem Ausgang, fehlendem Slot-Endrecord und Cleanupfehler. Die finale
Aggregation erfolgt nach dem Lane-Cleanup und erhält bestätigte Zähler.
Dies ist kein neuer SQL-Transportfault- oder physischer Zielnachweis.

## Ausgeführter deterministischer Scope

Am 2026-10-02 besteht `pwsh -NoProfile -File
Workers/ExternalQueue/Tests/Worker.Contract.ps1` auf dem Windows-Workerhost.
Fault-Orakel prüfen unbekannten Commit/Rollback ohne Replay, Ownershipverlust,
Cancellation-Bestätigung, Default-/Slot-/Claimbudgets, Heartbeat im Drain,
Watchdog und bestätigten Commit mit getrenntem Cleanupfehler.
Geschlossene synthetische SqlConnections prüfen die tatsächliche
Callback-/Parameterbindung ohne Netzwerkzugriff.

Dies belegt die geprüfte Supervisorpolitik und die lokale Bindung.
Es simuliert keinen realen Transportverlust bei einem SQL-Commit.

## Runtime-Matrix

| Workerhost | SQL-Ziel | Provider/Scope | Nachweisstand |
|---|---|---|---|
| Windows | 2019 Linux/latest | Lokaler Lab-Adapter, vollständige synthetische Fixtures | erfolgreich am 2026-10-02 |
| Windows | 2025 Windows/CU8, über allgemeinen base-Selektor mit erlaubter CU-Äquivalenz | Lokaler Lab-Adapter, vollständige synthetische Fixtures | finaler Source-Stand erfolgreich am 2026-10-02 |
| Linux | 2019 Linux | CI-Adapter mit eigener synthetischer Instanz | erfolgreich am 2026-10-02, [CI-Run](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/36939743866) |
| Windows/Linux | übrige Versionen und Zielkombinationen | Getrennte weitere Qualifikation | `not executed` |

Die [Fixtures](Runtime/Fixtures.sql) und der
[Runtime-Adapter](Runtime/Invoke-Contract.ps1) prüfen NONE/JSON, Unicode,
informative Returncodes, atomaren SQL-Effekt/Complete, Rollback, Unsupported-
und Resultsetfehler, Retry/Dead Letter, manuelle Cancellation und Watchdog,
parallele Slots, Stop/Grace sowie einen Handler über 60 Sekunden mit erneuerter
Lease. Contextdrift darf weder einen Commit noch einen Retry erzeugen.

Die Lab-Auswahl folgt dem schema-validierten Vertrag und dem READY-Gate aus
`AGENTS.md`; ein allgemeiner Windows-base-Lauf prüft deterministisch alle
bereiten base-/CU-Ziele dieser Version. Keine Lab-Infrastruktur- oder
Serverparameteränderung gehört zu diesem Test.

Die zusätzlichen fokussierten Identity-Tests mit `-IdentityGuardsOnly`
bestehen am 2026-10-02 auf beiden ausgewählten Zielen: tatsächlicher
SQL-Readonly-Fehler 15664 bleibt trotz expliziter Retry-Allowlist terminal,
der synthetische Effekt wird zurückgerollt. Mutable Contextdrift erzeugt
einen ungeklärten Claim ohne Retry oder committed Effekt.
Die vorherigen Volltests bleiben als eigener Nachweis erhalten; nach der
engen Scheduling-Härtung besteht der finale vollständige Windows-2025-Lauf.
Der CI-Run prüft denselben Worker-Source zusätzlich auf einem Linux-Host,
einschließlich vollständiger synthetischer Runtime-Fixtures, unabhängigem
60-Sekunden-Heartbeat und erfolgreichem Cleanup. Die deterministischen
Fault-Verträge bestehen dort getrennt auf Windows und Linux.

## Offene Nachweise und Cleanup

Echte Commit-Transportfaults, Cross-Principal-Minimalrechte, Recoveryrennen
und zentraler Deploymentmodus bleiben separate offene Runtime-Orakel.
Die bestehenden SQL-Kernnachweise werden nicht als Worker-Nachweis übernommen.
Die Host-/Versionsmatrix, Produktionskapazität und permanenter Betrieb sind
keine aus diesen Tests ableitbaren Zusagen.

Der Adapter erzeugt eine eindeutige eigene synthetische Datenbank und wartet
vor Cleanup auf alle eigenen Worker. Er entfernt sie ohne SQL-KILL oder
`ROLLBACK IMMEDIATE`. Unvollständiger Cleanup scheitert sichtbar; private
Diagnostik und Verbindungskonfiguration werden nicht versioniert.

Der [Providervertrag](../../../Documentation/Architecture/EXTERNAL_QUEUE_WORKER_CONTRACT.md)
legt Akzeptanzkriterien, Autorität und Grenzen fest. Plan und Testcode sind
kein erfolgreicher Ausführungsnachweis.

## Managed Welle 2: gezielte aktuelle Evidenz

Der fokussierte Managedlauf mit `Tests/CI/run-external-queue-worker-lab.ps1 -Platform windows -Version 2025 -Patch CU8 -ManagedOnly` bestand am 2026-10-05 einschließlich eigenem Cleanup. Der [Worker-Control-Nachweis](../../../Modules/toolbelt.core.worker-control/Tests/README.md) trennt die tatsächlich beobachteten Betriebs-, Stop-, Release-, Wettlauf- und Controltimeoutfälle von offenen Host-/Committransportfaults und Rechtekontexten. SQL-Verträge und sechs echte Lifecycle-Abweisungen bestanden separat auf 2019 Linux und 2025 Windows/CU8; echter Queue-Upgrade auf 2019 Linux. Ein Windows-Worker gegen ein Linux-SQL-Ziel ist kein Linux-Workerhost-Nachweis; dieser wird durch die passende aktuelle CI gesondert erbracht.

## Ruhender Queue-/Control-Repeat

Der zusätzliche `QueueUpgradeOnly`-Scope ergänzt nach dem echten Upgrade
und zwei Queue2.1-Repeats zwei ruhende Queue-/Control-Repeats. Eigene
Legacyclaims werden zuerst abgeschlossen; die vollständig installierte
Control1.0-Historie bleibt erhalten. Der Zeilen-/Katalogvergleich umfasst
alle zehn Tabellen einschließlich WorkType. Ein eigener Sperrhalter und
ein synthetischer DDL-Fault prüfen Abbruch ohne Datenverlust; keine neuen
Jobs, Provider oder Rechte. Dieser Scope bestand am 2026-10-07 auf SQL Server
2019 Linux am Commit `91507c65ac24051890a1775cc4264c8c119f549f`
einschließlich eigenem Cleanup
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37672934548));
der [Controlnachweis](../../../Modules/toolbelt.core.worker-control/Tests/README.md)
führt die Fälle und offenen Grenzen getrennt. Weitere Verbundziele und
nichtleere Benutzergrants bleiben nicht ausgeführt.

## Historischer Queue-Capture: Helperkopplung2026-10-05

Die bekannte Prozesshelper-Pin ist nach der qualifizierten Erweiterung seiner
Timeoutobergrenze von120000 auf900000 Millisekunden aktualisiert. Der Capture
selbst bleibt auf5000 Millisekunden je Prozess und60000 insgesamt begrenzt;
Queue2.0-Commit,15 Originalblobs und14 Includebindungen bleiben unverändert.
Änderungen des Helpers lösen jetzt auch die Worker-CI und Work-Queue-
Impactprüfung aus. Kein Abschwächen der Hash- oder historischen Blobprüfung.

Der vorherige Linux-CI-Lauf scheiterte vor der Migration mit
`HISTORICAL_PROCESS_HELPER`; dies bleibt ein fehlgeschlagener Lauf.
Ein tatsächlicher Offlinecapture mit dem korrigierten exakten Helperpin
bestand am2026-10-05:15 Blob-Identitäten und Bytes,14 Includes, Manifest und
abschließende Toolpins. Neue SQL-Migrations-CI bleibt ein separater Nachweis.

Am 2026-10-06 änderte sich derselbe Helper ausschließlich für feste,
datensparsame Fehlerkategorien. Der erste PR197-Worker-CI-Lauf wies den dadurch
veralteten exakten Pin mit `HISTORICAL_PROCESS_HELPER` ab, bevor historische
Blobs oder die Migration verarbeitet wurden; dieser Lauf bleibt fehlgeschlagen.
Der Pin wurde auf die überprüften neuen Helperbytes aktualisiert. Die
historischen Queue2.0-Quellen und ihre 15 Blob-/14 Include-Prüfungen bleiben
unverändert. Am exakten [PR197-Head](https://github.com/gecompat/SQL_Server_Toolbelt/pull/197)
bestand anschließend der [Worker-CI-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37423892477):
Linux-Workerhost gegen eine flüchtige synthetische SQL-2019-Instanz mit
Managed-Vertrag und echtem Queue2.0→2.1-Upgrade sowie die getrennten
Windows-/Linux-Faultverträge. Auf `main` scheiterte der erste
[Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37425398209)
im zeitabhängigen Managed-Controltimeout-Orakel; Cleanup bestand. Genau ein
gezielter Retry auf unverändertem Merge-Commit bestand alle drei Jobs. Der
Erstfehler bleibt fehlgeschlagen; seine Ursache ist nicht nachgewiesen.
Echter Committransportverlust, Minimalrechte, weitere Zielkombinationen und
permanenter Betrieb bleiben offen.
