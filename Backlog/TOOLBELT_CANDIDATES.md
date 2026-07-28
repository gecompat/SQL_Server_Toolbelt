# Toolbelt-Kandidaten

Kandidaten für wiederverwendbare Funktionen in `gecompat/SQL_Server_Toolbelt`. Ein Eintrag ist keine Implementierungszusage.

Vorlage: [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md)

## TC-2026-001: String-Split mit mehreren Trennzeichen

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-001` |
| **Titel** | String-Split mit mehreren Trennzeichen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | String |
| **SQL-Server-Lücke** | `STRING_SPLIT` verarbeitet ein einzelnes Separatorzeichen; ein allgemeiner Multi-Separator-Vertrag fehlt. Ordinal-Unterstützung ist versionsabhängig. |
| **Betroffene Versionen** | SQL Server 2019, 2022, 2025 |
| **Spätere native Funktion** | Unklar; vor Umsetzung erneut gegen die aktuelle Version prüfen. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Einheitlicher Split-Vertrag mit Reihenfolge und optional mehreren Separatoren. |
| **Mögliche Technologie** | T-SQL; Inline TVF bevorzugt, falls der Vertrag set-basiert und optimizer-sichtbar umsetzbar ist. |
| **Performance und Security** | Planung: Inline-Ansatz und alternative native Funktionen benchmarken. Keine offensichtliche Secret- oder Berechtigungsanforderung; abschließende Security-Prüfung offen. |
| **Plattformgrenzen** | Windows und Linux voraussichtlich gleich; Azure nicht geprüft. |
| **Dependencies** | keine bekannt |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; native SQL-Server-Funktionen vor Arbeitspaket erneut prüfen. |
| **Status** | `proposed` |
| **Primärquellen** | https://learn.microsoft.com/sql/t-sql/functions/string-split-transact-sql |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Semantik für mehrere Separatoren, leere Tokens, Ordinal und Collation recherchieren; erst danach priorisieren. |

## TC-2026-002: Kalendarische Differenz in vollständigen Einheiten

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-002` |
| **Titel** | Kalendarische Differenz in vollständigen Jahren, Monaten und Tagen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Datetime |
| **SQL-Server-Lücke** | `DATEDIFF` zählt Boundary-Übergänge und liefert keinen vollständigen fachlichen Kalenderperiodenvertrag. |
| **Betroffene Versionen** | SQL Server 2019, 2022, 2025 |
| **Spätere native Funktion** | Nach aktuellem Stand keine allgemeine vollständige Kalenderperiodenfunktion; vor Umsetzung erneut prüfen. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Wiederverwendbare Alters- und Periodenberechnung mit dokumentierten Regeln für Monatsende und Schaltjahre. |
| **Mögliche Technologie** | T-SQL; Inline TVF oder Scalar Function nach Performance- und Vertragsvergleich. |
| **Performance und Security** | Performance für mengenorientierte Aufrufe offen; keine offensichtlichen besonderen Berechtigungen. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz; Azure nicht geprüft. |
| **Dependencies** | keine bekannt |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; SQL-Server-2025+-Funktionen vor Arbeitspaket erneut prüfen. |
| **Status** | `proposed` |
| **Primärquellen** | https://learn.microsoft.com/sql/t-sql/functions/datediff-transact-sql |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Fachliche Semantik und Randwertmatrix definieren, anschließend Implementierungsvarianten benchmarken. |
