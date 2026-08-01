SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_SetExecutionContext]
(
      @ExpectedExecutionId uniqueidentifier
    , @CorrelationId       uniqueidentifier = NULL
    , @Actor               nvarchar(256)    = NULL
    , @Tenant              nvarchar(256)    = NULL
    , @ClearActor          bit              = 0
    , @ClearTenant         bit              = 0
    , @Debug               tinyint          = 0
    , @Hilfe               bit              = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @ClearActor = ISNULL(@ClearActor, 0);
    SET @ClearTenant = ISNULL(@ClearTenant, 0);
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
               CAST(N'toolbelt_core' AS sysname) AS SchemaName,
               CAST(N'USP_SetExecutionContext' AS sysname) AS ObjectName,
               CAST('DESCRIPTION' AS varchar(32)) AS Section,
               1 AS Ordinal,
               CAST(NULL AS sysname) AS ItemName,
               CAST(NULL AS varchar(256)) AS SqlDataType,
               CAST(NULL AS bit) AS IsRequired,
               CAST(NULL AS bit) AS IsNullable,
               CAST(NULL AS nvarchar(4000)) AS DefaultValue,
               CAST(N'Ändert Correlation-ID, Actor oder Tenant eines aktiven Contexts. Die erwartete Execution-ID verhindert Änderungen an einem fremden oder veralteten Sessionzustand.' AS nvarchar(max)) AS Description,
               CAST(NULL AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
    END;

    DECLARE @CurrentExecutionId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));
    IF @CurrentExecutionId IS NULL
        THROW 51426, N'In dieser Session ist kein Execution Context aktiv.', 1;
    IF @ExpectedExecutionId IS NULL OR @ExpectedExecutionId <> @CurrentExecutionId
        THROW 51427, N'@ExpectedExecutionId stimmt nicht mit dem aktiven Context überein.', 1;
    IF @ClearActor = 1 AND @Actor IS NOT NULL
        THROW 51428, N'@Actor und @ClearActor dürfen nicht gleichzeitig gesetzt sein.', 1;
    IF @ClearTenant = 1 AND @Tenant IS NOT NULL
        THROW 51429, N'@Tenant und @ClearTenant dürfen nicht gleichzeitig gesetzt sein.', 1;

    IF @CorrelationId IS NOT NULL
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id', @value=@CorrelationId;
    IF @ClearActor = 1
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=NULL;
    ELSE IF @Actor IS NOT NULL
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=@Actor;
    IF @ClearTenant = 1
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=NULL;
    ELSE IF @Tenant IS NOT NULL
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=@Tenant;

    IF @Debug > 0
        RAISERROR(N'USP_SetExecutionContext: Execution Context wurde aktualisiert.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
