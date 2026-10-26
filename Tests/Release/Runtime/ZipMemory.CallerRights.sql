-- Enges Rechtematrixprofil für drei bestehende ZIP-Memory-USPs; nur synthetische ZIP-Bytes.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET ANSI_NULL_DFLT_ON ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR @Owner COLLATE Latin1_General_100_BIN2 NOT LIKE REPLICATE(N'[0-9a-f]',32) COLLATE Latin1_General_100_BIN2
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52097,N'Markierter eigener ZIP-Testscope erforderlich.',1;
IF USER_ID(N'ContosoZipCaller') IS NOT NULL THROW 52097,N'Vorhandener Principal wird nicht übernommen.',2;
DECLARE @ReaderZip varbinary(max)=CONVERT(varbinary(max),N'$(ZIP_READER_FIXTURE_HEX)',2);
DECLARE @WriterGolden varbinary(max)=CONVERT(varbinary(max),N'$(ZIP_WRITER_GOLDEN_HEX)',2);
IF DATALENGTH(@ReaderZip)<>121 OR DATALENGTH(@WriterGolden)<>121
 THROW 52097,N'ZIP-Bytes müssen den festen Ein-Entry-Goldens entsprechen.',3;

DECLARE @Objects table(Id int PRIMARY KEY,FullName nvarchar(257),PermissionName varchar(16),Probe nvarchar(max));
INSERT @Objects VALUES
 (1,N'toolbelt_archive.USP_ListZipEntriesFromBinary','EXECUTE',N'EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @Hilfe=1;'),
 (2,N'toolbelt_archive.USP_ExtractZipEntryFromBinary','EXECUTE',N'EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @Hilfe=1;'),
 (3,N'toolbelt_archive.USP_CreateZipFromEntries','EXECUTE',N'EXEC toolbelt_archive.USP_CreateZipFromEntries @Hilfe=1;'),
 (4,N'toolbelt_archive.TVF_InternalListZipEntriesClr','SELECT',N'SELECT TOP(1) * FROM toolbelt_archive.TVF_InternalListZipEntriesClr(0x,1);'),
 (5,N'toolbelt_archive.TVF_InternalExtractZipEntryClr','SELECT',N'SELECT TOP(1) * FROM toolbelt_archive.TVF_InternalExtractZipEntryClr(0x,N''hello.txt'',16777216,200,1);'),
 (6,N'toolbelt_archive.TVF_InternalZipWriterName','SELECT',N'SELECT TOP(1) * FROM toolbelt_archive.TVF_InternalZipWriterName(N''hello.txt'',1024);'),
 (7,N'toolbelt_archive.TVF_InternalZipWriterArchive','SELECT',N'SELECT TOP(1) * FROM toolbelt_archive.TVF_InternalZipWriterArchive(0x,0,1,1024,5,5,121,121,30000);'),
 (8,N'toolbelt_core.USP_PrepareResultTable','EXECUTE',N'EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=N''#DeniedProbe'',@LikeTable=N''#DeniedShape'';');
IF EXISTS(SELECT 1 FROM @Objects WHERE OBJECT_ID(FullName) IS NULL) THROW 52097,N'Feste ZIP-Objektmenge fehlt.',4;

-- Je API: keine Rechte; Public EXECUTE allein; API plus passende FT-SELECTs;
-- vollständiges schmales Profil; passende FTs+Helper ohne Public; Public+Helper ohne FTs.
DECLARE @States table(Id int PRIMARY KEY,Api int,ApiGrant bit,FtGrant bit,HelperGrant bit,DirectError int,TableError int);
INSERT @States VALUES
 (1,1,0,0,0,229,229),(2,1,1,0,0,51329,51329),(3,1,1,1,0,0,51329),(4,1,1,1,1,0,0),(5,1,0,1,1,229,229),(6,1,1,0,1,51329,51329),
 (7,2,0,0,0,229,229),(8,2,1,0,0,51329,51329),(9,2,1,1,0,0,51329),(10,2,1,1,1,0,0),(11,2,0,1,1,229,229),(12,2,1,0,1,51329,51329),
 (13,3,0,0,0,229,229),(14,3,1,0,0,51357,51357),(15,3,1,1,0,51357,51357),(16,3,1,1,1,0,0),(17,3,0,1,1,229,229),(18,3,1,0,1,51357,51357);

DECLARE @ExpectedList table(EntryOrdinal int,EntryName varbinary(max),IsDirectory bit,CompressedBytes bigint,UncompressedBytes bigint,CompressionMethod int,Crc32 int,IsEncrypted bit,IsExtractionSupported bit,DuplicateCount int,IsPathSafe bit,PathStatus varbinary(max),LastModifiedAt datetime2(0));
INSERT @ExpectedList VALUES(1,CONVERT(varbinary(max),N'hello.txt'),0,5,5,0,-137262718,0,1,1,1,CONVERT(varbinary(max),'safe'),CONVERT(datetime2(0),'2020-02-03T04:05:06'));
DECLARE @ExpectedExtract table(EntryName varbinary(max),CompressedBytes bigint,UncompressedBytes bigint,CompressionMethod int,Crc32 int,IsEncrypted bit,EntryPayload varbinary(max));
INSERT @ExpectedExtract VALUES(CONVERT(varbinary(max),N'hello.txt'),5,5,0,-137262718,0,0x48656C6C6F);
DECLARE @ExpectedWriter table(ArchivePayload varbinary(max),ArchiveBytes bigint,EntryCount int,TotalPayloadBytes bigint,CompressionMethod int);
INSERT @ExpectedWriter VALUES(@WriterGolden,121,1,5,0);
DECLARE @ExpectedShape table(Api int,Ordinal int,ColumnName sysname,TypeId tinyint,MaxLength smallint,IsNullable bit,PRIMARY KEY(Api,Ordinal));
INSERT @ExpectedShape VALUES
 (1,1,N'EntryOrdinal',56,4,0),(1,2,N'EntryName',231,2048,0),(1,3,N'IsDirectory',104,1,0),
 (1,4,N'CompressedBytes',127,8,0),(1,5,N'UncompressedBytes',127,8,0),(1,6,N'CompressionMethod',56,4,0),
 (1,7,N'Crc32',56,4,0),(1,8,N'IsEncrypted',104,1,0),(1,9,N'IsExtractionSupported',104,1,0),
 (1,10,N'DuplicateCount',56,4,0),(1,11,N'IsPathSafe',104,1,0),(1,12,N'PathStatus',167,32,0),(1,13,N'LastModifiedAt',42,6,1),
 (2,1,N'EntryName',231,2048,0),(2,2,N'CompressedBytes',127,8,0),(2,3,N'UncompressedBytes',127,8,0),
 (2,4,N'CompressionMethod',56,4,0),(2,5,N'Crc32',56,4,1),(2,6,N'IsEncrypted',104,1,0),(2,7,N'EntryPayload',165,-1,1),
 (3,1,N'ArchivePayload',165,-1,0),(3,2,N'ArchiveBytes',127,8,0),(3,3,N'EntryCount',56,4,0),
 (3,4,N'TotalPayloadBytes',127,8,0),(3,5,N'CompressionMethod',56,4,0);
-- USP_PrepareResultTable can use a temporary anchor column while replacing
-- schema, so physical column_id values may have gaps; compare logical order.

DECLARE @Id int=1,@Api int,@Ag bit,@Fg bit,@Hg bit,@Obj int,@Name nvarchar(257),@Perm varchar(16),@Want bit,@Sql nvarchar(max),@Probe nvarchar(max),@Route int,@Caught int,@Expected int,
 @DirectError int,@TableError int,@Positive int=0,@Denied int=0,@Api229 int=0,@DependencyDenied int=0,@OtherDenied int=0,@InternalDenied int=0,@Created bit=0,@Impersonated bit=0;
DECLARE @ActualList table(EntryOrdinal int,EntryName nvarchar(1024),IsDirectory bit,CompressedBytes bigint,UncompressedBytes bigint,CompressionMethod int,Crc32 int,IsEncrypted bit,IsExtractionSupported bit,DuplicateCount int,IsPathSafe bit,PathStatus varchar(32),LastModifiedAt datetime2(0));
DECLARE @ActualExtract table(EntryName nvarchar(1024),CompressedBytes bigint,UncompressedBytes bigint,CompressionMethod int,Crc32 int,IsEncrypted bit,EntryPayload varbinary(max));
DECLARE @ActualWriter table(ArchivePayload varbinary(max),ArchiveBytes bigint,EntryCount int,TotalPayloadBytes bigint,CompressionMethod int);
DECLARE @DeniedObjects table(Ordinal int PRIMARY KEY,Probe nvarchar(max));
DECLARE @Destination sysname,@DestinationId int;
CREATE TABLE #ZipWriterInput(Ordinal int NOT NULL,EntryName nvarchar(max) NOT NULL,Payload varbinary(max) NOT NULL);
INSERT #ZipWriterInput VALUES(1,N'hello.txt',0x48656C6C6F);
CREATE TABLE #DeniedProbe(Sentinel int);
CREATE TABLE #DeniedShape(Sentinel int);
BEGIN TRY
 CREATE USER ContosoZipCaller WITHOUT LOGIN; SET @Created=1;
$(ZIP_EXTRA_SCHEMA_GRANT)
 WHILE @Id<=18
 BEGIN
  SELECT @Api=Api,@Ag=ApiGrant,@Fg=FtGrant,@Hg=HelperGrant,@DirectError=DirectError,@TableError=TableError FROM @States WHERE Id=@Id;
  SET @Obj=1;
  WHILE @Obj<=8
  BEGIN
   SELECT @Name=FullName,@Perm=PermissionName FROM @Objects WHERE Id=@Obj;
   SET @Want=CASE WHEN @Obj=@Api THEN @Ag WHEN @Obj=8 THEN @Hg
    WHEN (@Api=1 AND @Obj=4) OR (@Api=2 AND @Obj=5) OR (@Api=3 AND @Obj IN(6,7)) THEN @Fg ELSE 0 END;
   SET @Sql=N'REVOKE '+@Perm+N' ON OBJECT::'+@Name+N' FROM ContosoZipCaller;'; EXEC sys.sp_executesql @Sql;
   IF @Want=1 BEGIN SET @Sql=N'GRANT '+@Perm+N' ON OBJECT::'+@Name+N' TO ContosoZipCaller;'; EXEC sys.sp_executesql @Sql; END;
   SET @Obj+=1;
  END;
  EXECUTE AS USER=N'ContosoZipCaller'; SET @Impersonated=1;
  IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0 OR ISNULL(IS_MEMBER(N'db_ddladmin'),0)<>0 OR ISNULL(IS_MEMBER(N'db_securityadmin'),0)<>0 OR ISNULL(IS_MEMBER(N'db_accessadmin'),0)<>0 OR ISNULL(IS_MEMBER(N'db_backupoperator'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'SELECT'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'EXECUTE'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_archive',N'SCHEMA',N'SELECT'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_archive',N'SCHEMA',N'EXECUTE'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_archive',N'SCHEMA',N'CONTROL'),0)<>0
   OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0 OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'CONTROL'),0)<>0
   THROW 52097,N'Broad caller role or schema/database permission detected.',5;
  IF EXISTS(SELECT 1 FROM @Objects WHERE ISNULL(HAS_PERMS_BY_NAME(FullName,N'OBJECT',PermissionName),0)<>CASE WHEN Id=@Api THEN @Ag WHEN Id=8 THEN @Hg WHEN (@Api=1 AND Id=4) OR (@Api=2 AND Id=5) OR (@Api=3 AND Id IN(6,7)) THEN @Fg ELSE 0 END)
   THROW 52097,N'Exact ZIP object permission mask mismatch.',6;

  SET @Route=0;
  WHILE @Route<2
  BEGIN
   SET @Expected=CASE WHEN @Route=0 THEN @DirectError ELSE @TableError END; SET @Caught=0;
   DELETE @ActualList; DELETE @ActualExtract; DELETE @ActualWriter;
   DECLARE @BeforeTc int=@@TRANCOUNT,@BeforeXs int=XACT_STATE();
   BEGIN TRY
    IF @Api=1
    BEGIN
     IF @Route=0 INSERT @ActualList EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@ReaderZip;
     ELSE BEGIN
      IF OBJECT_ID(N'tempdb..#ListDestination') IS NOT NULL DROP TABLE #ListDestination;
      CREATE TABLE #ListDestination(Sentinel int);
      EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@ReaderZip,@ResultTable=N'#ListDestination';
      SET @Destination=N'#ListDestination';SET @DestinationId=OBJECT_ID(N'tempdb..#ListDestination');
      IF EXISTS(SELECT Ordinal,CONVERT(varbinary(max),ColumnName),TypeId,MaxLength,IsNullable FROM @ExpectedShape WHERE Api=@Api
                EXCEPT SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY column_id)),CONVERT(varbinary(max),name),system_type_id,max_length,is_nullable FROM tempdb.sys.columns WHERE object_id=@DestinationId)
       OR EXISTS(SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY column_id)),CONVERT(varbinary(max),name),system_type_id,max_length,is_nullable FROM tempdb.sys.columns WHERE object_id=@DestinationId
                 EXCEPT SELECT Ordinal,CONVERT(varbinary(max),ColumnName),TypeId,MaxLength,IsNullable FROM @ExpectedShape WHERE Api=@Api)
       THROW 52097,N'ZIP list ResultTable typed shape mismatch.',12;
      INSERT @ActualList EXEC sys.sp_executesql N'SELECT EntryOrdinal,EntryName,IsDirectory,CompressedBytes,UncompressedBytes,CompressionMethod,Crc32,IsEncrypted,IsExtractionSupported,DuplicateCount,IsPathSafe,PathStatus,LastModifiedAt FROM #ListDestination;';
     END;
     IF @Expected=0 AND ((SELECT COUNT(*) FROM @ActualList)<>1 OR EXISTS(SELECT EntryOrdinal,CONVERT(varbinary(max),EntryName),IsDirectory,CompressedBytes,UncompressedBytes,CompressionMethod,Crc32,IsEncrypted,IsExtractionSupported,DuplicateCount,IsPathSafe,CONVERT(varbinary(max),PathStatus),LastModifiedAt FROM @ActualList EXCEPT SELECT * FROM @ExpectedList) OR EXISTS(SELECT * FROM @ExpectedList EXCEPT SELECT EntryOrdinal,CONVERT(varbinary(max),EntryName),IsDirectory,CompressedBytes,UncompressedBytes,CompressionMethod,Crc32,IsEncrypted,IsExtractionSupported,DuplicateCount,IsPathSafe,CONVERT(varbinary(max),PathStatus),LastModifiedAt FROM @ActualList)) THROW 52097,N'ZIP list fixed 13-column golden mismatch.',13;
    END
    ELSE IF @Api=2
    BEGIN
     IF @Route=0 INSERT @ActualExtract EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@ReaderZip,@EntryName=N'hello.txt';
     ELSE BEGIN
      IF OBJECT_ID(N'tempdb..#ExtractDestination') IS NOT NULL DROP TABLE #ExtractDestination;
      CREATE TABLE #ExtractDestination(Sentinel int);
      EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary @ZipArchive=@ReaderZip,@EntryName=N'hello.txt',@ResultTable=N'#ExtractDestination';
      SET @Destination=N'#ExtractDestination';SET @DestinationId=OBJECT_ID(N'tempdb..#ExtractDestination');
      IF EXISTS(SELECT Ordinal,CONVERT(varbinary(max),ColumnName),TypeId,MaxLength,IsNullable FROM @ExpectedShape WHERE Api=@Api
                EXCEPT SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY column_id)),CONVERT(varbinary(max),name),system_type_id,max_length,is_nullable FROM tempdb.sys.columns WHERE object_id=@DestinationId)
       OR EXISTS(SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY column_id)),CONVERT(varbinary(max),name),system_type_id,max_length,is_nullable FROM tempdb.sys.columns WHERE object_id=@DestinationId
                 EXCEPT SELECT Ordinal,CONVERT(varbinary(max),ColumnName),TypeId,MaxLength,IsNullable FROM @ExpectedShape WHERE Api=@Api)
       THROW 52097,N'ZIP extract ResultTable typed shape mismatch.',14;
      INSERT @ActualExtract EXEC sys.sp_executesql N'SELECT EntryName,CompressedBytes,UncompressedBytes,CompressionMethod,Crc32,IsEncrypted,EntryPayload FROM #ExtractDestination;';
     END;
     IF @Expected=0 AND ((SELECT COUNT(*) FROM @ActualExtract)<>1 OR EXISTS(SELECT CONVERT(varbinary(max),EntryName),CompressedBytes,UncompressedBytes,CompressionMethod,Crc32,IsEncrypted,EntryPayload FROM @ActualExtract EXCEPT SELECT * FROM @ExpectedExtract) OR EXISTS(SELECT * FROM @ExpectedExtract EXCEPT SELECT CONVERT(varbinary(max),EntryName),CompressedBytes,UncompressedBytes,CompressionMethod,Crc32,IsEncrypted,EntryPayload FROM @ActualExtract)) THROW 52097,N'ZIP extract fixed byte/null golden mismatch.',15;
    END
    ELSE
    BEGIN
     IF @Route=0 INSERT @ActualWriter EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipWriterInput',@CompressionMethod='Stored';
     ELSE BEGIN
      IF OBJECT_ID(N'tempdb..#WriterDestination') IS NOT NULL DROP TABLE #WriterDestination;
      CREATE TABLE #WriterDestination(Sentinel int);
      EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#ZipWriterInput',@CompressionMethod='Stored',@ResultTable=N'#WriterDestination';
      SET @Destination=N'#WriterDestination';SET @DestinationId=OBJECT_ID(N'tempdb..#WriterDestination');
      IF EXISTS(SELECT Ordinal,CONVERT(varbinary(max),ColumnName),TypeId,MaxLength,IsNullable FROM @ExpectedShape WHERE Api=@Api
                EXCEPT SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY column_id)),CONVERT(varbinary(max),name),system_type_id,max_length,is_nullable FROM tempdb.sys.columns WHERE object_id=@DestinationId)
       OR EXISTS(SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY column_id)),CONVERT(varbinary(max),name),system_type_id,max_length,is_nullable FROM tempdb.sys.columns WHERE object_id=@DestinationId
                 EXCEPT SELECT Ordinal,CONVERT(varbinary(max),ColumnName),TypeId,MaxLength,IsNullable FROM @ExpectedShape WHERE Api=@Api)
       THROW 52097,N'ZIP writer ResultTable typed shape mismatch.',16;
      INSERT @ActualWriter EXEC sys.sp_executesql N'SELECT ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod FROM #WriterDestination;';
     END;
     IF @Expected=0 AND ((SELECT COUNT(*) FROM @ActualWriter)<>1 OR EXISTS(SELECT ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod FROM @ActualWriter EXCEPT SELECT * FROM @ExpectedWriter) OR EXISTS(SELECT * FROM @ExpectedWriter EXCEPT SELECT ArchivePayload,ArchiveBytes,EntryCount,TotalPayloadBytes,CompressionMethod FROM @ActualWriter)) THROW 52097,N'ZIP writer fixed 121-byte golden mismatch.',17;
    END;
   END TRY
   BEGIN CATCH SET @Caught=ERROR_NUMBER(); IF @Expected=0 OR @Caught<>@Expected THROW; END CATCH;
   IF @Route=1
   BEGIN
    IF OBJECT_ID(N'tempdb..#ListDestination') IS NOT NULL DROP TABLE #ListDestination;
    IF OBJECT_ID(N'tempdb..#ExtractDestination') IS NOT NULL DROP TABLE #ExtractDestination;
    IF OBJECT_ID(N'tempdb..#WriterDestination') IS NOT NULL DROP TABLE #WriterDestination;
   END;
   IF @Caught<>@Expected THROW 52097,N'ZIP route expected a different rights result.',7;
   IF @BeforeTc<>@@TRANCOUNT OR @BeforeXs<>XACT_STATE() THROW 52097,N'Caller transaction state changed.',8;
   IF @Expected=0 SET @Positive+=1 ELSE BEGIN SET @Denied+=1; IF @Expected=229 SET @Api229+=1 ELSE IF @Expected IN(51329,51357) SET @DependencyDenied+=1 ELSE SET @OtherDenied+=1; END;
   SET @Route+=1;
  END;

  -- Gegen-API, nicht erlaubte interne Provider und ResultTable-Helper bleiben strikt 229.
  DELETE @DeniedObjects;
  INSERT @DeniedObjects SELECT CONVERT(int,ROW_NUMBER() OVER(ORDER BY Id)),Probe FROM @Objects WHERE Id BETWEEN 1 AND 3 AND Id<>@Api;
  DECLARE @DeniedOffset int=(SELECT COUNT(*) FROM @DeniedObjects);
  INSERT @DeniedObjects SELECT @DeniedOffset+CONVERT(int,ROW_NUMBER() OVER(ORDER BY Id)),Probe FROM @Objects WHERE Id BETWEEN 4 AND 7 AND ISNULL(HAS_PERMS_BY_NAME(FullName,N'OBJECT',PermissionName),0)=0;
  SET @DeniedOffset=(SELECT COUNT(*) FROM @DeniedObjects);
  IF @Hg=0 INSERT @DeniedObjects SELECT @DeniedOffset+CONVERT(int,ROW_NUMBER() OVER(ORDER BY Id)),Probe FROM @Objects WHERE Id=8;
  DECLARE @ProbeOrdinal int=1,@ProbeCount int=(SELECT COUNT(*) FROM @DeniedObjects);
  WHILE @ProbeOrdinal<=@ProbeCount
  BEGIN
   SELECT @Probe=Probe FROM @DeniedObjects WHERE Ordinal=@ProbeOrdinal; SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Probe; END TRY BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=229; END CATCH;
   IF @Caught<>229 THROW 52097,N'Other public API, internal FT or core helper unexpectedly accessible.',9;
   SET @InternalDenied+=1; SET @ProbeOrdinal+=1;
  END;
  REVERT; SET @Impersonated=0; SET @Id+=1;
 END;
 IF @Positive<>8 OR @Denied<>28 OR @Api229<>12 OR @DependencyDenied<>16 OR @OtherDenied<>0 OR @InternalDenied<>105
  THROW 52097,N'Fixed ZIP caller probe counts mismatch.',10;
 DROP USER ContosoZipCaller; SET @Created=0;
END TRY
BEGIN CATCH IF @Impersonated=1 REVERT; IF @Created=1 DROP USER ContosoZipCaller; THROW; END CATCH;
IF USER_ID(N'ContosoZipCaller') IS NOT NULL THROW 52097,N'Owned caller principal remains.',11;
PRINT N'ZIP caller probe counts: positive=8, denied=28 (229=12, dependency=16), extra-denied=105; principal removed.';
