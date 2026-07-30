SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 51390, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 51391, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary', N'P') IS NULL
    THROW 51392, N'USP_ExtractZipEntryFromBinary fehlt oder besitzt den falschen Typ.', 1;

DECLARE @Help TABLE
(
      HelpContractVersion varchar(16)    NOT NULL
    , SchemaName          sysname        NOT NULL
    , ObjectName          sysname        NOT NULL
    , Section             varchar(32)    NOT NULL
    , Ordinal             int            NOT NULL
    , ItemName            sysname        NULL
    , SqlDataType         varchar(256)   NULL
    , IsRequired          bit            NULL
    , IsNullable          bit            NULL
    , DefaultValue        nvarchar(4000) NULL
    , Description         nvarchar(max)  NOT NULL
    , ExampleSql          nvarchar(max)  NULL
);

INSERT INTO @Help
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = 0x00
    , @EntryName = N'x'
    , @Hilfe = 1;

IF NOT EXISTS (SELECT 1 FROM @Help WHERE Section = 'DESCRIPTION')
   OR NOT EXISTS (SELECT 1 FROM @Help WHERE Section = 'PARAMETER' AND ItemName = N'@ZipArchive')
   OR NOT EXISTS (SELECT 1 FROM @Help WHERE Section = 'RESULT_COLUMN' AND ItemName = N'EntryPayload')
    THROW 51393, N'Der Help-Vertrag ist unvollstaendig.', 1;

DECLARE @ZipStored varbinary(max) =
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
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipStored
    , @EntryName = N'plain.txt';

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'plain.txt'
         AND CompressionMethod = 0
         AND IsEncrypted = 0
         AND EntryPayload = 0x48454C4C4F
   )
    THROW 51394, N'Der Stored-Entry-Erfolgspfad ist falsch.', 1;

CREATE TABLE #ZipResult
(
    IgnoredDummy nvarchar(1) NULL
);

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipStored
    , @EntryName = N'plain.txt'
    , @ResultTable = N'#ZipResult'
    , @KeepData = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM #ZipResult
       WHERE EntryName = N'plain.txt'
         AND EntryPayload = 0x48454C4C4F
   )
    THROW 51400, N'Der ResultTable-Pfad hat die Resultzeile nicht geschrieben.', 1;

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipStored
    , @EntryName = N'plain.txt'
    , @ResultTable = N'#ZipResult'
    , @KeepData = 1;

IF (SELECT COUNT(*) FROM #ZipResult) <> 2
    THROW 51401, N'@KeepData = 1 hat die Resultzeile nicht angehaengt.', 1;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipStored
        , @EntryName = N'plain.txt'
        , @MaxEntryBytes = 4;
    THROW 51402, N'Erwarteter Fehler 51325 wurde nicht ausgeloest.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51325
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = 0x00000000000000000000000000000000000000000000
        , @EntryName = N'plain.txt';
    THROW 51403, N'Erwarteter Fehler 51321 wurde nicht ausgeloest.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51321
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipStored
        , @EntryName = N'missing.txt';
    THROW 51395, N'Erwarteter Fehler 51322 wurde nicht ausgeloest.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51322
        THROW;
END CATCH;

DECLARE @ZipDuplicate varbinary(max) =
    0x504B030414000000000000000000000000000100000001000000070000006475702E74787441504B030414000000000000000000000000000100000001000000070000006475702E74787442504B010214001400000000000000000000000001000000010000000700000000000000000000000000000000006475702E747874504B010214001400000000000000000000000001000000010000000700000000000000000000000000260000006475702E747874504B050600000000020002006A0000004C0000000000;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipDuplicate
        , @EntryName = N'dup.txt';
    THROW 51396, N'Erwarteter Fehler 51323 wurde nicht ausgeloest.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51323
        THROW;
END CATCH;

DECLARE @ZipDeflate varbinary(max) =
    0x504B0304140000000800000000000000000003000000050000000B0000006465666C6174652E747874414243504B010214001400000008000000000000000003000000050000000B000000000000000000000000000000006465666C6174652E747874504B05060000000001000100390000002C0000000000;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipDeflate
        , @EntryName = N'deflate.txt';
    THROW 51397, N'Erwarteter Fehler 51327 wurde nicht ausgeloest.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51327
        THROW;
END CATCH;

DECLARE @ZipEncrypted varbinary(max) =
    0x504B030414000100000000000000000000000300000003000000070000007365632E74787458595A504B01021400140001000000000000000000000000030000000300000007000000000000000000000000000000007365632E747874504B0506000000000100010035000000280000000000;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipEncrypted
        , @EntryName = N'sec.txt'
        , @FailIfEncrypted = 1;
    THROW 51398, N'Erwarteter Fehler 51324 wurde nicht ausgeloest.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51324
        THROW;
END CATCH;

DELETE FROM @Result;
INSERT INTO @Result
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipEncrypted
    , @EntryName = N'sec.txt'
    , @FailIfEncrypted = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'sec.txt'
         AND IsEncrypted = 1
         AND EntryPayload IS NULL
   )
    THROW 51399, N'Der encrypted Statuspfad ohne Payload ist falsch.', 1;

PRINT N'ZIP Memory Contract-Pruefung: erfolgreich';
GO
