SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

/*
 * Interner Providervertrag. Öffentliche Aufrufer verwenden ausschließlich
 * toolbelt_archive.USP_ExtractZipEntryFromBinary.
 */
IF OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr', N'FT') IS NOT NULL
    DROP FUNCTION [toolbelt_archive].[TVF_InternalExtractZipEntryClr];
GO

CREATE FUNCTION [toolbelt_archive].[TVF_InternalExtractZipEntryClr]
(
      @ZipArchive          varbinary(max)
    , @EntryName           nvarchar(1024)
    , @MaxEntryBytes       bigint
    , @MaxCompressionRatio decimal(9,2)
    , @FailIfEncrypted     bit
)
RETURNS TABLE
(
      ErrorNumber          int
    , ErrorMessage         nvarchar(4000)
    , EntryName            nvarchar(1024)
    , CompressedBytes      bigint
    , UncompressedBytes    bigint
    , CompressionMethod    int
    , Crc32                int
    , IsEncrypted          bit
    , EntryPayload         varbinary(max)
)
AS EXTERNAL NAME
    [Toolbelt_Archive_ZipMemory]
    .[Toolbelt.Archive.ZipMemory.ZipEntryProvider]
    .[ExtractZipEntry];
GO
