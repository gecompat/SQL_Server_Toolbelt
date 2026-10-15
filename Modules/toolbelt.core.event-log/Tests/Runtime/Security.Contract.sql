SET NOCOUNT ON;
DECLARE @Own TABLE(EventId bigint NOT NULL PRIMARY KEY);
INSERT toolbelt_core.EventLog(OccurredAtUtc,RecordedAtUtc,EventName,EventLevel,ExecutionId,CorrelationId,SourceDatabaseName,CallerSessionId,CallerXactState,CallerTransactionCount,RemoteSessionId)
OUTPUT inserted.EventId INTO @Own
SELECT CONVERT(datetime2(7),'2099-01-01'),CONVERT(datetime2(7),'2020-01-01'),'contoso.retention','INFO',NEWID(),NEWID(),N'Contoso',1,0,0,1
FROM (VALUES(1),(2),(3))n(i);
DECLARE @Deleted bigint;
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @BeforeRecordedAtUtc='2021-01-01',@BatchSize=1,@MaxBatches=2,@DeletedRows=@Deleted OUTPUT;
IF @Deleted<>2 OR (SELECT COUNT(*) FROM toolbelt_core.EventLog e JOIN @Own o ON o.EventId=e.EventId)<>1 THROW 52990,N'Recorded retention batch bound.',1;
BEGIN TRANSACTION;
EXEC toolbelt_core.USP_DeleteRecordedEventsBefore @BeforeRecordedAtUtc='2021-01-01',@BatchSize=1,@MaxBatches=1,@DeletedRows=@Deleted OUTPUT;
IF @Deleted<>1 OR @@TRANCOUNT<>1 THROW 52990,N'Recorded retention caller transaction.',2;
ROLLBACK TRANSACTION;
IF (SELECT COUNT(*) FROM toolbelt_core.EventLog e JOIN @Own o ON o.EventId=e.EventId)<>1 THROW 52990,N'Recorded retention rollback.',3;
DELETE e FROM toolbelt_core.EventLog e JOIN @Own o ON o.EventId=e.EventId;
GO
