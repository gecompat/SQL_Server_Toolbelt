# ROADMAP.md – SQL Server Toolbelt

## Status

Repository-Grundaufbau, Foundation-Korrektur, zwei kandidatenbezogene
Backlog-Research-Wellen, die projektübergreifende
Toolbelt-Landschaftsrecherche und die Spezifikation des ersten Kernmoduls sind
abgeschlossen. `toolbelt.core.result-table` ist implementiert und auf
GitHub-hosted Linux für SQL Server 2019, 2022 und 2025 teilweise validiert.
Das zweite Modul `toolbelt.conversion.base64` ist implementiert und auf
SQL Server 2025 Linux teilweise validiert. Das dritte Modul
`toolbelt.core.generate-series` ist ebenfalls implementiert und auf SQL
Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise
validiert; `AP-2026-009` ist abgeschlossen. Das vierte Modul
`toolbelt.metadata.identifier` ist implementiert; seine Runtime-Evidenz steht
auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Das Modul ist wegen offener physischer 2019-/2022- und
Windows-Läufe `partially validated`.
Das fünfte Modul `toolbelt.string.split-characters` ist implementiert und auf
SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 teilweise
validiert. Die getrennte Ausbaustufe `TC-2026-032` bleibt Research ohne
Implementierungsfreigabe.
Das sechste Modul `toolbelt.validation.semantic-version` ist implementiert;
SQL Server 2025 Linux ist mit Compatibility Levels 150, 160 und 170
erfolgreich. Physische 2019-/2022- und Windows-Läufe bleiben offen.

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

## Phase 0.4 – Toolbelt-Landschaft und Prior Art

**Status:** `completed`
**Abschluss:** 2026-07-29

Enthält:

- systematische Einordnung von 16 direkten Libraries, Testframeworks, Skriptkatalogen, Diagnose-, Maintenance- und Automationsprojekten;
- vertiefte Architekturbetrachtung von SDU Tools, SQL#, T-SQL Toolbox und SQLServerSpatialTools;
- `tSQLt.NewConnection` als konkrete Prior Art für eine synchron geöffnete zweite Session;
- Vergleich von Service Broker, SQL Server Agent, tabellenbasierter Queue und externem Orchestrator als Parallelisierungsprovider;
- Packaging-, Discovery-, Versionierungs-, Test-, Lizenz-, Security- und Scope-Lehren;
- Präzisierung des vorhandenen Base64-Kandidaten `TC-2026-012` anhand der nativen SQL-Server-2025-Semantik;
- neue Kandidaten `TC-2026-023` für Runtime-Capability-Discovery und `TC-2026-024` für URI-Percent-Encoding/-Decoding;
- quellenbasierte Scope-Vorprüfung der persönlichen Brainstorm-Themen Zahlensysteme, Kompression/Archive, Datei-/Verzeichniszugriff, Anonymisierung und Objektklonen;
- Kandidaten `TC-2026-025` bis `TC-2026-028` für kontrollierte PowerShell- und Python-Provider, versionsbezogene REST-Aufrufe sowie getrennte Embedding-/KI-/Chat-Verträge;
- dokumentierte Ausschlussgrenze gegen Raw Script, beliebige Endpunkte und ungeprüfte KI-Ausgabe als ausführbaren Code;
- Screening-Liste für weitere Funktionsrecherche ohne Implementierungs- oder Kandidatenstatus.

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
- GitHub-hosted Linux: vollständige vorhandene Suite auf SQL Server 2019, 2022 und 2025 erfolgreich;
- lokale und zentrale Nutzung, Wiederholungsdeployment, Fremdobjekt-Kollision, Uninstall, explizite Collations, 1024-Spalten-Grenze, Transaktionspfade, vier parallele Sitzungen und synthetischer Performance-Workload auf allen drei Linux-Versionen erfolgreich;
- Windows, echter Savepoint-Rollback nach einem natürlichen Enginefehler und eine plattformübergreifend vergleichbare Performance-Baseline offen;
- Validierungsstatus deshalb `partially validated`, nicht vollständig `validated`.

Die erste Version benötigt keine persistente Tabelle, kein Synonym, keine Assembly und keinen Type. Eine Entscheidung zu diesen offenen persistenten Namenskonventionen ist deshalb noch nicht erforderlich.

## Phase 2 – Weitere Module

**Status:** `in progress`
**Abhängigkeit:** funktionsbezogene Freigabe und scopebezogen ausreichende
Validierung aller tatsächlich verwendeten gemeinsamen Verträge.

Schrittweise Umsetzung priorisierter Toolbelt-Kandidaten nach fachlicher Kategorie und Dependency-Reihenfolge.

Die Entscheidungsvorbereitung `AP-2026-007` ist abgeschlossen.
`TC-2026-012` (Base64/Base64URL) wurde gegenüber `TC-2026-004`
(`DATETRUNC`-Kompatibilität) ausgewählt, besprochen und zur Implementierung
freigegeben. Die Auswahlbegründung steht in
`Documentation/Research/SECOND_MODULE_SELECTION.md`; der verbindliche Vertrag
steht in `Documentation/Architecture/BASE64_MODULE_DESIGN.md`.

Der Base64-Vertrag wurde am 2026-07-29 besprochen und ausdrücklich zur
Implementierung freigegeben. `AP-2026-008` setzt ihn als unabhängiges Modul
`toolbelt.conversion.base64` um. Das Modul verwendet weder ResultTable noch
einen anderen noch unzureichend validierten gemeinsamen Runtime-Vertrag.

Das frühere pauschale Gate „mindestens ein vollständig validiertes
Referenzmodul“ wird durch `DEC-2026-021` scopebezogen präzisiert. Jedes Modul
benötigt weiterhin seine eigenen vollständigen Source-, Lifecycle-,
Dokumentations-, Contract- und Testartefakte. Verwendete gemeinsame
Infrastruktur muss für den konkret benötigten Vertrag ausreichend validiert
sein. Statuswerte dürfen nur tatsächlich ausgeführte Evidenz abbilden.

Stand `toolbelt.conversion.base64`:

- Implementierung, Manifest, Lifecycle, Dokumentation, Beispiele sowie
  statische und Runtime-Contract-Tests vorhanden;
- SQL Server 2025 mit Compatibility Levels 150, 160 und 170 als erste
  serielle Runtime-Matrix vorgesehen;
- physische SQL-Server-2019-/2022- und Windows-Prüfungen für die gezielte
  Releasevalidierung vorgesehen;
- SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
  einschließlich RFC-4648-, Fehler-, Größen-, Deployment- und
  Lifecycle-Contracts erfolgreich;
- wegen der offenen physischen 2019-/2022- und Windows-Prüfungen
  `validation_status: partially validated`.

Stand `toolbelt.core.generate-series`:

- Vertrag am 2026-07-30 besprochen und ausdrücklich freigegeben;
- zwei portable Inline TVFs für `int` und `bigint`, wobei der `int`-Wrapper
  den gemeinsamen `bigint`-Kern verwendet;
- Modulmanifest, Lifecycle, Dokumentation, Beispiele sowie statische und
  Runtime-Contract-Artefakte vorhanden;
- SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
  einschließlich Semantik, nativer Parität, Fehlern, Grenzen, einer Million
  Werten, Row Goal, Join, `CROSS APPLY`, Deployment- und Lifecycle-Contracts
  erfolgreich;
- wegen der offenen physischen 2019-/2022- und Windows-Prüfungen
  `validation_status: partially validated`.

Stand `toolbelt.metadata.identifier`:

- vollständiger Funktionsvertrag am 2026-07-30 gemeinsam mit den drei
  nachfolgenden Modulen besprochen und ausdrücklich freigegeben;
- formaler Kandidat `TC-2026-029`, aktives Arbeitspaket `AP-2026-010`;
- zustandsbasierter Parser und Scalar-Wrapper für ein- bis vierteilige Namen;
- Modulmanifest, Lifecycle, Dokumentation, Beispiele sowie statische und
  Runtime-Contract-Artefakte vorhanden;
- SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich;
- physische 2019-/2022- und Windows-Läufe offen, daher
  `validation_status: partially validated`.

Stand `toolbelt.string.split-characters`:

- freigegebener Vertrag `TC-2026-001`, aktives Arbeitspaket `AP-2026-011`;
- Inline-TVF für mehrere einzelne literal interpretierte UTF-16-Codeeinheiten;
- Dependency auf `toolbelt.core.generate-series` Version `1.0.0`;
- Modulmanifest, Lifecycle, Dokumentation, Beispiele sowie statische und
  Runtime-Contract-Artefakte vorhanden;
- SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich;
- physische 2019-/2022- und Windows-Läufe offen, daher
  `validation_status: partially validated`;
- mehrzeichige Separatorstrings, Quote und Escape bleiben `TC-2026-032`.

Freigegebene weitere Entwicklungsfolge:

1. `AP-2026-013` / `TC-2026-031` – Ganzzahlen in frei definierbaren Zahlensystemen.

`AP-2026-012` ist abgeschlossen. `AP-2026-013` ist das verbleibende
Arbeitspaket und darf ohne weitere Zwischenfreigabe begonnen werden. Die breitere
Split-Version mit mehrzeichigen Separatoren, Escape und Quote ist separat als
`TC-2026-032` erfasst und nicht freigegeben.

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
