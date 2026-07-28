# Repository-Grenzen

## Dieses Repository

`gecompat/SQL_Server_Toolbelt` enthält ausschließlich:
- Modulare, wiederverwendbare SQL-Server-Objekte (SQL Server 2019+)
- Zugehörige Dokumentation, Templates, Tests und Backlogs
- Grundaufbau (Regeln, Architektur, Standards)

## Abgrenzung zu SQL_Server_Analyze

`gecompat/SQL_Server_Analyze` ist das zuständige Repository für:
- Performance-Analysen
- Konfigurations-Analysen
- Diagnose-Analysen
- Security Assessments

**Solche Inhalte werden in diesem Repository nicht implementiert.** Ideen dürfen im Backlog `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` erfasst werden; dieses Repository ändert `gecompat/SQL_Server_Analyze` nicht.

## Keine automatische Azure-Unterstützung

Azure SQL Database, Azure SQL Managed Instance und andere Azure-Produkte werden nicht automatisch unterstützt. Support wird später pro Modul bewertet und dokumentiert.

## Keine Produktionsdaten

Das Repository enthält keine:
- Produktionsdaten oder -backups
- Realen Servernamen, Datenbanknamen, Domainnamen oder Pfade
- Realen Logs, Traces oder Query Plans
- Personenbezogenen Daten

## Cross-Repository-Regeln

- Dieses Repository ändert keine andere Repositories.
- Andere Repositories ändern dieses Repository nur über den normalen PR-Prozess.
- Backlog-Kandidaten für andere Repositories werden in den jeweiligen Backlog-Dateien erfasst, ohne Änderungen im Ziel-Repository.
