# PROJECT_RULES.md – Kanonische Regeln

## 1. Architekturregeln

### 1.1 Modulprinzip
- Modul = Lifecycle-, Deployment- und Dokumentationseinheit.
- Module besitzen versionierte Abhängigkeiten; Preflight vor erster Mutation.
- Fehlende oder ungeeignete Abhängigkeit: klare Meldung, vollständiger Abbruch, keine automatische Nachinstallation.
- Keine Abhängigkeitszyklen.
- Wiederverwendete Fachlogik existiert genau einmal; Wrapper verwenden die kanonische Implementierung.

### 1.2 Deployment
- Jedes Modul besitzt Install-, Upgrade- und Uninstall-Verträge.
- Lokale (Zieldatenbank) und zentrale (Toolbelt-Datenbank) Deployment-Modi sind gleichwertig.
- Cross-database-Verwendung ist Designziel, keine Garantie. Synonyme oder lokale Wrapper sind zulässig; Grenzen müssen dokumentiert sein.
- Keine divergierenden lokalen und zentralen Fachimplementierungen.

### 1.3 SQL-Namenskonventionen
- Stored Procedure: `USP_{CamelCase}`
- Inline/Multi-statement Table-valued Function: `TVF_{CamelCase}`
- Scalar-valued Function: `SVF_{CamelCase}`
- View: `VW_{CamelCase}`
- Schemas: `toolbelt_<category>` (z. B. `toolbelt_core`, `toolbelt_string`, `toolbelt_datetime`, `toolbelt_conversion`, `toolbelt_validation`, `toolbelt_json`, `toolbelt_xml`, `toolbelt_metadata`, `toolbelt_security`)
- Keine allgemeinen Schemas wie `string`, `time`, `io`, `json`.
- Neue Namen gegen aktuelle und zukünftige T-SQL-Keywords prüfen.
- Tabellen, Synonyme, Assemblies, Trigger, Sequences, Types: noch keine Konvention; als offene Entscheidung in DECISIONS.md dokumentieren.

Details: [SQL_OBJECT_NAMING.md](../Documentation/Standards/SQL_OBJECT_NAMING.md)

## 2. Datenschutzregeln

- Kein personenbezogenes Datum, keine Firmen-/Kundendaten, keine realen Infrastrukturnamen in Repository, Code, Beispielen, Tests, Commits, PRs, Issues.
- Keine Secrets (Passwörter, Tokens, API-Keys, Connection Strings mit Credentials, private Schlüssel).
- Keine Runtime-Ausgaben, Logs, Traces, Query Plans als Repository-Inhalt.
- Erlaubt: synthetische Daten, `localhost`, Contoso, Fabrikam, AdventureWorks, WideWorldImporters.
- `gecompat - Gerhard Pisch` ausschließlich für Copyright, Attribution, Lizenz.
- Datenschutz-Stop-Gate: vor jeder Dateiänderung, jedem Commit und PR prüfen.

Details: [DATA_PRIVACY_AND_CONFIDENTIALITY.md](../Documentation/Standards/DATA_PRIVACY_AND_CONFIDENTIALITY.md)

## 3. Coding-Regeln (T-SQL)

- Set-basiert; Inline TVF klar vor Multi-statement TVF.
- Error Handling an fachlichen/transaktionalen Grenzen; `TRY/CATCH` bei Cleanup, Transaktionen, dynamischem SQL; `THROW`.
- SARGability, Cardinality Estimation, Parallelität, Memory Grants, TempDB, Compile-Verhalten, implizite Konvertierungen beachten.
- `varchar`/`nvarchar` nach Semantik, Zeichenvorrat, Codepage, Collation; `nvarchar` kein pauschaler Default.
- Collation-safe für eigene unterstützte Pfade.
- Metadaten bevorzugt über Catalog Views (`sys.objects`, `sys.schemas`, usw.); `WITH (NOLOCK)` für read-only Catalog-Abfragen zulässig.
- Lokale Temp-Tabelle einmalig mit `OBJECT_ID(N'tempdb..#Name', N'U')` auflösen, dann über `tempdb.sys.*`.
- Keine Temp-Tabellennamen wie `#Temp`, `#Result`, `#Help`, `#Hilfe1`.

Details: [TSQL_ENGINEERING.md](../Documentation/Standards/TSQL_ENGINEERING.md)

## 4. USP-Vertrag

Verbindlicher Vertrag für alle Toolbelt-USPs. Details: [USP_CONTRACT.md](../Documentation/Standards/USP_CONTRACT.md)

## 5. Debug-Regeln

- `@Debug tinyint`: 0 keine Ausgabe; 1 Hauptschritte; 2 Entscheidungen/Zeilenzahlen; 3 Detailmetadaten/SQL; höhere Werte reserviert.
- Nur Messages, keine Resultsets.
- Echte Secrets (Passwörter, Tokens, Keys) nie ausgeben.

## 6. CLR-Regeln

- SQL CLR nur mit technischer Begründung; `SAFE` bevorzugt.
- `clr strict security` nicht regulär deaktivieren.
- Default-Trust: kontrollierter SHA2-512-Hash oder Strong Name.
- Keine privaten Signing Keys, PFX/P12/PVK oder SNK-Dateien im Repository.
- `TRUSTWORTHY ON` keine reguläre Option; nur dokumentierte Last-Resort-Ausnahme.

Details: [CLR_SECURITY_AND_PORTABILITY.md](../Documentation/Architecture/CLR_SECURITY_AND_PORTABILITY.md)

## 7. Dokumentationsregeln

- Codekommentare und technische Dokumentation: deutsch.
- Englisch bleibt für SQL-Schlüsselwörter, Produkt-/API-/Objektnamen, etablierte Fachbegriffe.
- Nicht triviale Codeblöcke erklären Zweck, Voraussetzungen, Seiteneffekte, Designgrund.
- Kommentare erklären Absicht, nicht jede Zeile. Veraltete Kommentare gelten als Fehler.
- Jedes öffentliche SQL-Objekt erhält einen Header.
- Sachlich, präzise, ohne Marketing, Floskeln, erfundene Fakten oder künstliche Übersetzungen.

Details: [CODE_DOCUMENTATION.md](../Documentation/Standards/CODE_DOCUMENTATION.md)

## 8. Qualitätsregeln

- Statusangaben müssen wahr sein.
- Plan/Doku/Testcode sind kein Runtime-Nachweis.
- Nur tatsächlich ausgeführte erfolgreiche Prüfungen sind `validated`.
- Einschränkungen ehrlich dokumentieren.
- Keine erfundenen Kompatibilitätsangaben oder Quellen.

## 9. Neue Regeln und Entscheidungen

- Neue Regeln zuerst gegen README, AGENTS, CONTRIBUTING, AI-Metadaten, Architekturentscheidungen und Standards prüfen.
- Keine konkurrierenden oder doppelten Regeln anlegen.
- Unlösbare Konflikte dokumentieren und nichts ändern.
- Dauerhafte Entscheidungen mit stabiler ID, Datum, Status, Begründung, Scope, Auswirkungen und ersetzten Alternativen in DECISIONS.md dokumentieren.
