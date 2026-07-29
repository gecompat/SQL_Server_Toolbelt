# Mitwirken an SQL Server Toolbelt

## Lizenz

Dieses Repository steht unter der [Attribution & Non-Commercial Redistribution License](./LICENSE.md). Mit einem Beitrag erklärst du dich damit einverstanden, dass der Beitrag unter denselben Projektbedingungen veröffentlicht werden darf.

Diese Regel behauptet keine pauschale Übertragung des Urheberrechts externer Beitragender. Copyright- und Attributionstexte des Projekts bleiben geschützt; zusätzliche Rechte oder Contributor-Vereinbarungen müssen ausdrücklich dokumentiert werden.

## Vor jedem Beitrag lesen

- [AGENTS.md](./AGENTS.md) – Regelpriorität und Stop-Gates
- [.ai/PROJECT_CONTEXT.md](./.ai/PROJECT_CONTEXT.md) – Scope und Non-Goals
- [.ai/PROJECT_RULES.md](./.ai/PROJECT_RULES.md) – verbindliche Projektregeln
- [.ai/WORKING_RULES.md](./.ai/WORKING_RULES.md) – Branch-, Pull-Request- und Abschlussregeln

## Branches und Pull Requests

- Ein Branch und ein Pull Request behandeln genau einen klar abgegrenzten Scope.
- Fachliche Änderungen benötigen ein freigegebenes Arbeitspaket oder einen ausdrücklichen unmittelbaren Benutzerauftrag.
- Pull Requests werden nicht durch die ausführende KI selbst freigegeben; ein ausdrücklicher Benutzerauftrag zum Merge gilt als Freigabe.
- Nach erfolgreichem Merge wird der Arbeitsbranch gelöscht, sofern er nicht ausdrücklich weiter benötigt wird.

## KI-generierte Commit Messages

KI-generierte Commit Messages beginnen mit dem tatsächlichen KI-Namen, beispielsweise `ChatGPT:` oder `GitHub Copilot:`. Das gilt auch für automatisch erzeugte Plan- und Zwischencommits. Menschliche Commits benötigen kein KI-Präfix.

## Datenschutz-Stop-Gate

Vor jeder Dateiänderung und vor jedem Commit prüfen: keine personenbezogenen Daten, keine internen Firmen- oder Kundendaten, keine realen Infrastruktur- oder Runtime-Daten und keine Secrets. Details: [DATA_PRIVACY_AND_CONFIDENTIALITY.md](./Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md)

## Coding- und Namenskonventionen

- T-SQL ist bevorzugt; Alternativen erfordern eine dokumentierte technische Begründung.
- Öffentliche und interne technische Identifier sind englisch.
- Naming: `USP_`, `TVF_`, `SVF_`, `VW_`; Schemas folgen `toolbelt_<category>`.
- Details: [SQL_OBJECT_NAMING.md](./Documentation/Standards/SQL_OBJECT_NAMING.md) und [TSQL_ENGINEERING.md](./Documentation/Standards/TSQL_ENGINEERING.md).

## Dokumentation und Tests

Code, Dokumentation, Beispiele, Help-Vertrag, Tests, Backlog und Status werden gekoppelt gepflegt. Jedes Modul muss die Kriterien aus [MODULE_DEFINITION_OF_DONE.md](./Documentation/Standards/MODULE_DEFINITION_OF_DONE.md) erfüllen.

Vor einem Pull Request wird der inkrementelle Change-Impact-Validator ausgeführt:

```text
python3 Tests/Documentation/validate_documentation.py --base origin/main --head HEAD
```

Er prüft nur die geänderten und explizit gekoppelten Artefakte. Ein vollständiger
Audit mit `--all` ist für Releases sowie Änderungen an Governance,
Kopplungsregeln oder Validator vorgesehen.

## Templates

Die Vorlagen unter [Templates/](./Templates/) sind nicht ausführbar. Verwende immer die zum SQL-Objekttyp passende Source- und Dokumentationsvorlage.

## Sprache

Codekommentare und technische Dokumentation sind deutsch. Etablierte englische Fachbegriffe, SQL-Schlüsselwörter, Produkt-, API-, Datei-, Schema-, Objekt-, Klassen- und Parameternamen bleiben englisch.
