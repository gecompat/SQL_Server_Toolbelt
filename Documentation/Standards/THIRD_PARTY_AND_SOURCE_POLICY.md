# Drittanbieter- und Quellenrichtlinie

## Prüfung vor Aufnahme

Vor der Aufnahme eines Drittanbieters, einer externen Bibliothek, eines Samples oder eines Code-Snippets:

### Lizenzprüfung
- Lizenz ermitteln und dokumentieren.
- Lizenz muss mit der Attribution & Non-Commercial Redistribution License dieses Repositories kompatibel sein.
- Bei Zweifeln: Benutzer fragen, nichts aufnehmen.

### Security-Prüfung
- Bekannte Sicherheitslücken prüfen (CVE, Hersteller-Advisories).
- Prüfsumme (Hash) des verwendeten Artefakts dokumentieren, wenn relevant.

### Versions- und Wartbarkeitsprüfung
- Version dokumentieren.
- Aktiv gewartet?
- Langfristig verfügbar?

### Verfügbarkeit und Exit
- Verfügbarkeit des Quellcodes oder Binaries langfristig absichern.
- Exit-Strategie bei Wegfall des Drittanbieters dokumentieren.

## Dokumentationspflicht

Für jeden Drittanbieter oder jede externe Quelle dokumentieren:

| Feld | Inhalt |
|---|---|
| Name | Name der Bibliothek/des Samples |
| Quelle | URL oder Referenz |
| Lizenz | Lizenzbezeichnung und -version |
| Variante | Welche Variante oder Version |
| Verwendete Version | Exakte Versionsnummer |
| Prüfsumme | SHA-Hash des Artefakts (falls relevant) |
| Aufgenommen | Datum |
| Begründung | Warum diese externe Quelle? |

## Aufgenommene Governance-Quelle

| Feld | Inhalt |
|---|---|
| Name | AI Repository Foundation |
| Quelle | `https://github.com/gecompat/AI_Repository_Foundation` |
| Lizenz | MIT; vollständiger Hinweis unter `.ai/foundation/AI_REPOSITORY_FOUNDATION_NOTICE.md` |
| Variante | Vollständiger manifestierter Core, alle Discovery-Adapter und alle ohne zusätzliche Projektentscheidung anwendbaren optionalen Referenz-Capabilities; ohne Runtime-Konfiguration, Credentials oder externe Endpunkte |
| Verwendete Version | `1.17.2`, Git-Commit `36d2cb20c2880b7cfaa6428db3716e6768e23964` |
| Prüfsumme | Kein separates Binärartefakt; die Foundation-Integritätsprüfung vergleicht die übertragenen Dateien mit dem festgelegten Quell-Checkout. Ausschließlich UTF-8-LF-/CRLF-Unterschiede gelten dabei als semantisch gleich. |
| Aufgenommen | 2026-08-23 |
| Aktualisiert | 2026-09-09 |
| Begründung | Anbieterneutrale, versionierte Governance-Baseline für Autorisierung, Sicherheit, Provenienz, Quellen, Dependencies, AI-Arbeitsorchestrierung, Modellrouting und getrennte Validierungsebenen. |

Die Integration führt keine Runtime-Abhängigkeit und keinen externen Dienst ein. Upgrades bleiben explizit und impact-basiert; bei einem späteren Entfernen müssen Foundation-Regeln, Discovery-Brücke und zugehörige Provenienz gemeinsam konsistent behandelt werden.

### Upgrade-Bewertung 1.4.0 auf 1.8.0

| Feature | Klassifikation | Projektevidenz und Behandlung |
|---|---|---|
| `artifact-registration` | `PROJECT_STRONGER` | `DEC-2026-028` verbietet bereits das Erraten neuer finaler Sequenzreferenzen und verlangt vor einer neuen Referenzfamilie oder einem Allocator eine eigene Entscheidung über Registration Authority, Modus, Kollisionsschutz und Historie. Diese strengere Stop-Gate-Regel bleibt erhalten. |
| `central-artifact-registry` | `RECOMMENDED` | Das Projekt besitzt noch keine gemeinsame Registration Authority. Das zentrale JSON-v2-Profil kann bei einer späteren Auswahl die heute getrennten Planungsreferenzen kollisionssicher registrieren; Einführung oder Migration bleibt eine gesonderte Projektentscheidung. Die optionale GitHub-Capability wird nicht ausgewählt. |
| `layered-validation` | `APPLY_DEFAULT` | `FOUNDATION_INTEGRITY`, `PROJECT_SEMANTIC` und `RUNTIME_EMPIRICAL` bleiben getrennt. Die neuen Regeln zur LF-/CRLF-Äquivalenz sowie zur Unterscheidung von fachlichem Fehlschlag und nicht verfügbarer Validierungsinfrastruktur werden übernommen. |
| `repository-continuity-break-glass` | `NOT_APPLICABLE` | Zum Bewertungszeitpunkt sind für `main` weder Repository-Rulesets noch Branch Protection mit verpflichtenden Statusprüfungen nachweisbar. Es besteht daher aktuell kein durch Required Checks verursachter Verfügbarkeits-Single-Point. Bei Einführung verpflichtender externer Checks ist das Feature neu zu bewerten. |
| `rule-context-cache` | `RECOMMENDED` | Die umfangreiche transitive Governance und mehrwellige KI-Arbeit machen einen deterministischen, fail-closed Cache grundsätzlich nützlich. Policy und Schema werden als Core übernommen; die optionale Referenzimplementierung und ein lokaler Cachepfad werden ohne gesonderte Auswahl nicht eingerichtet. |
| `semantic-integration` | `APPLY_DEFAULT` | Die additive Integration bleibt erhalten; projektspezifische Regeln, Adapter-Capability und `.ai/repo_map.yaml` werden nicht ersetzt. |
| `semantic-upgrade-applicability` | `APPLY_DEFAULT` | Das vollständige Feature-Delta wurde anhand des Upstream-Katalogs am exakten Quell-Commit bewertet und hier dauerhaft dokumentiert. |

### Upgrade-Bewertung 1.8.0 auf 1.17.2

| Feature | Klassifikation | Projektevidenz und Behandlung |
|---|---|---|
| `model-routing-interoperability` | `RECOMMENDED` | Die anbieterneutrale Kosten- und Qualitätsrichtlinie ordnet bereits zu den Foundation-Tiers zu. Das aktuelle dynamische Routing ergänzt frische Evidenz, Ablaufgrenzen und attestierte Ausführung. Der Referenzrouter wird auf ausdrücklichen Auftrag mitgeführt, bleibt aber ohne Runtime-Konfiguration inaktiv. |
| `ai-work-orchestration` | `RECOMMENDED` | Das Repository wird für Entwicklung, Recherche und Dokumentation KI-unterstützt gepflegt. Die Control-Plane-Policy und Schemas ergänzen die bestehende Governance; konkrete Runtime-Auswahl und Effekte bleiben projekt- und auftragsgebunden. |
| `ai-runtime-adapters` | `RECOMMENDED` | Die Referenzadapter sind ausgewählt, um eine spätere isolierte Integration zu ermöglichen. Es werden keine Endpunkte, Credential-Referenzen, Modelle oder Remote-Verarbeitung eingerichtet; dafür wäre weiterhin eine gesonderte Entscheidung nötig. |
| `ai-work-execution` | `RECOMMENDED` | Der Executor wird als optionale Referenz übernommen. Checkpoints, Freigabequittungen und externe Effekte werden nicht konfiguriert oder autorisiert. |
| `ai-host-preparation` | `NOT_APPLICABLE` | Es besteht kein konkreter Auftrag zur Laufzeit-Provisionierung, zum Download oder zur Installation eines KI-Runtimes. Die Referenz bleibt verfügbar, aber unkonfiguriert. |
| `ai-client-integration` | `RECOMMENDED` | Codex und GitHub Copilot sind etablierte Clients; die Claude- und Gemini-Discovery-Brücken werden vollständig ergänzt. Client-spezifische Konfiguration, Prompt-Transfer und Modell-Attestierung bleiben an frische Evidenz und explizite Freigabe gebunden. |
| `central-artifact-registry` | `RECOMMENDED` | Die Materialänderung wurde geprüft. Es gibt weiterhin keine gemeinsame Registration Authority; eine Einführung oder Migration bleibt eine gesonderte Architekturentscheidung. Die GitHub-Registry-Capability wird deshalb nicht installiert, weil sie ohne zentrale Registry jeden Pull Request blockieren würde. |
| `installed-foundation-provenance` | `APPLY_DEFAULT` | Der manifestierte portable Hash- und Provenienzbeleg wird für alle ausgewählten Dateien erstellt und dient ausschließlich der Foundation-Integrität. |

Ausgewählt sind der manifestierte Core, die Adapter `github-copilot`, `claude-code` und `gemini` sowie alle derzeit anwendbaren optionalen Referenz-Capabilities. Ausgenommen bleibt ausschließlich `artifact-registry-github`, bis eine zentrale Registry durch eine eigene Architekturentscheidung ausgewählt ist. Die Auswahl aktiviert keine Runtime, keinen externen Endpoint, keine Credentials, keine Ausführung und keine Repository-Administration.

## Verbote

- Keine erfundenen Kompatibilitätsangaben.
- Keine Quellen ohne bekannte Lizenz.
- Keine Bibliotheken mit kritischen, ungepatchten Sicherheitslücken.
- Keine Samples mit personenbezogenen oder vertraulichen Daten.
- Keine Samples oder Code-Snippets ohne klare Herkunft.

## Microsoft-Beispieldatenbanken

Die folgenden Microsoft-Beispieldatenbanken sind ausdrücklich erlaubt:
- AdventureWorks
- WideWorldImporters
- Contoso (wenn öffentlich verfügbar)

Quelle und Lizenz dennoch dokumentieren.
