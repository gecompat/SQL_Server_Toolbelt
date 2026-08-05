# PROJECT_CONTEXT.md – Projektzusammenhang

## Projektstatus

`toolbelt.file.content` ist als portabler Read-only-Dateiprovider implementiert und auf SQL Server 2025 Linux teilweise validiert. `toolbelt.filesystem.windows` ist implementiert, benötigt aber weiterhin den manuellen Windows-SQL-Server-/NTFS-Runtime-Nachweis. `toolbelt.archive.zip-memory` ist als SAFE-SQL-CLR-Provider unter SQL Server 2019/2022/2025 Linux teilweise validiert.

24 Module sind implementiert. 23 sind `partially validated`, ein Modul ist
`not executed`. Die verbindlichen Einzelstatus werden aus den jeweiligen
`module.yaml`-Manifesten abgeleitet.

Die W2c-Module `toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog` sind auf SQL Server 2025 Linux mit
Compatibility Levels 150, 160 und 170 einschließlich Langtext-/Unicode-,
Marker-/Drift-, Wiederholungs-, Lifecycle-, Central- und Uninstall-Contracts
erfolgreich. Physische SQL-Server-2019-/2022-, Windows- und
modulspezifische Releasefälle bleiben `not executed`.

Der Repository-Grundaufbau ist initialisiert und konsolidiert. Das Kernmodul
`toolbelt.core.result-table` ist implementiert und teilweise validiert: Die
GitHub-hosted Linux-Matrix ist auf SQL Server 2019, 2022 und 2025 erfolgreich;
Windows und noch nicht automatisierte Pflichtfälle bleiben `not executed`.
Das unabhängige Modul `toolbelt.conversion.base64` ist implementiert; seine
Runtime-Prüfung auf SQL Server 2025 mit Compatibility Levels 150, 160 und 170
war unter Linux erfolgreich. Physische SQL-Server-2019-/2022- und
Windows-Läufe bleiben `not executed`; das Modul ist deshalb
`partially validated`.

Das unabhängige Modul `toolbelt.core.generate-series` ist mit portablen
Inline TVFs für `int` und `bigint` implementiert. Seine Runtime-Prüfung auf
SQL Server 2025 mit Compatibility Levels 150, 160 und 170 war unter Linux
erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe bleiben
`not executed`; das Modul ist deshalb `partially validated`.

Das Modul `toolbelt.metadata.identifier` implementiert einen zustandsbasierten
Parser und einen Quote-Wrapper für ein- bis vierteilige SQL-Namen. Code,
Lifecycle-, Dokumentations- und Testartefakte sind vorhanden. SQL Server 2025
Linux mit Compatibility Levels 150, 160 und 170 ist erfolgreich; physische
2019-/2022- und Windows-Läufe bleiben `not executed`.

Das Modul `toolbelt.string.split-characters` implementiert einen literal
interpretierten Multi-Separator-Vertrag mit stabilen Ordinals, definierter
Leer-Token-Semantik und `nvarchar(max)`-Verarbeitung. Code, Lifecycle-,
Dokumentations- und Testartefakte sind vorhanden. SQL Server 2025 Linux mit
Compatibility Levels 150, 160 und 170 ist erfolgreich; physische
2019-/2022- und Windows-Läufe bleiben `not executed`. Die breitere
Quote-/Escape-Version bleibt getrennt als `TC-2026-032`.

`toolbelt.validation.semantic-version` ist mit strengem SemVer-2.0.0-Parser,
Comparator und binärem Sort Key implementiert. SQL Server 2025 Linux ist mit
Compatibility Levels 150, 160 und 170 erfolgreich; physische 2019-/2022- und
Windows-Läufe bleiben `not executed`.

`toolbelt.conversion.integer-base` codiert und decodiert den vollständigen
`bigint`-Bereich mit frei definierbaren binär eindeutigen ASCII-Alphabeten.
SQL Server 2025 Linux ist mit Compatibility Levels 150, 160 und 170
erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben `not executed`.

`toolbelt.datetime.calendar-difference` zerlegt `date`-Intervalle nach einer
dokumentierten Anniversary-Regel. `toolbelt.string.directional-trim` stellt
typstabile `varchar`-/`nvarchar`-TVFs für `LEADING`, `TRAILING` und `BOTH`
bereit. `toolbelt.conversion.uri-component` codiert und decodiert
RFC-3986-URI-Komponenten mit expliziter UTF-8-Sequenzvalidierung. Die drei
Module sind auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und
170 einschließlich Wiederholungsdeployment, zentraler Nutzung und Uninstall
erfolgreich. Physische 2019-/2022- und Windows-Läufe bleiben `not executed`;
die Module sind deshalb `partially validated`.

W2a ist mit drei weiteren portablen Inline-TVF-Modulen implementiert:
`toolbelt.datetime.truncate` bietet typgetrennte Truncation für `date`,
`datetime2(7)` und `datetimeoffset(7)`, `toolbelt.datetime.bucket` ergänzt
Origin-basierte Buckets derselben Typfamilie und
`toolbelt.binary.bit-operations` portiert die fünf SQL-Server-2022-
Bitoperationen für `bigint`. SQL Server 2025 Linux ist mit Compatibility
Levels 150, 160 und 170
einschließlich Wiederholungsdeployment, Lifecycle, zentraler Nutzung und
Uninstall erfolgreich. Physische SQL-Server-2019-/2022- und Windows-Läufe
bleiben offen; die Module sind deshalb `partially validated`.

W2b-A ist als `toolbelt.json.path-exists` implementiert. Die
Multi-statement TVF prüft Root-, Property-, Array-Index- und
Array-Wildcard-Pfade, propagiert SQL `NULL` und liefert für ungültiges JSON
oder ungültige Pfade fehlerfrei `0`. Konstruktoren aus `TC-2026-009` und
JSON-Aggregate aus `TC-2026-013` bleiben zurückgestellt. SQL Server 2025
Linux ist mit Compatibility Levels 150, 160 und 170 einschließlich nativer
Parität, Wiederholungsdeployment, Lifecycle, Central und Uninstall
erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben offen.

W2c ist als `toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog` implementiert. Die Console-USP
verwendet Unicode-sichere `PRINT`- beziehungsweise
`RAISERROR ... WITH NOWAIT`-Chunks. Die Capability-View liest ausschließlich
Database-level Extended Properties und weist Marker als `valid`,
`incomplete` oder `invalid` aus. SQL Server 2025 Linux ist mit Compatibility
Levels 150, 160 und 170 einschließlich Langtext-/Unicode-, Marker-/Drift-,
Wiederholungs-, Lifecycle-, Central- und Uninstall-Contracts erfolgreich.

`toolbelt.archive.zip-memory` ist als V1A-In-memory-Slice implementiert und
stellt `toolbelt_archive.USP_ExtractZipEntryFromBinary` bereit. Version
`1.0.0` extrahiert einen einzelnen Entry aus einem ZIP-Container im Speicher,
erzwingt Default-Limits fuer Entry-Groesse und Kompressionsverhaeltnis,
behandelt Duplicate-Namen als expliziten Fehler und liefert bei
`@FailIfEncrypted = 0` einen verschluesselten Status ohne Payload.
Runtime-Evidenz ist noch `not executed`.

## Projektzweck

SQL Server Toolbelt ist eine modulare Erweiterungsbibliothek für Microsoft SQL Server Database Engine ab Version 2019. Sie stellt Funktionen bereit, die SQL Server nicht nativ besitzt, erst in späteren Versionen anbietet oder nur mit wiederkehrendem, fehleranfälligem Boilerplate ermöglicht.

## Nutzen

- wiederverwendbare, getestete und dokumentierte SQL-Server-Objekte;
- Reduzierung wiederkehrender Implementierungslogik;
- stabile öffentliche Verträge und versionsbezogene Compatibility-Informationen;
- lokale oder zentrale Installation, soweit die Capability dies erlaubt.

## Scope

- SQL Server 2019, 2022 und 2025; spätere Versionen werden nach Erscheinen ausdrücklich bewertet;
- Windows und Linux, jeweils pro Modul und Provider ausgewiesen;
- T-SQL bevorzugt;
- SQL CLR, C#, Python, Java oder R nur mit technischer Begründung;
- lokale und zentrale Deployment-Modi;
- Cross-database-Verwendung als Designziel, nicht als pauschale Garantie.

## Non-Goals

- Performance-, Konfigurations-, Diagnose- und Security-Analysen; diese gehören in `gecompat/SQL_Server_Analyze`;
- automatische Unterstützung von Azure SQL Database oder Azure SQL Managed Instance;
- Demo-Anwendungen, Produktionsdaten, Produktionsbackups oder reale Runtime-Ausgaben;
- ungeprüfte Drittanbieterabhängigkeiten.

## Repository-Grenzen

- Dieses Repository ändert kein anderes Repository ohne ausdrücklichen Auftrag.
- Analyseideen dürfen in `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` erfasst werden.
- Vor einem Analyze-Kandidaten wird das Ziel-Repository nach Möglichkeit lesend auf vorhandene oder gleichwertige Funktionalität geprüft.

## Plattformmatrix

| Plattform | Grundstatus |
|---|---|
| SQL Server 2019 Windows | Zielplattform |
| SQL Server 2022 Windows | Zielplattform |
| SQL Server 2025 Windows | Zielplattform |
| SQL Server 2019 Linux | Zielplattform, modulabhängig |
| SQL Server 2022 Linux | Zielplattform, modulabhängig |
| SQL Server 2025 Linux | Zielplattform, modulabhängig |
| Azure SQL Database | kein automatischer Support |
| Azure SQL Managed Instance | kein automatischer Support |
| SQL Server vor 2019 | nicht unterstützt |

## Statusbegriffe

Arbeitspakete und Kandidaten verwenden einen Workflow-Status wie `proposed`,
`researched`, `active`, `blocked`, `completed`, `rejected` oder `curiosity`.

Module trennen dagegen verbindlich:

- `implementation_status`: Stand der Implementierung;
- `validation_status`: tatsächlich belegter Testscope;
- `release_status`: Veröffentlichungsstand.

Die zulässigen Modulwerte und ihre Bedeutung stehen im
[Modul- und Abhängigkeitsmodell](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md).
Plan, Dokumentation, Manifest und vorhandener Testcode sind kein
Runtime-Nachweis.
