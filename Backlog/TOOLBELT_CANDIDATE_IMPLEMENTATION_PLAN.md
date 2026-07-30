# Implementierungsplan für Toolbelt-Kandidaten

Stand: 2026-07-30

Dieser Plan zerlegt die Kandidaten aus
[`TOOLBELT_CANDIDATES.md`](./TOOLBELT_CANDIDATES.md) in mögliche Module,
öffentliche SQL-Objekte, interne beziehungsweise externe Provider-Artefakte,
Abhängigkeiten und ausführbare Entwicklungswellen.

## Verbindlichkeit und Aussagegrenzen

- **Dokumentiert:** Die Kandidatenliste enthält 46 Kandidaten. 17 Module sind
  implementiert; 16 sind `partially validated`, 1 ist `not executed`.
- **Planungsvorschlag:** Noch nicht implementierte Modul-IDs, Objektnamen und
  Objektzuschnitte in diesem Dokument sind Arbeitsnamen für die
  Vertragsbesprechung. Sie sind noch kein öffentlicher Runtime-Vertrag.
- **Keine Implementierungsfreigabe:** Ein Eintrag in diesem Plan ändert einen
  Kandidaten nicht von `researched` auf `ready for development`. Vor jeder
  Implementierung bleiben die funktionsbezogene Vertragsbesprechung und die
  anschließende ausdrückliche Benutzerfreigabe erforderlich.
- **Keine spekulativen persistenten Namen:** Für Tabellen, Synonyme,
  Assemblies, Trigger, Sequences, Types und bisher ungeregelte Objekttypen
  bleibt die Namensentscheidung gemäß
  [`DEC-2026-003`](../Documentation/Architecture/DECISIONS.md) bis zum ersten
  konkreten Bedarf offen.
- **Provider sind keine stillen Alternativimplementierungen:** Ein alternativer
  Provider erhält eine eigene Support-, Security-, Deployment- und
  Testmatrix. Kanonische Fachlogik wird nicht kopiert.

## Ergebnis der Bestandsprüfung

| Gruppe | Kandidaten | Konsequenz |
|---|---|---|
| Implementiert | `TC-2026-001`, `TC-2026-002`, `TC-2026-003`, `TC-2026-004`, `TC-2026-005`, `TC-2026-006`, `TC-2026-007`, `TC-2026-008`, `TC-2026-009` Slice A, `TC-2026-012`, `TC-2026-016`, `TC-2026-023`, `TC-2026-024`, `TC-2026-029`, `TC-2026-030`, `TC-2026-031` | Capability-spezifische Runtime sowie offene physische Zielversions-, Windows- und modulspezifische Releasevalidierung gezielt abschließen. |
| Parser-, CLR- oder breite Semantikmodule | `TC-2026-010`, `TC-2026-011`, `TC-2026-013`, `TC-2026-032` | Funktionsfamilien und Provider vor dem ersten Code begrenzen und benchmarken. |
| Execution-Infrastruktur | `TC-2026-014` bis `TC-2026-022`, `TC-2026-046` | Als abhängige Plattform in mehreren Modulen entwickeln; kein monolithisches Sammelmodul. |
| Externe Provider und Integrationen | `TC-2026-025` bis `TC-2026-028`, `TC-2026-037`, `TC-2026-038` | Allowlist-, Identity-, Secret-, Timeout-, Abbruch- und Plattformvertrag sind Pflicht-Gates. |
| Archive, Kompression und Office | `TC-2026-033` bis `TC-2026-036`, `TC-2026-045` | In-memory-Verträge von Dateisystemverträgen trennen; untrusted input und Ressourcenlimits zuerst. |
| Pseudonymisierung und synthetische Daten | `TC-2026-039` bis `TC-2026-043` | Gemeinsame deterministische Primitive zuerst; Datenschutzwirkung nicht als Anonymisierung behaupten. |
| DDL-/Clone-Framework | `TC-2026-044` | Script-only vor automatischer Mutation; Dependency- und Recovery-Vertrag getrennt. |

## Einheitlicher Ablauf je neuem Modul

1. Kandidat auf einen kleinsten fachlich vollständigen Version-1-Slice
   reduzieren.
2. Zweck, öffentliche Signatur, Resultsets, Fehler, Collation, Datentypen,
   Limits, Berechtigungen, Deployment-Modi und Alternativen besprechen.
3. Breite Kandidaten in getrennte Arbeitspakete und gegebenenfalls Module
   teilen. Mehrere öffentliche Objekte bleiben in einem Modul, wenn sie
   denselben Lifecycle und denselben kanonischen Kern besitzen.
4. Bei erstmaligem Bedarf an persistenten Tabellen, Assemblies, Types,
   Triggern, Sequences oder Synonymen die Namenskonvention mit dem Benutzer
   entscheiden und als Architekturentscheidung festhalten.
5. Implementierungsfreigabe dokumentieren und erst dann ein Arbeitspaket auf
   `ready for development` beziehungsweise beim Start auf `active` setzen.
6. Moduldesign, Contract-Testmatrix und `module.yaml` vor oder gemeinsam mit
   dem ersten Runtime-Objekt erstellen.
7. Source, `Deploy.sql`, `Uninstall.sql`, Release-Manifest,
   Objektdokumentation, Beispiele sowie statische, Contract-, Lifecycle- und
   Runtime-Tests gekoppelt umsetzen.
8. Zuerst den geänderten Capability-Scope testen. Für portables T-SQL ist SQL
   Server 2025 unter den Compatibility Levels 150, 160 und 170 der schnelle
   Entwicklungsfilter. Physische SQL-Server-2019-/2022-Läufe bleiben für
   Engine-, Provider- oder Versionsunterschiede und die Releasevalidierung
   erforderlich. Windows wird bei plattformrelevanten Modulen und vor Release
   getrennt geprüft.
9. Status ausschließlich aus tatsächlich vorhandenen Artefakten und
   ausgeführter Evidenz ableiten.

## Entwicklungswellen und Abhängigkeiten

| Welle | Status | Inhalt | Kandidaten | Eintrittsbedingung | Ergebnis |
|---|---|---|---|---|---|
| `V0` | `planned` | Offene Releasevalidierung | `001`, `002`, `003`, `004`, `005`, `006`, `007`, `008`, `009`, `012`, `016`, `023`, `024`, `029`, `030`, `031` | Geeignete physische Engines beziehungsweise Windows-Runner | Nachweisbare Erweiterung des Validierungsscopes; keine Codeänderung ohne Befund. |
| `W1` | `completed` | Kleine unabhängige T-SQL-Kerne | `002`, `008`, `024` | Einzelvertrag und Freigabe | Drei implementierte, auf SQL Server 2025 Linux teilweise validierte Module. |
| `W2a` | `completed` | Date/Time- und Bigint-Bit-Kompatibilität | `004`, `005`, `007` | Typfamilien, Paritätsumfang und Fehlervertrag am 2026-07-30 freigegeben | Drei Module implementiert und auf SQL Server 2025 Linux teilweise validiert. |
| `W2b-A` | `completed` | JSON-Pfadprüfung | `009` Slice A | Pfad-, NULL-, Fehler- und Providervertrag am 2026-07-30 freigegeben | `toolbelt.json.path-exists` implementiert und auf SQL Server 2025 Linux teilweise validiert. |
| `W2b-B` | `deferred` | JSON-Konstruktoren und Aggregate | `009` Slice B, `013` | Variable Konstruktoroberfläche beziehungsweise stabiler Aggregat-/CLR-Provider entschieden | Keine Implementierung; Aggregate bleiben während Preview zurückgestellt. |
| `W2c` | `completed` | Console-Ausgabe und Runtime-Capability-Discovery | `016`, `023` | Provider-, Chunk-, Null-, Metadatenquellen- und Driftvertrag am 2026-07-30 freigegeben | Zwei Module implementiert und auf SQL Server 2025 Linux teilweise validiert. |
| `W3` | `researched` | String-Parser und Matching | `010`, `011`, `032` | Syntaxsubset, Limits und Providervergleich entschieden | Getrennte Regex-, Fuzzy- und Quote-/Escape-Module. |
| `W4` | `researched` | Weitere Execution-Grundlagen | `017`, `019`, `022` | Persistente Namenskonvention nur soweit tatsächlich benötigt | Error Envelope, Correlation und Work-Type-Katalog. |
| `W5` | `researched` | Session- und Ausführungsprovider | `046`, `014` | `017`, `019`, `022`; Provider- und Security-Entscheidung | Synchrone zweite Session und darauf aufbauendes rollback-unabhängiges Logging. |
| `W6` | `researched` | Queue, Retry, Lease und Cancellation | `015`, `020`, `021`, `018` | `017`, `019`, `022`; Tabellenkonvention entschieden | Begrenzte, beobachtbare und wiederanlaufbare Work Queue. |
| `W7` | `researched` | Datei- und Host-Provider | `037`, `038`, `025`, `026`, `027` | Execution-Basis, Root-/Endpoint-Allowlist und Identity-Vertrag | Kontrollierte Provider ohne Raw-Script- oder freie URL-Schnittstelle. |
| `W8` | `active` | Archive und XLSX | `033`, `034`, `035`, `036`, `045` | Untrusted-input-Limits; Dateiprovider nur bei pfadbasiertem Scope | Verarbeitungswelle 1 fuer `TC-2026-034` aktiv: V1A-Vertragsentwurf fuer In-memory-Extraktion einzelner Eintraege dokumentiert; Implementierung bleibt bis zur finalen Benutzerfreigabe gesperrt. |
| `W9` | `researched` | Deterministische Pseudonymisierungsprimitive | `040`, `039`, `041`, `042`, `043` | Key-/Seed-, Kanonisierungs- und Datenschutzvertrag | Range-Primitive zuerst; darauf Lookup, Translation, Date Shift und Geo Jitter. |
| `W10` | `researched` | Kontrolliertes DDL-Klonen | `044` | Identifier-Modul vorhanden; unterstützte Objektmenge festgelegt | Zuerst nur geprüftes Script, später optional getrennte Ausführung. |
| `W11` | `researched` | KI-Capabilities | `028` | REST/Worker, Capability-Katalog, Credentials, Kosten- und Datengovernance | Embeddings und generative Aufrufe als getrennte Module. |

Die Wellen sind eine Dependency-Reihenfolge, keine pauschale
Implementierungsfreigabe. Innerhalb einer Welle wird nur ein ausdrücklich
freigegebenes Arbeitspaket aktiv.

## Objekt- und Modulplan

### Bereits implementierte Module

| Kandidat | Modul | Vorhandene öffentliche Objekte | Restarbeit |
|---|---|---|---|
| `TC-2026-001` | `toolbelt.string.split-characters` | `toolbelt_string.TVF_SplitByCharacters` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; `TC-2026-032` bleibt getrennt. |
| `TC-2026-002` | `toolbelt.datetime.calendar-difference` | `toolbelt_datetime.TVF_CalendarDifference` | Physische SQL-Server-2019-/2022- und Windows-Evidenz sowie offene Kollisionsfälle. |
| `TC-2026-003` | `toolbelt.core.result-table` | `toolbelt_core.USP_PrepareResultTable` | Windows, natürlicher Savepoint-Fehlerfall und vergleichbare plattformübergreifende Performance-Evidenz. |
| `TC-2026-006` | `toolbelt.core.generate-series` | `toolbelt_core.TVF_GenerateSeriesBigInt`, `toolbelt_core.TVF_GenerateSeriesInt` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |
| `TC-2026-008` | `toolbelt.string.directional-trim` | `toolbelt_string.TVF_TrimDirectionalNvarchar`, `toolbelt_string.TVF_TrimDirectionalVarchar` | Weitere Collations und physische SQL-Server-2019-/2022- und Windows-Evidenz. |
| `TC-2026-012` | `toolbelt.conversion.base64` | `toolbelt_conversion.TVF_Base64Encode`, `toolbelt_conversion.TVF_Base64Decode`, `toolbelt_conversion.SVF_Base64Encode`, `toolbelt_conversion.SVF_Base64Decode` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |
| `TC-2026-024` | `toolbelt.conversion.uri-component` | `toolbelt_conversion.TVF_UriComponentEncode`, `toolbelt_conversion.TVF_UriComponentDecode`, `toolbelt_conversion.SVF_UriComponentEncode`, `toolbelt_conversion.SVF_UriComponentDecode` | LOB-/Performancegrenzen und physische SQL-Server-2019-/2022- und Windows-Evidenz. |
| `TC-2026-029` | `toolbelt.metadata.identifier` | `toolbelt_metadata.TVF_ParseMultipartName`, `toolbelt_metadata.SVF_QuoteMultipartName` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |
| `TC-2026-030` | `toolbelt.validation.semantic-version` | `toolbelt_validation.TVF_ParseSemanticVersion`, `toolbelt_validation.TVF_CompareSemanticVersion`, `toolbelt_validation.TVF_SemanticVersionSortKey`, `toolbelt_validation.SVF_CompareSemanticVersion`, `toolbelt_validation.SVF_SemanticVersionSortKey` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |
| `TC-2026-031` | `toolbelt.conversion.integer-base` | `toolbelt_conversion.TVF_IntegerToBase`, `toolbelt_conversion.TVF_TryBaseToInteger`, `toolbelt_conversion.SVF_IntegerToBase`, `toolbelt_conversion.SVF_TryBaseToInteger` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |
| `TC-2026-004` | `toolbelt.datetime.truncate` | `TVF_TruncateDate`, `TVF_TruncateDateTime2`, `TVF_TruncateDateTimeOffset` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |
| `TC-2026-005` | `toolbelt.datetime.bucket` | `TVF_DateBucketDate`, `TVF_DateBucketDateTime2`, `TVF_DateBucketDateTimeOffset` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung. |
| `TC-2026-007` | `toolbelt.binary.bit-operations` | `TVF_LeftShiftBigInt`, `TVF_RightShiftBigInt`, `TVF_BitCountBigInt`, `TVF_GetBitBigInt`, `TVF_SetBitBigInt` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; Binary-Slice bleibt getrennt. |
| `TC-2026-009` | `toolbelt.json.path-exists` | `toolbelt_json.TVF_JsonPathExists` | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; Konstruktoren bleiben getrennt. |
| `TC-2026-016` | `toolbelt.core.console-message` | `toolbelt_core.USP_WriteConsoleMessage` | Physische 2019-/2022-, Windows- und weitere Client-/Treiber-Evidenz. |
| `TC-2026-023` | `toolbelt.metadata.capability-catalog` | `toolbelt_metadata.VW_ModuleCapabilities` | Physische 2019-/2022-, Windows- und eingeschränkte Metadata-Visibility. |

### Portable Fach- und Compatibility-Module

| Kandidat | Vorgeschlagener Modul-Slice | Vorgeschlagene öffentliche Objekte | Zentrale Vertragsentscheidung | Testschwerpunkt |
|---|---|---|---|---|
| `TC-2026-013` | `toolbelt.json.aggregate` mit zwei getrennten Aggregat-Slices | Array- und Object-Aggregat-Oberfläche; Objekttyp und Name bleiben bis zur Providerentscheidung offen | T-SQL-Resultset-Procedure versus CLR User-defined Aggregate; Order, Duplicate Keys, NULL und Return Type. | Native Parität auf 2025, Reihenfolge, Escaping, große Gruppen, Memory Grants und Providervergleich. |

### Parser, Regex und Matching

| Kandidat | Vorgeschlagener Modul-Slice | Vorgeschlagene öffentliche Objekte | Zentrale Vertragsentscheidung | Testschwerpunkt |
|---|---|---|---|---|
| `TC-2026-010` | `toolbelt.string.regex` mit freigegebenem Syntaxsubset | `SVF_RegexLike`, `SVF_RegexReplace`, `SVF_RegexSubstring`, `SVF_RegexIndex`, `SVF_RegexCount`, `TVF_RegexSplit`, `TVF_RegexMatches`; nur ausgewählte Version-1-Funktionen | RE2-Kompatibilität, .NET-Abweichungen, Flags, Match-/Capture-Schema, Timeouts und Eingabelimits. | Gemeinsame Vektoren gegen SQL Server 2025, ReDoS-Schutz, Unicode, Collations, LOBs und CLR-Trust. |
| `TC-2026-011` | `toolbelt.string.fuzzy-match` | `SVF_EditDistance`, `SVF_EditDistanceSimilarity`, `SVF_JaroWinklerDistance`, `SVF_JaroWinklerSimilarity` | Exakte SQL-Server-2025-Semantik, maximale Länge, Unicode/Collation und T-SQL- versus CLR-Kern. | Native Parität, Symmetrie, Grenzwerte, lange Strings, Mengenaufruf und Benchmark. |
| `TC-2026-032` | `toolbelt.string.split-quoted` | Arbeitsname `TVF_SplitQuotedText`; bei nicht-TVF-fähigem Provider eine resultseterzeugende USP statt einer erzwungenen TVF | Separatorstrings, Longest Match, öffnende/schließende Quote-Strings, Escape-Modell, fehlerhafte Eingabe und LOB-Limit. | Überlappende Separatoren, verschachtelte/unerlaubte Quotes, Escapes, leere Tokens, Ordinals, Unicode und Linearität. |

### Execution- und Provider-Infrastruktur

| Kandidat | Vorgeschlagener Modul-Slice | Vorgeschlagene öffentliche Objekte | Interne/persistente Bestandteile und Blocker |
|---|---|---|---|
| `TC-2026-017` | `toolbelt.core.error-envelope` | `toolbelt_core.USP_CaptureErrorEnvelope` | Rückgabeform, Klassifikation und Rethrow-Grenze entscheiden; keine persistente Tabelle erforderlich. |
| `TC-2026-019` | `toolbelt.core.execution-context` | `USP_BeginExecution`, `USP_SetExecutionContext`, `SVF_CurrentExecutionId`, optional `USP_EndExecution` | Session-Context-Keys, Nested Ownership und Lebensdauer; persistenter Ausführungsstatus nur als getrennte Erweiterung. |
| `TC-2026-022` | `toolbelt.core.work-type` | `USP_RegisterWorkType`, `USP_DisableWorkType`, `USP_ResolveWorkType`, `VW_WorkTypes` | Persistenter Katalog und gegebenenfalls Types benötigen vorherige Namensentscheidung; Registration-Berechtigung und Parameterschema sind Security-Gates. |
| `TC-2026-046` | `toolbelt.core.second-session` plus getrennte Providerpakete | `USP_ExecuteWorkTypeInNewSession`; kein Raw-SQL-Parameter | Provideradapter für synchrone SQL-CLR-Verbindung, Agent, Broker oder externen Worker erfüllen nicht automatisch denselben Vertrag. Version 1 auf genau eine synchrone Semantik begrenzen; Assemblyname ist offen. |
| `TC-2026-014` | `toolbelt.core.event-log` mit genau einem freigegebenen Provider in Version 1 | `USP_WriteEvent`; optional `VW_Events` und kontrollierte Retention-USP | Persistente Logtabelle und Providerartefakte benötigen Namens-/Retention-Entscheidung. Haltbarkeit, Blockierung und Fehlerverhalten müssen explizit sein. |
| `TC-2026-015` | `toolbelt.core.work-queue` | `USP_EnqueueWork`, `USP_ClaimWork`, `USP_CompleteWork`, `USP_FailWork`, `USP_GetWorkStatus`, `VW_WorkQueue` | Queue-, Status- und Payloadtabellen, Aktivierungsprocedure sowie Workeradapter; Tabellen-/Triggernamen offen. Kein beliebiges SQL als Payload. |
| `TC-2026-020` | `toolbelt.core.retry-policy` | `SVF_ComputeRetryDelay`, `USP_ScheduleRetry`, `USP_MoveToDeadLetter`, `USP_RequeueDeadLetter` | Verwendet Queuezustand; Retry-Klassen, Idempotency Key, Jitter, Max Attempts und manuelle Freigabe definieren. |
| `TC-2026-021` | `toolbelt.core.worker-lease` | `USP_AcquireWorkLease`, `USP_HeartbeatWorkLease`, `USP_ReleaseWorkLease`, `USP_RecoverOrphanedWork`, `VW_WorkLeases` | Lease-/Heartbeat-Zustand benötigt persistente Tabellenkonvention; atomare Ownership-Version und Recovery zuerst spezifizieren. |
| `TC-2026-018` | `toolbelt.core.execution-cancel` | `USP_RequestExecutionCancellation`, `SVF_IsCancellationRequested`; privilegierter `USP_StopExecutionGroup` nur als separater optionaler Slice | Cancellation-Status benötigt persistente Benennung. Kooperative Prüfung ist Default; `KILL` verlangt eindeutige Sessionzuordnung und eigenes Berechtigungsmodell. |

Pflichtprüfungen für diese Familie sind konkurrierende Worker, Doppelausführung,
Crash zwischen Zustandsübergängen, Deadlocks, Caller-Transaktionen,
uncommittable Transactions, Timeout, Abbruch, Wiederanlauf, Berechtigungen,
Providerausfall und idempotentes Deployment. Jeder Test verwendet ausschließlich
synthetische Work Types und Payloads.

### Externe Automation, Dateien, Netzwerk und KI

| Kandidat | Vorgeschlagener Modul-/Provider-Slice | Vorgeschlagene öffentliche Objekte | Pflicht-Gates |
|---|---|---|---|
| `TC-2026-025` | `toolbelt.automation.powershell` | `toolbelt_automation.USP_InvokePowerShellWorkType` | Exakte erlaubte Aufgaben, kein Raw Script, Workeridentität, Parameter-/Outputschema, Timeout, Cancellation, Audit und Windows-/Linux-Matrix. |
| `TC-2026-026` | A: `toolbelt.integration.python-ml`; B: `toolbelt.automation.python-worker` | A: `USP_ExecutePythonCapability`; B: `USP_InvokePythonWorkType` | Datenorientierte In-database-Ausführung strikt von Host-Automation trennen; Packages, Version, Ressourcen, Import-Allowlist und ResultTable-Vertrag festlegen. |
| `TC-2026-027` | `toolbelt.integration.rest` mit internem 2025- und Worker-Provider | `toolbelt_integration.USP_InvokeRestEndpoint` | Endpoint-/Method-Allowlist, Credentialreferenz statt Secret, Redirects, DNS/SSRF, Payloadlimit, Timeout, Retry/Idempotenz und 2019/2022-Provider. |
| `TC-2026-028` | A: `toolbelt.ai.embedding`; B: `toolbelt.ai.structured-inference`; C: generativer Chat erst danach | Arbeitsnamen `USP_CreateEmbedding`, `USP_RunStructuredInference`, `USP_CreateChatCompletion` | Separate Verträge, Datenfreigabe, Modell/Version, Region, Credentials, Kostenlimit, Outputschema, Prompt-Injection-Grenze und keine automatische Codeausführung. |
| `TC-2026-037` | `toolbelt.file.content` | `toolbelt_file.USP_LoadTextFile`, `USP_SaveTextFile`, `USP_LoadBinaryFile`, `USP_SaveBinaryFile` | Root-Allowlist, kanonische Pfadauflösung, Links, Identität, Encoding/BOM, Maximalgröße, Atomic Write, Overwrite und Provider. |
| `TC-2026-038` | `toolbelt.file.directory` | `toolbelt_file.USP_ListDirectoryEntries` | Flach/rekursiv, Paging, Sortierung, Metadatenschema, Links, Root-Allowlist und Ressourcenlimit. |

Für jede resultseterzeugende USP gelten der vollständige Help-,
`@ResultTable`-, `@KeepData`- und Debug-Vertrag. Provider-E2E-Tests werden
getrennt von den providerneutralen Contract-Tests ausgewiesen.

### Archive, Kompression und XLSX

| Kandidat | Vorgeschlagener Modul-/Capability-Slice | Vorgeschlagene öffentliche Objekte | Reihenfolge und Grenzen |
|---|---|---|---|
| `TC-2026-033` | `toolbelt.archive.zip-metadata` | `toolbelt_archive.USP_ListZipEntries`; eine TVF nur bei nachgewiesen reinem und begrenztem In-memory-Vertrag | `varbinary(max)` zuerst; ZIP64, Verschlüsselung, beschädigte Central Directory, Pfadnormalisierung, Entry-/Größenlimits und Zip Bombs testen. |
| `TC-2026-034` | A: `toolbelt.archive.zip-memory`; B: `toolbelt.archive.zip-filesystem`; C: optionaler CLR-Provider-Slice | A: `USP_ExtractZipEntry`, `USP_CreateZipArchive`; B: `USP_ExtractZipArchiveToDirectory`, `USP_CreateZipArchiveFromFiles`; C: Providerobjektname nach Vertragswelle | A vor B und C. Filesystem-Slice hängt von `TC-2026-037` ab. CLR-Slice startet als separate Vertragswelle `AP-2026-021` und folgt den CLR-Sicherheitsregeln ohne pauschales `TRUSTWORTHY ON`. |
| `TC-2026-035` | Bedingter Slice `toolbelt.compression.gzip-stream` | Nur bei belegter Lücke: `USP_GzipCompressStream`, `USP_GzipDecompressStream` | Vorheriger Spike gegen native `COMPRESS`/`DECOMPRESS`. Ohne klaren Streaming-/Datei-Use-Case Kandidat ablehnen oder in Dateiprovider integrieren. |
| `TC-2026-036` | Pro tatsächlich benötigtem Format ein Modul `toolbelt.compression.<format>` | Formatbezogene Compress-/Decompress-Oberflächen; kein generisches „beliebiges Format“-Objekt | Erst Format und Use Case wählen. Lizenz, Supply Chain, Plattform, Wartung, Bomb-Limits und Exit-Strategie je Provider prüfen. |
| `TC-2026-045` | `toolbelt.office.xlsx` | V1: `toolbelt_office.USP_ListXlsxWorksheets`, `USP_ReadXlsxCells`; später getrennt `USP_ImportXlsxTable` | V1 liefert stabiles zellorientiertes Schema. Tabellenförmige Typinferenz und Mutation folgen separat. Shared Strings, Styles, 1900/1904-Datumsmodus, Formeln, Fehlerzellen, Limits und Streaming testen. |

### Pseudonymisierung und synthetische Daten

| Kandidat | Vorgeschlagener Modul-Slice | Vorgeschlagene öffentliche Objekte | Pflicht-Gates |
|---|---|---|---|
| `TC-2026-040` | `toolbelt.pseudonymization.range` als gemeinsames Primitive | `toolbelt_pseudonymization.SVF_DeterministicRangeBigInt`; optional getrennte normalisierte Unit-Interval-Funktion | Kanonisierung, Hash/PRF, Seed versus geheimer Key, Verteilung, Bias, Bereich und Versionierung. |
| `TC-2026-039` | `toolbelt.pseudonymization.lookup` | `SVF_DeterministicLookupIndex` als Primitive; `USP_MapDeterministicLookupValue` für kontrollierte Lookupquellen | Stabile Sortierung, Lookup-Version, leere/geänderte Menge, Identifier-Sicherheit und Referenzkonsistenz. Gemeinsamen Kern aus `TC-2026-040` wiederverwenden. |
| `TC-2026-041` | `toolbelt.pseudonymization.translation` | `SVF_TranslateDeterministic` | Reversibilität, Alphabet, Unicode, Case-Regeln, Format Preservation, Key/Salt, Rotation und Mappingversion. |
| `TC-2026-042` | `toolbelt.pseudonymization.date-shift` | Typfamilie `SVF_ShiftDate`, `SVF_ShiftDateTime2`, optional `SVF_ShiftDateTimeOffset` | Granularität pro Entität/Gruppe/Zeile, Intervallerhalt, Offsetbereich, Zeitzone, Overflow und Schlüsselmodell. |
| `TC-2026-043` | `toolbelt.pseudonymization.spatial-jitter` | `SVF_JitterGeography`, `SVF_JitterGeometry` nur bei jeweils freigegebenem Modell | SRID, planar/geodätisch, Distanzverteilung, deterministische Parameter, Clipping, zulässige Gebiete und messbare Re-Identifikationsgrenze. |

Diese Module werden als Pseudonymisierung beziehungsweise synthetische
Datenerzeugung dokumentiert. Der Plan behauptet keine irreversible
Anonymisierung oder automatische Datenschutzkonformität.

### DDL- und Clone-Framework

| Kandidat | Vorgeschlagener Slice | Vorgeschlagene öffentliche Objekte | Pflicht-Gates |
|---|---|---|---|
| `TC-2026-044` | V1 `toolbelt.metadata.table-clone-script`; V2 getrennte Execute-Capability | V1 `toolbelt_metadata.USP_ScriptTableClone`; V2 optional `USP_ExecuteTableClone` | V1 nur Script-Erzeugung und Validierung. Unterstützte Tabellenarten, Spalten, Identity, Indizes, PK/UQ/FK, Check-/Default-Constraints, Trigger, Computed Columns, Partitionierung, Temporal/Graph/Ledger, Dateigruppen und Reihenfolge explizit whitelisten. Generierte persistente Objektnamen erfordern vorab die offene Namensentscheidung. |

V1 testet ausschließlich synthetische DDL-Modelle, deterministische
Namensbildung, Dependency-Reihenfolge, Kollisionsfreiheit und wiederholbare
Skripterzeugung. Automatische Ausführung, Datenkopie und Rollback gehören nicht
stillschweigend zu V1.

## Abnahmekriterien für den Plan

- Jeder der 46 Kandidaten ist genau einer Planzeile beziehungsweise einem
  vorhandenen Modul zugeordnet.
- Breite Kandidaten sind in getrennte Capabilities oder Provider-Slices
  zerlegt.
- Abhängigkeiten sind azyklisch und gemeinsame Primitive werden nicht
  dupliziert.
- Vorgeschlagene USP-, TVF-, SVF- und View-Namen entsprechen den bestehenden
  Konventionen.
- Für ungeregelte persistente Objekttypen wurde kein Name erfunden.
- Implementierungs-, Validierungs- und Release-Status bleiben getrennt.
- Der Plan verändert keine Implementierungsfreigabe und behauptet keine nicht
  ausgeführte Runtime-Evidenz.
- Datenschutz-, Secret-, Third-Party-, Provider-, Plattform- und
  untrusted-input-Gates sind bei den betroffenen Modulen sichtbar.

## Nächste konkrete Auswahl

W2c mit `TC-2026-016` und `TC-2026-023` ist als
`toolbelt.core.console-message` sowie
`toolbelt.metadata.capability-catalog` implementiert und auf SQL Server 2025
Linux mit Compatibility Levels 150/160/170 teilweise validiert. Physische
Zielversions-, Windows- und modulspezifische Releasefälle bleiben offen.

JSON-Konstruktoren und `TC-2026-013` bilden W2b-B und bleiben zurückgestellt.
Konstruktoren benötigen eine belastbare variable Eingabeoberfläche;
JSON-Aggregate bleiben während des nativen Preview-Status und ohne
freigegebenen SQL-CLR-/Providervertrag außerhalb der Entwicklung.

Parallel dazu kann `V0` die offenen physischen Releasevalidierungen der 17
implementierten Module bündeln. Fuer `TC-2026-034` laeuft mit `AP-2026-020`
die V1A-Implementierungswelle und mit `AP-2026-021` die CLR-
Folgevertragswelle. CLR-Runtime-Implementierung startet erst nach separater
Freigabe.
