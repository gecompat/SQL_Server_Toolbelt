-- Synthetische volle Callerziele; committable Callertransaktion mit XACT_ABORT OFF.
-- Der Aufrufer entscheidet selbst ueber COMMIT/ROLLBACK; keine Heap- oder TLSzusage.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: neutraler Start fehlt.',4;
CREATE TABLE #CsvTxnBaseline(OriginalOptions int NOT NULL,CellsId int NULL,SourceId int NULL,OutputId int NULL);
INSERT #CsvTxnBaseline(OriginalOptions) VALUES(@@OPTIONS);
SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE #CsvTxnCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvTxnSource(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvTxnOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
CREATE TABLE #CsvCallerSentinel(Id int NOT NULL PRIMARY KEY,[Value] int NOT NULL);
CREATE TABLE #CsvTxnProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
UPDATE #CsvTxnBaseline SET CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells'),SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource'),OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput');
INSERT #CsvCallerSentinel VALUES(1,100);
INSERT #CsvTxnCells VALUES('DATA',1,1,REPLICATE(CONVERT(nvarchar(max),N'p'),8388608));
INSERT #CsvTxnOutput VALUES(REPLICATE(CONVERT(nvarchar(max),N'o'),8388606)+NCHAR(13)+NCHAR(10),1,1);
-- Fall 1: Parser16MiB-Erfolg, Caller ROLLBACK.
DECLARE @Caught bit=0,@OldCell nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'p'),8388608),@OldOutput nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'o'),8388606)+NCHAR(13)+NCHAR(10);
DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV caller transaction: Parserfixture weicht ab.',6;
DECLARE @Before nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'p'),8388608);
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Before) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Before)) THROW 55396,N'CSV caller transaction: Parserbaseline weicht ab.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
BEGIN TRANSACTION;
UPDATE #CsvCallerSentinel SET [Value]=11 WHERE Id=1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@KeepData=0,@ResultTable=N'#CsvTxnCells';
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=11) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Text) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Text)) THROW 55396,N'CSV caller transaction: voller Parserzielwert weicht ab.',8;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
ROLLBACK TRANSACTION;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=100) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Before) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Before)) THROW 55396,N'CSV caller transaction: Parserrollback verlor Baseline.',12;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
UPDATE #CsvCallerSentinel SET [Value]=100 WHERE Id=1;
INSERT #CsvTxnProgress VALUES(1);

GO
-- Fall 2: Parser16MiB+2-Abweisung, Caller ROLLBACK.
DECLARE @Caught bit=0,@OldCell nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'p'),8388608),@OldOutput nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'o'),8388606)+NCHAR(13)+NCHAR(10);
DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'd'),8388609);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV caller transaction: Parserfixture weicht ab.',6;
DECLARE @Before nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'p'),8388608);
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Before) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Before)) THROW 55396,N'CSV caller transaction: Parserbaseline weicht ab.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
BEGIN TRANSACTION;
UPDATE #CsvCallerSentinel SET [Value]=12 WHERE Id=1;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@KeepData=0,@ResultTable=N'#CsvTxnCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV caller transaction: erwartete Budgetabweisung fehlt.',5;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=12) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@OldCell) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@OldCell)) THROW 55396,N'CSV caller transaction: voller Parserzielwert weicht ab.',8;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
ROLLBACK TRANSACTION;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=100) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Before) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Before)) THROW 55396,N'CSV caller transaction: Parserrollback verlor Baseline.',12;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
UPDATE #CsvCallerSentinel SET [Value]=100 WHERE Id=1;
INSERT #CsvTxnProgress VALUES(2);

GO
-- Fall 3: Writer16MiB-Erfolg, Caller ROLLBACK.
DECLARE @Caught bit=0,@OldCell nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'p'),8388608),@OldOutput nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'o'),8388606)+NCHAR(13)+NCHAR(10);
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),@Expected nvarchar(max);
SET @Expected=@Value+NCHAR(13)+NCHAR(10);
TRUNCATE TABLE #CsvTxnSource;
INSERT #CsvTxnSource VALUES('DATA',1,1,@Value);
IF DATALENGTH(@Expected)<>16777216 OR DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV caller transaction: Writerfixture weicht ab.',9;
DECLARE @Before nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'o'),8388606)+NCHAR(13)+NCHAR(10);
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Before)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: Writerbaseline weicht ab.',10;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
BEGIN TRANSACTION;
UPDATE #CsvCallerSentinel SET [Value]=13 WHERE Id=1;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvTxnSource',@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#CsvTxnOutput';
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=13) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: voller Output oder Quellwert weicht ab.',11;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
ROLLBACK TRANSACTION;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=100) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Before)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: Writerrollback verlor Baseline oder Quelle.',13;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
UPDATE #CsvCallerSentinel SET [Value]=100 WHERE Id=1;
INSERT #CsvTxnProgress VALUES(3);

GO
-- Fall 4: Writer16MiB+2-Abweisung, Caller ROLLBACK.
DECLARE @Caught bit=0,@OldCell nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'p'),8388608),@OldOutput nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'o'),8388606)+NCHAR(13)+NCHAR(10);
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388607),@Expected nvarchar(max);
SET @Expected=@Value+NCHAR(13)+NCHAR(10);
TRUNCATE TABLE #CsvTxnSource;
INSERT #CsvTxnSource VALUES('DATA',1,1,@Value);
IF DATALENGTH(@Expected)<>16777218 OR DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV caller transaction: Writerfixture weicht ab.',9;
DECLARE @Before nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'o'),8388606)+NCHAR(13)+NCHAR(10);
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Before)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: Writerbaseline weicht ab.',10;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
BEGIN TRANSACTION;
UPDATE #CsvCallerSentinel SET [Value]=14 WHERE Id=1;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvTxnSource',@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#CsvTxnOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV caller transaction: erwartete Budgetabweisung fehlt.',5;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=14) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OldOutput)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: voller Output oder Quellwert weicht ab.',11;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
ROLLBACK TRANSACTION;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=100) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Before)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: Writerrollback verlor Baseline oder Quelle.',13;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
UPDATE #CsvCallerSentinel SET [Value]=100 WHERE Id=1;
INSERT #CsvTxnProgress VALUES(4);

GO
-- Fall 5: Parser16MiB-Erfolg, Caller COMMIT.
DECLARE @Caught bit=0,@OldCell nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388608),@OldOutput nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'e'),8388606)+NCHAR(13)+NCHAR(10);
DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388608);
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV caller transaction: Parserfixture weicht ab.',6;
DECLARE @Before nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'p'),8388608);
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Before) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Before)) THROW 55396,N'CSV caller transaction: Parserbaseline weicht ab.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
BEGIN TRANSACTION;
UPDATE #CsvCallerSentinel SET [Value]=15 WHERE Id=1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@KeepData=0,@ResultTable=N'#CsvTxnCells';
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=15) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Text) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Text)) THROW 55396,N'CSV caller transaction: voller Parserzielwert weicht ab.',8;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
COMMIT TRANSACTION;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=15) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Text) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Text)) THROW 55396,N'CSV caller transaction: voller Parserzielwert weicht ab.',8;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
UPDATE #CsvCallerSentinel SET [Value]=100 WHERE Id=1;
INSERT #CsvTxnProgress VALUES(5);

GO
-- Fall 6: Parser16MiB+2-Abweisung, Caller COMMIT.
DECLARE @Caught bit=0,@OldCell nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388608),@OldOutput nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'e'),8388606)+NCHAR(13)+NCHAR(10);
DECLARE @Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'f'),8388609);
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV caller transaction: Parserfixture weicht ab.',6;
DECLARE @Before nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388608);
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Before) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Before)) THROW 55396,N'CSV caller transaction: Parserbaseline weicht ab.',7;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
BEGIN TRANSACTION;
UPDATE #CsvCallerSentinel SET [Value]=16 WHERE Id=1;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@KeepData=0,@ResultTable=N'#CsvTxnCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV caller transaction: erwartete Budgetabweisung fehlt.',5;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=16) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@OldCell) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@OldCell)) THROW 55396,N'CSV caller transaction: voller Parserzielwert weicht ab.',8;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
COMMIT TRANSACTION;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=16) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnCells WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@OldCell) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@OldCell)) THROW 55396,N'CSV caller transaction: voller Parserzielwert weicht ab.',8;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
UPDATE #CsvCallerSentinel SET [Value]=100 WHERE Id=1;
INSERT #CsvTxnProgress VALUES(6);

GO
-- Fall 7: Writer16MiB-Erfolg, Caller COMMIT.
DECLARE @Caught bit=0,@OldCell nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388608),@OldOutput nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'e'),8388606)+NCHAR(13)+NCHAR(10);
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'e'),8388606),@Expected nvarchar(max);
SET @Expected=@Value+NCHAR(13)+NCHAR(10);
TRUNCATE TABLE #CsvTxnSource;
INSERT #CsvTxnSource VALUES('DATA',1,1,@Value);
IF DATALENGTH(@Expected)<>16777216 OR DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV caller transaction: Writerfixture weicht ab.',9;
DECLARE @Before nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'o'),8388606)+NCHAR(13)+NCHAR(10);
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Before)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: Writerbaseline weicht ab.',10;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
BEGIN TRANSACTION;
UPDATE #CsvCallerSentinel SET [Value]=17 WHERE Id=1;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvTxnSource',@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#CsvTxnOutput';
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=17) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: voller Output oder Quellwert weicht ab.',11;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
COMMIT TRANSACTION;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=17) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: voller Output oder Quellwert weicht ab.',11;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
UPDATE #CsvCallerSentinel SET [Value]=100 WHERE Id=1;
INSERT #CsvTxnProgress VALUES(7);

GO
-- Fall 8: Writer16MiB+2-Abweisung, Caller COMMIT.
DECLARE @Caught bit=0,@OldCell nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388608),@OldOutput nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'e'),8388606)+NCHAR(13)+NCHAR(10);
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'g'),8388607),@Expected nvarchar(max);
SET @Expected=@Value+NCHAR(13)+NCHAR(10);
TRUNCATE TABLE #CsvTxnSource;
INSERT #CsvTxnSource VALUES('DATA',1,1,@Value);
IF DATALENGTH(@Expected)<>16777218 OR DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV caller transaction: Writerfixture weicht ab.',9;
DECLARE @Before nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'e'),8388606)+NCHAR(13)+NCHAR(10);
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Before)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: Writerbaseline weicht ab.',10;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
BEGIN TRANSACTION;
UPDATE #CsvCallerSentinel SET [Value]=18 WHERE Id=1;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvTxnSource',@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#CsvTxnOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught<>1 THROW 55396,N'CSV caller transaction: erwartete Budgetabweisung fehlt.',5;
IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=18) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OldOutput)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: voller Output oder Quellwert weicht ab.',11;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
COMMIT TRANSACTION;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: Transaktionszustand weicht ab.',1;
IF (SELECT COUNT_BIG(*) FROM #CsvCallerSentinel)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvCallerSentinel WHERE Id=1 AND [Value]=18) THROW 55396,N'CSV caller transaction: Callerarbeit ging verloren.',2;
IF (SELECT COUNT_BIG(*) FROM #CsvTxnOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OldOutput)) OR (SELECT COUNT_BIG(*) FROM #CsvTxnSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvTxnSource WHERE RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH(RowKind)=4 AND CONVERT(varbinary(max),RowKind)=0x44415441 AND [Value] IS NOT NULL AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV caller transaction: voller Output oder Quellwert weicht ab.',11;
IF NOT EXISTS(SELECT 1 FROM #CsvTxnBaseline WHERE CellsId=OBJECT_ID(N'tempdb..#CsvTxnCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvTxnSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvTxnOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvTxnOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvTxnCells'),OBJECT_ID(N'tempdb..#CsvTxnSource')) AND type='PK')<>2
 THROW 55396,N'CSV caller transaction: Calleridentitaet oder Schluessel ging verloren.',3;
UPDATE #CsvCallerSentinel SET [Value]=100 WHERE Id=1;
INSERT #CsvTxnProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvTxnProgress),@OriginalOptions int=(SELECT OriginalOptions FROM #CsvTxnBaseline);
IF @Cases<>8 THROW 55396,N'CSV caller transaction: Phasenwitness fehlt.',14;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV caller transaction: neutraler Abschluss fehlt.',15;
IF (@OriginalOptions & 16384)=16384 SET XACT_ABORT ON; ELSE SET XACT_ABORT OFF;
IF (@@OPTIONS & 16384)<>(@OriginalOptions & 16384) THROW 55396,N'CSV caller transaction: XACT_ABORT nicht wiederhergestellt.',16;
DROP TABLE #CsvTxnProgress;
DROP TABLE #CsvCallerSentinel;
DROP TABLE #CsvTxnOutput;
DROP TABLE #CsvTxnSource;
DROP TABLE #CsvTxnCells;
DROP TABLE #CsvTxnBaseline;
SELECT CONVERT(nvarchar(32),N'CSV_CALLER_TRANSACTION_GUARDS') Fixture,CONVERT(int,@Cases) CasesPassed;

