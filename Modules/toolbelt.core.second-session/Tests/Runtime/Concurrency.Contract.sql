:on error exit
SET NOCOUNT ON;

DECLARE @WorkerId int = $(WorkerId);
DECLARE @PayloadJson nvarchar(max) =
    N'{"worker":' + CONVERT(nvarchar(20), @WorkerId)
    + N',"callerSession":' + CONVERT(nvarchar(20), @@SPID) + N'}';

EXEC toolbelt_core.USP_ExecuteWorkTypeInNewSession
      @WorkTypeName = 'test.second-session.concurrent'
    , @PayloadJson = @PayloadJson
    , @ExecutionId = NEWID()
    , @CorrelationId = NEWID()
    , @Actor = N'concurrency-worker';
GO
