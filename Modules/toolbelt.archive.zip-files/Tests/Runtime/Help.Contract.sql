-- Hilfetests enthalten keinerlei Dateiarbeit, auch innerhalb Caller-TX.
SET NOCOUNT ON;
CREATE TABLE #HelpRows(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
CREATE TABLE #Untouched(Dummy int NOT NULL);
INSERT #Untouched VALUES(7);
BEGIN TRANSACTION;
INSERT #HelpRows EXEC toolbelt_archive.USP_CreateZipFileFromEntries
    @EntryTable=N'#missing',@RootAlias=NULL,@CompressionMethod=NULL,@ResultTable=N'#Untouched',@KeepData=0,@Debug=255,@Hilfe=1;
IF @@TRANCOUNT<>1 OR (SELECT COUNT(*) FROM #Untouched WHERE Dummy=7)<>1
BEGIN
    ROLLBACK TRANSACTION;
    THROW 54690,N'ZIP_FILES_HELP_MUTATION',1;
END;
ROLLBACK TRANSACTION;
-- Die HelpRows aus der Testtransaktion sind zurückgerollt; ohne Fachparameter wiederholen.
INSERT #HelpRows EXEC toolbelt_archive.USP_CreateZipFileFromEntries @Hilfe=1;
INSERT #HelpRows EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=NULL,@EntryName=NULL,@ResultTable=N'#missing',@Debug=255,@Hilfe=1;
IF (SELECT COUNT(DISTINCT ObjectName) FROM #HelpRows)<>2
   OR EXISTS(SELECT 1 FROM #HelpRows WHERE HelpContractVersion<>'1.0' OR SchemaName<>N'toolbelt_archive')
   OR (SELECT COUNT(*) FROM #HelpRows WHERE ObjectName=N'USP_CreateZipFileFromEntries' AND Section='PARAMETER')<>17
   OR (SELECT COUNT(*) FROM #HelpRows WHERE ObjectName=N'USP_ExtractZipEntryToFile' AND Section='PARAMETER')<>12
   OR (SELECT COUNT(*) FROM #HelpRows WHERE Section='RESULT_COLUMN')<>8
   OR EXISTS(SELECT ObjectName,Section,Ordinal FROM #HelpRows GROUP BY ObjectName,Section,Ordinal HAVING COUNT(*)<>1)
   OR EXISTS(SELECT 1 FROM (VALUES(N'USP_CreateZipFileFromEntries'),(N'USP_ExtractZipEntryToFile')) o(Name)
       CROSS JOIN (VALUES('DESCRIPTION'),('PARAMETER'),('RESULT_COLUMN'),('EXAMPLE')) s(Section)
       WHERE NOT EXISTS(SELECT 1 FROM #HelpRows h WHERE h.ObjectName=o.Name AND h.Section=s.Section))
    THROW 54690,N'ZIP_FILES_HELP_CONTRACT',1;
DROP TABLE #HelpRows,#Untouched;
PRINT N'PASS ZIP_FILES_HELP';
GO
