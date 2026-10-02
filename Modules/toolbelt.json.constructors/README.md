# JSON Constructors

`toolbelt.json.constructors` 1.1.0 implementiert die beiden einzeln freigegebenen Gruppen-USPs über den gemeinsamen T-SQL-Kern. Auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 bestanden lokal und zentral die API-/100000-/16-MiB-/Clientprüfungen als Teil insgesamt fehlgeschlagener früherer Läufe. Die finalen fokussierten Läufe mit ausschließlich InstalledMetadata.Contract.sql als Runtime-Auswahl bestanden Metadaten, genuine 1.0-Upgrades, Lifecycle, Central und eigene Bereinigung. Neue Minimalrechte bleiben offen; die Uninstall-Voraussetzung VIEW DEFINITION/SELECT wurde am 2026-10-02 einzeln freigegeben und die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht; historische 1.0-Evidenz bleibt getrennt.
Einzeln abgegrenzte Nachweise und Fehlerhistorie stehen in [Tests](Tests/README.md).
[Gruppenvertrag](../../Documentation/Architecture/JSON_GROUP_CONSTRUCTORS_CONTRACT.md).
Die historische Version 1.0.0 ist implementiert, `partially validated` und `unreleased`.

`toolbelt_json.USP_JsonArray` und `USP_JsonObject` erzeugen begrenzte JSON-Werte
aus caller-lokalen Temp-Tabellen. Der interne kanonische Kern prüft alle Daten
vor Ausgabe oder ResultTable-Mutation. Keine Inferenz, Ausführung oder Datei-I/O.

Deployment im Deployment-Verzeichnis mit SQLCMD: `sqlcmd -b -i Deploy.sql -v DeploymentMode=local`.
Dependency `toolbelt.core.result-table >=1.0.0` vorher in derselben Datenbank installieren.
Uninstall: `sqlcmd -b -i Uninstall.sql -v ConfirmNoExternalConsumers=0`;
für zentrale Installation ist Betreiberbestätigung `1` erforderlich.
Uninstall setzt vorhandenes `ALTER` auf `toolbelt_json`, Datenbank-`VIEW DEFINITION`
und `SELECT` auf `sys.sql_expression_dependencies` voraus; fehlende Rechte
(auch eine unbekannte Sichtbarkeit) blockieren vor Objektmutation mit `53622/1`.
Es werden keine Rechte erteilt.

Öffentliche Verträge: [Array](Documentation/USP_JsonArray.md),
[Object](Documentation/USP_JsonObject.md),
[Arrays je Gruppe](Documentation/USP_JsonArraysByGroup.md) und
[Objects je Gruppe](Documentation/USP_JsonObjectsByGroup.md).
[Architektur](../../Documentation/Architecture/JSON_CONSTRUCTOR_PROPOSAL.md).

Historischer Nachweis für ausschließlich Version 1.0.0: Am 2026-10-01 besteht der vollständige synthetische Adapter auf physischen
SQL Server2019Linux/latest und2025Windows/CU8, einschließlich tatsächlicher
NOT-NULL-Clientmetadaten, 16-MiB-Ergebnis und100000Entries. Kein allgemeiner
Produktionskapazitäts-/Parallelitätsnachweis. Weitere Zielkombinationen und
GitHub-hosted Workflow nicht ausgeführt; CrossDB-Minimalrechte bleiben offen.
Reproduzierbarer Nachweis: `local: Tests/CI/run-lab-local.ps1`, siehe [Tests](Tests/README.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-02`
- Nachweis: `local: Tests/CI/run-json-groups-lab.ps1 (Uninstall-Metadatenvoraussetzung)`
- Scope: Neue fail-closed Uninstall-Voraussetzung VIEW DEFINITION/SELECT: fokussierter Adapter Exit0 auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 jeweils lokal/zentral; Runtime-Auswahl nur InstalledMetadata.Contract.sql, gekoppelte genuine1.0-/Repeat-/Rollback-/AppLock-/Caller-/Marker-/Future-/Dependency-/Client-/Central-/Uninstallprüfungen PASS. Beide Journale COMPLETE, alle eigenen Datenbanken entfernt, keine Konfigurations-/Rechteänderung. Kein Default-All-PASS, keine tatsächliche Minimalrechtequalifikation; negative synthetische Predicate-Injektionen und neue Exact-head-CI noch nicht ausgeführt. Historische Nachweise bleiben unverändert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
