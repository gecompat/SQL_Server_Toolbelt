-- Tatsächliche vollständige Input-/Outputtextbytes; keine Heap-/Laufzeitzusage.
-- Kleinste UTF16-Überschreitung ist +2 Bytes. Writerwertsumme bleibt strikt unter16MiB.
SET NOCOUNT ON;
CREATE TABLE #CsvExpansionCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvExpansionOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
CREATE TABLE #CsvExpansionProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
-- NUL, getrennte Surrogate und BOM im Wert: Parser genau16MiB.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677721)+N'x',
 @Text nvarchar(max);
SET @Text=@V1+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV expansion: exakte Inputfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvExpansionCells';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: exakte Parserzellen weichen ab.',2;
INSERT #CsvExpansionProgress VALUES(1);

GO
-- NUL, getrennte Surrogate und BOM im Wert: Writer genau16MiB, vollständige Quell-/Zielbytes.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677721)+N'x',
 @ExpectedText nvarchar(max);
SET @ExpectedText=@V1+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: Writerfixture weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=0,@LineEnding='CRLF',@ResultTable=N'#CsvExpansionOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: exakter Writer oder Quellerhalt weicht ab.',4;
INSERT #CsvExpansionProgress VALUES(2);

GO
-- NUL, getrennte Surrogate und BOM im Wert: Parser16MiB+2, vorheriges ResultTable erhalten.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677721)+N'x',
 @OverV1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677721)+N'xx',
 @Text nvarchar(max),@Caught bit=0;
SET @Text=@OverV1+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV expansion: Plus-zwei-Inputfixture weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvExpansionCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: Inputabweisung oder Zielerhalt fehlt.',6;
INSERT #CsvExpansionProgress VALUES(3);

GO
-- NUL, getrennte Surrogate und BOM im Wert: unabhängig gesetzte Writer-Übergrenzquelle,16MiB+2 Output.
TRUNCATE TABLE #CsvExpansionCells;
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677721)+N'xx',
 @OldV1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677721)+N'x',
 @ExpectedText nvarchar(max),@OverText nvarchar(max),@Caught bit=0;
INSERT #CsvExpansionCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('DATA',1,1,@V1);
SET @ExpectedText=@OldV1+NCHAR(13)+NCHAR(10);
SET @OverText=@V1+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR DATALENGTH(@OverText)<>16777218
 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: Writer-Übergrenzfixture weicht ab.',7;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=0,@LineEnding='CRLF',@ResultTable=N'#CsvExpansionOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: Outputabweisung oder Quell-/Zielerhalt fehlt.',8;
INSERT #CsvExpansionProgress VALUES(4);

GO
-- Fuehrender BOM und quotierte Kontrollcodeeinheiten: Parser genau16MiB.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),0xFFFE)+N','+REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677720)+N'xx',
 @Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'"')+@V1+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV expansion: exakte Inputfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvExpansionCells';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: exakte Parserzellen weichen ab.',2;
INSERT #CsvExpansionProgress VALUES(5);

GO
-- Fuehrender BOM und quotierte Kontrollcodeeinheiten: Writer genau16MiB, vollständige Quell-/Zielbytes.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),0xFFFE)+N','+REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677720)+N'xx',
 @ExpectedText nvarchar(max);
SET @ExpectedText=CONVERT(nvarchar(max),N'"')+@V1+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: Writerfixture weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=0,@LineEnding='CRLF',@ResultTable=N'#CsvExpansionOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: exakter Writer oder Quellerhalt weicht ab.',4;
INSERT #CsvExpansionProgress VALUES(6);

GO
-- Fuehrender BOM und quotierte Kontrollcodeeinheiten: Parser16MiB+2, vorheriges ResultTable erhalten.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),0xFFFE)+N','+REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677720)+N'xx',
 @OverV1 nvarchar(max)=CONVERT(nvarchar(max),0xFFFE)+N','+REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677720)+N'xxx',
 @Text nvarchar(max),@Caught bit=0;
SET @Text=CONVERT(nvarchar(max),N'"')+@OverV1+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV expansion: Plus-zwei-Inputfixture weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvExpansionCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: Inputabweisung oder Zielerhalt fehlt.',6;
INSERT #CsvExpansionProgress VALUES(7);

GO
-- Fuehrender BOM und quotierte Kontrollcodeeinheiten: unabhängig gesetzte Writer-Übergrenzquelle,16MiB+2 Output.
TRUNCATE TABLE #CsvExpansionCells;
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),0xFFFE)+N','+REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677720)+N'xxx',
 @OldV1 nvarchar(max)=CONVERT(nvarchar(max),0xFFFE)+N','+REPLICATE(CONVERT(nvarchar(max),0x000000D8780000DCFFFE),1677720)+N'xx',
 @ExpectedText nvarchar(max),@OverText nvarchar(max),@Caught bit=0;
INSERT #CsvExpansionCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('DATA',1,1,@V1);
SET @ExpectedText=CONVERT(nvarchar(max),N'"')+@OldV1+N'"'+NCHAR(13)+NCHAR(10);
SET @OverText=CONVERT(nvarchar(max),N'"')+@V1+N'"'+NCHAR(13)+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR DATALENGTH(@OverText)<>16777218
 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: Writer-Übergrenzfixture weicht ab.',7;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=0,@LineEnding='CRLF',@ResultTable=N'#CsvExpansionOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1)))) THROW 55396,N'CSV expansion: Outputabweisung oder Quell-/Zielerhalt fehlt.',8;
INSERT #CsvExpansionProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvExpansionProgress);
IF @Cases<>8 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV expansion: Abschlusswitness fehlt.',9;
DROP TABLE #CsvExpansionProgress;
DROP TABLE #CsvExpansionOutput;
DROP TABLE #CsvExpansionCells;
SELECT CONVERT(nvarchar(32),N'CSV_CONTROL_TEXT_CEILINGS') Fixture,CONVERT(int,@Cases) CasesPassed;
