# Historische Modulnotizen aus der Projekt-README

Diese Seite erhält die früheren Modul- und Testnotizen der Root-README mit
ihrem jeweiligen damaligen Versions- und Nachweisumfang. Übernommen am
2026-10-22; keine neue Prüfung und keine aktuelle Supportzusage.

Für die heutige Auswahl beginne mit der [Modulübersicht](../../Modules/README.md),
für die Installation mit der [Schritt-für-Schritt-Anleitung](../../INSTALL.md).
Die Modulmanifeste und ihre verlinkte aktuelle Evidenz bleiben maßgeblich.

## Aktueller Status

[`toolbelt.core.worker-control`](../../Modules/toolbelt.core.worker-control/README.md)
ergänzt den externen Worker um ein explizites Managed-Opt-in mit zentraler
SQL-Steuerung, dynamischen Parallelitätsbudgets und Stop/Hold. Der gezielte
SQL-Vertrag auf 2019 Linux und 2025 Windows/CU8 ist bestanden; Linux-Workerhost-Nachweis
über Head-CI stehen aus. Spätere Agent-, Broker- und
SSIS-Provider sind abgegrenzt.

`toolbelt.json.constructors` 1.1.0 implementiert die beiden einzeln freigegebenen Gruppen-USPs über den gemeinsamen T-SQL-Kern. Auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 bestanden lokal und zentral die API-/100000-/16-MiB-/Clientprüfungen als Teil insgesamt fehlgeschlagener früherer Läufe. Die finalen fokussierten Läufe mit ausschließlich InstalledMetadata.Contract.sql als Runtime-Auswahl bestanden Metadaten, genuine 1.0-Upgrades, Lifecycle, Central und eigene Bereinigung. Neue Minimalrechte bleiben offen; die Uninstall-Voraussetzung VIEW DEFINITION/SELECT wurde am 2026-10-02 einzeln freigegeben und die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht; historische 1.0-Evidenz bleibt getrennt.

**Der Repository-Grundaufbau ist abgeschlossen. 45 Module sind implementiert; 21 sind `validated`, 24 sind `partially validated`, 0 sind `not executed`, alle sind `unreleased`.**

Securitystand 2026-10-19: Die 25 ausdrücklich freigegebenen Härtungen sind
implementiert und gezielt geprüft. URI, Path Exists und Split Characters
sind mit der aktuellen V0c-Fachmatrix nachqualifiziert; Cancellation und
andere Modulgrenzen bleiben gemäß Manifest separat. Die ersten 16 Module
sind nach erfolgreichen Pflicht-Lastfällen validiert; Zeitmessungen sind optional. Authentifizierte
Lab-TLS-Abnahme bleibt separat und blockiert unabhängige Fachtests nicht. [Verträge und Nachweisgrenzen](../../Documentation/Architecture/SECURITY_HARDENING_2026_10.md).


[`toolbelt.pseudonymization.deterministic`](../../Modules/toolbelt.pseudonymization.deterministic/README.md)
liefert versionierte synthetische Range-, DateShift- und Pool-Lookup-Werte;
Version 1.1.0 ergänzt die formaterhaltende ASCII-Translation.
Der vollständige Translate-Adapter besteht auf SQL Server 2019 Linux/latest
local/central und 2025 Windows/CU8 central CL150/160/170. Windows local ist
durch erfolgreiche API-/Safetyfälle und die separate korrigierte Metadaten-/
Lifecycleprüfung belegt; der frühere Gesamtfehllauf bleibt davon getrennt.
Die sieben abschließenden 1.1-CI-Prüfungen und der Merge sind in
[PR #140](https://github.com/gecompat/SQL_Server_Toolbelt/pull/140) belegt.
Version 1.2.0 ergänzt die einzeln freigegebene synthetische GeoJitter-TVF;
Finale Geo-API-/Safety-/Metadaten- und Lifecycleadapter bestehen auf Linux
2019/latest und Windows 2025/CU8 lokal und zentral; drei ausgewählte Runtime-Fixtures
und der ursprüngliche fünfteilige Geo-Vertrag mit 504 Orakeln sind geprüft.
Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. Weitere Ziele, neue Minimalrechte-
und Kapazitätsnachweise bleiben offen. `partially validated`, `unreleased`;
keine Anonymisierungszusage.

Die Execution-Grundlagen bestehen aus
[`toolbelt.core.error-envelope`](../../Modules/toolbelt.core.error-envelope/README.md)
und
[`toolbelt.core.execution-context`](../../Modules/toolbelt.core.execution-context/README.md).
Sie standardisieren explizit übergebene Fehlerdaten und verwalten eine
sessiongebundene Execution-/Correlation-ID ohne persistente Tabellen. Beide
sind auf Windows/Linux 2019/2022/2025 `validated`.

Der persistente
[`toolbelt.core.work-type`](../../Modules/toolbelt.core.work-type/README.md)
registriert ausschließlich kontrollierte Stored-Procedure-Work-Types.
Raw SQL bleibt ausgeschlossen; Änderungen sind über `rowversion`,
explizite Update-/Reaktivierungsflags und Data-Loss-geschützten Uninstall
abgesichert. Das Modul ist auf Windows/Linux 2019/2022/2025 `validated`.

Die freigegebenen E1a-/E1b-/W6c-Slices
[`toolbelt.core.work-queue`](../../Modules/toolbelt.core.work-queue/README.md)
stellen Enqueue, atomaren Lease-Claim, Heartbeat, explizite Recovery, Complete,
Fail, Retry, Dead Letter, Idempotenz und gruppenbezogene Drain-Barriers bereit.
Die historische 2.0-Matrix auf SQL Server 2019, 2022 und 2025 unter Windows
und Linux ist erfolgreich. Die neue 2.1-Managedkopplung und der echte
2.0→2.1-Upgrade sind im gezielten SQL-Scope geprüft; das Modul bleibt
`partially validated` und `unreleased`.
Cancellation bleibt ein getrennter Slice.

[`toolbelt.core.execution-cancel`](../../Modules/toolbelt.core.execution-cancel/README.md)
stellt für W6d eine persistierte, irreversible kooperative Cancellation je
ExecutionId bereit. Sie beendet keine Sessions und mutiert keine Work-Queue-
Items. Die Windows-/Linux-Matrix SQL Server 2019/2022/2025 ist erfolgreich;
das Modul ist `validated` und `unreleased`.

[`toolbelt.core.second-session`](../../Modules/toolbelt.core.second-session/README.md)
führt registrierte Work-Types synchron über einen administrativ vorbereiteten
Loopback-Linked-Server in einer getrennten SQL-Server-Session aus und ist auf
Windows/Linux 2019/2022/2025 `validated`.

[`toolbelt.core.event-log`](../../Modules/toolbelt.core.event-log/README.md)
persistiert strukturierte Events synchron in einer zweiten Session. Erfolgreiche
Writes überleben Caller-Rollback und uncommittable Caller-Transaktionen; Linked
Server und Login-Mappings bleiben administrativ außerhalb des Moduls. Das
Modul ist auf Windows/Linux 2019/2022/2025 `validated`.

Das portable Modul
[`toolbelt.file.content`](../../Modules/toolbelt.file.content/README.md)
liest freigegebene Text- und Binärdateien über einen Root-Allowlist-Vertrag.
Die SQL-Server-2025-Linux-Matrix mit Compatibility Levels 150, 160 und 170
ist erfolgreich; Windows, separat bereitgestellte serverseitige Fixtures und
nicht-ASCII-spezifische Providergrenzen bleiben als getrennte
Releasevalidierung sichtbar.

Das implementierte Modul [`toolbelt.core.result-table`](../../Modules/toolbelt.core.result-table/README.md) stellt `toolbelt_core.USP_PrepareResultTable` als gemeinsame `@ResultTable`-/`@KeepData`-Infrastruktur bereit. Die Windows-/Linux-Matrix ist auf SQL Server 2019, 2022 und 2025 erfolgreich; der Pflicht-Lastfall auf SQL 2025 Linux CL170 ist erfolgreich, Laufzeitmessungen sind optional.

Das unabhängige Modul
[`toolbelt.conversion.base64`](../../Modules/toolbelt.conversion.base64/README.md)
stellt portable Base64-/Base64URL-Konvertierung bereit. Der vollständige
Moduladapter ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter
Windows base und Linux latest erfolgreich; der 4-MiB-Pflicht-Lastfall ist
zusätzlich geprüft. Laufzeitmessungen sind optional.

Das implementierte Modul
[`toolbelt.core.generate-series`](../../Modules/toolbelt.core.generate-series/README.md)
stellt portable, typstabile Ganzzahlreihen für `int` und `bigint` bereit. Der
vollständige Moduladapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich; der
Zehn-Millionen-Pflicht-Lastfall ist zusätzlich geprüft. Laufzeitmessungen sind optional.

Das implementierte Modul
[`toolbelt.metadata.identifier`](../../Modules/toolbelt.metadata.identifier/README.md)
analysiert und begrenzt ein- bis vierteilige SQL-Namen. Der vollständige
Moduladapter ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter
Windows base und Linux latest erfolgreich; das Modul ist `validated`.

Das implementierte Modul
[`toolbelt.string.split-characters`](../../Modules/toolbelt.string.split-characters/README.md)
teilt Unicode-Text an mehreren einzelnen literal interpretierten
Separatorzeichen. Die Windows-/Linux-Matrix 2019/2022/2025 ist erfolgreich;
das Modul ist `validated`. Die breitere Quote-/Escape-Ausbaustufe bleibt
separat in `TC-2026-032`; S2 ist als
[`toolbelt.string.split-advanced`](../../Modules/toolbelt.string.split-advanced/README.md)
implementiert und auf SQL Server 2019 Linux sowie 2025 Linux/Windows gezielt geprüft.
Version 1.1.0 ergänzt ausdrücklich freigegebenes, separates Unquoting und die
prozedurale Split-Fassade mit Help und ResultTable. Der Split selbst gibt
weiterhin Originaltokens zurück; die Folgeversion behält den begrenzten,
risikobasierten Validierungsstatus ihrer Modul-Testmatrix.

Das Modul
[`toolbelt.string.edit-distance`](../../Modules/toolbelt.string.edit-distance/README.md)
implementiert in 1.1.0 die einzeln freigegebenen Levenshtein-/OSA-/Jaro-Winkler-TVFs
mit gemeinsamem portablen SAFE-CLR-Kern. Unicode Scalars und feste Profile sind
begrenzt und ohne Kürzung. Neue Offline Framework-/Matrixprüfungen, Releasebuilds
und IL-Metadatengates bestanden; private native 1.1-Gesamtadapter auf Linux
2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral samt
SC-UTF8 und unabhängiger eigener DB-/Trustbereinigung bestanden.
Tatsächliche Minimalrechte und übrige physische Ziele bleiben offen. Teilweise validiert, unveröffentlicht; aktuelle CI als
separater PR-Mergegate.

Das implementierte R1b-Modul
[`toolbelt.string.regex`](../../Modules/toolbelt.string.regex/README.md) stellt
IsMatch, Instr und Count für einen begrenzten, parsergesicherten
Toolbelt-Regexdialekt über `SAFE` SQL CLR bereit. Die vollständige physische
Matrix SQL Server 2019/2022/2025 unter Windows base und Linux latest ist
erfolgreich. Version 1.2.0 ergänzt Matches-/Split-TVFs über denselben Kern;
der vollständige neue Adapter besteht auf SQL Server 2019 Linux/latest CL150
und 2025 Windows/CU8 CL150/160/170. Weitere R2b-Ziele, Lowpriv-CrossDB und
SQL-100k-Durchsatz bleiben offen. RE2-Parität und lineare Laufzeit werden nicht
behauptet; die neue Modulversion ist `partially validated` und `unreleased`.

Version 1.3.0 ergänzt sämtliche Capture-Wiederholungen und getrenntes
gruppenbezogenes Replace. Die finalen Gesamtadapter auf denselben beiden
Zielen bestehen lokal/zentral einschließlich echtem 1.2-Upgrade, expliziter
erwarteter Binaryhashbindung, Caller-TX/Optionserhalt, AppLock, Rollback,
Kollisionen, Dependencies, Uninstall und eigenem DB-/Trustcleanup.
Neue Capture-Minimalrechte, weitere Ziele, große SQL-Capture-Ausgabe und
SQL-100k-Durchsatz bleiben offen. Der Nachweis der aktuellen CI erfolgt separat
als PR-Mergegate. Teilweise validiert, unveröffentlicht.

Das implementierte Modul
[`toolbelt.validation.semantic-version`](../../Modules/toolbelt.validation.semantic-version/README.md)
parst, vergleicht und sortiert strikte Semantic-Version-2.0.0-Werte. Der
vollständige Moduladapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich; das Modul ist
`validated`.

Das implementierte Modul
[`toolbelt.conversion.integer-base`](../../Modules/toolbelt.conversion.integer-base/README.md)
codiert und decodiert den vollständigen `bigint`-Bereich mit frei
definierbaren ASCII-Alphabeten. Der vollständige Moduladapter ist auf
physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und
Linux latest erfolgreich; der aktuelle Modulstatus ist `partially validated`.
Wartungscheckpoint 2026-10-09 vor CI: Die Korrektur für `+` als Alphabetziffer
ist `SOURCE_ONLY` und `NOT_EXECUTED`. Die bisherigen Matrixnachweise bleiben
historisch erhalten; die geänderte Quelle ist noch nicht nativ qualifiziert.

Das implementierte Modul
[`toolbelt.datetime.calendar-difference`](../../Modules/toolbelt.datetime.calendar-difference/README.md)
zerlegt `date`-Intervalle nach einer dokumentierten Anniversary-Regel. Der
vollständige Moduladapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest einschließlich Lifecycle,
Kollisionsschutz und zentraler Nutzung erfolgreich; das Modul ist `validated`.

Das implementierte Modul
[`toolbelt.string.directional-trim`](../../Modules/toolbelt.string.directional-trim/README.md)
stellt typstabile `varchar`-/`nvarchar`-TVFs für `LEADING`, `TRAILING` und
`BOTH` bereit. Der vollständige Moduladapter ist auf physischen SQL-Server-
2019-, 2022- und 2025-Zielen unter Windows base und Linux latest einschließlich
CI-, CS- und UTF-8-Collations erfolgreich; das Modul ist `validated`.

Das implementierte Modul
[`toolbelt.conversion.uri-component`](../../Modules/toolbelt.conversion.uri-component/README.md)
codiert und decodiert RFC-3986-URI-Komponenten mit UTF-8 und strikter
Validierung. Der vollständige Moduladapter ist auf physischen SQL-Server-
2019-, 2022- und 2025-Zielen unter Windows base und Linux latest einschließlich
ASCII-, Unicode- und Large-Input-Fällen erfolgreich; das Modul ist `validated`.

Die implementierten W2a-Module
[`toolbelt.datetime.truncate`](../../Modules/toolbelt.datetime.truncate/README.md),
[`toolbelt.datetime.bucket`](../../Modules/toolbelt.datetime.bucket/README.md) und
[`toolbelt.binary.bit-operations`](../../Modules/toolbelt.binary.bit-operations/README.md)
stellen typgetrennte Date/Time-Truncation, Origin-basiertes Bucketing und die
fünf Bitoperationen für `bigint` als kanonische relationale TVFs bereit.
Die vollständigen Moduladapter sind auf physischen SQL-Server-2019-, 2022-
und 2025-Zielen unter Windows base und Linux latest einschließlich nativer
Parität, Kollisionsschutz, Wiederholungsdeployment, Lifecycle, Central und
Uninstall erfolgreich; die drei Module sind `validated`.

Das implementierte D1-Modul
[`toolbelt.datetime.date-spine`](../../Modules/toolbelt.datetime.date-spine/README.md)
erzeugt Tages-, ISO-Wochen- und Monatsperioden für halboffene `date`-Bereiche.
Der vollständige Adapter ist auf physischen SQL-Server-2019-/2022-/2025-
Zielen unter Windows base und Linux latest erfolgreich; das Modul ist
`validated`.

Das implementierte W2b-A-Modul
[`toolbelt.json.path-exists`](../../Modules/toolbelt.json.path-exists/README.md)
prüft SQL/JSON-Pfade fehlerfrei auf Existenz und stellt den Backport-Slice von
`TC-2026-009` bereit. Die Windows-/Linux-Matrix 2019/2022/2025 ist
einschließlich nativer Parität, Kollisionsschutz, Lifecycle, Central und
Uninstall erfolgreich; das Modul ist `validated`. JSON-Aggregate bleiben
ausdrücklich zurückgestellt.

[`toolbelt.json.core`](../../Modules/toolbelt.json.core/README.md)1.0 stellt den
gemeinsamen technischen SAFE-JSON-Scanner bereit;
[`toolbelt.json.schema`](../../Modules/toolbelt.json.schema/README.md)1.0 ergänzt
das begrenzte Profil `toolbelt-2020-12-v1` mit exakten Zahlen/Unicode,
lokalen nichtrekursiven Referenzen und vollständigem Urteil trotz gekürzter
Diagnosen. Die native Core-/Schema-Teilqualifikation auf Linux2019 CL150
und Windows2025 CU8 CL170 bestand local/central. Weitere Matrix und
vollständige Lifecycle-/Rechtequalifikation offen, unveröffentlicht.

[`toolbelt.json.constructors`](../../Modules/toolbelt.json.constructors/README.md)
ergänzt getrennte `USP_JsonArray` und `USP_JsonObject` aus caller-lokalen
Temp-Tabellen mit expliziten Typen, strikter Prüfung und atomarer
ResultTable-Ausgabe. Der vollständige finale Adapter besteht auf SQL Server
2019 Linux/latest und 2025 Windows/CU8; weitere Ziele und gemappte CrossDB-
Minimalrechte bleiben offen. Das Modul ist `partially validated`, `unreleased`.

Der getrennte [Script-only Tabellenklon](../../Modules/toolbelt.metadata.table-clone/README.md)
liefert keine automatische Ausführung oder Datenkopie. Der Tabellenklon ist
auf 2019 Linux und 2025 Windows/CU8 im begrenzten synthetischen Scope geprüft;
weitere Zielkombinationen und Lowpriv-CrossDB bleiben offen, Status teilweise
validiert und unveröffentlicht.

Die implementierten W2c-Module
[`toolbelt.core.console-message`](../../Modules/toolbelt.core.console-message/README.md)
und
[`toolbelt.metadata.capability-catalog`](../../Modules/toolbelt.metadata.capability-catalog/README.md)
stellen Unicode-sichere lange Message-Ausgabe sowie eine read-only Sicht auf
Database-level Toolbelt-Modulmarker bereit. Die vollständigen Moduladapter
sind auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base
und Linux latest erfolgreich. Der Capability Catalog ist einschließlich
eingeschränkter Metadatensichtbarkeit `validated`; Console Message bleibt
wegen zusätzlicher Client-/Treiber- und Buffering-Grenzen `partially validated`.

Die implementierten Windows-ZIP-Dateifassaden
[`toolbelt.archive.zip-files`](../../Modules/toolbelt.archive.zip-files/README.md)
verbinden genau zwei öffentliche T-SQL-USPs mit den bestehenden lokalen
ZIP-/Filesystemprovidern. Keine neue Assembly; begrenzte native Windows-Teilnachweise vorhanden,
vollständige Qualifikation offen. Datei-Publish und spätere SQL-Ausgabe sind nicht gemeinsam
atomar.

Das implementierte ZIP-Memory-Modul
[`toolbelt.archive.zip-memory`](../../Modules/toolbelt.archive.zip-memory/README.md)
extrahiert einzelne ZIP-Einträge aus `varbinary(max)` mit Methoden `0`
(Stored) und `8` (Deflate), Payload-CRC32 und harten Limits. Für
TC-2026-033 wurde der ZIP-Metadata-Pfad intern ergänzt. Die automatisierte
Windows-/Linux-Matrix 2019/2022/2025 des Readers ist erfolgreich. Version
1.3.0 ergänzt `USP_CreateZipFromEntries` für begrenzte In-memory-Erzeugung
mit Stored oder explizitem Deflate. Der neue vollständige Adapter ist auf
SQL Server 2019 Linux und 2025 Windows/CU8 erfolgreich, einschließlich echtem
1.2-Upgrade. Reale Archive, höhere SQL-Live-Grenzen und weitere
Interoperabilitätsfälle bleiben offen; keine Datei-I/O-Erweiterung.

Das implementierte Binary-XLSX-Modul
[`toolbelt.file.xlsx-memory`](../../Modules/toolbelt.file.xlsx-memory/README.md)
liefert Worksheetmetadaten und sparse Raw/Text/Formula/Cache-Zellen ohne Datei-I/O,
SDK oder Formelberechnung. Der begrenzte SAFE-XML-Kern verwendet den kanonischen
ZIP-Parser aus Release 1.4.0. Finale lokale/zentralen Adapter auf Linux 2019/latest
und Windows 2025/CU8 sowie begrenzte NoIO-/IL-Gates sind erfolgreich;
Ressourcen-, Rechte- und übrige Plattformmatrix bleiben teilweise offen.
Typinterpretation und Anzeigeformatierung sind getrennte freigegebene Folgescopes,
keine Fähigkeiten dieses Raw-Readers.

Das implementierte Windows-only Modul
[`toolbelt.filesystem.windows`](../../Modules/toolbelt.filesystem.windows/README.md)
stellt kontrollierten `EXTERNAL_ACCESS`-SQL-CLR-Zugriff für begrenztes
Text-/Binary-I/O, Codepages, Transcoding sowie Directory-Operationen bereit.
`Caller` ist der Default, `ServiceAccount` explizit. Der Windows-SQL-Server-/
NTFS-Runtime-Nachweis ist teilweise ausgeführt: Der Lauf
`Ergänzender Windows-CLR-Preflight-Lauf` bestätigte kontrolliertes
ServiceAccount-Verzeichnis- und Textschreiben mit konfiguriertem `WorkPath`.
Windows-Authentication-,
NTFS-ACL- und weitere I/O-Tests bleiben `not executed`; Linux ist nicht
anwendbar.

Das implementierte Windows-only Modul
[`toolbelt.tsql.script-parser`](../../Modules/toolbelt.tsql.script-parser/README.md)
stellt deterministische, rein lesende SQL-CLR Table-Valued Functions auf Basis
von Microsoft ScriptDom (.NET Framework 4.8) bereit, um T-SQL-Statements
syntaktisch in AST-Knoten, Knoteneigenschaften, einen verlustfreien Tokenstrom
und strukturierte Fehlerlisten zu zerlegen. Der Modulstatus ist
für 2.0.1 `partially validated` und `unreleased`: 245 isolierte Framework-
Kindprozesse und 60 Guardfälle bestehen am unveränderten ScriptDom-Pin.
Das SSIS-gekoppelte Upgrade von 2.0.0 und die Table-Clone-Triggerregression
sind zusätzlich nativ geprüft; der Umfang steht in der
[SSIS-Prüfmatrix](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md).
Weitere Parserqualifikation bleibt gesondert. Historische Runtime-Evidenz
gilt für ihre damaligen Versionen und Binarypins; Linux ist nicht anwendbar.

## Begrenzter Paarvergleich 1.0.0

Das neue Modul [`toolbelt.string.text-pairs`](../../Modules/toolbelt.string.text-pairs/README.md)
1.0.0 liefert den einzeln freigegebenen begrenzten Batchwrapper
`USP_CompareTextPairs` über die vorhandenen Levenshtein-, OSA- und
Jaro-Winkler-TVFs. Typgenaue caller-lokale Paare, globale Admission und atomare
ResultTable-Veröffentlichung; keine neue Assembly. Gezielte lokale Linux-/Windows-
und zentrale Windows-Nachweise bestanden; teilweise validiert. Minimalrechte,
weitere Lifecycle-Negativfälle, Ziele und aktuelle PR-Head-CI bleiben offen,
unveröffentlicht. [Vertrag](../../Documentation/Architecture/TEXT_PAIRS_CONTRACT.md).

## XLSX-Typinterpretation 1.1.0

XLSX 1.1.0 ergänzt die einzeln freigegebene `TVF_InterpretXlsxCell` im bestehenden SAFE-Provider. Der finale öffentliche Typadapter bestand am 2026-10-02 auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral: drei Types-Runtime-Fixtures, exakte Zahlen-/100-ns-/NULL-/Clientmetadaten, clean/genuine 1.0/Repeat, Caller-TX OFF/ON intakt und doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung. Raw→Type-Komposition wurde nach den API-CL-Schleifen auf der jeweils letzten CL (2019:150, 2025:170) sowie separat im zentralen Caller geprüft. Keine Konfigurations- oder Rechteänderungen. Die öffentliche Pfadfassung bestand nach ihrem unabhängig geprüften Port auf beiden ausgewählten Targets einschließlich frischer eigener Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Minimalrechte, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. `partially validated`, `unreleased`; historische Raw-1.0-Evidenz bleibt getrennt.


Das neue Modul [toolbelt.string.phonetic](../../Modules/toolbelt.string.phonetic/README.md)
1.0.0 implementiert die einzeln freigegebenen Kölner- und Double-Metaphone-TVFs
über eine eigene begrenzte SAFE-Assembly. Vollständige Codes, kein
Vierzeichen-Clamp und keine optionale Normalisierung. Begrenzte Build-/Framework-/IL- und native Installations-, Fixture-, Client- und Lifecycleteilnachweise liegen vor. Java-Differential, vollständige Zielmatrix, Minimalrechte und aktuelle Head-CI bleiben offen; teilweise validiert und unveröffentlicht.
[Begrenzte Evidenz](../../Modules/toolbelt.string.phonetic/Tests/README.md).

## CSV Memory 1.0.0

[`toolbelt.file.csv-memory`](../../Modules/toolbelt.file.csv-memory/README.md) ergänzt
`USP_ParseCsv` und `USP_WriteCsv` mit eigenem SAFE-CLR-Kern. Rechteckige
Unicode-Zellen, optionale exakte NULL-Tokens und atomarer ResultTable-Vertrag;
kein Datei- oder Netzwerkzugriff. Nur absenkbare Grenzen: 100000 DATA-Records,
1024 Spalten, eine Million Zellen und 16 MiB UTF16-Textbytes.
Framework-/IL-Prüfungen und finale öffentliche Labadapter auf Linux2019/latest
CL150 sowie Windows2025/exaktCU8 CL170 lokal, zentral und mit separatem Consumer
bestanden einschließlich Clientmetadaten, 29 gezielter Lifecyclefälle je Ziel
und unabhängiger eigener Bereinigungsprüfung. Weitere Ziele, Minimalrechte,
Fremdslot-/Driftvollmatrix und Heap-/Produktionskapazität bleiben offen.
Teilweise validiert, unveröffentlicht; exakte Head-CI als separater Mergegate.
[Vertrag](../../Documentation/Architecture/CSV_MEMORY_CONTRACT.md),
[Evidenz](../../Modules/toolbelt.file.csv-memory/Tests/README.md).

## JSON Pointer 1.0.0

[`toolbelt.json.pointer`](../../Modules/toolbelt.json.pointer/README.md)1.0.0
liefert die einzeln freigegebene native MSTVF für RFC6901-Pointer. Die
anschließend ausdrücklich freigegebene [128er-Priorität](../../Documentation/Architecture/JSON_POINTER_NATIVE_DEPTH_BOUNDARY.md)
schützt den nativen Parser und erhält innerhalb der Grenze Syntax vor
caller-seitig abgesenkter Tiefe. Finale Adapter auf Linux2019/latest CL150
und Windows2025/exaktCU8 CL170 bestehen jeweils local/central/Consumer mit
3072 festen APPLY-Oracles,15 direkten Clientreadern und42 Lifecyclefällen.
Frische unabhängige Audits bestätigen Bereinigung, exakte Fixturewiederherstellung
und Inputpins. Beide früheren Gesamtfehlläufe und separate Lifecycle-Scope-
Erfolge bleiben getrennt. Weitere physische Ziele, Minimalrechte,16MiB-
Maximalworkload/Heap und exakte Head-CI sind separat offen. Teilweise validiert,
unveröffentlicht; [Nachweise](../../Modules/toolbelt.json.pointer/Tests/README.md).

## Safe Cast 1.0.0

[`toolbelt.conversion.safe-cast`](../../Modules/toolbelt.conversion.safe-cast/README.md)
enthält die sechs einzeln freigegebenen Inline-TVFs für bigint, decimal(38,18),
date, datetime2(7), bit und uniqueidentifier. Strikte ASCII-/ISO-Lexik,
Value/Status/ErrorCode, höchstens 8192 Inputbytes und keine stille Rundung.
Der genaue Wertebereich wird vor Skalenverlust geprüft. Finale Adapter auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 bestanden local/central/
Consumer: je 13104 API-Oracles, 54 Clientreader und 38 Lifecyclefälle mit
unabhängigem Bereinigungsaudit. Frühere Fehlläufe bleiben separat dokumentiert.
Teilweise validiert, unveröffentlicht; weitere Ziele, Minimalrechte und Heap offen.
[Vertrag](../../Documentation/Architecture/SAFE_CAST_CONTRACT.md),
[Evidenz](../../Modules/toolbelt.conversion.safe-cast/Tests/README.md).

## Frühere SSIS-Modulübersicht

[`toolbelt.tsql.ssis-debug`](../../Modules/toolbelt.tsql.ssis-debug/README.md)
erzeugt JSON-Bindings und einzeln ausführbare CTE-Debugstufen aus DTSX.
Windows-/UNSAFE-Profil; Offline- und native Stufen-/Lookup-/Upgradeprüfungen
bestanden. [Prüfumfang und verbleibende Gates](../../Modules/toolbelt.tsql.ssis-debug/Tests/README.md)
sind dokumentiert; authentifizierte TLS-Abnahme bleibt separat.
