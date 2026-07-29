# Backlog – SQL Server Toolbelt

Dieses Verzeichnis enthält drei kanonische Kandidatenlisten sowie einen vom Benutzer gepflegten persönlichen Brainstorm als Research-Input.

| Datei | Inhalt |
|---|---|
| [TOOLBELT_CANDIDATES.md](./TOOLBELT_CANDIDATES.md) | wiederverwendbare Toolbelt-Funktionen |
| [SQL_SERVER_ANALYZE_CANDIDATES.md](./SQL_SERVER_ANALYZE_CANDIDATES.md) | geprüfte Ideen für `gecompat/SQL_Server_Analyze` |
| [MAN_KANN_ES_AUCH_UEBERTREIBEN.md](./MAN_KANN_ES_AUCH_UEBERTREIBEN.md) | theoretische, akademische oder bewusst unterhaltsame Ideen |
| [personal_Backlog_Bainstorm.md](./personal_Backlog_Bainstorm.md) | freie Gedanken des Benutzers als verpflichtend zu berücksichtigende, nicht autoritative Research-Hinweise |
| [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md) | verbindliche Vorlage für formale Kandidaten |

## Rolle des persönlichen Brainstorms

- Die Datei darf ohne formales Kandidatenformat ergänzt werden.
- Vorhandene Gedanken werden nicht gelöscht oder stillschweigend umformuliert.
- Nicht mehr aktuelle Aussagen werden mit Markdown durchgestrichen. Direkt anschließend folgt ein Änderungskommentar mit Datum, Autor beziehungsweise KI-Name, Begründung und gegebenenfalls Nachfolger-ID.
- Wird ein Gedanke formalisiert, bleibt das Original erhalten und erhält nach Möglichkeit einen Verweis auf die zugehörige `TC-`, `AC-` oder `UE-`-ID.
- Die Datei ist keine Source of Truth für Regeln, Prioritäten, Verträge oder Implementierungsfreigaben.
- Datenschutz- und Secret-Regeln gelten unverändert.

Empfohlenes Änderungsmuster:

```markdown
~~Nicht mehr aktuelle Aussage~~

> Änderung 2026-07-29 — ChatGPT: Durch neuere Primärquelle widerlegt. Nachfolger: `TC-2026-NNN`.
```

## Prozess

1. Vor jeder Funktionsrecherche den persönlichen Brainstorm und alle drei kanonischen Listen lesen.
2. Vor jedem formalen Eintrag alle Listen auf Duplikate prüfen.
3. Bei Analyze-Ideen nach Möglichkeit das Ziel-Repository lesend auf vorhandene Funktionalität prüfen.
4. Fakten, Vermutungen und offene Fragen trennen.
5. Kandidat mit Primärquelle und Prüfdatum in die passende kanonische Liste eintragen.
6. Im persönlichen Brainstorm nach Möglichkeit einen Querverweis ergänzen, ohne Originalinhalt zu löschen.
7. Ideen und Research-Kandidaten dürfen fortlaufend ergänzt werden; dadurch entsteht keine Implementierungszusage.
8. Vor jeder Implementierung Zweck, öffentlichen Vertrag, Alternativen, Risiken und Scope der konkreten Funktion mit dem Benutzer besprechen.
9. Kandidaten erst nach dieser Besprechung und ausdrücklicher Benutzerfreigabe in `.ai/BACKLOG.md` als aktives Implementierungsarbeitspaket übernehmen.

Der GitHub-Copilot-Custom-Agent [backlog-curator.agent.md](../.github/agents/backlog-curator.agent.md) unterstützt diese Pflege bei expliziter Zuweisung. Er arbeitet nicht unbeaufsichtigt im Hintergrund.
