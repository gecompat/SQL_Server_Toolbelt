# Editierdistanz-Tests

`Framework/run-framework-distance.ps1` erzeugt synthetische Goldens aus einer
unabhängigen Vollmatrixreferenz, kompiliert exakt die produktiven Kernel- und
Providerquellen mit dem Framework-Harness und startet neun begrenzte Kinder
(maximal 45 Sekunden je Kind). Keine SQL-, Providerinstallation oder Downloads.

Tatsächlich am 2026-10-02: Python-Referenz 21185 Assertions; neun Frameworkkinder
81380 Assertions, einschließlich 27104 Matrixgoldens, Profile/UTF16/NULL/INT_MAX,
Provider-FillRow und realer vollständiger 1M-/16M- sowie Large-Bandberechnung.
Diese sind Offlinequellenprüfungen; die getrennte native Evidenz folgt unten.
Historische private 101936 Assertions gehören zum Vor-Source-Kandidaten und
werden nicht als erneuter öffentlicher Providerlauf umgedeutet.

Runtime/Distance.Contract.sql prüft Scalar-/OSA-/Levenshtein-Goldens, Fehlerpriorität,
Defaults, NULL und Einzeilenverhalten. Distance.Boundaries.sql prüft tatsächlich
berechnete 16M-Grenzen, Überschreitung und lange Bänder. InstalledMetadata.Contract.sql
prüft vier IF/FT-Slots und Transporttypen. Lifecycle.Snapshot.sql ist optionsneutral.
Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/Runtime/Invoke-LabContract.ps1; unabhängiger Root-Bereinigungsaudit`
- Scope: Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Der erfolgreich ausgeführte native Adapter umfasst CS-/CI-Datenbanken, 1000 unterschiedliche Paarorakel, tatsächlichen Versions-/Datenbankpreflight, zweite Connection/AppLock, post-DROP-Rollback, synthetische 0-/NULL-Rechtegates im zweiten Pass, sechs Kollisionsfälle einschließlich Aliastyp und fremde Dependency sowie read-only Trustverbraucherprüfung. Synthetische 0-/NULL-Rechtegates sind kein tatsächlicher Lowpriv-PASS. Die 1000 Paar-Goldens wurden zusätzlich gegen die unabhängige Vollmatrixreferenz mit 2000 Assertions geprüft.

Historie: Der erste Linux-Lauf scheiterte mit SQL468/State9 im Metadaten-Fixture (Collationkonflikt) und wurde vollständig bereinigt. Nach expliziter DATABASE_DEFAULT-Harmonisierung bestand der neue Gesamtadapter. Kein rückwirkender PASS für den Fehlerlauf. Beide finalen Läufe endeten mit unveränderten Quellpins; je drei eigene Testdatenbanken und der eigene hinzugefügte Trust wurden unabhängig als entfernt bestätigt. IL-NoIO/NoPInvoke-/Allowlistprüfung am tatsächlichen Releasebinary separat bestanden; daraus folgt keine transitive Framework- oder Heapzusage.
