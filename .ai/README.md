# .ai – KI-Arbeitsartefakte

Dieses Verzeichnis enthält KI-interne Steuerungs- und Metadaten für SQL Server Toolbelt.

## Zweck

Die Dateien hier dienen als autoritative Quellen für KI-Systeme und Entwickler. Sie sind **keine** öffentlich beworbenen Inhalte und werden in der öffentlichen README nicht verlinkt.

## Inhalt

| Datei | Inhalt |
|---|---|
| [PROJECT_CONTEXT.md](./PROJECT_CONTEXT.md) | Projektzweck, Scope, Non-Goals, Grenzen |
| [PROJECT_RULES.md](./PROJECT_RULES.md) | Architektur-, Datenschutz-, Coding-, Qualitätsregeln |
| [WORKING_RULES.md](./WORKING_RULES.md) | Preflight, Branching, PR, Abschlussregeln |
| [foundation/FOUNDATION_RULESET.md](./foundation/FOUNDATION_RULESET.md) | Versionierte, additive AI-Repository-Foundation-Baseline und Provenienz |
| [repo_map.yaml](./repo_map.yaml) | Maschinenlesbare Repository-Rolle und Artefaktklassen |
| [ROADMAP.md](./ROADMAP.md) | Roadmap nach Priorität und Abhängigkeiten |
| [BACKLOG.md](./BACKLOG.md) | Priorisierte Arbeitspakete |

## Regelpriorität

Diese Dateien ordnen sich in die in [AGENTS.md](../AGENTS.md) definierte Regelpriorität ein.

## Quellen und technische Untersuchung

Menschliche Benutzung beginnt bei den [Lesewegen](../Documentation/README.md).
KI-Steuerung beginnt ausschließlich bei [AGENTS.md](../AGENTS.md). Gemeinsam
genutzte Fachverträge bleiben an ihrem kanonischen Ort; ein KI-Verweis erzeugt
keine zweite Fassung und macht einen Fachvertrag nicht zu Steuerungsmetadaten.

| Quelle | Autorität, Ableitung und Prüfung |
|---|---|
| Projektregeln und WORKING_RULES | Aktive Regeln gemäß Root-Priorität; aktuelle Änderung und betroffene Abhängigkeiten bestimmen den Lesescope |
| repo_map.yaml | Projektgeführte Modul-/Artefaktkopplung und Change-Impact-Auswahl; geprüft durch [validate_documentation.py](../Tests/Documentation/validate_documentation.py) |
| Modules/*/module.yaml | Kanonischer Modulstatus und gekoppelte Artefakte; markierte Statusübersichten werden daraus erzeugt |
| Foundation | [Ruleset](foundation/FOUNDATION_RULESET.md), [Manifestindex](foundation/repo_map.yaml) und [Installationsprovenienz](foundation/installation-provenance.json); Format [installation-provenance.schema.json](foundation/schemas/installation-provenance.schema.json) |
| Foundation-Upgrade | [Bewertung und Prüfgrenzen 1.25](../Documentation/Architecture/FOUNDATION_1_25_INTEGRATION.md); historische Integrationsnachweise bleiben an ihren damaligen Stand gebunden |
| ROADMAP und BACKLOG | Planung und Freigabeverlauf; kein Runtime- oder CI-Nachweis |

Die [Dokumentationsprüfung](../Tests/Documentation/README.md) erläutert
Generatoren, Auswahl und Fehleruntersuchung. Foundation-Provenienz belegt
portable Quell-/Zielhashes und begründete Overrides; sie attestiert weder
fachliche SQL-Abnahme noch Lesbarkeit. Private Wiederherstellungsjournale,
Labverträge, Rohlogs, Secrets und konkrete Runtimezustände werden nicht hier
abgelegt. Fehlende Nachweise bleiben ausdrücklich offen.
