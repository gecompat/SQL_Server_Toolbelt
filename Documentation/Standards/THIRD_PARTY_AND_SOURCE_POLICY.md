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
