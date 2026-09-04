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
| Variante | Manifestierter Rules-only-Core und GitHub-Copilot-Discovery-Adapter |
| Verwendete Version | `1.8.0`, Git-Commit `7ddc29988b23570f462e46ebf527f8dfdd05fd75` |
| Prüfsumme | Kein separates Binärartefakt; die Foundation-Integritätsprüfung vergleicht die übertragenen Dateien mit dem festgelegten Quell-Checkout. Ausschließlich UTF-8-LF-/CRLF-Unterschiede gelten dabei als semantisch gleich. |
| Aufgenommen | 2026-08-23 |
| Aktualisiert | 2026-09-04 |
| Begründung | Anbieterneutrale, versionierte Governance-Baseline für Autorisierung, Sicherheit, Provenienz, Quellen, Dependencies und getrennte Validierungsebenen. |

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

Ausgewählt sind der manifestierte Core und der vorhandene GitHub-Copilot-Discovery-Adapter. Die optionalen Capabilities `artifact-registration-clients`, `artifact-registry-github` und `rule-context-cache` bleiben unselektiert.

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
