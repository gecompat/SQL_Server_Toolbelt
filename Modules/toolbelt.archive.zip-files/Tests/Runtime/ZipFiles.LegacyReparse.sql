-- The lab harness owns both the junction and its synthetic target directory.
SET NOCOUNT ON;
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #Entries VALUES(1,N'first.bin',0x0405);

BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries
        @EntryTable=N'#Entries',@RootAlias=N'ContosoZipLegacyReparse',
        @RelativePath=N'junction\protected.bin',@Overwrite=1;
    THROW 54690,N'ZIP_LEGACY_WRITER_REPARSE_WAS_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR CHARINDEX(N'TBXFS:ReparsePointForbidden',ERROR_MESSAGE())=0 THROW;
END CATCH;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryToFile
        @ZipArchive=@Zip,@EntryName=N'first.bin',@RootAlias=N'ContosoZipLegacyReparse',
        @RelativePath=N'junction\protected.bin',@Overwrite=1;
    THROW 54690,N'ZIP_LEGACY_READER_REPARSE_WAS_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR CHARINDEX(N'TBXFS:ReparsePointForbidden',ERROR_MESSAGE())=0 THROW;
END CATCH;
SELECT N'ZIP_LEGACY_REPARSE_SQL_PASS' AS Outcome,2 AS Checks;
