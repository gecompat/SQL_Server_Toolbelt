SET NOCOUNT ON;
DECLARE @ExecutionId uniqueidentifier='00000000-0000-0000-0000-000000000021';
EXEC toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@ExecutionId,@CancellationReason=N'synthetic concurrent';
