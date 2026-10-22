# v1.0.0: erledigte Prüfungen und offene Releasegates

Stand 2026-10-22. Dies ist der Prüfbericht zur unveröffentlichten
[Releasevorbereitung](README.md), keine Freigabe von Supportkombinationen.
Die [Freigabematrix](FREIGABEMATRIX.md) bleibt bei 19 stabilen und 26
Preview-Kandidaten; alle 45 Modulmanifeste bleiben `unreleased`.

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
aktuellen Prüf-/Paketierungsquellen. Dokumentations- und Helperergänzungen
ändern diese SQL-/DLL-Bytes nicht; der finale ZIP-Hash ist entsprechend neu.

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

## Was vor Veröffentlichung offen bleibt

| Gate | Konkret erforderlich | Abhängigkeit |
|---|---|---|
| Fachlicher Releaseumfang | Modulversionen und stabile/Preview-Kanäle sowie SQL-/CL-/Plattform-/Provider-/Deployment-/Consumerkombinationen ausdrücklich abnehmen | Releaseentscheidung des Benutzers; die Matrix ist weiterhin ein Vorschlag |
| Pflichtqualifikation im gewählten Umfang | Fehlende Minimalrechte-, API-/Lifecycle-, Datei-/Identitäts-/Worker-, Heap-/Parallelitäts- oder Recoveryfälle je Modul prüfen oder die betreffende Kombination außerhalb des veröffentlichten Umfangs halten | Konkreter Supportumfang; gegebenenfalls bereitgestellte Principals, Fixtures oder gesonderte Recoveryumgebung |
| CLR-Releaseumfang abnehmen | Den jetzt vorhandenen vorgebauten CLR-Installationssatz mit seinen begrenzten Paketnachweisen in den zugesagten Releaseumfang übernehmen | Das Liefergate „DLLs ohne eigenen Build“ ist technisch erledigt; vollständige fachliche Pflichtnachweise der gewählten Preview-Kombinationen bleiben erforderlich |
| Gesamter endgültiger Lieferumfang | Den tatsächlich zu veröffentlichenden Paketstand mit den freigegebenen Modulen einschließlich gewählter CLR-/Previewanteile installieren und die zugesagten Upgrade-/Uninstallwege prüfen | Finaler Lieferumfang und zugehörige Voraussetzungen; die Installation aller 45 Module ist `not executed` |
| Finaler Releasekandidat | Paketintegrität, Dokumentationsaudit und echte CI am endgültigen Head bestätigen; geänderte Inputs mit betroffenem Nachweis abgleichen | Nach Abschluss der noch offenen Inhalte; heutige grüne CI qualifiziert keine späteren Änderungen |
| Öffentliche Veröffentlichung | Separater ausdrücklicher Auftrag; danach tatsächlichen Tag, Release-URL, Zeitpunkt, Assethashes und `publication_record` je veröffentlichter Modulversion pflegen | Noch nicht autorisiert; kein Tag, kein GitHub-Release und keine Statusaufwertung |

Preview ersetzt keine Pflichtprüfung im zugesagten Scope. Authentifizierte
TLS-Abnahme bleibt getrennt; die optionalen Laufzeitmessungen für ResultTable,
Base64 und Generate Series sind kein pauschales Releasegate.

## Aufwand und Fortsetzung

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
und Tokenverbrauch sind `UNKNOWN`. Die autonome Weiterentwicklung und ihre
Automation bleiben pausiert; eine spätere Veröffentlichung benötigt einen
eigenen Auftrag.
