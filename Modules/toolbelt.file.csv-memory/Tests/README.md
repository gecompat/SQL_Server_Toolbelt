# CSV-Prüfungen und Evidenz

Stand 2026-10-05: Version1.0.0 ist implementiert, `partially validated` und
unveröffentlicht. Die unten genannte CI ist an den exakten CSV-PR-Head
gebunden; andere SAFE-Assemblies qualifizieren diese CSV-Bytes nicht.

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
Lauf liefert den genannten Gesamtadapter-PASS. SQL Server 2022, übrige Windows-/Linux-Ziele und Compatibility Levels,
weitere Collations bleiben offen.

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
- Datum: `2026-10-05`
- Nachweis: `local: hashgebundener Typed-Marker-Teiladapter aus Tests/CI/run-csv-memory-lab.ps1`
- Scope: Zwei separate synthetische Markerfälle auf Linux2019/latest CL150 lokal: Deploy/Uninstall weisen Toolbelt.Managed als int statt bit auf USP_ParseCsv mit SQL55324/state5 ab; vollständige Metadaten unverändert, neutraler Transaktionszustand und exakte eigene Restaurierung bestanden. Exit0, vollständige Kanäle, leeres Stderr; frischer unabhängiger Audit bestätigt eine eigene DB/einen eigenen Trusthash abwesend, keine Konfigurations-/Rechteänderungen. Kein neuer Gesamtadapter-, API-, Client-, Central-, Windows-, Minimalrechte-, Heap- oder vollständiger Fremdslot-/Driftmatrix-Nachweis; nicht zum bisherigen 29-Fall-Zähler addiert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
