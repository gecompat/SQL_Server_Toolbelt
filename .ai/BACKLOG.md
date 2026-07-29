# BACKLOG.md – Priorisierte Arbeitspakete

Nur priorisierte Kandidaten werden hier als konkrete Arbeitspakete geführt. Ein Eintrag ist keine automatische Implementierungszusage; er wird durch ausdrückliche Benutzerfreigabe aktiv.

## Aktive Arbeitspakete

### AP-2026-003: ResultTable-Kernmodul implementieren und validieren

| Feld | Wert |
|---|---|
| ID | `AP-2026-003` |
| Ziel | Das implementierungsreif spezifizierte Modul `toolbelt.core.result-table` vollständig implementieren, dokumentieren, installieren, deinstallieren und auf den verfügbaren Zielplattformen validieren. |
| Scope | Modulverzeichnis, `module.yaml`, `toolbelt_core.USP_PrepareResultTable`, Install-/Upgrade-/Uninstall-Skripte, Objekt- und Moduldokumentation, synthetische Beispiele sowie statische, Contract-, Runtime-, Collation-, Deployment- und Plattformtests. |
| Dependencies | `AP-2026-002`, `RESULT_TABLE_MODULE_DESIGN.md`, `RESULT_TABLE_CONTRACT_TEST_MATRIX.md`, `DEC-2026-013` bis `DEC-2026-017`. |
| Priorität | `P0` |
| Status | `blocked` |
| Akzeptanzkriterien | Exakt ein persistentes SQL-Objekt in Version `1.0.0`; öffentliche Signatur und Help-Vertrag vollständig; `@LikeTable`-Schemaquelle, `@KeepData`-Matrix, Preflight, in-place-Umbau, Savepoint- und Fehlervertrag implementiert; lokale und zentrale Installation; kontrolliert wiederholbare Lifecycle-Skripte; keine nicht freigegebenen weiteren persistenten Objekttypen; Dokumentation und Manifest konsistent; alle verfügbaren Pflichtprüfungen ausgeführt und nicht verfügbare Prüfungen ehrlich ausgewiesen. |
| Tests | Vollständige Matrix aus `Tests/RESULT_TABLE_CONTRACT_TEST_MATRIX.md`; SQL Server 2019, 2022 und 2025 sowie Windows/Linux und lokal/zentral getrennt, soweit die benötigten Runner tatsächlich vorhanden sind. |
| Blocker | Vor Implementierung müssen Zweck, öffentlicher Vertrag, Alternativen, Risiken und Scope der konkreten Funktion mit dem Benutzer besprochen und anschließend ausdrücklich freigegeben werden. Verfügbarkeit geeigneter Runtime-Runner ist vor der Validierungswelle zusätzlich zu prüfen; fehlende Runner ergeben `not executed`, keinen grünen Nachweis. |
| Evidenz | Implementierungsreife Spezifikation und statisch validiertes Design aus `AP-2026-002`. |
| Nächster Schritt | `toolbelt_core.USP_PrepareResultTable` anhand der vorhandenen Spezifikation mit dem Benutzer besprechen, offene Vertragsentscheidungen festhalten und eine ausdrückliche Implementierungsfreigabe abwarten. |

## Abgeschlossene Arbeitspakete

### AP-2026-005: SQL-Server-Toolbelt-Landschaft und Prior Art

| Feld | Wert |
|---|---|
| ID | `AP-2026-005` |
| Ziel | Öffentliche SQL-Server-Toolbox-, Capability-, Test-, Diagnose-, Maintenance- und Parallelisierungsprojekte systematisch vergleichen, belastbare Prior Art für die bereits erfassten Execution-Themen dokumentieren und neue Toolbelt-Lücken ableiten. |
| Scope | Landschaftsdokument mit direkter Einordnung von 16 Projekten; vertiefter Vergleich der direkten Capability-Libraries; zweite Session, rollback-unabhängiges Logging, Parallelisierungsprovider, Console, Error Handling und Cancellation; Präzisierung von `TC-2026-012`; neue Kandidaten `TC-2026-023` und `TC-2026-024`; quellenbasierte Vorprüfung des zusätzlichen persönlichen Brainstorms zu Zahlensystemen, Kompression/Archiven, Datei-/Verzeichniszugriff, Anonymisierung und Objektklonen. |
| Dependencies | `AP-2026-001`, `AP-2026-004`, Repository-Grenzen, Third-Party-/Source-Policy und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `validated` |
| Akzeptanzkriterien | Projekte nach Rolle, Technik, Packaging, Lizenz-/Statushinweis und Repository-Ziel eingeordnet; direkte Analogien von bloßen Skriptkatalogen getrennt; Prior Art für zweite Session und Parallelisierung aus Primärquellen dokumentiert; übertragbare und zu vermeidende Muster benannt; neue Kandidaten vollständig und ohne Implementierungszusage erfasst. |
| Tests | Quellen- und Linkstrukturprüfung; Duplikatprüfung gegen kuratierte Kandidatenlisten, persönlichen Brainstorm und Architekturverträge; Third-Party-, Datenschutz- und Secret-Gate; ausschließlich Dokumentations- und Backlogänderungen. |
| Blocker | Keine für Research; Codeübernahme benötigt zusätzlich eine datei- und versionsbezogene Lizenzprüfung. Jede Funktion benötigt vor Implementierung weiterhin eine eigene Besprechung und ausdrückliche Benutzerfreigabe. |
| Evidenz | `Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md`, präzisierter Kandidat `TC-2026-012`, aktualisierte Kandidaten `TC-2026-014`/`TC-2026-015` und neue Kandidaten `TC-2026-023`/`TC-2026-024`; geprüft am 2026-07-29. |
| Nächster Schritt | Forschungsergebnis mit dem Benutzer priorisieren; keine automatische Aktivierung eines weiteren Implementierungsarbeitspakets. |

### AP-2026-004: Backlog Research Wave 2 – Execution Infrastructure

| Feld | Wert |
|---|---|
| ID | `AP-2026-004` |
| Ziel | Die vom Benutzer angestoßenen Ideen zu zweiter Session, rollback-unabhängigem Logging, Parallelisierung, Error Handling, Console-Ausgabe und Gruppenabbruch quellenbasiert erfassen und um unmittelbar notwendige Supporting Capabilities ergänzen. |
| Scope | `TC-2026-014` bis `TC-2026-022`; Toolbelt-Kandidaten für autonome Ereignisprotokollierung, Work Queue, Console, Error Envelope, Cancellation, Correlation, Retry/Dead-letter, Worker Lease und sicheren Work-Type-Katalog. |
| Dependencies | Repository-Grundaufbau, Backlog-Curator-Regeln und funktionsbezogenes Implementierungs-Gate. |
| Priorität | `P1` |
| Status | `validated` |
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
| Status | `validated` |
| Akzeptanzkriterien | Modul-ID und Scope festgelegt; einzige Procedure klassifiziert; keine ungeregelten weiteren persistenten Objekttypen benötigt; Referenztabellen- und Vertrauensgrenze definiert; interne Temp-Namensregel festgelegt; Fehler-, Transaktions-, Collation-, Datentyp-, Install-, Upgrade- und Uninstall-Verträge dokumentiert; vollständige Testmatrix vorhanden. |
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
| Status | `validated` |
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
| Status | <proposed / researched / planned / implemented / validated / blocked / rejected> |
| Akzeptanzkriterien | <Überprüfbare Done-Bedingungen> |
| Tests | <Statische, Contract-, Runtime- und Plattformtests> |
| Blocker | <Bekannte Blocker> |
| Evidenz | <Commits, Pull Requests, Befehle, Workflows oder Testergebnisse> |
| Nächster Schritt | <Konkret ausführbare nächste Aktion> |
```

## Wiederaufnahme

Ein Chat allein ist keine dauerhafte Source of Truth. Entscheidungen, Prioritäten, Fortschritt und Blocker müssen in dieser Datei oder in `Documentation/Architecture/DECISIONS.md` nachvollziehbar festgehalten werden.
