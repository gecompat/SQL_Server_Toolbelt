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
| Verwendete Version | `1.2.0`, Git-Commit `28e0e071fef421528d106676c99234d48be08b6b` |
| Prüfsumme | Kein separates Binärartefakt; die Foundation-Integritätsprüfung vergleicht die übertragenen Dateien bytegenau mit dem festgelegten Quell-Checkout. |
| Aufgenommen | 2026-08-23 |
| Begründung | Anbieterneutrale, versionierte Governance-Baseline für Autorisierung, Sicherheit, Provenienz, Quellen, Dependencies und getrennte Validierungsebenen. |

Die Integration führt keine Runtime-Abhängigkeit und keinen externen Dienst ein. Upgrades bleiben explizit und impact-basiert; bei einem späteren Entfernen müssen Foundation-Regeln, Discovery-Brücke und zugehörige Provenienz gemeinsam konsistent behandelt werden.

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
