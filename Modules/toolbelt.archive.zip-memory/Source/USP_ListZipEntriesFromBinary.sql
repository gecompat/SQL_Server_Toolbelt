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
        -- API_PARAMETER_HELP:BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
            CAST(N'toolbelt_archive' AS sysname) AS SchemaName,
            CAST(N'USP_ListZipEntriesFromBinary' AS sysname) AS ObjectName,
            CAST(v.Section AS varchar(32)) AS Section, CAST(v.Ordinal AS int) AS Ordinal,
            CAST(v.ItemName AS sysname) AS ItemName, CAST(v.SqlDataType AS varchar(256)) AS SqlDataType,
            CAST(v.IsRequired AS bit) AS IsRequired, CAST(v.IsNullable AS bit) AS IsNullable,
            CAST(v.DefaultValue AS nvarchar(4000)) AS DefaultValue,
            CAST(v.Description AS nvarchar(max)) AS Description,
            CAST(v.ExampleSql AS nvarchar(max)) AS ExampleSql
        FROM (VALUES
        (N'DESCRIPTION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Listet deklarierte Metadaten aller Central-Directory-Entries eines klassischen Single-Disk-ZIP aus varbinary(max), ohne Payloads zu lesen oder zu dekomprimieren.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 1, N'EntryOrdinal', N'int', 1, 0, NULL, CAST(N'Einsbasierte Position im Central Directory.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 2, N'EntryName', N'nvarchar(1024)', 1, 0, NULL, CAST(N'Exakt dekodierter, nicht normalisierter Entry-Name.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 3, N'IsDirectory', N'bit', 1, 0, NULL, CAST(N'Aus einem abschließenden Schrägstrich abgeleitete Directory-Markierung.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 4, N'CompressedBytes', N'bigint', 1, 0, NULL, CAST(N'Deklarierte komprimierte Größe.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 5, N'UncompressedBytes', N'bigint', 1, 0, NULL, CAST(N'Deklarierte unkomprimierte Größe.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 6, N'CompressionMethod', N'int', 1, 0, NULL, CAST(N'Numerischer ZIP-Methodenwert.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 7, N'Crc32', N'int', 1, 0, NULL, CAST(N'Deklarierte und beim Listing nicht neu berechnete CRC32.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 8, N'IsEncrypted', N'bit', 1, 0, NULL, CAST(N'Verschlüsselungsstatus aus den General-Purpose-Flags.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 9, N'IsExtractionSupported', N'bit', 1, 0, NULL, CAST(N'1 nur für unverschlüsselte Methods 0 und 8.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 10, N'DuplicateCount', N'int', 1, 0, NULL, CAST(N'Ordinal und case-sensitive gezählte Namensduplikate.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 11, N'IsPathSafe', N'bit', 1, 0, NULL, CAST(N'1 nur für einen kanonischen relativen Pfad.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 12, N'PathStatus', N'varchar(32)', 1, 0, NULL, CAST(N'safe, absolute, drive-qualified, parent-traversal oder noncanonical.' AS nvarchar(max)), NULL),
        (N'RESULT_COLUMN', 13, N'LastModifiedAt', N'datetime2(0)', 0, 1, NULL, CAST(N'DOS-Zeit ohne Zeitzonenbehauptung; bei ungültigem Wert NULL.' AS nvarchar(max)), NULL),
        (N'ERROR', 1, N'51320-51329', NULL, NULL, NULL, NULL, CAST(N'Parameter-, Struktur-, Limit-, Feature- und Providerfehlerbereich.' AS nvarchar(max)), NULL),
        (N'LIMITATION', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'ZIP64 und Multi-Disk werden abgelehnt. Metadaten sind keine Integritätsbestätigung des Payloads.' AS nvarchar(max)), NULL),
        (N'EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, CAST(N'Listet alle Entries eines ZIP-BLOBs.' AS nvarchar(max)), CAST(N'EXEC toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive = 0x...;' AS nvarchar(max))),
        (N'PARAMETER', 1, N'@ZipArchive', N'varbinary(max)', 1, 0, N'NULL', CAST(N'Vollständiger nicht leerer ZIP-Bytepuffer varbinary(max), kein Pfad/Base64text. NULL (technischer Help-Default)/0x ungültig. Harte Readergrenze 268435456 Archivbytes, höchstens 10000 Entries, Namen höchstens 1024 UTF-16-Einheiten; keine ZIP64-/Multi-Disk-Unterstützung. Namen werden nach Flag11 als UTF-8, sonst CP437 decodiert. Metadatenlisting ist keine CRC-/Payloadvalidierung aller Einträge.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 2, N'@MaxEntries', N'int', 0, 0, N'10000', CAST(N'Ganzzahl 1..10000 Central-Directory-Entries, Default 10000. NULL/0/negativ/höher ungültig. Überschreitung verwirft den gesamten Aufruf, kein gültiges TOP-Präfix; keine Payloadextraktion durch dieses Limit.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 3, N'@ResultTable', N'sysname', 0, 1, N'NULL', CAST(N'NULL (Default) liefert den fachlichen SELECT-Resultset. Sonst ein einzelner sysname mit 2..116 UTF-16-Einheiten einschließlich führendem # als Name einer bereits im Caller-Scope angelegten lokalen #Temp-Tabelle, z.B. N''#Result''; keine globale ##Temp, persistente oder mehrteilige Tabelle. Der ResultTable-Helper muss verfügbar sein; die Ausgabeform wird anhand des konkreten Objektresultsets vorbereitet.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 4, N'@KeepData', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 0 ersetzt Ergebnisdaten (Default), 1 hängt bei kompatibler ResultTable an; NULL entspricht 0. Nur bei nicht-NULL ResultTable relevant; Schema- und Datenbehandlung folgen dem kanonischen ResultTable-Vertrag.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 5, N'@Debug', N'tinyint', 0, 1, N'0', CAST(N'tinyint 0..255, Default 0; NULL wirkt wie 0. Keine eigene zusätzliche Readerdiagnose; im ResultTable-Pfad an den kanonischen Helper weitergereicht.' AS nvarchar(max)), NULL),
        (N'PARAMETER', 6, N'@Hilfe', N'bit', 0, 1, N'0', CAST(N'Taxativ für bit: 1 liefert nur die Standardhilfe vor der Fachvalidierung; 0 (Default) führt den Fachaufruf aus. NULL wird wie 0 behandelt. Syntaktisch erforderliche Argumente ohne technischen Default müssen auch beim Help-Aufruf angegeben werden.' AS nvarchar(max)), NULL)
        ) AS v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1
            WHEN 'RESULT_COLUMN' THEN 2 WHEN 'EXAMPLE' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
        -- API_PARAMETER_HELP:END
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
