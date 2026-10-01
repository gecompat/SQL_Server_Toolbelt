/*
Interner Statusrow-Provider für USP_ReadXlsxWorksheetCells; keine öffentliche Neben-API.
Dependency Toolbelt_File_XlsxMemory 1.0.0 und Toolbelt_Archive_ZipMemory 1.4.0.
SAFE, DataAccess/SystemDataAccess None. Vollständige Materialisierung vor Rows.
Erwartete Inputfehler: eine ErrorNumber/ErrorMessage-Zeile; unerwartete CLR-Fehler
bleiben Originalfehler. Keine Dateisystem- oder Netzwerkzugriffe.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.TVF_InternalXlsxCells
(
    @XlsxBinary varbinary(max),
    @SheetOrdinal int,
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
    RowOrdinal int NULL,
    ColumnOrdinal int NULL,
    StoredType nvarchar(16) NULL,
    ValuePresent bit NULL,
    RawValue nvarchar(max) NULL,
    TextValue nvarchar(max) NULL,
    FormulaPresent bit NULL,
    FormulaText nvarchar(max) NULL,
    FormulaKind nvarchar(16) NULL,
    SharedFormulaIndex int NULL,
    CachePresent bit NULL,
    CacheValue nvarchar(max) NULL
)
AS EXTERNAL NAME [Toolbelt_File_XlsxMemory].[Toolbelt.Xlsx.Qualification.XlsxEntryPoints].[ReadCells];
GO
