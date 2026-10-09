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

Vor jeder Dateiänderung und vor jedem Commit prüfen: Öffentliche Organisations-/Projektnamen und öffentliche Quellenlinks sind bei fachlicher Relevanz zulässig. Personenbezogene oder sensible Daten, interne oder vertrauliche Informationen, Original-Tabelleninhalte, reale Runtime-Ausgaben, konkrete Remote-Runner-Hardwarewerte und Secrets sind nicht zulässig. `gecompat` und `Gerhard Pisch` sind ausdrücklich freigegeben. Details: [DATA_PRIVACY_AND_CONFIDENTIALITY.md](./Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md)

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
Audit mit `--all` ist für Baseline, Releases, globale Fach-/Schutzverträge,
Kopplungsregistry oder Validator, unbekannten Impact und ausdrücklichen Auftrag
vorgesehen. Begrenzte Prozess-/Foundationänderungen verwenden ihre Impact-Pakete.
Phasen und Wiederholungsgründe regelt die
[Test- und Validierungsrichtlinie](Documentation/Standards/TEST_AND_VALIDATION_POLICY.md).

## Verwendeten Modulstand festhalten

Für eine spätere Fehleranalyse beim Bezug den Herkunfts-Commit mit
`git rev-parse HEAD` festhalten und mit `git status --short` prüfen, ob lokale
Änderungen vorhanden sind. Den Stand von `module.yaml` und die benutzten
Build-/Trust-Manifeste ebenfalls aufbewahren. Bei ausgelieferten Binaries deren
Hash mit dem manifestierten Wert vergleichen, beispielsweise lokal mit
`Get-FileHash -Algorithm SHA256`; für CLR gelten zusätzlich die bestehenden
SHA2-512-/Trust-Regeln des jeweiligen Moduls. Diese Unterlagen bleiben lokal,
soweit sie nicht ausdrücklich öffentliche oder synthetische Inhalte sind.

Die installierte Modulversion ist bei Modulen mit entsprechender Markierung
über die vorhandenen Extended Properties auslesbar. Beispiel in der
Installationsdatenbank:

```sql
SELECT name, CONVERT(nvarchar(128), value) AS ModuleVersion
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = N'Toolbelt.Module.toolbelt.string.directional-trim.Version';
```

Diese Markierung zeigt die vom Installer hinterlegte Version, attestiert aber
keinen Herkunfts-Commit und keine Unverändertheit der installierten Objekte.
Die Metadatenverfügbarkeit ist modul- und berechtigungsabhängig. Ein später
abgefragter Checkout-Commit identifiziert keine frühere Installation. Innerhalb
derselben unveröffentlichten Modulversion können verschiedene Quellstände
existieren. Bei kopierten Quellen oder lokalen Änderungen die Herkunft und
Abweichungen selbst festhalten; unbekannte Angaben ausdrücklich als unbekannt
kennzeichnen. Es gibt keine allgemeine automatische Commitermittlung aus SQL.

Bei veröffentlichten Versionen stellt der
[Veröffentlichungsnachweis](Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md#öffentlicher-veröffentlichungsnachweis)
die Zuordnung von Modulversion, Quellcommit, Release und Asset-Hashes her.

## Freiwillige Fehlermeldungen

Wer einen Fehler melden möchte, verwendet das vorhandene
[Fehlerformular](https://github.com/gecompat/SQL_Server_Toolbelt/issues/new?template=bug-report.yml).
Hilfreich sind Modul/Objekt, Modulversion und Herkunfts-Commit oder Release-Link,
SQL-Version, Plattform, Provider, lokaler/zentraler Deployment-Modus sowie
erwartetes und beobachtetes Verhalten mit minimaler synthetischer Reproduktion.
Allgemeine Produkt-/Supportangaben genügen; keine Connection Strings, privaten
Endpoints, Originaldaten, realen Logs oder sonstigen vertraulichen Details
übernehmen. Weitere Grenzen stehen in der
[Datenschutzrichtlinie](Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md).

Eine Meldung ist freiwillig und keine Voraussetzung für Nutzung. Das Projekt
führt keine verpflichtende Nutzungsregistrierung ein. Rückmeldungen, Stars,
Forks und Downloads sind keine verlässliche Zählung von Nutzern oder
Installationen; fehlende Rückmeldungen belegen keine fehlende Nutzung.

## Templates

Die Vorlagen unter [Templates/](./Templates/) sind nicht ausführbar. Verwende immer die zum SQL-Objekttyp passende Source- und Dokumentationsvorlage.

## Sprache

Codekommentare und technische Dokumentation sind deutsch. Etablierte englische Fachbegriffe, SQL-Schlüsselwörter, Produkt-, API-, Datei-, Schema-, Objekt-, Klassen- und Parameternamen bleiben englisch.
