SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE OR ALTER FUNCTION [toolbelt_core].[TVF_CurrentExecutionContext]()
RETURNS TABLE
AS
RETURN
(
    SELECT
          TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id')) AS ExecutionId
        , TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.correlation_id')) AS CorrelationId
        , CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.actor')) AS Actor
        , CONVERT(nvarchar(256), SESSION_CONTEXT(N'toolbelt.execution.tenant')) AS Tenant
        , TRY_CONVERT(datetime2(7), CONVERT(nvarchar(33), SESSION_CONTEXT(N'toolbelt.execution.started_at_utc')), 126) AS StartedAtUtc
        , TRY_CONVERT(int, SESSION_CONTEXT(N'toolbelt.execution.depth')) AS ScopeDepth
    WHERE TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id')) IS NOT NULL
);
GO
