# SQL Server Analyze – Kandidaten

Diese Liste enthält Analyse-, Diagnose-, Performance-, Konfigurations- oder Security-Assessment-Ideen ohne nachgewiesene gleichwertige Implementierung im Ziel-Repository. Bereits dort geplante Themen werden mit dem bestehenden Intake verknüpft; die Toolbelt-ID bleibt als Herkunft erhalten.

**Änderungen an `gecompat/SQL_Server_Analyze` benötigen einen ausdrücklichen Cross-Repository-Auftrag.** Dieser liegt für die Dokumentations- und Backlog-Übergabe vom 2026-09-11 vor. Ein Eintrag oder diese Übergabe ist keine Implementierungszusage für eines der beiden Repositories.

## AC-2026-001: Read-only Security-Feature-Katalog

| Feld | Wert |
|---|---|
| **ID** | `AC-2026-001` |
| **Titel** | Read-only Katalog für Dynamic Data Masking, Row-Level Security, Datenklassifizierung und Berechtigungen |
| **Ziel-Repository** | `SQL_Server_Analyze` |
| **Kategorie** | Analyse / Security |
| **SQL-Server-Lücke** | SQL Server stellt die einzelnen Security-Features und zugehörigen Catalog Views bereit, aber keinen einheitlichen, versionsbewussten Bericht, der Dynamic Data Masking, Row-Level Security, Sensitivity Classifications und relevante Berechtigungen gemeinsam inventarisiert und seine Aussagegrenzen offenlegt. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine einheitliche native Reporting-Funktion dokumentiert; einzelne Catalog Views und Features sind bereits vorhanden. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Read-only Bestandsaufnahme für Review, Governance und gezielte Vertiefung, ohne Security-Konfiguration automatisch zu verändern. |
| **Mögliche Technologie** | T-SQL Stored Procedure im bestehenden `monitor`-Vertrag; getrennte Resultsets beziehungsweise stabile Projektionen für Masking, Security Policies/Predicates, Klassifizierungen und Berechtigungen. |
| **Performance und Security** | Ausschließlich lesend. Metadatensichtbarkeit und fehlende Berechtigungen müssen als Teilstatus ausgewiesen werden; der Bericht beweist weder Wirksamkeit noch vollständige Schutzwirkung und darf keine Änderungen oder pauschalen Compliance-Aussagen erzeugen. |
| **Plattformgrenzen** | Windows und Linux voraussichtlich gleich; Azure-Produkte nicht automatisch aus dem SQL-Server-Vertrag ableiten. |
| **Dependencies** | Bestehende Capability-Erkennung, Ausgabearten und Status-/Partial-Verträge von `SQL_Server_Analyze`. |
| **Duplikatprüfung** | Root-README, Procedure-Referenz und Spezialfall-Architektur von `gecompat/SQL_Server_Analyze` am 2026-07-30 lesend geprüft. Vorhanden sind allgemeine Sicherheitskonfiguration, Verschlüsselungsanalyse und Spezialfeature-Inventur; ein expliziter kombinierter DDM-/RLS-/Klassifizierungs-/Berechtigungskatalog wurde in diesen öffentlichen Vertragsdokumenten nicht gefunden. |
| **Aktualisierter Abgleich** | Am 2026-09-11 gegen Toolbelt `f4fe237` und Analyze `6e46adc` geprüft. Die [Analyze-Abdeckungsmatrix](https://github.com/gecompat/SQL_Server_Analyze/blob/main/Metadata/Quality/Diagnostic_Coverage_Landscape.csv) führt `PRINCIPALS_ROLE_PERMISSIONS`, `RLS_DYNAMIC_MASKING` und `SENSITIVITY_CLASSIFICATION` bereits als `RESEARCHED_NOT_IMPLEMENTED`. Es besteht Planungsüberschneidung, kein Nachweis eines implementierten kombinierten Berichts. |
| **Kanonische Weiterführung** | [Analyze WI-0010 – Toolbelt-Übergabe](https://github.com/gecompat/SQL_Server_Analyze/blob/main/AI_Metadata/Internal_Documentation/Research/SQL_Server_Diagnostic_Coverage_Landscape.md#toolbelt-übergabe); die drei bestehenden CoverageKeys werden wiederverwendet. `AC-2026-001` bleibt Herkunftsreferenz und eröffnet kein paralleles Arbeitspaket. |
| **Status** | `researched` |
| **Primärquellen** | [SQL Server Analyze – README](https://github.com/gecompat/SQL_Server_Analyze/blob/main/README.md)<br>[SQL Server – Dynamic Data Masking](https://learn.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking?view=sql-server-ver17)<br>[SQL Server – Row-Level Security](https://learn.microsoft.com/en-us/sql/relational-databases/security/row-level-security?view=sql-server-ver17)<br>[SQL Server – sys.sensitivity_classifications](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sensitivity-classifications-transact-sql?view=sql-server-ver17)<br>[SQL Server – Permissions](https://learn.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine?view=sql-server-ver17) |
| **Prüfdatum** | 2026-09-11; Erstprüfung 2026-07-30 |
| **Nächster Schritt** | Unter Analyze `WI-0010` vor einer Priorisierung erneut die Teilabdeckung prüfen und mit dem Benutzer klären, ob bestehende Module erweitert oder getrennte Security-Berichte benötigt werden. Die gemeinsame Ausgabe, Resultset-Aufteilung, Metadatensichtbarkeit und Aussagegrenzen bleiben offene Vertragsfragen. Keine neue Procedure, Priorität oder Implementierungsfreigabe ableiten. |

Vor einem neuen Eintrag:

1. `gecompat/SQL_Server_Analyze` nach Objektname, Begriffen und gleichwertiger Capability durchsuchen;
2. vorhandene Implementierung und Dokumentation lesen;
3. nur einen echten Capability Gap eintragen;
4. Primärquelle, Prüfdatum und konkreten Übergabeschritt dokumentieren.

Vorlage: [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md)
