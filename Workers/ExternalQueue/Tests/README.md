# Worker-Qualifikation

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
Exakte Head-CI und tatsächlicher Linux-Workerhost sind separate Nachweise.

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
unverändert; ein neuer erfolgreicher Lauf am aktuellen Head ist erforderlich.
