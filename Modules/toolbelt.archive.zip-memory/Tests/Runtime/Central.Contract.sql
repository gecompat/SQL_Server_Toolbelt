SET NOCOUNT ON;

DECLARE @ZipArchive varbinary(max) =
    0x504B0304140000000800000021502383920B18000000160000000C0000006465666C617465642E747874F370F5F1F157700BF2F75570F60952707175F3710C710500504B01021403140000000800000021502383920B18000000160000000C00000000000000000000008001000000006465666C617465642E747874504B050600000000010001003A000000420000000000;

DECLARE @Result TABLE
(
      EntryName         nvarchar(1024) NOT NULL
    , CompressedBytes   bigint         NOT NULL
    , UncompressedBytes bigint         NOT NULL
    , CompressionMethod int            NOT NULL
    , Crc32             int            NULL
    , IsEncrypted       bit            NOT NULL
    , EntryPayload      varbinary(max) NULL
);

INSERT INTO @Result
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipArchive
    , @EntryName = N'deflated.txt';

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'deflated.txt'
         AND CompressionMethod = 8
         AND Crc32 = 194151203
         AND IsEncrypted = 0
         AND EntryPayload =
             0x48454C4C4F2046524F4D20434C52204445464C415445
   )
    THROW 51385, N'Der zentrale CLR-Deflate-Aufruf ist fehlgeschlagen.', 1;

PRINT N'ZIP Memory CLR Central-Contract-Prüfung: erfolgreich';
GO
