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
| Status | proposed |
| Entscheidung | Für Tabellen, Synonyme, Assemblies, Trigger, Sequences und Types wird vor dem ersten Bedarf keine Namenskonvention erfunden. |
| Begründung | Die Konvention soll anhand eines konkreten fachlichen Objekts entschieden werden. |
| Scope | genannte SQL-Objekttypen |
| Auswirkungen | Beim ersten Bedarf ist der Benutzer zu fragen und diese Entscheidung zu ersetzen oder anzunehmen. |
| Alternativen | Spekulative Präfixe wurden verworfen. |
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
