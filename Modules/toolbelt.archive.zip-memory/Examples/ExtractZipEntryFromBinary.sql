SET NOCOUNT ON;

/*
 * Synthetisches ZIP mit einem Stored-Entry "plain.txt" und Payload "HELLO".
 */
DECLARE @ZipStored varbinary(max) =
    0x504B030414000000000000002150366444C1050000000500000009000000706C61696E2E74787448454C4C4F504B0102140314000000000000002150366444C10500000005000000090000000000000000000000800100000000706C61696E2E747874504B05060000000001000100370000002C0000000000;

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipStored
    , @EntryName = N'plain.txt';

/*
 * Synthetisches ZIP mit einem Deflate-Entry "deflated.txt" und Payload
 * "HELLO FROM CLR DEFLATE". Der Provider prüft außerdem die Payload-CRC32.
 */
DECLARE @ZipDeflate varbinary(max) =
    0x504B0304140000000800000021502383920B18000000160000000C0000006465666C617465642E747874F370F5F1F157700BF2F75570F60952707175F3710C710500504B01021403140000000800000021502383920B18000000160000000C00000000000000000000008001000000006465666C617465642E747874504B050600000000010001003A000000420000000000;

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipDeflate
    , @EntryName = N'deflated.txt';

/* ResultTable-Pfad */
CREATE TABLE #ZipResult
(
      EntryName         nvarchar(1024) NOT NULL
    , CompressedBytes   bigint         NOT NULL
    , UncompressedBytes bigint         NOT NULL
    , CompressionMethod int            NOT NULL
    , Crc32             int            NULL
    , IsEncrypted       bit            NOT NULL
    , EntryPayload      varbinary(max) NULL
);

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipDeflate
    , @EntryName = N'deflated.txt'
    , @ResultTable = N'#ZipResult'
    , @KeepData = 0;

SELECT *
FROM #ZipResult;
