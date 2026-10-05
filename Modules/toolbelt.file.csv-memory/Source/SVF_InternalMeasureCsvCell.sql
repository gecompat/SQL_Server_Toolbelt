-- Interner SAFE-Messtransport; gemeinsamer AnalyzeCell-Kern, keine Fragmentallokation.
-- Nonnegative UTF-16-Bytes oder negativer eigener Fachcode; unerwartetes NULL ist Invariantenfehler.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.SVF_InternalMeasureCsvCell
(@Value nvarchar(max),@Separator nvarchar(2),@NullToken nvarchar(128),@IsHeader bit)
RETURNS bigint
AS EXTERNAL NAME [Toolbelt_File_CsvMemory].[Toolbelt.Csv.CsvEntryPoints].[MeasureCell];
GO
