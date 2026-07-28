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

[![Status: In Entwicklung – keine fachlichen Module implementiert](https://img.shields.io/badge/Status-In%20Entwicklung-yellow)](./CHANGELOG.md)
[![Lizenz: Attribution & Non-Commercial Redistribution](https://img.shields.io/badge/Lizenz-Attribution%20%26%20Non--Commercial-red)](./LICENSE.md)
[![SQL Server: ab 2019](https://img.shields.io/badge/SQL%20Server-ab%202019-blue)](./Documentation/Architecture/DEPLOYMENT_MODEL.md)

## Zweck

SQL Server Toolbelt ist eine modulare Erweiterungsbibliothek für Microsoft SQL Server Database Engine ab Version 2019. Sie stellt Funktionen bereit, die SQL Server nicht nativ besitzt, erst in späteren Versionen bietet oder nur mit wiederkehrendem, fehleranfälligem Boilerplate ermöglicht.

## Scope

- Wiederverwendbare SQL-Server-Objekte (Stored Procedures, Functions, Views), die fehlende oder versionsabhängige Funktionalität kapseln.
- T-SQL ist die bevorzugte Implementierungssprache.
- C#, SQL CLR, Python, Java oder R sind zulässig, wenn sie technisch besser sind; Performance-, Security-, Deployment-, Plattform- und Wartungsauswirkungen sind dann zu begründen.
- Lokale Installation in einer Zieldatenbank und zentrale Installation in einer dedizierten Toolbelt-Datenbank sind gleichwertige Modi.

## Non-Goals

- Performance-, Konfigurations-, Diagnose- und Security-Analysen gehören in [`gecompat/SQL_Server_Analyze`](https://github.com/gecompat/SQL_Server_Analyze). Ideen dürfen hier im Backlog erfasst, aber nicht implementiert werden.
- Azure SQL Database, Azure SQL Managed Instance und andere Azure-Produkte werden nicht automatisch unterstützt; Support wird später pro Modul bewertet.
- Dieses Repository enthält keine Demo-Datenbanken, keine Produktionsdaten und keine lokalen Laufzeitausgaben.

## Zielgruppe

SQL-Server-Entwickler und -Administratoren, die wiederverwendbare, getestete und dokumentierte Erweiterungsobjekte für SQL Server 2019 und neuer einsetzen möchten.

## Aktueller Status

**Noch keine fachlichen Module implementiert.** Dieses Repository enthält ausschließlich den Grundaufbau: Struktur, Regeln, Architektur, Templates, Backlogs und Dokumentation.

## Modulprinzip

- Jedes Modul ist eine eigenständige Lifecycle-, Deployment- und Dokumentationseinheit.
- Module besitzen versionierte Abhängigkeiten auf andere Module.
- Jedes Modul liefert Install-, Upgrade- und Uninstall-Skripte.
- Wiederverwendete Fachlogik existiert genau einmal; Wrapper verwenden die kanonische Implementierung.
- Schemas folgen dem Muster `toolbelt_<category>` (z. B. `toolbelt_core`, `toolbelt_string`).

Details: [Modul- und Deployment-Modell](./Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md)

## Unterstützte SQL-Server-Versionen

SQL Server 2019 und neuer. Windows und Linux (SQL Server on Linux). Ältere Versionen und Azure-Varianten sind kein Ziel; Ausnahmen werden pro Modul dokumentiert.

## T-SQL-First

T-SQL ist bevorzugt. Alternativen werden nur eingesetzt, wenn sie technisch besser sind, und müssen explizit begründet werden. Details: [TSQL_ENGINEERING.md](./Documentation/Standards/TSQL_ENGINEERING.md)

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
