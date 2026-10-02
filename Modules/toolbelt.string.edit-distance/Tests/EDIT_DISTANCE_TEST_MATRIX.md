# Editierdistanz-Testmatrix

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
- Datum: `2026-10-02`
- Nachweis: `local: Tests/Runtime/Invoke-LabContract.ps1; unabhängiger Root-Bereinigungsaudit`
- Scope: Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->

Finale Gesamtadapter am 2026-10-02 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral sowie separatem SC-UTF8-Consumer bestanden. API-/Budget-/1000-Paar-/Client- und InstalledMetadata-, NULL-Modemarker-, AppLock-, Caller-TX/SET-, post-DROP-Rollback-, Kollisions-/Dependency-, Reinstall-/Uninstall- und eigene Bereinigungsorakel erfolgreich; Konfigurations- und Rechteänderungen jeweils 0. Tatsächliche Minimalrechte, übrige physische Ziele und Heap-/Produktionskapazität sind nicht nachgewiesen; aktuelle CI wird als separater PR-Mergegate nachgewiesen.

Der erste Linux-Lauf SQL468/State9 (Metadaten-Fixture-Collation) ist FAILED_CLEANED; der korrigierte neue Lauf ist ein separater PASS. Je drei eigene Datenbanken und eigener hinzugefügter Trust nach beiden finalen Läufen unabhängig als entfernt bestätigt. Synthetische 0-/NULL-Rechtepredikate sind kein tatsächlicher Lowpriv-PASS. IL-NoIO-Prüfung am Releasebinary separat bestanden. Andere physische Ziele bleiben NOT_EXECUTED.
