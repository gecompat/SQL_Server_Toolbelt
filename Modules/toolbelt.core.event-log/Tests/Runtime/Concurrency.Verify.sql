SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM toolbelt_core.EventLog WHERE EventName='test.concurrent')<>4 THROW 52720,N'Concurrency-Evidenz ist unvollständig.',1;
IF EXISTS(SELECT 1 FROM toolbelt_core.EventLog WHERE EventName='test.concurrent' AND RemoteSessionId=CallerSessionId) THROW 52721,N'Concurrency-Evidenz lief nicht in getrennten Sessions.',1;
IF (SELECT COUNT(DISTINCT TRY_CONVERT(int,JSON_VALUE(DataJson,'$.worker'))) FROM toolbelt_core.EventLog WHERE EventName='test.concurrent')<>4 THROW 52722,N'Worker-Evidenz ist nicht eindeutig.',1;
PRINT N'Event Log Concurrency: erfolgreich';
