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

[![Status: Erstes Kernmodul implementiert – Runtime nicht ausgeführt](https://img.shields.io/badge/Status-Erstes%20Kernmodul%20implementiert-yellow)](./Modules/toolbelt.core.result-table/README.md)
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

**Der Repository-Grundaufbau ist abgeschlossen. Das erste Kernmodul ist implementiert und statisch geprüft; Runtime- und Plattformvalidierung sind noch nicht ausgeführt.**

Das implementierte Modul [`toolbelt.core.result-table`](./Modules/toolbelt.core.result-table/README.md) stellt `toolbelt_core.USP_PrepareResultTable` als gemeinsame `@ResultTable`-/`@KeepData`-Infrastruktur bereit. Seine verbindliche Testmatrix und synthetische Testartefakte sind vorhanden; SQL-Server-Runtime-Evidenz bleibt `not executed`.

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
