-- Inputs and independent ZIP metadata are supplied by the runner.
SET NOCOUNT ON;
CREATE TABLE #ZipEntryBoundary
(
    EntryName nvarchar(1024) NOT NULL, CompressedBytes bigint NOT NULL, UncompressedBytes bigint NOT NULL,
    CompressionMethod int NOT NULL, Crc32 int NULL, IsEncrypted bit NOT NULL, EntryPayload varbinary(max) NULL
);

BEGIN TRY
    EXEC [__ZIP_TARGET__].toolbelt_archive.USP_ExtractZipEntryFromBinary
        @ZipArchive=@Input,@EntryName=N'payload.txt',@MaxEntryBytes=67108864,@ResultTable=N'#ZipEntryBoundary';
    IF @Overflow=1 THROW 54749,N'ZIP_READER_LIMIT_NOT_ENFORCED',1;
END TRY
BEGIN CATCH
    IF @Overflow=0 OR ERROR_NUMBER()<>51325 OR ERROR_STATE()<>1 OR ERROR_MESSAGE() NOT LIKE @ExpectedError
        THROW;
END CATCH;

IF @Overflow=1
BEGIN
    IF EXISTS (SELECT 1 FROM #ZipEntryBoundary) THROW 54750,N'ZIP_READER_PARTIAL_OUTPUT',1;
END
ELSE
BEGIN
    IF (SELECT COUNT(*) FROM #ZipEntryBoundary)<>1 OR NOT EXISTS
    (
        SELECT 1 FROM #ZipEntryBoundary
        WHERE EntryName=N'payload.txt' AND CompressedBytes=@Packed AND UncompressedBytes=@Expanded
            AND CompressionMethod=@Method AND Crc32=@Crc AND IsEncrypted=0
            AND DATALENGTH(EntryPayload)=@Expanded AND HASHBYTES('SHA2_256',EntryPayload)=@Digest
    )
        THROW 54751,N'ZIP_READER_ENTRY_CONTENT',1;
END;

SELECT N'ZIP_PORTABLE_READER_CEILING_PASS' AS Outcome,1 AS Checks;
