SET NOCOUNT ON;
-- Explizit same-database bedeutet Installationsdatenbank, nicht Caller-USE-Kontext.
CREATE TABLE #CentralClonePlan(Dummy int);
EXEC [$(ToolbeltDatabase)].sys.sp_executesql N'CREATE TABLE dbo.SyntheticCentralClone(Id int NOT NULL);';
EXEC [$(ToolbeltDatabase)].toolbelt_metadata.USP_ScriptTableClone N'dbo',N'SyntheticCentralClone',N'dbo',N'SyntheticCentralTarget',@ResultTable=N'#CentralClonePlan';
IF (SELECT COUNT(*) FROM #CentralClonePlan)<>8 THROW 54920,N'Central preview failed.',4;
EXEC [$(ToolbeltDatabase)].sys.sp_executesql N'IF OBJECT_ID(N''dbo.SyntheticCentralTarget'') IS NOT NULL THROW 54920,N''Central planner executed DDL.'',5; DROP TABLE dbo.SyntheticCentralClone;';
