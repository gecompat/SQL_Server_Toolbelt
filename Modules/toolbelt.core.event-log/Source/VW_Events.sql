SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER VIEW [toolbelt_core].[VW_Events]
AS
SELECT
      EventId, OccurredAtUtc, RecordedAtUtc, EventName, EventLevel, Category
    , Message, DataJson, ExecutionId, CorrelationId, Actor, Tenant
    , SourceDatabaseName, SourceSchemaName, SourceObjectName
    , CallerSessionId, CallerXactState, CallerTransactionCount, RemoteSessionId
    , ErrorNumber, ErrorSeverity, ErrorState, ErrorProcedure, ErrorLine
FROM toolbelt_core.EventLog;
GO
