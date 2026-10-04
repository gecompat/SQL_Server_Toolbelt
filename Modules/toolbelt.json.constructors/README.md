# JSON Constructors

Aktuelle Sourcewelle 1.2.0: Die beiden freigegebenen CLR-Aggregate und die
vier bestehenden USPs verwenden einen gemeinsamen SAFE-Kern. Die acht
CLR-Quelldateien entsprechen dem unabhängig offline qualifizierten bekannten
Produktbinary. Begrenzte native Installations-, Fixture-, Upgrade- und
Uninstallteilnachweise sind vorhanden; die vollständige Legacy-/Caller-/
Lifecyclequalifikation, aktuelle CI und Release bleiben offen.
Die genaue Reichweite steht in [Tests](Tests/README.md). Teilweise validiert und unveröffentlicht; keine Übertragung der
historischen 1.0-/1.1-Nachweise auf 1.2.
[JSON-1.2-Vertrag](../../Documentation/Architecture/JSON_CLR_MIGRATION_CONTRACT.md),
[Aggregate](Documentation/JSON_AGGREGATES.md) und
[bekannte Artefakte](Documentation/KNOWN_CLR_ARTIFACTS.json).

## Historische 1.1-Evidenz

`toolbelt.json.constructors` 1.1.0 implementiert die beiden einzeln freigegebenen Gruppen-USPs über den gemeinsamen T-SQL-Kern. Auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 bestanden lokal und zentral die API-/100000-/16-MiB-/Clientprüfungen als Teil insgesamt fehlgeschlagener früherer Läufe. Die finalen fokussierten Läufe mit ausschließlich InstalledMetadata.Contract.sql als Runtime-Auswahl bestanden Metadaten, genuine 1.0-Upgrades, Lifecycle, Central und eigene Bereinigung. Neue Minimalrechte bleiben offen; die Uninstall-Voraussetzung VIEW DEFINITION/SELECT wurde am 2026-10-02 einzeln freigegeben und die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht; historische 1.0-Evidenz bleibt getrennt.
Einzeln abgegrenzte Nachweise und Fehlerhistorie stehen in [Tests](Tests/README.md).
[Gruppenvertrag](../../Documentation/Architecture/JSON_GROUP_CONSTRUCTORS_CONTRACT.md).
Die historische Version 1.0.0 ist implementiert, `partially validated` und `unreleased`.

`toolbelt_json.USP_JsonArray` und `USP_JsonObject` erzeugen begrenzte JSON-Werte
aus caller-lokalen Temp-Tabellen. Der interne kanonische Kern prüft alle Daten
vor Ausgabe oder ResultTable-Mutation. Keine Inferenz, Ausführung oder Datei-I/O.

Deployment 1.2 benötigt das exakt bekannte SAFE-Binary und vorher separat
administrativ freigegebenen Hash-Trust bei unverändertem `clr strict security`.
`Scripts/New-ClrReleaseArtifacts.ps1` paketiert ein bereits qualifiziertes
Binary und erzeugt `Deploy.WithAssembly.sql`/`Uninstall.Expanded.sql` sowie
ein gekoppeltes Hashmanifest in einem neuen privaten Verzeichnis. Das Script
startet keinen Build und verändert keine Datenbank oder Trusteinträge.
Die expandierte Deploymentdatei wird mit SQLCMD und `DeploymentMode=local`
beziehungsweise `central` aufgerufen; das Template `Deploy.sql` benötigt
zusätzlich `AssemblyBits` und darf nicht ohne exakte Binarybindung ausgeführt werden.
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
- Datum: `2026-10-04`
- Nachweis: `local: scoped JSON 1.2 qualification`
- Scope: Kanonischer Projektbuild mit MSBuild 18 ohne Profil-Overrides bytegleich zur unabhängig offline qualifizierten bekannten SAFE-Zeile. Lokal acht Original-Fixtures auf Linux2019 CL150 und Windows2025/CU8 CL170. Windows2025/CU8 CL170: genuine1.1 lokal und genuine1.0 lokal/zentral, Repeat, acht Slots/sechs typisierte Marker, Uninstall/Repeat; zentrale erste-GO-Bestätigung und originaler Consumer. Sechs erste-GO-Negativfälle, Guest916/4 und Ownerfall NOT_EXECUTED. Eigene Bereinigung/frische Abwesenheit bestanden, keine Konfigurations-/Rechte-/Owneränderung. Kein vollständiger Produkt-/Matrix-/Minimalrechte-/Heap-/Spillnachweis; aktuelle Exact-head-CI mit ihrem Compilerstand und Release offen. Historische Fehlversuche unverändert.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
