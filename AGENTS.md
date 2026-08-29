# AGENTS.md – Autoritativer Einstieg für KI-Systeme

Dieses Dokument ist der verbindliche Einstiegspunkt für alle KI-Systeme, die in diesem Repository arbeiten.

<!-- AI_REPOSITORY_FOUNDATION:BEGIN v1 -->
## AI Repository Foundation baseline

Before project work, read `.ai/foundation/FOUNDATION_RULESET.md` and then only the Foundation rule files relevant to the current scope. Project-specific instructions in this repository remain the source of truth for project facts, domain rules, architecture, state, and selected overrides.

Active project-specific governance must be transitively discoverable from this root `AGENTS.md`. If this repository keeps authoritative project rules elsewhere, preserve or add a concise project-owned discovery section outside this managed Foundation block that points to their canonical entrypoints or documents the scoped-`AGENTS.md` convention. Do not copy project rule text into this Foundation block. Active authority that cannot be discovered is an integration defect.

The current explicit task authorizes ordinary, reasonably expected and proportionate operations inside the project's authorization envelope. Do not create repeated confirmation gates for normal work. Escalate only for unresolved handling/authorization boundaries, unexpected material scope/effects, or destructive/irreversible effects lacking exact authority.

Foundation `REQUIRED` rules are a minimum protected floor; a project may intentionally be stricter. Foundation `DEFAULT` rules may be intentionally overridden by project-specific rules. Use `.ai/foundation/SEMANTIC_INTEGRATION_POLICY.md` to classify overlaps instead of replacing richer project governance.

Tool-specific adapters must lead back to this repository entry point and may not define parallel governance. When an existing adapter contains unique project rules, preserve/rehome those rules before thinning the adapter.

Foundation validation covers Foundation integration integrity only. Preserve and use the target repository's existing semantic validators, static contracts, tests, reviews, and manual validation when their contracts are affected. A green Foundation validator is not evidence that the entire project is validated.

Chat history, memory, prior scratchpads, and vendor-specific project prompts are not durable project truth.
<!-- AI_REPOSITORY_FOUNDATION:END -->

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

## Lokale SQL-Server-Tests

SQL-Server-Integrations- und Kompatibilitätstests sollen vorrangig die lokalen
SQL_Server_Lab-Testumgebungen verwenden. Der Vertrag wird portabel über
`SQL_SERVER_LAB_TEST_ENV_FILE` ermittelt; Fallback ist
`SQL_SERVER_LAB_DATA_ROOT/Exports/TestUmgebung.json`. Vor Verwendung muss er
gegen das danebenliegende Schema validiert werden. Regulär wird eine Gruppe
mit `groupStatus = READY` verwendet. Aufgrund der ausdrücklichen
Benutzerfreigabe vom 2026-08-29 dürfen aus einer Gruppe mit
`groupStatus = INCOMPLETE` einzelne, explizit nach Plattform, SQL-Version und
Patch ausgewählte Systeme verwendet werden, wenn ihr `runtimeStatus` exakt
`READY` und ihr `status` entweder `READY` oder `GROUP_INCOMPLETE` ist.
`groupStatus = EMPTY`, gestoppte Einzelziele, implizite Ersatzwahl und ein
automatischer Provider-Fallback bleiben ausgeschlossen. Dieser
projektspezifische Override hat für dieses Repository Vorrang vor einer
widersprechenden gruppenweiten READY-Klausel im Zusatzprompt. Das Projekt
startet, repariert oder löscht keine Lab-Ressourcen selbst. Zugangsdaten oder
vollständige Connection Strings dürfen nicht protokolliert, kopiert oder
committed werden. Falls vorhanden, ist der übrige Prompt aus
`SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE` zu befolgen.

## Persönlicher Research-Input

`Backlog/personal_Backlog_Bainstorm.md` ist ein vom Benutzer gepflegter Ideenpool. Vor jeder Backlog- oder Research-Aufgabe ist diese Datei als Hinweisquelle zu lesen und bei der Recherche zu berücksichtigen.

Die Datei ist keine Source of Truth für Projektregeln, Prioritäten, öffentliche Verträge oder Implementierungsfreigaben. Vorhandene Inhalte werden niemals gelöscht oder stillschweigend umformuliert. KI-Systeme dürfen ergänzen, kommentieren und auf formale Kandidaten verweisen. Nicht mehr aktuelle Aussagen werden mit Markdown durchgestrichen und unmittelbar durch einen datierten Änderungskommentar mit Autor, Begründung und gegebenenfalls Nachfolger-ID ergänzt.

## Datenschutz-Stop-Gate

**Vor jeder Dateiänderung, jedem Commit und jedem Pull Request ist zu prüfen:**

- keine personenbezogenen oder sensiblen Daten; reale Personennamen nur bei fachlicher Relevanz, rechtmäßiger Verwendung oder ausdrücklicher Freigabe;
- keine internen oder vertraulichen Firmen-, Kunden-, Organisations- oder Projektdaten;
- keine nicht öffentlichen Host-, Server-, Datenbank-, Domain-, Endpoint-, URL- oder Pfadangaben;
- keine Original-Tabelleninhalte aus realen Umgebungen, Produktionsdaten, Produktionsbackups, Exporte, realen Logs, Traces oder Execution Plans;
- keine Secrets wie Passwörter, Tokens, API-Keys, private Schlüssel oder Connection Strings mit Credentials;
- keine realen Runtime-Ausgaben sowie keine konkreten Hardware-, Kapazitäts-, Inventar- oder Umgebungswerte von Remote Runnern als Repository-Artefakte.

Im Zweifel: **vor dem Schreiben stoppen und den Benutzer fragen.**

Erlaubt sind synthetische Daten, `localhost`, `127.0.0.1`, Contoso, Fabrikam, AdventureWorks und WideWorldImporters. Ebenfalls erlaubt sind fachlich relevante, öffentlich bekannte Organisations- und externe Projektnamen sowie öffentliche Quellen-, Projekt- und Dokumentations-URLs. `gecompat` und `Gerhard Pisch` sind für Repository-Inhalte ausdrücklich freigegeben.

Eine öffentliche Organisation, ein öffentliches Projekt oder ein öffentlicher Link macht darin vorkommende personenbezogene, sensible, interne oder vertrauliche Daten nicht automatisch zulässig. Details regelt [DATA_PRIVACY_AND_CONFIDENTIALITY.md](./Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md).

## Geschützte Lizenzinhalte

`LICENSE.md`, Copyright- und Attributionstexte sowie der Lizenzblock am Anfang der README sind geschützt. Sie dürfen ohne ausdrücklichen Benutzerauftrag nicht verändert werden.

## KI-Commit-Regel

Jede vollständig oder überwiegend von einer KI erzeugte Commit Message beginnt mit dem Namen des tatsächlich verwendeten KI-Systems. Sind die konkrete LLM-Bezeichnung, der Thinking Effort und die Content Size für die Sitzung zuverlässig ermittelbar, stehen sie direkt nach dem KI-System in einer eckigen Klammer.

Verbindliches Format:

```text
<KI-System> [LLM: <Bezeichnung>; ThinkingEffort: <Wert>; ContentSize: <Wert>]: <Zusammenfassung>
```

Sind einzelne Zusatzwerte nicht zuverlässig ermittelbar, werden sie samt zugehörigem Label ausgelassen. Sie dürfen nicht geraten, geschätzt oder durch technische Platzhalter ersetzt werden. Beispielsweise:

```text
GitHub Copilot [LLM: <Bezeichnung>]: Initialize module template
GitHub Copilot: Correct repository foundation
```

Die Regel gilt auch für automatisch angelegte Plan-, Initialisierungs- und Zwischencommits. Menschliche Commits benötigen kein KI-Präfix.

## Implementierungs-Gate

Ideen und recherchierte Funktionskandidaten dürfen fortlaufend in den getrennten Backlog-Listen erfasst und präzisiert werden. Ein Kandidat, ein Design oder ein geplantes Arbeitspaket ist jedoch keine Implementierungsfreigabe.

Kein fachliches SQL-Objekt, keine Stored Procedure, Function, View, Assembly oder ResultTable-Helper-Prozedur darf implementiert werden, bevor:

1. Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope der konkreten Funktion mit dem Benutzer besprochen wurden;
2. der Benutzer anschließend die Implementierung dieser Funktion ausdrücklich freigegeben hat.

Die Besprechung und Freigabe sind vor dem Merge in `.ai/BACKLOG.md`, im Pull Request oder in einer Architekturentscheidung nachvollziehbar festzuhalten. Eine pauschale Roadmap- oder Backlog-Freigabe ersetzt diese funktionsbezogene Freigabe nicht.

## Weitere autoritative Dokumente

| Dokument | Inhalt |
|---|---|
| [.ai/PROJECT_CONTEXT.md](./.ai/PROJECT_CONTEXT.md) | Projektzweck, Scope, Non-Goals, Plattformen |
| [.ai/PROJECT_RULES.md](./.ai/PROJECT_RULES.md) | Architektur-, Datenschutz-, Coding- und Qualitätsregeln |
| [.ai/WORKING_RULES.md](./.ai/WORKING_RULES.md) | Preflight, Branching, Pull Request und Abschluss |
| [.ai/ROADMAP.md](./.ai/ROADMAP.md) | Roadmap nach Priorität und Abhängigkeiten |
| [.ai/BACKLOG.md](./.ai/BACKLOG.md) | Priorisierte Arbeitspakete |
| [.github/agents/backlog-curator.agent.md](./.github/agents/backlog-curator.agent.md) | GitHub-Copilot-Custom-Agent für die Backlog-Pflege |
| [Documentation/Standards/AI_COST_AND_QUALITY_PROCESSING_POLICY.md](./Documentation/Standards/AI_COST_AND_QUALITY_PROCESSING_POLICY.md) | Anbieterneutrale Richtlinie zur kosten- und qualitätsoptimierten Verarbeitung |
| [Documentation/Standards/USP_CONTRACT.md](./Documentation/Standards/USP_CONTRACT.md) | Verbindlicher USP-Vertrag |
| [Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md](./Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md) | Datenschutz und Vertraulichkeit |
| [Documentation/Architecture/DECISIONS.md](./Documentation/Architecture/DECISIONS.md) | Dauerhafte Architekturentscheidungen |

Andere KI-Systeme dürfen nicht von Copilot-spezifischen Dateien abhängen. Sie lesen dieses `AGENTS.md` als Einstieg und folgen der genannten Regelpriorität.
