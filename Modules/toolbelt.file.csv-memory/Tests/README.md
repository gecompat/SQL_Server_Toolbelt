# CSV-Prüfungen und Evidenz

Stand 2026-10-05: Version1.0.0 ist implementiert, `partially validated` und
unveröffentlicht. Keine historische CI oder andere SAFE-Assembly qualifiziert
diese neuen CSV-Bytes.

Die statischen Verträge bestanden. `Tests/Framework/run-framework-csv.ps1`
qualifizierte das exakt gepackte aktuelle .NET48-Binary in en-US, de-DE und
tr-TR mit unabhängigen Orakeln sowie IL-/NoIO-Prüfungen; die harte Grenzphase
lief in en-US. Das ist ein CLR-Nachweis ohne SQL-/Client-/Lifecycle- oder
Heapqualifikation.

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
weitere Collations sowie aktuelle exakte Head-CI sind noch nicht nachgewiesen.

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
- Nachweis: `local: Tests/CI/run-csv-memory-lab.ps1`
- Scope: Finales gleiches Produkt-/Binarypaar: öffentliche Gesamtadapter auf Linux2019/latest CL150 und Windows2025/exaktCU8 CL170 jeweils local/central mit allen drei SQLfixtures, Clientmetadaten, Clean/Repeat, fünf Slots/drei Bindings, je 29 gezielten Caller-/SET-/Lock-/Rollback-/Confirm0-Prüfungen, frischem SC-/UTF8-Consumer und Uninstall/Repeat PASS. Je Exit0, vollständige Kanäle, leeres Stderr und Cleanup im Lauf bestanden. Linux: frischer unabhängiger Audit bestätigt drei eigene DBs/einen eigenen Trusthash abwesend, keine Konfigurations-/Rechteänderungen; Windows: frischer unabhängiger Audit bestätigt ebenfalls drei eigene DBs/einen eigenen Trusthash abwesend, keine Konfigurations-/Rechteänderungen. Keine Minimalrechte-/Fremdslot-/Driftvollmatrix-/Heap-/übrige Zielmatrix- oder Head-CI-Qualifikation. Frühere FAILED-Läufe bleiben getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
