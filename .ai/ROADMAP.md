# ROADMAP.md – SQL Server Toolbelt

## Status

Repository-Grundaufbau, Foundation-Korrektur, zwei Backlog-Research-Wellen und die Spezifikation des ersten Kernmoduls sind abgeschlossen. `toolbelt.core.result-table` ist implementiert und auf GitHub-hosted Linux für SQL Server 2019, 2022 und 2025 teilweise validiert.

## Phase 0 – Repository-Grundaufbau

**Status:** `completed`
**Abschluss:** 2026-07-28

Enthält Root-Dateien, AI-Steuerung, Architektur- und Standardsdokumentation, Modul-Templates, Backlog-Struktur und den USP-Vertrag.

## Phase 0.1 – Foundation-Korrektur

**Status:** `completed`  
**Abschluss:** 2026-07-29

Enthält:

- korrigiertes GitHub-Copilot-Custom-Agent-Profil;
- objekttypspezifische SQL- und Dokumentations-Templates;
- vollständige USP-Contract-Testanforderungen;
- SQL Server 2025 in Support- und Testmatrizen;
- präzisierte CLR-, Linux- und `TRUSTWORTHY`-Regeln;
- vervollständigtes Entscheidungsprotokoll;
- konsolidierte Status-, Sprach- und Contribution-Regeln.

## Phase 0.2 – Backlog Research Wave 1

**Status:** `completed`  
**Abschluss:** 2026-07-29

Enthält:

- Präzisierung der bestehenden Kandidaten `TC-2026-001` und `TC-2026-002`;
- neue Kandidaten `TC-2026-003` bis `TC-2026-013`;
- versionsbezogene Abgrenzung zwischen SQL Server 2019, 2022 und 2025;
- Primärquellen, Plattformgrenzen, Performance-/Security-Fragen und konkrete nächste Schritte;
- Priorisierung der ResultTable-Infrastruktur als erstes Kernarbeitspaket.

## Phase 0.3 – Backlog Research Wave 2: Execution Infrastructure

**Status:** `completed`
**Abschluss:** 2026-07-29

Enthält:

- Kandidaten `TC-2026-014` bis `TC-2026-022`;
- transaktionsunabhängige Ereignisprotokollierung mit klarer Abgrenzung zu transactional Service-Broker-Messaging;
- asynchrone Work Queue und begrenzte Parallelisierung;
- lange beziehungsweise ungepufferte Console-Ausgabe;
- Error Envelope, Cancellation, Correlation, Retry/Dead-letter und Worker-Leases;
- sicheren Work-Type-Katalog anstelle einer ungeprüften Raw-SQL-Ausführung;
- verbindliche Trennung zwischen fortlaufender Ideenpflege und funktionsbezogener Implementierungsfreigabe.

## Phase 1 – Erstes Kernmodul

### Phase 1.1 – Implementierungsreife Spezifikation

**Status:** `completed`  
**Abschluss:** 2026-07-29  
**Arbeitspaket:** `AP-2026-002`

Ergebnis:

- Modul-ID `toolbelt.core.result-table`;
- einziges persistentes Objekt `toolbelt_core.USP_PrepareResultTable`;
- öffentliche Signatur und Modulfehlerbereich;
- Referenztabellenvertrag für Version `1.0.0`; ein sicherer `@CreateStmt`-Pfad bleibt als spätere parsergestützte Erweiterung möglich;
- normalisierte Spaltenmetadaten, Typ-Whitelist und invariant-binäre Namenssemantik;
- vollständiger `@KeepData`-, Preflight-, in-place-DDL-, Savepoint-, Transaktions- und Deployment-Vertrag;
- interne Temp-Namenskonvention `#tbx_` ohne Festlegung persistenter Tabellennamen;
- Lifecycle-, Ownership- und Berechtigungsmodell;
- vollständige statische und Runtime-Testmatrix;
- Architekturentscheidungen `DEC-2026-013` bis `DEC-2026-017`.

### Phase 1.2 – Implementierung und Validierung

**Arbeitsstatus:** `in progress`

**Implementierungsstatus:** `implemented`

**Validierungsstatus:** `partially validated`

**Release-Status:** `unreleased`
**Arbeitspaket:** `AP-2026-003`

Der Benutzer hat `toolbelt_core.USP_PrepareResultTable` am 2026-07-29 nach der ausführlichen Vertragsbesprechung ausdrücklich zum Beginn freigegeben. Diese Freigabe gilt nur für diese Funktion; weitere Kandidaten bleiben am funktionsbezogenen Gate.

Reihenfolge:

1. Funktionsvertrag, Alternativen, Risiken und Scope mit dem Benutzer besprechen;
2. ausdrückliche Implementierungsfreigabe dokumentieren;
3. Modulgerüst, Manifest, Procedure, Help und Lifecycle-Artefakte implementieren;
4. Objekt- und Moduldokumentation sowie synthetische Beispiele fertigstellen;
5. statische und Contract Tests ausführen;
6. lokale und zentrale Runtime-Tests auf SQL Server 2019, 2022 und 2025 durchführen;
7. Windows und Linux getrennt validieren, soweit geeignete Runner vorhanden sind;
8. Collation-, Fehler-, Recovery- und Performance-Tests dokumentieren;
9. `implemented` nach vollständigem Code und statischem Vertrag, `validated` ausschließlich nach tatsächlicher Runtime-Evidenz vergeben.

Stand:

- Schritte 1 bis 5 abgeschlossen;
- Source, Manifest, Lifecycle, Dokumentation, Beispiele sowie statische und synthetische Contract-Testartefakte vorhanden;
- reproduzierbare statische Vertragsprüfung erfolgreich;
- GitHub-hosted Linux: SQL Server 2019 mit vorhandener Vollsuite und SQL Server 2022/2025 mit Kompatibilitätssuiten erfolgreich;
- lokale und zentrale Nutzung, Wiederholungsdeployment, Fremdobjekt-Kollision und Uninstall im 2019-Lauf erfolgreich;
- Windows und noch nicht automatisierte Collation-, Grenz-, Recovery- und Performancefälle offen;
- Validierungsstatus deshalb `partially validated`, nicht vollständig `validated`.

Die erste Version benötigt keine persistente Tabelle, kein Synonym, keine Assembly und keinen Type. Eine Entscheidung zu diesen offenen persistenten Namenskonventionen ist deshalb noch nicht erforderlich.

## Phase 2 – Weitere Module

**Status:** `proposed`  
**Abhängigkeit:** mindestens ein validiertes Referenzmodul.

Schrittweise Umsetzung priorisierter Toolbelt-Kandidaten nach fachlicher Kategorie und Dependency-Reihenfolge.

## Phase 3 – Schlanke Test-Infrastruktur und CI

**Status:** `in progress`

**Abhängigkeit:** mindestens ein implementiertes Modul mit konkreten Testpfaden.

Der inkrementelle Dokumentations- und Change-Impact-Validator sowie die
capability-spezifische ResultTable-Runtime-Matrix bilden den ersten vertikalen
Slice. Weitere Module registrieren ihre gekoppelten Artefakte im Manifest und
ihre Impact-Pfade in `.ai/repo_map.yaml`. Reine Dokumentationsänderungen lösen
keine pauschale Runtime-Vollmatrix aus.

## Repository-Grenze

Analyse-, Diagnose-, Performance-, Konfigurations- und Security-Assessment-Ideen für `gecompat/SQL_Server_Analyze` werden nur in `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` gesammelt und nicht hier implementiert.
