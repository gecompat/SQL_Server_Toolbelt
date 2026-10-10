# AGENTS.md – Autoritativer Einstieg für KI-Systeme

Dieses Dokument ist der verbindliche Einstiegspunkt für alle KI-Systeme, die in diesem Repository arbeiten.

<!-- AI_REPOSITORY_FOUNDATION:BEGIN v1 -->
## AI Repository Foundation baseline

Apply the native scoped `AGENTS.override.md`/`AGENTS.md` chain on every new session. Read `.ai/foundation/FOUNDATION_RULESET.md`, affected project sources, and only relevant additional policies. Project facts, domain contracts, selected overrides, and current state remain project-owned. Discovery links are not a demand to load every document.

Use `.ai/foundation/PROCESSING_EFFICIENCY_POLICY.md` for routine work, verified session-local rule reuse, proportionate review/delegation, shared wave budgets, and bounded waiting. Reuse requires current authority/content/scope/dependency checks and actually available analysis; no optional planner or persistent record is necessary. Persistent cache users additionally follow `.ai/foundation/RULE_CONTEXT_CACHE_POLICY.md`. Unknown discovery or lost analysis never becomes a fabricated hit.

A concrete task authorizes ordinary proportionate work inside its envelope; gate only real unresolved or exceeded boundaries. Preserve REQUIRED safety/privacy/integrity/evidence floors and compatible stronger project rules. Use `.ai/foundation/SEMANTIC_INTEGRATION_POLICY.md` for integration conflicts and efficiency recommendations. Keep active project governance transitively discoverable from this root outside the managed block; preserve/rehome unique adapter rules before thinning adapters.

Foundation validation establishes FOUNDATION_INTEGRITY only. Run affected project semantic/runtime checks and required independent reviews. Use optional routing/execution contracts only for relevant selected operations. Optional capabilities grant no execution authority. Requested models, chat history, fingerprints, and cached analysis are not evidence or durable project truth.

Installation/upgrade and material workflow-rule changes require the processing-overhead assessment: actual test triggers, duplicate checks, logs, review chains, and model calls. Preserve necessary gates; justify bounded stronger exceptions or expose pending decisions. Copying rules alone does not establish efficient integration.
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
`groupStatus = EMPTY`, gestoppte Einzelziele und ein automatischer
Provider-Fallback bleiben ausgeschlossen. Für allgemeine Windows-Tests mit
`patch = base` dürfen aufgrund der ausdrücklichen Benutzerfreigabe vom
2026-09-19 bereite `CU<n>`-Ziele als äquivalenter Patchstand verwendet werden.
Bereite `base`- und `CU<n>`-Ziele derselben Windows-/SQL-Version werden
deterministisch gemeinsam ausgeführt; ein ausdrücklich angeforderter `CU<n>`-
Patch bleibt immer exakt. Andere Ersatzwahlen bleiben ausgeschlossen.
Dieser
projektspezifische Override hat für dieses Repository Vorrang vor einer
widersprechenden gruppenweiten READY-Klausel im Zusatzprompt. Das Projekt
startet, repariert oder löscht keine Lab-Ressourcen selbst. Zugangsdaten oder
vollständige Connection Strings dürfen nicht protokolliert, kopiert oder
committed werden. Falls vorhanden, ist der übrige Prompt aus
`SQL_SERVER_LAB_TEST_ENV_PROMPT_FILE` zu befolgen.

### Autorisierte SQL-Testparameter

Auf ausdrücklichen Benutzerauftrag vom 2026-10-01 dürfen die zuvor
schema-validierten, ausdrücklich ausgewählten Testsysteme für die
freigegebenen Entwicklungs- und Testwellen konfiguriert werden. Der Benutzer
hat freie Verfügung über deren Testkonfiguration ausdrücklich bestätigt.
Dies erlaubt insbesondere
`clr enabled = 1` für freigegebene CLR-Tests, nicht die Verwaltung von
Lab-Infrastruktur oder eine allgemeine Serveroptimierung.

- Notwendigkeit und Ziel vor der Änderung prüfen; vorhandene Berechtigungen
  nutzen, keine Rechte erteilen. Sicherheitsverträge bleiben unverändert:
  kein Abschalten von `clr strict security`, kein `TRUSTWORTHY ON`, kein
  `RECONFIGURE WITH OVERRIDE` und kein Serverneustart.
- Vor `RECONFIGURE` alle ausstehenden Parameteränderungen prüfen und ihre
  Auswirkungen in den Änderungsscope aufnehmen. Bereits vorgemerkte Änderungen
  dürfen auf diesen Testsystemen mitaktiviert werden; auch deren Vorzustände
  erfassen und wirksamen Zustand verifizieren. Keine implizite Übertragung der
  Freigabe auf Produktionssysteme oder andere, nicht ausgewählte Ressourcen.
- Vorzustand und eigener Änderungsscope nur in einem lokalen, nicht
  versionierten Wiederherstellungsjournal festhalten; keine Secrets,
  Connection Strings oder privaten Endpoints aufnehmen. Reale Parameterwerte
  nicht in Repository, Pull Request oder öffentliche Evidenz übernehmen.
- Änderungen zwischen Agents koordinieren und den wirksamen Zustand prüfen.
  Wiederherstellung erst nach Abschluss aller betroffenen Testverbraucher
  und nur bei weiterhin eindeutig eigenem, unverändertem Änderungsscope;
  fremde zwischenzeitliche Änderungen nicht überschreiben.

Diese eng begrenzte Freigabe ergänzt die Infrastrukturgrenze oben. Ein
blockiertes Testziel stoppt keine unabhängige freigegebene Entwicklungswelle.

### Ständige Trust-Freigabe für Entwicklungswellen

Auf ausdrücklichen Benutzerauftrag vom 2026-10-10 sind hashgebundene
`sp_add_trusted_assembly`-Einträge für bereits einzeln freigegebene
CLR-Entwicklungs- und Testwellen auf ausdrücklich ausgewählten, schema-validen
Labzielen grundsätzlich autorisiert. Diese Freigabe gilt nur für den exakten
SHA2-512-Hash eines reproduzierbar gebauten und vor dem Eintrag geprüften
Releaseartefakts. Sie ersetzt keine Funktions-, Rechte-, Infrastruktur- oder
Produktionsfreigabe und erweitert weder `clr strict security`, `TRUSTWORTHY`
noch andere Servereinstellungen.

- Vorzustand, exakter Hash, eigener Eintrag und betroffener Testscope werden
  ausschließlich im lokalen, nicht versionierten Wiederherstellungsjournal
  erfasst; keine Hashes, Serverdetails oder Runtimeausgaben in öffentlicher
  Evidenz speichern.
- Vor einem Eintrag Assemblyherkunft, Buildbindung, notwendige vorhandene
  Berechtigungen und mögliche Assemblyverbraucher prüfen. Keine Rechte erteilen
  und keine unbekannten oder abweichenden Binaries vertrauen.
- Nach Abschluss aller Verbraucher nur eindeutig eigene, unveränderte und
  nicht mehr verwendete Einträge entfernen. Unklare Ownership, Drift oder
  Verbrauch blockieren die Entfernung statt fremde Zustände zu überschreiben.

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
