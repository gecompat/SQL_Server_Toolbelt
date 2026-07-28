# GitHub Copilot Instructions

Diese Datei ist eine **Brücke** zu den autoritativen Steuerungsdateien. Sie enthält keine Regelkopien.

## Autoritative Quellen

Lies vor jeder Arbeit in dieser Reihenfolge:

1. [`AGENTS.md`](../AGENTS.md) – Einstieg, Regelpriorität, Stop-Gates
2. [`.ai/PROJECT_RULES.md`](../.ai/PROJECT_RULES.md) – Architektur-, Coding-, Datenschutzregeln
3. [`.ai/WORKING_RULES.md`](../.ai/WORKING_RULES.md) – Preflight, Branch, PR, Abschluss
4. [`.ai/PROJECT_CONTEXT.md`](../.ai/PROJECT_CONTEXT.md) – Scope, Non-Goals, Grenzen
5. [`Documentation/Standards/USP_CONTRACT.md`](../Documentation/Standards/USP_CONTRACT.md) – USP-Vertrag
6. [`Documentation/Architecture/DECISIONS.md`](../Documentation/Architecture/DECISIONS.md) – Entscheidungen

## Commit-Regel

KI-generierte Commits beginnen mit `GitHub Copilot: <Beschreibung>`.

## Datenschutz-Stop-Gate

Vor jeder Dateiänderung: Datenschutz-Stop-Gate aus `AGENTS.md` prüfen. Im Zweifel stoppen.

## Implementierungsverbot

Kein fachliches SQL-Objekt ohne freigegebenes Arbeitspaket in `.ai/BACKLOG.md`.
