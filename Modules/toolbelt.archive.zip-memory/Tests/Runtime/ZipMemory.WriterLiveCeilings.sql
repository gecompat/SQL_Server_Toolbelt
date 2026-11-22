-- Expects a portable target selected by the runner. Payloads stay in SQL.
SET NOCOUNT ON;
DECLARE @OneEntry int=33554432,@FullPayload bigint=134217728;
CREATE TABLE #Entries(Ordinal int NOT NULL,EntryName nvarchar(max) NOT NULL,Payload varbinary(max) NOT NULL);
DECLARE @Index int=1;
WHILE @Index<=1024
BEGIN
    INSERT #Entries VALUES(@Index,CONCAT(N'file',@Index),
        CASE WHEN @Index<=4 THEN CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'A'),@OneEntry)) ELSE 0x END);
    SET @Index+=1;
END;
UPDATE #Entries SET EntryName=REPLICATE(N'x',2048) WHERE Ordinal=1024;
CREATE TABLE #Archive
(
    ArchivePayload varbinary(max) NOT NULL, ArchiveBytes bigint NOT NULL, EntryCount int NOT NULL,
    TotalPayloadBytes bigint NOT NULL, CompressionMethod int NOT NULL
);
EXEC [__ZIP_TARGET__].toolbelt_archive.USP_CreateZipFromEntries
    @EntryTable=N'#Entries',@ResultTable=N'#Archive',@MaxEntries=1024,@MaxEntryNameCodeUnits=2048,
    @MaxEntryBytes=33554432,@MaxTotalPayloadBytes=134217728,@MaxEnvelopeBytes=142606336,
    @MaxArchiveBytes=150994944,@WriterBudgetMilliseconds=60000;
DECLARE @Zip varbinary(max),@ArchiveBytes bigint;
SELECT @Zip=ArchivePayload,@ArchiveBytes=ArchiveBytes FROM #Archive;
DECLARE @ExpectedBytes bigint=22+76*1024+@FullPayload+
    (SELECT 2*SUM(CONVERT(bigint,DATALENGTH(CONVERT(varchar(max),EntryName)))) FROM #Entries);
IF (SELECT COUNT(*) FROM #Archive)<>1 OR DATALENGTH(@Zip)<>@ExpectedBytes OR @ArchiveBytes<>@ExpectedBytes
    OR NOT EXISTS(SELECT 1 FROM #Archive WHERE EntryCount=1024 AND TotalPayloadBytes=@FullPayload AND CompressionMethod=0)
    OR SUBSTRING(@Zip,@ArchiveBytes-21,4)<>0x504B0506
    OR SUBSTRING(@Zip,@ArchiveBytes-11,2)<>0x0004
    THROW 54741,N'ZIP_WRITER_LIVE_CEILING',1;
-- The portable reader admits at most 1024 name units at listing/extraction.
-- Check the independent ZIP end record and the last central-directory name.
DECLARE @NameBytes varbinary(max)=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'x'),2048));
IF SUBSTRING(@Zip,@ArchiveBytes-2069,2048)<>@NameBytes
    THROW 54743,N'ZIP_WRITER_LONG_NATIVE_NAME',1;
IF SUBSTRING(@Zip,1,4)<>0x504B0304 OR SUBSTRING(@Zip,31,5)<>0x66696C6531
    OR HASHBYTES('SHA2_256',SUBSTRING(@Zip,36,@OneEntry))<>
       (SELECT HASHBYTES('SHA2_256',Payload) FROM #Entries WHERE Ordinal=1)
    THROW 54742,N'ZIP_WRITER_FIRST_PAYLOAD',1;

-- Negative probes use small inputs to isolate the indicated public limit.
DELETE #Entries;
INSERT #Entries VALUES(1,REPLICATE(N'x',2049),0x01);
BEGIN TRY
    EXEC [__ZIP_TARGET__].toolbelt_archive.USP_CreateZipFromEntries
        @EntryTable=N'#Entries',@ResultTable=N'#Archive',@MaxEntryNameCodeUnits=2048;
    THROW 54744,N'ZIP_WRITER_LONG_NAME_OVERFLOW',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51354 OR ERROR_STATE()<>1 THROW;
END CATCH;

DELETE #Entries;
INSERT #Entries VALUES(1,N'one',CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'A'),@OneEntry+1)));
BEGIN TRY
    EXEC [__ZIP_TARGET__].toolbelt_archive.USP_CreateZipFromEntries
        @EntryTable=N'#Entries',@ResultTable=N'#Archive',@MaxEntryBytes=33554432;
    THROW 54745,N'ZIP_WRITER_ENTRY_OVERFLOW',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51354 OR ERROR_STATE()<>1 THROW;
END CATCH;

UPDATE #Entries SET Payload=SUBSTRING(Payload,1,@OneEntry);
INSERT #Entries SELECT 2,N'two',Payload FROM #Entries WHERE Ordinal=1;
INSERT #Entries SELECT 3,N'three',Payload FROM #Entries WHERE Ordinal=1;
INSERT #Entries SELECT 4,N'four',Payload FROM #Entries WHERE Ordinal=1;
INSERT #Entries VALUES(5,N'excess',0x41);
BEGIN TRY
    EXEC [__ZIP_TARGET__].toolbelt_archive.USP_CreateZipFromEntries
        @EntryTable=N'#Entries',@ResultTable=N'#Archive',@MaxEntryBytes=33554432,@MaxTotalPayloadBytes=134217728;
    THROW 54746,N'ZIP_WRITER_TOTAL_OVERFLOW',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51354 OR ERROR_STATE()<>1 THROW;
END CATCH;

DELETE #Entries;
SET @Index=1;
WHILE @Index<=1025
BEGIN
    INSERT #Entries VALUES(@Index,CONCAT(N'file',@Index),0x);
    SET @Index+=1;
END;
BEGIN TRY
    EXEC [__ZIP_TARGET__].toolbelt_archive.USP_CreateZipFromEntries
        @EntryTable=N'#Entries',@ResultTable=N'#Archive',@MaxEntries=1024;
    THROW 54747,N'ZIP_WRITER_COUNT_OVERFLOW',1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER()<>51354 OR ERROR_STATE()<>1 THROW;
END CATCH;

IF (SELECT COUNT(*) FROM #Archive)<>1 OR NOT EXISTS
   (SELECT 1 FROM #Archive WHERE ArchiveBytes=@ExpectedBytes AND DATALENGTH(ArchivePayload)=@ExpectedBytes
      AND HASHBYTES('SHA2_256',ArchivePayload)=HASHBYTES('SHA2_256',@Zip))
    THROW 54748,N'ZIP_WRITER_REJECTED_OUTPUT_MUTATED',1;
SELECT N'ZIP_PORTABLE_WRITER_CEILING_PASS' AS Outcome,6 AS Checks;
