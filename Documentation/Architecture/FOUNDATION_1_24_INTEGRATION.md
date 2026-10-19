# Foundation 1.24.0: semantisches Upgrade

Stand: 2026-10-20. Scope: ausdrücklich beauftragtes Foundation-Upgrade; vorhandene Facharbeit, Pausen und Runtimefreigaben bleiben unverändert.

## Quelle und vollständige Bewertung

Die Quelle ist [Foundation 1.24.0](https://github.com/gecompat/AI_Repository_Foundation/tree/96391403a1b89e19d4824838806d7190d8033389) am exakten Commit `96391403a1b89e19d4824838806d7190d8033389`. Ausgang ist die installierte Version 1.21.0 aus `d720db4f2f0d043756a958d5195d0e62090b1c8f`. Die [maschinenlesbare Bewertung](FOUNDATION_1_24_ASSESSMENT.json) erfasst alle neun eingeführten oder materiell geänderten Features genau einmal. Historische Bewertungen und Kennungen werden erhalten.

| Feature | Bewertung |
|---|---|
| `ai-runtime-adapters` | `PROJECT_STRONGER` |
| `ai-work-execution` | `RECOMMENDED` |
| `ai-work-orchestration` | `APPLY_DEFAULT` |
| `bounded-processing-efficiency` | `APPLY_DEFAULT` |
| `foundation-baseline` | `APPLY_DEFAULT` |
| `layered-validation` | `APPLY_DEFAULT` |
| `orchestrator-job-control` | `DECISION_REQUIRED` |
| `session-lifecycle-management` | `RECOMMENDED` |
| `test-evidence-reuse` | `RECOMMENDED` |

`RECOMMENDED` bezeichnet eine mögliche Nutzung unter den bestehenden Projektgates. `DECISION_REQUIRED` betrifft ausschließlich eine künftige Aktivierung autonomer Hoststeuerung; sie bleibt für dieses Upgrade ausdrücklich ausgeschaltet. Eine neue Anwendung von Local-to-Remote-Reuse benötigt einen geschützten Producer und Verifikator sowie passende Input-, Runtime-, Freshness-, Oracle- und Cleanupnachweise. Ohne diese Grundlage bleibt der vorhandene Test-/CI-Weg erforderlich. Keine Aktivierung wird aus dem Versionswechsel abgeleitet.

## Erhaltene Projektverträge und Transfer

Die bisherigen 3 Adapter und 9 Capabilities bleiben ausgewählt. Alle 112 ausgewählten Ziele sind im erneuerten Installationsreceipt mit portablem Quell- und Zielhash erfasst. Nur Manifestziele werden übertragen; Projekt-README, Lizenz, Backlog, Status und Identitätsregistry der Foundationquelle werden nicht kopiert. Die Root-Bridge wird innerhalb ihrer Marker aktualisiert. Projektgeführte Discovery, Datenschutzverschärfungen, SQL-/Demo-/Providerverträge, geschützte Lizenztexte und historische IDs bleiben erhalten. Neue Host-, Provider-, Modell-, Netzwerk-, Credential-, Budget- oder GitHub-Adminrechte werden nicht eingerichtet.

Semantisch bleiben strengere Datenschutz-, Freigabe-, Cleanup- und frische CI-Gates `PROJECT_STRONGER`; Sprache, ausgewählte Capabilities und Commitkennzeichnung bleiben `PROJECT_SELECTABLE_OVERRIDE`. Die neuen portablen Verträge sind `COMPLEMENTARY`. Es besteht kein ungelöster Required-Konflikt. Runtime- und native SQL-Abnahmen werden durch die Foundationprüfung nicht bestätigt.

## Erforderliche Bewertung des Verarbeitungsaufwands

| Tatsächlicher Weg | Disposition und Schutzgrund |
|---|---|
| Projekt-Testselektion und Workflows | Die vorhandenen konservativen Selektoren und erforderlichen aktuellen Checks bleiben maßgeblich. Foundation-/Regelprüfungen werden vor fachlich betroffenen SQL-Läufen gewählt. Unbekannte Abhängigkeit bleibt ein breiterer Fallback. Keine Matrix oder Oracle wird zur Einsparung entfernt. |
| Optionale ausführbare Referenzen | Nur bereits ausgewählte Capabilities werden aktualisiert. Synthetische lokale Verträge prüfen die betroffenen Datei-/Transport-/Provenienzgrenzen; Live-Provider und automatische Fortsetzung bleiben unkonfiguriert. |
| Logs und Erfolgsbewertung | Bestehende lokale Runner werten Status und begrenzte Findings aus. Rohlogs bleiben lokal; vollständiger Erfolg benötigt keinen zusätzlichen Modellaufruf zur bloßen Bestätigung. Unbekannte Messwerte bleiben unbekannt. |
| Reviews, Modelle und Budget | Ein Implementierungsverantwortlicher bearbeitet die vier ausdrücklich benannten Repository-Upgrades mit je einem kohärenten PR. Zusätzliche Reviews benötigen einen konkreten Befund. Es gibt keine neue Reviewkette, Telemetrie oder behauptete monetäre Budgetdurchsetzung. |
| Warten, Pausen und Aktivierung | Bestehende Pausen und laufende unabhängige PRs bleiben erhalten. Kein Scheduler oder Heartbeat wird eingerichtet. Zustandsabfragen verwenden begrenztes Backoff; unveränderte Blocker lösen keine neue semantische Analyse aus. |

## Validierung und Grenzen

Am 2026-10-20 lokal unter Windows/Python: `foundation_validator.py --profile full` mit der erhaltenen Auswahl: PASS ohne Fehler; die acht Code-/Guide-Abweichungen gegenüber der Quelle sind erklärte Projektverschärfungen. `Tests/Documentation/validate_documentation.py --base <Upgradebasis> --head <geprüfter Git-Tree>`: PASS; der konservative Selektor verlangte einen vollständigen Audit. Darin bestehen Provenienz-/Redirecttests (204 Transportszenarien, 112 Dateien), HTTP-Response (111 Szenarien), Discovery (266 Szenarien), Budget-, Security- und übrige statische Verträge. Die Handle-Suite besteht mit 13 Tests, davon zwei plattformbedingt übersprungenen POSIX-Fällen; Windows-Junction-/Handleprüfungen und die neue Stdio-Sperre werden ausgeführt. `ai_orchestrator/control.example.py`: PASS als ausschließlich synthetischer Offline-Roundtrip ohne Modellaufrufe. Der relative Control-Schema-Link im installierten Orchestratorguide ist gezielt an das Installationslayout angepasst und als Override erfasst. README, Lizenz und projektgeführte Arbeits-/Fachregeln sind inhaltlich unverändert.

Native SQL-/Lab-, Provider-, Trust-, Remote-Evidence- und reale Modellabnahmen bleiben `not executed`, weil das Upgrade keine entsprechende Aktivierung oder fachliche SQL-Änderung vornimmt. Erforderliche bestehende Projektgates bleiben erhalten. Remote-PR-CI ist bei Erstellung dieses lokalen Nachweises noch ausstehend und wird vor dem Merge am aktuellen Head geprüft.

## Toolbelt-Sicherheitsabweichungen

SC-010 (gehaltene sichere Datei-Handles), SC-030 (exakte Budgetgrenzen) und SC-034 (explizite Remoteautorität) bleiben erhalten. Die vorhandenen Redirect-, HTTP-Response- und Discovery-Grenzen bleiben in ihren gekoppelten Tests gebunden. Neue Stdio-Nutzdateninvocation ist `TOOLBELT_STDIO_INVOKE_UNAVAILABLE`, bevor ein Pfad geöffnet oder ein Prozess aufgerufen wird. Eine spätere Freigabe erfordert einen separat abgesicherten gepinnten Handletransport und eigene positive sowie negative Race-/Protokolltests; Probe/Katalog ist keine solche Abnahme.
