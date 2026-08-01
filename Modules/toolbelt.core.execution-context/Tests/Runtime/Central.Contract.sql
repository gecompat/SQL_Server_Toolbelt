SET NOCOUNT ON;
DECLARE @Id uniqueidentifier;
DECLARE @Sql nvarchar(max) = N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.USP_BeginExecution @ExecutionId=@Id OUTPUT, @Actor=N''central'';';
EXEC sys.sp_executesql @Sql, N'@Id uniqueidentifier OUTPUT', @Id=@Id OUTPUT;
IF @Id IS NULL OR TRY_CONVERT(uniqueidentifier, SESSION_CONTEXT(N'toolbelt.execution.id')) <> @Id
 THROW 52432, N'Central Begin fehlgeschlagen.', 1;
SET @Sql = N'EXEC ' + QUOTENAME(N'$(ToolbeltDatabase)') + N'.toolbelt_core.USP_EndExecution @ExpectedExecutionId=@Id;';
EXEC sys.sp_executesql @Sql, N'@Id uniqueidentifier', @Id=@Id;
IF SESSION_CONTEXT(N'toolbelt.execution.id') IS NOT NULL
 THROW 52433, N'Central End fehlgeschlagen.', 1;
PRINT N'Execution Context Central: erfolgreich';
