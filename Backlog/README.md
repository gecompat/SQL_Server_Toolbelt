# Backlog – SQL Server Toolbelt

Dieses Verzeichnis enthält drei kanonische Kandidatenlisten, eine deduplizierte Research-Inbox, eine grobe Fokuspriorisierung sowie einen vom Benutzer gepflegten persönlichen Brainstorm als Research-Input.

| Datei | Inhalt |
|---|---|
| [TOOLBELT_CANDIDATES.md](./TOOLBELT_CANDIDATES.md) | formal beschriebene wiederverwendbare Toolbelt-Funktionen |
| [TOOLBELT_RESEARCH_INBOX.md](./TOOLBELT_RESEARCH_INBOX.md) | breit recherchierte, deduplizierte und noch nicht priorisierte Toolbelt-Ideen mit Quellen |
| [TOOLBELT_RESEARCH_PRIORITIES.md](./TOOLBELT_RESEARCH_PRIORITIES.md) | grobe, veränderbare Fokusgruppen nach Nutzen, Hebel, Abhängigkeiten und Komplexität |
| [SQL_SERVER_ANALYZE_CANDIDATES.md](./SQL_SERVER_ANALYZE_CANDIDATES.md) | geprüfte Ideen für `gecompat/SQL_Server_Analyze` |
| [MAN_KANN_ES_AUCH_UEBERTREIBEN.md](./MAN_KANN_ES_AUCH_UEBERTREIBEN.md) | theoretische, akademische oder bewusst unterhaltsame Ideen |
| [personal_Backlog_Bainstorm.md](./personal_Backlog_Bainstorm.md) | freie Gedanken des Benutzers als verpflichtend zu berücksichtigende, nicht autoritative Research-Hinweise |
| [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md) | verbindliche Vorlage für formale Kandidaten |

## Rolle der Research-Inbox

- Die Inbox verdichtet Mehrfachnennungen zu stabilen `RI-`-IDs und bewahrt alle zugehörigen Quellen.
- Ein Inbox-Eintrag ist weder Priorisierung noch öffentlicher Vertrag, formaler `TC-`-Kandidat oder Implementierungsfreigabe.
- Nach gemeinsamer Filterung werden ausgewählte Ideen mit [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md) formalisiert; die ursprüngliche `RI-`-ID bleibt als Herkunft erhalten.
- Datenschutz- und Secret-Regeln gelten unverändert.

## Rolle der Fokuspriorisierung

- Die Priorisierung ist eine veränderbare Arbeits- und Konzentrationshilfe, keine endgültige Bewertung.
- Sie darf `RI-`-Einträge gruppieren und formale `TC-`-Kandidaten in den aktuellen Projektkontext einordnen.
- Sie ersetzt weder Research-Inbox noch kanonischen Backlog, definiert keinen öffentlichen Vertrag und erteilt keine Implementierungsfreigabe.
- Quellen bleiben an den ursprünglichen `RI-`- und `TC-`-Einträgen erhalten.

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

1. Vor jeder Funktionsrecherche den persönlichen Brainstorm, die Research-Inbox und alle drei kanonischen Listen lesen.
2. Vor jeder Ergänzung Inbox und kanonische Listen auf Duplikate prüfen; Mehrfachquellen am vorhandenen Eintrag sammeln.
3. Breite, noch ungefilterte Research-Ideen mit öffentlicher Quelle und stabiler `RI-`-ID in die Inbox aufnehmen.
4. Bei Analyze-Ideen nach Möglichkeit das Ziel-Repository lesend auf vorhandene Funktionalität prüfen.
5. Fakten, Vermutungen und offene Fragen trennen.
6. Nach gemeinsamer Filterung ausgewählte Ideen mit Primärquelle und Prüfdatum in die passende kanonische Liste überführen.
7. Im persönlichen Brainstorm nach Möglichkeit einen Querverweis ergänzen, ohne Originalinhalt zu löschen.
8. Ideen und Research-Kandidaten dürfen fortlaufend ergänzt werden; dadurch entsteht keine Implementierungszusage.
9. Vor jeder Implementierung Zweck, öffentlichen Vertrag, Alternativen, Risiken und Scope der konkreten Funktion mit dem Benutzer besprechen.
10. Kandidaten erst nach dieser Besprechung und ausdrücklicher Benutzerfreigabe in `.ai/BACKLOG.md` als aktives Implementierungsarbeitspaket übernehmen.

Der GitHub-Copilot-Custom-Agent [backlog-curator.agent.md](../.github/agents/backlog-curator.agent.md) unterstützt diese Pflege bei expliziter Zuweisung. Er arbeitet nicht unbeaufsichtigt im Hintergrund.
