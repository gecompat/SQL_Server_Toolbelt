# Deploymentprüfungen

`Test-SqlExport.ps1` prüft den Exportvertrag offline mit synthetischen Dateien.
Es verbindet sich nicht mit SQL Server und ersetzt keine Runtimequalifikation.

## Befüllter gemeinsamer Exportrepeat

`Invoke-ExportPopulatedRepeat.ps1` ist ein begrenzter CI-Adapter für das bereits
eigene externe Linux-/SQL-Server-2019-Ziel mit Compatibility Level 150 und
vorhandenen Rechten. Es startet keine Infrastruktur und konfiguriert weder
CLR noch Provider, Trust oder Berechtigungen. Die Verbindung kommt ausschließlich
aus einer ausdrücklich benannten Prozessumgebungsvariable.

Die Auswahl `worker-control`, `event-log`, `file.content`, `execution-cancel`
wird durch den echten `Deploy-All.ps1 -OutputSqlFile` zu neun Modulen ergänzt:
execution-context, result-table, file.content, execution-cancel, work-type,
second-session, work-queue, event-log und worker-control. Lokal und zentral wird
je eine eigene Datenbank mit unterschiedlicher Collation angelegt. Pro Modus
werden dieselben hashgebundenen Exportbytes für die Erstinstallation und zwei
befüllte Repeats verwendet; jeder Aufruf erhält eine frische ungepoolte Sitzung.
Der geschlossene Consumer erlaubt ausschließlich `:ON ERROR EXIT` und `GO`,
führt alle nichtleeren Batches in Reihenfolge aus und stoppt beim ersten Fehler.
Das ist eine Qualifikation der exportierten Batchfolge, keine Ausführung durch
SSMS oder `sqlcmd.exe`.

Die vier Runtimefixtures erzeugen ausschließlich synthetische Daten. Alle
14 Tabellen müssen befüllt sein; jedes deklarierte Feld wird als Binary mit
expliziten NULLs privat verglichen, einschließlich Auditpräzision, Textpadding,
Rowversions, Tokens und verbrauchter Identitywerte. Der ruhende Queue2.1-/
Control1.0-Verbund hat weder Claims, Holds noch belegte/offene Reservations.
Der einzelne synthetische Loopback-Eintrag bleibt deaktiviert. Es erfolgt
kein RPC, File-Content-I/O-API-Aufruf oder Workerstart im neuen Repeat.

Im ersten Repeat sind exakt zwei kanonische Änderungen erwartet:
`FileContentRootAllowlist` erneuert seine Tabellenbeschreibung; EventLog
reaktiviert seine eigene zuvor abweichend deaktivierte WorkType-Registrierung.
Separate Assertions prüfen deren kanonische Werte, unveränderte ID/Created-Audit
und geänderte Rowversion/Modified-Audit. Der zweite Repeat vergleicht auch diese
beiden Kategorien vollständig. Andere WorkTypes und eigene typisierte Tabellen-/
Spaltenannotation bleiben erhalten. Ausgewählte Objekt-/Spalten-/Index-/
Constraint-/Moduldefinitions-/Permissionsmetadaten werden verglichen;
wiedererzeugte Checkconstraint-IDs und DDL-Zeitstempel sind keine Zusage.
Nichtleere Benutzergrants werden weder erzeugt noch qualifiziert.

Identity-Nextinsert-Zeugen laufen erst nach beiden Vergleichsfenstern.
Snapshots und freie Diagnosen bleiben privat. Öffentlich erscheinen feste
Ergebnis-/Cleanupmarker und eine geschlossene Diagnose mit vorab definierten
Phasen-/Assertioncodes sowie numerischem SQL-Fehlercode/-State, ohne SQLtext
oder Exceptionmessage. Primärfehler und Cleanupfehler bleiben getrennt.
Die Bereinigung prüft in frischer Verbindung Namen,
DB-ID, Erzeugungszeit, Owner und typisierten Runmarker sowie fremde Sessions/
Requests. Bei unklarem Besitz wird nicht gelöscht; kein KILL, SINGLE_USER oder
Rollback fremder Verbraucher. Das private Journal bleibt bei Fehlern erhalten;
der vorhandene CI-Containercleanup bleibt separat unverändert.

Stand 2026-10-08: Offlineexport und unabhängige Reviews bestanden;
der erste native Lauf am Commit `e5b51d14500203947fd45d6ad0533e40b1302c8a`
ist im neuen Test **FAILED**
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37696018416)).
Vorherige Worker-/Upgradefälle und eigene Containerbereinigung bestanden.
Der Diagnoselauf am Commit `947da95d61ae617f88e42847ae453dd27e132197`
ist ebenfalls FAILED im Verbindungs-Preflight
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37697052700)).
Ohne Verbindung reproduziert: PowerShell-Dotzuweisungen für `InitialCatalog`
und `ConnectTimeout` erzeugen ungültige Builder-Schlüssel. Explizite Indexer
`Initial Catalog` und `Connect Timeout` beheben dies; der separate abschließende
Pfadseparatorfehler im Adaptercleanup ist ebenfalls korrigiert. Beide
fehlgeschlagenen Läufe bleiben historische Evidenz. Zu diesem Stand war die
korrigierte Head-CI noch offen. Die Einzelmodulnachweise stehen in
[Backlog](../../.ai/BACKLOG.md). Windows-FileSystemRoot, weitere Versionen/CLs,
historische und partielle Installationen, Minimalrechte, nichtleere Grants,
Hard-Interrupt-Recovery, native SQLCMD-Clients und vollständige 44-Modul-
Lifecycle-/Releasequalifikation bleiben offen.

Der folgende Lauf `6989d8ac43033e8cd45c2f8fb88f59239429c64a` besteht den
Verbindungs-Preflight, ist aber im eigenen Datenbank-/Sitzungsgate FAILED
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37697908672)).
Der Diagnoselauf `e79bf5a4c1d0db3760b6fbc29a8d1714b8fc7368` ist ebenfalls
FAILED ([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37699250549)):
Alle zwölf Einzelbedingungen bestehen, das kombinierte Gate wirft State 13.
Die Korrektur trennt die neutralen Sitzungsprüfungen von den kataloglesenden
Besitzprüfungen wie im bestehenden Repeatactor. Sämtliche Besitzprädikate
bleiben gemeinsam gebunden; die Sitzung wird davor und danach geprüft.
Ein während des Katalogstatements aktiver Autocommit erklärt das Ergebnis als
Hypothese; der konkrete interne Operand wurde nicht nativ gemessen.
Containerbereinigung und vorherige Runtimefälle bestanden weiterhin.
Der folgende Head `52526f7836b0d4c113991fc972608b1eff276283` besteht Besitzgate
und Erstinstallation, bleibt aber im initialen Fixture-Sitzungsgate
FAILED/SQL54980/State1
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37700707745)).
Die kombinierten Sitzungsbedingungen der vier Fixtures werden jeweils einzeln
geprüft; Prädikate, Fehlercodes und die fachlichen Orakel bleiben erhalten.
Vorherige Workerfälle und Containerbereinigung bestehen. Der korrigierte Head
`a836b87778fbe4c498b4b1ce05f06c58373ea03c` besteht die gemeinsame Exportfolge
auf Linux2019/CL150 lokal und zentral über zwei befüllte Repeats aller 14
Tabellen, eigene DB-/Dateibereinigung sowie vorhandene Worker-/Upgradefälle
und Containerbereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37701845352)).
Dokumentations-CI am selben Head besteht. Der beobachtete Erfolg belegt die
Korrektur im gewählten Scope; der interne Ausdrucksoperand der früheren
Sitzungsfehler wurde weiterhin nicht direkt gemessen. Historische FAILED-
Läufe und die oben genannten übrigen Qualifikationsgrenzen bleiben erhalten.

## Echter Queue2.0-Upgrade durch Exportdatei

`Invoke-ExportPopulatedRepeat.ps1 -Scenario Queue20Upgrade` ergänzt einen
getrennten Migrationsfall unter der vorhandenen Deploymentwartungsfreigabe.
Der Standardfall `Repeat` und seine vier `ExportPopulated.*.sql`-Fixtures
bleiben unverändert. Der neue Fall ist für denselben vorhandenen externen
Linux2019-/CL150-Scope lokal und zentral vorbereitet; neue native Ausführung
ist **NOT_EXECUTED**.

Pro Modus installiert eine echte `-OutputSqlFile`-Datei zunächst sieben
aktuelle Module: execution-context, result-table, file.content,
execution-cancel, work-type, second-session und event-log. Danach installiert
der unveränderte `New-GenuineQueue20Capture.ps1` die Originalquellen der
Work Queue 2.0.0 aus Commit `62e7b06588b28c45c58f7ec335e4e5c45f120e3e`.
Blob- und Dateiidentität werden geprüft; ein geänderter Versionsmarker einer
aktuellen Queue ersetzt diesen historischen Installationsstand nicht.
Anschließend konsumiert der begrenzte Batchconsumer die vollständige echte
Exportdatei aller neun aktuellen Module einschließlich Queue2.1 und der
erstmaligen Control1.0-Installation. Jeder Aufruf verwendet eine frische
ungepoolte Sitzung mit `LOCK_TIMEOUT -1`; alle Exportbatches werden in ihrer
Reihenfolge ausgeführt. SSMS und `sqlcmd.exe` werden damit nicht qualifiziert.

`ExportUpgrade.Setup.sql` erzeugt über die Original-Queue-APIs je eine
COMPLETED-, CLAIMED- und QUEUED-Zeile. Der vorhandene kanonische JSON-Handler
wird nur registriert, niemals ausgeführt; es entsteht kein neuer Callback
oder öffentliches SQL-Objekt. Der aktive Legacyclaim bleibt während des
Upgrades und der ersten Controlinstallation erhalten. Weitere synthetische
Zeilen, verbrauchte gelöschte Identitywerte sowie eigene typisierte Tabellen-/
Spaltenannotation und Beschreibungen bezeugen die übrigen Bestandstabellen.

| Bestandstabelle | Legacyfelder | Zeilen vor und nach Migration |
|---|---:|---:|
| `WorkType` | 18 | 2 |
| `WorkItem` | 43 | 3 |
| `WorkQueueScheduler` | 1 | 1 |
| `WorkQueueBarrierBlocker` | 5 | 0 |
| `ExecutionCancellation` | 5 | 3 |
| `SecondSessionProvider` | 8 | 1 |
| `EventLog` | 24 | 3 |
| `FileContentRootAllowlist` | 5 | 4 |

`ExportUpgrade.Capture.sql` erfasst alle 109 Legacyfelder mit binären
Text-/Token-/Rowversion-/Auditbytes und expliziten NULLs im privaten
Adaptermemory über Sitzungsgrenzen. Die 43 WorkItem-Feldnamen und ihre
Ordinalpositionen sind gepinnt. Ein eigener Countzeuge erfasst auch die
ausdrücklich leere Barrier-Tabelle. Identity-Seed, Increment und letzter
verbrauchter Wert sowie ausgewählte alte Tabellen-/Spalten-/Index-/Default-/
Check-/Key-/FK-/Permissionsmetadaten werden verglichen. Vorhandene Rechte
werden nur beobachtet; es werden keine Benutzergrants erzeugt. Eigene
Annotationen einschließlich `MS_Description` bleiben erhalten; die bereits
kanonische File-Content-Beschreibung und Event-WorkType-Zeile werden ebenfalls
vollständig verglichen.

Nur der erwartete Queue-Versionswert und die IDs der drei neu erzeugten
WorkItem-Checks werden normalisiert; deren Name, Ausdruck und Vertrauensstatus
bleiben im Vergleich. `ExportUpgrade.Assert.sql` prüft rein lesend die echten
Zielmarker, die drei neutralen Managedfelder (`NULL`, `0`, `NULL`), die
Spaltenformen der sechs neuen Tabellen sowie Gate-/Control-Singletondefaults
und leere Controlhistory. Dies ist kein vollständiges Orakel aller neuen
PK-/FK-/Index-/Defaultdefinitionen. Der Legacyvergleich erfolgt vor jeder
anschließenden persistenten DML. Danach folgt ausschließlich die bestehende
eigene Datenbankbereinigung; keine Post-Migration-Completion, neue Admission
oder zusätzliche 14-Tabellen-Repeatfolge.

Source, Deployments und Exportgenerator bleiben unverändert. Keine neue
Provider-, RPC-, Datei-I/O-, Worker-, Konfigurations-, Rechte- oder
Trustausweitung. Offline-Syntaxprüfung und unabhängiger Domainreview bestanden;
dies ersetzt weder native Migration noch eigenen nativen Cleanup. Stand
2026-10-08 bestand Parent [PR290](https://github.com/gecompat/SQL_Server_Toolbelt/pull/290)
am Qualifikationshead `a836b87778fbe4c498b4b1ce05f06c58373ea03c` den
begrenzten nativen Exportrepeat einschließlich eigener Bereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37701845352));
Dokumentations-CI desselben Heads bestand ebenfalls. Frühere FAILED-Läufe
bleiben als historische Evidenz im Parentabschnitt erhalten. Finale Parent-
Head-CI am Stand `bdc2ba9f001190d9d63cc97e040f1e693fb4dafd`
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37702891518))
bestand; PR290 ist nach `origin/main` integriert, Mainstand
`acba925419973d9dfb2b7b8e481d67f0a75789e3` mit identischem Parentbaum.
Main-Dokumentations-CI
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37703434131))
bestand; Main-Worker-CI
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37703434018))
bestand einschließlich eigener Bereinigung. Die Migrationswelle wird erst
nach tatsächlicher eigener Head-CI qualifiziert. Weitere Plattformen/CLs,
Minimalrechte, nichtleere Grants, unbekannte/partielle Installationen und
vollständiger 44-Modul-Lifecycle bleiben getrennt.
