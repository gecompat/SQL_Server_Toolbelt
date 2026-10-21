SET NOCOUNT ON;
-- Direkter Parser unquotiert: genau16MiB, Client prueft komplette Resultsetbytes.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388606),@Text nvarchar(max);
SET @Text=@Value+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV SELECT: exakte Textfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=NULL;

GO
SET NOCOUNT ON;
-- Direkter Writer unquotiert: unabhaengige Quelle, genau16MiB Output.
CREATE TABLE #CsvSelectCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388606),@Text nvarchar(max);
SET @Text=@Value+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV SELECT: exakte Textfixture weicht ab.',1;
IF DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV SELECT: Writerwertcharge nicht isoliert.',2;
INSERT #CsvSelectCells VALUES('DATA',1,1,@Value);
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value))
 THROW 55396,N'CSV SELECT: vollstaendige Writerquelle weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSelectCells',@LineEnding='CRLF',@ResultTable=NULL;
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value))
 THROW 55396,N'CSV SELECT: vollstaendige Writerquelle weicht ab.',3;
DROP TABLE #CsvSelectCells;

GO
SET NOCOUNT ON;
-- Parser unquotiert:16MiB+2; Client verlangt55303/state1 ohne Resultset.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388606)+N'x',@Text nvarchar(max);
SET @Text=@Value+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV SELECT: uebergrosse Textfixture weicht ab.',4;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=NULL;

GO
SET NOCOUNT ON;
-- Writer unquotiert:16MiB+2; Quelle erhalten, kein partielles Resultset.
CREATE TABLE #CsvSelectCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388606)+N'x',@Text nvarchar(max);
SET @Text=@Value+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV SELECT: uebergrosse Textfixture weicht ab.',4;
IF DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV SELECT: Writeruebergrenze nicht isoliert.',5;
INSERT #CsvSelectCells VALUES('DATA',1,1,@Value);
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value))
 THROW 55396,N'CSV SELECT: vollstaendige Writerquelle weicht ab.',3;
BEGIN TRY
 EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSelectCells',@LineEnding='CRLF',@ResultTable=NULL;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW;
 IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value))
 THROW 55396,N'CSV SELECT: vollstaendige Writerquelle weicht ab.',3;
 DROP TABLE #CsvSelectCells;
 THROW;
END CATCH;
DROP TABLE #CsvSelectCells;

GO
SET NOCOUNT ON;
-- Direkter Parser quotiert: genau16MiB, Client prueft komplette Resultsetbytes.
DECLARE @Value nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388603),@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'"')+@Value+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV SELECT: exakte Textfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=NULL;

GO
SET NOCOUNT ON;
-- Direkter Writer quotiert: unabhaengige Quelle, genau16MiB Output.
CREATE TABLE #CsvSelectCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
DECLARE @Value nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388603),@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'"')+@Value+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV SELECT: exakte Textfixture weicht ab.',1;
IF DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV SELECT: Writerwertcharge nicht isoliert.',2;
INSERT #CsvSelectCells VALUES('DATA',1,1,@Value);
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value))
 THROW 55396,N'CSV SELECT: vollstaendige Writerquelle weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSelectCells',@LineEnding='CRLF',@ResultTable=NULL;
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value))
 THROW 55396,N'CSV SELECT: vollstaendige Writerquelle weicht ab.',3;
DROP TABLE #CsvSelectCells;

GO
SET NOCOUNT ON;
-- Parser quotiert:16MiB+2; Client verlangt55303/state1 ohne Resultset.
DECLARE @Value nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388603)+N'x',@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'"')+@Value+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV SELECT: uebergrosse Textfixture weicht ab.',4;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=NULL;

GO
SET NOCOUNT ON;
-- Writer quotiert:16MiB+2; Quelle erhalten, kein partielles Resultset.
CREATE TABLE #CsvSelectCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
DECLARE @Value nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388603)+N'x',@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'"')+@Value+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV SELECT: uebergrosse Textfixture weicht ab.',4;
IF DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV SELECT: Writeruebergrenze nicht isoliert.',5;
INSERT #CsvSelectCells VALUES('DATA',1,1,@Value);
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value))
 THROW 55396,N'CSV SELECT: vollstaendige Writerquelle weicht ab.',3;
BEGIN TRY
 EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSelectCells',@LineEnding='CRLF',@ResultTable=NULL;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW;
 IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value))
 THROW 55396,N'CSV SELECT: vollstaendige Writerquelle weicht ab.',3;
 DROP TABLE #CsvSelectCells;
 THROW;
END CATCH;
DROP TABLE #CsvSelectCells;
