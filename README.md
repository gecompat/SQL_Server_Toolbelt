# ⚠️ READ BEFORE USE

## License notice

**NOTICE: SQL Server Toolbelt is NOT Open Source. Use is governed by the custom Attribution & Non-Commercial Redistribution License.**

1. **NO RESALE:** Selling or charging third parties for access to this software or its contents is strictly prohibited.
2. **ATTRIBUTION REQUIRED:** You must preserve the copyright notice for **gecompat - Gerhard Pisch**.
3. **NO LIABILITY:** Use this software at your own risk. The author is **NOT liable** for damages, data loss, or business interruptions.

The complete legal terms are available in [LICENSE.md](./LICENSE.md). In case of a discrepancy, the English master version in `LICENSE.md` prevails.

---

## Lizenzhinweis

**HINWEIS: SQL Server Toolbelt ist keine Open-Source-Software. Die Nutzung richtet sich nach der projektspezifischen Attribution & Non-Commercial Redistribution License.**

1. **NO RESALE:** Der Verkauf der Software sowie das Entgelt für den Zugang zu dieser Software oder ihren Inhalten sind untersagt.
2. **ATTRIBUTION REQUIRED:** Der Copyright-Hinweis für **gecompat – Gerhard Pisch** muss erhalten bleiben.
3. **NO LIABILITY:** Die Nutzung erfolgt auf eigenes Risiko; der Autor haftet nicht für Schäden, Datenverlust oder Betriebsunterbrechungen.

Maßgeblich ist der vollständige englische Wortlaut in [LICENSE.md](./LICENSE.md). Die Übersetzungen dienen der Verständlichkeit.

---

# SQL Server Toolbelt

<!-- BEGIN GENERATED:MODULE_STATUS_BADGE -->
[![Status: 17 Module implementiert – 17 teilweise validiert](https://img.shields.io/badge/Status-17%20Module%20implementiert%20%7C%2017%20teilweise%20validiert-yellow)](./Modules/README.md)
<!-- END GENERATED:MODULE_STATUS_BADGE -->
[![Lizenz: Attribution & Non-Commercial Redistribution](https://img.shields.io/badge/Lizenz-Attribution%20%26%20Non--Commercial-red)](./LICENSE.md)
[![SQL Server: 2019, 2022, 2025](https://img.shields.io/badge/SQL%20Server-2019%20%7C%202022%20%7C%202025-blue)](./Documentation/Architecture/DEPLOYMENT_MODEL.md)

## Zweck

SQL Server Toolbelt ist eine modulare Erweiterungsbibliothek für Microsoft SQL Server Database Engine ab Version 2019. Sie stellt Funktionen bereit, die SQL Server nicht nativ besitzt, erst in späteren Versionen anbietet oder nur mit wiederkehrendem, fehleranfälligem Boilerplate ermöglicht.

## Scope

- Wiederverwendbare Stored Procedures, Table-valued Functions, Scalar-valued Functions, Views und bei technischer Notwendigkeit weitere Komponenten.
- T-SQL ist die bevorzugte Implementierungssprache.
- C#, SQL CLR, Python, Java oder R sind zulässig, wenn sie fachlich oder technisch besser geeignet sind und die Entscheidung dokumentiert wird.
- Lokale Installation in einer Zieldatenbank und zentrale Installation in einer dedizierten Toolbelt-Datenbank sind gleichwertige Designziele.
- Cross-database-Verwendung wird angestrebt, soweit SQL-Server-Verträge und Plattformgrenzen dies zulassen.

## Non-Goals

- Performance-, Konfigurations-, Diagnose- und Security-Analysen gehören in [`gecompat/SQL_Server_Analyze`](https://github.com/gecompat/SQL_Server_Analyze).
- Azure SQL Database, Azure SQL Managed Instance und andere Azure-Produkte werden nicht automatisch unterstützt.
- Das Repository enthält keine Produktionsdaten, Produktionsbackups oder realen Runtime-Ausgaben.

## Zielgruppe

SQL-Server-Entwickler und -Administratoren, die wiederverwendbare, dokumentierte und testbare Erweiterungsobjekte einsetzen möchten.

## Aktueller Status

**Der Repository-Grundaufbau ist abgeschlossen. 17 Module sind implementiert; Runtime-Evidenz wird pro Modul getrennt ausgewiesen.**

Das implementierte Modul [`toolbelt.core.result-table`](./Modules/toolbelt.core.result-table/README.md) stellt `toolbelt_core.USP_PrepareResultTable` als gemeinsame `@ResultTable`-/`@KeepData`-Infrastruktur bereit. Die Linux-Matrix ist auf SQL Server 2019, 2022 und 2025 erfolgreich; Windows und weitere Pflichtfälle bleiben offen.

Das unabhängige Modul
[`toolbelt.conversion.base64`](./Modules/toolbelt.conversion.base64/README.md)
stellt portable Base64-/Base64URL-Konvertierung bereit. Seine erste
SQL-Server-2025-Linux-Matrix mit Compatibility Levels 150, 160 und 170 ist
erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.core.generate-series`](./Modules/toolbelt.core.generate-series/README.md)
stellt portable, typstabile Ganzzahlreihen für `int` und `bigint` bereit.
Seine SQL-Server-2025-Linux-Matrix mit Compatibility Levels 150, 160 und 170
ist erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.metadata.identifier`](./Modules/toolbelt.metadata.identifier/README.md)
analysiert und begrenzt ein- bis vierteilige SQL-Namen. Runtime-Evidenz ist
auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.string.split-characters`](./Modules/toolbelt.string.split-characters/README.md)
teilt Unicode-Text an mehreren einzelnen literal interpretierten
Separatorzeichen. SQL Server 2025 Linux ist mit Compatibility Levels 150, 160
und 170 erfolgreich; die breitere Quote-/Escape-Ausbaustufe bleibt separat in
`TC-2026-032`.

Das implementierte Modul
[`toolbelt.validation.semantic-version`](./Modules/toolbelt.validation.semantic-version/README.md)
parst, vergleicht und sortiert strikte Semantic-Version-2.0.0-Werte.
SQL Server 2025 Linux ist mit Compatibility Levels 150, 160 und 170
erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.conversion.integer-base`](./Modules/toolbelt.conversion.integer-base/README.md)
codiert und decodiert den vollständigen `bigint`-Bereich mit frei
definierbaren ASCII-Alphabeten. SQL Server 2025 Linux ist mit Compatibility
Levels 150, 160 und 170 erfolgreich; physische 2019-/2022- und Windows-Läufe
bleiben offen.

Das implementierte Modul
[`toolbelt.datetime.calendar-difference`](./Modules/toolbelt.datetime.calendar-difference/README.md)
zerlegt `date`-Intervalle nach einer dokumentierten Anniversary-Regel.
SQL Server 2025 Linux ist mit Compatibility Levels 150, 160 und 170
einschließlich Lifecycle und zentraler Nutzung erfolgreich; physische
2019-/2022- und Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.string.directional-trim`](./Modules/toolbelt.string.directional-trim/README.md)
stellt typstabile `varchar`-/`nvarchar`-TVFs für `LEADING`, `TRAILING` und
`BOTH` bereit. SQL Server 2025 Linux ist mit Compatibility Levels 150, 160
und 170 erfolgreich; weitere Collations sowie physische 2019-/2022- und
Windows-Läufe bleiben offen.

Das implementierte Modul
[`toolbelt.conversion.uri-component`](./Modules/toolbelt.conversion.uri-component/README.md)
codiert und decodiert RFC-3986-URI-Komponenten mit UTF-8 und strikter
Validierung. SQL Server 2025 Linux ist mit Compatibility Levels 150, 160 und
170 erfolgreich; LOB-/Performancegrenzen sowie physische 2019-/2022- und
Windows-Läufe bleiben offen.

Die implementierten W2a-Module
[`toolbelt.datetime.truncate`](./Modules/toolbelt.datetime.truncate/README.md),
[`toolbelt.datetime.bucket`](./Modules/toolbelt.datetime.bucket/README.md) und
[`toolbelt.binary.bit-operations`](./Modules/toolbelt.binary.bit-operations/README.md)
stellen typgetrennte Date/Time-Truncation, Origin-basiertes Bucketing und die
fünf Bitoperationen für `bigint` als kanonische relationale TVFs bereit.
SQL Server 2025 Linux ist mit Compatibility Levels 150, 160 und 170
einschließlich Wiederholungsdeployment, Lifecycle, Central und Uninstall
erfolgreich; physische 2019-/2022- und Windows-Läufe bleiben offen.

Das implementierte W2b-A-Modul
[`toolbelt.json.path-exists`](./Modules/toolbelt.json.path-exists/README.md)
prüft SQL/JSON-Pfade fehlerfrei auf Existenz und stellt den Backport-Slice von
`TC-2026-009` bereit. SQL Server 2025 Linux ist mit Compatibility Levels 150,
160 und 170 einschließlich Lifecycle, Central und Uninstall erfolgreich;
Konstruktoren und JSON-Aggregate bleiben ausdrücklich zurückgestellt.

Die implementierten W2c-Module
[`toolbelt.core.console-message`](./Modules/toolbelt.core.console-message/README.md)
und
[`toolbelt.metadata.capability-catalog`](./Modules/toolbelt.metadata.capability-catalog/README.md)
stellen Unicode-sichere lange Message-Ausgabe sowie eine read-only Sicht auf
Database-level Toolbelt-Modulmarker bereit. SQL Server 2025 Linux ist mit
Compatibility Levels 150, 160 und 170 einschließlich Langtext-/Unicode-,
Marker-/Drift-, Lifecycle-, Central- und Uninstall-Contracts erfolgreich;
physische Zielversions-, Windows- und modulspezifische Releasefälle bleiben
offen.

Das implementierte ZIP-V1A-Modul
[`toolbelt.archive.zip-memory`](./Modules/toolbelt.archive.zip-memory/README.md)
stellt eine kontrollierte In-memory-Extraktion einzelner ZIP-Eintraege aus
`varbinary(max)` bereit. Version `1.0.0` erzwingt harte Default-Limits,
behandelt Duplicate-Entry-Namen als expliziten Fehler und liefert bei
`@FailIfEncrypted = 0` einen verschluesselten Status ohne Payload.
Runtime-Evidenz ist aktuell noch `not executed`.

## Modulprinzip

- Ein Modul ist Lifecycle-, Deployment- und Dokumentationseinheit.
- Module können einzelne zentrale Capabilities oder mehrere zusammengehörige Objekte enthalten.
- Abhängigkeiten sind versioniert, werden vor der ersten Mutation geprüft und nicht automatisch nachinstalliert.
- Wiederverwendete Fachlogik existiert genau einmal.
- Öffentliche Objekte liegen in fachlichen Schemas nach `toolbelt_<category>`.

Details: [Modul- und Abhängigkeitsmodell](./Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md)

## Unterstützte SQL-Server-Versionen

Die konkrete Grundmatrix umfasst SQL Server 2019, 2022 und 2025. Windows- und Linux-Support sowie lokale, zentrale und Cross-database-Verwendung werden je Modul getrennt ausgewiesen und validiert.

## T-SQL-first

T-SQL ist bevorzugt. Alternative Technologien benötigen eine dokumentierte Begründung zu Performance, Security, Deployment, Plattform und Wartung. Details: [T-SQL-Engineering](./Documentation/Standards/TSQL_ENGINEERING.md)

## Navigation

| Bereich | Pfad |
|---|---|
| Architektur | [Documentation/Architecture/](./Documentation/Architecture/) |
| Standards | [Documentation/Standards/](./Documentation/Standards/) |
| Module | [Modules/](./Modules/) |
| Templates | [Templates/](./Templates/) |
| Backlogs | [Backlog/](./Backlog/) |
| Tests | [Tests/](./Tests/) |
| Mitwirken | [CONTRIBUTING.md](./CONTRIBUTING.md) |
| Sicherheit | [SECURITY.md](./SECURITY.md) |
| Changelog | [CHANGELOG.md](./CHANGELOG.md) |
| Lizenz | [LICENSE.md](./LICENSE.md) |
