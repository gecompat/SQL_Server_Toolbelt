# Foundation 1.21 und begründete Testzyklen

Datum: 2026-10-09. Autor: Codex. Status: accepted im ausdrücklich beauftragten
Foundation-/Prozessscope. Andere Entwicklungswellen und die pausierte autonome
Fortsetzung bleiben geschlossen. Keine neue finale Sequenzreferenz.

## Quelle, Auswahl und semantische Integration

Quelle: [AI Repository Foundation](https://github.com/gecompat/AI_Repository_Foundation/tree/d720db4f2f0d043756a958d5195d0e62090b1c8f),
Version 1.21.0, Commit `d720db4f2f0d043756a958d5195d0e62090b1c8f`.
Ausgang: 1.20.0 aus `39ae5c534bb0cf78046485754ed1be7867bf9534`.
Die [vollständige Bewertung](FOUNDATION_1_21_ASSESSMENT.json) klassifiziert alle
sieben Kandidaten des exakten Feature-Deltas genau einmal. Alle erhalten
`APPLY_DEFAULT`; keine offene Empfehlung, Entscheidung oder Konfliktauflösung.

105 ausgewählte Manifestzeilen werden portable hashgebunden übernommen beziehungsweise
erhalten. Zehn Ziele ändern sich; AGENTS erhält ausschließlich die neue markierte
Bridge. Drei Adapter und neun optionale Capabilities aus der bisherigen
[Provenienz](../../.ai/foundation/installation-provenance.json) bleiben ausgewählt,
ohne Konfiguration/Aktivierung. Alle sieben intentionalen Overrides bleiben erhalten,
insbesondere die fünf Securitydateien samt Baselinehash, installierten Bytes und
Begründung. Die Redirectregression wird auf die exakte neue Gesamtprovenienz gebunden;
ihre Transportorakel und historischen Securitybaselines bleiben erhalten.

Kompatibilität: `COMPLEMENTARY` für die neue verpflichtende Overheadbewertung;
`PROJECT_STRONGER` für Datenschutz, SQL-Einzelfreigabe, Lab-/Cleanupgrenzen und
exakte CI; `DUPLICATE_GOVERNANCE` für pauschalen Vollaudit plus den ebenfalls
breiten Governance-Selektor. Letzterer wird im Benutzerauftrag bereinigt.
Keine geschützte Lizenz-/Attributionänderung oder historische ID-Migration.
Die kanonischen Projektquellen bleiben über AGENTS und Repo-Map erreichbar.

## Pflichtbewertung der tatsächlichen Verarbeitung

| Bereich und tatsächlicher Trigger | Vertrag/Risiko | Disposition und begrenzte Ausnahme |
|---|---|---|
| `.ai/repo_map.yaml`: Foundation-, AGENTS-, Arbeitsregel- und Entscheidungsänderungen wählten sämtliche Modulvalidatoren | Gekoppelte Verbraucher und Basisschutz | Umgesetzt: begrenzte Prozessdateien wählen ihre Pakete; Governance enthält nur Status-/Linkprüfung. Globale Fach-/Schutzverträge, Registry, Validator und unbekannte Inputs behalten Vollaudit. Diese Änderungen können alle Verbraucher oder den Selektor selbst betreffen; ein kleinerer Scope wäre ohne belegte Kopplung unsicher. |
| Dokumentationsjob: SafeCast und JSON Pointer direkt und über `validate_documentation.py` | Gleiche Source-/Generatorprüfung im identischen Checkout/Job | Umgesetzt: direkte Doppelaufrufe entfernt; Modulvalidatoren bleiben im Impactpfad und expliziten Gesamtaudit. ZIP-Files, Export-, Labargument- und Cleanupregressionen sind eigenständige Prüfungen und bleiben erhalten. |
| Veröffentlichung und API-Katalog: Werkzeug-Selbsttests bei gewöhnlichen Modulinputänderungen | Aktuelle Inputs versus negative Toolorakel | Umgesetzt: Projektinputprüfung bleibt erhalten; Selbsttests werden bei Werkzeug-/Test-/Konfigurationsänderung oder explizitem Vollaudit ausgewählt. Keine negativen Assertions entfernt. |
| 14 Workflowfilter mit `Modules/<module>/**` | SQL-/Build-/Frameworkqualifikation | Umgesetzt: ausschließlich bekannte README-, CHANGELOG-, Objekt-/Testdokumentationspfade ausgeschlossen. Positive Code-, Manifest-, Fixture-, Generator-, Adapter-, gemeinsame Abhängigkeits- und unbekannte Dateifilter bleiben erhalten. Externe Fachverträge und `workflow_dispatch` bleiben wirksam. |
| Work-Type-Workflow: jeder Anhang in `DECISIONS.md` | Work-Type-Vertrag | Umgesetzt: allgemeines Entscheidungsprotokoll aus Runtimefilter entfernt. Work-Type-Design, Source-/Test-/Manifestdateien und Workflow bleiben Trigger. Materielle Entscheidungen müssen weiterhin in die betroffenen Fachverträge/Quellen reconciled werden. |
| Phonetikworkflow: Push auf jeden Arbeitsbranch und PR desselben Commits | Doppelte gleiche Qualifikation | Umgesetzt nach tatsächlichem Remote-Befund: Push auf `main` begrenzt, PR und manueller Trigger erhalten. Keine doppelte Branch-Push-/PRqualifikation; tatsächliche Main-Integration bleibt separat geprüft. Gestartete Prüfungen bleiben erhalten. |
| Diagnose, begrenzte Integration und Modul-DoD | Supportmatrix und Statuswahrheit | Umgesetzt: Phasen ausdrücklich getrennt. Offene Qualifikationsfälle bleiben offen; ein begrenzter Fix erbt nicht alle offenen Release-/Matrixfälle als neue Testpflicht. Eine volle Qualifikationsaussage behält alle bisherigen Anforderungen. |
| Neue Commits, PR-Head und Main-Integration | Tatsächliche CI-/Frischebindung | Begründete Ausnahme: echte aktuelle CI bleibt erforderlich. Lokale Teilnachweise können nach vollständiger relevanter Bindungsprüfung anwendbar bleiben und werden nie als neu ausgeführt bezeichnet. Keine erfundene grüne Prüfung oder GitHub-Adminänderung. |
| Statische Vorprüfungen in getrennten Runtime-/Qualification-Jobs | Getrennte Runner-/Toolumgebung und Preflight vor Mutation | Begründete Ausnahme: je tatsächlich gestarteter Umgebung bleibt der günstige Preflight erhalten. Checkoutidentität allein beweist keine gleiche Tool-/Umgebungsbindung zwischen Jobs; keine neue jobübergreifende Receiptinfrastruktur. Dieselbe Prüfung im gleichen Dokumentationsjob wird dagegen dedupliziert. |
| CSV-Qualification: zweiter Build und historische Upgrade-/Lifecyclewiederholungen | Reproduzierbarkeit, genuine Vorgänger, Idempotenz und Recovery | Begründete Ausnahme: ausdrücklich unterschiedliche Orakel innerhalb einer gewählten Qualifikation; identische Source ist dabei Teil der Anforderung. Keine Änderung an Build-/Trust-, Cleanup-, Statistik- oder Lifecycleorakeln. |
| Vollogs, Receipt-/PR-Textreviews und zusätzliche Modellaufrufe | Fehler-, Skip-, Capture- und Cleanupwahrheit | Umgesetzt: vorhandene lokale Werkzeuge prüfen Exitstatus und Bindungen; nur begrenzte Befunde werden semantisch gelesen. Grüne Logs/Berichte lösen keine neue Modellreviewkette aus. Erforderliche unabhängige Fachreviews bleiben eigenständig. |
| Instruktionsadapter und Delegation | Autorität und unabhängiges Urteil | Bestehende dünne Discoveryadapter bleiben erhalten. Ein Verantwortlicher; kein neuer Agent oder Planner für diese Welle. Zusätzliche Reviews brauchen eine offene semantische Frage und stabile Inputs. Keine besondere unabhängige Freigabepflicht für diese Governanceänderung festgestellt. |
| Projektbezogene Fortsetzungsautomation | Ausdrückliche Entwicklungspause | Begründete Ausnahme: vorhandener Prompt/PAUSED-Zustand bleibt unverändert. Keine timergetriebene Arbeit oder Wiederaktivierung durch dieses Upgrade. Frühere umfangreiche Handofftexte werden nicht erneut als Runtimeautorität übernommen. |
| Kostenmessung | Ehrliche Verbrauchsaussage | Keine zuverlässige Token-/Kostenmessung für die Gesamtwelle verfügbar. Endlicher Scope: ein Upgrade-/Prozessbranch, ein Verantwortlicher, keine Delegation, keine Anschlusswelle. Vermeidbare Doppelarbeit wird sachlich benannt; keine erfundene Einsparquote oder neue Telemetrie. |

Kanonisch sind die [Test- und Validierungsrichtlinie](../Standards/TEST_AND_VALIDATION_POLICY.md)
und die [Arbeitsregeln](../../.ai/WORKING_RULES.md). CONTRIBUTING, DoD und
Kostenrichtlinie verweisen darauf. Alternativen: bloßer Versionswechsel,
pauschale Entfernung aller Vollaudits, Abschwächung der Supportmatrix,
Unterbrechung laufender mutierender Tests und neue Reader-/Review-/Receiptketten
wurden verworfen. Kein materieller Bewertungsbereich bleibt ohne Disposition.

## Validierung und Aussagegrenzen

Foundationvalidator gegen den gepinnten Source dient ausschließlich
`FOUNDATION_INTEGRITY`. Ein einmaliger vollständiger Projektaudit ist in dieser
Welle wegen Änderungen am Selektor, globaler Testpolicy und Validator erforderlich.
Er umfasst die bestehenden Securityregressionen und zehn neue Offline-Regressionen
für positive/negative Auswahl, globale/gemeinsame/unknown Inputs,
Werkzeug-Selbsttesttrennung, Doppelaufrufe und die tatsächlichen Workflowfilter.
Die eingeschränkte Globauswertung testet die im Projekt verwendete Syntax;
sie ist keine allgemeine GitHub-Engine oder remote CI-Ausführung.

Keine neue SQL-Funktion, Produktquelle, Build-/Trustbytes oder Nativefixture
wird verändert. SQL-/Lab-/Supportmatrix-/Minimalrechte-/Releasequalifikation
ist für diese Welle `not applicable`. Neue Workflowbytes erfordern nach einem
Push tatsächliche CI am exakten Head; lokale Offlineprüfungen behaupten diesen
Nachweis nicht.

Ausgeführt am 2026-10-09 unter lokalem Python 3.14:

- Source-`tools/foundation_validator.py --target <repository> --profile full`
  mit unveränderter Adapter-/Capabilityauswahl: bestanden,
  109 INFO, 5 WARNING, 0 ERROR, 0 BLOCKING. Die fünf Warnungen betreffen die
  exakt erhaltenen Securityoverrides; keine unbekannte Drift.
- `python -B Tests/Documentation/validate_documentation.py --all`: bestanden,
  44 Modulmanifeste, alle registrierten Impact-Pakete. Enthalten: zehn neue
  Selektorregressionen, acht Redirect-, neun Response-, zwölf Discovery- und
  fünf Processingtests sowie bestehende statische Modul-/Toolregressionen.
  Kein separater zusätzlicher grüner Direktlauf der neuen Tests.
- Deterministische Quellen-/Provenienz-/Assessmentprüfung: alle 105
  Installedhashes, sieben exakte Deltaklassifikationen und unveränderte Auswahl
  bestätigt. Schemafelder, zulässige Klassifikationen und Kandidatengründe
  wurden lokal gegen den exakten Schema-/Katalogstand geprüft; kein allgemeiner
  JSON-Schemavalidator eingesetzt.
- Deterministischer Vergleich der 14 Workflowdateien: alle `jobs`-Blöcke und
  bisherigen positiven Filter unverändert, mit der ausdrücklich dokumentierten
  Ausnahme des allgemeinen DECISIONS-Triggers. AGENTS außerhalb der Bridge,
  Toolbelt-Lizenz, Root-README und drei Discoveryadapter unverändert.

Der erste Gesamtaudit bleibt fehlgeschlagen: die neue Selektorregression setzte
irrtümlich auch für den bestehenden Windows-Filesystem-Build einen manuellen
Trigger voraus. Ein gezielter Diagnoseaufruf isolierte diesen Befund. Die
Regression erhält nun ausdrücklich dessen bisherigen fehlenden manuellen
Trigger; anschließend wurde der noch unerfüllte vollständige Audit bestanden.
Keine Änderung der Produkt-, Transport-, Cleanup- oder Qualificationorakel.
Nach dem grünen Audit wurden zunächst nur diese Ergebnisse dokumentiert.
Der erste Push/PR zeigte anschließend die doppelte Phonetikqualifikation am
gleichen Head durch zwei Events. Die daraufhin ergänzte Branchbegrenzung und
elfte Selektorregression wurden gezielt gegen den neuen Input geprüft;
kein erneuter lokaler grüner Vollaudit, Build oder Native-Lauf. Die aktuellen
Remote-Headprüfungen sind ein separates Pflichtgate, keine neue Modellreviewkette.
