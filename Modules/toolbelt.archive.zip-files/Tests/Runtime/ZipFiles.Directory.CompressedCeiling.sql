-- A valid DEFLATE stream made of non-final empty Stored blocks and a final
-- fixed-Huffman block containing one or two ASCII A bytes. The archives use
-- one entry each. BLOB construction happens inside SQL Server.
SET NOCOUNT ON;
DECLARE @Blocks varbinary(max)=CONVERT(varbinary(max),REPLICATE(
    CONVERT(varchar(max),0x000000FFFF),26843545));
IF DATALENGTH(@Blocks)<>134217725
    THROW 54623,N'ZIP_COMPRESSED_BLOCK_LENGTH',1;
DECLARE @Zip varbinary(max)=CONVERT(varbinary(max),@AboveHeader)+@Blocks+0x73740400+@AboveSuffix;
IF DATALENGTH(@Zip)<>134217729+DATALENGTH(@AboveHeader)+DATALENGTH(@AboveSuffix)
    THROW 54623,N'ZIP_COMPRESSED_ABOVE_FIXTURE_LENGTH',1;

CREATE TABLE #ArchiveRows
(
    Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
    Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
);
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip, @RootAlias=N'ContosoZipCompressed', @MaxArchiveBytes=268435456,
    @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1 OR NOT EXISTS
(
    SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'first.bin'
        AND Status='failed' AND ErrorCode='ENTRY_SIZE_LIMIT' AND BytesWritten IS NULL
)
    THROW 54623,N'ZIP_COMPRESSED_PLUS_ONE_ASSERTION',1;

SET @Zip=CONVERT(varbinary(max),@MaxHeader)+@Blocks+0x730400+@MaxSuffix;
IF DATALENGTH(@Zip)<>134217728+DATALENGTH(@MaxHeader)+DATALENGTH(@MaxSuffix)
    THROW 54623,N'ZIP_COMPRESSED_MAX_FIXTURE_LENGTH',1;
SET @Blocks=NULL;
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip, @RootAlias=N'ContosoZipCompressed', @MaxArchiveBytes=268435456,
    @ResultTable=N'#ArchiveRows';
IF (SELECT COUNT(*) FROM #ArchiveRows)<>1 OR NOT EXISTS
(
    SELECT 1 FROM #ArchiveRows WHERE Ordinal=1 AND EntryName=N'first.bin'
        AND EntryKind='file' AND Status='completed' AND BytesWritten=1 AND ErrorCode IS NULL
)
    THROW 54623,N'ZIP_COMPRESSED_AT_MAX_ASSERTION',1;

SELECT N'ZIP_DIRECTORY_COMPRESSED_SQL_PASS' AS Outcome, 2 AS Checks;
