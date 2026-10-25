SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET ANSI_NULL_DFLT_ON ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52093,N'Markierter eigener frischer Queue-Worker-Testscope erforderlich.',1;
IF USER_ID(N'ContosoQueueWorkerCaller') IS NOT NULL OR OBJECT_ID(N'dbo.USP_ContosoQueueWorkerNoop') IS NOT NULL
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='contoso.queue.worker.rights')
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker)
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=0 AND PendingReservationId IS NULL)
 THROW 52093,N'Vorhandene oder verwaltete Queuefixture wird nicht uebernommen.',2;
DECLARE @Apis table(Id int PRIMARY KEY,Name sysname,PermissionName varchar(16),SqlText nvarchar(max),Probe nvarchar(max));
INSERT @Apis VALUES
 (1,N'toolbelt_core.USP_ClaimWork','EXECUTE',N'EXEC toolbelt_core.USP_ClaimWork @LeaseDurationSeconds=300;',N'EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;'),
 (2,N'toolbelt_core.USP_RenewWorkLease','EXECUTE',N'EXEC toolbelt_core.USP_RenewWorkLease @WorkItemId=@Item,@ClaimToken=@Token;',N'EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;'),
 (3,N'toolbelt_core.USP_RecoverExpiredWork','EXECUTE',N'EXEC toolbelt_core.USP_RecoverExpiredWork @MaxItems=1;',N'EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;'),
 (4,N'toolbelt_core.USP_CompleteWork','EXECUTE',N'EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@Item,@ClaimToken=@Token;',N'EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;'),
 (5,N'toolbelt_core.USP_FailWork','EXECUTE',N'EXEC toolbelt_core.USP_FailWork @WorkItemId=@Item,@ClaimToken=@Token,@FailureCode=''SyntheticFailure'',@FailureMessage=N''synthetic failure'';',N'EXEC toolbelt_core.USP_FailWork @Hilfe=1;'),
 (6,N'toolbelt_core.USP_ScheduleWorkRetry','EXECUTE',N'EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=@Item,@ClaimToken=@Token,@FailureCode=''SyntheticRetry'',@FailureMessage=N''synthetic retry'';',N'EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;'),
 (7,N'toolbelt_core.USP_RequeueDeadLetter','EXECUTE',N'EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=@Item,@ExpectedRowVersion=@Version,@RequeueReason=N''synthetic reset'';',N'EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;'),
 (8,N'toolbelt_core.VW_WorkQueueBarrierBlockers','SELECT',N'
  IF (SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueueBarrierBlockers)<>1
   OR NOT EXISTS(SELECT 1 FROM toolbelt_core.VW_WorkQueueBarrierBlockers WHERE BarrierWorkItemId=@Barrier AND BarrierEpoch=1
    AND BlockingWorkItemId=@Item AND BlockingClaimGeneration=7 AND CapturedAtUtc IS NOT NULL AND IsResolved=0)
   THROW 52093,N''Befuellter unaufgeloester Blocker-Festwert verletzt.'',3;',
  N'SELECT TOP(0) * FROM toolbelt_core.VW_WorkQueueBarrierBlockers;'),
 (9,N'toolbelt_core.USP_EnqueueWork','EXECUTE',NULL,N'EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;'),
 (10,N'toolbelt_core.USP_EnqueueWorkWithPolicy','EXECUTE',NULL,N'EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;'),
 (11,N'toolbelt_core.USP_EnqueueBarrierWork','EXECUTE',NULL,N'EXEC toolbelt_core.USP_EnqueueBarrierWork @Hilfe=1;'),
 (12,N'toolbelt_core.USP_GetWorkStatus','EXECUTE',NULL,N'EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;'),
 (13,N'toolbelt_core.VW_WorkQueue','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.VW_WorkQueue;'),
 (14,N'toolbelt_core.USP_ClaimWorkCore','EXECUTE',NULL,N'EXEC toolbelt_core.USP_ClaimWorkCore @Hilfe=1;'),
 (15,N'toolbelt_core.USP_FailWorkCore','EXECUTE',NULL,N'EXEC toolbelt_core.USP_FailWorkCore @Hilfe=1;'),
 (16,N'toolbelt_core.USP_ScheduleWorkRetryCore','EXECUTE',NULL,N'EXEC toolbelt_core.USP_ScheduleWorkRetryCore @Hilfe=1;'),
 (17,N'toolbelt_core.WorkItem','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkItem;'),
 (18,N'toolbelt_core.WorkQueueScheduler','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkQueueScheduler;'),
 (19,N'toolbelt_core.WorkQueueBarrierBlocker','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkQueueBarrierBlocker;'),
 (20,N'toolbelt_core.WorkQueueManagedGate','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkQueueManagedGate;'),
 (21,N'toolbelt_core.USP_PrepareResultTable','EXECUTE',NULL,N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;'),
 (22,N'toolbelt_core.USP_RegisterWorkType','EXECUTE',NULL,N'EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;'),
 (23,N'toolbelt_core.WorkType','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkType;'),
 (24,N'dbo.USP_ContosoQueueWorkerNoop','EXECUTE',NULL,N'EXEC dbo.USP_ContosoQueueWorkerNoop;');
DECLARE @Profile int=1,@Phase int,@Other int,@Name sysname,@Permission varchar(16),@Sql nvarchar(max),@Grant nvarchar(max),@Probe nvarchar(max),
 @Caught bit,@Created bit=0,@HandlerCreated bit=0,@Impersonated bit=0,@Positive int=0,@Denied int=0,@TokenDenied int=0,@EmptyClaims int=0,@ViewStates int=0,
 @TypeId bigint,@Item bigint,@Barrier bigint,@Version binary(8),@LeaseBefore datetime2(7),@Started datetime2(7),@Expires datetime2(7),@ExpectedTokenError int,
 @Token uniqueidentifier='11111111-1111-1111-1111-111111111111',@WrongToken uniqueidentifier='22222222-2222-2222-2222-222222222222',
 @ExpectedClaimStatus varchar(16)='CLAIMED';
BEGIN TRY
 EXEC sys.sp_executesql N'CREATE PROCEDURE dbo.USP_ContosoQueueWorkerNoop AS RETURN 0;'; SET @HandlerCreated=1;
 EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='contoso.queue.worker.rights',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_ContosoQueueWorkerNoop';
 SELECT @TypeId=WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='contoso.queue.worker.rights';
 IF @TypeId IS NULL THROW 52093,N'Eigener Worker-Work-Type fehlt.',4;
 CREATE USER ContosoQueueWorkerCaller WITHOUT LOGIN; SET @Created=1;
 EXEC toolbelt_core.USP_SetWorkTypePermission 'contoso.queue.worker.rights',N'ContosoQueueWorkerCaller','CLAIM','ALLOW';
 WHILE @Profile<=8
 BEGIN
  SELECT @Name=Name,@Permission=PermissionName,@Sql=SqlText FROM @Apis WHERE Id=@Profile;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   SET @Barrier=NULL; SET @Started=SYSUTCDATETIME();
   IF @Profile=1
    INSERT toolbelt_core.WorkItem(WorkTypeId,ExecutionGroup) VALUES(@TypeId,'ContosoWorkerRights');
   ELSE IF @Profile=7
    INSERT toolbelt_core.WorkItem(WorkTypeId,Status,ExecutionGroup,ClaimGeneration,CycleAttemptCount,DeadLetteredAtUtc,DeadLetteredBy)
     VALUES(@TypeId,'DEAD_LETTER','ContosoWorkerRights',7,3,@Started,ORIGINAL_LOGIN());
   ELSE
   BEGIN
    SET @Expires=DATEADD(SECOND,CASE WHEN @Profile=3 THEN -30 WHEN @Profile=2 THEN 600 ELSE 3600 END,@Started);
    INSERT toolbelt_core.WorkItem(WorkTypeId,Status,ExecutionGroup,ClaimedAtUtc,ClaimedBy,ClaimToken,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,CycleAttemptCount)
     VALUES(@TypeId,'CLAIMED','ContosoWorkerRights',DATEADD(SECOND,-600,@Started),ORIGINAL_LOGIN(),@Token,7,3600,@Expires,DATEADD(SECOND,-60,@Started),1);
   END;
   SET @Item=CONVERT(bigint,SCOPE_IDENTITY());
   IF @Profile=8
   BEGIN
    INSERT toolbelt_core.WorkItem(WorkTypeId,Status,ExecutionGroup,Priority,ExecutionMode,BarrierEpoch)
     VALUES(@TypeId,'BARRIER_WAIT','ContosoWorkerRights',9,'DRAIN_BARRIER',1);
    SET @Barrier=CONVERT(bigint,SCOPE_IDENTITY());
    INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration) VALUES(@Barrier,1,@Item,7);
   END;
   SELECT @Version=CONVERT(binary(8),RowVersion),@LeaseBefore=LeaseUntilUtc FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item;
   SET @Grant=CASE @Phase WHEN 1 THEN N'GRANT '+@Permission+N' ON OBJECT::'+@Name+N' TO ContosoQueueWorkerCaller;'
    WHEN 2 THEN N'REVOKE '+@Permission+N' ON OBJECT::'+@Name+N' FROM ContosoQueueWorkerCaller;' END;
   IF @Grant IS NOT NULL EXEC sys.sp_executesql @Grant;
   IF @Profile=1 AND @Phase=2 REVOKE EXECUTE ON OBJECT::dbo.USP_ContosoQueueWorkerNoop FROM ContosoQueueWorkerCaller;
   EXECUTE AS USER=N'ContosoQueueWorkerCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0
    THROW 52093,N'Unerwartete breite Queue-Worker-Rechte.',5;
   IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(Name,N'OBJECT',PermissionName),0)<>CASE WHEN @Phase=1 AND Id=@Profile THEN 1 ELSE 0 END)
    OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.USP_ContosoQueueWorkerNoop',N'OBJECT',N'VIEW DEFINITION'),0)<>0
    THROW 52093,N'Queue-Worker-Objektrechte ueberschreiten das Profil.',6;
   IF @Profile=1 AND @Phase=1
   BEGIN
    REVERT; SET @Impersonated=0;
    GRANT VIEW DEFINITION ON OBJECT::dbo.USP_ContosoQueueWorkerNoop TO ContosoQueueWorkerCaller;
    EXECUTE AS USER=N'ContosoQueueWorkerCaller'; SET @Impersonated=1;
    IF ISNULL(HAS_PERMS_BY_NAME(N'dbo.USP_ContosoQueueWorkerNoop',N'OBJECT',N'VIEW DEFINITION'),0)<>1
     OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.USP_ContosoQueueWorkerNoop',N'OBJECT',N'EXECUTE'),0)<>0
     THROW 52093,N'Handler muss sichtbar, aber nicht ausfuehrbar sein.',7;
    EXEC sys.sp_executesql @Sql;
    REVERT; SET @Impersonated=0;
    IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='QUEUED' AND ClaimGeneration=0 AND CONVERT(binary(8),RowVersion)=@Version)
     THROW 52093,N'Claim ohne Handler-EXECUTE veraenderte das Item.',8;
    SET @EmptyClaims+=1;
    REVOKE VIEW DEFINITION ON OBJECT::dbo.USP_ContosoQueueWorkerNoop FROM ContosoQueueWorkerCaller;
    GRANT EXECUTE ON OBJECT::dbo.USP_ContosoQueueWorkerNoop TO ContosoQueueWorkerCaller;
    EXECUTE AS USER=N'ContosoQueueWorkerCaller'; SET @Impersonated=1;
    IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(Name,N'OBJECT',PermissionName),0)<>CASE WHEN Id IN(1,24) THEN 1 ELSE 0 END)
     THROW 52093,N'Claimprofil braucht nur Claim- und Handler-EXECUTE.',9;
   END;
   IF @Phase=1 AND @Profile IN(2,4,5,6)
   BEGIN
    SET @ExpectedTokenError=CASE @Profile WHEN 2 THEN 51952 WHEN 4 THEN 51923 WHEN 5 THEN 51928 ELSE 51987 END; SET @Caught=0;
    BEGIN TRY EXEC sys.sp_executesql @Sql,N'@Item bigint,@Token uniqueidentifier,@Version binary(8),@Barrier bigint',@Item,@WrongToken,@Version,@Barrier; END TRY
    BEGIN CATCH IF ERROR_NUMBER()<>@ExpectedTokenError THROW; SET @Caught=1; SET @TokenDenied+=1; END CATCH;
    IF @Caught=0 THROW 52093,N'Falsches Worker-Ownership-Token wurde zugelassen.',10;
    REVERT; SET @Impersonated=0;
    IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='CLAIMED' AND ClaimToken=@Token AND CONVERT(binary(8),RowVersion)=@Version)
     THROW 52093,N'Falsches Token veraenderte das eigene Item.',11;
    EXECUTE AS USER=N'ContosoQueueWorkerCaller'; SET @Impersonated=1;
   END;
   SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Sql,N'@Item bigint,@Token uniqueidentifier,@Version binary(8),@Barrier bigint',@Item,@Token,@Version,@Barrier; END TRY
   BEGIN CATCH IF @Phase=1 OR ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
   IF @Phase<>1 AND @Caught=0 THROW 52093,N'Fehlendes Queue-Worker-Recht wurde zugelassen.',12;
   IF @Phase=1
   BEGIN
    SET @Positive+=1; SET @Other=1;
    WHILE @Other<=24
    BEGIN
     IF @Other<>@Profile AND NOT(@Other=24 AND @Profile=1)
     BEGIN
      SELECT @Probe=Probe FROM @Apis WHERE Id=@Other; SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @Probe; END TRY
      BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
      IF @Caught=0 THROW 52093,N'Fremdes Worker-API, Handler oder interner Zustand war zugaenglich.',13;
     END;
     SET @Other+=1;
    END;
   END;
   REVERT; SET @Impersonated=0;
   IF @Phase=1
   BEGIN
    IF @Profile=1 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status=@ExpectedClaimStatus AND ClaimGeneration=1 AND ClaimToken IS NOT NULL AND CycleAttemptCount=1 AND LeaseDurationSeconds=300 AND LeaseUntilUtc>@Started)
     THROW 52093,N'Persistiertes Claim-Festwertorakel verletzt.',14;
    IF @Profile=2 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='CLAIMED' AND ClaimToken=@Token AND ClaimGeneration=7 AND LeaseUntilUtc>@LeaseBefore)
     THROW 52093,N'Persistiertes Lease-Festwertorakel verletzt.',15;
    IF @Profile=3 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='RETRY_WAIT' AND ClaimToken IS NULL AND LeaseUntilUtc IS NULL AND RecoveryCount=1 AND ClaimGeneration=7 AND LastRecoveredAtUtc IS NOT NULL AND NextAttemptAtUtc>@Started)
     THROW 52093,N'Persistiertes Recovery-Festwertorakel verletzt.',16;
    IF @Profile=4 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='COMPLETED' AND CompletedAtUtc IS NOT NULL AND ClaimGeneration=7)
     THROW 52093,N'Persistiertes Complete-Festwertorakel verletzt.',17;
    IF @Profile=5 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='FAILED' AND FailureCode='SyntheticFailure' AND FailureMessage=N'synthetic failure' AND FailedAtUtc IS NOT NULL)
     THROW 52093,N'Persistiertes Fail-Festwertorakel verletzt.',18;
    IF @Profile=6 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='RETRY_WAIT' AND ClaimToken IS NULL AND NextAttemptAtUtc>@Started AND LastErrorCode='SyntheticRetry')
     THROW 52093,N'Persistiertes Retry-Festwertorakel verletzt.',19;
    IF @Profile=7 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='QUEUED' AND ClaimToken IS NULL AND RetryCycleNumber=2 AND CycleAttemptCount=0 AND LastRequeueReason=N'synthetic reset' AND LastRequeuedAtUtc IS NOT NULL)
     THROW 52093,N'Persistiertes Requeue-Festwertorakel verletzt.',20;
    IF @Profile=8
    BEGIN
     EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@Item,@ClaimToken=@Token;
     EXECUTE AS USER=N'ContosoQueueWorkerCaller'; SET @Impersonated=1;
     EXEC sys.sp_executesql N'IF (SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueueBarrierBlockers)<>1
      OR NOT EXISTS(SELECT 1 FROM toolbelt_core.VW_WorkQueueBarrierBlockers WHERE BarrierWorkItemId=@Barrier AND BarrierEpoch=1
       AND BlockingWorkItemId=@Item AND BlockingClaimGeneration=7 AND IsResolved=1)
      THROW 52093,N''Aufgeloester Blocker-Festwert verletzt.'',21;',N'@Item bigint,@Barrier bigint',@Item,@Barrier;
     REVERT; SET @Impersonated=0; SET @ViewStates+=2;
    END;
   END;
   IF @Phase<>1 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND CONVERT(binary(8),RowVersion)=@Version)
    THROW 52093,N'Abgewiesenes Worker-API veraenderte das eigene Item.',22;
   DELETE toolbelt_core.WorkQueueBarrierBlocker WHERE BarrierWorkItemId IN(SELECT WorkItemId FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId)
    OR BlockingWorkItemId IN(SELECT WorkItemId FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId);
   DELETE toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId;
   SET @Phase+=1;
  END;
  SET @Profile+=1;
 END;
 IF @Positive<>8 OR @Denied<>199 OR @TokenDenied<>4 OR @EmptyClaims<>1 OR @ViewStates<>2
  THROW 52093,N'Unvollstaendige Queue-Worker-Probenzahl.',23;
 DELETE toolbelt_core.WorkTypePermission WHERE WorkTypeId=@TypeId;
 DELETE toolbelt_core.WorkType WHERE WorkTypeId=@TypeId;
 DROP USER ContosoQueueWorkerCaller; SET @Created=0;
 DROP PROCEDURE dbo.USP_ContosoQueueWorkerNoop; SET @HandlerCreated=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF XACT_STATE()<>0 ROLLBACK;
 SELECT @TypeId=WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='contoso.queue.worker.rights';
 DELETE toolbelt_core.WorkQueueBarrierBlocker WHERE BarrierWorkItemId IN(SELECT WorkItemId FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId)
  OR BlockingWorkItemId IN(SELECT WorkItemId FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId);
 DELETE toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId;
 DELETE toolbelt_core.WorkTypePermission WHERE WorkTypeId=@TypeId;
 DELETE toolbelt_core.WorkType WHERE WorkTypeId=@TypeId;
 IF @Created=1 DROP USER ContosoQueueWorkerCaller;
 IF @HandlerCreated=1 DROP PROCEDURE dbo.USP_ContosoQueueWorkerNoop;
 THROW;
END CATCH;
IF USER_ID(N'ContosoQueueWorkerCaller') IS NOT NULL OR OBJECT_ID(N'dbo.USP_ContosoQueueWorkerNoop') IS NOT NULL
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='contoso.queue.worker.rights')
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker) OR @@TRANCOUNT<>0
 THROW 52093,N'Eigene Queue-Workerfixture nicht entfernt.',24;
PRINT N'Queue-Worker-Rechte: acht Profile,199 SQL229,vier Tokenabweisungen,ein leerer Claim und zwei befuellte Viewzustaende; eigene Fixture bereinigt.';
