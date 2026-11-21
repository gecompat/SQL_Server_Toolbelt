-- Uses the same synthetic ZIP as ZipFiles.Directory.Partial.sql.
-- The harness supplies an isolated root and a DB user with the service role.
SET NOCOUNT ON;
EXECUTE AS USER = N'ContosoZipServiceCaller';
BEGIN TRY
    IF USER_NAME() <> N'ContosoZipServiceCaller'
        OR ISNULL(IS_ROLEMEMBER(N'toolbelt_filesystem_service_account'),0) <> 1
        THROW 54623,N'ZIP_PARTIAL_SERVICE_ROLE_REQUIRED',1;

    CREATE TABLE #ArchiveRows
    (
        Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
        Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
    );
    EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
        @ZipArchive=@Zip, @RootAlias=N'ContosoZipServicePartial', @ExecutionIdentity=N'ServiceAccount', @ResultTable=N'#ArchiveRows';

    IF (SELECT COUNT(*) FROM #ArchiveRows)<>3 OR NOT EXISTS
    (
        SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'first.bin'
            AND EntryKind='file' AND Status='completed' AND BytesWritten=3 AND ErrorCode IS NULL
    )
        THROW 54623,N'ZIP_PARTIAL_COMPLETED_ASSERTION',1;
    IF NOT EXISTS
    (
        SELECT 1 FROM #ArchiveRows WHERE Ordinal=2 AND EntryName=N'second.bin'
            AND EntryKind='file' AND Status='failed' AND BytesWritten IS NULL AND ErrorCode='CRC_MISMATCH'
    )
        THROW 54623,N'ZIP_PARTIAL_CRC_ASSERTION',1;
    IF NOT EXISTS
    (
        SELECT 1 FROM #ArchiveRows WHERE Ordinal=3 AND EntryName=N'third.bin'
            AND EntryKind='file' AND Status='not_attempted' AND BytesWritten IS NULL AND ErrorCode IS NULL
    )
        THROW 54623,N'ZIP_PARTIAL_NOT_ATTEMPTED_ASSERTION',1;

    CREATE TABLE #ReadBack
    (
        Content varbinary(max), BytesRead int, NextByteOffset bigint, EndOfFile bit
    );
    INSERT #ReadBack
    EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
        @RootAlias=N'ContosoZipServicePartial', @RelativePath=N'first.bin',
        @MaxBytes=4, @ExecutionIdentity=N'ServiceAccount';
    IF (SELECT COUNT(*) FROM #ReadBack)<>1 OR NOT EXISTS
    (
        SELECT 1 FROM #ReadBack WHERE Content=0x010203 AND BytesRead=3 AND EndOfFile=1
    )
        THROW 54623,N'ZIP_PARTIAL_BYTES_ASSERTION',1;
END TRY
BEGIN CATCH
    REVERT;
    THROW;
END CATCH;
REVERT;

SELECT N'ZIP_DIRECTORY_PARTIAL_SERVICE_SQL_PASS' AS Outcome, 5 AS Checks;
