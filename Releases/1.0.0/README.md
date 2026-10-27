# SQL Server Toolbelt v1.0.0 vorbereiten

Der ergänzende [ZIP-Callerbericht](ZIP-CALLER-PROFILE.md) belegt begrenzte
Objektrechte und feste synthetische Ausgabeorakel für die bestehenden
Listing-, Extraktions- und Writer-USPs. Er ändert weder Modulstatus noch
Releasefreigabe.

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

[JSON Pointer mit einzelnem SELECT-Recht](POINTER-CALLER-QUALIFICATION.md): eine API, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

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

[Entwurf der Release Notes](RELEASE-NOTES.md) · [Releaseübersicht](../README.md)
