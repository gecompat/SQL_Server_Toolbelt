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
| **Mögliche Technologie** | T-SQL/XML als dependency-freier Provider und `SAFE` SQL CLR als Performance-Provider vergleichen. |
| **Performance und Security** | Große Werte dürfen nicht unnötig mehrfach materialisiert werden. Exakte RFC-4648-, Padding-, Whitespace- und Fehlersemantik festlegen. Debug darf Binärinhalte anzeigen, echte Secrets jedoch nicht aktiv ausgeben. |
| **Plattformgrenzen** | T-SQL portabel; CLR-Provider pro Plattform testen. |
| **Dependencies** | Optional CLR-Infrastruktur. |
| **Duplikatprüfung** | Toolbelt-Backlogs geprüft. |
| **Status** | `researched` |
| **Primärquellen** | https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-encode-transact-sql?view=sql-server-ver17<br>https://learn.microsoft.com/en-us/sql/t-sql/functions/base64-decode-transact-sql?view=sql-server-ver17 |
| **Prüfdatum** | 2026-07-29 |
| **Nächster Schritt** | Native SQL-Server-2025-Semantik als Testoracle erfassen und XML-/CLR-Provider hinsichtlich CPU, Speicher und LOB-Verhalten benchmarken. |

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
