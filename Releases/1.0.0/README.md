# SQL Server Toolbelt v1.0.0 vorbereiten

Die [aktuelle direkte Vorgängermatrix](TABLE-CLONE-KNOWN-PREDECESSORS-QUALIFICATION.md)
belegt fünf echte öffentliche Versionen 2.0.0/3.0.0/3.1.0/4.0.0/4.1.0
gegen 4.1.1 auf 24 lokalen/direkt zentralen Windows-/Linux-SQL-Kontexten:
360 eindeutige Uninstall-/Upgrade-Rollback-/Direktupgradeprofile, zwölf
vollständige Läufe und zwölf frische Audits. Alle 24 eigenen DBs entfernt;
keine Fehler, Wiederholung grüner Profile, Produkt- oder Rechteänderung.
Ältere pauschale Offenangaben zu diesen direkten Vorgängerpfaden sind damit
erledigt; historische Teilnachweise und übrige Modulpflichten bleiben getrennt.

Die [aktuelle Planner-Fünfrechtematrix](TABLE-CLONE-PLANNER-RIGHTS-QUALIFICATION.md)
besteht auf 24 lokalen/direkt zentralen Windows-/Linux-SQL-Kontexten:
24 vollständige Originalfixtures mit gebundener interner Direktaufrufverweigerung
und zwölf frische Audits. Alle 24 temporären Benutzer und eigenen DBs entfernt;
keine Rechte außerhalb dieser eigenen DBs. Der gezielte Planner-Sichtbarkeits-
und Aufrufketten-Scope ist geschlossen; Executor-/Copy-/Trigger-Rechte sowie
andere Clients/Identitäten und Modulgesamtpflichten bleiben getrennt.

Die [aktuelle genuine V1-Lifecycle-Profilmatrix](TABLE-CLONE-GENUINE-V1-LIFECYCLE-QUALIFICATION.md)
belegt 240 eindeutige Profile auf 24 lokalen/direkt zentralen Windows-/Linux-
Kontexten: elf vollständige Fälle und ein Fall mit vier gebunden wiederverwendeten
Profilen plus bestandenem Restumfang. Beide ursprünglichen Koordinatoren bleiben
fehlgeschlagen. Alle 26 eigenen DBs entfernt, 14 frische Audits bestanden;
keine Rechte-/Produkt-SQL-/Server-/Labänderung. V1-Upgrade, aktuelles Uninstall,
Repeat und die drei gezielten Rollbackprofile sind damit belegt. Andere genuine
Zwischenversionen und übrige Modulpflichten bleiben getrennt.

Der [vollständige SQLCMD-Caller-Abbruch vom 2026-11-07](TABLE-CLONE-SQLCMD-CALLER-QUALIFICATION.md)
besteht auf zwölf Windows-/Linux-Engine-/CL-Paaren lokal/direkt zentral:
24 Kontexte, 96 vollständige Deploy-/Uninstall-Profile mit XACT_ABORT OFF/ON.
Einschließlich erhaltenem Erstfehler bestätigen 13 frische Audits die Entfernung
aller 25 angelegten eigenen DBs. Die geänderte Kindprozess-Isolation behebt
nur den Testadapter; Produkt-SQL, Rechte und Serverzustand bleiben unverändert.
Die früher pauschal offenen vollständigen SQLCMD-Caller-Includes sind damit
geschlossen. Linux-Clienthost und genuine Upgrade-/Uninstall-/Recoveryfälle
bleiben separat; ältere datierte Teilnachweise behalten ihren ursprünglichen Scope.

Die [aktuelle Windows-Client-Metadatenmatrix](TABLE-CLONE-WINDOWS-CLIENT-METADATA-QUALIFICATION.md)
belegt 24 lokale/direkt zentrale Windows-/Linux-SQL-Kontexte und zwölf frische
Audits. Das veraltete Zwölf-Help-Orakel ist auf dreizehn Parameter korrigiert;
alle 24 eigenen DBs entfernt, Produkt-SQL und Rechte unverändert. Linux-
Clienthost und vollständige Lifecyclepfade bleiben gesondert.

Der [aktuelle Table-Clone-Trigger-Consumer](TABLE-CLONE-TRIGGER-CURRENT-QUALIFICATION.md)
belegt zwölf Windows-Kontexte mit 24 vollständigen Originalfixture-Ausführungen
und sechs frischen Audits. Die einzige Produktänderung korrigiert den exakten
Parserhash im Option-1-Gate. Die folgenden Option-0-Nachweise werden mit
geprüfter Quellenäquivalenz wiederverwendet; eigene Ressourcen sind bereinigt.

Die [aktuelle W1-/W2-Zielmatrix](TABLE-CLONE-W1-W2-QUALIFICATION.md) besteht
auf 24 Kontexten mit 168 vollständigen Originalfixture-Ausführungen und
13 frischen Audits. Erstfehler, gezielte Adapterkorrektur und SQL-freie
Fristreparatur bleiben getrennt; alle 25 tatsächlich angelegten DBs entfernt.

Die [aktuelle Table-Clone-Planner-/Executor-Matrix](TABLE-CLONE-PLANNER-EXECUTOR-QUALIFICATION.md)
belegt vier unveränderte 4.1.1-Fixtures auf 24 Kontexten mit 96 Ausführungen
und zwölf frischen Audits. Rechte, weitere Profile und Modulgesamtfreigabe
bleiben separat; alle 24 eigenen DBs sind entfernt.

Die [nichtleere Constructor-USP-ACL-Matrix](JSON-CONSTRUCTORS-NONEMPTY-ACL-QUALIFICATION.md)
besteht am 2026-11-08 nach neuer ausdrücklicher Freigabe auf 24 lokalen/direkt
zentralen Windows-/Linux-SQL-Kontexten: zwölf vollständige Originalkoordinatoren
und zwölf frische Audits, 120 erhaltene Prozeduridentitäten und 96 Objektgrants
über Rollback, echtes Upgrade und Repeat. Alle 24 Benutzer und DBs entfernt,
96 eigene Grants widerrufen; Konfiguration/Trust wiederhergestellt.
Die zwei vorherigen bereinigten Fehlläufe behalten ihre eigenen Audits und
geschlossenen Grenzen. Der ausgewählte Vier-USP-Erhaltungsumfang ist damit
geschlossen; direkte CLR-/Assembly-ACLs, andere Owner, Netzwerk-/CrossDB- und
Linux-Clienthostfälle sowie die Modulgesamtqualifikation bleiben getrennt.

Der [exakte native129-Byte-Geography-Nachweis vom2026-11-07](GEO-EXACT129-QUALIFICATION.md)
schließt den bisher unbeobachteten Grenzoperand auf24 lokalen/direkt zentralen
Kontexten Windows/Linux2019/2022/2025 über alle unterstützten CLs:24 gemessene
129-Byte-Ablehnungen mit ErrorCode15/NULL und24 gültige Punkt-Kontrollen,
zwölf frische Audits,alle24 eigenen DBs entfernt. Keine Rechte-/Principal-/
CLR-/Trust-/Serveränderung. Die älteren129er-Integer- und128/>128-UDT-Belege
bleiben mit ihren ursprünglichen Grenzen erhalten; keine Modulgesamtfreigabe.


Der [direkte Aggregate-Minimalrechtetest](JSON-CONSTRUCTORS-AGGREGATE-CALLER-QUALIFICATION.md)
besteht seit2026-11-07 die ausdrücklich freigegebenen zwei temporären EXECUTE-
Objektrechte auf24 lokalen/direkt zentralen Kontexten Windows/Linux2019/2022/2025
über alle unterstützten CLs:48 positive Profile,144 SQL229-Abweisungen und zwölf
frische Abschlussaudits. Alle24 eigenen DBs/Benutzer entfernt, Trust/Konfiguration
wiederhergestellt. Zwei frühere bereinigte Adapterfehler samt separaten Audits
bleiben erhalten; acht Offlinegegenproben bestanden. Kein Netzwerk-/CrossDB-
Login-, Linux-Clienthost- oder Modulgesamt-PASS.


Der [korrigierte XLSX-SST-Quellkandidat](XLSX-SST-BUDGET-CORRECTION.md)
besteht 50.000/50.001 Shared Strings auf zwölf lokalen/direkt zentralen
Ziel-/CL-Fällen bei unverändertem 5.000-ms-Budget. Der aktuelle
[CLR-Wartungskandidat](CLR-MAINTENANCE.md) übernimmt diese DLL und besteht
zwölf neue lokale/direkt zentrale Installations-, Hilfe- und SST-Fälle samt
zwölf unabhängigen Audits. Das historische Basispaket, seine früheren
Paketnachweise und der dortige Budgetblocker bleiben getrennt erhalten.
Die [Hilfe-/Parameterkorrekturen](HELP-CONTRACT-MAINTENANCE.md) erläutern
die weiteren bestehenden Prozeduren und die fünf freigegebenen ResultTable-Routen.

Die [XLSX-Grenzprüfung](XLSX-BOUNDARY-QUALIFICATION.md) besteht für die feste
32/33-Blattgrenze von `USP_ListXlsxWorksheets`. Der getrennte 50.000-Shared-
String-Test blieb nach zwei lokalen Budgetfehlern `BLOCKED_BUDGET`; 50.001 und
zentrale Routen wurden nicht ausgeführt. Die [Evidenzdatei](xlsx-boundary-qualification.json)
bindet Paket-DLLs und Eingabepins.

Der [XLSX-/ZIP-Writer-Paketnachweis](XLSX-ZIP-PACKAGE-FRAMEWORK-QUALIFICATION.md)
bindet 19 bestehende XLSX-Candidate-Frameworkphasen und den bestehenden
ZIP-Writer-/Entry-Security-Vertrag an die Installationspaket-DLLs. Er ersetzt
keine vollständige Modul- oder SQL-Qualifikation.

Der ergänzende [ZIP-Callerbericht](ZIP-CALLER-PROFILE.md) belegt begrenzte
Objektrechte und feste synthetische Ausgabeorakel für die bestehenden
Listing-, Extraktions- und Writer-USPs. Er ändert weder Modulstatus noch
Releasefreigabe.

Die [ZIP-Entryanzahl-Grenzprüfung](ZIP-ENTRY-COUNT-QUALIFICATION.md) ergänzt den bestehenden ZIP-Callerbericht um feste 10.000-/10.001-Entry-Grenzfälle der Listing-API. Sie ist keine vollständige ZIP- oder Modulqualifikation; Modulstatus und Veröffentlichung bleiben unverändert. Die [Evidenzdatei](zip-entry-count-qualification.json) bindet Paket-DLL und Eingabepins.

Die [ZIP-Manifest- und Paketpflege](ZIP-METADATA-UPDATE.md) übernimmt die
separat nachgewiesenen internen FT- und ResultTable-Helperrechte exakt in das
Manifest und die gebundene CLR-Paketprojektion; SQL-/DLL-Payloads bleiben
unverändert.

Status: **Releasevorbereitung, nicht veröffentlicht**. Die Lieferpakete sind an
ihre dokumentierten Quell- und Prüfstände gebunden. Veröffentlichung, Tag und
GitHub-Release sind nicht freigegeben.

Die [aktuelle SSIS-Teilqualifikation und Paketbindung](SSIS-LOOKUP-QUALIFICATION.md)
trennt neue Windows-Nachweise von unverändert übernommenen Linux-Payloads und
nennt die weiterhin offenen Client-, Ressourcen- und Releasegates.

Für den aktuellen SSIS-Standard führt die
[Installations- und Bedienungsanleitung](../../Modules/toolbelt.tsql.ssis-debug/Documentation/CurrentInstallation.md)
zum reinen T-SQL-Installer, zur editierbaren Parameter-JSON und zum vollständigen
`DebugScript`. Ressourcenlimits werden über benannte SQL-Parameter gesetzt.
Die [aktuelle Paketmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.InstallPackage.Matrix.20261029.json)
belegt den gebundenen Paketvertrag auf zwölf Windows-/Engine-/CL-/Moduskontexten;
die [Prüfmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) grenzt
diesen Nachweis von den übrigen SSIS- und Releasegates ab.
Die [aktuelle Standalone-Installer-Matrix](ssis-current-standalone-installer-matrix.json)
ergänzt vier unverändert übernommene und acht neue lokale/zentrale Kontexte für
denselben festen T-SQL-Installer auf Windows SQL2019/CL150, SQL2022/CL150 und
CL160 sowie SQL2025/CL150, CL160 und CL170. Sie erweitert weder die getrennte
Binarymatrix noch die allgemeine Komponenten-/API-Qualifikation; die aktuelle
Head-/Main-CI wird am jeweiligen Integrationsstand nachgewiesen.
Der [frühere eigenständige SSIS-Installer](SSIS-INSTALL-TSQL.md) und seine
Nachweise bleiben historische Lieferungen; sie implementieren diesen aktuellen
Standard nicht. Keine Lieferung ist zur Veröffentlichung freigegeben.

Für den ersten praktischen Test beginne mit der
[Installationsanleitung für SSMS](../../INSTALL.md). Sie benötigt für die
stabilen T-SQL-Kandidaten keinen eigenen Build. Die folgenden Abschnitte
erklären Lieferumfang, Paketpflege und Freigabegrenzen.

Für den schnellen SQL-Einstieg gibt es das eigenständige
[Stable-SQL-ZIP](InstallPackages/SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip) mit
[SHA-256-Prüfsumme](InstallPackages/SQL-Server-Toolbelt-1.0.0-Stable-SQL.zip.sha256).
Die [kurze Anleitung](STABLE-SQL-INSTALL.md) beschreibt Installation und Kontrolle.
Es enthält genau die beiden bereits qualifizierten SQL-Payloads, unveränderte
Lizenz, Anleitung, Herkunftsmanifest und Dateiprüfsummen. Dies ergänzt die
Lieferform; Modulstatus, Support- und Veröffentlichungsgrenzen bleiben bestehen.

Die [Caller-Rechteübersicht](CALLER-METADATA-UPDATE.md) erklärt die korrigierten
Einzelrechte für sechs Module und die getrennten historischen Nachweise.

Die [JSON-Constructor-Paketqualifikation](JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.md)
bindet den vorhandenen Framework-/IL-Nachweis an die Constructor- und Core-DLLs
aus dem CLR-Installationspaket. Sie ist ein begrenzter Offlinebeleg und ändert
keinen Modulstatus.

Die [direkte Constructor-Clientmatrix](JSON-CONSTRUCTORS-CLIENT-METADATA-QUALIFICATION.md)
ergänzt separat24 lokale/direkt zentrale Windows-/Linux-SQL-Kontexte mit
480 Reader-/Help-/ResultTable-/AGF-Rückgabetyp-Profilen und zwölf frischen Audits.
Keine neue Rechte-/Identitätsvergabe, kein Linux-Clienthost oder Modulgesamt-PASS.

Die [aktuelle genuine Constructor-Migrationsmatrix](JSON-CONSTRUCTORS-CURRENT-MIGRATION-QUALIFICATION.md)
belegt bekannte1.2→1.3 mit aktuellem Core/Schema-Consumer auf24 lokalen/direkt
zentralen Windows-/Linux-SQL-Kontexten, zwölf frischen Fallaudits und sechs
abschließenden Konfigurations-/Trustaudits. Historische Quellenbindungen bleiben
getrennt; keine Owner-/Rechteerweiterung oder vollständige Modulfreigabe.

Die getrennte [JSON-Schema-Paket-IL-Qualifikation](JSON-SCHEMA-PACKAGE-QUALIFICATION.md)
bindet die Schema-DLL bytegenau an das geprüfte Installationspaket und führt
den vorhandenen IL-Guard direkt auf dieser Paket-DLL aus. Sie verwendet den
unveränderten erfolgreichen Source-Framework-Receipt; SQL, Modulstatus und
Veröffentlichungsfreigabe bleiben davon unberührt.

Die [Edit-Distance-Paketqualifikation](EDIT-DISTANCE-PACKAGE-QUALIFICATION.md)
bindet die gelieferte DLL an feste Distance- und Jaro-Frameworkorakel sowie
eine begrenzte IL-Inspektion. Sie ist keine vollständige CLR- oder
Sicherheitsqualifikation und ändert weder Modulstatus noch Veröffentlichung.

Die [begrenzte Scriptparser-Paketbindung](SCRIPT-PARSER-PACKAGE-QUALIFICATION.md)
prüft den gelieferten Provider gegen 63 festgelegte Parserfälle. Ein separater
60-Assertions-Source-Guard ist nicht paketgebunden. Vollständige Modul-,
SQL-, IL- und Deploymentqualifikationen bleiben davon unberührt. Die
[maschinenlesbare Evidenz](SCRIPT-PARSER-PACKAGE-QUALIFICATION.json) enthält
die 16 repo-relativen Eingabepins.

Die [CSV- und Phonetic-Framework-Paketprofile](CLR-FRAMEWORK-PACKAGE-QUALIFICATION.md)
binden die beiden unveränderten Frameworkharnesses an die gelieferten DLL-Bytes.
CSV besteht drei Kulturphasen mit gemessenen Assertionzahlen; Phonetic besteht
223 feste Assertions je Kultur. Die Prüfung führt kein SQL aus und ist keine
vollständige Modul-, Plattform-, Sicherheits- oder CLR-Suitequalifikation.

[XLSX-Raw-Callerrechte](XLSX-RAW-CALLER-PROFILE.md): zwei bestehende Rohleser-USPs mit einem schmalen Objektprofil auf zwölf lokalen/direkt zentralen Windows-/Linux-Ziel-/CL-Fällen. 14 Masken je Kontext, 672 direkte-/ResultTable-Routen, 144 positive Aufrufe und 720 feste Ergebniszeilen. Der [maschinenlesbare Bericht](xlsx-raw-caller-profile.json) bindet Quellen, synthetisches Workbook, Kontrollen und Bereinigung. Weitere Modul-, Paket- und Veröffentlichungsfreigaben bleiben offen.

[XLSX-Manifest- und Paketpflege](XLSX-METADATA-UPDATE.md) übernimmt die in PR #452 und #453 gebundenen Zell- und Rohleserrechte in das Manifest und den bestehenden CLR-Installationssatz. Native Quellberichte bleiben unverändert; SQL- und DLL-Payloads bleiben bytegleich.

## Was enthalten ist

[XLSX-Zell-Callerrechte](XLSX-CELL-CALLER-QUALIFICATION.md): zwei öffentliche TVFs mit einzelnem SELECT auf zwölf lokalen/direkt zentralen Windows-/Linux-Ziel-/CL-Fällen.48 positive Profile,672 SQL229-Abweisungen und144 feste Ergebniszeilenorakel; Raw-Reader, volle Typ-/Client-/Ressourcen- und Releasegates bleiben separat.

[CSV-Manifest- und Paketpflege](CSV-METADATA-UPDATE.md): die in PR450 belegten getrennten Parser-/Writer-/ResultTable-Rechte werden exakt übernommen. Historische Ausführungspins bleiben erhalten; ausführbare SQL-/DLL-Payloads und weitere Releasegrenzen bleiben unverändert.

[CSV-Callerrechte](CSV-CALLER-PROFILE.md): getrennte Parser-/Writer-/ResultTable-Objektrechte, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 384 Rechtezustände, 504 feste Ergebniszeilenorakel und frische eigene Bereinigungsprüfungen. Manifest-/Paketpflege und weitere Releasegates bleiben separat.

Alle 45 implementierten Module mit ihren unveränderten Modulversionen,
SQL-Quellen, vorhandenen CLR-Buildskripten, Deployment, Beispielen, Workern,
Dokumentation, Tests und Lizenzen sind im **Quellpaket-Kandidaten** enthalten.
Zusätzliche eigenständige SQL-Dateien bündeln die stabilen Kandidaten für
lokales beziehungsweise zentrales Deployment. Sie ändern keine öffentlichen
SQL-Verträge und werden durch den bestehenden Offline-Exporter erzeugt.

Die [Freigabematrix](FREIGABEMATRIX.md) unterscheidet 19 stabile und 26
Preview-Kandidaten. Der [Support-Zielumfang](SUPPORT.md) und die Kanalzuordnung
sind seit 2026-10-23 ausdrücklich freigegeben. Ausgangspunkt ist der Manifest-Prüfstatus; transitive
Preview-Dependencies begrenzen den Kanal. Deshalb sind Second Session und
Event Log trotz eigenem `validated` vorläufig Preview. Vor Veröffentlichung
bleibt die vollständige Pflichtqualifikation jeder zugesagten Kombination erforderlich.

Die [Nachweiszuordnung aller 45 Module](EVIDENCE-MAP.md) führt zu den
kanonischen Modulbelegen. Der [API-/Grenzbericht](API-QUALIFICATION.md)
trennt zusätzliche Labprüfungen von weiter offenen externen Voraussetzungen.
Die [Regex-Timeout-Nachprüfung](REGEX-TIMEOUT-QUALIFICATION.md) belegt die
Korrektur der Literal-Replace-Materialisierung. Das anschließende historische
Capture-Timeout-Gate ist für die gebundene DLL mit ausdrücklich angenommenem
Restrisiko [begrenzt abgeschlossen](CAPTURE-RELEASE-ACCEPTANCE.md); weitere
Modul- und Paketgates bleiben offen.

Die [CLR-String-Callerrechte](CLR-STRING-CALLER-QUALIFICATION.md) ergänzen
fünf vorhandene Phonetic-/Edit-Distance-TVFs auf zwölf lokalen/direkt zentralen
Ziel-/CL-Fällen. Der neue Labtreiber prüft isolierte SELECT-Profile und eigene
Trust-/Konfigurationsbereinigung; Produktimplementierung und weitere Modulpflichten
bleiben separat.

[Textpaar-Callerrechte](TEXT-PAIRS-CALLER-QUALIFICATION.md): ein EXECUTE-Grant, drei Algorithmen, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 24 positive Profile und 216 SQL229-Abweisungen. 1008 feste Zeilenorakel und eigene Bereinigung sind belegt; weitergehende Gates bleiben separat.

[JSON-Schema-Callerrechte](JSON-SCHEMA-CALLER-PROFILE.md): drei einzelne Objektrechte, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 168 Rechtezustände und 240 feste Fachfälle. Neuer Labtreiber und SQL-Fixture; keine Produkt- oder Paketänderung. Das pauschale EXECUTE-Manifestlabel bleibt als Paketpflege offen.

Die [Execution-Context-Minimalrechte](EXECUTION-CONTEXT-RIGHTS-QUALIFICATION.md)
sind für alle fünf öffentlichen APIs mit jeweils einem einzelnen Objektrecht
lokal und direkt zentral auf zwölf Ziel-/CL-Kombinationen geprüft.
Echte CrossDB-Identitätsmappings und andere Modulpflichtfälle bleiben separat.

Die [Split-Advanced-Callerrechte](SPLIT-ADVANCED-RIGHTS-QUALIFICATION.md)
sind mit dem [ergänzenden CL-Abschluss](SPLIT-ADVANCED-CL-COMPLETION.md)
lokal/direkt zentral auf allen zwölf Ziel-/CL-Kombinationen belegt: sechs
neue niedrigere CL-Fälle und sechs unverändert wiederverwendete Fälle.
Drei Einzelgrants und der Helperpfad bleiben getrennt; weitere Modulpflichtfälle offen.
Die [aktuelle Funktions-/Clientmatrix](SPLIT-ADVANCED-CURRENT-QUALIFICATION.md)
ergänzt 24 Kontexte mit 96 Original-SQL-Fixtures und 24 Clientproben,
zwölf frischen Audits und entferntem eigenem DB-Scope. Die Bindung der alten
Rechtepfade und aktuelle Hilfeausgabe werden ausdrücklich getrennt; weitere
Lifecycle-/Collation-/Ressourcen-/Identitätsfälle bleiben offen.

Die [gezielte aktuelle Lifecyclematrix](SPLIT-ADVANCED-LIFECYCLE-QUALIFICATION.md)
ergänzt 240 neue Profile auf 24 lokalen/zentralen CS_AS-/BIN2-Kontexten mit
zwölf frischen Audits. Exakte Versions-/Bestätigungs-/Consumerabweisungen,
kanonische Drift-/Typreparatur, Fremdobjekterhalt, Neuinstallation und fehlendes
Uninstall sind darin belegt; weitere Modulpflichten bleiben getrennt.

Die [Split-Advanced-AppLockergänzung](SPLIT-ADVANCED-APPLOCK-QUALIFICATION.md)
belegt 24 weitere Moduskontexte mit 96 Sperr-/Freigabeprofilen und zwölf frischen
Audits: exakte 51677/State1-Abweisungen von Deploy/Uninstall unter bestätigter
zweiter Sitzungssperre, Erfolg nach verifiziertem Release, Core erhalten und alle
24 eigenen DBs entfernt. Kein allgemeiner Race-/Recovery- oder Gesamtmodulnachweis.

Die [Queue-Frontend-Callerrechte](QUEUE-FRONTEND-RIGHTS-QUALIFICATION.md)
ergänzen sechs Producer-/Status-/Viewprofile. Die
[Worker-Callerrechte](QUEUE-WORKER-RIGHTS-QUALIFICATION.md) ergänzen sieben
Worker-APIs und die befüllte Blockerview auf zwölf Ziel-/CL-Kombinationen.
Damit bestehen direkte Callerprofile aller 13 öffentlichen APIs; Managed-/
Provider-/ResultTable- und weitere Betriebsvarianten bleiben separat.

Die [zusätzliche Geo-SQL-Matrix](GEO-MISSING-TARGETS-QUALIFICATION.md) ergänzt
acht bisher fehlende Ziel-/CL-Kombinationen lokal/direkt zentral mit unveränderten
Geo-/Safety-/SQL-Metadatenverträgen. Sie erweitert weder historische
Client-/Lifecycle-Abnahmen noch den Modulstatus oder die Veröffentlichung.

Die [Konvertierungs-Callerprofile](CONVERSION-CALLER-QUALIFICATION.md) ergänzen
16 öffentliche Base64-/IntegerBase-/URI-Funktionen einschließlich Status-TVFs
und Scalarwrappern: zwölf lokale/direkt zentrale Ziel-/CL-Fälle mit einzelnen
SELECT-/EXECUTE-Grants. Veraltete pauschale Manifestlabels bleiben ausdrücklich
als getrennte Metadaten-/Paketlücke dokumentiert; keine Statusaufwertung.

Die [Series-/Datums-Callerprofile](SERIES-DATE-CALLER-QUALIFICATION.md) ergänzen
neun öffentliche GenerateSeries-/DateSpine-/Truncate-TVFs einschließlich der
begrenzten Series-Status-API. Zwölf lokale/direkt zentrale Ziel-/CL-Fälle belegen
je ein SELECT; interne Core-/Helperrechte und andere APIs bleiben getrennt.
Keine Erweiterung alter Last-/Client-/Lifecycle- oder CrossDB-Nachweise.

Die [Utility-Callerprofile](UTILITY-CALLER-QUALIFICATION.md) ergänzen16 öffentliche
Bit-/Trim-/Split-/Identifier-/SemVer-Funktionen mit getrennten SELECT-/EXECUTE-
Grants auf zwölf lokalen/direkt zentralen Ziel-/CL-Kombinationen. Opake Sort Keys
werden nach ihrem Ordnungsvertrag geprüft; breite Rechte bleiben ausgeschlossen.
Andere API-/Ressourcen-/Lifecycle- und Paket-/Metadatengates bleiben separat.

Die [ausgewählten Date-Math-Callerprofile](DATE-MATH-HIGHEST-CL-QUALIFICATION.md)
belegen vier TVFs auf Windows/Linux SQL2019/CL150,SQL2022/CL160 undSQL2025/CL170
lokal/direkt zentral als damaligen Teilscope. Die [additive Ergänzung](DATE-MATH-CL-COMPLETION.md)
schließt inzwischen die sechs niedrigeren CL-Fälle mit identischen Inputs.
Die volle Caller-Matrix umfasst zwölf Fälle; Modulstatus und weitere Gates bleiben separat.

Die [Pseudonymisierungs-Callerrechte](DETERMINISTIC-RIGHTS-QUALIFICATION.md)
sind für fünf Einzelgrantprofile und den getrennten Lookup-/Helperpfad
lokal/direkt zentral auf zwölf Ziel-/CL-Kombinationen geprüft. Weitere
Großwert-, Lifecycle- und CrossDB-Verträge behalten ihren eigenen Umfang.

Die [Cancellation-Callerrechte](CANCELLATION-RIGHTS-QUALIFICATION.md) bestehen
für alle drei APIs mit getrennten EXECUTE-/SELECT-Grants lokal/direkt zentral
auf zwölf Ziel-/CL-Kombinationen. Quoten-/Konkurrenz-/Lifecycle- und echte
CrossDB-Verträge bleiben eigene offene Nachweise.

Die [Safe-Cast-Callerrechte](SAFE-CAST-RIGHTS-QUALIFICATION.md) sind für alle
sechs TVFs mit je genau einem SELECT lokal/direkt zentral auf zwölf
Ziel-/CL-Kombinationen geprüft. Die bestehende volle Funktionsmatrix bleibt
getrennt; Lifecycle-DDL-Minimalrechte und echte CrossDB-Mappings bleiben offen.

Der [Queue-Autorisierungsvertrag](QUEUE-AUTHORIZATION-QUALIFICATION.md) besteht
auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral. Er prüft Producer-Policy,
Handler-Ausführbarkeit, DENY vor Idempotenzauskunft und Callertransaktionsschutz;
isolierte API-Minimalrechte und externer Workerbetrieb bleiben separat.

Die [Work-Type-Rechtequalifikation](WORK-TYPE-RIGHTS-QUALIFICATION.md) prüft
alle sechs öffentlichen APIs mit getrennten Objekt-, Handler- und Policyrechten
auf zwölf Ziel-/CL-Kombinationen lokal und direkt zentral. Sie ergänzt die
vorhandenen Funktionsbelege; Modulstatus und Paketbytes bleiben unverändert.

Die [ResultTable-/Error-Envelope-Callerprüfung](TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md)
hat zwölf Ziel-/CL-Kombinationen lokal und direkt zentral bestanden. Der
begrenzte Rechtebeleg und die vier früheren bereinigten Testfehler sind getrennt
ausgewiesen. CrossDB-Identitäten und weitere Releasegates bleiben offen.

Das Gesamt-ZIP enthält zusätzlich den
[CLR-Installationskandidaten mit fertigen DLLs](CLR-INSTALL.md). Er liefert alle
zwölf Toolbelt-CLR-Module und ScriptDom, SQL-Dateien mit eingebetteten Bytes,
explizite Trustwerte, Quellcode und Attributionen. Die vier Profile unterscheiden
Windows/Portable und local/central; das Windows-Dateisystemmodul bleibt lokal.
Auf dem Installationsrechner sind keine Buildwerkzeuge erforderlich.
SSIS-/Parser-/ScriptDom-Binaries bleiben exakt aus dem bestehenden qualifizierten
Satz erhalten. Die maschinenlesbare Lieferform steht pro Modul in
[release-plan.json](release-plan.json). Paketinstallation und vollständige
fachliche Releasefreigabe sind getrennt; Preview-Grenzen bleiben bestehen.
Der [native ODBC-Clientnachweis](CLR-CLIENT-QUALIFICATION.md) ergänzt die
Paketprüfung für den optionalen PowerShell-Helper mit expliziter SQL-Anmeldung.
Die [Regex-Rechtequalifikation](REGEX-RIGHTS-QUALIFICATION.md) belegt die engen
EXECUTE-Rechte für alle sechs Skalarfunktionen und erklärt die korrigierte
Dokumentation samt getrennter historischer und aktueller Produktbindung.

## Paket bauen und unabhängig prüfen

Voraussetzungen sind ein vollständiger Git-Checkout, Python 3.10 oder neuer
und PowerShell 7. Es werden weder SQL Server, `sqlcmd`, Labzugang noch
Verbindungsdaten benötigt. Die Python-Werkzeuge nutzen die Standardbibliothek.

Im Repositoryroot, nach Commit der Releasevorbereitung, in einem neuen
privaten Ausgabeordner; das versionierte ZIP wird dabei nicht überschrieben:

```powershell
python -B Scripts/Release/prepare_release.py --check
New-Item -ItemType Directory .runtime/release-rebuild
python -B Scripts/Release/prepare_release.py --build --source-commit HEAD `
  --output .runtime/release-rebuild/SQL-Server-Toolbelt-1.0.0-candidate-source.zip
python -B Scripts/Release/prepare_release.py `
  --verify .runtime/release-rebuild/SQL-Server-Toolbelt-1.0.0-candidate-source.zip
```

Das Zielverzeichnis muss bestehen; ZIP und Prüfsumme dürfen noch nicht
existieren. Für Wiederholungen einen neuen leeren Ausgabeort wählen. Der
Generator überschreibt keine bestehenden Pakete. Der ZIP-Inhalt kommt aus
dem ausdrücklich ausgewählten Commit. Die eigene Artefaktablage bleibt
ausgeschlossen, sodass kein ZIP sich selbst enthält. Gitmetadaten, ignorierte
Builds, Secrets und private `.runtime`-Daten werden nicht übernommen.
`PREPARATION.bundle` erhält einen reproduzierbaren Snapshotcommit mit exakt
demselben Quellbaum, ohne Paketablage und mit ausschließlich synthetischen
Autor-/Committerdaten (`Codex`, `codex@localhost`). Sein Parent ist der
bytegleiche synthetische Produkt-Snapshot aus [product-source.json](product-source.json).
Dieser ersetzt ausschließlich Commitmetadaten des Entwicklungsstands und
hat den darin genannten öffentlichen Main-Commit als Parent. Beide neuen
Snapshotobjekte sind im Bundle enthalten. Arbeitscommit-Metadaten,
`.git`-Konfiguration und Reflogs werden nicht übernommen. Dadurch
bleibt der Quellcommit nach Squash-Merge und Branchcleanup rekonstruierbar.
Der Prüfmodus importiert das Bundle nur in ein eigenes temporäres Repository;
der vorhandene Objektstore und seine Refs werden nicht geändert. Er braucht
die lokal verfügbare öffentliche Main-Basis, keinen Remote- oder Credentialzugriff.
Der frühere Arbeitsbranch und seine persönlichen Commitmetadaten sind für die
Prüfung nicht erforderlich. Auch der Plancheck kann die Produktbasis aus dem
prüfsummengebundenen lokalen Paket in einem privaten temporären Repository
wiederherstellen; er verändert dabei keine Checkout-Refs oder dessen Objektstore.
Für einen eigenen Neubau in einem frischen Checkout kann der Maintainer das
geprüfte `PREPARATION.bundle` aus dem entpackten Paket ausdrücklich lokal
importieren: `git fetch --no-tags --no-write-fetch-head <PREPARATION.bundle> refs/heads/preparation`.
Dieser lokale Import ergänzt immutable Gitobjekte und benötigt keinen
früheren Arbeitsbranch oder Netzwerkzugriff; Branches und Tags bleiben erhalten.
Der Paketbau erzeugt dazu nur unreferenzierte immutable Gitobjekte und einen
temporären eigenen Index. Der echte Index, Branches und Tags bleiben erhalten.
`preparation_origin_commit` nennt den Arbeitsstand als Herkunft; `source_commit`
bindet den bytegleichen bereinigten Snapshot. Die Herkunfts-ID ist kein
Veröffentlichungsnachweis.

`PACKAGE-MANIFEST.json` bindet jede Datei mit Größe und SHA-256 an den
Quellcommit und die unveränderte Produktbasis. `SHA256SUMS.txt` deckt auch
das Paketmanifest ab; die externe `.zip.sha256` bindet das gesamte Archiv.
Zeitstempel und Reihenfolge sind fest. Bytegleiche ZIPs werden bei identischen
Inputs und identischer Python-/Kompressionsruntime erzeugt; eine digitale
Herausgebersignatur oder native Installationsqualifikation folgt daraus nicht.

Der Prüfmodus erzeugt beide stabilen SQL-Exports erneut aus dem eingefrorenen
Gitstand und vergleicht ihre vollständigen Bytes. Er startet dafür ausschließlich
den vorhandenen Offline-Exporter; keine SQL-Verbindung wird aufgebaut.

Ein Fehler bei Manifest, Dependencyclosure, Quellbindung, Export oder
Paketintegrität stoppt den Vorgang. Es gibt keinen Git-, Provider- oder
Binaryfallback. Die [Release-Tests](../../Tests/Release/README.md) prüfen auch
negative Fälle und laufen über den bestehenden Dokumentationsworkflow.

## Auspacken und erster Test

1. Gesamte ZIP in ein neues Verzeichnis entpacken und `START-HERE.md` lesen.
2. Vor Ausführung die ZIP-Prüfsumme mit der separat aus demselben Stand
   bezogenen Prüfsumme vergleichen, wie in der Installationsanleitung erklärt.
   Die vollständige Source-/Paketprüfung mit dem obigen Prüfmodus bleibt
   Bestandteil der Paketpflege und CI und kann unabhängig in einem vollständigen
   Checkout wiederholt werden. Der referenzierte Quellcommit muss dort lokal
   verfügbar sein. Prüfsummen allein sind kein Herkunftsnachweis.
3. Den [Deploymentablauf](../../Deployment/README.md) und die Objektseiten der
   gewünschten Module lesen. Als erste Vorschau im entpackten Paket ausführen:

   ```powershell
   pwsh -File Deployment/Deploy-All.ps1 -DeploymentMode local `
     -ModuleId toolbelt.datetime.date-spine -PlanOnly
   ```

4. In einem eigenen Testsystem nur die bewusste Modulauswahl installieren und
   ein einzelnes synthetisches Objektbeispiel testen. Die beiden generierten
   `Install-Stable-local.sql` / `Install-Stable-central.sql` sind alternative
   Gesamt-Exports, keine automatisch ausgeführten Installer. SQLCMD-Modus,
   Fehlerabbruch, frische exklusive Sitzung und richtige Zieldatenbank sind
   erforderlich. Ein späterer Modulfehler rollt frühere Module nicht zurück.
5. Preview-Module separat auswählen. CLR, Trust, Dateifixtures oder
   Loopback-Provider gemäß den Modulregeln vorbereiten; das Paket ändert diese
   Voraussetzungen nicht. Uninstall folgt dem jeweiligen Modulvertrag.

Die gepackten Exports der 19 stabilen Kandidaten bestanden auf zwölf
Windows-/Linux-/SQL-/CL-Kombinationen Erstinstallation, Wiederholung,
zentralen Consumer und Uninstall. Der [Gatebericht](RELEASE-GATES.md)
nennt den exakten Scope, die Eingabebindung und den bereinigten Erstfehler.
Die [aktuelle CLR- und Gesamtpaketqualifikation](SSIS-LOOKUP-QUALIFICATION.md)
ergänzt jeweils sechs Windows-Engine-/CL-Kontexte mit lokaler, zentraler und
Consumer-Installation. Die Windows-Gesamtprofile enthalten 45 beziehungsweise
43 Module. Unveränderte Linux-Payloads behalten ihre ursprünglichen Nachweise.
Diese Paketprüfungen ersetzen keine noch offenen modulspezifischen Rechte-,
Speicher-, Parallelitäts-, Recovery- oder TLS-Gates.

## Ergänzende Teilnachweise

[Event Log: Lesen und lokale Retention mit Einzelrechten](EVENT-LOG-CALLER-QUALIFICATION.md): 3 APIs, zwölf Fälle lokal/direkt zentral, 72 Einzelgrantprofile und 648 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Providerview mit einzelnem SELECT-Recht](PROVIDER-CALLER-QUALIFICATION.md): eine API, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 144 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

Der [aktuelle CLR-String-Callerrechteabgleich](CLR-STRING-CALLER-CURRENT-BINDING.md)
ordnet die vorhandenen Phonetik-/Edit-Distance-SELECT-Profile ihren 29 unveränderten
Modulinputs zu. Pauschale ältere Datenpfad-Minimalrechte-Offenangaben sind
überholt; Lifecycle-DDL-/Owner-/CrossDB-Rechte und weitere Modulpflichten bleiben getrennt.

Der [aktuelle API-Quellenabgleich](CLR-STRING-API-CURRENT-BINDING.md) bestätigt
die vorhandenen Phonetik-/Edit-Distance-API-Fixtures auf jeweils zwölf Zielpaaren
lokal/direkt zentral; pauschale API-Ziellücken sind überholt, keine neue Matrix nötig.
Die [Edit-Distance-Neuausführung](EDIT-DISTANCE-MISSING-TARGETS-QUALIFICATION.md)
hatte diesen Record übersehen: 80 redundante API-Fixtures und 16 read-only
Baseline-Receipts mit Paketbytebindung, acht frische Audits, alle 16 eigenen DBs
entfernt. Verbrauch und Originale bleiben erhalten; übrige Modulpflichten getrennt.

[JSON Pointer mit einzelnem SELECT-Recht](POINTER-CALLER-QUALIFICATION.md): eine API, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

Die [kleine Pointer-Securityfixture](JSON-POINTER-SECURITY-QUALIFICATION.md)
ergänzt 18 neue und sechs gültig wiederverwendete lokale Linux-Kontexte.
Zwölf frische Audits bestätigen alle 18 eigenen DBs entfernt. Genau die beiden
festen WORK_LIMIT-/JSON_NULL-Orakel sind damit auf 24 Moduskontexten belegt;
keine neue Maximallast-/Heap-/Parallelitäts- oder Modulgesamtabnahme.

[Capability-Katalog mit einzelnem SELECT-Recht](CATALOG-CALLER-QUALIFICATION.md): eine API, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Konsolenausgabe mit einzelnem EXECUTE-Recht](CONSOLE-CALLER-QUALIFICATION.md): eine API, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[JSON-Pfade mit getrennten SELECT-Rechten](JSON-PATH-CALLER-QUALIFICATION.md): 2 APIs, zwölf Fälle lokal/direkt zentral, 48 Einzelgrantprofile und 192 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.


Die [additive Date-Math-Ergänzung](DATE-MATH-CL-COMPLETION.md) schließt die sechs niedrigeren CL-Callerfälle. Insgesamt zwölf Fälle mit unveränderter Fixture sind gebunden; der frühere Teilscope bleibt historisch erhalten. Offline zusätzlich prüfen: `python -B Tests/Release/test_additive_caller_qualification.py`.

## Vor einer Veröffentlichung

- Pro Modulversion die tatsächlich freizugebenden SQL-Versionen, relevanten
  CLs, Plattformen, Provider, Deploymentmodi und Dependency-/Consumerpfade
  abgrenzen; vollständige Pflichtnachweise fachlich prüfen. Auch Preview
  ersetzt keine fehlende Pflichtqualifikation im zugesagten Scope.
- Offene CSV-/Parser-/Datei-I/O-/Worker-/Recovery- und weitere Modulgrenzen
  aus der Matrix behandeln oder außerhalb des zugesagten Umfangs halten.
  Die Liste ist kein Auftrag für zusätzliche Entwicklungs- oder Labwellen.
- Den CLR-Installationskandidaten einschließlich seiner gebundenen Binaries,
  Trustwerte, Herkunft, Lizenzhinweise und abgegrenzten Paketnachweise in den
  konkret freigegebenen Lieferumfang aufnehmen. Keine spätere Binaryänderung
  ohne Prüfung der betroffenen Dependencies und Nachweise übernehmen.
- Endgültige Artefakte und deren Installationsweg prüfen; vollständigen
  Dokumentationsaudit und tatsächliche CI des endgültigen Heads nachweisen.
- Konkrete öffentliche Veröffentlichung separat freigeben. Erst danach
  tatsächliche URL, Tagcommit, Veröffentlichungszeit, Assethashes und
  Supportnachweise als `publication_record` pflegen und Modulstatus ändern.

Authentifizierte TLS-Abnahme und optionale Laufzeitmessungen bleiben getrennt.
Es werden kein Tag, GitHub-Release oder Veröffentlichungszeitpunkt vorgetäuscht.
Der [aktuelle Gatebericht](RELEASE-GATES.md) unterscheidet erledigte technische
Vorarbeiten, noch fehlende Nachweise und Entscheidungen zur Veröffentlichung.

## Quellen und Pflege

`module.yaml` bleibt Quelle für Version, Prüfstatus, Dependencies und Evidenz.
Der [Plan](release-plan.json) friert diese Daten und die Kanalvorschläge ein;
die Markdownmatrix wird daraus erzeugt. Nur für einen ausdrücklich geänderten
Produktstand `--refresh --product-commit <Commit>` verwenden und anschließend
alle betroffenen Nachweise erneut zuordnen. Die Prüfung verwirft Produktdrift
gegenüber der festgehaltenen Basis; sie wertet keinen Prüfstatus auf.

Die [historische erste File-Content-Restwelle](FILE-CONTENT-REPEAT-QUALIFICATION.md)
verwendete gültige Linux-CI-Nachweise weiter. Ihr Windows-Restkoordinator bleibt
FAILED_CLEANED mit frischem Audit PASS; die damals nur offline geprüfte
Rendererkorrektur belegte noch keine Gesamtmatrixabnahme oder Statusänderung.

Der [anschließende native Repeat-Abschluss](FILE-CONTENT-REPEAT-COMPLETION.md)
belegt die nach neuer Freigabe korrigierte Welle: 18 neue Kontexte, 36 Fixtures,
neun frische Audits und vollständig entfernter eigener DB-Scope. Mit den drei
belegten Linux-CI-Default-Paaren sind zwölf Engine-/CL-Paare lokal/zentral
abgedeckt. Die obige Sperraussage gilt historisch für die erste Welle;
weitere Modulpflichten und der ursprüngliche Fehlnachweis bleiben getrennt.

Die [zusätzliche File-Content-Lifecyclematrix](FILE-CONTENT-LIFECYCLE-QUALIFICATION.md)
belegt 288 gezielte Versions-/Kollisions-/Uninstall-/Neuinstallationsprofile auf
24 Windows-/Linux-Kontexten mit zwölf frischen Audits. Die Repeat-Matrix wurde
nicht wiederholt; weitere Modulpflichten bleiben getrennt.

Die [File-Content-AppLockergänzung](FILE-CONTENT-APPLOCK-QUALIFICATION.md)
belegt getrennte echte Sitzungen, exakte Sperrabweisungen und erfolgreiche
Deploy-/Uninstallpfade nach verifizierter Freigabe auf 24 Moduskontexten:
96 Profile, zwölf frische Audits, alle 24 eigenen DBs entfernt. Andere
Identitäts-/Race-/Betriebs- und Modulpflichten bleiben separat.

Die [File-Content-Definitionsdriftmatrix](FILE-CONTENT-DEFINITION-DRIFT-QUALIFICATION.md)
ergänzt 48 gezielte Reparaturen nach jeweils bestätigtem verändertem Prozedurbody
bei stabiler Objekt-ID: 24 Moduskontexte, erhaltene Allowlist-Zeilen/Identity und
Rechte, zwölf frische Audits, alle 24 eigenen DBs entfernt. Keine neue Datei-I/O,
Rechtevergabe oder Wiederholung der bereits grünen Vollfixtures; übrige Gates getrennt.

Der [aktuelle Phonetik-Frameworklauf](PHONETIC-CURRENT-FRAMEWORK-QUALIFICATION.md)
belegt 669 Assertions für die vorhandene DLL unter dem ausdrücklich neu
geprüften Compiler. Keine erneute Produktkompilierung oder SQL-Ausführung;
weiterhin nur dieser begrenzte Frameworkscope, keine Modulgesamtabnahme.

Die [JSON-Schema-Sessionergänzung](JSON-SCHEMA-XACT-ABORT-QUALIFICATION.md)
belegt vier neue frühe Caller-Guardfälle mit XACT_ABORT ON und NOCOUNT OFF/ON
bei fehlenden Modulen auf Windows2025/CU8 CL170. Bestehende Orakel wiederverwendet,
Caller/Savepoint/Daten/Optionen erhalten, frischer Audit und eigene DB-Entfernung
bestanden. Keine Modulinstallation oder neue Rechte; weitere Gates bleiben getrennt.

Die [File-Content-Sitzungsverlustprüfung](FILE-CONTENT-LEASE-RECOVERY.md) ergänzt
vier vollständige Deploy-/Uninstallfälle nach dem Ende eigener ruhender AppLock-
Halter auf Windows2025/CU8 CL170 lokal/zentral. Frischer Audit und beide eigenen
DB-Bereinigungen bestanden; zwei vorherige Adapterfehler bleiben getrennt.
Keine Rechteänderung oder aktive Mutations-/Host-/Transportunterbrechung.

[Entwurf der Release Notes](RELEASE-NOTES.md) · [Releaseübersicht](../README.md)

Die [echte gemappte Split-CrossDB-Identität](SPLIT-ADVANCED-MAPPED-CALLER-QUALIFICATION.md)
ist für SQL-Authentifizierung über TCP auf Windows2025/CU8 CL170 zentral
mit getrennter Consumer-DB belegt: drei gezielte DB-Rechte, sechs Profile,
strikter Widerruf und frischer Audit. Frühere DB-Benutzerprofile bleiben
unverändert gültig; andere Identitäts- und Netzwerkzielpfade bleiben separat.

## JSON Schema: Callerprofil XACT_ABORT OFF / NOCOUNT ON — 2026-11-09

Die [gezielte Ergänzung](JSON-SCHEMA-NOCOUNT-QUALIFICATION.md) belegt zwei neue frühe Caller-Guardfälle
für Deploy/Uninstall auf Windows2025/CU8 CL170 lokal bei fehlenden Modulen.
XACT_ABORT OFF/NOCOUNT ON tatsächlich geprüft; exakt50000/1/16, gesunde
Callertransaktion, Sessionoptionen, Snapshots, Zeugenwerte und Savepoint-/
Vollrollback sowie unabhängiger Observer erhalten. Frischer Audit PASS,
eigene DB entfernt, Konfiguration/Trust unverändert. Acht Offlinegegenproben
und kanonischer Preflight bestanden. 2/2 Aufrufe,1DB,45Minuten beim ersten
Versuch geschlossen; alte Fehler/Grenzen/Nachweise erhalten. Keine Assembly-/
Modulinstallation, neuen Rechte/Identitäten oder Produkt-/Manifeständerungen.
Bestehende OFF/OFF- und ON-Profile werden wiederverwendet. Installierter
Uninstall unter weiteren SET-Profilen, übrige Lifecycle-/Rechte-/Recovery-
und Modulpflichten bleiben separat; keine Veröffentlichung oder Tags.

## JSON Schema: installierte Uninstall-Callerprofile — 2026-11-09

Die [gezielte Ergänzung](JSON-SCHEMA-INSTALLED-SESSION-QUALIFICATION.md) schließt auf Windows2025/CU8 CL170 lokal
drei neue gesunde Callerfälle mit installiertem aktuellem Core/Schema:
Uninstall unter XACT_ABORT/NOCOUNT OFF/ON,ON/OFF,ON/ON. Exakte Guardmeldung,
Callertransaktion/Sessionbits/Snapshots, Zeugen-/Savepoint-/Vollrollbackwerte
und unabhängiger Observer bestanden. Frischer Audit PASS, eigene DB und zwei
eigene Releasehash-Trusteinträge entfernt, ursprüngliche Konfiguration/Trust
exakt erhalten. Aktuelle Registry-/Projekt-/Quell-/Paketbytebindung, zehn
Offlinegegenproben und kanonischer Preflight PASS. Erster Gesamtlauf COMPLETE;
zwei Aufrufe/eine DB innerhalb des gemeinsamen4-Aufrufe-/2-DB-/45-Minuten-
Rahmens, ungenutzte Korrekturreserve geschlossen. Keine alten Grenzen erneuert
und keine grünen OFF/OFF- oder Missing-Modulprofile wiederholt. Keine Builds,
Produkt-/Manifeständerungen, Grants/Principals/Owner-/Konfig-/Lab-/Datei-I/O.
Weitere Ziel-/SET-/Lifecycle-/Rechte-/Recoverypflichten bleiben eigenständig.
Keine Veröffentlichung oder Tags; private Originale erhalten.

## JSON Core: direkte Lifecycle-Sperrmatrix — 2026-11-09

Die [gezielte Ergänzung](JSON-CORE-APPLOCK-QUALIFICATION.md) belegt die direkte Core-Deploy-/Uninstall-
Sperrabwehr auf zwölf Windows-/Linux-Engine-/CL-Paaren lokal/direkt zentral:
24 Kontexte,48 exakte55627/1/16-Abweisungen unter eigener bestätigter
exklusiver Sitzungssperre,48 erfolgreiche Schritte nach verifizierter Freigabe.
Coreprojektion und lokale/externe Sitzungsneutralität erhalten, kanonischer
Repeat beziehungsweise vollständiger Uninstall geprüft. Vorhandene Schema-
Shared-Lock-Belege bleiben getrennt; keine API-Vollsuiten wiederholt.
Erster Adapterfehler wegen fehlendem SPID-Parameter bleibt FAILED_CLEANED;
Gegenprobe mit echtem Orakel reproduziert ihn, korrigierter Rest vollständig
PASS.26 verbrauchte Aufrufe/DB-Reservierungen im gemeinsamen28/28/45-Minuten-
Rahmen,25 tatsächlich angelegte DBs entfernt,13 frische Audits einschließlich
Fehlversuch. Eigene Trust-/notwendige CLR-Konfigurationsänderungen nach
bestehenden Freigaben vollständig zurückgenommen; fremde Zustände unverändert.
Keine neuen Builds, Produkt-/Manifest-/Statusänderungen, Grants/Principals/
Owner-/Lab-/serverseitige Datei-I/O. Weitere Owner-/ACL-/Drift-/Migrations-/
SET-/Ressourcen-/Recoverypflichten bleiben separat. Private Originale und
Quellkapseln erhalten; keine Veröffentlichung oder Tags.

## Executor: echtes begrenztes Anmelde-/Rechteprofil — 2026-11-09

Die [aktuelle Executor-Rechtematrix](TABLE-CLONE-EXECUTOR-RIGHTS-QUALIFICATION.md)
besteht auf zwölf Windows-/Linux-Engine-/CL-Paaren lokal/direkt zentral:
24 Kontexte, 144 Profile, zwölf erfolgreiche Gesamtläufe und zwölf frische Audits.
Je Fall ein eigener SQL-/TCP-Login mit genehmigtem VIEW ANY DEFINITION,
zwei exakt SID-gemappte Benutzer und sechs gezielte DB-Rechte; keine Rollen.
EXECUTE-/DDL-Abweisung, erfolgreicher hashgebundener Grundfall, Daten-/Helper-
Verweigerung und wirksamer EXECUTE-Widerruf bestanden. Alle 24 eigenen DBs und
zwölf Logins entfernt, Konfiguration und Trust unverändert. 24 von 28 Aufruf-/DB-
und zwölf von 14 Login-Reservierungen innerhalb von 45 Minuten; erster Versuch erfolgreich,
keine Wiederholung. Ältere pauschale Offenangaben zu Executor-Rechten sind für
exakt dieses Grundprofil erledigt. Erweiterte Executor-/Copy-/Trigger-Rechte,
FK-/ResultTable- und weitere Identitäts-/Recoverypflichten bleiben getrennt;
keine Modulgesamtaufwertung. Private Originale erhalten, nichts veröffentlicht.
## JSON Core: fünf direkte Lifecycle-Grenzen — 2026-11-10

Der [neue Teilnachweis](JSON-CORE-FIVE-BOUNDARIES-QUALIFICATION.md) prüft
Callertransaktionen ohne/mit Core, verwaiste DB-Marker, sechs typisierte
Assembly-Marker und Argument-/Consumer-Bestätigungen. Zehn Windows-/Linux-
Zielpaare bestehen lokal/zentral mit 730 Profilen; 28 gültige Originalprofile
bleiben erhalten. Insgesamt 758 von 876 Profilen belegt, 118 in zwei gezielt
vorbereiteten Restläufen noch nicht ausgeführt. Zwei ursprüngliche Adapterfehler
bleiben FAILED_CLEANED mit frischen PASS-Audits. Zwölf Audits insgesamt,
22 eigene DBs entfernt; Config/Trust im Vorzustand, keine neuen Rechte/Identitäten.
Der vorab gewählte Präfix-Retry-Stopp benötigt eine konkrete Ausnahme; kein
Gesamtabschluss der fünf Punkte oder des Moduls. Alte Sperr-/Consumerbelege
werden nicht wiederholt. Private Originale erhalten, keine Veröffentlichung.