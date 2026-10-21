-- Tatsächliche Input-/Outputtextdecken; keine Heap-, MaxValueBytes- oder Laufzeitzusage.
-- nvarchar-Text hat gerade Bytelängen: kleinstes tatsächliches Darüber ist +2 UTF16-Bytes.
SET NOCOUNT ON;
CREATE TABLE #CsvTextCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvTextOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
CREATE TABLE #CsvTextProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
-- Unquotierter Parserinput genau16MiB.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388608);
IF DATALENGTH(@Value)<>16777216 THROW 55395,N'CSV text: exakte Inputfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Value,@HasHeader=0,@ResultTable=N'#CsvTextCells';
IF (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal=1 AND ColumnOrdinal=1
  AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4
  AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value)
  AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55395,N'CSV text: exakter Parserinhalt weicht ab.',2;
INSERT #CsvTextProgress VALUES(1);

GO
-- Unquotierter Parserinput16MiB+2, vorheriges Ziel vollständig erhalten.
DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388609),@Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388608),@Caught bit=0;
IF DATALENGTH(@Text)<>16777218 THROW 55395,N'CSV text: Plus-zwei-Inputfixture weicht ab.',3;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvTextCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal=1 AND ColumnOrdinal=1
  AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4
  AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value)
  AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55395,N'CSV text: Inputdecke oder Zielerhalt fehlt.',4;
INSERT #CsvTextProgress VALUES(2);

GO
-- Zwei unquotierte Records: globale Ausgabegenau16MiB, beide LF zählen mit.
-- Die globale Quellwertcharge bleibt strikt unter16MiB.
TRUNCATE TABLE #CsvTextCells;
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388605),@ExpectedOutput nvarchar(max);
INSERT #CsvTextCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('DATA',1,1,@Value),('DATA',2,1,N'x');
IF DATALENGTH(@Value)+2>=16777216 OR (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>2
 OR EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal NOT BETWEEN 1 AND 2 OR ColumnOrdinal<>1
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4 OR [Value] IS NULL
  OR DATALENGTH([Value])<>CASE WHEN RowOrdinal=1 THEN DATALENGTH(@Value) ELSE 2 END
  OR CONVERT(varbinary(max),[Value])<>CONVERT(varbinary(max),CASE WHEN RowOrdinal=1 THEN @Value ELSE CONVERT(nvarchar(max),N'x') END))
 THROW 55395,N'CSV text: Writerquelle weicht ab.',5;
SET @ExpectedOutput=@Value+NCHAR(10)+N'x'+NCHAR(10);
IF DATALENGTH(@ExpectedOutput)<>16777216
 THROW 55395,N'CSV text: Outputfixture weicht ab.',6;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvTextCells',@HasHeader=0,@LineEnding='LF',@ResultTable=N'#CsvTextOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvTextOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextOutput WHERE DataRows=2 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedOutput))
 OR (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>2
 OR EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal NOT BETWEEN 1 AND 2 OR ColumnOrdinal<>1
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4 OR [Value] IS NULL
  OR DATALENGTH([Value])<>CASE WHEN RowOrdinal=1 THEN DATALENGTH(@Value) ELSE 2 END
  OR CONVERT(varbinary(max),[Value])<>CONVERT(varbinary(max),CASE WHEN RowOrdinal=1 THEN @Value ELSE CONVERT(nvarchar(max),N'x') END)) THROW 55395,N'CSV text: Outputdecke oder Quell-/Zielerhalt fehlt.',7;
INSERT #CsvTextProgress VALUES(3);

GO
-- Zwei unquotierte Records: globale Ausgabe16MiB+2, beide LF zählen mit.
-- Die globale Quellwertcharge bleibt strikt unter16MiB.
TRUNCATE TABLE #CsvTextCells;
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388606),@ExpectedOutput nvarchar(max),@Caught bit=0;
INSERT #CsvTextCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('DATA',1,1,@Value),('DATA',2,1,N'x');
IF DATALENGTH(@Value)+2>=16777216 OR (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>2
 OR EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal NOT BETWEEN 1 AND 2 OR ColumnOrdinal<>1
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4 OR [Value] IS NULL
  OR DATALENGTH([Value])<>CASE WHEN RowOrdinal=1 THEN DATALENGTH(@Value) ELSE 2 END
  OR CONVERT(varbinary(max),[Value])<>CONVERT(varbinary(max),CASE WHEN RowOrdinal=1 THEN @Value ELSE CONVERT(nvarchar(max),N'x') END))
 THROW 55395,N'CSV text: Writerquelle weicht ab.',5;
SET @ExpectedOutput=REPLICATE(CONVERT(nvarchar(max),N'x'),8388605)+NCHAR(10)+N'x'+NCHAR(10);
IF DATALENGTH(@ExpectedOutput)<>16777216 OR DATALENGTH(@Value+NCHAR(10)+N'x'+NCHAR(10))<>16777218
 THROW 55395,N'CSV text: Outputfixture weicht ab.',6;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvTextCells',@HasHeader=0,@LineEnding='LF',@ResultTable=N'#CsvTextOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvTextOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextOutput WHERE DataRows=2 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedOutput))
 OR (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>2
 OR EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal NOT BETWEEN 1 AND 2 OR ColumnOrdinal<>1
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4 OR [Value] IS NULL
  OR DATALENGTH([Value])<>CASE WHEN RowOrdinal=1 THEN DATALENGTH(@Value) ELSE 2 END
  OR CONVERT(varbinary(max),[Value])<>CONVERT(varbinary(max),CASE WHEN RowOrdinal=1 THEN @Value ELSE CONVERT(nvarchar(max),N'x') END)) THROW 55395,N'CSV text: Outputdecke oder Quell-/Zielerhalt fehlt.',7;
INSERT #CsvTextProgress VALUES(4);

GO
-- Quotierter Parserinput genau16MiB, beide Quotes gehören zum Inputbudget.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388606),@Text nvarchar(max);
SET @Text=CONVERT(nvarchar(max),N'"')+@Value+N'"';
IF DATALENGTH(@Text)<>16777216 THROW 55395,N'CSV text: quotierte Inputfixture weicht ab.',8;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvTextCells';
IF (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal=1 AND ColumnOrdinal=1
  AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4
  AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value)
  AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55395,N'CSV text: quotierter Parserinhalt weicht ab.',9;
INSERT #CsvTextProgress VALUES(5);

GO
-- Quotes allein heben den sonst passenden decodierten Wert über die Inputdecke.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'),8388606),@Text nvarchar(max),@Caught bit=0;
SET @Text=CONVERT(nvarchar(max),N'"')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388607)+N'"';
IF DATALENGTH(@Text)<>16777218 THROW 55395,N'CSV text: quotierte Plus-zwei-Fixture weicht ab.',10;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvTextCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal=1 AND ColumnOrdinal=1
  AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4
  AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value)
  AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55395,N'CSV text: quotierte Inputdecke oder Zielerhalt fehlt.',11;
INSERT #CsvTextProgress VALUES(6);

GO
-- Quotierte Writerausgabegenau16MiB, LF vollständig mitgezählt.
TRUNCATE TABLE #CsvTextCells;
DECLARE @Value nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388604),@ExpectedOutput nvarchar(max);
INSERT #CsvTextCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('DATA',1,1,@Value);
IF (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal=1 AND ColumnOrdinal=1
  AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4
  AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value)
  AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55395,N'CSV text: Writerquelle weicht ab.',5;
SET @ExpectedOutput=CONVERT(nvarchar(max),N'"')+@Value+N'"'+NCHAR(10);
IF DATALENGTH(@ExpectedOutput)<>16777216
 THROW 55395,N'CSV text: Outputfixture weicht ab.',6;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvTextCells',@HasHeader=0,@LineEnding='LF',@ResultTable=N'#CsvTextOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvTextOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216
  AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedOutput))
 OR (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal=1 AND ColumnOrdinal=1
  AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4
  AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value)
  AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55395,N'CSV text: Outputdecke oder Quell-/Zielerhalt fehlt.',7;
INSERT #CsvTextProgress VALUES(7);

GO
-- Quotierte Writerausgabe16MiB+2, LF vollständig mitgezählt.
TRUNCATE TABLE #CsvTextCells;
DECLARE @Value nvarchar(max)=CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388605),@ExpectedOutput nvarchar(max),@Caught bit=0;
INSERT #CsvTextCells(RowKind,RowOrdinal,ColumnOrdinal,[Value]) VALUES('DATA',1,1,@Value);
IF (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal=1 AND ColumnOrdinal=1
  AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4
  AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value)
  AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55395,N'CSV text: Writerquelle weicht ab.',5;
SET @ExpectedOutput=CONVERT(nvarchar(max),N'"')+(CONVERT(nvarchar(max),N',')+REPLICATE(CONVERT(nvarchar(max),N'x'),8388604))+N'"'+NCHAR(10);
IF DATALENGTH(@ExpectedOutput)<>16777216 OR DATALENGTH(CONVERT(nvarchar(max),N'"')+@Value+N'"'+NCHAR(10))<>16777218
 THROW 55395,N'CSV text: Outputfixture weicht ab.',6;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvTextCells',@HasHeader=0,@LineEnding='LF',@ResultTable=N'#CsvTextOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvTextOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextOutput WHERE DataRows=1 AND ColumnCount=1
  AND DATALENGTH(CsvText)=16777216
  AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@ExpectedOutput))
 OR (SELECT COUNT_BIG(*) FROM #CsvTextCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvTextCells WHERE RowOrdinal=1 AND ColumnOrdinal=1
  AND CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4
  AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value)
  AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55395,N'CSV text: Outputdecke oder Quell-/Zielerhalt fehlt.',7;
INSERT #CsvTextProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvTextProgress);
IF @Cases<>8 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55395,N'CSV text: Abschlusswitness fehlt.',12;
DROP TABLE #CsvTextProgress;
DROP TABLE #CsvTextOutput;
DROP TABLE #CsvTextCells;
SELECT CONVERT(nvarchar(32),N'CSV_TEXT_CEILINGS') Fixture,CONVERT(int,@Cases) CasesPassed;
