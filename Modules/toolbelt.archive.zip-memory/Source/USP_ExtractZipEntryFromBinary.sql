SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ExtractZipEntryFromBinary]
(
      @ZipArchive          varbinary(max) = NULL
    , @EntryName           nvarchar(1024) = NULL
    , @MaxEntryBytes       bigint         = 104857600
    , @MaxCompressionRatio decimal(9,2)   = 200.00
    , @FailIfEncrypted     bit            = 1
    , @ResultTable         sysname        = NULL
    , @KeepData            bit            = 0
    , @Debug               tinyint        = 0
    , @Hilfe               bit            = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @FailIfEncrypted = ISNULL(@FailIfEncrypted, 1);
    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
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
        (
              HelpContractVersion
            , SchemaName
            , ObjectName
            , Section
            , Ordinal
            , ItemName
            , SqlDataType
            , IsRequired
            , IsNullable
            , DefaultValue
            , Description
            , ExampleSql
        )
        VALUES
          ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'DESCRIPTION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Extrahiert einen einzelnen benannten ZIP-Eintrag aus einem varbinary(max)-Archiv im Speicher ohne Dateisystemzugriff.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 1
          , N'@ZipArchive', 'varbinary(max)', 1, 0, N'NULL'
          , N'ZIP-Container als in-memory-BLOB.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 2
          , N'@EntryName', 'nvarchar(1024)', 1, 0, N'NULL'
          , N'Exakter Entry-Name, binar verglichen mit Latin1_General_100_BIN2.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 3
          , N'@MaxEntryBytes', 'bigint', 0, 1, N'104857600'
          , N'Obere Grenze fuer die unkomprimierte Entry-Groesse.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 4
          , N'@MaxCompressionRatio', 'decimal(9,2)', 0, 1, N'200.00'
          , N'Obere Grenze fuer UncompressedBytes/CompressedBytes.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 5
          , N'@FailIfEncrypted', 'bit', 0, 1, N'1'
          , N'1 lehnt verschluesselte Entries ab. 0 liefert IsEncrypted=1 ohne Payload.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 6
          , N'@ResultTable', 'sysname', 0, 1, N'NULL'
          , N'Optionale lokale Temp-Tabelle fuer den USP-ResultTable-Pfad.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 7
          , N'@KeepData', 'bit', 0, 1, N'0'
          , N'Gilt nur mit @ResultTable und wird an USP_PrepareResultTable weitergegeben.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 8
          , N'@Debug', 'tinyint', 0, 1, N'0'
          , N'Standardisierter USP-Debugparameter.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 9
          , N'@Hilfe', 'bit', 0, 1, N'0'
          , N'1 liefert ausschliesslich dieses Help-Resultset.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 1
          , N'EntryName', 'nvarchar(1024)', 1, 0, NULL
          , N'Entry-Name aus dem ZIP Central Directory.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 2
          , N'CompressedBytes', 'bigint', 1, 0, NULL
          , N'Komprimierte Entry-Groesse laut ZIP-Metadaten.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 3
          , N'UncompressedBytes', 'bigint', 1, 0, NULL
          , N'Unkomprimierte Entry-Groesse laut ZIP-Metadaten.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 4
          , N'CompressionMethod', 'int', 1, 0, NULL
          , N'ZIP Compression Method. Version 1.0.0 extrahiert Payload nur fuer Method 0.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 5
          , N'Crc32', 'int', 0, 1, NULL
          , N'CRC32-Wert aus den ZIP-Metadaten.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 6
          , N'IsEncrypted', 'bit', 1, 0, NULL
          , N'1 kennzeichnet einen als verschluesselt markierten Entry.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 7
          , N'EntryPayload', 'varbinary(max)', 0, 1, NULL
          , N'Payload des Eintrags. Bei @FailIfEncrypted = 0 und verschluesseltem Entry ist der Wert NULL.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'ERROR', 1
          , N'51320-51329', NULL, NULL, NULL, NULL
          , N'ZIP- und Vertragsfehlerbereich des Objekts.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PERMISSION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Erforderlich sind EXECUTE auf diesem Objekt und bei @ResultTable zusaetzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'LIMITATION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Version 1.0.0 unterstuetzt fuer Payload-Extraktion nur Compression Method 0 (Stored).' 
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'EXAMPLE', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Extrahiert plain.txt aus einem synthetischen ZIP-BLOB.'
          , N'DECLARE @ZipArchive varbinary(max) = 0x...;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipArchive
    , @EntryName = N''plain.txt'';' );

        SELECT
              HelpContractVersion
            , SchemaName
            , ObjectName
            , Section
            , Ordinal
            , ItemName
            , SqlDataType
            , IsRequired
            , IsNullable
            , DefaultValue
            , Description
            , ExampleSql
        FROM @Help
        ORDER BY
              CASE Section
                  WHEN 'DESCRIPTION' THEN 1
                  WHEN 'PARAMETER' THEN 2
                  WHEN 'RESULT_COLUMN' THEN 3
                  WHEN 'ERROR' THEN 4
                  WHEN 'PERMISSION' THEN 5
                  WHEN 'LIMITATION' THEN 6
                  WHEN 'EXAMPLE' THEN 7
                  ELSE 8
              END
            , Ordinal;

        RETURN 0;
    END;

    IF @ZipArchive IS NULL OR DATALENGTH(@ZipArchive) = 0
        THROW 51320, N'@ZipArchive muss einen nicht leeren ZIP-Container enthalten.', 1;
    IF @EntryName IS NULL OR LEN(@EntryName) = 0
        THROW 51320, N'@EntryName muss gesetzt sein.', 1;
    IF @MaxEntryBytes IS NULL OR @MaxEntryBytes <= 0
        THROW 51320, N'@MaxEntryBytes muss groesser als 0 sein.', 1;
    IF @MaxCompressionRatio IS NULL OR @MaxCompressionRatio < 1
        THROW 51320, N'@MaxCompressionRatio muss groesser oder gleich 1 sein.', 1;

    DECLARE
          @ArchiveLength bigint = DATALENGTH(@ZipArchive)
        , @EocdStartPos bigint = 0
        , @SearchPos bigint
        , @MinSearchPos bigint
        , @CommentLength int
        , @CentralDirectorySize int
        , @CentralDirectoryOffset int
        , @TotalEntries int;

    IF @ArchiveLength < 22
        THROW 51321, N'Der ZIP-Container ist zu kurz fuer einen gueltigen EOCD-Record.', 1;

    SET @SearchPos = @ArchiveLength - 21;
    SET @MinSearchPos = CASE WHEN @ArchiveLength > 65557 THEN @ArchiveLength - 65557 ELSE 1 END;

    WHILE @SearchPos >= @MinSearchPos
    BEGIN
        IF SUBSTRING(@ZipArchive, CONVERT(int, @SearchPos), 4) = 0x504B0506
        BEGIN
            SET @EocdStartPos = @SearchPos;
            BREAK;
        END;
        SET @SearchPos -= 1;
    END;

    IF @EocdStartPos = 0
        THROW 51321, N'EOCD-Signatur wurde im ZIP-Container nicht gefunden.', 1;

    SET @TotalEntries =
        CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 10), 1)))
        + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 11), 1))) * 256;
    SET @CentralDirectorySize =
        CONVERT(int,
            CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 12), 1)))
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 13), 1))) * 256
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 14), 1))) * 65536
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 15), 1))) * 16777216
        );
    SET @CentralDirectoryOffset =
        CONVERT(int,
            CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 16), 1)))
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 17), 1))) * 256
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 18), 1))) * 65536
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 19), 1))) * 16777216
        );
    SET @CommentLength =
        CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 20), 1)))
        + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @EocdStartPos + 21), 1))) * 256;

    IF @TotalEntries < 1
        THROW 51321, N'Das ZIP-Archiv enthaelt keine Entries.', 1;

    IF @EocdStartPos + 21 + @CommentLength <> @ArchiveLength
        THROW 51321, N'Die EOCD-Kommentarlaenge ist inkonsistent.', 1;

    IF @CentralDirectoryOffset < 0
       OR @CentralDirectorySize < 46
       OR CONVERT(bigint, @CentralDirectoryOffset) + CONVERT(bigint, @CentralDirectorySize) > @ArchiveLength
        THROW 51321, N'Central Directory Offset oder Groesse ist ungueltig.', 1;

    DECLARE @Entries TABLE
    (
          EntryOrdinal int IDENTITY(1,1) NOT NULL
        , EntryName nvarchar(1024) NOT NULL
        , LocalHeaderOffset bigint NOT NULL
        , CompressionMethod int NOT NULL
        , GeneralPurposeFlags int NOT NULL
        , Crc32 int NOT NULL
        , CompressedBytes bigint NOT NULL
        , UncompressedBytes bigint NOT NULL
    );

    DECLARE
          @CursorPos bigint = CONVERT(bigint, @CentralDirectoryOffset) + 1
        , @EntryIndex int = 1;

    WHILE @EntryIndex <= @TotalEntries
    BEGIN
        IF @CursorPos + 45 > @ArchiveLength
            THROW 51321, N'Das Central Directory ist vorzeitig beendet.', 1;

        IF SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos), 4) <> 0x504B0102
            THROW 51321, N'Ein Central-Directory-Header besitzt eine ungueltige Signatur.', 1;

        DECLARE
              @GpFlags int
            , @Method int
            , @Crc32 int
            , @CrcVal bigint
            , @CompressedSize bigint
            , @UncompressedSize bigint
            , @NameLength int
            , @ExtraLength int
            , @CommentLen int
            , @LocalOffset bigint
            , @EntryNameBytes varbinary(1024)
            , @EntryNameValue nvarchar(1024)
            , @HeaderLength int;

        SET @GpFlags =
            CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 8), 1)))
            + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 9), 1))) * 256;
        SET @Method =
            CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 10), 1)))
            + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 11), 1))) * 256;
        
        SET @CrcVal =
            CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 16), 1)))
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 17), 1))) * 256
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 18), 1))) * 65536
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 19), 1))) * 16777216;
        SET @Crc32 = CONVERT(int, CASE WHEN @CrcVal >= 2147483648 THEN @CrcVal - 4294967296 ELSE @CrcVal END);

        SET @CompressedSize =
            CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 20), 1)))
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 21), 1))) * 256
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 22), 1))) * 65536
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 23), 1))) * 16777216;

        SET @UncompressedSize =
            CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 24), 1)))
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 25), 1))) * 256
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 26), 1))) * 65536
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 27), 1))) * 16777216;

        SET @NameLength =
            CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 28), 1)))
            + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 29), 1))) * 256;
        SET @ExtraLength =
            CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 30), 1)))
            + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 31), 1))) * 256;
        SET @CommentLen =
            CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 32), 1)))
            + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 33), 1))) * 256;
        
        SET @LocalOffset =
            CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 42), 1)))
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 43), 1))) * 256
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 44), 1))) * 65536
          + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 45), 1))) * 16777216;

        IF @NameLength < 1 OR @NameLength > 1024 OR @ExtraLength < 0 OR @CommentLen < 0
            THROW 51321, N'Entry-Metadaten sind ausserhalb der unterstuetzten Grenzen.', 1;

        SET @HeaderLength = 46 + @NameLength + @ExtraLength + @CommentLen;

        IF @CursorPos + @HeaderLength - 1 > @ArchiveLength
            THROW 51321, N'Central-Directory-Headerlaenge ueberschreitet den Archivbereich.', 1;

        SET @EntryNameBytes = SUBSTRING(@ZipArchive, CONVERT(int, @CursorPos + 46), @NameLength);
        SET @EntryNameValue = CONVERT(nvarchar(1024), CONVERT(varchar(1024), @EntryNameBytes));

        INSERT INTO @Entries
        (
              EntryName
            , LocalHeaderOffset
            , CompressionMethod
            , GeneralPurposeFlags
            , Crc32
            , CompressedBytes
            , UncompressedBytes
        )
        VALUES
        (
              @EntryNameValue
            , @LocalOffset
            , @Method
            , @GpFlags
            , @Crc32
            , @CompressedSize
            , @UncompressedSize
        );

        SET @CursorPos += @HeaderLength;
        SET @EntryIndex += 1;
    END;

    DECLARE @MatchingEntries int;

    SELECT @MatchingEntries = COUNT(*)
    FROM @Entries
    WHERE EntryName COLLATE Latin1_General_100_BIN2 = @EntryName COLLATE Latin1_General_100_BIN2;

    IF @MatchingEntries = 0
        THROW 51322, N'Der angeforderte Entry wurde nicht gefunden.', 1;
    IF @MatchingEntries > 1
        THROW 51323, N'Der angeforderte Entry-Name ist im ZIP-Archiv nicht eindeutig.', 1;

    DECLARE
          @SelectedEntryName nvarchar(1024)
        , @SelectedOffset bigint
        , @SelectedMethod int
        , @SelectedFlags int
        , @SelectedCrc32 int
        , @SelectedCompressedBytes bigint
        , @SelectedUncompressedBytes bigint
        , @IsEncrypted bit
        , @CompressionRatio decimal(38,6)
        , @LocalHeaderPos bigint
        , @LocalNameLen int
        , @LocalExtraLen int
        , @LocalDataPos bigint
        , @LocalFlags int
        , @LocalMethod int
        , @LocalCrc int
        , @LocalCrcVal bigint
        , @LocalCompressed bigint
        , @LocalUncompressed bigint
        , @LocalName nvarchar(1024)
        , @Payload varbinary(max) = NULL;

    SELECT
          @SelectedEntryName = EntryName
        , @SelectedOffset = LocalHeaderOffset
        , @SelectedMethod = CompressionMethod
        , @SelectedFlags = GeneralPurposeFlags
        , @SelectedCrc32 = Crc32
        , @SelectedCompressedBytes = CompressedBytes
        , @SelectedUncompressedBytes = UncompressedBytes
    FROM @Entries
    WHERE EntryName COLLATE Latin1_General_100_BIN2 = @EntryName COLLATE Latin1_General_100_BIN2;

    SET @IsEncrypted = CASE WHEN (@SelectedFlags & 1) = 1 THEN 1 ELSE 0 END;

    IF @SelectedUncompressedBytes > @MaxEntryBytes
        THROW 51325, N'Der Entry ueberschreitet @MaxEntryBytes.', 1;

    SET @CompressionRatio =
        CASE
            WHEN @SelectedCompressedBytes = 0
                THEN CASE WHEN @SelectedUncompressedBytes = 0 THEN 0 ELSE 999999999 END
            ELSE CONVERT(decimal(38,6), @SelectedUncompressedBytes)
                 / CONVERT(decimal(38,6), @SelectedCompressedBytes)
        END;

    IF @CompressionRatio > @MaxCompressionRatio
        THROW 51326, N'Der Entry ueberschreitet @MaxCompressionRatio.', 1;

    SET @LocalHeaderPos = CONVERT(bigint, @SelectedOffset) + 1;

    IF @LocalHeaderPos < 1 OR @LocalHeaderPos + 29 > @ArchiveLength
        THROW 51321, N'Local Header Offset liegt ausserhalb des ZIP-Containers.', 1;

    IF SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos), 4) <> 0x504B0304
        THROW 51321, N'Der Local Header besitzt eine ungueltige Signatur.', 1;

    SET @LocalFlags =
        CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 6), 1)))
        + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 7), 1))) * 256;
    SET @LocalMethod =
        CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 8), 1)))
        + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 9), 1))) * 256;
    
    SET @LocalCrcVal =
        CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 14), 1)))
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 15), 1))) * 256
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 16), 1))) * 65536
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 17), 1))) * 16777216;
    SET @LocalCrc = CONVERT(int, CASE WHEN @LocalCrcVal >= 2147483648 THEN @LocalCrcVal - 4294967296 ELSE @LocalCrcVal END);

    SET @LocalCompressed =
        CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 18), 1)))
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 19), 1))) * 256
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 20), 1))) * 65536
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 21), 1))) * 16777216;

    SET @LocalUncompressed =
        CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 22), 1)))
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 23), 1))) * 256
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 24), 1))) * 65536
      + CONVERT(bigint, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 25), 1))) * 16777216;

    SET @LocalNameLen =
        CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 26), 1)))
        + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 27), 1))) * 256;
    SET @LocalExtraLen =
        CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 28), 1)))
        + CONVERT(int, CONVERT(tinyint, SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 29), 1))) * 256;

    IF @LocalNameLen < 1 OR @LocalNameLen > 1024 OR @LocalExtraLen < 0
        THROW 51321, N'Der Local Header enthaelt ungueltige Feldlaengen.', 1;

    SET @LocalName = CONVERT
    (
        nvarchar(1024),
        CONVERT(varchar(1024), SUBSTRING(@ZipArchive, CONVERT(int, @LocalHeaderPos + 30), @LocalNameLen))
    );

    IF @LocalName COLLATE Latin1_General_100_BIN2
           <> @SelectedEntryName COLLATE Latin1_General_100_BIN2
        THROW 51328, N'Local- und Central-Header enthalten unterschiedliche Entry-Namen.', 1;

    IF @LocalFlags <> @SelectedFlags
       OR @LocalMethod <> @SelectedMethod
       OR (@LocalCrc <> 0 AND @LocalCrc <> @SelectedCrc32)
        THROW 51328, N'Local- und Central-Header sind inkonsistent.', 1;

    SET @LocalDataPos = @LocalHeaderPos + 30 + @LocalNameLen + @LocalExtraLen;

    IF @LocalDataPos < 1
       OR @LocalDataPos - 1 + @SelectedCompressedBytes > @ArchiveLength
        THROW 51321, N'Die Entry-Daten liegen ausserhalb des ZIP-Containers.', 1;

    IF @IsEncrypted = 1 AND @FailIfEncrypted = 1
        THROW 51324, N'Der angeforderte Entry ist verschluesselt und laut Parameter abzulehnen.', 1;

    IF @IsEncrypted = 0
    BEGIN
        IF @SelectedMethod <> 0
            THROW 51327, N'Compression Method wird fuer Payload-Extraktion in Version 1.0.0 nicht unterstuetzt.', 1;

        IF @SelectedCompressedBytes <> @SelectedUncompressedBytes
            THROW 51328, N'Stored-Entry hat inkonsistente Groessenangaben.', 1;

        IF @SelectedCompressedBytes > 2147483647
            THROW 51325, N'Der Entry ist groesser als die unterstuetzte SUBSTRING-Grenze.', 1;

        SET @Payload = SUBSTRING
        (
              @ZipArchive
            , CONVERT(int, @LocalDataPos)
            , CONVERT(int, @SelectedCompressedBytes)
        );
    END;

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
    (
          EntryName
        , CompressedBytes
        , UncompressedBytes
        , CompressionMethod
        , Crc32
        , IsEncrypted
        , EntryPayload
    )
    VALUES
    (
          @SelectedEntryName
        , @SelectedCompressedBytes
        , @SelectedUncompressedBytes
        , @SelectedMethod
        , @SelectedCrc32
        , @IsEncrypted
        , @Payload
    );

    IF @ResultTable IS NULL
    BEGIN
        SELECT
              EntryName
            , CompressedBytes
            , UncompressedBytes
            , CompressionMethod
            , Crc32
            , IsEncrypted
            , EntryPayload
        FROM @Result;

        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51329, N'Die ResultTable-Dependency toolbelt_core.USP_PrepareResultTable ist nicht installiert.', 1;

    CREATE TABLE #tbx_ZipMemory_ResultShape
    (
          EntryName nvarchar(1024) NOT NULL
        , CompressedBytes bigint NOT NULL
        , UncompressedBytes bigint NOT NULL
        , CompressionMethod int NOT NULL
        , Crc32 int NULL
        , IsEncrypted bit NOT NULL
        , EntryPayload varbinary(max) NULL
    );

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable          = N'#tbx_ZipMemory_ResultShape'
        , @KeepData           = @KeepData
        , @Debug              = @Debug;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable) + N'
        (
              EntryName
            , CompressedBytes
            , UncompressedBytes
            , CompressionMethod
            , Crc32
            , IsEncrypted
            , EntryPayload
        )
        SELECT
              EntryName
            , CompressedBytes
            , UncompressedBytes
            , CompressionMethod
            , Crc32
            , IsEncrypted
            , EntryPayload
        FROM @ResultSource;';

    EXEC sys.sp_executesql @InsertSql
        , N'@ResultSource TABLE
            (
                  EntryName nvarchar(1024) NOT NULL
                , CompressedBytes bigint NOT NULL
                , UncompressedBytes bigint NOT NULL
                , CompressionMethod int NOT NULL
                , Crc32 int NULL
                , IsEncrypted bit NOT NULL
                , EntryPayload varbinary(max) NULL
            )'
        , @ResultSource = @Result;

    RETURN 0;
END;
GO
