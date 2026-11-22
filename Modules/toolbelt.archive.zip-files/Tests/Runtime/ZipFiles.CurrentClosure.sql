-- Own empty local Windows root ContosoZipClosure. The harness audits cleanup.
SET NOCOUNT ON;
CREATE TABLE #Write
(
    BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,
    RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL
);
CREATE TABLE #Read(Content varbinary(max),BytesRead int,NextByteOffset bigint,EndOfFile bit);
INSERT #Write EXEC toolbelt_filesystem.CLR_WriteBinaryFile
    @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.zip',@Content=0xAA;
INSERT #Write EXEC toolbelt_filesystem.CLR_WriteBinaryFile
    @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.bin',@Content=0xAAAAAAAAAA;
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #Entries VALUES(1,N'first.bin',0x010203);

EXEC toolbelt_archive.USP_CreateZipFileFromEntries
    @EntryTable=N'#Entries',@RootAlias=N'ContosoZipClosure',@RelativePath=N'first.zip',
    @Overwrite=1,@ResultTable=N'#Write';
INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.zip';
DECLARE @Zip varbinary(max)=(SELECT Content FROM #Read WHERE EndOfFile=1);
IF (SELECT COUNT(*) FROM #Write WHERE RelativePath=N'first.zip' AND State='completed'
    AND BytesWritten=DATALENGTH(@Zip) AND BytesWritten>22)<>1
    THROW 54690,N'ZIP_CLOSURE_WRITER_REPLACEMENT',1;

EXEC toolbelt_archive.USP_ExtractZipEntryToFile
    @ZipArchive=@Zip,@EntryName=N'first.bin',@RootAlias=N'ContosoZipClosure',
    @RelativePath=N'first.bin',@Overwrite=1,@ResultTable=N'#Write';
IF (SELECT COUNT(*) FROM #Write WHERE RelativePath=N'first.bin' AND State='completed'
    AND BytesWritten=3)<>1
    THROW 54690,N'ZIP_CLOSURE_READER_REPLACEMENT',1;

DELETE #Read;
INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.bin',@MaxBytes=2;
IF (SELECT COUNT(*) FROM #Read WHERE Content=0x0102 AND BytesRead=2 AND NextByteOffset=2 AND EndOfFile=0)<>1
    THROW 54690,N'ZIP_CLOSURE_FIRST_CHUNK',1;
DECLARE @Offset bigint=(SELECT NextByteOffset FROM #Read);
DELETE #Read;
INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.bin',@ByteOffset=@Offset,@MaxBytes=2;
IF (SELECT COUNT(*) FROM #Read WHERE Content=0x03 AND BytesRead=1 AND NextByteOffset=3 AND EndOfFile=1)<>1
    THROW 54690,N'ZIP_CLOSURE_FINAL_CHUNK',1;
SET @Offset=(SELECT NextByteOffset FROM #Read);
DELETE #Read;
INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.bin',@ByteOffset=@Offset,@MaxBytes=2;
IF (SELECT COUNT(*) FROM #Read WHERE Content=0x AND BytesRead=0 AND NextByteOffset=3 AND EndOfFile=1)<>1
    THROW 54690,N'ZIP_CLOSURE_EOF_OFFSET',1;

BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',
        @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.zip',@Overwrite=1,@MaxEntryBytes=2;
    THROW 54690,N'ZIP_CLOSURE_WRITER_LIMIT_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51354 OR ERROR_STATE()<>1 THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',
        @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.zip',@Overwrite=1,@MaxEnvelopeBytes=39;
    THROW 54690,N'ZIP_CLOSURE_ENVELOPE_LIMIT_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51354 OR ERROR_STATE()<>2 THROW;
END CATCH;

UPDATE #Entries
SET Payload=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'A'),16777216));
BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',
        @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.zip',@Overwrite=1,
        @CompressionMethod='Deflate',@WriterBudgetMilliseconds=1;
    THROW 54690,N'ZIP_CLOSURE_WRITER_BUDGET_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51356 THROW;
END CATCH;

DELETE #Read;
INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipClosure',@RelativePath=N'first.zip';
IF (SELECT COUNT(*) FROM #Read WHERE Content=@Zip AND DATALENGTH(Content)=DATALENGTH(@Zip)
    AND EndOfFile=1)<>1
    THROW 54690,N'ZIP_CLOSURE_REJECTED_WRITER_CHANGED_TARGET',1;

SELECT N'ZIP_CURRENT_CLOSURE_SQL_PASS' AS Outcome,9 AS Checks;
