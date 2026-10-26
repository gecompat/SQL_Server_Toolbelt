SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULL_DFLT_ON ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52097,N'Markierter eigener CSV-Testscope erforderlich.',1;
IF USER_ID(N'ContosoCsvCaller') IS NOT NULL
 THROW 52097,N'Vorhandener CSV-Principal wird nicht uebernommen.',2;
DECLARE @ExpectedFirstValue nvarchar(40)=N'Contoso';
DECLARE @Objects table(Id int PRIMARY KEY,FullName nvarchar(257),PermissionName varchar(16));
INSERT @Objects VALUES
 (1,N'toolbelt_file.USP_ParseCsv','EXECUTE'),(2,N'toolbelt_file.USP_WriteCsv','EXECUTE'),
 (3,N'toolbelt_file.TVF_InternalParseCsv','SELECT'),
 (4,N'toolbelt_file.SVF_InternalMeasureCsvCell','EXECUTE'),
 (5,N'toolbelt_file.SVF_InternalQuoteCsvCell','EXECUTE'),
 (6,N'toolbelt_core.USP_PrepareResultTable','EXECUTE');
IF EXISTS(SELECT 1 FROM @Objects WHERE OBJECT_ID(FullName) IS NULL)
 THROW 52097,N'Unvollstaendige feste CSV-Objektmenge.',3;
-- Exact masks: public API, parser, measure, quote, ResultTable helper.
DECLARE @States table(Id int PRIMARY KEY,Api int,P bit,C1 bit,C2 bit,H bit,DirectError int,TableError int);
INSERT @States VALUES
 (1,1,0,0,0,0,229,229),(2,1,1,0,0,0,55309,55309),
 (3,1,1,1,0,0,0,55309),(4,1,1,1,0,1,0,0),
 (5,1,1,0,0,1,55309,55309),(6,1,0,1,0,1,229,229),(7,1,0,0,0,0,229,229),
 (8,2,0,0,0,0,229,229),(9,2,1,0,0,0,55309,55309),
 (10,2,1,1,0,0,55309,55309),(11,2,1,1,1,0,0,55309),
 (12,2,1,1,1,1,0,0),(13,2,1,0,1,1,55309,55309),
 (14,2,1,1,0,1,55309,55309),(15,2,0,1,1,1,229,229),(16,2,0,0,0,0,229,229);
DECLARE @Oracle nvarchar(max)=N'
DECLARE @BeforeTc int=@@TRANCOUNT,@BeforeXs int=XACT_STATE();
CREATE TABLE #CsvProfileCells(RowKind varchar(6) NOT NULL,RowOrdinal bigint NOT NULL,
 ColumnOrdinal int NOT NULL,Value nvarchar(max) NULL);
INSERT #CsvProfileCells VALUES (''HEADER'',0,1,N''H1''),(''HEADER'',0,2,N''H2''),
 (''DATA'',1,1,N''Contoso''),(''DATA'',1,2,N''a,"b"''),
 (''DATA'',2,1,NULL),(''DATA'',2,2,N''<NULL>'');
CREATE TABLE #CsvProfileDestination(Sentinel int);
CREATE TABLE #CsvActualCells(RowKind varchar(6) NOT NULL,RowOrdinal bigint NOT NULL,
 ColumnOrdinal int NOT NULL,Value nvarchar(max) NULL);
CREATE TABLE #CsvActualText(CsvText nvarchar(max) NOT NULL,DataRows bigint NOT NULL,ColumnCount int NOT NULL);
DECLARE @Text nvarchar(max)=N''H1,H2''+NCHAR(10)+N''Contoso,"a,""b"""''+NCHAR(10)+N''<NULL>,"<NULL>"''+NCHAR(10);
IF @Api=1
BEGIN
 IF @Route=0 INSERT #CsvActualCells EXEC toolbelt_file.USP_ParseCsv
  @Text=@Text,@HasHeader=1,@NullToken=N''<NULL>'';
 ELSE BEGIN
  EXEC toolbelt_file.USP_ParseCsv @Text=@Text,@HasHeader=1,@NullToken=N''<NULL>'',@ResultTable=N''#CsvProfileDestination'';
  EXEC sys.sp_executesql N''INSERT #CsvActualCells SELECT RowKind,RowOrdinal,ColumnOrdinal,Value FROM #CsvProfileDestination;'';
 END;
 DECLARE @Expected table(RowKind varchar(6),RowOrdinal bigint,ColumnOrdinal int,Value nvarchar(max));
 INSERT @Expected VALUES (''HEADER'',0,1,N''H1''),(''HEADER'',0,2,N''H2''),
  (''DATA'',1,1,@ExpectedFirstValue),(''DATA'',1,2,N''a,"b"''),
  (''DATA'',2,1,NULL),(''DATA'',2,2,N''<NULL>'');
 IF (SELECT COUNT(*) FROM #CsvActualCells)<>6 OR EXISTS(
  SELECT 1 FROM @Expected e FULL JOIN #CsvActualCells a
   ON e.RowOrdinal=a.RowOrdinal AND e.ColumnOrdinal=a.ColumnOrdinal
  WHERE e.RowOrdinal IS NULL OR a.RowOrdinal IS NULL
   OR CONVERT(varbinary(max),e.RowKind)<>CONVERT(varbinary(max),a.RowKind)
   OR (e.Value IS NULL AND a.Value IS NOT NULL) OR (e.Value IS NOT NULL AND a.Value IS NULL)
   OR CONVERT(varbinary(max),e.Value)<>CONVERT(varbinary(max),a.Value))
  THROW 52097,N''CSV fixed parser oracle failed.'',21;
END ELSE BEGIN
 IF @Route=0 INSERT #CsvActualText EXEC toolbelt_file.USP_WriteCsv
  @CellsTable=N''#CsvProfileCells'',@HasHeader=1,@NullToken=N''<NULL>'',@LineEnding=''LF'';
 ELSE BEGIN
  EXEC toolbelt_file.USP_WriteCsv @CellsTable=N''#CsvProfileCells'',@HasHeader=1,@NullToken=N''<NULL>'',
   @LineEnding=''LF'',@ResultTable=N''#CsvProfileDestination'';
  EXEC sys.sp_executesql N''INSERT #CsvActualText SELECT CsvText,DataRows,ColumnCount FROM #CsvProfileDestination;'';
 END;
 DECLARE @Golden nvarchar(max)=N''H1,H2''+NCHAR(10)+@ExpectedFirstValue+N'',"a,""b"""''+NCHAR(10)+N''<NULL>,"<NULL>"''+NCHAR(10);
 IF (SELECT COUNT(*) FROM #CsvActualText)<>1 OR EXISTS(SELECT 1 FROM #CsvActualText
  WHERE CONVERT(varbinary(max),CsvText)<>CONVERT(varbinary(max),@Golden) OR DataRows<>2 OR ColumnCount<>2)
  THROW 52097,N''CSV fixed writer oracle failed.'',22;
END;
DECLARE @AfterTc int=@@TRANCOUNT,@AfterXs int=XACT_STATE();
IF @BeforeTc<>@AfterTc OR @BeforeXs<>@AfterXs
 THROW 52097,N''CSV transaction state changed.'',23;
';
DECLARE @State int=1,@Api int,@P bit,@C1 bit,@C2 bit,@H bit,@Route int,@ExpectedError int,
 @Object int,@Permission varchar(16),@Name nvarchar(257),@Wanted bit,@Sql nvarchar(max),
 @Created bit=0,@Impersonated bit=0,@Caught int,@Positive int=0,@Sql229 int=0,@Dependency int=0;
DECLARE @Mask table(Id int PRIMARY KEY,Wanted bit);
BEGIN TRY
 CREATE USER ContosoCsvCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @State<=16
 BEGIN
  SELECT @Api=Api,@P=P,@C1=C1,@C2=C2,@H=H FROM @States WHERE Id=@State;
  DELETE @Mask;
  INSERT @Mask VALUES (1,CASE WHEN @Api=1 THEN @P ELSE 0 END),(2,CASE WHEN @Api=2 THEN @P ELSE 0 END),
   (3,CASE WHEN @Api=1 THEN @C1 ELSE 0 END),(4,CASE WHEN @Api=2 THEN @C1 ELSE 0 END),
   (5,CASE WHEN @Api=2 THEN @C2 ELSE 0 END),(6,@H);
  SET @Object=1;
  WHILE @Object<=6
  BEGIN
   SELECT @Name=o.FullName,@Permission=o.PermissionName,@Wanted=m.Wanted
    FROM @Objects o JOIN @Mask m ON m.Id=o.Id WHERE o.Id=@Object;
   SET @Sql=N'REVOKE '+@Permission+N' ON OBJECT::'+@Name+N' FROM ContosoCsvCaller;';
   EXEC sys.sp_executesql @Sql;
   IF @Wanted=1 BEGIN
    SET @Sql=N'GRANT '+@Permission+N' ON OBJECT::'+@Name+N' TO ContosoCsvCaller;';
    EXEC sys.sp_executesql @Sql;
   END;
   SET @Object+=1;
  END;
  EXECUTE AS USER=N'ContosoCsvCaller'; SET @Impersonated=1;
  IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0
   OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0 OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0
   OR ISNULL(IS_MEMBER(N'db_securityadmin'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'SELECT'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_file',N'SCHEMA',N'SELECT'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_file',N'SCHEMA',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_file',N'SCHEMA',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'CONTROL'),0)<>0
   THROW 52097,N'CSV broad caller rights detected.',5;
  IF EXISTS(SELECT 1 FROM @Objects o JOIN @Mask m ON m.Id=o.Id
   WHERE ISNULL(HAS_PERMS_BY_NAME(o.FullName,N'OBJECT',o.PermissionName),0)<>m.Wanted)
   THROW 52097,N'CSV exact object mask failed.',6;
  SET @Route=0;
  WHILE @Route<2
  BEGIN
   SELECT @ExpectedError=CASE @Route WHEN 0 THEN DirectError ELSE TableError END FROM @States WHERE Id=@State;
   SET @Caught=0;
   BEGIN TRY
    EXEC sys.sp_executesql @Oracle,N'@Api int,@Route int,@ExpectedFirstValue nvarchar(40)',@Api,@Route,@ExpectedFirstValue;
   END TRY
   BEGIN CATCH
    SET @Caught=ERROR_NUMBER();
    IF @ExpectedError=0 OR @Caught<>@ExpectedError THROW;
   END CATCH;
   IF @Caught<>@ExpectedError THROW 52097,N'CSV missing permission was accepted.',7;
   IF @ExpectedError=0 SET @Positive+=1;
   ELSE IF @ExpectedError=229 SET @Sql229+=1;
   ELSE SET @Dependency+=1;
   SET @Route+=1;
  END;
  SET @Sql=CASE @Api WHEN 1 THEN N'EXEC toolbelt_file.USP_WriteCsv @Hilfe=1;'
   ELSE N'EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;' END;
  SET @Caught=0;
  BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
  BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=229; SET @Sql229+=1; END CATCH;
  IF @Caught<>229 THROW 52097,N'CSV other public API was accessible.',8;
  REVERT; SET @Impersonated=0; SET @State+=1;
 END;
 IF @Positive<>6 OR @Sql229<>28 OR @Dependency<>14
  THROW 52097,N'CSV fixed probe count failed.',9;
 DROP USER ContosoCsvCaller; SET @Created=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF @Created=1 DROP USER ContosoCsvCaller;
 THROW;
END CATCH;
IF USER_ID(N'ContosoCsvCaller') IS NOT NULL THROW 52097,N'CSV owned principal remains.',10;
PRINT N'CSV16 exact permission states, fixed parser/writer oracles and strict rejections passed; own principal removed.';
