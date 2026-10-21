-- Synthetische tatsächliche Zeilen-/Spaltendecken; keine Heap- oder Laufzeitzusage.
-- Acht getrennte Phasen mit begrenztem Kommandotimeout und gemeinsamem Abschlusswitness.
SET NOCOUNT ON;
CREATE TABLE #CsvShapeCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
CREATE TABLE #CsvShapeOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
CREATE TABLE #CsvShapeProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
DECLARE @Text nvarchar(max);

-- Die Defaults bleiben unberührt: genau 100000 DATA-Records, eine Spalte.
SET @Text=REPLICATE(CONVERT(nvarchar(max),N'x'+NCHAR(10)),100000);
IF DATALENGTH(@Text)<>400000 THROW 55393,N'CSV shape: synthetische Zeilenfixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@ResultTable=N'#CsvShapeCells';
IF (SELECT COUNT_BIG(*) FROM #CsvShapeCells)<>100000
 OR (SELECT COUNT_BIG(DISTINCT RowOrdinal) FROM #CsvShapeCells)<>100000
 OR EXISTS(SELECT 1 FROM #CsvShapeCells WHERE RowOrdinal NOT BETWEEN 1 AND 100000 OR ColumnOrdinal<>1
  OR DATALENGTH(RowKind)<>4 OR CONVERT(varbinary(max),RowKind)<>0x44415441
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55393,N'CSV shape: Parser an tatsächlicher Zeilendecke weicht ab.',2;
INSERT #CsvShapeProgress VALUES(1);
GO
DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'+NCHAR(10)),100000);

EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvShapeCells',@LineEnding='LF',@ResultTable=N'#CsvShapeOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvShapeOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvShapeOutput WHERE DataRows=100000 AND ColumnCount=1
  AND DATALENGTH(CsvText)=400000 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Text))
 THROW 55393,N'CSV shape: Writer an tatsächlicher Zeilendecke weicht ab.',3;
INSERT #CsvShapeProgress VALUES(2);
GO



-- Ein zusätzlicher echter Record, kein erhöhter Budgetparameter; Ziel bleibt exakt.
DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x'+NCHAR(10)),100001),@Caught bit;
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@ResultTable=N'#CsvShapeCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvShapeCells)<>100000
 OR (SELECT COUNT_BIG(DISTINCT RowOrdinal) FROM #CsvShapeCells)<>100000
 OR EXISTS(SELECT 1 FROM #CsvShapeCells WHERE RowOrdinal NOT BETWEEN 1 AND 100000 OR ColumnOrdinal<>1
  OR DATALENGTH(RowKind)<>4 OR CONVERT(varbinary(max),RowKind)<>0x44415441
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55393,N'CSV shape: Parser-Zeilendecke oder atomarer Zielerhalt fehlt.',4;
INSERT #CsvShapeProgress VALUES(3);
GO
DECLARE @Caught bit,@Expected nvarchar(max);

INSERT #CsvShapeCells VALUES('DATA',100001,1,N'x');
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvShapeCells',@LineEnding='LF',@ResultTable=N'#CsvShapeOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
SET @Expected=REPLICATE(CONVERT(nvarchar(max),N'x'+NCHAR(10)),100000);
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvShapeOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvShapeOutput WHERE DataRows=100000 AND ColumnCount=1
  AND DATALENGTH(CsvText)=400000 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 OR (SELECT COUNT_BIG(*) FROM #CsvShapeCells)<>100001
 OR (SELECT COUNT_BIG(DISTINCT RowOrdinal) FROM #CsvShapeCells)<>100001
 OR EXISTS(SELECT 1 FROM #CsvShapeCells WHERE RowOrdinal NOT BETWEEN 1 AND 100001 OR ColumnOrdinal<>1
  OR DATALENGTH(RowKind)<>4 OR CONVERT(varbinary(max),RowKind)<>0x44415441
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55393,N'CSV shape: Writer-Zeilendecke oder Quell-/Zielerhalt fehlt.',5;
INSERT #CsvShapeProgress VALUES(4);
GO



-- Genau 1024 Spalten in einem DATA-Record; keine leere zusätzliche Spalte.
DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x,'),1023)+N'x';
IF DATALENGTH(@Text)<>4094 THROW 55393,N'CSV shape: synthetische Spaltenfixture weicht ab.',6;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@ResultTable=N'#CsvShapeCells';
IF (SELECT COUNT_BIG(*) FROM #CsvShapeCells)<>1024
 OR (SELECT COUNT(DISTINCT ColumnOrdinal) FROM #CsvShapeCells)<>1024
 OR EXISTS(SELECT 1 FROM #CsvShapeCells WHERE RowOrdinal<>1 OR ColumnOrdinal NOT BETWEEN 1 AND 1024
  OR DATALENGTH(RowKind)<>4 OR CONVERT(varbinary(max),RowKind)<>0x44415441
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55393,N'CSV shape: Parser an tatsächlicher Spaltendecke weicht ab.',7;
INSERT #CsvShapeProgress VALUES(5);
GO
DECLARE @Expected nvarchar(max);

EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvShapeCells',@LineEnding='LF',@ResultTable=N'#CsvShapeOutput';
SET @Expected=REPLICATE(CONVERT(nvarchar(max),N'x,'),1023)+N'x'+NCHAR(10);
IF (SELECT COUNT_BIG(*) FROM #CsvShapeOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvShapeOutput WHERE DataRows=1 AND ColumnCount=1024
  AND DATALENGTH(CsvText)=4096 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 THROW 55393,N'CSV shape: Writer an tatsächlicher Spaltendecke weicht ab.',8;
INSERT #CsvShapeProgress VALUES(6);
GO


DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x,'),1024)+N'x',@Caught bit;
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@ResultTable=N'#CsvShapeCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvShapeCells)<>1024
 OR (SELECT COUNT(DISTINCT ColumnOrdinal) FROM #CsvShapeCells)<>1024
 OR EXISTS(SELECT 1 FROM #CsvShapeCells WHERE RowOrdinal<>1 OR ColumnOrdinal NOT BETWEEN 1 AND 1024
  OR DATALENGTH(RowKind)<>4 OR CONVERT(varbinary(max),RowKind)<>0x44415441
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55393,N'CSV shape: Parser-Spaltendecke oder atomarer Zielerhalt fehlt.',9;
INSERT #CsvShapeProgress VALUES(7);
GO
DECLARE @Caught bit,@Expected nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'x,'),1023)+N'x'+NCHAR(10);

INSERT #CsvShapeCells VALUES('DATA',1,1025,N'x');
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvShapeCells',@LineEnding='LF',@ResultTable=N'#CsvShapeOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvShapeOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvShapeOutput WHERE DataRows=1 AND ColumnCount=1024
  AND DATALENGTH(CsvText)=4096 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 OR (SELECT COUNT_BIG(*) FROM #CsvShapeCells)<>1025
 OR (SELECT COUNT(DISTINCT ColumnOrdinal) FROM #CsvShapeCells)<>1025
 OR EXISTS(SELECT 1 FROM #CsvShapeCells WHERE RowOrdinal<>1 OR ColumnOrdinal NOT BETWEEN 1 AND 1025
  OR DATALENGTH(RowKind)<>4 OR CONVERT(varbinary(max),RowKind)<>0x44415441
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55393,N'CSV shape: Writer-Spaltendecke oder Quell-/Zielerhalt fehlt.',10;
INSERT #CsvShapeProgress VALUES(8);

DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvShapeProgress);
IF @Cases<>8 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55393,N'CSV shape: Abschlusswitness fehlt.',11;
DROP TABLE #CsvShapeProgress;
DROP TABLE #CsvShapeOutput;
DROP TABLE #CsvShapeCells;
SELECT CONVERT(nvarchar(32),N'CSV_SHAPE_CEILINGS') Fixture,CONVERT(int,@Cases) CasesPassed;
