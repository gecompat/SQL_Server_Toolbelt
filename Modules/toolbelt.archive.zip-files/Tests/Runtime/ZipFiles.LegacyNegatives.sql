-- Uses an empty, owned root ContosoZipLegacyNegatives.
SET NOCOUNT ON;
EXEC toolbelt_filesystem.CLR_WriteBinaryFile
    @RootAlias=N'ContosoZipLegacyNegatives',@RelativePath=N'first.bin',@Content=0x010203;
DECLARE @Cases table
(
    Id int PRIMARY KEY, ArchivePayload varbinary(max), EntryName nvarchar(1024),
    MaxEntryBytes bigint, MaxRatio decimal(9,2), ErrorNumber int
);
INSERT @Cases VALUES
    (1,@CorruptZip,N'second.bin',1000,200,51328),
    (2,@EncryptedFlagZip,N'first.bin',1000,200,51324),
    (3,@DuplicateZip,N'first.bin',1000,200,51323),
    (4,@ClearZip,N'absent.bin',1000,200,51322),
    (5,@ClearZip,N'first.bin',1,200,51325),
    (6,@DeflateZip,N'first.bin',1000,1,51326);
DECLARE @Case int=1,@Archive varbinary(max),@Name nvarchar(1024),@MaxBytes bigint,
    @Ratio decimal(9,2),@ExpectedError int,@Checks int=0;
CREATE TABLE #Read(Content varbinary(max),BytesRead int,NextByteOffset bigint,EndOfFile bit);
WHILE @Case<=6
BEGIN
    SELECT @Archive=ArchivePayload,@Name=EntryName,@MaxBytes=MaxEntryBytes,
        @Ratio=MaxRatio,@ExpectedError=ErrorNumber FROM @Cases WHERE Id=@Case;
    BEGIN TRY
        EXEC toolbelt_archive.USP_ExtractZipEntryToFile
            @ZipArchive=@Archive,@EntryName=@Name,@RootAlias=N'ContosoZipLegacyNegatives',
            @RelativePath=N'first.bin',@Overwrite=1,@MaxEntryBytes=@MaxBytes,@MaxCompressionRatio=@Ratio;
        THROW 54690,N'ZIP_LEGACY_INVALID_ENTRY_WAS_PUBLISHED',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()<>@ExpectedError THROW;
    END CATCH;
    DELETE FROM #Read;
    INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
        @RootAlias=N'ContosoZipLegacyNegatives',@RelativePath=N'first.bin',@MaxBytes=4;
    IF (SELECT COUNT(*) FROM #Read WHERE Content=0x010203 AND BytesRead=3 AND EndOfFile=1)<>1
        THROW 54690,N'ZIP_LEGACY_REJECTED_ENTRY_CHANGED_TARGET',1;
    SET @Checks+=1;
    SET @Case+=1;
END;

CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #Entries VALUES(1,N'first.bin',0x0405);
BEGIN TRY
    EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',
        @RootAlias=N'ContosoZipLegacyNegatives',@RelativePath=N'first.bin',@Overwrite=0;
    THROW 54690,N'ZIP_LEGACY_WRITER_NO_OVERWRITE',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR CHARINDEX(N'TBXFS:HandlePublishFailed',ERROR_MESSAGE())=0 THROW;
END CATCH;
SET @Checks+=1;

BEGIN TRY
    EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=@ClearZip,@EntryName=N'first.bin',
        @RootAlias=N'ContosoZipLegacyNegatives',@RelativePath=N'first.bin',@Overwrite=0;
    THROW 54690,N'ZIP_LEGACY_READER_NO_OVERWRITE',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR CHARINDEX(N'TBXFS:HandlePublishFailed',ERROR_MESSAGE())=0 THROW;
END CATCH;
SET @Checks+=1;

DECLARE @Route int=1,@Root sysname,@Target nvarchar(4000),@Diagnostic nvarchar(128);
WHILE @Route<=4
BEGIN
    SET @Root=CASE WHEN @Route%2=1 THEN N'ContosoZipUnregistered' ELSE N'ContosoZipLegacyNegatives' END;
    SET @Target=CASE WHEN @Route%2=1 THEN N'never.bin' ELSE N'missing\never.bin' END;
    SET @Diagnostic=CASE WHEN @Route%2=1 THEN N'TBXFS:RootNotAuthorized' ELSE N'TBXFS:HandleOpenFailed' END;
    BEGIN TRY
        IF @Route<=2
            EXEC toolbelt_archive.USP_CreateZipFileFromEntries @EntryTable=N'#Entries',
                @RootAlias=@Root,@RelativePath=@Target;
        ELSE
            EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=@ClearZip,@EntryName=N'first.bin',
                @RootAlias=@Root,@RelativePath=@Target;
        THROW 54690,N'ZIP_LEGACY_INVALID_DESTINATION_WAS_ACCEPTED',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()<>51540 OR CHARINDEX(@Diagnostic,ERROR_MESSAGE())=0 THROW;
    END CATCH;
    SET @Checks+=1;
    SET @Route+=1;
END;

SET XACT_ABORT ON;
BEGIN TRANSACTION;
BEGIN TRY
    THROW 54690,N'ZIP_LEGACY_FIXTURE_DOOM_TRANSACTION',1;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>-1 THROW;
    BEGIN TRY
        EXEC toolbelt_archive.USP_CreateZipFileFromEntries
            @EntryTable=N'#Entries',@RootAlias=N'ContosoZipLegacyNegatives',@RelativePath=N'never.bin';
        THROW 54690,N'ZIP_LEGACY_WRITER_ACCEPTED_DOOMED_TRANSACTION',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()<>54621 OR XACT_STATE()<>-1 OR @@TRANCOUNT<>1 THROW;
    END CATCH;
    BEGIN TRY
        EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=@ClearZip,@EntryName=N'first.bin',
            @RootAlias=N'ContosoZipLegacyNegatives',@RelativePath=N'never.bin';
        THROW 54690,N'ZIP_LEGACY_READER_ACCEPTED_DOOMED_TRANSACTION',1;
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER()<>54621 OR XACT_STATE()<>-1 OR @@TRANCOUNT<>1 THROW;
    END CATCH;
    ROLLBACK TRANSACTION;
END CATCH;
SET XACT_ABORT OFF;
SET @Checks+=2;

SELECT N'ZIP_LEGACY_NEGATIVES_SQL_PASS' AS Outcome,@Checks AS Checks;
