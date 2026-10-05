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
  DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL DEFAULT('1.0'),SchemaName sysname NOT NULL DEFAULT(N'toolbelt_file'),ObjectName sysname NOT NULL DEFAULT(N'USP_ParseCsv'),
   Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
  INSERT @Help(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql) VALUES
  ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'CSV-Text vollständig prüfen und in HEADER-/DATA-Zellen decodieren.',NULL),
  ('PARAMETER',1,N'@Text','nvarchar(max)',1,0,N'NULL',N'CSV-Text im Speicher; NULL ist Argumentfehler, leer liefert keine Zellen.',NULL),
  ('PARAMETER',2,N'@Separator','nvarchar(2)',0,0,N'N'',''',N'Exakt eine zulässige UTF-16-Codeeinheit.',NULL),
  ('PARAMETER',3,N'@HasHeader','bit',0,0,N'0',N'Erster Record ist HEADER; NULL ist ungültig.',NULL),
  ('PARAMETER',4,N'@NullToken','nvarchar(128)',0,1,N'NULL',N'Optionaler exakter NULL-Token; quoted Token bleibt Text.',NULL),
  ('PARAMETER',5,N'@MaxRows','bigint',0,0,N'100000',N'Positive DATA-Recordgrenze bis 100000.',NULL),
  ('PARAMETER',6,N'@MaxColumns','int',0,0,N'1024',N'Positive rechteckige Breite bis 1024.',NULL),
  ('PARAMETER',7,N'@MaxCells','bigint',0,0,N'1000000',N'Positive HEADER+DATA-Zellgrenze bis 1000000.',NULL),
  ('PARAMETER',8,N'@MaxInputBytes','bigint',0,0,N'16777216',N'Positive vollständige UTF-16-Inputbytegrenze bis 16777216.',NULL),
  ('PARAMETER',9,N'@ResultTable','sysname',0,1,N'NULL',N'Vorhandene caller-lokale Temp-Tabelle, sonst SELECT.',NULL),
  ('PARAMETER',10,N'@KeepData','bit',0,1,N'0',N'Replace=0, Append=1; NULL entspricht 0.',NULL),
  ('PARAMETER',11,N'@Debug','tinyint',0,1,N'0',N'Nur Messages ohne Zellinhalte; NULL entspricht 0.',NULL),
  ('PARAMETER',12,N'@Hilfe','bit',0,1,N'0',N'Ausschließlich Hilfe; ignoriert sämtliche anderen Eingaben.',NULL),
  ('RESULT_COLUMN',1,N'RowKind','varchar(6)',1,0,NULL,N'Exakt HEADER oder DATA.',NULL),
  ('RESULT_COLUMN',2,N'RowOrdinal','bigint',1,0,NULL,N'HEADER=0; DATA ab1.',NULL),
  ('RESULT_COLUMN',3,N'ColumnOrdinal','int',1,0,NULL,N'Einsbasierte rechteckige Spalte.',NULL),
  ('RESULT_COLUMN',4,N'Value','nvarchar(max)',1,1,NULL,N'Unveränderter decodierter Text oder SQL-NULL.',NULL),
  ('ERROR',1,N'55300..55309',NULL,NULL,NULL,NULL,N'Begrenzte Argument-/Syntax-/Form-/Budget-/Transportfehler; ursprüngliche Enginefehler bleiben erhalten.',NULL),
  ('PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE und sichtbare eigene lokale Temps; ResultTable zusätzlich vorhandene Helperberechtigung. Keine Rechteausweitung.',NULL),
  ('LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'In-memory UTF-16; kein I/O, Casting, Trim oder Streaming. NUL/unpaired Surrogate bleiben Zelltext.',NULL),
  ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Hilfe ohne fachliche Eingaben.',N'EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;');
  SELECT HelpContractVersion,SchemaName,ObjectName,
   Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
  FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 WHEN 'PERMISSION' THEN 5 WHEN 'LIMITATION' THEN 6 ELSE 7 END,Ordinal;
  RETURN 0;
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
