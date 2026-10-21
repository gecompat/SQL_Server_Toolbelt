-- Synthetische passende Callerziele; per-Aufruf-Textbudget, keine Heapzusage.
SET NOCOUNT ON;
CREATE TABLE #CsvKeepCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvKeepSource(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvKeepOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
CREATE TABLE #CsvKeepProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
CREATE TABLE #CsvKeepIdentity(CellsId int NOT NULL,SourceId int NOT NULL,OutputId int NOT NULL);
INSERT #CsvKeepIdentity VALUES(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource'),OBJECT_ID(N'tempdb..#CsvKeepOutput'));
INSERT #CsvKeepCells VALUES('DATA',99,99,N'old');
INSERT #CsvKeepOutput VALUES(N'old',0,0);
-- KeepData=1: Parserinput genau16MiB; vorherige Callerwerte appendieren/ersetzen.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),@Text nvarchar(max);
SET @Text=@Value;
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV KeepData: exakter Parserinput weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@KeepData=1,@ResultTable=N'#CsvKeepCells';
IF (SELECT COUNT_BIG(*) FROM #CsvKeepCells)<>2 OR NOT EXISTS(SELECT 1 FROM #CsvKeepCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) OR NOT EXISTS(SELECT 1 FROM #CsvKeepCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=99 AND ColumnOrdinal=99 AND DATALENGTH([Value])=6 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),N'old')) THROW 55396,N'CSV KeepData: Parserziel weicht ab.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvKeepIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvKeepCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvKeepSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvKeepOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource')) AND type='PK')<>2
 THROW 55396,N'CSV KeepData: Calleridentitaet oder Schluessel ging verloren.',9;
INSERT #CsvKeepProgress VALUES(1);

GO
-- KeepData=1: Parserinput16MiB+2; Ziel unveraendert.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),@Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'd'),8388609),@Caught bit=0;
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV KeepData: ueberlanger Parserinput weicht ab.',3;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@KeepData=1,@ResultTable=N'#CsvKeepCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvKeepCells)<>2 OR NOT EXISTS(SELECT 1 FROM #CsvKeepCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) OR NOT EXISTS(SELECT 1 FROM #CsvKeepCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=99 AND ColumnOrdinal=99 AND DATALENGTH([Value])=6 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),N'old')) THROW 55396,N'CSV KeepData: Parserabweisung oder Zielerhalt fehlt.',4;
IF NOT EXISTS(SELECT 1 FROM #CsvKeepIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvKeepCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvKeepSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvKeepOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource')) AND type='PK')<>2
 THROW 55396,N'CSV KeepData: Calleridentitaet oder Schluessel ging verloren.',9;
INSERT #CsvKeepProgress VALUES(2);

GO
-- KeepData=1: unabhaengige Writerquelle, Output genau16MiB.
TRUNCATE TABLE #CsvKeepSource;
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),@Expected nvarchar(max);
SET @Expected=@Value+NCHAR(13)+NCHAR(10);
INSERT #CsvKeepSource VALUES('DATA',1,1,@Value);
IF DATALENGTH(@Expected)<>16777216 OR DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV KeepData: Writerfixture weicht ab.',5;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvKeepSource',@LineEnding='CRLF',@KeepData=1,@ResultTable=N'#CsvKeepOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvKeepOutput)<>2 OR NOT EXISTS(SELECT 1 FROM #CsvKeepOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected)) OR NOT EXISTS(SELECT 1 FROM #CsvKeepOutput WHERE DataRows=0 AND ColumnCount=0 AND DATALENGTH(CsvText)=6 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),N'old')) OR (SELECT COUNT_BIG(*) FROM #CsvKeepSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvKeepSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV KeepData: Writerziel oder Quelle weicht ab.',6;
IF NOT EXISTS(SELECT 1 FROM #CsvKeepIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvKeepCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvKeepSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvKeepOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource')) AND type='PK')<>2
 THROW 55396,N'CSV KeepData: Calleridentitaet oder Schluessel ging verloren.',9;
INSERT #CsvKeepProgress VALUES(3);

GO
-- KeepData=1: unabhaengige uebergrosse Writerquelle, Output16MiB+2.
TRUNCATE TABLE #CsvKeepSource;
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388607),@OldValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),@Expected nvarchar(max),@OverText nvarchar(max),@Caught bit=0;
SET @Expected=@OldValue+NCHAR(13)+NCHAR(10);
SET @OverText=@Value+NCHAR(13)+NCHAR(10);
INSERT #CsvKeepSource VALUES('DATA',1,1,@Value);
IF DATALENGTH(@Expected)<>16777216 OR DATALENGTH(@OverText)<>16777218 OR DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV KeepData: Writeruebergrenze weicht ab.',7;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvKeepSource',@LineEnding='CRLF',@KeepData=1,@ResultTable=N'#CsvKeepOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvKeepOutput)<>2 OR NOT EXISTS(SELECT 1 FROM #CsvKeepOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected)) OR NOT EXISTS(SELECT 1 FROM #CsvKeepOutput WHERE DataRows=0 AND ColumnCount=0 AND DATALENGTH(CsvText)=6 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),N'old')) OR (SELECT COUNT_BIG(*) FROM #CsvKeepSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvKeepSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV KeepData: Writerabweisung oder Quell-/Zielerhalt fehlt.',8;
IF NOT EXISTS(SELECT 1 FROM #CsvKeepIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvKeepCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvKeepSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvKeepOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource')) AND type='PK')<>2
 THROW 55396,N'CSV KeepData: Calleridentitaet oder Schluessel ging verloren.',9;
INSERT #CsvKeepProgress VALUES(4);

GO
-- KeepData=0: Parserinput genau16MiB; vorherige Callerwerte appendieren/ersetzen.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388608),@Text nvarchar(max);
SET @Text=@Value;
IF DATALENGTH(@Text)<>16777216 THROW 55396,N'CSV KeepData: exakter Parserinput weicht ab.',1;
EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@KeepData=0,@ResultTable=N'#CsvKeepCells';
IF (SELECT COUNT_BIG(*) FROM #CsvKeepCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvKeepCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV KeepData: Parserziel weicht ab.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvKeepIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvKeepCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvKeepSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvKeepOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource')) AND type='PK')<>2
 THROW 55396,N'CSV KeepData: Calleridentitaet oder Schluessel ging verloren.',9;
INSERT #CsvKeepProgress VALUES(5);

GO
-- KeepData=0: Parserinput16MiB+2; Ziel unveraendert.
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388608),@Text nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'd'),8388609),@Caught bit=0;
IF DATALENGTH(@Text)<>16777218 THROW 55396,N'CSV KeepData: ueberlanger Parserinput weicht ab.',3;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@KeepData=0,@ResultTable=N'#CsvKeepCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvKeepCells)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvKeepCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV KeepData: Parserabweisung oder Zielerhalt fehlt.',4;
IF NOT EXISTS(SELECT 1 FROM #CsvKeepIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvKeepCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvKeepSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvKeepOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource')) AND type='PK')<>2
 THROW 55396,N'CSV KeepData: Calleridentitaet oder Schluessel ging verloren.',9;
INSERT #CsvKeepProgress VALUES(6);

GO
-- KeepData=0: unabhaengige Writerquelle, Output genau16MiB.
TRUNCATE TABLE #CsvKeepSource;
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'e'),8388606),@Expected nvarchar(max);
SET @Expected=@Value+NCHAR(13)+NCHAR(10);
INSERT #CsvKeepSource VALUES('DATA',1,1,@Value);
IF DATALENGTH(@Expected)<>16777216 OR DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV KeepData: Writerfixture weicht ab.',5;
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvKeepSource',@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#CsvKeepOutput';
IF (SELECT COUNT_BIG(*) FROM #CsvKeepOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvKeepOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected)) OR (SELECT COUNT_BIG(*) FROM #CsvKeepSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvKeepSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV KeepData: Writerziel oder Quelle weicht ab.',6;
IF NOT EXISTS(SELECT 1 FROM #CsvKeepIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvKeepCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvKeepSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvKeepOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource')) AND type='PK')<>2
 THROW 55396,N'CSV KeepData: Calleridentitaet oder Schluessel ging verloren.',9;
INSERT #CsvKeepProgress VALUES(7);

GO
-- KeepData=0: unabhaengige uebergrosse Writerquelle, Output16MiB+2.
TRUNCATE TABLE #CsvKeepSource;
DECLARE @Value nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'f'),8388607),@OldValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'e'),8388606),@Expected nvarchar(max),@OverText nvarchar(max),@Caught bit=0;
SET @Expected=@OldValue+NCHAR(13)+NCHAR(10);
SET @OverText=@Value+NCHAR(13)+NCHAR(10);
INSERT #CsvKeepSource VALUES('DATA',1,1,@Value);
IF DATALENGTH(@Expected)<>16777216 OR DATALENGTH(@OverText)<>16777218 OR DATALENGTH(@Value)>=16777216 THROW 55396,N'CSV KeepData: Writeruebergrenze weicht ab.',7;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvKeepSource',@LineEnding='CRLF',@KeepData=0,@ResultTable=N'#CsvKeepOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT_BIG(*) FROM #CsvKeepOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvKeepOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@Expected)) OR (SELECT COUNT_BIG(*) FROM #CsvKeepSource)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvKeepSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=DATALENGTH(@Value) AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@Value)) THROW 55396,N'CSV KeepData: Writerabweisung oder Quell-/Zielerhalt fehlt.',8;
IF NOT EXISTS(SELECT 1 FROM #CsvKeepIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvKeepCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvKeepSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvKeepOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvKeepOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvKeepCells'),OBJECT_ID(N'tempdb..#CsvKeepSource')) AND type='PK')<>2
 THROW 55396,N'CSV KeepData: Calleridentitaet oder Schluessel ging verloren.',9;
INSERT #CsvKeepProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvKeepProgress);
IF @Cases<>8 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV KeepData: Abschlusswitness fehlt.',10;
DROP TABLE #CsvKeepProgress;
DROP TABLE #CsvKeepIdentity;
DROP TABLE #CsvKeepOutput;
DROP TABLE #CsvKeepSource;
DROP TABLE #CsvKeepCells;
SELECT CONVERT(nvarchar(32),N'CSV_KEEPDATA_CEILINGS') Fixture,CONVERT(int,@Cases) CasesPassed;
