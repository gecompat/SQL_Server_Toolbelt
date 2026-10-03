# Editierdistanz-Testmatrix

## Historische 1.0-Qualifikation

|Gate|Stand|Grenze|
|---|---|---|
|Unabhängige Matrixreferenz|2026-10-02 PASS, 21185 Assertions|Endlicher synthetischer Korpus; kein universeller Beweis|
|Produktive Quellen + Frameworktransport|2026-10-02 PASS, neun Kinder/81380 Assertions|Keine SQL-Engine-/Metadatenbindung|
|Releasebuild|2026-10-02 PASS, Release/Framework 4.8|Privates Releasebinary; native Installation separat nachgewiesen|
|Native API/Defaults/Collations/NUL/Surrogates/INT_MAX|PASS, ausgewählte native Ziele|Linux 2019/latest CL150; Windows 2025/CU8 CL150/160/170, jeweils local/central|
|Native 16M/Bandbudgets|PASS, ausgewählte native Ziele|Tatsächlich ausgeführte 16M/Bandberechnungen; 1M zusätzlich offline|
|SQLClient-/InstalledMetadata|PASS, ausgewählte native Ziele|ErrorCode logisch nicht NULL, Metadaten nullable; SC-UTF8-Consumer|
|Local/central, Reinstall, Caller-TX, AppLock, Rollback, Kollisionen, Dependencies, Uninstall|PASS, ausgewählte native Ziele|Exakter Binaryhash; NULL-Modemarker, post-DROP-Rollback, fremde Objekte und Dependencies erhalten|
|Minimalrechte|NOT_EXECUTED|Vorhandene Rechte, keine impliziten GRANTs|
|Aktuelle CI|Separater PR-Mergegate|Keine grüne CI behauptet|

OSA ist eingeschränkt und besitzt keine Dreiecksungleichungszusage. Endliche
Zell- und Nutzdatenpuffergrenzen sind keine Heap-/Durchsatz-/Hardwallgarantie.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-03`
- Nachweis: `private bounded Root qualification adapters; public Framework/runtime fixtures; independent read-only cleanup audits`
- Scope: Separate neue 1.1-/genuine 1.0-Builds, vollständige Distanz-/Jaro-Frameworkregression und Python 21185, beide Artefakt-IL-Metadatengates. Private native Gesamtadapter auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral und SC-UTF8 bestanden: genuine Upgrades, sechs Slots, API/Client/Metadata/Lifecycle/Caller/AppLock/Faults/Kollision/Dependency/Hash/Sichtbarkeit und unabhängige eigene 3DB/2Trust-Bereinigung. Healthy-Guard direkt; doomed ganzer originaler Firstbatch in eigener DB-Prozedur, kein vollständiger SQLCMD-doomed-Nachweis. Keine Konfigurations-/Rechte-/Owner-/Infrastrukturänderungen. Tatsächliche Minimalrechte, weitere physische Ziele, Heap und aktuelle PR-Head-CI bleiben getrennte offene Gates. Historische 1.0-Evidenz bleibt getrennt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen.

Der erste Linux-Lauf SQL468/State9 (Metadaten-Fixture-Collation) ist FAILED_CLEANED; der korrigierte neue Lauf ist ein separater PASS. Je drei eigene Datenbanken und eigener hinzugefügter Trust nach beiden finalen Läufen unabhängig als entfernt bestätigt. Synthetische 0-/NULL-Rechtepredikate sind kein tatsächlicher Lowpriv-PASS. IL-NoIO-Prüfung am Releasebinary separat bestanden. Andere physische Ziele bleiben NOT_EXECUTED.

## 1.1 Jaro – ausgewählte Scope qualifiziert 2026-10-03

| Prüfbereich | Geprüfte Orakel | Status |
|---|---|---|
| Score | Harte float-Brüche, ungerades h, exakte 0.7-Schwelle, Präfix 4 | PASS, Framework und ausgewählte native Scope |
| Scalars | Paar/isolierte Surrogate, keine Normalisierung, NUL | PASS, Framework und ausgewählte native Scope |
| Priorität | NULL/Profil/Raw/UTF16/Scalar/Work | PASS, Framework und ausgewählte native Scope |
| Ressourcen | Prognose 4096/5000, kein Identitätsbypass | PASS, Framework und ausgewählte native Scope; keine Heapzusage |
| Metadaten | 3 Parameter, float(53)/int, sechs Slots, nullable beobachtbar | PASS, ausgewählte native Scope |
| Regression | Alle bisherigen Distanzkinder und native Distanzfixtures | PASS, neue 1.1-Ausführung |
| Lifecycle | Genuine 1.0→1.1, fremde Zukunftsslots, Repeat/Uninstall | PASS, ausgewählte native Scope |
| Client/Targets | Privater Ownscopeadapter, lokal/zentral, SC-UTF8 | PASS, Linux 2019/latest CL150; Windows 2025/CU8 CL150/160/170 |

Historische 1.0-Nachweise oben sind keine 1.1-Qualifikation. Die neue Evidenz
ist separat in [Tests/README.md](README.md) dokumentiert. Tatsächliche Minimalrechte mit eigenem Principal, weitere physische Ziele und Heap-/Produktionskapazität bleiben offen. Die aktuelle CI ist ein separater Mergegate am exakten PR-Head; teilweise validiert und unveröffentlicht.