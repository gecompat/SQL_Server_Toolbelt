SET NOCOUNT ON;
-- Direkte Unicode-/NULL-Parserausgabe; vollstaendige Clientorakel.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x3DD800DE),4194303),@Text nvarchar(max);
SET @Text=@V1+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV Unicode SELECT: Textfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=NULL;

GO
SET NOCOUNT ON;
-- Unabhaengige Writerquelle; NULL bleibt von literalem Token getrennt.
CREATE TABLE #CsvSelectCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x3DD800DE),4194303),@Text nvarchar(max);
SET @Text=@V1+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV Unicode SELECT: Textfixture weicht ab.',1;
INSERT #CsvSelectCells VALUES('DATA',1,1,@V1);
IF (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvSelectCells)>=16777216 THROW 55396,N'CSV Unicode SELECT: Wertcharge nicht isoliert.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV Unicode SELECT: vollstaendige Quelle weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSelectCells',@LineEnding='CRLF',@ResultTable=NULL;
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV Unicode SELECT: vollstaendige Quelle weicht ab.',3;
DROP TABLE #CsvSelectCells;

GO
SET NOCOUNT ON;
-- Direkte Unicode-/NULL-Parserausgabe; vollstaendige Clientorakel.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x3DD800DE),4194303)+N'x',@Text nvarchar(max);
SET @Text=@V1+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV Unicode SELECT: Textfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=NULL;

GO
SET NOCOUNT ON;
-- Unabhaengige Writerquelle; NULL bleibt von literalem Token getrennt.
CREATE TABLE #CsvSelectCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x3DD800DE),4194303)+N'x',@Text nvarchar(max);
SET @Text=@V1+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV Unicode SELECT: Textfixture weicht ab.',1;
INSERT #CsvSelectCells VALUES('DATA',1,1,@V1);
IF (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvSelectCells)>=16777216 THROW 55396,N'CSV Unicode SELECT: Wertcharge nicht isoliert.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV Unicode SELECT: vollstaendige Quelle weicht ab.',3;
BEGIN TRY
 EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSelectCells',@LineEnding='CRLF',@ResultTable=NULL;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW;
 IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV Unicode SELECT: vollstaendige Quelle weicht ab.',3;
 DROP TABLE #CsvSelectCells;
 THROW;
END CATCH;
DROP TABLE #CsvSelectCells;

GO
SET NOCOUNT ON;
-- Direkte Unicode-/NULL-Parserausgabe; vollstaendige Clientorakel.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),NULL),@V2 nvarchar(max)=CONVERT(nvarchar(max),N'NULL'),@V3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x2D4E),8388594),@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'NULL,"NULL",')+@V3+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV Unicode SELECT: Textfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@NullToken=N'NULL',@ResultTable=NULL;

GO
SET NOCOUNT ON;
-- Unabhaengige Writerquelle; NULL bleibt von literalem Token getrennt.
CREATE TABLE #CsvSelectCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),NULL),@V2 nvarchar(max)=CONVERT(nvarchar(max),N'NULL'),@V3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x2D4E),8388594),@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'NULL,"NULL",')+@V3+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV Unicode SELECT: Textfixture weicht ab.',1;
INSERT #CsvSelectCells VALUES('DATA',1,1,@V1),('DATA',1,2,@V2),('DATA',1,3,@V3);
IF (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvSelectCells)>=16777216 THROW 55396,N'CSV Unicode SELECT: Wertcharge nicht isoliert.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=2 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=3 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV Unicode SELECT: vollstaendige Quelle weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSelectCells',@LineEnding='CRLF',@NullToken=N'NULL',@ResultTable=NULL;
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=2 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=3 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV Unicode SELECT: vollstaendige Quelle weicht ab.',3;
DROP TABLE #CsvSelectCells;

GO
SET NOCOUNT ON;
-- Direkte Unicode-/NULL-Parserausgabe; vollstaendige Clientorakel.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),NULL),@V2 nvarchar(max)=CONVERT(nvarchar(max),N'NULL'),@V3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x2D4E),8388595),@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'NULL,"NULL",')+@V3+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV Unicode SELECT: Textfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@NullToken=N'NULL',@ResultTable=NULL;

GO
SET NOCOUNT ON;
-- Unabhaengige Writerquelle; NULL bleibt von literalem Token getrennt.
CREATE TABLE #CsvSelectCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),NULL),@V2 nvarchar(max)=CONVERT(nvarchar(max),N'NULL'),@V3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x2D4E),8388595),@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'NULL,"NULL",')+@V3+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV Unicode SELECT: Textfixture weicht ab.',1;
INSERT #CsvSelectCells VALUES('DATA',1,1,@V1),('DATA',1,2,@V2),('DATA',1,3,@V3);
IF (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvSelectCells)>=16777216 THROW 55396,N'CSV Unicode SELECT: Wertcharge nicht isoliert.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=2 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=3 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV Unicode SELECT: vollstaendige Quelle weicht ab.',3;
BEGIN TRY
 EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSelectCells',@LineEnding='CRLF',@NullToken=N'NULL',@ResultTable=NULL;
END TRY
BEGIN CATCH
 IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW;
 IF (SELECT COUNT_BIG(*) FROM #CsvSelectCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=2 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvSelectCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=3 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV Unicode SELECT: vollstaendige Quelle weicht ab.',3;
 DROP TABLE #CsvSelectCells;
 THROW;
END CATCH;
DROP TABLE #CsvSelectCells;
