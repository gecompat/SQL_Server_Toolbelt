/*
Interner Statusrow-Provider für USP_ListXlsxWorksheets; keine öffentliche Neben-API.
Dependency Toolbelt_File_XlsxMemory 1.0.0 und Toolbelt_Archive_ZipMemory 1.4.0.
SAFE, DataAccess/SystemDataAccess None. Vollständige Materialisierung vor Rows.
Erwartete Inputfehler: eine ErrorNumber/ErrorMessage-Zeile; unerwartete CLR-Fehler
bleiben Originalfehler. Keine Dateisystem- oder Netzwerkzugriffe.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.TVF_InternalXlsxSheets
(
    @XlsxBinary varbinary(max),
    @MaxArchiveBytes bigint,
    @MaxPartBytes bigint,
    @MaxTotalUncompressedBytes bigint,
    @MaxParts int,
    @MaxSheets int,
    @MaxCells int,
    @MaxSharedStrings int,
    @MaxSharedStringBytes bigint,
    @MaxXmlDepth int,
    @MaxCompressionRatio decimal(18,4),
    @BudgetMilliseconds int
)
RETURNS TABLE
(
    ErrorNumber int NULL, ErrorMessage nvarchar(4000) NULL,
    SheetOrdinal int NULL,
    SheetName nvarchar(max) NULL,
    Visibility nvarchar(16) NULL,
    Date1904 bit NULL
)
AS EXTERNAL NAME [Toolbelt_File_XlsxMemory].[Toolbelt.Xlsx.Qualification.XlsxEntryPoints].[ListSheets];
GO

