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

Statusfortschreibung 2026-10-08: Der begrenzte native Export-Migrationsfall
in [PR291](https://github.com/gecompat/SQL_Server_Toolbelt/pull/291) besteht
am Qualifikationshead `155f74c9d11548cf600e7770f0d0d12e0720a7f4` (**PASS**;
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37707910466),
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37707910490)).
Auf SQL Server 2019 Linux/CL150 bestand lokal und zentral die tatsächliche
Exportfolge: sieben aktuelle Bootstrapmodule (124 Batches), die gepinnte
Original-Queue2.0 (46 Batches) und der vollständige aktuelle Neun-Modul-Export
(261 Batches), jeweils in frischen ungepoolten Sitzungen. Acht Legacytabellen
mit allen 109 Feldern einschließlich der 43 WorkItem-Felder und des aktiven
Legacyclaims bleiben vor weiterer persistenter DML bytegenau erhalten;
Rowversions, Tokens, NULLs, Audit-/Textbytes, verbrauchte Identitywerte und
ausgewählte Katalogmetadaten sind eingeschlossen. Nur die dokumentierten
Queue-Versions-/Check-ID-Normalisierungen sind ausgenommen. Die drei neutralen
Managedfelder und die bekannten Spaltenformen/neutralen Zustände der sechs
neuen Gate-/Controltabellen bestehen die lesenden Assertions. Eigene
Migration-DB-/Dateibereinigung und separate Containerbereinigung bestanden.
Auch der vorhandene gemeinsame befüllte Exportrepeat bestand separat; die
Migration erhält keine Post-Migration-Completion, Admission, neue Callback-/
SQL-API oder zusätzliche Repeatfolge. Keine Rechte-, Provider-, Trust-,
Konfigurations- oder Zielausweitung; weitere Plattformen/CLs, Minimalrechte,
nichtleere Grants und allgemeiner 44-Modul-Lifecycle bleiben offen.

Frühere Vorbereitungs-/NOT_EXECUTED-Angaben und beide FAILED-Läufe einschließlich
der SKIPPED-Exportschritte bleiben historische Evidenz ihrer Quellenstände.
Der Erfolg schreibt keine früheren Fehler oder fehlenden Cleanupnachweise um.
Die Actor-/Guardianursache des früheren Managed-UNKNOWN bleibt **UNMEASURED**;
im erfolgreichen Lauf erschien kein UNKNOWN-Diagnosedescriptor. Die begrenzte
Beobachterabbildung ist offline validiert; ihre UNKNOWN-Ausgabestrecke wurde
hier nicht ausgelöst. Der UNKNOWN-Guard bleibt unverändert; daraus wird kein
Workerprodukt- oder Ursachenfix abgeleitet. Parentnachweise bleiben erhalten.
Finale Head-CI nach dieser Evidenzfortschreibung, PR291-Merge und anschließende
Main-CI einschließlich Maincleanup sind noch offen.

Statusfortschreibung 2026-10-08 nach PR291-Merge: Die vorstehende offene
Abschlussangabe beschreibt den damaligen Stand. Der erfolgreiche
Qualifikationshead `155f74c9d11548cf600e7770f0d0d12e0720a7f4` bleibt erhalten;
auch der finale Head `6a28ba484760d181ce2b37833b339780084a457d` bestand
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709411383)
und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709411388).
PR291 wurde nach `main` `f8b9b407ad30fc560015b8b475005b4505617689` gemergt.
Die [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709938821)
bestand; die [Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37709938890)
ist **FAILED** im bestehenden Schritt „Execute genuine Queue 2.0 to 2.1
upgrade“. Die vorherigen realen Linux-Worker-, Managed- und Admissionprüfungen
bestanden. Beide neuen Export-Schritte sind **SKIPPED / NOT_EXECUTED**.
Die separate eigene Containerbereinigung bestand mit genau einem tatsächlichen
festen Cleanupmarker; daraus folgt kein eigener Export- oder Fixturecleanup-PASS.
Die beiden früheren FAILED-Läufe bleiben unverändert historische Evidenz.

Der geschlossene Fehlerbefund nennt die Sourcephase
`control-repeat-post-source-rollback`, SQL1222, die äußere Source-Skriptzeile141
und Orakel `UNSPECIFIED`; der bestehende Sourcefall erwartet SQL54969/State1.
Ein numerischer Enginefehlerdescriptor wurde nicht ausgegeben. Enginezeile,
tatsächlicher State, erster fehlgeschlagener Batch und Blockerursache bleiben
**UNMEASURED**. Weder ein
Timingproblem noch ein Produktfehler ist damit ursächlich belegt; die frühere
Managed-UNKNOWN-Ursache bleibt ebenfalls offen. Kein Main-PASS wird abgeleitet.

Die begrenzte Diagnosewartung liegt als privater, eingefrorener
Testfixturekandidat vor. Ausschließlich `Invoke-ControlRepeatExpectedFailure`
erfasst vor dem unveränderten Weiterwerfen der ersten unerwarteten SQL-Abweisung
den Batch und höchstens vier numerische Enginefehler im vorhandenen
`fixtureSqlFailure`-Pfad; Texte sind auf fünf vorhandene Source-Guardmeldungen
oder leer beschränkt. Die bestehende geschlossene Descriptorabbildung gibt
keine freien Fehlertexte aus. Offlineprüfungen und unabhängiger Client-/Privacy-
Review bestanden: erste begrenzte Erfassung ohne Überschreiben, erwartete
Abweisungen und State-Wildcard unverändert, unbekannte Meldungen ausgeschlossen
und ursprüngliche Exception auch bei fehlgeschlagener Erfassung erhalten.
Syntax sowie vollständige Byteerhaltung außerhalb dieser Diagnosefunktion
wurden offline geprüft. Die native Ausführung des Kandidaten ist
**NOT_EXECUTED**; Ursache und Mainqualifikation bleiben offen. Erwartete
Abweisungen, Orakel, Timing, Transaktions-/Ownership-Guards, Produktquellen,
Ziele und Cleanup bleiben unverändert; kein unveränderter Retry ersetzt diesen
Nachweis. Kanonische Main-Adoption von ParameterMetadata und class3-
Schemaannotation bleibt bis zur Mainqualifikation gesperrt; private Vorbereitung
kann innerhalb der bestehenden Grenzen fortgesetzt werden.


Statusfortschreibung 2026-10-08: Der erste native Migrationslauf in
[PR291](https://github.com/gecompat/SQL_Server_Toolbelt/pull/291) am Head
`1d4f9cbdde094c2c59c22eb01b5c5ee261df73b0` ist **FAILED**
([Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37705019236));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37705019277)
bestand. Die Setupfixture verwendete `#tbx_ExportUpgradeStatus` und
`#tbx_ExportUpgradeClaim` als öffentliche ResultTable-Ziele. Der bestehende
Vertrag von `USP_PrepareResultTable` reserviert `#tbx_` und weist diese Namen
mit Fehler `51020`/State `1` ab. Die vorbereitete Korrektur benennt nur diese
beiden eigenen Fixtureziele in `#ExportUpgradeStatus` und
`#ExportUpgradeClaim` um; Source, Deployment, Guards und Datenorakel bleiben
unverändert. Die korrigierte native Migration ist **NOT_EXECUTED**.
Der erfolgreiche Wholejob-Cleanup wurde getrennt verifiziert. Auf dem
Fehlerpfad erschien kein Erfolgsmarker der eigenen Migration-DB-/Datei-
Bereinigung; daraus wird kein eigener Cleanup-PASS abgeleitet.

Die bisherigen SQL150-Offlinenachweise mit 865 Export-Inputs und 28
Fixture-/Wrapper-Inputs sowie die unabhängigen Reviews bleiben an ihren
ursprünglichen Quellenständen gültig. Sie belegen Syntax beziehungsweise
Reviewumfang und erkennen diese Laufzeitverletzung des ResultTable-
Namensvertrags nicht. Die oben genannten NOT_EXECUTED-Angaben dokumentieren
den Vorbereitungsstand; dieser fehlgeschlagene Lauf qualifiziert weder die
Migration noch deren eigenen nativen Cleanup. Parentnachweise bleiben
unverändert erhalten. Keine API-, Rechte-, Ziel- oder Vertragsausweitung.


Statusfortschreibung 2026-10-08: Der zweite Lauf am korrigierten Head
`2735ad3167174d8986857e2f16ec92c3c6942beb` ist bereits in den unveränderten
Managed-Worker-SQL-Contracts **FAILED**
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37706094651));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37706094720)
bestand. Das feste Oracle `MANAGED.UNEXPECTED_UNKNOWN` meldet ein unbekanntes
Workerende im Fall `budget-two`, nach `LIVE_BUDGET_TWO_REDUCED_WITHOUT_CANCEL`.
Beide Export-Schritte wurden **SKIPPED**; die korrigierte native Migration
bleibt **NOT_EXECUTED**. Always-Containercleanup bestand. Die zugrunde liegende
Actor-/Guardianursache ist nicht gemessen; SQL0 der generischen Waitexception
belegt keinen Actor-SQL-Code. Eine begrenzte Diagnoseergänzung an der Testfixture
soll bereits vorhandene Actor-/Guardianfelder ausschließlich als feste
Sourcecodes, typisierte numerische SQL-Codes und Statusflags sichtbar machen.
Workerprodukt, SQL, Orakel, Timing, Ressourcen und Cleanup bleiben unverändert;
kein unveränderter Retry oder gelockerter UNKNOWN-Guard qualifiziert den Test.

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

## Parametermetadaten im Dreimodul-Exportrepeat

Der vorbereitete Fall `Invoke-ExportPopulatedRepeat.ps1 -Scenario ParameterMetadata`
ergänzt ausschließlich die vorhandene Deploymentwartung für die bestehenden
`toolbelt_core.USP_PrepareResultTable` (fünf Parameter) und
`toolbelt_core.USP_EnqueueWork` (sechs Parameter). Die echten Exporte umfassen
genau `toolbelt.core.result-table`, `toolbelt.core.work-type` und
`toolbelt.core.work-queue`: je Modus 90 Batches, drei Modulendmarker und vier
Transaktionsguards. Der Standard-Repeat und Queue20Upgrade bleiben erhalten.
Neue native Parameterqualifikation ist **NOT_EXECUTED**.

Pro local/central ist die Folge eigene Datenbank, tatsächliche Erstinstallation,
`ExportParameter.Setup.sql`, rein lesende Assertion und privater Baseline-
Snapshot, ein Repeat derselben eingefrorenen Exportdatei in einer frischen
ungepoolten Sitzung, Assertion, erneuter Snapshot und vollständiger Vergleich
ohne Ausnahmekategorien vorgesehen. Alle Batches einschließlich Guards werden
konsumiert. Danach erfolgt ausschließlich die bestehende eigene vollständige
Datenbankbereinigung; es ist kein gesondertes Property-Drop erforderlich.
Die bestehende Besitz-, Sitzungs-, Datei- und Journalprüfung bleibt erhalten.

Setup prüft vor der ersten Mutation Kollisionen für vier eigene class-2-
Properties auf `@ResultTableToAlter` und `@WorkTypeName`: eine typisierte
Annotation sowie ein eigenes `MS_Description` je Parameter. Die Zeugen
enthalten varbinary- beziehungsweise int-Werte sowie Unicodebeschreibung
mit nachgestellten Leerzeichen. Die Testdatenbank stammt ausschließlich aus
den Repositoryquellen. Es entsteht kein neues Produktobjekt und keine
bestehende API wird ausgeführt.

Capture und Assert binden alle elf Parameter an Namen, Ordinalpositionen,
SQL-Systemtypen, Länge, Precision, Scale und die SQL2019-Katalogflags
`is_output`, `is_cursor_ref`, `has_default_value`, `is_xml_document`,
`xml_collection_id`, `is_readonly` und `is_nullable`. Die tatsächlich
vorliegenden nullable/default-Metadaten bleiben erhalten. T-SQL-
`has_default_value = 0` beweist keine deklarierte Defaultsemantik; die
bytegenaue Moduldefinition einschließlich Defaults wird separat verglichen.
Neuere Vector-Katalogfelder gehören nicht zu diesem SQL2019-Testscope.

`ExportParameter.Capture.sql` liefert genau Category/Payload. Texte und
Definitionen werden vor XML-BASE64 binär erfasst, nullable Katalogfelder
besitzen explizite NULL-Markierung. Je zwei ausgewählte Objekt- und Modulmetadaten-
zeilen enthalten Identität, SET- und Ausführungsmetadaten; die durch ALTER
veränderliche Objekt-modify_date gehört nicht zum Erhaltungsorakel. Alle
vorhandenen class-2-Properties der beiden Procedures werden mit Major-/Minor-
Bindung und typisierten SQL-variant-Metadaten erfasst; die vier eigenen
Werte werden zusätzlich exakt gelesen und geprüft. Bestehende Objektpermissions
werden ausschließlich beobachtet, nicht erzeugt. Ein expliziter Countzeuge
erfasst auch Permissions=0; das ist kein Nachweis nichtleerer Benutzergrants
oder tatsächlicher Minimalrechte. Kein eigener NULL-Propertyzeuge wird erzeugt.

Der tabellenfreie Adapterpfad ist ausschließlich an diese Capturedatei mit
leerer Parameterübergabe gebunden. Er verlangt genau elf Parameter, zwei
Objekte, zwei Module, mindestens vier Properties und eine Countzeile; eine
nichtleere Permissionskategorie ist optional und muss zum Countzeugen passen.
Unbekannte Kategorien oder andere Tabellenzahlen werden abgewiesen. Alle
Snapshotwerte bleiben im privaten Adaptermemory. Öffentliche Ausgaben sind
feste Ergebnis-/Cleanupmarker und die bestehenden geschlossenen Diagnosecodes.

Stand 2026-10-08: Fixture-SQL150-Prüfung und quellengebundene 5+6-Parameterkarten,
unabhängige Reviews, PowerShell-AST sowie tatsächlicher Offlineexport bestanden.
Beide Exporte ergaben zusammen 180 SQL150-Batches ohne Syntaxfehler. Dies ist
kein nativer Installations-, Repeat- oder Cleanup-Nachweis; Integration und
exakte Head-CI stehen aus. Produktquellen, Deployment-DDL, API, Berechtigungen
und Ziele bleiben unverändert. Keine Qualifikation ausführender APIs,
zusätzlicher Tabellendaten, Grants/Minimalrechte, anderer Plattformen/CLs,
SSMS/sqlcmd.exe oder aller 44 Module wird daraus abgeleitet.

Voraussetzung für die Parameterintegration, Stand 2026-10-08: PR292 wurde
nach `main` `c73f67959185c7a7846455b89c067854dc7d87f6` gemergt.
Die [Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37713277392)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37713277427)
bestanden am exakten Mainstand. Alle drei Workerjobs sowie beide bestehenden
Exportfälle bestanden; die tatsächlichen Festmarker bezeugen beide Export-PASS,
zweimal eigenen Exportcleanup und einmal eigene Containerbereinigung.
Auch die bestehende Control-Repeat- und Ablehnungsabnahme bestand.
Der neue unerwartete SQL-Diagnosezweig wurde dabei **NOT_TRIGGERED**;
seine Offline-Negativprüfung bleibt ein getrennter Nachweis. Der frühere
Mainfehler auf `f8b9b407ad30fc560015b8b475005b4505617689` und seine
weiterhin **UNMEASURED** Ursache bleiben unveränderte Historie; der erfolgreiche
Lauf belegt keine Ursachenbehebung.
Die native Parameterprüfung einschließlich eigener Bereinigung bleibt
**NOT_EXECUTED**. Der Mainnachweis wurde unabhängig geprüft; der Parameter-
branch enthält Adapter, Fixtures und CI-Schritt für die eigene Headprüfung.
Sämtliche bisherigen
Migrations-/Fehler-/Parentnachweise bleiben vollständig erhalten.

## class-3-Erhalt im bestehenden DefaultRepeat

Genau fünf eigene Schemaannotationszeugen auf `toolbelt_core` und `toolbelt_file`
umfassen zweimal `MS_Description` als `nvarchar(128)` mit Unicode und Padding,
`varbinary(5)`, `int` und eine vorhandene Propertyzeile mit NULL-Wert. Alle Namen
werden vor dem ersten Add kollisionsgeprüft; fünf Adds liegen in einer eigenen
kleinen Transaktion. Capture/Assert binden class, SchemaId, minor0 und binären
Namen und prüfen Count5, NULL-Präsenz sowie den gesamten typisierten Werttupel
in beiden EXCEPT-Richtungen. Alle class-3-Properties der beiden Schemas und
endliche Countzeugen erscheinen in zwei neuen Katalogkategorien, ohne Ausnahme
im ersten Repeatfenster. Die bestehenden 14 Tabellen/156 Spalten, Identityzeugen,
beide Fenster und vollständige eigene Datenbankbereinigung bleiben erhalten.

Diese Welle ändert weder Adapter/Workflow noch Parameter- oder
Queue20Upgrade-Fixtures. Der Codescope umfasst drei bestehende Populated-Fixtures.
Native class3-Prüfung und eigener Cleanup: **NOT_EXECUTED**. Nichtleere Grants,
Minimalrechte, weitere Plattformen/CLs und vollständiger 44-Modul-Lifecycle sind
kein Bestandteil dieses Testscopes.

Quellengebundene Offlineprüfungen und unabhängige Reviews der eingefrorenen
Kandidaten bestanden; sie ersetzen keine integrierte Head-/Main-CI.

Voraussetzung, Stand 2026-10-08: PR293 ist nach `main`
`2ad2c018da18768c05f05e0fd7cf4c333fd6b090` gemergt.
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37715148163)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37715148155)
bestanden am exakten Mainstand; Parameterrepeat, beide bestehenden Exportfälle,
drei eigene Exportbereinigungen und Containercleanup sind separat bezeugt.
Die Parameter-Mainvoraussetzung ist erfüllt. Native class3-Prüfung und
eigener Cleanup sind **NOT_EXECUTED**; die eigene exakte Head-/Main-CI
einschließlich Bereinigung bleibt **PENDING**.

## class-1-Objektannotation im bestehenden DefaultRepeat

Setup und Assert binden `toolbelt_core.USP_PrepareResultTable` (P),
`toolbelt_core.SVF_CurrentExecutionId` (FN) und `toolbelt_core.VW_WorkQueue` (V)
an Typ, Schema, Namen, vorhandene Definition und typisierte Modulmarker.
Je Objekt: `MS_Description` und `Toolbelt.Test.ExportObject.Typed`, insgesamt
sechs eigene, nicht vom Deployment verwaltete class-1/minor0-Zeugen. Werte:
`int` 7, `varbinary(5)` und `nvarchar(128)` mit Unicode und abschließenden Leerzeichen.
Alle sechs Kollisionen werden vor dem ersten Add geprüft; sechs Adds liegen
in einer eigenen kleinen Transaktion. Count6 und beide EXCEPT-Richtungen prüfen
Klasse, Objekt-ID, minor0, binären Namen, Wertpräsenz, Basistyp, MaxLength,
Precision, Scale, Collation und Wertbytes. Der vollständige vorhandene Capture
einschließlich Definition, Owner und Permissions bleibt unverändert.
Beide Repeatfenster, 14 Tabellen/156 Spalten, bisherige Erstfensterausnahmen,
Identityzeugen und eigene Bereinigung bleiben erhalten. Zwei bestehende Fixtures
und vier Dokumente bilden den Branchscope; keine doppelte Capturekategorie,
fachlichen API-Aufrufe, neuen SQL-Objekte, Grants, Konfigurations- oder Zieländerungen.
Native class1-Prüfung und eigener Cleanup: **NOT_EXECUTED**; exakte Head-/Main-CI **PENDING**.
Der begrenzte class3-Mainnachweis gilt für Linux SQL Server 2019/CL150 local/central.
Weitere Plattformen/CLs, Minimalrechte, nichtleere Grants und voller44-Modul-Lifecycle bleiben offen.

Class3-Voraussetzung erfüllt: PR294, Main `91e13af689334407527fddfdc8d22285933f4225` (2026-10-08).
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37717103755) und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37717103790): **PASS**.

## View-Spaltenannotation im bestehenden DefaultRepeat

Genau zwei eigene class-1-Properties auf `toolbelt_core.VW_WorkQueue.RowVersion`:
`MS_Description` als `nvarchar(128)` mit Unicode und abschließenden Leerzeichen,
`Toolbelt.Test.ExportViewColumn.Typed` als `varbinary(5)`. Die vorhandene View,
ihre typisierten ModuleId-/ModuleVersion-/ContractVersion-Marker und die nach
binärem Spaltennamen ermittelte tatsächliche column_id binden das Ziel; minor_id
ist diese ID. Keine feste Spaltenposition und kein erfundener Managed-Objektmarker.
Beide Kollisionen werden vor zwei eigenen Adds in kleiner Transaktion geprüft.
Count2 und beide EXCEPT-Richtungen vergleichen alle elf Felder: class/ObjectId/
ColumnId, binären Propertynamen, Wertpräsenz, Basistyp, MaxLength, Precision,
Scale, Collation und Wertbytes. Beide Werte sind nicht NULL; keine neue NULL-Saat.
Der vorhandene vollständige class-1-Capture bleibt unverändert; sein Snapshot
wird in beiden Repeatfenstern vollständig verglichen. Die bisherigen 14 Tabellen/156 Spalten, Schema-/Objektzeugen,
Erstfensterausnahmen, Identity und Cleanup bleiben erhalten. Vorgesehener Scope:
nur Setup/Assert und vier Dokumente, keine neuen SQL-Objekte, API-Aufrufe, Grants,
Konfigurations-, Ziel-, Adapter-, Workflow- oder Captureänderungen.
Native View-Spaltenprüfung und eigener Cleanup: **NOT_EXECUTED**; eigene exakte
Head-CI sowie Merge-/Mainqualifikation einschließlich Cleanup: **PENDING**.
Keine breitere Matrix-, Minimalrechte- oder Releaseclosure.

Class1-Voraussetzung erfüllt: PR295, Main `a585803de0d1d94be595dbf7b3153e582fbff9d2` (2026-10-08).
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37721226636) und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37721226645): **PASS**.
Der begrenzte Nachweis gilt für Linux SQL2019/CL150 local/central; sechs Objektzeugen, drei eigene Exportbereinigungen und Containercleanup sind belegt. Er qualifiziert keine neuen View-Spaltenzeugen und erklärt keine historische Fehlerursache.

## Im Branch ergänzt: identischer Dateirepeat nach genuine Migration

Stand 2026-10-08, separate Wartungswelle im bestehenden `Queue20Upgrade`-Fall.
Bootstrap, Genuine2.0 und erster Neun-Modul-Export bleiben erhalten; der
ursprüngliche acht-Tabellen-/109-Feldervergleich erfolgt unverändert vor
weiterer persistenter DML.
Erst danach bindet die neue Fixture genau einen eigenen noch gültigen
unmanaged Legacyclaim und ruft einmal die bestehende `USP_CompleteWork` auf,
ohne Leaseänderung, neuen Claim oder Handlerdispatch. Nur Status,
CompletedAtUtc, CompletedBy und RowVersion dieses WorkItems dürfen sich ändern;
42 stabile Felder aller drei WorkItems, alle 46 Felder der beiden anderen
WorkItems und sämtliche anderen Tabellen/Katalogkategorien bleiben exakt.

Die neue Baseline umfasst 14 Tabellen/156 sourcegebundene Felder mit binären
Werten, expliziten NULLs und CountWitness je Tabelle, auch für die leere Barrier
und vier leere Controlhistorytabellen. Positives Sollinventar: sechs PKs,
zwei UQs, acht Backingindizes, fünf FKs mit sechs geordneten Spaltenpaaren und
neun aktive vertrauenswürdige CHECKs. Deren unveränderte Sourceausdrücke werden
in anonymen Temp-CHECKs gegen tatsächliche Definitionbytes geprüft; die
Engineäquivalenz ist **NOT_EXECUTED**, keine Textnormalisierung wird behauptet.
Genau ein zusätzlicher vollständiger Aufruf derselben hashgebundenen Datei
pro local/central folgt; der komplette Consumervergleich hat weder Firstskip
noch Versionsnormalisierung. Nur die drei tatsächlich neu erzeugten
WorkItem-CHECK-IDs und die bisher ausgenommenen Objekt-DDL-Zeitstempel bleiben
außerhalb des semantischen Katalogvertrags. Snapshot-, Claim- und Auditwerte
bleiben im privaten Memory; alte Ownership-/Session-/Timeout-/Control-/Queueguards
und eigene Cleanupgrenzen bleiben erhalten.

Autorprüfung: fünf neue SQL150-Inputs/35 Batches und neuer Adapter-AST ohne
Fehler, ausschließlich Syntax; unveränderte Tests wurden nicht wiederholt.
Unabhängiger Source-/Client-/Privacyreview der eingefrorenen Payloads bestanden.
Neue native Folge und eigener Cleanup **NOT_EXECUTED**. Eigene Head-/Merge-/Main-
qualifikation **PENDING**. Keine historische Ursachenbehebung, neue
öffentliche SQL-Funktion, Rechte/Config/Provider/Ziele, aktive Controlhistory,
Concurrency-, Windows-/weitere SQL-Versionen-/SSMS-/Minimalrechte-/44-Modul-
Qualifikation wird daraus abgeleitet.

View-Mainvoraussetzung erfüllt, Stand 2026-10-08: [PR296](https://github.com/gecompat/SQL_Server_Toolbelt/pull/296)
ist nach `main` `c1dc014d94f6ce827bd52ef542722faea5bb267b` gemergt.
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37723945915)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37723945917): **PASS**.
Der Nachweis ist auf Linux SQL Server 2019/CL150 local/central und den bisherigen
View-Spalten-/Exportscope begrenzt; er qualifiziert diese neue Upgrade→Repeat-Folge nicht.

Weitere Statusfortschreibung 2026-10-08: Auch der zweite native Headlauf
`6abf635a26c314744fa3bba27d2eb289e9f4445d` ist **FAILED**
([Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37729131172));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37729131184)
bestand. Vier tatsächliche Checkouts sind über ihren Tree an diesen Head gebunden.
Die geschlossene lokale Upgrade-Diagnose SQL54998/State90 lokalisiert
`PARENT_COLUMN`, Sourceindex0: Das bisherige Prädikat
`c.parent_column_id <> 0` war wahr. Konkrete ID, Spaltenname, Mirrorzustand
und Ursache sind dadurch **UNMEASURED**. Der ursprüngliche 109-Feldervergleich
wurde davor erreicht; neue Completion, vollständiger Nach-Completion-Snapshot
und identischer Dateirepeat bleiben **NOT_EXECUTED**, die Folge **NOT_QUALIFIED**.
DefaultRepeat bestand, Parameterexport wurde übersprungen. Containercleanup
bestand separat; der einzelne Exportcleanup-Erfolgsmarker gehört zum
DefaultRepeat und belegt keinen eigenen Migrationcleanup.

Die neue Testassertion vergleicht zunächst die
Table-/Columnklassifikation mit dem Compiler-Mirror. Positive Columnbindungen
werden je eigenem Parentobjekt anhand acht fester Source-Spaltennamen und ihrer
Typform geprüft; der mehrspaltige Limits-CHECK verlangt beide Tablebindings0.
Absolute ColumnIDs werden nicht objektübergreifend gleichgesetzt. Derselbe
Invalid-Term gilt im Gesamtgate und in der endlichen State90-Diagnose;
Count-, Namen-, Definitionbytes-, Trust-/Flaggates und State12-Fallback bleiben.
Genau ein neuer vollständiger SQL150-Input/ein Batch bestand die reine
Offline-Grammatikprüfung. Ein unabhängiger Source-/Inverse-/Privacyreview
bestand ohne Blocker; er führte weder Parser noch SQL aus. Root hat den
Sourceentwurf vollständig gelesen. Diese Fortschreibung begleitet die
Übernahme der Testassertion. Native Parent-/Compilerqualifikation, neue
exakte Head-/Merge-/Mainqualifikation und eigener Cleanup bleiben **PENDING**.
Keine native Parent-/Compilerqualifikation oder Ursachenbehebung wird behauptet.

Statusfortschreibung 2026-10-08: Der erste native Lauf dieser Upgrade→Repeat-Welle
in [PR297](https://github.com/gecompat/SQL_Server_Toolbelt/pull/297) am Head
`913a3d6c42f4962a22c11656977bdf458d1bd15c` ist **FAILED**
([Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37726736364));
[Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37726736429)
bestand. Die kombinierte Neun-CHECK-Assertion weist im lokalen Upgrade mit
SQL54998/State12 ab. Welche Unterbedingung und Sourcebindung verletzt ist,
bleibt **UNMEASURED**; ein Produktfehler oder eine Ursachenbehebung ist nicht belegt.
Der bisherige Immediatevergleich wurde davor erreicht. Die neue Completion
und der anschließende identische Dateirepeat sind **NOT_EXECUTED**, die neue
Folge ist **NOT_QUALIFIED**. Der separate DefaultRepeat bestand; der
Parameterexport wurde übersprungen. Containercleanup bestand separat;
der beobachtete eigene Exportcleanup-Erfolgsmarker gehört zum DefaultRepeat,
kein eigener Migrationcleanup-PASS wird daraus abgeleitet.

Die im Branch übernommene Diagnose ergänzt nur den bereits fehlgeschlagenen CHECK-
Zweig: höchstens drei lesende Queries, feste Komponenten und Sourceordinal0..8,
numerische States höchstens108 sowie der unveränderte State12-Fallback.
Originalgate und Erfolgsweg bleiben erhalten; keine tatsächlichen Katalognamen,
Definitionen oder Werte werden veröffentlicht. Ein neuer SQL150-Input/ein Batch
bestand die Offline-Syntaxprüfung. Native Diagnose, CHECK-Engineäquivalenz,
vollständige neue Folge und eigener Cleanup bleiben offen; neue exakte
Head-/Merge-/Mainqualifikation **PENDING**.
Bisherige Vorbereitungsangaben und alle Parentnachweise bleiben historische
Evidenz ihrer Quellenstände; keine Guards, Timeouts, Produkte, APIs oder Rechte ändern sich.

## Abschluss PR297 und nachfolgende genuine Queue1.1-Wartung

Abschluss der vorausgehenden Wartungswelle, 2026-10-08: [PR297](https://github.com/gecompat/SQL_Server_Toolbelt/pull/297)
ist nach `main` `fdd01df40a4cb495bff126bfe1db8db9b2156bed` gemergt.
Der letzte Head `a61ae213b969b2fa5df84b493ed2a369781d1c13` bestand
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37731699578)
und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37731699498).
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37732809028)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37732809105): **PASS**.
Je vier tatsächliche Checkout-Commits wurden über ihren Tree an den geprüften
Sourcebaum gebunden. Die genuine2.0→2.1→Completion→Dateirepeat-Folge bestand
für Linux SQL Server 2019/CL150 local/central; drei eigene Exportbereinigungen
und der separate Containercleanup sind belegt. Eigene Arbeitsrefs sind entfernt,
private Originale vollständig und unabhängig auf Bytes/Hash/Länge gesichert.
Die folgenden früheren **PENDING**-/**NOT_EXECUTED**-Vorbereitungsangaben gelten
für ihre damaligen Quellenstände. Beide historischen fehlgeschlagenen Headläufe
bleiben **FAILED** mit Ursache **UNMEASURED**; der spätere Erfolg erklärt sie nicht.
Dieser begrenzte Abschluss qualifiziert den neuen Queue1.1-Fall noch nicht.

### Queue11Upgrade: ausgewählter Fall und Quellenbindung

`Invoke-ExportPopulatedRepeat.ps1 -Scenario Queue11Upgrade` nutzt ausschließlich
den vorhandenen eigenen Linux-SQL2019-/CL150-CI-Zielscope und seine local/central-
Modi. Sieben aktuelle Bootstrapmodule stellen die bisherigen Abhängigkeiten
bereit; danach wird der saubere originale Queue1.1-Installer vollständig in
einer frischen ungepoolten Sitzung einschließlich seiner ursprünglichen
Transaktion über GO-Batches ausgeführt. Der aus1.0 migrierte1.1-Spaltenstand
gehört nicht zu diesem Testfall.

Originalcommit `7c6cb157db39a948e14f3db1f4973f80579a5832`, Root-Tree
`86e3b854bbf66b442cd2b19c26802628acfd0cd0`, Modul-Tree
`8b0c04a64a91f7022865cc695659dd8f6e06bd39`. Ein begrenzter Quellenbezug vor
beiden Modi ist nur im exklusiv eigenen normalen CI-Checkout ausgewählt;
Storeumleitungen, Alternates, Redirects und abweichende effektive URLs werden
geschlossen abgewiesen. Kein stiller Quellenfallback und kein lokaler Fetch
im gemeinsam genutzten Repository. Die elf unveränderten Originalblobs,
neun geordneten Includes, ein Modus und die vollständige Expansion werden
vor der jeweiligen DB-Anlage erneut auf Identität/Bytes/Hash gebunden.
Der Erwerbsreturn allein erlaubt keine DB-Mutation. Git-Object-/Pack-/Shallow-
Effekte bleiben im eigenen temporären Checkout; unbewiesene Teilergebnisse
werden erhalten, ohne Retry oder blinde Bereinigung.

Der neue Fall befüllt die bestehenden APIs mit drei eigenen WorkItems in
COMPLETED/FAILED/QUEUED, ohne verbleibenden Claimconsumer. Unmittelbar nach
genau einem aktuellen Neun-Modul-Export werden sechs alte Tabellen mit83
physischen Feldern geprüft:22 alte WorkItemfelder bleiben bytegleich;
die drei keyed binary8-RowVersions müssen jeweils wechseln. Die übrigen60
Legacyfelder einschließlich ihrer RowVersions bleiben exakt. Neue23
WorkItemspalten, acht neue Tabellen/50Felder und sourcegebundene Katalogformen
erhalten eigene positive Assertions. Der Nachhercapture enthält alle14
Tabellen, einschließlich expliziter Leerzeugen. Keine freie Versions-,
Definition- oder Whitespace-Normalisierung und keine nachfolgende persistente DML.

Privater NEWroot und CreateNew-Journal werden vor Mutation gebunden; der neue
Journalrecord bleibt vor dem Schreiben auf64KiB begrenzt. Alle Quellenfiles,
Export und Manifest müssen vollständig registriert und erneut geprüft sein.
Vor Cleanup müssen sämtliche eigenen Verbraucher beendet sein. Unvollständige
Ownership, geänderte oder unregistrierte Files bleiben erhalten und führen zu
**DEFERRED**; DB-, File- und Containercleanup sind getrennte Nachweise.
Nur feste Phasen/Codes und numerische SQLdiagnosen dürfen öffentlich erscheinen.

Neue native Migration, Transport-/Gitversionskompatibilität, tatsächliche
Definitions-/Compilerform und eigener Cleanup sind **NOT_EXECUTED**;
neue exakte Head-/Merge-/Mainqualifikation **PENDING**. Reine Source-/ASTprüfungen
belegen keine SQL-Ausführung. Hard-Interrupt-Recovery, tatsächliche Minimalrechte,
nichtleere Benutzergrants, Windows, weitere SQL-Versionen/physische Matrix,
Concurrency, Ressourcenmessung, vollständige Lifecycle- und Releasequalifikation
bleiben getrennt offen. Die vorhandenen Security-/CLR-Versionsgrenzen bleiben.

Herstellerreferenzen zum begrenzten Gitbezug:
[git-fetch](https://git-scm.com/docs/git-fetch),
[git-ls-remote](https://git-scm.com/docs/git-ls-remote),
[git-config](https://git-scm.com/docs/git-config).

### Erster Queue1.1-Head: Root-Preflight und begrenzte Diagnoseänderung

Erster exakter Head `e9fc95ea5192ac35697a2d87e11c8f94c1938d2b`:
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37738796909)
**FAILED**, [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37738797015)
**PASS**. Der neue Fall wurde im Preflight abgewiesen; einzelne Bedingung und
Ursache sind **UNMEASURED**, Migration bleibt **NOT_QUALIFIED**. Die bisherigen
drei Exportfälle bestanden mit drei eigenen Bereinigungen; neuer Dateicleanup
**DEFERRED**, separater Containercleanup bestätigt. Eine eng begrenzte
Diagnoseänderung unterscheidet die dreizehn vorhandenen Root-Prädikate mit
festen Codes, ohne die Schutzbedingungen zu lockern oder Runtimewerte auszugeben.
Diese Änderung ist noch nicht nativ geprüft; aktueller Merge/Main bleiben offen.
Die vorherigen PENDING-Angaben beschreiben die ursprüngliche Vorbereitung.

Root und unabhängiger Reader haben denselben abgeschlossenen Quellenstand und
alle vier tatsächlichen Checkout-Trees an `f79b3d16e1bc8cf4e7ddbccaaf17f19c4362bc3a`
gebunden. Ausschließlich der neue Queue1.1-Schritt scheiterte; die übrigen elf
benannten Linuxschritte und beide Faultjobs bestanden. Die feste Sourcephase
`preflight` und der bisherige Sammelcode `QUEUE11_ROOT_BOUNDARY` begrenzen den
Befund. Aus der kontrollierten Aufrufreihenfolge folgt, dass Quellenbezug und
DB-Anlage dieses neuen Falles nicht erreicht wurden; dies ist Sourceinferenz,
kein zusätzlicher Runtime-Trace und keine Ursachenklärung.

Der neue Adapter trennt sieben Assertions in dreizehn unveränderte boolesche
Teilbedingungen. Reihenfolge und Abweisung bleiben erhalten; weder Getter,
CreationTime-/Attributwerte, Journal-, DB- oder Filecleanupverträge werden
normalisiert oder gelockert. Nur feste Sourcecodes dürfen die fehlgeschlagene
Bedingung unterscheiden. Kein Pfad, Zeitwert, Attributwert oder Runnerinventar
wird öffentlich ausgegeben. Kein unveränderter CI-Retry und kein Rootcause-Fix
werden behauptet. Erwerb, Definition-/Compilerformen, Migration und eigener
Cleanup dieses Falles bleiben bis einer vollständigen neuen Qualifikation offen.
