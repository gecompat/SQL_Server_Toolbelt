# SQL Server Analyze – Kandidaten

Kandidaten für Analyse-, Diagnose-, Performance-, Konfigurations- und Security-Assessment-Ideen, die in `gecompat/SQL_Server_Analyze` gehören.

**Dieses Repository ändert `gecompat/SQL_Server_Analyze` nicht.** Diese Liste dient ausschließlich als Sammelstelle für Ideen, die später an das zuständige Repository weitergegeben werden können.

Ein Eintrag hier ist **keine Implementierungszusage** für dieses oder das andere Repository.

Vorlage: [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md)

---

## AC-2026-001: Unused-Index-Analyse

| Feld | Wert |
|---|---|
| **ID** | AC-2026-001 |
| **Titel** | Analyse ungenutzter Indizes |
| **Ziel-Repo** | `SQL_Server_Analyze` |
| **Kategorie** | Performance-Analyse |
| **SQL-Server-Lücke** | Keine eingebaute, einfach aufrufbare Analyse für ungenutzte oder redundante Indizes mit Empfehlung. `sys.dm_db_index_usage_stats` ist vorhanden, aber erfordert Interpretation und Kontext. |
| **Betroffene Versionen** | SQL Server 2019, 2022 |
| **Spätere native Funktion** | Nein |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Schnelle Identifikation von Indizes, die Wartungsaufwand erzeugen ohne gelesen zu werden. |
| **Mögliche Technologie** | T-SQL, Catalog Views, DMVs |
| **Performance / Security** | Lesend; kein Sicherheitsrisiko. |
| **Plattformgrenzen** | Keine bekannte Einschränkung |
| **Dependencies** | keine |
| **Status** | `proposed` |
| **Primärquellen** | [sys.dm_db_index_usage_stats](https://learn.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-db-index-usage-stats-transact-sql) |
| **Prüfdatum** | 2026-07-28 |
| **Nächster Schritt** | An `gecompat/SQL_Server_Analyze` kommunizieren |
