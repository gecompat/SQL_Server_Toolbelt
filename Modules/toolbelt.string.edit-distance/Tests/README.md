# Editierdistanz-Tests

`Framework/run-framework-distance.ps1` erzeugt synthetische Goldens aus einer
unabhängigen Vollmatrixreferenz, kompiliert exakt die produktiven Kernel- und
Providerquellen mit dem Framework-Harness und startet neun begrenzte Distanzkinder
sowie drei Jaro-Culturekinder (maximal 45 Sekunden je Kind). Keine SQL-,
Providerinstallation oder Downloads.

Historisch für 1.0 am 2026-10-02: Python-Referenz 21185 Assertions; neun Frameworkkinder
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
- Datum: `2026-10-03`
- Nachweis: `private bounded Root qualification adapters; public Framework/runtime fixtures; independent read-only cleanup audits`
- Scope: Separate neue 1.1-/genuine 1.0-Builds, vollständige Distanz-/Jaro-Frameworkregression und Python 21185, beide Artefakt-IL-Metadatengates. Private native Gesamtadapter auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral und SC-UTF8 bestanden: genuine Upgrades, sechs Slots, API/Client/Metadata/Lifecycle/Caller/AppLock/Faults/Kollision/Dependency/Hash/Sichtbarkeit und unabhängige eigene 3DB/2Trust-Bereinigung. Healthy-Guard direkt; doomed ganzer originaler Firstbatch in eigener DB-Prozedur, kein vollständiger SQLCMD-doomed-Nachweis. Keine Konfigurations-/Rechte-/Owner-/Infrastrukturänderungen. Tatsächliche Minimalrechte, weitere physische Ziele, Heap und aktuelle PR-Head-CI bleiben getrennte offene Gates. Historische 1.0-Evidenz bleibt getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

## Historische 1.0-Adapterläufe

Der erfolgreich ausgeführte native 1.0-Adapter umfasst CS-/CI-Datenbanken, 1000 unterschiedliche Paarorakel, tatsächlichen Versions-/Datenbankpreflight, zweite Connection/AppLock, post-DROP-Rollback, synthetische 0-/NULL-Rechtegates im zweiten Pass, sechs Kollisionsfälle einschließlich Aliastyp und fremde Dependency sowie read-only Trustverbraucherprüfung. Synthetische 0-/NULL-Rechtegates sind kein tatsächlicher Lowpriv-PASS. Die 1000 Paar-Goldens wurden zusätzlich gegen die unabhängige Vollmatrixreferenz mit 2000 Assertions geprüft.

Historie: Der erste Linux-Lauf scheiterte mit SQL468/State9 im Metadaten-Fixture (Collationkonflikt) und wurde vollständig bereinigt. Nach expliziter DATABASE_DEFAULT-Harmonisierung bestand der neue Gesamtadapter. Kein rückwirkender PASS für den Fehlerlauf. Beide finalen Läufe endeten mit unveränderten Quellpins; je drei eigene Testdatenbanken und der eigene hinzugefügte Trust wurden unabhängig als entfernt bestätigt. IL-NoIO/NoPInvoke-/Allowlistprüfung am tatsächlichen Releasebinary separat bestanden; daraus folgt keine transitive Framework- oder Heapzusage.

## 1.1-Qualifikation 2026-10-03

JaroContract.cs enthält harte Bruchgoldens, beide Textorientierungen/Profile,
UTF-16-/Ressourcenpriorität, Workprognosen und FillRow/SqlFunction-Prüfungen.
run-framework-distance.ps1 behält alle neun bisherigen Distanzkinder und ergänzt
Jaro in de-DE/en-US/tr-TR. Jaro.Contract.sql und Jaro.Boundaries.sql ergänzen
native Orakel; InstalledMetadata und Lifecycle prüfen sechs Slots.
New-LegacyTestArtifacts.ps1 paketiert genuine 1.0-Blobs unverändert; die tatsächlichen
neuen Builds und die Ausführung der öffentlichen Frameworkquellen wurden durch
einen privaten bounded Root-Offlineadapter separat gebunden.

Die neuen 1.1- und genuine 1.0-Releaseartefakte wurden in vier getrennten Offlinephasen gebaut und gebunden. Der vollständige Frameworklauf bestand neun Distanzkinder und Jaro in de-DE/en-US/tr-TR (20 physische Ausgabezeilen); die unabhängige Pythonreferenz bestand 21185 Assertions. Beide tatsächlichen Artefakte bestanden die IL-/NoIO-Metadatengates; daraus folgt keine transitive Framework- oder Heapzusage.

Am 2026-10-03 bestanden separate private, source- und binarygebundene 1.1-Qualifikationsadapter auf SQL Server 2019 Linux/latest CL150 und 2025 Windows/CU8 CL150/160/170 jeweils lokal und zentral sowie mit separatem SC-UTF8-Consumer. Genuine 1.0→1.1, sechs Slots, Repeat/Uninstall, vollständige Distanz- und Jaro-Runtime, SQLClient-/InstalledMetadata, Caller-TX/SET-Erhalt, AppLock, Faultrollback, Kollisions-/Dependency-/Hash-/Sichtbarkeitsorakel und eigene Bereinigung wurden geprüft. Tatsächlicher Child-Exit, vollständige Kanäle, gebundene Journale und frische unabhängige Cleanup-Audits wurden gemeinsam verifiziert. Je drei eigene Datenbanken und zwei exakte Hash-Trustscopes wurden bereinigt bzw. vorbestehender Trust unverändert erhalten; keine Konfigurations-, Rechte-, Owner- oder Infrastrukturänderungen.

Gesunde Caller-Guards wurden als originaler erster Clientbatch direkt geprüft. Für doomed OFF/ON lief der ganze unveränderte erste Produktbatch in einer gewöhnlichen, eigenen DB-Prozedur; Sentinel, Guardaufruf, Vor-/Nachzeugen und eigener Rollback lagen im selben parameterisierten Clientbatch. Das qualifiziert diesen Prozedurkontext, keinen vollständigen SQLCMD-Skriptlauf in einer doomed Caller-Transaktion.

Je Ziel wurden 16 endliche Testfamilien und 170 negative Rejections geprüft.
Der Runtimeledger umfasst zwölf Linux- bzw. 36 Windows-Fixtureausführungen,
der Clientledger fünf bzw. neun Prüfungen. Diese Teilzähler sind keine Zahl
sämtlicher Assertions. Die sechs Runtimequellen umfassen Distance.Contract,
Distance.Boundaries, Jaro.Contract, Jaro.Boundaries, InstalledMetadata und Lifecycle.
Genuine 1.0-Regressions-/Zukunftsslotfixtures wurden zusätzlich ausgeführt.

Syntaxqualifikation wurde getrennt gebunden: historischer Export mit 807
Quellen, fokussierte Floatfixture-/Doomseams und acht aktuelle Same-RPC-Commands.
Es wird kein tatsächlicher vollständiger 56-Command-Syntaxlauf behauptet.
Der bestehende ScriptDom-Toolprozess ist hashgebunden; seine Source wurde gelesen,
ein Source→EXE-Buildreceipt ist nicht belegt. SQL-Syntax ist kein Runtimebeweis.

Die vorherigen fehlgeschlagenen Adapterläufe bleiben Fehlerhistorie. Der
Floatfixture-Nachfolger verwendet explizite float-Brüche bei unveränderter
Toleranz; die Guardfixture bewahrt die ursprünglichen Orakel im beschriebenen
Caller-Kontext. Kein rückwirkender PASS für Fehlerläufe.
Tatsächliche Minimalrechte mit eigenem Principal, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. Die aktuelle CI ist ein separater Mergegate am exakten PR-Head; teilweise validiert und unveröffentlicht.