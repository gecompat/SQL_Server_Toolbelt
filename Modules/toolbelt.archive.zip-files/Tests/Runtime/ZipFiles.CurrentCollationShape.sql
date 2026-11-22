-- Use a fresh CS or BIN2 database and its owned root ContosoZipShape.
SET NOCOUNT ON;
IF CONVERT(sysname,DATABASEPROPERTYEX(DB_NAME(),'Collation'))<>@ExpectedCollation
    OR CONVERT(sysname,DATABASEPROPERTYEX(DB_NAME(),'Collation'))=CONVERT(sysname,DATABASEPROPERTYEX('tempdb','Collation'))
    THROW 54701,N'ZIP_SHAPE_COLLATION_BINDING',1;
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max) COLLATE DATABASE_DEFAULT,Payload varbinary(max));
INSERT #Entries VALUES(1,N'First.bin',0x11),(2,N'first.bin',0x22);
CREATE TABLE #Write
(
    BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,
    RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL
);
CREATE INDEX IX_ZipShape ON #Write(BytesWritten);
EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',
    @RootAlias=N'ContosoZipShape',@RelativePath=N'first.zip',@ResultTable=N'#Write';
CREATE TABLE #Read(Content varbinary(max),BytesRead int,NextByteOffset bigint,EndOfFile bit);
INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipShape',@RelativePath=N'first.zip';
DECLARE @Zip varbinary(max)=(SELECT Content FROM #Read WHERE EndOfFile=1);
IF @Zip IS NULL THROW 54702,N'ZIP_SHAPE_ARCHIVE_READBACK',1;

EXEC toolbelt_archive.USP_ExtractZipEntryToFile
    @ZipArchive=@Zip,@EntryName=N'First.bin',@RootAlias=N'ContosoZipShape',@RelativePath=N'upper.bin',
    @ResultTable=N'#Write',@KeepData=1;
EXEC toolbelt_archive.USP_ExtractZipEntryToFile
    @ZipArchive=@Zip,@EntryName=N'first.bin',@RootAlias=N'ContosoZipShape',@RelativePath=N'lower.bin',
    @ResultTable=N'#Write',@KeepData=1;
IF (SELECT COUNT(*) FROM #Write WHERE State='completed')<>3 OR NOT EXISTS
(
    SELECT 1 FROM tempdb.sys.indexes WHERE object_id=OBJECT_ID('tempdb..#Write') AND name=N'IX_ZipShape'
)
    THROW 54703,N'ZIP_SHAPE_INDEX_PRESERVATION',1;

DELETE #Read;
INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipShape',@RelativePath=N'upper.bin';
IF (SELECT COUNT(*) FROM #Read WHERE Content=0x11 AND BytesRead=1 AND EndOfFile=1)<>1
    THROW 54704,N'ZIP_SHAPE_ORDINAL_UPPER',1;
DELETE #Read;
INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipShape',@RelativePath=N'lower.bin';
IF (SELECT COUNT(*) FROM #Read WHERE Content=0x22 AND BytesRead=1 AND EndOfFile=1)<>1
    THROW 54705,N'ZIP_SHAPE_ORDINAL_LOWER',1;

CREATE TABLE #Dir
(
    Ordinal bigint NOT NULL,EntryName nvarchar(max) NOT NULL,EntryKind varchar(9) NOT NULL,
    Status varchar(16) NOT NULL,BytesWritten bigint NULL,ErrorCode varchar(64) NULL
);
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip,@RootAlias=N'ContosoZipShape',@ResultTable=N'#Dir';
IF (SELECT COUNT(*) FROM #Dir)<>2
   OR (SELECT COUNT(*) FROM #Dir WHERE Status='failed' AND ErrorCode='PATH_COLLISION')<>1
   OR (SELECT COUNT(*) FROM #Dir WHERE Status='not_attempted' AND ErrorCode IS NULL)<>1
   OR EXISTS(SELECT 1 FROM #Dir WHERE BytesWritten IS NOT NULL)
    THROW 54706,N'ZIP_SHAPE_NTFS_CASE_COLLISION',1;

CREATE TABLE #Blocked(Dummy int NOT NULL);
CREATE INDEX IX_ZipBlocked ON #Blocked(Dummy);
INSERT #Blocked VALUES(42);
BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryToFile
        @ZipArchive=@Zip,@EntryName=N'first.bin',@RootAlias=N'ContosoZipShape',
        @RelativePath=N'blocked.bin',@ResultTable=N'#Blocked',@KeepData=0;
    THROW 54707,N'ZIP_SHAPE_INDEX_BLOCKER_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51026 THROW;
END CATCH;
DECLARE @ObservedCount int=@@TRANCOUNT,@ObservedState int=XACT_STATE();
IF @ObservedCount<>0 OR @ObservedState=-1
    THROW 54710,N'ZIP_SHAPE_BLOCKER_TRANSACTION',1;
IF (SELECT COUNT(*) FROM #Blocked WHERE Dummy=42)<>1 OR NOT EXISTS
(
    SELECT 1 FROM tempdb.sys.indexes WHERE object_id=OBJECT_ID('tempdb..#Blocked') AND name=N'IX_ZipBlocked'
)

    THROW 54708,N'ZIP_SHAPE_BLOCKER_STATE',1;

IF @CheckHelp=1
BEGIN
    BEGIN TRANSACTION;
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1,@Debug=255,@EntryTable=N'#missing';
    EXEC toolbelt_archive.USP_ExtractZipEntryToFile @Hilfe=1,@Debug=255,@ZipArchive=NULL;
    EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory @Hilfe=1,@Debug=255,@ZipArchive=NULL;
    IF @@TRANCOUNT<>1 OR XACT_STATE()<>1 THROW 54709,N'ZIP_SHAPE_HELP_TRANSACTION',1;
    ROLLBACK TRANSACTION;
    SELECT ObjectName,SkillMarkdown
    FROM toolbelt_metadata.VW_ObjectUsageSkills
    WHERE SchemaName=N'toolbelt_archive' AND ObjectName IN
      (N'USP_CreateZipFileFromEntries',N'USP_ExtractZipEntryToFile',N'USP_ExtractZipArchiveToDirectory');
END;
SELECT N'ZIP_COLLATION_SHAPE_SQL_PASS' AS Outcome,6 AS Checks;
