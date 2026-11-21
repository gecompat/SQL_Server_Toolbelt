-- Approved disposable user ContosoZipServiceCaller and service-owned root.
SET NOCOUNT ON;
EXECUTE AS USER=N'ContosoZipServiceCaller';
BEGIN TRY
    IF USER_NAME()<>N'ContosoZipServiceCaller'
        OR ISNULL(IS_ROLEMEMBER(N'toolbelt_filesystem_service_account'),0)<>1
        THROW 54690,N'ZIP_LEGACY_SERVICE_ROLE',1;

    CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
    INSERT #Entries VALUES(1,N'first.bin',0x010203);
    CREATE TABLE #Result
    (
        BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,
        RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL
    );
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries
        @EntryTable=N'#Entries',@RootAlias=N'ContosoZipLegacyService',@RelativePath=N'first.zip',
        @ExecutionIdentity=N'ServiceAccount',@ResultTable=N'#Result';
    IF (SELECT COUNT(*) FROM #Result WHERE RelativePath=N'first.zip' AND State='completed' AND BytesWritten>22)<>1
        THROW 54690,N'ZIP_LEGACY_SERVICE_WRITER_RESULT',1;

    CREATE TABLE #Read(Content varbinary(max),BytesRead int,NextByteOffset bigint,EndOfFile bit);
    INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
        @RootAlias=N'ContosoZipLegacyService',@RelativePath=N'first.zip',@ExecutionIdentity=N'ServiceAccount';
    DECLARE @Archive varbinary(max)=(SELECT Content FROM #Read WHERE EndOfFile=1);
    IF DATALENGTH(@Archive) IS NULL OR DATALENGTH(@Archive)<>(SELECT BytesWritten FROM #Result)
        THROW 54690,N'ZIP_LEGACY_SERVICE_ARCHIVE_READBACK',1;

    EXEC toolbelt_archive.USP_ExtractZipEntryToFile
        @ZipArchive=@Archive,@EntryName=N'first.bin',@RootAlias=N'ContosoZipLegacyService',
        @RelativePath=N'first.bin',@ExecutionIdentity=N'ServiceAccount',@ResultTable=N'#Result';
    IF (SELECT COUNT(*) FROM #Result WHERE RelativePath=N'first.bin' AND State='completed' AND BytesWritten=3)<>1
        THROW 54690,N'ZIP_LEGACY_SERVICE_READER_RESULT',1;

    DELETE #Read;
    INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
        @RootAlias=N'ContosoZipLegacyService',@RelativePath=N'first.bin',
        @ExecutionIdentity=N'ServiceAccount',@MaxBytes=4;
    IF (SELECT COUNT(*) FROM #Read WHERE Content=0x010203 AND BytesRead=3 AND EndOfFile=1)<>1
        THROW 54690,N'ZIP_LEGACY_SERVICE_ENTRY_READBACK',1;
END TRY
BEGIN CATCH
    REVERT;
    THROW;
END CATCH;
REVERT;

SELECT N'ZIP_LEGACY_SERVICE_SQL_PASS' AS Outcome,5 AS Checks;
