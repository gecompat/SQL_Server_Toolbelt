# CHANGELOG

Alle wesentlichen Änderungen an SQL Server Toolbelt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

## [Unreleased]

### Hinzugefügt

- Repository-Grundaufbau mit autoritativen Steuerungsdateien, Architektur, Standards, Templates und Backlogs.
- Verbindlicher USP-Vertrag und SQL-Objekt-Namenskonventionen.
- GitHub-Copilot-Custom-Agent für die Backlog-Pflege.

### Korrigiert

- Custom-Agent-Profil auf gültige `.agent.md`-Struktur mit YAML-Frontmatter umgestellt.
- Generische Objektvorlagen durch objekttypspezifische USP-, TVF-, SVF- und View-Vorlagen ersetzt.
- USP-Vertrag und Teststandard um vollständige `@ResultTable`- und `@KeepData`-Contract-Tests ergänzt.
- SQL Server 2025 in Support-, Manifest- und Testmatrizen aufgenommen.
- CLR-Linux-Grenzen und `TRUSTWORTHY`-Ausnahmeregel präzisiert.
- Statusangaben nach dem initialen Merge aktualisiert.
- Entscheidungsprotokoll, Contribution-Regel und technische Identifier-Sprache konsolidiert.
- Bereits in `SQL_Server_Analyze` vorhandenen Unused-Index-Kandidaten aus dem offenen Analyze-Backlog entfernt.

### Status

Keine fachlichen Module implementiert. Keine Runtime-Validierung von Toolbelt-Funktionen vorhanden.
