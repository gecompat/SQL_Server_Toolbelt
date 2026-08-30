:On Error exit
SET NOCOUNT ON;
DECLARE @ToolbeltDatabase sysname=N'$(ToolbeltDatabase)';
DECLARE @Sql nvarchar(max)=N'CREATE TABLE #Status(Dummy int NULL); EXEC '+QUOTENAME(@ToolbeltDatabase)+N'.toolbelt_core.USP_EnqueueWork @WorkTypeName=''test.queue.central'',@ResultTable=N''#Status''; IF NOT EXISTS(SELECT 1 FROM #Status WHERE Status=''QUEUED'') THROW 52940,N''Zentrale Enqueue-Ausgabe fehlt.'',1; CREATE TABLE #Claim(Dummy int NULL); EXEC '+QUOTENAME(@ToolbeltDatabase)+N'.toolbelt_core.USP_ClaimWork @ResultTable=N''#Claim''; IF NOT EXISTS(SELECT 1 FROM #Claim) THROW 52941,N''Zentraler Claim fehlt.'',1;';
EXEC sys.sp_executesql @Sql;
PRINT N'Work Queue Central: erfolgreich';
GO
