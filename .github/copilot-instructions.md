# GitHub Copilot Instructions

Diese Datei ist eine kurze Brücke zu den autoritativen Projektregeln und dupliziert sie nicht.

## Vor jeder Arbeit lesen

1. [`AGENTS.md`](../AGENTS.md)
2. [`.ai/PROJECT_RULES.md`](../.ai/PROJECT_RULES.md)
3. [`.ai/WORKING_RULES.md`](../.ai/WORKING_RULES.md)
4. [`.ai/PROJECT_CONTEXT.md`](../.ai/PROJECT_CONTEXT.md)
5. relevante Dateien unter [`Documentation/Standards/`](../Documentation/Standards/) und [`Documentation/Architecture/`](../Documentation/Architecture/)

## Verbindliche Kurzregeln

- Vor jeder Dateiänderung Datenschutz- und Secret-Stop-Gate aus `AGENTS.md` prüfen.
- Kein fachliches SQL-Objekt ohne freigegebenes Arbeitspaket oder ausdrücklichen unmittelbaren Benutzerauftrag.
- KI-generierte Commit Messages folgen dem Format aus `AGENTS.md`: KI-System sowie, wenn zuverlässig ermittelbar, `LLM`, `ThinkingEffort` und `ContentSize`; dies gilt auch für Plan- und Zwischencommits. Nicht verfügbare Werte nicht erfinden.
- Öffentliche Verträge nur gemeinsam mit Dokumentation und Tests ändern.
- Lizenzdatei und geschützten README-Lizenzblock nicht ohne ausdrücklichen Auftrag verändern.

Für Backlog-Recherche steht das Custom-Agent-Profil [backlog-curator.agent.md](./agents/backlog-curator.agent.md) zur Verfügung.
