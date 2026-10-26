-- Exakte XLSX-Callerrechte; alle Workbookdaten stammen aus der synthetischen ZIP-Fixture.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULL_DFLT_ON ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR @Owner COLLATE Latin1_General_100_BIN2 NOT LIKE REPLICATE(N'[0-9a-f]',32) COLLATE Latin1_General_100_BIN2
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52097,N'Markierter eigener XLSX-Testscope erforderlich.',1;
IF USER_ID(N'ContosoXlsxCaller') IS NOT NULL THROW 52097,N'Vorhandener Principal wird nicht übernommen.',2;
DECLARE @Objects table(Id int PRIMARY KEY,FullName nvarchar(257),PermissionName varchar(16));
INSERT @Objects VALUES
 (1,N'toolbelt_file.USP_ListXlsxWorksheets','EXECUTE'),(2,N'toolbelt_file.USP_ReadXlsxWorksheetCells','EXECUTE'),
 (3,N'toolbelt_file.TVF_InternalXlsxSheets','SELECT'),(4,N'toolbelt_file.TVF_InternalXlsxCells','SELECT'),
 (5,N'toolbelt_core.USP_PrepareResultTable','EXECUTE');
IF EXISTS(SELECT 1 FROM @Objects WHERE OBJECT_ID(FullName) IS NULL) THROW 52097,N'Feste XLSX-Objektmenge fehlt.',3;
-- Die API, passende interne FT und ResultTable-Helper-Rechte sind getrennte Bits.
-- Pro Profil werden beide Ausgabewege versucht; fehlende Dependencies müssen 51529 liefern.
DECLARE @States table(Id int PRIMARY KEY,Api int,ApiGrant bit,FtGrant bit,HelperGrant bit,DirectError int,TableError int);
INSERT @States VALUES
 (1,1,0,0,0,229,229),(2,1,1,0,0,51529,51529),(3,1,1,1,0,0,51529),(4,1,1,1,1,0,0),
 (5,1,1,0,1,51529,51529),(6,1,0,1,1,229,229),(7,1,0,0,0,229,229),
 (8,2,0,0,0,229,229),(9,2,1,0,0,51529,51529),(10,2,1,1,0,0,51529),(11,2,1,1,1,0,0),
 (12,2,1,0,1,51529,51529),(13,2,0,1,1,229,229),(14,2,0,0,0,229,229);
DECLARE @Workbook varbinary(max)=CONVERT(varbinary(max),N'$(XLSX_WORKBOOK_HEX)',2);
IF DATALENGTH(@Workbook)<>2708 THROW 52097,N'Workbookpin-Länge weicht ab.',4;
DECLARE @ExpectedFirstText nvarchar(max)=N'tail ä😀'; -- Nur die Negativkontrolle darf diesen festen Oracle-Wert variieren.
DECLARE @Oracle nvarchar(max)=N'
DECLARE @BeforeTc int=@@TRANCOUNT,@BeforeXs int=XACT_STATE();
IF @Api=1
BEGIN
 DECLARE @ActualSheets table(SheetOrdinal int,SheetName nvarchar(max),Visibility nvarchar(16),Date1904 bit);
 IF @Route=0 INSERT @ActualSheets EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Workbook;
 ELSE BEGIN
  CREATE TABLE #SheetDestination(Sentinel int);
  EXEC toolbelt_file.USP_ListXlsxWorksheets @XlsxBinary=@Workbook,@ResultTable=N''#SheetDestination'';
  INSERT @ActualSheets EXEC sys.sp_executesql N''SELECT SheetOrdinal,SheetName,Visibility,Date1904 FROM #SheetDestination'';
 END;
 DECLARE @ExpectedSheets table(SheetOrdinal int,SheetName varbinary(max),Visibility varbinary(max),Date1904 bit);
 INSERT @ExpectedSheets VALUES(1,CONVERT(varbinary(max),N''Synthetic''),CONVERT(varbinary(max),N''hidden''),1);
 IF (SELECT COUNT(*) FROM @ActualSheets)<>1 OR EXISTS(
  SELECT SheetOrdinal,CONVERT(varbinary(max),SheetName),CONVERT(varbinary(max),Visibility),Date1904 FROM @ActualSheets
  EXCEPT SELECT SheetOrdinal,SheetName,Visibility,Date1904 FROM @ExpectedSheets)
  OR EXISTS(SELECT SheetOrdinal,SheetName,Visibility,Date1904 FROM @ExpectedSheets
  EXCEPT SELECT SheetOrdinal,CONVERT(varbinary(max),SheetName),CONVERT(varbinary(max),Visibility),Date1904 FROM @ActualSheets)
  THROW 52097,N''XLSX sheet golden mismatch.'',20;
END
ELSE
BEGIN
 DECLARE @ActualCells table(RowOrdinal int,ColumnOrdinal int,StoredType nvarchar(16),ValuePresent bit,RawValue nvarchar(max),TextValue nvarchar(max),FormulaPresent bit,FormulaText nvarchar(max),FormulaKind nvarchar(16),SharedFormulaIndex int,CachePresent bit,CacheValue nvarchar(max));
 IF @Route=0 INSERT @ActualCells EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Workbook,@SheetOrdinal=1;
 ELSE BEGIN
  CREATE TABLE #CellDestination(Sentinel int);
  EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @XlsxBinary=@Workbook,@SheetOrdinal=1,@ResultTable=N''#CellDestination'';
  INSERT @ActualCells EXEC sys.sp_executesql N''SELECT RowOrdinal,ColumnOrdinal,StoredType,ValuePresent,RawValue,TextValue,FormulaPresent,FormulaText,FormulaKind,SharedFormulaIndex,CachePresent,CacheValue FROM #CellDestination'';
 END;
 DECLARE @ExpectedCells table(RowOrdinal int,ColumnOrdinal int,StoredType varbinary(max),ValuePresent bit,RawValue varbinary(max),TextValue varbinary(max),FormulaPresent bit,FormulaText varbinary(max),FormulaKind varbinary(max),SharedFormulaIndex int,CachePresent bit,CacheValue varbinary(max),PRIMARY KEY(RowOrdinal,ColumnOrdinal));
 INSERT @ExpectedCells VALUES
 (1,1,CONVERT(varbinary(max),N''s''),1,CONVERT(varbinary(max),N''0''),CONVERT(varbinary(max),@ExpectedFirstText),0,NULL,NULL,NULL,0,NULL),
 (1,3,CONVERT(varbinary(max),N''inlineStr''),0,NULL,CONVERT(varbinary(max),N''''),0,NULL,NULL,NULL,0,NULL),
 (1,4,CONVERT(varbinary(max),N''n''),1,CONVERT(varbinary(max),N''''),NULL,0,NULL,NULL,NULL,0,NULL),
 (1,5,CONVERT(varbinary(max),N''n''),0,NULL,NULL,0,NULL,NULL,NULL,0,NULL),
 (1,6,CONVERT(varbinary(max),N''n''),1,CONVERT(varbinary(max),N''''),NULL,1,CONVERT(varbinary(max),N''SUM(A1)''),CONVERT(varbinary(max),N''shared''),0,1,CONVERT(varbinary(max),N'''')),
 (1,7,CONVERT(varbinary(max),N''n''),0,NULL,NULL,1,CONVERT(varbinary(max),N''''),CONVERT(varbinary(max),N''shared''),0,0,NULL),
 (1,8,CONVERT(varbinary(max),N''b''),1,CONVERT(varbinary(max),N''1''),NULL,0,NULL,NULL,NULL,0,NULL),
 (1,9,CONVERT(varbinary(max),N''e''),1,CONVERT(varbinary(max),N''#DIV/0!''),NULL,0,NULL,NULL,NULL,0,NULL),
 (1048576,16384,CONVERT(varbinary(max),N''n''),1,CONVERT(varbinary(max),N''42''),NULL,0,NULL,NULL,NULL,0,NULL);
 IF (SELECT COUNT(*) FROM @ActualCells)<>9 OR (SELECT COUNT(*) FROM @ExpectedCells)<>9
  OR (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N''tempdb..#CellDestination'')) NOT IN(0,12)
  OR EXISTS(SELECT RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),StoredType),ValuePresent,CONVERT(varbinary(max),RawValue),CONVERT(varbinary(max),TextValue),FormulaPresent,CONVERT(varbinary(max),FormulaText),CONVERT(varbinary(max),FormulaKind),SharedFormulaIndex,CachePresent,CONVERT(varbinary(max),CacheValue) FROM @ActualCells
   EXCEPT SELECT RowOrdinal,ColumnOrdinal,StoredType,ValuePresent,RawValue,TextValue,FormulaPresent,FormulaText,FormulaKind,SharedFormulaIndex,CachePresent,CacheValue FROM @ExpectedCells)
  OR EXISTS(SELECT RowOrdinal,ColumnOrdinal,StoredType,ValuePresent,RawValue,TextValue,FormulaPresent,FormulaText,FormulaKind,SharedFormulaIndex,CachePresent,CacheValue FROM @ExpectedCells
   EXCEPT SELECT RowOrdinal,ColumnOrdinal,CONVERT(varbinary(max),StoredType),ValuePresent,CONVERT(varbinary(max),RawValue),CONVERT(varbinary(max),TextValue),FormulaPresent,CONVERT(varbinary(max),FormulaText),CONVERT(varbinary(max),FormulaKind),SharedFormulaIndex,CachePresent,CONVERT(varbinary(max),CacheValue) FROM @ActualCells)
  THROW 52097,N''XLSX 9x12 byte-exact cell golden mismatch.'',21;
END;
IF @BeforeTc<>@@TRANCOUNT OR @BeforeXs<>XACT_STATE() THROW 52097,N''Caller transaction state changed.'',22;';
DECLARE @Id int=1,@Api int,@Ag bit,@Fg bit,@Hg bit,@Obj int,@Name nvarchar(257),@Perm varchar(16),@Want bit,@Sql nvarchar(max),@Route int,@Caught int,@Expected int,@DirectError int,@TableError int,@Positive int=0,@Denied int=0,@DependencyDenied int=0,@OtherDenied int=0,@InternalDenied int=0,@Created bit=0,@Impersonated bit=0;
BEGIN TRY
 CREATE USER ContosoXlsxCaller WITHOUT LOGIN; SET @Created=1;
 WHILE @Id<=14
 BEGIN
  SELECT @Api=Api,@Ag=ApiGrant,@Fg=FtGrant,@Hg=HelperGrant,@DirectError=DirectError,@TableError=TableError FROM @States WHERE Id=@Id;
  SET @Obj=1;
  WHILE @Obj<=5
  BEGIN
   SELECT @Name=FullName,@Perm=PermissionName FROM @Objects WHERE Id=@Obj;
   SET @Want=CASE WHEN @Obj=@Api THEN @Ag WHEN @Obj=5 THEN @Hg WHEN (@Api=1 AND @Obj=3) OR (@Api=2 AND @Obj=4) THEN @Fg ELSE 0 END;
   SET @Sql=N'REVOKE '+@Perm+N' ON OBJECT::'+@Name+N' FROM ContosoXlsxCaller;'; EXEC sys.sp_executesql @Sql;
   IF @Want=1 BEGIN SET @Sql=N'GRANT '+@Perm+N' ON OBJECT::'+@Name+N' TO ContosoXlsxCaller;'; EXEC sys.sp_executesql @Sql; END;
   SET @Obj+=1;
  END;
  EXECUTE AS USER=N'ContosoXlsxCaller'; SET @Impersonated=1;
  IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0 OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0 OR ISNULL(IS_MEMBER(N'db_securityadmin'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'SELECT'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_file',N'SCHEMA',N'SELECT'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_file',N'SCHEMA',N'EXECUTE'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_file',N'SCHEMA',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_archive',N'SCHEMA',N'SELECT'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_archive',N'SCHEMA',N'EXECUTE'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_archive',N'SCHEMA',N'CONTROL'),0)<>0
   THROW 52097,N'Broad caller role or schema/database permission detected.',5;
  IF EXISTS(SELECT 1 FROM @Objects WHERE ISNULL(HAS_PERMS_BY_NAME(FullName,N'OBJECT',PermissionName),0)<>CASE WHEN Id=@Api THEN @Ag WHEN Id=5 THEN @Hg WHEN (@Api=1 AND Id=3) OR (@Api=2 AND Id=4) THEN @Fg ELSE 0 END)
   THROW 52097,N'Exact object permission mask mismatch.',6;
  SET @Route=0;
  WHILE @Route<2
  BEGIN
   SET @Expected=CASE WHEN @Route=0 THEN @DirectError ELSE @TableError END; SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Oracle,N'@Api int,@Route int,@Workbook varbinary(max),@ExpectedFirstText nvarchar(max)',@Api,@Route,@Workbook,@ExpectedFirstText; END TRY
   BEGIN CATCH SET @Caught=ERROR_NUMBER(); IF @Expected=0 OR @Caught<>@Expected THROW; END CATCH;
   IF @Caught<>@Expected THROW 52097,N'Expected rights denial missing or wrong error.',7;
   IF @Expected=0 SET @Positive+=1 ELSE BEGIN SET @Denied+=1; IF @Expected=51529 SET @DependencyDenied+=1 ELSE SET @OtherDenied+=1; END;
   SET @Route+=1;
  END;
  -- Gegen-API und interne Core-/ZIP-/Typobjekte werden ohne Grant separat denied.
  DECLARE @DeniedObjects table(Ordinal int PRIMARY KEY,Probe nvarchar(max));
  DELETE @DeniedObjects;
  INSERT @DeniedObjects VALUES
   (1,CASE WHEN @Api=1 THEN N'EXEC toolbelt_file.USP_ReadXlsxWorksheetCells @Hilfe=1;' ELSE N'EXEC toolbelt_file.USP_ListXlsxWorksheets @Hilfe=1;' END),
   (2,N'EXEC toolbelt_file.USP_InternalXlsxRead @ReadCells=0;'),
   (3,N'SELECT TOP(1) * FROM toolbelt_archive.TVF_InternalListZipEntriesClr(0x,1);'),
   (4,N'SELECT TOP(1) * FROM toolbelt_file.TVF_InternalInterpretXlsxCell(N''n'',1,N''1'',NULL,NULL,NULL,1);'),
   (5,N'SELECT TOP(1) * FROM toolbelt_file.TVF_InternalFormatXlsxCell(N''n'',1,N''1'',NULL,NULL,NULL,NULL,NULL);');
  DECLARE @ProbeOrdinal int=1,@ProbeCount int=(SELECT COUNT(*) FROM @DeniedObjects);
  WHILE @ProbeOrdinal<=@ProbeCount
  BEGIN
   SELECT @Sql=Probe FROM @DeniedObjects WHERE Ordinal=@ProbeOrdinal; SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=229; END CATCH;
   IF @Caught<>229 THROW 52097,N'Counter API or internal object unexpectedly accessible.',8;
   SET @InternalDenied+=1; SET @ProbeOrdinal+=1;
  END;
  REVERT; SET @Impersonated=0; SET @Id+=1;
 END;
 IF @Positive<>6 OR @Denied<>22 OR @DependencyDenied<>10 OR @OtherDenied<>12 OR @InternalDenied<>70
  THROW 52097,N'Fixed XLSX caller probe counts mismatch.',9;
 DROP USER ContosoXlsxCaller; SET @Created=0;
END TRY
BEGIN CATCH IF @Impersonated=1 REVERT; IF @Created=1 DROP USER ContosoXlsxCaller; THROW; END CATCH;
IF USER_ID(N'ContosoXlsxCaller') IS NOT NULL THROW 52097,N'Owned caller principal remains.',10;
PRINT N'XLSX caller probe counts: positive=6, denied=22 (51529=10,229=12), internal-denied=70; principal removed.';
