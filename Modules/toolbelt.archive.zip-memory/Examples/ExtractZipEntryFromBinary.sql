SET NOCOUNT ON;

/*
 * Synthetisches ZIP mit einem Stored-Entry "plain.txt" und Payload "HELLO".
 */
DECLARE @ZipArchive varbinary(max) =
    0x504B030414000000000000000000366444C1050000000500000009000000706C61696E2E74787448454C4C4F504B0102140014000000000000000000366444C10500000005000000090000000000000000000000000000000000706C61696E2E747874504B05060000000001000100370000002C0000000000;

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipArchive
    , @EntryName = N'plain.txt';

/* ResultTable-Pfad */
CREATE TABLE #ZipResult
(
      EntryName nvarchar(1024) NOT NULL
    , CompressedBytes bigint NOT NULL
    , UncompressedBytes bigint NOT NULL
    , CompressionMethod int NOT NULL
    , Crc32 int NULL
    , IsEncrypted bit NOT NULL
    , EntryPayload varbinary(max) NULL
);

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipArchive
    , @EntryName = N'plain.txt'
    , @ResultTable = N'#ZipResult'
    , @KeepData = 0;

SELECT *
FROM #ZipResult;
