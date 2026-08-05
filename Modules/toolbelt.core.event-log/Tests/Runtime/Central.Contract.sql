:on error exit
SET NOCOUNT ON;
DECLARE @SourceDatabase sysname=DB_NAME();
EXEC [$(ToolbeltDatabase)].toolbelt_core.USP_WriteEvent @EventName='test.central',@SourceDatabaseName=@SourceDatabase,@Message=N'Central consumer';
IF NOT EXISTS(SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_core.EventLog WHERE EventName='test.central' AND SourceDatabaseName=@SourceDatabase AND RemoteSessionId<>CallerSessionId) THROW 52725,N'Central-Event fehlt oder Source-Datenbank ist inkonsistent.',1;
PRINT N'Event Log Central: erfolgreich';
GO
