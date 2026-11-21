-- Uses the existing two-file stored ZIP. This fixture checks SQL/CLR argument
-- ceilings with small payloads; it does not measure maximum-sized workloads.
SET NOCOUNT ON;
DECLARE @Limits table
(
    Sequence int PRIMARY KEY, ArchiveBytes bigint, EntryCount bigint, EntryBytes bigint,
    PathLength int, ExpectedDiagnostic nvarchar(128)
);
INSERT @Limits VALUES
    (1,268435457,10000,67108864,1024,N'ZIP_INVALID_LIMIT MaxArchiveBytes MAX=268435456'),
    (2,268435456,10001,67108864,1024,N'ZIP_INVALID_LIMIT MaxEntries MAX=10000'),
    (3,268435456,10000,67108865,1024,N'ZIP_INVALID_LIMIT MaxEntryBytes MAX=67108864'),
    (4,268435456,10000,67108864,1025,N'ZIP_INVALID_LIMIT MaxPathLength MAX=1024');

CREATE TABLE #ArchiveRows
(
    Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
    Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
);
DECLARE @Sequence int=1, @Checks int=0, @ArchiveBytes bigint, @EntryCount bigint, @EntryBytes bigint,
    @PathLength int, @ExpectedDiagnostic nvarchar(128),
    @MaxTotal bigint=9223372036854775807, @MaxRatio decimal(9,2)=9999999.99;
WHILE @Sequence<=4
BEGIN
    SELECT @ArchiveBytes=ArchiveBytes, @EntryCount=EntryCount, @EntryBytes=EntryBytes,
        @PathLength=PathLength, @ExpectedDiagnostic=ExpectedDiagnostic
    FROM @Limits WHERE Sequence=@Sequence;
    BEGIN TRY
        EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
            @ZipArchive=@Zip, @RootAlias=N'ContosoZipCeilings', @ResultTable=N'#ArchiveRows',
            @MaxArchiveBytes=@ArchiveBytes, @MaxEntries=@EntryCount, @MaxEntryBytes=@EntryBytes,
            @MaxTotalExpandedBytes=@MaxTotal, @MaxPathLength=@PathLength, @MaxCompressionRatio=@MaxRatio;
        THROW 54623,N'ZIP_CEILING_OUT_OF_RANGE_WAS_ACCEPTED',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()<>6522 OR CHARINDEX(@ExpectedDiagnostic,ERROR_MESSAGE())=0 THROW;
    END CATCH;
    SET @Checks+=1;
    SET @Sequence+=1;
END;

DECLARE @AboveTotal decimal(19,0)=9223372036854775808;
BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
        @ZipArchive=@Zip, @RootAlias=N'ContosoZipCeilings', @ResultTable=N'#ArchiveRows',
        @MaxTotalExpandedBytes=@AboveTotal;
    THROW 54623,N'ZIP_CEILING_BIGINT_OVERFLOW_WAS_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (8114,8115) THROW;
END CATCH;
SET @Checks+=1;

DECLARE @AboveRatio decimal(10,2)=10000000.00;
BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
        @ZipArchive=@Zip, @RootAlias=N'ContosoZipCeilings', @ResultTable=N'#ArchiveRows',
        @MaxCompressionRatio=@AboveRatio;
    THROW 54623,N'ZIP_CEILING_DECIMAL_OVERFLOW_WAS_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT IN (8114,8115) THROW;
END CATCH;
SET @Checks+=1;

IF EXISTS(SELECT 1 FROM #ArchiveRows)
    THROW 54623,N'ZIP_CEILING_REJECTION_PUBLISHED_RESULT_ROWS',1;

-- The same targets must remain available with overwrite off.
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip, @RootAlias=N'ContosoZipCeilings', @ResultTable=N'#ArchiveRows',
    @MaxArchiveBytes=268435456, @MaxEntries=10000, @MaxEntryBytes=67108864,
    @MaxTotalExpandedBytes=@MaxTotal, @MaxPathLength=1024, @MaxCompressionRatio=@MaxRatio;
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
    THROW 54623,N'ZIP_CEILING_EXACT_BOUNDARY_ASSERTION',1;

SELECT N'ZIP_DIRECTORY_CEILINGS_SQL_PASS' AS Outcome, @Checks+1 AS Checks;
