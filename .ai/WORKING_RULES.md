# WORKING_RULES.md – Arbeitsregeln für Entwickler und KI-Systeme

## Preflight-Checkliste (vor jeder Arbeit)

Vor der ersten Mutation einer Datei, einem Commit oder einem PR:

1. Ist der Scope klar abgegrenzt und im Arbeitspaket definiert?
2. Gibt es ein freigegebenes Arbeitspaket in `.ai/BACKLOG.md`?
3. Sind alle Abhängigkeiten erfüllt?
4. Wurden alle autoritativen Dateien gelesen (AGENTS.md, PROJECT_RULES.md, WORKING_RULES.md)?
5. Ist das Datenschutz-Stop-Gate geprüft?
6. Wurden bestehende Regeln auf Konflikte geprüft?

## Konfliktprüfung

Neue Regeln, Dateinamen, Schemas oder Objektnamen zuerst gegen folgende Quellen prüfen:
- README, AGENTS.md, CONTRIBUTING.md
- `.ai/PROJECT_RULES.md`, `.ai/PROJECT_CONTEXT.md`
- `Documentation/Architecture/DECISIONS.md`
- `Documentation/Standards/`

Keine konkurrierenden oder doppelten Regeln anlegen. Unlösbare Konflikte dokumentieren, nichts ändern, Benutzer informieren.

## Kleinste sinnvolle Änderung

- Minimaler Scope pro Branch/PR.
- Unabhängige Änderungen nicht in einem PR zusammenfassen.
- Keine spekulativen Änderungen oder Vorgriffe auf nicht freigegebene Arbeitspakete.

## Gekoppelte Pflege

Code-, Dokumentations- und Teständerungen gehören zusammen in einen PR:
- Implementierung, Doku, Tests, Backlog- und Status-Aktualisierung immer synchron.
- Kein Modul ohne vollständige Dokumentation und ausgeführte Pflichtprüfungen auf `implemented` oder `validated` setzen.

## Branch-Regeln

- Ein Branch = ein klarer Scope.
- Branch-Name beschreibt Inhalt kurz und präzise.
- Keine unabhängigen Änderungen in einem Branch/PR.

## PR-Regeln

- PR-Template ausfüllen: Scope, betroffene Verträge, Doku, Tests, Datenschutz, Lizenz.
- PR nicht selbst mergen.
- KI-generierte Commits beginnen mit `GitHub Copilot:` (oder zutreffendem KI-Namen).

## Abschlussregeln

Vor PR-Eröffnung prüfen:
1. README beginnt exakt mit dem bilingualen Lizenzhinweis.
2. LICENSE.md entspricht der Quelle; keine Open-Source-Lizenz.
3. Keine fachlichen SQL-Objekte ohne freigegebenes Arbeitspaket.
4. Alle Statusangaben wahr; nicht ausgeführte Tests als `not executed` gekennzeichnet.
5. Kein personenbezogenes Datum, kein Secret, keine Infrastrukturangabe.
6. Relative Links, Dateipfade und Repo-Map konsistent.
7. Keine leeren Verzeichnisse ohne README oder Template.

## Entscheidungen dokumentieren

Dauerhafte Architektur- und Designentscheidungen in `Documentation/Architecture/DECISIONS.md` mit:
- Stabiler ID (DEC-YYYY-NNN)
- Datum
- Status (`proposed`, `accepted`, `superseded`, `rejected`)
- Begründung
- Scope
- Auswirkungen
- Ersetzte Alternativen

## Drittanbieter

Vor Aufnahme eines Drittanbieters oder Samples: Lizenz-, Security-, Versions-, Wartungs-, Verfügbarkeits- und Exit-Prüfung. Quelle, Lizenz, Variante, Versionen und ggf. Prüfsumme dokumentieren. Keine erfundenen Kompatibilitätsangaben.

Details: [THIRD_PARTY_AND_SOURCE_POLICY.md](../Documentation/Standards/THIRD_PARTY_AND_SOURCE_POLICY.md)
