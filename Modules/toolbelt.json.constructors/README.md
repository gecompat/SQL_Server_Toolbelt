# JSON Constructors

Aktuelle Sourcewelle1.3.0: Die beiden freigegebenen CLR-Aggregate und die
vier bestehenden USPs referenzieren die gemeinsame technische SAFE-Assembly
`toolbelt.json.core`1.0 in derselben Datenbank. Sieben Constructoradapter,
Core und Schema wurden als neue Closure offline qualifiziert. Die native
Constructor1.3 bestand auf Linux2019/latest CL150 lokal sowie Windows2025/CU8
CL170 lokal/zentral die vier ausgewählten Runtime-Fixtures einschließlich
16 MiB/100000 Einträgen, Repeat, Uninstall/Repeat und eigene Bereinigung.
Der genuine1.2-ALTER-Versuch scheiterte bereinigt an SQL6282. Die korrigierte
atomare Migration erhält fünf Procedure-ObjectIds und Rechte, ersetzt drei
eigene CLR-Slots/Assembly und weist verlustgefährdete Rechte-/Ownertupel oder
zusätzliche Metadaten vorher ab. Sie bestand auf beiden genannten Zielen
local/central samt vier Fixtures, nachgelagertem Schema und frischem Audit.
Vollständige API-/Lifecycle-/Releasequalifikation bleibt getrennt offen.
Die genaue Reichweite steht in [Tests](Tests/README.md). Teilweise validiert und unveröffentlicht; keine Übertragung der
historischen1.0-/1.1-/1.2-Nachweise auf1.3.
[JSON-1.2-Vertrag](../../Documentation/Architecture/JSON_CLR_MIGRATION_CONTRACT.md),
[Aggregate](Documentation/JSON_AGGREGATES.md) und
[bekannte Artefakte](Documentation/KNOWN_CLR_ARTIFACTS.json).
Der [freigegebene Core-/Migrationsvertrag](../../Documentation/Architecture/JSON_SCHEMA_CONTRACT.md)
und die [aktuelle Closure](../toolbelt.json.core/Documentation/KNOWN_JSON_ARTIFACT_CLOSURE.json)
ergänzen die unveränderte historische1.2-Zeile.

## Historische 1.1-Evidenz

`toolbelt.json.constructors` 1.1.0 implementiert die beiden einzeln freigegebenen Gruppen-USPs über den gemeinsamen T-SQL-Kern. Auf Linux 2019/latest CL150 und Windows 2025/CU8 CL150/160/170 bestanden lokal und zentral die API-/100000-/16-MiB-/Clientprüfungen als Teil insgesamt fehlgeschlagener früherer Läufe. Die finalen fokussierten Läufe mit ausschließlich InstalledMetadata.Contract.sql als Runtime-Auswahl bestanden Metadaten, genuine 1.0-Upgrades, Lifecycle, Central und eigene Bereinigung. Neue Minimalrechte bleiben offen; die Uninstall-Voraussetzung VIEW DEFINITION/SELECT wurde am 2026-10-02 einzeln freigegeben und die neue Gateumsetzung bestand fokussierte native Lifecycle-Läufe, negative CI-Injektionen bleiben offen; aktuelle CI wird als separater PR-Mergegate nachgewiesen. Teilweise validiert und unveröffentlicht; historische 1.0-Evidenz bleibt getrennt.
Einzeln abgegrenzte Nachweise und Fehlerhistorie stehen in [Tests](Tests/README.md).
[Gruppenvertrag](../../Documentation/Architecture/JSON_GROUP_CONSTRUCTORS_CONTRACT.md).
Die historische Version 1.0.0 ist implementiert, `partially validated` und `unreleased`.

`toolbelt_json.USP_JsonArray` und `USP_JsonObject` erzeugen begrenzte JSON-Werte
aus caller-lokalen Temp-Tabellen. Der interne kanonische Kern prüft alle Daten
vor Ausgabe oder ResultTable-Mutation. Keine Inferenz, Ausführung oder Datei-I/O.

Deployment1.3 benötigt den separat installierten bekannten Core, das exakt
bekannte aktuelle Constructorbinary und vorher separat
administrativ freigegebenen Hash-Trust bei unverändertem `clr strict security`.
`Scripts/New-ClrReleaseArtifacts.ps1` paketiert ein bereits qualifiziertes
Binary zusammen mit `-CoreAssemblyPath` und erzeugt `Deploy.WithAssembly.sql`/`Uninstall.Expanded.sql` sowie
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
- Datum: `2026-10-05`
- Nachweis: `local: Tests/CI/run-json-schema-lab.ps1`
- Scope: Constructor1.3: vier ausgewählte Runtime-Fixtures einschließlich16 MiB/100000 Einträgen Linux2019/latest CL150 lokal und Windows2025/CU8 CL170 local/central bestanden. Genuine bekannte1.2→1.3 beide Ziele local/central, fünf Procedureidentitäten/Rechte und effektive Owner erhalten, drei eigene CLR-Slots/Assembly atomar neu, post-DROP-Rollback und Annotationserhalt, nachgelagerte Schema26-Fall-Fixture, Repeat/Uninstall/Coreerhalt und frische hashgebundene Dispositionaudits bestanden. Weitere Ziel-/Lifecycle-/Minimalrechtematrix und aktuelle Head-CI offen; verworfener ALTER-Versuch6282 bleibt fehlgeschlagen.
- Ergebnis: `success`
<!-- END GENERATED:MODULE_EVIDENCE -->
