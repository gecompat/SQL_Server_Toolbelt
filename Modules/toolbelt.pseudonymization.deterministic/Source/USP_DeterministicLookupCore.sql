-- Interner Ausgabekern hinter der öffentlichen Compilergrenze.
-- Parameter/Caller-Shapes/alle privaten Tempnamen validiert ausschließlich
-- die Fassade vor diesem Aufruf. Keine direkten Caller-Grants auf den Core.
-- Kanonisches Mapping, Materialisierung, Transaktion und ResultTable-Routing
-- existieren genau einmal hier; Hilfe wird an die öffentliche Fassade geroutet.
CREATE OR ALTER PROCEDURE [toolbelt_pseudonymization].[USP_DeterministicLookupCore]
(
      @InputTable sysname = NULL
    , @LookupTable sysname = NULL
    , @MappingVersion int = NULL
    , @Seed bigint = 0
    , @LookupVersion bigint = NULL
    , @MaxInputRows int = 10000
    , @MaxLookupRows int = 10000
    , @MaxLookupTextBytes bigint = 2097152
    , @MaxResultBytes bigint = 16777216
    , @InputObjectId int = NULL
    , @LookupObjectId int = NULL
    , @ResultTable sysname = NULL
    , @KeepData bit = 0
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT @KeepData=COALESCE(@KeepData,0),@Debug=COALESCE(@Debug,0),@Hilfe=COALESCE(@Hilfe,0);
    IF @Hilfe=1
    BEGIN
        EXEC toolbelt_pseudonymization.USP_DeterministicLookup @Hilfe=1;
        RETURN 0;
    END;
    DECLARE @OwnTransaction bit = CASE WHEN @@TRANCOUNT = 0 THEN 1 ELSE 0 END,
        @SavepointSet bit = 0, @Savepoint varchar(32) = REPLACE(CONVERT(varchar(36),NEWID()),'-',''),
        @Sql nvarchar(max), @InputCount bigint, @PoolCount bigint, @PoolBytes bigint,
        @BadOrdinal bit, @BadKey bit, @DuplicateOrdinal bit;
    BEGIN TRY
        IF @OwnTransaction = 1 BEGIN TRANSACTION;
        ELSE BEGIN SAVE TRANSACTION @Savepoint; SET @SavepointSet = 1; END;
        -- Begrenzter Metadaten-Preflight vor jeder privaten Key/Value-LOB-Kopie.
        -- S/HOLDLOCK-Snapshot: reguläre Locks bleiben in Callertransaktionen bestehen.
        SET @Sql = N'SELECT @Count=COUNT_BIG(*),@BadOrdinal=COALESCE(MAX(CONVERT(tinyint,CASE WHEN Ordinal IS NULL OR Ordinal<=0 THEN 1 ELSE 0 END)),0),'
            + N'@BadKey=COALESCE(MAX(CONVERT(tinyint,CASE WHEN [Key] IS NOT NULL AND (DATALENGTH([Key])=0 OR DATALENGTH([Key])>8000) THEN 1 ELSE 0 END)),0) '
            + N'FROM (SELECT TOP (@Limit) Ordinal,[Key] FROM ' + QUOTENAME(@InputTable) + N' WITH(TABLOCK,HOLDLOCK)) AS bounded;';
        DECLARE @InputLimit int = @MaxInputRows + 1, @PoolLimit int = @MaxLookupRows + 1;
        EXEC sys.sp_executesql @Sql,N'@Limit int,@Count bigint OUTPUT,@BadOrdinal bit OUTPUT,@BadKey bit OUTPUT',
            @InputLimit,@InputCount OUTPUT,@BadOrdinal OUTPUT,@BadKey OUTPUT;
        IF @InputCount > @MaxInputRows THROW 54001, N'DeterministicLookup: Eingabezeilenlimit überschritten.', 2;
        SET @Sql = N'SELECT @Duplicate=CASE WHEN EXISTS(SELECT Ordinal FROM ' + QUOTENAME(@InputTable)
            + N' WITH(TABLOCK,HOLDLOCK) GROUP BY Ordinal HAVING COUNT_BIG(*)>1) THEN 1 ELSE 0 END;';
        EXEC sys.sp_executesql @Sql,N'@Duplicate bit OUTPUT',@DuplicateOrdinal OUTPUT;
        IF @BadOrdinal = 1 OR @DuplicateOrdinal = 1 THROW 54003, N'DeterministicLookup: Eingabeordinals müssen positiv/eindeutig sein.', 1;
        IF @BadKey = 1 THROW 54004, N'DeterministicLookup: Nicht-NULL Keys müssen 1..8000 Byte enthalten.', 1;
        SET @Sql = N'SELECT @Count=COUNT_BIG(*),@Bytes=COALESCE(SUM(CONVERT(bigint,DATALENGTH([Value]))),0),'
            + N'@BadOrdinal=COALESCE(MAX(CONVERT(tinyint,CASE WHEN Ordinal IS NULL OR Ordinal<=0 THEN 1 ELSE 0 END)),0) '
            + N'FROM (SELECT TOP (@Limit) Ordinal,[Value] FROM ' + QUOTENAME(@LookupTable) + N' WITH(TABLOCK,HOLDLOCK)) AS bounded;';
        EXEC sys.sp_executesql @Sql,N'@Limit int,@Count bigint OUTPUT,@Bytes bigint OUTPUT,@BadOrdinal bit OUTPUT',
            @PoolLimit,@PoolCount OUTPUT,@PoolBytes OUTPUT,@BadOrdinal OUTPUT;
        IF @PoolCount > @MaxLookupRows THROW 54001, N'DeterministicLookup: Poolzeilenlimit überschritten.', 3;
        SET @Sql = N'SELECT @Duplicate=CASE WHEN EXISTS(SELECT Ordinal FROM ' + QUOTENAME(@LookupTable)
            + N' WITH(TABLOCK,HOLDLOCK) GROUP BY Ordinal HAVING COUNT_BIG(*)>1) THEN 1 ELSE 0 END;';
        EXEC sys.sp_executesql @Sql,N'@Duplicate bit OUTPUT',@DuplicateOrdinal OUTPUT;
        IF @BadOrdinal = 1 OR @DuplicateOrdinal = 1 THROW 54003, N'DeterministicLookup: Poolordinals müssen positiv/eindeutig sein.', 2;
        IF @PoolCount = 0 THROW 54005, N'DeterministicLookup: leerer Pool ist ungültig.', 1;
        IF @PoolBytes > @MaxLookupTextBytes THROW 54006, N'DeterministicLookup: Pooltextbudget überschritten.', 1;
        IF @Debug >= 2
            RAISERROR(N'DeterministicLookup: InputRows=%I64d, PoolRows=%I64d, PoolTextBytes=%I64d.',10,1,@InputCount,@PoolCount,@PoolBytes) WITH NOWAIT;
        IF @Debug >= 3
            RAISERROR(N'DeterministicLookup: InputObjectId=%d, PoolObjectId=%d; private Mapping-/Resultshape getrennt; keine Key-/Value-Diagnose.',10,1,@InputObjectId,@LookupObjectId) WITH NOWAIT;

        CREATE TABLE #tbx_DeterministicLookup_Pool
        (PoolPosition bigint NOT NULL PRIMARY KEY, LookupOrdinal bigint NOT NULL, [Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
        SET @Sql = N'INSERT #tbx_DeterministicLookup_Pool(PoolPosition,LookupOrdinal,[Value]) '
            + N'SELECT ROW_NUMBER() OVER(ORDER BY Ordinal),Ordinal,[Value] FROM ' + QUOTENAME(@LookupTable) + N' WITH(TABLOCK,HOLDLOCK);';
        EXEC sys.sp_executesql @Sql;
        -- Dynamisches SQL liest ausschließlich Caller-Temps. Den Range-Kern
        -- statisch aufrufen, damit die reguläre gleichbesitzige Ownershipchain
        -- ohne zusätzliche SELECT-Rechte auf internen Objekten gilt. Die
        -- begrenzte Keykopie ist bewusst: höchstens MaxInputRows * 8000 Byte
        -- Nutzdaten, kein behauptetes Peak-RAM-Limit. Nach Mapping sofort lösen.
        CREATE TABLE #tbx_DeterministicLookup_Input
        (InputOrdinal bigint NOT NULL, [Key] varbinary(8000) NULL);
        SET @Sql = N'INSERT #tbx_DeterministicLookup_Input(InputOrdinal,[Key]) SELECT Ordinal,[Key] FROM '
            + QUOTENAME(@InputTable) + N' WITH(TABLOCK,HOLDLOCK);';
        EXEC sys.sp_executesql @Sql;
        CREATE TABLE #tbx_DeterministicLookup_Map
        (InputOrdinal bigint NOT NULL, LookupOrdinal bigint NULL, ErrorCode int NOT NULL);
        INSERT #tbx_DeterministicLookup_Map(InputOrdinal,LookupOrdinal,ErrorCode)
        SELECT input.InputOrdinal,pool.LookupOrdinal,mapped.ErrorCode
        FROM #tbx_DeterministicLookup_Input AS input
        CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicRangeCore
            (0x544258444C4B5031,@LookupVersion,input.[Key],@MappingVersion,@Seed,CONVERT(bigint,1),@PoolCount) AS mapped
        LEFT JOIN #tbx_DeterministicLookup_Pool AS pool ON pool.PoolPosition=mapped.Value;
        DROP TABLE #tbx_DeterministicLookup_Input;
        IF EXISTS (SELECT 1 FROM #tbx_DeterministicLookup_Map WHERE ErrorCode <> 0)
            THROW 54007, N'DeterministicLookup: Range-Sampling hat keinen vollständigen gültigen Mapping-Snapshot geliefert.', 1;
        DECLARE @ResultBytes bigint;
        SELECT @ResultBytes = COALESCE(SUM(CONVERT(bigint,DATALENGTH(pool.[Value]))),0)
        FROM #tbx_DeterministicLookup_Map AS mapped LEFT JOIN #tbx_DeterministicLookup_Pool AS pool ON pool.LookupOrdinal = mapped.LookupOrdinal;
        IF @ResultBytes > @MaxResultBytes THROW 54006, N'DeterministicLookup: Ergebnistextbudget überschritten.', 2;
        CREATE TABLE #tbx_DeterministicLookup_ResultSource
        (InputOrdinal bigint NOT NULL, LookupOrdinal bigint NULL, [Value] nvarchar(max) COLLATE Latin1_General_100_BIN2 NULL);
        INSERT #tbx_DeterministicLookup_ResultSource(InputOrdinal,LookupOrdinal,[Value])
        SELECT mapped.InputOrdinal,mapped.LookupOrdinal,pool.[Value]
        FROM #tbx_DeterministicLookup_Map AS mapped LEFT JOIN #tbx_DeterministicLookup_Pool AS pool ON pool.LookupOrdinal = mapped.LookupOrdinal;
        IF @Debug > 0 RAISERROR(N'DeterministicLookup: vollständig validierter Mapping-Snapshot bereit.',10,1) WITH NOWAIT;

        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @DependencyId int = OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'), @DependencyVersion nvarchar(64);
            SELECT @DependencyVersion = TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
            WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.core.result-table.Version';
            DECLARE @Major int = TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)), @Minor int = TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)), @Patch int = TRY_CONVERT(int,PARSENAME(@DependencyVersion,1));
            IF @DependencyId IS NULL OR @Major IS NULL OR @Major < 1 OR @Minor IS NULL OR @Minor < 0 OR @Patch IS NULL OR @Patch < 0
                OR CONVERT(varbinary(max),@DependencyVersion) <> CONVERT(varbinary(max),CONCAT(@Major,N'.',@Minor,N'.',@Patch))
                OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ModuleId'
                    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'toolbelt.core.result-table'))
                OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
                    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),@DependencyVersion))
                OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyId AND minor_id=0 AND name=N'Toolbelt.ContractVersion'
                    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),N'1.0'))
                THROW 54008, N'DeterministicLookup: registrierte same-database ResultTable-Dependency >=1.0.0 fehlt oder ist ungeeignet.', 1;
            EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_DeterministicLookup_ResultSource',@KeepData=@KeepData,@Debug=@Debug;
            SET @Sql = N'INSERT ' + QUOTENAME(@ResultTable) + N' (InputOrdinal,LookupOrdinal,[Value]) SELECT InputOrdinal,LookupOrdinal,[Value] FROM #tbx_DeterministicLookup_ResultSource;';
            EXEC sys.sp_executesql @Sql;
        END;
        IF @OwnTransaction = 1 COMMIT TRANSACTION;
        -- Keine Zeilen vor eigenem Commit oder vollständig vorbereiteter Callerarbeit.
        IF @ResultTable IS NULL
            SELECT InputOrdinal,LookupOrdinal,[Value] FROM #tbx_DeterministicLookup_ResultSource ORDER BY InputOrdinal;
    END TRY
    BEGIN CATCH
        IF @OwnTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @SavepointSet = 1 AND XACT_STATE() = 1 ROLLBACK TRANSACTION @Savepoint;
        THROW;
    END CATCH;
    RETURN 0;
END;
GO
