-- The harness supplies one new root protected for the SQL service identity
-- and two single-file archives with different synthetic bytes.
SET NOCOUNT ON;
EXECUTE AS USER = N'ContosoZipServiceCaller';
IF USER_NAME() <> N'ContosoZipServiceCaller'
    OR ISNULL(IS_ROLEMEMBER(N'toolbelt_filesystem_service_account'),0) <> 1
    THROW 54623, N'ZIP_EXCLUSIVE_SERVICE_ROLE_REQUIRED', 1;

CREATE TABLE #ArchiveRows
(
    Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
    Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
);
CREATE TABLE #ReadBack
(
    Content varbinary(max), BytesRead int, NextByteOffset bigint, EndOfFile bit
);

EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@OriginalZip, @RootAlias=N'ContosoZipServiceExclusive', @ExecutionIdentity=N'ServiceAccount',
    @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1
    OR NOT EXISTS(SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'replace.bin'
        AND EntryKind='file' AND Status='completed' AND BytesWritten=3 AND ErrorCode IS NULL)
    THROW 54623, N'ZIP_EXCLUSIVE_INITIAL_RESULT', 1;

INSERT #ReadBack EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipServiceExclusive', @RelativePath=N'replace.bin', @MaxBytes=8, @ExecutionIdentity=N'ServiceAccount';
IF (SELECT COUNT(*) FROM #ReadBack)<>1
    OR NOT EXISTS(SELECT 1 FROM #ReadBack WHERE Content=0x010203 AND BytesRead=3 AND EndOfFile=1)
    THROW 54623, N'ZIP_EXCLUSIVE_INITIAL_BYTES', 1;

EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@ReplacementZip, @RootAlias=N'ContosoZipServiceExclusive', @ExecutionIdentity=N'ServiceAccount',
    @OverwriteExistingFiles=1, @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1
    OR NOT EXISTS(SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'replace.bin'
        AND EntryKind='file' AND Status='completed' AND BytesWritten=2 AND ErrorCode IS NULL)
    THROW 54623, N'ZIP_EXCLUSIVE_REPLACEMENT_RESULT', 1;

DELETE FROM #ReadBack;
INSERT #ReadBack EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipServiceExclusive', @RelativePath=N'replace.bin', @MaxBytes=8, @ExecutionIdentity=N'ServiceAccount';
IF (SELECT COUNT(*) FROM #ReadBack)<>1
    OR NOT EXISTS(SELECT 1 FROM #ReadBack WHERE Content=0x0405 AND BytesRead=2 AND EndOfFile=1)
    THROW 54623, N'ZIP_EXCLUSIVE_REPLACEMENT_BYTES', 1;

REVERT;
SELECT N'ZIP_EXCLUSIVE_SERVICE_SQL_PASS' AS Outcome, 5 AS Checks;
