DECLARE @ExecutionId uniqueidentifier;
EXEC toolbelt_core.USP_BeginExecution
      @ExecutionId = @ExecutionId OUTPUT
    , @Actor = N'synthetic-worker'
    , @Tenant = N'demo';

SELECT * FROM toolbelt_core.TVF_CurrentExecutionContext();
SELECT toolbelt_core.SVF_CurrentExecutionId() AS ExecutionId;

EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId = @ExecutionId;
