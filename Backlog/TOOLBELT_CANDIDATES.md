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
| **Mögliche Technologie** | T-SQL; Inline TVF bevorzugt, sofern der Vertrag set-basiert und optimizer-sichtbar umsetzbar ist. Für SQL Server 2025 ist ein nativer Regex-Provider zu prüfen. |
| **Performance und Security** | Planung: Inline-T-SQL, native Provider und gegebenenfalls CLR benchmarken. Keine besonderen Berechtigungen erwartet. Collation-, Längen- und LOB-Verhalten sind ausdrücklich zu definieren. |
| **Plattformgrenzen** | Windows und Linux voraussichtlich gleich. Azure nicht geprüft. |
| **Dependencies** | Keine bekannte harte Dependency; mögliche Wiederverwendung eines späteren Regex-Moduls prüfen. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; TC-2026-010 ist breiter und ersetzt diesen Literalvertrag nicht automatisch. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/string-split-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/regexp-split-to-table-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Semantik für Separatorliste, leere Tokens, Ordinal, maximale Eingabelänge und Collation festlegen; danach Provider vergleichen. |

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
| **Mögliche Technologie** | T-SQL. Exakte Typ- und Scale-Erhaltung ist zu prüfen; gegebenenfalls typspezifische Funktionen statt eines irreführend allgemeinen Backports. |
| **Performance und Security** | Muss SARGability-Auswirkungen dokumentieren. `week` hängt nativ von `@@DATEFIRST` ab; `iso_week` nicht. Keine besonderen Berechtigungen. |
| **Plattformgrenzen** | Keine erwartete Windows-/Linux-Differenz. |
| **Dependencies** | Keine bekannt |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft; TC-2026-002 und TC-2026-005 besitzen andere fachliche Verträge. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/datetrunc-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Unterstützten Datepart- und Datentypumfang festlegen und gegen SQL Server 2022/2025 als Referenz testen. |

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
| **SQL-Server-Lücke** | `GENERATE_SERIES` ist erst ab SQL Server 2022 und grundsätzlich ab Compatibility Level 160 verfügbar. SQL Server 2019 benötigt Hilfstabellen, rekursive CTEs oder projektspezifische Generatoren. |
| **Betroffene Versionen** | SQL Server 2019; außerdem Datenbanken auf neueren Engines mit zu niedrigem Compatibility Level, sofern die native TVF nicht freigeschaltet ist. |
| **Spätere native Funktion** | Ja: `GENERATE_SERIES` ab SQL Server 2022. |
| **Use-Case-Typ** | Realistisch |
| **Nutzen** | Einheitlicher, dokumentierter Zahlenreihenvertrag für Kalender, Datenexpansion, Tests und Mengenoperationen. |
| **Mögliche Technologie** | T-SQL Inline TVFs für klar definierte numerische Typen oder ein performanter Streaming-Provider. Rekursive CTEs sind nur nach messbarer Eignung zu verwenden. |
| **Performance und Security** | Cardinality Estimation, sehr große Reihen, negative Schritte, Overflow und Row-Goal-Verhalten benchmarken. Harte oder konfigurierbare Schutzgrenze prüfen. |
| **Plattformgrenzen** | Windows und Linux sollen denselben Vertrag verwenden. |
| **Dependencies** | Keine bekannte harte Dependency; persistente Numbers-Tabelle würde erstmals eine Tabellen-Namenskonvention erfordern. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/generate-series-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Inline-T-SQL, persistente Numbers-Tabelle und Streaming-Ansatz mit identischer Testmatrix vergleichen; vor einer Tabelle Benutzerentscheidung zur Namenskonvention einholen. |

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
| **Mögliche Technologie** | Providervergleich: T-SQL/XML für Standard-Base64; kontrollierte T-SQL-Normalisierung für Base64URL; `SAFE` SQL CLR für große Werte nur bei messbarem Vorteil; nativer Provider ab SQL Server 2025. Ein Backport im Projektschema darf den nativen Namen nicht im Systemschema imitieren. |
| **Performance und Security** | Native Semantik für Standard-/URL-safe-Alphabet, Padding, Whitespace-Toleranz, ungültige Zeichen, Formatfehler, `NULL`, Rückgabetyp und Längengrenzen als Contract-Matrix erfassen. Große LOBs dürfen nicht unnötig mehrfach oder als XML materialisiert werden. Dekodierte Inhalte bleiben untrusted binary data; Debug darf Binärinhalte anzeigen, echte Secrets jedoch nicht aktiv ausgeben. |
| **Plattformgrenzen** | T-SQL portabel; CLR-Provider pro Plattform testen. |
| **Dependencies** | Optional CLR-Infrastruktur. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `researched` |
| **Primärquellen** | [SQL_SERVER_TOOLBELT_LANDSCAPE.md](../Documentation/Research/SQL_SERVER_TOOLBELT_LANDSCAPE.md)<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-encode-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-decode-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/relational-databases/xml/use-the-binary-base64-option?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Native SQL-Server-2025-Semantik als Testmatrix erfassen und T-SQL/XML-, CLR- und nativen Provider mit identischen Small-/LOB-, URL-safe- und Fehlervektoren vergleichen. |

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
