# BACKLOG.md – Priorisierte Arbeitspakete

Nur priorisierte Kandidaten werden hier als konkrete Arbeitspakete geführt. Ein Eintrag ist keine automatische Implementierungszusage; er wird durch ausdrückliche Benutzerfreigabe aktiv.

27 Module sind implementiert. 2 sind `validated`, 25 sind `partially validated`; 0 sind `not executed`.

## Aktive Arbeitspakete

### V0a/V0b/V0c: Releasevalidierung und erste Releasekohorte

| Feld | Wert |
|---|---|
| ID | `V0a`, `V0b`, `V0c`; keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Die vorhandenen Module auf physischen Zielversionen und Windows validieren und daraus eine veröffentlichungsfertige erste Kohorte bilden, ohne Runtime- oder Release-Status vorwegzunehmen. |
| Scope | `V0a`: 24 portable beziehungsweise Linux-fähige Module auf SQL Server 2019/2022/2025 Linux. `V0b`: vollständige Windows-Matrix der V0c-Kohorte plus Hochrisikofälle für ResultTable, SQL CLR, Datei-I/O, Second Session und Event Log. `V0c`: 16 portable Module aus Kernfolge, W1, W2a, W2b-A und W2c. Keine neuen öffentlichen SQL-Objekte oder Signaturänderungen. |
| Dependencies | Ausdrückliche V0-Freigabe vom 2026-08-28 und Einzelzielfreigabe vom 2026-08-29; schema-valider SQL_Server_Lab-Vertrag; entweder `groupStatus = READY` oder explizit ausgewählte Einzelziele mit `runtimeStatus = READY` und zulässigem Eintragsstatus; vorhandene Modul-, Lifecycle- und Testverträge. |
| Priorität | `P0` |
| Status | `active`; `V0a` und `V0b` ausführbar; die E1b-Windows-Matrix belegt die aktuelle SQL-Erreichbarkeit der ausgewählten Base-Ziele |
| Implementation Status | 27 Module `implemented` – aus `module.yaml` abgeleitet |
| Validation Status | 2 Module `validated`, 25 Module `partially validated`; `toolbelt.core.work-queue` und `toolbelt.string.regex` besitzen die vollständige Windows-/Linux-Matrix, bei anderen Modulen bleiben Windows- und modulspezifische Restfälle offen. |
| Release Status | 27 Module `unreleased`; V0c, D1, E1a, E1b und R1b autorisieren keine tatsächliche Veröffentlichung. |
| Akzeptanzkriterien | Linux- und Windows-Zielversionen tatsächlich geprüft; Dependency-Closure und versionierte Objektmanifeste konsistent; Erst-, Wiederholungs-, Upgrade-, Central- und Uninstall-Verträge für die Kohorte erfolgreich; modulspezifische Pflichtfälle ausgeführt; nicht verfügbare Kombinationen sichtbar; vollständiger Dokumentationsaudit erfolgreich. |
| Tests | `Tests/CI/run-lab-local.ps1` mit `TestSuite=full`; getrennte synthetische File-Content-Fixtures; vorhandene manuelle Windows-Pläne für ResultTable, Windows Filesystem und ZIP Memory; vollständiger Dokumentations- und Datenschutzcheck. |
| Blocker | Kein Gruppenblocker für einzeln bereite Linux- oder Windows-Ziele. Das Projekt darf die Lab-Ressourcen nicht selbst starten oder reparieren. GitHub-hosted Linux-Runner sind unabhängig von der Lab-Verfügbarkeit ein reproduzierbarer Evidenzkanal und decken seit 2026-09-01 alle fünfzehn Modul-Runtime-Workflows auf 2019, 2022 und 2025 ab. Die früheren W5- und File-Content-Fehler auf diesem Kanal waren Testadapterfehler und sind behoben. Offen bleiben die Fehler auf den physischen Linux-Zielen 2019 und 2022, deren Ursachengleichheit nicht belegt ist, sowie die gesamte Windows-Matrix. |
| Evidenz | V0-Freigabe vom 2026-08-28 und Einzelzielfreigabe vom 2026-08-29; lokaler vollständiger Dokumentationsaudit und alle 16 statischen Modulvertragsprüfungen am 2026-08-28 erfolgreich. Am 2026-08-29 bestanden alle 16 V0c-Module ihre vollständigen Adapter auf physischen SQL-Server-2019-, 2022- und 2025-Linux-Zielen. Am 2026-08-30 bestand E1b zusätzlich die vollständige Windows-base-/Linux-latest-Matrix 2019/2022/2025. ZIP Memory und die W4-Module bestanden ebenfalls. Am 2026-09-01 bestanden alle fünfzehn GitHub-hosted Modul-Runtime-Workflows ihre Linux-Matrix auf SQL Server 2019, 2022 und 2025 vollständig, einschließlich Second Session, Event Log und File Content. Damit besteht für die betroffenen Module erstmals eine lab-unabhängige, reproduzierbare Dreiversionsevidenz unter Linux. Es werden keine Hosts, Credentials, konkreten Datenbanknamen, Laufzeiten oder vollständigen Logs übernommen. |
| Ursachenanalyse 2026-09-01 | Die GitHub-hosted W5-Fehler auf 2019 und 2022 entstanden im Testadapter, nicht im Modulcode: der Loopback-Linked-Server wurde mit `@provstr = N'encrypt=optional'` angelegt, und dieser Wert existiert erst ab MSOLEDBSQL 19. Die File-Content-Fehler entstanden, weil `Tests/CI/run-file-content-linux.sh` als einziges Modulskript `TBX_SQL_VERSION` nicht auswertete und feste Compatibility Levels 150, 160 und 170 setzte, was SQL Server 2019 mit Fehler 15048 ablehnt. Beide Korrekturen betreffen ausschließlich Testadapter; kein öffentliches SQL-Objekt, kein Vertrag und kein Modulmanifest wurde geändert. Ebenfalls belegt: die File-Content-Fixtures werden vom Containeradapter selbst erzeugt, sodass der Fixture-Blocker nur für die physischen Lab-Ziele gilt. |
| Nächster Schritt | Prüfen, ob die Fehler auf den physischen Linux-Zielen 2019 und 2022 dieselbe Ursache haben; der Lab-Pfad verwendet einen extern administrierten Linked Server und ist durch die Adapterkorrektur nicht automatisch miterledigt. Danach `V0a` vervollständigen; für `V0b` ist die externe Wiederherstellung der SQL-Erreichbarkeit der Windows-Ziele Voraussetzung. Windows bleibt der ausschlaggebende offene Nachweis; alle Module bleiben deshalb `partially validated`. |

Die V0c-Kohorte umfasst verbindlich:

`toolbelt.core.result-table`, `toolbelt.conversion.base64`,
`toolbelt.core.generate-series`, `toolbelt.metadata.identifier`,
`toolbelt.string.split-characters`, `toolbelt.validation.semantic-version`,
`toolbelt.conversion.integer-base`, `toolbelt.datetime.calendar-difference`,
`toolbelt.string.directional-trim`, `toolbelt.conversion.uri-component`,
`toolbelt.datetime.truncate`, `toolbelt.datetime.bucket`,
`toolbelt.binary.bit-operations`, `toolbelt.json.path-exists`,
`toolbelt.core.console-message` und
`toolbelt.metadata.capability-catalog`.

### ADP-008: SQL_Server_Lab Project-Adapter-Pilot

| Feld | Wert |
|---|---|
| ID | `ADP-008`; externer Pilot aus dem kanonischen Backlog von `SQL_Server_Lab`, keine neue sequenzielle `AP`-Referenz |
| Ziel | Ein vorhandenes versioniertes Toolbelt-Modul über den Project-Adapter-Vertrag 0.1 auf einem isolierten SQL-Server-2025-Container-Lab installieren, aktualisieren, validieren und deinstallieren. |
| Scope | `toolbelt.core.console-message` 1.0.0; fünf reine T-SQL-Entrypoints; markergebundene synthetische Datenbank; deterministische Ableitung aus kanonischem Deploy, Source und Uninstall. Keine neue öffentliche SQL-API, keine Providerlogik und keine Verwaltung von Lab-Infrastruktur im Toolbelt-Repository. |
| Status | `completed` für den deklarierten Pilot-Scope |
| Alternativen | Ein neues Pilotmodul würde unnötig einen öffentlichen Vertrag erzeugen; kopierte, unabhängig gepflegte SQL-Dateien würden vom Moduldeployment abdriften; ein im Toolbelt gestarteter Lab-Run würde die Repository-Grenze verletzen. |
| Risiken und Grenzen | Das Update ist ein versionsgleiches idempotentes Redeployment, weil für Version 1.0.0 kein historischer Upgradepfad existiert. Der Pilot belegt nur SQL Server 2025 Linux unter Docker und Podman und ändert den Modulstatus nicht. |
| Benutzerfreigabe | Der Benutzer hat am 2026-08-30 den autonomen Abschluss der offenen Backlogpunkte, die Verwendung des vorhandenen Podman-Providers und das Überführen jedes konsistenten Blocks auf `origin/main` ausdrücklich beauftragt. |
| Tests | Statischer Modul-/Generatorvertrag und Schema-/Resolverprüfung durch `SQL_Server_Lab`; echte getrennte SQL-Server-2025-Linux-Läufe unter Docker und Podman jeweils mit Install, Update, Validate, Adapter-Cleanup und anschließendem scopegebundenem Infrastruktur-Cleanup erfolgreich. |
| Evidenz | `Modules/toolbelt.core.console-message/TestLab/ProjectAdapter/`; ausschließlich synthetische Daten und abstrahierte Ergebnisse, ohne Credentials, Ports, Run-IDs, Laufzeiten oder vollständige Runtime-Logs. |
| Nächster Schritt | Pilotvertrag 0.1 stabil halten. Weitere Module, historische Upgradepfade oder ein breiterer Plattformscope benötigen einen eigenen begründeten Slice. |

### Q1: Migration-Idempotency-Verifier V1

| Feld | Wert |
|---|---|
| ID | `Q1`; konkretisiert `RI-2026-142`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Wiederholungsdeployment und wiederholtes Uninstall anhand des effektiven SQL-Katalogzustands prüfen, ohne eine öffentliche Runtime-Capability zu installieren. |
| Scope | Repository-interner SQLCMD-Verifier für eine isolierte synthetische Datenbank und ein dependency-freies, zustandsloses T-SQL-Modul. V1 vergleicht Schemas, Objekte, Definitionen, Spalten, Parameter, Toolbelt-Properties und Berechtigungen; zwei unabhängige Uninstall-Sitzungen und eine Restzustandsprüfung schließen den Lauf ab. Referenzmodul ist `toolbelt.core.generate-series`. |
| Priorität | `P1`; als einzelner Qualitäts-Enabler parallel zu V0 zulässig |
| Status | `completed` für den deklarierten V1-Scope |
| Alternativen | Vorhandene Lifecycle-Tests allein erkennen keine stille Katalogdrift; Source-Hashes bilden nicht den gesamten effektiven Katalog ab; ein dauerhaft installiertes Verifier-Modul würde den Prüfzustand selbst verändern. |
| Risiken und Grenzen | V1 unterstützt keine Tabellen, Assemblies, persistente Zustandsdaten, Dependency-Installation, historischen Upgradepfade, Central-Consumer oder parallele Migrationen. Abweichende Database-/Catalog-Collations bleiben ein eigener Lifecycle-Scope. |
| Tests | Statischer Contract, vollständiger Dokumentationsaudit und tatsächliche Q1-Runtime am 2026-08-29 auf SQL Server 2019, 2022 und 2025 jeweils unter Linux und Windows erfolgreich. Jeder Zieltest bestand erst nach Wiederholungsdeployment ohne Katalogdrift, zweimaligem Uninstall, leerer Restzustandsprüfung und erfolgreichem Entfernen seiner synthetischen Testdatenbank. |
| Evidenz | `Documentation/Architecture/MIGRATION_IDEMPOTENCY_VERIFIER_DESIGN.md`, `Tests/Quality/MigrationIdempotency/`, `Tests/CI/run-q1-migration-idempotency.sh` und `.github/workflows/q1-migration-idempotency.yml`; lokale SQL_Server_Lab-Matrix mit ausschließlich abstrahierter Evidenz. Keine Hosts, Credentials, Datenbanknamen, konkreten Buildnummern, Laufzeiten oder vollständigen Logs übernommen. |
| Nächster Schritt | Q1 V1 stabil halten. Tabellen-/Zustands-, Upgrade-, Central- und Parallelitäts-Slices nur bei eigenem nachgewiesenem Bedarf erweitern; Golden Snapshots und Contract-Test-Generierung bleiben zurückgestellt. |

### D1: Date Spine V1

| Feld | Wert |
|---|---|
| ID | `D1`; keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Einen kleinen portablen relationalen Date-Spine-Vertrag als nächste neue Nutzerfunktion bereitstellen. `Q1` bleibt ein Qualitäts-Enabler und ist keine nutzerorientierte SQL-Capability. |
| Scope | Drei öffentliche Inline TVFs für Tag, ISO-Woche und Monat. Der Bereich ist `[RangeStart, RangeEndExclusive)`; geliefert werden alle geschnittenen Perioden mit `Ordinal int` und `PeriodStart date`. `NULL`, leere und umgekehrte Bereiche liefern keine Zeilen. Keine Feiertage, Arbeitstage, Zeitzonen, DST, Locale-Texte, Geschäfts- oder Fiskalkalender und keine persistente Kalenderdimension. |
| Dependencies | `RI-2026-079`; `toolbelt.core.generate-series` 1.0.0 und `toolbelt.datetime.truncate` 1.0.0 in derselben Datenbank. Datetime Bucket ist ausdrücklich keine künstliche Dependency. |
| Priorität | `P1` nach `V0a`/`V0b`/`V0c`; parallel höchstens ein `Q1`-Qualitäts-Enabler |
| Status | `implemented`; Runtime `partially validated`, Release `unreleased` |
| Alternativen | Eine öffentliche Grain-Parameterfunktion, eine USP, nur vollständig enthaltene Perioden und eine persistente Kalenderdimension wurden für V1 verworfen. Quartal, frei wählbarer Schritt, Periodenende und abgeleitete Kalenderattribute bleiben mögliche getrennte Erweiterungen. |
| Risiken und Grenzen | Ergebnisgröße wächst linear; ohne `ORDER BY` keine Reihenfolgegarantie; ISO-Woche ist bewusst Montag-basiert und `DATEFIRST`-unabhängig; der maximale Kalendertag kann mangels darstellbarer Exklusivgrenze nach `9999-12-31` nicht eingeschlossen werden. |
| Benutzerfreigabe | Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope wurden am 2026-08-30 besprochen. Der Benutzer hat die Umsetzung anschließend mit „lass es uns so machen“ ausdrücklich freigegeben. |
| Tests | Statischer Vertrag sowie die vollständigen lokalen, zentralen, Lifecycle-, Dependency-, Kollisions-, Grenz-, `DATEFIRST`- und Skalierungsadapter waren am 2026-08-30 auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. Die drei explizit ausgewählten Windows-Ziele waren bereits beim SQL-Anmeldungs-Preflight nicht erreichbar; Windows-Runtime bleibt `not executed`. Alle erzeugten synthetischen Datenbanken wurden entfernt, Lab-Systeme wurden nicht beendet. |
| Nächster Schritt | Pull Request 61 ist auf `main` gemerged. Windows-Runtime nach extern wiederhergestellter SQL-Erreichbarkeit nachholen. `release_status` bleibt bis zu einer ausdrücklich autorisierten Veröffentlichung `unreleased`. |

### R1a: Regex-Semantik- und Provider-Spike

| Feld | Wert |
|---|---|
| ID | `R1a`; konkretisiert `TC-2026-010`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Die native SQL-Server-2025-RE2-Semantik für einen möglichen ersten Slice aus `LIKE`, `INSTR` und `COUNT` gegen portable Provideroptionen prüfen, ohne eine Runtime-API zu implementieren. |
| Scope | Native 2025-Semantik und Compatibility-Level-Verfügbarkeit; .NET-Framework-4.8-Vergleich; RE2-/CLR-/Linux-, Lizenz-, Wartungs- und Dependency-Gates. Replace, Substring, Split, Matches, Fuzzy Matching und jedes öffentliche SQL-Objekt bleiben außerhalb. |
| Priorität | `P1` Research nach D1; blockiert keine fachlich unabhängige Welle |
| Status | `completed` für den Research-Scope; der getrennt freigegebene R1b-Slice ist inzwischen implementiert |
| Ergebnis | SQL Server 2025 ist die kanonische RE2-Referenz. `REGEXP_INSTR` und `REGEXP_COUNT` liefen unter Compatibility 150/160/170, `REGEXP_LIKE` nur unter 170. Der eingebaute .NET-Framework-Regexkern weicht semantisch ab und besitzt keine lineare Laufzeitgarantie. Native RE2-Wrapper benötigen plattformspezifischen nativen Code und sind mit `SAFE`/SQL Server Linux unvereinbar. Kein portabler Paritätsprovider wurde ausgewählt oder aufgenommen. |
| Alternativen | Exakter externer/native RE2-Provider; ausdrücklich engerer Toolbelt-Dialekt mit Parser, Transformationen und Timeout; reine SQL-Server-2025-Fassade. Reines T-SQL ist kein allgemeiner Regex-Provider. |
| Risiken und Grenzen | Eine bloße Pattern-Blacklist erzeugt keine RE2-Parität. Zeichenklassen, Anker, Flags, ungültige Konstrukte, Input-/Patternlimits, Timeoutfehler, ReDoS und Providerdeployment benötigen je nach Richtung einen neuen öffentlichen Vertrag. |
| Tests | Physischer SQL-Server-2025-Linux-Lauf mit Compatibility 150/160/170 und synthetischen Semantik-/Fehlervektoren am 2026-08-30 erfolgreich; .NET-Framework-4.8-Harness bestätigte die erwarteten Abweichungen. Die synthetische Datenbank und temporären Buildartefakte wurden entfernt; Windows-SQL-Runtime blieb `not executed`; Lab-Systeme wurden nicht beendet. |
| Evidenz | `Documentation/Research/REGEX_SEMANTICS_PROVIDER_SPIKE.md`, `Tests/Research/Regex/` und `.github/workflows/regex-provider-spike.yml`. Keine Drittanbieterbibliothek oder Binärdatei wurde heruntergeladen oder aufgenommen. |
| Nächster Schritt | R1b ist als eigener enger Toolbelt-Dialekt umgesetzt. Weitere Regex-APIs oder RE2-Parität benötigen neue Verträge und Freigaben. |

### R1b: Begrenzter Regex-Runtime-Slice

| Feld | Wert |
|---|---|
| ID | `R1b`; konkretisiert `TC-2026-010`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Portable Regex-Prüfung, Positionssuche und Zählung für SQL Server 2019, 2022 und 2025 mit bewusst kleiner, stabil dokumentierter Semantik. |
| Scope | `toolbelt.string.regex` 1.0.0 mit `SVF_RegexIsMatch`, `SVF_RegexInstr`, `SVF_RegexCount`; eigener Dialektparser, UTF-16-Positionen, ASCII-Kurzklassen, `\p{L}`, Flags `c/i/m/s`, 2-MiB-/8.000-Byte-/1.000-Quantifier-Grenzen und fixer 250-ms-Timeout. |
| Provider | Eine .NET-Framework-4.8-Assembly mit `SAFE`, direkten Referenzen nur auf System/System.Data und exaktem SHA2-512-Trust; keine Drittanbieter-/Native-Abhängigkeit, kein TRUSTWORTHY und keine automatische CLR-Konfiguration. |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Alternativen | Exakter RE2-/Native-Provider, SQL-Server-2025-Fassade und reines T-SQL wurden für R1b verworfen. |
| Risiken und Grenzen | Keine RE2-Parität oder lineare Laufzeit, SARGability oder Parallelplanzusage. Backtracking bleibt trotz Parser und Timeout möglich. Replace, Substring, Captures, Split und Matches sind ausgeschlossen. |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken, Scope und Reihenfolge wurden am 2026-08-30 besprochen. Der Benutzer hat anschließend „E1b und R1b wie besprochen implementieren“ ausdrücklich freigegeben. |
| Evidenz | `Documentation/Architecture/REGEX_MODULE_DESIGN.md`, Modulvertrag und synthetischer Adapter; vollständige physische Matrix SQL Server 2019/2022/2025 unter Windows base und Linux latest. |
| Nächster Schritt | Pull Request 65 ist auf `main` gemerged; die tatsächliche Veröffentlichung bleibt unautorisiert. |

### E1a: Work Queue Claim/Complete/Fail

| Feld | Wert |
|---|---|
| ID | `E1a`; konkretisiert `TC-2026-015`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Einen kleinen persistenten Queue-Kern bereitstellen, der ausschließlich registrierte Work Types einreiht, atomar beansprucht und tokengebunden terminal abschließt. |
| Scope | `toolbelt.core.work-queue` 1.0.0 mit `USP_EnqueueWork`, `USP_ClaimWork`, `USP_CompleteWork`, `USP_FailWork`, `USP_GetWorkStatus` und `VW_WorkQueue`. Zustände `QUEUED -> CLAIMED -> COMPLETED|FAILED`; Payload nur NONE oder JSON-Objekt bis 64 KiB; Statusoberflächen ohne Payload und ClaimToken. |
| Dependencies | `toolbelt.core.result-table` 1.0.0 und `toolbelt.core.work-type` 1.1.0 in derselben Datenbank; persistente Namenskonvention aus `DEC-2026-025`. |
| Priorität | `P1` nach D1 und R1a, als eigenständiger vertikaler Slice |
| Status | `implemented`; Runtime `partially validated`, Release `unreleased` |
| Alternativen | Service Broker, SQL Server Agent und externe Worker wurden nicht an E1a gekoppelt. Raw SQL oder Handlernamen in Payloads, öffentliche Claim-Token in Statusoberflächen und ein gemeinsamer Lease-/Retry-/Cancellation-Vertrag wurden verworfen. |
| Risiken und Grenzen | Keine Lease, Recovery, Retry, Dead Letter, Idempotency Key, Cancellation, Resultpersistenz oder automatische Ausführung. Ein Worker-Abbruch nach Claim lässt das Item dauerhaft `CLAIMED`; keine Exactly-once- oder absolute Fairnesszusage. |
| Benutzerfreigabe | Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope wurden am 2026-08-30 besprochen. Der Benutzer hat die Umsetzung anschließend mit „lass es uns so machen“ ausdrücklich nach D1 und R1a freigegeben. |
| Tests | Statischer Vertrag sowie E1a-Semantik, Caller-Transaktionen, vier echte Claim-Sessions, ResultTable, Dependency-/Kollisionspreflight, Redeployment, Central, Datenverlustschutz, Uninstall und Cleanup waren am 2026-08-30 auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. Die drei Windows-Base-Ziele waren bereits beim SQL-Anmeldungs-Preflight nicht erreichbar; Windows blieb `not executed`. |
| Evidenz | `Documentation/Architecture/WORK_QUEUE_MODULE_DESIGN.md`, `Modules/toolbelt.core.work-queue/` und `.github/workflows/work-queue-runtime.yml`; ausschließlich synthetische Daten und abstrahierte Evidenz. |
| Nächster Schritt | Pull Request 63 ist auf `main` gemerged; E1b ist als Version 1.1.0 umgesetzt. E1c Retry/Dead Letter/Idempotenz bleibt ohne eigene Freigabe offen. |

### E1b: Work Queue Lease/Heartbeat/Orphan Recovery

| Feld | Wert |
|---|---|
| ID | `E1b`; konkretisiert `TC-2026-015` und `TC-2026-021`, keine neue sequenzielle `AP`-Referenz ohne reguläre Vergabe |
| Ziel | Dauerhaft blockierte Claims durch eine begrenzte Lease erkennbar machen und ausschließlich über eine explizite Recovery wieder freigeben. |
| Scope | `toolbelt.core.work-queue` 1.1.0; Claim-Lease 5 bis 86400 Sekunden, monotone ClaimGeneration, `USP_RenewWorkLease`, `USP_RecoverExpiredWork`, aktive-Lease-Prüfung in Complete/Fail sowie geschützte Lease-/Recovery-Statusfelder. |
| Migration | Unterstütztes Upgrade `1.0.0 → 1.1.0`; aktive E1a-Claims blockieren vor jeder Mutation. QUEUED- und terminale Daten bleiben erhalten. |
| Status | `implemented`; Runtime `validated`; Release `unreleased` |
| Alternativen | Persistenter ORPHANED-Status, implizite Recovery im Claim, SessionId als Ownership, globale unbegrenzte Lease, automatische Supervisor-Ausführung und `KILL` wurden verworfen. |
| Risiken und Grenzen | Recovery kann bereits erfolgte fachliche Seiteneffekte wiederholen. Keine Exactly-once-Garantie, generische Idempotenz, Retry, Dead Letter, Cancellation, Attempt-Historie oder Worker-Orchestrierung. |
| Benutzerfreigabe | Zweck, Vertrag, Alternativen, Risiken, Scope und Reihenfolge wurden am 2026-08-30 besprochen. Der Benutzer hat anschließend „E1b und R1b wie besprochen implementieren“ ausdrücklich freigegeben. |
| Evidenz | `Documentation/Architecture/WORK_QUEUE_MODULE_DESIGN.md`, Modulvertrag und synthetischer Runtime-/Upgrade-Adapter; vollständige physische Matrix SQL Server 2019/2022/2025 unter Windows base und Linux latest erfolgreich. |
| Nächster Schritt | Pull Request 64 ist auf `main` gemerged; R1b folgte mit Pull Request 65 gemäß eigener Freigabe. |

### AP-2026-003: ResultTable-Kernmodul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-003` |
| Ziel | Das implementierungsreif spezifizierte Modul `toolbelt.core.result-table` vollständig implementieren, dokumentieren, installieren, deinstallieren und auf den verfügbaren Zielplattformen validieren. |
| Scope | `toolbelt.core.result-table`; Modulverzeichnis, `module.yaml`, `toolbelt_core.USP_PrepareResultTable`, parametergesteuertes Deploy- und Uninstall-Skript, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Runtime-, Collation-, Deployment- und Plattformtests. |
| Dependencies | `AP-2026-002`, `RESULT_TABLE_MODULE_DESIGN.md`, `RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017` und `DEC-2026-019`. |
| Priorität | `P0` |
| Status | `active` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Exakt ein persistentes SQL-Objekt in Version `1.0.0`; öffentliche Signatur und Help-Vertrag vollständig; `@LikeTable`-Schemaquelle, `@KeepData`-Matrix, Preflight, in-place-Umbau, Savepoint- und Fehlervertrag implementiert; lokale und zentrale Installation; kontrolliert wiederholbare Lifecycle-Skripte; keine nicht freigegebenen weiteren persistenten Objekttypen; Dokumentation und Manifest konsistent; alle verfügbaren Pflichtprüfungen ausgeführt und nicht verfügbare Prüfungen ehrlich ausgewiesen. |
| Tests | Statischer Vertrag und vollständige GitHub-hosted Linux-Matrix auf SQL Server 2019, 2022 und 2025 einschließlich Collation-, 1024-Spalten-, Transaktions-, natürlichem Savepoint-Enginefehler 2705, Multi-Session-, Central-/Lifecycle- und synthetischem Performance-Workload erfolgreich. Windows und weitere Plattformfälle bleiben `not executed`. |
| Blocker | Kein Merge-Blocker für den implementierten und teilweise validierten Stand. Für `validated` fehlen Windows-Evidenz und eine vergleichbare plattformübergreifende Performance-Baseline. |
| Evidenz | Benutzerfreigabe vom 2026-07-29; kanonische Artefakte unter `Modules/toolbelt.core.result-table/`; [Basislauf 30447442638](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30447442638), [erweiterter Lauf 30456207934](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30456207934), [Multi-Session-Lauf 30459004717](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30459004717) und [Savepoint-Enginefehler-Lauf 30692956855](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692956855) erfolgreich. |
| Nächster Schritt | Manuellen Windows-Runtime- und Performance-Nachweis gemäß `Modules/toolbelt.core.result-table/Tests/Manual_Windows_Runtime_Testplan.md` ausführen. Erst nach vollständiger Pflichtmatrix auf `validated` setzen. |


### AP-2026-023: Windows Filesystem SQL CLR

| Feld | Wert |
|---|---|
| ID | AP-2026-023 |
| Ziel | Windows-only Dateisystemzugriff als kontrolliertes SQL-CLR-Modul für Text/Binary, Codepages, Transcoding, Directory-Verwaltung und begrenztes rekursives Löschen implementieren. |
| Scope | toolbelt.filesystem.windows, C#-.NET-Framework-4.8-Assembly, T-SQL-Fassade, Root-Alias-Konfiguration, Trust-/Deployment-Lifecycle, Dokumentation, Contract-Matrix und Windows-Build. |
| Dependencies | toolbelt.core.result-table; separate administrative SHA2-512-Trust-Freigabe; Windows SQL Server mit kontrolliertem synthetischem Testroot. |
| Priorität | P1 |
| Status | `active` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Caller ist Default und wird bei SQL Authentication abgelehnt; ServiceAccount ist explizit; absolute Pfade und Reparse Points sind gesperrt; I/O arbeitet begrenzt/gestreamt; Write nutzt atomare Staging-Dateien; rekursives Delete besitzt Tiefe-/Eintragslimits; Linux ist korrekt not applicable. |
| Tests | Statischer Vertragscheck und GitHub-Windows-Build; manueller Windows-SQL-Server-/NTFS-Test für Deployment, beide Identitätsmodi, Codepages, Limits, Reparse Points, atomare Writes und rekursives Delete. |
| Blocker | Caller-Impersonation und die breitere manuelle NTFS-/I/O-Matrix sind noch nicht ausgeführt. |
| Evidenz | Benutzerfreigabe am 2026-07-31; Implementierung und Windows-Build-/Static-Contract-Artefakte auf `main`; Build-Nachweis im Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356. |
| Nächster Schritt | Manuellen Windows-SQL-Server-/NTFS-Runtime-Test gemäß `Modules/toolbelt.filesystem.windows/Tests/Manual_Windows_Runtime_Testplan.md` ausführen und ausschließlich abstrahierte Ergebnisse erfassen. |


## Abgeschlossene Arbeitspakete

### AP-2026-030: TC-2026-033 ZIP-Metadaten-Listing

| Feld | Wert |
|---|---|
| ID | `AP-2026-030` |
| Ziel | Ein vorhandenes In-memory-ZIP als strikt geprüftes, geordnetes Metadaten-Listing inventarisieren, ohne Payload zu extrahieren oder zu dekomprimieren. |
| Scope | `toolbelt.archive.zip-memory` Version `1.2.0`; neue öffentliche `toolbelt_archive.USP_ListZipEntriesFromBinary`; gemeinsamer SAFE-CLR-Parserkern; direkte Ausgabe sowie `@ResultTable`/`@KeepData`; klassische Single-Disk-ZIPs. |
| Dependencies | Bestehendes `toolbelt.archive.zip-memory` 1.1.0, `toolbelt.core.result-table` 1.0.0 und freigegebener Vertrag `Documentation/Architecture/ZIP_METADATA_MODULE_DESIGN.md`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Listing-only aus `varbinary(max)`; Central-Directory-Reihenfolge; deklarierte Größen/CRC; Directory-, Encryption-, Extraction-Support-, Duplicate- und Path-Safety-Status; UTF-8/CP437; strikte Strukturprüfung; harte Limits; ZIP64/Multi-Disk abgelehnt; unbekannte Methoden und verdächtige Entries werden gelistet statt verworfen. |
| Alternativen | Getrenntes Metadatenmodul, reine T-SQL-Implementierung und externer Worker wurden zugunsten der Erweiterung des vorhandenen SAFE-CLR-Moduls verworfen, damit der ZIP-Parserkern nur einmal existiert. |
| Risiken | Untrusted Central-Directory-Metadaten, Encoding-Abweichungen, große Entry-Mengen, irreführende deklarierte Größen/CRC und die klare Trennung zwischen Listing und Extraktionsfreigabe. |
| Tests | Statischer Vertrag; synthetische Struktur-/Encoding-/Pfad-/Duplicate-/Limitfälle; direkte Ausgabe und ResultTable; Local/Central; Upgrade 1.1.0→1.2.0; SQL Server 2019/2022/2025 Linux; Windows-Runtime später über SQL_Server_Lab. |
| Freigabe | Fachvertrag und Implementierung dieses konkreten V1-Slices am 2026-08-09 ausdrücklich durch den Benutzer freigegeben. |
| Evidenz | Modulartefakte unter `Modules/toolbelt.archive.zip-memory/`; statischer Vertragscheck, Windows-.NET-Framework-4.8-Build und die vollständige SQL-Server-2019-/2022-/2025-Linux-Matrix einschließlich Listing und Extraktion sind im [GitHub-Actions-Lauf 32701896453](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/32701896453) erfolgreich. |
| Nächster Schritt | Windows-SQL-Server-Runtime, reale Archive, echte Extremgrößen und den vollständigen Upgradepfad aus einem realen 1.1.0-Stand als Releaseevidenz ergänzen. |

### AP-2026-029: TC-2026-014 Rollback-independent Event Log

| Feld | Wert |
|---|---|
| ID | `AP-2026-029` |
| Ziel | Strukturierte Events synchron in einer zweiten Session persistieren, sodass sie Caller-Rollback und uncommittable Caller überleben. |
| Scope | `toolbelt.core.event-log` Version `1.0.0`, EventLog-Tabelle, View, Writer, Retention, interner Work Type sowie Second Session `@SuppressResult`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `partially validated` |
| Release Status | `unreleased` |
| Tests | SQL Server 2025 Linux CL150/160/170 erfolgreich; physische Linux-Läufe 2019 und 2022 scheitern im gemeinsamen W5-Vertrag. Rollback, uncommittable Caller, Context, Validierung, Retention, Concurrency, Redeploy, Central und Uninstall. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/31018284410 |
| Nächster Schritt | W5-Fehler auf Linux 2019/2022 isolieren und Windows-Releasevalidierung ausführen. |

### AP-2026-027: TC-2026-022 Work-Type-Katalog

| Feld | Wert |
|---|---|
| ID | `AP-2026-027` |
| Ziel | Einen persistenten sicheren Katalog für benannte Stored-Procedure-Work-Types bereitstellen, ohne eine Raw-SQL-Ausführungsschnittstelle zu schaffen. |
| Scope | `toolbelt.core.work-type` Version `1.0.0`, interne Tabelle `toolbelt_core.WorkType`, öffentliche Register-/Disable-/Resolve-USPs, `VW_WorkTypes`, lokale und zentrale Installation. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `partially validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Linux-Läufe erfolgreich; Registrierung, Update/RowVersion, Disable/Reaktivierung, Resolve, ResultTable, vier parallele Sessions, Redeploy, Central und Data-Loss-Uninstall-Schutz. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30703339193 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Windows-Releasevalidierung; der physische Linux-Lauf 2019/2022/2025 ist erfolgreich. Second-Session-Provider bleibt getrennte W5-Capability. |

### AP-2026-026: TC-2026-019 Execution Context

| Feld | Wert |
|---|---|
| ID | `AP-2026-026` |
| Ziel | Sessiongebundene Execution- und Correlation-Information ohne persistente Tabelle bereitstellen. |
| Scope | `toolbelt.core.execution-context` Version `1.0.0`, Begin/Set/End, inline TVF, SVF-Wrapper, lokales und zentrales Deployment. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `partially validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Linux-Läufe erfolgreich; vier parallele Sessions, Lifecycle, Central und Uninstall. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Windows-Releasevalidierung; der physische Linux-Lauf 2019/2022/2025 ist erfolgreich. Persistenter Ausführungsstatus bleibt ein getrennter Slice. |

### AP-2026-025: TC-2026-017 Error Envelope

| Feld | Wert |
|---|---|
| ID | `AP-2026-025` |
| Ziel | Explizit aus einem CATCH übergebene Fehlerdaten standardisieren, ohne den unveränderten Rethrow zu ersetzen. |
| Scope | `toolbelt.core.error-envelope` Version `1.0.0`, direkte und ResultTable-Ausgabe, lokale und zentrale Installation. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` |
| Validation Status | `partially validated` |
| Release Status | `unreleased` |
| Tests | Physische SQL-Server-2019-/2022-/2025-Linux-Läufe erfolgreich; Klassifikation, ResultTable, Lifecycle, Central und Uninstall. |
| Evidenz | https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30699604948 und lokaler physischer Linux-Lauf vom 2026-08-29 |
| Nächster Schritt | Windows-Releasevalidierung; der physische Linux-Lauf 2019/2022/2025 ist erfolgreich. Persistentes Logging bleibt getrennt. |

### AP-2026-024: TC-2026-037 File-Content-Slice 1

| Feld | Wert |
|---|---|
| ID | `AP-2026-024` |
| Ziel | Den portablen Read-only-Slice für kontrolliertes Text- und Binary-Lesen über `OPENROWSET(BULK...)` implementieren, registrieren und mit ausführbarer Evidenz belegen. |
| Scope | `toolbelt.file.content` Version `1.0.0`, Root-Allowlist, `toolbelt_file.USP_LoadBinaryFile`, `toolbelt_file.USP_LoadTextFile`, lokales und zentrales Deployment, Dokumentation, statische sowie Runtime-/Lifecycle-Contracts. Keine Schreiboperationen und kein externer Worker. |
| Dependencies | Keine Runtime-Modulabhängigkeit; administrative Bulk-Read-Berechtigung beziehungsweise Ad-hoc-Distributed-Queries entsprechend Deploymentvertrag. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Absolute Pfade nur innerhalb freigegebener Roots; Traversal-Ablehnung; Text/Binary-Vertrag, BOM-/Encoding-Metadaten, Limits, Hilfe, Deployment und Uninstall vorhanden. |
| Tests | SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170; statischer Vertrag, synthetische UTF-8-/UTF-16-/ANSI-/Binary-Fixtures, Allowlist, Lifecycle und Uninstall. |
| Blocker | Kein Merge-Blocker. Windows sowie nicht-ASCII-spezifische Providergrenzen bleiben Releasevalidierung. |
| Evidenz | Wartungslauf https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30692267356. |
| Nächster Schritt | Physische Windows-Evidenz nur capabilitybezogen beziehungsweise vor Release ergänzen; Schreiboperationen werden durch den getrennten Windows-Provider abgedeckt. |

### AP-2026-022: SQL CLR ZIP Build-/Deployment-Spike

| Feld | Wert |
|---|---|
| ID | `AP-2026-022` |
| Ziel | Den technisch kleinsten SQL-CLR-Providerpfad für ZIP Method 8 mit einer minimalen `SAFE`-Assembly kontrolliert bauen, deployen, ausführen und wieder entfernen. |
| Scope | C#-Projekt für .NET Framework 4.8; Raw-Deflate über `DeflateStream` aus der unterstützten `System.dll`; eigene CRC32-Prüfung; SHA2-512-Trust-Manifest; binäres `CREATE ASSEMBLY`; getrennte Trust-, Deploy-, Verify- und Uninstall-Skripte; positiver SQL-Server-2022-Linux-Runtime-Gate. Keine produktive ZIP-Funktion, keine öffentliche API und kein Modulmanifest. |
| Dependencies | `AP-2026-021`, `ZIP_CLR_PROVIDER_DESIGN.md`, `CLR_SECURITY_AND_PORTABILITY.md`, .NET-Framework-4.8-Targeting-Pack, MSBuild, SQLCMD und eine disposable SQL-Server-Testinstanz. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Keine direkte Referenz auf `System.IO.Compression.dll` oder `ZipArchive`; `DeflateStream` wird aus `System.dll` geladen; die Testassembly bleibt `SAFE`; der Trust-Hash entsteht aus dem konkreten Binary; Deployment benötigt keinen serverlokalen Buildpfad; tatsächlicher CLR-Aufruf prüft Payload und CRC32; kein Skript setzt `TRUSTWORTHY ON`, deaktiviert `clr strict security` oder verwendet `EXTERNAL_ACCESS`/`UNSAFE`; Uninstall berührt keinen Trust-Eintrag. |
| Tests | Statische Vertragsprüfung, Windows-GitHub-hosted .NET-Framework-Build und positiver SQL-Server-2022-Linux-Lauf mit Trust, `CREATE ASSEMBLY`, Deflate-/CRC32-Ausführung und Uninstall sind erfolgreich. SQL Server 2019, SQL Server 2025 und Windows-Runtime bleiben separate Pflichtläufe vor Produktfreigabe. |
| Blocker | Kein bekannter technischer Blocker für den korrigierten Deflate-/CRC32-Spike. Der frühere Fehler 10301 entstand durch den ungeeigneten `ZipArchive`-Pfad und die direkte Abhängigkeit von `System.IO.Compression.dll`. |
| Evidenz | `Spikes/sql-clr-zip-provider/README.md`, `Source/ZipClrProbe.cs`, `Tests/Static/validate_spike.py`, `.github/workflows/sql-clr-zip-spike.yml` und SQL CLR ZIP Spike Run 30608612435. |
| Nächster Schritt | Historische Spike-Evidenz beibehalten; die produktive Implementierung und weitere Plattformvalidierung werden in `AP-2026-020` geführt. |

### AP-2026-021: TC-2026-034 Verarbeitungswelle 3 (CLR-Provider Vertragswelle)

| Feld | Wert |
|---|---|
| ID | `AP-2026-021` |
| Ziel | Den separaten CLR-Providervertrag für `TC-2026-034` abschließen und die Sicherheits-, Lifecycle- und Plattformgrenzen vor einer Implementierung verbindlich festlegen. |
| Scope | Keine Runtime-Implementierung. Der Vertrag begrenzt einen optionalen C#-SQL-CLR-Provider auf In-memory-Extraktion einzelner Entries mit ZIP Method 0 und 8, einschließlich Payload-CRC-Prüfung; Dateisystem, Verschlüsselungsentschlüsselung, Deflate64, ZIP-Erzeugung und weitere Formate bleiben ausgeschlossen. |
| Dependencies | `AP-2026-020`, `TC-2026-034`, `Documentation/Architecture/ZIP_ARCHIVE_MODULE_DESIGN.md`, `Documentation/Architecture/CLR_SECURITY_AND_PORTABILITY.md`, Datenschutz- und Lifecycle-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Klarer Provider-Schnitt mit explizitem Non-Goal gegen Dateisystem-Default, definiertem Methodensubset (0 und 8), expliziter Payload-CRC-Prüfung, dokumentiertem Sicherheitsweg ohne pauschales `TRUSTWORTHY ON` sowie definiertem Assembly-Lifecycle und Test-/Spike-Gates. |
| Tests | Vertrags- und Designkonsistenz sowie dokumentierte Build-/Trust- und Runtime-Matrix. Diese Welle behauptet keine Runtime-Evidenz. |
| Blocker | Keine. Der Vertrag wurde durch die produktive SAFE-SQL-CLR-Implementierung erfüllt. |
| Evidenz | Benutzerauftrag vom 2026-07-30; Architekturvertrag `ZIP_CLR_PROVIDER_DESIGN.md`; Spike-Quellartefakte in `Spikes/sql-clr-zip-provider/`. |
| Nächster Schritt | Keine weitere Vertragswelle erforderlich; verbleibende Windows-Evidenz wird in `AP-2026-020` nachgeführt. |

### AP-2026-020: TC-2026-034 Verarbeitungswelle 2 (Implementierungswelle V1A)

| Feld | Wert |
|---|---|
| ID | `AP-2026-020` |
| Ziel | Den freigegebenen V1A-Slice von `TC-2026-034` als erstes lauffaehiges ZIP-Modul implementieren, dokumentieren und mit Runtime-Evidenz belegen. |
| Scope | `toolbelt.archive.zip-memory` Version `1.1.0` mit In-memory-Extraktion einzelner Eintraege aus `varbinary(max)`; kein Dateisystemzugriff, keine Archiv-Erzeugung, keine rekursive Entpackung, keine Passwortentschluesselung. |
| Dependencies | Abgeschlossene Vertragswelle `AP-2026-019`, Kandidaten `TC-2026-033` und `TC-2026-034`, Moduldesign `ZIP_ARCHIVE_MODULE_DESIGN.md`, USP-Vertrag, Modul- und Lifecycle-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Ein oeffentliches Objekt mit stabilem Help-/Fehler-/Resultset-Vertrag; Duplicate-Entry-Semantik als expliziter Fehler; harte Default-Limits (`@MaxEntryBytes = 104857600`, `@MaxCompressionRatio = 200.00`); verschluesselte Eintraege liefern bei `@FailIfEncrypted = 0` einen expliziten Status ohne Payload; lokale und zentrale Lifecycle-Artefakte sowie statische und Runtime-Tests vorhanden. |
| Tests | Windows-.NET-Framework-4.8-Build sowie SQL Server 2019, 2022 und 2025 unter Linux; auf SQL Server 2025 Compatibility Levels 150, 160 und 170. Trust, Stored, Deflate, Data Descriptor, Encoding, CRC32, Limits, ResultTable, Wiederholungsdeployment, Central und Uninstall erfolgreich. |
| Blocker | Kein Merge-Blocker. Windows-SQL-Server-Runtime und echte Extremgrößen-/Ressourcenläufe bleiben offen. |
| Evidenz | Produktives Modul `toolbelt.archive.zip-memory` Version `1.1.0`; Workflow [30615544206](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30615544206) erfolgreich. |
| Nächster Schritt | Windows-SQL-Server-Runtime gezielt ausführen; ZIP-Erzeugung und vollständige Dateisystemextraktion bleiben getrennte spätere Slices. |

### AP-2026-019: TC-2026-034 Verarbeitungswelle 1 (Vertragswelle)

| Feld | Wert |
|---|---|
| ID | `AP-2026-019` |
| Ziel | Die erste Verarbeitungswelle fuer `TC-2026-034` als belastbare V1-Vertragsbasis abschliessen und die anschliessende Implementierungsfreigabe vorbereiten. |
| Scope | Keine Runtime-Implementierung. V1A auf In-memory-Extraktion einzelner ZIP-Eintraege begrenzen, Dateisystempfade ausschliessen, Sicherheitsgrenzen und Ergebnisvertrag dokumentieren, Testmatrix und Lifecycle-Scope vorbereiten. |
| Dependencies | `TC-2026-034`, `TC-2026-033`, `TC-2026-037`, `TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md`, `WORKING_RULES.md`, `PROJECT_RULES.md`. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | V1A-Vertrag ist dokumentiert, Nicht-Ziele sind explizit, Provider ist auf In-memory begrenzt, Sicherheits- und Testrahmen sind definiert. |
| Tests | Vertragskonsistenz und Dokumentationsvalidator erfolgreich; Runtime fuer diese Welle `not applicable`. |
| Blocker | Keine offenen Vertragsblocker nach Benutzerfreigabe. |
| Evidenz | `ZIP_ARCHIVE_MODULE_DESIGN.md`, aktualisierte Kandidaten- und Planartefakte, Benutzerentscheid am 2026-07-30. |
| Nächster Schritt | Implementierungswelle als `AP-2026-020` aktiv. |

### AP-2026-018: W2c Console Message und Capability Catalog

| Feld | Wert |
|---|---|
| ID | `AP-2026-018` |
| Ziel | Die freigegebenen Kandidaten `TC-2026-016` und `TC-2026-023` als zwei unabhängige portable Module implementieren und prüfen. |
| Scope | `toolbelt.core.console-message` Version `1.0.0` mit `toolbelt_core.USP_WriteConsoleMessage`; `toolbelt.metadata.capability-catalog` Version `1.0.0` mit `toolbelt_metadata.VW_ModuleCapabilities`; lokale und zentrale Installation; keine Präfixe, Severity-Optionen, Registry, Filter-TVF oder `module.yaml`-Runtime-Abhängigkeit. |
| Dependencies | W2c-Hauptempfehlung und ausdrückliche Benutzerfreigabe vom 2026-07-30; USP-, Modul-, Lifecycle- und Metadata-Verträge; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Unicode-sichere vollständige Message-Chunks mit PRINT oder NOWAIT; NULL ohne Ausgabe; kein fachliches Resultset; read-only Projektion kanonischer Database-level Marker; `valid`/`incomplete`/`invalid`; vollständige Source-, Lifecycle-, Dokumentations-, Contract- und CI-Artefakte; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Verträge und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 einschließlich Capture-Markern, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich; vollständige Adapter am 2026-08-29 auf physischen SQL-Server-2019-/2022-/2025-Linux-Zielen erfolgreich. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlen Windows-Evidenz sowie weitere Client-/Treiber- beziehungsweise eingeschränkte Metadata-Visibility-Läufe. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesigns `CONSOLE_MESSAGE_MODULE_DESIGN.md` und `CAPABILITY_CATALOG_MODULE_DESIGN.md`; kanonische Artefakte unter `Modules/toolbelt.core.console-message/` und `Modules/toolbelt.metadata.capability-catalog/`; [W2c Runtime 30573135975](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573135975), [Documentation Consistency 30573136009](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30573136009) und lokaler physischer Linux-Lauf vom 2026-08-29 erfolgreich. |
| Nächster Schritt | Windows- und modulspezifische Releasevalidierung gezielt planen. |

### AP-2026-017: W2b-A JSON Path Exists

| Feld | Wert |
|---|---|
| ID | `AP-2026-017` |
| Ziel | Den freigegebenen Pfadprüfungs-Slice von `TC-2026-009` als portables Modul für SQL Server 2019+ implementieren und prüfen. |
| Scope | `toolbelt.json.path-exists` Version `1.0.0`; öffentliche `toolbelt_json.TVF_JsonPathExists`; Root-, Property-, Quote-, Array-Index- und Wildcard-Pfade; SQL-NULL-Propagation; fehlerfreies `0` bei ungültigem JSON oder Pfad; lokales und zentrales Deployment. Keine JSON-Konstruktoren, Aggregate, SQL CLR, Scalar-Wrapper oder SQL-Server-2025-Preview-Ranges/-Listen/`last`. |
| Dependencies | Gemeinsame W2b-Vertragsrunde und ausdrückliche Benutzerfreigabe vom 2026-07-30; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | `1`/`0`/SQL-`NULL` als `int`; JSON `null` zählt als vorhanden; case-sensitive BIN2-Keyvergleich; Pfad- und JSON-Fehler verlassen den Funktionsvertrag nicht; vollständige Source-, Lifecycle-, Dokumentations-, Contract- und CI-Artefakte; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Prüfung und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 mit nativer Parität, synthetischen Fehler-/Collation-Fällen, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich. |
| Blocker | Keine. Windows-Läufe bleiben Releasevalidierung. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesign `JSON_PATH_EXISTS_MODULE_DESIGN.md`; kanonische Artefakte unter `Modules/toolbelt.json.path-exists/`; [W2b JSON Path Runtime 30568128943](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128943), [Documentation Consistency 30568128932](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30568128932) und lokaler physischer Linux-Lauf vom 2026-08-29 erfolgreich. |
| Nächster Schritt | Windows-Releasevalidierung gezielt ausführen. |

### AP-2026-016: Portable W2a – Truncation, Bucketing und Bigint-Bitoperationen

| Feld | Wert |
|---|---|
| ID | `AP-2026-016` |
| Ziel | Die gemeinsam geplanten Kandidaten `TC-2026-004`, `TC-2026-005` und `TC-2026-007` als drei portable Compatibility-Module implementieren und prüfen. |
| Scope | `toolbelt.datetime.truncate`, `toolbelt.datetime.bucket` und `toolbelt.binary.bit-operations`; typgetrennte öffentliche Date/Time-Inline-TVFs, interner Bucket-Optimizer-Core, Bigint-Shift/Count/Get/Set, Lifecycle, Central Deployment, Dokumentation und synthetische Contract-Tests. Keine Scalar UDFs, keine `datetime`-/`smalldatetime`-/`time`-Familie und kein `binary(n)`-/`varbinary(n)`-Provider. |
| Dependencies | Funktionsbezogener W2a-Vorschlag im Implementierungsplan und ausdrückliche Benutzerfreigabe vom 2026-07-30; keine Runtime-Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Typstabile relationale APIs; dokumentierte Dateparts, Scale-7-, `DATEFIRST`-, Origin-, negative Floor-, Shift-, Vorzeichen- und Validation-Code-Semantik; lokale und zentrale Installation; Wiederholungsdeployment und Uninstall; native Parität auf SQL Server 2022/2025; Status nur aus tatsächlicher Evidenz. |
| Tests | Statische Contracts und SQL-Server-2025-Linux-Workflow für Compatibility Levels 150/160/170 einschließlich Runtime, nativer Parität, Wiederholungsdeployment, Lifecycle, Central und Uninstall erfolgreich. |
| Blocker | Keine. Windows-Läufe bleiben Releasevalidierung. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; Moduldesigns `DATETIME_TRUNCATE_MODULE_DESIGN.md`, `DATETIME_BUCKET_MODULE_DESIGN.md` und `BIT_OPERATIONS_MODULE_DESIGN.md`; [W2a Portable Runtime 30561236509](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561236509), [Documentation Consistency 30561235177](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30561235177) und lokaler physischer Linux-Lauf vom 2026-08-29. |
| Nächster Schritt | Windows-Releasevalidierung sowie gezielte Bucket-Core-Performance-Evidenz ausführen. |

### AP-2026-015: Portable W1 – Calendar Difference, Directional TRIM und URI Component

| Feld | Wert |
|---|---|
| ID | `AP-2026-015` |
| Ziel | Die gemeinsam besprochenen Kandidaten `TC-2026-002`, `TC-2026-008` und `TC-2026-024` als drei unabhängige, portable Module implementieren. |
| Scope | `toolbelt.datetime.calendar-difference`, `toolbelt.string.directional-trim` und `toolbelt.conversion.uri-component`; öffentliche inline TVFs, optionale URI-Scalar-APIs, Lifecycle, Dokumentation und synthetische Contract-Tests. |
| Dependencies | Funktionsbezogene Besprechung und ausdrückliche Benutzerfreigabe vom 2026-07-30; für TRIM und URI `toolbelt.core.generate-series` Version `1.0.0`. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Anniversary-Regel, gerichtetes und typstabiles Trim sowie RFC-3986-Komponentenencoding sind explizit dokumentiert; keine implizite IRI-, Form-Encoding- oder Double-Decoding-Semantik. |
| Tests | Statische Contracts und GitHub-hosted SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 erfolgreich; Anniversary-, Grenzwert-, Unicode-/UTF-8-, Fehler-, Paritäts-, Wiederholungs-, lokaler, zentraler und Uninstall-Scope geprüft. |
| Blocker | Keine. Windows-Läufe bleiben Releasevalidierung. |
| Evidenz | Benutzerfreigabe 2026-07-30; [W1 Portable Runtime 30553118399](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118399), [Documentation Consistency 30553118014](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30553118014) und lokaler physischer Linux-Lauf vom 2026-08-29. |
| Nächster Schritt | Windows-Läufe sowie die noch offenen LOB-, Collation- und Kollisionsfälle im Rahmen der Releasevalidierung ausführen. |

### AP-2026-014: Inline-TVF-Alternativen für bestehende SVFs

| Feld | Wert |
|---|---|
| ID | `AP-2026-014` |
| Ziel | Für alle fachlich geeigneten vorhandenen SVFs eine semantisch äquivalente inline-TVF-API bereitstellen und die inline TVF als kanonischen relationalen Kern verwenden. |
| Scope | `toolbelt.conversion.base64`, `toolbelt.conversion.integer-base` und `toolbelt.validation.semantic-version`; sechs neue inline TVFs gemäß `SVF_INLINE_TVF_AUDIT.md`; vorhandene SVFs bleiben als Convenience-API erhalten. |
| Dependencies | Benutzeranforderung vom 2026-07-30; `DEC-2026-022`; bestehende öffentliche Verträge der sechs SVFs. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Kein TVF-Wrapper ruft lediglich die SVF auf; Fachlogik besitzt genau einen kanonischen Kern; Parität, Objekttyp, `NULL`- und Fehlersemantik, lokale und zentrale Installation sowie Lifecycle sind getestet; Objekt- und Moduldokumentation zeigt `APPLY` als bevorzugte Mengenverwendung. |
| Tests | Statische Modulverträge und vollständiger Dokumentationsaudit erfolgreich; Runtime auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 einschließlich Parität, `APPLY`, Upgrade, Wiederholung, Kollision, zentralem Deployment und Uninstall erfolgreich. |
| Blocker | Keine. Windows-Läufe bleiben Releasevalidierung. |
| Evidenz | `DEC-2026-022`, `Documentation/Architecture/SVF_INLINE_TVF_AUDIT.md`; [Base64 Runtime 30535377837](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377837), [Integer-Base Runtime 30535377860](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377860), [Semantic-Version Runtime 30535377984](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377984), [Documentation Consistency 30535377863](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30535377863). |
| Nächster Schritt | Windows-Läufe im Rahmen der Releasevalidierung ausführen. |

### AP-2026-013: Frei definierbare Zahlensysteme implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-013` |
| Ziel | `TC-2026-031` als Integer-Encode-/Decode-Capability mit frei definierbarem Alphabet implementieren. |
| Scope | `toolbelt.conversion.integer-base` Version `1.0.0`; vollständiger `bigint`-Bereich; Alphabet mit 2 bis 93 druckbaren ASCII-Zeichen außer `-`; kanonische Encode-/Decode-Darstellung und Overflow-Vertrag. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Encode/Decode verwenden denselben kanonischen Alphabetvertrag; Zeichen sind binär eindeutig; ungültiges Alphabet, ungültige Ziffer, Vorzeichen, `bigint`-Minimum, Null und Overflow sind dokumentiert und getestet; vollständiger Lifecycle und gekoppelte Dokumentation. |
| Tests | Statischer Vertrag, SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 und physischer Linux-Lauf 2019/2022/2025 vom 2026-08-29 erfolgreich; Windows-Läufe bleiben `not executed`. |
| Blocker | Keine bekannten. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-031`; kanonische Artefakte unter `Modules/toolbelt.conversion.integer-base/`; erfolgreicher [Runtime-Lauf 30518087070](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30518087070); persönlicher Brainstorm als Herkunft. |
| Nächster Schritt | Windows-Releasevalidierung später gezielt ausführen. |

### AP-2026-012: Semantic-Version Parser und Comparator implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-012` |
| Ziel | `TC-2026-030` als strikt SemVer-2.0.0-konformen Parser, Comparator und Sort Key implementieren. |
| Scope | `toolbelt.validation.semantic-version` Version `1.0.0`; ASCII `varchar(8000)`; Core, Pre-release, Build Metadata, Validierung, Präzedenzvergleich und binärer Sort Key; keine allgemeinen Produktversionsformate. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | SemVer-2.0.0-Grammatik und Präzedenz vollständig; Build Metadata beeinflusst Vergleich und Key nicht; beliebig lange numerische Komponenten ohne verlustbehaftete Konvertierung; offizielle und synthetische Vektoren, Lifecycle und Dokumentation vollständig. |
| Tests | Statischer Vertrag, SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 und physischer Linux-Lauf 2019/2022/2025 vom 2026-08-29 erfolgreich; Windows-Läufe bleiben `not executed`. |
| Blocker | Keine bekannten. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-030`; kanonische Artefakte unter `Modules/toolbelt.validation.semantic-version/`; erfolgreicher [Runtime-Lauf 30517137373](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30517137373). |
| Nächster Schritt | Windows-Releasevalidierung später gezielt ausführen. |

### AP-2026-011: Multi-Separator-Split Version 1 implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-011` |
| Ziel | `TC-2026-001` als portablen Split-Vertrag für mehrere einzelne Trennzeichen implementieren. |
| Scope | `toolbelt.string.split-characters` Version `1.0.0`; `TVF_SplitByCharacters`; stabile Ordinals, definierte leere Tokens, einzelne Separatorzeichen, binärer Collation- und LOB-Vertrag; keine mehrzeichigen Separatoren, Quote- oder Escape-Semantik. |
| Dependencies | `toolbelt.core.generate-series` Version `1.0.0`; vollständige Vertragsbesprechung und Sammelfreigabe vom 2026-07-30. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Literalvertrag bleibt von Regex getrennt; Token und Ordinal sind deterministisch; `NULL`, NUL, leerer Input, aufeinanderfolgende Separatoren, Separator am Rand, Collations und Größenklassen sind dokumentiert und getestet; vollständiger Lifecycle und gekoppelte Dokumentation. |
| Tests | Statischer Vertrag, SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 und physischer Linux-Lauf 2019/2022/2025 vom 2026-08-29 erfolgreich; Windows-Läufe bleiben `not executed`. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlt Windows-Evidenz. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-001`; kanonische Artefakte unter `Modules/toolbelt.string.split-characters/`; [Split-Characters Runtime Run 30516116708](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30516116708) erfolgreich. |
| Nächster Schritt | Windows-Läufe gezielt vor Release ausführen. `TC-2026-032` bleibt Research ohne Implementierungsfreigabe. |

### AP-2026-010: Identifier- und Multipart-Name-Toolkit implementieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-010` |
| Ziel | Den aus `RI-2026-011` formalisierten und freigegebenen Vertrag `TC-2026-029` als portables Metadata-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.metadata.identifier` Version `1.0.0`; `TVF_ParseMultipartName` und `SVF_QuoteMultipartName`; ein- bis vierteilige Namen, `[...]`, `]]`, ausgelassene mittlere Teile, stabile Validation Codes, lokales und zentrales Deployment. Keine Objektauflösung, Berechtigungsprüfung, doppelten Anführungszeichen oder CLR. |
| Dependencies | Vollständige Vertragsbesprechung und Sammelfreigabe des Benutzers vom 2026-07-30; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Modulabhängigkeit. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zustandsbasierter kanonischer Parser; genau eine Ergebniszeile; rechtsbündige Teile; vollständige Escape-, Omission-, Längen-, Collation-, Wrapper-, Deployment- und Lifecycle-Contracts; Dokumentation und Change-Impact-Registry gekoppelt. |
| Tests | Statischer Vertrag, SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 und physischer Linux-Lauf 2019/2022/2025 vom 2026-08-29 erfolgreich; Windows-Läufe bleiben `not executed`. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlt Windows-Evidenz. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; formaler Kandidat `TC-2026-029`; kanonische Artefakte unter `Modules/toolbelt.metadata.identifier/`; [Identifier Runtime Run 30514751834](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30514751834) erfolgreich. |
| Nächster Schritt | Windows-Läufe gezielt vor Release ausführen. |

### AP-2026-009: Portable Ganzzahlreihen implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-009` |
| Ziel | Den freigegebenen Vertrag von `TC-2026-006` als portables Core-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.core.generate-series` Version `1.0.0`; `TVF_GenerateSeriesInt` und `TVF_GenerateSeriesBigInt`; portable T-SQL Inline TVFs; lokales und zentrales Deployment; Richtungs-, Default-, NULL-, Fehler-, Grenz-, Größen-, Join-, `CROSS APPLY`-, native Paritäts- und Lifecycle-Tests. Keine Dezimaltypen, persistente Numbers-Tabelle oder SQL CLR. |
| Dependencies | Besprochener und am 2026-07-30 ausdrücklich freigegebener Funktionsvertrag; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Abhängigkeit zu einem anderen Toolbelt-Modul. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zwei öffentliche Inline TVFs im Schema `toolbelt_core`; typstabile `int`-/`bigint`-Resultsets; gemeinsamer `bigint`-Kern; richtungsabhängiger Default; keine stille Kürzung; Enginefehler bei Schritt `0` und nicht darstellbarer Zeilenzahl; vollständige gekoppelte Dokumentation und Lifecycle-Artefakte; SQL Server 2025 mit Compatibility Levels 150/160/170 erfolgreich. |
| Tests | Statische Vertragsprüfung, serieller GitHub-hosted SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 und physischer Linux-Lauf 2019/2022/2025 vom 2026-08-29 erfolgreich; Windows-Läufe bleiben `not executed`. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlen Windows-Evidenz sowie eine breitere Performancebewertung sehr großer Reihen. |
| Evidenz | Benutzerfreigabe vom 2026-07-30; kanonische Artefakte unter `Modules/toolbelt.core.generate-series/`; [Generate-Series Runtime Run 30496759324](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30496759324) erfolgreich. |
| Nächster Schritt | Windows-Läufe gezielt vor Release ausführen. |

### AP-2026-008: Base64/Base64URL-Modul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-008` |
| Ziel | Den freigegebenen Vertrag von `TC-2026-012` als portables Conversion-Modul implementieren, dokumentieren und gezielt validieren. |
| Scope | `toolbelt.conversion.base64` Version `1.0.0`; `SVF_Base64Encode` und `SVF_Base64Decode`; T-SQL/XML-Provider; lokales und zentrales Deployment; RFC-4648-, native Paritäts-, Fehler-, Größen- und Lifecycle-Tests. Kein CLR, keine Zeichenkodierung und keine Datei-I/O. |
| Dependencies | Besprochener und am 2026-07-29 ausdrücklich freigegebener Funktionsvertrag; scopebezogenes Qualitäts-Gate aus `DEC-2026-021`; keine technische Abhängigkeit zu ResultTable. |
| Priorität | `P1` |
| Status | `completed` |
| Implementation Status | `implemented` – abgeleitet aus `module.yaml` |
| Validation Status | `partially validated` – abgeleitet aus `module.yaml` |
| Release Status | `unreleased` – abgeleitet aus `module.yaml` |
| Akzeptanzkriterien | Zwei öffentliche Scalar UDFs im Schema `toolbelt_conversion`; Standard- und URL-safe-Ausgabe; Decode beider Alphabete, optionales Padding und definierter Whitespace; unveränderte Providerfehler; keine String-zu-Binär-Konvertierung; vollständige gekoppelte Dokumentation und Lifecycle-Artefakte; SQL Server 2025 mit Compatibility Levels 150/160/170 erfolgreich. |
| Tests | Statische Vertragsprüfung, serieller GitHub-hosted SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 und physischer Linux-Lauf 2019/2022/2025 vom 2026-08-29 erfolgreich; Windows-Läufe bleiben `not executed`. |
| Blocker | Kein Merge-Blocker. Für `validated` fehlen Windows-Evidenz sowie eine breitere Performancebewertung großer LOBs. |
| Evidenz | Benutzerfreigabe vom 2026-07-29; kanonische Artefakte unter `Modules/toolbelt.conversion.base64/`; [Base64 Runtime Run 30493304673](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30493304673) erfolgreich. |
| Nächster Schritt | Windows-Läufe gezielt vor Release ausführen. |

### AP-2026-007: Entscheidungsvorbereitung für das zweite Modul

| Feld | Wert |
|---|---|
| ID | `AP-2026-007` |
| Ziel | Die nächsten kleinen Compatibility-Kandidaten so vergleichen, dass die funktionsbezogene Benutzerbesprechung ohne verdeckte Typ-, Provider- oder Fehlerentscheidungen geführt werden kann. |
| Scope | Vertiefter Vergleich von `TC-2026-004` und `TC-2026-012`; dokumentierte Empfehlung, Vertragsfragen, Provideroptionen, Testdimensionen, Abhängigkeiten und Implementierungs-Gates. Keine SQL-Implementierung und kein Modulmanifest. |
| Dependencies | `AP-2026-003`, `AP-2026-005`, funktionsbezogenes Implementierungs-Gate und Phase-2-Abhängigkeit aus der Roadmap. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Bevorzugter Besprechungskandidat nachvollziehbar ausgewählt; Alternative mit konkretem Grund zurückgestellt; offene Benutzerentscheidungen und Pflichtprüfungen sichtbar; kein öffentlicher Funktionsvertrag oder Implementierungsrecht behauptet. |
| Tests | Primärquellenabgleich gegen Microsoft Learn und RFC 4648; Kandidaten-, Backlog-, Roadmap-, Link-, Datenschutz- und Change-Impact-Prüfung. Runtime-Tests sind für diese reine Entscheidungsvorbereitung `not applicable`. |
| Blocker | Keine. Der konkrete Vertrag wurde am 2026-07-29 besprochen und freigegeben; das pauschale Referenzmodul-Gate wurde durch `DEC-2026-021` scopebezogen präzisiert. |
| Evidenz | `Documentation/Research/SECOND_MODULE_SELECTION.md` und aktualisierte Kandidaten `TC-2026-004`/`TC-2026-012`; geprüft am 2026-07-29. |
| Nächster Schritt | Abgeschlossen; Umsetzung erfolgt in `AP-2026-008`. Die offenen ResultTable-Pflichtfälle bleiben ein eigenes Arbeitspaket. |

### AP-2026-006: Dokumentationsbaseline und inkrementeller Drift-Schutz

| Feld | Wert |
|---|---|
| ID | `AP-2026-006` |
| Ziel | Die vollständige Dokumentationsbaseline herstellen und nachfolgende Änderungen über explizite, diff-basierte Artefaktkopplungen synchron halten. |
| Scope | Statuskorrekturen, getrennte Modulstatusdimensionen, Modulregistry, gekoppelte Dokumentationspfade, generierte Statusabschnitte, inkrementeller Validator, pfadbezogene CI und Pull-Request-Checkliste. |
| Dependencies | aktueller `main`, implementiertes ResultTable-Modul und `DEC-2026-020`. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Einmaliger Vollaudit erfolgreich; bekannte Statusdrift beseitigt; Runtime-CI nicht mehr durch reine Dokumentationsänderungen ausgelöst; Folgeprüfungen diff-basiert; geschützte Lizenzinhalte unverändert. |
| Tests | Python-Standardbibliothek-Validator, modulspezifische statische Prüfung, Markdown-Linkprüfung, YAML-/Workflow-Strukturprüfung, Datenschutz-/Secret-Diffprüfung und GitHub Actions. |
| Blocker | Keine. |
| Evidenz | Lokaler vollständiger Baseline-Audit am 2026-07-29 erfolgreich; [Documentation Consistency Run 30453805254](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30453805254) und [ResultTable Runtime Run 30453805186](https://github.com/gecompat/SQL_Server_Toolbelt/actions/runs/30453805186) vollständig erfolgreich. |
| Nächster Schritt | Abgeschlossen; die laufende Dokumentationskonsistenz wird durch den inkrementellen Validator geschützt. |

### AP-2026-005: SQL-Server-Toolbelt-Landschaft und Prior Art

| Feld | Wert |
|---|---|
| ID | `AP-2026-005` |
| Ziel | Öffentliche SQL-Server-Toolbox-, Capability-, Test-, Diagnose-, Maintenance- und Parallelisierungsprojekte systematisch vergleichen, belastbare Prior Art für die bereits erfassten Execution-Themen dokumentieren und neue Toolbelt-Lücken ableiten. |
| Scope | Landschaftsdokument mit direkter Einordnung von 16 Projekten; vertiefter Vergleich der direkten Capability-Libraries; zweite Session, rollback-unabhängiges Logging, Parallelisierungsprovider, Console, Error Handling und Cancellation; Präzisierung von `TC-2026-012`; neue Kandidaten `TC-2026-023` bis `TC-2026-028`; quellenbasierte Vorprüfung des persönlichen Brainstorms einschließlich PowerShell, Python, REST/Web und KI/Chat. |
| Dependencies | `AP-2026-001`, `AP-2026-004`, Repository-Grenzen, Third-Party-/Source-Policy und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Projekte nach Rolle, Technik, Packaging, Lizenz-/Statushinweis und Repository-Ziel eingeordnet; direkte Analogien von bloßen Skriptkatalogen getrennt; Prior Art für zweite Session, Parallelisierung, Host-Automation, Python, REST und KI aus Primärquellen dokumentiert; übertragbare und zu vermeidende Muster benannt; neue Kandidaten vollständig und ohne Implementierungszusage erfasst. |
| Tests | Quellen- und Linkstrukturprüfung; Duplikatprüfung gegen kuratierte Kandidatenlisten, persönlichen Brainstorm und Architekturverträge; Third-Party-, Datenschutz- und Secret-Gate; ausschließlich Dokumentations- und Backlogänderungen. |
| Blocker | Keine für Research; Codeübernahme benötigt zusätzlich eine datei- und versionsbezogene Lizenzprüfung. Jede Funktion benötigt vor Implementierung weiterhin eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md`, präzisierter Kandidat `TC-2026-012`, aktualisierte Kandidaten `TC-2026-014`/`TC-2026-015` und neue Kandidaten `TC-2026-023` bis `TC-2026-028`; geprüft am 2026-07-29. |
| Nächster Schritt | Forschungsergebnis nach Abschluss der ResultTable-Validierungswelle mit dem Benutzer priorisieren; keine automatische Aktivierung eines weiteren Implementierungsarbeitspakets. |

### AP-2026-004: Backlog Research Wave 2 – Execution Infrastructure

| Feld | Wert |
|---|---|
| ID | `AP-2026-004` |
| Ziel | Die vom Benutzer angestoßenen Ideen zu zweiter Session, rollback-unabhängigem Logging, Parallelisierung, Error Handling, Console-Ausgabe und Gruppenabbruch quellenbasiert erfassen und um unmittelbar notwendige Supporting Capabilities ergänzen. |
| Scope | `TC-2026-014` bis `TC-2026-022`; Toolbelt-Kandidaten für autonome Ereignisprotokollierung, Work Queue, Console, Error Envelope, Cancellation, Correlation, Retry/Dead-letter, Worker Lease und sicheren Work-Type-Katalog. |
| Dependencies | Repository-Grundaufbau, Backlog-Curator-Regeln und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, vollständige Felder, Primärquellen, klare Trennung dokumentierter Engine-Semantik von offenen Architekturentscheidungen sowie einen nächsten Besprechungsschritt; kein Runtime-Objekt und keine Implementierungsfreigabe werden erzeugt. |
| Tests | Duplikatprüfung gegen alle drei Kandidatenlisten und bestehende Architekturverträge; Quellenprüfung gegen Microsoft Learn und den Microsoft SQL Server Blog; Datenschutz- und Secret-Gate. |
| Blocker | Keine für die Research-Erfassung; jede spätere Funktion benötigt eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Backlog/TOOLBELT_CANDIDATES.md`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | Kandidaten einzeln nach Nutzen und Abhängigkeiten mit dem Benutzer besprechen; keine automatische Aktivierung als Implementierungsarbeitspaket. |

### AP-2026-002: ResultTable-Infrastruktur implementierungsreif spezifizieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-002` |
| Ziel | Den Kandidaten `TC-2026-003` als erstes `toolbelt_core`-Modul ohne offene Vertragsfragen spezifizieren. |
| Scope | Modulgrenze, Objektinventar, öffentliche Schnittstelle, Schemaquelle, Metadaten- und Datentypnormalisierung, `@KeepData`, Preflight, DDL, Transaktionen, Fehler, Deployment, Lifecycle und Testmatrix. |
| Dependencies | `TC-2026-003`, `USP_CONTRACT.md`, Modul- und Deployment-Modell. |
| Priorität | `P0` |
| Status | `completed` |
| Akzeptanzkriterien | Modul-ID und Scope festgelegt; einzige Procedure klassifiziert; keine ungeregelten weiteren persistenten Objekttypen benötigt; Referenztabellen- und Vertrauensgrenze definiert; interne Temp-Namensregel festgelegt; Fehler-, Transaktions-, Collation-, Datentyp-, Deploy- und Uninstall-Verträge dokumentiert; vollständige Testmatrix vorhanden. |
| Tests | Statischer Abgleich gegen USP-Vertrag, T-SQL-Regeln, Modul-/Deployment-Modell, Namenskonventionen, Datenschutz, Supportmatrix und Architekturentscheidungen; Runtime-Tests für diese reine Designwelle `not applicable`. |
| Blocker | Keine |
| Evidenz | `Documentation/Architecture/RESULT_TABLE_MODULE_DESIGN.md`, `Tests/RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017`; geprüft am 2026-07-29. |
| Nächster Schritt | `AP-2026-003` ausführen. |

### AP-2026-001: Backlog Research Wave 1

| Feld | Wert |
|---|---|
| ID | `AP-2026-001` |
| Ziel | Eine erste belastbare, versionsbezogene Kandidatenwelle für SQL Server 2019, 2022 und 2025 erstellen. |
| Scope | `Backlog/TOOLBELT_CANDIDATES.md`; vorhandene Kandidaten präzisieren und neue Compatibility-, Core-, String-, Datetime-, JSON- und Binary-Kandidaten erfassen. |
| Dependencies | Repository-Grundaufbau und Backlog-Curator-Regeln. |
| Priorität | `P1` |
| Status | `completed` |
| Akzeptanzkriterien | Kandidaten besitzen stabile IDs, Ziel-Repository, Versionsbezug, spätere native Funktion, Nutzen, Technologieoptionen, Performance-/Security-Aspekte, Plattformgrenzen, Duplikatprüfung, Primärquellen, Prüfdatum und nächsten Schritt. |
| Tests | Primärquellenprüfung gegen Microsoft Learn; Duplikatprüfung innerhalb der Toolbelt-Listen; Abgrenzung zu `SQL_Server_Analyze`; Fakten und offene Punkte getrennt formuliert. |
| Blocker | Keine |
| Evidenz | `TC-2026-001` bis `TC-2026-013`, geprüft am 2026-07-29. Keine Runtime- oder Implementierungsvalidierung behauptet. |
| Nächster Schritt | Weitere Kandidatenwellen nach Abhängigkeit oder durch den Backlog Curator ergänzen. |

## Vorlage

```markdown
### AP-YYYY-NNN: <Titel>

| Feld | Wert |
|---|---|
| ID | AP-YYYY-NNN |
| Ziel | <Messbares Ziel> |
| Scope | <Betroffene Module, Schemas und Objekte> |
| Dependencies | <Arbeitspakete, Module oder externe Voraussetzungen> |
| Priorität | <P0 / P1 / P2 / P3> |
| Status | <proposed / researched / ready for development / active / blocked / completed / rejected> |
| Implementation Status | <nur für Module; aus module.yaml abgeleitet> |
| Validation Status | <nur für Module; aus module.yaml abgeleitet> |
| Release Status | <nur für Module; aus module.yaml abgeleitet> |
| Akzeptanzkriterien | <Überprüfbare Done-Bedingungen> |
| Tests | <Statische, Contract-, Runtime- und Plattformtests> |
| Blocker | <Bekannte Blocker> |
| Evidenz | <Commits, Pull Requests, Befehle, Workflows oder Testergebnisse> |
| Nächster Schritt | <Konkret ausführbare nächste Aktion> |
```

## Wiederaufnahme

Ein Chat allein ist keine dauerhafte Source of Truth. Entscheidungen, Prioritäten, Fortschritt und Blocker müssen in dieser Datei oder in `Documentation/Architecture/DECISIONS.md` nachvollziehbar festgehalten werden.
