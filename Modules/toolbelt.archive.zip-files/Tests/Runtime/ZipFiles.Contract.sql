-- Nur in eigenem ausdrücklich zugelassenem Windows-Testroot ContosoZipFiles ausführen.
-- Der koordinierte Runner entfernt nachweislich eigene Dateien; dieses Skript löscht keine.
SET NOCOUNT ON;
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #Entries VALUES(1,N'hello.txt',0x4869),(2,N'empty.txt',0x);
CREATE TABLE #Written(Dummy uniqueidentifier NULL);
DECLARE @Return int;
EXEC @Return=toolbelt_archive.USP_CreateZipFileFromEntries
    @EntryTable=N'#Entries',@RootAlias=N'ContosoZipFiles',@RelativePath=N'contract.zip',
    @Overwrite=1,@ResultTable=N'#Written';
IF @Return<>0 OR (SELECT COUNT_BIG(*) FROM #Written)<>1
   OR EXISTS(SELECT 1 FROM #Written WHERE BytesWritten<22 OR RootAlias<>N'ContosoZipFiles' OR RelativePath<>N'contract.zip' OR State<>'completed')
    THROW 54690,N'ZIP_FILES_CREATE_CONTRACT',1;
CREATE TABLE #Read(Dummy int);
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @RootAlias=N'ContosoZipFiles',@RelativePath=N'contract.zip',@ResultTable=N'#Read';
DECLARE @Archive varbinary(max)=(SELECT Content FROM #Read);
IF @Archive IS NULL OR (SELECT COUNT_BIG(*) FROM #Read)<>1 OR EXISTS(SELECT 1 FROM #Read WHERE EndOfFile<>1)
    THROW 54690,N'ZIP_FILES_ARCHIVE_READBACK',1;
EXEC @Return=toolbelt_archive.USP_ExtractZipEntryToFile
    @ZipArchive=@Archive,@EntryName=N'hello.txt',@RootAlias=N'ContosoZipFiles',@RelativePath=N'hello.txt',
    @Overwrite=1,@ResultTable=N'#Written',@KeepData=1;
IF @Return<>0 OR (SELECT COUNT_BIG(*) FROM #Written)<>2
   OR NOT EXISTS(SELECT 1 FROM #Written WHERE BytesWritten=2 AND RelativePath=N'hello.txt' AND State='completed')
    THROW 54690,N'ZIP_FILES_EXTRACT_APPEND',1;
TRUNCATE TABLE #Read;
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @RootAlias=N'ContosoZipFiles',@RelativePath=N'hello.txt',@ResultTable=N'#Read';
IF NOT EXISTS(SELECT 1 FROM #Read WHERE Content=0x4869 AND BytesRead=2 AND EndOfFile=1)
    THROW 54690,N'ZIP_FILES_PAYLOAD_READBACK',1;
EXEC @Return=toolbelt_archive.USP_ExtractZipEntryToFile
    @ZipArchive=@Archive,@EntryName=N'empty.txt',@RootAlias=N'ContosoZipFiles',@RelativePath=N'empty.txt',
    @Overwrite=1,@ResultTable=N'#Written',@KeepData=0;
IF @Return<>0 OR (SELECT COUNT_BIG(*) FROM #Written)<>1
   OR NOT EXISTS(SELECT 1 FROM #Written WHERE BytesWritten=0 AND RelativePath=N'empty.txt' AND State='completed')
    THROW 54690,N'ZIP_FILES_EMPTY_ENTRY_REPLACE',1;
TRUNCATE TABLE #Read;
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk @RootAlias=N'ContosoZipFiles',@RelativePath=N'empty.txt',@ResultTable=N'#Read';
IF NOT EXISTS(SELECT 1 FROM #Read WHERE Content=0x AND BytesRead=0 AND EndOfFile=1)
    THROW 54690,N'ZIP_FILES_ZERO_BYTE_FILE_READBACK',1;
DELETE #Entries;
EXEC toolbelt_archive.USP_CreateZipFileFromEntries
    @EntryTable=N'#Entries',@RootAlias=N'ContosoZipFiles',@RelativePath=N'empty.zip',
    @Overwrite=1,@ResultTable=N'#Written';
IF NOT EXISTS(SELECT 1 FROM #Written WHERE BytesWritten=22 AND RelativePath=N'empty.zip')
    THROW 54690,N'ZIP_FILES_EMPTY_ARCHIVE',1;
DROP TABLE #Entries,#Written,#Read;
PRINT N'PASS ZIP_FILES_CONTRACT';
GO
