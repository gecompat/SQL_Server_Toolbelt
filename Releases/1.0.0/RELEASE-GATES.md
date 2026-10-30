# v1.0.0: erledigte Prüfungen und offene Releasegates

[XLSX-/ZIP-Writer-Paketnachweis](XLSX-ZIP-PACKAGE-FRAMEWORK-QUALIFICATION.md):
19 bestehende XLSX-Candidate-Frameworkphasen und sieben ZIP-Entry-Security-Fälle
mit dem bestehenden Writer-Body bestanden. Paket-/Modulstatus blieb unverändert;
SQL, Deployment und Veröffentlichung sind nicht freigegeben.

[ZIP-Callerrechte](ZIP-CALLER-PROFILE.md): drei bestehende ZIP-Memory-USPs,
432 Maskenzustände, 864 API-Routen, 192 positive Orakel, 2.808 strikte
SQL-229-Abweisungen und 15 frische Abschlussaudits. Zwölf Matrixfälle
bestanden; die falsche Goldenwert- und breite Schema-SELECT-Kontrolle wurden
erwartungsgemäß bereinigt abgewiesen. Produkt-/Paketstatus und weitere
Releasegates bleiben getrennt.

[ZIP-Entryanzahl-Grenzprüfung](ZIP-ENTRY-COUNT-QUALIFICATION.md): zwölf Ziel-/CL-Fälle prüfen das 10.000-Entry-Limit der bestehenden Listing-API lokal und direkt zentral. 24 positive Routen lieferten 240.000 feste Metadatenzeilen; 48 direkte Reader-Pfade wurden ohne erste Zeile mit den festgelegten Fehlercodes abgewiesen. Zwölf unmittelbare und sechs zusätzliche Abschlussaudits bestanden. Der 256-MiB-Archivgrenzwert und vollständige Modulpflichten bleiben außerhalb dieses Scopes.

[XLSX-Raw-Callerrechte](XLSX-RAW-CALLER-PROFILE.md): zwölf ausgewählte Ziel-/CL-Fälle mit 336 Rechtezuständen, 672 API-Routen, 144 positiven Aufrufen und 720 festen Ergebniszeilen; 12 Matrixfälle und 15 frische Abschlussaudits bestanden. Die [Manifest- und Paketpflege](XLSX-METADATA-UPDATE.md) übernimmt Raw- und Zellrechte; historische Source-Header bleiben unverändert. Weitere Releasegates bleiben offen; Head- und Main-CI werden getrennt im integrierenden PR nachgewiesen.

[XLSX-Zell-Callerrechte](XLSX-CELL-CALLER-QUALIFICATION.md): zwei öffentliche TVFs mit einzelnem SELECT auf zwölf lokalen/direkt zentralen Windows-/Linux-Ziel-/CL-Fällen.48 positive Profile,672 SQL229-Abweisungen und144 feste Ergebniszeilenorakel; Raw-Reader, volle Typ-/Client-/Ressourcen- und Releasegates bleiben separat.

[CSV-Manifest- und Paketpflege](CSV-METADATA-UPDATE.md): die in PR450 belegten getrennten Parser-/Writer-/ResultTable-Rechte werden exakt übernommen. Historische Ausführungspins bleiben erhalten; ausführbare SQL-/DLL-Payloads und weitere Releasegrenzen bleiben unverändert.

[CSV-Callerrechte](CSV-CALLER-PROFILE.md): getrennte Parser-/Writer-/ResultTable-Objektrechte, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 384 Rechtezustände, 504 feste Ergebniszeilenorakel und frische eigene Bereinigungsprüfungen. Manifest-/Paketpflege und weitere Releasegates bleiben separat.

[Textpaar-Callerrechte](TEXT-PAIRS-CALLER-QUALIFICATION.md): ein EXECUTE-Grant, drei Algorithmen, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 24 positive Profile und 216 SQL229-Abweisungen. 1008 feste Zeilenorakel und eigene Bereinigung sind belegt; weitergehende Gates bleiben separat.

[JSON-Schema-Callerrechte](JSON-SCHEMA-CALLER-PROFILE.md): drei einzelne Objektrechte, zwölf lokale/direkt zentrale Ziel-/CL-Fälle, 168 Rechtezustände und 240 feste Fachfälle. Neuer Labtreiber und SQL-Fixture; keine Produkt- oder Paketänderung. Die [gebundene Metadatenkorrektur](CALLER-METADATA-UPDATE.md) übernimmt diese Rechte jetzt in Manifest und Paket.

[JSON-Schema-Deploy-AppLock](json-schema-deploy-lock-qualification.json): genau zwei lokale Windows/SQL-Server-2025/CU8/CL170-Sperrkonflikte mit getrennten Holder-/Contender-Verbindungen, unverändertem Zustand nach der Abweisung und positivem Deploy nach Freigabe. Fünf frühere Fehlversuche bleiben als aufgeräumte Historie erhalten; alle sechs unabhängigen Audits bestanden. Diese Funktionsabnahme ergänzt nur den angegebenen Deploy-Scope und ersetzt weder das vollständige Rechte-/Lifecycleprofil noch andere Zielkombinationen.

[JSON-Schema-Uninstall-AppLock](json-schema-uninstall-lock-qualification.json): genau zwei lokale Windows/SQL-Server-2025/CU8/CL170-Sperrkonflikte bei Uninstall, jeweils mit unverändertem installiertem Zustand, sauberem Contender und erfolgreichem identischem Uninstall nach Freigabe. Das leere Schema-Namespace bleibt erhalten; Core und ResultTable sind einschließlich Objektidentitäten und Berechtigungen unverändert. Ein Zielaufruf und ein unabhängiges Bereinigungsaudit bestanden. Dieser zusätzliche Funktionsnachweis schließt keine weiteren Zielkombinationen oder vollständigen API-/Rechte-/Lifecycleprofile.

[JSON-Schema-Deploy-Kollisionsschutz](json-schema-deploy-collision-qualification.json): vier synthetische Abweisungen vor Mutation bei fehlendem Schema-Modul und eigenem leerem `toolbelt_json`-Namespace für reservierte Temp-Tabelle, fremde öffentliche/interne Slots und verwaisten DeploymentMode-Marker auf Windows SQL Server 2025/CU8/CL170 lokal. Ein gemeinsamer positiver Deploy nach Bereinigung aller Fixtures sowie ein unabhängiges Cleanup-/Pin-Audit bestanden. Keine übrigen Fremdobjekt-, Marker- oder vollständigen Lifecyclematrizen werden dadurch geschlossen.

[JSON-Schema-Uninstall-Bestätigung](json-schema-uninstall-confirmation-qualification.json): zwei zentrale Abweisungen (`01` ungültig, `0` ohne zentrale Bestätigung), jeweils 55635/State 1 mit exakter Meldung und unverändertem Modul-, Core- und Sessionzustand; anschließend ein erfolgreicher Uninstall mit Bestätigung `1`. Geprüft wurde Windows SQL Server 2025/CU8/CL170 im zentralen Funktionsmodus mit festem Startprofil `QUOTED_IDENTIFIER ON`, `NOCOUNT ON`, `XACT_ABORT ON`, `IMPLICIT_TRANSACTIONS OFF`. Ein Zielaufruf und ein unabhängiges Bereinigungsaudit bestanden; drei frühere bereinigte Harnessfehler bleiben getrennte Historie. Andere Sessionprofile, Modi, Ziele und vollständige Lifecycle-/Rechtematrizen bleiben offen.

[JSON-Constructor-Paketqualifikation](JSON-CONSTRUCTORS-PACKAGE-QUALIFICATION.md):
27 bestehende Frameworkphasen bestanden; die gelieferten Constructor-/Core-DLLs
stimmen bytegenau mit den erzeugten Framework-DLLs überein. Der vorhandene
JSON-Core-Closure-IL-Gate bestand direkt mit der Constructor-DLL aus dem Paket.
Keine SQL-/Labverbindung, keine Schema-Paketqualifikation und keine
Gesamtfreigabe.

[JSON-Schema-Paket-IL](JSON-SCHEMA-PACKAGE-QUALIFICATION.md) ergänzt den
separaten direkten IL-Lauf für die Schema-DLL aus demselben unveränderten
Paket. Der abgeschlossene Source-Receipt wurde mit allen 27 Phasen und frischen
Eingaben wiederverwendet; ein neuer Frameworklauf fand nicht statt. SQL-, API-,
Gesamt-CLR- und Veröffentlichungsfreigaben bleiben getrennt.

[Edit-Distance-Paketqualifikation](EDIT-DISTANCE-PACKAGE-QUALIFICATION.md):
die DLL aus dem CLR-Paket besteht 27.104 Distance-Golden-Zeilen, 60 Jaro-Paare
in drei Kulturen und 109.333 feste Contract-Assertions. Eine begrenzte
IL-Inspektion bestand; Gesamt-CLR, SQL, API-Rechte und Veröffentlichung sind
nicht Teil des Nachweises.

[Scriptparser-Paketbindung](SCRIPT-PARSER-PACKAGE-QUALIFICATION.md): 63
ausgewählte feste Providerfälle bestanden gegen die DLL aus dem Paket. Der
separate Source-Guard umfasst 60 Assertions; kein SQL-/Lablauf und keine
vollständige Modul-, Plattform- oder transitive IL-Qualifikation. Die
[Evidenz](SCRIPT-PARSER-PACKAGE-QUALIFICATION.json) bindet 16 repo-relative
Eingabepins.

Die [SSIS-Qualifikation vom 2026-10-25](SSIS-LOOKUP-QUALIFICATION.md) ergänzt
zwölf explizite Windows-Engine-/CL-/Modusfälle, den finalen Installationssatz und
je sechs neue Windows-Fälle für CLR- und Gesamtpaket. Historische Manifest-/API-
Snapshots werden aus ihrer gebundenen früheren Lieferung gelesen. Unveränderte
Linux-Payloads behalten ihre ursprünglichen Nachweise; keine neue Linux-Ausführung
und keine automatische Modul- oder Gesamtfreigabe.

[CLR-String-Callerrechte](CLR-STRING-CALLER-QUALIFICATION.md): fünf vorhandene Phonetic-/Edit-Distance-TVFs, zwölf lokale/direkt zentrale Ziel-/CL-Fälle,120 positive Profile und1440 SQL229-Abweisungen. Entwickelt wurden Labtreiber, Sicherheitsprüfungen und feste SQL-Fixtures. Eigener Trust und notwendige Testkonfiguration sind unabhängig als bereinigt bestätigt; Produktquellen und Modulstatus bleiben unverändert.

[Event Log: Lesen und lokale Retention mit Einzelrechten](EVENT-LOG-CALLER-QUALIFICATION.md): 3 APIs, zwölf Fälle lokal/direkt zentral, 72 Einzelgrantprofile und 648 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Providerview mit einzelnem SELECT-Recht](PROVIDER-CALLER-QUALIFICATION.md): 1 APIs, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 144 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[JSON Pointer mit einzelnem SELECT-Recht](POINTER-CALLER-QUALIFICATION.md): 1 APIs, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Capability-Katalog mit einzelnem SELECT-Recht](CATALOG-CALLER-QUALIFICATION.md): 1 APIs, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[Konsolenausgabe mit einzelnem EXECUTE-Recht](CONSOLE-CALLER-QUALIFICATION.md): 1 APIs, zwölf Fälle lokal/direkt zentral, 24 Einzelgrantprofile und 72 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.

[JSON-Pfade mit getrennten SELECT-Rechten](JSON-PATH-CALLER-QUALIFICATION.md): 2 APIs, zwölf Fälle lokal/direkt zentral, 48 Einzelgrantprofile und 192 SQL229-Abweisungen. Quelle und feste Orakel sind gebunden; weitere Releasegates bleiben separat.


Die [additive Date-Math-Ergänzung](DATE-MATH-CL-COMPLETION.md) schließt die sechs niedrigeren CL-Callerfälle. Insgesamt zwölf Fälle mit unveränderter Fixture sind gebunden; der frühere Teilscope bleibt historisch erhalten. Offline zusätzlich prüfen: `python -B Tests/Release/test_additive_caller_qualification.py`.

Basisbericht vom 2026-10-23 mit Nachträgen vom 2026-10-24. Dies ist der Prüfbericht zur unveröffentlichten
[Releasevorbereitung](README.md), keine Freigabe von Supportkombinationen.
Die [Freigabematrix](FREIGABEMATRIX.md) bleibt bei 19 stabilen und 26
Preview-Kandidaten; diese Zielkanäle und der [Supportumfang](SUPPORT.md) sind
ausdrücklich freigegeben. Alle 45 Modulmanifeste bleiben `unreleased`.

## Was technisch geprüft ist

| Prüfung | Tatsächlicher Nachweis | Grenze |
|---|---|---|
| Gepackte stabile SQL-Exports | Zwölf erfolgreiche Labfälle; jeweils Erstinstallation, Repeat, fünf feste Funktionsorakel, zentraler Consumer sowie Uninstall/Repeat | Genau 19 stabile Kandidaten, keine Vollabnahme aller APIs oder Preview-Module |
| Installationsmetadaten | Alle 19 Versions-/Deploymentmarker vorhanden; Objektdefinitionen nach Repeat unverändert; nach Uninstall keine Modulobjekte/-marker | Eigene administrative synthetische Testdatenbanken, kein Minimalrechtenachweis |
| Bereinigung | 36 eigene Datenbanken entfernt; zwölf separate lesende Auditprozesse bestätigten Abwesenheit und Inputpins | Keine fremden Ressourcen, Server-, Rechte-, Login- oder Truständerungen |
| CLR-Buildinputs | Zwölf vorhandene Projekte jeweils zweimal isoliert gebaut; identische DLL-Bytes, keine CodeView-Einträge und keine geprüften privaten Buildpfade | Der erste Offlinebuild allein war keine vollständige IL-/Framework-/SQL-Abnahme; die anschließende Paketlieferung ist unten getrennt beschrieben |
| JSON-Binarybindung | Die drei erneut erzeugten JSON-Binaries stimmen exakt mit den kanonischen bekannten Closure-Pins überein | Keine Erweiterung des vorhandenen nativen Supportumfangs |
| Ausgewählte Frameworkprüfungen | Sieben frühere Suiten auf ihren Kandidaten bestanden: CSV, Phonetic, ZIP-Writer, drei Regex-Suiten und SSIS Full; zusätzlich 27 Phasen für den JSON-Constructor mit exakt gebundenen Paket-DLLs | Begrenzte Frameworkprofile für einzelne Module; keine vollständige IL-/Framework- oder SQL-Qualifikation aller zwölf Projekte |

Am 27.10.2026 wurden die bestehenden CSV- und Phonetic-Harnesses zusätzlich
mit den DLL-Bytes aus dem CLR-Installationspaket ausgeführt. Die
[Paketprofile](CLR-FRAMEWORK-PACKAGE-QUALIFICATION.md) binden drei
Kulturphasen je Modul und begrenzen den Scope auf diese CLR-Verträge. Die
früheren Kandidatenläufe bleiben als historische Evidenz erhalten; diese
neuen Paketläufe ersetzen weder eine vollständige Modul-/Plattformmatrix noch
SQL-, Deployment-, transitive IL- oder Sicherheitsqualifikationen.

Der native Aufruf war
`Tests/Release/Invoke-StablePackageMatrix.ps1 -EvidenceDirectory <neues privates .runtime-Verzeichnis>`.
Er konsumierte den auf Commit `5b83a73aab3639b0d45b56e334fb38dc24509279`
versionierten Quellpaket-Kandidaten. Das geprüfte Produkt bleibt unverändert
an `756e7fb0444aedf04949409a8fab2189b9fa890f` gebunden. Die
[maschinenlesbare Projektion](qualification.json) nennt Archiv-/SQL- sowie
Adapterbindungen, konkrete abstrakte Ziel-/CL-Kombinationen und Ergebnisgrenzen.
Sie enthält keine Labidentitäten, Endpoints, Connection Strings oder Rohlogs.

Die Zielmatrix ist Windows und Linux mit SQL2019 CL150, SQL2022 CL150/160
und SQL2025 CL150/160/170, jeweils lokal/zentral und mit zentralem Consumer.
Die Auswahl folgt dem vorhandenen Labvertrag einschließlich der erlaubten
Windows-base/CU-Regel. `TestPurpose=Functional`, `Encrypt=True` und der
ausdrücklich boolesche Trustwert des Labvertrags wurden unverändert verwendet.
Dies belegt keine authentifizierte TLS-Verbindung.

Die fünf Smoke-Oracles sind Generate Series, Base64, Date Spine,
JSON Path Exists und ResultTable. Bestehende vollständige Modulqualifikationen
werden nur in ihrem ursprünglichen Scope weiterverwendet. Die Paketprüfung
erweitert weder Rechte-, Heap-/Parallelitäts-, Host-Recovery- noch Plattformzusagen.

Ein erster Versuch scheiterte am Markerparameter des neuen Testadapters:
`nvarchar(max)` war als Wert einer SQL-Extended-Property ungeeignet.
Der Adapter verwendet jetzt einen begrenzten `nvarchar(32)`-Wert und
journaliert die Datenbankidentität bereits vor der Markeranlage. Die eine
zunächst leere eigene Datenbank wurde anhand des privaten Erzeugungsintents,
der Erstellungsidentität und des unveränderten leeren Scopes reconciled,
markiert, entfernt und anschließend frisch lesend als abwesend bestätigt.
Dieser Versuch bleibt `failed_cleaned`; die zwölf anschließenden finalen
Gesamtläufe mit korrigiertem Adapter bestanden. Ein Cleanupfehler wurde nicht
als Erfolg umetikettiert und kein unveränderter Fall blind wiederholt.

Nach diesem ersten grünen Matrixlauf wurde im Abschlussreview die gemeinsame
Zeitreserve verschärft: Vor einem mutierenden Fall werden jetzt Arbeit und
separater Audit reserviert. Zwei neue Negativfälle prüfen die Abweisung vor
dem Wellenende. Alle zwölf finalen Fälle wurden mit diesem geänderten Wrapper
erneut erfolgreich ausgeführt. Ein abschließender unabhängiger lesender
Audit bestätigte alle 73 eigenen Datenbanknamen aus Erstfehler, früherer
grüner Matrix und finaler Matrix als abwesend. Beide erfolgreichen Matrizen
bleiben zeitlich und nach ihren jeweiligen Eingaben unterscheidbar.

Die reproduzierbare CLR-Prüfung verwendete
`Scripts/Release/check_clr_builds.py --msbuild <vorhandenes MSBuild> --output <neues direktes .runtime-Unterverzeichnis>`
auf Windows mit .NET Framework 4.8. Sie nahm nur versionierte Quellen und
die bereits gepinnte offizielle ScriptDom-DLL auf. PDB-freie Releaseflags und
synthetisches PathMap verhindern die Übernahme lokaler Buildpfade. Die neuen
Kandidaten bleiben lokal: Insbesondere ersetzt ein gleicher Modulname mit
neuem Binaryhash keine bestehende native/Consumer-Qualifikation.

Ergänzend bestanden sieben vorhandene, binarygebundene Frameworksuiten:
[CSV](../../Modules/toolbelt.file.csv-memory/Tests/README.md),
[Phonetic](../../Modules/toolbelt.string.phonetic/Tests/README.md),
[ZIP-Writer](../../Modules/toolbelt.archive.zip-memory/Tests/README.md),
[Regex Transformations/Relations/Captures](../../Modules/toolbelt.string.regex/Tests/README.md)
und [SSIS Full](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md).
Die Aufrufe konsumierten ausdrücklich die neuen Kandidaten, verwendeten
die vorhandenen Frameworkharnesses und führten kein SQL aus. Beim ersten
CSV-Setup wurde ein Evidenzpfad innerhalb des Checkouts vor Testausführung
abgewiesen; nach Wahl eines neuen privaten externen Verzeichnisses bestand
die Suite. Dieser Setupfehler bleibt in der Projektion sichtbar. Es gibt
weiterhin keinen vollständigen neuen Framework-/IL-/SQL-Nachweis für den
gesamten CLR-Satz.

Die Foundation wurde vor dem erneuten Paketbau frisch gegen Upstream geprüft:
1.25.0 bleibt aktuell. Commit `a3567f8e5372e5f4db72dbd466323aa22c71b13a`
ergänzt nur Foundation-eigene Release-/Navigationsdokumentation; alle 112
ausgewählten Transferquellen sind gegenüber der installierten Quelle
`9e1b9974de58ea775d40c7c6045cd5057ba8b30c` bytegleich. Die bestehende
Provenienz bleibt erhalten; es gibt keinen neuen Regelpayload oder Upgrade.

Bei einem aktualisierten Quell-ZIP müssen beide stabilen SQL-Dateien weiterhin
exakt den hier tatsächlich geprüften Bytes entsprechen. Der Paketgenerator
und sein Prüfmodus kontrollieren diese Bindung zusätzlich zum regulären
erneuten Export. Ein geänderter SQL-Payload oder Adapter invalidiert den
betroffenen Nachweis. Die Paket-/Negativtests und der vollständige
Dokumentationsaudit laufen im bestehenden CI; ein grüner Strukturcheck allein
bestätigt keine native Ausführung. Einzelheiten der Ausführung stehen im PR.

## Eigenständige Stable-SQL-Lieferform

Das neue [SQL-Installationspaket](STABLE-SQL-INSTALL.md) enthält nur die beiden
qualifizierten Stable-Payloads, unveränderte Lizenz, Anleitung, Herkunftsmanifest
und Dateiprüfsummen. Der Offlinegenerator prüft das aktuelle Quellarchiv gegen
seine Prüfsumme und beide SQL-Dateien gegen `qualification.json`. Der heutige
Quellarchivhash unterscheidet sich vom historischen nativen Archivhash; beide
SQL-Payloads bleiben exakt gleich. Wiederverwendet wird ausschließlich deren
bestehender nativer SQL-Scope, keine neue Gesamtarchiv- oder Modulabnahme.

Deterministische Containerbytes, exakte Dateiliste, Pfad-/Symlink-/Duplikat-
Abweisung, Größenlimits, unveränderte Lizenz und SQL-Bindung sowie verweigertes
Überschreiben werden offline geprüft. ZIP_STORED mit festen Metadaten vermeidet
Kompressionsunterschiede zwischen Laufzeitumgebungen. Installation, GUI, Anmeldung und TLS
wurden für die neue Verpackung nicht erneut nativ ausgeführt. Der eigenständige
Download erleichtert den vorhandenen SSMS-Weg; keine Produkt-/Manifest-/Status-
änderung, kein SSIS-/CLR-Paketrefresh und keine Veröffentlichung.

## Fertige CLR-DLLs und native Paketinstallation

Der anschließende ausdrückliche Benutzerauftrag verlangt fertige DLLs mit
Quellcode und eine schnelle Installation ohne eigenen Build. Der zusätzliche
[CLR-Installationssatz](CLR-INSTALL.md) enthält zwölf Toolbelt-DLLs, ScriptDom,
Quellcode, Lizenzhinweise, exakte Trustwerte und fertige SQL-Dateien mit
eingebetteten Assemblybytes. Vier Profile erhalten Windows/Portable und
local/central; das Windows-Dateisystemmodul bleibt ausschließlich lokal.
Ein optionaler PowerShell-Helper prüft alle Paketdateien vor Tool-/SQL-Zugriff.

Zehn DLLs stammen unverändert aus dem bereits reproduzierbaren Doppelbuild
mit identischen Produktquellen. SSIS und Parser sowie ScriptDom werden exakt
aus dem bestehenden qualifizierten SSIS-Paket übernommen. Die vorhandenen
Modulversionen und Dependency-/Consumerpins ändern sich nicht. Die
[CLR-Qualifikationsprojektion](clr-qualification.json) bindet alle ausgelieferten
SQL-Payloads und DLL-Bytes an den tatsächlich getesteten Satz sowie an die
aktuellen Prüf-/Paketierungsquellen. Die spätere
[ODBC-Clientqualifikation](CLR-CLIENT-QUALIFICATION.md) verwendet für dieselben
Binärwerte kurze SQL-Zeilenfortsetzungen und prüft alle zwölf Kombinationen
erneut über den optionalen Pakethelper. DLL-Bytes bleiben identisch; SQL- und
ZIP-Hashes ändern sich durch die ausdrücklich gebundene neue Lieferform.

Die endliche Welle bestand zwölf tatsächliche Ziel-/CL-Fälle: Windows und
Linux SQL2019 CL150, SQL2022 CL150/160 und SQL2025 CL150/160/170. Windows
prüfte die Windows-Profile, Linux die neun SAFE-Module der portablen Profile.
Jeweils Erstinstallation, explizit hashgebundener Repeat, exakte Assemblyhashes
und Modulmarkermenge, ein festes Phonetik-Wertorakel, zwei JSON-Help-Aufrufe,
zentraler Consumer, Uninstall und ausdrücklich abwesender Uninstallrepeat
bestanden. Es gab 24 Deploymentpfade mit 36 eigenen Datenbanken und zwölf
separate lesende Cleanup-/Pinaudits. Das ist eine Paketinstallationsprüfung,
keine vollständige neue Abnahme sämtlicher öffentlichen APIs.

Ein erster Paketadapterlauf scheiterte am Uninstallrepeat mit noch auf
Anwesenheit gebundenem Hash. Die getrennte Datei `UninstallAbsent` erhält
den vorhandenen Guard; das Produkt wurde nicht geändert. Der Versuch bleibt
`failed_cleaned`. Ein JSON-Datumskulturfehler stoppte eine Fortsetzung vor SQL;
ein weiterer Preflight wies deaktiviertes CLR vor Mutation ab. Unter der
stehenden Testkonfigurationsfreigabe wurde erforderliches CLR vorübergehend
aktiviert. Vorgemerkte Zustände und Auswirkungen wurden privat journalisiert;
die übrigen Konfigurationszustände blieben wirksam unverändert. Keine Rechte,
Sicherheitslockerung oder Infrastrukturänderung. Nach allen Verbrauchern
bestanden Wiederherstellung und ein neuer unabhängiger Konfigurationsaudit.
Ein abschließender lesender Gesamtaudit bestätigte alle **39 eigenen
Datenbanknamen** aus Erstfehler und erfolgreicher Welle als abwesend, eigene
Trusteinträge entfernt und vorbestehende Trustfingerprints erhalten.

Alle Versuche teilten dasselbe ursprüngliche Restbudget; keine grünen Fälle
wurden zur Statusauffrischung wiederholt. Nach Abschluss wurden ausschließlich
die Präfix-/Gesamtabdeckungsgrenzen des Matrixwrappers verschärft und positiv/
negativ ohne SQL geprüft. Der exakte ausgeführte Wrapperhash und seine
Quellreferenz bleiben getrennt vom aktuellen Wrapper gebunden; Case-Driver,
funktionale SQL-/DLL-Inputs und tatsächliche Ergebnisse bleiben unverändert.
Die Datumskulturregression prüft den echten Budgetausdruck über JSON-Roundtrip
mit zwei Kulturen. Neue Laufzeit-, Minimalrechte-, Heap-/Parallelitäts-,
Host-Recovery-, authentifizierte TLS- oder allgemeine Produktionszusagen folgen
aus der Paketprüfung nicht. GUI-Installation bleibt `not executed`.

## Gemeinsame Paketqualifikation und Lifecycle-Korrekturen am 2026-10-23

Die [maschinenlesbare Projektion](complete-qualification.json) bindet die
tatsächliche korrigierte Vollmatrix und ihre Daten-/Methodeninputs. Zwölf
Windows-/Linux-Fälle bestanden: SQL2019 CL150, SQL2022 CL150/160 und SQL2025
CL150/160/170, jeweils lokal/zentral und mit zentralem Consumer. Windows-local
enthielt 45 Module, Windows-central 43, Portable-local/central jeweils 40;
Plattform- und Dependencygrenzen blieben wirksam.

Je Fall bestanden Erstinstallation, explizit hashgebundener Repeat,
Assembly-/Versionsmarker- und Definitionsvergleich, feste Smoke-Oracles,
der unveränderte Pointer-Securityfixture, zentraler Consumer, Uninstall und
Absent-Repeat. Die beiden ursprünglich gefundenen Lifecycle-Blocker sind
damit behoben:

- Edit Distance akzeptiert ausschließlich den bekannten Text-Pairs-Consumer
  bei gleicher Version, gleichem Hash und gleichem Modus. 24 Fremdconsumer-
  und 24 abweichende Versionsmarkerfälle wurden weiterhin mit SQL55038
  abgewiesen; Text-Pairs-Objektidentität und eigene Annotation blieben in
  allen 24 Deploymentpfaden erhalten.
- Event Log kompiliert den optionalen WorkType-Zugriff erst nach dessen
  Existenzprüfung. Alle 24 vollständigen Absent-Repeats nach Entfernung der
  Registry bestanden. 24 unvollständige Event-Log-Markerfälle ohne Dependency
  blieben mit SQL51748 gesperrt und wurden durch die Abweisung nicht entfernt.

Zusätzlich bestanden zwölf **eigenständige** CLR-Paketfälle mit den geänderten
Installations-SQL-Dateien, wiederum Erst-/Repeat-/Consumer-/Uninstall-/Absent-
Repeat und separaten Cleanup-/Pinaudits. Die [CLR-Projektion](clr-qualification.json)
unterscheidet diese tatsächliche Ausführung vom früheren Nachweis. Die privaten
Testkandidaten trugen ausdrücklich `qualification_state=pending`; sie wurden
nicht als qualifizierte Releaseassets ausgegeben. Endgültige ZIPs nehmen erst
danach die tatsächlichen Nachweise auf und müssen exakt dieselben SQL-/DLL-
Bytes enthalten.

Die erste Diagnose blieb `failed_cleaned` (SQL55038), die zweite ebenfalls
`failed_cleaned` (SQL208 beim Absent-Repeat). Dazwischen bestanden zwölf
ausdrücklich begrenzte Install-/Consumer-/Einmal-Uninstallfälle; diese wurden
nie als erfolgreiche Vollqualifikation umetikettiert. Nach dem zusätzlichen
ausdrücklichen Korrekturauftrag wurden zwölf neue Vollfälle und zwölf neue
CLR-Fälle geprüft. Alle Phasen behielten denselben ursprünglichen Start und
Verbrauch im erweiterten Restbudget: 38 tatsächliche Caseversuche, Grenze
42/14400 Sekunden, keine blinden Retries oder Budgetresets.

Ein abschließender unabhängiger lesender Audit bestätigte alle **114 eigenen
Datenbanknamen** als abwesend, eigene Trusteinträge entfernt und vorbestehende
Trustfingerprints erhalten. Nach Abschluss aller Verbraucher wurden die
temporären CLR-Einstellungen wiederhergestellt; ein weiterer unabhängiger
Prozess bestätigte Originalkonfiguration und Datenbank-/Assemblykataloge.
Keine Rechte-/Login-/Labinfrastrukturänderung. Journale, tatsächliche
Parameterwerte und Rohlogs bleiben ausschließlich privat.

Die Produktquellen sind bytegleich als synthetischer Produkt-Snapshot
gebunden; Originalausführung und aktueller Snapshot stehen getrennt in den
Projektionen und in [product-source.json](product-source.json). Dies nimmt
keine persönliche Commitmetadaten ins Paket auf und erweitert keine API-,
Minimalrechte-, Heap-/Parallelitäts-, Dateiidentitäts-, Worker-Recovery- oder
authentifizierte TLS-Zusage. Alle Module bleiben `unreleased`.

## Was vor Veröffentlichung offen bleibt

Die [Zuordnung aller 45 Module](EVIDENCE-MAP.md) und der
[API-/Grenzbericht](API-QUALIFICATION.md) konkretisieren die fachlichen
Restfälle. Vorhandene volle Matrizen und CSV-Grenznachweise bleiben in ihrem
ursprünglichen Scope gültig; die nachfolgende Tabelle ist keine Aussage,
dass sämtliche genannten Einzelprüfungen noch fehlen.

Die zusätzliche API-/Grenzwelle ist abgeschlossen: 74 ausgewählte Fälle,
73 vollständig bestanden und ein Regex-Teilnachweis; zusätzliche Fixtures
für 37 Module. Alle eigenen Datenbanknamen sind abwesend, Trust und
temporäre CLR-Konfiguration unabhängig als wiederhergestellt geprüft.
Die [Regex-Nachprüfung vom 2026-10-24](REGEX-TIMEOUT-QUALIFICATION.md)
belegt den ursprünglichen positiven Transformationsabschluss auf einer DLL
mit weniger LOB-Kopien und unveränderten Sicherheitsbudgets. Ein zusätzlicher
Capture-Timeout unter Linux SQL2019/CL150 local war zunächst offen. Die neu
geprüften CLR-/Gesamtpaket-Lifecycles ersetzen keine übrigen Pflichtfälle.
Die anschließende [Capture-Diagnose](CAPTURE-TIMEOUT-INVESTIGATION.md) erhält
jetzt den zuvor verlorenen Unterfall und CLR-Stack. Der historische Fehler
ließ sich weiterhin nicht reproduzieren. Nach ausdrücklicher Freigabe der
Abschlussregel ist das historische Timeout-Gate für die exakt gebundene DLL
mit [dokumentiertem Restrisiko angenommen](CAPTURE-RELEASE-ACCEPTANCE.md).
Neue Minimalrechtetests lokal/direkt zentral bestanden in zwölf physischen
Ziel-/CL-Fällen. Die skalare Rechte-Dokumentation ist inzwischen korrigiert
und [begrenzt qualifiziert](REGEX-RIGHTS-QUALIFICATION.md). Echte
Lowpriv-CrossDB-Mappings und übrige Modulpflichtfälle bleiben offen.

| Gate | Konkret erforderlich | Abhängigkeit |
|---|---|---|
| Fachlicher Zielumfang | Erledigt: 45 bestehende Modulversionen, 19 stabil/26 Preview und SQL-/CL-/Plattform-/Deployment-Zielumfang sind ausdrücklich übernommen | [Benutzerfreigabe](SUPPORT.md#freigabe); konkrete öffentliche Kombinationen brauchen weiterhin ihre vollständigen Pflichtnachweise |
| Pflichtqualifikation im gewählten Umfang | Fehlende Minimalrechte-, API-/Lifecycle-, Datei-/Identitäts-/Worker-, Heap-/Parallelitäts- oder Recoveryfälle je Modul prüfen oder die betreffende Kombination außerhalb des veröffentlichten Umfangs halten | Konkreter Supportumfang; gegebenenfalls bereitgestellte Principals, Fixtures oder gesonderte Recoveryumgebung |
| CLR-Lieferumfang | Erledigt: vorgebauter Installationssatz samt Quellen ist in den Zielumfang übernommen | Keine weitere Build-/Lieferentscheidung offen; vollständige fachliche Pflichtnachweise der gewählten Preview-Kombinationen bleiben erforderlich |
| Gemeinsamer Paket-Lifecycle | Erledigt für die vier abgegrenzten Profile: Erst-/Repeat-/Uninstall-/Absent-Repeat und zentrale Consumer in zwölf physischen Ziel-/CL-Fällen; eigenständige CLR-Profile nochmals separat geprüft | Kein universeller historischer Upgradepfad und keine vollständige neue APIabnahme aller 45 Module |
| Finaler Releasekandidat | Paketintegrität, Dokumentationsaudit und echte CI am endgültigen Head bestätigen; geänderte Inputs mit betroffenem Nachweis abgleichen | Nach Abschluss der noch offenen Inhalte; heutige grüne CI qualifiziert keine späteren Änderungen |
| Öffentliche Veröffentlichung | Separater ausdrücklicher Auftrag; danach tatsächlichen Tag, Release-URL, Zeitpunkt, Assethashes und `publication_record` je veröffentlichter Modulversion pflegen | Noch nicht autorisiert; kein Tag, kein GitHub-Release und keine Statusaufwertung |

### Aktueller Restgate-Status und Voraussetzungen

Diese Übersicht ordnet den verbleibenden Scope den bestehenden Nachweisen zu.
`PASS` gilt jeweils nur für den angegebenen Fall; es erweitert weder den
Modulstatus noch den zugesagten Produktumfang. Unkonkretisierte
manifesteigene Pflichtfälle bleiben offen, bis sie pro Modul und Kombination
benannt sind. Sie werden nicht pauschal als durch externe Voraussetzungen
blockiert behandelt.

| Gate | Status | Verbleibender Scope und Grenze | Voraussetzung | Kanonische Evidenz |
|---|---|---|---|---|
| XLSX-Listing: feste Blattanzahl | **PASS FÜR 32/33 BLÄTTER** | `USP_ListXlsxWorksheets` lieferte auf 24 Routen jeweils 32 feste Zeilen; 24 33-Blatt-Aufrufe wurden mit 51520 und null gelesenen Zeilen abgewiesen. | Kein weiteres Ziel für diesen Grenzfall. Andere XLSX-APIs und Modulpflichten bleiben separat. | [XLSX-Grenzbericht](XLSX-BOUNDARY-QUALIFICATION.md) |
| XLSX-Rohleser: 50.000 Shared Strings | **PASS FÜR QUELL- UND WARTUNGSPAKETDELTA** | Der korrigierte Kandidat und die ausgewählte Installation des aktuellen Wartungspakets bestehen 50.000/50.001 lokal/direkt zentral auf zwölf Ziel-/CL-Fällen bei unverändertem 5.000-ms-Budget. Zwölf neue unabhängige Audits bestanden. Für die frühere Paket-DLL bleiben die ursprünglichen Budgetfehler und nicht ausgeführten Routen historisch erhalten. | Für diesen begrenzten Installations-/Hilfe-/SST-Delta kein weiterer Nativlauf; vollständige Modul-, Lifecycle- und übrige Releasegates bleiben separat. | [Aktueller Wartungsnachweis](CLR-MAINTENANCE.md), [SST-Quellkorrektur](XLSX-SST-BUDGET-CORRECTION.md), [historischer Paketbericht](XLSX-BOUNDARY-QUALIFICATION.md) |
| Modulpflichten je zugesagter Kombination | **OFFEN; nächste Schritte je Modul zugeordnet** | Die vorhandene 45-Modul-Übersicht nennt pro teilweise qualifiziertem Modul den belegten nächsten Schritt oder dessen Voraussetzung (zum Beispiel weitere deklarierte Ziele, Minimalrechte/Identität, Lifecycle/Upgrade, Datei-/Client-/Hostverhalten oder Last/Recovery). Sie erweitert keine Supportmatrix und erzeugt keine Kombinationen allein aus Betriebssystem- oder Versionsunterschieden. Ein `validated`-Eintrag gilt für den dort beschriebenen Scope. Ist ein zusätzlicher Schritt nicht benannt, ist er im Inventar nicht benannt und vor weiterer Abnahme anhand der kanonischen Matrix und des zugesagten Umfangs zu prüfen. | Nur die in Manifest und Modulmatrix tatsächlich zugesagten, noch nicht belegten Fälle konkretisieren; pro Fall feste Eingaben und begrenztes Ziel verwenden. Externe Voraussetzungen bleiben modulbezogen. | [45-Modul-Übersicht mit nächsten Schritten](../../Tests/README.md#modulspezifische-testmatrizen), [Modulzuordnung der Evidenz](EVIDENCE-MAP.md), jeweilige kanonische Modulmatrix |
| SSIS: aktuelles ZIP auf allen Windows-/CL-/Moduskontexten | **PASS FÜR DEN GEBUNDENEN AKTUELLEN PAKETVERTRAG** | Zehn neue Paketfälle mit je 206 festen Assertions und zehn unabhängigen Audits ergänzen zwei unveränderte grüne Fälle: SQL 2019/CL150, SQL 2022/CL150/160 und SQL 2025/CL150/160/170 jeweils lokal und zentral. API-Metadaten, editierbare Defaults, SQL-Limits, ResultTable-Schutz und ausgeführte Row-Count-/Flatfile-Debug-Scripts sind belegt; keine vollständige SSIS-Modulabnahme. | Übrige Komponenten-/Ausdruckskombinationen, echte SSIS-Ausführung, Windowsauthentifizierung/GUI, TLS und Recovery bleiben eigene Gates. | [Aktuelle Paketmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/Qualification/Current.InstallPackage.Matrix.20261029.json), [Prüfmatrix mit Grenzen](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) |
| SSIS: aktueller Standalone-T-SQL-Installer auf allen Windows-/CL-Kontexten | **PASS FÜR DEN GEBUNDENEN AKTUELLEN INSTALLER** | Acht neue Installationsfälle mit je 206 Assertions und vier unabhängigen Audits ergänzen vier unverändert übernommene Kontexte. Für den festen Installer sind SQL 2019/CL150, SQL 2022/CL150/160 und SQL 2025/CL150/160/170 lokal und zentral belegt; die vier ursprünglichen erfolgreichen Kontexte wurden nicht wiederholt. Das ist keine allgemeine SSIS-Modul- oder API-Vollabnahme. | Tatsächliche SSIS-Ausführung, Windowsauthentifizierung/GUI, TLS, Recovery und Veröffentlichung bleiben eigene Gates. Head-/Main-CI und Integration werden am jeweiligen PR-/Merge-Head nachgewiesen. | [Standalone-Installer-Matrix](ssis-current-standalone-installer-matrix.json), [Prüfmatrix mit Grenzen](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md) |
| ZIP-Listing: feste Entryanzahl-Grenzen | **PASS FÜR DEN GEBUNDENEN GRENZSCOPE** | Das bestehende `USP_ListZipEntriesFromBinary` gab 10.000 synthetische Einträge mit festen Metadaten aus; 10.001 Archiv-Entries und `@MaxEntries = 10001` wurden vor einer direkt gelesenen Zeile abgewiesen. Dies ist keine ZIP-Modul- oder sonstige API-Vollabnahme. | Kein weiteres Ziel für diese beiden festen Grenzfälle. Andere ZIP-Formate, Payload- und Modulpflichten bleiben separat. | [ZIP-Entryanzahl-Nachweis](ZIP-ENTRY-COUNT-QUALIFICATION.md), [maschinenlesbare Evidenz](zip-entry-count-qualification.json) |
| Echte Minimalrechte und CrossDB-Identität | **TEILWEISE BELEGT; CROSSDB OFFEN** | Ausgewählte Callerprofile mit engen Objektgrants sind belegt. Tests mit getrenntem Login, User-Mapping oder echten Lowpriv-CrossDB-Aufrufen bleiben eigenständige Fälle; DBO- oder direkte Consumer-Profile ersetzen sie nicht. | Geeignete getrennte Principals und ausdrücklich zugeordnete CrossDB-Mappings; kein Grant aus den vorhandenen Profilen ableiten. | [Callerrechteübersicht](CALLER-METADATA-UPDATE.md), [API- und Grenzbericht](API-QUALIFICATION.md), jeweilige Callerprofile |
| Serverseitige Dateien und Windows-Identitäten | **NICHT AUSGEFÜHRT** | ZIP-Dateien, File-Content und Windows-Filesystemzugriffe sind getrennte Verträge. SQL-API- und Paketprofile belegen weder Serverdateizugriff noch Caller-/ServiceAccount-, NTFS- oder Reparseverhalten. | Synthetische serverseitige Dateien und Fixture-Ownership; für Windows-Fälle geklärte Caller-/ServiceAccount-Identität sowie NTFS-/Reparse-Fixtures. | [API- und Grenzbericht](API-QUALIFICATION.md), [Dateimodule in der Modulzuordnung](EVIDENCE-MAP.md) |
| Zweite Session, EventLog und administrierter Provider | **NICHT AUSGEFÜHRT** | Direkte API-, Rollback- und Sessionunabhängigkeitsprüfungen qualifizieren keinen administrierten externen Provider. | Vorkonfigurierter administrierter Provider und eine passende bestehende Testfixture. | [API- und Grenzbericht](API-QUALIFICATION.md), [EventLog-Callerprofil](EVENT-LOG-CALLER-QUALIFICATION.md) |
| Queue 2.1 Managed-/Providerparallelität | **TEILWEISE BELEGT; PROVIDERLAUF OFFEN** | Die Vier-Sessions-/Ein-Claim-Fixture und die getrennten SQL-Managedfälle belegen nicht den vollständigen parallelen Worker-/Providerlauf. | Passende vorkonfigurierte Worker-/Providerkombinationen. | [Queue-Testmatrix](../../Modules/toolbelt.core.work-queue/Tests/WORK_QUEUE_CONTRACT_TEST_MATRIX.md), [Queue-Autorisierungsnachweis](QUEUE-AUTHORIZATION-QUALIFICATION.md), [Worker-Callerprofil](QUEUE-WORKER-RIGHTS-QUALIFICATION.md) |
| Transport-/Host-Recovery | **NICHT AUSGEFÜHRT** | Keine harte Unterbrechung eines laufenden mutierenden Tests als Ersatz für einen kontrollierten Recoveryvertrag. | Gesonderte kontrollierte Recoveryumgebung und ein sicher abbrechbarer, eigener Testfall. | [API- und Grenzbericht](API-QUALIFICATION.md), [Releasegates](#was-vor-veröffentlichung-offen-bleibt) |
| Regex-Capture-Outputgrenze | **PASS FÜR DIE GEBUNDENE 16-MiB-GRENZE; SEPARATER CAPTURE-TEILFALL PARTIAL** | `Captures.Metadata.ps1` prüfte den Large-Output exakt bei 16 MiB (8.388.480 Capture-Codeunits plus 128 Codeunits Gruppenname) und wies anschließend die um 2 Bytes größere Ausgabe mit `TBX_REGEX_OUTPUT_TOO_LARGE` ab. Das originale `Captures.Contract.sql` hatte separat unter Linux SQL Server 2019/CL150 einen Timeout; dieser Teilfall bleibt `PARTIAL` und wurde nur mit dokumentiertem Restrisiko angenommen. Das ist keine vollständige Regex-Modulabnahme. | Kein erneuter Lauf dieser unveränderten Evidenz; andere Capture-, Rechte-, Ressourcen-, Client- und Recoverypflichten bleiben separat. | [Regex-Nachprüfung](REGEX-TIMEOUT-QUALIFICATION.md), [Capture-Akzeptanz](CAPTURE-RELEASE-ACCEPTANCE.md), [Capture-Diagnose](CAPTURE-TIMEOUT-INVESTIGATION.md) |
| Pflicht-Lastfälle für ResultTable, Base64 und Generate Series | **PASS IM ANGEGEBENEN SQL-2025-UMFANG** | ResultTable: 100.000 Zeilen über 50 KeepData-Aufrufe, 20 Leerungen und zehn Schemawechsel. Base64: exakter 4-MiB-Roundtrip mit NULL-, Längen- und Inhaltsorakeln. Generate Series: zehn Millionen eindeutige Werte mit Grenzen 1 bis 10.000.000. Diese Ergebnisse sind funktionale Pflichtlastfälle, keine Zeit- oder Produktionskapazitätszusage. | Die protokollierten SQL-Server-2025/Linux/CL170-Fälle ergänzen die jeweiligen unveränderten Plattformmatrizen; weitere Modulpflichten bleiben eigenständig. | [V0c-Pflichtlaststatus](../../Tests/V0C_RELEASE_GATE_STATUS.md), [DEC-2026-036](../../Documentation/Architecture/DECISIONS.md#dec-2026-036-verpflichtende-lasttests-und-optionale-laufzeitmessungen), [ResultTable](../../Modules/toolbelt.core.result-table/README.md), [Base64](../../Modules/toolbelt.conversion.base64/README.md), [Generate Series](../../Modules/toolbelt.core.generate-series/README.md) |
| Optionale Laufzeitmessungen | **NOT EXECUTED; KEIN PFLICHTGATE** | Die drei vorstehenden funktionalen Lastorakel bleiben Pflicht. Optionale Laufzeitmessungen sind getrennt und werden nicht als fehlender Pflichtlasttest oder als PASS gewertet. | Gesonderter Auftrag für eine Messung; ein solcher Auftrag ändert nicht die fachlichen Ergebnisorakel. | [DEC-2026-036](../../Documentation/Architecture/DECISIONS.md#dec-2026-036-verpflichtende-lasttests-und-optionale-laufzeitmessungen), [V0c-Pflichtlaststatus](../../Tests/V0C_RELEASE_GATE_STATUS.md) |
| Endanwender-Clients | **TEILWEISE BELEGT; GUI-/WINDOWS-LOGIN NICHT AUSGEFÜHRT** | Der ODBC-PowerShell-Helper ist separat belegt. Dieser Nachweis deckt weder SSMS-GUI noch Windows-Authentifizierung ab. | Für die fehlenden Clientwege jeweils konkreter Supportumfang und ein geeignetes Testziel. | [Clientqualifikation](CLR-CLIENT-QUALIFICATION.md), [API- und Grenzbericht](API-QUALIFICATION.md) |
| Authentifizierte TLS | **NOT EXECUTED; SEPARATER TRANSPORTNACHWEIS** | Funktionale Läufe mit explizitem Lab-Trust sind kein Serveridentitätsnachweis und blockieren keine unabhängigen Funktionstests. | Separater TLS-Vertrag und dafür qualifiziertes Ziel; keine automatische Trustumschaltung. | [TLS-Consumervertrag](../../Documentation/Architecture/LAB_QUALIFIED_TLS_CONSUMER.md), [API- und Grenzbericht](API-QUALIFICATION.md) |
| Finaler Releasekandidat | **AUSSTEHEND** | Paketintegrität, Dokumentationsaudit und erforderliche CI müssen am endgültigen integrierten Head belegt sein; danach sind alle noch anwendbaren Pflichtnachweise abzugleichen. | Abgeschlossene Pflichtnachweise und exakter finaler Head. | Dieses Dokument; [Evidenzzuordnung](EVIDENCE-MAP.md) |
| Veröffentlichung | **NICHT AUTORISIERT** | Kein Tag, Release oder Statusupgrade aus der vorhandenen Abnahme ableiten. | Separater ausdrücklicher Veröffentlichungsauftrag. | [Supportumfang und Freigabe](SUPPORT.md#freigabe) |

Die ältere Aussage in `Modules/toolbelt.string.regex/Tests/README.md`, die
16-MiB-Capturegrenze sei noch nicht in SQL ausgeführt, ist durch die spätere
gebundene Regex-Evidenz überholt. Diese Releaseübersicht ordnet den neueren
Nachweis ein, ändert aber weder die alte Moduldatei noch den getrennten
`Captures.Contract.sql`-Teilbefund.

Preview ersetzt keine Pflichtprüfung im zugesagten Scope. Authentifizierte
TLS-Abnahme bleibt getrennt; die optionalen Laufzeitmessungen für ResultTable,
Base64 und Generate Series sind kein pauschales Releasegate.

Die zusätzliche [Callerrechteprüfung von ResultTable/Error Envelope](TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md)
ist für fünf enge Profile auf zwölf Ziel-/CL-Kombinationen lokal und direkt
zentral abgeschlossen: 120 Profilszenarien und 360 strikte Rechteabweisungen.
Eine neue Breitenkontrolle wurde nach bestandener Baseline gezielt verworfen.
Vier frühere bereinigte Testfehler und ihre originalen Eingabebytes bleiben
historisch erhalten; der Produktcode und die Paket-SQL-/DLL-Bytes blieben gleich.
Der ResultTable-Lesepfad verweist seit 2026-10-25 auf den kanonischen
Manifeststatus und die aktuelle V0c-Abnahme; frühere Statustexte sind als
Historie getrennt. Dies ist eine Dokumentationskorrektur ohne Statusaufwertung.
Der unveränderte archivierte Paketstand bleibt an seine ursprünglichen
Dokumentationsbytes gebunden; der endgültige Releasekandidat muss den
korrigierten Lesepfad samt passenden Quellen-/Paketbindungen übernehmen.
Bestehende gültige Nachweise werden weder umetikettiert noch pauschal verworfen.

Am 2026-10-25 sind zusätzlich die sechs öffentlichen
[Work-Type-Callerprofile](WORK-TYPE-RIGHTS-QUALIFICATION.md) auf zwölf
Ziel-/CL-Kombinationen lokal und direkt zentral geprüft: 144 positive Profile,
1.368 strikte Abweisungen und unabhängige Audits aller eigenen Ressourcen.
Notwendige Handler-/Policyrechte sind ausdrücklich getrennt. Produktquellen,
Paketbytes und Modulstatus blieben unverändert; echte CrossDB-Identitäten und
weitere Policy-/Rollen-/Lifecycleverträge bleiben offen.

Der [Queue-Autorisierungsvertrag vom 2026-10-25](QUEUE-AUTHORIZATION-QUALIFICATION.md)
ist ebenfalls auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral geprüft.
Producer-Policy, ausführbarer Handler, DENY vor Idempotenzauskunft und
Callertransaktionsschutz sind für die bestehende feste Fixture belegt;
vollständige API-Minimalrechte, Managed-/Providerparallelität und harte
Recovery bleiben davon unabhängig offen.

Die [sechs Safe-Cast-Callerprofile](SAFE-CAST-RIGHTS-QUALIFICATION.md) sind
zusätzlich auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral mit jeweils
einem einzelnen SELECT geprüft. Die neue Rechtequalifikation ersetzt keine
Lifecycle-DDL-, echte CrossDB-, harte Recovery- oder Produktionskapazitätsabnahme.

Die [Cancellation-Callerrechte](CANCELLATION-RIGHTS-QUALIFICATION.md) sind
ebenfalls für drei isolierte API-Profile auf zwölf Ziel-/CL-Kombinationen
lokal/direkt zentral geprüft. Das schließt keine Quoten-, Konkurrenz-,
Retention-, Lifecycle-, CrossDB- oder Recoverygates mit ein.

Die [zusätzliche Geo-SQL-Matrix](GEO-MISSING-TARGETS-QUALIFICATION.md) ergänzt
acht bisher fehlende Ziel-/CL-Kombinationen lokal/direkt zentral mit unveränderten
Geo-/Safety-/SQL-Metadatenverträgen. Sie erweitert weder historische
Client-/Lifecycle-Abnahmen noch den Modulstatus oder die Veröffentlichung.

Die [Konvertierungs-Callerprofile](CONVERSION-CALLER-QUALIFICATION.md) ergänzen
16 öffentliche Base64-/IntegerBase-/URI-Funktionen einschließlich Status-TVFs
und Scalarwrappern: zwölf lokale/direkt zentrale Ziel-/CL-Fälle mit einzelnen
SELECT-/EXECUTE-Grants. Die [Metadatenkorrektur](CALLER-METADATA-UPDATE.md) schließt die pauschalen
Manifestlabels dieser drei Module; keine Statusaufwertung.

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
ergänzen vier TVFs und Lookup mit Einzelgrants sowie den getrennten
Lookup-/Helperpfad auf zwölf lokalen/direkt zentralen Ziel-/CL-Kombinationen.
Großwert-/Konkurrenz-/Lifecycle-, echte CrossDB- und Recoverygates bleiben separat.

Die [Queue-Frontend-Callerrechte](QUEUE-FRONTEND-RIGHTS-QUALIFICATION.md)
und [Worker-Callerrechte](QUEUE-WORKER-RIGHTS-QUALIFICATION.md) belegen direkte
Callerprofile aller 13 öffentlichen Queue-APIs auf zwölf Ziel-/CL-Kombinationen.
Die befüllte Blockerview ist vor/nach eigenem Complete geprüft; Snapshotanlage,
Managed-/Provider-/Workerhost-, ResultTable-Ausgabe-, volle Lifecycle-/
Parallelitäts-/Ressourcen- und harte Recoveryverträge bleiben separat.

Die [Split-Advanced-Callerrechte](SPLIT-ADVANCED-RIGHTS-QUALIFICATION.md)
sind durch den [ergänzenden CL-Abschluss](SPLIT-ADVANCED-CL-COMPLETION.md)
auf zwölf Ziel-/CL-Kombinationen lokal/direkt zentral belegt. Sechs niedrigere
CL-Fälle wurden neu geprüft, die bisherigen sechs Fälle bei identischen
Inputs wiederverwendet. Andere Lifecycle-/CrossDB-/Recoveryverträge bleiben offen.

Die verbleibenden Arbeiten sind damit genauer getrennt:

| Punkt | Noch erforderlich | Voraussetzung / Verantwortung |
|---|---|---|
| Fachliche Modulabnahme | Nachweiszuordnung aller 45 Module liegt vor. Noch unbelegte API-, Ausgabegrenzen-, Lifecycle-/Upgrade- und Clientfälle je zugesagter Kombination abschließen. Historisches Capture-Timeout-Gate begrenzt angenommen; skalare Rechte-Dokumentation korrigiert und [begrenzt qualifiziert](REGEX-RIGHTS-QUALIFICATION.md). Ausgewählte grüne Fixtures ersetzen keine volle Modulabnahme | Modulverantwortlicher; bestehende unveränderte Nachweise nur in ihrem belegten Scope weiterverwenden |
| Minimalrechte | Die sechs Regex-Skalarfunktionen, alle fünf öffentlichen [Execution-Context-APIs](EXECUTION-CONTEXT-RIGHTS-QUALIFICATION.md) und fünf [ResultTable-/Error-Envelope-Profile](TABLE-ENVELOPE-RIGHTS-INVESTIGATION.md) sind jeweils lokal und direkt zentral auf zwölf Ziel-/CL-Kombinationen mit eigenen Benutzern ohne Login geprüft; andere APIs und echte CrossDB-Identitätsmappings bleiben separat | Der ausdrücklich freigegebene enge Datenbank-Testaufbau wurde vollständig bereinigt. Execution Context prüft jeweils nur ein Objektrecht und die Abweisung der vier anderen APIs. Keine Server-Logins oder fremden Rechte; weitere Principals nur mit passender Freigabe |
| Datei-/Identitätsmodule | Serverseitige synthetische Datei-, NTFS-/Reparse-/Caller-/ServiceAccount-Fixtures und ihre jeweiligen positiven/negativen Fälle | Bereitgestellte Fixtures/Identitäten mit geklärter Ownership; keine eigenmächtige Änderung der Labinfrastruktur |
| Provider/Worker und harte Recovery | Erforderliche administrierte Provider-/Workerhostkombinationen und kontrollierter echter Transport-/Hostverlust | Vorkonfigurierte Provider und geeignete gesonderte Recoveryumgebung; laufende mutierende Tests werden nicht als Ersatz hart abgebrochen |
| Weitere Ressourcen-/Parallelgrenzen | Die modulspezifisch weiterhin verpflichtenden Last-/Heap-/Parallelfälle | Je Modul begrenzter gesonderter Testscope und passende Voraussetzungen; die drei ausdrücklich optionalen Laufzeitmessungen bleiben optional |
| Endanwender-Clientwege | Der optionale ODBC-PowerShell-Helper ist mit expliziter SQL-Anmeldung auf zwölf Ziel-/CL-Kombinationen [nativ geprüft](CLR-CLIENT-QUALIFICATION.md); SSMS-GUI und Windows-Anmeldung bleiben `not executed` | Noch ausstehende GUI-/Windows-Identitätsprüfung; fachliche Modul- und TLS-Gates bleiben separat |

Für Kanalaufteilung, grundsätzlichen Plattform-/Deployment-Zielumfang und die
Lieferung fertiger CLR-DLLs ist keine erneute Grundsatzentscheidung offen.
Die explizite öffentliche Veröffentlichungsfreigabe bleibt ausstehend.

## Aufwand und Fortsetzung

Die aktuelle SSIS-Paketmatrix ergänzt zehn fehlende Fälle samt zehn unabhängigen
Audits und übernimmt zwei unveränderte grüne Fälle ohne erneuten SQL-Lauf.
Ein Luna-Implementierer und das integrierende Vertrags-/Evidenzreview genügen.
Sechs Offlineprüfungen für Zusammensetzung und Manipulationsabwehr laufen im
bestehenden SSIS-Workflow; es entstehen weder ein weiterer Workflow noch ein
SQL-CI-Lauf, Prozessrunner oder eine zusätzliche Reviewkette. Lokal werden nur
geänderte Prüfungen ausgeführt; Pflichtprüfungen am aktuellen Head und die echte
Main-Push-CI bleiben erforderlich. Rohprotokolle bleiben privat; Kosten und
Tokens sind unbekannt. Produkt und Paketbytes bleiben unverändert.

Die Head-CI fand außerdem eine zu enge äußere 30-Sekunden-Grenze der
Release-Regressionssuite. Diese ist auf weiterhin endliche 120 Sekunden
angehoben; Umfang, Assertions und einzelne Prozessgrenzen bleiben erhalten.
Ein zunächst nur generisch fehlgeschlagener Edit-Distance-Frameworklauf
bestand lokal und im folgenden Head-Lauf. Seine genaue Erstursache bleibt
nicht reproduziert; der bestehende Workflow meldet künftig begrenzt feste
Prozessfehlercodes und Quellzeilen statt privater Prozessdetails. Beide
CI-Anpassungen ändern keine Produkt-, SQL-, DLL- oder nativen Testinputs.
Es entstehen keine neuen Jobs, Trigger, Testfälle oder Reviewketten; die
größere äußere Reserve gilt nur der vorhandenen Offline-Regressionssuite.
Aktuelle Head-Ergebnisse werden im bestehenden PR geführt.

Der zusätzliche menschliche Installationsauftrag wird durch `INSTALL.md`
und direkte Einstiege aus Root-README, Dokumentationsübersicht und Paketstart
erfüllt. Die Anleitung trennt den Endanwenderweg mit verpflichtendem
ZIP-Prüfsummenvergleich von der weiterhin vollständigen Maintainer-/CI-
Quellprüfung. SSMS-Menüs und Verbindungsdialoge sind anhand der verlinkten
Microsoft-Primärquellen geprüft; ein neuer SSMS-GUI-Lauf ist `not executed`.
Die gezeigten Funktionen und Parameter entsprechen den nativen Paketorakeln.

Die bisherige Root-README-Prosa bleibt mit rebasierten Links unter
`Documentation/History/` erhalten. Frühere Abschnittslinks bleiben erreichbar,
geschützte Lizenztexte bleiben unverändert. Der Inventarcheck liest den
kanonischen generierten Modulkatalog und kontrolliert die beiden Einstiege
aus der Root-README. Fehlende, zusätzliche oder doppelte Module sowie fehlende
Installations-/Kataloglinks werden weiter abgewiesen; drei gezielte
Regressionen laufen in der bestehenden Katalogsuite. Es entsteht weder eine
zweite Modulliste noch ein neuer CI-Job. Die Release-Freigabematrix führt pro
Modul direkt zur lesbaren Modul-README statt zuerst zum YAML-Manifest.

Ein Implementierungsverantwortlicher, ein Arbeitspaket und ein PR; keine
Delegation, neue CI-Workflows oder automatischen Folgewellen. Native Prüfungen
wurden endlich ausgewählt, Inputs privat eingefroren und pro Fall begrenzt;
der konkrete Markerfehler begründete den korrigierten Folgeversuch.
Die zwei isolierten CLR-Builds prüfen ausdrücklich Reproduzierbarkeit, keine
Statusauffrischung vorhandener Modulnachweise. Zusätzliche Harness-/Pfadguards
laufen ohne SQL innerhalb der bestehenden Release-Regressionssuite. Kosten-
und Tokenverbrauch sind `UNKNOWN`. Die spätere ausdrückliche
[Releasefortsetzung](SUPPORT.md#releasefortsetzung-vom-2026-10-24) aktiviert
jetzt autonome Arbeit im bestehenden v1.0.0-Zielumfang und einen Heartbeat als
Stillstand-Sicherungsnetz; Veröffentlichung bleibt ein eigener Auftrag.

## JSON-Schema-Callertransaktionen

Der [gebundene Caller-Transaktionsnachweis](json-schema-caller-transaction-qualification.json)
qualifiziert ausschließlich Deploy bei fehlendem Schema und Uninstall bei
installiertem Schema auf Windows SQL Server 2025/CU8/CL170 lokal. Beide
Ablehnungen erhalten die aktive Callertransaktion, den Savepoint, den
Modulzustand und die Sessionoptionen; beide Aufrufe gelingen nach vollständigem
Rollback ohne Callertransaktion. Das Startprofil ist fest auf
`QUOTED_IDENTIFIER ON`, `XACT_ABORT OFF` und `NOCOUNT OFF` gesetzt. Ein
erfolgreicher Zielaufruf mit zwei Fachfällen und beide unabhängigen Bereinigungsaudits bestanden;
ein vorangegangener bereinigter Vorversuch ist getrennt erfasst. Der Nachweis
erweitert keine anderen Sessionprofile, Ziele oder vollständigen API-, Rechte-
und Lifecyclematrizen. Produkt- und Paketbytes blieben unverändert; eine
Veröffentlichung ist nicht autorisiert.

## JSON-Schema-Deploy-Kollisionsschutz

Der [gebundene Nachweis](json-schema-deploy-collision-qualification.json)
qualifiziert vier feste Deploy-Abweisungen bei fehlendem Schema-Modul und
eigenem leerem `toolbelt_json`-Namespace auf Windows SQL Server 2025/CU8/CL170
lokal: reservierter Caller-Tempzustand (55633/State 1),
fremder öffentlicher und interner Slot sowie verwaister DeploymentMode-Marker
(jeweils 55634/State 1). Jeder Fehler erhält den vollständigen Modulzustand
und seine synthetische Fixture bis zur geprüften eigenen Bereinigung. Erst
danach folgt ein gemeinsamer erfolgreicher Deploy. Ein Zielaufruf und ein
unabhängiges Cleanup-/Pin-Audit bestanden, ohne fehlgeschlagene Nativeversuche.
Der Scope ist keine vollständige Fremdslot-, Marker-, Rechte- oder
Lifecyclequalifikation; Produkt und Paket blieben unverändert.
