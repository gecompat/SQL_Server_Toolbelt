-- Tatsächliche Gesamtzelldecke, keine Heap-/Laufzeit- oder Gesamtmatrixzusage.
-- 1000*1000=1000000; 9901*101=1000001. Zeilen/Spalten/Textbytes bleiben unter ihren Grenzen.
SET NOCOUNT ON;
CREATE TABLE #CsvCellCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvCellOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
CREATE TABLE #CsvCellProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
-- PK plus exakte Bereichs-/Gesamtzahlprüfung belegt das vollständige Raster ohne Lücken/Duplikate.
-- Parser an tatsächlicher Gesamtzelldecke ohne Header.
DECLARE @Text nvarchar(max)=REPLICATE(REPLICATE(CONVERT(nvarchar(max),N'x,'),999)+N'x'+NCHAR(10),1000);
IF DATALENGTH(@Text)<>4000000 THROW 55394,N'CSV cells: exakte Fixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvCellCells';
IF (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000000
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 1 AND 1000 OR ColumnOrdinal NOT BETWEEN 1 AND 1000
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55394,N'CSV cells: exakte Parserzellen weichen ab.',2;
INSERT #CsvCellProgress VALUES(1);

GO
-- Writer muss alle Zellen ohne Header bytegenau und read-only ausgeben.
DECLARE @Expected nvarchar(max)=REPLICATE(REPLICATE(CONVERT(nvarchar(max),N'x,'),999)+N'x'+NCHAR(10),1000);
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCellCells',@HasHeader=0,@LineEnding='LF',@ResultTable=N'#CsvCellOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvCellOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvCellOutput WHERE DataRows=1000 AND ColumnCount=1000
  AND DATALENGTH(CsvText)=4000000 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 OR (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000000
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 1 AND 1000 OR ColumnOrdinal NOT BETWEEN 1 AND 1000
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55394,N'CSV cells: exakter Writer oder Quellerhalt weicht ab.',3;
INSERT #CsvCellProgress VALUES(2);

GO
-- Genau eine zusätzliche Zelle in einem weiterhin vollständigen Rechteck ohne Header.
DECLARE @Text nvarchar(max)=REPLICATE(REPLICATE(CONVERT(nvarchar(max),N'x,'),100)+N'x'+NCHAR(10),9901),@Caught bit=0;
IF DATALENGTH(@Text)<>4000004 THROW 55394,N'CSV cells: Plus-eins-Fixture weicht ab.',4;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=0,@ResultTable=N'#CsvCellCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000000
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 1 AND 1000 OR ColumnOrdinal NOT BETWEEN 1 AND 1000
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55394,N'CSV cells: Parser-Zelldecke oder atomarer Zielerhalt fehlt.',5;
INSERT #CsvCellProgress VALUES(3);

GO
-- Unabhängige synthetische Writerquelle mit genau1000001 eindeutigen Zellen.
TRUNCATE TABLE #CsvCellCells;
;WITH d(n) AS(SELECT n FROM(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))v(n)),
r AS(SELECT 1+a.n+10*b.n+100*c.n+1000*e.n RecordNo FROM d a CROSS JOIN d b CROSS JOIN d c CROSS JOIN d e),
c AS(SELECT 1+a.n+10*b.n+100*e.n ColumnNo FROM d a CROSS JOIN d b CROSS JOIN d e)
INSERT #CsvCellCells(RowKind,RowOrdinal,ColumnOrdinal,[Value])
SELECT CASE WHEN 0=1 AND r.RecordNo=1 THEN 'HEADER' ELSE 'DATA' END,r.RecordNo-0,c.ColumnNo,N'x'
FROM r CROSS JOIN c WHERE r.RecordNo<=9901 AND c.ColumnNo<=101;
IF (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000001
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 1 AND 9901 OR ColumnOrdinal NOT BETWEEN 1 AND 101
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800) THROW 55394,N'CSV cells: Writer-Plus-eins-Quelle weicht ab.',6;
DECLARE @Expected nvarchar(max)=REPLICATE(REPLICATE(CONVERT(nvarchar(max),N'x,'),999)+N'x'+NCHAR(10),1000),@Caught bit=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCellCells',@HasHeader=0,@LineEnding='LF',@ResultTable=N'#CsvCellOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvCellOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvCellOutput WHERE DataRows=1000 AND ColumnCount=1000
  AND DATALENGTH(CsvText)=4000000 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 OR (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000001
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 1 AND 9901 OR ColumnOrdinal NOT BETWEEN 1 AND 101
  OR CONVERT(varbinary(max),RowKind)<>0x44415441 OR DATALENGTH(RowKind)<>4
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55394,N'CSV cells: Writer-Zelldecke oder Quell-/Zielerhalt fehlt.',7;
INSERT #CsvCellProgress VALUES(4);

GO
-- Parser an tatsächlicher Gesamtzelldecke mit Header.
DECLARE @Text nvarchar(max)=REPLICATE(REPLICATE(CONVERT(nvarchar(max),N'x,'),999)+N'x'+NCHAR(10),1000);
IF DATALENGTH(@Text)<>4000000 THROW 55394,N'CSV cells: exakte Fixture weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=1,@ResultTable=N'#CsvCellCells';
IF (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000000
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 0 AND 999 OR ColumnOrdinal NOT BETWEEN 1 AND 1000
  OR CONVERT(varbinary(max),RowKind)<>CASE WHEN RowOrdinal=0 THEN 0x484541444552 ELSE 0x44415441 END
  OR DATALENGTH(RowKind)<>CASE WHEN RowOrdinal=0 THEN 6 ELSE 4 END
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55394,N'CSV cells: exakte Parserzellen weichen ab.',2;
INSERT #CsvCellProgress VALUES(5);

GO
-- Writer muss alle Zellen mit Header bytegenau und read-only ausgeben.
DECLARE @Expected nvarchar(max)=REPLICATE(REPLICATE(CONVERT(nvarchar(max),N'x,'),999)+N'x'+NCHAR(10),1000);
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCellCells',@HasHeader=1,@LineEnding='LF',@ResultTable=N'#CsvCellOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvCellOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvCellOutput WHERE DataRows=999 AND ColumnCount=1000
  AND DATALENGTH(CsvText)=4000000 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 OR (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000000
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 0 AND 999 OR ColumnOrdinal NOT BETWEEN 1 AND 1000
  OR CONVERT(varbinary(max),RowKind)<>CASE WHEN RowOrdinal=0 THEN 0x484541444552 ELSE 0x44415441 END
  OR DATALENGTH(RowKind)<>CASE WHEN RowOrdinal=0 THEN 6 ELSE 4 END
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55394,N'CSV cells: exakter Writer oder Quellerhalt weicht ab.',3;
INSERT #CsvCellProgress VALUES(6);

GO
-- Genau eine zusätzliche Zelle in einem weiterhin vollständigen Rechteck mit Header.
DECLARE @Text nvarchar(max)=REPLICATE(REPLICATE(CONVERT(nvarchar(max),N'x,'),100)+N'x'+NCHAR(10),9901),@Caught bit=0;
IF DATALENGTH(@Text)<>4000004 THROW 55394,N'CSV cells: Plus-eins-Fixture weicht ab.',4;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=1,@ResultTable=N'#CsvCellCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000000
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 0 AND 999 OR ColumnOrdinal NOT BETWEEN 1 AND 1000
  OR CONVERT(varbinary(max),RowKind)<>CASE WHEN RowOrdinal=0 THEN 0x484541444552 ELSE 0x44415441 END
  OR DATALENGTH(RowKind)<>CASE WHEN RowOrdinal=0 THEN 6 ELSE 4 END
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55394,N'CSV cells: Parser-Zelldecke oder atomarer Zielerhalt fehlt.',5;
INSERT #CsvCellProgress VALUES(7);

GO
-- Unabhängige synthetische Writerquelle mit genau1000001 eindeutigen Zellen.
TRUNCATE TABLE #CsvCellCells;
;WITH d(n) AS(SELECT n FROM(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))v(n)),
r AS(SELECT 1+a.n+10*b.n+100*c.n+1000*e.n RecordNo FROM d a CROSS JOIN d b CROSS JOIN d c CROSS JOIN d e),
c AS(SELECT 1+a.n+10*b.n+100*e.n ColumnNo FROM d a CROSS JOIN d b CROSS JOIN d e)
INSERT #CsvCellCells(RowKind,RowOrdinal,ColumnOrdinal,[Value])
SELECT CASE WHEN 1=1 AND r.RecordNo=1 THEN 'HEADER' ELSE 'DATA' END,r.RecordNo-1,c.ColumnNo,N'x'
FROM r CROSS JOIN c WHERE r.RecordNo<=9901 AND c.ColumnNo<=101;
IF (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000001
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 0 AND 9900 OR ColumnOrdinal NOT BETWEEN 1 AND 101
  OR CONVERT(varbinary(max),RowKind)<>CASE WHEN RowOrdinal=0 THEN 0x484541444552 ELSE 0x44415441 END
  OR DATALENGTH(RowKind)<>CASE WHEN RowOrdinal=0 THEN 6 ELSE 4 END
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800) THROW 55394,N'CSV cells: Writer-Plus-eins-Quelle weicht ab.',6;
DECLARE @Expected nvarchar(max)=REPLICATE(REPLICATE(CONVERT(nvarchar(max),N'x,'),999)+N'x'+NCHAR(10),1000),@Caught bit=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvCellCells',@HasHeader=1,@LineEnding='LF',@ResultTable=N'#CsvCellOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvCellOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvCellOutput WHERE DataRows=999 AND ColumnCount=1000
  AND DATALENGTH(CsvText)=4000000 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected))
 OR (SELECT COUNT_BIG(*) FROM #CsvCellCells)<>1000001
 OR EXISTS(SELECT 1 FROM #CsvCellCells WHERE RowOrdinal NOT BETWEEN 0 AND 9900 OR ColumnOrdinal NOT BETWEEN 1 AND 101
  OR CONVERT(varbinary(max),RowKind)<>CASE WHEN RowOrdinal=0 THEN 0x484541444552 ELSE 0x44415441 END
  OR DATALENGTH(RowKind)<>CASE WHEN RowOrdinal=0 THEN 6 ELSE 4 END
  OR [Value] IS NULL OR DATALENGTH([Value])<>2 OR CONVERT(varbinary(max),[Value])<>0x7800)
 THROW 55394,N'CSV cells: Writer-Zelldecke oder Quell-/Zielerhalt fehlt.',7;
INSERT #CsvCellProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvCellProgress);
IF @Cases<>8 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55394,N'CSV cells: Abschlusswitness fehlt.',8;
DROP TABLE #CsvCellProgress;
DROP TABLE #CsvCellOutput;
DROP TABLE #CsvCellCells;
SELECT CONVERT(nvarchar(32),N'CSV_CELL_CEILINGS') Fixture,CONVERT(int,@Cases) CasesPassed;
