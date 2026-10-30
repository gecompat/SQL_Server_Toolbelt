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
        (N'PARAMETER', 3, N'@HasHeader', N'bit', 0, 0, N'0', CAST(N'Taxativ im gebundenen bit: 0 kein Header (Default); 1 erster Record als HEADER/RowOrdinal 0, DATA beginnt bei 1. NULL ist ungültig und kein Default. Header zählt zu MaxCells, nicht zu MaxRows. Writer verlangt bei 1 einen vollständigen nicht-NULL-Header.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@NullToken', N'nvarchar(128)', 0, 1, N'NULL', CAST(N'NULL (Default) deaktiviert die DATA-NULL-Darstellung. Andernfalls 1..128 UTF-16-Einheiten, ohne Separator, Doppelquote, CR, LF, NUL oder ungepaarte Surrogate; gültige Surrogatpaare sind erlaubt. Binäre längensensitive Übereinstimmung: nur unquoted DATA-Token wird SQL-NULL. Quoted Token und HEADER sind Text; der Writer quoted einen wörtlich gleichen Text zur Unterscheidung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@MaxRows', N'bigint', 0, 0, N'100000', CAST(N'Ganzzahl 1..100000 DATA-Records, Default 100000; Header zählt nicht mit. NULL/außerhalb ungültig; Überschreitung verwirft den gesamten Aufruf.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@MaxColumns', N'int', 0, 0, N'1024', CAST(N'Ganzzahl 1..1024 Spalten pro Record, Default 1024; positive rechteckige Breite für alle Records. NULL/außerhalb ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 7, N'@MaxCells', N'bigint', 0, 0, N'1000000', CAST(N'Ganzzahl 1..1000000 Zellen einschließlich HEADER und DATA, Default 1000000. NULL/außerhalb ungültig.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 8, N'@MaxInputBytes', N'bigint', 0, 0, N'16777216', CAST(N'Ganzzahl 1..16777216 DATALENGTH-Bytes des UTF-16-Inputs, Default 16777216; einschließlich Quotes, Separatoren, Header und Zeilenumbrüchen. NULL/außerhalb ungültig; kein Streaming und keine Teilausgabe bei Überschreitung.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 9, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet. Kein #tbx_-Präfix; beim Writer nicht dieselbe tatsächliche Tabelle wie CellsTable.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 10, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 11, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255: 0 (Default) oder NULL ohne Diagnose; 1..255 aktiviert die im Objekt beschriebenen abstrakten Diagnose-Messages, ohne zusätzlichen fachlichen Resultset. Bei >0 meldet der CSV-Kern den vollständigen Snapshot/das Writergebnis ohne Zellinhalte; im ResultTable-Pfad zusätzlich Helperdiagnose.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 12, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
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
  DECLARE @CoreId int=OBJECT_ID(N''toolbelt_core.USP_PrepareResultTable'',N''P''),@CoreVersion nvarchar(64),@Major int,@Minor int,@Patch int;
  SELECT @CoreVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N''Toolbelt.Module.toolbelt.core.result-table.Version'';
  SELECT @Major=TRY_CONVERT(int,PARSENAME(@CoreVersion,3)),@Minor=TRY_CONVERT(int,PARSENAME(@CoreVersion,2)),@Patch=TRY_CONVERT(int,PARSENAME(@CoreVersion,1));
  IF @CoreId IS NULL OR @Major IS NULL OR @Major<1 OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
   OR CONVERT(varbinary(max),@CoreVersion)<>CONVERT(varbinary(max),CONCAT(@Major,N''.'',@Minor,N''.'',@Patch))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@CoreId AND minor_id=0 AND name=N''Toolbelt.ModuleId'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N''toolbelt.core.result-table''))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@CoreId AND minor_id=0 AND name=N''Toolbelt.ModuleVersion'' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@CoreVersion))
   THROW 55309,N''CSV: registrierte ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.'',1;
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
