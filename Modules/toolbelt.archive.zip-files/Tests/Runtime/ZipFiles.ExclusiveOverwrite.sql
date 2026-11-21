-- The harness provides a fresh ContosoZipExclusive root with an exclusive
-- NTFS policy and two single-file archives with different synthetic bytes.
SET NOCOUNT ON;
IF CONVERT(nvarchar(40), CONNECTIONPROPERTY('auth_scheme')) NOT IN (N'NTLM', N'KERBEROS')
    THROW 54623, N'ZIP_EXCLUSIVE_WINDOWS_AUTH_REQUIRED', 1;

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
    @ZipArchive=@OriginalZip, @RootAlias=N'ContosoZipExclusive', @ExecutionIdentity=N'Caller',
    @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1
    OR NOT EXISTS(SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'replace.bin'
        AND EntryKind='file' AND Status='completed' AND BytesWritten=3 AND ErrorCode IS NULL)
    THROW 54623, N'ZIP_EXCLUSIVE_INITIAL_RESULT', 1;

INSERT #ReadBack EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipExclusive', @RelativePath=N'replace.bin', @MaxBytes=8, @ExecutionIdentity=N'Caller';
IF (SELECT COUNT(*) FROM #ReadBack)<>1
    OR NOT EXISTS(SELECT 1 FROM #ReadBack WHERE Content=0x010203 AND BytesRead=3 AND EndOfFile=1)
    THROW 54623, N'ZIP_EXCLUSIVE_INITIAL_BYTES', 1;

EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@ReplacementZip, @RootAlias=N'ContosoZipExclusive', @ExecutionIdentity=N'Caller',
    @OverwriteExistingFiles=1, @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1
    OR NOT EXISTS(SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'replace.bin'
        AND EntryKind='file' AND Status='completed' AND BytesWritten=2 AND ErrorCode IS NULL)
    THROW 54623, N'ZIP_EXCLUSIVE_REPLACEMENT_RESULT', 1;

DELETE FROM #ReadBack;
INSERT #ReadBack EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipExclusive', @RelativePath=N'replace.bin', @MaxBytes=8, @ExecutionIdentity=N'Caller';
IF (SELECT COUNT(*) FROM #ReadBack)<>1
    OR NOT EXISTS(SELECT 1 FROM #ReadBack WHERE Content=0x0405 AND BytesRead=2 AND EndOfFile=1)
    THROW 54623, N'ZIP_EXCLUSIVE_REPLACEMENT_BYTES', 1;

SELECT N'ZIP_EXCLUSIVE_SQL_PASS' AS Outcome, 5 AS Checks;
