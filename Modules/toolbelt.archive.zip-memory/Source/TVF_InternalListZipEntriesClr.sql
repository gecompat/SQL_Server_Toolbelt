SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE FUNCTION [toolbelt_archive].[TVF_InternalListZipEntriesClr]
(
      @ZipArchive varbinary(max)
    , @MaxEntries int
)
RETURNS TABLE
(
      ErrorNumber          int            NULL
    , ErrorMessage         nvarchar(4000) NULL
    , EntryOrdinal         int            NULL
    , EntryName            nvarchar(1024) NULL
    , IsDirectory          bit            NULL
    , CompressedBytes      bigint         NULL
    , UncompressedBytes    bigint         NULL
    , CompressionMethod    int            NULL
    , Crc32                int            NULL
    , IsEncrypted          bit            NULL
    , IsExtractionSupported bit           NULL
    , DuplicateCount       int            NULL
    , IsPathSafe           bit            NULL
    , PathStatus           nvarchar(32)   NULL
    , LastModifiedAt       datetime2(0)   NULL
)
AS EXTERNAL NAME
    [Toolbelt_Archive_ZipMemory]
    [Toolbelt.Archive.ZipMemory.ZipEntryProvider]
    [ListZipEntriesFromBinary];
GO
