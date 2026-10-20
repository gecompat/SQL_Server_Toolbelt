# CSV-Prüfungen und Evidenz

Stand 2026-10-20: Version1.0.0 ist implementiert, `partially validated` und
unveröffentlicht. CI und native Labnachweise besitzen getrennte Bindungen;
andere SAFE-Assemblies qualifizieren diese CSV-Bytes nicht.

## Zusätzliche Compatibility Levels 2026-10-20

Nach Abschluss der Standard-CL-Ergänzung in
[PR339](https://github.com/gecompat/SQL_Server_Toolbelt/pull/339) bestanden
sechs weitere native Gesamtadapterläufe, jeweils im ersten Versuch:

| Plattformen | SQL Server / Lab-Auswahl | Zusätzlich geprüfte CL | Modi |
|---|---|---|---|
| Windows, Linux | 2022 / Windows base mit erlaubtem bereitem CU-Äquivalent, Linux latest | 150 | local, central |
| Windows, Linux | 2025 / Windows base mit erlaubtem bereitem CU-Äquivalent, Linux latest | 150, 160 | local, central |

Der unveränderte öffentliche Labadapter setzte die eigene Testdatenbank pro
Modus auf den ausgewählten CL. Je Lauf bestanden die drei SQLfixtures,
Clientmetadaten, Clean/Repeat, fünf Slots/drei Bindings, dieselben 29 gezielten
Caller-/SET-/Lock-/Rollback-/Confirm0-Fälle, frischer SC-/UTF8-Consumer und
Uninstall/Repeat. Je äußerer Watchdog, Exit0, vollständige Kanäle und leeres
Stderr sowie frischer unabhängiger Audit mit drei eigenen DBs/einem eigenen
Trusthash abwesend und unveränderten Inputpins bestanden.

Auf den beiden ausgewählten SQL2022-Zielen war eine autorisierte temporäre
CLR-Aktivierung nötig. Vorzustand und vorgemerkter Scope wurden privat erfasst;
nach jedem betroffenen Verbraucher wurde der vollständige Ausgangszustand
unter Driftprüfung restauriert. Die vier SQL2025-Läufe benötigten keine
Konfigurationsänderung. Keine Rechte-, Owner- oder Infrastrukturänderungen;
`clr strict security` blieb aktiv.

Paket und ursprüngliche Build-/Frameworknachweise aus der ersten Welle vom
2026-10-20 wurden nach erneuter Source-/Binary-/Runner-/Harness-/Helper-/Compiler-/
Frameworkreferenzbindung wiederverwendet; kein neuer lokaler Build oder
Frameworklauf. Die Standard-CL-Nachweise wurden ebenfalls nach aktueller
Inputprüfung weiterverwendet und nicht erneut ausgeführt.

Damit ist der begrenzte Gesamtadapter am aktuellen Quellen-/Abhängigkeitsstand
auf allen zwölf zulässigen Kombinationen bestanden: Windows und Linux jeweils
SQL2019/CL150, SQL2022/CL150/160 und SQL2025/CL150/160/170, lokal und zentral.
Die je 29 gezielten Lifecyclefälle bleiben derselbe Teilumfang; Minimalrechte,
Fremdslot-/Driftvollmatrix, weitere Collations, Heap, authentifiziertes TLS und
Release bleiben offen. `partially validated`, `unreleased` bleiben unverändert;
aktuelle Head-/Main-CI ist ein eigener Integrationsgate.

## Standard-CL-Bindung 2026-10-20

Nach [PR338](https://github.com/gecompat/SQL_Server_Toolbelt/pull/338) bestanden
zwei zusätzliche native Läufe mit den aktuellen ResultTable-Abhängigkeiten:
Linux2019/latest CL150 und Windows2025/base CL170 mit erlaubtem bereitem
CU-Äquivalent, jeweils local/central im ersten nativen Versuch. Beide Läufe
verwenden das unveränderte Paket aus der vorherigen Vierzielwelle. Dessen
Source-/Binarybindungen sowie Frameworkrunner, Harness, Prozesshelfer,
Compiler und .NET48-Referenzen wurden vor Wiederverwendung geprüft;
Build und Framework wurden hier nicht erneut ausgeführt.

Je Ziel bestanden drei SQLfixtures, Clientmetadaten, Clean/Repeat, fünf
Slots/drei Bindings, dieselben 29 gezielten Lifecyclefälle, frischer
SC-/UTF8-Consumer und Uninstall/Repeat. Äußerer Watchdog, Exit0, vollständige
Kanäle und leeres Stderr bestanden; je frische unabhängige Verbindung bestätigt
drei eigene DBs/einen eigenen Trusthash abwesend und unveränderte Inputpins.
Keine Konfigurations-, Rechte-, Owner- oder Infrastrukturänderungen.

Zusammen mit den vier Läufen aus PR338 ist damit der begrenzte Gesamtadapter
auf allen sechs physischen Windows-/Linux-/SQL2019/2022/2025-Kombinationen
mit deren Standard-CL150/160/170 am aktuellen Quellen-/Abhängigkeitsstand
bestanden. Die früheren Läufe vom 2026-10-05 bleiben historische Evidenz.
Die zusätzlichen CL-Nachweise stehen in der getrennten Folgewelle oben.
Minimalrechte, Fremdslot-/Driftvollmatrix, weitere Collations, Heap und Release
bleiben offen. Functional-Transport qualifiziert kein
authentifiziertes TLS; aktuelle Head-/Main-CI bleibt ein separater Gate.

## Vorherige ergänzende native Zielwelle 2026-10-20

Der unveränderte öffentliche Adapter `Tests/CI/run-csv-memory-lab.ps1` bestand
auf vier zusätzlich ausgewählten physischen Labzielen, jeweils im ersten
nativen Versuch:

| Lab-Auswahl | Compatibility Level | Modi | Ergebnis |
|---|---|---|---|
| Windows / SQL2019 / base mit erlaubtem bereitem CU-Äquivalent | 150 | local, central | bestanden |
| Windows / SQL2022 / base mit erlaubtem bereitem CU-Äquivalent | 160 | local, central | bestanden |
| Linux / SQL2022 / latest | 160 | local, central | bestanden |
| Linux / SQL2025 / latest | 170 | local, central | bestanden |

Vertrag und Schema wurden vor Auswahl validiert, die tatsächliche Plattform
und SQL-Hauptversion vor jedem Lauf geprüft. Windows-base verwendet die
projektspezifisch erlaubte deterministische Auswahl bereiter base-/CU-Ziele.
Alle vier Läufe konsumierten dasselbe neue Releasepaket: zwei vollständige
.NET48-Builds am selben lokalen Buildort lieferten identische SHA2-512-Bytes.
`Scripts/New-ClrReleaseArtifacts.ps1` band das erste Binary an aktuelle Quellen;
`Tests/Framework/run-framework-csv.ps1` bestand mit diesen gepackten Bytes in
en-US, de-DE und tr-TR einschließlich IL-/NoIO-Orakeln und harter Grenzphase
in en-US. Statische Verträge und Adapter-AST bestanden ebenfalls.

Je Ziel bestanden beide Modi mit `Contract.Tests.sql`, `Safety.Tests.sql`,
`Lifecycle.Tests.sql`, Clientmetadaten, Clean/Repeat, fünf Slots/drei CLR-Bindings,
29 gezielten Caller-/SET-/Lock-/Rollback-/Confirm0-Fällen, frischem
SC-/UTF8-Consumer und Uninstall/Repeat. Die 29 Fälle zählen je Lauf dieselben
gezielten Prüfungen und keine vollständige Fremdslot-/Driftmatrix.
Der äußere Watchdog begrenzte jeden tatsächlich gestarteten eigenen Prozess;
Exit0, vollständig konsumierte Ausgabekanäle und leeres Stderr bestanden.
Nach Prozessende bestätigte je eine frische unabhängige Verbindung drei eigene
Datenbanken und einen eigenen Trusthash abwesend sowie unveränderte Inputpins.

Die notwendige temporäre CLR-Testkonfiguration auf drei ausgewählten Zielen
erfolgte unter der bestehenden Benutzerfreigabe. Vorzustand und zuvor
vorgemerkter Konfigurationsscope blieben ausschließlich im privaten Journal;
nach Abschluss aller eigenen Verbraucher wurde der vollständige Ausgangszustand
unter Driftprüfung wiederhergestellt. `clr strict security` blieb aktiv;
keine Rechte-, Owner- oder Lab-Infrastrukturänderungen.
Der vierte Lauf benötigte keine Konfigurationsänderung.
Die äußeren Vorprüfungen auf Windows2019 und Windows2022 hatten zuvor wegen
der fehlenden CLR-Voraussetzung gestoppt, jeweils vor Aufruf des nativen
Adapters und ohne Testressourcen anzulegen.

Diese Welle ändert keine Produkt-, Deployment-, CLR-, Adapter- oder
Testorakelquellen. In dieser Vierzielwelle wurden die historischen Läufe auf
Linux2019/CL150 und Windows2025/CL170 nicht neu ausgeführt; ihr damaliger
ResultTable-Stand wird erst durch die getrennte Standard-CL-Ergänzung oben
aktuell qualifiziert. Zusätzliche CLs,
Minimalrechte, Fremdslot-/Driftvollmatrix, weitere Collations, Heap und Release
bleiben offen. Transport war `Functional`; authentifiziertes TLS ist
`not executed`. Aktuelle Head-/Main-CI ist ein gesonderter Integrationsgate.

## Historische Nachweise

Testwartung 2026-10-09 – Quellenstand: Der Frameworkrunner kopiert die gepinnte
DLL mit festem 64-KiB-Puffer, `Int64`-Längenbindung und exakter EOF-Prüfung statt
eines vollständigen DLL-Bytearrays. Bestehende Kopie-/Endpins, Harnessorakel,
Kulturen und Prozessbudgets bleiben erhalten. Fokussierte Prüfung des neuen Kopierblocks: sechs synthetische Fälle **PASS**
(0, 1, 65536 und 65537 Bytes, vorhandenes Ziel abgewiesen und erhalten,
falscher Hash abgewiesen). Exakte neue Head-CI **NOT_EXECUTED**; kein neuer
Framework-, SQL-, Heap- oder Cleanup-PASS. Die folgenden historischen Abnahmen behalten
unverändert ihren damaligen Scope; Modulstatus und Produkt/API unverändert.

Die statischen Verträge bestanden. `Tests/Framework/run-framework-csv.ps1`
qualifizierte das exakt gepackte aktuelle .NET48-Binary in en-US, de-DE und
tr-TR mit unabhängigen Orakeln sowie IL-/NoIO-Prüfungen; die harte Grenzphase
lief in en-US. Das ist ein CLR-Nachweis ohne SQL-/Client-/Lifecycle- oder
Heapqualifikation.
Der CSV-Qualifikationsworkflow baut das Produkt auf demselben Runner zweimal
vollständig neu und vergleicht die SHA2-512-Trustbytes des zweiten Builds
mit dem unveränderten ersten Releasepaket. Das belegt bei Erfolg nur
Build-Reproduzierbarkeit innerhalb dieses Runnerlaufs, nicht zwischen Hosts
oder eine native SQL-Qualifikation.

Der achte öffentliche Lauf von `Tests/CI/run-csv-memory-lab.ps1` bestand am
2026-10-05 auf SQL Server 2019 Linux/latest CL150 lokal und zentral mit dem
finalen gepackten Produktstand und identischen CLR-Bytes. Alle drei SQLfixtures,
Clientmetadaten, Clean/Repeat, fünf Slots/drei CLR-Bindings, Caller-/SET-/AppLock-/
Rollbackfälle, zentraler Confirm0-Schutz, Uninstall/Repeat und Nutzung aus frischer
SC-/UTF8-Consumerdatenbank bestanden. Der Lifecycle-Zähler29 bezeichnet die
konkreten Caller-/Lock-/Rollback-/Confirm0-Prüfungen, keine vollständige Fremdslot-
oder Driftmatrix. Der Prozess endete mit Exit0, vollständiger Kanalerfassung und
leerem Stderr. Eigener Cleanup im Lauf bestand; der frische unabhängige Audit
dieses achten Laufs war zunächst ausstehend. Der anschließende frische Linuxaudit
bestätigt drei eigene Datenbanken und einen eigenen Trusthash abwesend; keine
Konfigurations-/Rechteänderungen.

Der gleiche finale öffentliche Adapter und dasselbe Produkt-/Binarypaar bestanden
auch auf Windows2025/exakt CU8 CL170 local/central einschließlich aller drei
SQLfixtures, Client, SC-/UTF8-Consumer, Clean/Repeat, fünf Slots/drei Bindings,
29 gezielten Lifecycleprüfungen und Uninstall/Repeat. Exit0, vollständige Kanäle,
leeres Stderr und Cleanup im Lauf bestanden. Der frische unabhängige Windowsaudit
bestand anschließend: drei eigene DBs/ein eigener Trusthash abwesend, keine
Konfigurations-/Rechteänderungen. Weitere Ziele, Minimalrechte, Fremdslot-/Driftvollmatrix und Heap
bleiben offen.

Historische native Versuche bleiben FAILED: zunächst Syntax, danach LF-Padding
und im fünften Gesamtlauf eine generische Assertion in `Metadata.Tests.ps1`.
Der fünfte Lauf belegte lediglich lokale Clean/Repeat-/Binding- und SQLfixture-
Teilresultate. Die Produktkorrekturen betreffen das NCHAR-CASE-Padding des LF-
Writers und drei deklarierte NOT-NULL-Spalten im Help-first-Pfad. Erst der achte
Lauf liefert den genannten Gesamtadapter-PASS. Zum damaligen Stand blieben
SQL Server 2022, übrige Windows-/Linux-Ziele und Compatibility Levels sowie
weitere Collations offen; die Ergänzung vom 2026-10-20 steht oben getrennt.

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

[PR169](https://github.com/gecompat/SQL_Server_Toolbelt/pull/169) wurde am
exakten Head `89f36f848ab68a1a72898ddd5f081fc47740f119` mit fünf erfolgreichen
Checks gemergt: CSV Memory Qualification, Documentation Incremental sowie
ZIP Static contract, .NET48 build und Linux SQL2022 runtime. Der CSV-Workflow
qualifiziert seinen registrierten Framework-/statischen Scope; der ZIP-Runtime-
Check ist kein CSV-SQL2022-Nachweis. Die unveränderten kanonischen CSV-Quellen
binden diese historische Head-CI an denselben Source-Stand; lokale Produktbytes
wurden getrennt qualifiziert. Neue PR-Heads benötigen
ihre eigenen Checks.

Reproduzierbare Prüfpunkte:

- `python Modules/toolbelt.file.csv-memory/Tests/Static/validate_contract.py`
- `Clr/Toolbelt.File.CsvMemory.csproj`: eigener begrenzter .NET48-Build;
  `Scripts/New-ClrReleaseArtifacts.ps1` konsumiert dessen exakte Bytes.
- `Tests/Framework/run-framework-csv.ps1`: exakt gepacktes Binary mit Hashbindung,
  begrenzte unabhängige Orakel und IL-/NoIO-Qualifikation.
- `Tests/CI/run-csv-memory-lab.ps1`: schema-validierte explizite Labziele,
  eigener DB-/Trustscope, private Wiederherstellungsjournale, begrenzte SQL- und
  Clientprüfungen und eigenes Cleanup. Externer Root-Watchdog muss den tatsächlich
  gestarteten eigenen Prozess zeitlich begrenzen und beide Kanäle vollständig
  konsumieren; ein PASS-Text allein ist kein Erfolg.
- `.github/workflows/csv-memory-qualification.yml`: separater Nachweis am exakten PR-Head.

Keine Konfiguration, Rechte, Owner oder Lab-Infrastruktur automatisch ändern.
Ein bestehender Trusteintrag bleibt vollständig unverändert; eigene Einträge
werden nur bei gleicher Identität und ohne Verbraucher entfernt. Keine Adoption
fremder Journale oder Ressourcen. Frische unabhängige Prüfung nach dem Prozessende
belegt den eigenen Cleanup, ohne reale Laufzeitdaten in das Repository zu übernehmen.

Weitere Versionen, Plattformen, Minimalrechte, Ceiling- und Heapfälle bleiben
sichtbar offen bis zu einer tatsächlich erfolgreichen begrenzten Qualifikation.
Die [Matrix](CSV_TEST_MATRIX.md) trennt erfolgreiche Teilprüfungen und offene
Pflichtscopes. Manifest-Evidenz enthält keine privaten Journale, Pfade oder Logs.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-20`
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1; zusätzliche CL-Welle nach PR339`
- Scope: Sechs zusätzliche Kombinationen Windows/Linux jeweils SQL2022 CL150 sowie SQL2025 CL150 und CL160 bestanden je im ersten nativen Versuch local/central mit aktuellem Quellen-/ResultTable-Abhängigkeitsstand: drei SQLfixtures, Client, Clean/Repeat, fünf Slots/drei Bindings, je 29 gezielte Lifecyclefälle, frischer SC-/UTF8-Consumer, Uninstall/Repeat; Exit0, vollständige Kanäle, leeres Stderr. Je frischer unabhängiger Audit drei eigene DBs/einen eigenen Trusthash abwesend und Inputpins unverändert. Zwei autorisierte temporäre SQL2022-CLR-Konfigurationen vollständig restauriert; keine Rechte-/Owner-/Infrastrukturänderungen. Paket, ursprüngliche Build-/Frameworknachweise und sechs Standard-CL-Läufe nach erneuter Inputprüfung wiederverwendet, nicht neu ausgeführt. Damit zwölf zulässige Plattform-/Engine-/CL-Kombinationen im begrenzten Gesamtadapter bestanden; Minimalrechte, Driftvollmatrix, weitere Collations, Heap, authentifiziertes TLS und Release bleiben offen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
