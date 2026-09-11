SET NOCOUNT ON;
DECLARE @ExecutionId uniqueidentifier='00000000-0000-0000-0000-000000000031';
DECLARE @Sql nvarchar(max)=N'EXEC '+QUOTENAME(N'$(ToolbeltDatabase)')+N'.toolbelt_core.USP_RequestExecutionCancellation @ExecutionId=@p;';
EXEC sys.sp_executesql @Sql,N'@p uniqueidentifier',@p=@ExecutionId;
SET @Sql=N'IF NOT EXISTS(SELECT 1 FROM '+QUOTENAME(N'$(ToolbeltDatabase)')+N'.toolbelt_core.TVF_ExecutionCancellationStatus(@p)) THROW 52711,N''Central status is inconsistent.'',1;';
EXEC sys.sp_executesql @Sql,N'@p uniqueidentifier',@p=@ExecutionId;
PRINT N'Execution Cancellation Central: erfolgreich';
