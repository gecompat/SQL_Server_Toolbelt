SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 51390, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 51391, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary', N'P') IS NULL
    THROW 51392, N'USP_ExtractZipEntryFromBinary fehlt oder besitzt den falschen Typ.', 1;
IF OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr', N'FT') IS NULL
    THROW 51392, N'Der interne CLR-ZIP-Provider fehlt oder besitzt den falschen Typ.', 1;
IF NOT EXISTS
   (
       SELECT 1
       FROM sys.assemblies
       WHERE name = N'Toolbelt_Archive_ZipMemory'
         AND permission_set_desc = N'SAFE_ACCESS'
   )
    THROW 51392, N'Die erwartete SAFE-CLR-ZIP-Assembly fehlt.', 1;
IF EXISTS
   (
       SELECT 1
       FROM sys.assembly_references AS ar
       INNER JOIN sys.assemblies AS source_assembly
         ON source_assembly.assembly_id = ar.assembly_id
       INNER JOIN sys.assemblies AS referenced_assembly
         ON referenced_assembly.assembly_id = ar.referenced_assembly_id
       WHERE source_assembly.name = N'Toolbelt_Archive_ZipMemory'
         AND referenced_assembly.name = N'System.IO.Compression'
   )
    THROW 51392, N'Die CLR-ZIP-Assembly darf System.IO.Compression.dll nicht direkt referenzieren.', 1;

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

DECLARE @ZipUtf8EntryName nvarchar(50) = N'Gr' + NCHAR(252) + NCHAR(223) + N'e.txt';

INSERT INTO @Help
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = 0x00
    , @EntryName = N'x'
    , @Hilfe = 1;

IF NOT EXISTS (SELECT 1 FROM @Help WHERE Section = 'DESCRIPTION')
   OR NOT EXISTS
      (
          SELECT 1
          FROM @Help
          WHERE Section = 'PARAMETER'
            AND ItemName = N'@ZipArchive'
      )
   OR NOT EXISTS
      (
          SELECT 1
          FROM @Help
          WHERE Section = 'RESULT_COLUMN'
            AND ItemName = N'EntryPayload'
      )
   OR NOT EXISTS
      (
          SELECT 1
          FROM @Help
          WHERE Section = 'LIMITATION'
            AND Description LIKE N'%ZIP64%'
      )
   OR NOT EXISTS
      (
          SELECT 1
          FROM @Help
          WHERE Section = 'DESCRIPTION'
            AND Description LIKE N'%Methods 0 und 8%'
      )
    THROW 51393, N'Der Help-Vertrag ist unvollständig.', 1;

DECLARE
      @ZipStored varbinary(max) =
        0x504B030414000000000000002150366444C1050000000500000009000000706C61696E2E74787448454C4C4F504B0102140314000000000000002150366444C10500000005000000090000000000000000000000800100000000706C61696E2E747874504B05060000000001000100370000002C0000000000
    , @ZipDeflate varbinary(max) =
        0x504B0304140000000800000021502383920B18000000160000000C0000006465666C617465642E747874F370F5F1F157700BF2F75570F60952707175F3710C710500504B01021403140000000800000021502383920B18000000160000000C00000000000000000000008001000000006465666C617465642E747874504B050600000000010001003A000000420000000000
    , @ZipDescriptor varbinary(max) =
        0x504B0304140008000800313CFF5C0000000000000000000000000E00000064657363726970746F722E74787473710C715470710D760EF20C08F10F5208708CF4F177740100504B0708AD526A711900000017000000504B01021403140008000800313CFF5CAD526A7119000000170000000E000000000000000000000080010000000064657363726970746F722E747874504B050600000000010001003C000000550000000000
    , @ZipUtf8 varbinary(max) =
        0x504B030414000008080000002150FE397C240D0000000B0000000B0000004772C3BCC39F652E7478743B3CADB824B5A8283533390300504B0102140314000008080000002150FE397C240D0000000B0000000B00000000000000000000008001000000004772C3BCC39F652E747874504B0506000000000100010039000000360000000000
    , @ZipDuplicate varbinary(max) =
        0x504B0304140000000000000021508B9ED9D30100000001000000070000006475702E74787441504B03041400000008000000215031CFD04A0300000001000000070000006475702E747874730200504B01021403140000000000000021508B9ED9D301000000010000000700000000000000000000008001000000006475702E747874504B010214031400000008000000215031CFD04A03000000010000000700000000000000000000008001260000006475702E747874504B050600000000020002006A0000004E0000000000
    , @ZipEncrypted varbinary(max) =
        0x504B0304140001000800000021502383920B18000000160000000C0000006465666C617465642E747874F370F5F1F157700BF2F75570F60952707175F3710C710500504B01021403140001000800000021502383920B18000000160000000C00000000000000000000008001000000006465666C617465642E747874504B050600000000010001003A000000420000000000
    , @ZipBadCrc varbinary(max) =
        0x504B0304140000000800000021502780900A18000000160000000C0000006465666C617465642E747874F370F5F1F157700BF2F75570F60952707175F3710C710500504B01021403140000000800000021502780900A18000000160000000C00000000000000000000008001000000006465666C617465642E747874504B050600000000010001003A000000420000000000
    , @ZipUnsupported varbinary(max) =
        0x504B0304140000000C00000021502383920B18000000160000000C0000006465666C617465642E747874F370F5F1F157700BF2F75570F60952707175F3710C710500504B01021403140000000C00000021502383920B18000000160000000C00000000000000000000008001000000006465666C617465642E747874504B050600000000010001003A000000420000000000
    , @Zip64Sentinel varbinary(max) =
        0x504B0304140000000800000021502383920B18000000160000000C0000006465666C617465642E747874F370F5F1F157700BF2F75570F60952707175F3710C710500504B01021403140000000800000021502383920BFFFFFFFF160000000C00000000000000000000008001000000006465666C617465642E747874504B050600000000010001003A000000420000000000
    , @ZipLocalNameMismatch varbinary(max) =
        0x504B0304140000000800000021502383920B18000000160000000C0000005865666C617465642E747874F370F5F1F157700BF2F75570F60952707175F3710C710500504B01021403140000000800000021502383920B18000000160000000C00000000000000000000008001000000006465666C617465642E747874504B050600000000010001003A000000420000000000
    , @ZipRatio varbinary(max) =
        0x504B030414000000080000002150012EA0510B000000E803000009000000726174696F2E74787473741C05A360140C770000504B0102140314000000080000002150012EA0510B000000E8030000090000000000000000000000800100000000726174696F2E747874504B0506000000000100010037000000320000000000;

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
      @ZipArchive = @ZipStored
    , @EntryName = N'plain.txt';

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'plain.txt'
         AND CompressedBytes = 5
         AND UncompressedBytes = 5
         AND CompressionMethod = 0
         AND Crc32 = -1052482506
         AND IsEncrypted = 0
         AND EntryPayload = 0x48454C4C4F
   )
    THROW 51394, N'Der Stored-Entry-Erfolgspfad ist falsch.', 1;

DELETE FROM @Result;

INSERT INTO @Result
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipDeflate
    , @EntryName = N'deflated.txt';

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'deflated.txt'
         AND CompressedBytes = 24
         AND UncompressedBytes = 22
         AND CompressionMethod = 8
         AND Crc32 = 194151203
         AND IsEncrypted = 0
         AND EntryPayload =
             0x48454C4C4F2046524F4D20434C52204445464C415445
   )
    THROW 51395, N'Der Deflate-Erfolgspfad ist falsch.', 1;

DELETE FROM @Result;

INSERT INTO @Result
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipDescriptor
    , @EntryName = N'descriptor.txt';

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'descriptor.txt'
         AND CompressionMethod = 8
         AND Crc32 = 1902793389
         AND EntryPayload =
             0x444154412044455343524950544F52205041594C4F4144
   )
    THROW 51396, N'Der Data-Descriptor-Erfolgspfad ist falsch.', 1;

DELETE FROM @Result;

INSERT INTO @Result
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipUtf8
    , @EntryName = @ZipUtf8EntryName;

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = @ZipUtf8EntryName
         AND CompressionMethod = 8
         AND Crc32 = 612121086
         AND EntryPayload = 0xC396737465727265696368
   )
    THROW 51397, N'Der UTF-8-Entry-Erfolgspfad ist falsch.', 1;

CREATE TABLE #ZipResult
(
    IgnoredDummy nvarchar(1) NULL
);

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipDeflate
    , @EntryName = N'deflated.txt'
    , @ResultTable = N'#ZipResult'
    , @KeepData = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM #ZipResult
       WHERE EntryName = N'deflated.txt'
         AND CompressionMethod = 8
         AND EntryPayload =
             0x48454C4C4F2046524F4D20434C52204445464C415445
   )
    THROW 51398, N'Der ResultTable-Replace-Pfad hat die Resultzeile nicht geschrieben.', 1;

EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipStored
    , @EntryName = N'plain.txt'
    , @ResultTable = N'#ZipResult'
    , @KeepData = 1;

IF (SELECT COUNT(*) FROM #ZipResult) <> 2
    THROW 51399, N'@KeepData=1 hat die Resultzeile nicht angehängt.', 1;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = NULL
        , @EntryName = N'plain.txt';
    THROW 51400, N'Erwarteter Fehler 51320 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51320
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipLocalNameMismatch
        , @EntryName = N'deflated.txt';
    THROW 51401, N'Erwarteter Fehler 51321 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51321
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipDeflate
        , @EntryName = N'DEFLATED.TXT';
    THROW 51402, N'Erwarteter Fehler 51322 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51322
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipDuplicate
        , @EntryName = N'dup.txt';
    THROW 51403, N'Erwarteter Fehler 51323 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51323
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipEncrypted
        , @EntryName = N'deflated.txt'
        , @FailIfEncrypted = 1;
    THROW 51404, N'Erwarteter Fehler 51324 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51324
        THROW;
END CATCH;

DELETE FROM @Result;

INSERT INTO @Result
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipEncrypted
    , @EntryName = N'deflated.txt'
    , @FailIfEncrypted = 0;

IF NOT EXISTS
   (
       SELECT 1
       FROM @Result
       WHERE EntryName = N'deflated.txt'
         AND CompressionMethod = 8
         AND IsEncrypted = 1
         AND EntryPayload IS NULL
   )
    THROW 51405, N'Der verschlüsselte Statuspfad ohne Payload ist falsch.', 1;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipDeflate
        , @EntryName = N'deflated.txt'
        , @MaxEntryBytes = 21;
    THROW 51406, N'Erwarteter Fehler 51325 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51325
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipRatio
        , @EntryName = N'ratio.txt'
        , @MaxCompressionRatio = 10.00;
    THROW 51407, N'Erwarteter Fehler 51326 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51326
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipUnsupported
        , @EntryName = N'deflated.txt';
    THROW 51408, N'Erwarteter Fehler 51327 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51327
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @Zip64Sentinel
        , @EntryName = N'deflated.txt';
    THROW 51409, N'Erwarteter ZIP64-Fehler 51327 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51327
        THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
          @ZipArchive = @ZipBadCrc
        , @EntryName = N'deflated.txt';
    THROW 51410, N'Erwarteter CRC-Fehler 51328 wurde nicht ausgelöst.', 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() <> 51328
        THROW;
END CATCH;

PRINT N'ZIP Memory CLR Contract-Prüfung: erfolgreich';
GO
