# Mitwirken an SQL Server Toolbelt

## Lizenz

Dieses Repository steht unter der **Attribution & Non-Commercial Redistribution License** (siehe [LICENSE.md](./LICENSE.md)). Durch Beiträge stimmst du zu, dass dein Beitrag unter denselben Bedingungen lizenziert wird und das Copyright bei **gecompat - Gerhard Pisch** verbleibt.

## Grundregeln

Lies vor jedem Beitrag:
- [AGENTS.md](./AGENTS.md) – Regelpriorität und Stop-Gates
- [.ai/PROJECT_CONTEXT.md](./.ai/PROJECT_CONTEXT.md) – Scope und Non-Goals
- [.ai/PROJECT_RULES.md](./.ai/PROJECT_RULES.md) – verbindliche Regeln
- [.ai/WORKING_RULES.md](./.ai/WORKING_RULES.md) – Branch-, PR- und Abschlussregeln

## Branches und Pull Requests

- Ein Branch/PR = ein klar abgegrenzter Scope.
- KI-generierte Commits beginnen mit `GitHub Copilot:` (oder entsprechendem KI-Namen).
- PRs werden nicht selbst gemergt.
- PR-Template: [.github/pull_request_template.md](./.github/pull_request_template.md)

## Datenschutz-Stop-Gate

Vor jedem Commit prüfen: keine personenbezogenen Daten, keine realen Infrastruktur-/Logdaten, keine Secrets. Details: [DATA_PRIVACY_AND_CONFIDENTIALITY.md](./Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md)

## Issue-Templates

- Funktionskandidat: `.github/ISSUE_TEMPLATE/function-candidate.yml`
- Modul-Implementierung: `.github/ISSUE_TEMPLATE/module-implementation.yml`
- Fehlerbericht: `.github/ISSUE_TEMPLATE/bug-report.yml`

## Coding- und Namenskonventionen

- T-SQL bevorzugt; Alternativen erfordern Begründung.
- Naming: `USP_`, `TVF_`, `SVF_`, `VW_` Präfixe; Schemas `toolbelt_<category>`.
- Details: [SQL_OBJECT_NAMING.md](./Documentation/Standards/SQL_OBJECT_NAMING.md), [TSQL_ENGINEERING.md](./Documentation/Standards/TSQL_ENGINEERING.md)

## Templates für neue Module

Nutze die Vorlagen unter `Templates/Module/` als Ausgangspunkt für neue Module.

## Definition of Done

Jedes Modul muss die Kriterien aus [MODULE_DEFINITION_OF_DONE.md](./Documentation/Standards/MODULE_DEFINITION_OF_DONE.md) erfüllen, bevor es als `implemented` oder `validated` gekennzeichnet wird.

## Sprache

Codekommentare und technische Dokumentation sind deutsch; etablierte englische Fachbegriffe, SQL-Schlüsselwörter, Produkt-, API- und Objektnamen bleiben englisch. Details: [LANGUAGE_AND_TRANSLATION_RULES.md](./Documentation/Standards/LANGUAGE_AND_TRANSLATION_RULES.md)
