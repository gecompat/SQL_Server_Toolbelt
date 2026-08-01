SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_EndExecution]
(
      @ExpectedExecutionId uniqueidentifier
    , @Debug               tinyint = 0
    , @Hilfe               bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT CAST('1.0' AS varchar(16)) AS HelpContractVersion,
               CAST(N'toolbelt_core' AS sysname) AS SchemaName,
               CAST(N'USP_EndExecution' AS sysname) AS ObjectName,
               CAST('DESCRIPTION' AS varchar(32)) AS Section,
               1 AS Ordinal,
               CAST(NULL AS sysname) AS ItemName,
               CAST(NULL AS varchar(256)) AS SqlDataType,
               CAST(NULL AS bit) AS IsRequired,
               CAST(NULL AS bit) AS IsNullable,
               CAST(NULL AS nvarchar(4000)) AS DefaultValue,
               CAST(N'Verringert den ScopeDepth eines aktiven Contexts und löscht bei Tiefe 1 alle Toolbelt-Sessionwerte.' AS nvarchar(max)) AS Description,
               CAST(NULL AS nvarchar(max)) AS ExampleSql;
        RETURN 0;
    END;

    DECLARE @CurrentExecutionId uniqueidentifier = TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id'));
    DECLARE @CurrentDepth int = TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth'));
    IF @CurrentExecutionId IS NULL
        THROW 51430, N'In dieser Session ist kein Execution Context aktiv.', 1;
    IF @ExpectedExecutionId IS NULL OR @ExpectedExecutionId <> @CurrentExecutionId
        THROW 51431, N'@ExpectedExecutionId stimmt nicht mit dem aktiven Context überein.', 1;
    IF @CurrentDepth IS NULL OR @CurrentDepth < 1
        THROW 51432, N'Der aktive Context besitzt einen ungültigen ScopeDepth.', 1;

    IF @CurrentDepth > 1
    BEGIN
        DECLARE @NewDepth int = @CurrentDepth - 1;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=@NewDepth;
    END
    ELSE
    BEGIN
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.id', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.correlation_id', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.actor', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.tenant', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.started_at_utc', @value=NULL;
        EXEC sys.sp_set_session_context @key=N'toolbelt.execution.depth', @value=NULL;
    END;

    IF @Debug > 0
        RAISERROR(N'USP_EndExecution: Execution Scope wurde beendet.', 10, 1) WITH NOWAIT;
    RETURN 0;
END;
GO
