# Repository-Grenzen

## SQL Server Toolbelt

`gecompat/SQL_Server_Toolbelt` enthält:

- modulare, wiederverwendbare SQL-Server-Capabilities ab SQL Server 2019;
- Source, Deployment, Dokumentation, Beispiele und Tests dieser Module;
- Architektur-, Engineering- und AI-Steuerungsregeln;
- getrennte Kandidaten-Backlogs.

## Abgrenzung zu SQL Server Analyze

`gecompat/SQL_Server_Analyze` ist fachlich zuständig für:

- Performance- und Wait-Analysen;
- Konfigurations- und Infrastrukturbeurteilung;
- Diagnose laufender oder historischer Zustände;
- Security Assessments und Findings.

Solche Inhalte werden nicht im Toolbelt implementiert. Vor Aufnahme eines Analyze-Kandidaten wird das Ziel-Repository nach Möglichkeit lesend auf vorhandene oder gleichwertige Funktionalität geprüft. Das Toolbelt-Repository ändert das Ziel-Repository nicht ohne ausdrücklichen Auftrag.

## Azure

Azure SQL Database, Azure SQL Managed Instance und andere Azure-Produkte sind nicht automatisch unterstützt. Jede Capability benötigt eine eigene Prüfung von verfügbaren Features, Berechtigungen, Deployment und Plattformgrenzen.

## Öffentliche Referenzen und verbotene Repository-Inhalte

Fachlich relevante, öffentlich bekannte Organisations- und externe Projektnamen sowie öffentliche Quellen-, Projekt- und Dokumentations-URLs dürfen im Repository verwendet werden. `gecompat` und `Gerhard Pisch` sind ausdrücklich freigegeben.

Verboten bleiben:

- personenbezogene oder sensible Daten;
- interne oder vertrauliche Firmen-, Kunden-, Organisations- oder Projektdaten;
- Original-Tabelleninhalte aus realen Umgebungen, Produktionsdaten, Backups oder Exporte;
- nicht öffentliche Server-, Datenbank-, Domain-, Endpoint-, URL-, Netzwerk- oder Pfadangaben;
- reale Logs, Traces, Execution Plans oder Runtime-Evidence;
- konkrete Hardware-, Kapazitäts-, Inventar- oder Umgebungswerte von Remote Runnern;
- Secrets und private Schlüssel.

## Cross-Repository-Regeln

- Kein anderes Repository ohne ausdrücklichen Auftrag ändern.
- Fehlende Capability im zuständigen Repository als Gap dokumentieren, nicht stillschweigend dort implementieren.
- Keine parallele allgemeine Implementierung derselben Capability in mehreren Repositories.
- Austausch zwischen Repositories erfolgt über dokumentierte öffentliche Verträge oder geprüfte Backlog-Übergabe.
