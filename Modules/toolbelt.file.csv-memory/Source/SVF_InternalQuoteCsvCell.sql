-- Interner SAFE-Quotingtransport; gemeinsamer AnalyzeCell-Kern und eigener Allokationsdeckel.
-- Nur nach vollständiger erfolgreicher Messung/globalem Chargepreflight aufrufen; technische Fehler original.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.SVF_InternalQuoteCsvCell
(@Value nvarchar(max),@Separator nvarchar(2),@NullToken nvarchar(128),@IsHeader bit,@MaxOutputBytes bigint)
RETURNS nvarchar(max)
AS EXTERNAL NAME [Toolbelt_File_CsvMemory].[Toolbelt.Csv.CsvEntryPoints].[QuoteCell];
GO
