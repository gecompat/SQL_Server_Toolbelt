SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_archive].[USP_ListZipEntriesFromBinary]
(
      @ZipArchive  varbinary(max) = NULL
    , @MaxEntries  int            = 10000
    , @ResultTable sysname        = NULL
    , @KeepData    bit            = 0
    , @Debug       tinyint        = 0
    , @Hilfe       bit            = 0
)
AS
BEGIN
    SET NOCOUNT ON;

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
              HelpContractVersion, SchemaName, ObjectName, Section, Ordinal
            , ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue
            , Description, ExampleSql
        )
        VALUES
          ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'DESCRIPTION', 1,
           NULL, NULL, NULL, NULL, NULL,
           N'Listet deklarierte Metadaten aller Central-Directory-Entries eines klassischen Single-Disk-ZIP aus varbinary(max), ohne Payloads zu lesen oder zu dekomprimieren.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'PARAMETER', 1,
           N'@ZipArchive', 'varbinary(max)', 1, 0, N'NULL',
           N'Nicht leerer ZIP-Container im Speicher; hartes Limit 268435456 Bytes.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'PARAMETER', 2,
           N'@MaxEntries', 'int', 0, 0, N'10000',
           N'Zulässige Zahl der Entries zwischen 1 und dem harten Limit 10000.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'PARAMETER', 3,
           N'@ResultTable', 'sysname', 0, 1, N'NULL',
           N'Optionale bestehende lokale Temp-Tabelle für den ResultTable-Pfad.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'PARAMETER', 4,
           N'@KeepData', 'bit', 0, 1, N'0',
           N'Gilt nur mit @ResultTable und steuert Replace oder Append.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'PARAMETER', 5,
           N'@Debug', 'tinyint', 0, 1, N'0', N'Standardisierter USP-Debugparameter.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'PARAMETER', 6,
           N'@Hilfe', 'bit', 0, 1, N'0', N'1 liefert ausschließlich dieses Help-Resultset.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 1,
           N'EntryOrdinal', 'int', 1, 0, NULL, N'Einsbasierte Position im Central Directory.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 2,
           N'EntryName', 'nvarchar(1024)', 1, 0, NULL, N'Exakt dekodierter, nicht normalisierter Entry-Name.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 3,
           N'IsDirectory', 'bit', 1, 0, NULL, N'Aus einem abschließenden Schrägstrich abgeleitete Directory-Markierung.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 4,
           N'CompressedBytes', 'bigint', 1, 0, NULL, N'Deklarierte komprimierte Größe.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 5,
           N'UncompressedBytes', 'bigint', 1, 0, NULL, N'Deklarierte unkomprimierte Größe.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 6,
           N'CompressionMethod', 'int', 1, 0, NULL, N'Numerischer ZIP-Methodenwert.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 7,
           N'Crc32', 'int', 1, 0, NULL, N'Deklarierte und beim Listing nicht neu berechnete CRC32.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 8,
           N'IsEncrypted', 'bit', 1, 0, NULL, N'Verschlüsselungsstatus aus den General-Purpose-Flags.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 9,
           N'IsExtractionSupported', 'bit', 1, 0, NULL, N'1 nur für unverschlüsselte Methods 0 und 8.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 10,
           N'DuplicateCount', 'int', 1, 0, NULL, N'Ordinal und case-sensitive gezählte Namensduplikate.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 11,
           N'IsPathSafe', 'bit', 1, 0, NULL, N'1 nur für einen kanonischen relativen Pfad.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 12,
           N'PathStatus', 'varchar(32)', 1, 0, NULL, N'safe, absolute, drive-qualified, parent-traversal oder noncanonical.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'RESULT_COLUMN', 13,
           N'LastModifiedAt', 'datetime2(0)', 0, 1, NULL, N'DOS-Zeit ohne Zeitzonenbehauptung; bei ungültigem Wert NULL.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'ERROR', 1,
           N'51320-51329', NULL, NULL, NULL, NULL,
           N'Parameter-, Struktur-, Limit-, Feature- und Providerfehlerbereich.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'LIMITATION', 1,
           NULL, NULL, NULL, NULL, NULL,
           N'ZIP64 und Multi-Disk werden abgelehnt. Metadaten sind keine Integritätsbestätigung des Payloads.', NULL)
        , ('1.0', N'toolbelt_archive', N'USP_ListZipEntriesFromBinary', 'EXAMPLE', 1,
           NULL, NULL, NULL, NULL, NULL, N'Listet alle Entries eines ZIP-BLOBs.',
           N'EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive = 0x...;');

        SELECT
              HelpContractVersion, SchemaName, ObjectName, Section, Ordinal
            , ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue
            , Description, ExampleSql
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
    IF @MaxEntries IS NULL OR @MaxEntries < 1 OR @MaxEntries > 10000
        THROW 51320, N'@MaxEntries muss zwischen 1 und 10000 liegen.', 1;
    IF OBJECT_ID(N'toolbelt_archive.TVF_InternalListZipEntriesClr', N'FT') IS NULL
        THROW 51329, N'Der interne CLR-ZIP-Metadatenprovider ist nicht installiert.', 1;

    DECLARE @ProviderResult TABLE
    (
          ErrorNumber           int            NULL
        , ErrorMessage          nvarchar(4000) NULL
        , EntryOrdinal          int            NULL
        , EntryName             nvarchar(1024) NULL
        , IsDirectory           bit            NULL
        , CompressedBytes       bigint         NULL
        , UncompressedBytes     bigint         NULL
        , CompressionMethod     int            NULL
        , Crc32                 int            NULL
        , IsEncrypted           bit            NULL
        , IsExtractionSupported bit            NULL
        , DuplicateCount        int            NULL
        , IsPathSafe            bit            NULL
        , PathStatus            nvarchar(32)   NULL
        , LastModifiedAt        datetime2(0)   NULL
    );

    INSERT INTO @ProviderResult
    (
          ErrorNumber, ErrorMessage, EntryOrdinal, EntryName, IsDirectory
        , CompressedBytes, UncompressedBytes, CompressionMethod, Crc32
        , IsEncrypted, IsExtractionSupported, DuplicateCount, IsPathSafe
        , PathStatus, LastModifiedAt
    )
    SELECT
          ErrorNumber, ErrorMessage, EntryOrdinal, EntryName, IsDirectory
        , CompressedBytes, UncompressedBytes, CompressionMethod, Crc32
        , IsEncrypted, IsExtractionSupported, DuplicateCount, IsPathSafe
        , PathStatus, LastModifiedAt
    FROM toolbelt_archive.TVF_InternalListZipEntriesClr(@ZipArchive, @MaxEntries);

    IF EXISTS (SELECT 1 FROM @ProviderResult WHERE ErrorNumber IS NOT NULL)
    BEGIN
        IF (SELECT COUNT_BIG(*) FROM @ProviderResult) <> 1
            THROW 51329, N'Der interne CLR-ZIP-Metadatenprovider lieferte einen inkonsistenten Fehlerstatus.', 1;

        DECLARE
              @ProviderErrorNumber int
            , @ProviderErrorMessage nvarchar(2048);

        SELECT
              @ProviderErrorNumber = ErrorNumber
            , @ProviderErrorMessage = CONVERT(nvarchar(2048), LEFT(ErrorMessage, 2048))
        FROM @ProviderResult;

        IF @ProviderErrorNumber NOT BETWEEN 51320 AND 51329
            THROW 51329, N'Der interne CLR-ZIP-Metadatenprovider lieferte einen ungültigen Fehlercode.', 1;

        SET @ProviderErrorMessage = COALESCE(NULLIF(@ProviderErrorMessage, N''), N'Der CLR-ZIP-Metadatenprovider hat den Vorgang abgebrochen.');
        THROW @ProviderErrorNumber, @ProviderErrorMessage, 1;
    END;

    IF EXISTS
       (
           SELECT 1
           FROM @ProviderResult
           WHERE EntryOrdinal IS NULL
              OR EntryName IS NULL
              OR IsDirectory IS NULL
              OR CompressedBytes IS NULL
              OR UncompressedBytes IS NULL
              OR CompressionMethod IS NULL
              OR Crc32 IS NULL
              OR IsEncrypted IS NULL
              OR IsExtractionSupported IS NULL
              OR DuplicateCount IS NULL
              OR IsPathSafe IS NULL
              OR PathStatus IS NULL
       )
        THROW 51329, N'Der interne CLR-ZIP-Metadatenprovider lieferte eine unvollständige Datenzeile.', 1;

    CREATE TABLE #tbx_ZipList_ResultSource
    (
          EntryOrdinal          int            NOT NULL
        , EntryName             nvarchar(1024) NOT NULL
        , IsDirectory           bit            NOT NULL
        , CompressedBytes       bigint         NOT NULL
        , UncompressedBytes     bigint         NOT NULL
        , CompressionMethod     int            NOT NULL
        , Crc32                 int            NOT NULL
        , IsEncrypted           bit            NOT NULL
        , IsExtractionSupported bit            NOT NULL
        , DuplicateCount        int            NOT NULL
        , IsPathSafe            bit            NOT NULL
        , PathStatus            varchar(32)    NOT NULL
        , LastModifiedAt        datetime2(0)   NULL
    );

    INSERT INTO #tbx_ZipList_ResultSource
    SELECT
          EntryOrdinal, EntryName, IsDirectory, CompressedBytes
        , UncompressedBytes, CompressionMethod, Crc32, IsEncrypted
        , IsExtractionSupported, DuplicateCount, IsPathSafe
        , CONVERT(varchar(32), PathStatus), LastModifiedAt
    FROM @ProviderResult;

    IF @ResultTable IS NULL
    BEGIN
        SELECT
              EntryOrdinal, EntryName, IsDirectory, CompressedBytes
            , UncompressedBytes, CompressionMethod, Crc32, IsEncrypted
            , IsExtractionSupported, DuplicateCount, IsPathSafe, PathStatus
            , LastModifiedAt
        FROM #tbx_ZipList_ResultSource
        ORDER BY EntryOrdinal;
        RETURN 0;
    END;

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51329, N'Die ResultTable-Dependency toolbelt_core.USP_PrepareResultTable ist nicht installiert.', 1;

    CREATE TABLE #tbx_ZipList_ResultShape
    (
          EntryOrdinal          int            NOT NULL
        , EntryName             nvarchar(1024) NOT NULL
        , IsDirectory           bit            NOT NULL
        , CompressedBytes       bigint         NOT NULL
        , UncompressedBytes     bigint         NOT NULL
        , CompressionMethod     int            NOT NULL
        , Crc32                 int            NOT NULL
        , IsEncrypted           bit            NOT NULL
        , IsExtractionSupported bit            NOT NULL
        , DuplicateCount        int            NOT NULL
        , IsPathSafe            bit            NOT NULL
        , PathStatus            varchar(32)    NOT NULL
        , LastModifiedAt        datetime2(0)   NULL
    );

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable          = N'#tbx_ZipList_ResultShape'
        , @KeepData           = @KeepData
        , @Debug              = @Debug;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable) + N'
        SELECT
              EntryOrdinal, EntryName, IsDirectory, CompressedBytes
            , UncompressedBytes, CompressionMethod, Crc32, IsEncrypted
            , IsExtractionSupported, DuplicateCount, IsPathSafe, PathStatus
            , LastModifiedAt
        FROM #tbx_ZipList_ResultSource;';

    EXEC sys.sp_executesql @InsertSql;
    RETURN 0;
END;
GO
