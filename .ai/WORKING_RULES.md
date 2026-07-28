# WORKING_RULES.md – Arbeitsregeln für Entwickler und KI-Systeme

## Preflight vor jeder Änderung

1. Scope und Schreibziel bestimmen.
2. Freigegebenes Arbeitspaket oder ausdrücklichen unmittelbaren Benutzerauftrag feststellen.
3. `AGENTS.md`, `.ai/PROJECT_RULES.md`, `.ai/WORKING_RULES.md`, relevanten Kontext, Standards und Entscheidungen lesen.
4. Abhängigkeiten und parallele Arbeiten prüfen.
5. Datenschutz- und Secret-Stop-Gate durchführen.
6. Neue Anforderungen auf Regelkonflikte prüfen.

Ein unmittelbarer Benutzerauftrag gilt als Freigabe. Er muss vor dem Merge im Pull Request, Backlog oder Entscheidungsprotokoll nachvollziehbar dokumentiert sein.

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

## Branch-, Commit- und Pull-Request-Regeln

- Branch-Name beschreibt den Scope kurz und eindeutig.
- KI-generierte Commit Messages beginnen mit dem tatsächlichen KI-Namen.
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
