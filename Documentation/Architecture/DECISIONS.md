# Architekturentscheidungen

Dauerhafte Entscheidungen werden mit stabiler ID dokumentiert. Historische Entscheidungen werden nicht rückwirkend umgeschrieben; eine Ablösung verwendet `superseded` und verweist auf die neue ID.

## Vorlage

```markdown
## DEC-YYYY-NNN: <Titel>

| Feld | Wert |
|---|---|
| Datum | YYYY-MM-DD |
| Status | proposed / accepted / superseded / rejected |
| Entscheidung | <Verbindliche Festlegung> |
| Begründung | <Fachliche Begründung> |
| Scope | <Betroffene Artefakte oder Module> |
| Auswirkungen | <Wesentliche Folgen> |
| Alternativen | <Verworfen oder nachrangig> |
| Betroffene Verträge | <Links> |
```

## DEC-2026-001: T-SQL-first

| Feld | Wert |
|---|---|
| Datum | 2026-07-28 |
| Status | accepted |
| Entscheidung | T-SQL ist die bevorzugte Implementierungssprache. |
| Begründung | Native Ausführung, geringe Deployment-Komplexität und breite Plattformverfügbarkeit. |
| Scope | alle Module |
| Auswirkungen | CLR, C#, Python, Java oder R benötigen eine dokumentierte technische Begründung. |
| Alternativen | CLR-first oder externe Runtime als Default wurden verworfen. |
| Betroffene Verträge | `TSQL_ENGINEERING.md`, `CLR_SECURITY_AND_PORTABILITY.md` |

## DEC-2026-002: Fachliche Schemas `toolbelt_<category>`

| Feld | Wert |
|---|---|
| Datum | 2026-07-28 |
| Status | accepted |
| Entscheidung | Öffentliche Objekte werden in kollisionsarmen fachlichen Schemas `toolbelt_<category>` angelegt. |
| Begründung | Eindeutige Herkunft und geringeres Kollisionsrisiko bei lokaler Installation. |
| Scope | öffentliche Schemas und Synonyme |
| Auswirkungen | Generische Schemas wie `string`, `time`, `io`, `json` oder `xml` sind unzulässig. |
| Alternativen | Ein einzelnes Schema `toolbelt` und unpräfixierte Kategorien wurden verworfen. |
| Betroffene Verträge | `SQL_OBJECT_NAMING.md` |

## DEC-2026-003: Weitere Objekttypen bleiben offen

| Feld | Wert |
|---|---|
| Datum | 2026-07-28 |
| Status | superseded |
| Entscheidung | Für persistente Tabellen, Synonyme, Assemblies, Trigger, Sequences und Types wird vor dem ersten Bedarf keine Namenskonvention erfunden. |
| Begründung | Die Konvention soll anhand eines konkreten fachlichen Objekts entschieden werden. |
| Scope | genannte persistente SQL-Objekttypen |
| Auswirkungen | Beim ersten Bedarf ist der Benutzer zu fragen und diese Entscheidung zu ersetzen oder anzunehmen. Interne lokale Temp-Objekte sind gesondert in `DEC-2026-017` geregelt. |
| Alternativen | Spekulative Präfixe für persistente Objekte wurden verworfen. |
| Betroffene Verträge | `SQL_OBJECT_NAMING.md` |

## DEC-2026-004: Modul- und Dependency-Modell

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Ein Modul ist Lifecycle-, Deployment- und Dokumentationseinheit; Abhängigkeiten sind versioniert und azyklisch. |
| Begründung | Teilinstallationen und kopierte Parallelimplementierungen müssen vermieden werden. |
| Scope | alle Module und Installer |
| Auswirkungen | Dependency-Preflight vor erster Mutation; keine automatische Nachinstallation. |
| Alternativen | Objektweise unabhängige Installation wurde verworfen. |
| Betroffene Verträge | `MODULE_AND_DEPENDENCY_MODEL.md`, Modulmanifest |

## DEC-2026-005: Lokale und zentrale Installation

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Capabilities sollen lokal in einer Zieldatenbank und zentral in einer Toolbelt-Datenbank einsetzbar sein, soweit technisch möglich. |
| Begründung | Unterschiedliche Betriebsmodelle sollen denselben fachlichen Vertrag nutzen. |
| Scope | Deployment, Wrapper, Synonyme |
| Auswirkungen | Cross-database-Verwendung ist Designziel; lokale Installation bleibt bei technischen Grenzen zulässig oder erforderlich. |
| Alternativen | Nur zentrale oder nur lokale Installation wurden verworfen. |
| Betroffene Verträge | `DEPLOYMENT_MODEL.md` |

## DEC-2026-006: Einheitlicher USP-Hilfevertrag

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Jede Toolbelt-USP besitzt `@Hilfe bit = 0`; bei `@Hilfe = 1` wird ausschließlich ein stabiles maschinenlesbares Help-Resultset ausgegeben. |
| Begründung | Menschen und KI-Systeme sollen Vertrag, Parameter, Resultspalten und Beispiele ohne Quellcodeanalyse ermitteln können. |
| Scope | öffentliche und interne USPs |
| Auswirkungen | Fachliche Pflichtparameter erhalten technische Defaults; Help-Modus verursacht keine Seiteneffekte. |
| Alternativen | Freitext-`PRINT` und pro USP unterschiedliche Help-Formate wurden verworfen. |
| Betroffene Verträge | `USP_CONTRACT.md` |

## DEC-2026-007: `@ResultTable` und `@KeepData`

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | USPs mit tabellarischem Resultset unterstützen eine bestehende lokale Temp-Tabelle über `@ResultTable`; `@KeepData` steuert Replace oder Append. |
| Begründung | Resultsets müssen ohne verschachteltes `INSERT ... EXEC` programmatisch weiterverarbeitet werden können. |
| Scope | USPs mit fachlichem tabellarischem Resultset |
| Auswirkungen | Höchstens ein fachliches Resultset; vollständige Contract-Testmatrix; beliebige Dummyspalte zulässig. |
| Alternativen | Nur Console-Resultset und generisches `INSERT ... EXEC` wurden verworfen. |
| Betroffene Verträge | `USP_CONTRACT.md`, `TEST_AND_VALIDATION_POLICY.md` |

## DEC-2026-008: Metadaten, Collation und String-Typen

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Reguläre Metadaten werden bevorzugt über Catalog Views gelesen; lokale Temp-Tabellen einmalig über `OBJECT_ID` aufgelöst. String-Typ und Collation werden nach fachlicher Semantik gewählt. |
| Begründung | Unnötige Metadatenfunktionsaufrufe, Collation-Konflikte und pauschaler Unicode-Overhead sollen vermieden werden. |
| Scope | T-SQL-Implementierungen und interne Temp-Objekte |
| Auswirkungen | Geeignete read-only Catalog-Abfragen dürfen `NOLOCK` verwenden; `nvarchar` ist kein pauschaler Default. |
| Alternativen | Wiederholte Metadatenfunktionen und pauschales `nvarchar` wurden verworfen. |
| Betroffene Verträge | `TSQL_ENGINEERING.md` |

## DEC-2026-009: CLR-Trust und `TRUSTWORTHY`

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Exaktes SHA2-512-Hash-Pinning ist bevorzugter Release-Trust; Strong Name ist Alternative. `TRUSTWORTHY ON` bleibt eine ausdrücklich freizugebende Last-Resort-Ausnahme. |
| Begründung | Reproduzierbare Autorisierung ohne Veröffentlichung privater Schlüssel und ohne pauschales Datenbankvertrauen. |
| Scope | CLR und privilegierte Datenbankkontexte |
| Auswirkungen | Linux unterstützt nur geeignete `SAFE`-CLR-Szenarien; private Signing Keys bleiben außerhalb des Repositorys. |
| Alternativen | `TRUSTWORTHY ON` oder deaktiviertes `clr strict security` als Default wurden verworfen. |
| Betroffene Verträge | `CLR_SECURITY_AND_PORTABILITY.md` |

## DEC-2026-010: Debugdaten und Secrets

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Diagnostisch notwendige vertrauliche Runtime-Werte dürfen im lokalen Debug erscheinen; echte Secrets werden nicht aktiv ausgegeben. |
| Begründung | Diagnosefähigkeit bleibt erhalten, ohne Credentials offenzulegen. |
| Scope | Debug-Messages und Runtime-Ausgaben |
| Auswirkungen | Reale Debugausgaben dürfen nicht als Repository-, Help-, Beispiel- oder Testartefakt übernommen werden. |
| Alternativen | Vollständige Runtime-Anonymisierung und uneingeschränkte Secret-Ausgabe wurden verworfen. |
| Betroffene Verträge | `DATA_PRIVACY_AND_CONFIDENTIALITY.md`, `USP_CONTRACT.md` |

## DEC-2026-011: Repository-Grenze zu SQL Server Analyze

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Analyse-, Diagnose-, Performance-, Konfigurations- und Security-Assessment-Funktionalität wird nicht im Toolbelt implementiert. |
| Begründung | `gecompat/SQL_Server_Analyze` besitzt die fachliche Verantwortung. |
| Scope | Backlog und Modulklassifikation |
| Auswirkungen | Ideen werden nur als geprüfter Backlog-Input erfasst; vor Eintrag erfolgt nach Möglichkeit ein Duplikatabgleich. |
| Alternativen | Parallele Analyseimplementierungen wurden verworfen. |
| Betroffene Verträge | `REPOSITORY_BOUNDARIES.md`, Analyze-Kandidatenliste |

## DEC-2026-012: Supportmatrix und portable Provider

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Die Grundmatrix umfasst SQL Server 2019, 2022 und 2025; Windows- und Linux-Support wird pro Modul und Provider getrennt ausgewiesen. |
| Begründung | „SQL Server 2019+“ muss aktuelle Hauptversionen konkret und prüfbar abbilden. |
| Scope | Manifest, Tests, Dokumentation und Provider |
| Auswirkungen | Windows-only-Capabilities benötigen eine Prüfung auf portable Alternativen; `not applicable` erfordert Begründung. |
| Alternativen | Nur 2019/2022 und pauschale Plattformzusagen wurden verworfen. |
| Betroffene Verträge | `DEPLOYMENT_MODEL.md`, `TEST_AND_VALIDATION_POLICY.md` |

## DEC-2026-013: Erstes Kernmodul `toolbelt.core.result-table`

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Das erste geplante Kernmodul trägt die ID `toolbelt.core.result-table` und stellt in Version `1.0.0` ausschließlich `toolbelt_core.USP_PrepareResultTable` bereit. |
| Begründung | ResultTable-Routing ist Voraussetzung für programmatisch verschachtelbare Toolbelt-USPs und eignet sich als erste Referenz für Lifecycle, Help, Deployment und Contract Tests. |
| Scope | `AP-2026-002`, erstes `toolbelt_core`-Modul |
| Auswirkungen | Die erste Version benötigt keine persistente Tabelle, kein Synonym, keine Assembly und keinen Type; `DEC-2026-003` bleibt daher für persistente Objekttypen offen. |
| Alternativen | Ein breiteres allgemeines Core-Modul mit spekulativer Modulregistrierung wurde für die erste Welle verworfen. |
| Betroffene Verträge | `RESULT_TABLE_MODULE_DESIGN.md`, `USP_CONTRACT.md` |

## DEC-2026-014: Referenztabelle vor frei geliefertem `CREATE TABLE`-DDL

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Version `1.0.0` ermittelt das gewünschte Schema aus einer vorhandenen lokalen oder regulären Referenztabelle über `@LikeTable`. Ein öffentlicher `@CreateStmt`-Parameter wird für diese Version zurückgestellt. |
| Begründung | Eine routinenspezifische Helper-Temp-Tabelle lässt SQL Server selbst Datentyp, Länge, Precision, Scale, Nullability und Collation auflösen und vermeidet in der ersten Version einen unvollständigen DDL-Sicherheitsparser. |
| Scope | `toolbelt_core.USP_PrepareResultTable` und aufrufende Toolbelt-USPs |
| Auswirkungen | Jede resultseterzeugende USP legt bei Bedarf eine eindeutig benannte Schema-Helper-Temp-Tabelle an und übergibt sie als `@LikeTable`. Die zuvor erwogene `@CreateStmt`-Capability bleibt ein möglicher späterer Ausbau, benötigt für fremdes DDL jedoch ScriptDOM oder einen gleichwertigen vollständigen Parser und einen eigenen Sicherheitsvertrag. |
| Alternativen | Für Version `1.0.0` wurden Regex-/String-basierte Sicherheitsbewertung beliebigen DDLs und ungeprüfte Ausführung von `@CreateStmt` verworfen; die Capability als solche wird nicht dauerhaft ausgeschlossen. |
| Betroffene Verträge | `RESULT_TABLE_MODULE_DESIGN.md`, `TSQL_ENGINEERING.md` |

## DEC-2026-015: In-place-Schemaumbau mit vollständigem Preflight

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Eine abweichende lokale ResultTable wird nach vollständigem read-only Preflight mit einer temporären Anchor-Spalte in-place umgebaut; das Zielobjekt wird nicht gedroppt und neu erstellt. |
| Begründung | Das vom Aufrufer erzeugte lokale Temp-Objekt muss in seinem ursprünglichen Scope erhalten bleiben. |
| Scope | `@KeepData`-Replace-Pfad von `USP_PrepareResultTable` |
| Auswirkungen | Blockierende Indizes, Constraints, computed columns, Trigger, user-created statistics oder andere Dependencies führen vor der ersten Mutation zum Abbruch; kein Blocker wird automatisch entfernt. |
| Alternativen | Drop/Recreate des Zielobjekts und automatisches Entfernen fremder Dependencies wurden verworfen. |
| Betroffene Verträge | `RESULT_TABLE_MODULE_DESIGN.md`, `RESULT_TABLE_CONTRACT_TEST_MATRIX.md` |

## DEC-2026-016: Savepoint-fähiger Transaktionsvertrag und zentrale Verwendbarkeit

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Die ResultTable-Mutation verwendet eine eigene Transaktion oder bei vorhandener Caller-Transaktion einen Savepoint. Das Modul unterstützt lokale und zentrale Installation ohne Synonympflicht. |
| Begründung | Fehler dürfen keinen halb umgebauten Zustand hinterlassen; zugleich darf eine Toolbelt-USP keine vollständige Caller-Transaktion committen oder zurückrollen. Lokale Temp-Tabellen derselben Session sind auch bei dreiteiligem Procedure-Aufruf nutzbar. |
| Scope | Transaktions-, Fehler- und Deployment-Vertrag des ResultTable-Moduls |
| Auswirkungen | Bei `XACT_STATE() = -1` bleibt der uncommittable Zustand sichtbar; die Procedure rethrowt den Originalfehler. Zentrale Deinstallation benötigt eine Betreiberbestätigung, weil beliebige externe Direktaufrufer nicht vollständig ermittelbar sind. |
| Alternativen | Unbedingter Full Rollback, `TRUSTWORTHY ON`, Synonympflicht und separate lokale/ zentrale Fachimplementierungen wurden verworfen. |
| Betroffene Verträge | `RESULT_TABLE_MODULE_DESIGN.md`, `DEPLOYMENT_MODEL.md` |

## DEC-2026-017: Interne lokale Temp-Objekte verwenden `#tbx_`

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Interne lokale Temp-Tabellen verwenden den reservierten Präfix `#tbx_` sowie englische Modul-, Routine- und Rollenbestandteile; dynamische Arbeitsobjekte erhalten zusätzlich einen Invocation-spezifischen Suffix. |
| Begründung | Eindeutige Namen vermeiden Kollisionen in verschachtelten, rekursiven und parallelen Aufrufkontexten und unterscheiden interne Objekte von Benutzer-ResultTables. |
| Scope | interne lokale Temp-Objekte aller Module |
| Auswirkungen | Benutzer-ResultTables dürfen nicht mit `#tbx_` beginnen. Routinenspezifische unveränderliche Schema-Helper dürfen bei Rekursion wiederverwendet und nur vom tatsächlichen Erzeuger entfernt werden. Die Namenskonvention persistenter Tabellen bleibt offen. |
| Alternativen | Generische Namen wie `#Temp`, `#Result` und zufällige Namen ohne fachliche Zuordnung wurden verworfen. |
| Betroffene Verträge | `SQL_OBJECT_NAMING.md`, `TSQL_ENGINEERING.md`, `RESULT_TABLE_MODULE_DESIGN.md` |

## DEC-2026-018: Persönlicher Brainstorm als erhaltener Research-Input

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | `Backlog/personal_Backlog_Bainstorm.md` wird vor jeder Funktionsrecherche und Backlog-Pflege als vom Benutzer gepflegte Hinweisquelle berücksichtigt. Bestehende Inhalte werden nicht gelöscht; Überholtes wird durchgestrichen und unmittelbar mit einem datierten Änderungskommentar versehen. |
| Begründung | Freie Gedanken sollen als dauerhafte Rechercheimpulse erhalten bleiben, ohne die Struktur und Verbindlichkeit der kanonischen Kandidatenlisten zu erzwingen oder historische Hinweise zu verlieren. |
| Scope | Funktionsrecherche, Backlog Curator, Backlog-Pflege und AI-Steuerung |
| Auswirkungen | KI-Systeme dürfen ergänzen, kommentieren und Querverweise setzen. Die Datei ist keine Source of Truth für Regeln, Prioritäten, öffentliche Verträge oder Implementierungsfreigaben. Formale Ergebnisse verbleiben in den kanonischen Kandidatenlisten und in `.ai/BACKLOG.md`. |
| Alternativen | Löschen nach Übernahme, stillschweigende redaktionelle Neufassung und Behandlung als kanonischer Fachbacklog wurden verworfen. |
| Betroffene Verträge | `AGENTS.md`, `.ai/PROJECT_RULES.md`, `.ai/WORKING_RULES.md`, `.ai/repo_map.yaml`, `Backlog/README.md`, `backlog-curator.agent.md` |

## DEC-2026-019: Parametergesteuertes Deployment mit Release-Manifesten

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Erstinstallation, Upgrade und Wiederholungsinstallation eines Moduls verwenden ein gemeinsames parametergesteuertes `Deploy.sql`. Lokaler und zentraler Modus wählen nur Installationsort und Metadatum. Versionierte Release-Manifeste bestimmen Framework-Herkunft, Kollisionen und entfernte Objekte. |
| Begründung | Getrennte Install- und Upgrade-Implementierungen erzeugen unnötige Drift. Die Herkunft aus einem bekannten Vorgängerrelease ist eine belastbarere Lösch- und Überschreibgrenze als ein Source-Hash. |
| Scope | alle Toolbelt-Module und ihre Lifecycle-Artefakte |
| Auswirkungen | Framework-Objekte aus dem bekannten Vorgängerrelease werden auch nach lokalen Änderungen aktualisiert oder bei Wegfall entfernt. Neue Zielobjekte dürfen keine frameworkfremden Namenskollisionen überschreiben. Wiederholungsinstallation derselben Version deployed alle Release-Objekte erneut. Source-Hashes bleiben rein diagnostisch. Mutationstransaktionen beginnen erst nach dem Preflight und dauern nur bis zur atomaren Aktualisierung von Objekten und Installationsstand. |
| Alternativen | getrennte Install-/Upgrade-Skripte sowie Drift-Blockade anhand von Source-Hashes wurden verworfen. |
| Betroffene Verträge | `DEPLOYMENT_MODEL.md`, `MODULE_AND_DEPENDENCY_MODEL.md`, `MODULE_DEFINITION_OF_DONE.md`, Modulmanifest und Lifecycle-Tests |

## DEC-2026-020: Manifestzentrierte Status- und Change-Impact-Steuerung

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Jedes Modulmanifest ist die autoritative Quelle für Implementierungs-, Validierungs- und Release-Status sowie gekoppelte Dokumentationspfade und Contract-Versionen. Wiederholte Statusdarstellungen werden aus den registrierten Manifesten erzeugt. Konsistenzprüfungen beginnen mit dem Git-Diff und laden nur die in `.ai/repo_map.yaml` registrierten Impact-Pakete. |
| Begründung | Unabhängig gepflegte Statusangaben und pauschale Repository-Scans erzeugen zugleich Drift und unnötigen Aufwand. Explizite Kopplungen machen den Prüfbereich deterministisch, sparsam und überprüfbar. |
| Scope | Modulmanifeste, README-Status, Modulübersicht, Dokumentationsprüfung, Pull Requests und CI-Auslösung |
| Auswirkungen | Ein Modul verwendet getrennte Felder `implementation_status`, `validation_status` und `release_status`. Vollständige Audits bleiben auf Baseline, Release, Governance- oder Kopplungsänderungen sowie ausdrückliche Aufträge begrenzt. Reine Dokumentationsänderungen starten keine Runtime-Vollmatrix. |
| Alternativen | Ein Sammelstatus, unabhängige manuelle Statuspflege, Vollscan bei jedem Commit und ungeprüfte Pfadheuristiken wurden verworfen. |
| Betroffene Verträge | `.ai/repo_map.yaml`, `.ai/PROJECT_RULES.md`, `.ai/WORKING_RULES.md`, `ARTIFACT_ROLES.md`, `MODULE_AND_DEPENDENCY_MODEL.md`, `TEST_AND_VALIDATION_POLICY.md`, Modulmanifeste und GitHub-Actions-Workflows |

## DEC-2026-021: Scopebezogenes Qualitäts-Gate für weitere Module

| Feld | Wert |
|---|---|
| Datum | 2026-07-29 |
| Status | accepted |
| Entscheidung | Ein weiteres Modul benötigt nicht pauschal ein vollständig validiertes, fachlich unabhängiges Referenzmodul. Verbindlich sind die funktionsbezogene Besprechung und Freigabe, vollständige eigene Source-, Lifecycle-, Dokumentations- und Testartefakte sowie eine für den konkret verwendeten Vertrag ausreichende Validierung jeder gemeinsamen Infrastruktur. |
| Begründung | Ein pauschales Gate koppelt unabhängige Capabilities ohne technische Ursache und blockiert sie durch offene Prüfungen fremder Verträge. Scopebezogene Gates erhalten die Qualitätsanforderung und machen den tatsächlichen Abhängigkeits- und Testumfang explizit. |
| Scope | Phase 2, Modulplanung, Dependency-Preflight, Test- und Statuswahrheit |
| Auswirkungen | `toolbelt.conversion.base64` kann ohne ResultTable-Abhängigkeit implementiert und eigenständig validiert werden. Ein Modul darf offene Pflichtfälle verwendeter gemeinsamer Infrastruktur nicht umgehen; nicht ausgeführte Tests bleiben sichtbar. |
| Alternativen | Vollständige Validierung irgendeines Referenzmoduls als pauschale Voraussetzung; vollständig unabhängige Module ohne eigenes Qualitäts-Gate. |
| Betroffene Verträge | `.ai/ROADMAP.md`, `.ai/BACKLOG.md`, `BASE64_MODULE_DESIGN.md`, `MODULE_DEFINITION_OF_DONE.md`, `TEST_AND_VALIDATION_POLICY.md` |

## DEC-2026-022: Inline-TVF-Alternative für Scalar Functions

| Feld | Wert |
|---|---|
| Datum | 2026-07-30 |
| Status | accepted |
| Entscheidung | Für jede öffentliche SVF wird nach Möglichkeit eine semantisch äquivalente inline TVF angeboten. Die inline TVF bildet den kanonischen relationalen Kern; die SVF bleibt als zusätzliche Convenience-API verfügbar. Ein TVF-Wrapper, der lediglich die SVF aufruft, erfüllt den Vertrag nicht. |
| Begründung | Nicht ge-inline-te Scalar UDFs verhindern Intra-query-Parallelität und verbergen Fachlogik vor dem Optimizer. Eine inline TVF lässt sich über `CROSS APPLY` oder `OUTER APPLY` mengenorientiert einbinden. Scalar UDF Inlining ab SQL Server 2019 kann den Nachteil nur unter Voraussetzungen aufheben und ist kein stabiler API-Vertrag. |
| Scope | Alle bestehenden und zukünftigen öffentlichen SVFs in T-SQL-Modulen |
| Auswirkungen | Neue SVFs benötigen im Design eine inline-TVF-Prüfung. Bestehende Lücken werden im Audit und in `AP-2026-014` nachverfolgt. Dokumentation und Beispiele empfehlen die relationale API für mengenorientierte Abfragen. |
| Alternativen | Nur SVFs anzubieten oder eine inline TVF als bloßen Aufruf-Wrapper um die SVF zu legen wurde verworfen. Der vollständige Verzicht auf SVFs wurde verworfen, weil die skalare API für Einzelaufrufe und bestehende Aufrufstellen nützlich bleibt. |
| Betroffene Verträge | `TSQL_ENGINEERING.md`, `MODULE_DEFINITION_OF_DONE.md`, `SVF_INLINE_TVF_AUDIT.md` |

## DEC-2026-023: CLR-ZIP-Provider und Assemblyname

**Status:** Accepted  
**Datum:** 2026-07-31

### Kontext

Der erfolgreich validierte SQL-CLR-Spike hat gezeigt, dass Raw-Deflate
über `DeflateStream` aus der unterstützten `System.dll` mit
`PERMISSION_SET = SAFE`, aktiviertem `clr strict security` und einer
expliziten SHA2-512-Vertrauensfreigabe auf SQL Server Linux ausführbar
ist. Für die produktive Erweiterung von
`toolbelt.archive.zip-memory` werden erstmals ein persistenter
Assemblyname und ein interner CLR-SQL-Objektname benötigt.

### Entscheidung

- Die vorhandene öffentliche
  `toolbelt_archive.USP_ExtractZipEntryFromBinary` bleibt der einzige
  öffentliche Entry-Extraktionsvertrag und wird intern CLR-backed.
- Die modulspezifische SQL-Assembly heißt
  `Toolbelt_Archive_ZipMemory`; das Binary heißt
  `Toolbelt.Archive.ZipMemory.dll`.
- Der interne SQL-Provider heißt
  `toolbelt_archive.TVF_InternalExtractZipEntryClr` und ist keine
  öffentliche Convenience-API.
- Diese Namen entscheiden ausschließlich den konkreten Bedarf dieses
  Moduls. Sie begründen keine globale Assembly- oder CLR-Objektnamensregel
  für andere Module; `DEC-2026-003` bleibt im Übrigen unverändert.
- Die Assembly referenziert direkt nur `System` und `System.Data`.
  Deflate verwendet `DeflateStream` aus `System.dll`; eine direkte
  Referenz auf `System.IO.Compression.dll` und `ZipArchive` ist
  ausgeschlossen.
- Reguläres Deployment bleibt `SAFE`, prüft den exakten SHA2-512-Hash
  gegen `sys.trusted_assemblies` und ändert weder `clr enabled`,
  `clr strict security`, `TRUSTWORTHY` noch die Trust-Liste.
- Trust-Opt-in und Trust-Entfernung sind getrennte administrative
  Vorgänge. Der Modul-Uninstall entfernt keinen serverweiten
  Trust-Eintrag.

### Folgen

Das Modul erhält einen expliziten Build-/Release-Schritt für DLL,
Trust-Manifest und ein aus dem Binary abgeleitetes Deployment-SQL.
Die Runtime-Matrix muss den echten CLR-Aufruf, Stored, Deflate,
Payload-CRC32, Limits, lokale und zentrale Installation sowie den
vollständigen Datenbank-Uninstall prüfen. Windows-SQL-Server-Runtime
bleibt ein separater Release-Nachweis.


## DEC-2026-024: Windows-only Filesystem Provider

| Feld | Wert |
|---|---|
| Datum | 2026-07-31 |
| Status | accepted |
| Entscheidung | Dateisystemzugriff ist ein lokales EXTERNAL_ACCESS-SQL-CLR-Modul für Windows. Default ist Caller über SqlContext.WindowsIdentity; ServiceAccount wird nur explizit verwendet. |
| Begründung | Ein interaktiv angemeldeter Benutzer ist aus SQL Server nicht zuverlässig bestimmbar. Relative Pfade unter Root-Aliassen, Reparse-Point-Sperren und Staging begrenzen das Risiko. |
| Scope | toolbelt.filesystem.windows; Text/Binary, Codepages, Transcoding, Directory-Operationen und rekursives Delete. |
| Auswirkungen | Linux ist not applicable. TRUSTWORTHY ON, UNSAFE, xp_cmdshell und absolute/UNC-Pfade sind ausgeschlossen. Ein manueller Windows-Runtime-Nachweis ist verpflichtend. |
| Alternativen | OPENROWSET(BULK) bleibt für portable read-only Nutzung ein separates Modul; es ersetzt keine kontrollierten Writes, Impersonation oder Directory-Verwaltung. |
| Betroffene Verträge | CLR_SECURITY_AND_PORTABILITY.md, USP_CONTRACT.md, WINDOWS_FILESYSTEM_MODULE_DESIGN.md |


## DEC-2026-025: Persistente Tabellen, Constraints und Indizes

| Feld | Wert |
|---|---|
| Datum | 2026-08-01 |
| Status | accepted |
| Entscheidung | Persistente Toolbelt-Tabellen verwenden im fachlichen `toolbelt_<category>`-Schema einen verständlichen singulären `CamelCase`-Namen ohne `TBL_`-Präfix. Constraints und Indizes werden explizit mit `PK_`, `UQ_`, `FK_`, `CK_`, `DF_` beziehungsweise `IX_` benannt. |
| Begründung | Das Schema und der SQL-Objekttyp identifizieren eine Tabelle bereits eindeutig. Fachliche Namen bleiben lesbar; explizite Constraint-/Indexnamen ermöglichen stabile Deployments, Fehlerdiagnose und Upgrade-Skripte. |
| Scope | Persistente Tabellen, ihre Constraints und Indizes; erster konkreter Einsatz ist `toolbelt_core.WorkType`. |
| Auswirkungen | Tabellen sind standardmäßig intern, sofern das Manifest sie nicht ausdrücklich public erklärt. Spalten sind englisch und `CamelCase`; systemgenerierte Constraintnamen sind unzulässig. Direkter Tabellenzugriff ist kein impliziter API-Vertrag. |
| Alternativen | `TBL_`-/`TB_`-Präfixe und unbenannte Constraints wurden verworfen. Pluralformen bleiben nur bei fachlich etablierten Sammelbegriffen zulässig. |
| Betroffene Verträge | `SQL_OBJECT_NAMING.md`, `WORK_TYPE_MODULE_DESIGN.md`, `toolbelt.core.work-type` |

## DEC-2026-026: AI Repository Foundation 1.2 als additive Governance-Baseline

| Feld | Wert |
|---|---|
| Datum | 2026-08-23 |
| Status | accepted |
| Entscheidung | AI Repository Foundation 1.2 wird über den manifestierten Rules-only-Umfang unter `.ai/foundation/` integriert. `AGENTS.md` bleibt der kanonische Einstieg; die vorhandenen Toolbelt-Regeln bleiben für Projektfakten, Fachverträge und bewusst strengere Vorgaben autoritativ. Ausgewählt ist der vorhandene GitHub-Copilot-Adapter; Claude- und Gemini-Adapter bleiben unselektiert. |
| Begründung | Die Foundation ergänzt portable Regeln für Autorisierung, Sicherheit, Provenienz, Quellen, Dependencies und getrennte Validierungsebenen, ohne reife projektspezifische Governance zu ersetzen. Der semantische Integrationsvertrag verhindert Textüberschreibung und Regelverlust. |
| Scope | KI-Governance, Regel-Discovery, Modellrouting, Validierung, Datenschutz, Drittanbieter- und Quellenbehandlung |
| Auswirkungen | Das funktionsbezogene Implementierungs-Gate und der strengere Datenschutz sind `PROJECT_STRONGER`. Die Toolbelt-Modellrichtlinie und ihre Foundation-Tier-Zuordnung sowie die erweiterten Validierungsstatus sind `COMPLEMENTARY`. KI-Commit-Regel, Sprache, Git-/Merge-Workflow und konkrete Prüfkommandos bleiben `PROJECT_SELECTABLE_OVERRIDE`. Der Copilot-Adapter ist eine reine Discovery-Brücke; das projektspezifische Backlog-Curator-Profil bleibt als ausgewählte Capability erhalten. Foundation-Integrität, Toolbelt-Semantik und Runtime-Evidenz werden getrennt berichtet. |
| Alternativen | Vollständiges Ersetzen bestehender Regeln, Kopieren des Foundation-Repositories als Template, Änderung der Toolbelt-Root-Lizenz und parallele Governance in Tool-Adaptern wurden verworfen. |
| Betroffene Verträge | `AGENTS.md`, `.ai/foundation/`, `.ai/repo_map.yaml`, `.github/copilot-instructions.md`, `AI_COST_AND_QUALITY_PROCESSING_POLICY.md`, `TEST_AND_VALIDATION_POLICY.md` |
