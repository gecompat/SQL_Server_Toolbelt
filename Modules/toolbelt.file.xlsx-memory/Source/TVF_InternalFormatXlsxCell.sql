/*
-- Objekt: toolbelt_file.TVF_InternalFormatXlsxCell (interne CLR-FT).
-- Zweck: Reiner Einzelzell-Anzeigetransport auf unverändertem Typkern.
-- Parameter: Acht Zell-/Ziel-/Kulturparameter, keine Workbook-/Styleauswertung.
-- Resultset: Genau eine nullable Zeile DisplayText nvarchar(max), StatusCode int.
-- Fehler: Erwartete Zellfehler als Status; unerwartete CLR-Fehler original.
-- Performance: Feste Input-/Ausgabequoten, kein externer Datenzugriff.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.TVF_InternalFormatXlsxCell
(
 @StoredType nvarchar(max), @ValuePresent bit, @RawValue nvarchar(max),
 @TextValue nvarchar(max), @TargetType nvarchar(max), @FormatCode nvarchar(max),
 @Date1904 bit, @CultureName nvarchar(max)
)
RETURNS TABLE(DisplayText nvarchar(max) NULL, StatusCode int NULL)
AS EXTERNAL NAME [Toolbelt_File_XlsxMemory].[Toolbelt.Xlsx.Qualification.XlsxCellDisplayBridge].[Evaluate];
GO
