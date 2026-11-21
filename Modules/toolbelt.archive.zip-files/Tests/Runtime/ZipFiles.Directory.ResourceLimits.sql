-- The harness supplies a stored ZIP with first.bin (3 bytes) and
-- second.bin (2 bytes) in that order. Both files must be absent initially.
SET NOCOUNT ON;
DECLARE @ArchiveBytes bigint=DATALENGTH(@Zip);
CREATE TABLE #ArchiveRows
(
    Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
    Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
);

DECLARE @Limits table
(
    Sequence int PRIMARY KEY, ArchiveBytes bigint, EntryCount bigint, EntryBytes bigint,
    TotalBytes bigint, PathLength int, FailureOrdinal int, ExpectedError varchar(64)
);
INSERT @Limits VALUES
    (1,@ArchiveBytes-1,2,3,5,10,NULL,'ZIP_ARCHIVE_LIMIT'),
    (2,@ArchiveBytes,  1,3,5,10,NULL,'ZIP_ENTRY_COUNT_LIMIT'),
    (3,@ArchiveBytes,  2,2,5,10,1,   'ENTRY_SIZE_LIMIT'),
    (4,@ArchiveBytes,  2,3,4,10,2,   'TOTAL_SIZE_LIMIT'),
    (5,@ArchiveBytes,  2,3,5, 9,2,   'ENTRY_NAME_LIMIT');

DECLARE @Sequence int=1, @Checks int=0, @Bytes bigint, @Entries bigint,
    @EntryBytes bigint, @TotalBytes bigint, @PathLength int,
    @FailureOrdinal int, @ExpectedError varchar(64), @Caught bit;
WHILE @Sequence<=5
BEGIN
    SELECT @Bytes=ArchiveBytes,@Entries=EntryCount,@EntryBytes=EntryBytes,
        @TotalBytes=TotalBytes,@PathLength=PathLength,
        @FailureOrdinal=FailureOrdinal,@ExpectedError=ExpectedError
    FROM @Limits WHERE Sequence=@Sequence;

    TRUNCATE TABLE #ArchiveRows;
    SET @Caught=0;
    BEGIN TRY
        EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
            @ZipArchive=@Zip, @RootAlias=N'ContosoZipLimits', @ResultTable=N'#ArchiveRows',
            @MaxArchiveBytes=@Bytes, @MaxEntries=@Entries, @MaxEntryBytes=@EntryBytes,
            @MaxTotalExpandedBytes=@TotalBytes, @MaxPathLength=@PathLength, @MaxCompressionRatio=1.00;
    END TRY
    BEGIN CATCH
        IF @FailureOrdinal IS NOT NULL OR ERROR_NUMBER()<>6522
            OR CHARINDEX(@ExpectedError,ERROR_MESSAGE())=0 THROW;
        SET @Caught=1;
    END CATCH;

    IF @FailureOrdinal IS NULL
    BEGIN
        IF @Caught=0 OR EXISTS(SELECT 1 FROM #ArchiveRows)
            THROW 54623,N'ZIP_LIMITS_GLOBAL_REJECTION_ASSERTION',1;
    END
    ELSE IF (SELECT COUNT(*) FROM #ArchiveRows)<>2 OR NOT EXISTS
    (
        SELECT 1 FROM #ArchiveRows WHERE Ordinal=@FailureOrdinal
            AND Status='failed' AND ErrorCode=@ExpectedError AND BytesWritten IS NULL
    )
    OR NOT EXISTS
    (
        SELECT 1 FROM #ArchiveRows WHERE Ordinal=3-@FailureOrdinal
            AND Status='not_attempted' AND ErrorCode IS NULL AND BytesWritten IS NULL
    )
        THROW 54623,N'ZIP_LIMITS_ENTRY_REJECTION_ASSERTION',1;

    SET @Checks+=1;
    SET @Sequence+=1;
END;

-- Successful publication to the same empty root also rules out any final
-- file left at either target by a rejected call, because overwrite is off.
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip, @RootAlias=N'ContosoZipLimits', @ResultTable=N'#ArchiveRows',
    @MaxArchiveBytes=@ArchiveBytes, @MaxEntries=2, @MaxEntryBytes=3,
    @MaxTotalExpandedBytes=5, @MaxPathLength=10, @MaxCompressionRatio=1.00;
IF (SELECT COUNT(*) FROM #ArchiveRows)<>2 OR NOT EXISTS
(
    SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'first.bin'
        AND Status='completed' AND ErrorCode IS NULL AND BytesWritten=3
)
OR NOT EXISTS
(
    SELECT 1 FROM #ArchiveRows WHERE Ordinal=2 AND EntryName=N'second.bin'
        AND Status='completed' AND ErrorCode IS NULL AND BytesWritten=2
)
    THROW 54623,N'ZIP_LIMITS_EXACT_BOUNDARY_ASSERTION',1;

SELECT N'ZIP_DIRECTORY_LIMITS_SQL_PASS' AS Outcome, @Checks+1 AS Checks;
