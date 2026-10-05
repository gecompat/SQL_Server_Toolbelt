-- Synthetischer Roundtrip mit explizitem NULL-Token; keine Datei oder Netzwerkquelle.
CREATE TABLE #CsvCells(Dummy int);
EXEC toolbelt_file.USP_ParseCsv
 @Text=N'name,value'+NCHAR(10)+N'Contoso,NULL'+NCHAR(10)+N'Fabrikam,"NULL"',
 @HasHeader=1,@NullToken=N'NULL',@ResultTable=N'#CsvCells';
EXEC toolbelt_file.USP_WriteCsv
 @CellsTable=N'#CsvCells',@HasHeader=1,@NullToken=N'NULL',@LineEnding='LF';
DROP TABLE #CsvCells;
GO
EXEC toolbelt_file.USP_ParseCsv @Hilfe=1;
EXEC toolbelt_file.USP_WriteCsv @Hilfe=1;
