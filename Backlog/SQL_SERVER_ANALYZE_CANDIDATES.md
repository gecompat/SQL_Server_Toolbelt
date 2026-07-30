# SQL Server Analyze – Kandidaten

Diese Liste enthält ausschließlich noch nicht im Ziel-Repository vorhandene Analyse-, Diagnose-, Performance-, Konfigurations- oder Security-Assessment-Ideen.

**Dieses Repository ändert `gecompat/SQL_Server_Analyze` nicht.** Ein Eintrag ist keine Implementierungszusage für eines der beiden Repositories.

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
| **Status** | `researched` |
| **Primärquellen** | [SQL Server Analyze – README](https://github.com/gecompat/SQL_Server_Analyze/blob/main/README.md)<br>[SQL Server – Dynamic Data Masking](https://learn.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking?view=sql-server-ver17)<br>[SQL Server – Row-Level Security](https://learn.microsoft.com/en-us/sql/relational-databases/security/row-level-security?view=sql-server-ver17)<br>[SQL Server – sys.sensitivity_classifications](https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/sys-sensitivity-classifications-transact-sql?view=sql-server-ver17)<br>[SQL Server – Permissions](https://learn.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine?view=sql-server-ver17) |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Im Ziel-Repository die SQL-Objekte und maschinenlesbaren Inventare vollständig auf gleichwertige Teilfunktionen prüfen; danach Scope und Resultset-Aufteilung mit dem Benutzer besprechen. Keine Implementierungsfreigabe ableiten. |

Vor einem neuen Eintrag:

1. `gecompat/SQL_Server_Analyze` nach Objektname, Begriffen und gleichwertiger Capability durchsuchen;
2. vorhandene Implementierung und Dokumentation lesen;
3. nur einen echten Capability Gap eintragen;
4. Primärquelle, Prüfdatum und konkreten Übergabeschritt dokumentieren.

Vorlage: [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md)
