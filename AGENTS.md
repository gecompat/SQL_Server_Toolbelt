# AGENTS.md – Autoritativer Einstieg für KI-Systeme

Dieses Dokument ist der verbindliche Einstiegspunkt für alle KI-Systeme, die in diesem Repository arbeiten.

## Regelpriorität

1. Dieses `AGENTS.md` – Einstieg, Scope und Stop-Gates
2. `.ai/PROJECT_RULES.md` – kanonische Architektur-, Datenschutz-, Coding- und Qualitätsregeln
3. `.ai/WORKING_RULES.md` – Preflight, Branching, Pull Request und Abschluss
4. `.ai/PROJECT_CONTEXT.md` – Projektzweck, Scope, Non-Goals und Grenzen
5. `Documentation/Architecture/` und `Documentation/Standards/` – verbindliche Fachregeln und Entscheidungen
6. Tool-spezifische Brücken wie `.github/copilot-instructions.md`

Bei Widersprüchen gilt die höhere Priorität. Unlösbare Konflikte sind zu dokumentieren; bis zur Klärung wird nichts geändert.

## Scope dieses Repositories

SQL Server Toolbelt liefert modulare, wiederverwendbare SQL-Server-Objekte für SQL Server 2019 und neuer. Die aktuelle Zielmatrix umfasst SQL Server 2019, 2022 und 2025 auf Windows und Linux, soweit ein Modul die jeweilige Plattform unterstützt.

Performance-, Konfigurations-, Diagnose- und Security-Analysen gehören in `gecompat/SQL_Server_Analyze` und werden hier nicht implementiert. Geeignete Ideen werden ausschließlich als Backlog-Input erfasst.

## Datenschutz-Stop-Gate

**Vor jeder Dateiänderung, jedem Commit und jedem Pull Request ist zu prüfen:**

- keine personenbezogenen Daten oder nicht freigegebenen realen Namen;
- keine internen Firmen-, Kunden- oder Organisationsdaten;
- keine realen Host-, Server-, Datenbank-, Domain-, URL- oder Pfadangaben;
- keine Produktionsdaten, Produktionsbackups, realen Logs, Traces oder Execution Plans;
- keine Secrets wie Passwörter, Tokens, API-Keys, private Schlüssel oder Connection Strings mit Credentials;
- keine realen Runtime-Ausgaben als Repository-Artefakte.

Im Zweifel: **vor dem Schreiben stoppen und den Benutzer fragen.**

Erlaubt sind synthetische Daten, `localhost`, `127.0.0.1`, Contoso, Fabrikam, AdventureWorks und WideWorldImporters. `gecompat - Gerhard Pisch` ist ausschließlich für Copyright, Attribution und Lizenz freigegeben.

## Geschützte Lizenzinhalte

`LICENSE.md`, Copyright- und Attributionstexte sowie der Lizenzblock am Anfang der README sind geschützt. Sie dürfen ohne ausdrücklichen Benutzerauftrag nicht verändert werden.

## KI-Commit-Regel

Jede vollständig oder überwiegend von einer KI erzeugte Commit Message beginnt mit dem Namen der tatsächlich verwendeten KI, beispielsweise:

```text
GitHub Copilot: Initialize module template
ChatGPT: Correct repository foundation
```

Die Regel gilt auch für automatisch angelegte Plan-, Initialisierungs- und Zwischencommits. Menschliche Commits benötigen kein KI-Präfix.

## Implementierungs-Gate

Kein fachliches SQL-Objekt, keine Stored Procedure, Function, View, Assembly oder ResultTable-Helper-Prozedur darf ohne freigegebenes Arbeitspaket oder ausdrücklichen unmittelbaren Benutzerauftrag implementiert werden. Ein unmittelbarer Benutzerauftrag ist vor dem Merge in `.ai/BACKLOG.md`, im Pull Request oder in einer Architekturentscheidung nachvollziehbar festzuhalten.

## Weitere autoritative Dokumente

| Dokument | Inhalt |
|---|---|
| [.ai/PROJECT_CONTEXT.md](./.ai/PROJECT_CONTEXT.md) | Projektzweck, Scope, Non-Goals, Plattformen |
| [.ai/PROJECT_RULES.md](./.ai/PROJECT_RULES.md) | Architektur-, Datenschutz-, Coding- und Qualitätsregeln |
| [.ai/WORKING_RULES.md](./.ai/WORKING_RULES.md) | Preflight, Branching, Pull Request und Abschluss |
| [.ai/ROADMAP.md](./.ai/ROADMAP.md) | Roadmap nach Priorität und Abhängigkeiten |
| [.ai/BACKLOG.md](./.ai/BACKLOG.md) | Priorisierte Arbeitspakete |
| [.github/agents/backlog-curator.agent.md](./.github/agents/backlog-curator.agent.md) | GitHub-Copilot-Custom-Agent für die Backlog-Pflege |
| [Documentation/Standards/USP_CONTRACT.md](./Documentation/Standards/USP_CONTRACT.md) | Verbindlicher USP-Vertrag |
| [Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md](./Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md) | Datenschutz und Vertraulichkeit |
| [Documentation/Architecture/DECISIONS.md](./Documentation/Architecture/DECISIONS.md) | Dauerhafte Architekturentscheidungen |

Andere KI-Systeme dürfen nicht von Copilot-spezifischen Dateien abhängen. Sie lesen dieses `AGENTS.md` als Einstieg und folgen der genannten Regelpriorität.
