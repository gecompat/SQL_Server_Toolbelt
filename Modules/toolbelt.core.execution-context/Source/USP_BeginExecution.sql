SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_BeginExecution]
(
      @ExecutionId   uniqueidentifier = NULL OUTPUT
    , @CorrelationId uniqueidentifier = NULL
    , @Actor         nvarchar(256)    = NULL
    , @Tenant        nvarchar(256)    = NULL
    , @AllowNested   bit              = 1
    , @Debug         tinyint          = 0
    , @Hilfe         bit              = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @AllowNested = ISNULL(@AllowNested, 1);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
               CAST(N'toolbelt_core' AS sysname) AS SchemaName,
               CAST(N'USP_BeginExecution' AS sysname) AS ObjectName,
               CAST('DESCRIPTION' AS varchar(32)) AS Section,
               1 AS Ordinal,
               CAST(NULL AS sysname) AS ItemName,
               CAST(NULL AS varchar(256)) AS SqlDataType,
               CAST(NULL AS bit) AS IsRequired,
               CAST(NULL AS bit) AS IsNullable,
               CAST(NULL AS nvarchar(4000)) AS DefaultValue,
               CAST(N'Beginnt einen sessiongebundenen Toolbelt Execution Context oder erhöht bei erlaubter Verschachtelung dessen ScopeDepth. Die Execution-ID wird als OUTPUT zurückgegeben.' AS nvarchar(max)) AS Description,
               CAST(N'DECLARE @Id uniqueidentifier; EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT;' AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
    END;

    DECLARE @CurrentExecutionId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));
    DECLARE @CurrentCorrelationId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.correlation_id'));
    DECLARE @CurrentDepth int = TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth'));
    DECLARE @CurrentActor nvarchar(256) = CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.actor'));
    DECLARE @CurrentTenant nvarchar(256) = CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.tenant'));

    IF @CurrentExecutionId IS NULL
    BEGIN
        SET @ExecutionId = ISNULL(@ExecutionId, NEWID());
        SET @CorrelationId = ISNULL(@CorrelationId, @ExecutionId);
        DECLARE @StartedAtUtc nvarchar(33) = CONVERT(nvarchar(33), SYSUTCDATETIME(), 126);
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id', @value=@ExecutionId;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id', @value=@CorrelationId;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=@Actor;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=@Tenant;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.started_at_utc', @value=@StartedAtUtc;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=1;
    END
    ELSE
    BEGIN
        IF @AllowNested = 0
            THROW 51420, N'In dieser Session ist bereits ein Execution Context aktiv.', 1;
        IF @CurrentDepth IS NULL OR @CurrentDepth < 1 OR @CurrentDepth >= 32767
            THROW 51421, N'Der vorhandene Execution Context besitzt einen ungültigen ScopeDepth.', 1;
        IF @ExecutionId IS NOT NULL AND @ExecutionId <> @CurrentExecutionId
            THROW 51422, N'Die angeforderte Execution-ID stimmt nicht mit dem aktiven Context überein.', 1;
        IF @CorrelationId IS NOT NULL AND @CorrelationId <> @CurrentCorrelationId
            THROW 51423, N'Die angeforderte Correlation-ID stimmt nicht mit dem aktiven Context überein.', 1;
        IF @Actor IS NOT NULL AND ISNULL(@CurrentActor, N'') <> @Actor
            THROW 51424, N'Ein verschachtelter Begin-Aufruf darf Actor nicht ändern.', 1;
        IF @Tenant IS NOT NULL AND ISNULL(@CurrentTenant, N'') <> @Tenant
            THROW 51425, N'Ein verschachtelter Begin-Aufruf darf Tenant nicht ändern.', 1;
        SET @ExecutionId = @CurrentExecutionId;
        DECLARE @NewDepth int = @CurrentDepth + 1;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=@NewDepth;
    END;

    IF @Debug > 0
        RAISERROR(N'USP_BeginExecution: Execution Context ist aktiv.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
