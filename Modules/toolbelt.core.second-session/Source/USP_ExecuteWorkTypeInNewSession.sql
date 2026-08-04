SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_ExecuteWorkTypeInNewSession]
(
      @WorkTypeName  varchar(128) = NULL
    , @PayloadJson   nvarchar(max) = NULL
    , @ExecutionId   uniqueidentifier = NULL
    , @CorrelationId uniqueidentifier = NULL
    , @Actor         nvarchar(256) = NULL
    , @Tenant        nvarchar(256) = NULL
    , @ResultTable   sysname = NULL
    , @KeepData      bit = 0
    , @Debug         tinyint = 0
    , @Hilfe         bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @KeepData = ISNULL(@KeepData, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_ExecuteWorkTypeInNewSession' AS sysname) AS ObjectName
            , v.Section
            , v.Ordinal
            , v.ItemName
            , v.SqlDataType
            , v.IsRequired
            , v.IsNullable
            , v.DefaultValue
            , v.Description
            , v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Führt einen registrierten Work Type synchron in einer getrennten SQL-Server-Session aus. Raw SQL ist ausgeschlossen; der Provider muss rpc out aktiv und Remote-Transaction-Promotion deaktiviert haben.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@WorkTypeName', 'varchar(128)', 1, 0, NULL, N'Kanonischer Name aus toolbelt.core.work-type.', NULL)
            , ('PARAMETER', 2, N'@PayloadJson', 'nvarchar(max)', 0, 1, NULL, N'JSON-Objekt nur für Work Types mit ParameterMode JSON_PAYLOAD.', NULL)
            , ('PARAMETER', 3, N'@ExecutionId', 'uniqueidentifier', 0, 1, NULL, N'Explizite Execution-ID; sonst aktiver Context oder neue ID.', NULL)
            , ('PARAMETER', 4, N'@CorrelationId', 'uniqueidentifier', 0, 1, NULL, N'Explizite Correlation-ID; sonst aktiver Context oder Execution-ID.', NULL)
            , ('PARAMETER', 5, N'@Actor', 'nvarchar(256)', 0, 1, NULL, N'Expliziter Actor; sonst aktiver Context oder ORIGINAL_LOGIN().', NULL)
            , ('PARAMETER', 6, N'@Tenant', 'nvarchar(256)', 0, 1, NULL, N'Optionaler Tenant-Kontext.', NULL)
            , ('PARAMETER', 7, N'@ResultTable', 'sysname', 0, 1, NULL, N'Optionale lokale Temp-Tabelle; in uncommittable Transaktionen nicht zulässig.', NULL)
            , ('ERROR', 1, N'51610-51619', NULL, NULL, NULL, NULL, N'Provider-, Work-Type-, Payload- und ResultTable-Fehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Führt einen NONE-Handler in einer neuen Session aus.', N'EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession @WorkTypeName=''demo.noop'';')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
    END;

    IF NULLIF(@WorkTypeName, '') IS NULL
        THROW 51610, N'@WorkTypeName ist erforderlich.', 1;
    IF @ResultTable IS NOT NULL AND XACT_STATE() = -1
        THROW 51611, N'@ResultTable ist in einer uncommittable Caller-Transaktion nicht zulässig.', 1;

    DECLARE
          @LinkedServerName sysname
        , @ProviderEnabled bit
        , @LinkedServerExists bit
        , @RpcOutEnabled bit
        , @PromotionEnabled bit;

    SELECT
          @LinkedServerName = p.LinkedServerName
        , @ProviderEnabled = p.IsEnabled
        , @LinkedServerExists = p.LinkedServerExists
        , @RpcOutEnabled = p.RpcOutEnabled
        , @PromotionEnabled = p.RemoteProcTransactionPromotionEnabled
    FROM toolbelt_core.VW_SecondSessionProviders AS p
    WHERE p.ProviderName = 'loopback';

    IF @LinkedServerName IS NULL
        THROW 51612, N'Es ist kein Loopback-Second-Session-Provider konfiguriert.', 1;
    IF @ProviderEnabled = 0
        THROW 51613, N'Der Loopback-Second-Session-Provider ist deaktiviert.', 1;
    IF @LinkedServerExists = 0 OR @RpcOutEnabled = 0 OR @PromotionEnabled = 1
        THROW 51614, N'Die aktuelle Linked-Server-Konfiguration verletzt den Second-Session-Vertrag.', 1;

    DECLARE @ParameterMode varchar(16);
    DECLARE @WorkTypeEnabled bit;
    SELECT
          @ParameterMode = wt.ParameterMode
        , @WorkTypeEnabled = wt.IsEnabled
    FROM toolbelt_core.WorkType AS wt
    WHERE wt.WorkTypeName = @WorkTypeName;

    IF @ParameterMode IS NULL
        THROW 51615, N'Der Work Type ist nicht registriert.', 1;
    IF @WorkTypeEnabled = 0
        THROW 51616, N'Der Work Type ist deaktiviert.', 1;
    IF @ParameterMode = 'NONE' AND @PayloadJson IS NOT NULL
        THROW 51617, N'Der Work Type akzeptiert keine JSON-Payload.', 1;
    IF @ParameterMode = 'JSON_PAYLOAD'
       AND
       (
           @PayloadJson IS NULL
           OR ISJSON(@PayloadJson) <> 1
           OR LEFT(LTRIM(@PayloadJson), 1) <> N'{'
       )
        THROW 51618, N'Der Work Type benötigt eine JSON-Objekt-Payload.', 1;

    DECLARE
          @CurrentExecutionId uniqueidentifier
        , @CurrentCorrelationId uniqueidentifier
        , @CurrentActor nvarchar(256)
        , @CurrentTenant nvarchar(256);

    SELECT
          @CurrentExecutionId = c.ExecutionId
        , @CurrentCorrelationId = c.CorrelationId
        , @CurrentActor = c.Actor
        , @CurrentTenant = c.Tenant
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;

    SET @ExecutionId = COALESCE(@ExecutionId, @CurrentExecutionId, NEWID());
    SET @CorrelationId = COALESCE(@CorrelationId, @CurrentCorrelationId, @ExecutionId);
    SET @Actor = COALESCE(@Actor, @CurrentActor, CONVERT(nvarchar(256), ORIGINAL_LOGIN()));
    SET @Tenant = COALESCE(@Tenant, @CurrentTenant);

    DECLARE @TargetDatabaseName sysname = DB_NAME();
    DECLARE @CallerSessionId int = @@SPID;
    DECLARE @CallerXactState smallint = CONVERT(smallint, XACT_STATE());
    DECLARE @CallerTransactionCount int = @@TRANCOUNT;
    DECLARE @RemoteSessionId int;
    DECLARE @HandlerReturnCode int;
    DECLARE @RemoteStartedAtUtc datetime2(7);
    DECLARE @RemoteCompletedAtUtc datetime2(7);
    DECLARE @ProviderReturnCode int;

    DECLARE @RpcSql nvarchar(max) =
        N'EXEC @ProviderReturnCode = '
        + QUOTENAME(@LinkedServerName) + N'.' + QUOTENAME(@TargetDatabaseName)
        + N'.[toolbelt_core].[USP_DispatchWorkType]'
        + N' @WorkTypeName=@WorkTypeName,'
        + N' @PayloadJson=@PayloadJson,'
        + N' @ExecutionId=@ExecutionId,'
        + N' @CorrelationId=@CorrelationId,'
        + N' @Actor=@Actor,'
        + N' @Tenant=@Tenant,'
        + N' @RemoteSessionId=@RemoteSessionId OUTPUT,'
        + N' @HandlerReturnCode=@HandlerReturnCode OUTPUT,'
        + N' @StartedAtUtc=@RemoteStartedAtUtc OUTPUT,'
        + N' @CompletedAtUtc=@RemoteCompletedAtUtc OUTPUT'
        + N' WITH RESULT SETS NONE;';

    EXEC sys.sp_executesql
          @RpcSql
        , N'@WorkTypeName varchar(128), @PayloadJson nvarchar(max), @ExecutionId uniqueidentifier, @CorrelationId uniqueidentifier, @Actor nvarchar(256), @Tenant nvarchar(256), @RemoteSessionId int OUTPUT, @HandlerReturnCode int OUTPUT, @RemoteStartedAtUtc datetime2(7) OUTPUT, @RemoteCompletedAtUtc datetime2(7) OUTPUT, @ProviderReturnCode int OUTPUT'
        , @WorkTypeName = @WorkTypeName
        , @PayloadJson = @PayloadJson
        , @ExecutionId = @ExecutionId
        , @CorrelationId = @CorrelationId
        , @Actor = @Actor
        , @Tenant = @Tenant
        , @RemoteSessionId = @RemoteSessionId OUTPUT
        , @HandlerReturnCode = @HandlerReturnCode OUTPUT
        , @RemoteStartedAtUtc = @RemoteStartedAtUtc OUTPUT
        , @RemoteCompletedAtUtc = @RemoteCompletedAtUtc OUTPUT
        , @ProviderReturnCode = @ProviderReturnCode OUTPUT;

    IF ISNULL(@ProviderReturnCode, -1) <> 0
        THROW 51619, N'Der Remote-Dispatcher lieferte keinen erfolgreichen Returncode.', 1;

    DECLARE @DurationMilliseconds decimal(19,3) =
        CONVERT(decimal(19,3), DATEDIFF_BIG(MICROSECOND, @RemoteStartedAtUtc, @RemoteCompletedAtUtc) / 1000.0);

    IF @ResultTable IS NULL
    BEGIN
        SELECT
              SYSUTCDATETIME() AS ExecutedAtUtc
            , CAST('loopback' AS varchar(32)) AS ProviderName
            , @LinkedServerName AS LinkedServerName
            , @TargetDatabaseName AS TargetDatabaseName
            , @WorkTypeName AS WorkTypeName
            , @ParameterMode AS ParameterMode
            , @CallerSessionId AS CallerSessionId
            , @RemoteSessionId AS RemoteSessionId
            , @CallerXactState AS CallerXactState
            , @CallerTransactionCount AS CallerTransactionCount
            , @ExecutionId AS ExecutionId
            , @CorrelationId AS CorrelationId
            , @HandlerReturnCode AS HandlerReturnCode
            , @RemoteStartedAtUtc AS RemoteStartedAtUtc
            , @RemoteCompletedAtUtc AS RemoteCompletedAtUtc
            , @DurationMilliseconds AS DurationMilliseconds;
        RETURN 0;
    END;

    CREATE TABLE #tbx_SecondSessionResultShape
    (
          ExecutedAtUtc datetime2(7) NOT NULL
        , ProviderName varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL
        , LinkedServerName sysname NOT NULL
        , TargetDatabaseName sysname NOT NULL
        , WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL
        , ParameterMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL
        , CallerSessionId int NOT NULL
        , RemoteSessionId int NOT NULL
        , CallerXactState smallint NOT NULL
        , CallerTransactionCount int NOT NULL
        , ExecutionId uniqueidentifier NOT NULL
        , CorrelationId uniqueidentifier NOT NULL
        , HandlerReturnCode int NULL
        , RemoteStartedAtUtc datetime2(7) NOT NULL
        , RemoteCompletedAtUtc datetime2(7) NOT NULL
        , DurationMilliseconds decimal(19,3) NOT NULL
    );

    IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
        THROW 51619, N'Für @ResultTable fehlt toolbelt.core.result-table.', 2;

    EXEC toolbelt_core.USP_PrepareResultTable
          @ResultTableToAlter = @ResultTable
        , @LikeTable = N'#tbx_SecondSessionResultShape'
        , @KeepData = @KeepData;

    DECLARE @InsertSql nvarchar(max) =
        N'INSERT INTO ' + QUOTENAME(@ResultTable)
        + N' (ExecutedAtUtc, ProviderName, LinkedServerName, TargetDatabaseName, WorkTypeName, ParameterMode, CallerSessionId, RemoteSessionId, CallerXactState, CallerTransactionCount, ExecutionId, CorrelationId, HandlerReturnCode, RemoteStartedAtUtc, RemoteCompletedAtUtc, DurationMilliseconds)'
        + N' VALUES (SYSUTCDATETIME(), ''loopback'', @LinkedServerName, @TargetDatabaseName, @WorkTypeName, @ParameterMode, @CallerSessionId, @RemoteSessionId, @CallerXactState, @CallerTransactionCount, @ExecutionId, @CorrelationId, @HandlerReturnCode, @RemoteStartedAtUtc, @RemoteCompletedAtUtc, @DurationMilliseconds);';

    EXEC sys.sp_executesql
          @InsertSql
        , N'@LinkedServerName sysname, @TargetDatabaseName sysname, @WorkTypeName varchar(128), @ParameterMode varchar(16), @CallerSessionId int, @RemoteSessionId int, @CallerXactState smallint, @CallerTransactionCount int, @ExecutionId uniqueidentifier, @CorrelationId uniqueidentifier, @HandlerReturnCode int, @RemoteStartedAtUtc datetime2(7), @RemoteCompletedAtUtc datetime2(7), @DurationMilliseconds decimal(19,3)'
        , @LinkedServerName = @LinkedServerName
        , @TargetDatabaseName = @TargetDatabaseName
        , @WorkTypeName = @WorkTypeName
        , @ParameterMode = @ParameterMode
        , @CallerSessionId = @CallerSessionId
        , @RemoteSessionId = @RemoteSessionId
        , @CallerXactState = @CallerXactState
        , @CallerTransactionCount = @CallerTransactionCount
        , @ExecutionId = @ExecutionId
        , @CorrelationId = @CorrelationId
        , @HandlerReturnCode = @HandlerReturnCode
        , @RemoteStartedAtUtc = @RemoteStartedAtUtc
        , @RemoteCompletedAtUtc = @RemoteCompletedAtUtc
        , @DurationMilliseconds = @DurationMilliseconds;

    IF @Debug > 0
        RAISERROR(N'USP_ExecuteWorkTypeInNewSession: Work Type wurde in einer zweiten Session ausgeführt.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
