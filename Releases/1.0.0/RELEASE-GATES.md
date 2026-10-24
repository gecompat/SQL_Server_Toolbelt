# v1.0.0: erledigte Prüfungen und offene Releasegates

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
| Ausgewählte Frameworkprüfungen | Sieben bestehende Suiten auf den neuen Kandidaten bestanden: CSV, Phonetic, ZIP-Writer, drei Regex-Suiten und SSIS Full | Fünf CLR-Module in begrenzten Frameworkprofilen; keine vollständige IL-/Framework- oder SQL-Qualifikation aller zwölf Projekte |

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
Ziel-/CL-Fällen. Die gefundene falsche skalare Rechte-Dokumentation, echte
Lowpriv-CrossDB-Mappings und übrige Modulpflichtfälle bleiben offen.

| Gate | Konkret erforderlich | Abhängigkeit |
|---|---|---|
| Fachlicher Zielumfang | Erledigt: 45 bestehende Modulversionen, 19 stabil/26 Preview und SQL-/CL-/Plattform-/Deployment-Zielumfang sind ausdrücklich übernommen | [Benutzerfreigabe](SUPPORT.md#freigabe); konkrete öffentliche Kombinationen brauchen weiterhin ihre vollständigen Pflichtnachweise |
| Pflichtqualifikation im gewählten Umfang | Fehlende Minimalrechte-, API-/Lifecycle-, Datei-/Identitäts-/Worker-, Heap-/Parallelitäts- oder Recoveryfälle je Modul prüfen oder die betreffende Kombination außerhalb des veröffentlichten Umfangs halten | Konkreter Supportumfang; gegebenenfalls bereitgestellte Principals, Fixtures oder gesonderte Recoveryumgebung |
| CLR-Lieferumfang | Erledigt: vorgebauter Installationssatz samt Quellen ist in den Zielumfang übernommen | Keine weitere Build-/Lieferentscheidung offen; vollständige fachliche Pflichtnachweise der gewählten Preview-Kombinationen bleiben erforderlich |
| Gemeinsamer Paket-Lifecycle | Erledigt für die vier abgegrenzten Profile: Erst-/Repeat-/Uninstall-/Absent-Repeat und zentrale Consumer in zwölf physischen Ziel-/CL-Fällen; eigenständige CLR-Profile nochmals separat geprüft | Kein universeller historischer Upgradepfad und keine vollständige neue APIabnahme aller 45 Module |
| Finaler Releasekandidat | Paketintegrität, Dokumentationsaudit und echte CI am endgültigen Head bestätigen; geänderte Inputs mit betroffenem Nachweis abgleichen | Nach Abschluss der noch offenen Inhalte; heutige grüne CI qualifiziert keine späteren Änderungen |
| Öffentliche Veröffentlichung | Separater ausdrücklicher Auftrag; danach tatsächlichen Tag, Release-URL, Zeitpunkt, Assethashes und `publication_record` je veröffentlichter Modulversion pflegen | Noch nicht autorisiert; kein Tag, kein GitHub-Release und keine Statusaufwertung |

Preview ersetzt keine Pflichtprüfung im zugesagten Scope. Authentifizierte
TLS-Abnahme bleibt getrennt; die optionalen Laufzeitmessungen für ResultTable,
Base64 und Generate Series sind kein pauschales Releasegate.

Die verbleibenden Arbeiten sind damit genauer getrennt:

| Punkt | Noch erforderlich | Voraussetzung / Verantwortung |
|---|---|---|
| Fachliche Modulabnahme | Nachweiszuordnung aller 45 Module liegt vor. Noch unbelegte API-, Ausgabegrenzen-, Lifecycle-/Upgrade- und Clientfälle je zugesagter Kombination abschließen. Historisches Capture-Timeout-Gate begrenzt angenommen; skalare Rechte-Dokumentation korrigiert und [begrenzt qualifiziert](REGEX-RIGHTS-QUALIFICATION.md). Ausgewählte grüne Fixtures ersetzen keine volle Modulabnahme | Modulverantwortlicher; bestehende unveränderte Nachweise nur in ihrem belegten Scope weiterverwenden |
| Minimalrechte | Die sechs Regex-Skalarfunktionen sind lokal und direkt zentral auf zwölf Ziel-/CL-Kombinationen mit eigenen Benutzern ohne Login geprüft; andere APIs und echte CrossDB-Identitätsmappings bleiben separat | Der ausdrücklich freigegebene enge Datenbank-Testaufbau wurde vollständig bereinigt. Keine Server-Logins oder fremden Rechte; weitere Principals nur mit passender Freigabe |
| Datei-/Identitätsmodule | Serverseitige synthetische Datei-, NTFS-/Reparse-/Caller-/ServiceAccount-Fixtures und ihre jeweiligen positiven/negativen Fälle | Bereitgestellte Fixtures/Identitäten mit geklärter Ownership; keine eigenmächtige Änderung der Labinfrastruktur |
| Provider/Worker und harte Recovery | Erforderliche administrierte Provider-/Workerhostkombinationen und kontrollierter echter Transport-/Hostverlust | Vorkonfigurierte Provider und geeignete gesonderte Recoveryumgebung; laufende mutierende Tests werden nicht als Ersatz hart abgebrochen |
| Weitere Ressourcen-/Parallelgrenzen | Die modulspezifisch weiterhin verpflichtenden Last-/Heap-/Parallelfälle | Je Modul begrenzter gesonderter Testscope und passende Voraussetzungen; die drei ausdrücklich optionalen Laufzeitmessungen bleiben optional |
| Endanwender-Clientwege | Der optionale ODBC-PowerShell-Helper ist mit expliziter SQL-Anmeldung auf zwölf Ziel-/CL-Kombinationen [nativ geprüft](CLR-CLIENT-QUALIFICATION.md); SSMS-GUI und Windows-Anmeldung bleiben `not executed` | Noch ausstehende GUI-/Windows-Identitätsprüfung; fachliche Modul- und TLS-Gates bleiben separat |

Für Kanalaufteilung, grundsätzlichen Plattform-/Deployment-Zielumfang und die
Lieferung fertiger CLR-DLLs ist keine erneute Grundsatzentscheidung offen.
Die explizite öffentliche Veröffentlichungsfreigabe bleibt ausstehend.

## Aufwand und Fortsetzung

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
