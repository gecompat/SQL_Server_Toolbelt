# Testausführung

## Additive Gruppenwelle 1.1.0

Vor-Source-Gate als Commit `412dbdd3` festgehalten. Genau zwei neue Fassaden verwenden den bestehenden Kern mit GroupMode.

Am 2026-10-02 bestanden auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal und zentral die fünf Runtime-Fixtures `JsonConstructors.Contract.sql`, `Collation.Contract.sql`, `JsonGroups.Contract.sql`, `JsonGroups.Boundaries.sql` und `InstalledMetadata.Contract.sql` sowie Clientmetadaten. Dazu gehören alte ungruppierte Regression, Unicode-/Literalfälle, Gruppierung, beide Resultschemas, KeepData/Empty-Routing, späte Fehler und echte 100000-Gruppen-/16-MiB-Grenzen. Diese Teilnachweise stammen aus insgesamt fehlgeschlagenen Läufen: Das spätere Central-Orakel meldete 54600/45 wegen einer column_id-Lücke. Sie sind kein vollständiger Adapter-PASS.

Die finalen fokussierten Läufe wählten ausdrücklich nur `-RuntimeTests InstalledMetadata.Contract.sql`. Beide Adapter bestanden lokal und zentral Metadaten, genuine unveränderte 1.0-Upgrades, Repeat, Rollback/Postlock/AppLock, Marker, Future-Slot-Typen, Dependencies, committable/doomed Callertransaktionen mit ON/OFF-Optionen, Central-Bestätigung, den tatsächlichen Consumer am höchsten ausgewählten CL, Uninstall und eigene Bereinigung. Die Wiederherstellungsjournale wurden unabhängig geprüft: abgeschlossen, eigene Datenbanken entfernt, keine Konfigurations- oder Rechteänderung. Daraus wird kein finaler Default-All-Fixtures-PASS abgeleitet.

Frühere fehlgeschlagene Läufe bleiben erhalten: 53609/4 im Escape-Budget-Orakel, 206 im Kollisionsfixture, 3998 im Caller-Batch und 54600/45 im Central-Orakel. Die jeweiligen Test-/Adapterkorrekturen ändern keinen Corevertrag.

Neue Minimalrechte und die Benutzerentscheidung zu `VIEW DEFINITION`/`SELECT`, weitere Zielkombinationen und Produktions-/Parallelkapazität bleiben offen. Aktuelle CI wird als separater PR-Mergegate nachgewiesen. Status `partially validated`, `unreleased`. Historische 1.0-Evidenz unten gilt ausschließlich für die damaligen drei Slots.

Aktueller nativer Gruppenadapter: `Tests/CI/run-json-groups-lab.ps1`; Ausführung und Auswahl erfolgen nach Rootkoordination. Die frühere Bash-Labroute ist für Lab explizit gesperrt, GitHub-Container verwenden den Bash-Runner weiterhin.

## Historische Ausführung 1.0.0

Static: `python Modules/toolbelt.json.constructors/Tests/Static/validate_contract.py`.
Lab: `pwsh -File Tests/CI/run-lab-local.ps1 -RunScripts run-json-constructors-linux.sh -Versions 2019 -Platforms linux -StopOnFailure`.
Zweiter Scope separat2025Windows, CU/base-Override nach Rootregeln.
Der bestehende Runner validiert den portablen Exportvertrag/schema; keine Lab-Infrastrukturänderungen.
Am 2026-10-01 ausgeführt: beide obigen Zielscopes erfolgreich mit dem vollständigen
finalen Adapter. `local: Tests/CI/run-lab-local.ps1` ist der Nachweis, keine
persistierten Rohlogs/Verbindungswerte. Windowsbefehl:
`pwsh -NoProfile -File Tests/CI/run-lab-local.ps1 -RunScripts run-json-constructors-linux.sh -Versions 2025 -Platforms windows -WindowsPatches CU8 -StopOnFailure`.
Static, PowerShell-Syntax und scopebezogene Manifest-/Dokumentationslinksprüfung
erfolgreich. Weitere Ziele/GitHub-hosted/CrossDB-Minimalrechte nicht ausgeführt.

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-json-groups-lab.ps1 (final fokussiert)`
- Scope: Version 1.1.0: Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 lokal/zentral. Runtime-Auswahl ausschließlich InstalledMetadata.Contract.sql; Metadaten, genuine unveränderte 1.0-Upgrades, Repeat, Rollback/Postlock/AppLock, Marker/Future-Typen/Dependencies, committable/doomed Caller mit ON/OFF, Central-Bestätigung, tatsächlicher Consumer am höchsten ausgewählten CL, Uninstall und eigene Bereinigung PASS. Journale unabhängig als abgeschlossen geprüft; keine Konfigurations-/Rechteänderung. API-/100000-/16-MiB-/Clientteilnachweise aus früheren insgesamt fehlgeschlagenen Läufen separat, kein finaler Default-All-PASS. Neue Minimalrechte und VIEW DEFINITION/SELECT-Benutzerentscheidung offen; aktuelle CI als separater PR-Mergegate, weitere Ziele/Kapazität offen. Partially validated, unreleased.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
