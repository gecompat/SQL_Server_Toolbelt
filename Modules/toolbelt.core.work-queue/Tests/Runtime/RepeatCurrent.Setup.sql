:On Error exit
SET NOCOUNT ON;
-- Nur der isolierte QueueUpgradeOnly-Adapter: Original2.0 wurde bereits auf
-- 2.1 migriert. Kein Controlconsumer, keine eigene Installation oder Deaktivierung.
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'2.1.0')
 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version')
 THROW 54927,N'Repeatfixture verlangt Queue2.1 ohne Controlconsumer.',1;
DECLARE @Type bigint=(SELECT WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='test.queue.upgrade20');
IF @Type IS NULL THROW 54927,N'Genuine Upgradefixture fehlt.',2;
-- Legitime gespeicherte Statuswerte einschließlich der drei W6c-Erweiterungen.
-- Der isolierte Test setzt diese Zustände direkt; kein Scheduler-/Handlernachweis.
DECLARE @Now datetime2(7)=SYSUTCDATETIME();
INSERT toolbelt_core.WorkItem(WorkTypeId,PayloadJson,Status,ExecutionMode,ClaimGeneration,ClaimToken,
 ClaimedAtUtc,ClaimedBy,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,CycleAttemptCount,
 CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,
 NextAttemptAtUtc,LastErrorCode,LastErrorMessage,LastRetryScheduledAtUtc,LastRetryScheduledBy,
 DeadLetteredAtUtc,DeadLetteredBy,BarrierEpoch)
 SELECT @Type,N'{"repeat":"Unicode ä, spaces  ","ordinal":'+CONVERT(nvarchar(3),v.Ordinal)+N'}',v.Status,
        CASE WHEN v.Status='BARRIER_WAIT' THEN 'DRAIN_BARRIER' ELSE 'SHARED' END,
        CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT') THEN 0 ELSE 1 END,
        CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE NEWID() END,
        CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE @Now END,
        CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE N'ToolbeltSyntheticCaller' END,
        CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE 300 END,
        CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE DATEADD(SECOND,300,@Now) END,
        CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT','RETRY_WAIT') THEN NULL ELSE @Now END,
        CASE WHEN v.Status IN('QUEUED','BARRIER_WAIT') THEN 0 WHEN v.Status='DEAD_LETTER' THEN 3 ELSE 1 END,
        CASE WHEN v.Status='COMPLETED' THEN @Now END,CASE WHEN v.Status='COMPLETED' THEN N'ToolbeltSyntheticCaller' END,
        CASE WHEN v.Status='FAILED' THEN @Now END,CASE WHEN v.Status='FAILED' THEN N'ToolbeltSyntheticCaller' END,
        CASE WHEN v.Status IN('FAILED','DEAD_LETTER') THEN 'TEST.REPEAT' END,CASE WHEN v.Status IN('FAILED','DEAD_LETTER') THEN N'Synthetischer Repeatfall' END,
        CASE WHEN v.Status='RETRY_WAIT' THEN DATEADD(SECOND,60,@Now) END,
        CASE WHEN v.Status IN('RETRY_WAIT','DEAD_LETTER') THEN 'TEST.REPEAT' END,
        CASE WHEN v.Status IN('RETRY_WAIT','DEAD_LETTER') THEN N'Synthetischer Repeatfall' END,
        CASE WHEN v.Status='RETRY_WAIT' THEN @Now END,CASE WHEN v.Status='RETRY_WAIT' THEN N'ToolbeltSyntheticCaller' END,
        CASE WHEN v.Status='DEAD_LETTER' THEN @Now END,CASE WHEN v.Status='DEAD_LETTER' THEN N'ToolbeltSyntheticCaller' END,
        CASE WHEN v.Status='BARRIER_WAIT' THEN 1 ELSE 0 END
 FROM(VALUES(1,'QUEUED'),(2,'CLAIMED'),(3,'COMPLETED'),(4,'FAILED'),(5,'BARRIER_WAIT'),(6,'RETRY_WAIT'),(7,'DEAD_LETTER'))v(Ordinal,Status);
INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration)
 SELECT b.WorkItemId,b.BarrierEpoch,c.WorkItemId,c.ClaimGeneration
 FROM toolbelt_core.WorkItem b CROSS JOIN toolbelt_core.WorkItem c
 WHERE b.PayloadJson LIKE N'%"ordinal":5}' AND c.PayloadJson LIKE N'%"ordinal":2}';
IF (SELECT COUNT(DISTINCT Status) FROM toolbelt_core.WorkItem)<>7
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker)
 THROW 54927,N'Befüllte Repeatstatus-/FK-Fixture fehlt.',3;

-- Lossless Zeilenvergleich: JSON mit NULLs und binärer UTF16-Darstellung
-- erhält auch Rowversion, Tokens, Textcase und nachlaufende Leerzeichen.
CREATE TABLE #tbx_QueueRepeatRows(TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,RowBytes varbinary(max) NOT NULL);
CREATE TABLE #tbx_QueueRepeatObjects(TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ObjectId int NOT NULL);
CREATE TABLE #tbx_QueueRepeatIdentity(TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ColumnName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ColumnId int NOT NULL,TypeId int NOT NULL,SeedValue decimal(38,0) NOT NULL,IncrementValue decimal(38,0) NOT NULL,LastValue decimal(38,0) NULL,NotForReplication bit NOT NULL);
DECLARE @Table sysname,@Sql nvarchar(max);
DECLARE tables_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT name FROM sys.tables WHERE schema_id=SCHEMA_ID(N'toolbelt_core') AND name IN(N'WorkItem',N'WorkType',N'WorkQueueScheduler',N'WorkQueueBarrierBlocker',N'WorkQueueManagedGate') ORDER BY name;
OPEN tables_cursor;FETCH NEXT FROM tables_cursor INTO @Table;
WHILE @@FETCH_STATUS=0
BEGIN
 INSERT #tbx_QueueRepeatObjects VALUES(@Table,OBJECT_ID(N'toolbelt_core.'+QUOTENAME(@Table)));
 INSERT #tbx_QueueRepeatIdentity SELECT @Table,name,column_id,system_type_id,CONVERT(decimal(38,0),seed_value),CONVERT(decimal(38,0),increment_value),CONVERT(decimal(38,0),last_value),is_not_for_replication FROM sys.identity_columns WHERE object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(@Table));
 SET @Sql=N'INSERT #tbx_QueueRepeatRows SELECT @Name,CONVERT(varbinary(max),(SELECT r.* FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER)) FROM toolbelt_core.'+QUOTENAME(@Table)+N' r;';
 EXEC sys.sp_executesql @Sql,N'@Name sysname',@Name=@Table;
 FETCH NEXT FROM tables_cursor INTO @Table;
END;
CLOSE tables_cursor;DEALLOCATE tables_cursor;
IF (SELECT COUNT(*) FROM #tbx_QueueRepeatObjects)<>5 THROW 54927,N'Repeatsnapshot besitzt nicht alle fünf Tabellen.',4;
GO
