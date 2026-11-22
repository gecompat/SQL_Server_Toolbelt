-- This call exercises the V1 direct SELECT path with a two-entry Stored ZIP.
-- The caller checks the six returned columns and both rows.
SET NOCOUNT ON;
EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
    @ZipArchive=@Zip,@RootAlias=N'ContosoZipDirect',@ResultTable=NULL,@Debug=1;

-- A separate pair of result rows is expected from each subsequent call.
-- The owned root allows overwrite, so the four output cases reuse both files.
DECLARE @Cases table (Id int PRIMARY KEY, KeepData bit, ShapeMatches bit);
INSERT @Cases VALUES(1,0,1),(2,0,0),(3,1,1),(4,1,0);
DECLARE @Case int=1,@KeepData bit,@Matches bit,@Rows int,@NewRows int,@PriorRows int,@Blocked bit;
WHILE @Case<=4
BEGIN
    SELECT @KeepData=KeepData,@Matches=ShapeMatches FROM @Cases WHERE Id=@Case;
    CREATE TABLE #Output(Dummy int NOT NULL);
    IF @Matches=1
    BEGIN
        ALTER TABLE #Output ADD Ordinal bigint NOT NULL,EntryName nvarchar(max) NOT NULL,EntryKind varchar(9) NOT NULL,
            Status varchar(16) NOT NULL,BytesWritten bigint NULL,ErrorCode varchar(64) NULL;
        ALTER TABLE #Output DROP COLUMN Dummy;
        EXEC sys.sp_executesql N'CREATE INDEX IX_ZipDirectory ON #Output(Ordinal);
            INSERT #Output VALUES(7,N''prior'', ''file'', ''completed'',0,NULL);';
    END
    ELSE
        INSERT #Output VALUES(42);
    SET @Blocked=0;
    BEGIN TRY
        EXEC toolbelt_archive.USP_ExtractZipArchiveToDirectory
            @ZipArchive=@Zip,@RootAlias=N'ContosoZipDirect',@OverwriteExistingFiles=1,
            @ResultTable=N'#Output',@KeepData=@KeepData;
    END TRY
    BEGIN CATCH
        IF @Case<>4 OR ERROR_NUMBER()<>51025 THROW;
        SET @Blocked=1;
    END CATCH;

    IF @Case=4
    BEGIN
        EXEC sys.sp_executesql N'SELECT @Rows=COUNT(*) FROM #Output WHERE Dummy=42;',
            N'@Rows int OUTPUT',@Rows OUTPUT;
        IF @Blocked<>1 OR @Rows<>1 THROW 54721,N'ZIP_DIRECT_INCOMPATIBLE_KEEPDATA',1;
    END
    ELSE
    BEGIN
        EXEC sys.sp_executesql
            N'SELECT @Rows=COUNT(*), @NewRows=COUNT(CASE WHEN Ordinal IN(1,2) AND Status=''completed''
                AND ErrorCode IS NULL THEN 1 END), @PriorRows=COUNT(CASE WHEN Ordinal=7 AND EntryName=N''prior'' THEN 1 END)
                FROM #Output;',
            N'@Rows int OUTPUT,@NewRows int OUTPUT,@PriorRows int OUTPUT',
            @Rows OUTPUT,@NewRows OUTPUT,@PriorRows OUTPUT;
        IF @NewRows<>2 OR @Rows<>@NewRows+@PriorRows OR @PriorRows<>CASE WHEN @Case=3 THEN 1 ELSE 0 END
            THROW 54722,N'ZIP_DIRECT_KEEPDATA_RESULT',1;
        IF @Matches=1 AND NOT EXISTS
        (
            SELECT 1 FROM tempdb.sys.indexes WHERE object_id=OBJECT_ID('tempdb..#Output') AND name=N'IX_ZipDirectory'
        )
            THROW 54723,N'ZIP_DIRECT_INDEX_LOST',1;
    END;
    DROP TABLE #Output;
    SET @Case+=1;
END;
SELECT N'ZIP_DIRECT_KEEPDATA_PASS' AS Outcome,4 AS Checks;
