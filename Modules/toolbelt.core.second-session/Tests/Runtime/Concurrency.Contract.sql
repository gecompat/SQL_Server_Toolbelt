:on error exit
SET NOCOUNT ON;

DECLARE @WorkerId int = $(WorkerId);
DECLARE @ExecutionId uniqueidentifier = NEWID();
DECLARE @CorrelationId uniqueidentifier = NEWID();
DECLARE @PayloadJson nvarchar(max) =
    N'{"worker":' + CONVERT(nvarchar(20), @WorkerId)
    + N',"callerSession":' + CONVERT(nvarchar(20), @@SPID) + N'}';
DECLARE @ExecutionId uniqueidentifier = NEWID();
DECLARE @CorrelationId uniqueidentifier = NEWID();

EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
      @WorkTypeName = 'test.second-session.concurrent'
    , @PayloadJson = @PayloadJson
    , @ExecutionId = @ExecutionId
    , @CorrelationId = @CorrelationId
    , @Actor = N'concurrency-worker';
GO
