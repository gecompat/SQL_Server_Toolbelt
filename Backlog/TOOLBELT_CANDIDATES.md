# Toolbelt-Kandidaten

Kandidaten für wiederverwendbare Funktionen in `gecompat/SQL_Server_Toolbelt`.

Ein Eintrag hier ist **keine Implementierungszusage**. Nur priorisierte Kandidaten werden als Arbeitspakete in `.ai/BACKLOG.md` übernommen.

Vorlage: [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md)

---

## TC-2026-001: String-Split mit mehreren Trennzeichen

| Feld | Wert |
|---|---|
| **ID** | TC-2026-001 |
| **Titel** | String-Split mit mehreren Trennzeichen |
| **Ziel-Repo** | `SQL_Server_Toolbelt` |
| **Kategorie** | String |
| **SQL-Server-Lücke** | `STRING_SPLIT` (SQL Server 2016+) unterstützt nur ein einzelnes Trennzeichen. Ordinal-Unterstützung erst ab SQL Server 2022 (Kompatibilitätslevel 130+). Keine native Unterstützung für mehrere Trennzeichen. |
| **Betroffene Versionen** | SQL Server 2019, 2022 |
| **Spätere native Funktion** | Unklar |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Einheitliche Split-Funktion mit Ordinal und optionalem Multi-Separator-Support als TVF. |
| **Mögliche Technologie** | T-SQL (Inline TVF bevorzugt) |
| **Performance / Security** | Inline TVF ist parallelitätsfähig; Multi-statement TVF nicht. Keine Security-Risiken. |
| **Plattformgrenzen** | Windows und Linux; keine Azure-Einschränkung bekannt |
| **Dependencies** | keine |
| **Status** | `proposed` |
| **Primärquellen** | [STRING_SPLIT (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql) |
| **Prüfdatum** | 2026-07-28 |
| **Nächster Schritt** | Arbeitspaket erstellen und priorisieren |

---

## TC-2026-002: Datumsdifferenz in vollständigen Zeiteinheiten (Jahr/Monat/Tag)

| Feld | Wert |
|---|---|
| **ID** | TC-2026-002 |
| **Titel** | Datumsdifferenz in vollständigen Zeiteinheiten |
| **Ziel-Repo** | `SQL_Server_Toolbelt` |
| **Kategorie** | Datetime |
| **SQL-Server-Lücke** | `DATEDIFF` gibt keine vollständig korrekten kalendarischen Differenzen (z. B. für Alter in Jahren unter Berücksichtigung von Schaltjahren). |
| **Betroffene Versionen** | SQL Server 2019, 2022 |
| **Spätere native Funktion** | Nein |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Korrekte Alters- und Periodenberechnungen ohne Boilerplate. |
| **Mögliche Technologie** | T-SQL (Inline TVF oder SVF) |
| **Performance / Security** | Keine nennenswerten Performance-Risiken bei einzelnen Werten. |
| **Plattformgrenzen** | Keine |
| **Dependencies** | keine |
| **Status** | `proposed` |
| **Primärquellen** | [DATEDIFF (Transact-SQL)](https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql) |
| **Prüfdatum** | 2026-07-28 |
| **Nächster Schritt** | Arbeitspaket erstellen und priorisieren |
