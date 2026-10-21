-- Tatsächliche vollständige Input-/Outputtextbytes; keine Heap-/Laufzeitzusage.
-- Kleinste UTF16-Überschreitung ist +2 Bytes. Writerwertsumme bleibt strikt unter16MiB.
SET NOCOUNT ON;
CREATE TABLE #CsvExpansionCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvExpansionOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
CREATE TABLE #CsvExpansionProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
-- Headerwert und DATAwert mit LF: Parser genau16MiB.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'h'),128),
 @V2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388478),
 @Text nvarchar(max);
SET @Text=@V1+NCHAR(10)+@V2+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV expansion: exakte Inputfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=1,@ResultTable=N'#CsvExpansionCells';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: exakte Parserzellen weichen ab.',2;
INSERT #CsvExpansionProgress VALUES(1);

GO
-- Headerwert und DATAwert mit LF: Writer genau16MiB, vollständige Quell-/Zielbytes.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'h'),128),
 @V2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388478),
 @ExpectedText nvarchar(max);
SET @ExpectedText=@V1+NCHAR(10)+@V2+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Writerfixture weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=1,@LineEnding='LF',@ResultTable=N'#CsvExpansionOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: exakter Writer oder Quellerhalt weicht ab.',4;
INSERT #CsvExpansionProgress VALUES(2);

GO
-- Headerwert und DATAwert mit LF: Parser16MiB+2, vorheriges ResultTable erhalten.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'h'),128),
 @V2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388478),
 @OverV1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'h'),128),
 @OverV2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388479),
 @Text nvarchar(max),@Caught bit=0;
SET @Text=@OverV1+NCHAR(10)+@OverV2+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV expansion: Plus-zwei-Inputfixture weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=1,@ResultTable=N'#CsvExpansionCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Inputabweisung oder Zielerhalt fehlt.',6;
INSERT #CsvExpansionProgress VALUES(3);

GO
-- Headerwert und DATAwert mit LF: unabhängig gesetzte Writer-Übergrenzquelle,16MiB+2 Output.
TRUNCATE TABLE #CsvExpansionCells;
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'h'),128),
 @V2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388479),
 @OldV1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'h'),128),
 @OldV2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388478),
 @ExpectedText nvarchar(max),@OverText nvarchar(max),@Caught bit=0;
INSERT #CsvExpansionCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('HEADER',0,1,@V1),('DATA',1,1,@V2);
SET @ExpectedText=@OldV1+NCHAR(10)+@OldV2+NCHAR(10);
SET @OverText=@V1+NCHAR(10)+@V2+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR DATALENGTH(@OverText)<>16777218
 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Writer-Übergrenzfixture weicht ab.',7;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=1,@LineEnding='LF',@ResultTable=N'#CsvExpansionOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Outputabweisung oder Quell-/Zielerhalt fehlt.',8;
INSERT #CsvExpansionProgress VALUES(4);

GO
-- Quotierter Header und DATAwert mit CRLF: Parser genau16MiB.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),N'h,'),
 @V2 nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388597),
 @Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'"')+@V1+N'"'+NCHAR(13)+NCHAR(10)+N'"'+@V2+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV expansion: exakte Inputfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=1,@ResultTable=N'#CsvExpansionCells';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: exakte Parserzellen weichen ab.',2;
INSERT #CsvExpansionProgress VALUES(5);

GO
-- Quotierter Header und DATAwert mit CRLF: Writer genau16MiB, vollständige Quell-/Zielbytes.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),N'h,'),
 @V2 nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388597),
 @ExpectedText nvarchar(max);
SET @ExpectedText=CONVERT(nvarchar(max),N'"')+@V1+N'"'+NCHAR(13)+NCHAR(10)+N'"'+@V2+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Writerfixture weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=1,@LineEnding='CRLF',@ResultTable=N'#CsvExpansionOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: exakter Writer oder Quellerhalt weicht ab.',4;
INSERT #CsvExpansionProgress VALUES(6);

GO
-- Quotierter Header und DATAwert mit CRLF: Parser16MiB+2, vorheriges ResultTable erhalten.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),N'h,'),
 @V2 nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388597),
 @OverV1 nvarchar(max)=CONVERT(nvarchar(max),N'h,'),
 @OverV2 nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388598),
 @Text nvarchar(max),@Caught bit=0;
SET @Text=CONVERT(nvarchar(max),N'"')+@OverV1+N'"'+NCHAR(13)+NCHAR(10)+N'"'+@OverV2+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV expansion: Plus-zwei-Inputfixture weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=1,@ResultTable=N'#CsvExpansionCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Inputabweisung oder Zielerhalt fehlt.',6;
INSERT #CsvExpansionProgress VALUES(7);

GO
-- Quotierter Header und DATAwert mit CRLF: unabhängig gesetzte Writer-Übergrenzquelle,16MiB+2 Output.
TRUNCATE TABLE #CsvExpansionCells;
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),N'h,'),
 @V2 nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388598),
 @OldV1 nvarchar(max)=CONVERT(nvarchar(max),N'h,'),
 @OldV2 nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388597),
 @ExpectedText nvarchar(max),@OverText nvarchar(max),@Caught bit=0;
INSERT #CsvExpansionCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('HEADER',0,1,@V1),('DATA',1,1,@V2);
SET @ExpectedText=CONVERT(nvarchar(max),N'"')+@OldV1+N'"'+NCHAR(13)+NCHAR(10)+N'"'+@OldV2+N'"'+NCHAR(13)+NCHAR(10);
SET @OverText=CONVERT(nvarchar(max),N'"')+@V1+N'"'+NCHAR(13)+NCHAR(10)+N'"'+@V2+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR DATALENGTH(@OverText)<>16777218
 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Writer-Übergrenzfixture weicht ab.',7;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=1,@LineEnding='CRLF',@ResultTable=N'#CsvExpansionOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=0 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x484541444552 AND DATALENGTH(RowKind)=6 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Outputabweisung oder Quell-/Zielerhalt fehlt.',8;
INSERT #CsvExpansionProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvExpansionProgress);
IF @Cases<>8 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV expansion: Abschlusswitness fehlt.',9;
DROP TABLE #CsvExpansionProgress;
DROP TABLE #CsvExpansionOutput;
DROP TABLE #CsvExpansionCells;
SELECT CONVERT(nvarchar(32),N'CSV_HEADER_TEXT_CEILINGS') Fixture,CONVERT(int,@Cases) CasesPassed;
