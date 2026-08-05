SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_WriteEventInternal]
    @PayloadJson nvarchar(max)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF @PayloadJson IS NULL OR DATALENGTH(@PayloadJson) > 131072 OR ISJSON(@PayloadJson) <> 1 OR LEFT(LTRIM(@PayloadJson), 1) <> N'{'
        THROW 51720, N'Die interne Event-Payload muss ein begrenztes JSON-Objekt sein.', 1;

    DECLARE
          @EventName varchar(128) = CONVERT(varchar(128), JSON_VALUE(@PayloadJson, '$.eventName'))
        , @EventLevel varchar(16) = CONVERT(varchar(16), JSON_VALUE(@PayloadJson, '$.eventLevel'))
        , @Category varchar(128) = CONVERT(varchar(128), JSON_VALUE(@PayloadJson, '$.category'))
        , @Message nvarchar(4000) = CONVERT(nvarchar(4000), JSON_VALUE(@PayloadJson, '$.message'))
        , @DataJson nvarchar(max) = JSON_QUERY(@PayloadJson, '$.data')
        , @OccurredAtUtc datetime2(7) = TRY_CONVERT(datetime2(7), JSON_VALUE(@PayloadJson, '$.occurredAtUtc'), 127)
        , @SourceDatabaseName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceDatabaseName'))
        , @SourceSchemaName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceSchemaName'))
        , @SourceObjectName sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.sourceObjectName'))
        , @CallerSessionId int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.callerSessionId'))
        , @CallerXactState smallint = TRY_CONVERT(smallint, JSON_VALUE(@PayloadJson, '$.callerXactState'))
        , @CallerTransactionCount int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.callerTransactionCount'))
        , @ErrorNumber int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorNumber'))
        , @ErrorSeverity int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorSeverity'))
        , @ErrorState int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorState'))
        , @ErrorProcedure sysname = CONVERT(sysname, JSON_VALUE(@PayloadJson, '$.errorProcedure'))
        , @ErrorLine int = TRY_CONVERT(int, JSON_VALUE(@PayloadJson, '$.errorLine'));

    DECLARE
          @ExecutionId uniqueidentifier
        , @CorrelationId uniqueidentifier
        , @Actor nvarchar(256)
        , @Tenant nvarchar(256);
    SELECT
          @ExecutionId = c.ExecutionId
        , @CorrelationId = c.CorrelationId
        , @Actor = c.Actor
        , @Tenant = c.Tenant
    FROM toolbelt_core.TVF_CurrentExecutionContext() AS c;

    IF NULLIF(@EventName, '') IS NULL OR @OccurredAtUtc IS NULL OR NULLIF(@SourceDatabaseName, N'') IS NULL
       OR @CallerSessionId IS NULL OR @CallerXactState NOT IN (-1,0,1) OR @CallerTransactionCount IS NULL
       OR @ExecutionId IS NULL OR @CorrelationId IS NULL
        THROW 51721, N'Die interne Event-Payload ist unvollständig.', 1;
    IF @EventLevel NOT IN ('TRACE','DEBUG','INFO','WARNING','ERROR','CRITICAL')
        THROW 51722, N'Die interne Event-Level-Angabe ist ungültig.', 1;
    IF @DataJson IS NOT NULL AND (DATALENGTH(@DataJson) > 65536 OR LEFT(LTRIM(@DataJson), 1) <> N'{')
        THROW 51723, N'Die interne Data-Payload verletzt den JSON-Objekt- oder Größenvertrag.', 1;
    IF @ErrorSeverity IS NOT NULL AND @ErrorSeverity NOT BETWEEN 0 AND 25
        THROW 51724, N'ErrorSeverity liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorState IS NOT NULL AND @ErrorState NOT BETWEEN 0 AND 255
        THROW 51725, N'ErrorState liegt außerhalb des SQL-Server-Bereichs.', 1;
    IF @ErrorLine IS NOT NULL AND @ErrorLine <= 0
        THROW 51726, N'ErrorLine muss positiv sein.', 1;

    INSERT INTO toolbelt_core.EventLog
    (
          OccurredAtUtc, EventName, EventLevel, Category, Message, DataJson
        , ExecutionId, CorrelationId, Actor, Tenant
        , SourceDatabaseName, SourceSchemaName, SourceObjectName
        , CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId
        , ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine
    )
    VALUES
    (
          @OccurredAtUtc, @EventName, @EventLevel, @Category, @Message, @DataJson
        , @ExecutionId, @CorrelationId, @Actor, @Tenant
        , @SourceDatabaseName, @SourceSchemaName, @SourceObjectName
        , @CallerSessionId, @CallerXactState, @CallerTransactionCount, @@SPID
        , @ErrorNumber, @ErrorSeverity, @ErrorState, @ErrorProcedure, @ErrorLine
    );

    RETURN 0;
END;
GO
