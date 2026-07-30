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
| **SQL-Server-Lücke** | `STRING_SPLIT` verarbeitet ein einzelnes Separatorzeichen. Ein allgemeiner Vertrag für mehrere literal definierte Separatoren, leere Tokens und stabile Reihenfolge fehlt in SQL Server 2019 und 2022. SQL Server 2025 besitzt mit `REGEXP_SPLIT_TO_TABLE` eine regexbasierte Alternative, deren Semantik nicht automatisch mit einem Literal-Separatorvertrag identisch ist. |
| **Betroffene Versionen** | SQL Server 2019 und 2022; SQL Server 2025 nur bei bewusst abweichendem Literalvertrag oder als alternativer Provider. |
| **Spätere native Funktion** | Teilweise: `REGEXP_SPLIT_TO_TABLE` ab SQL Server 2025, Compatibility Level 170. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Einheitlicher Split-Vertrag mit definierter Token-Reihenfolge, kontrolliertem Verhalten für leere Tokens und optional mehreren Separatoren. |
| **Mögliche Technologie** | Implementierte T-SQL Inline-TVF mit `toolbelt.core.generate-series` als gemeinsamem Positionsprovider. SQL Server 2025 Regex bleibt ausschließlich enges Testoracle. |
| **Performance und Security** | Synchrone lineare Verarbeitung ohne künstliche `nvarchar(max)`-Grenze; Separatorvergleich binär und literal; keine Regex-/SQL-Interpretation. Große LOBs bleiben eine bewusst dokumentierte Ressourcenfrage. |
| **Plattformgrenzen** | Windows und Linux voraussichtlich gleich. Azure nicht geprüft. |
| **Dependencies** | `toolbelt.core.generate-series` Version `1.0.0` in derselben Datenbank. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; TC-2026-010 ist breiter und ersetzt diesen Literalvertrag nicht automatisch. |
| **Status** | `implemented`; Runtime `not executed` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | `AP-2026-011` mit statischen, SQL-Server-2025-Linux- und Lifecycle-Prüfungen abschließen. Version 1 bleibt auf mehrere einzelne Trennzeichen ohne Quote-/Escape-Semantik begrenzt; die breitere Ausbaustufe ist separat als `TC-2026-032` erfasst. |

## TC-2026-002: Kalendarische Differenz in vollständigen Einheiten

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-002` |
| **Titel** | Kalendarische Differenz in vollständigen Jahren, Monaten und Tagen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Datetime |
| **SQL-Server-Lücke** | `DATEDIFF` zählt Boundary-Übergänge und liefert keinen vollständigen fachlichen Kalenderperiodenvertrag. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine allgemeine vollständige Kalenderperiodenfunktion dokumentiert; vor Umsetzung erneut prüfen. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Wiederverwendbare Alters- und Periodenberechnung mit dokumentierten Regeln für Monatsende, Schaltjahre und umgekehrte Intervalle. |
| **Mögliche Technologie** | T-SQL; Inline TVF oder Scalar-valued Function nach Vertrags- und Performancevergleich. |
| **Performance und Security** | Performance bei mengenorientierten Aufrufen offen. Keine besonderen Berechtigungen erwartet. Datentyp- und Overflow-Verhalten müssen Teil des Vertrags sein. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. Azure nicht geprüft. |
| **Dependencies** | Keine bekannt |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; TC-2026-004 und TC-2026-005 behandeln Truncation beziehungsweise Bucketing, nicht vollständige Kalenderperioden. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Fachliche Semantik und Randwertmatrix definieren, anschließend Implementierungsvarianten benchmarken. |

## TC-2026-003: Einheitliches ResultTable-Routing für Stored Procedures

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-003` |
| **Titel** | ResultTable-Routing und automatische Anpassung lokaler Temp-Tabellen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | SQL Server bietet keinen eingebauten allgemeinen Mechanismus, mit dem eine Stored Procedure ihr bekanntes Resultset wahlweise direkt ausgibt oder ohne `INSERT ... EXEC` in eine bereits vom Aufrufer erzeugte lokale Temp-Tabelle schreibt und deren Schema kontrolliert anpasst. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein bekannt |
| **Use-Case-Typ** | Realistisch; zugleich grundlegende Infrastruktur für weitere Toolbelt-USPs. |
| **Nutzen** | Programmatische Weiterverarbeitung von USP-Ergebnissen, beliebig tiefe verschachtelte Toolbelt-Aufrufe und einheitlicher `@ResultTable`-/`@KeepData`-Vertrag. |
| **Mögliche Technologie** | T-SQL mit kontrolliertem dynamischem DDL, einmaliger Temp-Table-Auflösung über `OBJECT_ID`, anschließend Catalog Views. Freies DDL später gegebenenfalls mit ScriptDOM analysieren. |
| **Performance und Security** | Ein vollständiger Preflight vor der ersten Mutation; keine wiederholten Metadatenfunktionsaufrufe; strikte Validierung lokaler Temp-Tabellennamen; keine automatische Entfernung blockierender Dependencies; kein ungeprüftes fremdes DDL. |
| **Plattformgrenzen** | T-SQL-Kern soll unter Windows und Linux identisch funktionieren. |
| **Dependencies** | Architekturvertrag in `Documentation/Standards/USP_CONTRACT.md`; voraussichtlich erstes `toolbelt_core`-Modul. |
| **Duplikatprüfung** | Toolbelt-Backlogs und bestehende Foundation-Dokumentation geprüft; Vertrag vorhanden, Runtime-Implementierung fehlt bewusst. |
| **Status** | `researched` |
| **Primärquellen** | [USP_CONTRACT.md](../Documentation/Standards/USP_CONTRACT.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/object-id-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Als erstes Kernarbeitspaket priorisieren und Objektinventar, Schemaschnittstellen, Transaktionsgrenzen sowie Contract-Testmatrix implementierungsreif spezifizieren. |

## TC-2026-004: DATETRUNC-Kompatibilität für SQL Server 2019

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-004` |
| **Titel** | Versionsübergreifende Date/Time-Truncation |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Datetime |
| **SQL-Server-Lücke** | `DATETRUNC` wurde erst mit SQL Server 2022 eingeführt. SQL Server 2019 benötigt wiederkehrende `DATEADD`-/`DATEDIFF`-Ausdrücke, deren Verhalten für `week`, `iso_week`, Datentyp und Fractional Scale leicht auseinanderläuft. |
| **Betroffene Versionen** | SQL Server 2019; 2022 und 2025 besitzen die native Funktion. |
| **Spätere native Funktion** | Ja: `DATETRUNC` ab SQL Server 2022. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Einheitlicher Vertrag für Truncation nach Jahr, Quartal, Monat, Tag, Woche und Zeitanteilen sowie sauberer Migrationspfad auf native Provider. |
| **Mögliche Technologie** | T-SQL. Die native Funktion erhält Eingabetyp und Fractional Scale dynamisch, während eine skalare UDF einen festen Rückgabetyp benötigt. Deshalb nur nach expliziter Entscheidung zwischen bewusst vereinheitlichtem Rückgabetyp, typspezifischer Funktionsfamilie oder einem anderen Vertrag weiterführen. |
| **Performance und Security** | Muss SARGability-Auswirkungen und Scalar-UDF-Inlining dokumentieren. `week` hängt nativ von `@@DATEFIRST` ab; `iso_week` nicht. `datepart` muss in einem Backport kontrolliert aufgelöst werden. T-SQL-UDFs erlauben weder dynamisches SQL noch `TRY...CATCH` oder `RAISERROR`; Fehlerparität ist daher eine offene Vertragsentscheidung. Keine besonderen Berechtigungen. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Grundsatzentscheidung zu Rückgabetyp, Objektfamilie, Datepart-Aliassen und Fehlervertrag; danach vollständige scopebezogene Eigenvalidierung gemäß `DEC-2026-021`. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; TC-2026-002 und TC-2026-005 besitzen andere fachliche Verträge. |
| **Status** | `researched` |
| **Primärquellen** | [Auswahlvorbereitung für das zweite Modul](../Documentation/Research/SECOND_MODULE_SELECTION.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/datetrunc-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Zurückgestellt, bis der Benutzer Rückgabetyp beziehungsweise Objektfamilie, unterstützte Dateparts, `DATEFIRST`- und Fehlersemantik besprochen hat. Keine Implementierung aus dem Research-Status ableiten. |

## TC-2026-005: DATE_BUCKET-Kompatibilität für SQL Server 2019

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-005` |
| **Titel** | Versionsübergreifendes Date/Time-Bucketing |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Datetime |
| **SQL-Server-Lücke** | `DATE_BUCKET` ist erst ab SQL Server 2022 vorhanden. SQL Server 2019 besitzt keinen allgemeinen nativen Vertrag für Buckets variabler Breite und optionalen Ursprung. |
| **Betroffene Versionen** | SQL Server 2019; 2022 und 2025 besitzen die native Funktion. |
| **Spätere native Funktion** | Ja: `DATE_BUCKET` ab SQL Server 2022. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Wiederverwendbare Zeitfenster für Aggregation, Telemetrie und Reporting ohne wiederholte fehleranfällige Berechnungen. |
| **Mögliche Technologie** | T-SQL mit `DATEADD`/`DATEDIFF_BIG` und explizitem Origin-Vertrag. Exakte Typgleichheit zur nativen Funktion ist gesondert zu prüfen. |
| **Performance und Security** | Overflow, negative Zeitdifferenzen, Wochenursprung und Datentypgrenzen testen. Ausdrucksverwendung in Prädikaten kann SARGability beeinflussen. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Mögliche Wiederverwendung aus TC-2026-004, ohne doppelte Fachlogik. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/date-bucket-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Paritätsmatrix für Dateparts, Bucketbreite, Origin, negative Abstände und Rückgabetyp erstellen. |

## TC-2026-006: GENERATE_SERIES-Kompatibilität für SQL Server 2019

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-006` |
| **Titel** | Zahlenreihen als Table-valued Function |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | `GENERATE_SERIES` ist erst ab SQL Server 2022 und grundsätzlich ab Compatibility Level 160 verfügbar. Die derzeit auf Azure SQL Database und Fabric SQL Database begrenzte Database-scoped Configuration `ALLOW_BUILTIN_TVF_IN_ALL_COMPAT_LEVELS` ändert den SQL-Server-Supportscope nicht; SQL Server 2019 benötigt weiterhin Hilfstabellen, rekursive CTEs oder projektspezifische Generatoren. |
| **Betroffene Versionen** | SQL Server 2019; außerdem Datenbanken auf neueren Engines mit zu niedrigem Compatibility Level, sofern die native TVF nicht freigeschaltet ist. |
| **Spätere native Funktion** | Ja: `GENERATE_SERIES` ab SQL Server 2022. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Einheitlicher, dokumentierter Zahlenreihenvertrag für Kalender, Datenexpansion, Tests und Mengenoperationen. |
| **Mögliche Technologie** | Als drittes Modul mit zwei portablen T-SQL Inline TVFs für `int` und `bigint` implementiert. Binär gestapelte konstante Rowsets und ein zeilenzahlgesteuerter Row Goal ersetzen rekursive CTEs, Systemkataloge und eine persistente Numbers-Tabelle. Der `int`-Wrapper verwendet den gemeinsamen `bigint`-Kern. |
| **Performance und Security** | Sehr große Reihen bleiben Aufruferverantwortung; es gibt keine stille Kürzung. `decimal(38,0)` schützt interne Grenzarithmetik. Eine mathematische Zeilenzahl außerhalb `bigint` erzeugt einen Engine-Overflow. Cardinality Estimates, äußerer Row Goal, Joins, `CROSS APPLY` und eine Million synthetische Werte gehören zur Testmatrix. Keine besonderen Security-Rechte außer `SELECT`/`REFERENCES`. |
| **Plattformgrenzen** | Windows und Linux sollen denselben Vertrag verwenden. |
| **Dependencies** | Keine Modulabhängigkeit. Der öffentliche Vertrag wurde am 2026-07-30 freigegeben. Eine persistente Numbers-Tabelle und damit eine neue Tabellen-Namenskonvention sind nicht erforderlich. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `implemented` |
| **Primärquellen** | [GENERATE_SERIES_MODULE_DESIGN.md](../Documentation/Architecture/GENERATE_SERIES_MODULE_DESIGN.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/generate-series-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/queries/top-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Gezielte physische SQL-Server-2019-/2022- und Windows-Releasevalidierung planen; der SQL-Server-2025-Linux-Lauf mit Compatibility Levels 150/160/170 ist erfolgreich. |

## TC-2026-007: Bit-Manipulationsfunktionen für SQL Server 2019

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-007` |
| **Titel** | Backport der Bit-Manipulationsfunktionen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Binary / Core |
| **SQL-Server-Lücke** | `LEFT_SHIFT`, `RIGHT_SHIFT`, `BIT_COUNT`, `GET_BIT` und `SET_BIT` wurden erst mit SQL Server 2022 eingeführt. SQL Server 2019 besitzt nur grundlegende bitweise Operatoren. |
| **Betroffene Versionen** | SQL Server 2019; 2022 und 2025 besitzen native Funktionen. |
| **Spätere native Funktion** | Ja: fünf Bit-Manipulationsfunktionen ab SQL Server 2022. |
| **Use-Case-Typ** | Realistisch, aber eher technisch spezialisiert. |
| **Nutzen** | Lesbare, wiederverwendbare Operationen für Flags, Masken und kompakte binäre Repräsentationen. |
| **Mögliche Technologie** | T-SQL für Integer-Typen; SQL CLR prüfen, wenn `binary(n)`/`varbinary(n)` performant und speicherschonend unterstützt werden soll. |
| **Performance und Security** | Bitnummerierung, Vorzeichen, Shift-Überlauf und Byte-Reihenfolge müssen exakt dokumentiert werden. CLR nur mit begründetem Providervergleich. |
| **Plattformgrenzen** | T-SQL portabel; CLR-Provider pro Plattform ausweisen. |
| **Dependencies** | Keine bekannt |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/bit-manipulation-functions-overview?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Exakten Datentypumfang und Parität zu SQL Server 2022/2025 festlegen; Integer- und Binary-Provider getrennt benchmarken. |

## TC-2026-008: Richtungsabhängiges TRIM für SQL Server 2019

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-008` |
| **Titel** | `LEADING`-, `TRAILING`- und `BOTH`-Trim-Kompatibilität |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | String |
| **SQL-Server-Lücke** | SQL Server 2019 unterstützt `TRIM([characters FROM] string)` für beide Seiten, aber nicht die ab SQL Server 2022 bei Compatibility Level 160 verfügbaren Positionsangaben `LEADING`, `TRAILING` und `BOTH`. |
| **Betroffene Versionen** | SQL Server 2019; außerdem niedrigere Compatibility Levels auf neueren Engines. |
| **Spätere native Funktion** | Ja: erweiterte TRIM-Syntax ab SQL Server 2022 bei Compatibility Level 160. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Konsistentes Entfernen benutzerdefinierter Zeichensätze nur links, nur rechts oder beidseitig. |
| **Mögliche Technologie** | T-SQL; Inline- oder Scalar-valued Functions nach Performancevergleich. |
| **Performance und Security** | Collation bestimmt Zeichenvergleich und muss zum Vertrag passen. LOB- und Max-Längen-Verhalten der nativen Syntax nicht unbegründet erweitern. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Keine bekannt |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/trim-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Caller- versus invariant-Collation-Semantik und Verhalten bei leerem Zeichensatz, NULL und großen Werten definieren. |

## TC-2026-009: JSON-Konstruktion und Pfadprüfung für SQL Server 2019

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-009` |
| **Titel** | Kompatibilitätsmodul für `JSON_OBJECT`, `JSON_ARRAY` und `JSON_PATH_EXISTS` |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | JSON |
| **SQL-Server-Lücke** | SQL Server 2019 besitzt `FOR JSON`, `ISJSON`, `JSON_VALUE`, `JSON_QUERY`, `JSON_MODIFY` und `OPENJSON`, aber nicht die mit SQL Server 2022 eingeführten Konstruktoren `JSON_OBJECT`/`JSON_ARRAY` und die Pfadprüfung `JSON_PATH_EXISTS`. |
| **Betroffene Versionen** | SQL Server 2019; 2022 und 2025 besitzen native Funktionen. |
| **Spätere native Funktion** | Ja: SQL Server 2022. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Lesbare JSON-Konstruktion und Pfadprüfung mit einem stabilen Vertrag für ältere Installationen. |
| **Mögliche Technologie** | T-SQL auf Basis von `FOR JSON`, `STRING_ESCAPE`, `JSON_VALUE`, `JSON_QUERY` und `OPENJSON`; exakte Null-, Escaping- und Typsemantik muss nachgebildet oder als bewusster Subset-Vertrag dokumentiert werden. |
| **Performance und Security** | Doppeltes Escaping, Injection in JSON-Schlüssel, LOB-Materialisierung und mehrfache Parsingkosten prüfen. Keine ungeprüfte String-Konkatenation. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. Azure nicht automatisch unterstützt. |
| **Dependencies** | Mögliche gemeinsame JSON-Escaping-Kernlogik; keine Duplikate zwischen Konstruktoren. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; JSON-Aggregate werden separat in TC-2026-013 behandelt. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2022?view=sql-server-ver16<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/json-object-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/json-path-exists-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Native Null-, Typ-, Escaping- und Fehlersemantik als Contract-Matrix erfassen und einen klaren Backport-Subset bestimmen. |

## TC-2026-010: Regular-Expression-Kompatibilitätsmodul

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-010` |
| **Titel** | Regex-Matching, Extraktion, Ersetzung und Split für SQL Server 2019/2022 |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | String |
| **SQL-Server-Lücke** | Native `REGEXP_*`-Funktionen stehen erst in SQL Server 2025 zur Verfügung. SQL Server 2019 und 2022 besitzen keine allgemeine Regex-Engine. |
| **Betroffene Versionen** | SQL Server 2019 und 2022; SQL Server 2025 als nativer Provider und Referenzvertrag. |
| **Spätere native Funktion** | Ja: SQL Server 2025 mit RE2-basierter Implementierung. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Wiederverwendbare Validierung, Suche, Extraktion, Ersetzung und Tokenisierung ohne externe Anwendungsschicht. |
| **Mögliche Technologie** | SQL CLR ist wahrscheinlich geeigneter als reines T-SQL. .NET Regex ist nicht automatisch semantisch identisch zu RE2; ein exakter Kompatibilitätsanspruch benötigt bewusste Syntaxgrenze oder geprüften RE2-Provider. |
| **Performance und Security** | Pattern-Limits, ReDoS-Risiken, Timeout, Speicherverbrauch und LOB-Grenzen definieren. Native SQL-Server-2025-Regex folgt nicht der sprachlichen Collation-Semantik. Parallelitätsfähigkeit und Streaming für TVFs prüfen. |
| **Plattformgrenzen** | `SAFE`-fähigen CLR-Kern und Linux-Verhalten prüfen; Windows-only-Provider nur bei messbarem Vorteil. |
| **Dependencies** | CLR-Trust- und Portabilitätsregeln; möglicher Nutzen für TC-2026-001. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; TC-2026-001 ist ein engerer Split-Vertrag. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/relational-databases/regular-expressions/overview?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Fachlichen Mindestumfang und gewünschte Regex-Syntax festlegen; RE2-, .NET- und gegebenenfalls eingeschränkten T-SQL-Provider vergleichen. |

## TC-2026-011: Fuzzy String Matching für SQL Server 2019/2022

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-011` |
| **Titel** | Edit Distance und Jaro-Winkler als stabile Toolbelt-Funktionen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | String / Validation |
| **SQL-Server-Lücke** | Fuzzy-String-Funktionen stehen erst in SQL Server 2025 zur Verfügung und sind dort derzeit Preview. SQL Server 2019 und 2022 besitzen keine nativen allgemeinen Edit-Distance- oder Jaro-Winkler-Funktionen. |
| **Betroffene Versionen** | SQL Server 2019 und 2022; SQL Server 2025 nur als Preview-Referenz oder optionaler Provider. |
| **Spätere native Funktion** | Ja, derzeit Preview in SQL Server 2025: `EDIT_DISTANCE`, `EDIT_DISTANCE_SIMILARITY`, `JARO_WINKLER_DISTANCE`, `JARO_WINKLER_SIMILARITY`. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Duplikaterkennung, fehlertolerante Validierung und Ähnlichkeitsbewertung mit expliziter, versionsstabiler Semantik. |
| **Mögliche Technologie** | SQL CLR für performante skalare Berechnung; T-SQL-Referenzimplementierung nur für Korrektheitsvergleich oder kleine Eingaben prüfen. |
| **Performance und Security** | Quadratischer Speicher-/CPU-Bedarf bei naiver Edit Distance vermeiden; maximale Eingabelänge und Abbruchgrenzen definieren. Native Preview-Funktionen folgen derzeit nicht der Collation-Semantik, daher invariant oder Caller-Semantik ausdrücklich entscheiden. |
| **Plattformgrenzen** | Portablen `SAFE`-CLR-Provider prüfen; kein Windows-only-Zwang ohne Messnachweis. |
| **Dependencies** | CLR-Grundmodul nur falls tatsächlich erforderlich. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/relational-databases/fuzzy-string-match/overview?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Preview-Semantik, Algorithmen, Grenzwerte und Rückgabetypen erfassen; T-SQL und CLR mit festen Testvektoren vergleichen. |

## TC-2026-012: Base64 Encode/Decode für SQL Server 2019/2022

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-012` |
| **Titel** | Base64- und URL-safe-Base64-Konvertierung |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Conversion / Binary |
| **SQL-Server-Lücke** | `BASE64_ENCODE` und `BASE64_DECODE` sind erst ab SQL Server 2025 nativ vorhanden. Frühere Versionen benötigen XML-basierte Workarounds, CLR oder externe Verarbeitung. |
| **Betroffene Versionen** | SQL Server 2019 und 2022; SQL Server 2025 besitzt native Funktionen. |
| **Spätere native Funktion** | Ja: SQL Server 2025. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Standard- und URL-safe-Base64 für Binärdaten, Tokens ohne Secret-Inhalt, Integrationsformate und Tests. |
| **Mögliche Technologie** | Als zweites Modul ausgewählt und mit T-SQL/XML für Standard-Base64 sowie kontrollierter T-SQL-Normalisierung für Base64URL implementiert. `SAFE` SQL CLR bleibt für große Werte nur bei messbarem Vorteil eine spätere Alternative. Der Backport verwendet das Projektschema und imitiert keinen nativen Namen im Systemschema. |
| **Performance und Security** | Native Semantik für Standard-/URL-safe-Alphabet, Padding, Whitespace-Toleranz, ungültige Zeichen, Formatfehler, `NULL`, Rückgabetyp und Längengrenzen als Contract-Matrix erfassen. Große LOBs dürfen nicht unnötig mehrfach oder als XML materialisiert werden. Dekodierte Inhalte bleiben untrusted binary data; Debug darf Binärinhalte anzeigen, echte Secrets jedoch nicht aktiv ausgeben. |
| **Plattformgrenzen** | T-SQL portabel; CLR-Provider pro Plattform testen. |
| **Dependencies** | Keine Modulabhängigkeit. Der öffentliche Vertrag wurde am 2026-07-29 freigegeben; `DEC-2026-021` verlangt scopebezogene Eigenvalidierung statt eines fachlich unabhängigen ResultTable-Gates. CLR-Infrastruktur ausschließlich optional und nach Messnachweis. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `implemented` |
| **Primärquellen** | [SQL_SERVER_TOOLBELT_LANDSCAPE.md](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>[Auswahlvorbereitung für das zweite Modul](../Documentation/Research/SECOND_MODULE_SELECTION.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-encode-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-decode-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/xml/use-the-binary-base64-option?view=sql-server-ver17<br>https://www.rfc-editor.org/rfc/rfc4648 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | SQL Server 2025 mit Compatibility Levels 150/160/170 ausführen; danach gezielte physische 2019-/2022- und Windows-Releasevalidierung planen. |

## TC-2026-013: JSON-Aggregate für SQL Server 2019/2022

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-013` |
| **Titel** | JSON-Array- und JSON-Object-Aggregation |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | JSON |
| **SQL-Server-Lücke** | `JSON_ARRAYAGG` und `JSON_OBJECTAGG` stehen in SQL Server 2025 derzeit nur als Preview zur Verfügung; SQL Server 2019 und 2022 besitzen keine nativen JSON-Aggregatfunktionen. |
| **Betroffene Versionen** | SQL Server 2019 und 2022; SQL Server 2025 bei Bedarf als stabiler Fallback, solange die native Funktion Preview oder bewusst nicht aktiviert ist. |
| **Spätere native Funktion** | Ja, derzeit Preview in SQL Server 2025. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Gruppierte JSON-Konstruktion mit dokumentierter Reihenfolge, Nullbehandlung und Escaping-Semantik. |
| **Mögliche Technologie** | T-SQL auf Basis von `FOR JSON`, `STRING_AGG` und gemeinsamem JSON-Escaping-Kern; CLR-Aggregat nur nach deutlichem Vorteil. |
| **Performance und Security** | Reihenfolge, `NULL ON NULL`/`ABSENT ON NULL`, Duplicate Keys, Max-Länge, Memory Grants und Escape-Korrektheit testen. Keine zweite unabhängige JSON-Konstruktionslogik neben TC-2026-009. |
| **Plattformgrenzen** | T-SQL portabel; native 2025-Preview separat ausweisen. |
| **Dependencies** | Gemeinsamer JSON-Escaping- und Typkonvertierungskern mit TC-2026-009. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; Konstruktoren und Pfadprüfung verbleiben in TC-2026-009. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/json-arrayagg-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/json-objectagg-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Preview-Vertrag und T-SQL-Fallback anhand fester JSON-Testvektoren vergleichen; gemeinsamen JSON-Kern vor Objektentwurf festlegen. |

## TC-2026-014: Transaktionsunabhängige Ereignisprotokollierung

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-014` |
| **Titel** | Logging, das einen Rollback der aufrufenden Transaktion überlebt |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | SQL Server besitzt keinen direkten T-SQL-Vertrag für autonome Transaktionen. Ein regulärer Insert in eine Logtabelle und auch ein Service-Broker-`SEND` gehören zur aktuellen Transaktion und werden mit ihr zurückgerollt. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine direkte autonome T-SQL-Transaktion dokumentiert. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Fehler-, Fortschritts- oder Audit-Ereignisse können erhalten bleiben, obwohl die fachliche Caller-Transaktion zurückgerollt wird oder uncommittable ist. |
| **Mögliche Technologie** | Providervergleich erforderlich: reguläre SQL-CLR-Verbindung als zweite Session; bewusst konfigurierter Loopback-Linked-Server-RPC ohne Transaction Promotion; externer Logger; eingeschränkter Error-Log-Provider über `RAISERROR ... WITH LOG` beziehungsweise `xp_logevent`; Extended Events für beobachtbare Engine-Ereignisse. Service Broker ist für Commit-gekoppelte asynchrone Arbeit geeignet, aber nicht als rollback-unabhängiger Sender innerhalb derselben Transaktion. `tSQLt.NewConnection` belegt als Apache-2.0-Prior-Art die synchrone Ausführung über eine separate SQL-CLR-Verbindung mit unterdrückter Ambient Transaction, legt aber keinen Toolbelt-Vertrag fest. |
| **Performance und Security** | Eine zweite Session besitzt eigene Transaktion, `SET`-Optionen und Security Context und sieht keine lokalen Temp-Tabellen. Loopback kann sich an Locks der Caller-Transaktion selbst blockieren. SQL CLR benötigt Reauthentifizierung beziehungsweise kontrollierte Credentials und einen Trust-Vertrag. Error-Log-Provider sind längen- und berechtigungsbeschränkt; `RAISERROR ... WITH LOG` schreibt höchstens 440 Bytes. Payloads benötigen strikte Datenschutz-, Größen- und Secret-Regeln. |
| **Plattformgrenzen** | T-SQL-Linked-Server-, SQL-CLR-, Error-Log- und externe Provider sind getrennt auf Windows/Linux, Edition, Providerverfügbarkeit und Betriebsfreigabe zu prüfen. Azure ist nicht automatisch unterstützt. |
| **Dependencies** | Mögliche Dependencies zu Execution Correlation (`TC-2026-019`) und standardisiertem Error Envelope (`TC-2026-017`). Eine persistente Logtabelle würde vor Implementierung eine freigegebene Tabellen-Namenskonvention erfordern. |
| **Duplikatprüfung** | Alle drei Backlog-Listen sowie vorhandene Architektur- und USP-Verträge geprüft; kein gleichwertiger Kandidat vorhanden. |
| **Status** | `researched` |
| **Primärquellen** | https://techcommunity.microsoft.com/blog/sqlserver/how-to-create-an-autonomous-transaction-in-sql-server-2008/383471<br>https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/data-access/context-connection?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/database-engine/service-broker/transactional-messaging?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/xp-logevent-transact-sql?view=sql-server-ver17<br>https://tsqlt.org/125/tsqlt-build-9-release-notes/<br>https://github.com/tSQLt-org/tSQLt/blob/4a921d0dacfb1d66b3db124c58158c80e5e910e6/tSQLtCLR/tSQLtCLR/CommandExecutor.cs |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer zuerst Haltbarkeitsgarantie, synchrones/asynchrones Verhalten, zulässige Provider, Blockierungsverhalten, Payload und Security Context besprechen; erst danach einen öffentlichen Funktionsvertrag entwerfen. |

## TC-2026-015: Asynchrone Work-Queue und begrenzte Parallelisierung

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-015` |
| **Titel** | Mehrere unabhängige Arbeiten in getrennten Sessions parallel ausführen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | T-SQL-Statements eines regulären Batches werden nacheinander gestartet. Query-Plan-Parallelität parallelisiert Operatoren einer Abfrage, stellt aber keinen allgemeinen Fan-out/Fan-in-Vertrag für mehrere unabhängige Statements oder Procedures bereit. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Kein allgemeiner nativer Batch-Parallelisierer dokumentiert. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Unabhängige Arbeitspakete können mit begrenzter Parallelität, eigenem Status und anschließender Ergebnisaggregation abgearbeitet werden. |
| **Mögliche Technologie** | Service Broker mit Internal Activation und `MAX_QUEUE_READERS` als T-SQL-naher Hauptkandidat; externer Orchestrator als portabler Provider; SQL Server Agent über `sp_start_job` für gröbere, vorab definierte Jobs; tabellenbasierter Queue-/Claiming-Kern mit getrenntem Worker-Provider. SQL Server Multi Thread und die Queue-Tabellen der SQL Server Maintenance Solution sind konkrete, unterschiedlich zugeschnittene Prior-Art-Beispiele. Eine SQL-CLR-Routine darf gemäß Projektregel keine eigenen Worker Threads erzwingen. |
| **Performance und Security** | Parallelität muss hart begrenzt und gegen CPU, Memory Grants, TempDB, Locks und Logdurchsatz geschützt werden. Jede Session besitzt einen eigenen Transaktions- und Sessionzustand. Beliebiger SQL-Text wäre eine Code-Execution-Schnittstelle und ist kein sicherer Default; benannte und validierte Work-Types sind zu bevorzugen. Fehler-, Timeout-, Retry-, Idempotenz-, Result- und Cancellation-Semantik sind vor Objektentwurf festzulegen. |
| **Plattformgrenzen** | Service Broker gilt für SQL Server und laut Dokumentation teilweise Managed Instance; SQL Server Agent ist editions- und dienstabhängig. Externe Provider sowie Windows/Linux sind getrennt zu validieren. |
| **Dependencies** | `TC-2026-017` bis `TC-2026-022`; persistente Queue-/Statusobjekte benötigen eine zuvor freigegebene Tabellen-Namenskonvention. |
| **Duplikatprüfung** | Alle Kandidatenlisten und Architekturregeln geprüft. Vorhandene Hinweise zur Query-Plan-Parallelität sind kein Work-Queue-Vertrag. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/database-engine/service-broker/typical-uses-of-service-broker?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-queue-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/database-engine/service-broker/understanding-when-activation-occurs?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-start-job-transact-sql?view=sql-server-ver17<br>https://github.com/jobbish-sql/SQL-Server-Multi-Thread<br>https://github.com/olahallengren/sql-server-maintenance-solution/blob/main/Queue.sql |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer Use Cases, synchrones Warten versus Fire-and-forget, Work-Type-Vertrag, gewünschte Parallelitätsgrenze und zulässige Provider einzeln besprechen. |

## TC-2026-016: Lange Console-Messages mit sofortiger Ausgabe

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-016` |
| **Titel** | Gepufferte und ungepufferte Console-Ausgabe langer Texte |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | `PRINT` begrenzt Ausgaben auf 8.000 Nicht-Unicode- beziehungsweise 4.000 Unicode-Zeichen und kann clientseitig verzögert erscheinen. `RAISERROR ... WITH NOWAIT` sendet sofort, ist aber auf höchstens 2.047 Zeichen pro Message begrenzt. Eine einheitliche, Unicode-sichere Chunking- und Severity-Semantik fehlt. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein bekannt |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Lange Debug-, Fortschritts- und generierte SQL-Texte können vollständig, geordnet und auf Wunsch sofort im Messages-Kanal ausgegeben werden, ohne zusätzliche Resultsets zu erzeugen. |
| **Mögliche Technologie** | Kleine T-SQL-Infrastruktur-USP mit `PRINT`- und `RAISERROR`/`NOWAIT`-Provider, kontrolliertem Chunking, Zeilenumbruchbehandlung und optionaler Präfix-/Zeitstempelbildung. `THROW` bleibt echten Fehlern vorbehalten. |
| **Performance und Security** | Message-Ausgabe ist langsam und darf nicht zeilenweise im Hot Path verwendet werden. Chunks dürfen Unicode-Zeichenpaare und Zeilen möglichst nicht unnötig zerlegen. Prozentzeichen müssen bei `RAISERROR` sicher als Daten behandelt werden. Debug darf diagnostische Werte, aber niemals aktiv ausgegebene Secrets enthalten. |
| **Plattformgrenzen** | Engine-Verhalten voraussichtlich gleich; tatsächliche Darstellung, Pufferung und Reihenfolge hängen zusätzlich vom Client beziehungsweise Treiber ab und sind getrennt zu testen. |
| **Dependencies** | USP- und Debug-Vertrag; mögliche Wiederverwendung durch `TC-2026-017` und spätere Module. |
| **Duplikatprüfung** | Vorhandener Debug-Vertrag verlangt Messages, enthält aber keine wiederverwendbare Langtext- oder NOWAIT-Funktion. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/language-elements/print-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer Provider, sofortige Ausgabe, Chunkgrenze, Zeilenbehandlung, Präfixe und Verhalten für NULL/Leertext besprechen. |

## TC-2026-017: Standardisierter Error Envelope

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-017` |
| **Titel** | Einheitliche Erfassung und Weitergabe von Fehlerkontext |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | `TRY...CATCH` und die `ERROR_*`-Funktionen liefern den technischen Fehlerkontext, aber keinen projektweiten stabilen Envelope für Korrelation, Work-Item, Transaktionszustand, Retry-Klassifikation und optionale Console-/Logging-Ausgabe. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein bekannt |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Fehler können einheitlich erfasst, protokolliert, über Worker-Grenzen transportiert und dennoch mit erkennbarer Originalursache weitergegeben werden. |
| **Mögliche Technologie** | T-SQL-Infrastruktur innerhalb eines `CATCH`: `ERROR_NUMBER`, `ERROR_SEVERITY`, `ERROR_STATE`, `ERROR_PROCEDURE`, `ERROR_LINE`, `ERROR_MESSAGE`, `XACT_STATE` und `@@TRANCOUNT`; strukturierter OUTPUT-/Result-Vertrag oder JSON nur nach Besprechung. Das eigentliche Rethrow bleibt mit parameterlosem `THROW;` an der aufrufenden CATCH-Grenze. |
| **Performance und Security** | Originalfehler darf nicht von Logging- oder Cleanup-Fehlern überschrieben werden. Bei `XACT_STATE() = -1` sind nur Reads und vollständiger Rollback zulässig; reguläres Tabellenlogging in derselben Transaktion ist dann unmöglich. Fehlermeldungen können schutzwürdige Runtime-Werte enthalten und dürfen nicht ungeprüft persistiert werden. Retry-Klassifikation allein nach Fehlernummer ist nicht immer ausreichend. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz im T-SQL-Kern; Logger-Provider getrennt bewerten. |
| **Dependencies** | Optional `TC-2026-014`, `TC-2026-016` und `TC-2026-019`. |
| **Duplikatprüfung** | `USP_CONTRACT.md` und `TSQL_ENGINEERING.md` definieren Grundregeln, aber keine wiederverwendbare Error-Envelope-Capability. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/xact-state-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/set-xact-abort-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer gewünschte Felder, Rückgabeform, Klassifikation, Logger-/Console-Kopplung und verbindliche Rethrow-Semantik besprechen. |

## TC-2026-018: Kontrollierter Abbruch einer Ausführungsgruppe

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-018` |
| **Titel** | Laufende Worker bei Fehler, Timeout oder Benutzerabbruch gemeinsam stoppen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | SQL Server kennt `KILL` für einzelne Sessions und providerspezifische Stop-Mechanismen, aber keinen sicheren allgemeinen Gruppenabbruch für zusammengehörige Work-Items. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein bekannt |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Bei einem fehlgeschlagenen Teiljob können noch nicht gestartete Arbeiten gesperrt, aktive Worker kooperativ beendet und nur im notwendigen Eskalationsfall gezielt terminiert werden. |
| **Mögliche Technologie** | Zweistufiges Modell: Cancellation-Status je ExecutionId, den Worker an definierten Grenzen prüfen; providerspezifisches Stoppen noch nicht gestarteter beziehungsweise Agent-Arbeit; optional privilegierter `KILL`-Fallback für eindeutig verifizierte Toolbelt-Sessions. |
| **Performance und Security** | `KILL` benötigt `ALTER ANY CONNECTION`, kann die eigene Session nicht beenden und löst gegebenenfalls einen langen Rollback aus. Session IDs werden wiederverwendet; vor einem Kill müssen ExecutionId, SessionId und unveränderliche Verbindungsmerkmale erneut geprüft werden. `ALTER QUEUE ... STATUS = OFF` stoppt bereits aktive Activation-Procedures nicht. Ein globales „alle Prozesse abbrechen“ außerhalb der eigenen Ausführungsgruppe ist ausdrücklich kein zulässiger Vertrag. |
| **Plattformgrenzen** | T-SQL-Kill-Semantik gilt für SQL Server; Agent-, Service-Broker- und externe Provider benötigen eigene Stop-Adapter. Azure nicht automatisch unterstützt. |
| **Dependencies** | `TC-2026-015`, `TC-2026-019`, optional `TC-2026-021`; persistenter Status benötigt eine freigegebene Tabellen-Namenskonvention. |
| **Duplikatprüfung** | Keine bestehende Toolbelt-Cancellation-Capability; Analyze-Funktionen zum Beobachten von Sessions wären kein mutierender Gruppenabbruch. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/language-elements/kill-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-queue-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-stop-job-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer Fail-fast versus Weiterverarbeitung, kooperative Prüfpunkte, Grace Period, Kill-Berechtigung und Rollback-Warteverhalten besprechen. |

## TC-2026-019: Execution Correlation und Session-Kontext-Propagation

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-019` |
| **Titel** | Zusammengehörige Aufrufe und Worker sessionsicher korrelieren |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | `SESSION_CONTEXT` speichert Schlüssel nur für die aktuelle logische Verbindung. Eine neu geöffnete Session übernimmt weder diese Werte noch Temp-Tabellen, `SET`-Optionen oder die Caller-Transaktion automatisch. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein bekannt |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | ExecutionId, ParentExecutionId, WorkItemId und ausgewählte sichere Kontextwerte können über Logs, Worker, Console und Cancellation hinweg eindeutig verbunden werden. |
| **Mögliche Technologie** | T-SQL-Vertrag für GUID-basierte Correlation IDs und explizite Übergabe an jede neue Session; optional kontrolliertes Setzen über `sys.sp_set_session_context`. Keine automatische Übernahme beliebiger Caller-Kontextwerte. |
| **Performance und Security** | `SESSION_CONTEXT` erlaubt höchstens 8.000 Bytes je Wert und insgesamt 1 MB je Session. Kontext darf keine Secrets oder ungeprüften personenbezogenen Werte transportieren. Read-only-Werte können innerhalb einer logischen Verbindung geschützt werden, müssen in einer neuen Session aber erneut gesetzt und autorisiert werden. Connection Pooling und MARS sind gesondert zu testen. |
| **Plattformgrenzen** | T-SQL-Kern voraussichtlich plattformgleich; Client- und Pooling-Verhalten ist providerabhängig. |
| **Dependencies** | Grundlage für `TC-2026-014`, `TC-2026-015`, `TC-2026-018` und `TC-2026-021`. |
| **Duplikatprüfung** | Keine bestehende projektweite Execution-Correlation-Capability gefunden. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/session-context-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/data-access/context-connection?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer minimale Felder, Ownership, Erzeugungsregeln, erlaubte Context Keys und Verhalten bei verschachtelten Aufrufen festlegen. |

## TC-2026-020: Retry-, Idempotenz- und Dead-letter-Vertrag

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-020` |
| **Titel** | Fehlgeschlagene asynchrone Arbeit kontrolliert wiederholen oder isolieren |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | Service Broker erkennt Poison Messages und deaktiviert eine Queue nach wiederholten Rollbacks, liefert aber keinen anwendungsneutralen Vertrag für Retry-Klassifikation, Backoff, Idempotency Key, maximale Versuche und Dead-letter-Verarbeitung. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Kein allgemeiner nativer Work-Retry-Vertrag dokumentiert. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Transiente Fehler können begrenzt wiederholt werden; permanente Fehler blockieren nicht unkontrolliert die gesamte Queue; doppelte fachliche Seiteneffekte werden vermieden. |
| **Mögliche Technologie** | T-SQL-Statusmodell mit Retry-Klassifikation, deterministischem Idempotency Key, Attempt-Zähler, NextAttemptAt und Dead-letter-Zustand; providerspezifische Queue-Anbindung. |
| **Performance und Security** | Wiederholungen dürfen keine Retry-Stürme erzeugen. Backoff benötigt Obergrenze und Jitter-Entscheidung. Payload und Error Envelope unterliegen Datenschutz- und Größenregeln. Idempotenz kann nicht generisch garantiert werden, wenn die fachliche Work Procedure keinen geeigneten Schlüsselvertrag besitzt. |
| **Plattformgrenzen** | Kernvertrag portabel; Zeitplanung und Dead-letter-Transport sind providerabhängig. |
| **Dependencies** | `TC-2026-015`, `TC-2026-017`, `TC-2026-019`; persistente Zustände benötigen eine freigegebene Tabellen-Namenskonvention. |
| **Duplikatprüfung** | Kein entsprechender Kandidat vorhanden; Service-Broker-Poison-Handling ist eine Engine-Schutzfunktion, kein vollständiger Toolbelt-Vertrag. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/database-engine/service-broker/handling-poison-messages?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/database-engine/service-broker/service-broker-application-outline?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/database-engine/service-broker/transactional-messaging?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer Retry-Klassen, Idempotenzpflicht, Backoff, maximale Versuche und manuellen Requeue-Vertrag besprechen. |

## TC-2026-021: Worker-Heartbeat, Lease und Orphan Recovery

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-021` |
| **Titel** | Hängende oder verlorene Worker erkennen und Arbeit kontrolliert übernehmen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core |
| **SQL-Server-Lücke** | Eine gestartete Session oder Activation-Procedure liefert keinen allgemeinen dauerhaften Business-Status, Heartbeat oder Lease-Vertrag. Sessionende, Agentabbruch und Infrastrukturfehler können sonst Work-Items ohne eindeutigen Besitzer hinterlassen. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein bekannt |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Ein Supervisor kann aktive, überfällige und verwaiste Arbeit unterscheiden, Status anzeigen und nur nach abgelaufener Lease eine kontrollierte Wiederaufnahme zulassen. |
| **Mögliche Technologie** | T-SQL-Lease mit ExecutionId, WorkItemId, WorkerId, SessionId, LeaseUntil, LastHeartbeatAt und monotoner Ownership-Version; Abgleich mit providerspezifischen aktiven Tasks nur als zusätzliche Evidenz. |
| **Performance und Security** | Heartbeats erzeugen zusätzliche Writes und Logvolumen; Intervall und Batch-Verhalten müssen begrenzt sein. SessionId allein ist wegen Wiederverwendung nicht hinreichend. Lease-Übernahme und fachliche Idempotenz müssen zusammenpassen. Reale Host-, Login- oder Programmnamen werden nicht als Repository-Testdaten gespeichert. |
| **Plattformgrenzen** | Statuskern voraussichtlich plattformgleich; aktive Task-Metadaten und Agent-/Broker-Provider getrennt prüfen. |
| **Dependencies** | `TC-2026-015`, `TC-2026-019`, `TC-2026-020`; persistente Zustände benötigen eine freigegebene Tabellen-Namenskonvention. |
| **Duplikatprüfung** | Keine entsprechende Toolbelt-Capability gefunden. Diagnose vorhandener Sessions würde in `SQL_Server_Analyze` gehören; Ownership und Recovery des eigenen Work-Frameworks bleiben Toolbelt-Scope. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/database-engine/service-broker/understanding-when-activation-occurs?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/language-elements/kill-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer Statusmodell, Heartbeat-Intervall, Lease-Dauer, Ownership-Wechsel und Recovery-Verhalten besprechen. |

## TC-2026-022: Sicherer Work-Type-Katalog statt beliebigem SQL-Text

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-022` |
| **Titel** | Validierte benannte Arbeitspakete für parallele oder asynchrone Ausführung |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core / Security |
| **SQL-Server-Lücke** | SQL Server kann dynamisches SQL ausführen, stellt aber keinen anwendungsneutralen sicheren Vertrag bereit, der beliebige übergebene Statements automatisch auf Berechtigungen, Seiteneffekte, Transaktionsgrenzen und Idempotenz begrenzt. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein bekannt |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Ein Parallelisierungs-Framework kann ausschließlich registrierte Procedures beziehungsweise versionierte Work Types mit typisierten Parametern starten, anstatt eine allgemeine Remote-Code-Execution-Schnittstelle für SQL-Text anzubieten. |
| **Mögliche Technologie** | T-SQL-Metadatenvertrag für WorkType, Zielprocedure, Parameter-Schema, Mindestversion, Timeout-, Retry-, Idempotenz- und Berechtigungsprofil; Werte werden parametrisiert, technische Identifier validiert und mit `QUOTENAME` behandelt. Frei übergebener SQL-Text bleibt standardmäßig ausgeschlossen. |
| **Performance und Security** | Der Katalog ist selbst ein Security Boundary und benötigt kontrollierte Änderungsrechte, Dependency-Preflight und Versionierung. Modul-Signing oder gezielte `EXECUTE AS`-Alternativen sind vor Privilegienerweiterung zu vergleichen. Raw-SQL-Opt-in wäre eine separate Hochrisiko-Capability und keine versteckte Option. |
| **Plattformgrenzen** | T-SQL-Kern voraussichtlich plattformgleich; Signierung, Provider und zentrale Installation getrennt validieren. |
| **Dependencies** | `TC-2026-015`; persistenter Katalog benötigt eine freigegebene Tabellen-Namenskonvention und eigene Architekturentscheidung. |
| **Duplikatprüfung** | Kein vorhandener Work-Type- oder Command-Registry-Kandidat. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-executesql-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/signing-stored-procedures-with-a-certificate?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer festlegen, ob ausschließlich Procedures oder auch deklarative Statement-Typen zugelassen werden sollen und wer Work Types registrieren darf. |

## TC-2026-023: Abfragbarer Capability- und Versionskatalog

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-023` |
| **Titel** | Installierte Toolbelt-Module und Capabilities zur Laufzeit eindeutig abfragen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core / Metadata |
| **SQL-Server-Lücke** | SQL Server stellt Objektmetadaten, Extended Properties und Produktversionen bereit, kennt aber keinen Toolbelt-spezifischen Vertrag, der installierte Module, öffentliche Capabilities, Objektversionen, Provider, Supportgrenzen und Installationsvollständigkeit gemeinsam beschreibt. Repository-Manifeste beantworten diese Fragen nicht automatisch für eine konkrete Zieldatenbank. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine Toolbelt-spezifische native Funktion möglich. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Benutzer, Installer, Tests und abhängige Module können feststellen, welche Capability in welcher Version tatsächlich installiert ist, ohne Objektlisten oder Dateistände heuristisch zu interpretieren. |
| **Mögliche Technologie** | Deterministische Extended Properties plus View/TVF über Catalog Views; alternativ kontrollierter persistenter Modulkatalog. `module.yaml` bleibt Build-/Repository-Quelle, muss aber eine eindeutige Projektion in die Runtime-Metadaten erhalten. SDU Tools dient als öffentliches Produktmuster für abfragbare Tool- und Versionsinformation, nicht als Codequelle. |
| **Performance und Security** | Katalogabfragen müssen rein lesend, günstig und ohne Sichtbarkeit von Secrets oder internen Deployment-Pfaden sein. Drift darf nicht als gesunder Installationsstatus erscheinen. Ein persistenter Katalog benötigt Ownership, Upgrade, Rollback, Reparatur und eine zuvor freigegebene Tabellen-Namenskonvention. |
| **Plattformgrenzen** | T-SQL-Metadatenkern soll unter Windows und Linux gleich sein; zentrale und lokale Installation sowie eingeschränkte Metadatensicht sind getrennt zu testen. |
| **Dependencies** | Modul-/Dependency-Modell, Lifecycle-Vertrag und mindestens ein implementiertes Referenzmodul; persistente Variante benötigt eine Tabellen-Namensentscheidung. |
| **Duplikatprüfung** | Toolbelt-Kandidaten, Repository-Map, Modulmodell und ResultTable-Design geprüft. Manifeste dokumentieren den Sollstand, stellen aber noch keinen Runtime-Capability-Katalog bereit. |
| **Status** | `researched` |
| **Primärquellen** | [SQL_SERVER_TOOLBELT_LANDSCAPE.md](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://sqldownunder.com/sdutools/<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/extended-properties-catalog-views-sys-extended-properties?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer die erforderlichen Abfragefälle und Drift-Semantik besprechen; danach Extended-Property-Projektion und persistente Registry als Alternativen entwerfen. |

## TC-2026-024: URI-Percent-Encoding und -Decoding

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-024` |
| **Titel** | RFC-3986-konformes Percent-Encoding und -Decoding für URI-Komponenten |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | String / Conversion |
| **SQL-Server-Lücke** | SQL Server dokumentiert `STRING_ESCAPE` nur für JSON und bietet in SQL Server 2019, 2022 und 2025 keine allgemeine T-SQL-Funktion für das Percent-Encoding oder -Decoding einer URI-Komponente nach RFC 3986. Projektspezifische Ketten aus `REPLACE` behandeln Unicode, reservierte Zeichen und bereits kodierte Sequenzen häufig uneinheitlich. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine allgemeine dokumentierte URI-Percent-Encoding-Funktion; vor Umsetzung erneut prüfen. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Werte für Pfadsegmente, Query-Komponenten und Integrationsschnittstellen können deterministisch als UTF-8-Octets kodiert und sicher dekodiert werden, ohne dass jedes Modul eigene, inkompatible Ersetzungsketten pflegt. |
| **Mögliche Technologie** | T-SQL-Provider mit expliziter UTF-8-Konvertierung und byteweiser Verarbeitung; `SAFE` SQL CLR nur nach messbarem Performance- oder Korrektheitsvorteil. Encoding einer URI-Komponente und Decoding in Unicode sind getrennte öffentliche Verträge. `application/x-www-form-urlencoded`, vollständiges URL-Parsing, IRI-Normalisierung und Domain-/Punycode-Verarbeitung gehören nicht stillschweigend zur ersten Capability. |
| **Performance und Security** | Vertrag für unreserved/reserved Characters, Groß-/Kleinschreibung hexadezimaler Triplets, `%20` gegenüber `+`, bereits kodierte Sequenzen, ungültige `%`-Triplets, UTF-8-Fehler, NUL, Surrogate und maximale Länge festlegen. Decoding darf keine automatische zweite Decoding-Runde auslösen; sonst können Delimiter- oder Validierungsregeln umgangen werden. Mengen- und LOB-Performance sind zu benchmarken. |
| **Plattformgrenzen** | UTF-8-/T-SQL-Kern soll unter Windows und Linux identisch sein; Collation- und Compatibility-Level-Anforderungen sind explizit auszuweisen. CLR-Provider separat validieren. |
| **Dependencies** | Keine harte Dependency; möglicher gemeinsamer UTF-8-/Binary-Konvertierungskern erst nach Abgleich mit `TC-2026-012`. |
| **Duplikatprüfung** | Alle Toolbelt-Kandidaten geprüft. `TC-2026-012` behandelt Base64/Base64URL, nicht URI-Percent-Encoding; `TC-2026-009` behandelt JSON-Escaping. |
| **Status** | `researched` |
| **Primärquellen** | [SQL_SERVER_TOOLBELT_LANDSCAPE.md](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/string-escape-transact-sql?view=sql-server-ver17<br>https://datatracker.ietf.org/doc/html/rfc3986 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer zunächst URI-Komponente versus Form-Encoding und Encode-/Decode-Fehlersemantik festlegen; anschließend T-SQL- und CLR-Provider anhand von RFC-, Unicode-, Double-decoding- und LOB-Testvektoren vergleichen. |

## TC-2026-025: Kontrollierte PowerShell-Host-Automation

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-025` |
| **Titel** | Freigegebene PowerShell-Arbeit auf dem Host ausführen und strukturiertes Ergebnis übernehmen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | External Automation / Provider |
| **SQL-Server-Lücke** | SQL Server besitzt keinen sicheren allgemeinen T-SQL-Vertrag, der eine freigegebene PowerShell-Operation auf dem Host ausführt und deren typisiertes Ergebnis synchron oder asynchron zurückliefert. SQL Server Agent kann PowerShell- beziehungsweise CmdExec-Jobsteps ausführen, ist aber kein allgemeiner Resultset-RPC. `xp_cmdshell` ist für neue Entwicklung laut Microsoft nicht empfohlen und soll grundsätzlich deaktiviert bleiben. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine allgemeine native PowerShell-RPC-Funktion dokumentiert. |
| **Use-Case-Typ** | Realistisch, aber hoch privilegiert |
| **Nutzen** | Eng definierte Host-Aufgaben können über einen kontrollierten Provider ausgeführt werden, ohne dass jede Datenbank eigene Shell-Aufrufe, Credential- oder Ergebnisparser implementiert. |
| **Mögliche Technologie** | Hauptoption ist ein externer Worker mit allowlisted Work Types und typisierten Parametern. SQL Server Agent kann für grobe, vorab angelegte Windows-PowerShell-Jobs ein optionaler Provider sein. Jobname, Skript und Parameter stammen aus einem administrativ gepflegten Katalog; beliebiger PowerShell- oder CmdExec-Text ist kein zulässiger öffentlicher Vertrag. `xp_cmdshell` wird nicht als regulärer Provider vorgesehen. |
| **Performance und Security** | Host-Code-Ausführung ist eine Remote-Code-Execution-Grenze. Erforderlich sind Least Privilege, getrennte Service-/Proxy-Identität, Allowlist, Parameter-Schema, Timeout, Output-Limit, Exitcode, Secret-Redaction, Audit, Cancellation und Schutz vor Command Injection. Viele parallele PowerShell-Jobsteps verbrauchen eigene Prozesse und Speicher. Ergebnisse dürfen keine realen Infrastruktur- oder Secret-Werte als Repository-Evidenz erzeugen. |
| **Plattformgrenzen** | Die dokumentierte SQL-Agent-PowerShell-Integration ist Windows-bezogen. PowerShell 7, Linux, Agent-Verfügbarkeit und externe Worker sind getrennte Provider mit eigener Installation und Evidenz. Azure-Produkte werden nicht automatisch unterstützt. |
| **Dependencies** | Sicherer Work-Type-Katalog `TC-2026-022`, Execution Correlation `TC-2026-019`, Error Envelope `TC-2026-017`; asynchrone Ausführung gegebenenfalls `TC-2026-015`, `TC-2026-018`, `TC-2026-020` und `TC-2026-021`. |
| **Duplikatprüfung** | `TC-2026-015` beschreibt allgemeine Work-Queue-/Parallelisierung, aber keinen PowerShell-spezifischen Provider- und Ergebnisvertrag. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/powershell/sql-server/run-windows-powershell-steps-in-sql-server-agent?view=sqlserver-ps<br>https://learn.microsoft.com/en-us/ssms/agent/create-a-powershell-script-job-step<br>https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/xp-cmdshell-server-configuration-option?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/xp-cmdshell-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer konkrete erlaubte Host-Aufgaben, synchrones oder asynchrones Ergebnis, Provider, Identität, Output-Schema, Timeout und Abbruch besprechen; keine generische Script-Schnittstelle entwerfen. |

## TC-2026-026: Kontrollierte Python-Ausführung

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-026` |
| **Titel** | Freigegebene Python-Capability aus SQL Server aufrufen und tabellarisches Ergebnis übernehmen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | External Language / Provider |
| **SQL-Server-Lücke** | `sp_execute_external_script` kann Python über Machine Learning Services ausführen, definiert aber noch keinen Toolbelt-Vertrag für freigegebene Scripts, Paketversionen, Parameter, Resultsets, Timeouts, Fehler und Providerparität. Allgemeine Python-Host-Automation ist außerdem nicht dasselbe wie In-database-Datenverarbeitung. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | `sp_execute_external_script` ist bereits vorhanden; die Lücke ist ein kontrollierter Capability- und Providervertrag. |
| **Use-Case-Typ** | Realistisch, aber installations- und securityabhängig |
| **Nutzen** | Geeignete datenorientierte Python-Funktionen können nahe an relationalen Daten genutzt werden; alternative externe Worker können Host- oder Netzwerkaufgaben übernehmen, ohne Providerdetails an jeden Aufrufer zu leaken. |
| **Mögliche Technologie** | Provider A verwendet Machine Learning Services und `sp_execute_external_script` für datenorientierte, versionierte und allowlisted Python-Capabilities. Provider B ist ein externer Worker für Host-, Datei- oder Netzwerkaufgaben. Rohes Python aus einem Procedure-Parameter, dynamische Paketinstallation und ungeprüfte Modulimporte sind kein sicherer Default. |
| **Performance und Security** | Runtime- und Paketversionen sind Teil des Vertrags. Zu prüfen sind Launchpad-/Worker-Isolation, externe Datenzugriffe, Paket-Supply-Chain, Ressourcenlimits, Serialisierung, LOBs, Null-/Typabbildung, stdout/stderr, Timeout und reproduzierbare Umgebungen. SQL Server 2022 und neuer installieren Python/R-Runtimes nicht mehr automatisch mit Setup. |
| **Plattformgrenzen** | Machine Learning Services und installierte Runtime-/Paketkombinationen werden je SQL-Version sowie Windows/Linux separat nachgewiesen. Externe Worker sind eigene Provider. Azure-Unterstützung wird nicht abgeleitet. |
| **Dependencies** | Providerfähiges Modulmodell, sicherer Work-Type-Katalog `TC-2026-022`, ResultTable-Infrastruktur `TC-2026-003`, Error Envelope `TC-2026-017` und optional Execution Correlation `TC-2026-019`. |
| **Duplikatprüfung** | Die Projektgrundregeln erlauben Python als begründete Technologie, enthalten aber noch keine Python-Capability oder einen Script-/Environment-Vertrag. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/machine-learning/sql-server-machine-learning-services?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-execute-external-script-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/machine-learning/install/sql-machine-learning-services-windows-install-sql-2022?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Zuerst reale datenorientierte Use Cases von Host-Automation trennen; danach Input-/Output-Vertrag, erlaubte Packages, Runtimeversionen, Ressourcenlimits und Providerparität besprechen. |

## TC-2026-027: Externe REST-/Web-Requests mit Versionsprovider

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-027` |
| **Titel** | Kontrollierte HTTPS-Requests aus Toolbelt-Modulen versionsübergreifend ausführen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Integration / Network |
| **SQL-Server-Lücke** | SQL Server 2025 besitzt `sys.sp_invoke_external_rest_endpoint`; die Funktion ist standardmäßig deaktiviert und gilt nicht für SQL Server 2019/2022. Ein stabiler Toolbelt-Vertrag für erlaubte Endpunkte, Methoden, Header, Payload, Antwort, Fehler, Timeout, Retry und Providerparität fehlt. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025; native Engine-Funktion nur 2025 |
| **Spätere native Funktion** | `sys.sp_invoke_external_rest_endpoint` in SQL Server 2025 |
| **Use-Case-Typ** | Realistisch, aber Netzwerk- und Datenabflussgrenze |
| **Nutzen** | Module können kontrollierte REST-/GraphQL-Integrationen verwenden, ohne eigene HTTP-Implementierungen oder ad-hoc Shell-Aufrufe zu erzeugen. Für SQL Server 2025 kann der native Provider genutzt werden; ältere Versionen können optional einen kompatiblen externen Provider erhalten. |
| **Mögliche Technologie** | Provider 2025: Wrapper um `sys.sp_invoke_external_rest_endpoint` mit Endpoint-Allowlist und typisiertem Vertrag. Provider 2019/2022: vorzugsweise externer Worker. SQL CLR mit `EXTERNAL_ACCESS` wäre ein Windows-spezifischer Hochprivileg-Provider und ist unter SQL Server Linux nicht unterstützt. Direkte OLE-Automation, `xp_cmdshell` und beliebige URLs sind keine regulären Provider. |
| **Performance und Security** | Hauptrisiken sind SSRF, Datenexfiltration, DNS-/Redirect-Umgehung, Credential-Leakage, unkontrollierte Header, große Payloads, lange Transaktionen, Rate Limits und Retry-Duplikate. Erforderlich sind HTTPS, Allowlist, Least Privilege, sichere Credentials, Request-/Response-Limits, Content-Type-Prüfung, Timeout, Retry-/Idempotenzvertrag, Redaction und Audit. Ein REST-Aufruf unter offenen Locks ist zu vermeiden. |
| **Plattformgrenzen** | Nativer Provider ist SQL Server 2025. Externer Worker wird je Windows/Linux und Betriebsmodell validiert. SQL-CLR-`EXTERNAL_ACCESS`/`UNSAFE` ist auf Linux nicht unterstützt. Azure-Verhalten und Outbound-Firewallregeln sind nicht automatisch auf SQL Server übertragbar. |
| **Dependencies** | URI-Encoding `TC-2026-024`, Error Envelope `TC-2026-017`, Execution Correlation `TC-2026-019`, Retry/Idempotenz `TC-2026-020`, Work-Type-Katalog `TC-2026-022`; Secrets- und Endpoint-Governance vor Implementierung. |
| **Duplikatprüfung** | `TC-2026-024` kodiert URI-Komponenten, führt aber keinen Request aus. PowerShell-/Python-Kandidaten sind alternative externe Provider, kein HTTP-Vertrag. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-invoke-external-rest-endpoint-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2025?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/common-language-runtime-clr-integration-programming-concepts?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Mit dem Benutzer reale Endpunkte und Methoden, Sync/Async, erlaubte Authentifizierung, Payload-/Resultvertrag, Endpoint-Allowlist und gewünschten 2019/2022-Provider festlegen. |

## TC-2026-028: KI-/Chat-Provider mit Daten- und Modellgrenzen

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-028` |
| **Titel** | Kontrollierte Embedding- oder generative KI-Capability aus SQL Server nutzen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | AI / Integration |
| **SQL-Server-Lücke** | SQL Server 2025 kann External Models für Embeddings registrieren und mit `AI_GENERATE_EMBEDDINGS` Vektoren erzeugen. Das ist kein allgemeiner Chat-, Prompt-, Tool-Calling- oder Conversation-Vertrag. SQL Server 2019/2022 besitzen diese native Modellabstraktion nicht. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025; native Embedding-Funktionen nur 2025 |
| **Spätere native Funktion** | SQL Server 2025: `CREATE EXTERNAL MODEL`, `AI_GENERATE_CHUNKS`, `AI_GENERATE_EMBEDDINGS`; generative Chat-Semantik bleibt providerabhängig. |
| **Use-Case-Typ** | Experimentell bis konkrete fachliche Use Cases und Governance feststehen |
| **Nutzen** | Embeddings, Klassifikation, Extraktion oder generative Antworten könnten über einen stabilen Modulvertrag genutzt werden, ohne Modell-, Endpoint- und Credentialdetails in Fach-SQL zu duplizieren. |
| **Mögliche Technologie** | Embedding-Modul 2025 über External Model und native AI-Funktionen. Generative Calls über den kontrollierten REST-Provider `TC-2026-027` oder einen externen Worker. Embeddings und Chat bleiben getrennte Capabilities; ein generisches `Prompt -> Text` ohne Schema, Modell- und Datenvertrag wird nicht vorweggenommen. |
| **Performance und Security** | Erforderlich sind Datenklassifikation, ausdrückliche Freigabe externer Übertragung, PII-/Secret-Filter, Prompt-Injection-Grenzen, Modell-/API-Version, Kosten- und Tokenlimits, Rate Limits, Timeout/Retry, Caching, Audit, Content Policy, Output-Validierung und Kennzeichnung nichtdeterministischer Ergebnisse. KI-Ausgabe ist kein vertrauenswürdiger SQL- oder DDL-Input. |
| **Plattformgrenzen** | Native External Models und Embeddings gelten für SQL Server 2025 und besitzen zusätzliche Voraussetzungen wie Endpointzugriff und gegebenenfalls Azure-Arc-Managed-Identity. 2019/2022 sowie generative Provider benötigen externe Integration und eigene Windows-/Linux-Evidenz. |
| **Dependencies** | REST-Provider `TC-2026-027`, Capability-Katalog `TC-2026-023`, URI-Encoding `TC-2026-024`, Error Envelope `TC-2026-017`, Correlation `TC-2026-019` sowie noch festzulegende Daten-, Modell-, Credential- und Kosten-Governance. |
| **Duplikatprüfung** | SQL Server 2025 Embeddings, allgemeine REST-Aufrufe und KI/Chat sind drei überlappende, aber nicht gleichwertige Verträge. Kein vorhandener Toolbelt-Kandidat beschreibt Modell- und Datengovernance. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/statements/create-external-model-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/ai-generate-embeddings-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2025?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-invoke-external-rest-endpoint-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Konkrete Use Cases zuerst in Embeddings, deterministische Extraktion/Klassifikation und generative Chat-Antworten trennen; danach Datenfreigabe, Modellprovider, Output-Schema, Kosten- und Fehlersicht besprechen. |

## TC-2026-029: Sicheres Identifier- und Multipart-Name-Toolkit

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-029` |
| **Herkunft** | `RI-2026-011` |
| **Titel** | Sicheres Identifier- und Multipart-Name-Toolkit |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Metadata / Security |
| **SQL-Server-Lücke** | SQL Server besitzt mit `QUOTENAME` und `PARSENAME` Einzelbausteine, aber keinen vollständigen wiederverwendbaren Vertrag zum sicheren Parsen, Validieren, Normalisieren und Quoten ein- bis vierteiliger SQL-Identifier. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine vollständige native Toolkit-Funktion bekannt. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Gemeinsame sichere Namensbasis für Metadaten-, DDL- und Dynamic-SQL-Utilities. |
| **Mögliche Technologie** | Portables T-SQL; Parser, Validator und Quoting-Funktionen mit binär eindeutiger Prüfung der Bestandteile. `QUOTENAME` darf als Quoting-Primitive dienen, ersetzt aber nicht den Gesamtvertrag. |
| **Performance und Security** | Ungeprüfter SQL-Text, Kommentare, Ausdrücke und mehr als vier Teile bleiben ausgeschlossen. Leere Teile, Klammer-Escaping, Whitespace, maximale Identifierlänge, Collation und `NULL` sind Contract- und Testfälle. Das Toolkit bestätigt Syntax, nicht automatisch Existenz oder Berechtigung eines Objekts. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Keine Modulabhängigkeit. Die empfohlenen Vertragsgrenzen wurden am 2026-07-30 besprochen und die Implementierung ausdrücklich freigegeben. |
| **Duplikatprüfung** | Research-Inbox und formale Toolbelt-Kandidaten geprüft; `RI-2026-013` behandelt die Erzeugung neuer Constraint-/Indexnamen und bleibt getrennt. |
| **Status** | `ready for development` |
| **Primärquellen** | [Research-Inbox `RI-2026-011`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/quotename-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/parsename-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Als `AP-2026-010` implementieren; das Moduldesign hält die bereits akzeptierten Signaturen, Fehler- und Resultsetverträge vor dem ersten Runtime-Objekt dauerhaft fest. |

## TC-2026-030: Semantic-Version Parser und Comparator

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-030` |
| **Herkunft** | `RI-2026-075` |
| **Titel** | Semantic-Version Parser und Comparator |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Validation / Core |
| **SQL-Server-Lücke** | SQL Server besitzt keinen nativen SemVer-2.0.0-Parser und keine standardkonforme Präzedenzlogik für Pre-release-Identifier. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine bekannt. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Strikte Validierung, Vergleich und Sortierung von Modul-, Capability- und Paketversionen. |
| **Mögliche Technologie** | Portables T-SQL mit gemeinsamem kanonischem Parserkern; Parse- und Compare-Oberflächen verwenden dieselbe Validierungs- und Präzedenzlogik. |
| **Performance und Security** | SemVer 2.0.0 wird strikt von beliebigen Produktversionsformaten getrennt. Numerische Pre-release-Identifier, führende Nullen, ASCII-Zeichenvorrat, beliebig lange numerische Komponenten, Build Metadata und ungültige Eingaben benötigen explizite Tests ohne verlustbehaftete Integer-Konvertierung. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Keine Modulabhängigkeit. Der Standardumfang einschließlich Pre-release und Build Metadata wurde am 2026-07-30 besprochen und die Implementierung ausdrücklich freigegeben. |
| **Duplikatprüfung** | Research-Inbox und formale Toolbelt-Kandidaten geprüft. |
| **Status** | `ready for development` |
| **Primärquellen** | [Research-Inbox `RI-2026-075`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://semver.org/spec/v2.0.0.html |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Als `AP-2026-012` implementieren; Parser-, Comparator-, Sortier- und Fehlermatrix aus dem akzeptierten SemVer-Vertrag ableiten. |

## TC-2026-031: Ganzzahlen in frei definierbaren Zahlensystemen

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-031` |
| **Herkunft** | `RI-2026-055` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Ganzzahlen in frei definierbaren Zahlensystemen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Conversion |
| **SQL-Server-Lücke** | SQL Server besitzt keinen allgemeinen Vertrag, der Ganzzahlen mit einem frei vorgegebenen Alphabet in ein Zahlensystem kodiert und wieder strikt dekodiert. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Keine allgemeine native Funktion bekannt. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Ein gemeinsamer Kern für Binär-, Oktal-, Hexadezimal-, Base36- und projektspezifische Integerdarstellungen. |
| **Mögliche Technologie** | Portables T-SQL mit gemeinsamem Encode-/Decode-Kern und explizitem Alphabetparameter. |
| **Performance und Security** | Alphabetlänge, binär eindeutige Zeichen, Vorzeichen, Null, Groß-/Kleinschreibung, ungültige Zeichen und `bigint`-Overflow sind Vertragsbestandteile. Keine stillschweigende Normalisierung des Alphabets. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Keine Modulabhängigkeit. Der Umfang mit frei definierbarem Alphabet, positiven und negativen Ganzzahlen sowie mindestens Base 2 bis Base 36 wurde am 2026-07-30 besprochen und die Implementierung ausdrücklich freigegeben. |
| **Duplikatprüfung** | Research-Inbox, persönlicher Brainstorm und formale Toolbelt-Kandidaten geprüft; Base64 kodiert Binärdaten und ist kein Duplikat. |
| **Status** | `ready for development` |
| **Primärquellen** | [Research-Inbox `RI-2026-055`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Persönlicher Brainstorm](./personal_Backlog_Bainstorm.md)<br>https://www.rfc-editor.org/info/rfc4648/ |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Als `AP-2026-013` implementieren; akzeptierten Alphabet-, Vorzeichen-, Fehler- und Overflow-Vertrag im Moduldesign und in der Contract-Testmatrix festhalten. |

## TC-2026-032: Erweiterter String-Split mit mehrzeichigen Separatoren, Escape und Quote

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-032` |
| **Herkunft** | Benutzerergänzung zu `TC-2026-001` vom 2026-07-30 |
| **Titel** | Erweiterter String-Split mit mehrzeichigen Separatoren, Escape und Quote |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | String |
| **SQL-Server-Lücke** | Weder `STRING_SPLIT` noch ein einfacher Literal-Split-Vertrag decken gleichzeitig mehrere Separatoren beliebiger Länge, frei wählbare Quote-Zeichen und Escape-Semantik ab. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Teilweise Regex-Split ab SQL Server 2025; Quote- und Escape-Vertrag bleibt eigenständig. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Kontrolliertes Tokenizing strukturierter Texte, deren Separatoren innerhalb gequoteter oder escapeter Bereiche nicht trennen dürfen. |
| **Mögliche Technologie** | Offen: T-SQL-Parser, SQL CLR oder versionsbezogener Providervergleich. |
| **Performance und Security** | Separatorpriorität bei Präfixüberschneidungen, Quote-/Escape-Zeichen beliebiger Länge, Verschachtelung, unvollständige Quotes, LOBs, Collation und Worst-case-Laufzeit müssen vor einer Freigabe definiert werden. Kein stilles Gleichsetzen mit CSV oder regulären Ausdrücken. |
| **Plattformgrenzen** | T-SQL portabel; CLR oder native Provider separat auf Windows und Linux prüfen. |
| **Dependencies** | Funktional getrennte Folgestufe zu `TC-2026-001`; darf Version 1 nicht nachträglich verbreitern. |
| **Duplikatprüfung** | `TC-2026-001` und `TC-2026-010` geprüft; eigener Literal-/Parser-Vertrag erforderlich. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Nach Version 1 Separatorrepräsentation für beliebig lange Separatorstrings, längste-Treffer-Regel, frei definierbare öffnende/schließende Quote-Zeichen oder -Strings, Escape-Modell, Fehlervertrag, maximale Eingabelänge und Providervergleich mit dem Benutzer besprechen. Keine Implementierungsfreigabe aus `TC-2026-001` ableiten. |
