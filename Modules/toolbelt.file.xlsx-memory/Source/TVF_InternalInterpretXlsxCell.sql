/*
-- Objekt: toolbelt_file.TVF_InternalInterpretXlsxCell (interne CLR-FT)
-- Parameter: Sieben Zell-/Zielparameter; keine Workbook- oder Styleauswertung.
-- Resultset: Genau eine nullable Statuszeile mit 14 Spalten.
-- Fehlerverhalten: Erwartete Zellfehler als Status; unerwartete CLR-Fehler original.
-- Performance: Feste Input-/Ausgabequoten, datenzugriffsfreie Einzelzellinterpretation.
*/
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.TVF_InternalInterpretXlsxCell
(
 @StoredType nvarchar(max), @ValuePresent bit, @RawValue nvarchar(max),
 @TextValue nvarchar(max), @TargetType nvarchar(max), @FormatCode nvarchar(max), @Date1904 bit
)
RETURNS TABLE
(
 StoredType nvarchar(32) NULL, ValuePresent bit NULL, RawValue nvarchar(max) NULL,
 TextValue nvarchar(max) NULL, EchoPreserved bit NULL, ResolvedType nvarchar(16) NULL,
 NumberValue sql_variant NULL, BooleanValue bit NULL, DateValue date NULL,
 DateTimeValue datetime2(7) NULL, TimeValue time(7) NULL, DurationTicks bigint NULL,
 TypedTextValue nvarchar(max) NULL, StatusCode int NULL
)
AS EXTERNAL NAME [Toolbelt_File_XlsxMemory].[Toolbelt.Xlsx.Qualification.XlsxCellType].[Interpret];
GO
