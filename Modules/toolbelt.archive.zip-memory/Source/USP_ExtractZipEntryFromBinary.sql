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
          , N'Extrahiert einen einzelnen benannten ZIP-Entry aus einem varbinary(max)-Archiv im Speicher. Der interne SAFE-CLR-Provider unterstützt ZIP Methods 0 und 8 und prüft die CRC32 des tatsächlichen Payloads.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 1
          , N'@ZipArchive', 'varbinary(max)', 1, 0, N'NULL'
          , N'ZIP-Container als In-memory-BLOB. Das harte Providerlimit beträgt 268435456 Bytes.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 2
          , N'@EntryName', 'nvarchar(1024)', 1, 0, N'NULL'
          , N'Exakter Entry-Name. Der CLR-Provider vergleicht ordinal und case-sensitive.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 3
          , N'@MaxEntryBytes', 'bigint', 0, 1, N'104857600'
          , N'Obere Grenze für die tatsächlich ausgegebene unkomprimierte Entry-Größe.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 4
          , N'@MaxCompressionRatio', 'decimal(9,2)', 0, 1, N'200.00'
          , N'Obere Grenze für tatsächliche und deklarierte UncompressedBytes/CompressedBytes.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 5
          , N'@FailIfEncrypted', 'bit', 0, 1, N'1'
          , N'1 lehnt verschlüsselte Entries ab. 0 liefert IsEncrypted=1 und keinen Payload.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PARAMETER', 6
          , N'@ResultTable', 'sysname', 0, 1, N'NULL'
          , N'Optionale bestehende lokale Temp-Tabelle für den USP-ResultTable-Pfad.'
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
          , N'1 liefert ausschließlich dieses Help-Resultset.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 1
          , N'EntryName', 'nvarchar(1024)', 1, 0, NULL
          , N'Exakter Entry-Name aus dem Central Directory.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 2
          , N'CompressedBytes', 'bigint', 1, 0, NULL
          , N'Komprimierte Entry-Größe laut Central Directory.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 3
          , N'UncompressedBytes', 'bigint', 1, 0, NULL
          , N'Unkomprimierte Entry-Größe, nach erfolgreicher Extraktion gegen die tatsächliche Ausgabe geprüft.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 4
          , N'CompressionMethod', 'int', 1, 0, NULL
          , N'ZIP Compression Method. Unterstützt werden 0 (Stored) und 8 (Deflate).'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 5
          , N'Crc32', 'int', 0, 1, NULL
          , N'CRC32 des tatsächlichen Payloads als SQL-int-Bitmuster. Bei verschlüsseltem Status stammt der Wert aus dem Central Directory.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 6
          , N'IsEncrypted', 'bit', 1, 0, NULL
          , N'1 kennzeichnet einen als verschlüsselt markierten Entry.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'RESULT_COLUMN', 7
          , N'EntryPayload', 'varbinary(max)', 0, 1, NULL
          , N'Dekomprimierter Payload. Bei @FailIfEncrypted=0 und verschlüsseltem Entry ist der Wert NULL.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'ERROR', 1
          , N'51320-51329', NULL, NULL, NULL, NULL
          , N'Parameter-, ZIP-Struktur-, Limit-, Feature-, Integritäts- und Providerfehlerbereich.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'PERMISSION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Erforderlich sind EXECUTE auf diesem Objekt und bei @ResultTable zusätzlich EXECUTE auf toolbelt_core.USP_PrepareResultTable.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'LIMITATION', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Nicht unterstützt: ZIP64, Multi-Disk, Verschlüsselungsentschlüsselung, Deflate64, unbekannte Methods und zusätzliche Central-Directory-Datensätze.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'LIMITATION', 2
          , NULL, NULL, NULL, NULL, NULL
          , N'Harte Providerlimits: 268435456 Archivbytes, 134217728 komprimierte Entry-Bytes und 10000 Entries.'
          , NULL )
        , ( '1.0', N'toolbelt_archive', N'USP_ExtractZipEntryFromBinary', 'EXAMPLE', 1
          , NULL, NULL, NULL, NULL, NULL
          , N'Extrahiert deflated.txt aus einem synthetischen ZIP-BLOB.'
          , N'DECLARE @ZipArchive varbinary(max) = 0x...;
EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
      @ZipArchive = @ZipArchive
    , @EntryName = N''deflated.txt'';' );

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
    IF @MaxEntryBytes IS NULL
       OR @MaxEntryBytes <= 0
       OR @MaxEntryBytes > 2147483647
        THROW 51320, N'@MaxEntryBytes muss zwischen 1 und 2147483647 liegen.', 1;
    IF @MaxCompressionRatio IS NULL OR @MaxCompressionRatio < 1
        THROW 51320, N'@MaxCompressionRatio muss größer oder gleich 1 sein.', 1;

    IF OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr', N'FT') IS NULL
        THROW 51329, N'Der interne CLR-ZIP-Provider ist nicht installiert.', 1;

    DECLARE @ProviderResult TABLE
    (
          ErrorNumber       int            NULL
        , ErrorMessage      nvarchar(4000) NULL
        , EntryName         nvarchar(1024) NULL
        , CompressedBytes   bigint         NULL
        , UncompressedBytes bigint         NULL
        , CompressionMethod int            NULL
        , Crc32             int            NULL
        , IsEncrypted       bit            NULL
        , EntryPayload      varbinary(max) NULL
    );

    INSERT INTO @ProviderResult
    (
          ErrorNumber
        , ErrorMessage
        , EntryName
        , CompressedBytes
        , UncompressedBytes
        , CompressionMethod
        , Crc32
        , IsEncrypted
        , EntryPayload
    )
    SELECT
          ErrorNumber
        , ErrorMessage
        , EntryName
        , CompressedBytes
        , UncompressedBytes
        , CompressionMethod
        , Crc32
        , IsEncrypted
        , EntryPayload
    FROM toolbelt_archive.TVF_InternalExtractZipEntryClr
    (
          @ZipArchive
        , @EntryName
        , @MaxEntryBytes
        , @MaxCompressionRatio
        , @FailIfEncrypted
    );

    IF (SELECT COUNT_BIG(*) FROM @ProviderResult) <> 1
        THROW 51329, N'Der interne CLR-ZIP-Provider lieferte keinen eindeutigen Status.', 1;

    DECLARE
          @ProviderErrorNumber int
        , @ProviderErrorMessage nvarchar(2048);

    SELECT
          @ProviderErrorNumber = ErrorNumber
        , @ProviderErrorMessage =
              CONVERT(nvarchar(2048), LEFT(ErrorMessage, 2048))
    FROM @ProviderResult;

    IF @ProviderErrorNumber IS NOT NULL
    BEGIN
        IF @ProviderErrorNumber NOT BETWEEN 51320 AND 51329
            THROW 51329, N'Der interne CLR-ZIP-Provider lieferte einen ungültigen Fehlercode.', 1;

        SET @ProviderErrorMessage =
            COALESCE(NULLIF(@ProviderErrorMessage, N''), N'Der CLR-ZIP-Provider hat den Vorgang abgebrochen.');

        THROW @ProviderErrorNumber, @ProviderErrorMessage, 1;
    END;

    CREATE TABLE #tbx_ZipMemory_ResultSource
    (
          EntryName         nvarchar(1024) NOT NULL
        , CompressedBytes   bigint         NOT NULL
        , UncompressedBytes bigint         NOT NULL
        , CompressionMethod int            NOT NULL
        , Crc32             int            NULL
        , IsEncrypted       bit            NOT NULL
        , EntryPayload      varbinary(max) NULL
    );

    INSERT INTO #tbx_ZipMemory_ResultSource
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
    FROM @ProviderResult;

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
        FROM #tbx_ZipMemory_ResultSource;

        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51329, N'Die ResultTable-Dependency toolbelt_core.USP_PrepareResultTable ist nicht installiert.', 1;

    CREATE TABLE #tbx_ZipMemory_ResultShape
    (
          EntryName         nvarchar(1024) NOT NULL
        , CompressedBytes   bigint         NOT NULL
        , UncompressedBytes bigint         NOT NULL
        , CompressionMethod int            NOT NULL
        , Crc32             int            NULL
        , IsEncrypted       bit            NOT NULL
        , EntryPayload      varbinary(max) NULL
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
        FROM #tbx_ZipMemory_ResultSource;';

    EXEC sys.sp_executesql @InsertSql;

    RETURN 0;
END;
GO
