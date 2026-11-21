-- Needs a new, empty owned Windows root named ContosoZipMatrix and Windows authentication.
SET NOCOUNT ON;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID())<>@ExpectedCl
    THROW 54690,N'ZIP_MATRIX_COMPATIBILITY_LEVEL',1;
CREATE TABLE #Entries(Ordinal int, EntryName nvarchar(max), Payload varbinary(max));
INSERT #Entries VALUES(1,N'archive-entry.bin',0x010203);
EXEC toolbelt_archive.USP_CreateZipFileFromEntries
    @EntryTable=N'#Entries', @RootAlias=N'ContosoZipMatrix', @RelativePath=N'direct.zip';

CREATE TABLE #Read(Dummy int);
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipMatrix', @RelativePath=N'direct.zip', @ResultTable=N'#Read';
DECLARE @Zip varbinary(max)=(SELECT Content FROM #Read);
IF @Zip IS NULL OR (SELECT COUNT(*) FROM #Read WHERE EndOfFile=1 AND BytesRead=DATALENGTH(@Zip))<>1
    THROW 54690,N'ZIP_MATRIX_WRITER_BYTES',1;

EXEC toolbelt_archive.USP_ExtractZipEntryToFile
    @ZipArchive=@Zip, @EntryName=N'archive-entry.bin', @RootAlias=N'ContosoZipMatrix',
    @RelativePath=N'direct.bin';
EXEC toolbelt_filesystem.USP_ReadBinaryFileChunk
    @RootAlias=N'ContosoZipMatrix', @RelativePath=N'direct.bin', @ResultTable=N'#Read';
IF (SELECT COUNT(*) FROM #Read WHERE Content=0x010203 AND EndOfFile=1 AND BytesRead=3)<>1
    THROW 54690,N'ZIP_MATRIX_READER_BYTES',1;

DECLARE @Modes table (Id int PRIMARY KEY, KeepData bit, ShapeMatches bit, HasPriorRows bit);
INSERT @Modes VALUES(1,0,1,1),(2,0,0,1),(3,1,1,1),(4,1,0,0),(5,1,0,1),(6,1,1,0);
DECLARE @Facade int=1, @Case int, @KeepData bit, @ShapeMatches bit, @HasPriorRows bit,
    @Path nvarchar(4000), @Rejected bit, @Rows int, @OutputRows int, @PriorRows int, @Checks int=2;
WHILE @Facade<=2
BEGIN
    SET @Case=1;
    WHILE @Case<=6
    BEGIN
        SELECT @KeepData=KeepData,@ShapeMatches=ShapeMatches,@HasPriorRows=HasPriorRows
            FROM @Modes WHERE Id=@Case;
        SET @Path=CONCAT(CASE WHEN @Facade=1 THEN N'writer' ELSE N'entry' END,@Case,
            CASE WHEN @Facade=1 THEN N'.zip' ELSE N'.bin' END);
        CREATE TABLE #Output(Dummy int NULL);
        IF @ShapeMatches=1
        BEGIN
            ALTER TABLE #Output ADD BytesWritten bigint NOT NULL,RootAlias nvarchar(128) NOT NULL,
                RelativePath nvarchar(4000) NOT NULL,State varchar(16) NOT NULL;
            ALTER TABLE #Output DROP COLUMN Dummy;
            IF @HasPriorRows=1
                EXEC sys.sp_executesql N'INSERT #Output VALUES(7,N''ContosoZipMatrix'',N''prior'',''completed'');';
        END
        ELSE IF @HasPriorRows=1
            INSERT #Output VALUES(42);
        SET @Rejected=0;
        BEGIN TRY
            IF @Facade=1
                EXEC toolbelt_archive.USP_CreateZipFileFromEntries
                    @EntryTable=N'#Entries',@RootAlias=N'ContosoZipMatrix',@RelativePath=@Path,
                    @ResultTable=N'#Output',@KeepData=@KeepData;
            ELSE
                EXEC toolbelt_archive.USP_ExtractZipEntryToFile
                    @ZipArchive=@Zip,@EntryName=N'archive-entry.bin',@RootAlias=N'ContosoZipMatrix',
                    @RelativePath=@Path,@ResultTable=N'#Output',@KeepData=@KeepData;
        END TRY
        BEGIN CATCH
            IF @Case<>5 OR ERROR_NUMBER()<>51025 THROW;
            SET @Rejected=1;
        END CATCH;

        IF @Case=5
        BEGIN
            EXEC sys.sp_executesql N'SELECT @Rows=COUNT(*) FROM #Output WHERE Dummy=42;',N'@Rows int OUTPUT',@Rows OUTPUT;
            IF @Rejected<>1 OR @@TRANCOUNT<>0 OR XACT_STATE()<>0
                OR @Rows<>1
                THROW 54690,N'ZIP_MATRIX_KEEP_INCOMPATIBLE_PRESERVATION',1;
        END
        ELSE
        BEGIN
            EXEC sys.sp_executesql
                N'SELECT @Rows=COUNT(*),
                  @OutputRows=COUNT(CASE WHEN RelativePath=@Path AND RootAlias=N''ContosoZipMatrix''
                   AND State=''completed'' AND ((@Facade=1 AND BytesWritten>22) OR (@Facade=2 AND BytesWritten=3))
                  THEN 1 END), @PriorRows=COUNT(CASE WHEN RelativePath=N''prior'' AND BytesWritten=7 THEN 1 END)
                  FROM #Output;',
                N'@Path nvarchar(4000),@Facade int,@Rows int OUTPUT,@OutputRows int OUTPUT,@PriorRows int OUTPUT',
                @Path,@Facade,@Rows OUTPUT,@OutputRows OUTPUT,@PriorRows OUTPUT;
            IF @OutputRows<>1 OR @PriorRows<>CASE WHEN @Case=3 THEN 1 ELSE 0 END OR @Rows<>@OutputRows+@PriorRows
                THROW 54690,N'ZIP_MATRIX_KEEPDATA_RESULT',1;
        END;
        DROP TABLE #Output;
        SET @Checks+=1;
        SET @Case+=1;
    END;
    SET @Facade+=1;
END;

IF @RunDirectory=1
BEGIN
    CREATE TABLE #DirectoryRows
    (
        Ordinal bigint NOT NULL, EntryName nvarchar(max) NOT NULL, EntryKind varchar(9) NOT NULL,
        Status varchar(16) NOT NULL, BytesWritten bigint NULL, ErrorCode varchar(64) NULL
    );
    EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
        @ZipArchive=@Zip,@RootAlias=N'ContosoZipMatrix',@ResultTable=N'#DirectoryRows';
    IF (SELECT COUNT(*) FROM #DirectoryRows)<>1 OR NOT EXISTS
    (
        SELECT 1 FROM #DirectoryRows WHERE Ordinal=1 AND EntryName=N'archive-entry.bin'
          AND Status='completed' AND EntryKind='file' AND BytesWritten=3 AND ErrorCode IS NULL
    )
        THROW 54690,N'ZIP_MATRIX_DIRECTORY_OUTPUT',1;
    SET @Checks+=1;
END;
SELECT N'ZIP_WINDOWS_MATRIX_SQL_PASS' AS Outcome,@Checks AS Checks;
