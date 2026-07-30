# Grobe Fokuspriorisierung der Toolbelt-Kandidaten

Stand: 2026-07-30

## Rolle und Verbindlichkeit

| Aussage | Einordnung |
|---|---|
| Aktueller Projektstand | **Dokumentiert:** 14 Module sind implementiert und `partially validated`. |
| Reihenfolge in diesem Dokument | **Einschätzung:** Grobe Arbeits- und Konzentrationshilfe, bewusst ohne Scheingenauigkeit. |
| Implementierungsfreigabe | **Abgeschlossen beziehungsweise aktiv:** Die bisher implementierten Einzelkandidaten, W1, W2a und W2b-A wurden nach ausdrücklicher Freigabe umgesetzt. Andere Rang- oder Fokusangaben autorisieren weiterhin keine Implementierung. |
| Quellen | Die `RI-`-Einträge und ihre vollständigen Source-IDs bleiben in der [Research-Inbox](./TOOLBELT_RESEARCH_INBOX.md) erhalten. Formale Kandidaten stehen in [TOOLBELT_CANDIDATES.md](./TOOLBELT_CANDIDATES.md). |

Die Liste soll die 168 Research-Ideen nicht endgültig bewerten. Sie benennt einen kleinen Arbeitsvorrat, auf den sich die nächste Vertiefung konzentrieren kann. Neue Erkenntnisse, Abhängigkeiten oder Benutzerpräferenzen dürfen die Reihenfolge jederzeit ändern.

## Bewertungsmaßstab

- **Nutzen:** Häufigkeit und Breite realistischer Anwendungsfälle.
- **Hebel:** Wiederverwendbarkeit als Grundlage für weitere Module, Tests oder sichere dynamische Verarbeitung.
- **Komplexität:** Vertragsbreite, Provider, Security, Plattformmatrix, Performance und Testaufwand gemeinsam.
- **Abhängigkeiten:** Kandidaten ohne große Vorarbeiten werden bevorzugt; Grundlagen dürfen trotz höherer Komplexität früh bleiben.
- **Repository-Fit:** Allgemeine Toolbelt-Utilities vor Diagnose-, Assessment- oder vollständigen Plattformfunktionen.

| Kürzel | Grobe Komplexität |
|---|---|
| `S` | klein und überwiegend deterministisch; begrenzter Vertrag |
| `M` | mehrere Semantik- oder Kompatibilitätsentscheidungen; normale Testmatrix |
| `L` | breiter Vertrag, mehrere Provider oder erhebliche Security-/Lifecycle-Fragen |
| `XL` | Plattform- oder Frameworkcharakter mit mehreren gekoppelten Modulen |

Die Größen sind relative Einschätzungen, keine Aufwandsschätzungen.

## F0 – Bereits eingeschlagener Pfad

| Reihenfolge | Kandidat | Komplexität | Begründung |
|---:|---|---:|---|
| 1 | `TC-2026-003` – ResultTable-Routing | `L` | Implementiertes Kernmodul; offene Windows-, Recovery- und Performancefälle bleiben eine getrennte Releasevalidierung und blockieren fachlich unabhängige Module nicht. |
| 2 | `TC-2026-012` – Base64/Base64URL | `M` | Implementiert und auf SQL Server 2025 Linux teilweise validiert; physische 2019-/2022- und Windows-Läufe bleiben Releaseaufgabe. |
| 3 | `TC-2026-006` – Zahlenreihen / `GENERATE_SERIES` | `M` | Implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170 teilweise validiert. |
| 4 | `TC-2026-029` – Identifier- und Multipart-Name-Toolkit | `M` | Implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170 teilweise validiert. |
| 5 | `TC-2026-001` – Split mit mehreren einzelnen Trennzeichen | `M` | Implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170 teilweise validiert; breitere Quote-/Escape-Stufe bleibt getrennt. |
| 6 | `TC-2026-030` – Semantic-Version Parser/Comparator | `S–M` | Implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170 teilweise validiert. |
| 7 | `TC-2026-031` – frei definierbare Zahlensysteme | `S–M` | Implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170 teilweise validiert. |
| 8 | `TC-2026-002` – kalendarische Differenz | `M` | Als W1-Modul implementiert und auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170 teilweise validiert. |
| 9 | `TC-2026-008` – Directional TRIM | `S–M` | Als W1-Modul mit getrennten `varchar`-/`nvarchar`-TVFs implementiert und teilweise validiert. |
| 10 | `TC-2026-024` – URI-Percent-Encoding | `M` | Als W1-Modul mit kanonischen inline TVFs und optionalen SVF-Wrappern implementiert und teilweise validiert. |

**Hauptempfehlung:** Die offenen Releasevalidierungen getrennt weiterführen.
Die vier freigegebenen Entwicklungsgruppen bis einschließlich W2b-A sind
umgesetzt und teilweise validiert.

## F1 – Abgeschlossene Sammelfreigaben

Die freigegebenen Kandidaten wurden in vier Gruppen umgesetzt:

| Gruppe | Kandidaten | Status | Wichtigste Scope-Grenze |
|---|---|---|---|
| Sammelfreigabe 2026-07-30 | `TC-2026-029`, `TC-2026-001`, `TC-2026-030`, `TC-2026-031` | `completed`; Runtime `partially validated` | Identifier, Split Version 1, Semantic Versioning und Integer Base bleiben getrennte Module. |
| Portable W1 | `TC-2026-002`, `TC-2026-008`, `TC-2026-024` | `completed`; Runtime `partially validated` | Calendar Difference, Directional TRIM und URI Component besitzen voneinander unabhängige Verträge. |
| Portable W2a | `TC-2026-004`, `TC-2026-005`, `TC-2026-007` | `completed`; Runtime `partially validated` | Date/Time-Typfamilien und der Bigint-Bit-Slice bleiben von späteren Typ-/Providererweiterungen getrennt. |
| Portable W2b-A | `TC-2026-009` Slice A | `completed`; Runtime `partially validated` | Nur Path Exists; Konstruktoren und Aggregate bleiben zurückgestellt. |

Die vier Sammelfreigaben vom 2026-07-30 sind vollständig abgearbeitet und
teilweise validiert.

## F1-Q – Qualitäts-Enabler parallel, aber nicht alle zugleich

| Rang | Kandidat | Komplexität | Hebel | Abhängigkeit oder Grenze |
|---:|---|---:|---|---|
| 1 | `RI-2026-138` – Contract-Test-Generator | `M–L` | Übersetzt Help-, Parameter-, Resultset-, Fehler- und KeepData-Verträge wiederverwendbar in Tests. | Erst sinnvoll, wenn der Referenzvertrag stabil und ausreichend validiert ist. |
| 2 | `RI-2026-137` – Golden-/Snapshot-Resultset-Vergleich | `M` | Wiederverwendbarer Testbaustein für viele datenorientierte Module. | Kanonisierung, Reihenfolge, Collation und tolerante Felder explizit festlegen. |
| 3 | `RI-2026-142` – Migration Idempotency Verifier | `M–L` | Schützt Deploy, Upgrade und Uninstall systematisch gegen Drift. | Benötigt synthetische Zustände und einen stabilen Lifecycle-Vertrag. |

Empfehlung: höchstens einen Qualitäts-Enabler gleichzeitig mit einem
nutzerorientierten Modul vertiefen. `RI-2026-138` wird erst formalisiert, wenn
mehrere Module einen nachweisbar gemeinsamen, stabilen Generatorvertrag
benötigen.

## F2 – Nächster Vertragsfokus

| Kandidat | Komplexität | Einordnung |
|---|---:|---|
| `RI-2026-079` – Date Spine und Kalenderdimension | `M` | Hoher Nutzen; die mögliche Generate-Series-Grundlage `TC-2026-006` ist bereits verfügbar. |
| `RI-2026-041` – JSON Pointer | `M` | Kleiner standardisierter Kern für spätere JSON-Patch-Funktionen. |
| `TC-2026-009` Slice B – JSON-Konstruktion | `M–L` | Path Exists ist als W2b-A implementiert; variable Konstruktorargumente benötigen weiterhin eine eigene Aufrufoberfläche. |
| `TC-2026-013` – JSON-Aggregate | `L` | Zurückgestellt, solange die native Funktion Preview ist und Aggregatoberfläche sowie T-SQL-/CLR-Provider offen sind. |
| `RI-2026-076` – Safe Cast mit Fehlerdetails | `M` | Nützlich für Import und Validierung; darf nicht nur `TRY_CONVERT` umbenennen. |
| `RI-2026-097` – deterministisches Hash-Sampling | `S–M` | Einfacher, reproduzierbarer Baustein für Tests und Datenreduktion. |
| `RI-2026-086` – `width_bucket` | `S–M` | Begrenzter mathematischer Vertrag und nützlich für Verteilungen. |
| `RI-2026-109` – RFC-4180-CSV Parser/Writer | `M–L` | Sehr praxisnah, jedoch wegen Streaming, Encoding und Dialekten deutlich breiter. |

## F3 – Hoher möglicher Nutzen, vorerst wegen Komplexität zurückstellen

| Kandidatenfamilie | Beispiele | Komplexität | Grund für später |
|---|---|---:|---|
| DDL- und Migrationsframework | `TC-2026-044`, `RI-2026-002` bis `RI-2026-004`, `RI-2026-010`, `RI-2026-012` | `L–XL` | Dependency-Auflösung, sichere DDL-Erzeugung, Drift und Destruktivität greifen ineinander. |
| Regex, Fuzzy Matching und vollständige Unicode-Verarbeitung | `TC-2026-010`, `TC-2026-011`, `RI-2026-021` bis `RI-2026-030` | `L–XL` | Große Semantik-, Datenversions-, Performance- und Providerfläche. |
| Breite JSON-/XML-Schemata und Patch-Systeme | `RI-2026-042` bis `RI-2026-054` | `L–XL` | Standards sind umfangreich; mehrere Funktionen bauen auf kleinen Kernen wie JSON Pointer auf. |
| Execution- und Host-Plattform | `TC-2026-014` bis `TC-2026-022`, `TC-2026-025` bis `TC-2026-028`, `TC-2026-046`, `RI-2026-143` bis `RI-2026-150` | `XL` | Security, Secrets, Queues, Recovery, externe Laufzeiten und Betriebsverantwortung. |
| Dateien, Archive, Office und analytische Bridges | `TC-2026-033` bis `TC-2026-038`, `TC-2026-045`, verbleibend `RI-2026-109` bis `RI-2026-124` | `L–XL` | Rechte, Plattformen, Streaming, Parser, Lizenzen und untrusted input. |
| Pseudonymisierung und synthetische Datensysteme | `TC-2026-039` bis `TC-2026-043`, verbleibend `RI-2026-129` bis `RI-2026-136` | `L–XL` | Datenschutzwirkung, Re-Identifikation, Referenzkonsistenz und Fehlklassifikation. |
| Probabilistische Datenstrukturen | `RI-2026-090` bis `RI-2026-095`, `RI-2026-158` | `L–XL` | Versionierte Binärformate, Merge-Verträge, Fehlergrenzen und Benchmarks. |

Zurückstellen bedeutet nicht ablehnen. Diese Themen sollten jeweils in kleinere, unabhängig testbare Kerne zerlegt werden, bevor sie formale Kandidaten oder Implementierungsarbeitspakete werden.

## F4 – Spezialnutzen oder noch unklarer Repository-Fit

- Geodaten jenseits kleiner Konvertierungen: `RI-2026-099` bis `RI-2026-106`.
- Volltext-, Template-, Diff-/Patch- und Formatierungsfamilien: `RI-2026-036` bis `RI-2026-040`, `RI-2026-141`.
- Kryptografie-nahe Authentication-Utilities wie JWT, HOTP/TOTP und HMAC: `RI-2026-064` bis `RI-2026-066`.
- Weit gedachte Frameworks wie Merkle Trees, Content-defined Chunking, Event Sourcing und Token Vault: `RI-2026-151` bis `RI-2026-162`.

Diese Ideen bleiben in der Research-Inbox erhalten. Vor einer Höherstufung sind ein konkreter Toolbelt-Anwendungsfall, die Repository-Grenze und ein deutlich kleinerer erster Slice zu klären.

## Nächste Ausführung

`AP-2026-017` hat die ausdrücklich freigegebene W2b-A umgesetzt.
`toolbelt.json.path-exists` ist implementiert und auf SQL Server 2025 Linux
mit Compatibility Levels 150, 160 und 170 teilweise validiert. Konstruktoren,
JSON-Aggregate und `TC-2026-032` bleiben ohne eigene Freigabe außerhalb dieses
abgeschlossenen Arbeitspakets.

Der [kandidatenübergreifende Implementierungsplan](./TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md)
führt `TC-2026-009` Slice A als W2b-A und `TC-2026-013` weiterhin
zurückgestellt. Diese Auswahlhilfe erteilt keine Freigabe für Konstruktoren
oder Aggregate.
