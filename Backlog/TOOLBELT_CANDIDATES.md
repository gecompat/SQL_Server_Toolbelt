# Toolbelt-Kandidaten

Kandidaten für wiederverwendbare Funktionen in `gecompat/SQL_Server_Toolbelt`. Ein Eintrag ist keine Implementierungszusage.

Vorlage: [CANDIDATE_TEMPLATE.md](./CANDIDATE_TEMPLATE.md)

Objekt-, Dependency- und Wellenplanung: [TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md](./TOOLBELT_CANDIDATE_IMPLEMENTATION_PLAN.md)

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Windows-Releasevalidierung ausführen. Version 1 bleibt auf mehrere einzelne Trennzeichen ohne Quote-/Escape-Semantik begrenzt; die breitere Ausbaustufe ist separat als `TC-2026-032` erfasst. |

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Windows-Evidenz sowie die noch offenen Kollisionsfälle gezielt ergänzen. |

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [USP_CONTRACT.md](../Documentation/Standards/USP_CONTRACT.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/object-id-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/create-table-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Windows-Validierung und eine vergleichbare plattformübergreifende Performance-Baseline gemäß manuellem Testplan gezielt nachholen; der natürliche Savepoint-Enginefehler ist auf SQL Server 2019, 2022 und 2025 Linux validiert. |

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
| **Mögliche Technologie** | Implementierte T-SQL-Inline-TVF-Familie für `date`, `datetime2(7)` und `datetimeoffset(7)`. Der `datetimeoffset(7)`-Kern wird relational wiederverwendet; keine Scalar UDF und keine duplizierte native Providerlogik. |
| **Performance und Security** | Kanonische Inline TVFs bleiben für `APPLY` sichtbar. `week` folgt `@@DATEFIRST`, `iso_week` nicht. Parametrisierte Vertragsfehler werden über stabile Validation Codes ausgewiesen; echte Engine-Overflows bleiben unverändert. Keine besonderen Berechtigungen. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Keine Modulabhängigkeit. Der typgetrennte W2a-Vertrag wurde am 2026-07-30 ausdrücklich freigegeben. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; TC-2026-002 und TC-2026-005 besitzen andere fachliche Verträge. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [Auswahlvorbereitung für das zweite Modul](../Documentation/Research/SECOND_MODULE_SELECTION.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/datetrunc-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/create-user-defined-functions-database-engine?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/user-defined-functions/scalar-udf-inlining?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Windows-Releasevalidierung ausführen. |

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
| **Mögliche Technologie** | Implementierte öffentliche T-SQL-Inline-TVF-Familie für `date`, `datetime2(7)` und `datetimeoffset(7)` mit `DATEADD`/`DATEDIFF_BIG`, typgleichem Origin und SQL-Server-2019-kompatibler Zerlegung großer Zeitabstände. `datetime2` und `datetimeoffset` verwenden einen internen einzeiligen MSTVF-Core als Optimizer-Grenze. |
| **Performance und Security** | Negative Abstände werden mathematisch zum früheren Bucket abgerundet. Overflow, Origin-Zeitanteil, Monatsende und Datentypgrenzen sind Teil der Contract-Matrix. Der interne Core verhindert nachgewiesenen Enginefehler `8632`; Ausdrucksverwendung in Prädikaten und die MSTVF-Grenze können SARGability beziehungsweise Schätzung beeinflussen. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Keine Modulabhängigkeit: Bucketing ist kein Truncation-Wrapper. Der W2a-Vertrag wurde am 2026-07-30 ausdrücklich freigegeben. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/date-bucket-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Windows-Releasevalidierung sowie gezielte Performance-Evidenz für die interne Optimizer-Grenze ausführen. |

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [GENERATE_SERIES_MODULE_DESIGN.md](../Documentation/Architecture/GENERATE_SERIES_MODULE_DESIGN.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/generate-series-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/create-function-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/queries/top-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Gezielte Windows-Releasevalidierung planen; die physischen Linux-Läufe 2019/2022/2025 sind erfolgreich. |

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
| **Mögliche Technologie** | Implementierte T-SQL-Inline-TVF-Familie für den vollständigen `bigint`-Bitraum. Vorzeichenlose Zwischenwerte verwenden `decimal(38,0)`; `BIT_COUNT` wertet exakt acht Bytes set-basiert aus. |
| **Performance und Security** | Logische Shifts, negative Shiftweiten, Vorzeichenbit, Offset `0` bis `63` und Overflow-/Discard-Semantik sind explizit dokumentiert. CLR ist für den Bigint-Slice nicht erforderlich. |
| **Plattformgrenzen** | T-SQL portabel; CLR-Provider pro Plattform ausweisen. |
| **Dependencies** | Keine Modulabhängigkeit. Der Bigint-Slice wurde am 2026-07-30 ausdrücklich freigegeben; `binary(n)`/`varbinary(n)` bleiben separat. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/bit-manipulation-functions-overview?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Windows-Releasevalidierung ausführen; Binary-Provider erst nach eigener Vertragsbesprechung und Benchmarkentscheidung. |

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/trim-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Weitere Collations und Windows-Evidenz gezielt ergänzen. |

## TC-2026-009: JSON-Konstruktion und Pfadprüfung für SQL Server 2019

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-009` |
| **Titel** | Kompatibilitätsfamilie für `JSON_OBJECT`, `JSON_ARRAY` und `JSON_PATH_EXISTS` |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | JSON |
| **SQL-Server-Lücke** | SQL Server 2019 besitzt `FOR JSON`, `ISJSON`, `JSON_VALUE`, `JSON_QUERY`, `JSON_MODIFY` und `OPENJSON`, aber nicht die mit SQL Server 2022 eingeführten Konstruktoren `JSON_OBJECT`/`JSON_ARRAY` und die Pfadprüfung `JSON_PATH_EXISTS`. |
| **Betroffene Versionen** | SQL Server 2019; 2022 und 2025 besitzen native Funktionen. |
| **Spätere native Funktion** | Ja: SQL Server 2022. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Pfadprüfung mit einem stabilen Vertrag für ältere Installationen; JSON-Konstruktion bleibt ein getrennter späterer Slice. |
| **Mögliche Technologie** | Slice A ist als zustandsbehaftete T-SQL-Multi-statement-TVF auf Basis von `ISJSON` und `OPENJSON` implementiert. Slice B für Konstruktoren bleibt zurückgestellt, weil T-SQL-UDFs keine variadische native Aufrufoberfläche besitzen. |
| **Performance und Security** | Pfadtiefe und Wildcard-Fan-out materialisieren Frontier-Zustände; Property-Vergleich ist BIN2. Ungültige Pfade werden vor `OPENJSON` validiert. Doppeltes Escaping, Schlüssel-Injection und LOB-Materialisierung bleiben Pflichtfragen eines späteren Konstruktor-Slices. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. Azure nicht automatisch unterstützt. |
| **Dependencies** | Der implementierte Path-Exists-Slice besitzt keine Modulabhängigkeit. Ein späterer Konstruktor-Slice benötigt einen eigenen Eingabe-, Typ- und Escaping-Vertrag. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; JSON-Aggregate werden separat in TC-2026-013 behandelt. |
| **Status** | `implemented` (Slice A); Runtime `partially validated`; Konstruktoren `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/sql-server/what-s-new-in-sql-server-2022?view=sql-server-ver16<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/json-object-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/json-path-exists-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Windows-Releasevalidierung für `toolbelt.json.path-exists` ausführen. Konstruktoren erst nach einer eigenen Aufrufoberflächenentscheidung besprechen. |

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
| **Mögliche Technologie** | R1a hat drei verbleibende Richtungen identifiziert: exakter externer/native RE2-Provider, enger eigener Toolbelt-Dialekt auf .NET Framework mit Parser/Transformationen/Timeout oder reine SQL-Server-2025-Fassade. Der eingebaute .NET-Regexkern ist kein RE2-Paritätsprovider; native RE2-Wrapper sind nicht portabel als `SAFE`-SQL-CLR. |
| **Performance und Security** | Pattern-Limits, ReDoS-Risiken, Timeout, Speicherverbrauch und LOB-Grenzen definieren. Native SQL-Server-2025-Regex folgt nicht der sprachlichen Collation-Semantik. Parallelitätsfähigkeit und Streaming für TVFs prüfen. |
| **Plattformgrenzen** | `SAFE`-fähigen CLR-Kern und Linux-Verhalten prüfen; Windows-only-Provider nur bei messbarem Vorteil. |
| **Dependencies** | Vor jeder Implementierung Provider-/Semantikentscheidung, CLR-Trust- und Portabilitätsregeln sowie ein eigener öffentlicher Vertrag; möglicher Nutzen für TC-2026-001 bleibt getrennt. R1a hat keine Drittanbieter-Dependency aufgenommen. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; TC-2026-001 ist ein engerer Split-Vertrag. |
| **Status** | `researched`; R1a-Semantik-/Provider-Spike abgeschlossen, kein Runtime-Provider ausgewählt oder freigegeben |
| **Primärquellen** | [R1a Research-Ergebnis](../Documentation/Research/REGEX_SEMANTICS_PROVIDER_SPIKE.md)<br>https://learn.microsoft.com/en-us/sql/relational-databases/regular-expressions/overview?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-like-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-instr-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-count-transact-sql?view=sql-server-ver17<br>https://github.com/google/re2 |
| **Prüfdatum** | 2026-08-30 |
| **Nächster Schritt** | Mit dem Benutzer zwischen exakter RE2-Parität, ausdrücklich engerem Toolbelt-Dialekt oder SQL-Server-2025-Fassade wählen. Danach den konkreten V1-Slice aus `LIKE`, `INSTR` und `COUNT` vollständig besprechen und ausdrücklich freigeben. |

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
| **Status** | `deferred`; SQL-Server-2025-Referenzfunktionen weiterhin Preview |
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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [SQL_SERVER_TOOLBELT_LANDSCAPE.md](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>[Auswahlvorbereitung für das zweite Modul](../Documentation/Research/SECOND_MODULE_SELECTION.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-encode-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-decode-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/xml/use-the-binary-base64-option?view=sql-server-ver17<br>https://www.rfc-editor.org/rfc/rfc4648 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Windows-Releasevalidierung gezielt ausführen. |

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
| **Dependencies** | Keine Abhängigkeit zum Path-Exists-Slice von `TC-2026-009`. Ein späterer Aggregatvertrag benötigt einen eigenen Escaping-/Typkern oder ausdrücklich freigegebenes SQL CLR. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; Konstruktoren und Pfadprüfung verbleiben in TC-2026-009. |
| **Status** | `deferred`; native SQL-Server-2025-Aggregate weiterhin Preview |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/json-arrayagg-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/json-objectagg-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Zurückgestellt, solange die nativen SQL-Server-2025-Aggregate Preview sind und kein Aggregat-/SQL-CLR-Providervertrag freigegeben wurde. Preview-Status vor einer erneuten Besprechung neu prüfen. |

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
| **Mögliche Technologie** | Implementiert als `toolbelt.core.event-log` über den synchronen Loopback-RPC-Provider aus `toolbelt.core.second-session` Version 1.1.0. `USP_WriteEvent` nutzt einen registrierten JSON-Work-Type und unterdrückt das lokale Infrastruktur-Resultset. Service Broker und SQL CLR External Access bleiben für Version 1 ausgeschlossen. |
| **Performance und Security** | Eine zweite Session besitzt eigene Transaktion, `SET`-Optionen und Security Context und sieht keine lokalen Temp-Tabellen. Loopback kann sich an Locks der Caller-Transaktion selbst blockieren. SQL CLR benötigt Reauthentifizierung beziehungsweise kontrollierte Credentials und einen Trust-Vertrag. Error-Log-Provider sind längen- und berechtigungsbeschränkt; `RAISERROR ... WITH LOG` schreibt höchstens 440 Bytes. Payloads benötigen strikte Datenschutz-, Größen- und Secret-Regeln. |
| **Plattformgrenzen** | T-SQL-Linked-Server-, SQL-CLR-, Error-Log- und externe Provider sind getrennt auf Windows/Linux, Edition, Providerverfügbarkeit und Betriebsfreigabe zu prüfen. Azure ist nicht automatisch unterstützt. |
| **Dependencies** | `toolbelt.core.second-session` 1.1.0, `toolbelt.core.work-type` 1.1.0 und `toolbelt.core.execution-context` 1.0.0. |
| **Duplikatprüfung** | Alle drei Backlog-Listen sowie vorhandene Architektur- und USP-Verträge geprüft; kein gleichwertiger Kandidat vorhanden. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://techcommunity.microsoft.com/blog/sqlserver/how-to-create-an-autonomous-transaction-in-sql-server-2008/383471<br>https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/data-access/context-connection?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/database-engine/service-broker/transactional-messaging?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/xp-logevent-transact-sql?view=sql-server-ver17<br>https://tsqlt.org/125/tsqlt-build-9-release-notes/<br>https://github.com/tSQLt-org/tSQLt/blob/4a921d0dacfb1d66b3db124c58158c80e5e910e6/tSQLtCLR/tSQLtCLR/CommandExecutor.cs |
| **Prüfdatum** | 2026-08-05 |
| **Nächster Schritt** | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; Blockierungs- und Berechtigungsprofile des administrierten Loopback-Providers betriebsbezogen prüfen. |

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
| **Status** | `implemented` für E1a; Lease/Recovery, Retry/Dead Letter/Idempotenz, Cancellation und Worker bleiben getrennt `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/database-engine/service-broker/typical-uses-of-service-broker?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/alter-queue-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/database-engine/service-broker/understanding-when-activation-occurs?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-start-job-transact-sql?view=sql-server-ver17<br>https://github.com/jobbish-sql/SQL-Server-Multi-Thread<br>https://github.com/olahallengren/sql-server-maintenance-solution/blob/main/Queue.sql |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | E1a stabil halten und nicht allein veröffentlichen. Als Nächstes E1b Lease/Orphan Recovery mit eigenem Zustands-, Zeit-, Ownership-, Recovery- und Migrationsvertrag besprechen; keine automatische Aktivierung. |

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
| **Mögliche Technologie** | Implementiert als `toolbelt_core.USP_WriteConsoleMessage`: `PRINT` mit 4.000-Codeunit-Chunks oder `RAISERROR(N'%s', 0, 1, ...) WITH NOWAIT` mit konservativen 2.000-Codeunit-Chunks. BIN2-basierte Grenzprüfung hält High-/Low-Surrogatpaare zusammen; Präfixe und Zeitstempel bleiben außerhalb von V1. |
| **Performance und Security** | Message-Ausgabe ist langsam und darf nicht zeilenweise im Hot Path verwendet werden. Chunks dürfen Unicode-Zeichenpaare und Zeilen möglichst nicht unnötig zerlegen. Prozentzeichen müssen bei `RAISERROR` sicher als Daten behandelt werden. Debug darf diagnostische Werte, aber niemals aktiv ausgegebene Secrets enthalten. |
| **Plattformgrenzen** | Engine-Verhalten voraussichtlich gleich; tatsächliche Darstellung, Pufferung und Reihenfolge hängen zusätzlich vom Client beziehungsweise Treiber ab und sind getrennt zu testen. |
| **Dependencies** | USP- und Debug-Vertrag; mögliche Wiederverwendung durch `TC-2026-017` und spätere Module. |
| **Duplikatprüfung** | Vorhandener Debug-Vertrag verlangt Messages, enthält aber keine wiederverwendbare Langtext- oder NOWAIT-Funktion. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/language-elements/print-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/language-elements/raiserror-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Physische 2019-/2022-, Windows- sowie weitere Client-/Treiber-Evidenz ergänzen; SQL Server 2025 Linux mit Compatibility Levels 150/160/170 ist erfolgreich. |

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
| **Mögliche Technologie** | Implementiert als `toolbelt.core.error-envelope` mit `toolbelt_core.USP_CaptureErrorEnvelope`; explizite ERROR_*-Parameter, kleine Klassifikation, direkte oder ResultTable-Ausgabe, kein persistentes Logging und kein Rethrow-Wrapper. |
| **Performance und Security** | Originalfehler darf nicht von Logging- oder Cleanup-Fehlern überschrieben werden. Bei `XACT_STATE() = -1` sind nur Reads und vollständiger Rollback zulässig; reguläres Tabellenlogging in derselben Transaktion ist dann unmöglich. Fehlermeldungen können schutzwürdige Runtime-Werte enthalten und dürfen nicht ungeprüft persistiert werden. Retry-Klassifikation allein nach Fehlernummer ist nicht immer ausreichend. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz im T-SQL-Kern; Logger-Provider getrennt bewerten. |
| **Dependencies** | Optional `TC-2026-014`, `TC-2026-016` und `TC-2026-019`. |
| **Duplikatprüfung** | `USP_CONTRACT.md` und `TSQL_ENGINEERING.md` definieren Grundregeln, aber keine wiederverwendbare Error-Envelope-Capability. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/language-elements/try-catch-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/language-elements/throw-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/xact-state-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/statements/set-xact-abort-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-08-01 |
| **Nächster Schritt** | Physische SQL-Server-2019-/2022- und Windows-Releasevalidierung; rollback-unabhängiges Logging erst nach Second-Session-Provider. |

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
| **Mögliche Technologie** | Implementiert als `toolbelt.core.execution-context` über namespacete `SESSION_CONTEXT`-Schlüssel, Begin/Set/End, inline `TVF_CurrentExecutionContext` und SVF-Komfortwrapper. |
| **Performance und Security** | `SESSION_CONTEXT` erlaubt höchstens 8.000 Bytes je Wert und insgesamt 1 MB je Session. Kontext darf keine Secrets oder ungeprüften personenbezogenen Werte transportieren. Read-only-Werte können innerhalb einer logischen Verbindung geschützt werden, müssen in einer neuen Session aber erneut gesetzt und autorisiert werden. Connection Pooling und MARS sind gesondert zu testen. |
| **Plattformgrenzen** | T-SQL-Kern voraussichtlich plattformgleich; Client- und Pooling-Verhalten ist providerabhängig. |
| **Dependencies** | Grundlage für `TC-2026-014`, `TC-2026-015`, `TC-2026-018` und `TC-2026-021`. |
| **Duplikatprüfung** | Keine bestehende projektweite Execution-Correlation-Capability gefunden. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-set-session-context-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/session-context-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/data-access/context-connection?view=sql-server-ver17 |
| **Prüfdatum** | 2026-08-01 |
| **Nächster Schritt** | Windows-Releasevalidierung; persistenter Execution-Status bleibt ein getrennter späterer Slice. |

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
| **Mögliche Technologie** | Implementiert als persistenter T-SQL-Katalog `toolbelt.core.work-type`. Version `1.1.0` ergänzt die kontrollierte Entfernung deaktivierter Work Types über `USP_RemoveWorkType`; Raw SQL bleibt ausgeschlossen. |
| **Performance und Security** | Der Katalog ist selbst ein Security Boundary und benötigt kontrollierte Änderungsrechte, Dependency-Preflight und Versionierung. Modul-Signing oder gezielte `EXECUTE AS`-Alternativen sind vor Privilegienerweiterung zu vergleichen. Raw-SQL-Opt-in wäre eine separate Hochrisiko-Capability und keine versteckte Option. |
| **Plattformgrenzen** | T-SQL-Kern voraussichtlich plattformgleich; Signierung, Provider und zentrale Installation getrennt validieren. |
| **Dependencies** | `toolbelt.core.result-table`; die persistente Tabellen-/Constraint-/Indexkonvention ist mit `DEC-2026-025` akzeptiert. `TC-2026-046` und `TC-2026-014` bauen darauf auf. |
| **Duplikatprüfung** | Kein vorhandener Work-Type- oder Command-Registry-Kandidat. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-executesql-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/signing-stored-procedures-with-a-certificate?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/security/permissions-database-engine?view=sql-server-ver17 |
| **Prüfdatum** | 2026-08-01 |
| **Nächster Schritt** | Windows-Releasevalidierung; abhängige Module verwenden für ihren Lifecycle Disable → Remove statt direkter Katalog-DML. |

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
| **Mögliche Technologie** | Implementiert als read-only `toolbelt_metadata.VW_ModuleCapabilities` über Database-level Extended Properties. V1 verwendet keine persistente Registry, keine Runtime-Projektion aus `module.yaml` und keine zusätzliche Filter-TVF. |
| **Performance und Security** | Katalogabfragen müssen rein lesend, günstig und ohne Sichtbarkeit von Secrets oder internen Deployment-Pfaden sein. Drift darf nicht als gesunder Installationsstatus erscheinen. Ein persistenter Katalog benötigt Ownership, Upgrade, Rollback, Reparatur und eine zuvor freigegebene Tabellen-Namenskonvention. |
| **Plattformgrenzen** | T-SQL-Metadatenkern soll unter Windows und Linux gleich sein; zentrale und lokale Installation sowie eingeschränkte Metadatensicht sind getrennt zu testen. |
| **Dependencies** | Modul-/Dependency- und Lifecycle-Vertrag; keine Runtime-Modulabhängigkeit und keine Tabellen-Namensentscheidung in V1. |
| **Duplikatprüfung** | Toolbelt-Kandidaten, Repository-Map, Modulmodell und ResultTable-Design geprüft. Manifeste dokumentieren den Sollstand, stellen aber noch keinen Runtime-Capability-Katalog bereit. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [SQL_SERVER_TOOLBELT_LANDSCAPE.md](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://sqldownunder.com/sdutools/<br>https://learn.microsoft.com/en-us/sql/relational-databases/system-catalog-views/extended-properties-catalog-views-sys-extended-properties?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Physische 2019-/2022-, Windows- und eingeschränkte Metadata-Visibility prüfen; die W2c-Marker-, Drift- und Object-level-Matrix auf SQL Server 2025 Linux ist erfolgreich. |

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [SQL_SERVER_TOOLBELT_LANDSCAPE.md](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/string-escape-transact-sql?view=sql-server-ver17<br>https://datatracker.ietf.org/doc/html/rfc3986 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | LOB- und Performancegrenzen sowie Windows-Evidenz ergänzen; CLR erst bei messbarem Vorteil erneut prüfen. |

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [Research-Inbox `RI-2026-011`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/quotename-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/parsename-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Windows-Releasevalidierung gezielt ausführen. |

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [Research-Inbox `RI-2026-075`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://semver.org/spec/v2.0.0.html |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Windows-Releasevalidierung später gezielt ausführen. |

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
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [Research-Inbox `RI-2026-055`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Persönlicher Brainstorm](./personal_Backlog_Bainstorm.md)<br>https://www.rfc-editor.org/info/rfc4648/ |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Windows-Releasevalidierung später gezielt ausführen. |

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

## TC-2026-033: ZIP-Directory-Listing ohne Extraktion

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-033` |
| **Herkunft** | `RI-2026-112` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | ZIP-Directory-Listing ohne Extraktion |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Archive / Metadata |
| **SQL-Server-Lücke** | SQL Server besitzt keinen dokumentierten nativen Parser für das Central Directory eines ZIP-Archivs. `COMPRESS` und `DECOMPRESS` verwenden Gzip für Einzelwerte und stellen kein ZIP-Dateiverzeichnis bereit. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein; native Gzip-Wertkompression ist kein ZIP-Container. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Archive können vor einer Extraktion inventarisiert und auf Eintragsnamen, Größen, Kompressionsmethode und auffällige Pfade geprüft werden. |
| **Mögliche Technologie** | Freigegeben als Erweiterung von `toolbelt.archive.zip-memory` auf Version `1.2.0`: neue öffentliche `USP_ListZipEntriesFromBinary`, bestehende SAFE-Assembly und gemeinsam genutzter ZIP-Parserkern. Ein Dateipfad-Provider bleibt getrennt. |
| **Performance und Security** | Central Directory, ZIP64, doppelte Namen, Pfadnormalisierung, verschachtelte Archive, Verschlüsselung, maximale Eintragszahl und Größenangaben sind untrusted input. Listing darf keine Extraktion oder Pfadfreigabe implizieren. |
| **Plattformgrenzen** | Ein In-memory-Provider kann portabel sein; CLR- und Dateipfad-Provider benötigen eigene Windows-/Linux-Evidenz. |
| **Dependencies** | `toolbelt.archive.zip-memory` 1.1.0 und `toolbelt.core.result-table` 1.0.0; keine File-I/O-Dependency für den freigegebenen `varbinary(max)`-Vertrag. |
| **Duplikatprüfung** | Alle Toolbelt-Kandidaten und `RI-2026-112` geprüft. ZIP-Extraktion bleibt getrennt in `TC-2026-034`. |
| **Status** | `implemented`; Runtime `partially validated` |
| **Primärquellen** | [Research-Inbox `RI-2026-112`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Landschaftsrecherche](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT |
| **Prüfdatum** | 2026-08-09 |
| **Nächster Schritt** | Nach erfolgreicher SQL-Server-2019-/2022-/2025-Linux-Matrix für Version `1.2.0` Windows-Runtime, reale Archive, echte Extremgrößen und den vollständigen Upgradepfad aus einem realen 1.1.0-Stand ergänzen. |

## TC-2026-034: ZIP-Archive kontrolliert extrahieren und erzeugen

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-034` |
| **Herkunft** | `RI-2026-113` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | ZIP-Archive kontrolliert extrahieren und erzeugen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Archive / External Resource |
| **SQL-Server-Lücke** | SQL Server besitzt keinen nativen ZIP-Containervertrag zum Extrahieren einzelner Einträge in Binärwerte oder Dateien und zum Erzeugen vollständiger Archive. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein; `COMPRESS` und `DECOMPRESS` decken nur Gzip-komprimierte Werte ab. |
| **Use-Case-Typ** | Realistisch, aber security- und ressourcenintensiv |
| **Nutzen** | Einzelne Dateien, Streams oder vollständige Archive können über einen kontrollierten, auditierbaren Provider verarbeitet werden. |
| **Mögliche Technologie** | Implementiert als In-memory-SAFE-SQL-CLR-Provider `toolbelt.archive.zip-memory` Version `1.1.0` für genau einen benannten Entry, ZIP Methods 0 und 8 sowie eigene CRC32-Prüfung. Dateisystemextraktion und ZIP-Erzeugung bleiben getrennte spätere Slices. |
| **Performance und Security** | Zip Slip, Symlink-/Reparse-Point-Umgehung, Zip Bombs, hohe Kompressionsraten, CRC-Fehler, Verschlüsselung, Overwrite, Atomicity, Quotas und Cancellation benötigen harte Grenzen vor der ersten Extraktion. |
| **Plattformgrenzen** | Externe und CLR-Provider sind je Plattform zu validieren. Pfad- und ACL-Semantik ist betriebssystemabhängig. |
| **Dependencies** | `TC-2026-033` für Vorab-Listing; optional `TC-2026-037` für kontrollierte Datei-I/O. |
| **Duplikatprüfung** | `TC-2026-033` listet nur Metadaten. Gzip und weitere Algorithmen stehen getrennt in `TC-2026-035` und `TC-2026-036`. |
| **Status** | `implemented`; Runtime `partially validated`; ZIP-Erzeugung und vollständige Dateisystemextraktion offen |
| **Primärquellen** | [Research-Inbox `RI-2026-113`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Landschaftsrecherche](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT |
| **Prüfdatum** | 2026-08-01 |
| **Nächster Schritt** | Windows-SQL-Server-Runtime und echte Extremgrößen-/Ressourcengrenzen ergänzen. ZIP-Erzeugung nur nach eigener Vertrags- und Implementierungsfreigabe beginnen. |

## TC-2026-035: Gzip-Stream- und Datei-Adapter

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-035` |
| **Herkunft** | `RI-2026-114` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Gzip-Stream- und Datei-Adapter |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Compression / External Resource |
| **SQL-Server-Lücke** | `COMPRESS` und `DECOMPRESS` unterstützen seit SQL Server 2016 Gzip für Werte, definieren aber keinen vollständigen Toolbelt-Vertrag für große Streams, Dateien, Offsetverarbeitung, Metadaten und kontrollierte External-Resource-I/O. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Teilweise bereits vorhanden: `COMPRESS` und `DECOMPRESS` für Gzip-komprimierte SQL-Werte. |
| **Use-Case-Typ** | Realistisch, sofern ein nachweisbarer Stream- oder Datei-Use-Case über die nativen Funktionen hinaus besteht |
| **Nutzen** | Große oder externe Gzip-Daten könnten mit expliziten Limits und Providersemantik verarbeitet werden, ohne die native In-memory-Funktion fälschlich als Archivframework darzustellen. |
| **Mögliche Technologie** | Native Funktionen für passende In-memory-Werte bevorzugen. Einen zusätzlichen Streaming-/Dateiprovider nur nach Nutzen- und Benchmarknachweis vorsehen. |
| **Performance und Security** | LOB-Materialisierung, maximale dekomprimierte Größe, Kompressionsbomben, fehlerhafte Header/Trailer, Checksummen, Streaming, Timeout und Speicherlimits sind Vertragsbestandteile. |
| **Plattformgrenzen** | Native Wertfunktionen sind Engine-Funktionen. Jeder externe oder CLR-basierte Stream-/Dateiprovider benötigt eigene Windows-/Linux-Evidenz. |
| **Dependencies** | Optional `TC-2026-037` für kontrollierte Datei-I/O. |
| **Duplikatprüfung** | ZIP-Container stehen in `TC-2026-033`/`TC-2026-034`; weitere Algorithmen in `TC-2026-036`. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-114`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/compress-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/decompress-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Zuerst belegen, welcher reale Use Case von `COMPRESS`/`DECOMPRESS` nicht erfüllt wird; Kandidaten andernfalls als überflüssig ablehnen. |

## TC-2026-036: Optionale Provider für weitere Kompressionsverfahren

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-036` |
| **Herkunft** | `RI-2026-115` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Optionale Provider für weitere Kompressionsverfahren |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Compression / Provider |
| **SQL-Server-Lücke** | SQL Server stellt keinen allgemeinen Providervertrag für Deflate-, Brotli-, Zstandard-, bzip2-, 7z- oder weitere Kompressionsformate bereit. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein als allgemeiner Vertrag; Gzip-Wertkompression ist separat vorhanden. |
| **Use-Case-Typ** | Realistisch, aber nur pro nachgewiesenem Formatbedarf |
| **Nutzen** | Benötigte Formate können hinter einem versionierten Capability-Vertrag verarbeitet werden, ohne Algorithmen, Container und Dateisystemzugriff zu vermischen. |
| **Mögliche Technologie** | Pro Format ein expliziter optionaler Provider. Standardbibliotheken bevorzugen; Drittanbieterkomponenten nur nach Lizenz-, Supply-Chain-, Wartungs- und Plattformprüfung. |
| **Performance und Security** | Algorithmus-/Containerverwechslung, Bomben, unbounded Output, native Bibliotheken, CVEs, Lizenzierung, Versionierung, Checksummen und Streaming müssen je Provider getrennt bewertet werden. |
| **Plattformgrenzen** | Jeder Provider besitzt eine eigene Windows-/Linux- und Runtime-Matrix; keine Portabilitätsannahme aus einem anderen Algorithmus ableiten. |
| **Dependencies** | Providerfähiges Modulmodell; optional `TC-2026-037` für Dateizugriff. Keine pauschale Dependency auf ZIP. |
| **Duplikatprüfung** | Gzip steht in `TC-2026-035`; ZIP-Container stehen in `TC-2026-033`/`TC-2026-034`. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-115`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Landschaftsrecherche](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md) |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Konkrete benötigte Formate und Use Cases priorisieren; erst danach je Format Bibliothek, Lizenz, Provider, Limits und Testvektoren festlegen. |

## TC-2026-037: Kontrolliertes Lesen und Schreiben von Text- und Binärdateien

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-037` |
| **Herkunft** | `RI-2026-107` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Kontrolliertes Lesen und Schreiben von Text- und Binärdateien |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | External Resource / File |
| **SQL-Server-Lücke** | `BULK INSERT` und `OPENROWSET(BULK...)` unterstützen Imports, bilden aber keinen allgemeinen sicheren Read-/Write-Vertrag für Binary/Text, Encoding, BOM, Offset, Atomicity und Ergebnisstatus. Bulk-Export ist regelmäßig ein externer Prozess. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Teilweise für Import; kein vollständiger symmetrischer Datei-I/O-Vertrag. |
| **Use-Case-Typ** | Realistisch, aber hoch privilegiert |
| **Nutzen** | Freigegebene Dateipfade können mit typisierten Operationen, kontrolliertem Encoding und nachvollziehbaren Limits verarbeitet werden. |
| **Mögliche Technologie** | Zwei getrennte implementierte Provider: `toolbelt.file.content` als portabler Read-only-Slice über `OPENROWSET(BULK...)` und `toolbelt.filesystem.windows` als Windows-only EXTERNAL_ACCESS-SQL-CLR-Provider für begrenztes Lesen, Schreiben, Transcoding und Directory-Operationen. Ein externer plattformübergreifender Worker bleibt optional. |
| **Performance und Security** | Path Traversal, Symlinks/Reparse Points, ACLs, Service-Identität, TOCTOU, Overwrite, Atomic Replace, Encoding/BOM, maximale Größe, Partial Reads/Writes, Secrets und Audit sind Pflichtbestandteile. |
| **Plattformgrenzen** | Pfad-, ACL-, Encoding- und Dateisperrsemantik ist Windows-/Linux-spezifisch. `EXTERNAL_ACCESS`/`UNSAFE` ist unter SQL Server Linux nicht unterstützt. |
| **Dependencies** | Sicherer Work-Type-Katalog `TC-2026-022`, Error Envelope `TC-2026-017`, optional Execution Correlation `TC-2026-019`. |
| **Duplikatprüfung** | Directory Listing steht in `TC-2026-038`; Archive und Office-Formate erhalten eigene Verträge. |
| **Status** | `implemented`; beide vorhandenen Module Runtime `partially validated`; optionale portable Worker-Slices offen |
| **Primärquellen** | [Research-Inbox `RI-2026-107`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-bulk-data-by-using-bulk-insert-or-openrowset-bulk-sql-server?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-ver17 |
| **Prüfdatum** | 2026-08-01 |
| **Nächster Schritt** | Den manuellen Windows-Runtime-Test für `toolbelt.filesystem.windows` ausführen. Einen externen Worker nur bei einem nachgewiesenen plattformübergreifenden Use Case spezifizieren. |

## TC-2026-038: Kontrolliertes Directory Listing

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-038` |
| **Herkunft** | `RI-2026-108` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Kontrolliertes Directory Listing |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | External Resource / File |
| **SQL-Server-Lücke** | SQL Server besitzt keine dokumentierte allgemeine tabellarische API für ein portables Directory Listing mit klarer Pfad-, Symlink-, Rechte- und Fehlersemantik. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein als dokumentierter portabler Vertrag. |
| **Use-Case-Typ** | Realistisch, aber hoch privilegiert |
| **Nutzen** | Freigegebene Verzeichnisse können flach oder rekursiv mit definierten Metadaten und Limits inventarisiert werden. |
| **Mögliche Technologie** | Windows-Provider implementiert als `toolbelt_filesystem.USP_ListDirectory` mit Root-Alias, optionaler Rekursion, `@MaxDepth`, `@MaxEntries`, Reparse-Point-Sperre sowie Caller-/ServiceAccount-Identität. Ein portabler Provider bleibt getrennt offen. |
| **Performance und Security** | Path Traversal, Symlinks/Reparse Points, Mounts, versteckte Dateien, TOCTOU, Race Conditions, sehr große Verzeichnisse, Berechtigungsfehler, Sortierung und Resultset-Limits sind zu definieren. |
| **Plattformgrenzen** | Pfadsyntax, Case-Semantik, Zeitstempel, Dateiattribute und Linkverhalten unterscheiden sich zwischen Windows und Linux. |
| **Dependencies** | Sicherer Work-Type-Katalog `TC-2026-022`; gemeinsame Pfad-Sandbox mit `TC-2026-037` nur bei identischer Semantik. |
| **Duplikatprüfung** | `TC-2026-037` liest oder schreibt Dateiinhalte; dieser Kandidat listet ausschließlich Verzeichnismetadaten. |
| **Status** | `implemented`; Windows-Provider Runtime `partially validated`; portabler Provider offen |
| **Primärquellen** | [Research-Inbox `RI-2026-108`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Landschaftsrecherche](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://learn.microsoft.com/en-us/sql/relational-databases/clr-integration/security/clr-integration-code-access-security?view=sql-server-ver17 |
| **Prüfdatum** | 2026-08-01 |
| **Nächster Schritt** | Manuellen Windows-Runtime-Test einschließlich ACL-, Reparse-Point-, Paging-/Limit- und Rekursionsfällen ausführen; einen portablen Provider nur bei konkretem Bedarf planen. |

## TC-2026-039: Deterministischer Hash-Lookup für synthetische Ersatzwerte

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-039` |
| **Herkunft** | `RI-2026-125` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Deterministischer Hash-Lookup für synthetische Ersatzwerte |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Pseudonymization / Test Data |
| **SQL-Server-Lücke** | `HASHBYTES` erzeugt Hashwerte, bietet aber keinen versionierten Vertrag, der einen kanonisierten Schlüssel stabil einer freigegebenen synthetischen Lookup-Zeile zuordnet und referenzielle Konsistenz erhält. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein; `HASHBYTES` ist nur ein Primitive. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Gleiche Eingangsschlüssel können reproduzierbar denselben synthetischen Ersatzwert erhalten, ohne Originalwerte in der Lookup-Tabelle zu speichern. |
| **Mögliche Technologie** | Portables T-SQL ist möglich. Kanonisierung, Hashalgorithmus, Lookup-Reihenfolge, Mappingversion und Umgang mit Änderungen der Lookup-Menge müssen explizit sein. |
| **Performance und Security** | Unkeyed Hashes schützen kleine Eingangsräume nicht vor Dictionary-Angriffen. Modulo-Bias, Kollisionen, Lookup-Drift, Eindeutigkeit, NULL, Case-/Accent-Semantik und Re-Identifikationsrisiko sind zu behandeln. |
| **Plattformgrenzen** | T-SQL-Kern voraussichtlich plattformgleich; Collation- und Encodingvertrag darf nicht implizit von der Installation abhängen. |
| **Dependencies** | Freigegebene synthetische Lookup-Daten und ein versionierter Mappingvertrag; Secret-/Key-Governance, falls ein keyed Verfahren gewählt wird. |
| **Duplikatprüfung** | Von `TC-2026-040` bis `TC-2026-043` getrennt; dieser Kandidat wählt Lookup-Zeilen statt numerische, textuelle, zeitliche oder geografische Transformationen. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-125`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/hashbytes-transact-sql?view=sql-server-ver17<br>https://github.com/data-privacy-stack/presidio |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Kanonisierung, Hash-/Key-Vertrag, stabile Lookup-Ordnung, Lookup-Versionierung, Verteilungsanforderung und Umgang mit Lookup-Änderungen besprechen. |

## TC-2026-040: Deterministischer Random-Range-Provider

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-040` |
| **Herkunft** | `RI-2026-127` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Deterministischer Random-Range-Provider |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Pseudonymization / Test Data |
| **SQL-Server-Lücke** | `CRYPT_GEN_RANDOM` liefert Zufallsbytes, aber keinen reproduzierbaren, schlüsselabhängigen Range-Vertrag für Testdaten und Masking. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein als deterministischer Range-Vertrag. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Ein Schlüssel, Seed und Wertebereich können reproduzierbare synthetische Werte erzeugen, ohne pro Aufruf persistenten Zustand zu benötigen. |
| **Mögliche Technologie** | T-SQL-Kern auf kanonischem Hash möglich; kryptografisch sicherer PRF- oder externer Provider nur bei entsprechendem Schutzbedarf. |
| **Performance und Security** | Modulo-Bias, negative Bereiche, inklusive/exklusive Grenzen, Overflow, Verteilung, Kollisionen, Seed-/Key-Lifecycle und Vorhersagbarkeit sind Teil des Vertrags. Nicht als Anonymisierungsgarantie darstellen. |
| **Plattformgrenzen** | Portabler T-SQL-Kern möglich; Collation-/Encodingabhängigkeit der Schlüsselkanonisierung vermeiden. |
| **Dependencies** | Gemeinsame kanonische Hash-/Key-Semantik mit `TC-2026-039` nur nach Vertragsabgleich. |
| **Duplikatprüfung** | `TC-2026-039` wählt Lookup-Zeilen; `TC-2026-042` verschiebt Datumswerte; `TC-2026-043` arbeitet mit Geokoordinaten. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-127`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/crypt-gen-random-transact-sql?view=sql-server-ver17<br>https://faker.readthedocs.io/ |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Determinismus, Wertebereich, Verteilung, Seed-/Key-Modell, Datentypen, Fehler und kryptografischen Anspruch mit dem Benutzer festlegen. |

## TC-2026-041: Gesalzene deterministische Zeichentranslation mit Case-Regeln

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-041` |
| **Herkunft** | `RI-2026-126` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Gesalzene deterministische Zeichentranslation mit Case-Regeln |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Pseudonymization / String |
| **SQL-Server-Lücke** | SQL Server besitzt kein allgemeines versioniertes Verfahren, das Text deterministisch anhand eines Salt-/Key-Kontexts transformiert und dabei explizite Zeichensatz-, Längen-, Case- und Formatregeln einhält. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein; `TRANSLATE` definiert nur eine statische Zeichenabbildung. |
| **Use-Case-Typ** | Realistisch, aber datenschutzkritisch |
| **Nutzen** | Pseudonyme Textwerte können reproduzierbar und formatbewusst erzeugt werden, wenn referenzielle Konsistenz benötigt wird. |
| **Mögliche Technologie** | Offen: T-SQL-Transformation für begrenzte Alphabete oder geprüfter externer Provider. Salt, geheimer Key und Mappingversion dürfen nicht begrifflich vermischt werden. |
| **Performance und Security** | Ein Salt ist kein Secret. Reversible Substitution, kleine Alphabete, Häufigkeitsanalyse, Unicode-Grapheme, Case-/Accent-Semantik, Kollisionen, Formatlecks und Key-Rotation beeinflussen die Re-Identifizierbarkeit. |
| **Plattformgrenzen** | T-SQL kann portabel sein; Unicode-, Collation- und Normalisierungssemantik muss installationsunabhängig festgelegt werden. |
| **Dependencies** | Secret-/Key-Governance; optional gemeinsame deterministische Primitive mit `TC-2026-039`/`TC-2026-040`. |
| **Duplikatprüfung** | Kein Ersatz für Hash-Lookup, Date Shifting oder Geo-Jittering. Dynamic Data Masking verändert gespeicherte Werte nicht. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-126`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Landschaftsrecherche](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://learn.microsoft.com/en-us/sql/relational-databases/security/dynamic-data-masking?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Gewünschte Reversibilität, Alphabete, Unicode-/Case-Regeln, Formaterhalt, Key-/Salt-Modell, Rotation und Validierungsnachweis besprechen. |

## TC-2026-042: Deterministisches Date Shifting

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-042` |
| **Herkunft** | `RI-2026-128` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Deterministisches Date Shifting |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Pseudonymization / Datetime |
| **SQL-Server-Lücke** | SQL Server besitzt keinen wiederverwendbaren Vertrag, der Datums-/Zeitwerte pro Entität stabil innerhalb eines definierten Bereichs verschiebt und optional zeitliche Abstände erhält. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein; `DATEADD` ist nur ein Rechenprimitive. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Zeitbezogene Test- oder pseudonymisierte Daten können reproduzierbar verschoben werden, ohne die ursprüngliche Zeitachse vollständig offenzulegen. |
| **Mögliche Technologie** | T-SQL auf Basis eines deterministischen Offset-Providers; Mappinggranularität pro Entität, Gruppe oder Zeile explizit festlegen. |
| **Performance und Security** | Datentypgrenzen, Overflow, Schaltjahre, Monatsende, Zeitzonen/DST, Genauigkeit, NULL, Reihenfolge, Intervallerhalt und Re-Identifikation durch bekannte Ereignisse sind zu prüfen. |
| **Plattformgrenzen** | T-SQL-Kern plattformgleich; Zeitzonenprovider und Referenzdaten gegebenenfalls getrennt versionieren. |
| **Dependencies** | Deterministischer Range-Provider `TC-2026-040` oder ein gleichwertiges kanonisches Offset-Primitive. |
| **Duplikatprüfung** | Kein allgemeiner Datetime-Utility-Vertrag und kein Geo-Jittering; fachlicher Zweck ist Pseudonymisierung/Testdatenerzeugung. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-128`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/dateadd-transact-sql?view=sql-server-ver17<br>https://github.com/data-privacy-stack/presidio |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Offsetgranularität, Bereich, Determinismus, Intervallerhalt, Datentypen, Zeitzonen, Overflow und Datenschutzwirkung besprechen. |

## TC-2026-043: Geografisches Jittering für synthetische oder pseudonymisierte Daten

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-043` |
| **Herkunft** | `RI-2026-103` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Geografisches Jittering für synthetische oder pseudonymisierte Daten |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Pseudonymization / Spatial |
| **SQL-Server-Lücke** | SQL Server besitzt räumliche Typen und Methoden, aber keinen Datenschutzvertrag, der Koordinaten deterministisch oder zufällig innerhalb einer definierten Distanz verschiebt und die verbleibende Re-Identifizierbarkeit bewertet. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein als Pseudonymisierungsvertrag. |
| **Use-Case-Typ** | Realistisch, aber datenschutzkritisch |
| **Nutzen** | Synthetische oder freigegebene Geodaten können räumlich verfremdet werden, während eine definierte grobe Lagebeziehung erhalten bleibt. |
| **Mögliche Technologie** | T-SQL-Spatial oder externer Geoprovider; planar und geodätisch, deterministisch und zufällig sowie Clipping/zulässige Gebiete getrennt behandeln. |
| **Performance und Security** | Distanzverteilung, Pole/Datumsgrenze, SRID, ungültige Geometrien, Land-/Gebietsgrenzen, Dichte, bekannte Orte, wiederholte Beobachtungen und Kombination mit anderen Attributen beeinflussen Re-Identifikation. |
| **Plattformgrenzen** | SQL-Spatial-Kern voraussichtlich plattformgleich; externe Geodaten und Bibliotheken benötigen eigene Lizenz- und Plattformprüfung. |
| **Dependencies** | Optional `TC-2026-040` für deterministische Zufallsparameter; zulässige Gebiete oder Referenzdaten benötigen versionierten Lifecycle. |
| **Duplikatprüfung** | Kein allgemeines Spatial-Analysemodul; Fokus liegt ausschließlich auf synthetischer beziehungsweise pseudonymisierender Transformation. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-103`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/spatial-geography/spatial-types-geography?view=sql-server-ver17<br>https://github.com/data-privacy-stack/presidio |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Geometrietyp, SRID, Distanzmodell, Verteilung, Determinismus, zulässige Gebiete und akzeptierte Datenschutzwirkung mit dem Benutzer festlegen. |

## TC-2026-044: Framework zum kontrollierten Klonen von Tabellenobjekten

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-044` |
| **Herkunft** | `RI-2026-001`, `RI-2026-013` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Framework zum kontrollierten Klonen von Tabellenobjekten |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Metadata / DDL |
| **SQL-Server-Lücke** | `SELECT...INTO` kopiert Daten und ausgewählte Spalteneigenschaften, aber keine vollständige Tabelle mit Indizes, Check-/Foreign-Key-/Default-Constraints, Triggern und allen Spezialmerkmalen. Ein sicherer allgemeiner Clone-Vertrag fehlt. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein als vollständiger, versionierter Clone-Vertrag; SMO/DacFx bieten externe Scripting-Bausteine. |
| **Use-Case-Typ** | Realistisch, aber mit breiter DDL- und Dependency-Fläche |
| **Nutzen** | Tabellenstrukturen könnten reproduzierbar mit ausgewählten abhängigen Objekten, eindeutiger Namensbildung und optionaler Identity-/Datenbehandlung geklont werden. |
| **Mögliche Technologie** | Hauptoption: kontrollierte Skripterzeugung über SMO/DacFx oder einen eng begrenzten Metadatenkern. Version 1 sollte Script erzeugen und prüfen; automatische Ausführung ist eine getrennte Mutation. |
| **Performance und Security** | Abhängigkeitsgraph, Schema-/Objektberechtigungen, Namenskollisionen, maximale Identifierlänge, Datenkopie, Identity, FK-Reihenfolge, Trigger, Partitionierung, Temporal, Memory-optimized, Ledger, Verschlüsselung, Extended Properties, Rollback und Drift sind explizit zu begrenzen. |
| **Plattformgrenzen** | T-SQL-Metadaten sind weitgehend plattformgleich; SMO/DacFx-Provider und Spezialfeatures benötigen versions- und plattformspezifische Evidenz. |
| **Dependencies** | Identifier-Toolkit `TC-2026-029`; Namensgenerator aus `RI-2026-013`; DDL-/Deployment- und Recovery-Vertrag vor jeder automatischen Mutation. |
| **Duplikatprüfung** | Kein Duplikat zu ResultTable-Routing. `TC-2026-029` validiert Namen, klont aber keine Objekte. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-001`/`RI-2026-013`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Landschaftsrecherche](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/queries/select-into-clause-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Unterstützte Tabellentypen und abhängige Objekte, Script-only versus Execute, Daten/Identity, Namensregeln, Dependency-Reihenfolge und Recovery mit dem Benutzer festlegen. |

## TC-2026-045: XLSX-Dateien direkt lesen

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-045` |
| **Herkunft** | `RI-2026-116` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | XLSX-Dateien direkt lesen |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Office / Import |
| **SQL-Server-Lücke** | SQL Server besitzt keinen nativen XLSX-Parser. XLSX ist ein ZIP-basierter Open-XML-Container; korrektes Lesen erfordert mehr als das Entpacken einzelner XML-Dateien. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein. |
| **Use-Case-Typ** | Realistisch, aber format- und ressourcenintensiv |
| **Nutzen** | Freigegebene Workbooks könnten ohne installierte Excel-Anwendung in tabellarische, typisierte Resultsets überführt werden. |
| **Mögliche Technologie** | Bevorzugt externer Worker oder Open XML SDK. Ein direkter ZIP/XML-Provider ist nur sinnvoll, wenn Shared Strings, Styles, Zelltypen, Formeln, Datumsmodi und Streaming vollständig kontrolliert werden. |
| **Performance und Security** | ZIP-/XML-Bomben, externe Beziehungen, Formeln versus cached values, sehr große Shared-String-Tabellen, Styles, 1900/1904-Datumsmodus, Merge Cells, Hidden Sheets, Limits und untrusted input sind zu behandeln. Keine Makroausführung. |
| **Plattformgrenzen** | Open XML SDK ist grundsätzlich plattformfähig; Provider, Dateizugriff und Runtimeversion benötigen eigene Windows-/Linux-Evidenz. |
| **Dependencies** | Optional `TC-2026-033`/`TC-2026-034` für einen internen Containerprovider und `TC-2026-037` für pfadbasierte Eingaben; keine erzwungene Dependency bei SDK-/Worker-Provider. |
| **Duplikatprüfung** | CSV/Delimited Parsing und ein XLSX Writer sind getrennte Capabilities. Dieser Kandidat liest ausschließlich XLSX. |
| **Status** | `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-116`](./TOOLBELT_RESEARCH_INBOX.md)<br>https://learn.microsoft.com/en-us/openspecs/office_standards/ms-xlsx/2c5dee00-eff2-4b22-92b6-0738acd4475e<br>https://learn.microsoft.com/en-us/office/open-xml/open-xml-sdk |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Ersten Scope auf Sheets, Zelltypen und Resultsetform reduzieren; Formeln, Styles, Datumsmodi, Shared Strings, Streaming, Dateizugriff und Fehlerresultset besprechen. |

## TC-2026-046: Provider-Abstraktion für kontrollierte zweite SQL-Sessions

| Feld | Wert |
|---|---|
| **ID** | `TC-2026-046` |
| **Herkunft** | `RI-2026-139` und `Backlog/personal_Backlog_Bainstorm.md` |
| **Titel** | Provider-Abstraktion für kontrollierte zweite SQL-Sessions |
| **Ziel-Repository** | `SQL_Server_Toolbelt` |
| **Kategorie** | Core / Execution Provider |
| **SQL-Server-Lücke** | SQL Server besitzt keinen allgemeinen Toolbelt-Vertrag, der eine zweite Session über austauschbare Provider öffnet, typisierte Arbeit ausführt und Ergebnis, Fehler, Timeout und Abbruch einheitlich zurückliefert. |
| **Betroffene Versionen** | SQL Server 2019, 2022 und 2025 |
| **Spätere native Funktion** | Nein als einheitlicher Providervertrag. |
| **Use-Case-Typ** | Realistisch als Infrastruktur für Logging, Parallelisierung und Orchestrierung |
| **Nutzen** | SQL CLR, SQL Server Agent, Service Broker oder externe Runner könnten hinter einem Capability-Vertrag gewählt werden, ohne providerspezifische Details in jede Fachfunktion zu kopieren. |
| **Mögliche Technologie** | Providervergleich anhand konkreter Semantik. `tSQLt.NewConnection` ist Prior Art für eine synchrone zweite CLR-Verbindung; Agent, Broker und externe Runner besitzen andere Transaktions-, Haltbarkeits- und Ergebnisverträge. |
| **Performance und Security** | Security Context, Credentials, Ambient Transaction, Locks/Selbstblockierung, SET-Optionen, lokale Temp-Tabellen, Session Context, Resultset-Serialisierung, Timeout, Cancellation, Ressourcenlimits und Fehlerisolation sind providerabhängig. |
| **Plattformgrenzen** | CLR-, Agent-, Broker- und externe Provider werden getrennt nach Windows/Linux, Edition, Installation und Betriebsfreigabe ausgewiesen. |
| **Dependencies** | Execution Correlation `TC-2026-019`, Error Envelope `TC-2026-017`, Work-Type-Katalog `TC-2026-022`; fachliche Nutzer wie `TC-2026-014`/`TC-2026-015` bleiben getrennt. |
| **Duplikatprüfung** | `TC-2026-014` definiert rollback-unabhängiges Logging und `TC-2026-015` eine Work Queue. Dieser Kandidat beschreibt ausschließlich die austauschbare Session-Erzeugungs-/Ausführungsschicht. |
| **Status** | `implemented`; synchroner Second-Session-Slice Runtime `partially validated`; breitere Providerabstraktion `researched` |
| **Primärquellen** | [Research-Inbox `RI-2026-139`](./TOOLBELT_RESEARCH_INBOX.md)<br>[Landschaftsrecherche](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://tsqlt.org/125/tsqlt-build-9-release-notes/<br>https://github.com/tSQLt-org/tSQLt/blob/4a921d0dacfb1d66b3db124c58158c80e5e910e6/tSQLtCLR/tSQLtCLR/CommandExecutor.cs |
| **Prüfdatum** | 2026-07-30 |
| **Nächster Schritt** | Den implementierten synchronen Loopback-Vertrag physisch auf SQL Server 2019/2022 und Windows validieren. Weitere Agent-, Broker- oder Worker-Provider nur nach eigenem Bedarf, Vertrag und Freigabe planen. |
