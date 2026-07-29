# CHANGELOG

Alle wesentlichen Änderungen an SQL Server Toolbelt werden hier dokumentiert.

Das Format orientiert sich an [Keep a Changelog](https://keepachangelog.com/de/1.0.0/).

## [Unreleased]

### Hinzugefügt

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

### Geändert

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

### Status

Das erste fachliche SQL-Objekt ist implementiert und statisch geprüft. Runtime-, Deploy-, Uninstall-, Collation- und Plattformvalidierung ist `not executed`; der Modulstatus ist deshalb nicht `validated`.
