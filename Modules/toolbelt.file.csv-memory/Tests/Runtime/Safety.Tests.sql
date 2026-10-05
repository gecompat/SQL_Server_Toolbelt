-- Synthetische Fehler- und Atomikverträge; feste eigene Zielwerte bleiben bei Preflightfehlern intakt.
SET NOCOUNT ON;
CREATE TABLE #CsvSafetyTarget(Marker int NOT NULL);
INSERT #CsvSafetyTarget VALUES(73);
DECLARE @Cases TABLE(Id int NOT NULL,SqlText nvarchar(max) NOT NULL,Expected int NOT NULL);
INSERT @Cases VALUES
(1,N'EXEC toolbelt_file.USP_ParseCsv @Text=NULL,@ResultTable=N''#CsvSafetyTarget'';',55300),
(2,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''x'',@HasHeader=NULL,@ResultTable=N''#CsvSafetyTarget'';',55300),
(3,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''x'',@Separator=N''ab'',@ResultTable=N''#CsvSafetyTarget'';',55300),
(4,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''x'',@NullToken=N'''',@ResultTable=N''#CsvSafetyTarget'';',55300),
(5,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''x'',@NullToken=N''a,b'',@ResultTable=N''#CsvSafetyTarget'';',55300),
(6,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''"a"x'',@ResultTable=N''#CsvSafetyTarget'';',55301),
(7,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''a"b'',@ResultTable=N''#CsvSafetyTarget'';',55301),
(8,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''"a'',@ResultTable=N''#CsvSafetyTarget'';',55301),
(9,N'DECLARE @t nvarchar(max)=N''a''+NCHAR(13)+N''b''; EXEC toolbelt_file.USP_ParseCsv @Text=@t,@ResultTable=N''#CsvSafetyTarget'';',55301),
(10,N'DECLARE @t nvarchar(max)=N''a,b''+NCHAR(10)+N''c''; EXEC toolbelt_file.USP_ParseCsv @Text=@t,@ResultTable=N''#CsvSafetyTarget'';',55302),
(11,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''a,b'',@MaxCells=1,@ResultTable=N''#CsvSafetyTarget'';',55303),
(12,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''a,b'',@MaxColumns=1,@ResultTable=N''#CsvSafetyTarget'';',55303),
(13,N'EXEC toolbelt_file.USP_ParseCsv @Text=N''a,b'',@MaxInputBytes=5,@ResultTable=N''#CsvSafetyTarget'';',55303),
(14,N'DECLARE @t nvarchar(max)=N''a''+NCHAR(10)+N''b''; EXEC toolbelt_file.USP_ParseCsv @Text=@t,@MaxRows=1,@ResultTable=N''#CsvSafetyTarget'';',55303);
DECLARE @Id int,@Sql nvarchar(max),@Expected int,@Caught bit;
DECLARE Cases CURSOR LOCAL FAST_FORWARD FOR SELECT Id,SqlText,Expected FROM @Cases ORDER BY Id;
OPEN Cases; FETCH NEXT FROM Cases INTO @Id,@Sql,@Expected;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Caught=0;
 BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
 BEGIN CATCH IF ERROR_NUMBER()<>@Expected THROW; SET @Caught=1; END CATCH;
 IF @Caught=0 OR (SELECT COUNT(*) FROM #CsvSafetyTarget)<>1 OR NOT EXISTS(SELECT 1 FROM #CsvSafetyTarget WHERE Marker=73)
  THROW 55391,N'CSV safety: erwarteter Preflightfehler oder Zielerhalt fehlt.',1;
 FETCH NEXT FROM Cases INTO @Id,@Sql,@Expected;
END;
CLOSE Cases; DEALLOCATE Cases;
-- Jeder reduzierbare Budgetparameter: NULL, 0 und Default+1.
DECLARE @Budget TABLE(ObjectName sysname,ParameterName sysname,Ceiling bigint);
INSERT @Budget VALUES
(N'USP_ParseCsv',N'MaxRows',100000),(N'USP_ParseCsv',N'MaxColumns',1024),(N'USP_ParseCsv',N'MaxCells',1000000),(N'USP_ParseCsv',N'MaxInputBytes',16777216),
(N'USP_WriteCsv',N'MaxRows',100000),(N'USP_WriteCsv',N'MaxColumns',1024),(N'USP_WriteCsv',N'MaxCells',1000000),(N'USP_WriteCsv',N'MaxValueBytes',16777216),(N'USP_WriteCsv',N'MaxOutputBytes',16777216);
DECLARE @Object sysname,@Parameter sysname,@Ceiling bigint,@Variant int,@Value nvarchar(32);
DECLARE Budgets CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectName,ParameterName,Ceiling FROM @Budget;
OPEN Budgets; FETCH NEXT FROM Budgets INTO @Object,@Parameter,@Ceiling;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Variant=0;
 WHILE @Variant<3
 BEGIN
  SET @Value=CASE @Variant WHEN 0 THEN N'NULL' WHEN 1 THEN N'0' ELSE CONVERT(nvarchar(32),@Ceiling+1) END;
  SET @Sql=N'EXEC toolbelt_file.'+QUOTENAME(@Object)+N' @'+@Parameter+N'='+@Value+N';';
  -- Pflichttexte bleiben gültig, damit die isolierte Budgetprüfung erreichbar ist.
  IF @Object=N'USP_ParseCsv' SET @Sql=N'EXEC toolbelt_file.'+QUOTENAME(@Object)+N' @Text=N''x'',@'+@Parameter+N'='+@Value+N';';
  SET @Caught=0;
  BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY BEGIN CATCH IF ERROR_NUMBER()<>55303 THROW; SET @Caught=1; END CATCH;
  IF @Caught=0 THROW 55391,N'CSV safety: Budgetparameter wurde akzeptiert.',2;
  SET @Variant+=1;
 END;
 FETCH NEXT FROM Budgets INTO @Object,@Parameter,@Ceiling;
END;
CLOSE Budgets; DEALLOCATE Budgets;
CREATE TABLE #CsvSafetyCells(RowKind varchar(6),RowOrdinal bigint,ColumnOrdinal int,[Value] nvarchar(max));
CREATE TABLE #CsvSafetyOutput(CsvText nvarchar(max) COLLATE Latin1_General_100_BIN2 NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
INSERT #CsvSafetyCells VALUES('DATA',1,1,N'x');
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSafetyCells',@ResultTable=N'#CsvSafetyCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55308 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR (SELECT COUNT(*) FROM #CsvSafetyCells)<>1 THROW 55391,N'CSV safety: Inputalias wurde nicht bewahrt.',3;
-- Exakte globale Charge: x+LF = vier UTF-16-Bytes.
EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSafetyCells',@LineEnding='LF',@MaxOutputBytes=4,@ResultTable=N'#CsvSafetyOutput';
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSafetyCells',@LineEnding='LF',@MaxOutputBytes=3,@ResultTable=N'#CsvSafetyOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 OR NOT EXISTS(SELECT 1 FROM #CsvSafetyOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=4)
 THROW 55391,N'CSV safety: exakte Outputgrenze oder Zielerhalt fehlt.',4;
-- Tokenexpansion wird vor vollständiger Fragmentallokation global geprüft.
TRUNCATE TABLE #CsvSafetyCells; INSERT #CsvSafetyCells VALUES('DATA',1,1,NULL),('DATA',1,2,NULL);
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSafetyCells',@NullToken=N'longtoken',@MaxOutputBytes=10,@ResultTable=N'#CsvSafetyOutput'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55303 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55391,N'CSV safety: NULL-Tokenexpansion wurde akzeptiert.',5;
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSafetyCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55307 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55391,N'CSV safety: deaktivierter NULL-Token wurde ignoriert.',6;
TRUNCATE TABLE #CsvSafetyCells; INSERT #CsvSafetyCells VALUES('DATA ',1,1,N'x');
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSafetyCells'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55306 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55391,N'CSV safety: RowKindpadding wurde akzeptiert.',7;
DECLARE @WriterCases TABLE(Id int NOT NULL,SeedSql nvarchar(max) NOT NULL,Arguments nvarchar(256) NOT NULL,Expected int NOT NULL);
INSERT @WriterCases VALUES
(1,N'INSERT #CsvSafetyCells VALUES(''DATA'',1,1,N''x''),(''DATA'',3,1,N''y'');',N'',55306),
(2,N'INSERT #CsvSafetyCells VALUES(''DATA'',1,1,N''x''),(''DATA'',1,1,N''y'');',N'',55306),
(3,N'INSERT #CsvSafetyCells VALUES(''DATA'',1,1,N''x''),(''DATA'',1,2,N''y''),(''DATA'',2,1,N''z'');',N'',55306),
(4,N'',N',@HasHeader=1',55306),
(5,N'INSERT #CsvSafetyCells VALUES(''HEADER'',0,1,NULL);',N',@HasHeader=1,@NullToken=N''NULL''',55307),
(6,N'INSERT #CsvSafetyCells VALUES(''DATA'',1,1,N''x''),(''DATA'',2,1,N''y'');',N',@MaxRows=1',55303),
(7,N'INSERT #CsvSafetyCells VALUES(''DATA'',1,1,N''x'');',N',@MaxValueBytes=1',55303),
(8,N'INSERT #CsvSafetyCells VALUES(''DATA'',1,1,N''x'');',N',@LineEnding=''lf''',55300),
(9,N'INSERT #CsvSafetyCells VALUES(''data'',1,1,N''x'');',N'',55306),
(10,N'INSERT #CsvSafetyCells VALUES(''DATA'',1,1,N''x''),(''DATA'',1,2,N''y'');',N',@MaxColumns=1',55303);
DECLARE @Seed nvarchar(max),@Arguments nvarchar(256);
DECLARE WriterCases CURSOR LOCAL FAST_FORWARD FOR SELECT Id,SeedSql,Arguments,Expected FROM @WriterCases ORDER BY Id;
OPEN WriterCases; FETCH NEXT FROM WriterCases INTO @Id,@Seed,@Arguments,@Expected;
WHILE @@FETCH_STATUS=0
BEGIN
 TRUNCATE TABLE #CsvSafetyCells;
 EXEC sys.sp_executesql @Seed;
 SET @Sql=N'EXEC toolbelt_file.USP_WriteCsv @CellsTable=N''#CsvSafetyCells'',@ResultTable=N''#CsvSafetyOutput'''+@Arguments+N';';
 SET @Caught=0;
 BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY BEGIN CATCH IF ERROR_NUMBER()<>@Expected THROW; SET @Caught=1; END CATCH;
 IF @Caught=0 OR NOT EXISTS(SELECT 1 FROM #CsvSafetyOutput WHERE DataRows=1 AND ColumnCount=1 AND DATALENGTH(CsvText)=4)
  THROW 55391,N'CSV safety: Writerpreflight oder ursprünglicher Output fehlt.',8;
 FETCH NEXT FROM WriterCases INTO @Id,@Seed,@Arguments,@Expected;
END;
CLOSE WriterCases; DEALLOCATE WriterCases;
-- Zusätzliche Quellspalten sind auch ohne fachlichen Inhalt nicht zugelassen.
CREATE TABLE #CsvSafetyExtra(RowKind varchar(6),RowOrdinal bigint,ColumnOrdinal int,[Value] nvarchar(max),Extra int);
SET @Caught=0;
BEGIN TRY EXEC toolbelt_file.USP_WriteCsv @CellsTable=N'#CsvSafetyExtra'; END TRY
BEGIN CATCH IF ERROR_NUMBER()<>55305 THROW; SET @Caught=1; END CATCH;
IF @Caught=0 THROW 55391,N'CSV safety: fünfte Quellspalte wurde akzeptiert.',9;
DROP TABLE #CsvSafetyExtra;
DROP TABLE #CsvSafetyCells;
DROP TABLE #CsvSafetyOutput;
DROP TABLE #CsvSafetyTarget;
SELECT N'PASS' AS Status;
GO
