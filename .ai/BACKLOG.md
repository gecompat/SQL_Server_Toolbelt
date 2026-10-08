# BACKLOG.md – Priorisierte Arbeitspakete

Nur priorisierte Kandidaten werden hier als konkrete Arbeitspakete geführt. Ein Eintrag ist keine automatische Implementierungszusage; er wird durch ausdrückliche Benutzerfreigabe aktiv.

44 Module sind implementiert. 19 sind `validated`, 25 sind `partially validated`; 0 sind `not executed`.

## Aktive Arbeitspakete

### Genuine Queue1.1 als weitere Deploymentwartung

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

Unter der bestehenden Freigabe zum datenwahrenden Gesamtdeployment wird der
saubere originale Queue1.1-Installer mit genau einem aktuellen Neun-Modul-Export
je local/central geprüft. Dies ist Testwartung vorhandener öffentlicher Objekte.
Die Originalquellen sind an Commit `7c6cb157db39a948e14f3db1f4973f80579a5832`
gebunden; der Quellenbezug erfolgt einmal im eigenen exklusiven Linux-CI-Checkout,
vollständige Elf-Blob-/Expansionsprüfung vor jeder eigenen DB-Anlage.
Sechs alte Tabellen/83 Felder, erwartete keyed RowVersion-Wechsel der drei
WorkItems sowie neue Defaults und Katalogformen werden getrennt geprüft.
Keine zusätzliche DML nach dem unmittelbaren Migrationsvergleich, kein Repeat,
neuer Claimconsumer, öffentliche API, Rechte-/Provider-/Zielausweitung.
Native neue Migration und eigener Cleanup: **NOT_EXECUTED**; neue exakte
Head-/Merge-/Mainqualifikation: **PENDING**. Details und Grenzen stehen in den
[Deploymenttests](../Deployment/Tests/README.md).

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

Weitere Deploymentwartung, im Branch übernommen 2026-10-08: Der bestehende
`Queue20Upgrade`-Fall prüft nach genuine Queue2.0→2.1 und erstmaligem Control1.0
auch einen Repeat derselben Neun-Modul-Datei, jeweils local/central.
Der ursprüngliche Immediatevergleich aller acht Legacytabellen/109 Felder
bleibt unverändert vor weiterer persistenter DML. Erst danach wird genau ein
eigener Legacyclaim über die bestehende `USP_CompleteWork` abgeschlossen;
nur Status, CompletedAtUtc, CompletedBy und RowVersion dieses WorkItems dürfen
sich ändern. Vollständige private Snapshots erfassen danach 14 Tabellen/156
Felder einschließlich fünf leerer Tabellen und ein positives neues
Constraintinventar. Ein identischer Dateirepeat vergleicht alles ohne
First-Ausnahmen oder Versionsnormalisierung. Bestehende Gates, Timeouts,
Ownership und Cleanup bleiben erhalten; keine neue API oder zusätzliche
Scenario-/DB-/Export-/Rechte-/Ziel-/Provider-/Configfreigabe.
Autor-Syntaxnachweis: fünf neue SQL150-Inputs/35 Batches und Adapter-AST ohne
Fehler; CHECK-Engineäquivalenz, neue native Folge und eigener Cleanup sind
**NOT_EXECUTED**. Unabhängiger Source-/Client-/Privacyreview der eingefrorenen
Payloads bestanden; eigene Headprüfung, Merge und Mainqualifikation sind
**PENDING**. Historische
Fehler- und Qualifikationsnachweise bleiben erhalten; Details künftig in den
[Deploymenttests](../Deployment/Tests/README.md).

View-Mainvoraussetzung erfüllt, Stand 2026-10-08: [PR296](https://github.com/gecompat/SQL_Server_Toolbelt/pull/296)
ist nach `main` `c1dc014d94f6ce827bd52ef542722faea5bb267b` gemergt.
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37723945915)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37723945917): **PASS**.
Der Nachweis ist auf Linux SQL Server 2019/CL150 local/central und den bisherigen
View-Spalten-/Exportscope begrenzt; er qualifiziert diese neue Upgrade→Repeat-Folge nicht.

### View-Spaltenannotation im bestehenden Exportrepeat

View-Spaltenwartung, Stand 2026-10-08: zwei eigene class-1-Properties auf
der vorhandenen View-Spalte `toolbelt_core.VW_WorkQueue.RowVersion`.
Setup und Assert verwenden die nach Namen ermittelte tatsächliche column_id;
Capture und beide Repeatfenster bleiben erhalten. [Deploymenttests](../Deployment/Tests/README.md)
beschreiben Count2 und den vollständigen typisierten Erhaltungsnachweis.
Native View-Spaltenprüfung und eigener Cleanup: **NOT_EXECUTED**; eigene exakte
Head-CI sowie Merge-/Mainqualifikation einschließlich Cleanup: **PENDING**.

Class1-Voraussetzung erfüllt: PR295, Main `a585803de0d1d94be595dbf7b3153e582fbff9d2` (2026-10-08).
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37721226636) und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37721226645): **PASS**.
Der begrenzte Nachweis gilt für Linux SQL2019/CL150 local/central; sechs Objektzeugen, drei eigene Exportbereinigungen und Containercleanup sind belegt. Er qualifiziert keine neuen View-Spaltenzeugen und erklärt keine historische Fehlerursache.

### Deploymentwartung 2026-10-07 – datenwahrender Queue-/Control-Repeat

Der ausdrücklich besprochene Auftrag zum aktuellen Gesamtdeployment umfasst
Anlegen beziehungsweise Altern bestehender Objekte unter Erhalt persistenter
Daten und die gewählte zusätzliche eigenständige SQL-Datei. PR282 liefert
den Export; PR283 korrigiert den Queue2.1-Repeat mit allen sieben Zuständen.
Diese Folgekorrektur begrenzt den installierten Controlconsumer auf den
bekannten vollständigen Queue2.1-/Control1.0-Verbund mit deaktiviertem Gate
und ohne Claims, Holds oder offene Reservations. Sie implementiert keine
neue öffentliche SQL-Funktion und erweitert weder Testziele noch Rechte.

Der [bestehende Controlvertrag](../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md)
beschreibt Formprüfung, gemeinsame Lifecyclelockreihenfolge und begrenztes
Schreibfencing. Kein Disable, Uninstall oder Token-/Historiereset dient als
Hilfsmigration. Der ergänzte externe Upgradeadapter bestand am 2026-10-07 auf
SQL Server 2019 Linux am Commit `91507c65ac24051890a1775cc4264c8c119f549f`
einschließlich befüllter Verbundrepeats, Negativfälle und eigener Bereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37672934548)).
Allgemeiner Gesamt-Refresh, unbekannte Migrationsformen,
Windows-/weitere Versionsmatrix und reale Minimalrechte bleiben getrennt.

#### Fortsetzung und Pausenauftrag

Der Benutzer verlangt am 2026-10-07 nach Abschluss dieser Entwicklungsrunde
einschließlich [PR284](https://github.com/gecompat/SQL_Server_Toolbelt/pull/284)
und Merge nach `origin/main` eine Entwicklungspause. Mit diesem Merge tritt
die Pause in Kraft; weitere Wartungswellen beginnen erst nach ausdrücklichem
Fortsetzungsauftrag. Der native Verbundnachweis oben ist bestanden. Finale
Head-CI und tatsächlicher Merge sind im PR nachvollziehbar; ein noch laufender
oder fehlgeschlagener Check ist keine Integrationsevidenz.

Datierter Fortsetzungsauftrag 2026-10-07: Der Benutzer hebt die Pause mit
„Fortsetzen. Lies aber Regelwerk neu“ auf. Native Regelkette, Foundation und
relevante Projektregeln wurden neu gelesen; `main` einschließlich PR285 und
die Modulquellen wurden abgeglichen. Die nächste Wartungswelle ergänzt den
befüllten File-Content-Repeat ausschließlich als Test-/Evidenzscope unter
der vorhandenen Deploymentfreigabe. Neue öffentliche SQL-Funktionen bleiben
einzeln freigabepflichtig; lokale SQL-/Dockerläufe bleiben ausgesetzt.

File-Content-Wartung: Der befüllte 1.0.0-Repeat bestand am Commit
`8effcee91106cb4b8924c7a839928d550c0653b6` auf SQL Server 2019/150,
2022/160 und 2025/170 Linux jeweils lokal/zentral mit zwei echten Deploys
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37687448814)).
Vier synthetische Zeilen, verbrauchte Identitywerte und ausgewählte
Katalogmetadaten einschließlich vorhandener Permissions blieben erhalten;
Tabellen-/Spaltenannotation blieb gleich, Tabellen-`MS_Description` wurde
kanonisch erneuert. Keine Benutzergrants wurden erzeugt. Der erste offene
Tabellenscope ist jetzt `ExecutionCancellation`; Windows, weitere Repeat-CLs,
nichtleere Benutzergrants, echte Minimalrechte und historische Übergänge
bleiben separat. Finale Head-CI/Merge werden über
[PR286](https://github.com/gecompat/SQL_Server_Toolbelt/pull/286) geprüft.

Arbeitsmodus konkretisiert 2026-10-07: Der Benutzer verlangt unmittelbare
autonome Fortsetzung und Delegation mit Abschlussmeldungen; die geplanten
20-Minuten-Stupser sind ausschließlich ein Sicherheitsnetz. Nach jedem
abgeschlossenen Arbeitspaket wird die nächste konkrete freigegebene Arbeit
direkt vorbereitet beziehungsweise umgesetzt. Agentenberichte werden vor
Integration abgewartet und gegen Quellen sowie tatsächliche Tests geprüft.
Cancellation-Wartung: Zwei befüllte 1.0.0-Repeats bestanden am Commit
`fac18e590f854a26364e5f498c6a2b5d330a95c2` auf SQL Server 2019/150,
2022/160 und 2025/170 Linux jeweils lokal/zentral
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37690604199)).
Alle fünf Spalten einschließlich Rowversion, Audit- und Textbytes sowie
ausgewählter Katalog und eigene Tabellen-/Spaltenbeschreibungen blieben
erhalten; vorhandene API-/Parallelitäts-/Consumer-/Uninstallfälle und eigene
CI-Bereinigung bestanden. Finale Head-CI und Merge sind in
[PR287](https://github.com/gecompat/SQL_Server_Toolbelt/pull/287) abzugleichen.
Der nächste konkrete Wartungsscope ist jetzt `EventLog`: dessen bestehende
WorkType-Reaktivierung zuerst prüfen, anschließend den unveränderten aktiven
Repeat. Keine neue öffentliche Funktion oder Änderung dieser Semantik.

EventLog-Wartung: Der befüllte Repeat bestand am Commit
`6f51078cfa1f13ace32212f07d46de8d55d39ef0` auf Linux2019/150,2022/160,
2025/170 jeweils lokal/zentral
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37692309192)).
Alle 24 Eventspalten und verbrauchte Identitywerte bleiben über zwei echte
1.0.0-Deploys erhalten. Der erste reaktiviert die über Register/Disable
abweichend deaktivierte eigene WorkType-Registrierung kanonisch; der zweite
erhält die vollständige aktive Zeile einschließlich Rowversion. Andere
Registrierungen, ausgewählter Katalog und eigene Beschreibungen bleiben gleich.
Bestehende API-/Rollback-/Parallelitäts-/Consumer-/Uninstallfälle sowie eigene
CI-Bereinigung bestanden. Finale Head-CI/Merge sind in
[PR288](https://github.com/gecompat/SQL_Server_Toolbelt/pull/288) abzugleichen.
Keine Source-/Deploy-/Provider-/Rechteänderung. Der nächste konkrete
tabellenreine Wartungsscope ist jetzt `SecondSessionProvider`; neue Windows-,
weitere Repeat-CL-, Benutzergrant-, Minimalrechte- und historische Nachweise
bleiben getrennt.

SecondSessionProvider-Wartung: Zwei echte befüllte 1.1.0-Repeats bestanden
am 2026-10-08 am Commit `32ee260e413b8de7f9b2046ffdc11618b0afd69b` auf
Linux2019/150,2022/160,2025/170 jeweils lokal/zentral
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37693379887)).
Genau ein deaktivierter synthetischer `loopback`-Eintrag blieb mit allen acht
Spalten einschließlich Audit-/Unicode-/Padding-/Rowversionbytes sowie
ausgewähltem Katalog und eigenen Beschreibungen erhalten. Keine RPC- oder
Configure-USP-Aufrufe im neuen Tabellenrepeat. Bestehende API-/Provider-/
Rollback-/Parallelitäts-/Consumer-/Uninstallfälle und eigene CI-Bereinigung
bestanden; abhängige W5b-Suite37693379826 ebenfalls am selben Head SUCCESS.
Finale Head-CI/Merge sind in
[PR289](https://github.com/gecompat/SQL_Server_Toolbelt/pull/289) abzugleichen.
Neue Windows-Repeats, weitere CLs, Benutzergrants, Minimalrechte und historische
Übergänge bleiben offen. FileSystemRoot besitzt neun Spalten ohne Identity,
Auditfelder oder Rowversion; sein nativer Repeat benötigt zusätzlich die
bestehenden Windows-/Assembly-/Trustvoraussetzungen. Der vorhandene Buildworkflow
ersetzt keine SQL-Runtime. Unabhängig ist der gemeinsame exportierte Repeat
von neun CLR-freien Modulen mit 14 der 15 Tabellen als nächster Testscope
vorbereitet; Windows-FileSystemRoot und vollständiger 44-Modul-Export bleiben
getrennt. Keine neue Funktions-, Rechte-, Provider- oder Trustfreigabe.

Gemeinsamer Exportrepeat, vorbereitet 2026-10-08: Der neue Testadapter
konsumiert die echten hashgebundenen `-OutputSqlFile`-Exporte der neun
CLR-freien Module lokal/zentral in frischen Sitzungen. Alle 14 Tabellen werden
synthetisch befüllt und über zwei Repeats vollständig verglichen; erwartete
File-Content-Beschreibungsnormalisierung und EventLog-WorkType-Reaktivierung
sind separat abgegrenzt. Er nutzt ausschließlich das bestehende externe
Linux2019/CL150-CI-Ziel. Offlineexport und unabhängige Reviews sind bestanden;
Der erste gemeinsame native Lauf am Commit `e5b51d14500203947fd45d6ad0533e40b1302c8a`
ist im neuen Test FAILED, zunächst ohne abgegrenzte Primärursache
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37696018416)).
Vorherige Worker-/Upgradefälle und eigene Containerbereinigung bestanden.
Der Diagnoselauf `947da95d61ae617f88e42847ae453dd27e132197` ist ebenfalls
FAILED im Verbindungs-Preflight
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37697052700)).
Die Builder-Dotzuweisungen `InitialCatalog`/`ConnectTimeout` scheitern ohne
Serververbindung reproduzierbar; sie werden durch die bestehenden gültigen
Indexer ersetzt. Der separate Adaptercleanup-Pfadseparatorfehler ist korrigiert.
Beide FAILED-Läufe bleiben historische Evidenz und gelten nicht als Runtime-PASS.
Der korrigierte Builder-Head `6989d8ac43033e8cd45c2f8fb88f59239429c64a`
besteht den Preflight, ist aber beim eigenen Datenbank-/Sitzungsgate FAILED
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37697908672)).
Vorherige Runtimefälle und Containerbereinigung bestanden. Der Diagnoselauf
`e79bf5a4c1d0db3760b6fbc29a8d1714b8fc7368` bleibt FAILED
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37699250549)):
Zwölf Einzelbedingungen bestehen, das kombinierte Gate wirft State 13.
Die Korrektur prüft die neutrale Sitzung getrennt vor und nach dem gemeinsam
gebundenen Besitzgate. Kein Besitzprädikat entfällt; Autocommit während der
Katalogauswertung ist eine Hypothese, keine nativ gemessene Primärursache.
Der Korrekturlauf `52526f7836b0d4c113991fc972608b1eff276283` besteht das
Besitzgate und die Erstinstallation, bleibt beim initialen Fixture-Sitzungsgate
FAILED/SQL54980/State1
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37700707745)).
Die gleichen kombinierten Sitzungsprüfungen in den vier Testfixtures werden
ebenfalls ohne Prädikatverlust in einzelne IFs getrennt. Vorherige Workerfälle
und Containerbereinigung bestehen. Der korrigierte Head
`a836b87778fbe4c498b4b1ce05f06c58373ea03c` besteht den gemeinsamen Exporttest
auf Linux2019/CL150 lokal und zentral: alle 14 Tabellen über zwei befüllte
Repeats, eigene DB-/Dateibereinigung sowie vorhandene Worker-/Upgradefälle
und Containerbereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37701845352)).
Die Dokumentations-CI desselben Heads besteht ebenfalls. Die historischen
FAILED-Läufe bleiben getrennt; dies qualifiziert ausschließlich diese
Neun-Modul-Folge im genannten Zielscope.
Details und offene Grenzen stehen in
[Deploymenttests](../Deployment/Tests/README.md). Windows-FileSystemRoot und
vollständiger 44-Modul-Export bleiben getrennte Nachweise; Source, Deploy und
öffentliche SQL-API werden nicht geändert.

Exportmigration, vorbereitet 2026-10-08: Unter derselben engen
Deploymentwartungsfreigabe ergänzt `Queue20Upgrade` ausschließlich die echte
Migration von gepinnter Queue2.0 nach Queue2.1 mit erstmaliger Control1.0-
Installation. Sieben aktuelle Bootstrapmodule und anschließend der vollständige
aktuelle Neun-Modul-Export werden lokal/zentral in frischen Sitzungen konsumiert.
Acht Legacytabellen mit 109 Feldern, darunter alle 43 WorkItem-Felder und ein
aktiver Originalclaim, werden vor weiterer persistenter DML binär verglichen;
die leere Barrier-Tabelle besitzt einen ausdrücklichen Countzeugen. Drei
neutrale Managedfelder, sechs neue Tabellen mit bekannten Spaltenformen und
neutralen Gate-/Controlzuständen werden rein lesend geprüft. Keine neue
Callback-/SQL-API, Post-Migration-Completion, Admission oder zusätzliche
14-Tabellen-Repeatfolge. Source, Deploy und die bisherigen vier Repeatfixtures
bleiben unverändert; vorhandene Rechte werden nur beobachtet. Offlineprüfungen
und unabhängiger Domainreview bestanden, native Migration ausdrücklich
`NOT_EXECUTED`. Parent [PR290](https://github.com/gecompat/SQL_Server_Toolbelt/pull/290)
bestand am Qualifikationshead `a836b87778fbe4c498b4b1ce05f06c58373ea03c`
den begrenzten nativen Exportrepeat einschließlich eigener Bereinigung
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37701845352));
Dokumentations-CI desselben Heads bestand ebenfalls. Frühere FAILED-Läufe
bleiben historische Evidenz. Finale Parent-Head-CI am Stand
`bdc2ba9f001190d9d63cc97e040f1e693fb4dafd`
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37702891518))
bestand; PR290 ist nach `origin/main` integriert, Mainstand
`acba925419973d9dfb2b7b8e481d67f0a75789e3` mit identischem Parentbaum.
Main-Dokumentations-CI bestand; Main-Worker-CI
([CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37703434018))
bestand einschließlich eigener Bereinigung. Eigene native Migrationsqualifikation
bleibt bis tatsächlicher eigener Head-CI offen. Keine neue Funktions-, Rechte-,
Provider-, Trust-, Ziel- oder allgemeine Migrationsfreigabe wird daraus
abgeleitet. Details und Grenzen stehen in den
[Deploymenttests](../Deployment/Tests/README.md).

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



Export-Parametermetadaten, vorbereitet 2026-10-08: Die vorhandene
Deploymentwartungsfreigabe umfasst als nächsten begrenzten Testscope die
bestehenden `USP_PrepareResultTable` und `USP_EnqueueWork` mit insgesamt elf
Parametern. Der vorbereitete Fall `ParameterMetadata` konsumiert die echten
Exporte von result-table, work-type und work-queue lokal/zentral einmal zur
Installation und einmal zum Repeat in jeweils frischen Sitzungen. Vier eigene
class-2-Annotationszeugen prüfen typisierte Werte und `MS_Description` auf
zwei ausgewählten Parametern. Parameterkatalog, ausgewählte Objekt-/Modul-
metadaten, Definitionbytes und alle vorhandenen class-2-Properties dieser
beiden Procedures werden privat binär verglichen; vorhandene Permissions
werden nur beobachtet, auch eine leere Menge wird ausdrücklich gezählt.
T-SQL-`has_default_value = 0` ist kein Nachweis der Parameterdefaults;
deren Definitionbytes bleiben Teil des Erhaltungsorakels.

Offline bestanden: drei Fixtures und ihre quellengebundenen Parameterkarten,
unabhängige Reviews sowie die beiden aktuellen Dreimodul-Exporte mit jeweils
90 Batches, drei Endmarkern und vier Guards; 180 exportierte Batches wurden
mit SQL150 ohne Fehler geparst, die Adapter-PowerShell-AST ist fehlerfrei.
Die native Parameterprüfung einschließlich eigener Bereinigung ist
`NOT_EXECUTED`; Integration und exakte Head-CI stehen aus. Produktquellen,
öffentliche API und Deployment-DDL bleiben unverändert, ebenso Rechte und
Testziele. Bestehende Repeat- und Queue20Upgrade-Zweige bleiben erhalten.
Keine API-Ausführung, neue Tabelle, Benutzergrants, Windows-/weitere CL-
Qualifikation oder vollständige 44-Modul-Erhaltungsbehauptung.

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
Details stehen in [Deploymenttests](../Deployment/Tests/README.md).


Schemaannotation beim bestehenden Exportrepeat, Stand 2026-10-08:
Der nächste begrenzte Maintenance-Test ergänzt genau fünf class-3-Zeugen auf
`toolbelt_core` und `toolbelt_file` samt vollständigem typisiertem Erhaltungsorakel.
Die bestehenden 14 Tabellen mit 156 Spalten, beide Repeatfenster, Identityzeugen
und eigene Bereinigung bleiben erhalten. Der Branch ergänzt drei bestehende
Populated-Fixtures; native class3-Prüfung und ihr eigener Cleanup
sind **NOT_EXECUTED**. Keine neue SQL-Funktion, Rechte- oder Zieländerung.

Voraussetzung, Stand 2026-10-08: PR293 ist nach `main`
`2ad2c018da18768c05f05e0fd7cf4c333fd6b090` gemergt.
[Main-Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37715148163)
und [Main-Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37715148155)
bestanden am exakten Mainstand; Parameterrepeat, beide bestehenden Exportfälle,
drei eigene Exportbereinigungen und Containercleanup sind separat bezeugt.
Die Parameter-Mainvoraussetzung ist erfüllt. Native class3-Prüfung und
eigener Cleanup sind **NOT_EXECUTED**; die eigene exakte Head-/Main-CI
einschließlich Bereinigung bleibt **PENDING**.

Objektannotation im bestehenden Exportrepeat, Stand 2026-10-08:
Der Branch ergänzt Setup und Assert um sechs eigene class-1/minor0-Zeugen auf
drei vorhandenen P/FN/V-Objekten. Capture und beide Repeatfenster bleiben erhalten.
[Deploymenttests](../Deployment/Tests/README.md) beschreiben das volle typisierte Orakel.
Native class1-Prüfung und eigener Cleanup: **NOT_EXECUTED**; exakte class1-Head-/Main-CI **PENDING**.

Class3-Voraussetzung erfüllt: PR294, Main `91e13af689334407527fddfdc8d22285933f4225` (2026-10-08).
[Worker-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37717103755) und [Dokumentations-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37717103790): **PASS**.

Runner und eigenständiger SQL-Export sind über PR282 integriert; PR283 erhält
den Queue2.1-Repeat ohne Control mit allen sieben Queuezuständen. Der enge
Verbundrepeat dieser Runde ist kein allgemeiner Schema-Refresh. Der offene
Gesamtscope umfasst 15 persistente Tabellen in acht Modulen; der neue
Verbundnachweis umfasst zehn Tabellen einschließlich WorkType.

Bei Fortsetzung zunächst die native AGENTS-Kette, Foundation und relevanten
Projektregeln neu ermitteln beziehungsweise einen regelkonform validierten
Analysecache verwenden. Danach den Merge- und CI-Stand aus Git/GitHub sowie
die aktuellen Modulquellen reconciliieren. Private Laufzeitjournale und
Chatverlauf ersetzen diese Repositoryquellen nicht.

| Reihenfolge | Nächster Wartungsscope | Noch fehlender Nachweis oder Entscheidung |
|---|---|---|
| 1 (gezielt bestanden) | `toolbelt.file.content` / `FileContentRootAllowlist` | Befüllter Repeat lokal/zentral in obiger Linux-/Default-CL-Matrix bestanden. Windows, weitere Repeat-CLs, nichtleere Benutzergrants und echte Minimalrechte bleiben offen. Dieser Tabellenrepeat benötigt weder Datei-I/O noch Konfigurations- oder CLR-Änderungen. |
| 2 (gezielt bestanden) | `toolbelt.core.execution-cancel` / `ExecutionCancellation` | Befüllte Repeats mit exakten Zeilen-, Rowversion- und ausgewählten Katalogvergleichen lokal/zentral in obiger Linux-/Default-CL-Matrix bestanden. Neue Windows-Repeats, weitere CLs, nichtleere Benutzergrants, Minimalrechte und historische Übergänge bleiben offen. |
| 3 (gezielt bestanden) | `toolbelt.core.event-log` / `EventLog` | Daten-/Identity-/ausgewählter Katalogerhalt und vertragsgemäße WorkType-Reaktivierung mit anschließend unverändertem aktivem Repeat lokal/zentral in obiger Linux-/Default-CL-Matrix bestanden. Neue Windows-Repeats, weitere CLs, Benutzergrants, Minimalrechte und historische Übergänge bleiben offen. |
| 4 (gezielt bestanden) | `toolbelt.core.second-session` / `SecondSessionProvider` | Deaktivierter Einzelprovider einschließlich acht Spalten, Audit-/Rowversionbytes und ausgewähltem Katalog lokal/zentral in obiger Linux-/Default-CL-Matrix bestanden. Neue Windows-Repeats, weitere CLs, Benutzergrants, Minimalrechte und historische Übergänge offen; keine Provider- oder Rechteausweitung. |
| 5 | `toolbelt.filesystem.windows` / `FileSystemRoot` | Befüllten Repeat unter bestehenden Windows-/Assembly-/Trustvoraussetzungen qualifizieren; fehlende Windows-Runtime nicht durch Offlineparser ersetzen. |

Danach die exportierte gemeinsame Modulfolge mit befüllten Tabellen prüfen.
Gesamtdeployment bleibt nicht atomar; Objekt-/Berechtigungserhaltung, lokale
und zentrale Modi, weitere Plattformen und echte Minimalrechte benötigen
eigene Qualifikation. Nichtleere Benutzergrants sind im Queue-/Control-Verbundrepeat
und File-Content-Repeat nicht nachgewiesen. Die fünf zusätzlichen Tabellenquellen erstellen
fehlende Tabellen, liefern aber keinen allgemeinen Schemaabgleich.
Unbekannte/partielle Installationen und historische Schemaübergänge benötigen
gesondert beschriebene versionierte Migrationspfade. Q1 V1 bleibt zustandslos.
Dieser Checkpoint erteilt keine neue Funktions-, API- oder generische
Copy-/Swap-Migrationsfreigabe.

Lokale SQL-/Dockerläufe bleiben bis zur gesonderten Freigabe nach Klärung des
Stabilitätsproblems ausgesetzt. Die native Windows-CLR-Qualifikation des neuen
ScriptDom-Pins und seines Table-Clone-Consumers bleibt ein getrennter offener
Nachweis; Syntaxparser und historische Security-Cloud-Ergebnisse ersetzen
keine frische Runtime- oder Security-Qualifikation. Fehlgeschlagene frühere
CI-Läufe behalten ihren Status.

### RI-2026-041: JSON Pointer – einzeln freigegeben 2026-10-05

Nach konkreter Besprechung und Design-/Enginevorprüfung in
[PR173](https://github.com/gecompat/SQL_Server_Toolbelt/pull/173) antwortete der
Benutzer ausdrücklich „Diese Pointer-Funktion freigegeben“. Genau eine lesende
T-SQL-MSTVF `toolbelt_json.TVF_ResolveJsonPointer`: Json/Pointer nvarchar(max),
MaxInputBytes bigint=16777216, MaxDepth int=128; positiv und nur absenkbar,
Pointer höchstens4000 UTF16-Einheiten. Genau eine Status/JsonType/Value/ErrorCode-
Zeile mit FOUND/MISSING/JSON_NULL/SQL_NULL/INVALID und besprochener Priorität.
Exakte Keys, passende Duplicatekeys ungültig, vollständige Unicode-/Tiefenprüfung,
native ISJSON/OPENJSON-Grammatik plus Policywalker; keine CLR-Änderung.
Fragmentkosten und API-/Lifecyclequalifikation sind ausdrücklich eingeschlossen.
Der [kanonische Vertrag](../Documentation/Architecture/JSON_POINTER_CONTRACT.md)
begrenzt die autonome Umsetzung einschließlich Review, begrenzter Tests,
exakter Head-CI, PR/Merge und eigenem Branch-Cleanup. Keine Schema-, Patch-,
Providerwechsel- oder Veröffentlichungsgenehmigung. Status: aktive Umsetzung;
keine öffentliche API-Runtimequalifikation allein aus der Freigabe abgeleitet.
Ältere offene Pointer-Sourcegate-Aussagen bleiben Historie; diese datierte
Einzelzustimmung ersetzt ausschließlich deren Freigabegrenze.

Native Vertragsgrenze 2026-10-05: SQL2019-ISJSON wirft bei129 offenen
Containern SQL13606/state1, sowohl für gültiges als auch fehlerhaftes JSON.
Zwei begrenzte Adapter scheiterten in Safety; der zweite isolierte Fall41.
Je FAILED_CLEANED, eigene DB über neue Verbindung abwesend und Inputpins
unverändert; kein vollständiger Sicherheits-/Client-/Lifecycle-PASS.
Der [konkrete Änderungsvorschlag](../Documentation/Architecture/JSON_POINTER_NATIVE_DEPTH_BOUNDARY.md)
führt einen vorgelagerten festen128er-Guard mit DEPTH_LIMIT vor JSON_SYNTAX
nur jenseits dieser nativen Grenze ein. Zustimmung zu dieser neuen Priorität
steht aus; die bestehende Funktionsfreigabe bleibt gültig. Unabhängige
Lifecycle-/Dokumentationsarbeit darf fortgesetzt werden.
Separater Lifecycle-Scope auf Linux2019/latest CL150 und Windows2025/exaktCU8
CL170 anschließend bestanden: je local/central/Consumer,15 direkte Clientreader,
42 gezielte Lifecyclefälle, Exit0 und vollständige Kanäle mit leeremStderr.
Frische unabhängige Audits bestätigen je drei eigeneDBs abwesend, je zwei
Marker-/Fremdslot-/Dependencyfixtures exakt restauriert mit zwei Abweisungen
und sämtlicheInputpins unverändert; Nullscope Konfiguration/Rechte/Trust.
Contract/Safety-Fixtures in diesem Scope ausdrücklich nicht ausgeführt;
die notwendige Prioritätszustimmung bleibt offen.

Anschließende konkrete Zustimmung 2026-10-05: Der Benutzer antwortete
„Diese Prioritätsänderung freigegeben“. Damit ist genau der vorgelagerte
nonnegative128er-Strukturguard mit DEPTH_LIMIT auch vor fehlerhafter Syntax
jenseits128 und der geschützte Scalarwrapper freigegeben. Bis128 bleibt
JSON_SYNTAX vor caller-seitig abgesenktem MaxDepth; sonstige Oberfläche und
Semantik unverändert. Sourcekorrektur und neue vollständige Qualifikation
werden autonom fortgesetzt. Die vorherigen offenen Aussagen dokumentieren
den Stand vor dieser ausdrücklichen Antwort, die Fehlläufe bleiben Historie.
Finaler freigegebener Guard-/Wrapperstand auf Linux2019/latest CL150 und
Windows2025/exaktCU8 CL170 vollständig im begrenzten local/central/Consumer-
Scope bestanden: je3072 feste Contract-/Safety-APPLY-Oracles,15 direkte
Clientreader,42 Lifecyclefälle und Erst-/Repeat-/Uninstall-/Repeat. Je Exit0,
vollständige Kanäle und leeresStderr. Frische Audits bestätigen COMPLETE42,
je drei eigeneDBs abwesend, je zwei Marker-/Fremdslot-/Dependencyfixtures
exakt restauriert mit je zwei Abweisungen und sämtlicheInputpins unverändert.
Nullscope Konfiguration/Rechte/Trust. Beide finalen Zieladapter verwenden
identische eingefrorene Repository-Inputs. Weitere Ziele, Minimalrechte,
16MiB-Maximalworkload/Heap und exakteHead-CI separat offen; teilweise validiert,
unveröffentlicht. Frühere Fehlläufe bleiben fehlgeschlagen.

Zusätzliche Qualifikation 2026-10-06: Auf demselben zuvor ausgewählten,
schema-validierten Windows2025/exaktCU8-Ziel bestanden die vollständigen
Pointer-Adapter mit CL150 und CL160, jeweils local/central/Consumer,
Contract/Safety, direkte Clientmetadaten und42 Lifecyclefälle. Zwei frische
unabhängige Audits bestätigen je eigene DB-Bereinigung, exakte Wiederherstellung
der Marker-/Fremdslot-/Dependencyfixtures und unveränderte Inputpins; keine
Konfigurations-, Rechte- oder Truständerung. Die früheren CL170-/Linuxnachweise
bleiben getrennt. Weitere physische Ziele, Minimalrechte,16MiB-Maximalworkload/
Heap und vollständige Runtime-Head-CI bleiben offen.

CI-Fortschritt 2026-10-06: [PR187](https://github.com/gecompat/SQL_Server_Toolbelt/pull/187)
bestand am exakten Head `57dbc5e319b8229a68cf87d0a1140dec687ae4d2` die
[Dokumentationsprüfung](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403031663)
und den [Pointer-Runtime-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403031731)
mit erfolgreichen Linux-2019/2022/2025-Jobs. Auf `main` bestanden danach
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403199690)
und [Pointer-Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37403199703)
erneut. Der CI-Scope umfasst synthetische Contract-/Safetyfixtures, echte
Clientmetadaten und installierte Baseline mit local/central/Consumer, Repeat
und Uninstall. Die 42 gezielten Lifecyclefälle sind bislang nur in den oben
genannten physischen Labadaptern belegt. Ihre vollständige Head-CI, weitere
physische Ziele, Minimalrechte, Hard-Interrupt-Recovery, 16-MiB-Maximalworkload
und Heap bleiben offen; `partially validated`,
`unreleased`.

Eng begrenzte Lastqualifikation 2026-10-06: Nach
[PR201](https://github.com/gecompat/SQL_Server_Toolbelt/pull/201) bestanden
auf flüchtigem Linux-SQL2019-CL150-Container acht einzeln manuell ausgelöste
Größen-/Formstufen: Root und `/k` bei 64KiB,1MiB,4MiB und exakt16MiB
Originalbytes mit serverseitigem Einzeilen-/Längen-/SHA2-256-Orakel und
bestätigter eigener Bereinigung. Die [Testmatrix](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md)
verlinkt jeden Run. Die zuvor offenen 16-MiB-Aussagen beschrieben den Stand
vor diesen gezielten Läufen. SQL2022/2025-Maximallast, weitere Plattformen,
Tiefe128 bei Maximalgröße, Heap, Parallelität, tatsächliche Minimalrechte,
Hard-Interrupt-Recovery und Release bleiben offen; `partially validated`,
`unreleased`.

Weitere eng begrenzte Tiefenqualifikation 2026-10-06: Nach
[PR203](https://github.com/gecompat/SQL_Server_Toolbelt/pull/203) bestanden
auf flüchtigem Linux-SQL2019-CL150-Container zehn manuelle Einzeljobs:
64KiB mit Tiefe2,4,8,16,32,64,128 und anschließend Tiefe128 mit1MiB,4MiB
und exakt16MiB. Je eigenes serverseitiges Oracle, testdefinierte 3-GiB-
Containergrenze und bestätigte Bereinigung. Die [Testmatrix](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md)
verlinkt alle Runs. Die zuvor offene Tiefe128/Maximalgröße ist damit nur für
diese synthetische Kombination geschlossen. SQL2022/2025-Maximallast,
weitere JSON-Formen/Plattformen, Heap, Parallelität, Minimalrechte,
Hard-Interrupt-Recovery und Release bleiben offen; `partially validated`,
`unreleased`.

Zusätzliche lokale Lastqualifikation 2026-10-06: derselbe unveränderte
Einzelfalladapter bestand auf flüchtigem Linux-SQL2022-CL160 und SQL2025-
CL170 je Root und `/k` bei64KiB,1MiB,4MiB und exakt16MiB. Alle16 Fälle
lieferten das exakte serverseitige Einzeilen-/Längen-/SHA2-256-Oracle und
bestätigten eigene Bereinigung; frische Docker-Owner-Abfragen fanden keinen
eigenen Lastcontainer. Kein neuer GitHub-Dispatch oder Labzieltest. Frühere
offene Aussagen beschreiben ihren damaligen Stand. Tiefe128 bei Maximalgröße
auf SQL2022/2025, weitere JSON-Formen/Plattformen, reale Heap-/Parallel-
kapazität, Minimalrechte, Runner-/Host-Recovery und Release bleiben offen.

Weitere lokale Tiefenqualifikation 2026-10-06: Auf denselben flüchtigen
Linux-SQL2022-CL160-/SQL2025-CL170-Images bestanden je sieben Einzelprozesse
bei64KiB/Tiefe2,4,8,16,32,64,128 und je drei bei Tiefe128/1MiB,4MiB,
exakt16MiB. Alle20 lieferten das serverseitige Einzeilen-/Längen-/Hashoracle,
meldeten eigene Bereinigung und bestanden je Version den frischen
Owner-Label-Abwesenheitsaudit. [Testmatrix](../Modules/toolbelt.json.pointer/Tests/JSON_POINTER_TEST_MATRIX.md).
Die vorherige offene Tiefe128/Maximalgröße war zeitgebunden. Andere JSON-
Formen/Plattformen, tatsächlicher Heap, Parallelität, Minimalrechte,
Runner-/Host-Recovery und Release bleiben offen; `partially validated`,
`unreleased`.

### RI-2026-076: sechs Safe-Cast-TVFs – einzeln freigegeben 2026-10-05

Nach der Vertragsbesprechung in [PR170](https://github.com/gecompat/SQL_Server_Toolbelt/pull/170)
und der konkreten anschließenden Frage antwortete der Benutzer ausdrücklich:
„Diese sechs Funktionen freigegeben“. Damit sind genau `TVF_TryCastBigInt`,
`TVF_TryCastDecimal`, `TVF_TryCastDate`, `TVF_TryCastDateTime2`, `TVF_TryCastBit`
und `TVF_TryCastUniqueIdentifier` zur autonomen Umsetzung freigegeben.
Reine Inline-T-SQL-TVFs, je Value/Status/ErrorCode, strikte ASCII-/ISO-Lexik,
decimal(38,18), datetime2(7), maximal8192 Inputbytes, keine stille Rundung;
die explizite Zustimmung umfasst exakte Bereichsprüfung vor LOSSY und
INVALID_ARGUMENT/PARAMETER bei ungültigen Budgets. Zweck, native Alternative,
Optimizer-, Locale-, Trunkierungs- und Rundungsrisiken wurden besprochen.

Der [kanonische Vertrag](../Documentation/Architecture/SAFE_CAST_CONTRACT.md)
konkretisiert die Umsetzung. Status: implementiert, `partially validated`,
`unreleased`. Finale lokale Adapter auf Linux2019/latest CL150 und Windows2025/
exaktCU8 CL170 bestanden local/central und mit separatem Consumer: je13104
API-Oracles,54 Clientreader und38 gezielte Lifecyclefälle sowie Uninstall/Repeat.
Je Exit0, vollständige Kanäle und leeres Stderr; frische unabhängige Audits
bestätigen alle Inputpins, zwei Marker-/zwei Fremdslotfixtures exakt restauriert
und drei eigene Datenbanken abwesend. Keine Konfigurations-, Rechte- oder
Truständerungen. Drei frühere Gesamtfehlläufe bleiben getrennt fehlgeschlagen.
Weitere physische Ziele, Minimalrechte, Heap und exakte Head-CI separat offen.
Zusätzliche Qualifikation 2026-10-06: Auf demselben bereits ausgewählten,
schema-validierten Windows2025/exaktCU8-Ziel bestanden die vollständigen
Safe-Cast-Adapter mit CL150 und CL160, je local/central/Consumer mit 13104
API-Oracles, 54 Clientreadern und 38 Lifecyclefällen. Zwei unabhängige frische
Audits bestätigten je drei eigene DBs abwesend, exakte Marker-/Fremdslot-
Wiederherstellung und unveränderte Input-/Sourcepins. Keine Konfigurations-,
Rechte- oder Truständerung; übrige physische Ziele, Minimalrechte, Heap und
vollständige Runtime-Head-CI bleiben offen.

CI-Fortschritt 2026-10-06: [PR186](https://github.com/gecompat/SQL_Server_Toolbelt/pull/186)
bestand am exakten Head `64f4ab9dbd48a8eefd838f9fb95f3ab13e507513` die
[Dokumentationsprüfung](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402202963)
und den [Safe-Cast-Runtime-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402203046)
mit erfolgreichen Linux-2019/2022/2025-Jobs. Auf `main` bestanden danach
[Dokumentation](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402837670)
und [Safe-Cast-Runtime](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37402837558)
erneut. Der CI-Scope umfasst synthetische API-Fixtures, echte Clientmetadaten
und installierte Baseline mit local/central/Consumer, Repeat und Uninstall.
Die 38 gezielten Lifecyclefälle sind bislang nur in den oben genannten
physischen Labadaptern belegt. Ihre vollständige Head-CI, weitere physische
Ziele, Minimalrechte, Hard-Interrupt-Recovery und Heap bleiben offene
Nachweise; `partially validated`, `unreleased`.

Unabhängiger Review, begrenzte relevante Tests, exakte Head-CI, PR/Merge und
eigener Branch-Cleanup gehören zur bereits beauftragten Fortsetzung.
Keine neue Pointer-/Schema-/CLR-/Veröffentlichungsfreigabe. Ältere Aussagen
über offene Safe-Cast-Details dokumentieren den damaligen Vorschlagsstand;
diese datierte Einzelzustimmung ersetzt ausschließlich dessen Freigabegrenze.

### RI-2026-109: CSV-Memory – konkretisierte Umsetzung freigegeben 2026-10-05

Die unmittelbar vor der Fortsetzungsanweisung vorgelegte konkrete Welle umfasst
`USP_ParseCsv` und `USP_WriteCsv` mit eigener portabler SAFE-CLR-Assembly,
100000 Datenzeilen, 1024 Spalten, 1000000 Zellen und 16 MiB UTF16-Textbudget;
die Limits sind ausschließlich absenkbar. Zweck, öffentlicher Vertrag,
NULL-Token, T-SQL-Alternative, Trust-/Deploymentaufwand und Risiken wurden
besprochen. Darauf beauftragte der Benutzer autonome Weiterentwicklung bis
zu seinem Stopp oder einer tatsächlich notwendigen Eingabe und verwies
ausdrücklich auf die abgeschlossene Besprechung. Diese Antwort auf den
konkreten CSV-Vorschlag ist die funktionsbezogene Implementierungsfreigabe;
die zuvor engere Bewertung als offenes CSV-Sourcegate ist damit korrigiert.

Scope: genau diese beiden öffentlichen USPs, In-memory ohne Datei-/Netzwerkzugriff,
kanonischer ResultTable-Vertrag, unabhängiger Review, begrenzte aussagekräftige
Tests, exakte grüne Head-CI, PR/Merge und eigener Branch-Cleanup. Keine
Veröffentlichung; JSON Pointer, Safe Cast und JSON Schema erhalten daraus
keine Sourcefreigabe. Der [CSV-Vertrag](../Documentation/Architecture/CSV_MEMORY_CONTRACT.md)
konkretisiert die bereits besprochenen Grenzen. Version1.0.0 ist `implemented`,
`partially validated`, `unreleased`. Am 2026-10-05 bestanden statische Verträge
und das exakt gepackte CLR-Binary unter .NET48 in drei Kulturen einschließlich
harter Grenzfälle und IL-/NoIO-Prüfungen. Der achte öffentliche native
Gesamtadapter bestand auf Linux2019/latest CL150 local/central mit finalem
gepacktem Produkt und gleichen CLR-Bytes: drei SQLfixtures, Clientmetadaten,
Clean/Repeat, fünf Slots/drei Bindings, 29 konkrete Caller-/SET-/Lock-/Rollback-/
Confirm0-Prüfungen, frischer SC-/UTF8-Consumer und Uninstall/Repeat. Exit0,
vollständige Kanäle, leeres Stderr und eigener Cleanup im Lauf bestanden;
Der frische unabhängige Audit dieses Laufs bestand anschließend.
Derselbe finale Adapter und dasselbe Produkt-/Binarypaar bestanden zusätzlich
auf Windows2025/exaktCU8 CL170 local/central mit identischem Fixture-/Client-/
Consumer-/29-Lifecycle-Scope, Exit0, vollständigen Kanälen, leerem Stderr und
Cleanup im Lauf. Der frische Linuxaudit bestätigt drei eigene DBs/einen eigenen
Trusthash abwesend; der frische Windowsaudit bestätigt ebenfalls drei eigene
DBs/einen eigenen Trusthash abwesend. Historische Syntax-/
LF-Padding-Fehlläufe und der fünfte Metadata-Fehllauf bleiben FAILED. Die
Produktkorrekturen betreffen LF-Padding und drei Help-first-NOT-NULL-Spalten.
Keine Konfigurations-/Rechteänderungen. Weitere Ziele, Fremdslot-/
Driftvollmatrix, Minimalrechte und Heap bleiben offen.
Abschluss: [PR169](https://github.com/gecompat/SQL_Server_Toolbelt/pull/169)
ist mit fünf erfolgreichen Checks am exakten Head gemergt. Main/origin-main
und eigener Branch-Cleanup geprüft. Modulstatus bleibt teilweise validiert
und unveröffentlicht; keine Übertragung der Freigabe auf Folgefunktionen.

Zusätzlicher begrenzter Marker-Nachweis am 2026-10-05: ein mechanisch vom
öffentlichen Labadapter abgeleiteter, hashgebundener Adapter prüfte ausschließlich
zwei synthetische Typdriftfälle auf Linux2019/latest CL150 lokal. Deploy und
Uninstall wiesen `Toolbelt.Managed` als `int` statt des ursprünglichen `bit`
auf `USP_ParseCsv` jeweils mit SQL55324/state5 ab; vollständige Metadaten blieben
unverändert und der Transaktionszustand neutral. Der eigene Marker wurde unter
exakter Identitäts-/Driftprüfung restauriert. Exit0, vollständige Kanäle und
leeres Stderr sowie der frische unabhängige Audit bestanden: eine eigene DB und
ein eigener Trusthash abwesend, keine Konfigurations-/Rechteänderungen.
Diese zwei Fälle sind ein separater Teilnachweis; sie erweitern weder den
29-Fall-Zähler noch die API-/Client-/Central-/Windows- oder vollständige
Fremdslot-/Driftmatrixqualifikation.

### Queue-Worker 2 – autonome Umsetzung freigegeben 2026-10-04

Nach Besprechung von Zweck, Verträgen, Alternativen und Risiken beauftragte
der Benutzer ausdrücklich: „ok, machen wir es so, wie von dir vorgeschlagen;
starte autonome Verarbeitung wie besprochen“. Die Freigabe umfasst zentrale
SQL-Steuerung, getrennte Steuerungs-/Claim-APIs mit Versionsvergleich,
global und je Worker zur Laufzeit veränderbare Parallelität, konfigurierbare
Registrierungsintervalle mit Defaults 15/60 Sekunden sowie den kontrollierten
Übergang zwischen verwaltetem und bisherigem Betrieb. Intervalländerungen
gelten nur für neue Worker-Generationen. Keine automatische Deaktivierung.

Zusätzlich einzeln besprochen und bestätigt: Sofortstopp genau einer konkreten
Verarbeitung oder mehrerer/aller Worker. Persistenter Stop-/Hold-Auftrag muss
automatische Claims, Lease-Recovery und Retry vor dem Abbruch verhindern.
Erst nach nachgewiesenem Rollback/Ende darf der Slot freigegeben werden;
ungeklärte Ausgänge bleiben gesperrt. Bereits erfolgter atomarer Commit bleibt
erfolgreich. Ein gestoppter Auftrag bleibt erkennbar zurückgehalten bis zur
ausdrücklichen Wiederfreigabe; jeder geeignete Worker darf ihn dann übernehmen.
Korrektur im registrierten Handler, kein frei ausführbarer SQL-Text.
Ein einzelner Auftragsstopp lässt den Worker andere Arbeit ausführen;
mehrere/alle gestoppten Worker bleiben bis zur ausdrücklichen Reaktivierung
für neue Starts gesperrt. Historie bleibt erhalten.

Status: `implemented`, `partially validated`, `unreleased`. Der SQL-Vertrag mit
gezielten Negativfällen und sechs tatsächlichen Lifecycle-Abweisungen sowie
der echte Queue-Upgrade 2.0→2.1 bestanden am 2026-10-04 auf SQL Server 2019 Linux.
Die fokussierten Managedläufe mit Windows-Workerhost bestanden einschließlich
eigenem Cleanup am 2026-10-05 auf 2019 Linux und 2025 Windows/CU8. Zu diesem
Zeitpunkt blieb der Linux-Workerhost-Nachweis über exakte Head-CI offen. Der technische
[Worker-Control-Vertrag](../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md)
konkretisiert die Umsetzung einschließlich Bindung, Commit-/Rollbacknachweis
und unverändert gesperrter ungeklärter Ausgänge. Erst vorhandener externer Windows-/Linux-
Provider; SSIS/Agent/Broker bleiben spätere separat qualifizierte Provider.
Abbruchanforderung, tatsächliches Ende und Konsistenznachweis sind getrennt;
keine generische externe Rollback- oder Exactly-once-Zusage. Unabhängiger
Review, betroffene schema-validierte Lab-Tests, grüne exakte Head-CI, PR-Merge
nach origin/main und eigener Branch-/Worktree-Cleanup bleiben Pflicht.
Vorhandene Referenzen TC-2026-015/046; keine neue sequenzielle ID erfunden.

CI-Ergänzung 2026-10-06: Der begrenzte Linux-Workerhost-/SQL2019-Nachweis
bestand am exakten [PR197-Head](https://github.com/gecompat/SQL_Server_Toolbelt/pull/197)
im [Worker-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37423892477)
mit Managed-Vertrag, echtem Queue2.0→2.1-Upgrade und separaten Windows-/Linux-
Faultverträgen. Der erste [main-Lauf](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37425398209)
scheiterte im zeitabhängigen Controltimeout-Orakel; Cleanup bestand. Genau ein
Retry auf demselben Merge-Commit bestand alle Jobs. Der Erstfehler bleibt
fehlgeschlagen, seine Ursache unbekannt. Andere Host-/Zielkombinationen,
Minimalrechte, echter Committransportverlust und Release bleiben offen.

### Nächste Wellen – bestätigte Anforderungen und Entscheidungsvorbereitung 2026-10-04

Benutzerauftrag nach Merge/Cleanup: nächste Wellen besprechen und konkrete
Vorlagen ausarbeiten. Queue-Worker2 ist erster Schwerpunkt, CSV unabhängiger
zweiter Schwerpunkt; JSON Pointer, Safe Cast und JSON-Schema-Prüfung folgen.
Bestätigte Anforderungen und neue API-/Providerdetails stehen getrennt in der
[Entscheidungsvorlage](../Documentation/Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md).
Vorhandene Referenzen TC-2026-015/046 und RI-2026-109/041/076/048 werden
wiederverwendet. Status dieser Ausarbeitung: `proposed`; keine neue Runtime.

Einzeln bestätigt: externer Queueprovider jetzt, Agent/Broker später; gemeinsame
Steuerung, Registrierung, explizite Recovery, kontrollierter Neustart und bisherige
Handlergrenzen. Die anschließend bestätigte dynamische providerübergreifende
Parallelitätssteuerung ersetzt die vorgeschlagene feste Acht-Slot-Obergrenze:
Erhöhung/Reduktion im Betrieb, Budget0 als Admissionpause, laufende Arbeit
auslaufen lassen, separate Supervisor-Kapazitäten und kleine Lab-Budgets.
Keine privaten Kapazitäts-/Systemwerte in dieser Dokumentation.

Weitere Einzelfreigabe 2026-10-04: ausdrücklich aktivierter verwalteter Betrieb
darf direkte unverwaltete USP_ClaimWork-Aufrufe abweisen. Aktivierung nur bei
nachgewiesen claimfreiem Übergang; zuvor bleibt das bisherige Verhalten erhalten.
Antwort auf die konkrete Vertragsfrage: „ja, freigegeben“. Keine Wiederholung
dieser Freigabefrage; übrige neue API-/Recoverydetails bleiben getrennt.

Spätere Erweiterung auf ausdrücklichen Benutzerhinweis: SSIS-Workerpakete als
Provider für T-SQL sowie parametrierte Aufrufe anderer SSIS-Pakete berücksichtigen.
SSIS als Provider und SSIS-Pakete als Auftragstypen sind getrennte Folgegrenzen.
Ausdrücklich nicht Teil der aktuellen Welle; keine Paket-/Installationsfreigabe
und keine Übertragung der atomaren SQL-Abschlusszusage auf SSIS-Seiteneffekte.

CSV-Grundvorschlag wurde angenommen; die NULL-Nachfrage widerrief das nicht.
Optionales NULL-Token zusätzlich bestätigt: unquoted exakt ist SQL-NULL,
quoted Token ist Text; leeres Feld/quoted leer bleibt leerer Text. Ohne Token
weist der Writer SQL-NULL zurück. JSON Pointer read-only, sechs Safe-Cast-
Zieltypen/ISO-Datumsrichtung sowie explizite JSON-Schema-Prüfung ohne Netzwerk-
Referenzen oder Datenänderung wurden als Richtungen angenommen.

Neue konkrete APIs, zusätzliche Grenzen, genaue Recoverybeweise und CLR-/
Providerwahl benötigen die anschließende funktionsbezogene Freigabe. Bestehende
Zustimmungen bleiben erhalten; keine erneute pauschale Grundsatzabfrage.
Vorbereitungs-PR ist keine fachliche Source-/Providerfreigabe und aktiviert
keinen automatischen Dienst, Agentjob, Broker oder Heartbeat.

Fortsetzung 2026-10-05: Der Benutzer beauftragte ausdrücklich weitere autonome
Entwicklung und Analyse bis zu seinem Stopp oder bis ohne Input keine sinnvolle
autorisierte Arbeit möglich ist. Unabhängige Vorbereitung wird deshalb auch bei
einem noch offenen Sourcegate fortgesetzt. Die datierte technische Vorprüfung
in der obigen Entscheidungsvorlage ergänzt CSV-Transport/Atomik, Pointer-
Enginegrenzen, Safe-Cast-Lexik und den begrenzten Schema-Evaluationskern.

Fortschreibung nach CSV-Merge: Die Entscheidungsvorlage enthält konkrete
bevorzugte Pointer-Status-/Unicode-/Tiefenregeln, Safe-Cast-Fehlerpriorität und
exakte Decimal-Betragsgrenze sowie Schema-Referenz-/Unicode-/Arbeitsbudgets.
Sechs neue lesende Decimal-Engineproben bestanden auf Linux2019/latest CL150;
das ist kein Safe-Cast-Runtime-Nachweis. Reuse-Prüfung identifizierte den
vorhandenen Constructor1.2-Scanner und konkrete Policy-/Index-/Budgetlücken.
Providergrenze und funktionsbezogene Freigaben bleiben sichtbar getrennt;
keine neue SQL-Funktion oder Assembly durch diese Researchpflege.
Elf synthetische rein lesende Engine-Assertions bestanden auf dem schema-valide
ausgewählten SQL2019 Linux/latest CL150; kein öffentlicher API-Nachweis und keine
Labmutation. Bestehende konkrete Zustimmungen bleiben erhalten; neue Vorschläge
werden weder als Implementierungsfreigabe noch als Runtime-Capability dargestellt.

Weitere Designprüfung 2026-10-05 für `RI-2026-041/048`: Die
[Entscheidungsvorlage](../Documentation/Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md)
konkretisiert einen nativen Pointer-MSTVF-Pfad mit ISJSON als Grammatikautorität,
separatem Unicode-/Tiefenpolicywalker und vorgelagerten gültigen OPENJSON-
Operanden. Fragmentkopien bleiben ein begrenzter, unqualifizierter Kostenfaktor.
Für Schema sind exakte Mantissen-/Exponentziffernvergleiche ohne BigInteger-
Dependency und die unabhängigen Input-/Arbeitsceiling-Folgen ausgearbeitet:
16MiB Input garantieren keinen Abschluss unter einer Million Defaultschritten;
unvollständige Arbeit liefert LIMIT/IsValidNULL. Keine Defaultänderung,
Keyworderweiterung oder neue Source-/Providerfreigabe. Die Designprüfung enthält
keine Kernlaufzeitprüfung. Anschließend bestanden sechs neue synthetische lesende
Pointer-Engineproben mit eigenem120s-Watchdog, Exit0, vollständigen Kanälen und
leerem Stderr auf schema-validiertem Linux2019/latest CL150: NUL-Key-Identität,
zwei mixed-Surrogate-Fälle, zwei byteexakte Zahlenliterale und direkter Depth128-
Container. Keine Labmutation; ältere17 Proben nicht wiederholt. Kein öffentlicher
API-, Policywalker-, Maximalworkload- oder Gesamtproduktnachweis.
Safe Cast ist inzwischen separat
in PR171 umgesetzt; ältere Vorschlagsaussagen bleiben als Historie erhalten.

Fortsetzung 2026-10-05 nach Pointer-Merge: PR174 wurde nach vier erfolgreichen
Checks am exakten Head122910d gemergt; main/origin/main und eigener
Branchcleanup wurden verifiziert. Die Schema-Recherche konkretisiert jetzt
in der [Entscheidungsvorlage](../Documentation/Research/NEXT_DEVELOPMENT_WAVES_2026-10-04.md)
die physische Kerngrenze:
Constructor1.2 weist jede referenzierende Assembly mit53626 ab;
Source-Linking ist keine ausdrücklich genehmigte Ausnahme von einem
kanonischen Kern. Bevorzugter Besprechungsvorschlag ist eine eigene technische
Coreassembly mit separat qualifizierter Constructor1.3-Migration und darauf
aufbauender Schema-USP. Namen/Versionen und interne Bridge sind Vorschläge,
keine Registrierung oder neue Freigabe. Vergleichbare T-SQL- und integrierte
Constructor-Alternativen bleiben dokumentiert. Neue Binary-/Trust-/Owner-/
Dependency- und Abnahmegrenzen sind ausdrücklich getrennt; keine Runtime-
Implementierung oder neue SQL-/CLR-Prüfung durch diese Researchpflege.
Fehler-/Diagnosepriorität, MaxErrors0/Limitverhalten, abstrakte globale
Arbeitsabrechnung und eine synthetische Abnahmematrix sind konkret vorgeschlagen.
Keine neue Assertion als ausgeführter Nachweis dargestellt.


### JSON Schema / gemeinsamer Kern – ausdrücklich freigegeben2026-10-05

Nach konkreter Besprechung in PR175 antwortete der Benutzer:

> Diese Schema-/Kern-Welle freigegeben

Genau USP_ValidateJsonSchema im begrenzten Profil toolbelt-2020-12-v1,
zehn Ergebnisfelder, exakte Zahlen/Unicode, lokale nichtrekursive Referenzen,
globales Arbeitsbudget und vollständiges Urteil trotz gekürzter Diagnosen;
dazu gemeinsamer SAFE-JSON-Core und semantikerhaltende Constructor1.2→1.3-
Migration. Parameter, Fehlerpriorität, interne Bridge, Dependency-Lifecycle
und Abnahmematrix der besprochenen Vorlage sind eingeschlossen. Der
[kanonische Vor-Source-Vertrag](../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md)
hält die tatsächliche Einzelzustimmung und den Umfang fest.
Status: implemented, partially validated, unreleased. Gemeinsamer Source-
Frameworklauf, eigene vollständige IL, acht verbotene Negativfixtures, drei
kanonische bytegleiche Projektbuilds und sieben Paketierungsfälle bestanden.
Core-/Schema-Scope und genuine bekannte Constructor1.2→1.3 bestanden auf
Linux2019/latest CL150 und Windows2025/CU8 CL170 jeweils local/central,
einschließlich26 Schemafällen, Client/Safety, vier Constructor-Fixtures
mit16 MiB/100000 Einträgen, post-DROP-Rollback und zusätzlichen Annotationen.
Die Migration erhält fünf Procedureidentitäten/Rechte, ersetzt drei eigene
CLR-Slots/Assembly atomar und weist verlustgefährdete direkte Rechte/Owner/
Zusatzmetadaten vorher ab. Der verworfene ALTER-Versuch6282 bleibt fehlgeschlagen.
Frische hashgebundene Dispositionaudits beider aktueller Core-/Schema- und
Migrationsscopes bestanden; keine Konfigurations-/Rechte-/Owneränderung.
[Begrenzte native Evidenz](../Modules/toolbelt.json.schema/Tests/NATIVE_EVIDENCE.md).
Weitere Ziel-/Lifecyclematrix, CrossDB, Minimalrechte und aktuelle Head-CI offen.

CI-Statuskorrektur 2026-10-06: Die obige Head-CI-Aussage beschreibt den
früheren Stand. [PR176](https://github.com/gecompat/SQL_Server_Toolbelt/pull/176)
bestand am exakten Head `6dd4ef65ecac8d98d4d5c964a649d63c0d8692dc`
die [gekoppelte JSON-Constructors-Runtime-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37351670226).
Der spätere [PR179](https://github.com/gecompat/SQL_Server_Toolbelt/pull/179)
bestand am exakten Head `194c5ade272d38e2b2d6786694b74f7bbe082112`
[Documentation Consistency](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37386445044)
und die [JSON-Constructors-Runtime-CI](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37386445377)
mit Known-Artifact-/Offline- und Linux-SQL2019/2022/2025-Jobs; der
[Runtime-Push-Lauf auf main](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37389210961)
bestand ebenfalls. Der CI-Adapter prüft Schema Contract/Safety lokal und
Core-/Constructor-Lifecycle in seinem begrenzten Scope. Die vollständige
physische Ziel-/Lifecyclematrix, CrossDB, tatsächliche Minimalrechte und
Releasequalifikation bleiben offen; `partially validated`, `unreleased`.

Neue Binaries werden separat qualifiziert; die anschließende ausdrückliche
Trustfreigabe autorisiert notwendige begrenzte Tests der laufenden Welle ohne
erneute Schemahashfragen. Keine erneute allgemeine Funktions-/Migrationsfreigabefrage;
keine Release-, Rechtegrant-, Infrastruktur- oder Produktionsfreigabe.
Historische Constructor1.2-Artefakte und Nachweise bleiben getrennt erhalten.

Wartungsfortschritt2026-10-06, Codex: Schema1.0.1 korrigiert den bestehenden
Vertrag für die Reihenfolge codierter Schema-/Refgraphorte. Früh erkannte
Schemaformen werden beim geordneten Ortbesuch geprüft; Graphkanten folgen
budgetiert codierten Zielpfaden. Decodierte Instanzmember, numerische
Instanzarrays, Profil, Signatur und zehn Ergebnisfelder bleiben gleich.
Kein neuer öffentlicher Funktionsscope. Ein expliziter Maintenancepfad für
bekannte1.0.0→1.0.1-Stände und der Uninstall beider bekannten Releases sind
implementiert. Historische Closure und Core-/Constructorframes bleiben
unverändert erhalten; ihre Gesamtqualifikation wird nicht neu behauptet.

Der begrenzte aktuelle Schema-Driver bestand15 Prozessphasen mit stabilen
Pins:169 Profilfälle/1275 Assertions,854 Zahlenfälle/6830 Assertions und120
Bridge-Assertions jeweils en-US/de-DE/tr-TR, eigene IL und bytegleicher
kanonischer Schema-Projektbuild. Sechs Patch- und sieben Releasepaketierungs-
orakel, ScriptDom14 Batches/42 Assertions, PowerShell-/Bashsyntax und18
synthetische CI-Cleanupfälle sowie33 Selector-/Bindungsfälle ohne Labzugriff
bestanden. Der historische Builder erzeugte die
echte1.0.0-DLL aus50 unveränderten Gitblobs des festen Vorgängercommits in53
erfolgreichen Prozessphasen; falscher Core und belegtes Ausgabeziel wurden
abgewiesen. [Aktuelle Offline-Evidenz](../Modules/toolbelt.json.schema/Tests/Framework/README.md)
und [getrennte Testmatrix](../Modules/toolbelt.json.schema/Tests/TEST_MATRIX.md).

Fortschreibung2026-10-06, Codex: Die vorstehenden erfolgreichen
`qual3`/`package3` mit sechs Patchorakeln belegen ihren früheren Scriptstand.
Nach Common-Härtung bestanden `qual4`/`package4` erneut15 Phasen und die
gleichen Harnesszahlen, jetzt acht Packagingfälle. Common bindet einen
einzigen strict-UTF8-Byteinput an den festen historischen Snapshot-SHA256;
gültig neu gerahmte Constructorframes werden in Generator und Driver mit
`SCHEMA_PATCH_BASELINE_PIN` vor Ausgabe abgewiesen. Der finale Kandidat
entspricht semantisch exakt der aktiven Registry und ihren Binaryhashes.

Der erste [native CI-Versuch](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37525258700)
am Head `58993f7012a0b458db377d7d4374b7bf162f0432` scheiterte auf SQL2019/2022
mit Msg515 in UpgradeCapture Permissions: leerer FOR-XML-Katalog als NULL.
Capture und Verify normalisieren dies nun symmetrisch auf `0x`;
unabhängiger Review und ScriptDom14 Batches/42 Assertions bestanden.
SQL2025 lief bei Erfassung noch; der Fehlversuch bleibt Historie.
Native1.0.1-API, echter SQL-Upgrade, exakte korrigierte Head-CI und die
ergänzte Windows-CI-Qualifikation bleiben PENDING.
Die vorhandenen nativen1.0.0-Nachweise bleiben historische
Wahrheit. Weitere physische Ziele, Minimalrechte und Ressourcenqualifikation
bleiben offen; keine lokale Docker-/SQL-Maximallastprobe. Status weiterhin
implemented, partially validated, unreleased. Die Registryfelder zu Trust
und nativer Qualifikation bleiben unveränderliche Offline-Freeze-Metadaten,
getrennt von der bestehenden Testautorität und aktueller Evidenz.

Native Fortschreibung2026-10-06, Codex: [Runtime37532174433](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37532174433)
und Docs37532174428 am exakten Head83164b539e637deeb1ad21b74a15cad99e0184c1
PASS. Schema Linux SQL2019/CL150,2022/CL160,2025/CL170 je local/central:
genuine1.0.0→1.0.1, Mode-Abweisung, post-ALTER55699-Rollback,
Uninstall alt/Reinstall/Upgrade/Repeat,40 Contractfälle je Modus, Safety,
CrossDB und Cleanup; je acht Upgrade-/zwei Safety-Witnesses ohne
UnexpectedSQL/CleanupUnverified. SQLCMD-Dateifaulttransport besteht im
tatsächlichen Testpfad, keine exakte Actual168-Ursachenbehauptung.
Historische failed/PENDING-Records bleiben erhalten. Jeder spätere Head
benötigt vor Integration eigene erfolgreiche Checks; übrige physische-/Minimalrechte-/Lifecycle-/
Kapazitätsmatrix und Release offen, weiterhin partially validated/unreleased.

### TC-2026-039 / TC-2026-040 / TC-2026-042: Deterministic-Familie implementiert

Stand 2026-10-02: Die am 2026-10-01 einzeln freigegebenen
`TVF_DeterministicRange`, `TVF_DeterministicDateShift` und
`USP_DeterministicLookup` sind als `toolbelt.pseudonymization.deterministic`
1.0.0 implementiert. Ein versionierter SHA256-/Byteframing-Kern mit höchstens
128 Rejection-Kandidaten; volle bigint-Grenzen, strikter Date-Overflow,
caller-lokaler versionierter Pool und atomare Standard-ResultTable-Ausgabe.
Identischer finaler Safetyfix-Adapter auf 2019 Linux/latest CL150 und
2025 Windows/CU8 CL150/160/170 erfolgreich: Fach-/Grenz-/Fehlerverträge,
Local/Central, direkte Minimalrechte, Clientmetadaten, alle vier privaten
Tempnamen/Help, nichtdoomende Installer-Callertransaction-Guards ON/OFF,
SQLCMD-nonzero, Wiederholung/Drift/Kollision/Dependency/Uninstall.
Weitere Zielkombinationen, CrossDB-Minimalrechte, reale SQL-Exhaustion und
Produktionskapazität bleiben offen; `partially validated`, `unreleased`.
Historische Vor-Safetyfix-Nachweise vom 2026-10-01 bleiben getrennt erhalten.
Die ursprüngliche Reservebesprechung unten bleibt unverändert; keine
Translate-/Geo-/Fuzzy- oder andere Folgefreigabe aus diesem Abschluss ableiten.

### TC-2026-045: Freigegebener XLSX-Raw-Reader abgeschlossen

Stand 2026-10-02: Die bedingt einzeln freigegebenen `USP_ListXlsxWorksheets` und `USP_ReadXlsxWorksheetCells` sind als `toolbelt.file.xlsx-memory` 1.0.0 implementiert. Vor den öffentlichen Bindings wurden begrenzte Framework-NoIO-/IL-Gates und tatsächliche SAFE-Aufrufe erfolgreich qualifiziert. Der begrenzte eigene XML-Kern verwendet die kanonische technische ZIP-Fassade aus Release 1.4.0 ohne Parserkopie, SDK, Datei-/Netzwerkzugriff oder Rechteausweitung.

Finale identische Adapter auf Linux 2019/latest und Windows 2025/CU8 erfolgreich: local/central/cross-database, sparse Raw/Text/Formula/Cache, NULL- und Help-Metadaten, 128-MiB-Outputcharge, atomare ResultTable-Fehler, Caller-Transaktionen, nichtdoomender XLSX-/ZIP-Lifecycle und echte ZIP-1.3→1.4-Upgradefixture. Framework und unabhängige ZIP-Writer-Regression erfolgreich. Weitere reale große Ceiling-Fixtures, minimale Rechte, sämtliche Zielkombinationen und Produktionskapazität bleiben gemäß [Testmatrix](../Modules/toolbelt.file.xlsx-memory/Tests/XLSX_CONTRACT_TEST_MATRIX.md) offen; `partially validated`, `unreleased`.

Die bereits separat freigegebenen Typ-/Anzeige-Folgefunktionen bleiben `ready for development` für den Nachfolger; sie sind nicht Teil dieses Raw-Reader-Stands. Keine Veröffentlichung und keine neue Welle in dieser Abschlussphase.

### TC-2026-044: Script-only Tabellenklon V1 abgeschlossen

Stand 2026-10-01: Die einzeln freigegebene `USP_ScriptTableClone` ist als
`toolbelt.metadata.table-clone` 1.0.0 implementiert. Begrenzter SameDB-Scope:
Spalten, Defaults, Checks, PK/UQ, gewöhnliche Rowstore-Indizes und optionale
Identity-Eigenschaft; keine API-DDL-Ausführung oder Datenkopie.
Unsupported-Features werden atomar abgewiesen. Datenbankweite VIEW DEFINITION
ist für vollständige incoming-FK-/Kollisionssicht erforderlich; Lifecycle
lehnt aktive Caller-Transaktionen vor SET-/Temp-DDL nichtdoomend ab.
Vollständige finale Adapter auf 2019 Linux/latest CL150 und 2025 Windows/CU8
CL150/160/170 erfolgreich, einschließlich Runtime/ResultTable/Transaktionen,
Clientmetadaten, Rechte/hidden incoming FK, local/central, Typdrift,
Marker/Sourcehash, Kollisionen und Uninstall. Weitere Zielkombinationen,
GitHub-Runtime und niedrigprivilegiertes CrossDB waren zum Abschluss der
lokalen Qualifikation 2026-10-01 nicht ausgeführt; PR-CI ist ein separater
Nachweis und keine Aufwertung dieser lokalen Evidenz.
Status `partially validated`, `unreleased`; keine Ausbauwelle1/2 oder
Trigger-/Ausführungs-/Datenkopieimplementierung in diesem V1-Stand.

### Priorisierte Besprechung: Queue-Verarbeitung und Worker-Orchestrierung

Benutzerauftrag 2026-10-01: Queue-Verarbeitung steht weit oben in der
Wunschliste; als priorisiertes Thema aufnehmen und erforderliche Entscheidungen
jetzt besprechen. Konkretisiert den offenen Worker-Scope von TC-2026-015 und
die getrennten Provider von TC-2026-046; keine neue sequenzielle ID vergeben.

- Vorhandenen validierten Work-Queue-2.0-Kern mit Work-Type-Katalog, Leases,
  Retry/Dead Letter, Idempotency Keys und Drain-Barriers wiederverwenden.
  Keine zweite Queue oder kopierte Claim-/Retrylogik.
- Besprechungsziel: tatsächlich ausführender Worker mit begrenzter
  Parallelität, unabhängigem Lease-Heartbeat während langer Handler,
  kontrolliertem Shutdown, expliziter Recovery und nachvollziehbaren
  Fehler-/Retryentscheidungen. Keine Exactly-once-Zusage.
- Providerwahl, Betriebs-/Installationsgrenze, Handlertransaktionen,
  Ergebnis-/Statusvertrag, Limits und Abbruchverhalten vor Implementierung
  einzeln vereinbaren. SQL Server Agent, Service Broker und externer Worker
  sind Alternativen, nicht automatisch gemeinsam freigegebene Provider.
- Keine beliebige SQL-/Hostscript-Ausführung, Credentials im Repository,
  automatische Rechtevergabe, KILL oder produktive Dienst-/Jobinstallation.

#### Bestätigter Worker-Vertrag und Abschlussauftrag

Einzelfreigabe 2026-10-01: Der Benutzer bestätigte ausdrücklich die vier
besprochenen Queue-Punkte. Erster Provider: externer, manuell startbarer
Windows-/Linux-Worker mit getrennten Handler-/Steuerverbindungen; nur
registrierte NONE-/JSON_PAYLOAD-Handler, kein Raw SQL. SQL Server Agent und
Service Broker bleiben separat auszuarbeitende Folgeprovider, nicht bereits
freigegebene Implementierungen.

- Ein Supervisor, Default ein Slot, konfigurierbar bis acht; keine implizite
  Vervielfachung durch unabhängige Supervisoren. Lease zunächst 300 Sekunden,
  Heartbeat alle 60 Sekunden; Lauf nach Zeit/Auftragszahl oder bis Queue leer
  begrenzen. Kein automatischer Dienst-/Jobinstallationsauftrag.
- Retry nur für ausdrücklich klassifizierte transiente Fehler und dafür
  fachlich geeignete freigegebene Handler. Validierungs-/Rechte-/Unsupported-
  Fehler terminal. Unbekannter Commit-Ausgang sichtbar ungeklärt, niemals
  blind wiederholen. Recovery zuerst explizit, keine Exactly-once-Zusage.
- Geschützte WorkItem-/ClaimGeneration-/ExecutionId-Zuordnung, kooperative
  Handler-Checkpoints, kein KILL. Shutdown stoppt neue Claims, heartbeated
  laufende Arbeit bis zum kontrollierten Ende; nach Gracefrist noch aktiv/
  ungeklärt statt erfundenem Abbruch. Bestätigte Cancellation zunächst FAILED
  mit eindeutigem Fehlercode; keine zusätzliche Queuezustandsmaschine.
- Zunächst Status/Counts/Fehlercodes, keine beliebigen persistierten
  Handlerresultsets. Konkrete Worker-/SQL-Schnittstellen, kurze Control-
  Timeouts, Budgets, Authentifizierung und Testorakel innerhalb dieses Scopes
  vor Source schriftlich konkretisieren; neue fachliche Grenzen rückfragen.
- Dauerbetrieb, persistente Workerregistrierung, supervisorübergreifende
  Slotgrenze und kontrollierter Neustart als zweite Welle vorgesehen.
  Deren konkrete APIs und Dienst-/Jobinstallation separat konkretisieren;
  keine automatische Betriebsfreigabe aus dieser Reihenfolge ableiten.

Status erste Worker-Welle: `ready for development`, hohe Benutzerpriorität;
keine Runtime-Evidenz. Späterer Benutzerauftrag derselben Besprechung:
dieser Orchestrator finalisiert ausschließlich bereits laufende XLSX-Raw-,
Clone-V1- und Deterministic-Range/DateShift/Lookup-Wellen samt Reviews,
erforderlichen Fixes, Tests, PR-Merges und Branchcleanup. Keine neue
Entwicklungswelle hier starten. Danach sauberen Übergabestand in origin/main
herstellen und neuen Orchestrator-Chat mit unveränderten Projektregeln und
individuellen Freigaben zur autonomen Fortsetzung öffnen. Queue-Implementierung
und andere noch nicht gestartete Wellen gehen an diesen Nachfolger.

Nachfolgerstand 2026-10-02: Erste externe Worker-Welle implementiert;
finale PR-Qualifikation `active` im isolierten Branch.
Der [konkrete Providervertrag](../Documentation/Architecture/EXTERNAL_QUEUE_WORKER_CONTRACT.md)
legt vor Source die bestehenden SQL-Schnittstellen, private Authentifizierung,
endliche Laufbudgets, Handlerzulassung, claimgebundene Checkpoints,
atomaren Complete-/Handlercommit und Testorakel fest. Keine neue öffentliche
SQL-API; unabhängiger Review und deterministische Fault-Orakel erfolgreich.
Windows-Workerhost auf SQL Server 2019 Linux/latest und 2025 Windows/CU8
qualifiziert, einschließlich echtem Heartbeat während langem Handler,
Retry/Dead Letter, kooperativer Cancellation, Contextdrift, Slots und Drain.
SQL-Readonly-Fehler 15664 zusätzlich auf beiden Zielen geprüft; finale
vollständige Scheduling-Wiederholung auf Windows 2025/CU8 erfolgreich.
Linux-Workerhost-PR-CI gegen eine eigene synthetische SQL-2019-Instanz
einschließlich langem Heartbeat und Cleanup erfolgreich; deterministische
Fault-Verträge auf Windows und Linux erfolgreich.
Runtime `partially validated`, `unreleased`; offene Grenzen stehen in der
[Worker-Testmatrix](../Workers/ExternalQueue/Tests/README.md).
Die vorangehende Abschlussgrenze beschreibt den Vorgänger und verhindert
keine bereits einzeln freigegebene Nachfolgerwelle.

### Individuell freigegebene weitere Wellen und Parser-Voraussetzung

Benutzerfreigabe 2026-10-01: Nach gemeinsamer Besprechung der folgenden
fünf konkreten Themen bestätigte der Benutzer jede zugehörige Entscheidung
einzeln mit „ja“. Die zusätzlich vorgeschlagene Parser-Härtung und
systematische Syntaxqualifikation vor Trigger-Rewriting bestätigte er mit
„ok, das machen wir so“. Keine pauschale Freigabe weiterer Objekte.

#### Parser-Härtung und Syntaxqualifikation

- Bestehenden ScriptDom-Parser härten und eine versionierte Testmatrix für
  DML, DDL, Prozeduren/Funktionen/Trigger, Transaktionen, Security-Statements
  und versionsabhängige Syntax aufbauen. Vor Trigger-Rewriting abschließen.
- Festgestellte Schwachstellen gezielt adressieren: stiller Versionsfallback,
  unbegrenzter NULL-Eingabebyteparameter, Tiefenprüfung erst nach Parser.Parse,
  partielle ASTs bei Syntaxfehlern und widersprüchliche Dokumentationsdefaults.
- Konkreten begrenzten Parameter-/Fehler-/Kompatibilitätsvertrag und
  wirksamen vorgeschalteten Ressourcenwächter vor Sourceänderung dokumentieren
  und qualifizieren. Keine vollständige Syntaxabdeckung nur aus Smoke-Tests
  oder AST-Vorhandensein ableiten.
- Parsen ist keine semantische Namens-/Aliasauflösung und keine sichere
  Umschreibungsfreigabe. Der bestehende UNSAFE-/Windows-only-Vertrag bleibt
  sichtbar; kein Linux-/Worker-/SDKfallback oder Trust-/Rechteausweitung.

Nachfolgerstand 2026-10-02: Die einzeln freigegebene Parser-Härtung ist
`active` im isolierten Branch. Vor Source wird der begrenzte gemeinsame
Vertrag der vier vorhandenen TVFs als Major-Folgeversion konkretisiert:
[begrenzter Hardening-Vertrag](../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md).
Der vorgeschaltete Ressourcenwächter wird zuerst in isolierten
Framework-Prozessen auf dem exakt vorhandenen ScriptDom-Binarystand
qualifiziert. Neue Grenzen und fehlende Nachweise bleiben ausdrücklich
sichtbar; Trigger-Rewriting gehört weiterhin zur getrennten Folgewelle.
Der eingefrorene Wächterkandidat bestand 82 isolierte Framework-Fälle;
der integrierte Provider anschließend 245 begrenzte Kindprozesse,
unabhängig wiederholt. Windows 2025/CU8 CL150/160/170 bestand lokale/zentrale
Nutzung, echten 1.0-Upgrade, Wiederholung, Grenzen/Syntax, Caller-TX/SET-Erhalt,
Kollisionsschutz und eigenes DB-/Trust-Cleanup. Windows 2019 bleibt vor
Mutation konfigurationsbedingt blockiert; eine fachfremde Pending-Konfiguration
wird nicht blind mitaktiviert. Windows 2022, minimale Rechte und tatsächliche
Ausgabeceilings bleiben offen; Helperquoten ersetzen diese Nachweise nicht.
Status der 2.0-Welle: `partially validated`, `unreleased`.

#### Trigger-Scriptklon

Zusatzfreigabe 2026-10-04: Der Benutzer bestätigte ausdrücklich
`IncludeTriggers bit=0` an Position 9 mit Standardtail an Position 10..13
und Folgeversion 4.0.0. Triggernamen erhalten `TR_` plus den vollständigen
SHA256 über genau die drei längengerahmten UTF16LE-Komponenten Zielschema,
Zieltabelle und Originaltriggernamen, ohne zusätzlichen Marker im Hashinput.
`TR_` ist ausschließlich das Namenspräfix dieses Slices, keine globale
Triggernamenskonvention.
Die zuvor freigegebenen Parser-, Script-only- und Ablehnungsgrenzen bleiben
unverändert. Dies dokumentiert die Freigabe, keine Implementierung oder
Runtimequalifikation.

Vor-Source-Stand 2026-10-04, Codex: Der konkrete
[4.0-Triggervertrag](../Documentation/Architecture/TABLE_CLONE_TRIGGER_CONTRACT.md)
legt die notwendige feste SET-/DDL-Kapselung, quellengetreue FIRST/LAST-
Anordnung und getrennte triggerfreie Executorgrenze fest. Der unveränderte
Hash-v1 bindet im neuen Modulstand 4.0.0 statt 3.1.0; Parameter und Framing
des Executors bleiben gleich. Source und zwei begrenzte Runtime-Fixtures
sind jetzt vorhanden; unabhängige Coreprüfung, statische Kopplung und offline
Syntaxprüfung bestanden. Am2026-10-04 bestand der begrenzte private Nativeadapter
auf Windows2025/exakt CU8 CL170 lokal: beide Trigger-Fixtures einmal Clean4,
Clean4/genuine3.1→4 mit frischer Upgradesession, Repeat, unabhängiger Clienthash,
typgenaue Ausgabe, vier resolved-Consumer-Ablehnungen sowie Uninstall/Repeat.
Zwei eigene DBs entfernt, temporärer exakter Parsertrust wiederhergestellt;
Prozess-/Journal-/Pin- und frischer Cleanupnachweis unabhängig physisch geprüft.
Keine Konfigurations-, Rechte- oder Owneränderung. Separater Linux2019/latest
CL150-Option0-/Lifecycle-PASS wiederverwendet, nachfolgende Coreänderungen
ausschließlich Option1 unabhängig geprüft. Weitere native Ziele/CL, zentrale4.0,
Minimalrechte und unsichtbare/mehrdeutige Kontexte offen; unresolved Consumer
nicht etabliert. Head-CI separat im PR; teilweise validiert, unveröffentlicht.
Historische Fehlerläufe sind kein Gesamt-PASS.

- Bestehenden Scriptplaner optional für gewöhnliche T-SQL-DML-Trigger auf
  gemappten diskbasierten Tabellen erweitern; weiterhin nur Scripttext.
  Ereignisse, AFTER/INSTEAD OF und enabled/disabled-Zustand erhalten.
- Name, Zielbindung und eindeutig auflösbare Tabellenverweise anhand des
  expliziten Klon-Mappings umschreiben. Bestehenden Parser wiederverwenden;
  Kommentare/Stringliterale unverändert, keine blinde Textersetzung.
- Dynamisches SQL, verschlüsselte/CLR-Trigger, EXECUTE AS, mehrdeutige oder
  externe Referenzen sichtbar ablehnen. Keine automatische Kopie referenzierter
  Funktionen/Prozeduren. Parserfehler müssen vor Umschreibung ausgeschlossen sein.
- Plattformgrenze des Parsers vererben, keine vorgetäuschte Linux-Fähigkeit.

#### USP_ExecuteTableClone

Zusatzfreigabe 2026-10-04: Der Benutzer bestätigte ausdrücklich vorhandenes
Server-`VIEW ANY DEFINITION` und lesbare DB-/Server-DDL-Trigger- sowie
Eventnotification-Kataloge als Pflichtgate. Fehlende oder unklare Sicht und
relevante aktive DDL-Trigger/Eventnotifications blockieren vor eigener DDL;
keine Rechtevergabe oder Deaktivierung. Der konkrete additive 3.1-Vertrag,
das versionierte Hashlayout und die technische FK-Aufschuboption stehen in
[TABLE_CLONE_EXECUTE_CONTRACT](../Documentation/Architecture/TABLE_CLONE_EXECUTE_CONTRACT.md).
Implementierung und unabhängige Sourceprüfung sind abgeschlossen. Am
2026-10-04 bestanden die gezielten lokalen 3.1-Nachweise auf SQL Server
2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170: beide neuen
Fixtures, unabhängiger Client-Hash und Resultmetadata, genuine3→3.1,
Lifecycle und eigene Bereinigung. Head-CI wird separat im Pull Request nachgewiesen;
historische Planner-Nachweise bleiben getrennt. Serverweite negative
Trigger-/Eventnotification-Fixtures und tatsächliche Minimalrechte wurden
nicht ausgeführt; der Modulstatus bleibt teilweise validiert.

- Explizites Tabellen-Mapping/Planneroptionen und erwarteter Plan-Hash;
  kein frei übergebener SQL-Text. Kanonischen Plan unmittelbar neu erzeugen
  und vergleichen. Nur neue Ziele, kein DROP/Overwrite/Ändern vorhandener Ziele.
- Eigene begrenzte Transaktion, fremde aktive Caller-Transaktion ablehnen;
  Fehler rollen eigene SQL-Änderungen zurück. Keine Rechteausweitung.
- DDL-Trigger/nicht kontrollierbare externe Nebenwirkungen sind Scopeblocker.
  Toolbelt-Lock ist keine Driftgarantie gegen fremde DDL. Hash ist keine
  Berechtigungsfreigabe; aktuelle Quell-/Ziel-/Callerrechte weiter prüfen.

#### USP_CopyTableCloneData

Umsetzungsstand 2026-10-04, Codex: Der bereits einzeln freigegebene Copy-Scope
wird als Release4.1.0 konkret umgesetzt; [kanonischer Vertrag](../Documentation/Architecture/TABLE_CLONE_DATA_COPY_CONTRACT.md).
Neun öffentliche Parameter, fünf NOT-NULL-Ergebnisfelder; Map64,100000 globale
Zeilen und16MiB transportierte SQL-Nutzdaten, Caller nur absenkbar. Der bestehende
interne Core erhält ausschließlich einen PREVIEW/COPY_FK-Zweckparameter, keine
weitere öffentliche API. Vier Lifecycle-Slots13/14/14/9; die öffentliche
Planner13- und Executor14-Signatur bleiben erhalten. Vorhandene DB-/DML-Sicht
gilt immer; genehmigte Server-DDL-Vollsicht nur bei tatsächlich fehlenden FKs.
Gemeinsame FK-Herleitung, exakte Form-/RLS-/Seiteneffektgates, Identity- und
Rollbackgrenzen stehen im Vertrag. Keine automatische Konfiguration oder
Rechteerteilung. Besprochene Punkte vom Benutzer abschließend mit „alles
freigegeben“ bestätigt; Source, Runtime, unabhängige Prüfung und aktuelle
Head-CI bleiben eigene Nachweise. Normale fünf Copygruppen, Client und
Clean/genuine4.0→4.1-Lifecycle bestanden auf Linux2019 CL150 und Windows2025
exaktCU8 CL170; eigene Bereinigung unabhängig geprüft. Vier dynamische Identity-
Zustände und zwei gezielte SNAPSHOT-Konkurrenzfälle separat auf Linux2019
bestanden. Abgeschlossene Teilnachweise aus insgesamt fehlgeschlagenen
Adapterläufen werden bei unveränderten Produktbytes ausdrücklich getrennt
wiederverwendet; keine Wiederholung erfolgreicher Fälle. Head-CI gesondert
im PR, weiterhin teilweise validiert und unveröffentlicht. Historische4.0-
Zeugen werden nicht zur Copyqualifikation umgedeutet.

Zusatzfreigabe 2026-10-04: Der Benutzer bestätigte ausdrücklich maximal
100000 Zeilen und 16 MiB Nutzdaten, durch Caller absenkbar, sowie die
Rollbackgrenze bei Identity-Zählerfortschritt ohne automatisches RESEED.
Kontrolliert nach Copy neu angelegte FKs übernehmen die bekannten
Quellzustände checked/trusted, enabled/untrusted oder disabled/untrusted;
bestehende Constraints werden nicht heimlich deaktiviert. Das eigene
Servervollsicht-/DDL-Seiteneffektgate für diese nachgelagerte Anlage wurde
ebenfalls ausdrücklich bestätigt, ohne Rechtevergabe. Dies dokumentiert die
zusätzliche Entscheidung innerhalb der Einzelfreigabe; genaue Signatur,
Implementierung und Qualifikation bleiben getrennte Folgeschritte.

- Explizites SameDB-Mapping, nur leere kompatible Ziele. Keine freien SQL-
  Filter, Merge/Upsert oder Überschreiben. Konsistenter Verbundsnapshot:
  vorhandenes SNAPSHOT oder ausdrücklich gewählter SERIALIZABLE-Sperrmodus;
  keine automatische Datenbankkonfiguration durch die öffentliche Funktion.
- Identity erhalten oder neu vergeben ausdrücklich wählen. Neuvergabe bei
  davon abhängigen Beziehungen ablehnen. Computed/rowversion nicht einfügen.
- Zieltrigger fehlen oder sind disabled. Zyklische FKs nur über kontrollierte
  Anlage nach Datenkopie, keine heimliche Constraint-Deaktivierung.
- Zeilen-/Datenbudgets begrenzen, Fehler rollback eigener Zielwrites;
  Ausgabe nur Counts/Status, keine Rohdatenlogs. Sessionzustand einschließlich
  IDENTITY_INSERT sauber behandeln, fremden Zustand nicht überschreiben.

#### TVF_DeterministicTranslate

- Fortschritt 2026-10-02: [kanonischer Vor-Source-Vertrag](../Documentation/Architecture/DETERMINISTIC_TRANSLATE_CONTRACT.md)
  konkretisiert den freigegebenen Slice additiv im bestehenden Modul als
  1.1.0. Unabhängig wiederholte private Referenzqualifikation: 5.540 Assertions;
  getrennte Read-only-Nativprimitive: 48 Assertions, Linux 2019/latest und
  Windows 2025/CU8. Unabhängiger Semantikreview erfolgreich. SQL-API,
  Lifecycle, Metadaten, Rechte und CI dadurch noch nicht qualifiziert.

- Integrierter Fortschritt 2026-10-02: Source/Lifecycle implementiert;
  statische Referenzsuite mit 1.746 Translateassertions und unabhängige
  Reviews erfolgreich. Vollständiger synthetischer Adapter auf Linux
  2019/latest CL150 local/central und Windows 2025/CU8 CL150/160/170 central
  bestanden: alle sieben Slots, Fehler-/Safety-/LOB-/Collationfälle,
  SQL-/Clientmetadaten, echtes 1.0-Upgrade, Wiederholung, Callertransaktionen,
  Kollisionen/Zukunftsslots, Uninstall und eigener Cleanup. Windows local:
  API-/Safetyfälle im früheren Gesamtfehllauf bestanden; separate korrigierte
  Metadaten-/Lifecycleprüfung erfolgreich. Kein Gesamt-PASS des Fehllaufs.
  Keine Serverkonfiguration/Grants; neue Minimalrechte, weitere physische
  Targets, Kapazität und aktuelle CI offen. `partially validated`,
  `unreleased`; kein Merge- oder Veröffentlichungsnachweis.

- Zweck ausdrücklich bestätigt: formaterhaltende Transformation synthetischer
  Kennungen. Rückführbarkeit und verbleibende Länge-/Muster-/Häufigkeits-
  offenlegung ausdrücklich akzeptiert; keine Anonymisierung/Verschlüsselung.
- MappingVersion/Seed, explizite Alphabete zunächst ASCII-Buchstaben/Ziffern;
  Groß-/Kleinschreibung und ausdrücklich erlaubte Trennzeichen erhalten.
  Unbekannte Zeichen standardmäßig Fehler. Begrenzte Langtextverarbeitung,
  kein Abschneiden. Erste Version nur Vorwärtstransformation, Abbildung
  grundsätzlich rückführbar; keine zusätzliche Decode-API ableiten.

#### TVF_DeterministicGeoJitter

- Fortschritt 2026-10-02: Der [begrenzte Vor-Source-Vertrag](../Documentation/Architecture/DETERMINISTIC_GEO_JITTER_CONTRACT.md)
  konkretisiert die einzeln freigegebene Funktion additiv als Version 1.2.0.
  Unabhängig wiederholte Modellreferenz: 10.685 Assertions. Native Read-only-
  Qualifikation auf Linux 2019/latest und Windows 2025/CU8: je 1.458
  Modellfälle; korrigierte sichere Operandenkette mit 32 Variablen- und neun
  direkten Literalfixtures in jeweils drei Abfrageformen erfolgreich.
  Tatsächliche 128-Byte- und größere Non-Point-UDTs sind geprüft; ein exakt
  129-Byte-UDT wurde nicht beobachtet und wird nicht als PASS gewertet.
  Öffentliche API, Metadaten, Lifecycle und CI sind dadurch noch nicht geprüft.

- Historischer integrierter Zwischenstand 2026-10-02: Lokales echtes 1.0.0-Upgrade auf
  1.2.0 und Katalogmetadaten bestanden; der Geo-API-Aufruf auf Linux 2019
  scheitert mit SQL-Fehler 701. Auch der isolierte Einzelaufruf scheitert,
  einschließlich einer kleinen SafeKey-Entkopplung. Kein Geo-API-PASS und
  kein vollständiger Lifecycle-/CI-Nachweis. Eigene Testdatenbanken sind
  bereinigt; keine Konfigurations- oder Rechteänderungen. Die Ursache ist
  nicht nachgewiesen.

- Finaler Fortschritt 2026-10-02: Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`.

- Historische Zwischenstände vom 2026-10-02: Die ursprüngliche Ausdrucksform und kleinere Zwischenkandidaten scheiterten mit SQL-Fehler 701; ein späterer Lauf endete mit Timeout -2. Diese Läufe bleiben fehlgeschlagen, eine allgemeine Compilerursache ist nicht nachgewiesen. Der historische Vector-Facts-Kandidat bestand auf Linux mit einer vorübergehenden Partitionierung: 72 Gruppen mit je sieben Radiuswerten, zusammen dieselben 504 Orakel, eingebettet in 78 Batches einschließlich Metadaten/Goldens/Defaults, Setup, globalem Coverage-Orakel und Wiederholung. Dieser Zwischenbeleg ersetzt den finalen Nachweis der ursprünglichen fünf Batches nicht.

- Zweck ausdrücklich bestätigt: synthetische Testpunkte, SRID4326.
  Entitätsschlüssel/MappingVersion/Seed bestimmen reproduzierbare Verschiebung.
  Radius ausdrücklich in Metern, Default100m/Ceiling10km bestätigt.
- Dokumentierte flächenorientierte Verteilung, keine bevorzugte Richtung;
  Pole/Datumsgrenze/ungültige Koordinaten behandeln und Grenzen qualifizieren.
  Entfernung nach dokumentierter SQL-geography-Näherungssemantik prüfen.
- Kein Land-/Gebiets-Clipping; Wasser/außerhalb Verwaltungsgrenze akzeptiert.
  Verknüpfbarkeit wiederholter Beobachtungen bleibt möglich; keine
  Anonymisierungszusage, realen Geodaten oder zusätzlichen Spatial-APIs.

Status dieser Wellen: `ready for development`; keine Implementierungs-/
Runtime-Evidenz durch diesen Eintrag. Aktuelle V1-Wellen zuerst abschließen,
danach unabhängige freie Agent-Slots nutzen. Öffentliche Typen, genaue
Budgets, Fehler-/NULLsemantik und Dependencies innerhalb des besprochenen
Scopes vor Source schriftlich konkretisieren und qualifizieren; neue
fachliche Entscheidungen rückfragen. Unabhängiger Review, synthetische
Tests, scopebezogenes Lab, grüne CI, PR-Merge und Branchcleanup unverändert.
Die Freigabe erlaubt API-Implementierung und synthetische Qualifikation,
keine autonome Ausführung/Kopie gegen beliebige reale Benutzerdatenbanken.

### Folgewellen: Capture-Replace, XLSX-Interpretation und unscharfer Textvergleich

Benutzerentscheidungen 2026-10-01: Der Benutzer verlangt sämtliche
Capture-Wiederholungen statt nur der letzten Capture je Gruppe. Die separat
besprochene gruppenbezogene Replace-Erweiterung mit `$1`, `${Name}` und `$$`
wurde ausdrücklich mit „ja“ bestätigt. Bestehendes literal Replacement
bleibt davon getrennt und unverändert.

Für XLSX wurde die Reihenfolge bestätigt: Typinterpretation als eigene
Funktionen, danach Anzeigeformatierung. Der vorgeschlagene erste
Formatierungsumfang wurde mit „ja“ bestätigt: Zahlen, Prozent,
wissenschaftliche Schreibweise, Datum/Uhrzeit und Text, ausdrücklich
gewählte Culture; keine Farben, bedingte Formatierung, Layoutauswertung oder
Formelberechnung. Dies erweitert nicht stillschweigend die aktiven Raw-Reader.

Für unscharfen Textvergleich beauftragte der Benutzer Levenshtein,
Transposition und phonetischen Vergleich für Deutsch und Englisch.
Zuerst sind zwei getrennte Distanzfunktionen vorgesehen: Levenshtein und
eine exakt definierte Variante mit benachbarter Transposition. Hauptzweck
sind Namen und kurze Bezeichnungen; längere Texte müssen ebenfalls
berücksichtigt werden, gegebenenfalls über eine getrennte Variante.

#### Individuell freigegebener Textvergleichsvertrag

Implementierungsfreigabe 2026-10-01: Auf die ausdrückliche Frage
„Passt dieser Vertrag einschließlich Longtext-Verhalten und Phonetikverfahren
für die Implementierung?“ antwortete der Benutzer „ja“. Die vier getrennten
Funktionen sind damit einzeln freigegeben, zuerst die beiden Distanzen,
danach die beiden sprachbezogenen Phonetikverfahren:

- Levenshtein: Einfügen, Löschen und Ersetzen kosten jeweils 1.
- Optimal String Alignment (OSA): zusätzlich benachbarte Transposition
  für 1; eingeschränkte Variante, kein uneingeschränktes Damerau-Levenshtein.
- Unicode-Zeichen statt Bytes; Standard exakt und case-sensitive. Keine
  automatische Entfernung von Akzenten, Leerzeichen oder Satzzeichen.
  Optionale Normalisierung nur ausdrücklich gewählt und dokumentiert.
- Dieselben Distanzfunktionen mit Standard-/Large-Profil, ohne Abschneiden.
  Optionaler MaxDistance-Parameter: oberhalb der Schwelle ausdrücklich
  „größer als Grenze“, kein erfundener exakter Abstand. Rechenaufwand
  begrenzt; Ressourcenüberschreitung Fehler, keine stille Näherung.
  Konkrete Grenzen durch synthetische Tests qualifizieren und dokumentieren.
- Deutsch: Kölner Phonetik. Englisch: Double Metaphone mit primärem und
  alternativem Code. Verfahren/Sprache ausdrücklich wählen, keine
  automatische Spracherkennung; Phonetik getrennt von Editierdistanz.
- Öffentliche Namen, Parameter-/Ergebnistypen, NULL-/Fehlersemantik und
  technische Ressourcenprüfung innerhalb dieses Scopes vor Sourceumsetzung
  schriftlich konkretisieren. Keine zusätzliche fachliche API oder
  unbesprochene Normalisierungsoption ableiten; neue fachliche Entscheidung
  rückfragen. Standardprojektgates, unabhängiger Review, scopebezogene
  Lab-Tests, grüne CI und PR-Merge gelten unverändert.

Status Phonetik 2026-10-04: Die individuelle Provider-/TVF-/Alphabet-/Fullcode-/Grenzfreigabe vom 2026-10-03 wurde nach unabhängigem Referenz-/Lizenz-/Bindingreview in den kanonischen [Phonetikvertrag](../Documentation/Architecture/PHONETIC_CONTRACT.md) übernommen. Genau zwei öffentliche IF und zwei interne FT verwenden die eigene SAFE-Assembly in toolbelt.string.phonetic 1.0.0; kein Vierzeichen-Clamp, kein Aspell-Bulkimport und keine neue Normalisierungsoption. Begrenzte Build-/Framework-/IL- und native Installations-, Fixture-, Client- und Lifecycleteilnachweise liegen vor. Java-Differential, vollständige Zielmatrix, Minimalrechte und aktuelle Head-CI bleiben offen; teilweise validiert und unveröffentlicht. Die [Testevidenz](../Modules/toolbelt.string.phonetic/Tests/README.md) trennt private Lab- und öffentliche Offline-CI-Scope. Die historischen Distanzfreigaben und deren Nachweise bleiben getrennt.

Ergänzende konkrete Providerfreigabe 2026-10-02: Auf die Frage nach dem
besprochenen dedizierten portablen SAFE-CLR-Provider für Levenshtein und OSA
antwortete der Benutzer „Lebenshtein/OSA assembly -> ja“. Dies autorisiert
nur diesen Provider und seinen Lifecycle für die beiden bereits einzeln
freigegebenen Distanzfunktionen. Jaro und Phonetik werden dadurch nicht in
diesen Provider aufgenommen. Der [Vor-Source-Vertrag für Editierdistanzen](../Documentation/Architecture/EDIT_DISTANCE_CONTRACT.md)
konkretisiert Scalar-Semantik, Profile, Schwellen, Ergebnis- und Fehlerpriorität,
Metadaten sowie den separaten Deployment-/Trustvertrag. Root hat den vollständigen Vor-Source-Vertrag einschließlich nullable SQL-Metadaten bei logisch nicht-NULL ErrorCode am selben Tag geprüft und vor Runtime-Source geschlossen. Die Implementierung ist teilweise validiert und unveröffentlicht. Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Der erste Linux-Lauf SQL468/State9 im Metadaten-Fixture bleibt als vollständig bereinigter Fehlerlauf getrennt; der korrigierte neue Adapter bestand.
#### Individuell freigegebene Capture-/Replace-Welle

Implementierungsfreigabe 2026-10-01: Auf die ausdrückliche Frage
„Passt dieser konkrete Scope für beide Wellen zur Implementierung?“
antwortete der Benutzer „ja“. Dies bestätigt die folgende Capture-TVF und
die getrennte gruppenbezogene Replace-Funktion nach Einzelbesprechung:

- Alle Capture-Wiederholungen mit Match-, Gruppen- und Capture-Ordinal,
  Gruppenname, Position, Länge und Wert ausgeben.
- Nicht beteiligte Gruppen erkennbar mit Matched=0 und NULL für Position,
  Länge und Wert. Tatsächlich leerer Capture davon unterscheidbar.
- Replace unterstützt `$1`, `${Name}` und `$$`. Mehrfach erfasste Gruppe
  verwendet beim Replace ihre letzte Capture; die TVF liefert alle.
- Nicht beteiligte Gruppe ersetzt durch Leertext; unbekannte
  Gruppenreferenz ist ein Fehler.
- Bestehendes literales Replace unverändert. Keine Rückreferenzen im
  Suchpattern durch diese Erweiterung.
- Öffentliche Namen, genaue Typen, Zählweise, NULL-/Fehlerprioritäten und
  Profile innerhalb dieses Scopes vor Sourceumsetzung schriftlich
  konkretisieren; bestehende begrenzte SAFE-/LOB-Verträge weiterverwenden,
  keine Unlimited-, stille Truncation- oder Teilausgabeoption.

Status Capture/Replace: `ready for development`; keine Runtime-Evidenz.

Nachfolgerstand 2026-10-02: Vor-Source-Konkretisierung der bereits einzeln
freigegebenen zwei APIs ist `active` im isolierten Branch. Der
[Capture-/Replace-Vertragskandidat](../Documentation/Architecture/REGEX_CAPTURE_REPLACE_CONTRACT.md)
legt Signaturen, Gruppen-/Capture-Ordinals, Sentinelzeilen, Replacement-
Syntax und Fehlerpriorität fest. Ein zusätzliches konservatives
Capture-Historienprofil wird zunächst privat und synthetisch qualifiziert;
MaxRows/Textlimits allein schützen nicht vor bereits intern gespeicherten
Captures. Keine Sourceimplementierung oder SQL-Evidenz durch diesen Eintrag.
Die bisherigen sieben Regex-APIs und deren Nachweise bleiben unverändert.
Vor-Source-Gate anschließend erfolgreich: exakt präzisierter Strukturkandidat
bestand neun begrenzte Framework-Kinder mit 7608 Assertions, unabhängig
wiederholt; Semantikreview PASS. Die integrierte Source und SQL-SAFE-Runtime
bleiben separat zu qualifizieren; keine Heap-/Backtracking-Garantie.

Historischer API-only-Zwischenstand 2026-10-02: zwei freigegebene APIs im Branch umgesetzt,
integrierte Framework-Suite und unabhängiger Source-Review erfolgreich.
Begrenzte API-only-Labproben einschließlich SQLClient-Metadaten/Atomicity
lokal/zentral auf Windows2025 CU8 CL150/160/170 und Linux2019 latest CL150
erfolgreich; eigene Datenbanken/Trusthashes vollständig bereinigt. Lifecycle
ist blockiert: unsigned CLR-Katalogidentität belegt keine tatsächliche
Releaseversion. Vorgeschlagene zusätzliche erwartete Hashgrenze wartet auf
Benutzerentscheidung. Kein Upgrade-/Reinstall-/Uninstall-PASS, keine grüne
CI oder Mergebehauptung. Weitere Matrix, neue Mindestberechtigungsnachweise
und tatsächliche Large-Capture-Outputgrenze in SQL noch nicht ausgeführt.

Zusätzliche Einzelfreigabe 2026-10-02: Der Benutzer beantwortete die offene
technische Hashgrenze ausdrücklich mit „Ja, exakte Hashbindung freigeben“.
Deploy und Uninstall erhalten `ExpectedInstalledAssemblyHash`: den expliziten
SHA2_512-Hash der tatsächlich installierten, offline verifizierten Binarybytes
als `0x` plus 128 Hexzeichen. Bekannte installierte Releases 1.0 bis 1.3
erfordern den exakten Vergleich mit `sys.assembly_files.file_id = 1`, erneut
unter AppLock. Unbekannte Versionen, unbekannte oder abweichende Hashes bleiben
blockiert; keine Ableitung aus `clr_name`, Versionsannahme oder Hash-Fallback.
Nur vollständig geprüfte Modul-/Assembly-Abwesenheit erlaubt ausdrücklich
`0x`. Diese Freigabe erweitert weder APIs noch Trust, Konfiguration oder Rechte.
Der vorherige Blockierungsstand bleibt historische Evidenz; zum Zeitpunkt
dieser Freigabe standen neue Lifecycle- und CI-Nachweise weiterhin aus.

Finaler Nachweis 2026-10-02: Derselbe korrigierte Gesamtadapter bestand auf
Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal und
zentral. Umfasst die sieben alten und zwei neuen APIs, SQLClient-Metadaten,
atomare Fehler, echten 1.2-zu-1.3-Upgrade, Reinstall, explizite Binaryhashbindung,
Caller-Transaktionen/Optionserhalt, AppLock, post-DROP-Rollback, Versions-/
Marker-/Future-Slot-/Schema-Kollisionen, Dependencies, Uninstall und verifiziertes
eigenes Datenbank-/Trustcleanup. Frühere Gesamtadapterversuche scheiterten an
unverarbeiteter historischer SQLCMD-Direktive, einem optionsverändernden
Snapshot und der Credential-Quelle der zweiten Testverbindung; diese
Fixture-/Adapterfehler wurden behoben und bleiben historische Fehlernachweise.
Neue Capture-Minimalrechte, weitere Zielmatrix, tatsächliche große SQL-
Capture-Ausgabegrenze und SQL-100k-Durchsatz sind nicht ausgeführt. Die aktuelle CI wird separat als PR-Mergegate nachgewiesen; `partially validated`, `unreleased`, keine Mergebehauptung.

#### Individuell freigegebene XLSX-Typ-/Anzeige-Welle

Dieselbe ausdrückliche Benutzerantwort „ja“ vom 2026-10-01 bestätigt
separat die besprochene Typfunktion und Anzeigeformatierung:

- Separate Typfunktion liefert typisierte Werte samt Status, Rohwert bleibt
  erhalten. Zahlen nicht automatisch als Datum interpretieren: expliziter
  Zieltyp oder unterstützter Zellformatcode erforderlich.
- Datum, Uhrzeit und Dauer getrennt; Dauer darf über 24 Stunden liegen.
  Workbook-Datumssystem 1900/1904 beachten. Ungültiges Excel-Schalttagsdatum
  29.02.1900 liefert expliziten Sonderstatus, kein erfundenes SQL-Datum.
- Anzeigeformatierung liefert Text plus Status. Unterstützter erster Scope
  wie oben: Zahl, Prozent, wissenschaftlich, Datum/Uhrzeit und Text mit
  ausdrücklich gewählter Culture. Nicht unterstützte Formatcodes sichtbar
  melden, nicht stillschweigend annähern.
- Gespeicherte Formel-Ergebnisse dürfen verarbeitet werden, niemals neue
  Formelberechnung. Keine Farben, bedingte Formatierung oder Layoutauswertung.
- Nach qualifiziertem Raw-Reader implementieren; Typ-/Styletransport,
  unterstützte Formatgrammatik, SQL-Typ-/Überlauf-/NULLsemantik und begrenzte
  Ressourcen innerhalb dieses Scopes schriftlich konkretisieren. Keine
  Datei-/Netzwerk-, SDK-/Worker- oder Rechteausweitung ableiten.

Historischer Vorbereitungsstand der XLSX-Folgefunktionen: `ready for development`; damals keine Runtime-Evidenz. Der aktuelle Typstand folgt datiert unten; Anzeigeformatierung bleibt separat.
Am 2026-10-02 bestätigte der Benutzer zusätzlich die konkret besprochene
V3-Typentscheidung mit „Xlsx typeninterpretation -> freigegeben“: genau eine
`toolbelt_file.TVF_InterpretXlsxCell`, sieben Parameter / 14 Spalten,
exaktes SqlDecimal im sql_variant, enge ISO-/100-ns-/Serial60-Regeln und
atomarer Echoverzicht bei Ressourcenfehler 3 beziehungsweise NULL-Bindungs-
fallback 11. Der [kanonische Vor-Source-Vertrag](../Documentation/Architecture/XLSX_CELL_TYPE_CONTRACT.md)
hält die konkrete Semantik und getrennte private Framework-/technische
Hostevidenz fest. Root prüfte und schloss anschließend den konkreten
Vertragsfreeze; die Sourceumsetzung dieser V3-Welle ist freigegeben.
Die ausgewählte Modul-Runtimequalifikation ist erfolgreich; öffentlicher
Adapterport ist erfolgreich; aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Anzeigeformatierung
bleibt eine separate bereits freigegebene Welle.
Zusätzliche konkrete Freigabe 2026-10-02: Der Benutzer antwortete auf die
separate Lifecyclefrage „Ja, XLSX-Lifecycle-Sichtbarkeitsgate freigeben“.
Vorhandenes Datenbank-VIEW DEFINITION und SELECT auf
sys.sql_expression_dependencies werden vor Mutation und unter AppLock
verlangt; 0/NULL/unklar blockiert 51535/State 2. Keine Rechtevergabe.
Für beide Wellen gelten unabhängiger Review, synthetische Contract-/Grenztests,
scopebezogene Lab-Auswahl, erforderliche grüne CI und PR-Merge unverändert.
Neue fachliche Entscheidungen außerhalb dieses Scopes weiterhin rückfragen.
Der damalige Freigabeeintrag allein war kein Runtime-Nachweis. Der folgende
datierte Umsetzungsnachweis hält die tatsächlich geprüfte Typwelle getrennt
von Anzeigeformatierung und den anderen freigegebenen Wellen fest.

XLSX 1.1.0 ergänzt die einzeln freigegebene `TVF_InterpretXlsxCell` im bestehenden SAFE-Provider. Der finale öffentliche Typadapter bestand am 2026-10-02 auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral: drei Types-Runtime-Fixtures, exakte Zahlen-/100-ns-/NULL-/Clientmetadaten, clean/genuine 1.0/Repeat, Caller-TX OFF/ON intakt und doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung. Raw→Type-Komposition wurde nach den API-CL-Schleifen auf der jeweils letzten CL (2019:150, 2025:170) sowie separat im zentralen Caller geprüft. Keine Konfigurations- oder Rechteänderungen. Die öffentliche Pfadfassung bestand nach ihrem unabhängig geprüften Port auf beiden ausgewählten Targets einschließlich frischer eigener Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Minimalrechte, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. `partially validated`, `unreleased`; historische Raw-1.0-Evidenz bleibt getrennt.

### Individuell freigegebene Ergänzungen: Jaro-Winkler, Paarvergleich und gruppiertes JSON
Konkrete zusätzliche Jaro-Providerfreigabe 2026-10-03: Nach Besprechung der
Scalar-Sourceownership, Varianten, Profile, Binary-/Versions- und vollständigen
Distanz-/Lifecycle-Regressionswirkung antwortete der Benutzer ausdrücklich
„Ja, bestehende Assembly auf 1.1.0 erweitern“. Dies autorisiert genau die
additive Jaro-TVF und den internen Transport im vorhandenen SAFE-Provider
`toolbelt.string.edit-distance` 1.1.0 (vier auf sechs Slots), gemeinsame interne
`UnicodeScalar`-Source und neuen exakten Releasehash. Levenshtein/OSA-Verträge
bleiben unverändert. Keine neue Assembly, SVF, Paar-/Phonetik-API. Der
[Jaro-Vertrag](../Documentation/Architecture/JARO_WINKLER_CONTRACT.md) ist vor
Source festgehalten. Neue 1.1-/genuine 1.0-Builds, vollständige Frameworkregression
und beide IL-Metadatengates bestanden separat. Die privaten 1.1-Gesamtadapter
bestanden am 2026-10-03 auf Linux 2019/latest CL150 und Windows 2025/CU8
CL150/160/170 lokal/zentral sowie mit SC-UTF8-Consumer: genuine Upgrades,
Runtime-/Client-/Lifecycle- und eigene DB-/Trustbereinigung samt frischem
unabhängigem Audit. Doomed-Guards qualifizieren den vollständigen originalen
Firstbatch in einer eigenen DB-Prozedur, keinen vollständigen SQLCMD-Lauf.
Keine Konfigurations-, Rechte-, Owner- oder Infrastrukturänderungen.
Minimalrechte, weitere Ziele und Heap bleiben offen; aktuelle CI separat am
PR-Head. Teilweise validiert, unveröffentlicht; historische 1.0-Evidenz getrennt.

Benutzerfreigabe 2026-10-01: Nach Besprechung der folgenden vier konkreten
Funktionen bestätigte der Benutzer die ausdrückliche Implementierungsfrage
mit „ja“. Diese vier APIs sind einzeln freigegeben, zusätzlich zu den oben
dokumentierten Wellen; keine pauschale Backlogfreigabe.

- `TVF_JaroWinklerSimilarity`: Wert 0 bis 1, identisch 1; festes Präfixgewicht
  0,1, höchstens vier Präfixzeichen, Bonus nur bei Jaro-Wert über 0,7.
  Gemeinsame Unicode-/Normalisierungsgrundlage der Distanzfunktionen;
  NULL-Eingabe ergibt NULL, zwei leere Texte 1. Begrenzte Standard-/Large-
  Profile, keine Abschneidung oder Näherung.
- `USP_CompareTextPairs`: caller-lokale #Temp mit eindeutiger PairOrdinal,
  LeftText und RightText. Expliziter Algorithmus Levenshtein, OSA oder
  Jaro-Winkler; Ausgabe PairOrdinal, Distanz beziehungsweise Ähnlichkeit
  und Status. Bestehende Vergleichskerne wiederverwenden, Standard-USP-
  Vertrag. Begrenzte Zeilen-/Text-/Arbeitsbudgets, vollständige Verarbeitung
  vor ResultTable-Mutation. Keine automatische Kreuzkombination, kein
  verstecktes Ranking oder automatisches Duplikatzusammenführen.
  Ergänzende Vor-Source-Freigabe 2026-10-03: Der Benutzer bestätigte die
  gesondert besprochene eigene Modul-/Hash-/Lifecycle-Sichtgrenze mit
  „das passt für mich so“. Die ausdrücklich wiederaufgenommene autonome
  Umsetzung bestätigt die fünf konkreten Zusatzentscheidungen. Der
  [kanonische Vertrag](../Documentation/Architecture/TEXT_PAIRS_CONTRACT.md)
  legt elf Parameter, signed bigint Ordinals, fünf Ergebnisfelder, konservative
  globale Budgets und gleiche bekannte Dependencies fest. Keine neue Assembly.
  `toolbelt.string.text-pairs` 1.0.0 ist implementiert, teilweise validiert und
  unveröffentlicht. Fünf öffentliche SQL-Fixtures sowie Lifecycle-Wiederholungen
  bestanden auf Linux 2019/latest CL150 local und Windows 2025/CU8 CL170 local.
  Ein separater zentraler Windows-Lauf bestand InstalledMetadata, drei direkte
  Clientconsumer, drei ResultTable-Ausgaben ohne Resultset, strikte Uninstall-
  Bestätigung mit Katalogerhalt und eigene Bereinigung; unabhängig physisch
  geprüft am 2026-10-04. Minimalrechte, weitere Lifecycle-Negativfälle, Ziele
  und aktuelle PR-Head-CI bleiben getrennt offen.
- `USP_JsonArraysByGroup` und `USP_JsonObjectsByGroup`: bestehender Entries-
  Vertrag plus positive GroupOrdinal; ein JSON-Ergebnis je vorhandener
  Gruppe, Entry-Ordinal bestimmt Reihenfolge. Duplicate Keys innerhalb
  einer Gruppe Fehler. Gemeinsame ValueKind-/Unicode-/Escapingkerne und
  Ressourcenverträge wiederverwenden; Gesamtbudget über alle Gruppen,
  keine Teilmutation bei Fehler. Kein dynamischer SQL-Eingabetext und keine
  Typinferenz. Gruppierte USPs, keine direkt in GROUP BY verwendbaren
  SQL-Aggregatobjekte.

Status: `ready for development`; keine Implementierungs-/Runtime-Evidenz.
Technische SQL-Typen, NULL-/Fehlerprioritäten, exakte Grenzen und Kopplung
innerhalb dieses Scopes vor Sourceumsetzung dokumentieren und qualifizieren.
Neue fachliche Entscheidungen rückfragen. Unabhängiger Review, scopebezogene
Lab-Tests, erforderliche grüne CI und PR-Merge gelten unverändert.

Vor-Source-Präzisierung 2026-10-02, Codex: Für ausschließlich die beiden
gruppierten JSON-USPs konkretisiert der
[kanonische Vertrag](../Documentation/Architecture/JSON_GROUP_CONSTRUCTORS_CONTRACT.md)
Signaturen, globale Budgets, Resultschemas, Fehlerpriorität und notwendige
gekoppelte Lifecycle-Grenzen. Vorbereitung `active`; technisches Vor-Source-Gate
nach unabhängigem Kandidatenreview und Rootreview abgeschlossen, Umsetzung offen.
Einzelfreigabe 2026-10-02: Der Benutzer bestätigte ausdrücklich, dass JSON-Uninstall fehlende Metadatensichtbarkeit mit `53622/1` blockieren und vorhandenes Datenbank-`VIEW DEFINITION` sowie `SELECT` auf `sys.sql_expression_dependencies` voraussetzen darf. Keine Berechtigungserteilung. Die neue Gateumsetzung wird vor Dependencyabfrage im Preflight und erneut unter AppLock geprüft; neue gekoppelte CI und tatsächliche Minimalrechte bleiben getrennte Nachweise.

Umsetzungsstand 2026-10-02, Codex: `toolbelt.json.constructors` 1.1.0 implementiert die beiden einzeln freigegebenen Gruppen-USPs über den gemeinsamen T-SQL-Kern. Auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 bestanden lokal und zentral die API-/100000-/16-MiB-/Clientprüfungen als Teil insgesamt fehlgeschlagener früherer Läufe. Die finalen fokussierten Läufe mit ausschließlich InstalledMetadata.Contract.sql als Runtime-Auswahl bestanden Metadaten, genuine 1.0-Upgrades, Lifecycle, Central und eigene Bereinigung. Neue Minimalrechte bleiben offen; die Uninstall-Voraussetzung VIEW DEFINITION/SELECT wurde am 2026-10-02 einzeln freigegeben und die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht; historische 1.0-Evidenz bleibt getrennt. Dies ändert nicht den Status der weiteren einzeln freigegebenen Funktionen dieses Abschnitts.

111 private Assertions betreffen ausschließlich Gruppen vorvalidierter
synthetischer Fragmente, keine SQL-/Escaping-/Lifecycle-Validierung.

Zusätzlicher Benutzerauftrag 2026-10-01: „berücksichtige aber auch
CLR-Aggregate zusätzlich!“ Deshalb portable SQL-CLR-JSON-Array-/Object-
Aggregate ergänzend zu den USPs ausarbeiten, nicht durch diese ersetzen.
Nach anschließender Einzelbesprechung bestätigte der Benutzer am 2026-10-01
ausdrücklich „ja, freigegeben“ zur Implementierung der beiden Aggregate
einschließlich Namenskonvention und gemeinsamer Kernumstellung:

- `AGF_JsonArray` und `AGF_JsonObject` sind echte, direkt in SELECT/GROUP BY
  verwendbare JSON-Aggregate; Namenskonvention `AGF_{CamelCase}` für diese
  Objektart ausdrücklich freigegeben und im Namingstandard zu verankern.
- Eingaben explizite Ordinal, ValueKind, Value; Object zusätzlich Key.
  Reihenfolge nur über Ordinal, niemals SQL-Verarbeitungsreihenfolge.
  Doppelte Ordinals Fehler. Bestehende JSON-Regeln: explizites JSON-null,
  doppelte Object-Keys Fehler. Ergebnis nvarchar(max), leere Aggregation
  [] beziehungsweise {}.
- Begrenzte Profile für Einträge, Ergebnis und serialisierten Zwischenzustand
  je Gruppe; kein Unlimited und keine globale Speicherzusage über alle Gruppen.
- SAFE, memory-only, keine Datei-/Netzwerkzugriffe. Windows-/Linux-
  Qualifikation einschließlich Merge und Serialisierung von Teilzuständen.
- Gemeinsamer kanonischer JSON-Kern für Aggregate und Konstruktoren;
  erforderliche interne Kernumstellung mit vollständigen Regressionstests,
  öffentliche USP-Verträge unverändert. Kein zweiter ungeprüfter Escapingkern.
- Konkrete Typen/Profile/NULL-/Fehlerprioritäten und serialisierte Zustands-
  kodierung vor Sourceumsetzung dokumentieren, Grenzen synthetisch qualifizieren.
  Kein SDK-/Workerfallback, keine Rechteausweitung oder Veröffentlichung.

Status CLR-Aggregate: `ready for development`; keine Runtime-Evidenz.
Die bestehenden freigegebenen Wellen laufen unabhängig weiter.

Fortsetzung 2026-10-03: Die drei zusätzlichen Lifecyclegrenzen (exakte
Assemblymarkertypen, geschlossenes unabhängig qualifiziertes Binaryregister
und kohärente vorhandene Eigentümer ohne Rechte-/Owneränderung) wurden
einzeln genehmigt. Der konkrete
[JSON-1.2-Vertrag](../Documentation/Architecture/JSON_CLR_MIGRATION_CONTRACT.md)
und seine tatsächliche Registryzeile wurden vor Source unabhängig geprüft.
Der bekannte Produktbuild ist ausschließlich offline qualifiziert;
Sourceumsetzung und native Migration-/Caller-/Lifecyclequalifikation bleiben
getrennte Gates. Historische 1.0-/1.1-Nachweise bleiben unverändert.

### Individuell freigegebene Tabellenklon-Ausbauwellen 1 und 2

Benutzerfreigabe 2026-10-01: Nach Besprechung des begrenzten Script-only-V1
und der folgenden Ausbaustufen bestätigte der Benutzer die ausdrückliche
Empfehlung, Wellen 1 und 2 als Nächstes konkret freizugeben, mit
„ja, das passt so“. Keine Freigabe für Trigger, automatische Ausführung,
Datenkopie oder beliebige weitere Objektklassen.

- Welle 1: bestehende Script-only-Tabellenstruktur erweitern um berechnete
  Spalten einschließlich PERSISTED, gefilterte Rowstore-Indizes und optional
  Extended Properties. Nicht unterstützte Eigenschaften sichtbar ablehnen,
  niemals stillschweigend weglassen. Keine Scriptausführung durch die API.
- Welle 2: Foreign Keys und mehrere zusammengehörige Tabellen mit expliziter
  Quell-/Zieltabellenzuordnung. Beziehungen zwischen geklonten Tabellen und
  Selbstreferenzen zeigen auf neue Ziele. Referenzen auf nicht geklonte
  Tabellen bleiben nur bei ausdrücklich gewählter Regel bestehen. Erst
  Tabellen, dann Foreign Keys skripten, auch zyklische Beziehungen beachten.
- Vor Sourceumsetzung konkrete Parameter, Mappingtransport, Ergebnisordinals,
  Typ-/Index-/Propertygrenzen und FK-Regeln innerhalb dieses Scopes schriftlich
  konkretisieren; neue fachliche Entscheidungen rückfragen. Keine stillschweigende
  CrossDB-, Trigger-, Permissions-, Spezialtabellen- oder Mutationsausweitung.
- Bestehenden Klonkern wiederverwenden; V1 zuerst unabhängig prüfen und
  integrieren. Erweiterungen in getrennten überprüfbaren Wellen mit synthetischen
  Strukturoracles, scopebezogenen Lab-Tests und grünen PR-Merges integrieren.

Historischer W1-Stand: `implemented`, `partially validated`, `unreleased`; Welle2 war zu diesem Zeitpunkt getrennt und nicht implementiert. Der aktuelle W2-Stand folgt im datierten V3-Absatz.

Änderungsvermerk 2026-10-02 — Codex: Die zusätzliche Benutzerantwort
„Tabellenkopf Welle1 Ja“ bestätigt für Welle 1 `@IncludeExtendedProperties`
vor dem Standardtail (bisherige Positionen 6..9 werden 7..10) und sieben
einzelne `SESSION_OPTION`-Zeilen vor `TABLE`. Der
[Vor-Source-Reviewvertrag](../Documentation/Architecture/TABLE_CLONE_WAVE1_CONTRACT.md)
plant deshalb eine kohärente Modulversion 2.0.0 mit denselben zwei USP-Slots,
keinen neuen fachlichen APIs und unverändertem ScriptOnly-Scope.
Das Computed-only-Voraussetzungsgate für vorhandenes SELECT auf
`sys.sql_expression_dependencies` ist eine zusätzliche konkrete
Vertragsgrenze; die JSON-Uninstall-Freigabe wird nicht auf Clone übertragen.
Zusätzlich ist ausschließlich für EXTENDED_PROPERTY eine Zeile als
typisierter DECLARE+EXEC-Batch statt einer einzelnen Anweisung vorgeschlagen.
Nach gesonderter konkreter Besprechung bestätigte der Benutzer am 2026-10-02
„beides ja“ für das Computed-only-Gate mit 53901/3 und die begrenzte
EXTENDED_PROPERTY-Batchausnahme. Der vollständige Vertrag und die gekoppelten
Discovery-/Backlogänderungen wurden vor Source unabhängig durch Root geprüft;
das Sourcegate ist geschlossen. Der nachfolgende W1-Nachweis ist separat dokumentiert; Welle 2 bleibt
unverändert getrennt.

### TC-2026-034 / TC-2026-039 / TC-2026-040 / TC-2026-042 / TC-2026-044: Freigegebene Reservewellen

Benutzerfreigabe 2026-10-01: Nach der Einzelbesprechung der beiden
ZIP-Datei-USPs bestätigte der Benutzer „ZIP passt“ und nahm Range sowie Date
Shifting in die Planung auf. Anschließend wurden vier weitere APIs mit
konkreten Verträgen einschließlich Lookup und Script-only-Tabellenklon
besprochen. Auf die ausdrückliche Frage nach Implementierung, Prüfung und
PR-Merge aller vier sowie der beiden ZIP-Datei-USPs antwortete er:
„ja, ich gebe das alles frei“. Diese sechs Funktionen sind einzeln
freigegeben; keine pauschale Freigabe weiterer Backlogthemen.
Status: `ready for development`; noch keine Implementierungs-/Runtime-Evidenz.

#### ZIP-Datei-I/O: zwei Windows-Fassaden

Umsetzung 2026-10-04: [toolbelt.archive.zip-files 1.0.0](../Modules/toolbelt.archive.zip-files/README.md)
implementiert ausschließlich diese zwei freigegebenen T-SQL-Fassaden.
[Vertrag](../Documentation/Architecture/ZIP_FILES_CONTRACT.md), Signaturen,
ResultTable-Brücken und neue technische Fehler 54620–54624 sind gekoppelt.
Genau drei feste Brücken-Temps wurden für den bestehenden ResultTable-
Interoperabilitätskonflikt ausdrücklich genehmigt; keine Core-/Provideränderung.
Begrenzte native Teilnachweise auf Windows2025/CU8 CL170 local: elf frühere
erfolgreiche Fälle und zwei gezielt erfolgreiche AppLock-Aliasfälle mit identischen
Produktbytes; kein gemeinsamer 13-Fälle-Erfolgslauf. Eigene Bereinigung frisch geprüft.
Vollständige NTFS-/Rechte-/Race-/Zielmatrix- und aktuelle Head-CI-Qualifikation offen;
partially validated, unveröffentlicht.
Die übrigen Reservefunktionen in diesem Abschnitt bleiben getrennt.


- `USP_CreateZipFileFromEntries`: bestehender Entries-#Temp-/Writervertrag,
  dann kontrolliertes Schreiben des vollständigen Archiv-Binary.
- `USP_ExtractZipEntryToFile`: ZIP-Binary und genau ein benannter Entry,
  dann kontrolliertes Schreiben; keine vollständige/rekursive Entpackung.
- Bestehende kanonische ZIP-/Filesystemkerne wiederverwenden, kein zweiter
  ZIP-Algorithmus. Windows-only zunächst; kein impliziter Linux-/Workerfallback.
- Konfigurierter Root-Alias und relativer Dateipfad, Caller als Default,
  ServiceAccount nur ausdrücklich gewählt. Overwrite Default aus, vorhandene
  Datei Fehler. Zielverzeichnisse müssen bestehen; keine automatische Anlage.
- Erst vollständige temporäre Datei, dann kontrollierte Veröffentlichung;
  keine teilweise sichtbare Zieldatei. Fehler dürfen bestehende Zieldatei
  nicht beschädigen. Geforderte Atomarität tatsächlich nachweisen, sonst
  nur diesen Zweig blockieren, kein unsicherer Direct-Write-Fallback.
- Aktive Caller-SQL-Transaktionen zunächst ablehnen, weil Dateischreiben
  nicht durch SQL-Rollback rückgängig wird. Bestehende ZIP-Ressourcenlimits,
  kein Unlimited. Standard-USP-Vertrag; Ausgabe nur Metadaten wie BytesWritten,
  RootAlias, RelativePath, State, kein zusätzliches Archive-Binary.
- Konkrete öffentliche Schemas, Ressourcennamen und Fehlernummern sind
  technische Konkretisierung innerhalb dieses Scopes; keine neue Identitäts-,
  Pfad-, Trust- oder Infrastrukturfreigabe. Tests nur synthetische Fixtures
  in ausdrücklich zulässigen Testroots, keine Lab-Infrastrukturverwaltung.

#### TVF_DeterministicRange

- Eingaben Key varbinary(max), positive MappingVersion int, Seed bigint=0,
  Min bigint und Max bigint. Nicht leerer Key höchstens 8.000 Bytes; keine
  automatische Case-/Collation-/Unicode-Normalisierung. Caller kodiert Text.
- Grenzen geschlossen, negative Bereiche und vollständiger bigint-Bereich.
  Gleiche Eingaben liefern versionsstabil denselben Wert; Änderung von Seed,
  MappingVersion oder Grenzen kann die Zuordnung ändern, nicht garantiert.
- SHA-256, eindeutig gerahmte versionsgebundene Bytekodierung und
  Rejection-Sampling statt einfacher Modulo-Verzerrung. Höchstens 128 Versuche,
  danach expliziter Fehler; kein unbegrenztes Wiederholen.
- Eine Ergebniszeile Value bigint und ErrorCode. NULL-Key ergibt NULL-Wert
  ohne Fehler; ungültige Konfiguration Fehlercode und kein Wert. Technische
  Fehlerprioritäten, Byteformat und Testvektoren dauerhaft dokumentieren.
- Keine Secrets, persistierten Mappings, Eindeutigkeits-, Kryptografie- oder
  Anonymisierungsgarantie. Portabler T-SQL-Kern bevorzugt; keine neuen CLR-/
  externen Provider ohne gesonderte Autorisierung.

#### TVF_DeterministicDateShift

- datetime2(7), Entitätsschlüssel nach Rangevertrag, MappingVersion, Seed und
  MaxDays int=365. Bereich inklusiv [-MaxDays,+MaxDays]; MaxDays von 0 bis
  3.652.058. Ein kanonischer Range-Kern, keine zweite Hashimplementierung.
- Gleiche Entität bei identischen Parametern erhält denselben Tagesoffset;
  Uhrzeit/Präzision und zeitliche Abstände bleiben erhalten. MaxDays=0 identisch.
- Datentypüberlauf ist Fehler, kein Clamp/Wraparound. Keine Zeitzonen-/DST-
  Behandlung oder separate Offset-Diagnoseausgabe.
- Eine Ergebniszeile Value datetime2(7), ErrorCode. NULL-Zeitwert oder -Key
  ergibt NULL ohne Fehler; Konfiguration und Grenzen sonst strikt prüfen.

#### USP_DeterministicLookup

- Zwei caller-lokale #Temp-Tabellen: Eingaben Ordinal/Key, Pool Ordinal/Value.
  Ordinals positiv/eindeutig mit zulässigen Lücken; Auswahl aus nach Ordinal
  geordnetem Pool. Schlüssel nach Rangevertrag, Pooltext Unicode.
- MappingVersion, Seed und ausdrücklich gewählte LookupVersion gehören zum
  Mappingkontext. Unveränderter Pool/gleiche Eingaben liefern gleiche Auswahl.
  Pooländerung benötigt neue LookupVersion; kein Speichern/Überwachen früherer
  Pools. Keine Eins-zu-eins-Zusage; verschiedene Keys dürfen dasselbe erhalten.
- Ausgabe InputOrdinal, LookupOrdinal, Value, keine Originalkeys. Leerer Pool
  Fehler; NULL-Key erzeugt NULL-Zuordnung. Standard-USP-Vertrag, vollständige
  Prüfung vor ResultTable-Mutation; gemeinsame Range-Grundlage.
- Default je 10.000 Eingabe-/Poolzeilen, Ceiling je 100.000. Pooltext Default
  2 MiB/Ceiling 16 MiB; Ergebnistext höchstens 16 MiB. Keine Anonymisierungs-
  oder Re-Identifikationsschutzbehauptung, keine realen Daten als Testartefakte.

#### USP_ScriptTableClone

Stand2026-10-04, Codex: Die am2026-10-03 konkret bestätigte W2-Erweiterung umfasst Map-/FK-Planung, PositionsbruchV3 und failclosed FK-EP-/Stategrenzen. [Kanonischer V3-Vertrag](../Documentation/Architecture/TABLE_CLONE_WAVE2_CONTRACT.md). W2 implementiert, teilweise validiert und unveröffentlicht. Begrenzte lokale Linux2019/latest CL150-/Windows2025/exakt CU8 CL170-Lifecycle-/Upgrade-/resolved-Consumer-Nachweise samt frischer Bereinigung bestanden. Linux-Fixtures werden nur als Teilnachweis eines historischen insgesamt fehlgeschlagenen Laufs wiederverwendet; Windows vier Fixtures einmal im aktuellen Clean3. Unresolved NOT_ESTABLISHED, vollständige Qualifikation und aktuelle Head-CI offen. Die folgenden ursprünglichen V0-Grenzen bleiben historischer Ausgangsscope, keine neue W2-FK-Ablehnung.

- Script-only-Planer für explizite Quell-/Ziel-Schema-/Tabellennamen in
  derselben Datenbank, reguläre diskbasierte Tabellen. Keine DDL-Ausführung,
  Datenkopie, datenbankübergreifende Quelle oder automatische Recovery.
- Spalten, Nullability, Defaults, Checks, Primary-/Unique-Constraints und
  gewöhnliche Rowstore-Indizes. Identity optional übernehmen, keine Daten
  oder aktuellen Identity-Zähler.
- Keine Foreign Keys, Trigger, Rechte, Extended Properties, Computed-/Sparse-
  Spalten oder Temporal-/Ledger-/Graph-/Partitionierungsfeatures. Nicht
  unterstützte Eigenschaften sichtbar melden; kein stilles Weglassen mit
  behaupteter Vollständigkeit. Exakte Typ-/Indexgrenzen technisch dokumentieren.
- Geordnete Zeilen: Reihenfolge, Objektart, Zielname, DDL-Text.
  Deterministische kollisionsgeprüfte Namen, Identifierquoting und kein
  Überschreiben existierender Ziele. Standard-USP-Vertrag; komplette Vorschau
  vor Ausgabe. Plan ist eine Momentaufnahme, keine spätere Driftfreiheit.
- Tests erzeugen/führen ausschließlich synthetische Test-DDL aus und
  vergleichen Strukturen. Produktive API führt niemals den Scripttext aus.

#### Reihenfolge und Ausweicharbeit

Bereits aktive Regex-/JSON-/XLSX-Wellen zuerst unabhängig fortsetzen. Bei
freien Agent-Slots Range vor DateShift/Lookup; Scriptplaner unabhängig;
ZIP-Datei-I/O abhängig von qualifiziertem Filesystem-/Atomaritätsnachweis.
Blocker stoppen ausschließlich abhängige Zweige. Agents melden sofort,
Orchestrator prüft unabhängig und integriert grüne konsistente Stände über
PR nach origin/main samt Branchcleanup. Keine Veröffentlichung, zusätzlichen
fachlichen Funktionen oder Privilegien-/Lab-Infrastrukturänderungen.

### TC-2026-010 / TC-2026-009 / TC-2026-045: Freigegebene nächste Entwicklungswellen

Benutzerfreigabe 2026-10-01: Nach Besprechung von Zweck, öffentlichen
Verträgen, Alternativen, Risiken und Scope bestätigte der Benutzer zuerst
Regex ohne Captures, JSON über caller-lokale #Temp und einen eigenen begrenzten
SAFE-ZIP-/XML-Kern für XLSX mit „ja, das passt so“. Anschließend wurden die
folgenden sechs APIs und Detailverträge einzeln benannt; auf die ausdrückliche
Frage nach Implementierung, Prüfung und PR-Merge antwortete er „ok, passt so“.
Nur diese Funktionen sind damit freigegeben, keine weiteren fachlichen APIs,
Datei-I/O-, Capture-, SDK-/Worker-, Rechteausweitungs- oder Release-Slices.
Status: `active`; Regex R2b ist implementiert und im ausgewählten Lab-Scope
geprüft und über PR #127 integriert. JSON ist implementiert und im ausgewählten
Lab-Scope geprüft; XLSX bleibt eine getrennte aktive Welle.

#### Regex R2b: Gesamttreffer und Split

Stand 2026-10-01: Version 1.2.0 implementiert; vollständiger Adapter auf
SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 PASS.
Unabhängiger Source-/Contract-/Lifecycle-Review sowie reproduzierter
Framework-/Static-Vertrag erfolgreich; erforderliche PR-CI grün und über
[PR #127](https://github.com/gecompat/SQL_Server_Toolbelt/pull/127) integriert.
Weitere R2b-Ziele, Lowpriv-CrossDB und SQL-100k-Durchsatz bleiben offen.
Modulstatus `partially validated`, `unreleased`; keine Capture-Freigabe.

- `toolbelt_string.TVF_RegexMatches`: Input/Pattern `nvarchar(max)`, Start,
  bestehende Flags, Profil und MaxRows. Ergebnis `Ordinal bigint`,
  `StartPosition bigint`, `Length bigint`, `Value nvarchar(max)`.
  NULL-Input/Pattern oder kein Treffer: keine Zeilen. Leere Treffer gültig.
- `toolbelt_string.TVF_RegexSplit`: Input/Pattern, Flags, Profil und MaxRows;
  kein Startparameter, immer ganze Quelle. Gleiches Ergebnisschema; Treffer
  sind nicht ausgegebene Separatoren. Kein Treffer: gesamte Quelle als Token;
  leere Quelle ohne Separator-Treffer: ein leeres Token. Leere Rand-/
  Zwischentokens erhalten. NULL-Input/Pattern: keine Zeilen.
- Ordinals und Positionen 1-basiert, UTF-16-Codeeinheiten; keine Überlappung,
  Captures, Backreferences oder Entquotierung. Leere Separator-Treffer
  konsumieren kein Zeichen; Suche rückt eine Codeeinheit weiter.
- Bestehender Dialekt und R2a-Profile: Pattern 8.000 Codeeinheiten,
  standard 2 MiB/500 ms, large 16 MiB/2.000 ms. Ergebnistextsumme durch
  Profil begrenzt. MaxRows Default 10.000, Ceiling 100.000. Keine implizite
  Profilaufwertung, Truncation oder Unlimited-Option. Vollständige Prüfung/
  Materialisierung vor Zeilenausgabe; Vertragsfehler oder Timeout ohne
  verwertbare Teilmenge. Vorhandene R1b/R2a-Verträge unverändert.

#### JSON Slice B: getrennte Konstruktor-USPs

Stand 2026-10-01: `toolbelt.json.constructors` 1.0.0 implementiert.
Vollständiger finaler Adapter auf SQL Server 2019 Linux/latest und 2025
Windows/CU8 erfolgreich, einschließlich TF-Drift-Reparatur, reserviertem
Caller-Tempnamespace vor Core-Kompilierung, Help-Bypass und tatsächlichen
Client-LOB-Metadaten. Unabhängige Reviewbefunde korrigiert und in beiden
finalen Läufen geprüft. Modulstatus `partially validated`, `unreleased`;
weitere Ziele, gemappte CrossDB-Minimalrechte und Produktionskapazität offen.

- `toolbelt_json.USP_JsonArray` und `toolbelt_json.USP_JsonObject`:
  EntriesTable für caller-lokale #Temp, Ressourcenparameter und vollständiger
  Standard-USP-Vertrag. Dieser ausdrücklich gewählte Transport ersetzt
  prospektiv den bisherigen Table-Type-Vorschlag.
- Ordinal int positiv/eindeutig, Lücken erlaubt; ValueKind nvarchar(max)
  exakt string/number/boolean/null/json und Value nvarchar(max). Object
  zusätzlich Key nvarchar(max): nicht NULL/leer, höchstens 1.024 Codeeinheiten.
- string vollständig escapen; number strikte JSON-Literalgrammatik ohne
  Culturekonvertierung; boolean exakt true/false; null verlangt SQL-NULL und
  erzeugt JSON-null; json nur validiertes vollständiges Objekt/Array.
  Sonstige SQL-NULL-Werte und ungültige Unicode-Surrogatfolgen sind Fehler.
- Binär längensensitive unveränderte Keys, kein Trim/Normalisieren; doppelte
  Keys Fehler. Ordinalreihenfolge; leere Tabelle ergibt [] bzw. {}. Ergebnis
  genau eine Zeile/Spalte JsonValue nvarchar(max). Keine Typinferenz, Pretty
  Print, Ausführung, JSON-Patch oder Aggregate.
- Default 10.000 Einträge, jeweils 2 MiB Gesamtwert-/Ergebnistext; explizite
  Ceilings 100.000 und 16 MiB. Positive Grenzen, kein Unlimited. Vollständige
  Konstruktion vor ResultTable-Mutation, ein gemeinsamer Escaping-/Prüfkern.

#### XLSX: bedingt freigegebene Binary-Reader

- `toolbelt_file.USP_ListXlsxWorksheets`: Binary-Eingabe; SheetOrdinal,
  SheetName, Visibility, Date1904.
- `toolbelt_file.USP_ReadXlsxWorksheetCells`: Binary plus positiver
  SheetOrdinal; nur vorhandene Zellen, nach Zeile/Spalte geordnet. Ergebnis
  RowOrdinal, ColumnOrdinal, StoredType, ValuePresent, RawValue, TextValue,
  FormulaPresent, FormulaText, FormulaKind, SharedFormulaIndex, CachePresent,
  CacheValue. Fehlender SheetOrdinal ist Fehler; fehlende/leere Inhalte
  unterscheidbar. Keine Rechteckauffüllung, Shared-Formula-Expansion,
  Formelberechnung, Typinferenz, Styles-/Datums-/Anzeigeformatierung.
- NULL-Binary: keine Zeilen. Beschädigte/nicht unterstützte Inhalte: Fehler,
  keine stille Zellüberspringung. Standard-Hilfe/ResultTable; gewähltes
  Ergebnis vollständig vor Ausgabe. Sheetliste ist kein Vollnachweis aller
  nicht gelesenen Zellparts.
- Qualifizierungsgrenzen: 16 MiB Archiv, 64 MiB entpackt, 16 MiB je Part,
  256 Parts, 32 Sheets, 100.000 Zellen, 50.000 Shared Strings/8 MiB Text,
  XML-Tiefe 64, Ratio 200. Ressourcenparameter zunächst nur reduzierend;
  höhere Grenzen benötigen separate Qualifikation/Freigabe. Kooperatives
  Parserbudget 5 Sekunden, keine harte SQL-Wallclockzusage.
- Eigener begrenzter ZIP-/XML-Kern unter Wiederverwendung des kanonischen
  ZIP-Parsers. Vor öffentlichen APIs SAFE-/Memory-only-Qualifikation; keine
  DTDs, externen Beziehungen, Makros, Datei-/Netzwerkzugriffe, SDK-Beschaffung,
  externe Worker oder Hochprivilegierung. Bei gescheiterter Qualifikation
  wird nur XLSX blockiert, unabhängige freigegebene Wellen laufen weiter.
- XLSX-Schema/Modulzuordnung und noch nicht benannte technische Details sind
  Umsetzungsvorschläge, keine zusätzliche fachliche Scopeausweitung.

#### Ausführung und Nachweise

Agents melden Fertigstellung sofort an den Orchestrator. Je kohärenter Welle
unabhängiger Review, synthetische Contract-/Grenz-/Lifecycle-Tests,
risikobasierte SQL_Server_Lab-Auswahl (anfangs 2019 Linux/2025 Windows),
grüne erforderliche CI und PR-Merge nach origin/main; Branchcleanup.
Keine Lab-Infrastrukturverwaltung oder pauschale Matrix-/Kapazitätszusage.
Ein Blocker hält andere freigegebene unabhängige Wellen nicht an.
ZIP-Datei-I/O und weitere Reservefunktionen werden separat besprochen.

### Testkonfiguration für die freigegebenen Wellen

Benutzerfreigabe 2026-10-01: Zunächst wurden notwendige Parameteränderungen
am Testziel ausdrücklich beauftragt. Nach Besprechung eines Konflikts durch
ausstehende Serverkonfiguration bestätigte der Benutzer: „du kannst die
Testsysteme so konfigurieren, wie du willst verfüge frei darüber“.
Die kanonische Abgrenzung, Koordination, Sicherheits- und
Wiederherstellungsregeln stehen in [AGENTS.md](../AGENTS.md#autorisierte-sql-testparameter).
Dies ist eine Testkonfigurationsfreigabe, keine zusätzliche fachliche API,
Veröffentlichungsfreigabe oder Lab-Infrastrukturverwaltung. Dieser Eintrag
behauptet keinen ausgeführten Runtime-Test und keine erfolgte Konfigurationsänderung.

### TC-2026-032 / TC-2026-034: Freigegebene Unquoting-, Split-USP- und ZIP-Writer-Folgeslices

| Feld | Wert |
|---|---|
| Referenzen | Vorhandene Kandidaten `TC-2026-032` und `TC-2026-034`; keine neue sequenzielle `AP`-Referenz. |
| Benutzerfreigabe | Nach Besprechung von Zweck, konkreten Verträgen, Alternativen, Risiken und Scope hat der Benutzer am 2026-10-01 die Implementierung der drei einzeln benannten APIs `TVF_UnquoteToken`, `USP_SplitAdvanced` und `USP_CreateZipFromEntries` ausdrücklich freigegeben. Vertragsbasis ist [PR #121](https://github.com/gecompat/SQL_Server_Toolbelt/pull/121) mit `ADVANCED_STRING_SPLIT_PROPOSAL.md` und `ZIP_CREATION_PROPOSAL.md`. Die nachfolgend erhaltenen Vorfreigabebesprechungen sind historisch; dieser Nachtrag aktiviert ausschließlich diese drei Folgeslices. |
| Zweck und Scope | `toolbelt_string.TVF_UnquoteToken` entfernt nur ein gültiges äußeres Paar und dekodiert innere doubled closing Qualifier sowie ausdrücklich aktivierte begrenzte Backslash-Escapes. `toolbelt_string.USP_SplitAdvanced` ist die ResultTable-/Help-Fassade des vorhandenen TVF-Kerns ohne automatisches Unquoting. `toolbelt_archive.USP_CreateZipFromEntries` erzeugt ein begrenztes In-memory-ZIP aus caller-lokalen Entries über einen versionierten Binary-Envelope und einen reinen SAFE-CLR-Writer; Stored als Default, Deflate explizit. |
| Status | Alle drei APIs sind implementiert und im ausgewählten Lab-Scope geprüft. Split/Unquote 1.1.0 ist über [PR #122](https://github.com/gecompat/SQL_Server_Toolbelt/pull/122) integriert; ZIP 1.3.0 steht zum geprüften PR-Merge bereit. Beide Module bleiben `partially validated`, `unreleased`. |
| Dependencies und Grenzen | Kanonischer Split-Kern, bestehendes ZIP-Memory-Modul sowie ResultTable-Runtime für beide USPs; Dependency-Preflight vor Mutation. NULL-/Fehlerpriorität, UTF-16-/BIN2-Semantik, reservierter Außenrand, strikte Namenkodierung, begrenzte Ressourcen und atomare Ausgabe nach PR #121. Numerische Grenzen sind noch technisch zu qualifizieren; keine harte Echtzeit-, Streaming-, Parallelitäts- oder Deflate-Byteidentitätszusage. |
| Tests | Am 2026-10-01 besteht der erweiterte Split-/Unquote-Adapter auf SQL Server 2019 Linux/latest und 2025 Windows/CU8: synthetische Rand-, Fehlerprioritäts-, Grenz-, ResultTable-/Help-, Own-/Callertransaktions-, Local-/Central-, Kollisions- und Uninstall-Fälle sowie clientseitige Metadaten und lokale Minimalrechte. Der echte 1.0-zu-1.1-Upgrade verwendet den gepinnten historischen Installer und Originalsource. ZIP-SAFE-/Memory-/Interoperabilitätsnachweise bleiben getrennt. Kein pauschaler Cross-DB-Minimalrechte- oder vollständiger neuer Matrixnachweis. |
| Ausgeschlossen | XLSX-Reader, Datei-I/O, zusätzliche öffentliche APIs, Rechteausweitung und tatsächliche Veröffentlichung. Der separat freigegebene XLSX-Provider-Spike bleibt davon getrennt; verpflichtender späterer ZIP-Datei-I/O-Slice benötigt weiterhin seinen eigenen Sicherheitsvertrag und eine eigene Funktionsfreigabe. |
| ZIP-Evidenz | Am 2026-10-01: Framework-4.8-Build, unabhängiger ZipArchive-/CRC-/Headercheck und Staticvalidator erfolgreich; tatsächliche Framework-Grenzfixtures mit 32 MiB je Entry, 128 MiB Gesamtpayload, 1024 Entries und 2048 Namenscodeeinheiten. Vollständiger Lab-Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 erfolgreich: local/central, Metadaten, 16-MiB-Stored-/Deflate-Payloads, leere Payloads, Transaktionen, Fehleratomarität, echtes 1.2-Upgrade, Kollisionen und Uninstall. Keine Kapazitätszusage für Produktion, höhere SQL-Live-Grenzen oder beliebige Parallelität. |
| Nächster Schritt | ZIP-Writer nach unabhängigem Review und grüner CI über PR integrieren und gemergte Branches aufräumen. Danach ist diese Implementierungswelle abgeschlossen; weitere Funktionsslices bleiben getrennt. |

### R2a: Regex-Substring und Regex-Replace mit LOB-Profilen

| Feld | Wert |
|---|---|
| ID | `R2a`; Slice zu `TC-2026-010`, keine neue sequenzielle Referenz |
| Zweck und Scope | `toolbelt_string.SVF_RegexSubstring` und `toolbelt_string.SVF_RegexReplace` nach dem konkretisierten Vertrag in `Documentation/Architecture/REGEX_EXTENSION_PROPOSAL.md`: Gesamttreffer, literal Replacement, keine Captures; gemeinsamer SAFE-CLR-Kern; Standard-/Large-Profil; Typ-/Codepage- und LOB-Grenzen. Bestehende R1b-Signaturen bleiben unverändert. |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken und Scope wurden am 2026-10-01 besprochen und in PR #114 konkretisiert. Auf die ausdrücklich benannte Freigabefrage für beide Regex-Funktionen und die Split-TVF antwortete der Benutzer: „ja, entwickle das und mach anschließenden PR-Merge“. Damit sind diese beiden Funktionen einschließlich scopebezogener Tests, gekoppelter Dokumentation und anschließendem geprüften PR-Merge freigegeben. |
| Status | `completed` für freigegebenen R2a-Scope; Version 1.1.0 `validated`, `unreleased` |
| Grenzen | 2-MiB-Standardprofil und 16-MiB-Large-Zielprofil, Pattern 8.000 UTF-16-Codeeinheiten; kooperative Budgets und Patternkomplexität müssen technisch qualifiziert werden. Keine harte Echtzeit-, Streaming-, Parallelitäts- oder Verarbeitung-bis-2-GB-Zusage. Verlustfreie Quellkonvertierung vor zentralem Aufruf; weitere Typwrapper nur bei belegtem Nutzen und abgestimmtem Vertrag. |
| Tests | R1b-Regression, neue NULL-/Start-/Occurrence-/Empty-Match-Semantik, Literal Replacement, Grenzwerte, Gesamtbudget, Ergebnisexpansion, Unicode/Codepages, konkurrierende LOB-Aufrufe, Trust, Upgrade, lokales/zentraltes Deployment und Uninstall. Lab-Matrix nach tatsächlichem Source-/Providerimpact. |
| Nächster Schritt | R2a implementiert und auf SQL Server 2019/2022/2025 Windows/Linux einschließlich echtem 1.0-zu-1.1-Upgrade, Standard-/Large-, Fehler-/Grenz-, Central-/Codepage-, Kollisions-/Rollback-, Parallelaufruf- und Lifecycle-Verträgen erfolgreich geprüft. T-SQL-Fassaden erhalten max-Defaults vor internen SAFE-CLR-Kernen; technischer SQL-CLR-Default-/Collation-Workaround dokumentiert. Keine automatische Freigabe für R2b, neue Captures oder Veröffentlichung. |

### S2: Erweiterter Split als verpflichtende TVF

| Feld | Wert |
|---|---|
| ID | `S2`; Slice zu `TC-2026-032`, keine neue sequenzielle Referenz |
| Zweck und Scope | `toolbelt_string.TVF_SplitAdvanced` nach `Documentation/Architecture/ADVANCED_STRING_SPLIT_PROPOSAL.md`: mehrere Separatorstrings, Quote/Escape, Originaltokens, 1-basierte Ordinals und atomare Geschäftsfehlerzeile statt Teiltokens. |
| Benutzerfreigabe | Nach Vertragsbesprechung und Konkretisierung in PR #114 am 2026-10-01 ausdrücklich mit „ja, entwickle das und mach anschließenden PR-Merge“ freigegeben; die vorangehende Frage benannte `TVF_SplitAdvanced` einzeln neben den zwei Regex-Funktionen. |
| Status | `completed` für freigegebenen S2-Scope; Runtime `partially validated` |
| Grenzen | Pure-T-SQL-TVF; Inline-TVF-Alternative prüfen, MSTVF-Ausnahme technisch begründen. Input 65.536 UTF-16-Codeeinheiten, JSON-Rohtext 16.384, höchstens 16 Separatoren mit je 64 Codeeinheiten als zu validierende Grenzen. Fehlerpriorität, NULL-No-op, Originaltokens und fünf Resultspalten gemäß Vertrag. |
| Tests | Quote/Escape/Longest-Match, JSON-/Konfigurations- und Parserfehler, Fehlerpositionen/-priorität, keine Teiltokens, Ordinals, NULL/Empty/Trailing Spaces, Unicode/Collations, Grenzwerte, CROSS APPLY, lokales/zentraltes Deployment, Wiederholung, Kollision und Uninstall. |
| Nächster Schritt | TVF implementiert; vollständiger Adapter auf physischen SQL Server 2019 Linux und 2025 Linux/Windows erfolgreich. Weitere physische Zielkombinationen bleiben offen. Die GitHub-hosted Linux-Matrix SQL2019/2022/2025 bestand später auf [main](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/37386246931); sie ersetzt keine physische Zielprüfung. Risikobasierte Testauswahl; keine automatische Erweiterung der Testmatrix. Optionale USP, Unquoting, ZIP-Erzeugung, Datei-I/O und tatsächliche Veröffentlichung waren durch diese S2-Freigabe allein nicht autorisiert; spätere Einzelfreigaben stehen getrennt oben. |

### P1a: T-SQL Script Parser und AST-Provider

| Feld | Wert |
|---|---|
| ID | `P1a`; konkretisiert `TC-2026-047`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Einen deterministischen, rein lesenden In-Database-T-SQL-Parser auf Basis von Microsoft ScriptDom (.NET Framework 4.8) als SQL-CLR Table-Valued Functions (TVFs) für AST-Knoten, Knoteneigenschaften, Tokenstrom und Parse-Fehler bereitstellen. |
| Scope | Modul `toolbelt.tsql.script-parser` 1.0.0 mit `TVF_ParseScriptNodes`, `TVF_ParseScriptNodeProperties`, `TVF_TokenizeScript` und `TVF_ParseScriptErrors`. Schema `toolbelt_tsql`, Assembly `Toolbelt_Tsql_ScriptParser`. Keine automatische GUID-Ersetzung und keine semantische Namensauflösung im Kernmodul. |
| Provider | C# .NET Framework 4.8 Assembly mit ScriptDom-Integration, SHA2-512-Trust, kein Datenzugriff (`DataAccessKind.None`), harte Limits für Eingabegröße und Schachtelungstiefe. |
| Priorität | `P1` |
| Status | Historisch 1.0.0 `completed`/`validated`; die am 2026-10-01 separat freigegebene 2.0-Härtung ist `active`/`partially validated`, siehe [Nachfolgervertrag](../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md). |
| Alternativen | Reiner T-SQL-Parser (nicht grammatikvollständig), reiner Tokenizer ohne AST, Stored Procedures mit Temp-Tabellen und externes Parsen außerhalb der Datenbank wurden verworfen. |
| Risiken und Grenzen | Windows-only/UNSAFE; iterativer Wächter vor ScriptDom und empirische Qualifikation sind keine universelle Stack-, Laufzeit- oder Heap-Garantie. Tokenize bleibt ausschließlich lexikalisch; AST-Funktionen parsen je Aufruf ohne veränderlichen Cache. |
| Benutzerfreigabe | Zweck, Signatur, Fehlervertrag, Risiken und Scope wurden am 2026-09-03 besprochen. Der Benutzer hat die Umsetzung anschließend mit „halte den Plan im Repository fest und starte im Anschluss mit der Implementierung“ ausdrücklich freigegeben. |
| Tests | Spike zu ScriptDom-Ladbarkeit, statische Vertragsprüfung, synthetische AST- und Token-Golden-Tests (SELECT, JOIN, CTE, MERGE, DDL, Kommentare, `GO`), Roundtrip-Tokens, Fehlerbehandlung, Lifecycle-, Deployment- und Kollisionstests. |
| Evidenz | `Documentation/Architecture/TSQL_SCRIPT_PARSER_MODULE_DESIGN.md`, `Documentation/Architecture/DECISIONS.md` (`DEC-2026-029`), `Backlog/TOOLBELT_CANDIDATES.md` (`TC-2026-047`). |
| Nächster Schritt | Die frühere 1.0-Abschlussgrenze gilt historisch. Nur die separat freigegebene 2.0-Härtung mit ehrlichen Qualifikationsgrenzen abschließen; weitere APIs benötigen jeweils Freigabe. |
| Nachtrag 2026-10-07 | Nach Besprechung des nicht mehr offiziell verfügbaren bisherigen ScriptDom-Binaries wählte der Benutzer ausdrücklich NuGet `Microsoft.SqlServer.TransactSql.ScriptDom` `180.117.0` zur Umsetzung und Qualifikation und beauftragte die Prüfung sowie Behandlung aller betroffenen CLR-Objekte. Der Scope umfasst den Parser, den gefundenen `toolbelt.metadata.table-clone`-Trigger-Opt-in-Consumer und die erneute Qualifikation; keine automatische Trustregistrierung oder Änderung von SQL-Server-Sicherheitskonfiguration. Siehe [Hardening-Vertrag](../Documentation/Architecture/TSQL_SCRIPT_PARSER_HARDENING_CONTRACT.md). |

### V0a/V0b/V0c: Releasevalidierung und erste Releasekohorte

| Feld | Wert |
|---|---|
| ID | `V0a`, `V0b`, `V0c`; keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Die vorhandenen Module auf physischen Zielversionen und Windows validieren und daraus eine veröffentlichungsfertige erste Kohorte bilden, ohne Runtime- oder Release-Status vorwegzunehmen. |
| Scope | `V0a`: 24 portable beziehungsweise Linux-fähige Module auf SQL Server 2019/2022/2025 Linux. `V0b`: vollständige Windows-Matrix der V0c-Kohorte plus Hochrisikofälle für ResultTable, SQL CLR, Datei-I/O, Second Session und Event Log. `V0c`: 16 portable Module aus Kernfolge, W1, W2a, W2b-A und W2c. Keine neuen öffentlichen SQL-Objekte oder Signaturänderungen. |
| Dependencies | Ausdrückliche V0-Freigabe vom 2026-08-28 und Einzelzielfreigabe vom 2026-08-29; schema-valider SQL_Server_Lab-Vertrag; entweder `groupStatus = READY` oder explizit ausgewählte Einzelziele mit `runtimeStatus = READY` und zulässigem Eintragsstatus; vorhandene Modul-, Lifecycle- und Testverträge. |
| Priorität | `P0` |
| Status | `active`; autonom ausführbare V0a-/V0b-Matrix abgeschlossen; sieben externe oder manuelle Rest-Gates bleiben offen |
| Implementation Status | 30 Module `implemented` – aus `module.yaml` abgeleitet |
| Validation Status | 22 Module `validated`, 8 Module `partially validated`; die vollständige Windows-/Linux-Matrix ist für 22 Module belegt. Bei Result Table, Base64, Generate Series, Console Message, File Content, ZIP Memory und Windows Filesystem bleiben ausdrücklich abgegrenzte Performance-, Client-/Treiber-, Fixture-, Interoperabilitäts- oder manuelle Sicherheitsfälle offen. Das neue S2-Modul Split Advanced ist zusätzlich nur im ausdrücklich risikobasiert ausgewählten Scope geprüft; weitere Zielkombinationen und niedrigprivilegierte Cross-DB-Aufrufe sind nicht ausgeführt. |
| Release Status | 30 Module `unreleased`; V0c, D1, E1a, E1b, R1b und W6d autorisieren keine tatsächliche Veröffentlichung. |
| Akzeptanzkriterien | Linux- und Windows-Zielversionen tatsächlich geprüft; Dependency-Closure und versionierte Objektmanifeste konsistent; Erst-, Wiederholungs-, Upgrade-, Central- und Uninstall-Verträge für die Kohorte erfolgreich; modulspezifische Pflichtfälle ausgeführt; nicht verfügbare Kombinationen sichtbar; vollständiger Dokumentationsaudit erfolgreich. |
| Tests | `Tests/CI/run-lab-local.ps1` mit `TestSuite=full`; getrennte synthetische File-Content-Fixtures; vorhandene manuelle Windows-Pläne für ResultTable, Windows Filesystem und ZIP Memory; vollständiger Dokumentations- und Datenschutzcheck. |
| Blocker | Kein Gruppenblocker für einzeln bereite Linux- oder Windows-Ziele. Die automatisierte Matrix ist vollständig grün. Offen bleiben ausschließlich die sieben modulspezifisch dokumentierten Performance-, Client-/Treiber-, Fixture-, Interoperabilitäts- oder manuellen Sicherheitsgates. Das Projekt darf die Lab-Ressourcen nicht selbst starten oder reparieren. |
| Evidenz | V0-Freigabe vom 2026-08-28 und Einzelzielfreigabe vom 2026-08-29; am 2026-09-01 bestanden alle automatisierten Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest. W1-Collations/URI-Large-Input, W2a-Kollisionen/Bucket-Workload, W2b-Kollision, eingeschränkte Metadata Visibility sowie der korrigierte W5-Providervertrag sind eingeschlossen. Es werden keine Hosts, Credentials, konkreten Datenbanknamen, Laufzeiten oder vollständigen Logs übernommen. |
| Nächster Schritt | Die sieben nicht autonom schließbaren Rest-Gates getrennt bearbeiten, sobald externe Fixtures, manuelle Sicherheitskontexte, Vergleichsbaselines oder Releaseentscheidungen vorliegen. Der Benutzer hat am 2026-09-19 ein Stabilitäts-Gate für den bestehenden Generate-Series-Performancevergleich freigegeben: Instabile Batch-Mediane werden ohne Messwertpersistenz als nicht ausgeführt klassifiziert und führen weder zu einem Erfolgsnachweis noch zu einer Statusaufwertung. Die ebenfalls ausdrücklich freigegebenen Stabilitäts-Gates für ResultTable und Base64 sind über [PR #108](https://github.com/gecompat/SQL_Server_Toolbelt/pull/108) gemergt: drei Batches mit je Warm-up und fünf Samples, standardmäßig höchstens 20 % Batch-Median-Varianz; Instabilität führt zu `NOT_EXECUTED` mit `PERFORMANCE_STABILITY_UNAVAILABLE`. Baseline `0` deaktiviert ausschließlich den Regressionsvergleich. Die Gates verhindern ungesicherte Aufwertungen, begründen selbst aber keine Aufwertung; Messwerte werden nicht persistiert. Eine tatsächliche Veröffentlichung bleibt ohne ausdrückliche Autorisierung ausgeschlossen. |

Die V0c-Kohorte umfasst verbindlich:

`toolbelt.core.result-table`, `toolbelt.conversion.base64`,
`toolbelt.core.generate-series`, `toolbelt.metadata.identifier`,
`toolbelt.string.split-characters`, `toolbelt.validation.semantic-version`,
`toolbelt.conversion.integer-base`, `toolbelt.datetime.calendar-difference`,
`toolbelt.string.directional-trim`, `toolbelt.conversion.uri-component`,
`toolbelt.datetime.truncate`, `toolbelt.datetime.bucket`,
`toolbelt.binary.bit-operations`, `toolbelt.json.path-exists`,
`toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog`.

### ADP-008: SQL_Server_Lab Project-Adapter-Pilot

| Feld | Wert |
|---|---|
| ID | `ADP-008`; externer Pilot aus dem kanonischen Backlog von `SQL_Server_Lab`, keine neue sequenzielle `AP`-Referenz |
| Ziel | Ein vorhandenes versioniertes Toolbelt-Modul über den Project-Adapter-Vertrag 0.1 auf einem isolierten SQL-Server-2025-Container-Lab installieren, aktualisieren, validieren und deinstallieren. |
| Scope | `toolbelt.core.console-message` 1.0.0; fünf reine T-SQL-Entrypoints; markergebundene synthetische Datenbank; deterministische Ableitung aus kanonischem Deploy, Source und Uninstall. Keine neue öffentliche SQL-API, keine Providerlogik und keine Verwaltung von Lab-Infrastruktur im Toolbelt-Repository. |
| Status | `completed` für den deklarierten Pilot-Scope |
| Alternativen | Ein neues Pilotmodul würde unnötig einen öffentlichen Vertrag erzeugen; kopierte, unabhängig gepflegte SQL-Dateien würden vom Moduldeployment abdriften; ein im Toolbelt gestarteter Lab-Run würde die Repository-Grenze verletzen. |
| Risiken und Grenzen | Das Update ist ein versionsgleiches idempotentes Redeployment, weil für Version 1.0.0 kein historischer Upgradepfad existiert. Der Pilot belegt nur SQL Server 2025 Linux unter Docker und Podman und ändert den Modulstatus nicht. |
| Benutzerfreigabe | Der Benutzer hat am 2026-08-30 den autonomen Abschluss der offenen Backlogpunkte, die Verwendung des vorhandenen Podman-Providers und das Überführen jedes konsistenten Blocks auf `origin/main` ausdrücklich beauftragt. |
| Tests | Statischer Modul-/Generatorvertrag und Schema-/Resolverprüfung durch `SQL_Server_Lab`; echte getrennte SQL-Server-2025-Linux-Läufe unter Docker und Podman jeweils mit Install, Update, Validate, Adapter-Cleanup und anschließendem scopegebundenem Infrastruktur-Cleanup erfolgreich. |
| Evidenz | `Modules/toolbelt.core.console-message/TestLab/ProjectAdapter/`; ausschließlich synthetische Daten und abstrahierte Ergebnisse, ohne Credentials, Ports, Run-IDs, Laufzeiten oder vollständige Runtime-Logs. |
| Nächster Schritt | Pilotvertrag 0.1 stabil halten. Weitere Module, historische Upgradepfade oder ein breiterer Plattformscope benötigen einen eigenen begründeten Slice. |

### Q1: Migration-Idempotency-Verifier V1

| Feld | Wert |
|---|---|
| ID | `Q1`; konkretisiert `RI-2026-142`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Wiederholungsdeployment und wiederholtes Uninstall anhand des effektiven SQL-Katalogzustands prüfen, ohne eine öffentliche Runtime-Capability zu installieren. |
| Scope | Repository-interner SQLCMD-Verifier für eine isolierte synthetische Datenbank und ein dependency-freies, zustandsloses T-SQL-Modul. V1 vergleicht Schemas, Objekte, Definitionen, Spalten, Parameter, Toolbelt-Properties und Berechtigungen; zwei unabhängige Uninstall-Sitzungen und eine Restzustandsprüfung schließen den Lauf ab. Referenzmodul ist `toolbelt.core.generate-series`. |
| Priorität | `P1`; als einzelner Qualitäts-Enabler parallel zu V0 zulässig |
| Status | `completed` für den deklarierten V1-Scope |
| Alternativen | Vorhandene Lifecycle-Tests allein erkennen keine stille Katalogdrift; Source-Hashes bilden nicht den gesamten effektiven Katalog ab; ein dauerhaft installiertes Verifier-Modul würde den Prüfzustand selbst verändern. |
| Risiken und Grenzen | V1 unterstützt keine Tabellen, Assemblies, persistente Zustandsdaten, Dependency-Installation, historischen Upgradepfade, Central-Consumer oder parallele Migrationen. Abweichende Database-/Catalog-Collations bleiben ein eigener Lifecycle-Scope. |
| Tests | Statischer Contract, vollständiger Dokumentationsaudit und tatsächliche Q1-Runtime am 2026-08-29 auf SQL Server 2019, 2022 und 2025 jeweils unter Linux und Windows erfolgreich. Jeder Zieltest bestand erst nach Wiederholungsdeployment ohne Katalogdrift, zweimaligem Uninstall, leerer Restzustandsprüfung und erfolgreichem Entfernen seiner synthetischen Testdatenbank. |
| Evidenz | `Documentation/Architecture/MIGRATION_IDEMPOTENCY_VERIFIER_DESIGN.md`, `Tests/Quality/MigrationIdempotency/`, `Tests/CI/run-q1-migration-idempotency.sh` und `.github/workflows/q1-migration-idempotency.yml`; lokale SQL_Server_Lab-Matrix mit ausschließlich abstrahierter Evidenz. Keine Hosts, Credentials, Datenbanknamen, konkreten Buildnummern, Laufzeiten oder vollständigen Logs übernommen. |
| Nächster Schritt | Q1 V1 stabil halten. Tabellen-/Zustands-, Upgrade-, Central- und Parallelitäts-Slices nur bei eigenem nachgewiesenem Bedarf erweitern; Golden Snapshots und Contract-Test-Generierung bleiben zurückgestellt. |

### D1: Date Spine V1

| Feld | Wert |
|---|---|
| ID | `D1`; keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Einen kleinen portablen relationalen Date-Spine-Vertrag als nächste neue Nutzerfunktion bereitstellen. `Q1` bleibt ein Qualitäts-Enabler und ist keine nutzerorientierte SQL-Capability. |
| Scope | Drei öffentliche Inline TVFs für Tag, ISO-Woche und Monat. Der Bereich ist `[RangeStart, RangeEndExclusive)`; geliefert werden alle geschnittenen Perioden mit `Ordinal int` und `PeriodStart date`. `NULL`, leere und umgekehrte Bereiche liefern keine Zeilen. Keine Feiertage, Arbeitstage, Zeitzonen, DST, Locale-Texte, Geschäfts- oder Fiskalkalender und keine persistente Kalenderdimension. |
| Dependencies | `RI-2026-079`; `toolbelt.core.generate-series` 1.0.0 und `toolbelt.datetime.truncate` 1.0.0 in derselben Datenbank. Datetime Bucket ist ausdrücklich keine künstliche Dependency. |
| Priorität | `P1` nach `V0a`/`V0b`/`V0c`; parallel höchstens ein `Q1`-Qualitäts-Enabler |
| Status | `implemented`; Runtime `validated`, Release `unreleased` |
| Alternativen | Eine öffentliche Grain-Parameterfunktion, eine USP, nur vollständig enthaltene Perioden und eine persistente Kalenderdimension wurden für V1 verworfen. Quartal, frei wählbarer Schritt, Periodenende und abgeleitete Kalenderattribute bleiben mögliche getrennte Erweiterungen. |
| Risiken und Grenzen | Ergebnisgröße wächst linear; ohne `ORDER BY` keine Reihenfolgegarantie; ISO-Woche ist bewusst Montag-basiert und `DATEFIRST`-unabhängig; der maximale Kalendertag kann mangels darstellbarer Exklusivgrenze nach `9999-12-31` nicht eingeschlossen werden. |
| Benutzerfreigabe | Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope wurden am 2026-08-30 besprochen. Der Benutzer hat die Umsetzung anschließend mit „lass es uns so machen“ ausdrücklich freigegeben. |
| Tests | Statischer Vertrag sowie die vollständigen lokalen, zentralen, Lifecycle-, Dependency-, Kollisions-, Grenz-, `DATEFIRST`- und Skalierungsadapter waren am 2026-09-01 auf physischen SQL-Server-2019-/2022-/2025-Zielen unter Windows base und Linux latest erfolgreich. Alle erzeugten synthetischen Datenbanken wurden entfernt, Lab-Systeme wurden nicht beendet. |
| Nächster Schritt | PR #61 ist gemergt; das Modul ist `validated`. `release_status` bleibt bis zu einer ausdrücklich autorisierten Veröffentlichung `unreleased`. |

### R1a: Regex-Semantik- und Provider-Spike

| Feld | Wert |
|---|---|
| ID | `R1a`; konkretisiert `TC-2026-010`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Die native SQL-Server-2025-RE2-Semantik für einen möglichen ersten Slice aus `LIKE`, `INSTR` und `COUNT` gegen portable Provideroptionen prüfen, ohne eine Runtime-API zu implementieren. |
| Scope | Native 2025-Semantik und Compatibility-Level-Verfügbarkeit; .NET-Framework-4.8-Vergleich; RE2-/CLR-/Linux-, Lizenz-, Wartungs- und Dependency-Gates. Replace, Substring, Split, Matches, Fuzzy Matching und jedes öffentliche SQL-Objekt bleiben außerhalb. |
| Priorität | `P1` Research nach D1; blockiert keine fachlich unabhängige Welle |
| Status | `completed` für den Research-Scope; der getrennt freigegebene R1b-Slice ist inzwischen implementiert |
| Ergebnis | SQL Server 2025 ist die kanonische RE2-Referenz. `REGEXP_INSTR` und `REGEXP_COUNT` liefen unter Compatibility 150/160/170, `REGEXP_LIKE` nur unter 170. Der eingebaute .NET-Framework-Regexkern weicht semantisch ab und besitzt keine lineare Laufzeitgarantie. Native RE2-Wrapper benötigen plattformspezifischen nativen Code und sind mit `SAFE`/SQL Server Linux unvereinbar. Kein portabler Paritätsprovider wurde ausgewählt oder aufgenommen. |
| Alternativen | Exakter externer/native RE2-Provider; ausdrücklich engerer Toolbelt-Dialekt mit Parser, Transformationen und Timeout; reine SQL-Server-2025-Fassade. Reines T-SQL ist kein allgemeiner Regex-Provider. |
| Risiken und Grenzen | Eine bloße Pattern-Blacklist erzeugt keine RE2-Parität. Zeichenklassen, Anker, Flags, ungültige Konstrukte, Input-/Patternlimits, Timeoutfehler, ReDoS und Providerdeployment benötigen je nach Richtung einen neuen öffentlichen Vertrag. |
| Tests | Physischer SQL-Server-2025-Linux-Lauf mit Compatibility 150/160/170 und synthetischen Semantik-/Fehlervektoren am 2026-08-30 erfolgreich; .NET-Framework-4.8-Harness bestätigte die erwarteten Abweichungen. Die synthetische Datenbank und temporären Buildartefakte wurden entfernt; Windows-SQL-Runtime blieb `not executed`; Lab-Systeme wurden nicht beendet. |
| Evidenz | `Documentation/Research/REGEX_SEMANTICS_PROVIDER_SPIKE.md`, `Tests/Research/Regex/` und `.github/workflows/regex-provider-spike.yml`. Keine Drittanbieterbibliothek oder Binärdatei wurde heruntergeladen oder aufgenommen. |
| Nächster Schritt | R1b ist als eigener enger Toolbelt-Dialekt umgesetzt. Weitere Regex-APIs oder RE2-Parität benötigen neue Verträge und Freigaben. |

### R1b: Begrenzter Regex-Runtime-Slice

| Feld | Wert |
|---|---|
| ID | `R1b`; konkretisiert `TC-2026-010`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Portable Regex-Prüfung, Positionssuche und Zählung für SQL Server 2019, 2022 und 2025 mit bewusst kleiner, stabil dokumentierter Semantik. |
| Scope | `toolbelt.string.regex` 1.0.0 mit `SVF_RegexIsMatch`, `SVF_RegexInstr`, `SVF_RegexCount`; eigener Dialektparser, UTF-16-Positionen, ASCII-Kurzklassen, `\p{L}`, Flags `c/i/m/s`, 2-MiB-/8.000-Byte-/1.000-Quantifier-Grenzen und fixer 250-ms-Timeout. |
| Provider | Eine .NET-Framework-4.8-Assembly mit `SAFE`, direkten Referenzen nur auf System/System.Data und exaktem SHA2-512-Trust; keine Drittanbieter-/Native-Abhängigkeit, kein TRUSTWORTHY und keine automatische CLR-Konfiguration. |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Alternativen | Exakter RE2-/Native-Provider, SQL-Server-2025-Fassade und reines T-SQL wurden für R1b verworfen. |
| Risiken und Grenzen | Keine RE2-Parität oder lineare Laufzeit, SARGability oder Parallelplanzusage. Backtracking bleibt trotz Parser und Timeout möglich. Replace, Substring, Captures, Split und Matches sind ausgeschlossen. |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken, Scope und Reihenfolge wurden am 2026-08-30 besprochen. Der Benutzer hat anschließend „E1b und R1b wie besprochen implementieren“ ausdrücklich freigegeben. |
| Evidenz | `Documentation/Architecture/REGEX_MODULE_DESIGN.md`, Modulvertrag und synthetischer Adapter; vollständige physische Matrix SQL Server 2019/2022/2025 unter Windows base und Linux latest. |
| Nächster Schritt | PR #65 ist gemergt; den freigegebenen V1-Scope stabil halten. Weitere Regex-APIs und die tatsächliche Veröffentlichung bleiben unautorisiert. |

### E1a: Work Queue Claim/Complete/Fail

| Feld | Wert |
|---|---|
| ID | `E1a`; konkretisiert `TC-2026-015`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Einen kleinen persistenten Queue-Kern bereitstellen, der ausschließlich registrierte Work Types einreiht, atomar beansprucht und tokengebunden terminal abschließt. |
| Scope | `toolbelt.core.work-queue` 1.0.0 mit `USP_EnqueueWork`, `USP_ClaimWork`, `USP_CompleteWork`, `USP_FailWork`, `USP_GetWorkStatus` und `VW_WorkQueue`. Zustände `QUEUED -> CLAIMED -> COMPLETED|FAILED`; Payload nur NONE oder JSON-Objekt bis 64 KiB; Statusoberflächen ohne Payload und ClaimToken. |
| Dependencies | `toolbelt.core.result-table` 1.0.0 und `toolbelt.core.work-type` 1.1.0 in derselben Datenbank; persistente Namenskonvention aus `DEC-2026-025`. |
| Priorität | `P1` nach D1 und R1a, als eigenständiger vertikaler Slice |
| Status | `implemented`; Runtime `partially validated`, Release `unreleased` |
| Alternativen | Service Broker, SQL Server Agent und externe Worker wurden nicht an E1a gekoppelt. Raw SQL oder Handlernamen in Payloads, öffentliche Claim-Token in Statusoberflächen und ein gemeinsamer Lease-/Retry-/Cancellation-Vertrag wurden verworfen. |
| Risiken und Grenzen | Keine Lease, Recovery, Retry, Dead Letter, Idempotency Key, Cancellation, Resultpersistenz oder automatische Ausführung. Ein Worker-Abbruch nach Claim lässt das Item dauerhaft `CLAIMED`; keine Exactly-once- oder absolute Fairnesszusage. |
| Benutzerfreigabe | Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope wurden am 2026-08-30 besprochen. Der Benutzer hat die Umsetzung anschließend mit „lass es uns so machen“ ausdrücklich nach D1 und R1a freigegeben. |
| Tests | Statischer Vertrag sowie E1a-Semantik, Caller-Transaktionen, vier echte Claim-Sessions, ResultTable, Dependency-/Kollisionspreflight, Redeployment, Central, Datenverlustschutz, Uninstall und Cleanup waren am 2026-08-30 auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. Die drei Windows-Base-Ziele waren bereits beim SQL-Anmeldungs-Preflight nicht erreichbar; Windows blieb `not executed`. |
| Evidenz | `Documentation/Architecture/WORK_QUEUE_MODULE_DESIGN.md`, `Modules/toolbelt.core.work-queue/` und `.github/workflows/work-queue-runtime.yml`; ausschließlich synthetische Daten und abstrahierte Evidenz. |
| Nächster Schritt | E1b ist als Version 1.1.0 implementiert, validiert und über PR #64 gemergt. E1c Retry/Dead Letter/Idempotenz bleibt ohne eigene Freigabe offen. |

### E1b: Work Queue Lease/Heartbeat/Orphan Recovery

| Feld | Wert |
|---|---|
| ID | `E1b`; konkretisiert `TC-2026-015` und `TC-2026-021`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Dauerhaft blockierte Claims durch eine begrenzte Lease erkennbar machen und ausschließlich über eine explizite Recovery wieder freigeben. |
| Scope | `toolbelt.core.work-queue` 1.1.0; Claim-Lease 5 bis 86400 Sekunden, monotone ClaimGeneration, `USP_RenewWorkLease`, `USP_RecoverExpiredWork`, aktive-Lease-Prüfung in Complete/Fail sowie geschützte Lease-/Recovery-Statusfelder. |
| Migration | Unterstütztes Upgrade `1.0.0 → 1.1.0`; aktive E1a-Claims blockieren vor jeder Mutation. QUEUED- und terminale Daten bleiben erhalten. |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Alternativen | Persistenter ORPHANED-Status, implizite Recovery im Claim, SessionId als Ownership, globale unbegrenzte Lease, automatische Supervisor-Ausführung und `KILL` wurden verworfen. |
| Risiken und Grenzen | Recovery kann bereits erfolgte fachliche Seiteneffekte wiederholen. Keine Exactly-once-Garantie, generische Idempotenz, Retry, Dead Letter, Cancellation, Attempt-Historie oder Worker-Orchestrierung. |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken, Scope und Reihenfolge wurden am 2026-08-30 besprochen. Der Benutzer hat anschließend „E1b und R1b wie besprochen implementieren“ ausdrücklich freigegeben. |
| Evidenz | `Documentation/Architecture/WORK_QUEUE_MODULE_DESIGN.md`, Modulvertrag und synthetischer Runtime-/Upgrade-Adapter; vollständige physische Matrix SQL Server 2019/2022/2025 unter Windows base und Linux latest erfolgreich. |
| Nächster Schritt | PR #64 ist gemergt; den freigegebenen V1.1.0-Scope stabil halten. E1c Retry/Dead Letter/Idempotenz und die priorisierten Gruppen-Barriers aus `TC-2026-048` sind als Work Queue v2 umgesetzt. E1d bleibt eine getrennte W6d-Welle; die tatsächliche Veröffentlichung bleibt unautorisiert. |

### W6c: Work Queue v2 – Retry, Idempotenz und priorisierte Gruppen-Barriers

| Feld | Wert |
|---|---|
| ID | `W6c`; konkretisiert `TC-2026-020` und `TC-2026-048`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Work Queue 2.0.0 um expliziten Retry mit Backoff, Dead Letter, Idempotenz und priorisierte gruppenbezogene Drain-Barriers erweitern. |
| Scope | Neue Enqueue-Policy- und Barrier-USPs, Retry-/Dead-Letter-USPs, erweiterte Claim-/Statusoberflächen, persistente Retry- und Barrier-Metadaten, Upgrade von 1.0.0/1.1.0, Dokumentation und betroffene Tests. Keine Cancellation, Worker-Provider, Raw SQL, Systemzustandserkennung oder automatische Log-Shrink-Operation. |
| Priorität | `P1`; nach E1b, vor E1d und allen Host-Providern |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken und Scope wurden am 2026-09-10 besprochen. Der Benutzer hat anschließend mit „freigabe“ und dem ausdrücklichen Implementierungsauftrag die Umsetzung freigegeben. |
| Kernvertrag | Priority `0..255`, Gruppe pro Auftrag, `DRAIN_BARRIER` mit exaktem Snapshot aktiver Claim-Generationen, parallele gleichpriorisierte Barriers, Retry ohne Jitter und `RETRY_WAIT`, Dead Letter sowie Idempotenz je Work Type und Key. |
| Risiken und Grenzen | Barriers können eine Gruppe bewusst anhalten; deshalb ist ihre Enqueue-Procedure getrennt berechtigt. Lease-Ablauf beendet keinen Snapshot-Blocker. Idempotenz garantiert keine fachliche Exactly-once-Ausführung. |
| Tests | Statischer Vertrag und GitHub Actions Work-Queue Runtime #34533724721 am 2026-09-10 erfolgreich auf synthetischen SQL Server 2019/2022/2025 Linux sowie lokaler SQL_Server_Lab-Adapter am 2026-09-11 erfolgreich auf bereiten Windows-2019-, 2022- und 2025-Zielen: öffentlicher Vertrag, Retry/Dead Letter, Idempotenz, Barriers, Parallelität, Upgrade und Lifecycle. CU ist für diesen nicht patchgebundenen Vertrag irrelevant. |
| Nächster Schritt | Den validierten W6c-Scope stabil halten. W6d ist als getrennte kooperative Cancellation-Welle freigegeben. |

### W6d: Kooperative Execution-Cancellation

| Feld | Wert |
|---|---|
| ID | `W6d`; konkretisiert `TC-2026-018` |
| Ziel | Eine irreversible, persistierte Cancellation-Anforderung pro `ExecutionId` bereitstellen, die Worker an eigenen Checkpoints auswerten können. |
| Scope | Neues Modul `toolbelt.core.execution-cancel` 1.0.0 mit interner Persistenz, Status-TVF, Skalurfunktion, Anforderungs-USP, Lifecycle, Central-Deployment und gezielten Contract-Tests. Die Anforderung akzeptiert keine aktive Caller-Transaktion. |
| Priorität | `P1`; nach W6c, vor Provider- oder Host-Abbrüchen |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken und Scope wurden im Architekturdesign festgehalten. Der Benutzer hat am 2026-09-11 mit „do it“ die Implementierung ausdrücklich freigegeben. |
| Kernvertrag | Wiederholte Anforderung ist idempotent und behält die erste Auditzeit. Öffentlicher Status enthält nur ExecutionId, Flag und UTC-Zeit. Worker entscheiden über terminalen oder retryfähigen Ausgang selbst. |
| Risiken und Grenzen | Kein `KILL`, keine Sessionbeendigung, keine Transaktionsrücknahme, keine automatische Work-Queue-Mutation und keine Garantie für nicht kooperierende Provider. Die Checkpoint-Frequenz ist Work-Type-Vertrag. |
| Tests | Öffentlicher Vertrag, Idempotenz, Context-Auflösung, Caller-Transaktion, Parallelität, Lifecycle, Central und Uninstall sowie die betroffene lokale SQL_Server_Lab-Matrix. CU ist nicht patchgebunden. |
| Evidenz | Am 2026-09-11 erfolgreich: Statischer Vertrag sowie lokaler SQL_Server_Lab-Adapter für SQL Server 2019, 2022 und 2025 unter Linux und Windows mit öffentlichem Vertrag, Idempotenz, Transaktionsschutz, Parallelität, Lifecycle, Central und Uninstall. CU ist für diesen nicht patchgebundenen Vertrag irrelevant. |
| Nächster Schritt | Den validierten W6d-Scope stabil halten; Queue-Mutation, `KILL` und Provider-Abbrüche bleiben getrennte Slices. |

### AP-2026-003: ResultTable-Kernmodul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-003` |
| Ziel | Das implementierungsreif spezifizierte Modul `toolbelt.core.result-table` vollständig implementieren, dokumentieren, installieren, deinstallieren und auf den verfügbaren Zielplattformen validieren. |
| Scope | `toolbelt.core.result-table`; Modulverzeichnis, `module.yaml`, `toolbelt_core.USP_PrepareResultTable`, parametergesteuertes Deploy- und Uninstall-Skript, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Runtime-, Collation-, Deployment- und Plattformtests. |
| Dependencies | `AP-2026-002`, `RESULT_TABLE_MODULE_DESIGN.md`, `RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017` und `DEC-2026-019`. |
| Priorität | `P0` |
| Status | `active`; fachlich abgeschlossen und Windows-Nachweis vorhanden; offen ist ausschließlich die vergleichbare plattformübergreifende Performance-Baseline, die über `V0` geführt wird |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Exakt ein persistentes SQL-Objekt in Version `1.0.0`; öffentliche Signatur und Help-Vertrag vollständig; `@LikeTable`-Schemaquelle, `@KeepData`-Matrix, Preflight, in-place-Umbau, Savepoint- und Fehlervertrag implementiert; lokale und zentrale Installation; kontrolliert wiederholbare Lifecycle-Skripte; keine nicht freigegebenen weiteren persistenten Objekttypen; Dokumentation und Manifest konsistent; alle verfügbaren Pflichtprüfungen ausgeführt und nicht verfügbare Prüfungen ehrlich ausgewiesen. |
| Tests | Statischer Vertrag und vollständige Windows-/Linux-Matrix auf SQL Server 2019, 2022 und 2025 einschließlich Collation-, 1024-Spalten-, Transaktions-, natürlichem Savepoint-Enginefehler 2705, Multi-Session-, Central-/Lifecycle- und synthetischem Performance-Workload erfolgreich. |
| Blocker | Kein Merge-Blocker für den implementierten und teilweise validierten Stand. Für `validated` fehlt eine vergleichbare plattformübergreifende Performance-Baseline. |
| Evidenz | Benutzerfreigabe vom 2026-07-29; kanonische Artefakte unter `Modules/toolbelt.core.result-table/`; [Basislauf 30447442638](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30447442638), [erweiterter Lauf 30456207934](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30456207934), [Multi-Session-Lauf 30459004717](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) und [Savepoint-Enginefehler-Lauf 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855) erfolgreich. |
| Nächster Schritt | Die vorhandene Performancebasis je Ziel flüchtig gegen `Performance.Workload.sql` vergleichen; Default ist höchstens 20 % Median-Regression und der Wert ist je Lauf steuerbar. Erst nach vollständiger Pflichtmatrix auf `validated` setzen. |


### AP-2026-023: Windows Filesystem SQL CLR

| Feld | Wert |
|---|---|
| ID | AP-2026-023 |
| Ziel | Windows-only Dateisystemzugriff als kontrolliertes SQL-CLR-Modul für Text/Binary, Codepages, Transcoding, Directory-Verwaltung und begrenztes rekursives Löschen implementieren. |
| Scope | toolbelt.filesystem.windows, C#-.NET-Framework-4.8-Assembly, T-SQL-Fassade, Root-Alias-Konfiguration, Trust-/Deployment-Lifecycle, Dokumentation, Contract-Matrix und Windows-Build. |
| Dependencies | toolbelt.core.result-table; separate administrative SHA2-512-Trust-Freigabe; Windows SQL Server mit kontrolliertem synthetischem Testroot. |
| Priorität | P1 |
| Status | `active`; fachlich abgeschlossen, offen ist ausschließlich der Windows-Nachweis, der über `V0b` geführt wird |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Caller ist Default und wird bei SQL Authentication abgelehnt; ServiceAccount ist explizit; absolute Pfade und Reparse Points sind gesperrt; I/O arbeitet begrenzt/gestreamt; Write nutzt atomare Staging-Dateien; rekursives Delete besitzt Tiefe-/Eintragslimits; Linux ist korrekt not applicable. |
| Tests | Statischer Vertragscheck und GitHub-Windows-Build; manueller Windows-SQL-Server-/NTFS-Test für Deployment, beide Identitätsmodi, Codepages, Limits, Reparse Points, atomare Writes und rekursives Delete. |
| Blocker | Der ausgewählte Caller-/NTFS-/ServiceAccount-Lauf ist belegt; direkte CLR-/RunAs-, weitere Codepage-/Limit-/Reparse-/Delete-Fälle und Race-Beobachtung bleiben offen. Keine vollständige Matrix- oder ZIP-Dateizugriffsqualifikation. |
| Evidenz | Benutzerfreigabe am 2026-07-31; Implementierung und Windows-Build-/Static-Contract-Artefakte auf `main`; Build-Nachweis im Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356. |
| Nächster Schritt | Den unabhängig geprüften Lauf vom 2026-10-04 mit 16 erfolgreichen Pflichtfällen und einem `NOT_OBSERVED`-Race-Fall als begrenzte Evidenz führen; verbleibende Fälle gemäß `Modules/toolbelt.filesystem.windows/Tests/Manual_Windows_Runtime_Testplan.md` scopebezogen prüfen. Eigene Fixture-ACLs/Attribute und DB/Root/Trust wurden wiederhergestellt, separate frische Prüfung erfolgreich. Private Runtimeausgaben bleiben außerhalb des Repositorys. |


Wartung 2026-10-07 (Codex), innerhalb des bestehenden `AP-2026-023`:
Der Security-Cloud-Befund zur nicht durchgesetzten Delete-Tiefengrenze wird
als Korrektur des vorhandenen Vertrags behandelt. Ein vollständiger
begrenzter Prüfplan geht jeder Löschung voraus; danach werden ausschließlich
geprüfte Einträge und Directories nichtrekursiv gelöscht. Keine neue SQL-
Funktion, Identität, Rechtevergabe, Trustregistrierung oder Labausweitung.
Der autonome Wartungsauftrag deckt die Vertragskorrektur ab. Neue begrenzte
Frameworkfälle werden erst nach tatsächlicher Ausführung als erfolgreich
geführt; Windows-SQL-, Caller-/NTFS-/Reparse-/Race- und Releasequalifikation
bleiben gesonderte Gates. Historische Nachweise gelten für ihren damaligen Source.

## Besprochene Folgescopes ohne Implementierungsfreigabe

Die Vorfreigabebesprechungen zu `TC-2026-032` und `TC-2026-034` bleiben
nachfolgend historisch sichtbar. Ihr damaliger Freigabestatus wird durch den
aktuellen aktiven Nachtrag vom 2026-10-01 oben ersetzt; die übrigen
Folgescopes sind dadurch nicht freigegeben.

### TC-2026-032: Unquoting und optionale Split-USP

Am 2026-10-01 hat der Benutzer Unquoting auf einen äußerlich gequoteten Token
begrenzt und anschließend präzisiert: Das äußere Paar wird entfernt, innere
verdoppelte Quotes werden dekodiert; `"hallo""du"""` wird `hallo"du"`.
Die zuvor angenommene unveränderte Innenbehandlung wurde damit korrigiert.
Nachtrag 2026-10-01: Expliziter Qualifier verlangt passende Delimiter an
beiden Rändern, sonst Fehler; verschiedene öffnende/schließende Delimiter
sind zulässig. `[` oder `]` wählt `[]`. Automatische Erkennung lässt
unvollständige apparent Quotation wie `“Hallo` unverändert; verdoppelte
schließende Qualifier werden nur im vollständig außen gequoteten Inneren
aufgelöst. Keine globale Quoteentfernung/Normalisierung. Zu diesem
historischen Stand waren Auto-Kandidatenliste und malformed Innenbehandlung
noch offen; die nachfolgende Bestätigung ersetzt diese offenen Punkte.
Die Präzisierung ersetzt die zuvor offenen Randregeln.
Weitere Präzisierung 2026-10-01: Ein zusätzlicher Backslash-Escape-Modus
benötigt einen expliziten Opt-in-Parameter; ohne Opt-in bleibt Backslash
literal. Doubled closing Qualifier bleiben getrennte Quoting-Semantik,
kein impliziter globaler Escape-Modus. Die damals offene Dekodierung wird
nachfolgend konkretisiert; keine Implementierungsfreigabe oder S2-Änderung.
Weitere Nutzerbestätigung 2026-10-01 „so wie du vorschlägst!“: Auto-Paare
ASCII doppelt/einfach, `[]`, `“…”` (U+201C/U+201D), `„…“`
(U+201E/U+201C); nur vollständige äußere Paare entfernen, sonst unverändert,
nicht trimmen. Im Inneren doubled closing Delimiter dekodieren; einzelnes
unescaped closing Zeichen ist Fehler (`[a]]b]` → `a]b`,
`[a]b]` → Fehler). Opt-in-Backslash dekodiert nur Backslash vor aktivem
Quotezeichen und `\\`; kein `\n`/`\t`/Unicode-Escape, andere Folgen
bleiben unverändert. Ohne Opt-in Backslash literal. Öffentliche Signatur,
Parametername, Result-/Fehlervertrag und Inputlimits sind weiterhin
Vorschläge. Nachtrag 2026-10-01: Mit „do it“ hat der Benutzer die
Randempfehlungen und Vertragsausarbeitung bestätigt: Backslash schützt
opening und closing bei asymmetrischen Paaren; escaped letztes closing ist
kein Delimiter, daher Explicit Fehler und Auto unverändert. Frühere
offene Randpunkte sind ersetzt. Die bestätigte Semantik ist
keine ausdrückliche konkrete Funktionsimplementierungsfreigabe.
`USP_SplitAdvanced` soll ergänzend vorgesehen werden und führt kein
automatisches Unquoting aus. Die Split-TVF bleibt Pflicht.
Die [konkreten Folgeslice-Vorschläge](../Documentation/Architecture/ADVANCED_STRING_SPLIT_PROPOSAL.md#beschlossene-folgescope-grenzen-vom-2026-10-01)
halten Alternativen, Risiken, Dependencies, Testscope und noch offene
Signatur-/Fehler-/Randfallentscheidungen fest. Status: `proposed` für diese
Folgeslices, keine Implementierungsfreigabe; S2 ist davon getrennt `completed`.

Zur gebündelten Freigabe vorbereitet, nicht implementiert:
`TVF_UnquoteToken` mit Input/Qualifier/optionalem ClosingQualifier und
Backslash-Opt-in; NULL-Qualifier Auto, leer Disabled, generische einzelne
BMP-Paare in Explicit und klare typografische Defaultzuordnung vorgeschlagen.
Vier Resultspalten, atomare symbolische Fehler, Originalpositionen,
65.536-Codeunit-Zielgrenze und Prioritäten im
[TVF-Vertragsvorschlag](../Documentation/Architecture/ADVANCED_STRING_SPLIT_PROPOSAL.md#zur-gebündelten-freigabe-unquoting-tvf-vertragsvorschlag).
Die optionale `USP_SplitAdvanced` ist mit vollständiger USP-Signatur,
Value/Ordinal-Erfolgsschema, Kernprüfung vor ResultTable-Mutation, NULL-No-op,
ResultTable-Dependency und Transaktions-/Testvertrag vorbereitet.
API-/Fehler-/Grenzdetails sind Empfehlungen für die gemeinsame
Funktionsfreigabe, keine zusätzlichen erfundenen Nutzerbeschlüsse.
Tests erst nach Freigabe risikobasiert 2019 Linux/2025 Windows.

### TC-2026-034: In-memory-ZIP-Erzeugung

Richtungsbestätigung 2026-10-01: caller-lokale `#Temp` mit `Ordinal`,
`EntryName`, `Payload`; `Stored` als Default, `Deflate` explizit wählbar.
Konservative Default-Zielwerte aus dem
[Writer-Vorschlag](../Documentation/Architecture/ZIP_CREATION_PROPOSAL.md)
dürfen per Ressourcenparameter nach unten und oben innerhalb separat
qualifizierter harter Grenzen angepasst werden; kein `0 = unlimited`.
Hohe Writer-Ratio ist zulässig; notwendiges Readerlimit wird dokumentiert.
Dies ist keine öffentliche Implementierungsfreigabe. Signatur, interner
Transport, Fehler und technische Ceilings bleiben konkret zu besprechen;
Datei-I/O bleibt verpflichtender späterer Slice mit eigenem Sicherheitsvertrag.
Konkreter Writer-Vertragsvorschlag 2026-10-01 vorbereitet: caller-lokale
Entries, vollständige `USP_CreateZipFromEntries`-Signatur, eine Archive-/
Metadatenzeile, unabhängige Default-/Ceilinglimits, versionierter begrenzter
Binary-Envelope, strikte UTF-16-/UTF-8-Namenprüfung vor Konvertierung,
Fehlerpriorität und Finalisierung vor ResultTable-Mutation. Nur Vorschlag;
numerische Fehlerzuordnung, SAFE/Memory und Plattformscope sind
Umsetzungspflichten nach ausdrücklicher Funktionsfreigabe, keine
heutige Runtime-Evidenz. Keine Deflate-Byteidentitätszusage.

### TC-2026-045: Begrenzter XLSX-Reader und verpflichtende Erweiterung

Am 2026-10-01 hat der Benutzer Binaryinput und Raw-/Text-/Cache-Werte als
erste Readergrenze bestätigt. Text ist aufgelöster Shared-/Inline-Stringinhalt,
keine formatierte Excel-Anzeige. Provider, Signaturen, Limits und Fehler sind
noch offen; Status: `researched`, keine öffentliche Readerfreigabe.
Nachtrag 2026-10-01: Nur der begrenzte Provider-Spike ist freigegeben:
SDK-/Dependency-/Lizenzprüfung, Memory-only-/SAFE-/Plattformmachbarkeit mit
synthetischen Minimalworkbooks. Keine öffentliche SQL-Implementierung,
Hochprivilegierung, Datei-/Netzwerkzugriff des Workbook-Providers oder
automatischer externer Fallback; öffentliche Quellenrecherche bleibt zulässig.
Anzeigeformat, Styles, explizite Culture und Datumsbehandlung müssen später
als eigener Funktionsslice umgesetzt werden, sobald ihr Vertrag besprochen
und ausdrücklich freigegeben ist. Dazu gehören 1900-/1904-Modus,
1900-Schaltjahrsonderfall, Formatcodes sowie Datum/Zeit/Dauer-Abbildung.
Der [Reader-Vorschlag](../Documentation/Architecture/XLSX_READER_PROPOSAL.md)
führt Provider-Spike, ungemessene Zielgrenzen und die getrennte Folgestufe.
Quellenreview vom 2026-10-01 abgeschlossen, keine Installation oder
Runtime-/Labtests: SDK 3.5.1 mit Framework 3.5.1 bleibt Vergleichskandidat,
nicht SAFE-/Linux-Nachweis. Begrenzter eigener ZIP-/XML-Kern ist empfohlene
Qualifizierungsrichtung, keine endgültige Providerwahl. Nächster kleiner
Schritt: Prüfplan und exakte SDK-Dependency-/Lizenz-/Hashliste festhalten;
SAFE/Memory-only, Ressourcen und Plattformverhalten später in separat
begrenztem Runtime-Scope nachweisen. Keine öffentliche Readerfreigabe.
Praktischer Spikeplan im Proposal konkretisiert: synthetischer Non-SQL-
Harness, once-index/bounded Parts, positive/negative/Grenz-/Parallelfixtures,
beobachteter No-I/O-Nachweis oder INCONCLUSIVE, gepinnte Paket-/DLL-
Hashqualifizierung erst bei später begrenzter Beschaffung. Heute keine
Downloads, Hashes oder Runtimeprüfung und keine neue Harnesscodefreigabe.
Worksheetliste und Zellreader bleiben getrennte öffentliche Vorschläge.

## Abgeschlossene Arbeitspakete

### AP-2026-030: TC-2026-033 ZIP-Metadaten-Listing

| Feld | Wert |
|---|---|
| ID | `AP-2026-030` |
| Ziel | Ein vorhandenes In-memory-ZIP als strikt geprüftes, geordnetes Metadaten-Listing inventarisieren, ohne Payload zu extrahieren oder zu dekomprimieren. |
| Scope | `toolbelt.archive.zip-memory` Version `1.2.0`; neue öffentliche `toolbelt_archive.USP_ListZipEntriesFromBinary`; gemeinsamer SAFE-CLR-Parserkern; direkte Ausgabe sowie `@ResultTable`/`@KeepData`; klassische Single-Disk-ZIPs. |
| Dependencies | Bestehendes `toolbelt.archive.zip-memory` 1.1.0, `toolbelt.core.result-table` 1.0.0 und freigegebener Vertrag `Documentation/Architecture/ZIP_METADATA_MODULE_DESIGN.md`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Listing-only aus `varbinary(max)`; Central-Directory-Reihenfolge; deklarierte Größen/CRC; Directory-, Encryption-, Extraction-Support-, Duplicate- und Path-Safety-Status; UTF-8/CP437; strikte Strukturprüfung; harte Limits; ZIP64/Multi-Disk abgelehnt; unbekannte Methoden und verdächtige Entries werden gelistet statt verworfen. |
| Alternativen | Getrenntes Metadatenmodul, reine T-SQL-Implementierung und externer Worker wurden zugunsten der Erweiterung des vorhandenen SAFE-CLR-Moduls verworfen, damit der ZIP-Parserkern nur einmal existiert. |
| Risiken | Untrusted Central-Directory-Metadaten, Encoding-Abweichungen, große Entry-Mengen, irreführende deklarierte Größen/CRC und die klare Trennung zwischen Listing und Extraktionsfreigabe. |
| Tests | Statischer Vertrag; synthetische Struktur-/Encoding-/Pfad-/Duplicate-/Limitfälle; direkte Ausgabe und ResultTable; Local/Central; Upgrade 1.1.0→1.2.0; automatisierte SQL-Server-2019-/2022-/2025-Matrix unter Windows base und Linux latest erfolgreich. |
| Freigabe | Fachvertrag und Implementierung dieses konkreten V1-Slices am 2026-08-09 ausdrücklich durch den Benutzer freigegeben. |
| Evidenz | Modulartefakte unter `Modules/toolbelt.archive.zip-memory/`; statischer Vertragscheck, Windows-.NET-Framework-4.8-Build und die vollständige SQL-Server-2019-/2022-/2025-Linux-Matrix einschließlich Listing und Extraktion sind im [GitHub-Actions-Lauf 32701896453](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453) erfolgreich. |
| Nächster Schritt | Reale Archive, echte Extremgrößen, Interoperabilität und den vollständigen Upgradepfad aus einem realen 1.1.0-Stand als Releaseevidenz ergänzen. |

### AP-2026-029: TC-2026-014 Rollback-independent Event Log

| Feld | Wert |
|---|---|
| ID | `AP-2026-029` |
| Ziel | Strukturierte Events synchron in einer zweiten Session persistieren, sodass sie Caller-Rollback und uncommittable Caller überleben. |
| Scope | `toolbelt.core.event-log` Version `1.0.0`, EventLog-Tabelle, View, Writer, Retention, interner Work Type sowie Second Session `@SuppressResult`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `validated` |
| Release Status | `unreleased` |
| Tests | Windows/Linux 2019/2022/2025 einschließlich Rollback, uncommittable Caller, Context, Validierung, Retention, Concurrency, Redeploy, Central und Uninstall erfolgreich. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410 und `local: Tests/CI/run-lab-local.ps1` vom 2026-09-01 |
| Nächster Schritt | Keine autonome Validierung offen; tatsächliche Veröffentlichung bleibt unautorisiert. |

### AP-2026-027: TC-2026-022 Work-Type-Katalog

| Feld | Wert |
|---|---|
| ID | `AP-2026-027` |
| Ziel | Einen persistenten sicheren Katalog für benannte Stored-Procedure-Work-Types bereitstellen, ohne eine Raw-SQL-Ausführungsschnittstelle zu schaffen. |
| Scope | `toolbelt.core.work-type` Version `1.0.0`, interne Tabelle `toolbelt_core.WorkType`, öffentliche Register-/Disable-/Resolve-USPs, `VW_WorkTypes`, lokale und zentrale Installation. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest erfolgreich; Registrierung, Update/RowVersion, Disable/Reaktivierung, Resolve, ResultTable, vier parallele Sessions, Redeploy, Central und Data-Loss-Uninstall-Schutz. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Keine autonome Validierung offen; Second-Session-Provider bleibt eine getrennte W5-Capability. |

### AP-2026-026: TC-2026-019 Execution Context

| Feld | Wert |
|---|---|
| ID | `AP-2026-026` |
| Ziel | Sessiongebundene Execution- und Correlation-Information ohne persistente Tabelle bereitstellen. |
| Scope | `toolbelt.core.execution-context` Version `1.0.0`, Begin/Set/End, inline TVF, SVF-Wrapper, lokales und zentrales Deployment. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest erfolgreich; vier parallele Sessions, Lifecycle, Central und Uninstall. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Keine autonome Validierung offen; persistenter Ausführungsstatus bleibt ein getrennter, nicht freigegebener Slice. |

### AP-2026-025: TC-2026-017 Error Envelope

| Feld | Wert |
|---|---|
| ID | `AP-2026-025` |
| Ziel | Explizit aus einem CATCH übergebene Fehlerdaten standardisieren, ohne den unveränderten Rethrow zu ersetzen. |
| Scope | `toolbelt.core.error-envelope` Version `1.0.0`, direkte und ResultTable-Ausgabe, lokale und zentrale Installation. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Ziele unter Windows base und Linux latest erfolgreich; Klassifikation, ResultTable, Lifecycle, Central und Uninstall. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Keine autonome Validierung offen; persistentes Logging bleibt ein getrennter, nicht freigegebener Slice. |

### AP-2026-024: TC-2026-037 File-Content-Slice 1

| Feld | Wert |
|---|---|
| ID | `AP-2026-024` |
| Ziel | Den portablen Read-only-Slice für kontrolliertes Text- und Binary-Lesen über `OPENROWSET(BULK...)` implementieren, registrieren und mit ausführbarer Evidenz belegen. |
| Scope | `toolbelt.file.content` Version `1.0.0`, Root-Allowlist, `toolbelt_file.USP_LoadBinaryFile`, `toolbelt_file.USP_LoadTextFile`, lokales und zentrales Deployment, Dokumentation, statische sowie Runtime-/Lifecycle-Contracts. Keine Schreiboperationen und kein externer Worker. |
| Dependencies | Keine Runtime-Modulabhängigkeit; administrative Bulk-Read-Berechtigung beziehungsweise Ad-hoc-Distributed-Queries entsprechend Deploymentvertrag. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Absolute Pfade nur innerhalb freigegebener Roots; Traversal-Ablehnung; Text/Binary-Vertrag, BOM-/Encoding-Metadaten, Limits, Hilfe, Deployment und Uninstall vorhanden. |
| Tests | SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; statischer Vertrag, synthetische UTF-8-/UTF-16-/ANSI-/Binary-Fixtures, Allowlist, Lifecycle und Uninstall. |
| Blocker | Kein Merge-Blocker. Windows, separat bereitgestellte serverseitige Fixtures und nicht-ASCII-spezifische Providergrenzen bleiben Releasevalidierung. |
| Evidenz | Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356. |
| Nächster Schritt | Serverseitige synthetische Fixtures extern bereitstellen und Windows sowie die nicht-ASCII-spezifischen Providergrenzen prüfen; Schreiboperationen werden durch den getrennten Windows-Provider abgedeckt. |

Wartung 2026-10-07 (Codex): Der Security-Cloud-Befund zum nicht maskierten
Präfixvergleich wird innerhalb des bestehenden Root-Allowlist-Vertrags
korrigiert. Beide vorhandenen Lader verwenden dieselbe literale
Verzeichnisgrenze mit unverändertem Fehlercode `51321`; keine neue öffentliche
Funktion, kein zusätzlicher Provider und keine Rechte- oder Labausweitung.
Der autonome Wartungsauftrag deckt diese Vertragskorrektur ab. Native Windows-,
Minimalrechte- und Dateisystemlink-Qualifikation bleiben offen; neue Tests
werden nur mit tatsächlich ausgeführter Evidenz als bestanden geführt.

### AP-2026-022: SQL CLR ZIP Build-/Deployment-Spike

| Feld | Wert |
|---|---|
| ID | `AP-2026-022` |
| Ziel | Den technisch kleinsten SQL-CLR-Providerpfad für ZIP Method 8 mit einer minimalen `SAFE`-Assembly kontrolliert bauen, deployen, ausführen und wieder entfernen. |
| Scope | C#-Projekt für .NET Framework 4.8; Raw-Deflate über `DeflateStream` aus der unterstützten `System.dll`; eigene CRC32-Prüfung; SHA2-512-Trust-Manifest; binäres `CREATE ASSEMBLY`; getrennte Trust-, Deploy-, Verify- und Uninstall-Skripte; positiver SQL-Server-2022-Linux-Runtime-Gate. Keine produktive ZIP-Funktion, keine öffentliche API und kein Modulmanifest. |
| Dependencies | `AP-2026-021`, `ZIP_CLR_PROVIDER_DESIGN.md`, `CLR_SECURITY_AND_PORTABILITY.md`, .NET-Framework-4.8-Targeting-Pack, MSBuild, SQLCMD und eine disposable SQL-Server-Testinstanz. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Keine direkte Referenz auf `System.IO.Compression.dll` oder `ZipArchive`; `DeflateStream` wird aus `System.dll` geladen; die Testassembly bleibt `SAFE`; der Trust-Hash entsteht aus dem konkreten Binary; Deployment benötigt keinen serverlokalen Buildpfad; tatsächlicher CLR-Aufruf prüft Payload und CRC32; kein Skript setzt `TRUSTWORTHY ON`, deaktiviert `clr strict security` oder verwendet `EXTERNAL_ACCESS`/`UNSAFE`; Uninstall berührt keinen Trust-Eintrag. |
| Tests | Statische Vertragsprüfung, Windows-GitHub-hosted .NET-Framework-Build und positiver SQL-Server-2022-Linux-Lauf mit Trust, `CREATE ASSEMBLY`, Deflate-/CRC32-Ausführung und Uninstall sind erfolgreich. SQL Server 2019, SQL Server 2025 und Windows-Runtime bleiben separate Pflichtläufe vor Produktfreigabe. |
| Blocker | Kein bekannter technischer Blocker für den korrigierten Deflate-/CRC32-Spike. Der frühere Fehler 10301 entstand durch den ungeeigneten `ZipArchive`-Pfad und die direkte Abhängigkeit von `System.IO.Compression.dll`. |
| Evidenz | `Spikes/sql-clr-zip-provider/README.md`, `Source/ZipClrProbe.cs`, `Tests/Static/validate_spike.py`, `.github/workflows/sql-clr-zip-spike.yml` und SQL CLR ZIP Spike Run 30608612435. |
| Nächster Schritt | Historische Spike-Evidenz beibehalten; die produktive Implementierung und weitere Plattformvalidierung werden in `AP-2026-020` geführt. |

### AP-2026-021: TC-2026-034 Verarbeitungswelle 3 (CLR-Provider Vertragswelle)

| Feld | Wert |
|---|---|
| ID | `AP-2026-021` |
| Ziel | Den separaten CLR-Providervertrag für `TC-2026-034` abschließen und die Sicherheits-, Lifecycle- und Plattformgrenzen vor einer Implementierung verbindlich festlegen. |
| Scope | Keine Runtime-Implementierung. Der Vertrag begrenzt einen optionalen C#-SQL-CLR-Provider auf In-memory-Extraktion einzelner Entries mit ZIP Method 0 und 8, einschließlich Payload-CRC-Prüfung; Dateisystem, Verschlüsselungsentschlüsselung, Deflate64, ZIP-Erzeugung und weitere Formate bleiben ausgeschlossen. |
| Dependencies | `AP-2026-020`, `TC-2026-034`, `Documentation/Architecture/ZIP_ARCHIVE_MODULE_DESIGN.md`, `Documentation/Architecture/CLR_SECURITY_AND_PORTABILITY.md`, Datenschutz- und Lifecycle-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Klarer Provider-Schnitt mit explizitem Non-Goal gegen Dateisystem-Default, definiertem Methodensubset (0 und 8), expliziter Payload-CRC-Prüfung, dokumentiertem Sicherheitsweg ohne pauschales `TRUSTWORTHY ON` sowie definiertem Assembly-Lifecycle und Test-/Spike-Gates. |
| Tests | Vertrags- und Designkonsistenz sowie dokumentierte Build-/Trust- und Runtime-Matrix. Diese Welle behauptet keine Runtime-Evidenz. |
| Blocker | Keine. Der Vertrag wurde durch die produktive SAFE-SQL-CLR-Implementierung erfüllt. |
| Evidenz | Benutzerauftrag vom 2026-07-30; Architekturvertrag `ZIP_CLR_PROVIDER_DESIGN.md`; Spike-Quellartefakte in `Spikes/sql-clr-zip-provider/`. |
| Nächster Schritt | Keine weitere Vertragswelle erforderlich; reale Archive, Extremgrößen, historische Upgrades und Interoperabilität werden in `AP-2026-020` nachgeführt. |

### AP-2026-020: TC-2026-034 Verarbeitungswelle 2 (Implementierungswelle V1A)

| Feld | Wert |
|---|---|
| ID | `AP-2026-020` |
| Ziel | Den freigegebenen V1A-Slice von `TC-2026-034` als erstes lauffaehiges ZIP-Modul implementieren, dokumentieren und mit Runtime-Evidenz belegen. |
| Scope | `toolbelt.archive.zip-memory` Version `1.1.0` mit In-memory-Extraktion einzelner Eintraege aus `varbinary(max)`; kein Dateisystemzugriff, keine Archiv-Erzeugung, keine rekursive Entpackung, keine Passwortentschluesselung. |
| Dependencies | Abgeschlossene Vertragswelle `AP-2026-019`, Kandidaten `TC-2026-033` und `TC-2026-034`, Moduldesign `ZIP_ARCHIVE_MODULE_DESIGN.md`, USP-Vertrag, Modul- und Lifecycle-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Ein oeffentliches Objekt mit stabilem Help-/Fehler-/Resultset-Vertrag; Duplicate-Entry-Semantik als expliziter Fehler; harte Default-Limits (`@MaxEntryBytes = 104857600`, `@MaxCompressionRatio = 200.00`); verschluesselte Eintraege liefern bei `@FailIfEncrypted = 0` einen expliziten Status ohne Payload; lokale und zentrale Lifecycle-Artefakte sowie statische und Runtime-Tests vorhanden. |
| Tests | Windows-.NET-Framework-4.8-Build sowie SQL Server 2019, 2022 und 2025 unter Linux; auf SQL Server 2025 Compatibility Levels 150, 160 und 170. Trust, Stored, Deflate, Data Descriptor, Encoding, CRC32, Limits, ResultTable, Wiederholungsdeployment, Central und Uninstall erfolgreich. |
| Blocker | Kein Merge-Blocker. Reale Archive, echte Extremgrößen-/Ressourcenläufe, historische Upgrades und Interoperabilität bleiben offen. |
| Evidenz | Produktives Modul `toolbelt.archive.zip-memory` Version `1.1.0`; Workflow [30615544206](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206) erfolgreich. |
| Nächster Schritt | Reale Archive, echte Extremgrößen und historische Upgrade-/Interoperabilitätsevidenz ergänzen; ZIP-Erzeugung und vollständige Dateisystemextraktion bleiben getrennte spätere Slices. |

### AP-2026-019: TC-2026-034 Verarbeitungswelle 1 (Vertragswelle)

| Feld | Wert |
|---|---|
| ID | `AP-2026-019` |
| Ziel | Die erste Verarbeitungswelle fuer `TC-2026-034` als belastbare V1-Vertragsbasis abschliessen und die anschliessende Implementierungsfreigabe vorbereiten. |
| Scope | Keine Runtime-Implementierung. V1A auf In-memory-Extraktion einzelner ZIP-Eintraege begrenzen, Dateisystempfade ausschliessen, Sicherheitsgrenzen und Ergebnisvertrag dokumentieren, Testmatrix und Lifecycle-Scope vorbereiten. |
| Dependencies | `TC-2026-034`, `TC-2026-033`, `TC-2026-037`, `TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md`, `WORKING_RULES.md`, `PROJECT_RULES.md`. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | V1A-Vertrag ist dokumentiert, Nicht-Ziele sind explizit, Provider ist auf In-memory begrenzt, Sicherheits- und Testrahmen sind definiert. |
| Tests | Vertragskonsistenz und Dokumentationsvalidator erfolgreich; Runtime fuer diese Welle `not applicable`. |
| Blocker | Keine offenen Vertragsblocker nach Benutzerfreigabe. |
| Evidenz | `ZIP_ARCHIVE_MODULE_DESIGN.md`, aktualisierte Kandidaten- und Planartefakte, Benutzerentscheid am 2026-07-30. |
| Nächster Schritt | Implementierungswelle als `AP-2026-020` aktiv. |

### AP-2026-018: W2c Console Message und Capability Catalog

| Feld | Wert |
|---|---|
| ID | `AP-2026-018` |
| Ziel | Die freigegebenen Kandidaten `TC-2026-016` und `TC-2026-023` als zwei unabhängige portable Module implementieren und prüfen. |
| Scope | `toolbelt.core.console-message` Version `1.0.0` mit `toolbelt_core.USP_WriteConsoleMessage`; `toolbelt.metadata.capability-catalog` Version `1.0.0` mit `toolbelt_metadata.VW_ModuleCapabilities`; lokale und zentrale Installation; keine Präfixe, Severity-Optionen, Registry, Filter-TVF oder `module.yaml`-Runtime-Abhängigkeit. |
| Dependencies | W2c-Hauptempfehlung und ausdrückliche Benutzerfreigabe vom 2026-07-30; USP-, Modul-, Lifecycle- und Metadata-Verträge; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | beide Module `implemented` |
| Validation Status | `toolbelt.core.console-message`: `partially validated`; `toolbelt.metadata.capability-catalog`: `validated` |
| Release Status | beide Module `unreleased` |
| Akzeptanzkriterien | Unicode-sichere vollständige Message-Chunks mit PRINT oder NOWAIT; NULL ohne Ausgabe; kein fachliches Resultset; read-only Projektion kanonischer Database-level Marker; `valid`/`incomplete`/`invalid`; vollständige Source-, Lifecycle-, Dokumentations-, Contract- und CI-Artefakte; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Verträge und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 einschließlich Capture-Markern, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich; vollständige Adapter am 2026-08-29 auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. |
| Blocker | Capability Catalog: keiner. Console Message bleibt wegen zusätzlicher Client-/Treiber-, Buffering- und Framing-Evidenz `partially validated`. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesigns `CONSOLE_MESSAGE_MODULE_DESIGN.md` und `CAPABILITY_CATALOG_MODULE_DESIGN.md`; kanonische Artefakte unter `Modules/toolbelt.core.console-message/` und `Modules/toolbelt.metadata.capability-catalog/`; [W2c Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975), [Documentation Consistency 30573136009](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573136009) und lokaler physischer Linux-Lauf vom 2026-08-29 erfolgreich. |
| Nächster Schritt | Capability Catalog benötigt keine autonome Validierung mehr. Für Console Message zusätzliche reale Client-/Treiberkontexte bereitstellen; Veröffentlichung bleibt unautorisiert. |

### AP-2026-017: W2b-A JSON Path Exists

| Feld | Wert |
|---|---|
| ID | `AP-2026-017` |
| Ziel | Den freigegebenen Pfadprüfungs-Slice von `TC-2026-009` als portables Modul für SQL Server 2019+ implementieren und prüfen. |
| Scope | `toolbelt.json.path-exists` Version `1.0.0`; öffentliche `toolbelt_json.TVF_JsonPathExists`; Root-, Property-, Quote-, Array-Index- und Wildcard-Pfade; SQL-NULL-Propagation; fehlerfreies `0` bei ungültigem JSON oder Pfad; lokales und zentrales Deployment. Keine JSON-Konstruktoren, Aggregate, SQL CLR, Scalar-Wrapper oder SQL-Server-2025-Preview-Ranges/-Listen/`last`. |
| Dependencies | Gemeinsame W2b-Vertragsrunde und ausdrückliche Benutzerfreigabe vom 2026-07-30; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | `1`/`0`/SQL-`NULL` als `int`; JSON `null` zählt als vorhanden; case-sensitive BIN2-Keyvergleich; Pfad- und JSON-Fehler verlassen den Funktionsvertrag nicht; vollständige Source-, Lifecycle-, Dokumentations-, Contract- und CI-Artefakte; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Prüfung und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 mit nativer Parität, synthetischen Fehler-/Collation-Fällen, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich. |
| Blocker | Keine. Die vollständige Windows-/Linux-Matrix ist erfolgreich. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesign `JSON_PATH_EXISTS_MODULE_DESIGN.md`; kanonische Artefakte unter `Modules/toolbelt.json.path-exists/`; [W2b JSON Path Runtime 30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943), [Documentation Consistency 30568128932](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128932) und lokaler physischer Linux-Lauf vom 2026-08-29 erfolgreich. |
| Nächster Schritt | Keine autonome Validierung offen; Konstruktoren und Aggregate bleiben ohne Einzelvertrag und Freigabe zurückgestellt. |

### AP-2026-016: Portable W2a – Truncation, Bucketing und Bigint-Bitoperationen

| Feld | Wert |
|---|---|
| ID | `AP-2026-016` |
| Ziel | Die gemeinsam geplanten Kandidaten `TC-2026-004`, `TC-2026-005` und `TC-2026-007` als drei portable Compatibility-Module implementieren und prüfen. |
| Scope | `toolbelt.datetime.truncate`, `toolbelt.datetime.bucket` und `toolbelt.binary.bit-operations`; typgetrennte öffentliche Date/Time-Inline-TVFs, interner Bucket-Optimizer-Core, Bigint-Shift/Count/Get/Set, Lifecycle, Central Deployment, Dokumentation und synthetische Contract-Tests. Keine Scalar UDFs, keine `datetime`-/`smalldatetime`-/`time`-Familie und kein `binary(n)`-/`varbinary(n)`-Provider. |
| Dependencies | Funktionsbezogener W2a-Vorschlag im Implementierungsplan und ausdrückliche Benutzerfreigabe vom 2026-07-30; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Typstabile relationale APIs; dokumentierte Dateparts, Scale-7-, `DATEFIRST`-, Origin-, negative Floor-, Shift-, Vorzeichen- und Validation-Code-Semantik; lokale und zentrale Installation; Wiederholungsdeployment und Uninstall; native Parität auf SQL Server 2022/2025; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Contracts und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 einschließlich Runtime, nativer Parität, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich. |
| Blocker | Keine. Die vollständige Windows-/Linux-Matrix einschließlich Kollisionsschutz und Bucket-Workload ist erfolgreich. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesigns `DATETIME_TRUNCATE_MODULE_DESIGN.md`, `DATETIME_BUCKET_MODULE_DESIGN.md` und `BIT_OPERATIONS_MODULE_DESIGN.md`; [W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509), [Documentation Consistency 30561235177](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561235177) und lokaler physischer Linux-Lauf vom 2026-08-29. |
| Nächster Schritt | Keine autonome Validierung offen; weitere Performancezusagen würden einen getrennten Scope benötigen. |

### AP-2026-015: Portable W1 – Calendar Difference, Directional TRIM und URI Component

| Feld | Wert |
|---|---|
| ID | `AP-2026-015` |
| Ziel | Die gemeinsam besprochenen Kandidaten `TC-2026-002`, `TC-2026-008` und `TC-2026-024` als drei unabhängige, portable Module implementieren. |
| Scope | `toolbelt.datetime.calendar-difference`, `toolbelt.string.directional-trim` und `toolbelt.conversion.uri-component`; öffentliche inline TVFs, optionale URI-Scalar-APIs, Lifecycle, Dokumentation und synthetische Contract-Tests. |
| Dependencies | Funktionsbezogene Besprechung und ausdrückliche Benutzerfreigabe vom 2026-07-30; für TRIM und URI `toolbelt.core.generate-series` Version `1.0.0`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Anniversary-Regel, gerichtetes und typstabiles Trim sowie RFC-3986-Komponentenencoding sind explizit dokumentiert; keine implizite IRI-, Form-Encoding- oder Double-Decoding-Semantik. |
| Tests | Statische Contracts und GitHub-hosted SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; Anniversary-, Grenzwert-, Unicode-/UTF-8-, Fehler-, Paritäts-, Wiederholungs-, lokaler, zentraler und Uninstall-Scope geprüft. |
| Blocker | Keine. Die vollständige Windows-/Linux-Matrix einschließlich Collation-, ASCII-/Unicode-/Large-Input- und Kollisionsfällen ist erfolgreich. |
| Evidenz | Benutzerfreigabe 2026-07-30; [W1 Portable Runtime 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399), [Documentation Consistency 30553118014](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118014) und lokaler physischer Linux-Lauf vom 2026-08-29. |
| Nächster Schritt | Keine autonome Validierung offen; zusätzliche fachliche Ausbaustufen benötigen Einzelvertrag und Freigabe. |

### AP-2026-014: Inline-TVF-Alternativen für bestehende SVFs

| Feld | Wert |
|---|---|
| ID | `AP-2026-014` |
| Ziel | Für alle fachlich geeigneten vorhandenen SVFs eine semantisch äquivalente inline-TVF-API bereitstellen und die inline TVF als kanonischen relationalen Kern verwenden. |
| Scope | `toolbelt.conversion.base64`, `toolbelt.conversion.integer-base` und `toolbelt.validation.semantic-version`; sechs neue inline TVFs gemäß `SVF_INLINE_TVF_AUDIT.md`; vorhandene SVFs bleiben als Convenience-API erhalten. |
| Dependencies | Benutzeranforderung vom 2026-07-30; `DEC-2026-022`; bestehende öffentliche Verträge der sechs SVFs. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Kein TVF-Wrapper ruft lediglich die SVF auf; Fachlogik besitzt genau einen kanonischen Kern; Parität, Objekttyp, `NULL`- und Fehlersemantik, lokale und zentrale Installation sowie Lifecycle sind getestet; Objekt- und Moduldokumentation zeigt `APPLY` als bevorzugte Mengenverwendung. |
| Tests | Statische Modulverträge und vollständiger Dokumentationsaudit erfolgreich; Runtime auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Parität, `APPLY`, Upgrade, Wiederholung, Kollision, zentralem Deployment und Uninstall erfolgreich. |
| Blocker | Keine. Die vollständige Windows-/Linux-Matrix ist erfolgreich. |
| Evidenz | `DEC-2026-022`, `Documentation/Architecture/SVF_INLINE_TVF_AUDIT.md`; [Base64 Runtime 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837), [Integer-Base Runtime 30535377860](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860), [Semantic-Version Runtime 30535377984](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984), [Documentation Consistency 30535377863](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377863). |
| Nächster Schritt | Keine autonome Validierung offen; weitere Wrapper benötigen einen getrennten Vertrag. |

### AP-2026-013: Frei definierbare Zahlensysteme implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-013` |
| Ziel | `TC-2026-031` als Integer-Encode-/Decode-Capability mit frei definierbarem Alphabet implementieren. |
| Scope | `toolbelt.conversion.integer-base` Version `1.0.0`; vollständiger `bigint`-Bereich; Alphabet mit 2 bis 93 druckbaren ASCII-Zeichen außer `-`; kanonische Encode-/Decode-Darstellung und Overflow-Vertrag. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Encode/Decode verwenden denselben kanonischen Alphabetvertrag; Zeichen sind binär eindeutig; ungültiges Alphabet, ungültige Ziffer, Vorzeichen, `bigint`-Minimum, Null und Overflow sind dokumentiert und getestet; vollständiger Lifecycle und gekoppelte Dokumentation. |
| Tests | Statischer Vertrag sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Keine bekannten. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-031`; kanonische Artefakte unter `Modules/toolbelt.conversion.integer-base/`; erfolgreicher [Runtime-Lauf 30518087070](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30518087070); persönlicher Brainstorm als Herkunft. |
| Nächster Schritt | Keine autonome Validierung offen; Release bleibt unautorisiert. |

### AP-2026-012: Semantic-Version Parser und Comparator implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-012` |
| Ziel | `TC-2026-030` als strikt SemVer-2.0.0-konformen Parser, Comparator und Sort Key implementieren. |
| Scope | `toolbelt.validation.semantic-version` Version `1.0.0`; ASCII `varchar(8000)`; Core, Pre-release, Build Metadata, Validierung, Präzedenzvergleich und binärer Sort Key; keine allgemeinen Produktversionsformate. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | SemVer-2.0.0-Grammatik und Präzedenz vollständig; Build Metadata beeinflusst Vergleich und Key nicht; beliebig lange numerische Komponenten ohne verlustbehaftete Konvertierung; offizielle und synthetische Vektoren, Lifecycle und Dokumentation vollständig. |
| Tests | Statischer Vertrag sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Keine bekannten. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-030`; kanonische Artefakte unter `Modules/toolbelt.validation.semantic-version/`; erfolgreicher [Runtime-Lauf 30517137373](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373). |
| Nächster Schritt | Keine autonome Validierung offen; Release bleibt unautorisiert. |

### AP-2026-011: Multi-Separator-Split Version 1 implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-011` |
| Ziel | `TC-2026-001` als portablen Split-Vertrag für mehrere einzelne Trennzeichen implementieren. |
| Scope | `toolbelt.string.split-characters` Version `1.0.0`; `TVF_SplitByCharacters`; stabile Ordinals, definierte leere Tokens, einzelne Separatorzeichen, binärer Collation- und LOB-Vertrag; keine mehrzeichigen Separatoren, Quote- oder Escape-Semantik. |
| Dependencies | `toolbelt.core.generate-series` Version `1.0.0`; vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Literalvertrag bleibt von Regex getrennt; Token und Ordinal sind deterministisch; `NULL`, NUL, leerer Input, aufeinanderfolgende Separatoren, Separator am Rand, Collations und Größenklassen sind dokumentiert und getestet; vollständiger Lifecycle und gekoppelte Dokumentation. |
| Tests | Statischer Vertrag sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Kein Merge-Blocker; die vollständige Pflichtmatrix ist erfolgreich. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-001`; kanonische Artefakte unter `Modules/toolbelt.string.split-characters/`; [Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708) erfolgreich. |
| Nächster Schritt | Keine autonome Validierung offen. S2 zu `TC-2026-032` ist separat freigegeben und implementiert; USP/Unquoting bleiben offen. |

### AP-2026-010: Identifier- und Multipart-Name-Toolkit implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-010` |
| Ziel | Den aus `RI-2026-011` formalisierten und freigegebenen Vertrag `TC-2026-029` als portables Metadata-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.metadata.identifier` Version `1.0.0`; `TVF_ParseMultipartName` und `SVF_QuoteMultipartName`; ein- bis vierteilige Namen, `[...]`, `]]`, ausgelassene mittlere Teile, stabile Validation Codes, lokales und zentrales Deployment. Keine Objektauflösung, Berechtigungsprüfung, doppelten Anführungszeichen oder CLR. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe des Benutzers vom 2026-07-30; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zustandsbasierter kanonischer Parser; genau eine Ergebniszeile; rechtsbündige Teile; vollständige Escape-, Omission-, Längen-, Collation-, Wrapper-, Deployment- und Lifecycle-Contracts; Dokumentation und Change-Impact-Registry gekoppelt. |
| Tests | Statischer Vertrag sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Kein Merge-Blocker; die vollständige Pflichtmatrix ist erfolgreich. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-029`; kanonische Artefakte unter `Modules/toolbelt.metadata.identifier/`; [Identifier Runtime Run 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834) erfolgreich. |
| Nächster Schritt | Keine autonome Validierung offen; Release bleibt unautorisiert. |

### AP-2026-009: Portable Ganzzahlreihen implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-009` |
| Ziel | Den freigegebenen Vertrag von `TC-2026-006` als portables Core-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.core.generate-series` Version `1.0.0`; `TVF_GenerateSeriesInt` und `TVF_GenerateSeriesBigInt`; portable T-SQL Inline TVFs; lokales und zentrales Deployment; Richtungs-, Default-, NULL-, Fehler-, Grenz-, Größen-, Join-, `CROSS APPLY`-, native Paritäts- und Lifecycle-Tests. Keine Dezimaltypen, persistente Numbers-Tabelle oder SQL CLR. |
| Dependencies | Besprochener und am 2026-07-30 ausdrücklich freigegebener Funktionsvertrag; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Abhängigkeit zu einem anderen Toolbelt-Modul. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zwei öffentliche Inline TVFs im Schema `toolbelt_core`; typstabile `int`-/`bigint`-Resultsets; gemeinsamer `bigint`-Kern; richtungsabhängiger Default; keine stille Kürzung; Enginefehler bei Schritt `0` und nicht darstellbarer Zeilenzahl; vollständige gekoppelte Dokumentation und Lifecycle-Artefakte; SQL Server 2025 mit Compatibility Levels 150/160/170 erfolgreich. |
| Tests | Statische Vertragsprüfung sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlt eine breitere Performancebewertung sehr großer Reihen. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; kanonische Artefakte unter `Modules/toolbelt.core.generate-series/`; [Generate-Series Runtime Run 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324) erfolgreich. |
| Nächster Schritt | Breitere Very-large-series-Performance-Evidenz mit dem 10-Millionen-Workload gegen eine flüchtige Vergleichsbasis erheben; Default ist höchstens 20 % Median-Regression und je Lauf steuerbar. |

### AP-2026-008: Base64/Base64URL-Modul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-008` |
| Ziel | Den freigegebenen Vertrag von `TC-2026-012` als portables Conversion-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.conversion.base64` Version `1.0.0`; `SVF_Base64Encode` und `SVF_Base64Decode`; T-SQL/XML-Provider; lokales und zentrales Deployment; RFC-4648-, native Paritäts-, Fehler-, Größen- und Lifecycle-Tests. Kein CLR, keine Zeichenkodierung und keine Datei-I/O. |
| Dependencies | Besprochener und am 2026-07-29 ausdrücklich freigegebener Funktionsvertrag; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Abhängigkeit zu ResultTable. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zwei öffentliche Scalar UDFs im Schema `toolbelt_conversion`; Standard- und URL-safe-Ausgabe; Decode beider Alphabete, optionales Padding und definierter Whitespace; unveränderte Providerfehler; keine String-zu-Binär-Konvertierung; vollständige gekoppelte Dokumentation und Lifecycle-Artefakte; SQL Server 2025 mit Compatibility Levels 150/160/170 erfolgreich. |
| Tests | Statische Vertragsprüfung sowie vollständige Windows-/Linux-Matrix 2019/2022/2025 einschließlich Compatibility Levels 150/160/170 nach Zielversion erfolgreich. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlt eine breitere Performancebewertung großer LOBs. |
| Evidenz | Benutzerfreigabe vom 2026-07-29; kanonische Artefakte unter `Modules/toolbelt.conversion.base64/`; [Base64 Runtime Run 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673) erfolgreich. |
| Nächster Schritt | Breitere Large-LOB-Performance-Evidenz mit dem 4-MiB-Workload gegen eine flüchtige Vergleichsbasis erheben; Default ist höchstens 20 % Median-Regression und je Lauf steuerbar. |

### AP-2026-007: Entscheidungsvorbereitung für das zweite Modul

| Feld | Wert |
|---|---|
| ID | `AP-2026-007` |
| Ziel | Die nächsten kleinen Compatibility-Kandidaten so vergleichen, dass die funktionsbezogene Benutzerbesprechung ohne verdeckte Typ-, Provider- oder Fehlerentscheidungen geführt werden kann. |
| Scope | Vertiefter Vergleich von `TC-2026-004` und `TC-2026-012`; dokumentierte Empfehlung, Vertragsfragen, Provideroptionen, Testdimensionen, Abhängigkeiten und Implementierungs-Gates. Keine SQL-Implementierung und kein Modulmanifest. |
| Dependencies | `AP-2026-003`, `AP-2026-005`, funktionsbezogenes Implementierungs-Gate und Phase-2-Abhängigkeit aus der Roadmap. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Bevorzugter Besprechungskandidat nachvollziehbar ausgewählt; Alternative mit konkretem Grund zurückgestellt; offene Benutzerentscheidungen und Pflichtprüfungen sichtbar; kein öffentlicher Funktionsvertrag oder Implementierungsrecht behauptet. |
| Tests | Primärquellenabgleich gegen Microsoft Learn und RFC 4648; Kandidaten-, Backlog-, Roadmap-, Link-, Datenschutz- und Change-Impact-Prüfung. Runtime-Tests sind für diese reine Entscheidungsvorbereitung `not applicable`. |
| Blocker | Keine. Der konkrete Vertrag wurde am 2026-07-29 besprochen und freigegeben; das pauschale Referenzmodul-Gate wurde durch `DEC-2026-021` scopebezogen präzisiert. |
| Evidenz | `Documentation/Research/SECOND_MODULE_SELECTION.md` und aktualisierte Kandidaten `TC-2026-004`/`TC-2026-012`; geprüft am 2026-07-29. |
| Nächster Schritt | Abgeschlossen; Umsetzung erfolgt in `AP-2026-008`. Die offenen ResultTable-Pflichtfälle bleiben ein eigenes Arbeitspaket. |

### AP-2026-006: Dokumentationsbaseline und inkrementeller Drift-Schutz

| Feld | Wert |
|---|---|
| ID | `AP-2026-006` |
| Ziel | Die vollständige Dokumentationsbaseline herstellen und nachfolgende Änderungen über explizite, diff-basierte Artefaktkopplungen synchron halten. |
| Scope | Statuskorrekturen, getrennte Modulstatusdimensionen, Modulregistry, gekoppelte Dokumentationspfade, generierte Statusabschnitte, inkrementeller Validator, pfadbezogene CI und Pull-Request-Checkliste. |
| Dependencies | aktueller `main`, implementiertes ResultTable-Modul und `DEC-2026-020`. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Einmaliger Vollaudit erfolgreich; bekannte Statusdrift beseitigt; Runtime-CI nicht mehr durch reine Dokumentationsänderungen ausgelöst; Folgeprüfungen diff-basiert; geschützte Lizenzinhalte unverändert. |
| Tests | Python-Standardbibliothek-Validator, modulspezifische statische Prüfung, Markdown-Linkprüfung, YAML-/Workflow-Strukturprüfung, Datenschutz-/Secret-Diffprüfung und GitHub Actions. |
| Blocker | Keine. |
| Evidenz | Lokaler vollständiger Baseline-Audit am 2026-07-29 erfolgreich; [Documentation Consistency Run 30453805254](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30453805254) und [ResultTable Runtime Run 30453805186](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30453805186) vollständig erfolgreich. |
| Nächster Schritt | Abgeschlossen; die laufende Dokumentationskonsistenz wird durch den inkrementellen Validator geschützt. |

### AP-2026-005: SQL-Server-Toolbelt-Landschaft und Prior Art

| Feld | Wert |
|---|---|
| ID | `AP-2026-005` |
| Ziel | Öffentliche SQL-Server-Toolbox-, Capability-, Test-, Diagnose-, Maintenance- und Parallelisierungsprojekte systematisch vergleichen, belastbare Prior Art für die bereits erfassten Execution-Themen dokumentieren und neue Toolbelt-Lücken ableiten. |
| Scope | Landschaftsdokument mit direkter Einordnung von 16 Projekten; vertiefter Vergleich der direkten Capability-Libraries; zweite Session, rollback-unabhängiges Logging, Parallelisierungsprovider, Console, Error Handling und Cancellation; Präzisierung von `TC-2026-012`; neue Kandidaten `TC-2026-023` bis `TC-2026-028`; quellenbasierte Vorprüfung des persönlichen Brainstorms einschließlich PowerShell, Python, REST/Web und KI/Chat. |
| Dependencies | `AP-2026-001`, `AP-2026-004`, Repository-Grenzen, Third-Party-/Source-Policy und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Projekte nach Rolle, Technik, Packaging, Lizenz-/Statushinweis und Repository-Ziel eingeordnet; direkte Analogien von bloßen Skriptkatalogen getrennt; Prior Art für zweite Session, Parallelisierung, Host-Automation, Python, REST und KI aus Primärquellen dokumentiert; übertragbare und zu vermeidende Muster benannt; neue Kandidaten vollständig und ohne Implementierungszusage erfasst. |
| Tests | Quellen- und Linkstrukturprüfung; Duplikatprüfung gegen kuratierte Kandidatenlisten, persönlichen Brainstorm und Architekturverträge; Third-Party-, Datenschutz- und Secret-Gate; ausschließlich Dokumentations- und Backlogänderungen. |
| Blocker | Keine für Research; Codeübernahme benötigt zusätzlich eine datei- und versionsbezogene Lizenzprüfung. Jede Funktion benötigt vor Implementierung weiterhin eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md`, präzisierter Kandidat `TC-2026-012`, aktualisierte Kandidaten `TC-2026-014`/`TC-2026-015` und neue Kandidaten `TC-2026-023` bis `TC-2026-028`; geprüft am 2026-07-29. |
| Nächster Schritt | Forschungsergebnis nach Abschluss der ResultTable-Validierungswelle mit dem Benutzer priorisieren; keine automatische Aktivierung eines weiteren Implementierungsarbeitspakets. |

### AP-2026-004: Backlog Research Wave 2 – Execution Infrastructure

| Feld | Wert |
|---|---|
| ID | `AP-2026-004` |
| Ziel | Die vom Benutzer angestoßenen Ideen zu zweiter Session, rollback-unabhängigem Logging, Parallelisierung, Error Handling, Console-Ausgabe und Gruppenabbruch quellenbasiert erfassen und um unmittelbar notwendige Supporting Capabilities ergänzen. |
| Scope | `TC-2026-014` bis `TC-2026-022`; Toolbelt-Kandidaten für autonome Ereignisprotokollierung, Work Queue, Console, Error Envelope, Cancellation, Correlation, Retry/Dead-letter, Worker Lease und sicheren Work-Type-Katalog. |
| Dependencies | Repository-Grundaufbau, Backlog-Curator-Regeln und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, vollständige Felder, Primärquellen, klare Trennung dokumentierter Engine-Semantik von offenen Architekturentscheidungen sowie einen nächsten Besprechungsschritt; kein Runtime-Objekt und keine Implementierungsfreigabe werden erzeugt. |
| Tests | Duplikatprüfung gegen alle drei Kandidatenlisten und bestehende Architekturverträge; Quellenprüfung gegen Microsoft Learn und den Microsoft SQL Server Blog; Datenschutz- und Secret-Gate. |
| Blocker | Keine für die Research-Erfassung; jede spätere Funktion benötigt eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Backlog/TOOLBELT_CANDIDATES.md`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | Kandidaten einzeln nach Nutzen und Abhängigkeiten mit dem Benutzer besprechen; keine automatische Aktivierung als Implementierungsarbeitspaket. |

### AP-2026-002: ResultTable-Infrastruktur implementierungsreif spezifizieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-002` |
| Ziel | Den Kandidaten `TC-2026-003` als erstes `toolbelt_core`-Modul ohne offene Vertragsfragen spezifizieren. |
| Scope | Modulgrenze, Objektinventar, öffentliche Schnittstelle, Schemaquelle, Metadaten- und Datentypnormalisierung, `@KeepData`, Preflight, DDL, Transaktionen, Fehler, Deployment, Lifecycle und Testmatrix. |
| Dependencies | `TC-2026-003`, `USP_CONTRACT.md`, Modul- und Deployment-Modell. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Modul-ID und Scope festgelegt; einzige Procedure klassifiziert; keine ungeregelten weiteren persistenten Objekttypen benötigt; Referenztabellen- und Vertrauensgrenze definiert; interne Temp-Namensregel festgelegt; Fehler-, Transaktions-, Collation-, Datentyp-, Deploy- und Uninstall-Verträge dokumentiert; vollständige Testmatrix vorhanden. |
| Tests | Statischer Abgleich gegen USP-Vertrag, T-SQL-Regeln, Modul-/Deployment-Modell, Namenskonventionen, Datenschutz, Supportmatrix und Architekturentscheidungen; Runtime-Tests für diese reine Designwelle `not applicable`. |
| Blocker | Keine |
| Evidenz | `Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md`, `Tests/RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017`; geprüft am 2026-07-29. |
| Nächster Schritt | `AP-2026-003` ausführen. |

### AP-2026-001: Backlog Research Wave 1

| Feld | Wert |
|---|---|
| ID | `AP-2026-001` |
| Ziel | Eine erste belastbare, versionsbezogene Kandidatenwelle für SQL Server 2019, 2022 und 2025 erstellen. |
| Scope | `Backlog/TOOLBELT_CANDIDATES.md`; vorhandene Kandidaten präzisieren und neue Compatibility-, Core-, String-, Datetime-, JSON- und Binary-Kandidaten erfassen. |
| Dependencies | Repository-Grundaufbau und Backlog-Curator-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, Ziel-Repository, Versionsbezug, spätere native Funktion, Nutzen, Technologieoptionen, Performance-/Security-Aspekte, Plattformgrenzen, Duplikatprüfung, Primärquellen, Prüfdatum und nächsten Schritt. |
| Tests | Primärquellenprüfung gegen Microsoft Learn; Duplikatprüfung innerhalb der Toolbelt-Listen; Abgrenzung zu `SQL_Server_Analyze`; Fakten und offene Punkte getrennt formuliert. |
| Blocker | Keine |
| Evidenz | `TC-2026-001` bis `TC-2026-013`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | Weitere Kandidatenwellen nach Abhängigkeit oder durch den Backlog Curator ergänzen. |

## Vorlage

```markdown
### AP-YYYY-NNN: <Titel>

| Feld | Wert |
|---|---|
| ID | AP-YYYY-NNN |
| Ziel | <Messbares Ziel> |
| Scope | <Betroffene Module, Schemas und Objekte> |
| Dependencies | <Arbeitspakete, Module oder externe Voraussetzungen> |
| Priorität | <P0 / P1 / P2 / P3> |
| Status | <proposed / researched / ready for development / active / blocked / completed / rejected> |
| Implementation Status | <nur für Module; aus module.yaml abgeleitet> |
| Validation Status | <nur für Module; aus module.yaml abgeleitet> |
| Release Status | <nur für Module; aus module.yaml abgeleitet> |
| Akzeptanzkriterien | <Überprüfbare Done-Bedingungen> |
| Tests | <Statische, Contract-, Runtime- und Plattformtests> |
| Blocker | <Bekannte Blocker> |
| Evidenz | <Commits, Pull Requests, Befehle, Workflows oder Testergebnisse> |
| Nächster Schritt | <Konkret ausführbare nächste Aktion> |
```

## Wiederaufnahme

Ein Chat allein ist keine dauerhafte Source of Truth. Entscheidungen, Prioritäten, Fortschritt und Blocker müssen in dieser Datei oder in `Documentation/Architecture/DECISIONS.md` nachvollziehbar festgehalten werden.

### Clone W1: zusätzliche Lifecycle-Sichtbarkeit einzeln freigegeben

Am 2026-10-02 bestätigte der Benutzer nach konkreter Besprechung: "Ja, Lifecycle-Sichtbarkeitsgate freigeben". Bestehendes DB-VIEW DEFINITION und SELECT auf sys.sql_expression_dependencies werden für Deploy/Uninstall vor Änderungen und unter AppLock vorausgesetzt; fehlender oder unklarer Nachweis blockiert53926/2. Keine GRANT-Aktion. Computed-only53901/3 bleibt getrennt. Die finalen öffentlichen Adapter vom 2026-10-03 bestanden die native Lifecycle-Nachqualifikation einschließlich 0-/NULL-Predicate-Injektionen vor Änderungen und unter AppLock. CI am geprüften Head 76888216 bestanden; ein tatsächlicher Lowpriv-Principal bleibt offen.

### Tabellenklon W1: finaler öffentlicher Scope 2026-10-03

Am 2026-10-03 bestanden die finalen öffentlichen Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Vier Runtime-Fixtures einschließlich 27 Propertytypen und separater 18-datetimeoffset-Produktpfadregression, Client-/Lifecycle-/Caller-TX-/SET-/AppLock-/Rollback-/Kollisions-/Dependency-/Atomikorakel sowie genuine 1.0-Upgrades und eigene Bereinigung sind qualifiziert. Inputs und Genuine-Blobs sind hashgebunden; tatsächlicher Exit, vollständige Kanäle, exakt gebundenes Journal und frischer Cleanup-Audit wurden zusammen geprüft. Keine Konfigurations-, Rechte-, Trust- oder Infrastrukturänderungen. Der Zähler32 ist nur der Visibility-Teilbereich. CI am geprüften PR-Head 76888216 bestanden: alle sieben Checks SUCCESS einschließlich SQL Server 2019/2022/2025 Linux. Tatsächliche Minimalrechte mit eigenem Principal und weitere physische Ziele bleiben NOT_EXECUTED. Teilweise validiert und unveröffentlicht.

### XLSX-Anzeigeformatierung 1.2.0 – genehmigte Umsetzung

Stand 2026-10-04, Codex: die einzeln freigegebene Anzeige-TVF ist im bestehenden SAFE-Provider additiv implementiert. Acht Inputs, zwei Outputs, zehn Literalformate, en-US/de-DE/tr-TR, exakte SqlDecimal-Rundung half-away-from-zero, Datetimecarry/time24h-Status8 und unveränderte Typquote wurden konkret genehmigt. Raw-/Typquellen unverändert. Begrenzte aktuelle Offline- und lokale Nativequalifikation vom 2026-10-04 bestanden; zentrale1.2-Nutzung, vollständige Matrix, Minimalrechte und aktuelle Head-CI bleiben offen.

Am 2026-10-04 bestand ein privater Qualifikationsadapter auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 jeweils ausschließlich lokal: Clean1.2 und genuine installierte1.1→1.2 mit frischer Session, drei→vier CLR-Bindings und sieben→neun Slots am identischen aktuellen Binary. Je Ziel bestanden zwölf SQL-Fixtures, sechs Display-Clientprüfungen und zwei Raw→Type-/Raw→Type→Display-Kompositionen, Repeat sowie Uninstall/Repeat. Zwei eigene Datenbanken wurden entfernt und drei exakte Trust-Vorzustände wiederhergestellt; frische unabhängige Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte- oder Owneränderungen.

Dies ist ein begrenzter privater Adapternachweis, kein vollständiger öffentlicher Labadapter- oder Produkt-PASS. Zentrale1.2-Nutzung, genuine1.0→1.2, weitere CL/Ziele, vollständige Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und aktuelle exakte Head-CI bleiben offen. Status bleibt `partially validated`, `unreleased`. Keine neue Rechte-/Providergrenze.

Historische 1.0-/1.1-Nachweise bleiben getrennt. [Vertrag](../Documentation/Architecture/XLSX_CELL_DISPLAY_CONTRACT.md).

Ergänzung 2026-10-05, Codex: Der öffentliche Adapter-Slice
`DisplayCentral10Upgrade` bestand zentral auf Linux2019/latest CL150:
genuine1.0→1.2 mit frischer Session, neun Slots/vier CLR-Bindings, Display-Lifecycle,
Repeat, installierte Display.Contract/Safety sowie Clientmetadaten und
Raw→Type→Display aus frischer Consumerdatenbank. Confirm0/Uninstall, äußerer
eigener Prozesswatchdog und unabhängiger frischer OwnDB-/OwnTrustaudit bestanden;
keine Konfigurations-/Rechteänderungen. Diese konkreten zentralen Lücken sind
geschlossen; vollständige Lifecycle-/Kollisionsmatrix, weitere Ziele,
Minimalrechte und Heap bleiben offen. Status weiterhin teilweise validiert und
unreleased; keine neue fachliche API oder Providerfreigabe.

Ergänzung 2026-10-05, Codex: `DisplayCentralLifecycle` bestand auf demselben
Linux2019/latest-/central-/CL150-Ziel mit vier postDROP-/preCOMMIT-Rollbackfällen
und zwei AppLock-Abweisungen. Der vorhandene vollständige Lifecycle-Snapshot,
neun Slots/vier Bindings, exakter SAFE-Binaryhash und neutrale Session blieben
erhalten. Bestätigter Uninstall, äußerer eigener Prozesswatchdog und frischer
unabhängiger OwnDB-/OwnTrustaudit bestanden ohne Konfigurations-/Rechteänderungen.
Der frühere gemischte Setup-Prüflauf bleibt FAILED_CLEANED; ein gezielter
Read-only-Probe begründet die getrennte Sessionzustandsprüfung. API/Consumer/
Upgrades nicht wiederholt; Kollisionsmatrix, weitere Ziele, Minimalrechte und
Heap bleiben offen. Kein neuer Funktions-/Provider- oder Releaseumfang.

Ergänzung 2026-10-05, Codex: `DisplayCentralFutureCollisions4` bestand mit vier
Fremdslot-Fixtures auf genuine1.1 zentral Linux2019/latest CL150. Aktueller1.2-
Deploy weist ab und bewahrt vollständigen Snapshot; aktueller release-aware
Uninstall bewahrt exakten Fremdslot. Fünf genuine1.1-Installationen einschließlich
Setup/Restores, native Zeugen, finaler aktueller Uninstall, äußerer eigener
Prozesswatchdog und unabhängiger frischer OwnDB-/OwnTrustaudit bestanden ohne
Konfigurations-/Rechteänderungen. Originale Vorgänger-Uninstalls, weitere
Kontexte, Minimalrechte und Heap bleiben offen; keine erneute API-/Consumer-/
Upgrade- oder Lifecycle-six-Qualifikation.
