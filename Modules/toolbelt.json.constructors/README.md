# JSON Constructors

Version 1.0.0 ist implementiert, `partially validated` und `unreleased`.

`toolbelt_json.USP_JsonArray` und `USP_JsonObject` erzeugen begrenzte JSON-Werte
aus caller-lokalen Temp-Tabellen. Der interne kanonische Kern prüft alle Daten
vor Ausgabe oder ResultTable-Mutation. Keine Inferenz, Ausführung oder Datei-I/O.

Deployment im Deployment-Verzeichnis mit SQLCMD: `sqlcmd -b -i Deploy.sql -v DeploymentMode=local`.
Dependency `toolbelt.core.result-table >=1.0.0` vorher in derselben Datenbank installieren.
Uninstall: `sqlcmd -b -i Uninstall.sql -v ConfirmNoExternalConsumers=0`;
für zentrale Installation ist Betreiberbestätigung `1` erforderlich.

Öffentliche Verträge: [Array](Documentation/USP_JsonArray.md),
[Object](Documentation/USP_JsonObject.md). [Architektur](../../Documentation/Architecture/JSON_CONSTRUCTOR_PROPOSAL.md).

Am 2026-10-01 besteht der vollständige synthetische Adapter auf physischen
SQL Server2019Linux/latest und2025Windows/CU8, einschließlich tatsächlicher
NOT-NULL-Clientmetadaten, 16-MiB-Ergebnis und100000Entries. Kein allgemeiner
Produktionskapazitäts-/Parallelitätsnachweis. Weitere Zielkombinationen und
GitHub-hosted Workflow nicht ausgeführt; CrossDB-Minimalrechte bleiben offen.
Reproduzierbarer Nachweis: `local: Tests/CI/run-lab-local.ps1`, siehe [Tests](Tests/README.md).

## Aktuelle Validierungsevidenz

<!-- BEGIN GENERATED:MODULE_EVIDENCE -->
- Datum: `2026-10-01`
- Nachweis: `local: Tests/CI/run-lab-local.ps1`
- Scope: Physische SQL Server 2019 Linux/latest und 2025 Windows/CU8; local/central, Typ-/Literal-/Unicode-/Grenz-/Help-/ResultTable-/Transaktions-/Clientmetadaten-, CS/CI-Namespace-, lokale Minimalrechte-, Repeat-/Marker-/Hash-/TF-Drift-/Kollisions-/Uninstall-Contracts; 16 MiB Ergebnis und 100000 Entries. Weitere Ziele, GitHub und CrossDB-Minimalrechte nicht ausgefuehrt.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
