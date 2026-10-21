-- Acht ausgewaehlte Budgetparameter oberhalb ihrer festen Obergrenze.
-- Vollstaendige synthetische16MiB-Callerziele; keine neue Heap-/Performancezusage.
SET NOCOUNT ON;
CREATE TABLE #CsvBudgetCells(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvBudgetSource(RowKind varchar(6) COLLATE Latin1_General_100_BIN2 NOT NULL,RowOrdinal bigint NOT NULL,ColumnOrdinal int NOT NULL,[Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL,PRIMARY KEY(RowOrdinal,ColumnOrdinal));
CREATE TABLE #CsvBudgetOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL,PRIMARY KEY(DataRows,ColumnCount));
CREATE TABLE #CsvBudgetIdentity(CellsId int NOT NULL,SourceId int NOT NULL,OutputId int NOT NULL);
CREATE TABLE #CsvBudgetProgress(Id int NOT NULL PRIMARY KEY CHECK(Id BETWEEN 1 AND 8));
INSERT #CsvBudgetIdentity VALUES(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput'));
-- 1: USP_ParseCsv @MaxInputBytes=16777217; alle anderen Parameter gueltig.
DECLARE @ParserValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
 @SourceValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),
 @OutputText nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388606)+NCHAR(13)+NCHAR(10),@Caught bit=0;
IF DATALENGTH(@ParserValue)<>16777216 OR DATALENGTH(@SourceValue)<>16777212 OR DATALENGTH(@OutputText)<>16777216 THROW 55396,N'CSV budget: synthetische Fixtures weichen ab.',1;
INSERT #CsvBudgetCells VALUES('DATA',1,1,@ParserValue);
INSERT #CsvBudgetSource VALUES('DATA',1,1,@SourceValue);
INSERT #CsvBudgetOutput VALUES(@OutputText,1,1);
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=N'd',@ResultTable=N'#CsvBudgetCells',@KeepData=0,@MaxInputBytes=16777217; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55396,N'CSV budget: ungueltiger Ressourcenparameter wurde akzeptiert.',4;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
INSERT #CsvBudgetProgress VALUES(1);

GO
-- 2: USP_ParseCsv @MaxRows=100001; alle anderen Parameter gueltig.
DECLARE @ParserValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
 @SourceValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),
 @OutputText nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388606)+NCHAR(13)+NCHAR(10),@Caught bit=0;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=N'd',@ResultTable=N'#CsvBudgetCells',@KeepData=0,@MaxRows=100001; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55396,N'CSV budget: ungueltiger Ressourcenparameter wurde akzeptiert.',4;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
INSERT #CsvBudgetProgress VALUES(2);

GO
-- 3: USP_ParseCsv @MaxColumns=1025; alle anderen Parameter gueltig.
DECLARE @ParserValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
 @SourceValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),
 @OutputText nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388606)+NCHAR(13)+NCHAR(10),@Caught bit=0;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=N'd',@ResultTable=N'#CsvBudgetCells',@KeepData=0,@MaxColumns=1025; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55396,N'CSV budget: ungueltiger Ressourcenparameter wurde akzeptiert.',4;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
INSERT #CsvBudgetProgress VALUES(3);

GO
-- 4: USP_ParseCsv @MaxCells=1000001; alle anderen Parameter gueltig.
DECLARE @ParserValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
 @SourceValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),
 @OutputText nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388606)+NCHAR(13)+NCHAR(10),@Caught bit=0;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
BEGIN TRY EXEC toolbelt_file.USP_ParseCsv @Text=N'd',@ResultTable=N'#CsvBudgetCells',@KeepData=0,@MaxCells=1000001; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55396,N'CSV budget: ungueltiger Ressourcenparameter wurde akzeptiert.',4;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
INSERT #CsvBudgetProgress VALUES(4);

GO
-- 5: USP_WriteCsv @MaxValueBytes=16777217; alle anderen Parameter gueltig.
DECLARE @ParserValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
 @SourceValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),
 @OutputText nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388606)+NCHAR(13)+NCHAR(10),@Caught bit=0;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvBudgetSource',@LineEnding='CRLF',@ResultTable=N'#CsvBudgetOutput',@KeepData=0,@MaxValueBytes=16777217; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55396,N'CSV budget: ungueltiger Ressourcenparameter wurde akzeptiert.',4;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
INSERT #CsvBudgetProgress VALUES(5);

GO
-- 6: USP_WriteCsv @MaxOutputBytes=16777217; alle anderen Parameter gueltig.
DECLARE @ParserValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
 @SourceValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),
 @OutputText nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388606)+NCHAR(13)+NCHAR(10),@Caught bit=0;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvBudgetSource',@LineEnding='CRLF',@ResultTable=N'#CsvBudgetOutput',@KeepData=0,@MaxOutputBytes=16777217; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55396,N'CSV budget: ungueltiger Ressourcenparameter wurde akzeptiert.',4;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
INSERT #CsvBudgetProgress VALUES(6);

GO
-- 7: USP_WriteCsv @MaxRows=100001; alle anderen Parameter gueltig.
DECLARE @ParserValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
 @SourceValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),
 @OutputText nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388606)+NCHAR(13)+NCHAR(10),@Caught bit=0;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvBudgetSource',@LineEnding='CRLF',@ResultTable=N'#CsvBudgetOutput',@KeepData=0,@MaxRows=100001; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55396,N'CSV budget: ungueltiger Ressourcenparameter wurde akzeptiert.',4;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
INSERT #CsvBudgetProgress VALUES(7);

GO
-- 8: USP_WriteCsv @MaxCells=1000001; alle anderen Parameter gueltig.
DECLARE @ParserValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),8388608),
 @SourceValue nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'b'),8388606),
 @OutputText nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'c'),8388606)+NCHAR(13)+NCHAR(10),@Caught bit=0;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvBudgetSource',@LineEnding='CRLF',@ResultTable=N'#CsvBudgetOutput',@KeepData=0,@MaxCells=1000001; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 OR ERROR_STATE()<>1 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55396,N'CSV budget: ungueltiger Ressourcenparameter wurde akzeptiert.',4;
IF (SELECT COUNT_BIG(*) FROM #CsvBudgetCells)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetCells WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777216 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@ParserValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetSource)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetSource WHERE CONVERT(varbinary(max),RowKind)=0x44415441 AND DATALENGTH(RowKind)=4 AND RowOrdinal=1 AND ColumnOrdinal=1 AND DATALENGTH([Value])=16777212 AND CONVERT(varbinary(max),[Value])=CONVERT(varbinary(max),@SourceValue))
 OR (SELECT COUNT_BIG(*) FROM #CsvBudgetOutput)<>1
 OR NOT EXISTS(SELECT 1 FROM #CsvBudgetOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=16777216 AND CONVERT(varbinary(max),CsvText)=CONVERT(varbinary(max),@OutputText))
 THROW 55396,N'CSV budget: vollstaendiger Callerzustand wurde veraendert.',2;
IF NOT EXISTS(SELECT 1 FROM #CsvBudgetIdentity WHERE CellsId=OBJECT_ID(N'tempdb..#CsvBudgetCells') AND SourceId=OBJECT_ID(N'tempdb..#CsvBudgetSource') AND OutputId=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetCells'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetSource'))<>4
 OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#CsvBudgetOutput'))<>3
 OR (SELECT COUNT(*) FROM tempdb.sys.key_constraints WHERE parent_object_id IN(OBJECT_ID(N'tempdb..#CsvBudgetCells'),OBJECT_ID(N'tempdb..#CsvBudgetSource'),OBJECT_ID(N'tempdb..#CsvBudgetOutput')) AND type='PK')<>3
 THROW 55396,N'CSV budget: Calleridentitaet oder Schluessel weicht ab.',3;
-- Neutralitaet getrennt von Katalogabfragen pruefen.
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Transaktionszustand ist nicht neutral.',6;
INSERT #CsvBudgetProgress VALUES(8);
DECLARE @Cases int=(SELECT COUNT(*) FROM #CsvBudgetProgress);
IF @Cases<>8 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 55396,N'CSV budget: Abschlusswitness fehlt.',5;
DROP TABLE #CsvBudgetProgress;
DROP TABLE #CsvBudgetIdentity;
DROP TABLE #CsvBudgetOutput;
DROP TABLE #CsvBudgetSource;
DROP TABLE #CsvBudgetCells;
SELECT CONVERT(nvarchar(32),N'CSV_BUDGET_PARAMETER_GUARDS') Fixture,CONVERT(int,@Cases) CasesPassed;
