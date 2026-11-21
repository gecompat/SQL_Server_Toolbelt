-- Two separate Windows-authenticated sessions run this fixture with @Actor=1
-- and @Actor=2. The isolated database supplies a test-only rendezvous table
-- dbo.ZipRace with Phase, Actor, Ready, Started, Finished and Published columns.
SET NOCOUNT ON;
IF @Actor NOT IN (1,2) THROW 54690,N'ZIP_RACE_INVALID_ACTOR',1;
DECLARE @Size int=4194304;
DECLARE @Payload varbinary(max)=CONVERT(varbinary(max),REPLICATE(
    CONVERT(varchar(max),CASE WHEN @Actor=1 THEN 'A' ELSE 'B' END),@Size));
CREATE TABLE #Entries(Ordinal int,EntryName nvarchar(max),Payload varbinary(max));
INSERT #Entries VALUES(1,N'first.bin',@Payload);
CREATE TABLE #ArchiveOut(ArchivePayload varbinary(max) NOT NULL,ArchiveBytes bigint NOT NULL,
    EntryCount int NOT NULL,TotalPayloadBytes bigint NOT NULL,CompressionMethod int NOT NULL);
EXEC toolbelt_archive.USP_CreateZipFromEntries @EntryTable=N'#Entries',@ResultTable=N'#ArchiveOut';
DECLARE @Archive varbinary(max)=(SELECT ArchivePayload FROM #ArchiveOut);
CREATE TABLE #Write(BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,
    RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL);
CREATE TABLE #Read(Content varbinary(max),BytesRead int,NextByteOffset bigint,EndOfFile bit);
CREATE TABLE #Extracted(EntryName nvarchar(1024) NOT NULL,CompressedBytes bigint NOT NULL,
    UncompressedBytes bigint NOT NULL,CompressionMethod int NOT NULL,Crc32 int NULL,
    IsEncrypted bit NOT NULL,EntryPayload varbinary(max) NULL);

DECLARE @Phase int=1,@Deadline datetime2(7),@Started datetime2(7),@Finished datetime2(7),
    @Published bit,@Target nvarchar(4000),@Winner int,@Actual varbinary(max),@Expected varbinary(max);
WHILE @Phase<=2
BEGIN
    SET @Target=CASE WHEN @Phase=1 THEN N'race.zip' ELSE N'race.bin' END;
    UPDATE dbo.ZipRace SET Ready=1 WHERE Phase=@Phase AND Actor=@Actor AND Ready=0;
    IF @@ROWCOUNT<>1 THROW 54690,N'ZIP_RACE_RENDEZVOUS_STATE',1;
    SET @Deadline=DATEADD(second,20,SYSUTCDATETIME());
    WHILE (SELECT COUNT(*) FROM dbo.ZipRace WHERE Phase=@Phase AND Ready=1)<2
    BEGIN
        IF SYSUTCDATETIME()>@Deadline THROW 54690,N'ZIP_RACE_PEER_NOT_READY',1;
        WAITFOR DELAY '00:00:00.010';
    END;

    SET @Started=SYSUTCDATETIME();
    BEGIN TRY
        IF @Phase=1
            EXEC toolbelt_archive.USP_CreateZipFileFromEntries
                @EntryTable=N'#Entries',@RootAlias=N'ContosoZipLegacyRace',
                @RelativePath=@Target,@Overwrite=0,@ResultTable=N'#Write';
        ELSE
            EXEC toolbelt_archive.USP_ExtractZipEntryToFile @ZipArchive=@Archive,
                @EntryName=N'first.bin',@RootAlias=N'ContosoZipLegacyRace',
                @RelativePath=@Target,@Overwrite=0,@ResultTable=N'#Write';
        SET @Finished=SYSUTCDATETIME();
        SET @Published=1;
        IF (SELECT COUNT(*) FROM #Write WHERE RelativePath=@Target AND State='completed')<>1
            THROW 54690,N'ZIP_RACE_WINNER_OUTPUT',1;
    END TRY
    BEGIN CATCH
        SET @Finished=SYSUTCDATETIME();
        IF ERROR_NUMBER()<>51540 OR CHARINDEX(N'TBXFS:HandlePublishFailed',ERROR_MESSAGE())=0 THROW;
        SET @Published=0;
    END CATCH;
    DELETE #Write;
    UPDATE dbo.ZipRace SET Started=@Started,Finished=@Finished,Published=@Published
        WHERE Phase=@Phase AND Actor=@Actor;
    SET @Deadline=DATEADD(second,20,SYSUTCDATETIME());
    WHILE (SELECT COUNT(*) FROM dbo.ZipRace WHERE Phase=@Phase AND Finished IS NOT NULL)<2
    BEGIN
        IF SYSUTCDATETIME()>@Deadline THROW 54690,N'ZIP_RACE_PEER_NOT_FINISHED',1;
        WAITFOR DELAY '00:00:00.010';
    END;

    IF (SELECT COUNT(*) FROM dbo.ZipRace WHERE Phase=@Phase AND Published=1)<>1
        OR (SELECT COUNT(*) FROM dbo.ZipRace WHERE Phase=@Phase AND Published=0)<>1
        OR EXISTS
        (
            SELECT 1 FROM dbo.ZipRace a JOIN dbo.ZipRace b ON a.Phase=b.Phase AND a.Actor<>b.Actor
            WHERE a.Phase=@Phase AND a.Started>=b.Finished
        )
        THROW 54690,N'ZIP_RACE_OVERLAP_OR_SINGLE_PUBLICATION',1;
    IF @Actor=1
    BEGIN
        SELECT @Winner=Actor FROM dbo.ZipRace WHERE Phase=@Phase AND Published=1;
        SET @Expected=CONVERT(varbinary(max),REPLICATE(
            CONVERT(varchar(max),CASE WHEN @Winner=1 THEN 'A' ELSE 'B' END),@Size));
        DELETE #Read;
        INSERT #Read EXEC toolbelt_filesystem.CLR_ReadBinaryFileChunk
            @RootAlias=N'ContosoZipLegacyRace',@RelativePath=@Target,@MaxBytes=8388608;
        SET @Actual=(SELECT Content FROM #Read WHERE EndOfFile=1);
        IF @Phase=1
        BEGIN
            EXEC toolbelt_archive.USP_ExtractZipEntryFromBinary
                @ZipArchive=@Actual,@EntryName=N'first.bin',@ResultTable=N'#Extracted';
            SET @Actual=(SELECT EntryPayload FROM #Extracted);
        END;
        IF @Actual IS NULL OR DATALENGTH(@Actual)<>@Size
            OR HASHBYTES('SHA2_256',@Actual)<>HASHBYTES('SHA2_256',@Expected)
            THROW 54690,N'ZIP_RACE_WINNING_BYTES',1;
    END;
    SET @Phase+=1;
END;
SELECT N'ZIP_LEGACY_RACE_SQL_PASS' AS Outcome, @Actor AS Actor, 2 AS Cases;
