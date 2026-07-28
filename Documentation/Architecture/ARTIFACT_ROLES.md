# Artefaktrollen – SQL Server Toolbelt

Dieses Dokument definiert verbindlich die Rolle jedes Artefakttyps im Repository.

## Öffentliche Artefakte

Öffentlich sichtbar, versioniert, dauerhaft im Repository:

| Artefakt | Beschreibung | Erlaubter Inhalt |
|---|---|---|
| `README.md` | Projektübersicht | Beschreibung, Scope, Navigation; kein KI-Metadaten-Link |
| `LICENSE.md` | Lizenztext | Exakter Lizenztext; geschützt |
| `AGENTS.md` | KI-Einstieg | Regelpriorität, Stop-Gates |
| `CONTRIBUTING.md` | Mitwirken | Prozesse, Regeln |
| `SECURITY.md` | Sicherheitsrichtlinie | Meldewege |
| `CHANGELOG.md` | Änderungsprotokoll | Versions- und Änderungshistorie |
| `Documentation/` | Architektur und Standards | Dokumentation, keine Runtime-Ausgaben |
| `Modules/` | Implementierte Module | SQL-Objekte, Doku, Tests (wenn vorhanden) |
| `Templates/` | Nicht ausführbare Vorlagen | `.sql.template`-Dateien, README |
| `Backlog/` | Kandidatenlisten | Backlog-Einträge |
| `Tests/` | Test-Infrastruktur | Testdokumentation, Testpläne |

## Interne Artefakte

KI-Steuerung und Metadaten; öffentlich im Repository, aber nicht in der README beworben:

| Artefakt | Beschreibung |
|---|---|
| `.ai/` | KI-Arbeitsartefakte: Kontext, Regeln, Roadmap, Backlog |
| `.github/copilot-instructions.md` | Copilot-Brücke |
| `.github/agents/` | Agent-Definitionen |

## Generierte Artefakte

Werden nicht committet:

- `bin/`, `obj/`, `dist/`, `*.dll`, `*.exe`, `*.nupkg`
- Log-Dateien, temporäre Dateien

## Runtime-Artefakte

Niemals committen:

- Query Plans, Execution Logs, Traces
- Test-Evidence mit Produktionsdaten
- Reale Datenbankbackups oder -exporte

## Templates

SQL-Vorlagen haben die Endung `.sql.template` und sind eindeutig als nicht ausführbar gekennzeichnet.

## Verbotener Inhalt

In allen Artefakten verboten:
- Personenbezogene Daten
- Reale Infrastrukturnamen (Server, Datenbank, Domain, Pfad)
- Secrets (Passwörter, Tokens, API-Keys, Connection Strings)
- Produktionsdaten, reale Logs oder Execution Plans
