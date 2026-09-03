# ROADMAP.md – SQL Server Toolbelt

## Status

Repository-Grundaufbau, Foundation-Korrektur, Research-Wellen,
Toolbelt-Landschaftsrecherche und die bisherigen Entwicklungswellen sind
abgeschlossen. 28 Module sind implementiert. 2 sind `validated`, 26 sind
`partially validated`; 0 sind `not executed`. Die verbindlichen Einzelstatus werden aus den
jeweiligen `module.yaml`-Manifesten abgeleitet.

Alle 16 Module der V0c-Kohorte sind am 2026-08-29 auf physischen
SQL-Server-2019-, 2022- und 2025-Linux-Zielen erfolgreich gelaufen. Seit
2026-09-01 decken zusätzlich alle fünfzehn GitHub-hosted Modul-Runtime-
Workflows dieselben drei Zielversionen unter Linux ab; die früheren W5- und
File-Content-Fehler auf diesem Kanal waren Testadapterfehler und sind behoben.
Damit existiert ein von der Lab-Verfügbarkeit unabhängiger Evidenzkanal. Die
Windows-Matrix und die jeweils ausgewiesenen modulspezifischen Restfälle
bleiben offen; GitHub-hosted Windows-Runner sind dafür kein Ersatz, weil die
offiziellen Runner-Images keine SQL-Server-Engine enthalten. Ob die auf den
physischen Linux-Zielen 2019 und 2022 gemeldeten W5-Fehler dieselbe Ursache
haben, ist nicht belegt. `TC-2026-032` bleibt eine getrennte
Split-Ausbaustufe im Research-Status ohne Implementierungsfreigabe.

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
- natürlicher Savepoint-Rollback nach Enginefehler 2705 im [Lauf 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855) auf SQL Server 2019, 2022 und 2025 Linux erfolgreich;
- Windows und eine plattformübergreifend vergleichbare Performance-Baseline offen;
- Validierungsstatus deshalb `partially validated`, nicht vollständig `validated`.

Die erste Version benötigt keine persistente Tabelle, kein Synonym, keine Assembly und keinen Type. Eine Entscheidung zu diesen offenen persistenten Namenskonventionen ist deshalb noch nicht erforderlich.

## Phase 2 – Weitere Module

**Status:** `in progress`
**Abhängigkeit:** funktionsbezogene Freigabe und scopebezogen ausreichende
Validierung aller tatsächlich verwendeten gemeinsamen Verträge.

Schrittweise Umsetzung priorisierter Toolbelt-Kandidaten nach fachlicher Kategorie und Dependency-Reihenfolge.

### Phase 2.1 – Kandidatenübergreifende Objekt- und Wellenplanung

**Status:** `completed`  
**Abschluss:** 2026-07-30

Der [Implementierungsplan für Toolbelt-Kandidaten](../Backlog/TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md)
ordnet alle 46 formalen Kandidaten vorhandenen oder vorgeschlagenen Modulen,
öffentlichen Objektfamilien, Provider-Slices, Abhängigkeiten, Pflicht-Gates und
Entwicklungswellen zu. Breite Kandidaten werden vor der Entwicklung in
kleinste fachlich vollständige Arbeitspakete zerlegt. Der Plan erteilt keine
Implementierungsfreigabe und legt noch keinen öffentlichen Runtime-Vertrag fest.

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
  serielle Runtime-Matrix ausgeführt;
- vollständiger Adapter am 2026-08-29 auf physischen
  SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich;
- Windows-Prüfungen für die gezielte Releasevalidierung vorgesehen;
- SQL Server 2025 unter Linux mit Compatibility Levels 150, 160 und 170
  einschließlich RFC-4648-, Fehler-, Größen-, Deployment- und
  Lifecycle-Contracts erfolgreich;
- wegen der offenen Windows-Prüfungen
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
- vollständiger Adapter am 2026-08-29 auf physischen
  SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich;
- wegen der offenen Windows-Prüfungen
  `validation_status: partially validated`.

Stand `toolbelt.metadata.identifier`:

- vollständiger Funktionsvertrag am 2026-07-30 gemeinsam mit den drei
  nachfolgenden Modulen besprochen und ausdrücklich freigegeben;
- formaler Kandidat `TC-2026-029`, abgeschlossenes Arbeitspaket `AP-2026-010`;
- zustandsbasierter Parser und Scalar-Wrapper für ein- bis vierteilige Namen;
- Modulmanifest, Lifecycle, Dokumentation, Beispiele sowie statische und
  Runtime-Contract-Artefakte vorhanden;
- vollständiger Adapter auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen
  erfolgreich;
- Windows-Läufe offen, daher
  `validation_status: partially validated`.

Stand `toolbelt.string.split-characters`:

- freigegebener Vertrag `TC-2026-001`, abgeschlossenes Arbeitspaket `AP-2026-011`;
- Inline-TVF für mehrere einzelne literal interpretierte UTF-16-Codeeinheiten;
- Dependency auf `toolbelt.core.generate-series` Version `1.0.0`;
- Modulmanifest, Lifecycle, Dokumentation, Beispiele sowie statische und
  Runtime-Contract-Artefakte vorhanden;
- vollständiger Adapter auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen
  erfolgreich;
- Windows-Läufe offen, daher
  `validation_status: partially validated`;
- mehrzeichige Separatorstrings, Quote und Escape bleiben `TC-2026-032`.

Die freigegebene Entwicklungsfolge `AP-2026-010` bis `AP-2026-013` ist
abgeschlossen. Die breitere
Split-Version mit mehrzeichigen Separatoren, Escape und Quote ist separat als
`TC-2026-032` erfasst und nicht freigegeben.

`toolbelt.validation.semantic-version` und
`toolbelt.conversion.integer-base` sind einschließlich kanonischer inline
TVFs, SVF-Convenience-Wrappern und Lifecycle implementiert sowie auf
physischen SQL-Server-2019-/2022-/2025-Linux-Zielen teilweise validiert.

### Phase 2.2 – Portable W1

**Status:** `completed`

**Abschluss:** 2026-07-30

**Arbeitspaket:** `AP-2026-015`

Die gemeinsam besprochenen und freigegebenen Kandidaten `TC-2026-002`,
`TC-2026-008` und `TC-2026-024` sind als
`toolbelt.datetime.calendar-difference`,
`toolbelt.string.directional-trim` und
`toolbelt.conversion.uri-component` implementiert. Alle drei Module besitzen
eigene Manifeste, Lifecycle-Artefakte, Objektseiten, statische Prüfungen sowie
Runtime-, zentrale und Uninstall-Contracts.

Der finale [W1-Portable-Runtime-Lauf
30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399)
ist auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
erfolgreich. Die [Dokumentationskonsistenz
30553118014](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118014)
ist auf demselben Pull-Request-Stand erfolgreich. Der vollständige Adapter
aller drei Module war am 2026-08-29 auf physischen
SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. Windows-Läufe bleiben
gezielte Releasevalidierung.

### Phase 2.3 – W2a Compatibility-Welle

**Status:** `completed`; Runtime `partially validated`

W2a mit `TC-2026-004`, `TC-2026-005` und `TC-2026-007` wurde am 2026-07-30
ausdrücklich freigegeben und ist als drei Module implementiert. Die
SQL-Server-2025-Linux-Runtime war mit Compatibility Levels 150, 160 und 170
einschließlich Wiederholungsdeployment, Lifecycle, Central und Uninstall
erfolgreich. Die vollständigen Adapter waren am 2026-08-29 zusätzlich auf
physischen SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich.
Windows-Läufe bleiben Releasevalidierung.

### Phase 2.4 – W2b-A JSON Path Exists

**Status:** `completed`; Runtime `partially validated`

**Arbeitspaket:** `AP-2026-017`

Der Benutzer hat den empfohlenen V1-Scope am 2026-07-30 freigegeben.
`TC-2026-009` wird zunächst ausschließlich als
`toolbelt.json.path-exists` umgesetzt. Die öffentliche
`TVF_JsonPathExists` bildet die fehlerfreie `1`/`0`/SQL-`NULL`-Semantik für
Root-, Property-, Array-Index- und Wildcard-Pfade ab.

JSON-Konstruktoren bleiben ein eigener, noch nicht freigegebener Slice.
`TC-2026-013` bleibt zurückgestellt, solange die nativen Aggregate Preview
sind und kein freigegebener SQL-CLR-/Providervertrag besteht.

Der [W2b-JSON-Path-Runtime-Lauf
30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943)
ist auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170
einschließlich nativer Parität, Wiederholungsdeployment, Lifecycle, Central
und Uninstall erfolgreich. Der vollständige Adapter war am 2026-08-29
zusätzlich auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen
erfolgreich. Windows-Läufe bleiben Releasevalidierung.

### Phase 2.5 – W2c Console Message und Capability Catalog

**Status:** `completed`; Runtime `partially validated`

**Arbeitspaket:** `AP-2026-018`

Der Benutzer hat `TC-2026-016` und `TC-2026-023` am 2026-07-30 gemäß
Hauptempfehlung freigegeben. `toolbelt.core.console-message` implementiert
`toolbelt_core.USP_WriteConsoleMessage` mit 4.000-Codeunit-`PRINT`- und
2.000-Codeunit-NOWAIT-Chunks. `toolbelt.metadata.capability-catalog`
implementiert `toolbelt_metadata.VW_ModuleCapabilities` als read-only
Projektion der Database-level Modulmarker.

Source, Lifecycle, Dokumentation, Beispiele, statische und synthetische
Runtime-Contracts sind vorhanden. Die
[W2c-Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975)
ist auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170
einschließlich Langtext-/Unicode-, Marker-/Drift-, Wiederholungs-, Lifecycle-,
Central- und Uninstall-Contracts erfolgreich. Die vollständigen Adapter waren
am 2026-08-29 zusätzlich auf physischen
SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. Windows- und
modulspezifische Releasefälle bleiben offen.

### Phase 2.6 – Portable File Content

**Status:** `completed`; Runtime `partially validated`

**Arbeitspaket:** `AP-2026-024`

`toolbelt.file.content` stellt einen portablen Read-only-Vertrag für Text- und
Binärdateien über `OPENROWSET(BULK...)` und eine Root-Allowlist bereit. Der
Wartungslauf [https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356) hat SQL Server 2025 Linux mit
Compatibility Levels 150, 160 und 170 einschließlich synthetischer Fixtures,
Allowlist, Lifecycle und Uninstall erfolgreich geprüft. Windows und
nicht-ASCII-spezifische Providergrenzen bleiben Releasevalidierung.

### Phase 2.7 – ZIP Memory SQL CLR

**Status:** `completed`; Runtime `partially validated`

**Arbeitspaket:** `AP-2026-020`

`toolbelt.archive.zip-memory` Version `1.2.0` extrahiert genau einen benannten
ZIP-Entry und listet Central-Directory-Metadaten aus `varbinary(max)` über eine
`SAFE` SQL-CLR-Assembly. Extraktions- und Listingvertrag mit Methods 0 und 8,
Data Descriptor, UTF-8/CP437, eigener CRC32, Metadatenstatus, Limits,
ResultTable, Central und Uninstall wurden im Workflow
[32701896453](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453)
auf SQL Server 2019, 2022 und 2025 unter Linux erfolgreich geprüft.
Windows-SQL-Server-Runtime, reale Archive, echte Extremgrößen und ein
vollständiger Upgradepfad aus einem realen 1.1.0-Stand bleiben offen.

### Phase 2.8 – Windows Filesystem

**Status:** `in progress`; Runtime `partially validated`

**Arbeitspaket:** `AP-2026-023`

Die Windows-only Capability `toolbelt.filesystem.windows` stellt über eine `EXTERNAL_ACCESS`-SQL-CLR-Assembly Lesen/Schreiben von Text und Binary, explizite Codepages und Transcoding, Directory-Listing/Erzeugung sowie begrenztes Löschen bereit. `Caller` ist der Default; `ServiceAccount` ist eine explizite Alternative. Linux ist technisch `not applicable`.

Windows-Build, Trust, Deployment, Help, SQL-Authentication-Ablehnung und ein
kontrollierter ServiceAccount-Schreibpfad sind nachgewiesen. Caller-
Impersonation und die breitere NTFS-/I/O-Matrix bleiben manuell offen.

### Phase 2.9 – Error Envelope

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.error-envelope` standardisiert explizit aus einem CATCH
übergebene Fehlerdaten, ohne `THROW;` oder persistentes Logging zu ersetzen.
Evidence: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948.

### Phase 2.10 – Execution Context

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.execution-context` verwaltet Execution-ID, Correlation-ID,
Actor, Tenant und verschachtelten ScopeDepth über `SESSION_CONTEXT`.
Evidence: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948.

### Phase 2.11 – Work-Type-Katalog

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.work-type` registriert ausschließlich vorhandene Stored
Procedures, schließt Raw SQL aus und schützt Änderungen mit expliziten Flags
und `rowversion`. Die erste persistente Tabellenkonvention ist in
`DEC-2026-025` festgehalten.
Evidence: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193.

### Phase 2.12 – Synchrone zweite Session

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.second-session` führt registrierte Work Types synchron über
einen administrativ vorbereiteten Loopback-Linked-Server in einer getrennten
Session aus. Raw SQL und im Modul gespeicherte Credentials bleiben
ausgeschlossen. Der physische Linux-Lauf ist auf 2025 erfolgreich, scheitert
aber auf 2019/2022 im gemeinsamen W5-Vertrag; Windows-Evidenz ist offen.

### Phase 2.13 – Rollback-independent Event Log

**Status:** `completed`; Runtime `partially validated`

`toolbelt.core.event-log` persistiert strukturierte Events über die synchrone
zweite Session. Caller-Rollback und uncommittable Caller sind auf SQL Server
2025 Linux CL150/160/170 nachgewiesen. Der physische Linux-Lauf scheitert
jedoch auf 2019/2022 im gemeinsamen W5-Vertrag; Windows-Evidenz ist offen.
Evidence: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410.

## Phase 3 – Schlanke Test-Infrastruktur und CI

**Status:** `in progress`

**Abhängigkeit:** mindestens ein implementiertes Modul mit konkreten Testpfaden.

Der inkrementelle Dokumentations- und Change-Impact-Validator sowie die
capability-spezifische ResultTable-Runtime-Matrix bilden den ersten vertikalen
Slice. Weitere Module registrieren ihre gekoppelten Artefakte im Manifest und
ihre Impact-Pfade in `.ai/repo_map.yaml`. Reine Dokumentationsänderungen lösen
keine pauschale Runtime-Vollmatrix aus.

### Phase 4.1 – V0 Releasevalidierung in drei Slices

**Status:** `in progress`; am 2026-08-28 ausdrücklich freigegeben

**Aktuelles Runtime-Gate:** Der über die vorgesehenen Umgebungsvariablen
ermittelte SQL_Server_Lab-Vertrag ist schema-valide. Seit der ausdrücklichen
Benutzerfreigabe vom 2026-08-29 dürfen aus `groupStatus = INCOMPLETE`
explizit ausgewählte Einzelziele mit `runtimeStatus = READY` und geeignetem
Eintragsstatus verwendet werden. Damit ist die aktuelle Linux-Matrix für
`V0a` ausführbar; die beim SQL-Anmeldungs-Preflight nicht erreichbaren
Windows-Ziele bleiben für `V0b` `not executed`. Das Toolbelt-Projekt startet,
repariert oder löscht keine
Lab-Ressourcen selbst.

- `V0a`: alle 24 portablen beziehungsweise Linux-fähigen Module auf physischen
  SQL-Server-2019-, 2022- und 2025-Engines prüfen. Der lokale Lab-Adapter
  verwendet die vorhandenen Runtime-Suites; `toolbelt.file.content` benötigt
  separat bereitgestellte synthetische serverseitige Fixtures.
- `V0b`: die portable V0c-Kohorte vollständig auf Windows 2019, 2022 und 2025
  prüfen und die Hochrisikofälle für CLR, Filesystem, ResultTable, File
  Content, Second Session und Event Log mit synthetischen Daten und
  abstrahierter Evidenz ergänzen.
- `V0c`: eine veröffentlichungsfertige Kohorte aus den 16 Modulen
  `toolbelt.core.result-table`, `toolbelt.conversion.base64`,
  `toolbelt.core.generate-series`, `toolbelt.metadata.identifier`,
  `toolbelt.string.split-characters`, `toolbelt.validation.semantic-version`,
  `toolbelt.conversion.integer-base`, `toolbelt.datetime.calendar-difference`,
  `toolbelt.string.directional-trim`, `toolbelt.conversion.uri-component`,
  `toolbelt.datetime.truncate`, `toolbelt.datetime.bucket`,
  `toolbelt.binary.bit-operations`, `toolbelt.json.path-exists`,
  `toolbelt.core.console-message` und
  `toolbelt.metadata.capability-catalog` vorbereiten. Versionierte
  Artefakte, unterstützte Upgrades, Wiederholungsdeployment, Central und
  Uninstall gehören zum Pflichtscope. Bis zur tatsächlichen autorisierten
  Veröffentlichung bleibt `release_status: unreleased`.

V0 verändert keine öffentlichen SQL-Signaturen oder fachlichen Verträge.
Neue Q1-/D1-Runtime-Objekte bleiben außerhalb dieser Freigabe.

### Phase 4.2 – Q1 Lifecycle- und Upgrade-Automation

**Status:** `completed` für den eng begrenzten V1-Scope

Zuerst `RI-2026-142` als Migration-Idempotency-Verifier begrenzen. Golden
Snapshots und Contract-Test-Generierung folgen erst, wenn mehrere Module einen
nachweisbar gemeinsamen stabilen Vertrag besitzen.

`Q1` ist damit ein Qualitätsbaustein, aber keine neue nutzerorientierte
SQL-Capability. Parallel zu einer Nutzerfunktion darf höchstens ein solcher
Qualitäts-Enabler aktiv sein.

V1 ist als repository-interner SQLCMD-Verifier für ein isoliertes,
dependency-freies und zustandsloses T-SQL-Modul implementiert. Der effektive
Katalog wird vor und nach dem Wiederholungsdeployment verglichen; zwei
unabhängige Uninstall-Sitzungen und eine Restzustandsprüfung schließen den
Lauf ab. Die physische SQL_Server_Lab-Matrix war am 2026-08-29 auf SQL Server
2019, 2022 und 2025 jeweils unter Linux und Windows erfolgreich. Alle
synthetischen Testdatenbanken wurden entfernt; die Lab-Systeme wurden weder
gestartet noch beendet. Tabellen-/Zustands-, historische Upgrade-, Central-
und Parallelitätsslices bleiben außerhalb von V1.

### Phase 4.3 – D1 Date Spine V1

**Status:** `implemented`; Runtime `partially validated`, Release `unreleased`

`RI-2026-079` nutzt die vorhandenen Generate-Series- und Truncate-Primitiven;
Datetime Bucket ist keine künstliche Dependency. Version 1 bleibt auf drei
relationale Inline TVFs für Tag, ISO-Woche und Monat mit halboffenen Grenzen
und ohne Feiertags-, Zeitzonen- oder persistente Kalenderdimension begrenzt.

`D1` wurde als nächste eigentliche nutzerorientierte Funktionswelle gewählt. Gegenüber
JSON-Konstruktion, Regex und Work Queue besitzt sie die kleinste bereits
vorhandene Dependency-Closure, eine portable T-SQL-Basis und die begrenzteste
Provider-, Security- und Recovery-Fläche. Der Vertrag wurde am 2026-08-30
besprochen und anschließend ausdrücklich freigegeben. Der vollständige
Adapter ist auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen
erfolgreich. Die drei Windows-Ziele waren beim SQL-Anmeldungs-Preflight nicht
erreichbar und bleiben `not executed`. Feiertage, Arbeitstage, Zeitzonen,
DST, Locale-Texte, Geschäfts- und Fiskalkalender sowie persistente
Kalenderdimensionen bleiben außerhalb von V1.

### Phase 4.4 – R1 Regex V1

**Status:** `R1a research completed`; R1b `implemented`, Runtime `validated`, Release `unreleased`

R1a hat die native SQL-Server-2025-RE2-Semantik und die Provideroptionen ohne
Runtime-API geprüft. `REGEXP_INSTR` und `REGEXP_COUNT` sind auf der physischen
2025-Linux-Engine unter Compatibility 150/160/170 erfolgreich;
`REGEXP_LIKE` benötigt 170. Der .NET-Framework-4.8-Regexkern ist wegen
Semantikabweichungen und Backtracking kein Paritätsprovider. Native
RE2-Wrapper benötigen plattformspezifischen nativen Code und scheitern am
portablen `SAFE`-/Linux-Gate. Deshalb ist kein Runtime-Provider ausgewählt.

R1b verwendet nach der Benutzerentscheidung einen ausdrücklich engeren
Toolbelt-Dialekt über `SAFE` SQL CLR und stellt IsMatch, Instr und Count bereit.
Der Provider verspricht keine RE2-Parität oder lineare Laufzeit und erzwingt
Parser-, Größen- und Timeoutgrenzen. Die vollständige physische Matrix SQL
Server 2019/2022/2025 unter Windows base und Linux latest ist erfolgreich.
Replace, Substring, Split, Captures und Matches bleiben getrennte
Erweiterungen; Fuzzy Matching bleibt zurückgestellt.

### Phase 4.5 – E1 Work Queue in vertikalen Slices

**Status:** E1a und E1b `implemented`, Runtime `validated`, Release
`unreleased`; E1c und E1d benötigen weiterhin Einzelvertrag und Freigabe

Die bereits implementierten Grundlagen Work Type, Error Envelope, Execution
Context und Second Session tragen vier getrennte Slices: `E1a`
Claim/Complete/Fail, `E1b` Lease/Orphan Recovery, `E1c` Retry/Dead Letter/
Idempotenz und `E1d` kooperative Cancellation. Kein Slice autorisiert Raw SQL,
automatisches `KILL` oder einen externen Worker.

E1a umfasst als nutzbaren vertikalen Slice zusätzlich Enqueue und
Statusoberflächen. Der atomare tokengebundene Claim, Caller-Transaktionen,
Parallelität, Lifecycle und Central sind auf physischen Linux-Engines
2019/2022/2025 erfolgreich. Windows blieb im SQL-Anmeldungs-Preflight
`not executed`. E1b ergänzt eine begrenzte Lease, Heartbeat, explizite
Recovery, monotone Ownership-Generationen und ein vor aktiven E1a-Claims
geschütztes Upgrade auf 1.1.0. Die vollständige physische Matrix auf SQL Server
2019/2022/2025 unter Windows base und Linux latest ist erfolgreich. Recovery
bleibt manuell und begründet keine Exactly-once- oder Idempotenzzusage.

### Phase 4.6 – R2025 GA-Delta-Research

**Status:** `proposed research`; keine Implementierungsfreigabe

UNISTR, PRODUCT, DATEADD mit `bigint` und Vector-Scalar-Funktionen werden gegen
vorhandene Kandidaten dedupliziert und nur bei belegter Lücke formalisiert.
Vector Index/Search, Fuzzy Matching und JSON-Aggregate bleiben bis zu einer
erneuten Primärquellenprüfung ihres Previewstatus außerhalb einer
Implementierungswelle.

## Repository-Grenze

Analyse-, Diagnose-, Performance-, Konfigurations- und Security-Assessment-Ideen für `gecompat/SQL_Server_Analyze` werden nur in `Backlog/SQL_SERVER_ANALYZE_CANDIDATES.md` gesammelt und nicht hier implementiert.
