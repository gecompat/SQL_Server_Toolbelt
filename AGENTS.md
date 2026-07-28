# AGENTS.md – Autoritativer Einstieg für KI-Systeme

Dieses Dokument ist der verbindliche Einstiegspunkt für alle KI-Systeme (GitHub Copilot, Copilot Coding Agent, andere LLM-basierte Werkzeuge), die in diesem Repository arbeiten.

## Regelpriorität

1. Dieses `AGENTS.md` (Einstieg und Stop-Gates)
2. `.ai/PROJECT_RULES.md` (kanonische Architektur-, Datenschutz-, Coding- und Qualitätsregeln)
3. `.ai/WORKING_RULES.md` (Preflight, Branching, PR, Abschlussregeln)
4. `.ai/PROJECT_CONTEXT.md` (Projektzweck, Scope, Non-Goals, Grenzen)
5. `.github/copilot-instructions.md` (Copilot-spezifische Brücke)
6. `Documentation/Architecture/` und `Documentation/Standards/` (verbindliche Fachregeln)

Bei Widersprüchen gilt die höhere Priorität. Unlösbare Konflikte sind zu dokumentieren und führen zu keiner Änderung.

## Scope dieses Repositories

SQL Server Toolbelt liefert modulare, wiederverwendbare SQL-Server-Objekte für SQL Server 2019+. Performance-, Konfigurations-, Diagnose- und Security-Analysen gehören in `gecompat/SQL_Server_Analyze` und werden hier nicht implementiert.

## Datenschutz-Stop-Gate

**Vor jeder Dateiänderung, jedem Commit und jedem PR ist zu prüfen:**

- Keine personenbezogenen Daten, internen Firmen-/Kundendaten, realen Host-/Server-/DB-/Domainnamen.
- Keine internen URLs/API-Endpunkte/Pfade, Produktionsdaten/-backups, realen Logs/Traces/Plans.
- Keine Secrets (Passwörter, Tokens, API-Keys, Connection Strings mit Credentials).
- Keine lokalen Runtime-Ausgaben.

Im Zweifel: **vor dem Schreiben stoppen und Benutzer fragen.**

Erlaubt: synthetische Daten, `localhost`, `127.0.0.1`, Contoso, Fabrikam, AdventureWorks, WideWorldImporters.  
`gecompat - Gerhard Pisch` ist ausschließlich für Copyright, Attribution und Lizenz freigegeben.

## Geschützte Lizenzinhalte

`LICENSE.md`, Copyright- und Attributionstexte sowie der Lizenzblock am Anfang der README sind geschützt. Sie dürfen **ohne ausdrücklichen Benutzerauftrag nicht verändert werden**.

## KI-Commit-Regel

KI-generierte Commit Messages beginnen mit dem tatsächlichen KI-Namen, z. B.:

```
GitHub Copilot: <Beschreibung der Änderung>
```

Menschliche Commits brauchen kein KI-Präfix. Ein Branch/PR = ein klarer Scope; keine unabhängigen Änderungen in einem PR.

## Weitere autoritative Dokumente

| Dokument | Inhalt |
|---|---|
| [.ai/PROJECT_CONTEXT.md](./.ai/PROJECT_CONTEXT.md) | Projektzweck, Scope, Non-Goals, Grenzen |
| [.ai/PROJECT_RULES.md](./.ai/PROJECT_RULES.md) | Architektur-, Datenschutz-, Coding-, Qualitätsregeln |
| [.ai/WORKING_RULES.md](./.ai/WORKING_RULES.md) | Preflight, Branching, PR, Abschlussregeln |
| [.ai/ROADMAP.md](./.ai/ROADMAP.md) | Roadmap nach Priorität und Abhängigkeiten |
| [.ai/BACKLOG.md](./.ai/BACKLOG.md) | Priorisierte Arbeitspakete |
| [.github/agents/backlog-curator.md](./.github/agents/backlog-curator.md) | Backlog-Curator-Agent-Definition |
| [Documentation/Standards/USP_CONTRACT.md](./Documentation/Standards/USP_CONTRACT.md) | Verbindlicher USP-Vertrag |
| [Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md](./Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md) | Datenschutzregeln |

## Nicht-Copilot-KI-Systeme

Andere KI-Systeme dürfen nicht von `.github/copilot-instructions.md` abhängen. Sie lesen dieses `AGENTS.md` als autoritativen Einstieg und folgen der oben definierten Regelpriorität.

## Implementierungsverbot

Dieser PR enthält ausschließlich den Grundaufbau. **Kein fachliches SQL-Objekt, keine Stored Procedure, Function, View, Assembly oder ResultTable-Helper-Prozedur darf ohne freigegebenes Arbeitspaket implementiert werden.**
