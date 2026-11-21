-- Windows integration fixture. The harness owns and audits the empty root
-- ContosoZip, supplies the two synthetic archives and runs without a caller TX.
SET NOCOUNT ON;
DECLARE @Checks int=0;
CREATE TABLE #ArchiveRows
(
    Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
    Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
);
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip, @RootAlias=N'ContosoZip', @RelativeDirectory=N'output',
    @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>2
    OR NOT EXISTS(SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryKind='file'
        AND EntryName=N'nested/sample.txt' AND Status='completed' AND BytesWritten=3 AND ErrorCode IS NULL)
    OR NOT EXISTS(SELECT 1 FROM #ArchiveRows WHERE Ordinal=2 AND EntryKind='directory'
        AND EntryName=N'empty/' AND Status='completed' AND BytesWritten=0 AND ErrorCode IS NULL)
    THROW 54623,N'ZIP_DIRECTORY_RESULT_ASSERTION',1;
SET @Checks+=1;

CREATE TABLE #ReadBack
(
    Content varbinary(max), BytesRead int, NextByteOffset bigint, EndOfFile bit
);
INSERT #ReadBack
EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZip', @RelativePath=N'output\nested\sample.txt',
    @MaxBytes=4, @ExecutionIdentity=N'Caller';
IF NOT EXISTS(SELECT 1 FROM #ReadBack WHERE Content=0x010203 AND BytesRead=3 AND EndOfFile=1)
    THROW 54623,N'ZIP_DIRECTORY_BYTES_ASSERTION',1;
SET @Checks+=1;

EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@ConflictingZip, @RootAlias=N'ContosoZip', @RelativeDirectory=N'output',
    @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>2
    OR NOT EXISTS(SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND Status='not_attempted' AND BytesWritten IS NULL)
    OR NOT EXISTS(SELECT 1 FROM #ArchiveRows WHERE Ordinal=2 AND Status='failed' AND ErrorCode='TARGET_EXISTS')
    THROW 54623,N'ZIP_DIRECTORY_PREFLIGHT_ASSERTION',1;
SET @Checks+=1;

BEGIN TRANSACTION;
BEGIN TRY
    EXEC toolbelt_filesystem.CLR_ExtractZipArchiveToDirectory @ZipArchive=@Zip, @RootAlias=N'ContosoZip';
    THROW 54623,N'ZIP_DIRECTORY_DIRECT_TX_WAS_ACCEPTED',1;
END TRY
BEGIN CATCH
    DECLARE @DirectTxRejected bit=CASE WHEN ERROR_NUMBER()=6522
        AND CHARINDEX(N'ARCHIVE_TRANSACTION_FORBIDDEN', ERROR_MESSAGE())>0 THEN 1 ELSE 0 END;
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    IF @DirectTxRejected=0 THROW;
END CATCH;
SET @Checks+=1;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
        @ZipArchive=@Zip, @RootAlias=N'ContosoZip', @OverwriteExistingFiles=1;
    THROW 54623,N'ZIP_DIRECTORY_OVERWRITE_WITHOUT_POLICY',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>6522 OR CHARINDEX(N'OVERWRITE_EXCLUSIVITY_REQUIRED', ERROR_MESSAGE())=0 THROW;
END CATCH;
SET @Checks+=1;

SELECT N'ZIP_DIRECTORY_SQL_PASS' AS Outcome, @Checks AS Checks;
