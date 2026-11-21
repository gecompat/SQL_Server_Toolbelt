-- ============================================================================
-- Objekt: toolbelt_file.USP_ParseCsv; Typ: Stored Procedure
-- Zweck: CSV-Text vollständig prüfen und in HEADER-/DATA-Zellen decodieren.
-- Vertrag: CSV_MEMORY_CONTRACT.md; USP_CONTRACT 1.0
-- Parameter: @Text nvarchar(max)=NULL; @Separator nvarchar(2)=N','; @HasHeader bit=0; @NullToken nvarchar(128)=NULL; @MaxRows bigint=100000; @MaxColumns int=1024; @MaxCells bigint=1000000; @MaxInputBytes bigint=16777216; @ResultTable sysname=NULL; @KeepData bit=0; @Debug tinyint=0; @Hilfe bit=0
-- Resultset: RowKind varchar(6) NOT NULL; RowOrdinal bigint NOT NULL; ColumnOrdinal int NOT NULL; Value nvarchar(max) NULL
-- Dependencies: eigene SAFE-CLR-Bindungen; ResultTable >=1.0.0 same_database.
-- Rechte: EXECUTE, caller-lokale Temps; keine Rechtevergabe.
-- Versionen/Plattformen: SQL Server 2019+ CL150+, Windows/Linux; Qualifikation separat.
-- Fehler: 55300..55309; Originalenginefehler; eigene Transaktion oder Caller-Savepoint.
-- Performance: begrenzte private Snapshots, vollständige Charge vor Output; kein Heap-/Grantversprechen.
-- Grenzen: kein Datei-/Netzwerk-I/O, Casting oder Datenbereinigung.
-- ============================================================================
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_file.USP_ParseCsv
 @Text nvarchar(max)=NULL,
 @Separator nvarchar(2)=N',',
 @HasHeader bit=0,
 @NullToken nvarchar(128)=NULL,
 @MaxRows bigint=100000,
 @MaxColumns int=1024,
 @MaxCells bigint=1000000,
 @MaxInputBytes bigint=16777216,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
-- OBJECT_USAGE_SKILL:BEGIN
-- ---
-- name: "toolbelt-toolbelt-toolbelt-file-usp-parsecsv"
-- description: "Parst begrenzten Unicode-CSV-Text vollständig als rechteckige HEADER-/DATA-Zellen; keine Datei- oder Netzwerkquelle."
-- skill_format_version: "1.0"
-- module_id: "toolbelt.file.csv-memory"
-- schema_name: "toolbelt_file"
-- object_name: "USP_ParseCsv"
-- object_type: "USP"
-- database_role: "toolbelt"
-- is_internal: false
-- parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord."}, {"name": "@Separator", "sql_type": "nvarchar(2)", "sql_default": "N','", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim."}, {"name": "@HasHeader", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "0: alle Records DATA ab RowOrdinal 1. 1: erster Record HEADER mit RowOrdinal 0, folgende DATA ab 1. NULL ungültig. Header zählt zu MaxCells, nicht MaxRows. Auch mit 1 ergibt leerer Text keine Zellen."}, {"name": "@NullToken", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung."}, {"name": "@MaxRows", "sql_type": "bigint", "sql_default": "100000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf."}, {"name": "@MaxColumns", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig."}, {"name": "@MaxCells", "sql_type": "bigint", "sql_default": "1000000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig."}, {"name": "@MaxInputBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 oder NULL ohne Diagnose, 1..255 abstrakte Severity-10-NOWAIT-Meldung ohne Zellinhalte und ohne zusätzliches Fachresultset. Bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0 oder NULL: Fachaufruf; 1: vor Fachvalidierung nur bestehende zwölfspaltige Standardhilfe und genau ein zusätzliches vierspaltiges Skill-Resultset, danach RETURN 0. Alle SQL-Parameter besitzen Defaults, daher genügt @Hilfe=1."}]
-- source_paths: ["Modules/toolbelt.file.csv-memory/Source/USP_ParseCsv.sql", "Modules/toolbelt.file.csv-memory/Clr/CsvEntryPoints.cs", "Modules/toolbelt.file.csv-memory/Clr/CsvKernel.cs"]
-- review_status: "verified"
-- source_module_version: "1.0.0"
-- ---
--
-- # USP_ParseCsv
--
-- ## Zweck und Einsatzfälle
--
-- Parst begrenzten Unicode-CSV-Text vollständig als rechteckige HEADER-/DATA-Zellen; keine Datei- oder Netzwerkquelle. Leerer Text ergibt keine Zellen. Feste Doppelquote, darin verdoppelte Quotes; Quote nur am Feldanfang, nach Abschlussquote nur Separator, CRLF, LF oder EOF. LF und CRLF sind Recordgrenzen, isoliertes CR außerhalb Quotes ist ungültig. Quoted CR/LF bleiben Daten. Kein Trim; NUL und ungepaarte Surrogate in Zellwerten bleiben erhalten. Finaler Recordabschluss erzeugt keinen Zusatzrecord, Separator am EOF aber ein letztes leeres Feld. Alle Records haben dieselbe Breite. Nur unquoted DATA mit exakt gleichem NullToken wird SQL-NULL; HEADER und quoted Token bleiben Text.
--
-- ## Voraussetzungen
--
-- Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. ResultTable >=1.0.0 in derselben Datenbank für Routing. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.
--
-- ## Parameter und Zugriff
--
-- | Parameter | SQL-Typ | SQL-Default | Vertrag |
-- |---|---|---|---|
-- | `@Text` | `nvarchar(max)` | `NULL` | Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord. |
-- | `@Separator` | `nvarchar(2)` | `N','` | Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim. |
-- | `@HasHeader` | `bit` | `0` | 0: alle Records DATA ab RowOrdinal 1. 1: erster Record HEADER mit RowOrdinal 0, folgende DATA ab 1. NULL ungültig. Header zählt zu MaxCells, nicht MaxRows. Auch mit 1 ergibt leerer Text keine Zellen. |
-- | `@NullToken` | `nvarchar(128)` | `NULL` | NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. |
-- | `@MaxRows` | `bigint` | `100000` | Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. |
-- | `@MaxColumns` | `int` | `1024` | Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. |
-- | `@MaxCells` | `bigint` | `1000000` | Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. |
-- | `@MaxInputBytes` | `bigint` | `16777216` | Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung. |
-- | `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N'#Result'; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
-- | `@KeepData` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
-- | `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 oder NULL ohne Diagnose, 1..255 abstrakte Severity-10-NOWAIT-Meldung ohne Zellinhalte und ohne zusätzliches Fachresultset. Bei ResultTable zusätzlich Helperdiagnose. |
-- | `@Hilfe` | `bit` | `0` | 0 oder NULL: Fachaufruf; 1: vor Fachvalidierung nur bestehende zwölfspaltige Standardhilfe und genau ein zusätzliches vierspaltiges Skill-Resultset, danach RETURN 0. Alle SQL-Parameter besitzen Defaults, daher genügt @Hilfe=1. |
--
-- ## Ergebnisse
--
-- Je Zelle eine fachliche Zeile: RowKind varchar(6) NOT NULL exakt HEADER/DATA, RowOrdinal bigint NOT NULL (HEADER=0, DATA ab 1), ColumnOrdinal int NOT NULL ab 1, Value nvarchar(max) NULL. Textspalten im privaten Ergebnis BIN2. Direkter SELECT ist nach RowOrdinal,ColumnOrdinal geordnet; eine ResultTable besitzt keine dauerhafte Zeilenordnung. Kein öffentliches ErrorCode-Feld; leerer Input liefert null Zeilen. @ResultTable=NULL liefert den SELECT; sonst schreibt der vorhandene ResultTable-Helper in die caller-lokale #Temp und es gibt keinen fachlichen SELECT. @KeepData=0 ersetzt Ergebnisdaten, 1 hängt kompatibel an, NULL entspricht 0. RETURN 0 bei Erfolg, keine OUTPUT-Parameter. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Hilfe und dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), ohne Fachausführung.
--
-- ## Aufrufbeispiele
--
-- ```sql
-- DECLARE @Csv nvarchar(max)=N'name,value'+NCHAR(10)+N'alpha,1';
-- EXEC toolbelt_file.USP_ParseCsv @Text=@Csv,@HasHeader=1;
-- -- Vier Zellen: HEADER (0,1)/(0,2), DATA (1,1)/(1,2).
-- EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;
-- ```
--
-- ## Rechte
--
-- Vorhandenes EXECUTE auf dieser USP und SELECT auf TVF_InternalParseCsv. Bei Routing zusätzlich vorhandenes EXECUTE auf toolbelt_core.USP_PrepareResultTable und dessen vorhandene Abhängigkeitsrechte. Caller muss eigene lokale Temps sehen/lesen bzw. ändern können. Writer prüft tempdb.sys.columns, Routing sys.parameters des Helpers; notwendige Metadatensichtbarkeit muss bestehen. Keine neue Rechtevergabe oder Identitätsumschaltung durch die Prozedur. Zentraler Dreiteilname allein ersetzt keine Cross-DB-Rechte.
--
-- ## Ressourcenbedarf
--
-- Feste Obergrenzen: 100000 DATA-Records, 1024 Spalten, 1000000 Zellen einschließlich HEADER, 16777216 UTF-16-Bytes. Positive Aufrufbudgets dürfen diese Grenzen nur absenken. Das ist keine Heap-, Memory-Grant-, CPU-, Wallclock- oder Produktionskapazitätsgarantie. Input-DATALENGTH wird vor CLR-Kopie geprüft. CLR scannt vollständigen Input zuerst ohne decodierte Zellallokation und danach erneut zur Decodierung. Öffentliche USP materialisiert alle Zellen und prüft den Transport vollständig vor Veröffentlichung. Ganze Inputkopie, Zellwerte und Temp-/Tabellenvariablen können gleichzeitig bestehen; kein Streaming und keine erfolgreiche Teilausgabe.
--
-- ## Nebenwirkungen
--
-- Direkter Parse-SELECT benötigt keinen eigenen Transaktionsscope. Nur ResultTable-Routing kapselt Helper und finales INSERT transaktional. Reservierter Name #tbx_CsvParse_Result und #tbx_-ResultTable-Präfix werden vor separater Workbatchkompilierung abgewiesen. Bei eigenem Transaktionsscope Commit/Rollback nur der eigenen Transaktion; bei bestehender Callertransaktion Savepoint und nur bei XACT_STATE()=1 Rollback dorthin. Kein vollständiges Commit/Rollback der Callertransaktion. Ein technischer Fehler kann sie uncommittable lassen. Savepoints in nicht unterstützten Transaktionen können scheitern. Rollbackfehler werden nicht gesondert abgefangen und können den ursprünglichen Fehler überlagern. SET NOCOUNT ON, optionale abstrakte Diagnose und private temporäre Ergebnisse; keine Dateien, Netzwerkzugriffe, Serverkonfiguration oder persistenten Fachänderungen. Nur ausdrücklich angegebene ResultTable darf ihre Form/Daten gemäß Helpervertrag ändern. Hilfe kehrt davor zurück.
--
-- ## Fehlerbehandlung
--
-- 55300 Pflichtargument/Dialekt; 55301 Quotes/Recordsyntax; 55302 nichtrechteckige Parserrecords; 55303 Ressourcenparameter/-grenze; 55304 Tempname/-sichtbarkeit; 55305 Quellspaltenform; 55306 Writer-Raster/Ordinals/Header; 55307 nichtdarstellbares SQL-NULL; 55308 gleiche Quell-/Zieltabelle; 55309 Transport-/Helpervertrag oder uncommittable Caller. Nicht jeder Code ist auf jedem Pfad erreichbar. Parser-Sentinel muss genau eine Zeile mit vier NULL-Nutzfeldern und bekanntem Fehlercode sein; unbekannte, gemischte oder inkonsistente Transportzeilen ergeben 55309. Fachfehler werden als THROW ohne veröffentlichtes Teilresultat ausgegeben. Unerwartete Engine-/CLR-/Berechtigungsfehler bleiben technische Fehler. XACT_STATE()=-1 wird vor Facharbeit abgewiesen; Hilfe ist vorher erreichbar. Bei eigenem Transaktionsscope Commit/Rollback nur der eigenen Transaktion; bei bestehender Callertransaktion Savepoint und nur bei XACT_STATE()=1 Rollback dorthin. Kein vollständiges Commit/Rollback der Callertransaktion. Ein technischer Fehler kann sie uncommittable lassen. Savepoints in nicht unterstützten Transaktionen können scheitern. Rollbackfehler werden nicht gesondert abgefangen und können den ursprünglichen Fehler überlagern.
--
-- ## Aussagegrenzen
--
-- Quellgeprüfter aktueller Vertrag, keine neue native Gesamtqualifikation. Historische Fach-/Caller-/Paketnachweise behalten ihre ursprüngliche Bindung. Keine Installations- oder Rechteattestation, keine unbegrenzte Ausgabe, keine Datenbereinigung oder allgemeine RFC-/Spreadsheet-/Dateiimportgarantie.
-- OBJECT_USAGE_SKILL:END
BEGIN
 SET NOCOUNT ON;
 IF @Hilfe=1
 BEGIN
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_file' AS sysname) AS SchemaName,
            CAST(N'USP_ParseCsv' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'CSV-Text vollständig prüfen und in HEADER-/DATA-Zellen decodieren.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'RowKind', N'varchar(6)', 1, 0, NULL, CAST(N'Exakt HEADER oder DATA.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'RowOrdinal', N'bigint', 1, 0, NULL, CAST(N'HEADER=0; DATA ab1.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'ColumnOrdinal', N'int', 1, 0, NULL, CAST(N'Einsbasierte rechteckige Spalte.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'Value', N'nvarchar(max)', 1, 1, NULL, CAST(N'Unveränderter decodierter Text oder SQL-NULL.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'55300..55309', NULL, NULL, NULL, NULL, CAST(N'Begrenzte Argument-/Syntax-/Form-/Budget-/Transportfehler; ursprüngliche Enginefehler bleiben erhalten.' AS nvarchar(max)), NULL),
        (N'PERMISSION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'EXECUTE und sichtbare eigene lokale Temps; ResultTable zusätzlich vorhandene Helperberechtigung. Keine Rechteausweitung.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'In-memory UTF-16; kein I/O, Casting, Trim oder Streaming. NUL/unpaired Surrogate bleiben Zelltext.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Hilfe ohne fachliche Eingaben.' AS nvarchar(max)), CAST(N'EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@Text', N'nvarchar(max)', 1, 0, N'NULL', CAST(N'Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@Separator', N'nvarchar(2)', 0, 0, N'N'',''', CAST(N'Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@HasHeader', N'bit', 0, 0, N'0', CAST(N'0: alle Records DATA ab RowOrdinal 1. 1: erster Record HEADER mit RowOrdinal 0, folgende DATA ab 1. NULL ungültig. Header zählt zu MaxCells, nicht MaxRows. Auch mit 1 ergibt leerer Text keine Zellen.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@NullToken', N'nvarchar(128)', 0, 1, N'NULL', CAST(N'NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxRows', N'bigint', 0, 0, N'100000', CAST(N'Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxColumns', N'int', 0, 0, N'1024', CAST(N'Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxCells', N'bigint', 0, 0, N'1000000', CAST(N'Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxInputBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 oder NULL ohne Diagnose, 1..255 abstrakte Severity-10-NOWAIT-Meldung ohne Zellinhalte und ohne zusätzliches Fachresultset. Bei ResultTable zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'0 oder NULL: Fachaufruf; 1: vor Fachvalidierung nur bestehende zwölfspaltige Standardhilfe und genau ein zusätzliches vierspaltiges Skill-Resultset, danach RETURN 0. Alle SQL-Parameter besitzen Defaults, daher genügt @Hilfe=1.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        -- OBJECT_USAGE_SKILL_HELP:BEGIN
SELECT CONVERT(varchar(16),CAST(N'1.0' AS nvarchar(max))) AS SkillFormatVersion,
 CONVERT(sysname,CAST(N'toolbelt_file' AS nvarchar(max))) AS SchemaName,
 CONVERT(sysname,CAST(N'USP_ParseCsv' AS nvarchar(max))) AS ObjectName,
 CAST(N'---
name: "toolbelt-toolbelt-toolbelt-file-usp-parsecsv"
description: "Parst begrenzten Unicode-CSV-Text vollständig als rechteckige HEADER-/DATA-Zellen; keine Datei- oder Netzwerkquelle."
skill_format_version: "1.0"
module_id: "toolbelt.file.csv-memory"
schema_name: "toolbelt_file"
object_name: "USP_ParseCsv"
object_type: "USP"
database_role: "toolbelt"
is_internal: false
parameters: [{"name": "@Text", "sql_type": "nvarchar(max)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": true, "nullable": false, "description": "Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord."}, {"name": "@Separator", "sql_type": "nvarchar(2)", "sql_default": "N'',''", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungültig; Vergleich nach exakter Einheit/Länge, kein Trim."}, {"name": "@HasHeader", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "0: alle Records DATA ab RowOrdinal 1. 1: erster Record HEADER mit RowOrdinal 0, folgende DATA ab 1. NULL ungültig. Header zählt zu MaxCells, nicht MaxRows. Auch mit 1 ergibt leerer Text keine Zellen."}, {"name": "@NullToken", "sql_type": "nvarchar(128)", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "d' AS nvarchar(max)) + N'escription": "NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung."}, {"name": "@MaxRows", "sql_type": "bigint", "sql_default": "100000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf."}, {"name": "@MaxColumns", "sql_type": "int", "sql_default": "1024", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig."}, {"name": "@MaxCells", "sql_type": "bigint", "sql_default": "1000000", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig."}, {"name": "@MaxInputBytes", "sql_type": "bigint", "sql_default": "16777216", "is_output": false, "argument_required": false, "business_required": false, "nullable": false, "description": "Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung."}, {"name": "@ResultTable", "sql_type": "sysname", "sql_default": "NULL", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-E' + N'inheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable."}, {"name": "@KeepData", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag."}, {"name": "@Debug", "sql_type": "tinyint", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "tinyint 0..255: 0 oder NULL ohne Diagnose, 1..255 abstrakte Severity-10-NOWAIT-Meldung ohne Zellinhalte und ohne zusätzliches Fachresultset. Bei ResultTable zusätzlich Helperdiagnose."}, {"name": "@Hilfe", "sql_type": "bit", "sql_default": "0", "is_output": false, "argument_required": false, "business_required": false, "nullable": true, "description": "0 oder NULL: Fachaufruf; 1: vor Fachvalidierung nur bestehende zwölfspaltige Standardhilfe und genau ein zusätzliches vierspaltiges Skill-Resultset, danach RETURN 0. Alle SQL-Parameter besitzen Defaults, daher genügt @Hilfe=1."}]
source_paths: ["Modules/toolbelt.file.csv-memory/Source/USP_ParseCsv.sql", "Modules/toolbelt.file.csv-memory/Clr/CsvEntryPoints.cs", "Modules/toolbelt.file.csv-memory/Clr/CsvKernel.cs"]
review_status: "verified"
source_module_version: "1.0.0"
---

# USP_ParseCsv

## Zweck und Einsatzfälle

Parst begrenzten Unicode-CSV-Text vollständig als rechteckige HEADER-/DATA-Zellen; keine Datei- oder Netzwerkquelle. Leerer Text ergibt keine Zellen. Feste Doppelquot' + N'e, darin verdoppelte Quotes; Quote nur am Feldanfang, nach Abschlussquote nur Separator, CRLF, LF oder EOF. LF und CRLF sind Recordgrenzen, isoliertes CR außerhalb Quotes ist ungültig. Quoted CR/LF bleiben Daten. Kein Trim; NUL und ungepaarte Surrogate in Zellwerten bleiben erhalten. Finaler Recordabschluss erzeugt keinen Zusatzrecord, Separator am EOF aber ein letztes leeres Feld. Alle Records haben dieselbe Breite. Nur unquoted DATA mit exakt gleichem NullToken wird SQL-NULL; HEADER und quoted Token bleiben Text.

## Voraussetzungen

Installiertes Modul mit autorisierter SAFE-Assembly tlblt_File_CsvMemory, SQL Server 2019/2022/2025 auf Windows/Linux gemäß Modulmatrix, CL150/160/170 soweit zur Engine passend, lokal oder zentral. Kein Datei-, Netzwerk- oder Encodingprovider. ResultTable >=1.0.0 in derselben Datenbank für Routing. Separator genau eine UTF-16-Codeunit, nicht NULL/leer, keine Doppelquote, CR, LF, NUL oder Surrogate. NullToken NULL deaktiviert SQL-NULL; sonst 1..128 Codeunits, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate. Gültige Surrogatpaare im Token sind erlaubt. Tokenvergleich exakt nach Länge und Codeunits, nicht SQL-Padding.

## Parameter und Zugriff

| Parameter | SQL-Typ | SQL-Default | Vertrag |
|---|---|---|---|
| `@Text` | `nvarchar(max)` | `NULL` | Vollständiger In-memory-CSV-Text als nvarchar(max), kein Dateipfad und keine kodierten Bytes. Leer ergibt keine Zellen; NULL (technischer Default) ist außerhalb Hilfe ein Argumentfehler. Quote ist fest Doppelquote, innen durch Verdopplung escaped; Recordgrenzen LF oder CRLF, kein isoliertes CR. Kein Trim/Normalisieren; NUL und ungepaarte Surrogate bleiben Zellinhalt. Alle Records müssen die Breite des ersten haben; finaler Recordabschluss erzeugt keinen Zusatzrecord. |
| `@Separator` | `nvarchar(2)` | `N'',''` | Genau eine UTF-16-Einheit, Default Komma; keine mehrzeichige Trennfolge. Doppelquote U+0022, CR, LF, NUL und einzelne High-/Low-Surrogate sind verboten. NULL/leer ungül' + N'tig; Vergleich nach exakter Einheit/Länge, kein Trim. |
| `@HasHeader` | `bit` | `0` | 0: alle Records DATA ab RowOrdinal 1. 1: erster Record HEADER mit RowOrdinal 0, folgende DATA ab 1. NULL ungültig. Header zählt zu MaxCells, nicht MaxRows. Auch mit 1 ergibt leerer Text keine Zellen. |
| `@NullToken` | `nvarchar(128)` | `NULL` | NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung. |
| `@MaxRows` | `bigint` | `100000` | Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf. |
| `@MaxColumns` | `int` | `1024` | Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig. |
| `@MaxCells` | `bigint` | `1000000` | Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig. |
| `@MaxInputBytes` | `bigint` | `16777216` | Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung. |
| `@ResultTable` | `sysname` | `NULL` | NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable. |
| `@Keep' + N'Data` | `bit` | `0` | Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag. |
| `@Debug` | `tinyint` | `0` | tinyint 0..255: 0 oder NULL ohne Diagnose, 1..255 abstrakte Severity-10-NOWAIT-Meldung ohne Zellinhalte und ohne zusätzliches Fachresultset. Bei ResultTable zusätzlich Helperdiagnose. |
| `@Hilfe` | `bit` | `0` | 0 oder NULL: Fachaufruf; 1: vor Fachvalidierung nur bestehende zwölfspaltige Standardhilfe und genau ein zusätzliches vierspaltiges Skill-Resultset, danach RETURN 0. Alle SQL-Parameter besitzen Defaults, daher genügt @Hilfe=1. |

## Ergebnisse

Je Zelle eine fachliche Zeile: RowKind varchar(6) NOT NULL exakt HEADER/DATA, RowOrdinal bigint NOT NULL (HEADER=0, DATA ab 1), ColumnOrdinal int NOT NULL ab 1, Value nvarchar(max) NULL. Textspalten im privaten Ergebnis BIN2. Direkter SELECT ist nach RowOrdinal,ColumnOrdinal geordnet; eine ResultTable besitzt keine dauerhafte Zeilenordnung. Kein öffentliches ErrorCode-Feld; leerer Input liefert null Zeilen. @ResultTable=NULL liefert den SELECT; sonst schreibt der vorhandene ResultTable-Helper in die caller-lokale #Temp und es gibt keinen fachlichen SELECT. @KeepData=0 ersetzt Ergebnisdaten, 1 hängt kompatibel an, NULL entspricht 0. RETURN 0 bei Erfolg, keine OUTPUT-Parameter. @Hilfe=1 liefert zuerst die bestehende zwölfspaltige Hilfe und dann genau eine Zeile SkillFormatVersion varchar(16), SchemaName sysname, ObjectName sysname, SkillMarkdown nvarchar(max), ohne Fachausführung.

## Aufrufbeispiele

```sql
DECLARE @Csv nvarchar(max)=N''name,value''+NCHAR(10)+N''alpha,1'';
EXEC toolbelt_file.USP_ParseCsv @Text=@Csv,@HasHeader=1;
-- Vier Zellen: HEADER (0,1)/(0,2), DATA (1,1)/(1,2).
EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;
```

## Rechte

Vorhandenes EXECUTE auf dieser USP und SELECT auf TVF_InternalParseCsv. Bei Routing zusätzlich vorhandenes EXEC' + N'UTE auf toolbelt_core.USP_PrepareResultTable und dessen vorhandene Abhängigkeitsrechte. Caller muss eigene lokale Temps sehen/lesen bzw. ändern können. Writer prüft tempdb.sys.columns, Routing sys.parameters des Helpers; notwendige Metadatensichtbarkeit muss bestehen. Keine neue Rechtevergabe oder Identitätsumschaltung durch die Prozedur. Zentraler Dreiteilname allein ersetzt keine Cross-DB-Rechte.

## Ressourcenbedarf

Feste Obergrenzen: 100000 DATA-Records, 1024 Spalten, 1000000 Zellen einschließlich HEADER, 16777216 UTF-16-Bytes. Positive Aufrufbudgets dürfen diese Grenzen nur absenken. Das ist keine Heap-, Memory-Grant-, CPU-, Wallclock- oder Produktionskapazitätsgarantie. Input-DATALENGTH wird vor CLR-Kopie geprüft. CLR scannt vollständigen Input zuerst ohne decodierte Zellallokation und danach erneut zur Decodierung. Öffentliche USP materialisiert alle Zellen und prüft den Transport vollständig vor Veröffentlichung. Ganze Inputkopie, Zellwerte und Temp-/Tabellenvariablen können gleichzeitig bestehen; kein Streaming und keine erfolgreiche Teilausgabe.

## Nebenwirkungen

Direkter Parse-SELECT benötigt keinen eigenen Transaktionsscope. Nur ResultTable-Routing kapselt Helper und finales INSERT transaktional. Reservierter Name #tbx_CsvParse_Result und #tbx_-ResultTable-Präfix werden vor separater Workbatchkompilierung abgewiesen. Bei eigenem Transaktionsscope Commit/Rollback nur der eigenen Transaktion; bei bestehender Callertransaktion Savepoint und nur bei XACT_STATE()=1 Rollback dorthin. Kein vollständiges Commit/Rollback der Callertransaktion. Ein technischer Fehler kann sie uncommittable lassen. Savepoints in nicht unterstützten Transaktionen können scheitern. Rollbackfehler werden nicht gesondert abgefangen und können den ursprünglichen Fehler überlagern. SET NOCOUNT ON, optionale abstrakte Diagnose und private temporäre Ergebnisse; keine Dateien, Netzwerkzugriffe, Serverkonfiguration oder persistenten Fachänderungen. Nur ausdrücklich angegebene ResultTable ' + N'darf ihre Form/Daten gemäß Helpervertrag ändern. Hilfe kehrt davor zurück.

## Fehlerbehandlung

55300 Pflichtargument/Dialekt; 55301 Quotes/Recordsyntax; 55302 nichtrechteckige Parserrecords; 55303 Ressourcenparameter/-grenze; 55304 Tempname/-sichtbarkeit; 55305 Quellspaltenform; 55306 Writer-Raster/Ordinals/Header; 55307 nichtdarstellbares SQL-NULL; 55308 gleiche Quell-/Zieltabelle; 55309 Transport-/Helpervertrag oder uncommittable Caller. Nicht jeder Code ist auf jedem Pfad erreichbar. Parser-Sentinel muss genau eine Zeile mit vier NULL-Nutzfeldern und bekanntem Fehlercode sein; unbekannte, gemischte oder inkonsistente Transportzeilen ergeben 55309. Fachfehler werden als THROW ohne veröffentlichtes Teilresultat ausgegeben. Unerwartete Engine-/CLR-/Berechtigungsfehler bleiben technische Fehler. XACT_STATE()=-1 wird vor Facharbeit abgewiesen; Hilfe ist vorher erreichbar. Bei eigenem Transaktionsscope Commit/Rollback nur der eigenen Transaktion; bei bestehender Callertransaktion Savepoint und nur bei XACT_STATE()=1 Rollback dorthin. Kein vollständiges Commit/Rollback der Callertransaktion. Ein technischer Fehler kann sie uncommittable lassen. Savepoints in nicht unterstützten Transaktionen können scheitern. Rollbackfehler werden nicht gesondert abgefangen und können den ursprünglichen Fehler überlagern.

## Aussagegrenzen

Quellgeprüfter aktueller Vertrag, keine neue native Gesamtqualifikation. Historische Fach-/Caller-/Paketnachweise behalten ihre ursprüngliche Bindung. Keine Installations- oder Rechteattestation, keine unbegrenzte Ausgabe, keine Datenbereinigung oder allgemeine RFC-/Spreadsheet-/Dateiimportgarantie.
' AS SkillMarkdown;
        -- OBJECT_USAGE_SKILL_HELP:END
        RETURN 0;
        -- API_PARAMETER_HELP:END
    END;
 SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0);
 IF XACT_STATE()=-1 THROW 55309,N'CSV: Callertransaktion ist uncommittable.',1;
 IF @HasHeader IS NULL OR @Text IS NULL THROW 55300,N'CSV: erforderlicher Text oder Headerflag fehlt.',1;
 IF @MaxRows IS NULL OR @MaxRows NOT BETWEEN 1 AND 100000
 OR @MaxColumns IS NULL OR @MaxColumns NOT BETWEEN 1 AND 1024
 OR @MaxCells IS NULL OR @MaxCells NOT BETWEEN 1 AND 1000000
 OR @MaxInputBytes IS NULL OR @MaxInputBytes NOT BETWEEN 1 AND 16777216
  THROW 55303,N'CSV: Ressourcenparameter ist ungültig.',1;
 IF DATALENGTH(@Text)>@MaxInputBytes THROW 55303,N'CSV: Inputbytegrenze überschritten.',1;
 -- Namespacegrenze VOR separater Workbatch-Kompilierung: kein Caller-Temp-Eclipsing.
 IF (@ResultTable IS NOT NULL AND LOWER(LEFT(@ResultTable COLLATE Latin1_General_100_BIN2,5))=N'#tbx_')
 OR OBJECT_ID(N'tempdb..#tbx_CsvParse_Result',N'U') IS NOT NULL
  THROW 55304,N'CSV: reservierter privater Tempnamensbereich ist belegt.',1;
 IF OBJECT_ID(N'toolbelt_file.TVF_InternalParseCsv',N'FT') IS NULL
  THROW 55309,N'CSV: interne CLR-Bindung fehlt.',1;
 -- Fester vertrauenswürdiger SQL-Text; sämtliche Callerwerte sind gebundene Parameter.
 DECLARE @WorkSql nvarchar(max)=N'IF @ResultTable IS NOT NULL
 BEGIN

 DECLARE @CoreId int=OBJECT_ID(N''toolbelt_core.USP_PrepareResultTable'',N''P'');
 IF @CoreId IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@CoreId)<>5
 OR EXISTS(SELECT 1 FROM (VALUES (1,N''@ResultTableToAlter'',231,256),(2,N''@LikeTable'',231,1552),
(3,N''@KeepData'',104,1),(4,N''@Debug'',48,1),(5,N''@Hilfe'',104,1)) expected(id,name,typeid,bytes)
     WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=@CoreId
       AND p.parameter_id=expected.id AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.name)
       AND p.system_type_id=expected.typeid AND p.max_length=expected.bytes AND p.is_output=0))
 THROW 55309,N''ResultTable-Schnittstelle fehlt oder ist abweichend.'',1;
 END;
 DECLARE @Cells TABLE(RowKind nvarchar(6) COLLATE Latin1_General_100_BIN2 NULL,RowOrdinal bigint NULL,ColumnOrdinal int NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,ErrorCode int NULL);
 -- Vollständiger privater Konsum vor Ausgabe oder Zielmutation; späte CLR-Fehler bleiben Originalfehler.
 INSERT @Cells(RowKind,RowOrdinal,ColumnOrdinal,[Value],ErrorCode)
 SELECT RowKind,RowOrdinal,ColumnOrdinal,[Value],ErrorCode FROM toolbelt_file.TVF_InternalParseCsv(@Text,@Separator,@HasHeader,@NullToken,@MaxRows,@MaxColumns,@MaxCells,@MaxInputBytes);
 IF EXISTS(SELECT 1 FROM @Cells WHERE ErrorCode IS NULL OR (ErrorCode<>0 AND ErrorCode NOT BETWEEN 55300 AND 55309))
  THROW 55309,N''CSV: interner Parserstatus ungültig.'',1;
 DECLARE @ErrorCode int;
 IF EXISTS(SELECT 1 FROM @Cells WHERE ErrorCode<>0)
 BEGIN
  IF (SELECT COUNT_BIG(*) FROM @Cells)<>1 OR EXISTS(SELECT 1 FROM @Cells WHERE RowKind IS NOT NULL OR RowOrdinal IS NOT NULL OR ColumnOrdinal IS NOT NULL OR [Value] IS NOT NULL)
   THROW 55309,N''CSV: Parserfehler ist kein isolierter Sentinel.'',1;
  SELECT @ErrorCode=ErrorCode FROM @Cells;
  DECLARE @ErrorMessage nvarchar(2048)=CASE @ErrorCode
 WHEN 55300 THEN N''CSV: ungültiges Pflichtargument oder Dialekt.''
 WHEN 55301 THEN N''CSV: ungültige Quote- oder Recordsyntax.''
 WHEN 55302 THEN N''CSV: Parserrecords sind nicht rechteckig.''
 WHEN 55303 THEN N''CSV: Ressourcenparameter oder Ressourcengrenze verletzt.''
 WHEN 55304 THEN N''CSV: zulässige caller-lokale Quelle fehlt.''
 WHEN 55305 THEN N''CSV: Quellmetadaten sind nicht exakt unterstützt.''
 WHEN 55306 THEN N''CSV: RowKind, Ordinals, Header oder Rechteck ungültig.''
 WHEN 55307 THEN N''CSV: SQL-NULL ist nicht darstellbar.''
 WHEN 55308 THEN N''CSV: Quelle und ResultTable sind identisch.''
 ELSE N''CSV: interner Transportvertrag verletzt.'' END;
 THROW @ErrorCode,@ErrorMessage,1;
 END;
 IF EXISTS(SELECT 1 FROM @Cells WHERE RowKind IS NULL OR RowOrdinal IS NULL OR ColumnOrdinal IS NULL
  OR CONVERT(varbinary(max),RowKind) NOT IN(CONVERT(varbinary(max),N''HEADER''),CONVERT(varbinary(max),N''DATA''))
  OR ColumnOrdinal NOT BETWEEN 1 AND @MaxColumns
  OR (CONVERT(varbinary(max),RowKind)=CONVERT(varbinary(max),N''HEADER'') AND (@HasHeader=0 OR RowOrdinal<>0 OR [Value] IS NULL))
  OR (CONVERT(varbinary(max),RowKind)=CONVERT(varbinary(max),N''DATA'') AND RowOrdinal NOT BETWEEN 1 AND @MaxRows))
  THROW 55309,N''CSV: interne Parserzellform ungültig.'',1;
 IF (SELECT COUNT_BIG(*) FROM @Cells)>@MaxCells OR EXISTS(SELECT 1 FROM @Cells GROUP BY RowOrdinal,ColumnOrdinal HAVING COUNT_BIG(*)<>1)
  THROW 55309,N''CSV: interne Parsergrenze oder Eindeutigkeit ungültig.'',1;
 CREATE TABLE #tbx_CsvParse_Result(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
 INSERT #tbx_CsvParse_Result(RowKind,RowOrdinal,ColumnOrdinal,[Value]) SELECT CONVERT(varchar(6),RowKind),RowOrdinal,ColumnOrdinal,[Value] FROM @Cells;
 IF @Debug>0 RAISERROR(N''CSV: vollständiger Parser-Snapshot bereit.'',10,1) WITH NOWAIT;
 IF @ResultTable IS NULL
 BEGIN SELECT RowKind,RowOrdinal,ColumnOrdinal,[Value] FROM #tbx_CsvParse_Result ORDER BY RowOrdinal,ColumnOrdinal; RETURN; END;
 DECLARE @Own bit=CASE WHEN @@TRANCOUNT=0 THEN 1 ELSE 0 END,@Saved bit=0,@Savepoint varchar(32)=REPLACE(CONVERT(varchar(36),NEWID()),''-'','''');
 BEGIN TRY
  IF @Own=1 BEGIN TRANSACTION; ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @Saved=1; END;
  EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N''#tbx_CsvParse_Result'',@KeepData=@KeepData,@Debug=@Debug;
  DECLARE @InsertSql nvarchar(max)=N''INSERT ''+QUOTENAME(@ResultTable)+N'' (RowKind,RowOrdinal,ColumnOrdinal,[Value]) SELECT RowKind,RowOrdinal,ColumnOrdinal,[Value] FROM #tbx_CsvParse_Result;'';
  EXEC sys.sp_executesql @InsertSql;
  IF @Own=1 COMMIT TRANSACTION;
 END TRY
 BEGIN CATCH
  IF @Own=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
  ELSE IF @Saved=1 AND XACT_STATE()=1 ROLLBACK TRANSACTION @Savepoint;
  THROW;
 END CATCH;';
 EXEC sys.sp_executesql @WorkSql,N'@Text nvarchar(max),@Separator nvarchar(2),@HasHeader bit,@NullToken nvarchar(128),@MaxRows bigint,@MaxColumns int,@MaxCells bigint,@MaxInputBytes bigint,@ResultTable sysname,@KeepData bit,@Debug tinyint',
  @Text=@Text,@Separator=@Separator,@HasHeader=@HasHeader,@NullToken=@NullToken,@MaxRows=@MaxRows,@MaxColumns=@MaxColumns,@MaxCells=@MaxCells,@MaxInputBytes=@MaxInputBytes,@ResultTable=@ResultTable,@KeepData=@KeepData,@Debug=@Debug;
 RETURN 0;
END;
GO
