# WORKING_RULES.md – Arbeitsregeln für Entwickler und KI-Systeme

## Preflight je Scope und Änderungswelle

1. Scope und Schreibziel bestimmen.
2. Änderung als reine Ideen-/Research-Pflege oder als Implementierung klassifizieren.
3. Vor einer Implementierung die dokumentierte Besprechung von Zweck, Vertrag, Alternativen, Risiken und Scope sowie die anschließende ausdrückliche Benutzerfreigabe feststellen.
4. Bei reiner Ideen-/Research-Pflege sicherstellen, dass weder ein Runtime-Objekt entsteht noch eine Implementierungsfreigabe behauptet wird.
5. Zu Beginn einer Sitzung die native Instruktionskette bestimmen und `AGENTS.md`, Foundation-Ruleset, `.ai/PROJECT_RULES.md`, diese Arbeitsregeln und die tatsächlich betroffenen Kontext-, Standard- und Entscheidungsabschnitte erstmals lesen und analysieren. Discovery-Verweise sind keine Volllektüreliste. Vor späteren Änderungswellen aktuelle Autorität, Scope, Quellinhalt und Abhängigkeiten lokal deterministisch prüfen und die tatsächlich verfügbare Sessionanalyse nach dem folgenden Abschnitt wiederverwenden.
6. Bei Backlog- oder Research-Aufgaben zusätzlich `Backlog/personal_Backlog_Bainstorm.md` lesen und als nicht autoritative Hinweisquelle berücksichtigen.
7. Abhängigkeiten und parallele Arbeiten prüfen.
8. Datenschutz- und Secret-Stop-Gate durchführen.
9. Neue Anforderungen auf Regelkonflikte prüfen.

Ein Funktionskandidat, ein Design oder ein geplantes Arbeitspaket gilt nicht als Implementierungsfreigabe. Die funktionsbezogene Besprechung und die anschließende ausdrückliche Freigabe müssen vor dem Merge im Pull Request, Backlog oder Entscheidungsprotokoll nachvollziehbar dokumentiert sein.

## Geprüfte Sessionanalyse

Die [Processing-Regel](foundation/PROCESSING_EFFICIENCY_POLICY.md) gilt für die
Wiederverwendung in derselben Sitzung. Lokale Hash-/Git-/Discovery-Prüfungen
ermitteln die aktuellen Arbeitsbaumbytes einschließlich relevanter untracked,
staged und unstaged Dateien, die effektive native Instruktionskette und deren
Konfiguration sowie den vollständigen ausgewählten Abhängigkeitsgraphen.
Die Analyse bleibt in Sessionmemory unter dem geprüften Analysekey verfügbar;
ein Fingerprint, früherer Receipt oder Chatcheckpoint ersetzt sie nicht.
Unveränderte, korrekt gebundene Analysen werden ohne erneute Modelllektüre
verwendet. Eine geänderte Regel invalidiert sich und ihre transitiven
semantischen Verbraucher; unabhängige Analysen bleiben nutzbar. Geänderte
Instruktionsautorität, Scope oder Discovery erfordern eine neue gültige Bindung.
Ein anderer Commit oder Worktree allein löscht belegbar identische Analysen
nicht; aktuelle Bindung und inhaltliche Äquivalenz müssen geprüft sein.

Fehlende Analyse oder unvollständige Discovery erzwingt Erstlektüre im
betroffenen Scope. Unbekannte effektive Discoverywerte werden nicht geraten;
die Einschränkung wird einmal benannt und bei unverändertem Zustand nicht
erneut semantisch untersucht. Optionale persistente Cache-Nutzer erfüllen
zusätzlich [RULE_CONTEXT_CACHE_POLICY.md](foundation/RULE_CONTEXT_CACHE_POLICY.md)
mit dessen strengeren exakten Bindungen; dessen MISS wird nicht als HIT etikettiert.
Datenschutz-, Freigabe-, Lizenz- und SQL-Sicherheitsgates werden für die konkrete
Operation weiterhin angewendet, ohne deswegen unveränderte Regeltexte neu zu lesen.

## Endliche Verarbeitung und Review

Ein kohärenter Scope hat einen Implementierungsverantwortlichen. Routinearbeit
benötigt keinen neuen Planner, DAG, CI-Reader oder Receipt je Aktion.
Mechanische Hash-, Git-, Manifest-, Receipt-, CI-Status- und Textvergleichsprüfungen
erfolgen lokal deterministisch mit vorhandenen Werkzeugen. CI-Nachweise bleiben
an exakte Head-/Integrationsstände und tatsächliche Ergebnisse gebunden.

Erforderliche unabhängige Reviews bleiben erhalten. Jeder zusätzliche Review
braucht eine konkrete noch offene semantische Frage, feste Inputs und
Akzeptanzkriterien. Ein Bericht löst keinen weiteren Bericht-Review aus.
PR-Texte und Abschlussnachweise benötigen keinen eigenen Agenten, sofern keine
solche Frage oder ausdrückliche unabhängige Reviewpflicht besteht. Neue Befunde
werden am geänderten Input geprüft, nicht durch Wiederholung grüner Prüfungen.

Vor längerer autonomer Arbeit werden Scope, Budgetquelle, Checkpoint und
Abbruchgrenze gemeinsam für Root, Agenten, Koordination und Wiederholungen
festgelegt. Ohne zuverlässige Token-/Kostenmessung gilt als Projektdefault:
ein Arbeitspaket/ein PR, ein Implementierungsverantwortlicher, höchstens ein
zusätzlicher unabhängiger Reviewagent und ein Folgeauftrag an denselben Reviewer
nur für geänderte Inputs nach einem konkreten Befund. Erforderliche Prüfungen
werden nicht weggelassen; unerledigte Gates werden am Checkpoint genannt.
Keine neue Entwicklungswelle nach Abschluss. Ein begründeter größerer Scope
benötigt ein ausdrücklich festgelegtes gemeinsames Limit vor weiterer Delegation.
Unbekannte Verbräuche bleiben unbekannt, sind weder null noch gemessene Limits.

Fortsetzungsautomationen sind ein Sicherheitsnetz. Ein unveränderter
Wartezustand rechtfertigt keine Vollanalyse, neue Agenten, Testwiederholung oder
lange Historienübergabe. Ein echter Inputwait wird einmal sichtbar mit Quelle,
Auswirkung und benötigter Entscheidung gemeldet; weitere Arbeit folgt erst aus
geänderten Fakten, FINISH-Ereignissen oder einer begrenzten nötigen Prüfung.
Handoffs enthalten aktuelle Referenzen und neue Fakten statt kompletter
Chat-/Receipt-Historien. Pausierte Automationen und eine Entwicklungspause
bleiben erhalten, bis der Benutzer den betreffenden Scope ausdrücklich öffnet.

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

## CI-Ablösung und laufende Prüfungen

Runtime- und Qualification-Workflows mit mutierenden Testressourcen behalten
eine bereits laufende Prüfung (`cancel-in-progress: false`). Ein EXIT-Trap
allein beweist keine idempotente Bereinigung nach harter Unterbrechung.
Die vorhandenen Workflow-Timeouts und eigenen Cleanup-Verträge bleiben gültig;
gemeinsam genutzte Labressourcen werden nicht durch CI verwaltet.

Eine noch nicht gestartete Prüfung desselben logischen PR-Änderungssatzes
darf durch dessen vollständig ersetzenden neuen Head abgelöst werden.
Die vorhandenen Concurrency-Gruppen bleiben erhalten. Der ausschließlich
lesende Dokumentationsworkflow darf weiterhin laufende Arbeit ablösen.
Abgebrochene, abgelöste oder nicht gestartete Prüfungen sind kein PASS.
Integration erfordert die tatsächlichen Ergebnisse am exakten aktuellen Head;
nach Headänderung oder konfliktbehafteter Integration gelten frühere Erfolge
nur für ihren ursprünglichen Commit. Es wird keine Merge Queue aktiviert.

Bei Timeout, unbekanntem Cleanup oder Infrastrukturfehler bleibt die Evidenz
unvollständig. Fremde Änderungen werden nicht überschrieben; ein mutierender
Lauf wird vor abhängigen neuen Labverbrauchern reconciled. Die Foundation-
[Continuity-Regel](foundation/REPOSITORY_CONTINUITY_POLICY.md) erlaubt keine
erfundenen Statuswerte oder eigenmächtigen GitHub-Admin-/Bypassänderungen.

## Lange KI-Sitzungen

Die [Session-Regel](foundation/AI_WORK_ORCHESTRATION_POLICY.md) ergänzt die
autonome Fortsetzung über dauerhafte Repository-Quellen. Unbekannte Token-
metriken bleiben unbekannt; die heuristischen Beispielschwellen der Foundation
sind keine gewählte Projektkonfiguration. Kein periodischer Chat-Gesamtscan,
keine laufenden Summary-of-summary-Ketten und keine Rotation allein wegen
Antwortlatenz. Ein tatsächlicher Checkpoint hält nur neue, noch nicht in den
kanonischen Quellen reconciled Fakten plus Referenzen fest; Laufzeit-/Handoff-
Zustand bleibt unversioniert.

Automatische Nachfolgesitzungen werden weder aktiviert noch behauptet.
Eine konkrete Clientintegration benötigt belegte Fähigkeit und passende
Benutzerautorität. Der Einbau des optionalen Planners ist keine solche Freigabe.
Fehlende Schwellen-/Clientkonfiguration blockiert normale Projektarbeit nicht.

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
