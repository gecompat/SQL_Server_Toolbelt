# Backlog – SQL Server Toolbelt

Dieses Verzeichnis enthält drei getrennte Kandidatenlisten.

| Datei | Inhalt |
|---|---|
| [TOOLBELT_CANDIDATES.md](./TOOLBELT_CANDIDATES.md) | wiederverwendbare Toolbelt-Funktionen |
| [SQL_SERVER_ANALYZE_CANDIDATES.md](./SQL_SERVER_ANALYZE_CANDIDATES.md) | geprüfte Ideen für `gecompat/SQL_Server_Analyze` |
| [MAN_KANN_ES_AUCH_UEBERTREIBEN.md](./MAN_KANN_ES_AUCH_UEBERTREIBEN.md) | theoretische, akademische oder bewusst unterhaltsame Ideen |
| [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md) | verbindliche Vorlage |

## Prozess

1. Vor jedem Eintrag alle Listen auf Duplikate prüfen.
2. Bei Analyze-Ideen nach Möglichkeit das Ziel-Repository lesend auf vorhandene Funktionalität prüfen.
3. Fakten, Vermutungen und offene Fragen trennen.
4. Kandidat mit Primärquelle und Prüfdatum eintragen.
5. Kandidaten erst nach Priorisierung in `.ai/BACKLOG.md` als Arbeitspaket übernehmen.

Der GitHub-Copilot-Custom-Agent [backlog-curator.agent.md](../.github/agents/backlog-curator.agent.md) unterstützt diese Pflege bei expliziter Zuweisung. Er arbeitet nicht unbeaufsichtigt im Hintergrund.
