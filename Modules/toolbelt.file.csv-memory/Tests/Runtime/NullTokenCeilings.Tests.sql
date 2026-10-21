-- Tatsächliche vollständige Input-/Outputtextbytes; keine Heap-/Laufzeitzusage.
-- Kleinste UTF16-Überschreitung ist +2 Bytes. Writerwertsumme bleibt strikt unter16MiB.
SET NOCOUNT ON;
CREATE TABLE #CsvExpansionCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvExpansionOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
CREATE TABLE #CsvExpansionProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
-- NullTokenexpansion in zwei Spalten: Parser genau16MiB.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @V2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388478),
 @Token nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @Text nvarchar(max);
SET @Text=@Token+N','+@V2+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV expansion: exakte Inputfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@NullToken=@Token,@ResultTable=N'#CsvExpansionCells';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: exakte Parserzellen weichen ab.',2;
INSERT #CsvExpansionProgress VALUES(1);

GO
-- NullTokenexpansion in zwei Spalten: Writer genau16MiB, vollständige Quell-/Zielbytes.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @V2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388478),
 @Token nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @ExpectedText nvarchar(max);
SET @ExpectedText=@Token+N','+@V2+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Writerfixture weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=0,@NullToken=@Token,@LineEnding='LF',@ResultTable=N'#CsvExpansionOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=2
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: exakter Writer oder Quellerhalt weicht ab.',4;
INSERT #CsvExpansionProgress VALUES(2);

GO
-- NullTokenexpansion in zwei Spalten: Parser16MiB+2, vorheriges ResultTable erhalten.
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @V2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388478),
 @OverV1 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @OverV2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388479),
 @Token nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @Text nvarchar(max),@Caught bit=0;
SET @Text=@Token+N','+@OverV2+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV expansion: Plus-zwei-Inputfixture weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@NullToken=@Token,@ResultTable=N'#CsvExpansionCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Inputabweisung oder Zielerhalt fehlt.',6;
INSERT #CsvExpansionProgress VALUES(3);

GO
-- NullTokenexpansion in zwei Spalten: unabhängig gesetzte Writer-Übergrenzquelle,16MiB+2 Output.
TRUNCATE TABLE #CsvExpansionCells;
DECLARE @V1 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @V2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388479),
 @OldV1 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @OldV2 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388478),
 @Token nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @ExpectedText nvarchar(max),@OverText nvarchar(max),@Caught bit=0;
INSERT #CsvExpansionCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('DATA',1,1,@V1),('DATA',1,2,@V2);
SET @ExpectedText=@Token+N','+@OldV2+NCHAR(10);
SET @OverText=@Token+N','+@V2+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR DATALENGTH(@OverText)<>16777218
 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Writer-Übergrenzfixture weicht ab.',7;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=0,@NullToken=@Token,@LineEnding='LF',@ResultTable=N'#CsvExpansionOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=2
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>2
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2)))) THROW 55396,N'CSV expansion: Outputabweisung oder Quell-/Zielerhalt fehlt.',8;
INSERT #CsvExpansionProgress VALUES(4);

GO
-- Quotierte Tokenkollision und SQL-NULL: Parser genau16MiB.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @V2 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @V3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388347),
 @Token nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'"')+@V1+N'",'+@Token+N','+@V3+NCHAR(10);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV expansion: exakte Inputfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@NullToken=@Token,@ResultTable=N'#CsvExpansionCells';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=3 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV expansion: exakte Parserzellen weichen ab.',2;
INSERT #CsvExpansionProgress VALUES(5);

GO
-- Quotierte Tokenkollision und SQL-NULL: Writer genau16MiB, vollständige Quell-/Zielbytes.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @V2 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @V3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388347),
 @Token nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @ExpectedText nvarchar(max);
SET @ExpectedText=CONVERT(nvarchar(max),N'"')+@V1+N'",'+@Token+N','+@V3+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=3 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV expansion: Writerfixture weicht ab.',3;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=0,@NullToken=@Token,@LineEnding='LF',@ResultTable=N'#CsvExpansionOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=3
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=3 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV expansion: exakter Writer oder Quellerhalt weicht ab.',4;
INSERT #CsvExpansionProgress VALUES(6);

GO
-- Quotierte Tokenkollision und SQL-NULL: Parser16MiB+2, vorheriges ResultTable erhalten.
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @V2 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @V3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388347),
 @OverV1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @OverV2 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @OverV3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388348),
 @Token nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @Text nvarchar(max),@Caught bit=0;
SET @Text=CONVERT(nvarchar(max),N'"')+@OverV1+N'",'+@Token+N','+@OverV3+NCHAR(10);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV expansion: Plus-zwei-Inputfixture weicht ab.',5;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@NullToken=@Token,@ResultTable=N'#CsvExpansionCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=3 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV expansion: Inputabweisung oder Zielerhalt fehlt.',6;
INSERT #CsvExpansionProgress VALUES(7);

GO
-- Quotierte Tokenkollision und SQL-NULL: unabhängig gesetzte Writer-Übergrenzquelle,16MiB+2 Output.
TRUNCATE TABLE #CsvExpansionCells;
DECLARE @V1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @V2 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @V3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388348),
 @OldV1 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @OldV2 nvarchar(max)=CONVERT(nvarchar(max),NULL),
 @OldV3 nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388347),
 @Token nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'null'),32),
 @ExpectedText nvarchar(max),@OverText nvarchar(max),@Caught bit=0;
INSERT #CsvExpansionCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('DATA',1,1,@V1),('DATA',1,2,@V2),('DATA',1,3,@V3);
SET @ExpectedText=CONVERT(nvarchar(max),N'"')+@OldV1+N'",'+@Token+N','+@OldV3+NCHAR(10);
SET @OverText=CONVERT(nvarchar(max),N'"')+@V1+N'",'+@Token+N','+@V3+NCHAR(10);
IF DATALENGTH(@ExpectedText)<>16777216 OR DATALENGTH(@OverText)<>16777218
 OR (SELECT SUM(CONVERT(bigint,COALESCE(DATALENGTH([Value]),0))) FROM #CsvExpansionCells)>=16777216
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=3 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV expansion: Writer-Übergrenzfixture weicht ab.',7;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvExpansionCells',@HasHeader=0,@NullToken=@Token,@LineEnding='LF',@ResultTable=N'#CsvExpansionOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionOutput WHERE DataRows=1 AND ColumnCount=3
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedText))
 OR (SELECT COUNT_BIG(*) FROM #CsvExpansionCells)<>3
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V1 IS NULL AND [Value] IS NULL) OR (@V1 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V1) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V1))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=2 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V2 IS NULL AND [Value] IS NULL) OR (@V2 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V2) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V2))))
 OR NOT EXISTS(SELECT 1 FROM #CsvExpansionCells WHERE RowOrdinal=1 AND ColumnOrdinal=3 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND ((@V3 IS NULL AND [Value] IS NULL) OR (@V3 IS NOT NULL AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@V3) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@V3)))) THROW 55396,N'CSV expansion: Outputabweisung oder Quell-/Zielerhalt fehlt.',8;
INSERT #CsvExpansionProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvExpansionProgress);
IF @Cases<>8 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV expansion: Abschlusswitness fehlt.',9;
DROP TABLE #CsvExpansionProgress;
DROP TABLE #CsvExpansionOutput;
DROP TABLE #CsvExpansionCells;
SELECT CONVERT(nvarchar(32),N'CSV_NULL_TOKEN_CEILINGS') Fixture,CONVERT(int,@Cases) CasesPassed;
