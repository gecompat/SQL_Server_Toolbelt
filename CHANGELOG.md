# CHANGELOG

Alle wesentlichen Änderungen an SQL Server Toolbelt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

## [Unreleased]

### Hinzugefügt

- Formale Kandidaten `TC-2026-033` bis `TC-2026-046` für ZIP-/Kompressionsprovider, kontrollierte Datei-/Verzeichniszugriffe, getrennte Pseudonymisierungsbausteine, Objektklonen, XLSX-Lesen und eine providerneutrale Second-Session-Abstraktion; alle ohne Implementierungsfreigabe im Status `researched`.
- Deduplizierte Toolbelt-Research-Inbox mit 162 breit gefächerten Ideen und 82 öffentlichen Quellen; Mehrfachnennungen behalten ihre gemeinsamen Fundstellen.
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

### Geändert

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

### Korrigiert

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

Vier Module sind implementiert und `partially validated`. ResultTable ist unter Linux auf SQL Server 2019, 2022 und 2025 erfolgreich; Base64, Generate-Series und Identifier sind auf SQL Server 2025 Linux mit Compatibility Levels 150, 160 und 170 erfolgreich. Windows und die jeweils offenen Releasefälle bleiben `not executed`.
