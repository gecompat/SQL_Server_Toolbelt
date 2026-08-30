SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EnqueueWork]
(
      @WorkTypeName varchar(128)  = NULL
    , @PayloadJson  nvarchar(max) = NULL
    , @ResultTable  sysname       = NULL
    , @KeepData     bit           = 0
    , @Debug        tinyint       = 0
    , @Hilfe        bit           = 0
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
            , CAST(N'USP_EnqueueWork' AS sysname) AS ObjectName
            , v.Section, v.Ordinal, v.ItemName, v.SqlDataType
            , v.IsRequired, v.IsNullable, v.DefaultValue
            , v.Description, v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Reiht genau ein Work Item für einen registrierten, aktiven Work Type ein. Es wird niemals SQL-Text entgegengenommen oder ausgeführt.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@WorkTypeName', 'varchar(128)', 1, 0, NULL, N'Kanonischer Name eines aktiven Work Types.', NULL)
            , ('PARAMETER', 2, N'@PayloadJson', 'nvarchar(max)', 0, 1, NULL, N'Bei JSON_PAYLOAD ein JSON-Objekt mit höchstens 64 KiB; bei NONE ausschließlich NULL.', NULL)
            , ('PARAMETER', 3, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle für die Statuszeile.', NULL)
            , ('PARAMETER', 4, N'@KeepData', 'bit', 0, 0, N'0', N'Steuert die ResultTable-Vorbereitung.', NULL)
            , ('PARAMETER', 5, N'@Debug', 'tinyint', 0, 0, N'0', N'Erzeugt bei Werten größer 0 eine abstrakte Informationsmeldung.', NULL)
            , ('PARAMETER', 6, N'@Hilfe', 'bit', 0, 0, N'0', N'1 gibt ausschließlich dieses Help-Resultset aus.', NULL)
            , ('RESULT_COLUMN', 1, N'WorkItemId', 'bigint', 0, 0, NULL, N'Eindeutige Queue-ID.', NULL)
            , ('RESULT_COLUMN', 2, N'WorkTypeName', 'varchar(128)', 0, 0, NULL, N'Kanonischer Work-Type-Name.', NULL)
            , ('RESULT_COLUMN', 3, N'Status', 'varchar(16)', 0, 0, NULL, N'Nach Enqueue stets QUEUED.', NULL)
            , ('RESULT_COLUMN', 4, N'EnqueuedAtUtc', 'datetime2(7)', 0, 0, NULL, N'UTC-Zeitpunkt der Einreihung.', NULL)
            , ('RESULT_COLUMN', 5, N'EnqueuedBy', 'sysname', 0, 0, NULL, N'Original-Login der Einreihung.', NULL)
            , ('RESULT_COLUMN', 6, N'ClaimedAtUtc', 'datetime2(7)', 0, 1, NULL, N'UTC-Zeitpunkt des Claims; nach Enqueue NULL.', NULL)
            , ('RESULT_COLUMN', 7, N'ClaimedBy', 'sysname', 0, 1, NULL, N'Original-Login des Claimers; nach Enqueue NULL.', NULL)
            , ('RESULT_COLUMN', 8, N'CompletedAtUtc', 'datetime2(7)', 0, 1, NULL, N'UTC-Abschlusszeit; nach Enqueue NULL.', NULL)
            , ('RESULT_COLUMN', 9, N'CompletedBy', 'sysname', 0, 1, NULL, N'Original-Login des Abschlusses; nach Enqueue NULL.', NULL)
            , ('RESULT_COLUMN', 10, N'FailedAtUtc', 'datetime2(7)', 0, 1, NULL, N'UTC-Fehlerzeit; nach Enqueue NULL.', NULL)
            , ('RESULT_COLUMN', 11, N'FailedBy', 'sysname', 0, 1, NULL, N'Original-Login des Fail-Aufrufs; nach Enqueue NULL.', NULL)
            , ('RESULT_COLUMN', 12, N'FailureCode', 'varchar(64)', 0, 1, NULL, N'Stabiler Fehlercode; nach Enqueue NULL.', NULL)
            , ('RESULT_COLUMN', 13, N'FailureMessage', 'nvarchar(1000)', 0, 1, NULL, N'Optionale bereinigte Fehlermeldung; nach Enqueue NULL.', NULL)
            , ('RESULT_COLUMN', 14, N'RowVersion', 'binary(8)', 0, 0, NULL, N'Aktueller Concurrency-Marker.', NULL)
            , ('ERROR', 1, N'51900-51908', NULL, NULL, NULL, NULL, N'Work-Type-, Payload-, Transaktions- oder ResultTable-Fehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Reiht synthetische JSON-Arbeit ein.', N'EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName=''demo.json'', @PayloadJson=N''{"value":1}'';')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'RESULT_COLUMN' THEN 3 WHEN 'ERROR' THEN 4 ELSE 5 END, v.Ordinal;
        RETURN 0;
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51900, N'@WorkTypeName ist erforderlich.', 1;
    IF DATALENGTH(@PayloadJson) > 65536
        THROW 51905, N'@PayloadJson darf höchstens 64 KiB umfassen.', 1;
    IF XACT_STATE() = -1
        THROW 51906, N'Ein Work Item kann in einer uncommittable Caller-Transaktion nicht eingereiht werden.', 1;

    CREATE TABLE #tbx_WorkQueue_StatusShape
    (
          WorkItemId bigint NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , EnqueuedAtUtc datetime2(7) NOT NULL
        , EnqueuedBy sysname NOT NULL
        , ClaimedAtUtc datetime2(7) NULL
        , ClaimedBy sysname NULL
        , CompletedAtUtc datetime2(7) NULL
        , CompletedBy sysname NULL
        , FailedAtUtc datetime2(7) NULL
        , FailedBy sysname NULL
        , FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL
        , FailureMessage nvarchar(1000) NULL
        , RowVersion binary(8) NOT NULL
    );
    CREATE TABLE #tbx_WorkQueue_StatusResult
    (
          WorkItemId bigint NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , EnqueuedAtUtc datetime2(7) NOT NULL
        , EnqueuedBy sysname NOT NULL
        , ClaimedAtUtc datetime2(7) NULL
        , ClaimedBy sysname NULL
        , CompletedAtUtc datetime2(7) NULL
        , CompletedBy sysname NULL
        , FailedAtUtc datetime2(7) NULL
        , FailedBy sysname NULL
        , FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL
        , FailureMessage nvarchar(1000) NULL
        , RowVersion binary(8) NOT NULL
    );

    DECLARE @InitialTranCount int = @@TRANCOUNT;
    DECLARE @WorkTypeId bigint;
    DECLARE @ParameterMode varchar(16);
    DECLARE @IsEnabled bit;
    DECLARE @HandlerSchema sysname;
    DECLARE @HandlerProcedure sysname;
    DECLARE @WorkItemId bigint;

    IF @InitialTranCount = 0 BEGIN TRANSACTION;
    ELSE SAVE TRANSACTION TBX_WorkQueue_Enqueue;

    BEGIN TRY
        SELECT
              @WorkTypeId = wt.WorkTypeId
            , @ParameterMode = wt.ParameterMode
            , @IsEnabled = wt.IsEnabled
            , @HandlerSchema = wt.HandlerSchema
            , @HandlerProcedure = wt.HandlerProcedure
        FROM toolbelt_core.WorkType AS wt WITH (UPDLOCK, HOLDLOCK)
        WHERE wt.WorkTypeName = @WorkTypeName;

        IF @WorkTypeId IS NULL
            THROW 51900, N'Der angeforderte Work Type ist nicht registriert.', 1;
        IF @IsEnabled <> 1
            THROW 51901, N'Der angeforderte Work Type ist deaktiviert.', 1;
        IF COALESCE
           (
               OBJECT_ID(QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure), N'P'),
               OBJECT_ID(QUOTENAME(@HandlerSchema) + N'.' + QUOTENAME(@HandlerProcedure), N'PC')
           ) IS NULL
            THROW 51902, N'Der registrierte Work-Type-Handler ist nicht verfügbar.', 1;
        IF @ParameterMode = 'NONE' AND @PayloadJson IS NOT NULL
            THROW 51903, N'Für einen Work Type mit ParameterMode NONE muss @PayloadJson NULL sein.', 1;
        IF @ParameterMode = 'JSON_PAYLOAD'
           AND (@PayloadJson IS NULL OR ISJSON(@PayloadJson) <> 1 OR LEFT(LTRIM(@PayloadJson), 1) <> N'{')
            THROW 51904, N'Für JSON_PAYLOAD muss @PayloadJson ein JSON-Objekt sein.', 1;

        IF @ResultTable IS NOT NULL
        BEGIN
            IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
                THROW 51908, N'Für @ResultTable fehlt toolbelt.core.result-table.', 1;
            EXEC toolbelt_core.USP_PrepareResultTable
                  @ResultTableToAlter = @ResultTable
                , @LikeTable = N'#tbx_WorkQueue_StatusShape'
                , @KeepData = @KeepData;
        END;

        INSERT INTO toolbelt_core.WorkItem (WorkTypeId, PayloadJson)
        VALUES (@WorkTypeId, @PayloadJson);
        SET @WorkItemId = SCOPE_IDENTITY();

        INSERT INTO #tbx_WorkQueue_StatusResult
        SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId = @WorkItemId;

        IF @ResultTable IS NOT NULL
        BEGIN
            DECLARE @InsertSql nvarchar(max) =
                N'INSERT INTO ' + QUOTENAME(@ResultTable)
                + N' (WorkItemId, WorkTypeName, Status, EnqueuedAtUtc, EnqueuedBy, ClaimedAtUtc, ClaimedBy, CompletedAtUtc, CompletedBy, FailedAtUtc, FailedBy, FailureCode, FailureMessage, RowVersion)'
                + N' SELECT WorkItemId, WorkTypeName, Status, EnqueuedAtUtc, EnqueuedBy, ClaimedAtUtc, ClaimedBy, CompletedAtUtc, CompletedBy, FailedAtUtc, FailedBy, FailureCode, FailureMessage, RowVersion FROM #tbx_WorkQueue_StatusResult;';
            EXEC sys.sp_executesql @InsertSql;
        END;

        IF @InitialTranCount = 0 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @InitialTranCount = 0 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        ELSE IF @InitialTranCount > 0 AND XACT_STATE() = 1 ROLLBACK TRANSACTION TBX_WorkQueue_Enqueue;
        THROW;
    END CATCH;

    IF @Debug > 0
        RAISERROR(N'USP_EnqueueWork: ein Work Item wurde eingereiht.', 10, 1) WITH NOWAIT;
    IF @ResultTable IS NULL SELECT * FROM #tbx_WorkQueue_StatusResult;
    RETURN 0;
END;
GO
