-- Publish-vor-SQL-Fehler: eigene Datei bleibt, bisherige SQL-Ausgabe wird rückgerollt.
-- Nur koordinierter eigener Testroot ContosoZipFiles; kein compensating Delete.
SET NOCOUNT ON;
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #Entries VALUES(1,N'hello.txt',0x4869);
CREATE TABLE #Prior(BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL CONSTRAINT CK_ZipFilesTest_Prior CHECK(State='prior'));
INSERT #Prior VALUES(7,N'ContosoZipFiles',N'prior.txt','prior');
DECLARE @Seen bit=0;
BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries
        @EntryTable=N'#Entries',@RootAlias=N'ContosoZipFiles',@RelativePath=N'published-before-sql-error.zip',
        @Overwrite=1,@ResultTable=N'#Prior',@KeepData=0;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>547 THROW;
    SET @Seen=1;
END CATCH;
DECLARE @ObservedTC int=@@TRANCOUNT,@ObservedXS int=XACT_STATE();
IF @Seen<>1 OR @ObservedTC<>0 OR @ObservedXS<>0
   OR (SELECT COUNT_BIG(*) FROM #Prior)<>1
   OR NOT EXISTS(SELECT 1 FROM #Prior WHERE BytesWritten=7 AND RootAlias=N'ContosoZipFiles' AND RelativePath=N'prior.txt' AND State='prior')
    THROW 54690,N'ZIP_FILES_LATE_SQL_ROLLBACK',1;
CREATE TABLE #Read(Dummy int);
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @RootAlias=N'ContosoZipFiles',@RelativePath=N'published-before-sql-error.zip',@ResultTable=N'#Read';
IF (SELECT COUNT_BIG(*) FROM #Read)<>1 OR NOT EXISTS(SELECT 1 FROM #Read WHERE Content IS NOT NULL AND BytesRead>=22 AND EndOfFile=1)
    THROW 54690,N'ZIP_FILES_PUBLISHED_FILE_MUST_REMAIN',1;
DROP TABLE #Entries,#Prior,#Read;
PRINT N'PASS ZIP_FILES_SQL_OUTPUT_ATOMICITY_ONLY';
GO
