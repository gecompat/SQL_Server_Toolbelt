# PROJECT_CONTEXT.md – Projektzusammenhang

## Projektzweck

SQL Server Toolbelt ist eine modulare Erweiterungsbibliothek für Microsoft SQL Server Database Engine ab Version 2019. Ziel ist es, Funktionen bereitzustellen, die SQL Server nicht nativ besitzt, erst in späteren Versionen bietet oder nur mit wiederkehrendem, fehleranfälligem Boilerplate ermöglicht.

## Nutzen

- Wiederverwendbare, getestete und dokumentierte SQL-Server-Objekte.
- Reduzierung von Boilerplate-Code für häufige Aufgaben.
- Einheitliche Vertragsdefinitionen (USP, TVF, SVF, VW).
- Klare Trennung von implementierter Funktion und Konfigurationsanalyse.

## Scope

- SQL Server 2019 und neuer, Windows und Linux.
- T-SQL bevorzugt; CLR, C#, Python, Java oder R nur mit technischer Begründung.
- Lokale und zentrale Deployment-Modi gleichwertig.
- Cross-database-Verwendung als Designziel, keine Garantie.

## Non-Goals

- Performance-, Konfigurations-, Diagnose- und Security-Analysen → `gecompat/SQL_Server_Analyze`.
- Azure SQL Database, Azure SQL Managed Instance → kein automatischer Support.
- Demo-Anwendungen, Produktionsdaten, Backups, Logs.

## Repository-Grenzen

- Dieses Repository ändert nicht `gecompat/SQL_Server_Analyze` oder andere Repositories.
- Analyse-Ideen dürfen im Backlog `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` erfasst werden.

## Plattformen

| Plattform | Status |
|---|---|
| SQL Server 2019 (Windows) | Zielplattform |
| SQL Server 2022 (Windows) | Zielplattform |
| SQL Server 2019 (Linux) | Zielplattform |
| SQL Server 2022 (Linux) | Zielplattform |
| Azure SQL Database | Kein automatischer Support |
| Azure SQL Managed Instance | Kein automatischer Support |
| SQL Server < 2019 | Nicht unterstützt |

## Trennung von Status

- **geplant**: Im Backlog oder in der Roadmap erfasst; keine Implementierungszusage.
- **implementiert**: Code vorhanden, aber nicht zwingend getestet.
- **validiert**: Tatsächlich ausgeführte erfolgreiche Prüfungen auf Zielplattform.
- **experimental**: Funktionsfähig, aber noch nicht vollständig validiert.
- **deprecated**: Veraltet, wird in zukünftiger Version entfernt.
- **unsupported**: Nicht unterstützte Konfiguration.
- **not executed**: Test oder Prüfung nicht ausgeführt.
- **not applicable**: Nicht anwendbar für diese Konfiguration.
- **curiosity**: Theoretische oder akademische Überlegung ohne Implementierungszusage.

Plan, Dokumentation, Manifest und Testcode sind **kein** Runtime-Nachweis.
