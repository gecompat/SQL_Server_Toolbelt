# PROJECT_CONTEXT.md – Projektzusammenhang

## Projektstatus

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
Code, Lifecycle-, Dokumentations- und Testartefakte sind vorhanden; Runtime
ist noch `not executed`.

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
