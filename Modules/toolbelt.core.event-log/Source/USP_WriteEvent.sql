SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_WriteEvent]
(
      @EventName varchar(128) = NULL
    , @EventLevel varchar(16) = 'INFO'
    , @Category varchar(128) = NULL
    , @Message nvarchar(4000) = NULL
    , @DataJson nvarchar(max) = NULL
    , @OccurredAtUtc datetime2(7) = NULL
    , @ExecutionId uniqueidentifier = NULL
    , @CorrelationId uniqueidentifier = NULL
    , @Actor nvarchar(256) = NULL
    , @Tenant nvarchar(256) = NULL
    , @SourceDatabaseName sysname = NULL
    , @SourceSchemaName sysname = NULL
    , @SourceObjectName sysname = NULL
    , @ErrorNumber int = NULL
    , @ErrorSeverity int = NULL
    , @ErrorState int = NULL
    , @ErrorProcedure sysname = NULL
    , @ErrorLine int = NULL
    , @Debug tinyint = 0
    , @Hilfe bit = 0
)
AS
BEGIN
    SET NOCOUNT ON;

    SET @EventLevel = UPPER(ISNULL(@EventLevel, 'INFO'));
    SET @OccurredAtUtc = ISNULL(@OccurredAtUtc, SYSUTCDATETIME());
    SET @SourceDatabaseName = ISNULL(@SourceDatabaseName, DB_NAME());
    SET @Debug = ISNULL(@Debug, 0);
    SET @Hilfe = ISNULL(@Hilfe, 0);

    IF @Hilfe = 1
    BEGIN
        SELECT
              CAST('1.0' AS varchar(16)) AS HelpContractVersion
            , CAST(N'toolbelt_core' AS sysname) AS SchemaName
            , CAST(N'USP_WriteEvent' AS sysname) AS ObjectName
            , v.Section, v.Ordinal, v.ItemName, v.SqlDataType
            , v.IsRequired, v.IsNullable, v.DefaultValue, v.Description, v.ExampleSql
        FROM
        (
            VALUES
              (CAST('DESCRIPTION' AS varchar(32)), 1, CAST(NULL AS sysname), CAST(NULL AS varchar(256)), CAST(NULL AS bit), CAST(NULL AS bit), CAST(NULL AS nvarchar(4000)), CAST(N'Schreibt ein strukturiertes Event synchron über toolbelt.core.second-session. Der Remote-Commit ist unabhängig von Commit oder Rollback der Caller-Transaktion.' AS nvarchar(max)), CAST(NULL AS nvarchar(max)))
            , ('PARAMETER', 1, N'@EventName', 'varchar(128)', 1, 0, NULL, N'Kanonischer Eventname in lowercase ASCII.', NULL)
            , ('PARAMETER', 2, N'@EventLevel', 'varchar(16)', 0, 0, N'INFO', N'TRACE, DEBUG, INFO, WARNING, ERROR oder CRITICAL.', NULL)
            , ('PARAMETER', 3, N'@Message', 'nvarchar(4000)', 0, 1, NULL, N'Begrenzte menschenlesbare Meldung; keine ungeprüften Secrets persistieren.', NULL)
            , ('PARAMETER', 4, N'@DataJson', 'nvarchar(max)', 0, 1, NULL, N'Begrenztes JSON-Objekt bis 32 KiB UTF-16-Speicher.', NULL)
            , ('PARAMETER', 5, N'@OccurredAtUtc', 'datetime2(7)', 0, 0, N'SYSUTCDATETIME()', N'Fachlicher Ereigniszeitpunkt in UTC.', NULL)
            , ('ERROR', 1, N'51700-51709', NULL, NULL, NULL, NULL, N'Event-, JSON-, Fehler- und Dependency-Vertragsfehler.', NULL)
            , ('EXAMPLE', 1, NULL, NULL, NULL, NULL, NULL, N'Schreibt ein Info-Event.', N'EXEC toolbelt_core.USP_WriteEvent @EventName=''demo.completed'', @Message=N''Synthetic example'';')
        ) AS v(Section, Ordinal, ItemName, SqlDataType, IsRequired, IsNullable, DefaultValue, Description, ExampleSql)
        ORDER BY CASE v.Section WHEN 'DESCRIPTION' THEN 1 WHEN 'PARAMETER' THEN 2 WHEN 'ERROR' THEN 3 ELSE 4 END, v.Ordinal;
        RETURN 0;
    END;

    IF NULLIF(@EventName, '') IS NULL
       OR LEN(@EventName) NOT BETWEEN 3 AND 128
       OR @EventName <> LOWER(@EventName) COLLATE Latin1_General_100_BIN2
       OR @EventName NOT LIKE '[a-z]%' COLLATE Latin1_General_100_BIN2
       OR @EventName LIKE '%[^a-z0-9._-]%' COLLATE Latin1_General_100_BIN2
        THROW 51700, N'@EventName muss ein kanonischer lowercase ASCII-Name sein.', 1;
    IF @EventLevel NOT IN ('TRACE','DEBUG','INFO','WARNING','ERROR','CRITICAL')
        THROW 51701, N'@EventLevel ist ungültig.', 1;
    IF @Category IS NOT NULL AND (LEN(@Category) > 128 OR @Category LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2)
        THROW 51702, N'@Category enthält ungültige Zeichen oder ist zu lang.', 1;
    IF @DataJson IS NOT NULL AND (DATALENGTH(@DataJson) > 65536 OR ISJSON(@DataJson) <> 1 OR LEFT(LTRIM(@DataJson), 1) <> N'{')
        THROW 51703, N'@DataJson muss ein JSON-Objekt mit höchstens 32 KiB UTF-16-Speicher sein.', 1;
    IF NULLIF(@SourceDatabaseName, N'') IS NULL
        THROW 51704, N'@SourceDatabaseName ist erforderlich.', 1;
    IF @ErrorSeverity IS NOT NULL AND @ErrorSeverity NOT BETWEEN 0 AND 25
        THROW 51705, N'@ErrorSeverity liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorState IS NOT NULL AND @ErrorState NOT BETWEEN 0 AND 255
        THROW 51706, N'@ErrorState liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorLine IS NOT NULL AND @ErrorLine <= 0
        THROW 51707, N'@ErrorLine muss positiv sein.', 1;
    IF OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession', N'P') IS NULL
       OR NOT EXISTS
          (
              SELECT 1 FROM sys.parameters
              WHERE object_id = OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession')
                AND name = N'@SuppressResult'
          )
        THROW 51708, N'Die Abhängigkeit toolbelt.core.second-session Version 1.1.0 fehlt.', 1;

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

    DECLARE @CallerSessionId int = @@SPID;
    DECLARE @CallerXactState smallint = CONVERT(smallint, XACT_STATE());
    DECLARE @CallerTransactionCount int = @@TRANCOUNT;
    DECLARE @PayloadJson nvarchar(max);

    SELECT @PayloadJson =
    (
        SELECT
              @EventName AS eventName
            , @EventLevel AS eventLevel
            , @Category AS category
            , @Message AS message
            , JSON_QUERY(@DataJson) AS data
            , CONVERT(nvarchar(33), @OccurredAtUtc, 127) AS occurredAtUtc
            , @SourceDatabaseName AS sourceDatabaseName
            , @SourceSchemaName AS sourceSchemaName
            , @SourceObjectName AS sourceObjectName
            , @CallerSessionId AS callerSessionId
            , @CallerXactState AS callerXactState
            , @CallerTransactionCount AS callerTransactionCount
            , @ErrorNumber AS errorNumber
            , @ErrorSeverity AS errorSeverity
            , @ErrorState AS errorState
            , @ErrorProcedure AS errorProcedure
            , @ErrorLine AS errorLine
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
    );

    EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
          @WorkTypeName = 'toolbelt.event-log.write'
        , @PayloadJson = @PayloadJson
        , @ExecutionId = @ExecutionId
        , @CorrelationId = @CorrelationId
        , @Actor = @Actor
        , @Tenant = @Tenant
        , @SuppressResult = 1
        , @Debug = @Debug;

    RETURN 0;
END;
GO
