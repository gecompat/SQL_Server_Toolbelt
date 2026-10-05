# PROJECT_CONTEXT.md – Projektzusammenhang

## JSON-Pointer-Welle 2026-10-05

Die Antworten „Diese Pointer-Funktion freigegeben“ und anschließend
„Diese Prioritätsänderung freigegeben“ autorisieren genau die native lesende
MSTVF und ihren festen nonnegative128er-Guard samt geschütztem Scalarwrapper.
Der [Vertrag](../Documentation/Architecture/JSON_POINTER_CONTRACT.md) und
[Tiefenbefund](../Documentation/Architecture/JSON_POINTER_NATIVE_DEPTH_BOUNDARY.md)
halten Besprechung und Zustimmung nachvollziehbar fest.
Finale identische eingefrorene Inputs bestanden Linux2019/latest CL150 und
Windows2025/exaktCU8 CL170 jeweils local/central/Consumer: je3072 feste APPLY-
Oracles,15 direkte Clientreader,42 Lifecyclefälle und Erst-/Repeat-/Uninstall-/
Repeat. Neue Audits bestätigen Bereinigung, exakte Fixturewiederherstellung
und Inputpins; keine Konfigurations-/Rechte-/Truständerungen. Zwei frühere
Safetyfehlläufe und getrennte Lifecycle-only-Erfolge bleiben Historie.
Weitere physische Ziele, Minimalrechte,16MiB-Maximalworkload/Heap und exakte
Head-CI sind separat offen; teilweise validiert, unveröffentlicht.

## Aktive Safe-Cast-Welle 2026-10-05

Die ausdrückliche Antwort „Diese sechs Funktionen freigegeben“ autorisiert
nach Vertragsbesprechung in PR170 genau die sechs Inline-TVFs für bigint,
decimal(38,18), date, datetime2(7), bit und uniqueidentifier. Je Value/Status/
ErrorCode, strikte ASCII-/ISO-Lexik, höchstens8192 Inputbytes und keine stille
Rundung. Exakter Bereich vor LOSSY sowie INVALID_ARGUMENT/PARAMETER wurden
in der anschließenden Frage ausdrücklich eingeschlossen. Der
[kanonische Vertrag](../Documentation/Architecture/SAFE_CAST_CONTRACT.md)
und die datierte Einzelzustimmung in `.ai/BACKLOG.md` begrenzen die Umsetzung.
Implementiert und teilweise validiert, unveröffentlicht. Finale Adapter auf
Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 bestanden local/central/
Consumer: je13104 API-Oracles,54 Clientreader und38 gezielte Lifecyclefälle.
Frische unabhängige Audits bestätigen Inputpins, exakte Fixturewiederherstellung
und die eigene Bereinigung. Drei frühere Gesamtfehlläufe bleiben getrennt.
Weitere physische Ziele, Minimalrechte, Heap und exakte Head-CI sind separate Gates.
Keine Pointer-/Schema-/Provider-/Veröffentlichungsfreigabe daraus abgeleitet.

## Aktive CSV-Memory-Welle 2026-10-05

Die Antwort auf den konkret besprochenen CSV-Scope beauftragt dessen autonome
Umsetzung: genau `USP_ParseCsv` und `USP_WriteCsv`, eigener portabler SAFE-Kern,
optionales NULL-Token und ausschließlich absenkbare 100000-/1024-/1000000-/
16-MiB-Grenzen. Der [CSV-Vertrag](../Documentation/Architecture/CSV_MEMORY_CONTRACT.md)
und die datierte funktionsbezogene Freigabe in `.ai/BACKLOG.md` begrenzen die
Welle. Kein Datei-/Netzwerkzugriff, keine Drittanbieterbibliothek und keine
Veröffentlichung. Version1.0.0 ist `implemented`, `partially validated`,
`unreleased`. Am 2026-10-05 bestanden statische Verträge sowie das exakt
gepackte CLR-Binary unter .NET48 mit drei Kulturen, harten Grenzfällen und
IL-/NoIO-Prüfungen. Der achte öffentliche native Gesamtadapter bestand auf
Linux2019/latest CL150 local/central mit finalem gepacktem Produkt und gleichen
CLR-Bytes: drei SQLfixtures, Clientmetadaten, Clean/Repeat, fünf Slots/drei
Bindings, 29 konkrete Caller-/SET-/Lock-/Rollback-/Confirm0-Prüfungen, frischer
SC-/UTF8-Consumer und Uninstall/Repeat. Exit0, vollständige Kanäle, leeres Stderr
und Cleanup im Lauf bestanden; der frische unabhängige Audit bestand anschließend.
Derselbe finale Adapter und dasselbe Produkt-/Binarypaar bestanden zusätzlich
auf Windows2025/exaktCU8 CL170 local/central mit identischem Fixture-/Client-/
Consumer-/29-Lifecycle-Scope, Exit0, vollständigen Kanälen, leerem Stderr und
Cleanup im Lauf. Der frische Linuxaudit bestätigt drei eigene DBs/einen eigenen
Trusthash abwesend; der frische Windowsaudit bestätigt ebenfalls drei eigene
DBs/einen eigenen Trusthash abwesend. Historische Syntax-/LF-Padding-Fehlläufe
und der fünfte Metadata-Fehllauf bleiben
FAILED. LF-Padding und drei Help-first-NOT-NULL-Spalten wurden korrigiert.
Keine Konfigurations-/Rechteänderungen. Weitere Ziele, Fremdslot-/
Driftvollmatrix, Minimalrechte und Heap bleiben offen. PR169 ist mit fünf grünen
Checks am exakten Head gemergt; Main/origin-main und eigener Branch-Cleanup
bestätigt. JSON Pointer, Safe Cast und JSON Schema sind getrennte Folgegrenzen.

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

## Aktive Managed-Queue-Worker-Welle 2026-10-04

Die konkret freigegebene Weiterentwicklung ergänzt den bestehenden externen
Windows-/Linux-Worker um ein explizites Managed-Opt-in. Der gemeinsame
SQL-Steuerungskern übernimmt dynamische globale und lokale Parallelitätsbudgets,
generationgebundene Intervalle, kontrolliertes Drain und Stop/Hold mit expliziter
Wiederfreigabe. Der [kanonische Vertrag](../Documentation/Architecture/WORKER_CONTROL_CONTRACT.md)
und die Einzelentscheidungen in `.ai/BACKLOG.md` begrenzen diese Welle.
SQL Server Agent, Service Broker und SSIS bleiben spätere Provider.

Sourceimplementierung und Integration sind aktiv. Der gezielte SQL-Vertrag
einschließlich sechs tatsächlicher Lifecycle-Abweisungen bestand auf 2019 Linux
und 2025 Windows/CU8; der echte Queue-Upgrade 2.0→2.1 auf 2019 Linux.
Die gezielten Managedläufe auf beiden ausgewählten SQL-Zielen mit
Windows-Workerhost bestanden einschließlich Cleanup. Linux-Workerhost
und exakte Head-CI sind separate Nachweise am aktuellen PR-Head.
Teilnachweise qualifizieren nicht die gesamte Welle. Kein Releaseauftrag.

## Aktive Tabellenklon-Datenkopie 4.1.0

Die einzeln freigegebene `USP_CopyTableCloneData` wird im bestehenden Modul
umgesetzt: SameDB-Map und leere formgleiche Ziele, KEEP/REGENERATE, vorhandenes
SNAPSHOT oder SERIALIZABLE, eigene Transaktion und nachgelagerte fehlende FKs.
[Kanonischer Vertrag](../Documentation/Architecture/TABLE_CLONE_DATA_COPY_CONTRACT.md):
neun Parameter, fünf NOT-NULL-Summaryfelder,100000 Zeilen/16MiB global und nur
absenkbare Budgets. Gemeinsamer interner FK-Renderer, vier Lifecycle-Slots;
kein zusätzlicher Provider oder öffentlicher Helper. Die fünf Copygruppen,
Client und Clean/genuine4.0→4.1-Lifecycle bestanden auf Linux2019 CL150 und
Windows2025/exakt CU8 CL170; eigene Bereinigung unabhängig geprüft.
Vier dynamische Identity-Zustände und zwei gezielte SNAPSHOT-Konkurrenzfälle
bestanden separat auf Linux2019 CL150; abgeschlossene Teilnachweise aus
insgesamt fehlgeschlagenen Adapterläufen bleiben ausdrücklich getrennt.
Head-CI wird im Pull Request gesondert nachgewiesen.
Bestehende Planner-/Executor-Evidenz bleibt historisch. Unveröffentlicht,
keine vollständige Produktqualifikation.

## Aktive Jaro-Erweiterung 2026-10-03

Die ausdrücklich freigegebene bestehende SAFE-Assembly wird auf 1.1.0 erweitert:
TVF_JaroWinklerSimilarity plus interner FT, sechs Slots, gemeinsamer physischer
UnicodeScalar-Helfer. Der kanonische Jaro-Vertrag beschreibt genau drei Parameter,
float(53)/int und feste Profile. Neue Releasebuilds, Frameworkregression und beide
IL-Metadatengates bestanden separat. Die privaten 1.1-Gesamtadapter bestanden
auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral
sowie mit SC-UTF8-Consumer einschließlich genuine 1.0-Upgrades und frischer
unabhängiger eigener DB-/Trustbereinigung. Frühere 1.0-Evidenz bleibt historisch.
Minimalrechte, weitere Ziele und Heap bleiben offen; CI ist ein separater
PR-Head-Mergegate. Teilweise validiert und unveröffentlicht.

## Projektstatus

`toolbelt.json.constructors` 1.1.0 implementiert die beiden einzeln freigegebenen Gruppen-USPs über den gemeinsamen T-SQL-Kern. Auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 bestanden lokal und zentral die API-/100000-/16-MiB-/Clientprüfungen als Teil insgesamt fehlgeschlagener früherer Läufe. Die finalen fokussierten Läufe mit ausschließlich InstalledMetadata.Contract.sql als Runtime-Auswahl bestanden Metadaten, genuine 1.0-Upgrades, Lifecycle, Central und eigene Bereinigung. Neue Minimalrechte bleiben offen; die Uninstall-Voraussetzung VIEW DEFINITION/SELECT wurde am 2026-10-02 einzeln freigegeben und die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht; historische 1.0-Evidenz bleibt getrennt.

Die additive GeoJitter-Welle 1.2.0 im vorhandenen deterministischen Modul
ist nach Einzelfreigabe vom 2026-10-01 aktiv. Der unabhängig geprüfte
[Vor-Source-Vertrag](../Documentation/Architecture/DETERMINISTIC_GEO_JITTER_CONTRACT.md)
begrenzt sie auf synthetische 2D-Points/SRID 4326. Modellreferenz und sichere
native Operanden qualifiziert. Der finale synthetische Geo-Adapter besteht auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral. Ausgeführt wurden ausdrücklich `GeoJitter.Contract.sql`, `GeoJitter.Safety.sql` und `InstalledMetadata.Contract.sql`, dazu SQL-/Clientmetadaten, echte 1.0.0-/1.1.0-Upgrades, Erstinstallation/Wiederholung, Caller-TX-/SET-Erhalt, Snapshot-Faults, Zukunftsslot-Erhalt, Uninstall und eigene Bereinigung. Der ursprüngliche Geo-Vertrag besteht unverändert in fünf unpartitionierten Batches mit 504 Orakeln. Die sieben bisherigen Source-Dateien bleiben bytegleich; dies ist kein erneuter finaler Runtime-Nachweis aller bisherigen APIs. Keine Konfigurations- oder Rechteänderungen. Neue Minimalrechte, weitere physische Ziele und ein exakt 129-Byte-UDT bleiben offen. Aktuelle CI wird als separater PR-Mergegate am exakten Head nachgewiesen. `partially validated`, `unreleased`. Keine neue Spatial-API oder Privacy-Zusage.

`toolbelt.string.regex` 1.3.0 ergänzt die einzeln freigegebenen Capture-
Wiederholungen und getrenntes Gruppen-Replace. Nach zusätzlicher Freigabe
der erwarteten exakten Binaryhashbindung bestanden die finalen Gesamtadapter
auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral:
API-/SQLClient-Verträge, echter 1.2-Upgrade, Reinstall, Caller-TX/SET-Erhalt,
AppLock, Rollback, Kollisions-/Dependency-Erhalt, Uninstall und eigenes
DB-/Trustcleanup. Neue Capture-Minimalrechte, weitere Ziele, ältere Capture-
Upgrades und tatsächliche große SQL-Ausgabe bleiben offen. Die aktuelle CI
wird separat als PR-Mergegate nachgewiesen;
`partially validated`, `unreleased`. Historische API-only-/Adapterfehlerstände
werden in der Modul-Testdokumentation von den finalen Nachweisen getrennt.

`toolbelt.file.xlsx-memory` 1.0.0 implementiert die einzeln freigegebenen begrenzten Binary-Raw-Reader für Worksheetliste und sparse Zellen. Der eigene SAFE-/Memory-only-XML-Kern verwendet die technische ZIP-Fassade 1.4.0 ohne Parserkopie. Finale synthetische Adapter auf Linux 2019/latest und Windows 2025/CU8 erfolgreich; große Ceiling-/Rechte-/übrige Zielmatrix offen, teilweise validiert und unveröffentlicht. Typ-/Anzeige-Folgewellen gehören nicht zu diesem Raw-Vertrag.

`toolbelt.file.content` ist als portabler Read-only-Dateiprovider implementiert und auf SQL Server 2025 Linux teilweise validiert. `toolbelt.filesystem.windows` ist implementiert, benötigt aber weiterhin den manuellen Windows-SQL-Server-/NTFS-Runtime-Nachweis. `toolbelt.archive.zip-memory` ist als SAFE-SQL-CLR-Provider unter SQL Server 2019/2022/2025 Linux teilweise validiert.

42 Module sind implementiert. 19 sind `validated`, 23 sind `partially validated`; 0 sind `not executed`. Die verbindlichen Einzelstatus werden aus den jeweiligen
`module.yaml`-Manifesten abgeleitet.

`toolbelt.datetime.date-spine` implementiert D1 mit drei öffentlichen Inline
TVFs für Tag, ISO-Woche und Monat. Der halboffene Bereich liefert alle
geschnittenen Perioden mit nullbasiertem Ordinal. Die vollständigen lokalen,
zentralen, Lifecycle-, Dependency-, Kollisions-, Grenz-, `DATEFIRST`- und
Skalierungsadapter sind auf physischen SQL-Server-2019-/2022-/2025-Zielen
unter Windows base und Linux latest erfolgreich. Das Modul ist `validated`
und `unreleased`.

`toolbelt.core.work-queue` Version `2.0.0` implementiert die ausdrücklich
freigegebenen E1a-/E1b-/W6c-Slices mit Enqueue, atomarem Lease-Claim,
Heartbeat, expliziter Recovery, tokengebundenem Complete/Fail, Retry, Dead
Letter, Idempotenz und gruppenbezogenen Drain-Barriers. Die v2-Matrix ist auf
SQL Server 2019/2022/2025 unter Windows und Linux erfolgreich. Das Modul ist
`validated` und `unreleased`. Recovery und Retry begründen keine Exactly-once-
oder generische Idempotenzzusage; Cancellation bleibt ein getrennter Slice.

Die W2c-Module `toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog` sind auf physischen SQL-Server-2019-,
2022- und 2025-Zielen unter Windows base und Linux latest einschließlich
Langtext-/Unicode-, Marker-/Drift-, Wiederholungs-, Lifecycle-, Central- und
Uninstall-Contracts erfolgreich. Der Capability Catalog ist einschließlich
eingeschränkter Metadatensichtbarkeit `validated`; Console Message bleibt
wegen zusätzlicher Client-/Treiber- und Buffering-Grenzen `partially validated`.

`toolbelt.core.console-message` stellt zusätzlich den ADP-008-Piloten für den
Project-Adapter-Vertrag 0.1 von `SQL_Server_Lab` bereit. Der Adapter wird
deterministisch aus den kanonischen Modulquellen erzeugt und war mit SQL Server
2025 Linux getrennt unter Docker und Podman für Install, versionsgleiches
Update, Modul-/Help-Validierung und markergebundenen Cleanup erfolgreich. Der
Toolbelt-Runner verwaltet keine Lab-Infrastruktur. Die Windows-/Linux-Matrix
2019/2022/2025 ist erfolgreich; der Modulstatus bleibt wegen zusätzlicher
Client-/Treiber- und Buffering-Grenzen `partially validated`.

Der Repository-Grundaufbau ist initialisiert und konsolidiert. Das Kernmodul
`toolbelt.core.result-table` ist implementiert und teilweise validiert: Die
Windows-/Linux-Matrix ist auf SQL Server 2019, 2022 und 2025 erfolgreich; eine
vergleichbare plattformübergreifende Performance-Baseline bleibt offen.
Das unabhängige Modul `toolbelt.conversion.base64` ist implementiert; sein
vollständiger Adapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich. Das Modul bleibt
wegen der noch offenen breiteren Large-LOB-Performance-Evidenz `partially validated`.

Das unabhängige Modul `toolbelt.core.generate-series` ist mit portablen
Inline TVFs für `int` und `bigint` implementiert. Sein vollständiger Adapter
ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base
und Linux latest erfolgreich. Das Modul bleibt wegen der noch offenen
Very-large-series-Performance-Evidenz `partially validated`.

Das Modul `toolbelt.metadata.identifier` implementiert einen zustandsbasierten
Parser und einen Quote-Wrapper für ein- bis vierteilige SQL-Namen. Code,
Lifecycle-, Dokumentations- und Testartefakte sind vorhanden. Der
vollständige Adapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich; das Modul ist
`validated`.

Das Modul `toolbelt.string.split-characters` implementiert einen literal
interpretierten Multi-Separator-Vertrag mit stabilen Ordinals, definierter
Leer-Token-Semantik und `nvarchar(max)`-Verarbeitung. Code, Lifecycle-,
Dokumentations- und Testartefakte sind vorhanden. Der vollständige Adapter
ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base
und Linux latest erfolgreich; das Modul ist `validated`. Die breitere Quote-/Escape-Version
ist seit 2026-10-01 als freigegebener S2-Slice `toolbelt.string.split-advanced`
implementiert; risikobasiert 2019 Linux und 2025 Linux/Windows geprüft.
Die ausdrücklich freigegebene Folgeversion 1.1.0 ergänzt `TVF_UnquoteToken`
und `USP_SplitAdvanced`. Der Split-Kern bleibt unverändert; Unquoting ist
weiterhin ein separater, ausdrücklich aufzurufender Verarbeitungsschritt.
Die USP benötigt die kanonische ResultTable-Runtime. Der risikobasierte
Nachweis der Folgeversion und nicht ausgeführte Ziel-/Rechtekontexte werden
in der Modul-Testmatrix ausgewiesen; keine pauschale Statusaufwertung.

`toolbelt.validation.semantic-version` ist mit strengem SemVer-2.0.0-Parser,
Comparator und binärem Sort Key implementiert. Der vollständige Adapter ist
auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und
Linux latest erfolgreich; das Modul ist `validated`.

`toolbelt.conversion.integer-base` codiert und decodiert den vollständigen
`bigint`-Bereich mit frei definierbaren binär eindeutigen ASCII-Alphabeten.
Der vollständige Adapter ist auf physischen SQL-Server-2019-, 2022- und
2025-Zielen unter Windows base und Linux latest erfolgreich; das Modul ist
`validated`.

`toolbelt.datetime.calendar-difference` zerlegt `date`-Intervalle nach einer
dokumentierten Anniversary-Regel. `toolbelt.string.directional-trim` stellt
typstabile `varchar`-/`nvarchar`-TVFs für `LEADING`, `TRAILING` und `BOTH`
bereit. `toolbelt.conversion.uri-component` codiert und decodiert
RFC-3986-URI-Komponenten mit expliziter UTF-8-Sequenzvalidierung. Die drei
Module sind mit ihren vollständigen Adaptern auf physischen SQL-Server-2019-,
2022- und 2025-Zielen unter Windows base und Linux latest einschließlich
Wiederholungsdeployment, zentraler Nutzung, Kollisionsschutz und Uninstall
erfolgreich. Die zusätzlichen Collation- sowie ASCII-/Unicode-/Large-Input-
Pflichtfälle sind ebenfalls erfolgreich; die Module sind `validated`.

W2a ist mit drei weiteren portablen Inline-TVF-Modulen implementiert:
`toolbelt.datetime.truncate` bietet typgetrennte Truncation für `date`,
`datetime2(7)` und `datetimeoffset(7)`, `toolbelt.datetime.bucket` ergänzt
Origin-basierte Buckets derselben Typfamilie und
`toolbelt.binary.bit-operations` portiert die fünf SQL-Server-2022-
Bitoperationen für `bigint`. Die vollständigen Adapter sind auf physischen
SQL-Server-2019-, 2022- und 2025-Zielen unter Windows base und Linux latest
einschließlich Wiederholungsdeployment, Lifecycle, zentraler Nutzung,
Kollisionsschutz, nativer Parität und Uninstall erfolgreich. Der Bucket-
Optimizer-Workload umfasst zusätzlich 100.000 synthetische Zeilen; die drei
Module sind `validated`.

W2b-A ist als `toolbelt.json.path-exists` implementiert. Die
Multi-statement TVF prüft Root-, Property-, Array-Index- und
Array-Wildcard-Pfade, propagiert SQL `NULL` und liefert für ungültiges JSON
oder ungültige Pfade fehlerfrei `0`. Der getrennte Konstruktor-Slice aus
`TC-2026-009` ist inzwischen implementiert; JSON-Aggregate aus `TC-2026-013`
bleiben zurückgestellt. Der vollständige
Adapter ist auf physischen SQL-Server-2019-, 2022- und 2025-Zielen unter
Windows base und Linux latest einschließlich nativer Parität,
Wiederholungsdeployment, Kollisionsschutz, Lifecycle, Central und Uninstall
erfolgreich; das Modul ist `validated`.

W2c ist als `toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog` implementiert. Die Console-USP
verwendet Unicode-sichere `PRINT`- beziehungsweise
`RAISERROR ... WITH NOWAIT`-Chunks. Die Capability-View liest ausschließlich
Database-level Extended Properties und weist Marker als `valid`,
`incomplete` oder `invalid` aus. Die vollständige Windows-/Linux-Matrix
2019/2022/2025 ist einschließlich Langtext-/Unicode-, Marker-/Drift-,
Wiederholungs-, Lifecycle-, Central- und Uninstall-Contracts erfolgreich.
Die eingeschränkte Metadatensichtbarkeit wurde ohne Rechteausweitung geprüft;
der Capability Catalog ist `validated`. Console Message bleibt wegen der
zusätzlichen Client-/Treibergrenzen `partially validated`.

`toolbelt.archive.zip-memory` ist als V1A-In-memory-Slice implementiert und
stellt `toolbelt_archive.USP_ExtractZipEntryFromBinary` bereit. Version
`1.0.0` extrahiert einen einzelnen Entry aus einem ZIP-Container im Speicher,
erzwingt Default-Limits fuer Entry-Groesse und Kompressionsverhaeltnis,
behandelt Duplicate-Namen als expliziten Fehler und liefert bei
`@FailIfEncrypted = 0` einen verschluesselten Status ohne Payload. Version
`1.2.0` ergänzt das Metadaten-Listing. Extraktion und Listing sind im
[GitHub-Actions-Lauf 32701896453](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453)
auf SQL Server 2019, 2022 und 2025 unter Linux erfolgreich; die automatisierte
Windows-/Linux-Matrix 2019/2022/2025 war am 2026-09-01 ebenfalls erfolgreich.
Version `1.3.0` ergänzt den ausdrücklich freigegebenen begrenzten
In-memory-Writer `USP_CreateZipFromEntries` mit Stored/Deflate und SAFE-CLR.
Der vollständige neue Adapter besteht auf SQL Server 2019 Linux CL150 und
2025 Windows/CU8 CL150/160/170 einschließlich echtem 1.2-Upgrade und
16-MiB-Payloads. Frameworktests qualifizieren zusätzlich tatsächliche
32-MiB-Entry-/128-MiB-Gesamtfixtures. Reale Archive, höhere SQL-Live-Grenzen,
weitere Interoperabilität und Produktionskapazität bleiben offen;
`partially validated`, `unreleased`, ohne Datei-I/O.

`toolbelt.string.regex` 1.2.0 ergänzt die einzeln freigegebenen
`TVF_RegexMatches` und `TVF_RegexSplit` ohne Captures oder Entquotierung.
Beide verwenden den bestehenden SAFE-CLR-Kern mit begrenzter vollständiger
Materialisierung vor Ausgabe. Der neue Adapter besteht auf SQL Server 2019
Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170. Weitere R2b-Ziele,
Lowpriv-CrossDB und SQL-100k-Durchsatz bleiben offen; `partially validated`,
`unreleased`. Historische R1b-/R2a-Nachweise bleiben getrennt erhalten.

`toolbelt.json.constructors` 1.0.0 implementiert die einzeln freigegebenen
`USP_JsonArray` und `USP_JsonObject` aus caller-lokalen #Temp-Tabellen mit
expliziten ValueKinds, einem kanonischen Prüf-/Escapingkern und atomarer
ResultTable-Ausgabe. Der vollständige Adapter besteht auf SQL Server 2019
Linux/latest und 2025 Windows/CU8 einschließlich Literal-/Unicode-/Limit-,
CS-/CI-Namespace-, Clientmetadaten-, Transaktions- und Lifecycleverträgen.
Weitere Ziele, gemappte CrossDB-Minimalrechte und Produktionskapazität bleiben
offen; `partially validated`, `unreleased`.

`toolbelt.pseudonymization.deterministic` 1.0.0 implementiert die einzeln
freigegebenen Range-/DateShift-/Lookup-Verträge ohne CLR oder I/O mit einem
kanonischen SHA256-/Framing-/128-Rejection-Kern. Identische finale Adapter
auf 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 sind am
2026-10-02 erfolgreich, einschließlich Compilergrenzen-/Callertransaction-
Safetyfixes. Weitere Targets, CrossDB-Minimalrechte und Produktionskapazität
bleiben offen; `partially validated`, `unreleased`, keine Anonymisierungszusage.

Die additive Version 1.1.0 ergänzt die einzeln freigegebene echte Inline-TVF
`TVF_DeterministicTranslate`: ASCII-Buchstaben/Ziffern, casegekoppelte Bijektion,
explizite Separatoren und begrenzte Standard-/Large-Profile. Der vollständige
Adapter besteht auf Linux 2019/latest CL150 local/central und Windows 2025/CU8
CL150/160/170 central, einschließlich aller sieben API-/Kernslots, Metadaten,
echtem 1.0-Upgrade, Kollisions-/Lifecyclefällen und eigenem Cleanup. Windows
local: API-/Safetyfälle im früheren insgesamt fehlgeschlagenen Lauf bestanden;
separate korrigierte Metadaten-/Lifecycleprüfung erfolgreich. Neue direkte/
CrossDB-Minimalrechte, weitere physische Targets, Produktionskapazität und
aktuelle CI bleiben offen; teilweise validiert und unveröffentlicht.

## Projektzweck

SQL Server Toolbelt ist eine modulare Erweiterungsbibliothek für Microsoft SQL Server Database Engine ab Version 2019. Sie stellt Funktionen bereit, die SQL Server nicht nativ besitzt, erst in späteren Versionen anbietet oder nur mit wiederkehrendem, fehleranfälligem Boilerplate ermöglicht.

## Nutzen

- wiederverwendbare, getestete und dokumentierte SQL-Server-Objekte;
- Reduzierung wiederkehrender Implementierungslogik;
- stabile öffentliche Verträge und versionsbezogene Compatibility-Informationen;
- lokale oder zentrale Installation, soweit die Capability dies erlaubt.

## Scope

- SQL Server 2019, 2022 und 2025; spätere Versionen werden nach Erscheinen ausdrücklich bewertet;
- Windows und Linux, jeweils pro Modul und Provider ausgewiesen;
- T-SQL bevorzugt;
- SQL CLR, C#, Python, Java oder R nur mit technischer Begründung;
- lokale und zentrale Deployment-Modi;
- Cross-database-Verwendung als Designziel, nicht als pauschale Garantie.

## Non-Goals

- Performance-, Konfigurations-, Diagnose- und Security-Analysen; diese gehören in `gecompat/SQL_Server_Analyze`;
- automatische Unterstützung von Azure SQL Database oder Azure SQL Managed Instance;
- Demo-Anwendungen, Produktionsdaten, Produktionsbackups oder reale Runtime-Ausgaben;
- ungeprüfte Drittanbieterabhängigkeiten.

## Repository-Grenzen

- Dieses Repository ändert kein anderes Repository ohne ausdrücklichen Auftrag.
- Analyseideen dürfen in `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` erfasst werden.
- Vor einem Analyze-Kandidaten wird das Ziel-Repository nach Möglichkeit lesend auf vorhandene oder gleichwertige Funktionalität geprüft.

## Plattformmatrix

| Plattform | Grundstatus |
|---|---|
| SQL Server 2019 Windows | Zielplattform |
| SQL Server 2022 Windows | Zielplattform |
| SQL Server 2025 Windows | Zielplattform |
| SQL Server 2019 Linux | Zielplattform, modulabhängig |
| SQL Server 2022 Linux | Zielplattform, modulabhängig |
| SQL Server 2025 Linux | Zielplattform, modulabhängig |
| Azure SQL Database | kein automatischer Support |
| Azure SQL Managed Instance | kein automatischer Support |
| SQL Server vor 2019 | nicht unterstützt |

## Statusbegriffe

Arbeitspakete und Kandidaten verwenden einen Workflow-Status wie `proposed`,
`researched`, `active`, `blocked`, `completed`, `rejected` oder `curiosity`.

Module trennen dagegen verbindlich:

- `implementation_status`: Stand der Implementierung;
- `validation_status`: tatsächlich belegter Testscope;
- `release_status`: Veröffentlichungsstand.

Die zulässigen Modulwerte und ihre Bedeutung stehen im
[Modul- und Abhängigkeitsmodell](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md).
Plan, Dokumentation, Manifest und vorhandener Testcode sind kein
Runtime-Nachweis.

`toolbelt.string.edit-distance` 1.0.0 ergänzt die genau zwei freigegebenen Distanz-TVFs mit eigenem portablem SAFE-CLR-Provider. Der Vor-Source-Vertrag und die zusätzliche Providerfreigabe sind dokumentiert. Offline Framework-/Matrixprüfungen und Releasebuild bestanden. Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht.


## XLSX-Typinterpretation – gezielte Qualifikation 2026-10-02

XLSX 1.1.0 ergänzt die einzeln freigegebene `TVF_InterpretXlsxCell` im bestehenden SAFE-Provider. Der finale öffentliche Typadapter bestand am 2026-10-02 auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral: drei Types-Runtime-Fixtures, exakte Zahlen-/100-ns-/NULL-/Clientmetadaten, clean/genuine 1.0/Repeat, Caller-TX OFF/ON intakt und doomed, AppLock, postDROP/preCOMMIT-Rollback, historische Zukunftsslots, Sichtbarkeitsprädikate, Uninstall und eigene Bereinigung. Raw→Type-Komposition wurde nach den API-CL-Schleifen auf der jeweils letzten CL (2019:150, 2025:170) sowie separat im zentralen Caller geprüft. Keine Konfigurations- oder Rechteänderungen. Die öffentliche Pfadfassung bestand nach ihrem unabhängig geprüften Port auf beiden ausgewählten Targets einschließlich frischer eigener Bereinigungsprüfungen. Aktuelle CI wird separat am exakten PR-Head als Mergegate geprüft. Tatsächliche Minimalrechte, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. `partially validated`, `unreleased`; historische Raw-1.0-Evidenz bleibt getrennt.


## Paarvergleich – gezielte Nachweise 2026-10-03/04

`toolbelt.string.text-pairs` 1.0.0 bleibt teilweise validiert und
unveröffentlicht. Der private begrenzte Wrapperadapter bestand fünf Fixtures
und Lifecycle-Wiederholungen am2026-10-03 auf SQL Server2019 Linux/latest
CL150 local sowie am2026-10-04 auf SQL Server2025 Windows/CU8 CL170 local,
jeweils SC-UTF8. Separat central bestanden InstalledMetadata, drei direkte
Algorithmen mit exakt fünf typgenauen Feldern und EOF/noNext, drei
ResultTable-Aufrufe ohne Resultset, Confirm0-Ablehnung55128/1 mit vollständig
unverändertem Katalogsnapshot und gesunder Session sowie Confirm1-
Uninstall/repeat. Frische Bereinigungsprüfungen bestätigten eigenen
Ressourcenabbau; zentral zwei Datenbanken und ein wiederhergestellter
Trusteintrag. Keine Konfigurations-, SQL-Rechte- oder Owneränderungen.
Der frühere NULL-Secondarycount-Adapterfehler bleibt ein bereinigter Fehllauf,
kein Gesamt-PASS aus seinen Teilabschnitten. Minimalrechte, fremde CLR-PC,
weitere Lifecycle-Negativfälle und Ziele sowie exakte aktuelle Head-CI bleiben
separate offene Gates; keine vollständige Produktqualifikation.

## XLSX-Anzeigeformatierung 1.2.0

Stand 2026-10-03, Codex: die einzeln freigegebene Anzeige-TVF ist im bestehenden SAFE-Provider additiv implementiert. Acht Inputs, zwei Outputs, zehn Literalformate, en-US/de-DE/tr-TR, exakte SqlDecimal-Rundung half-away-from-zero, Datetimecarry/time24h-Status8 und unveränderte Typquote wurden konkret genehmigt. Raw-/Typquellen unverändert. Begrenzte aktuelle Offline- und lokale Nativequalifikation vom 2026-10-04 bestanden; zentrale1.2-Nutzung, vollständige Matrix, Minimalrechte und aktuelle Head-CI bleiben offen. Am 2026-10-04 bestand ein privater Qualifikationsadapter auf SQL Server 2019 Linux/latest CL150 und SQL Server 2025 Windows/exakt CU8 CL170 jeweils ausschließlich lokal: Clean1.2 und genuine installierte1.1→1.2 mit frischer Session, drei→vier CLR-Bindings und sieben→neun Slots am identischen aktuellen Binary. Je Ziel bestanden zwölf SQL-Fixtures, sechs Display-Clientprüfungen und zwei Raw→Type-/Raw→Type→Display-Kompositionen, Repeat sowie Uninstall/Repeat. Zwei eigene Datenbanken wurden entfernt und drei exakte Trust-Vorzustände wiederhergestellt; frische unabhängige Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte- oder Owneränderungen. Dies ist ein begrenzter privater Adapternachweis, kein vollständiger öffentlicher Labadapter- oder Produkt-PASS. Zentrale1.2-Nutzung, genuine1.0→1.2, weitere CL/Ziele, vollständige Lifecycle-/Kollisionsmatrix, Minimalrechte, Heap und aktuelle exakte Head-CI bleiben offen. Status bleibt `partially validated`, `unreleased`. `partially validated`, `unreleased`; keine neue Rechte-/Providergrenze. Historische 1.0-/1.1-Nachweise bleiben getrennt. [Vertrag](../Documentation/Architecture/XLSX_CELL_DISPLAY_CONTRACT.md).

Ergänzung 2026-10-05: `DisplayCentral10Upgrade` bestand zentral auf
Linux2019/latest CL150 mit genuine1.0→1.2, frischer Upgrade-Session,
neun Slots/vier CLR-Bindings, Repeat, installierten Anzeige-Fixtures und
Clientmetadaten/Raw→Type→Display aus frischer Consumerdatenbank.
Confirm0/Uninstall, äußerer eigener Prozesswatchdog und unabhängiger frischer
OwnDB-/OwnTrustaudit bestanden, ohne Konfigurations-/Rechteänderungen.
Diese zentralen Lücken sind für das Ziel geschlossen; vollständige
Lifecycle-/Kollisionsmatrix, weitere Ziele, Minimalrechte und Heap bleiben
offen. Status weiterhin `partially validated`, `unreleased`.

Zusätzlich bestand am2026-10-05 `DisplayCentralLifecycle` auf demselben Ziel:
vier postDROP-/preCOMMIT-Rollbackfälle und zwei AppLock-Abweisungen mit
unverändertem vorhandenen vollständigen Lifecycle-Snapshot, neun Slots/vier
Bindings, exaktem SAFE-Binaryhash und neutraler Session zwischen Statements.
Bestätigter Uninstall, äußerer eigener Prozesswatchdog und frischer unabhängiger
OwnDB-/OwnTrustaudit bestanden ohne Konfigurations-/Rechteänderungen. Ein früherer
gemischter Setup-Prüflauf bleibt FAILED_CLEANED. Weitere Kollisions-/Lifecyclefälle,
Ziele, Minimalrechte und Heap bleiben getrennte offene Gates.

Vier Fremdslot-Fixtures bestanden zusätzlich am2026-10-05 mit
`DisplayCentralFutureCollisions4` auf genuine1.1 zentral Linux2019/latest CL150:
aktueller1.2-Deploy weist ab, aktueller release-aware Uninstall bewahrt den
exakten Fremdslot. Fünf Vorgängerinstallationen einschließlich Setup/Restores,
native Zeugen, finaler aktueller Uninstall, eigener äußerer Prozesswatchdog und
frischer unabhängiger OwnDB-/OwnTrustaudit bestanden ohne Konfigurations-/
Rechteänderungen. Originale Vorgänger-Uninstalls und weitere Kontexte bleiben
offen; keine erneute API-/Consumer-/Upgrade- oder Lifecycle-six-Prüfung.

## Tabellenklon Trigger-Vorschau / 4.0.0 – begrenzte Native-Nachweise

Die einzeln freigegebene Windows-Option `IncludeTriggers=1` ergänzt den
vorhandenen Planner mit13 Parametern; dessen Standardtail steht10..13.
Der vorhandene Parser2.0 wird nur beim Opt-in benötigt und weder installiert
noch automatisch vertraut. Kommentare/Literale bleiben erhalten, belegte
AST-Identifier werden auf Mapziele umgeschrieben; Zustandszeilen erhalten
FIRST/LAST und Disabled. Der14-Parameter-Executor bleibt triggerfrei und
bindet im Hash-v1 das Modulrelease4.0. Unabhängige Coreprüfung, Statik und
offline Syntaxprüfung bestanden. Am2026-10-04 bestanden auf Windows2025/exakt
CU8 CL170 lokal beide Trigger-Fixtures, Clean4/genuine3.1→4 mit frischer
Session, Repeat, Clienthash/typgenaue Ausgabe, resolved Consumer und
Uninstall/Repeat. Eigene DBs und temporärer Parsertrust bereinigt; unabhängige
physische Journal-/Prozessprüfung bestanden. Linux2019/latest CL150 Option0
und Lifecycle aus dem separaten erfolgreichen4.0-Lauf wiederverwendet;
nachfolgende Coreänderungen ausschließlich Option1, unabhängig geprüft.
Head-CI, zentrale4.0-Nutzung, weitere native Ziele, Minimalrechte und
unsichtbare/mehrdeutige Kontexte bleiben getrennte offene Nachweise.
Keine Datenkopie oder vollständige Runtimequalifikation aus historischen Läufen.

## Tabellenklon Executor / 3.1.0 – historische begrenzte Nachweise

Der einzeln freigegebene `USP_ExecuteTableClone` führt ausschließlich einen
frisch erzeugten, exakt hashgebundenen V3-Plan für neue SameDB-Ziele aus.
CREATE/DEFER, eigene Transaktion, vorhandene DB-/Servervollsicht und
DDL-Seiteneffektgate sind gekoppelt; keine Daten-/Triggerkopie oder Rechtevergabe.
Am 2026-10-04 bestanden die gezielten lokalen Nachweise auf SQL Server
2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170: beide neuen
Fixtures, Client-Hash/Metadata, genuine3→3.1, Lifecycle und eigene Bereinigung.
Weitere native Ziele, zentrale Executor-Nutzung, tatsächliche Minimalrechte
und serverweite Negativfixtures bleiben offen; Head-CI ist ein separater PR-Nachweis.
Modul bleibt teilweise validiert und unveröffentlicht.

## Tabellenklon W2 / 3.0.0 – begrenzte Nachweise

Am 2026-10-04 bestanden begrenzte private Adapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/exakt CU8 CL170 ausschließlich lokal: Clean3 und genuine2→3 mit frischer Session, Repeat, resolved Consumer mit Deploy-/Uninstall-Ablehnung53926/1 und unverändertem Katalogsnapshot/gesunder Transaktion sowie Uninstall/Repeat. Je Lauf wurden zwei eigene Datenbanken entfernt; frische Bereinigungsprüfungen bestanden. Keine Konfigurations-, Rechte-, Owner- oder Truständerungen. Linux: drei W2-Fixtures und eine W1-Regressionsfixture stammen als Teilnachweis aus einem historischen insgesamt fehlgeschlagenen Lauf; der identische Produkt- und Fixturestand wurde wiederverwendet und im finalen Lifecycle-PASS nicht erneut ausgeführt. Windows: dieselben vier Fixtures bestanden einmal in Clean3 im aktuellen erfolgreichen Lauf, nicht erneut im Upgradezyklus. Unresolved Consumer: NOT_ESTABLISHED. Keine vollständige Produktqualifikation; weitere Ziele/CL, zentrale V3-Nutzung, Minimalrechte, übrige Lifecycle-Negativfälle und aktuelle Head-CI bleiben offen. Status bleibt teilweise validiert und unveröffentlicht.


## Phonetik 1.0.0 – begrenzte Teilnachweise

toolbelt.string.phonetic implementiert ausschließlich die einzeln freigegebenen
Kölner- und Double-Metaphone-TVFs über eine eigene SAFE-Assembly. Der vollständige
Scanner ist begrenzt, ohne Vierzeichen-Clamp oder zusätzliche Normalisierung.
Apache-Header/LICENSE/NOTICE und der markierte Port bleiben erhalten.
Begrenzte Build-/Framework-/IL- und native Installations-, Fixture-, Client- und Lifecycleteilnachweise liegen vor. Java-Differential, vollständige Zielmatrix, Minimalrechte und aktuelle Head-CI bleiben offen; teilweise validiert und unveröffentlicht. Der Vertrag liegt in
Documentation/Architecture/PHONETIC_CONTRACT.md.
