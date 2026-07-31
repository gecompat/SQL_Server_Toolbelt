SET NOCOUNT ON;

/*
 * Der Entry-Name "Grüße.txt" ist ohne UTF-8-Flag in CP437 kodiert:
 * Rohname: 0x477281E1652E747874; ü = 0x81, ß = 0xE1.
 * Der Payload "Österreich" ist unverändert UTF-8-Binärinhalt.
 */
DECLARE @ZipCp437 varbinary(max) =
    0x504B030414000000080000000000FE397C240D0000000B00000009000000477281E1652E7478743B3CADB824B5A8283533390300504B0102140314000000080000000000FE397C240D0000000B000000090000000000000000000000800100000000477281E1652E747874504B0506000000000100010037000000340000000000;

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
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipCp437
    , @EntryName = N'Grüße.txt';

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'Grüße.txt'
         AND CompressionMethod = 8
         AND Crc32 = 612121086
         AND EntryPayload = 0xC396737465727265696368
   )
    THROW 51411, N'Der CP437-Entry-Namensvertrag ist fehlgeschlagen.', 1;

PRINT N'ZIP Memory CLR CP437-Contract-Prüfung: erfolgreich';
GO
