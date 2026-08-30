# CHANGELOG

## 2026-08-24 – ZIP-Metadaten-Listing und Statuswahrheit

- `toolbelt.archive.zip-memory` Version `1.2.0` stellt die neue
  Listing-API samt internem CLR-TVF, Lifecycle, Help, ResultTable,
  Local-/Central- und Struktur-/Encoding-/Pfadverträgen.
- Windows-.NET-Framework-4.8-Build und SQL-Server-2019-/2022-/2025-Linux-
  Runtime für Extraktion und Listing sind im
  [GitHub-Actions-Lauf 32701896453](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453)
  erfolgreich; Windows-Runtime und echte Extremgrößen bleiben offen.
- Aggregierte Manifeststatus, Kandidatenplan und Roadmap sind konsolidiert;
  doppelte AP-/Phasenabschnitte entfernt und zukünftige Wellen mit expliziten
  Freigabegates verankert.
- Der Dokumentationsvalidator prüft abgeleitete AP-Status lokal im jeweiligen
  Abschnitt, Manifestaggregate und eindeutige Planungs-IDs.

## 2026-08-05 – W5b Event Log

- `toolbelt.core.second-session` auf Version `1.1.0` mit `@SuppressResult` erweitert.
- `toolbelt.core.event-log` Version `1.0.0` implementiert: rollback-unabhängiger Writer, Event-View, begrenzte Retention und sauberer Work-Type-Lifecycle.
- SQL Server 2025 Linux CL150/160/170 einschließlich Rollback, uncommittable Caller, Concurrency, Central und Uninstall erfolgreich.

## 2026-08-05 – Work-Type-Katalog 1.1.0

- `toolbelt.core.work-type` um `toolbelt_core.USP_RemoveWorkType` erweitert.
- Entfernung ist nur nach Disable, mit `@AllowDelete = 1` und optionaler `rowversion`-Prüfung zulässig.
- Savepoint-, uncommittable-Caller-, ResultTable- und Lifecycle-Verträge werden capabilitybezogen getestet.

## 2026-08-04 – W5a Second Session

- `toolbelt.core.second-session` Version `1.0.0` implementiert.
- Registrierte Work-Types laufen synchron über einen administrativ vorbereiteten
  Loopback-Linked-Server in einer getrennten SQL-Server-Session; Raw SQL und
  im Modul gespeicherte Credentials bleiben ausgeschlossen.
- SQL-Server-2025-Linux-Loopback-Spike ist erfolgreich; physische SQL-Server-
  2019-/2022- und Windows-Läufe bleiben `not executed`.

## 2026-08-01 – W4b Work-Type-Katalog

- `toolbelt.core.work-type` Version `1.0.0` implementiert.
- Persistente Tabelle `toolbelt_core.WorkType` mit expliziten Constraint-/Indexnamen und `rowversion`.
- Register, Disable, Resolve, View, ResultTable, Concurrency, Redeploy, Central und Data-Loss-Uninstall-Schutz.
- `DEC-2026-025` schließt die Tabellen-/Constraint-/Index-Namenskonvention.
- SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich: https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193.

Alle wesentlichen Änderungen an SQL Server Toolbelt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

## [Unreleased]

### Hinzugefügt

- `toolbelt.string.regex` Version `1.0.0` implementiert den ausdrücklich
  freigegebenen R1b-Slice mit `SVF_RegexIsMatch`, `SVF_RegexInstr` und
  `SVF_RegexCount`. Ein eigener Parser begrenzt den Toolbelt-Dialekt; Input,
  Pattern, Quantifier und Laufzeit besitzen feste Grenzen. Die identische
  .NET-Framework-4.8-Assembly läuft als `SAFE` SQL CLR ohne Drittanbieter-
  oder Native-Abhängigkeit und wird ausschließlich per exaktem SHA2-512-Hash
  autorisiert. Die vollständige physische Matrix SQL Server 2019/2022/2025
  unter Windows base und Linux latest ist erfolgreich; das Modul ist
  `validated` und `unreleased`. RE2-Parität, lineare Laufzeit, Replace,
  Substring, Captures, Split und Matches werden nicht zugesagt.

- `toolbelt.core.work-queue` Version `1.1.0` ergänzt den E1a-Kern um den
  ausdrücklich freigegebenen E1b-Slice: begrenzte Claim-Lease, monotone
  Generation, tokengebundener Heartbeat, explizite Batch-Recovery und
  aktive-Lease-Prüfung für Complete/Fail. Das echte Upgrade `1.0.0 → 1.1.0`
  erhält QUEUED-/terminale Daten und blockiert bei aktiven Alt-Claims vor der
  ersten Mutation. Der erste vollständige E1b-Lauf auf SQL Server 2025 Linux
  war erfolgreich; anschließend bestand die vollständige physische Matrix
  SQL Server 2019/2022/2025 unter Windows base und Linux latest. Das Modul ist
  `validated`. Retry/Dead Letter/Idempotenz, Cancellation und Worker
  bleiben getrennte Slices; das Modul bleibt `unreleased`.

- `toolbelt.datetime.date-spine` Version `1.0.0` mit drei portablen Inline
  TVFs für Tages-, ISO-Wochen- und Monatsperioden eines halboffenen
  `date`-Bereichs. Die vollständige Linux-Matrix auf SQL Server 2019, 2022 und
  2025 ist erfolgreich; Windows blieb wegen nicht erreichbarer SQL-
  Anmeldungs-Preflights `not executed`. Das Modul bleibt `unreleased`.

- Q1 Migration-Idempotency-Verifier für isolierte dependency-freie,
  zustandslose T-SQL-Module. V1 vergleicht den effektiven Katalog vor und nach
  einem Wiederholungsdeployment und prüft zwei unabhängige Uninstalls samt
  leerem Restzustand. Die physische SQL-Server-2019-/2022-/2025-Matrix ist auf
  Linux und Windows erfolgreich; alle synthetischen Testdatenbanken wurden
  anschließend entfernt.

- Windows-only Modul `toolbelt.filesystem.windows` mit EXTERNAL_ACCESS-SQL-CLR-Fassade für begrenztes Text-/Binary-I/O, explizite Codepages und Transcoding, Directory-Operationen und begrenztes rekursives Löschen. `Caller` ist der Default, `ServiceAccount` explizit; Build, Trust, Deployment, Help, SQL-Authentication-Ablehnung und kontrolliertes ServiceAccount-Schreiben sind validiert, die breitere Caller-/NTFS-/I/O-Matrix bleibt offen.

- `toolbelt.archive.zip-memory` ergänzt den ZIP-Metadaten-Pfad (TC-2026-033) im CLR-Provider inklusive Testhärtung für nicht-ASCII-Entry-Namen (`Grüße.txt` als Unicode-Konkatenausdruck). Version `1.2.0` stellt ihn über `USP_ListZipEntriesFromBinary` bereit; die vollständige Linux-SQL-Runtime-Matrix ist erfolgreich.

- W2c mit `toolbelt.core.console-message` für Unicode-sichere lange
  `PRINT`-/`RAISERROR ... WITH NOWAIT`-Messages und
  `toolbelt.metadata.capability-catalog` für eine read-only Projektion
  gültiger, unvollständiger oder ungültiger Database-level Modulmarker.
  Source, Lifecycle, Central-, Contract-, Dokumentations- und
  Runtime-Artefakte sind vorhanden. SQL Server 2025 Linux ist mit
  Compatibility Levels 150, 160 und 170 einschließlich Langtext-/Unicode-,
  Marker-/Drift-, Wiederholungs-, Lifecycle-, Central- und
  Uninstall-Contracts erfolgreich; beide Module sind `partially validated`.
- W2b-A mit `toolbelt.json.path-exists`: fehlerfreie SQL/JSON-Pfadprüfung
  für SQL Server 2019+ mit Root-, Property-, Array-Index-, Quote- und
  Wildcard-Semantik, gekoppelte Lifecycle-, Central-, Contract-,
  Dokumentations- und Runtime-Artefakte. SQL Server 2025 Linux ist mit
  Compatibility Levels 150, 160 und 170 einschließlich nativer Parität,
  Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich;
  Konstruktoren und JSON-Aggregate bleiben getrennt zurückgestellt.
- W2a mit typgetrennten Date/Time-Truncation- und Bucket-Inline-TVFs sowie
  Bigint-Shift-, Bit-Count-, Get-Bit- und Set-Bit-Funktionen. Die drei Module
  besitzen gekoppelte Lifecycle-, Central-, Contract-, Dokumentations- und
  Runtime-Artefakte. SQL Server 2025 Linux ist mit Compatibility Levels 150,
  160 und 170 einschließlich Wiederholungsdeployment, Lifecycle, Central und
  Uninstall erfolgreich; der Status ist `partially validated`.
- Sechs semantisch äquivalente inline-TVF-APIs für Base64, Integer-Base und
  Semantic Versioning als kanonische relationale Kerne für `CROSS APPLY` und
  `OUTER APPLY`; die vorhandenen SVFs bleiben Convenience-Wrapper.
- Kandidatenübergreifender Implementierungsplan für alle 46 Toolbelt-Kandidaten mit vorhandenen beziehungsweise vorgeschlagenen Modulen, öffentlichen Objektfamilien, Provider-Slices, Abhängigkeiten, Pflicht-Gates, Testschwerpunkten und Entwicklungswellen; ohne neue Implementierungsfreigabe.
- Formale Kandidaten `TC-2026-033` bis `TC-2026-046` für ZIP-/Kompressionsprovider, kontrollierte Datei-/Verzeichniszugriffe, getrennte Pseudonymisierungsbausteine, Objektklonen, XLSX-Lesen und eine providerneutrale Second-Session-Abstraktion; alle ohne Implementierungsfreigabe im Status `researched`.
- Deduplizierte Toolbelt-Research-Inbox mit 168 breit gefächerten Ideen und 92 öffentlichen Quellen; Mehrfachnennungen behalten ihre gemeinsamen Fundstellen; Funktionsideen aus dem Projektchat „SQL Server Toolbelt Planung“ zu Session Context, Sequence-Ranges, Schema-Introspektion, sicheren Dynamic-SQL-Primitiven, Resultset-Rendering und Temporal Queries sind nachgetragen.
- Repository-Grundaufbau mit autoritativen Steuerungsdateien, Architektur, Standards, Templates und Backlogs.
- Verbindlicher USP-Vertrag und SQL-Objekt-Namenskonventionen.
- GitHub-Copilot-Custom-Agent für die Backlog-Pflege.
- Erste evidence-basierte Backlog-Research-Welle mit den Kandidaten `TC-2026-001` bis `TC-2026-013`.
- Versionsbezogene Compatibility-Kandidaten für SQL Server 2019, 2022 und 2025 in den Bereichen Core, String, Datetime, JSON, Binary und Conversion.
- Implementierungsreife Spezifikation des ersten Kernmoduls `toolbelt.core.result-table`.
- Verbindliche ResultTable-Contract-Testmatrix für Help, Schema, `@KeepData`, DDL, Transaktionen, Collation, Deployment und Plattformen.
- Architekturentscheidungen `DEC-2026-013` bis `DEC-2026-017` für Modulscope, Schemaquelle, in-place-Umbau, Transaktionsvertrag und interne Temp-Namen.
- Folgearbeitspaket `AP-2026-003` für Implementierung und Validierung des ResultTable-Kernmoduls.
- Zweite Research-Welle mit den Execution-Infrastructure-Kandidaten `TC-2026-014` bis `TC-2026-022`.
- Kandidaten für transaktionsunabhängiges Logging, begrenzte Parallelisierung, Console-Ausgabe, Error Envelope, Cancellation, Correlation, Retry/Dead-letter, Worker-Leases und einen sicheren Work-Type-Katalog.
- Erstimplementierung von `toolbelt_core.USP_PrepareResultTable` mit Help-, Referenztabellen-, Typ-, Collation-, `@KeepData`-, Preflight-, in-place-DDL-, Debug-, Fehler- und Savepoint-Vertrag.
- Modulmanifest, parametergesteuertes Deploy- und Uninstall-Skript, Objekt- und Moduldokumentation, synthetisches Beispiel sowie statische und synthetische Contract-Testartefakte für `toolbelt.core.result-table`.
- Architekturentscheidung `DEC-2026-019` für gemeinsame Deployments, Release-Manifeste und kurze Mutationstransaktionen.
- GitHub-hosted Linux-Validierung für SQL Server 2019, 2022 und 2025.
- Manifestzentrierte Modulregistry mit gekoppelten Dokumentationspfaden und Contract-Versionen.
- Inkrementeller Dokumentations- und Change-Impact-Validator ohne externe Python-Abhängigkeiten.
- Eigener GitHub-Actions-Workflow für diff-basierte Dokumentationskonsistenz.
- Architekturentscheidung `DEC-2026-020` zur Status- und Change-Impact-Steuerung.
- Projektübergreifende Toolbelt-Landschaftsrecherche mit 16 direkten Libraries, Frameworks, Skriptkatalogen, Diagnose-, Maintenance- und Automationsprojekten.
- Prior-Art-Vergleich für zweite Sessions und Parallelisierungsprovider sowie Architekturfolgen für Packaging, Discovery, Versionierung, Tests, Lizenzierung, Security und Repository-Grenzen.
- Kandidaten `TC-2026-023` für einen abfragbaren Capability-/Versionskatalog und `TC-2026-024` für URI-Percent-Encoding/-Decoding.
- Quellenbasierte Vorprüfung der persönlichen Brainstorm-Themen Zahlensysteme, Kompression/Archive, Datei-/Verzeichniszugriff, Anonymisierung und Objektklonen.
- Kandidaten `TC-2026-025` bis `TC-2026-028` für kontrollierte PowerShell-Host-Automation, Python-Provider, versionsbezogene REST-/Web-Requests und getrennte KI-/Chat-Capabilities.
- ResultTable-Contract-Tests für explizite Collations, das 1024-Spalten-Limit, Caller-/uncommittable-Transaktionen und einen reproduzierbaren synthetischen Performance-Workload.
- Entscheidungsvorlage für das zweite Modul mit einem vertieften Vergleich von `TC-2026-004` und `TC-2026-012`, offenen Vertragsfragen, Provideroptionen, Testdimensionen und expliziten Implementierungs-Gates.
- ResultTable-Multi-Session-Contract für vier parallele Sitzungen mit identischen logischen Temp-Tabellennamen.
- Modul `toolbelt.conversion.base64` mit portablen Scalar UDFs für Base64- und Base64URL-Encoding/-Decoding.
- Parametergesteuertes lokales und zentrales Base64-Deployment, Uninstall, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Lifecycle- und Größenprüfungen.
- Serieller SQL-Server-2025-Linux-Workflow für Compatibility Levels 150, 160 und 170.
- Architekturentscheidung `DEC-2026-021` für scopebezogene Qualitäts-Gates unabhängiger Module.
- Erfolgreiche Base64-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich RFC-4648-, Fehler-, Größen-, Deployment- und Lifecycle-Contracts.
- Modul `toolbelt.core.generate-series` mit portablen Inline TVFs für `int`- und `bigint`-Zahlenreihen.
- Gemeinsamer `bigint`-Kern mit konstanten binär gestapelten Rowsets, zeilenzahlgesteuertem Row Goal und überlaufsicherer interner `decimal(38,0)`-Arithmetik.
- Parametergesteuertes lokales und zentrales Generate-Series-Deployment, Uninstall, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Lifecycle-, Grenz- und Größenprüfungen.
- Serieller SQL-Server-2025-Linux-Workflow für Generate-Series unter Compatibility Levels 150, 160 und 170.
- Erfolgreiche Generate-Series-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Semantik, nativer Parität, Fehlern, Grenzen, einer Million Werte, Row Goal, Join, `CROSS APPLY`, Deployment- und Lifecycle-Contracts.
- Formale Kandidaten `TC-2026-029` bis `TC-2026-031` für sicheres Identifier-Handling, Semantic Versioning und frei definierbare Zahlensysteme.
- Getrennte Split-Ausbaustufe `TC-2026-032` für mehrzeichige Separatoren, Escape und Quote.
- Modul `toolbelt.metadata.identifier` mit zustandsbasiertem Multipart-Parser und kanonischem Quote-Wrapper.
- Unterstützung für ein- bis vierteilige Namen, `[...]`, `]]`-Escapes, ausgelassene mittlere Teile und stabile abstrakte Validation Codes.
- Parametergesteuertes lokales und zentrales Identifier-Deployment, Uninstall, Objekt-/Moduldokumentation sowie statische, Contract-, Collation- und Lifecycle-Prüfungen.
- Modul `toolbelt.string.split-characters` mit literalem Multi-Separator-Vertrag, stabilen Ordinals und definierter Leer-Token-Semantik.
- Binärer Separatorvergleich, `nvarchar(max)`-Verarbeitung, Generate-Series-Dependency sowie lokales/zentrales Deployment und vollständige Lifecycle-Artefakte.

### Geändert

- R1a dokumentiert und reproduziert die native SQL-Server-2025-RE2-Semantik
  für einen möglichen `LIKE`-/`INSTR`-/`COUNT`-Slice. Der Spike nimmt keine
  Dependency und keine Runtime-API auf: .NET Framework 4.8 ist semantisch
  nicht RE2-paritätisch, native RE2-Wrapper verletzen das portable
  `SAFE`-/Linux-Gate. Die Implementierung bleibt bis zur Richtungs- und
  Vertragsfreigabe gesperrt.

- W4a implementiert: `toolbelt.core.error-envelope` standardisiert explizite CATCH-Daten ohne Rethrow- oder Logging-Seiteneffekt.
- W4a implementiert: `toolbelt.core.execution-context` stellt Begin/Set/End, inline TVF und SVF-Wrapper über `SESSION_CONTEXT` bereit.
- Beide Module auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Lifecycle, Central und Sessionisolation validiert (https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948).

- ResultTable-Contract um einen natürlichen Enginefehler 2705 nach begonnener Mutation erweitert; Savepoint-Rollback von Schema, Daten und Caller-Transaktion auf SQL Server 2019/2022/2025 Linux validiert ([Run 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855)).
- Manuelle Windows-Runtime-Testpläne für ResultTable und ZIP Memory mit synthetischem Scope und abstrahierter Rückmeldung ergänzt.

- Modulregistry um das bereits vorhandene `toolbelt.file.content` ergänzt; Statusübersichten zeigen nun 19 implementierte, 18 teilweise validierte und ein nicht ausgeführtes Modul.
- Dokumentationsvalidator erkennt künftig jedes vorhandene, aber nicht registrierte `Modules/*/module.yaml` sowie veraltete Registry-Einträge.
- `toolbelt.file.content` im Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356 auf SQL Server 2025 Linux mit Compatibility Levels 150/160/170 validiert und mit kanonischer Evidenz gekoppelt.
- ZIP-Backlog, Kandidaten, Implementierungsplan und Roadmap an die produktive CLR-Implementierung und die Linux-Matrix angepasst.
- Branchspezifischen Self-Mutation-Job aus dem ZIP-Workflow entfernt und Workflow-Berechtigung auf `contents: read` reduziert.
- Windows-Dateisystem-Arbeitspaket auf den tatsächlich verbleibenden manuellen Windows-SQL-Server-/NTFS-Runtime-Test reduziert.
- Welle `W1` implementiert: `TC-2026-002` als Calendar Difference,
  `TC-2026-008` als Directional TRIM Compatibility und `TC-2026-024` als
  RFC-3986-URI-Component-Percent-Encoding. Die drei Module besitzen
  eigenständige Lifecycle-Artefakte, Objektseiten und synthetische
  Contract-Tests. SQL Server 2025 Linux ist mit Compatibility Levels 150,
  160 und 170 einschließlich Wiederholungsdeployment, zentraler Nutzung und
  Uninstall erfolgreich; der Status ist `partially validated`.

- Base64, Integer-Base und Semantic Versioning auf Modulversion `1.1.0`
  angehoben; Deployment, Upgrade, Uninstall, Objektverträge, Beispiele,
  Manifeste und Testmatrizen um die inline-TVF-Alternativen erweitert.
- Inline-TVF-Remediation `AP-2026-014` nach erfolgreichen SQL-Server-2025-
  Linux-Läufen mit Compatibility Levels 150, 160 und 170 abgeschlossen.
- Datenschutz- und Vertraulichkeitsregeln präzisiert: fachlich relevante öffentliche Organisations-/Projektnamen und Links sowie `gecompat` und `Gerhard Pisch` sind zulässig; personenbezogene/sensible Daten, interne/vertrauliche Informationen, Original-Tabelleninhalte, reale Runtime-Ausgaben und konkrete Remote-Runner-Hardwarewerte bleiben ausgeschlossen.
- Bestehende Kandidaten zu Multi-Separator-Split und kalendarischer Differenz mit präziseren Versions-, Provider-, Performance- und Aussagegrenzen versehen.
- Roadmap um die abgeschlossene Research-Welle, die abgeschlossene ResultTable-Designphase und die geplante Implementierungswelle ergänzt.
- USP-Vertrag mit der kanonischen ResultTable-Runtime-Spezifikation und Testmatrix verknüpft.
- Repository-Map und Modulübersicht um das implementierungsreif geplante Kernmodul ergänzt.
- `@CreateStmt` für Version `1.0.0` zugunsten einer Referenztabelle zurückgestellt; die parsergestützte Capability bleibt als spätere Vertragsoption erhalten.
- Interne lokale Temp-Objekte verwenden den reservierten Präfix `#tbx_`; persistente Tabellenkonventionen bleiben offen.
- Implementierungs-Gate präzisiert: Ideen dürfen fortlaufend dokumentiert werden; jede konkrete Funktion benötigt vor der Implementierung eine Besprechung und anschließende ausdrückliche Benutzerfreigabe.
- `AP-2026-003` bis zur funktionsbezogenen Besprechung und Freigabe auf `blocked` gesetzt.
- `Backlog/personal_Backlog_Bainstorm.md` als verpflichtend zu berücksichtigenden, nicht autoritativen und historisch zu erhaltenden Research-Input in AI-Regeln, Repo-Map, Backlog-Prozess und Curator-Agent eingebunden.
- `AP-2026-003` nach ausdrücklicher funktionsbezogener Benutzerfreigabe auf `implemented` gesetzt; weitere Funktionen bleiben ohne eigene Freigabe blockiert.
- Anchor-Umbau am SQL-Server-Limit von 1024 Spalten in kontrollierte Teilschritte zerlegt.
- Getrennte Install-/Upgrade-Pfade durch ein gemeinsames `Deploy.sql` mit `DeploymentMode`, Release-Manifest, Application Lock und objektgenauer Herkunftsprüfung ersetzt.
- Source-Hashes von einem blockierenden Drift-Gate zu rein diagnostischer Information geändert.
- Modulstatus in getrennte Implementierungs-, Validierungs- und Release-Dimensionen aufgeteilt.
- README- und Modulübersichtsstatus als aus Manifesten erzeugte Abschnitte gekennzeichnet.
- ResultTable-Runtime-Workflow auf Source-, Deployment-, Manifest-, Runtime-Test- und CI-Adapteränderungen begrenzt.
- Execution-Infrastructure-Kandidaten um konkrete Prior Art aus tSQLt, SQL Server Multi Thread und der SQL Server Maintenance Solution ergänzt.
- Vorhandenen Base64-Kandidaten `TC-2026-012` anhand der nativen SQL-Server-2025-Semantik präzisiert.
- Toolbelt-Landschaftsrecherche auf den implementierten ResultTable-/Dokumentationsstand und die aktuellen SQL-Server-2025-REST-/AI-Funktionen konsolidiert.
- SQL Server 2022 und 2025 in der GitHub-hosted Linux-Matrix von der reduzierten Kompatibilitätsprüfung auf die vollständige ResultTable-Suite umgestellt.
- `TC-2026-012` als bevorzugten nächsten Besprechungskandidaten eingeordnet und `TC-2026-004` bis zur Grundsatzentscheidung über Typ-/Scale-Parität und Objektfamilie zurückgestellt; keine Implementierungsfreigabe erteilt.
- Vier parallele ResultTable-Sitzungen mit identischen logischen lokalen Temp-Tabellennamen auf SQL Server 2019, 2022 und 2025 unter Linux erfolgreich validiert; invasiven DDL-Trigger-Harness als ungeeignete Recovery-Evidenz verworfen.
- Das pauschale Phase-2-Gate eines vollständig validierten, fachlich unabhängigen Referenzmoduls durch ein scopebezogenes Gate ersetzt; konkrete Modulverträge, Eigenvalidierung und tatsächlich verwendete gemeinsame Infrastruktur bleiben verpflichtend.
- `TC-2026-012` nach Benutzerfreigabe vom Research-Kandidaten zum implementierten und auf SQL Server 2025 Linux teilweise validierten Modul überführt.
- `TC-2026-006` nach Benutzerfreigabe vom Research-Kandidaten zum implementierten und auf SQL Server 2025 Linux teilweise validierten Modul überführt.
- Veralteten Backlogstatus des bereits gemergten Base64-Arbeitspakets von `active` auf `completed` korrigiert.
- `TC-2026-001`, `TC-2026-030` und `TC-2026-031` nach gemeinsamer Vertragsbesprechung und ausdrücklicher Freigabe vom 2026-07-30 auf `ready for development` gesetzt; Arbeitspakete `AP-2026-011` bis `AP-2026-013` angelegt.
- `TC-2026-029` aus `RI-2026-011` als `AP-2026-010` implementiert und auf SQL Server 2025 Linux teilweise validiert.
- Identifier-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Parser-, Quote-, Escape-, Omission-, Längen-, Fehler-, Deployment- und Lifecycle-Contracts erfolgreich.
- `TC-2026-001` als `AP-2026-011` implementiert; die breitere Split-Version mit Separatorstrings beliebiger Länge, frei definierbaren Quote-Zeichen und Escape bleibt getrennt als `TC-2026-032` im Research-Status.
- Split-Characters-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Literal-, Leer-Token-, NULL-/NUL-, Collation-, LOB-, Dependency-, zentraler und Lifecycle-Contracts erfolgreich; Status auf `partially validated` angehoben.
- Modul `toolbelt.validation.semantic-version` mit striktem SemVer-2.0.0-Parser, Comparator und binärem Sort Key ohne numerischen Overflow.
- Semantic-Version-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Parser-, Präzedenz-, Sort-Key-, Größen-, Deployment- und Lifecycle-Contracts erfolgreich; Status auf `partially validated` angehoben.
- Modul `toolbelt.conversion.integer-base` mit kanonischer Codierung und strikter Decodierung des vollständigen `bigint`-Bereichs für frei definierbare ASCII-Alphabete der Basen 2 bis 93.
- Integer-Base-Runtime-Matrix auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Alphabet-, Kanonizitäts-, Grenzwert-, Overflow-, Deployment- und Lifecycle-Contracts erfolgreich; Status auf `partially validated` angehoben.

### Korrigiert

- Bucket-SQL-Alias und Optimizer-Expansion korrigiert. Die drei öffentlichen
  Verträge bleiben Inline TVFs; ein interner einzeiliger Core verhindert den
  in der Runtime nachgewiesenen SQL-Server-Fehler `8632`.
- Modulzahl, Modulübersichten, Testinventar, Roadmap, Backlog, Research-Fokus
  und den kandidatenübergreifenden Implementierungsplan auf die tatsächlich
  vorhandenen 10 Module synchronisiert.
- W1-Evidenz in Manifesten und gekoppelter Dokumentation auf den finalen
  erfolgreichen Runtime-Lauf `30553118399` sowie den finalen
  Dokumentationslauf `30553118014` vereinheitlicht.
- Abgeschlossene Arbeitspakete aus dem aktiven Backlogabschnitt entfernt und
  den noch aktiven ResultTable-Validierungsscope getrennt ausgewiesen.
- W2a mit `TC-2026-004`, `TC-2026-005` und `TC-2026-007` nach
  funktionsbezogener Freigabe implementiert; offene JSON-Oberflächen bleiben
  getrennt in `W2b`.
- Dokumentationsvalidator um manifestbasierte Prüfungen für Modulzahl,
  README-/Testinventar, implementierte Kandidaten und Research-Inbox-Status
  erweitert; W1-Runtime-Trigger auf Runtime- und Manifestpfade begrenzt.
- Kandidatenstatus und nächste Schritte von `TC-2026-003`, `TC-2026-006`, `TC-2026-012` und `TC-2026-029` an den nachweisbaren Implementierungs- und Validierungsstand angeglichen.
- Custom-Agent-Profil auf gültige `.agent.md`-Struktur mit YAML-Frontmatter umgestellt.
- Generische Objektvorlagen durch objekttypspezifische USP-, TVF-, SVF- und View-Vorlagen ersetzt.
- USP-Vertrag und Teststandard um vollständige `@ResultTable`- und `@KeepData`-Contract-Tests ergänzt.
- SQL Server 2025 in Support-, Manifest- und Testmatrizen aufgenommen.
- CLR-Linux-Grenzen und `TRUSTWORTHY`-Ausnahmeregel präzisiert.
- Statusangaben nach dem initialen Merge aktualisiert.
- Entscheidungsprotokoll, Contribution-Regel und technische Identifier-Sprache konsolidiert.
- Bereits in `SQL_Server_Analyze` vorhandenen Unused-Index-Kandidaten aus dem offenen Analyze-Backlog entfernt.
- Identische Ziel- und Referenz-Temp-Tabelle wird vor jeder Mutation mit `51022` abgelehnt.
- Engine-Fehler beim Metadatenzugriff und bei `TRUNCATE` bleiben unverändert; der unzulässige `DELETE`-Fallback wurde entfernt.
- Debug-Stufen `4` bis `254` liefern für `USP_PrepareResultTable` denselben Detailumfang wie Stufe `3`.
- Deployment-Sessionoption und Objektartvergleich für XML- und Collation-stabile Ausführung korrigiert.
- Runtime-Testmetadaten für `datetime2(3)` und CI-Kollisionsvorbereitung korrigiert.
- Veraltete Runtime-Statusangaben in README, SECURITY und USP-Vertrag korrigiert.
- ResultTable-Evidenz auf den finalen erfolgreichen Linux-Workflow aktualisiert.

### Status

27 Module sind implementiert. 2 sind `validated`, 25 sind `partially
validated`; 0 sind `not executed`. Die verbindliche, je Modul und Plattform getrennte Evidenz
steht in den Manifesten. Offene Windows- und modulspezifische Releasefälle
werden nicht aus Linux- oder Compatibility-Level-Läufen abgeleitet.
