# Artefaktrollen – SQL Server Toolbelt

Dieses Dokument definiert die Rolle der wesentlichen Repository-Artefakte.

## Öffentliche und versionierte Artefakte

| Artefakt | Rolle | Zulässiger Inhalt |
|---|---|---|
| `README.md` | öffentliche Projektübersicht | Zweck, Scope, Status und Navigation; keine internen AI-Arbeitsdetails |
| `LICENSE.md` | rechtlich maßgeblicher Lizenztext | geschützter unveränderter Lizenzinhalt |
| `AGENTS.md` | Einstieg für KI-Systeme | Regelpriorität, Scope und Stop-Gates |
| `CONTRIBUTING.md` | Contribution-Prozess | Branch-, Pull-Request-, Datenschutz- und Qualitätsregeln |
| `Documentation/` | Architektur und Standards | kanonische Entscheidungen und Fachregeln |
| `Modules/` | implementierte Module | Source, Deployment, Dokumentation, Beispiele und Tests |
| `Templates/` | nicht ausführbare Vorlagen | objekttypspezifische `.sql.template`- und Dokumentationsvorlagen |
| `Backlog/` | Kandidatenlisten | recherchierte, aber nicht automatisch freigegebene Ideen |
| `Tests/` | gemeinsame Testinfrastruktur | Testcode, synthetische Fixtures und Richtlinien |

## Interne Arbeitsartefakte

Diese Dateien sind öffentlich im Repository sichtbar, werden aber nicht als Benutzerreferenz beworben:

- `.ai/` – Projektkontext, Regeln, Roadmap, Backlog und Repo-Map;
- `.github/copilot-instructions.md` – Tool-spezifische Brücke;
- `.github/agents/*.agent.md` – GitHub-Copilot-Custom-Agent-Profile.

Interne Arbeitsartefakte dürfen keine neue fachliche Wahrheit erzeugen, die nicht in der passenden kanonischen Architektur-, Standard- oder Moduldatei dokumentiert ist.

## Generierte Artefakte

Nicht versionieren:

- `bin/`, `obj/`, `dist/`;
- DLLs, EXEs, NuGet-Pakete und Debug-Symbole;
- temporäre Dateien und Logs;
- automatisch erzeugte lokale Konfiguration.

## Runtime-Artefakte

Reale Query Plans, Execution Logs, Traces, Backups, Exporte und Test-Evidence aus produktiven oder internen Umgebungen werden nicht versioniert. Synthetische Fixtures sind nur in ausdrücklich vorgesehenen Testpfaden zulässig.

## Aktualisierungsfluss

- Architekturentscheidungen werden zuerst in `Documentation/Architecture/DECISIONS.md` festgehalten.
- Öffentliche Verträge werden in Standards und objektspezifischer Dokumentation gepflegt.
- Implementierung, Help, Beispiele, Tests, Manifest und Changelog werden gekoppelt aktualisiert.
- Generierte oder abgeleitete Artefakte werden nicht unabhängig als zweite Source of Truth gepflegt.
