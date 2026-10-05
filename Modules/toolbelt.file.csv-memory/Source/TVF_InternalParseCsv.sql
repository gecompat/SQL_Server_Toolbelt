-- Interner SAFE-Parsertransport; fünf physisch nullable Unicode-/Statusspalten.
-- Vollständiger Preflight im CLR-Kern; ein isolierter Fachfehlersentinel, unerwartete Fehler original.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE FUNCTION toolbelt_file.TVF_InternalParseCsv
(@Text nvarchar(max),@Separator nvarchar(2),@HasHeader bit,@NullToken nvarchar(128),@MaxRows bigint,@MaxColumns int,@MaxCells bigint,@MaxInputBytes bigint)
RETURNS TABLE(RowKind nvarchar(6),RowOrdinal bigint,ColumnOrdinal int,[Value] nvarchar(max),ErrorCode int)
AS EXTERNAL NAME [Toolbelt_File_CsvMemory].[Toolbelt.Csv.CsvEntryPoints].[Parse];
GO
