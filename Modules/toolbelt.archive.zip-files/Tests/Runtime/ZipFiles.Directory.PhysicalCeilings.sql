-- Synthetic Stored ZIPs and headers come from Build-ZipDirectoryPhysicalFixtures.py.
-- Assemble the large payload inside SQL Server so the lab transport stays small.
SET NOCOUNT ON;
DECLARE @Checks int=0, @Zip varbinary(max), @Length bigint,
    @EntryMaximum int=67108864, @ArchiveMaximum int=268435456;
CREATE TABLE #ArchiveRows
(
    Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
    Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
);
DECLARE @Payload varbinary(max)=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'A'),@EntryMaximum));
SET @Zip=CONVERT(varbinary(max),@EntryHeader)+@Payload+0x41+@EntrySuffix;
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip, @RootAlias=N'ContosoZipPhysical', @RelativeDirectory=N'volume',
    @MaxEntryBytes=@EntryMaximum, @MaxArchiveBytes=@ArchiveMaximum, @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1 OR NOT EXISTS
(
    SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'oversize.bin'
        AND Status='failed' AND ErrorCode='ENTRY_SIZE_LIMIT' AND BytesWritten IS NULL
)
    THROW 54623,N'ZIP_PHYSICAL_ENTRY_PLUS_ONE_ASSERTION',1;
SET @Checks+=1;

DECLARE @LastLength int=@ArchiveMaximum-3*@EntryMaximum-
    (DATALENGTH(@VolumeHeader0)+DATALENGTH(@VolumeHeader1)+DATALENGTH(@VolumeHeader2)
     +DATALENGTH(@VolumeHeader3)+DATALENGTH(@VolumeSuffix));
SET @Zip=CONVERT(varbinary(max),@VolumeHeader0)+@Payload+@VolumeHeader1+@Payload+
    @VolumeHeader2+@Payload+@VolumeHeader3+SUBSTRING(@Payload,1,@LastLength)+@VolumeSuffix;
SET @Payload=NULL;
SET @Length=DATALENGTH(@Zip);
IF @Length<>@ArchiveMaximum THROW 54623,N'ZIP_PHYSICAL_ARCHIVE_FIXTURE_LENGTH',1;

-- Replace the EOCD comment length (zero) with one and add a comment byte.
SET @Zip=SUBSTRING(@Zip,1,@Length-2)+0x010000;
IF DATALENGTH(@Zip)<>@ArchiveMaximum+1 THROW 54623,N'ZIP_PHYSICAL_ARCHIVE_PLUS_ONE_LENGTH',1;
BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
        @ZipArchive=@Zip, @RootAlias=N'ContosoZipPhysical', @RelativeDirectory=N'volume',
        @MaxEntryBytes=@EntryMaximum, @MaxArchiveBytes=@ArchiveMaximum, @ResultTable=N'#ArchiveRows';
    THROW 54623,N'ZIP_PHYSICAL_ARCHIVE_PLUS_ONE_WAS_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>6522 OR CHARINDEX(N'ZIP_ARCHIVE_LIMIT',ERROR_MESSAGE())=0 THROW;
END CATCH;
SET @Checks+=1;

SET @Zip=SUBSTRING(@Zip,1,@Length-2)+0x0000;
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip, @RootAlias=N'ContosoZipPhysical', @RelativeDirectory=N'volume',
    @MaxEntryBytes=@EntryMaximum, @MaxArchiveBytes=@ArchiveMaximum, @ResultTable=N'#ArchiveRows';
SET @Zip=NULL;
IF (SELECT COUNT(*) FROM #ArchiveRows)<>4 OR EXISTS
(
    SELECT 1 FROM #ArchiveRows WHERE EntryKind<>'file' OR Status<>'completed'
        OR ErrorCode IS NOT NULL OR BytesWritten IS NULL
        OR BytesWritten<>CASE WHEN Ordinal=4 THEN @LastLength ELSE @EntryMaximum END
)
    THROW 54623,N'ZIP_PHYSICAL_ARCHIVE_AND_ENTRY_AT_MAX_ASSERTION',1;
SET @Checks+=2;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
        @ZipArchive=@Count10001, @RootAlias=N'ContosoZipPhysical', @RelativeDirectory=N'count',
        @MaxEntries=10000, @ResultTable=N'#ArchiveRows';
    THROW 54623,N'ZIP_PHYSICAL_COUNT_PLUS_ONE_WAS_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>6522 OR CHARINDEX(N'ZIP_ENTRY_COUNT_LIMIT',ERROR_MESSAGE())=0 THROW;
END CATCH;
SET @Checks+=1;

EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Count10000, @RootAlias=N'ContosoZipPhysical', @RelativeDirectory=N'count',
    @MaxEntries=10000, @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows WHERE EntryKind='file' AND Status='completed'
    AND BytesWritten=0 AND ErrorCode IS NULL)<>10000 OR (SELECT COUNT(*) FROM #ArchiveRows)<>10000
    THROW 54623,N'ZIP_PHYSICAL_COUNT_AT_MAX_ASSERTION',1;
SET @Checks+=1;

EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Path1025, @RootAlias=N'ContosoZipPhysical', @RelativeDirectory=N'path',
    @MaxPathLength=1024, @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1 OR NOT EXISTS
(
    SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND DATALENGTH(EntryName)=2050
        AND Status='failed' AND ErrorCode='ENTRY_NAME_LIMIT' AND BytesWritten IS NULL
)
    THROW 54623,N'ZIP_PHYSICAL_PATH_PLUS_ONE_ASSERTION',1;
SET @Checks+=1;

EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Path1024, @RootAlias=N'ContosoZipPhysical', @RelativeDirectory=N'path',
    @MaxPathLength=1024, @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1 OR NOT EXISTS
(
    SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND DATALENGTH(EntryName)=2048
        AND EntryKind='file' AND Status='completed' AND BytesWritten=0 AND ErrorCode IS NULL
)
    THROW 54623,N'ZIP_PHYSICAL_PATH_AT_MAX_ASSERTION',1;
SET @Checks+=1;

SELECT N'ZIP_DIRECTORY_PHYSICAL_SQL_PASS' AS Outcome, @Checks AS Checks;
