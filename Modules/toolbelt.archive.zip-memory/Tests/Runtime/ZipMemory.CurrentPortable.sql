-- [__ZIP_TARGET__]. is bound by the runner to the local or central database.
-- This fixture covers the current marker-free DB/CLR binding and three APIs.
SET NOCOUNT ON;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>@ExpectedCl
    THROW 54731,N'ZIP_PORTABLE_CALLER_CL',1;
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #Entries VALUES(1,N'Mixed.bin',0x010203),(2,N'mixed.bin',0x0405);
CREATE TABLE #Archive(Dummy int);
EXEC [__ZIP_TARGET__].toolbelt_archive.USP_CreateZipFromEntries
    @EntryTable=N'#Entries',@CompressionMethod='Deflate',@ResultTable=N'#Archive';
DECLARE @Zip varbinary(max),@ArchiveBytes bigint,@Count int,@Total bigint,@Method int;
EXEC sys.sp_executesql
    N'SELECT @z=ArchivePayload,@b=ArchiveBytes,@c=EntryCount,@t=TotalPayloadBytes,@m=CompressionMethod FROM #Archive;',
    N'@z varbinary(max) OUTPUT,@b bigint OUTPUT,@c int OUTPUT,@t bigint OUTPUT,@m int OUTPUT',
    @Zip OUTPUT,@ArchiveBytes OUTPUT,@Count OUTPUT,@Total OUTPUT,@Method OUTPUT;
IF (SELECT COUNT(*) FROM #Archive)<>1 OR @Zip IS NULL OR @ArchiveBytes<>DATALENGTH(@Zip)
    OR @Count<>2 OR @Total<>5 OR @Method<>8
    THROW 54732,N'ZIP_PORTABLE_WRITER',1;

CREATE TABLE #List
(
    EntryOrdinal int NOT NULL,EntryName nvarchar(1024) NOT NULL,IsDirectory bit NOT NULL,
    CompressedBytes bigint NOT NULL,UncompressedBytes bigint NOT NULL,CompressionMethod int NOT NULL,
    Crc32 int NOT NULL,IsEncrypted bit NOT NULL,IsExtractionSupported bit NOT NULL,
    DuplicateCount int NOT NULL,IsPathSafe bit NOT NULL,PathStatus varchar(32) NOT NULL,LastModifiedAt datetime2(0) NULL
);
EXEC [__ZIP_TARGET__].toolbelt_archive.USP_ListZipEntriesFromBinary @ZipArchive=@Zip,@ResultTable=N'#List';
IF (SELECT COUNT(*) FROM #List)<>2
   OR NOT EXISTS(SELECT 1 FROM #List WHERE EntryOrdinal=1 AND EntryName COLLATE Latin1_General_100_BIN2=N'Mixed.bin'
        AND UncompressedBytes=3 AND CompressionMethod=8 AND DuplicateCount=1)
   OR NOT EXISTS(SELECT 1 FROM #List WHERE EntryOrdinal=2 AND EntryName COLLATE Latin1_General_100_BIN2=N'mixed.bin'
        AND UncompressedBytes=2 AND CompressionMethod=8 AND DuplicateCount=1)
    THROW 54733,N'ZIP_PORTABLE_LIST',1;

CREATE TABLE #Entry
(
    EntryName nvarchar(1024) NOT NULL,CompressedBytes bigint NOT NULL,UncompressedBytes bigint NOT NULL,
    CompressionMethod int NOT NULL,Crc32 int NULL,IsEncrypted bit NOT NULL,EntryPayload varbinary(max) NULL
);
EXEC [__ZIP_TARGET__].toolbelt_archive.USP_ExtractZipEntryFromBinary
    @ZipArchive=@Zip,@EntryName=N'Mixed.bin',@ResultTable=N'#Entry';
EXEC [__ZIP_TARGET__].toolbelt_archive.USP_ExtractZipEntryFromBinary
    @ZipArchive=@Zip,@EntryName=N'mixed.bin',@ResultTable=N'#Entry',@KeepData=1;
IF (SELECT COUNT(*) FROM #Entry)<>2
   OR NOT EXISTS(SELECT 1 FROM #Entry WHERE EntryName COLLATE Latin1_General_100_BIN2=N'Mixed.bin'
        AND EntryPayload=0x010203 AND DATALENGTH(EntryPayload)=3)
   OR NOT EXISTS(SELECT 1 FROM #Entry WHERE EntryName COLLATE Latin1_General_100_BIN2=N'mixed.bin'
        AND EntryPayload=0x0405 AND DATALENGTH(EntryPayload)=2)
    THROW 54734,N'ZIP_PORTABLE_ORDINAL_EXTRACT',1;

BEGIN TRY
    EXEC [__ZIP_TARGET__].toolbelt_archive.USP_ExtractZipEntryFromBinary
        @ZipArchive=@Zip,@EntryName=N'MIXED.bin',@ResultTable=N'#Entry';
    THROW 54735,N'ZIP_PORTABLE_CASE_ALIAS_ACCEPTED',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51322 OR ERROR_STATE()<>1 THROW;
END CATCH;
IF (SELECT COUNT(*) FROM #Entry)<>2 THROW 54736,N'ZIP_PORTABLE_ERROR_MUTATED_OUTPUT',1;

SELECT N'ZIP_CURRENT_PORTABLE_PASS' AS Outcome,4 AS Checks;
