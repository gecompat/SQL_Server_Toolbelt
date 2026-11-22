-- Requires Caller Windows authentication and an owned ContosoIo root with an empty WorkPath.
SET NOCOUNT ON;
SET XACT_ABORT OFF;
CREATE TABLE #Write( BytesWritten bigint NOT NULL, RootAlias nvarchar(128) NOT NULL,
    RelativePath nvarchar(4000) NOT NULL, State varchar(16) NOT NULL );
CREATE TABLE #Binary( Content varbinary(max) NULL, BytesRead int NOT NULL,
    NextByteOffset bigint NOT NULL, EndOfFile bit NOT NULL );
CREATE TABLE #Text( Content nvarchar(max) NULL, BytesRead int NOT NULL,
    NextByteOffset bigint NOT NULL, EndOfFile bit NOT NULL, EncodingName nvarchar(128) NOT NULL );

DECLARE @cap int=16777216, @checks int=0;
DECLARE @ascii varchar(max)=REPLICATE(CONVERT(varchar(max),'a'),@cap);
DECLARE @binary varbinary(max)=CONVERT(varbinary(max),@ascii)+0x62;
EXEC toolbelt_filesystem.USP_WriteBinaryFile N'ContosoIo',N'chunks.bin',@binary,@ResultTable=N'#Write';
IF (SELECT COUNT(*) FROM #Write WHERE BytesWritten=16777217 AND State='completed')<>1
    THROW 52970,N'FILESYSTEM_BINARY_WRITE',1;
SET @checks+=1;

EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk N'ContosoIo',N'chunks.bin',0,16777216,@ResultTable=N'#Binary';
IF (SELECT COUNT(*) FROM #Binary WHERE BytesRead=@cap AND NextByteOffset=@cap AND EndOfFile=0
    AND HASHBYTES('SHA2_256',Content)=HASHBYTES('SHA2_256',@ascii))<>1
    THROW 52970,N'FILESYSTEM_BINARY_CAP',2;
SET @checks+=1;
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk N'ContosoIo',N'chunks.bin',16777216,1,@ResultTable=N'#Binary';
IF (SELECT COUNT(*) FROM #Binary WHERE Content=0x62 AND BytesRead=1 AND NextByteOffset=16777217 AND EndOfFile=1)<>1
    THROW 52970,N'FILESYSTEM_BINARY_NEXT',3;
SET @checks+=1;
BEGIN TRY
    EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk N'ContosoIo',N'chunks.bin',0,16777217,@ResultTable=N'#Binary';
    THROW 52970,N'FILESYSTEM_BINARY_OVER_CAP_ACCEPTED',4;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR ERROR_STATE()<>1 OR ERROR_MESSAGE() NOT LIKE N'%InvalidChunkRange%' THROW;
END CATCH;
IF (SELECT COUNT(*) FROM #Binary WHERE Content=0x62 AND NextByteOffset=16777217)<>1
    THROW 52970,N'FILESYSTEM_BINARY_REJECTED_RESULT_CHANGED',4;
SET @checks+=1;

EXEC toolbelt_filesystem.USP_ReadTextFileChunk N'ContosoIo',N'chunks.bin',0,16777216,N'utf-8',@ResultTable=N'#Text';
IF (SELECT COUNT(*) FROM #Text WHERE BytesRead=@cap AND NextByteOffset=@cap AND EndOfFile=0
    AND HASHBYTES('SHA2_256',Content)=HASHBYTES('SHA2_256',CONVERT(nvarchar(max),@ascii)))<>1
    THROW 52970,N'FILESYSTEM_TEXT_CAP',5;
SET @checks+=1;
BEGIN TRY
    EXEC toolbelt_filesystem.USP_ReadTextFileChunk N'ContosoIo',N'chunks.bin',0,16777217,N'utf-8',@ResultTable=N'#Text';
    THROW 52970,N'FILESYSTEM_TEXT_OVER_CAP_ACCEPTED',6;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR ERROR_STATE()<>1 OR ERROR_MESSAGE() NOT LIKE N'%InvalidChunkRange%' THROW;
END CATCH;
SET @checks+=1;

-- Force a read to stop before the first byte of a supplementary UTF-8 character.
EXEC toolbelt_filesystem.USP_WriteBinaryFile N'ContosoIo',N'utf8-cut.bin',0x414243F09FA7AA5A,@ResultTable=N'#Write';
EXEC toolbelt_filesystem.USP_ReadTextFileChunk N'ContosoIo',N'utf8-cut.bin',0,4,N'utf-8',@ResultTable=N'#Text';
IF (SELECT COUNT(*) FROM #Text WHERE Content=N'ABC' AND BytesRead=3 AND NextByteOffset=3 AND EndOfFile=0)<>1
    THROW 52970,N'FILESYSTEM_TEXT_CHUNK_BOUNDARY',7;
SET @checks+=1;
EXEC toolbelt_filesystem.USP_ReadTextFileChunk N'ContosoIo',N'utf8-cut.bin',3,5,N'utf-8',@ResultTable=N'#Text';
IF (SELECT COUNT(*) FROM #Text WHERE CONVERT(varbinary(max),Content)=0x3ED8EADD5A00
    AND BytesRead=5 AND NextByteOffset=8 AND EndOfFile=1)<>1
    THROW 52970,N'FILESYSTEM_TEXT_CHUNK_RESUME',8;
SET @checks+=1;

DECLARE @encodings table(Path nvarchar(40), EncodingName nvarchar(128), FixtureBytes varbinary(16), WriteBom bit);
INSERT @encodings VALUES
    (N'utf8.txt',N'utf-8',0xEFBBBF41E282AC,1),
    (N'utf16le.txt',N'utf-16',0xFFFE4100AC20,1),
    (N'utf16be.txt',N'utf-16BE',0xFEFF004120AC,1),
    (N'cp1252.txt',N'windows-1252',0x4180,0);
DECLARE @path nvarchar(40), @encoding nvarchar(128), @bytes varbinary(16), @bom bit,
    @text nvarchar(10)=N'A'+NCHAR(8364), @decoded nvarchar(10);
DECLARE EncodingCases CURSOR LOCAL FAST_FORWARD FOR SELECT Path,EncodingName,FixtureBytes,WriteBom FROM @encodings;
OPEN EncodingCases;
FETCH NEXT FROM EncodingCases INTO @path,@encoding,@bytes,@bom;
WHILE @@FETCH_STATUS=0
BEGIN
    EXEC toolbelt_filesystem.USP_WriteTextFile N'ContosoIo',@path,@text,@encoding,@bom,@ResultTable=N'#Write';
    EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk N'ContosoIo',@path,0,32,@ResultTable=N'#Binary';
    IF (SELECT COUNT(*) FROM #Binary WHERE Content=@bytes AND BytesRead=DATALENGTH(@bytes)
        AND NextByteOffset=DATALENGTH(@bytes) AND EndOfFile=1)<>1
        THROW 52970,N'FILESYSTEM_CODEPAGE_BYTES',9;
    SET @checks+=1;
    SET @decoded=CASE WHEN @bom=1 THEN NCHAR(65279) ELSE N'' END+@text;
    EXEC toolbelt_filesystem.USP_ReadTextFileChunk N'ContosoIo',@path,0,32,@encoding,@ResultTable=N'#Text';
    IF (SELECT COUNT(*) FROM #Text WHERE CONVERT(varbinary(max),Content)=CONVERT(varbinary(max),@decoded)
        AND BytesRead=DATALENGTH(@bytes) AND NextByteOffset=DATALENGTH(@bytes) AND EndOfFile=1)<>1
        THROW 52970,N'FILESYSTEM_CODEPAGE_DECODE',10;
    SET @checks+=1;
    FETCH NEXT FROM EncodingCases INTO @path,@encoding,@bytes,@bom;
END;
CLOSE EncodingCases;
DEALLOCATE EncodingCases;

EXEC toolbelt_filesystem.USP_WriteBinaryFile N'ContosoIo',N'invalid.bin',0xFFFFFFFFFFFFFFFF,@ResultTable=N'#Write';
BEGIN TRY
    EXEC toolbelt_filesystem.USP_ReadTextFileChunk N'ContosoIo',N'invalid.bin',0,8,N'utf-8',@ResultTable=N'#Text';
    THROW 52970,N'FILESYSTEM_INVALID_UTF8_ACCEPTED',11;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR ERROR_STATE()<>1 OR ERROR_MESSAGE() NOT LIKE N'%TextChunkEndsInsideCharacter%' THROW;
END CATCH;
SET @checks+=1;

EXEC toolbelt_filesystem.USP_TranscodeTextFile N'ContosoIo',N'cp1252.txt',N'windows-1252',
    N'ContosoIo',N'converted.txt',N'utf-16BE',1,@ResultTable=N'#Write';
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk N'ContosoIo',N'converted.txt',0,32,@ResultTable=N'#Binary';
IF (SELECT COUNT(*) FROM #Binary WHERE Content=0xFEFF004120AC AND BytesRead=6 AND EndOfFile=1)<>1
    THROW 52970,N'FILESYSTEM_TRANSCODE_BYTES',12;
SET @checks+=1;

EXEC toolbelt_filesystem.USP_WriteBinaryFile N'ContosoIo',N'target.bin',0x1122,@ResultTable=N'#Write';
BEGIN TRY
    EXEC toolbelt_filesystem.USP_WriteBinaryFile N'ContosoIo',N'target.bin',0x3344,0,@ResultTable=N'#Write';
    THROW 52970,N'FILESYSTEM_NO_OVERWRITE_ACCEPTED',13;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR ERROR_STATE()<>1 OR ERROR_MESSAGE() NOT LIKE N'%HandlePublishFailed%' THROW;
END CATCH;
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk N'ContosoIo',N'target.bin',0,32,@ResultTable=N'#Binary';
IF (SELECT COUNT(*) FROM #Binary WHERE Content=0x1122 AND BytesRead=2 AND EndOfFile=1)<>1
    THROW 52970,N'FILESYSTEM_NO_OVERWRITE_TARGET_CHANGED',14;
SET @checks+=1;

-- More than two writer buffers precede the nonrepresentable character.
DECLARE @late varbinary(max)=CONVERT(varbinary(max),REPLICATE(CONVERT(varchar(max),'a'),98304))+0xCEA9;
EXEC toolbelt_filesystem.USP_WriteBinaryFile N'ContosoIo',N'late.txt',@late,@ResultTable=N'#Write';
BEGIN TRY
    EXEC toolbelt_filesystem.USP_TranscodeTextFile N'ContosoIo',N'late.txt',N'utf-8',
        N'ContosoIo',N'target.bin',N'windows-1252',0,1,@ResultTable=N'#Write';
    THROW 52970,N'FILESYSTEM_LATE_ENCODING_ERROR_ACCEPTED',15;
END TRY BEGIN CATCH
    IF ERROR_NUMBER()<>51540 OR ERROR_STATE()<>1 OR ERROR_MESSAGE() NOT LIKE N'%EncoderFallbackException%' THROW;
END CATCH;
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk N'ContosoIo',N'target.bin',0,32,@ResultTable=N'#Binary';
IF (SELECT COUNT(*) FROM #Binary WHERE Content=0x1122 AND BytesRead=2 AND EndOfFile=1)<>1
    THROW 52970,N'FILESYSTEM_ABORT_TARGET_CHANGED',16;
SET @checks+=1;

CREATE TABLE #Stage(EntryOrdinal bigint NOT NULL, RelativePath nvarchar(4000) NOT NULL,
    EntryType varchar(16) NOT NULL, SizeBytes bigint NOT NULL, LastWriteTimeUtc datetime2(0) NOT NULL,
    IsReparsePoint bit NOT NULL);
EXEC toolbelt_filesystem.USP_ListDirectory N'ContosoIo',N'work',@MaxEntries=16,@ResultTable=N'#Stage';
IF EXISTS(SELECT 1 FROM #Stage) THROW 52970,N'FILESYSTEM_WORKPATH_NOT_EMPTY',17;
SET @checks+=1;

EXEC toolbelt_filesystem.USP_WriteBinaryFile N'ContosoIo',N'target.bin',0x556677,1,@ResultTable=N'#Write';
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk N'ContosoIo',N'target.bin',0,32,@ResultTable=N'#Binary';
IF (SELECT COUNT(*) FROM #Binary WHERE Content=0x556677 AND BytesRead=3 AND NextByteOffset=3 AND EndOfFile=1)<>1
    THROW 52970,N'FILESYSTEM_OVERWRITE_BYTES',18;
SET @checks+=1;
IF @checks<>22 THROW 52970,N'FILESYSTEM_ASSERTION_COUNT',19;
SELECT N'FILESYSTEM_CURRENT_IO_PASS' Result,@checks Assertions;
