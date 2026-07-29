# PROJECT_RULES.md – Kanonische Projektregeln

## 1. Architektur

- Ein Modul ist Lifecycle-, Deployment- und Dokumentationseinheit.
- Module deklarieren versionierte Abhängigkeiten; der Preflight erfolgt vor der ersten Mutation.
- Fehlende oder ungeeignete Abhängigkeiten führen zu verständlicher Meldung und vollständigem Abbruch.
- Abhängigkeiten werden nicht automatisch installiert; Zyklen sind unzulässig.
- Wiederverwendete Fachlogik existiert genau einmal; Wrapper und Provider verwenden den kanonischen Kern.
- Lokale und zentrale Installation sind gleichwertige Deployment-Modi, soweit technisch möglich.
- Cross-database-Verwendung ist Designziel, keine pauschale Garantie.

Details: [MODULE_AND_DEPENDENCY_MODEL.md](../Documentation/Architecture/MODULE_AND_DEPENDENCY_MODEL.md) und [DEPLOYMENT_MODEL.md](../Documentation/Architecture/DEPLOYMENT_MODEL.md)

## 2. SQL-Namenskonventionen

- Stored Procedure: `USP_{CamelCase}`
- Inline oder Multi-statement Table-valued Function: `TVF_{CamelCase}`
- Scalar-valued Function: `SVF_{CamelCase}`
- View: `VW_{CamelCase}`
- Schemas: `toolbelt_<category>`
- Öffentliche und interne technische Identifier sind englisch.
- Für bisher ungeregelte Objekttypen wird keine Konvention erfunden; der Benutzer entscheidet beim ersten Bedarf.

Details: [SQL_OBJECT_NAMING.md](../Documentation/Standards/SQL_OBJECT_NAMING.md)

## 3. Datenschutz und Debug

- Fachlich relevante, öffentlich bekannte Organisations- und externe Projektnamen sowie öffentliche Quellen-, Projekt- und Dokumentations-URLs sind zulässig.
- `gecompat` und `Gerhard Pisch` sind für Repository-Inhalte ausdrücklich freigegeben.
- Keine personenbezogenen oder sensiblen Daten und keine internen oder vertraulichen Firmen-, Kunden-, Organisations- oder Projektdaten.
- Keine Original-Tabelleninhalte, Produktionsdaten, Backups, Exporte oder realen Runtime-Ausgaben in Repository-Artefakten.
- Keine nicht öffentlichen Infrastrukturangaben und keine konkreten Hardware-, Kapazitäts-, Inventar- oder Umgebungswerte von Remote Runnern.
- Keine Secrets oder privaten Schlüssel.
- Vertrauliche Runtime-Werte dürfen bei aktiviertem Debug diagnostisch ausgegeben werden.
- Echte Secrets werden auch im Debug nicht aktiv ausgegeben.
- Reale Debugausgaben werden nicht als Help, Beispiel, Test-Evidence, Issue-, Pull-Request- oder Repository-Inhalt gespeichert.

Details: [DATA_PRIVACY_AND_CONFIDENTIALITY.md](../Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md)

## 4. T-SQL-Engineering

- Set-basierte Lösungen bevorzugen.
- Inline TVFs haben klaren Vorrang vor Multi-statement TVFs, wenn der Vertrag dies erlaubt.
- Error Handling erfolgt an fachlichen und transaktionalen Grenzen, nicht nach jedem Statement.
- SARGability, Cardinality Estimation, Parallelität, Memory Grants, TempDB, Compile-Verhalten und implizite Konvertierungen berücksichtigen.
- `varchar` und `nvarchar` nach Semantik, Zeichenvorrat, Codepage, Collation, Speicher- und Konvertierungskosten wählen; `nvarchar` ist kein pauschaler Default.
- Eigene unterstützte Pfade müssen Collation-safe sein.
- Reguläre Metadaten bevorzugt über Catalog Views lesen; geeignete read-only Abfragen dürfen `WITH (NOLOCK)` verwenden.
- Lokale Temp-Tabelle einmalig mit `OBJECT_ID(N'tempdb..#Name', N'U')` auflösen und danach über `tempdb.sys.*` sowie die ermittelte `object_id` weiterarbeiten.
- Interne Temp-Objekte eindeutig benennen.

Details: [TSQL_ENGINEERING.md](../Documentation/Standards/TSQL_ENGINEERING.md)

## 5. USP-Vertrag

Der vollständige Vertrag für `@Hilfe`, `@Debug`, `@ResultTable` und `@KeepData` steht in [USP_CONTRACT.md](../Documentation/Standards/USP_CONTRACT.md). Änderungen daran sind öffentliche Vertragsänderungen und erfordern gekoppelte Dokumentations- und Contract-Tests.

## 6. CLR, Trust und Portabilität

- SQL CLR nur mit technischer Begründung.
- `SAFE` bevorzugen; `EXTERNAL_ACCESS` und `UNSAFE` nur bei dokumentierter Notwendigkeit und nur auf unterstützten Plattformen.
- `clr strict security` nicht regulär deaktivieren.
- Offizielle Release-Binaries bevorzugt über exakten SHA2-512-Hash autorisieren; Strong Name oder asymmetrischer Schlüssel sind Alternativen.
- `TRUSTWORTHY ON` ist kein regulärer Installationsweg. Eine Last-Resort-Ausnahme erfordert Prüfung selektiver Alternativen, eigene Architekturentscheidung und ausdrückliche Benutzerfreigabe.
- Für Windows-only-Funktionalität eine portable Alternative prüfen.

Details: [CLR_SECURITY_AND_PORTABILITY.md](../Documentation/Architecture/CLR_SECURITY_AND_PORTABILITY.md)

## 7. Dokumentation

- Codekommentare und technische Dokumentation sind deutsch.
- Etablierte englische Fachbegriffe und alle technischen Identifier bleiben englisch.
- Nicht triviale Codeblöcke erklären Absicht, Voraussetzungen, Seiteneffekte, Besonderheiten, Designgrund und relevante Performance- oder Plattformgrenzen.
- Veraltete Kommentare gelten als Fehler.
- Jedes öffentliche SQL-Objekt erhält eine eigene Dokumentationsseite und einen vollständigen Objekt-Header.
- Wiederholte Modulstatuswerte werden aus `module.yaml` abgeleitet; narrative Dokumentation bleibt manuell.
- Module registrieren ihre gekoppelten Dokumentations- und Contract-Artefakte im Manifest.

Details: [CODE_DOCUMENTATION.md](../Documentation/Standards/CODE_DOCUMENTATION.md)

## 8. Qualität und Statuswahrheit

- Statusangaben müssen dem nachweisbaren Stand entsprechen.
- Plan, Dokumentation und vorhandener Testcode sind kein Runtime-Nachweis.
- Nur tatsächlich ausgeführte erfolgreiche Prüfungen sind `validated`.
- Test-Evidence nennt Befehl oder Workflow, Scope, Version oder Plattform, Ergebnis, Datum und Einschränkungen.
- Keine erfundenen Fakten, Quellen, Kompatibilitätsangaben oder Testergebnisse.

## 9. Regeln und Entscheidungen

- Neue Anforderungen zuerst gegen README, AGENTS, CONTRIBUTING, AI-Metadaten, Standards und Entscheidungen prüfen.
- Keine doppelte oder konkurrierende Regel anlegen.
- Dauerhafte Entscheidungen mit stabiler ID in [DECISIONS.md](../Documentation/Architecture/DECISIONS.md) dokumentieren.
- Unlösbare Konflikte führen bis zur Klärung zu keiner Änderung.
- Die Konsistenzprüfung arbeitet standardmäßig diff-basiert über die in `.ai/repo_map.yaml` registrierten Impact-Pakete.
- Vollständige Repository-Audits sind für Baseline, Release, Governance- oder Kopplungsänderungen sowie auf ausdrücklichen Auftrag vorgesehen.

## 10. Persönlicher Brainstorm-Backlog

- `Backlog/personal_Backlog_Bainstorm.md` ist bei jeder Funktionsrecherche und Backlog-Pflege als vom Benutzer gepflegte Hinweisquelle zu lesen.
- Die Datei ist kein kanonischer Fachbacklog, keine Projektregel, keine Priorisierung und keine Implementierungsfreigabe.
- Bestehende Inhalte dürfen weder gelöscht noch stillschweigend ersetzt oder semantisch geglättet werden.
- KI-Systeme dürfen neue Gedanken, Recherchehinweise, Querverweise und Änderungskommentare ergänzen.
- Wird ein Inhalt fachlich überholt, wird der betroffene Text mit Markdown `~~durchgestrichen~~`. Direkt anschließend folgt ein Änderungskommentar mit Datum, tatsächlichem Autor beziehungsweise KI-Namen, Begründung und gegebenenfalls der ID des Nachfolgers.
- Wird ein Gedanke in eine kanonische Kandidatenliste überführt, bleibt der Originalgedanke erhalten und erhält nach Möglichkeit einen Querverweis auf `TC-`, `AC-` oder `UE-`-ID.
- Formale Rechercheergebnisse werden weiterhin in den drei kanonischen Kandidatenlisten gepflegt. Der persönliche Brainstorm darf diese Listen und `.ai/BACKLOG.md` nicht ersetzen.
- Datenschutz- und Secret-Regeln gelten auch für Ergänzungen in dieser Datei. Schutzwürdige Inhalte werden nicht in andere Artefakte kopiert.
