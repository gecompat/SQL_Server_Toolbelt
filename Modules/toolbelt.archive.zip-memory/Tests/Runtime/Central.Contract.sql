SET NOCOUNT ON;

DECLARE @ZipArchive varbinary(max) =
    0x504B03041400000000000000000000000000050000000500000009000000706C61696E2E74787448454C4C4F504B01021400140000000000000000000000000500000005000000090000000000000000000000000000000000706C61696E2E747874504B05060000000001000100370000002C0000000000;

DECLARE @Result TABLE
(
      EntryName nvarchar(1024) NOT NULL
    , CompressedBytes bigint NOT NULL
    , UncompressedBytes bigint NOT NULL
    , CompressionMethod int NOT NULL
    , Crc32 int NULL
    , IsEncrypted bit NOT NULL
    , EntryPayload varbinary(max) NULL
);

INSERT INTO @Result
EXEC [$(ToolbeltDatabase)].toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipArchive
    , @EntryName = N'plain.txt';

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'plain.txt'
         AND EntryPayload = 0x48454C4C4F
   )
    THROW 51383, N'Der zentrale ZIP-Memory-Aufruf ist fehlgeschlagen.', 1;

PRINT N'ZIP Memory Central-Contract-Pruefung: erfolgreich';
GO
