:on error exit
SET NOCOUNT ON;

DECLARE @Rows TABLE
(
      ExecutedAtUtc datetime2(7), ProviderName varchar(32), LinkedServerName sysname
    , TargetDatabaseName sysname, WorkTypeName varchar(128), ParameterMode varchar(16)
    , CallerSessionId int, RemoteSessionId int, CallerXactState smallint
    , CallerTransactionCount int, ExecutionId uniqueidentifier
    , CorrelationId uniqueidentifier, HandlerReturnCode int NULL
    , RemoteStartedAtUtc datetime2(7), RemoteCompletedAtUtc datetime2(7)
    , DurationMilliseconds decimal(19,3)
);

DECLARE @Sql nvarchar(max) =
    N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)')
    + N'.toolbelt_core.USP_ExecuteWorkTypeInNewSession'
    + N' @WorkTypeName=''test.second-session.central'','
    + N' @ExecutionId=''44444444-1111-1111-1111-111111111111'','
    + N' @CorrelationId=''44444444-2222-2222-2222-222222222222'','
    + N' @Actor=N''central-consumer'';';
INSERT INTO @Rows
EXEC sys.sp_executesql @Sql;

IF NOT EXISTS
(
    SELECT 1 FROM @Rows
    WHERE TargetDatabaseName = N'$(ToolbeltDatabase)'
      AND WorkTypeName = 'test.second-session.central'
      AND CallerSessionId = @@SPID
      AND RemoteSessionId <> @@SPID
      AND ExecutionId = '44444444-1111-1111-1111-111111111111'
      AND CorrelationId = '44444444-2222-2222-2222-222222222222'
      AND HandlerReturnCode = 0
)
    THROW 52680, N'Der zentrale Second-Session-Aufruf ist inkonsistent.', 1;

SET @Sql =
    N'IF NOT EXISTS'
    + N' (SELECT 1 FROM ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.SecondSessionCentralEvidence'
    + N' WHERE ExecutionId=''44444444-1111-1111-1111-111111111111'''
    + N' AND Actor=N''central-consumer'' AND RemoteSessionId <> ' + CONVERT(nvarchar(20), @@SPID) + N')'
    + N' THROW 52681, N''Zentrale Remote-Evidenz fehlt.'', 1;';
EXEC sys.sp_executesql @Sql;

PRINT N'Second Session Central: erfolgreich';
GO
