# WORKING_RULES.md – Arbeitsregeln für Entwickler und KI-Systeme

## Preflight vor jeder Änderung

1. Scope und Schreibziel bestimmen.
2. Änderung als reine Ideen-/Research-Pflege oder als Implementierung klassifizieren.
3. Vor einer Implementierung die dokumentierte Besprechung von Zweck, Vertrag, Alternativen, Risiken und Scope sowie die anschließende ausdrückliche Benutzerfreigabe feststellen.
4. Bei reiner Ideen-/Research-Pflege sicherstellen, dass weder ein Runtime-Objekt entsteht noch eine Implementierungsfreigabe behauptet wird.
5. `AGENTS.md`, `.ai/PROJECT_RULES.md`, `.ai/WORKING_RULES.md`, relevanten Kontext, Standards und Entscheidungen lesen.
6. Bei Backlog- oder Research-Aufgaben zusätzlich `Backlog/personal_Backlog_Bainstorm.md` lesen und als nicht autoritative Hinweisquelle berücksichtigen.
7. Abhängigkeiten und parallele Arbeiten prüfen.
8. Datenschutz- und Secret-Stop-Gate durchführen.
9. Neue Anforderungen auf Regelkonflikte prüfen.

Ein Funktionskandidat, ein Design oder ein geplantes Arbeitspaket gilt nicht als Implementierungsfreigabe. Die funktionsbezogene Besprechung und die anschließende ausdrückliche Freigabe müssen vor dem Merge im Pull Request, Backlog oder Entscheidungsprotokoll nachvollziehbar dokumentiert sein.

## Ideen- und Research-Pflege

- Ideen dürfen fortlaufend erfasst, recherchiert, abgegrenzt und priorisiert werden.
- Research-Arbeit darf Primärquellen, technische Optionen, offene Fragen und eine Empfehlung dokumentieren.
- Research-Arbeit implementiert keine Capability, legt keinen öffentlichen Runtime-Vertrag endgültig fest und aktiviert kein Arbeitspaket.
- Vor einer späteren Implementierung wird jeder konkrete Funktionsvertrag einzeln mit dem Benutzer besprochen.
- Gedanken aus `Backlog/personal_Backlog_Bainstorm.md` werden gegen bestehende Kandidaten und Primärquellen geprüft, bevor daraus ein formaler Kandidat entsteht.
- Beim Überführen in eine kanonische Kandidatenliste bleibt der Originalgedanke erhalten; nach Möglichkeit wird im persönlichen Brainstorm ein Querverweis auf die neue Kandidaten-ID ergänzt.
- Bestehender Brainstorm-Inhalt wird nicht gelöscht. Überholte Aussagen werden durchgestrichen und unmittelbar mit einem datierten Änderungskommentar, Autor beziehungsweise KI-Namen, Begründung und gegebenenfalls Nachfolger-ID versehen.
- Ergänzungen in der persönlichen Datei dürfen frei formuliert sein. Verbindliche Felder, Status und Quellen werden erst in den kanonischen Kandidatenlisten normalisiert.

## Konfliktprüfung

Neue Regeln, Dateinamen, Schemas, Objektnamen und Verträge gegen folgende Quellen prüfen:

- README, `AGENTS.md`, `CONTRIBUTING.md`;
- `.ai/PROJECT_RULES.md`, `.ai/PROJECT_CONTEXT.md`;
- `Documentation/Architecture/DECISIONS.md`;
- `Documentation/Standards/`.

Keine konkurrierenden oder doppelten Regeln anlegen. Unlösbare Konflikte dokumentieren, nichts ändern und den Benutzer informieren.

## Kleinste sinnvolle Änderung

- Ein Branch und ein Pull Request behandeln einen fachlich kohärenten Scope.
- Keine unabhängigen Bereinigungen, Übersetzungen oder Formatierungsänderungen beimischen.
- Große Vorhaben in überprüfbare Wellen mit eigenen Akzeptanzkriterien zerlegen.

## Gekoppelte Pflege

Bei öffentlichen Funktionen gemeinsam prüfen und aktualisieren:

- Implementierung;
- Parameter, Defaults und Resultsets;
- Help- und Fehlervertrag;
- Beispiele und öffentliche Dokumentation;
- Modulmanifest und Lifecycle-Skripte;
- statische, Runtime- und Contract-Tests;
- Backlog, Status, Changelog und bekannte Einschränkungen.

Das Modulmanifest registriert die zugehörige Modul-, Objekt-, Architektur- und
Testdokumentation sowie die verwendeten Contract-Versionen. Neue Kopplungen
werden in `.ai/repo_map.yaml` ergänzt.

## Change-Impact-Prüfung

1. geänderte Pfade mit `git diff --name-only <base> <head>` bestimmen;
2. nur passende Impact-Pakete aus `.ai/repo_map.yaml` und deren registrierte
   Modul-Artefakte prüfen;
3. Runtime-Tests ausschließlich bei Source-, Deployment-, Runtime-Test-,
   Manifest- oder CI-Adapteränderungen starten;
4. vollständigen Audit nur für Baseline, Release, Governance- oder
   Kopplungsänderungen sowie auf ausdrücklichen Auftrag ausführen.

Eine angeforderte tokensparende oder schnelle Arbeitsweise reduziert nicht die
Prüftiefe des ermittelten Impact-Scopes.

## Branch-, Commit- und Pull-Request-Regeln

- Branch-Name beschreibt den Scope kurz und eindeutig.
- KI-generierte Commit Messages folgen der Vorgabe aus `AGENTS.md`: tatsächliches KI-System und, soweit zuverlässig ermittelbar, `LLM`, `ThinkingEffort` und `ContentSize` in eckiger Klammer vor der Zusammenfassung. Nicht ermittelbare Werte werden nicht erfunden und samt Label ausgelassen.
- Die Präfixregel gilt auch für automatisch angelegte Plan-, Initialisierungs- und Zwischencommits.
- Pull-Request-Template vollständig ausfüllen.
- Die ausführende KI erteilt sich keine eigene fachliche Freigabe. Ein ausdrücklicher Benutzerauftrag zum Merge ist eine gültige Freigabe.
- Nach erfolgreichem Merge Zielbranch prüfen und Arbeitsbranch löschen, sofern er nicht weiter benötigt wird.

## Test- und Evidenzregel

Für jede tatsächlich ausgeführte Prüfung dokumentieren:

- Befehl, Tool oder Workflow;
- geprüften Scope;
- relevante SQL-Server-Version, Plattform oder Provider;
- Ergebnis;
- Ausführungsdatum;
- bekannte Einschränkungen.

Nicht ausgeführte Prüfungen als `not executed` oder `not applicable` kennzeichnen. Ein agenteninterner Review ohne reproduzierbare Ausgabe wird nicht als CI-Nachweis dargestellt.

## Abschlussprüfung

Vor dem Merge mindestens prüfen:

1. vollständiger Branch-Diff;
2. fachliche und vertragliche Konsistenz;
3. relevante statische und verfügbare Runtime-Tests;
4. Dokumentation, Links und Repo-Map;
5. Datenschutz, Secrets und geschützte Lizenzblöcke;
6. Statuswahrheit und offene Einschränkungen;
7. keine leeren Verzeichnisse ohne erklärende Datei.

## Entscheidungen

Dauerhafte Entscheidungen in `Documentation/Architecture/DECISIONS.md` mit stabiler ID, Datum, Status, Entscheidung, Begründung, Scope, Auswirkungen, Alternativen und betroffenen Verträgen dokumentieren. Ersetzte Entscheidungen als `superseded` kennzeichnen, nicht rückwirkend umschreiben.

## Drittanbieter

Vor Aufnahme von Drittanbieterkomponenten oder Samples Lizenz, Security, Version, Wartungsstatus, Verfügbarkeit, Exit-Strategie und Auswirkungen auf öffentliche Verträge prüfen. Quelle und gegebenenfalls Prüfsumme dokumentieren.
