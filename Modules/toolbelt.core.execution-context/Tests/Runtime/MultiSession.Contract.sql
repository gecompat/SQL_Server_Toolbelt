SET NOCOUNT ON;
DECLARE @Id uniqueidentifier;
DECLARE @Actor nvarchar(256) = N'worker-' + N'$(WorkerId)';
EXEC toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT, @Actor=@Actor;
WAITFOR DELAY '00:00:02';
IF NOT EXISTS (SELECT 1 FROM toolbelt_core.TVF_CurrentExecutionContext() WHERE ExecutionId=@Id AND Actor=@Actor AND ScopeDepth=1)
 THROW 52429, N'Sessionisolation fehlgeschlagen.', 1;
EXEC toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;
