SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ClaimWork]
(
      @ResultTable sysname  = NULL
    , @KeepData    bit      = 0
    , @Debug       tinyint  = 0
    , @Hilfe       bit      = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT OFF;

    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_ClaimWork' AS sysname) AS ObjectName
            , v.Section, v.Ordinal, v.ItemName, v.SqlDataType
            , v.IsRequired, v.IsNullable, v.DefaultValue
            , v.Description, v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Beansprucht atomar höchstens das älteste aktuell beanspruchbare Work Item. Ohne Kandidat wird eine leere Ergebnismenge geliefert.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle für die Claim-Zeile.', NULL)
            , ('PARAMETER', 2, N'@KeepData', 'bit', 0, 0, N'0', N'Steuert die ResultTable-Vorbereitung.', NULL)
            , ('PARAMETER', 3, N'@Debug', 'tinyint', 0, 0, N'0', N'Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung.', NULL)
            , ('PARAMETER', 4, N'@Hilfe', 'bit', 0, 0, N'0', N'1 gibt ausschließlich dieses Help-Resultset aus.', NULL)
            , ('RESULT_COLUMN', 1, N'WorkItemId', 'bigint', 0, 0, NULL, N'Eindeutige Queue-ID.', NULL)
            , ('RESULT_COLUMN', 2, N'WorkTypeName', 'varchar(128)', 0, 0, NULL, N'Name des aufzulösenden Work Types.', NULL)
            , ('RESULT_COLUMN', 3, N'PayloadJson', 'nvarchar(max)', 0, 1, NULL, N'Optionale bereinigte JSON-Payload.', NULL)
            , ('RESULT_COLUMN', 4, N'ClaimToken', 'uniqueidentifier', 0, 0, NULL, N'Capability-Token für Complete oder Fail; wird von Statusoberflächen nicht offengelegt.', NULL)
            , ('RESULT_COLUMN', 5, N'ClaimedAtUtc', 'datetime2(7)', 0, 0, NULL, N'UTC-Zeitpunkt des atomaren Claims.', NULL)
            , ('ERROR', 1, N'51910-51918', NULL, NULL, NULL, NULL, N'Transaktions- oder ResultTable-Fehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Beansprucht höchstens ein Item.', N'EXEC toolbelt_core.USP_ClaimWork;')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END, v.Ordinal;
        RETURN 0;
    END;

    IF @@TRANCOUNT <> 0 OR XACT_STATE() <> 0
        THROW 51910, N'USP_ClaimWork darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.', 1;

    CREATE TABLE #tbx_WorkQueue_ClaimShape
    (
          WorkItemId bigint NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , PayloadJson nvarchar(max) NULL
        , ClaimToken uniqueidentifier NOT NULL
        , ClaimedAtUtc datetime2(7) NOT NULL
    );
    CREATE TABLE #tbx_WorkQueue_ClaimResult
    (
          WorkItemId bigint NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , PayloadJson nvarchar(max) NULL
        , ClaimToken uniqueidentifier NOT NULL
        , ClaimedAtUtc datetime2(7) NOT NULL
    );
    DECLARE @Claimed TABLE (WorkItemId bigint NOT NULL PRIMARY KEY);
    DECLARE @ClaimedAtUtc datetime2(7) = SYSUTCDATETIME();
    DECLARE @ClaimToken uniqueidentifier = NEWID();
    DECLARE @ClaimedBy sysname = ORIGINAL_LOGIN();

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
                THROW 51918, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;
            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = @ResultTable
                , @LikeTable = N'#tbx_WorkQueue_ClaimShape'
                , @KeepData = @KeepData;
        END;

        ;WITH Candidate AS
        (
            SELECT TOP (1) wi.*
            FROM toolbelt_core.WorkItem AS wi WITH
                 (UPDLOCK, READPAST, READCOMMITTEDLOCK, ROWLOCK, INDEX(IX_WorkItem_Status_WorkItemId))
            JOIN toolbelt_core.WorkType AS wt
              ON wt.WorkTypeId = wi.WorkTypeId
             AND wt.IsEnabled = 1
            JOIN sys.schemas AS hs
              ON hs.name = wt.HandlerSchema
            JOIN sys.procedures AS hp
              ON hp.schema_id = hs.schema_id
             AND hp.name = wt.HandlerProcedure
             AND hp.is_ms_shipped = 0
            WHERE wi.Status = 'QUEUED'
            ORDER BY wi.WorkItemId
        )
        UPDATE Candidate
        SET
              Status = 'CLAIMED'
            , ClaimedAtUtc = @ClaimedAtUtc
            , ClaimedBy = @ClaimedBy
            , ClaimToken = @ClaimToken
        OUTPUT inserted.WorkItemId INTO @Claimed (WorkItemId);

        INSERT INTO #tbx_WorkQueue_ClaimResult
            (WorkItemId, WorkTypeName, PayloadJson, ClaimToken, ClaimedAtUtc)
        SELECT
              wi.WorkItemId, wt.WorkTypeName, wi.PayloadJson
            , wi.ClaimToken, wi.ClaimedAtUtc
        FROM @Claimed AS claimed
        JOIN toolbelt_core.WorkItem AS wi
          ON wi.WorkItemId = claimed.WorkItemId
        JOIN toolbelt_core.WorkType AS wt
          ON wt.WorkTypeId = wi.WorkTypeId;

        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max) =
                N'INSERT INTO ' + QUOTENAME(@ResultTable)
                + N' (WorkItemId, WorkTypeName, PayloadJson, ClaimToken, ClaimedAtUtc)'
                + N' SELECT WorkItemId, WorkTypeName, PayloadJson, ClaimToken, ClaimedAtUtc FROM #tbx_WorkQueue_ClaimResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;

    IF @Debug > 0
        RAISERROR(N'USP_ClaimWork: atomarer Claim abgeschlossen.', 10, 1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_ClaimResult;
    RETURN 0;
END;
GO
