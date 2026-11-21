-- Interner SAFE-Parsertransport; fünf physisch nullable Unicode-/Statusspalten.
-- Vollständiger Preflight im CLR-Kern; ein isolierter Fachfehlersentinel, unerwartete Fehler original.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.TVF_InternalParseCsv
(@Text nvarchar(max),@Separator nvarchar(2),@HasHeader bit,@NullToken nvarchar(128),@MaxRows bigint,@MaxColumns int,@MaxCells bigint,@MaxInputBytes bigint)
RETURNS TABLE(RowKind nvarchar(6),RowOrdinal bigint,ColumnOrdinal int,[Value] nvarchar(max),ErrorCode int)
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-csv-tvf-internalparsecsv"
-- description: "Interner vollständiger CSV-Parser mit privatem Fünf-Feld-Statusprotokoll."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.file.csv-memory"
-- schema_name: "toolbelt_file"
-- object_name: "TVF_InternalParseCsv"
-- object_type: "CLR_TVF"
-- database_role: "toolbelt"
-- is_internal: true
-- parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@Separator", "sql_type": "nvarchar(2)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@HasHeader", "sql_type": "bit", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "0: alle Records DATA ab RowOrdinal 1. 1: erster Record HEADER mit RowOrdinal 0, folgende DATA ab 1. NULL ungültig. Header zählt zu MaxCells, nicht MaxRows. Auch mit 1 ergibt leerer Text keine Zellen. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@NullToken", "sql_type": "nvarchar(128)", "sql_default": null, "is_output": false, "argument_required": true, "business_required": false, "nullable": true, "description": "NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@MaxRows", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@MaxColumns", "sql_type": "int", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@MaxCells", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. Kein SQL-Default; Argument ausdrücklich übergeben."}, {"name": "@MaxInputBytes", "sql_type": "bigint", "sql_default": null, "is_output": false, "argument_required": true, "business_required": true, "nullable": false, "description": "Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung. Kein SQL-Default; Argument ausdrücklich übergeben."}]
-- source_paths: ["Modules/toolbelt.file.csv-memory/Source/TVF_InternalParseCsv.sql", "Modules/toolbelt.file.csv-memory/Clr/CsvEntryPoints.cs", "Modules/toolbelt.file.csv-memory/Clr/CsvKernel.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- public_entrypoints: ["toolbelt_file.USP_ParseCsv"]
-- ---
--
-- # TVF_InternalParseCsv
--
-- ## Zweck und Einsatzfälle
--
-- Interner vollständiger CSV-Parser mit privatem Fünf-Feld-Statusprotokoll. Internes Transportdetail, regulärer Einstieg toolbelt_file.USP_ParseCsv.
--
-- ## Voraussetzungen
--
-- Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | Vertrag |
-- |---|---|---|
-- | `@Text` | `nvarchar(max)` | Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord. Kein SQL-Default; Argument ausdrücklich übergeben. |
-- | `@Separator` | `nvarchar(2)` | Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim. Kein SQL-Default; Argument ausdrücklich übergeben. |
-- | `@HasHeader` | `bit` | 0: alle Records DATA ab RowOrdinal 1. 1: erster Record HEADER mit RowOrdinal 0, folgende DATA ab 1. NULL ungültig. Header zählt zu MaxCells, nicht MaxRows. Auch mit 1 ergibt leerer Text keine Zellen. Kein SQL-Default; Argument ausdrücklich übergeben. |
-- | `@NullToken` | `nvarchar(128)` | NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. Kein SQL-Default; Argument ausdrücklich übergeben. |
-- | `@MaxRows` | `bigint` | Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. Kein SQL-Default; Argument ausdrücklich übergeben. |
-- | `@MaxColumns` | `int` | Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. Kein SQL-Default; Argument ausdrücklich übergeben. |
-- | `@MaxCells` | `bigint` | Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. Kein SQL-Default; Argument ausdrücklich übergeben. |
-- | `@MaxInputBytes` | `bigint` | Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung. Kein SQL-Default; Argument ausdrücklich übergeben. |
--
-- ## Ergebnisse
--
-- Fünf physisch nullable Felder: RowKind nvarchar(6), RowOrdinal bigint, ColumnOrdinal int, Value nvarchar(max), ErrorCode int. Erfolg: ErrorCode=0 und vollständige HEADER-/DATA-Zellen mit nicht-NULL Kind/Ordinals, Value kann bei DATA NULL sein. Fachfehler: genau eine Sentinelzeile, sämtliche vier Nutzfelder NULL, ErrorCode=55300/55301/55302/55303. Leerer Text: keine Zeilen, auch bei HasHeader=1. HEADER hat RowOrdinal 0, DATA ab 1, Spalten ab 1. Kein vertragliches SQL-ORDER-BY; Caller ordnet ausdrücklich.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- SELECT * FROM toolbelt_file.TVF_InternalParseCsv(N'a,b',N',',CONVERT(bit,0),NULL,100000,1024,1000000,16777216);
-- -- Zwei DATA-Zellen, ErrorCode=0; intern, Anwendungen verwenden USP_ParseCsv.
-- ```
--
-- ## Rechte
--
-- Vorhandenes SELECT auf diesem internen CLR-TVF nur im ausdrücklich autorisierten Implementierungs-/Testscope. Öffentliche Anwendungen folgen dem Callerprofil von toolbelt_file.USP_ParseCsv. CLR-/Assemblytrustvoraussetzungen separat erfüllen; diese Funktion erteilt keine Rechte, prüft keine Serveridentität und greift nicht auf Daten-/Systemkataloge zu.
--
-- ## Ressourcenbedarf
--
-- Feste Obergrenzen: 100000 DATA-Records, 1024 Spalten, 1000000 Zellen einschließlich HEADER, 16777216 UTF-16-Bytes. Positive Aufrufbudgets dürfen diese Grenzen nur absenken. Das ist keine Heap-, Memory-Grant-, CPU-, Wallclock- oder Produktionskapazitätsgarantie. Inputlänge vor eigener char[]-Kopie; vollständiger Syntax-/Budgetscan vor IEnumerable-Rückgabe, danach zweiter Scan mit Zellallokation während Enumeration. Kein Streaming des Originalinputs; nur vollständige öffentliche Materialisierung verhindert technischen Fehler nach schon konsumierten Zeilen.
--
-- ## Nebenwirkungen
--
-- Deterministische speicherreine Berechnung aus expliziten Argumenten. Keine Datei-/Netzwerk-/Katalogoperation, Temp-Tabelle, Transaktion, Callerzustandsänderung oder persistente Mutation. Kein Hilfeschalter an dieser Funktion; vollständiger Skill in ausgelieferter DDL und künftig im gemeinsamen Skillkatalog.
--
-- ## Fehlerbehandlung
--
-- Nur eigener CsvFault wird vor Rückgabe in die eine Sentinelzeile übersetzt. Priorität: numerische Grenzargumente, Text/HasHeader, Dialekt, Inputlänge, vollständiger Scan. Unerwartete technische Exceptions bleiben erhalten, insbesondere während zweiter Enumeration. Leerer Text ergibt keine Zellen. Feste Doppelquote, darin verdoppelte Quotes; Quote nur am Feldanfang, nach Abschlussquote nur Separator, CRLF, LF oder EOF. LF und CRLF sind Recordgrenzen, isoliertes CR außerhalb Quotes ist ungültig. Quoted CR/LF bleiben Daten. Kein Trim; NUL und ungepaarte Surrogate in Zellwerten bleiben erhalten. Finaler Recordabschluss erzeugt keinen Zusatzrecord, Separator am EOF aber ein letztes leeres Feld. Alle Records haben dieselbe Breite. Nur unquoted DATA mit exakt gleichem NullToken wird SQL-NULL; HEADER und quoted Token bleiben Text.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Gesamtqualifikation. Historische Fach-/Caller-/Paketnachweise behalten ihre ursprüngliche Bindung. Keine Installations- oder Rechteattestation, keine unbegrenzte Ausgabe, keine Datenbereinigung oder allgemeine RFC-/Spreadsheet-/Dateiimportgarantie.
-- OBJECT_USAGE_SKILL:END
AS EXTERNAL NAME [tlblt_File_CsvMemory].[Toolbelt.Csv.CsvEntryPoints].[Parse];
GO
