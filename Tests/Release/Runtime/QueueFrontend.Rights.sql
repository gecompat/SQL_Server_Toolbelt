SET NOCOUNT ON;
SET XACT_ABORT OFF;
SET ANSI_NULL_DFLT_ON ON;
DECLARE @Owner nvarchar(32)=(SELECT CONVERT(nvarchar(32),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Test.Release.Owner');
IF @Owner IS NULL OR LEN(@Owner)<>32 OR @Owner COLLATE Latin1_General_100_BIN2 LIKE N'%[^a-f0-9]%'
 OR DB_NAME() NOT IN(N'Toolbelt_Release_'+@Owner+N'_l',N'Toolbelt_Release_'+@Owner+N'_c') OR @@TRANCOUNT<>0
 THROW 52095,N'Markierter eigener frischer Queue-Frontend-Testscope erforderlich.',1;
IF USER_ID(N'ContosoQueueFrontendCaller') IS NOT NULL OR OBJECT_ID(N'dbo.USP_ContosoQueueRightsNoop') IS NOT NULL
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='contoso.queue.rights')
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker)
 THROW 52095,N'Vorhandene Queuefixture wird nicht uebernommen.',2;
DECLARE @Apis table(Id int PRIMARY KEY,Name sysname,PermissionName varchar(16),SqlText nvarchar(max),Probe nvarchar(max));
INSERT @Apis VALUES
 (1,N'toolbelt_core.USP_EnqueueWork','EXECUTE',N'EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName=''contoso.queue.rights'';',N'EXEC toolbelt_core.USP_EnqueueWork @Hilfe=1;'),
 (2,N'toolbelt_core.USP_EnqueueWorkWithPolicy','EXECUTE',N'EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @WorkTypeName=''contoso.queue.rights'',@IdempotencyKey=''ContosoPolicy'',@Priority=4,@ExecutionGroup=''ContosoRights'',@MaxAttempts=2,@RetryBaseDelaySeconds=1,@RetryMaxDelaySeconds=2;',N'EXEC toolbelt_core.USP_EnqueueWorkWithPolicy @Hilfe=1;'),
 (3,N'toolbelt_core.USP_EnqueueBarrierWork','EXECUTE',N'EXEC toolbelt_core.USP_EnqueueBarrierWork @WorkTypeName=''contoso.queue.rights'',@ExecutionGroup=''ContosoRights'',@Priority=4,@IdempotencyKey=''ContosoBarrier'';',N'EXEC toolbelt_core.USP_EnqueueBarrierWork @Hilfe=1;'),
 (4,N'toolbelt_core.USP_GetWorkStatus','EXECUTE',N'
  DECLARE @Rows table(WorkItemId bigint NULL,WorkTypeName varchar(128) NULL,Status varchar(16) NULL,EnqueuedAtUtc datetime2(7) NULL,EnqueuedBy sysname NULL,
   ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname NULL,
   FailureCode varchar(64) NULL,FailureMessage nvarchar(1000) NULL,RowVersion binary(8) NULL,ClaimGeneration bigint NULL,LeaseDurationSeconds int NULL,
   LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,IsLeaseExpired bit NULL,RecoveryCount bigint NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname NULL);
  INSERT @Rows EXEC toolbelt_core.USP_GetWorkStatus @WorkItemId=@SeedId;
  IF (SELECT COUNT(*) FROM @Rows)<>1 OR NOT EXISTS(SELECT 1 FROM @Rows WHERE WorkItemId=@SeedId AND WorkTypeName=''contoso.queue.rights'' AND Status=''QUEUED''
   AND EnqueuedAtUtc IS NOT NULL AND RowVersion IS NOT NULL AND ClaimGeneration=0 AND IsLeaseExpired=0 AND ClaimedAtUtc IS NULL AND LeaseUntilUtc IS NULL)
   THROW 52095,N''GetWorkStatus-Festwert verletzt.'',3;',N'EXEC toolbelt_core.USP_GetWorkStatus @Hilfe=1;'),
 (5,N'toolbelt_core.VW_WorkQueue','SELECT',N'
  IF (SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueue)<>1
   OR NOT EXISTS(SELECT 1 FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@SeedId AND WorkTypeName=''contoso.queue.rights'' AND Status=''QUEUED'' AND ExecutionMode=''SHARED'')
   OR EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N''toolbelt_core.VW_WorkQueue'') AND name IN(N''PayloadJson'',N''ClaimToken''))
   THROW 52095,N''Queue-View-Wert oder geschuetzte Spalten verletzt.'',4;',N'SELECT TOP(0) * FROM toolbelt_core.VW_WorkQueue;'),
 (6,N'toolbelt_core.VW_WorkQueueBarrierBlockers','SELECT',N'
  IF (SELECT COUNT(*) FROM toolbelt_core.VW_WorkQueueBarrierBlockers)<>0
   OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N''toolbelt_core.VW_WorkQueueBarrierBlockers''))<>6
   OR EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N''toolbelt_core.VW_WorkQueueBarrierBlockers'') AND name IN(N''PayloadJson'',N''ClaimToken''))
   THROW 52095,N''Leere Blocker-View oder geschuetzte Spalten verletzt.'',5;',N'SELECT TOP(0) * FROM toolbelt_core.VW_WorkQueueBarrierBlockers;'),
 (7,N'toolbelt_core.USP_ClaimWork','EXECUTE',NULL,N'EXEC toolbelt_core.USP_ClaimWork @Hilfe=1;'),
 (8,N'toolbelt_core.USP_RenewWorkLease','EXECUTE',NULL,N'EXEC toolbelt_core.USP_RenewWorkLease @Hilfe=1;'),
 (9,N'toolbelt_core.USP_RecoverExpiredWork','EXECUTE',NULL,N'EXEC toolbelt_core.USP_RecoverExpiredWork @Hilfe=1;'),
 (10,N'toolbelt_core.USP_CompleteWork','EXECUTE',NULL,N'EXEC toolbelt_core.USP_CompleteWork @Hilfe=1;'),
 (11,N'toolbelt_core.USP_FailWork','EXECUTE',NULL,N'EXEC toolbelt_core.USP_FailWork @Hilfe=1;'),
 (12,N'toolbelt_core.USP_ScheduleWorkRetry','EXECUTE',NULL,N'EXEC toolbelt_core.USP_ScheduleWorkRetry @Hilfe=1;'),
 (13,N'toolbelt_core.USP_RequeueDeadLetter','EXECUTE',NULL,N'EXEC toolbelt_core.USP_RequeueDeadLetter @Hilfe=1;'),
 (14,N'toolbelt_core.USP_ClaimWorkCore','EXECUTE',NULL,N'EXEC toolbelt_core.USP_ClaimWorkCore @Hilfe=1;'),
 (15,N'toolbelt_core.USP_FailWorkCore','EXECUTE',NULL,N'EXEC toolbelt_core.USP_FailWorkCore @Hilfe=1;'),
 (16,N'toolbelt_core.USP_ScheduleWorkRetryCore','EXECUTE',NULL,N'EXEC toolbelt_core.USP_ScheduleWorkRetryCore @Hilfe=1;'),
 (17,N'toolbelt_core.WorkItem','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkItem;'),
 (18,N'toolbelt_core.WorkQueueScheduler','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkQueueScheduler;'),
 (19,N'toolbelt_core.WorkQueueBarrierBlocker','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkQueueBarrierBlocker;'),
 (20,N'toolbelt_core.WorkQueueManagedGate','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkQueueManagedGate;'),
 (21,N'toolbelt_core.USP_PrepareResultTable','EXECUTE',NULL,N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;'),
 (22,N'toolbelt_core.USP_RegisterWorkType','EXECUTE',NULL,N'EXEC toolbelt_core.USP_RegisterWorkType @Hilfe=1;'),
 (23,N'toolbelt_core.WorkType','SELECT',NULL,N'SELECT TOP(0) * FROM toolbelt_core.WorkType;');
DECLARE @Profile int=1,@Phase int,@Other int,@Name sysname,@Permission varchar(16),@Sql nvarchar(max),@Grant nvarchar(max),@Probe nvarchar(max),
 @Caught bit,@Created bit=0,@HandlerCreated bit=0,@Impersonated bit=0,@Positive int=0,@Denied int=0,@MetadataDenied int=0,@TypeId bigint,@SeedId bigint,
 @ExpectedStatus varchar(16),@ExpectedMode varchar(16);
BEGIN TRY
 EXEC sys.sp_executesql N'CREATE PROCEDURE dbo.USP_ContosoQueueRightsNoop AS RETURN 0;'; SET @HandlerCreated=1;
 EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='contoso.queue.rights',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_ContosoQueueRightsNoop';
 SELECT @TypeId=WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='contoso.queue.rights';
 IF @TypeId IS NULL THROW 52095,N'Eigener Work Type fehlt.',6;
 CREATE USER ContosoQueueFrontendCaller WITHOUT LOGIN; SET @Created=1;
 EXEC toolbelt_core.USP_SetWorkTypePermission 'contoso.queue.rights',N'ContosoQueueFrontendCaller','ENQUEUE','ALLOW';
 WHILE @Profile<=6
 BEGIN
  SELECT @Name=Name,@Permission=PermissionName,@Sql=SqlText FROM @Apis WHERE Id=@Profile;
  SET @Phase=0;
  WHILE @Phase<=2
  BEGIN
   SET @SeedId=NULL;
   IF @Profile>=4
   BEGIN
    INSERT toolbelt_core.WorkItem(WorkTypeId) VALUES(@TypeId); SET @SeedId=CONVERT(bigint,SCOPE_IDENTITY());
   END;
   SET @Grant=CASE @Phase WHEN 1 THEN N'GRANT '+@Permission+N' ON OBJECT::'+@Name+N' TO ContosoQueueFrontendCaller;'
    WHEN 2 THEN N'REVOKE '+@Permission+N' ON OBJECT::'+@Name+N' FROM ContosoQueueFrontendCaller;' END;
   IF @Grant IS NOT NULL EXEC sys.sp_executesql @Grant;
   IF @Profile=1 AND @Phase=2 REVOKE VIEW DEFINITION ON OBJECT::dbo.USP_ContosoQueueRightsNoop FROM ContosoQueueFrontendCaller;
   EXECUTE AS USER=N'ContosoQueueFrontendCaller'; SET @Impersonated=1;
   IF ISNULL(IS_MEMBER(N'db_owner'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datareader'),0)<>0 OR ISNULL(IS_MEMBER(N'db_datawriter'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CONTROL'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'EXECUTE'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'SELECT'),0)<>0
    OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.USP_ContosoQueueRightsNoop',N'OBJECT',N'EXECUTE'),0)<>0
    THROW 52095,N'Unerwartete breite Queue-Frontend-Rechte.',7;
   IF EXISTS(SELECT 1 FROM @Apis WHERE ISNULL(HAS_PERMS_BY_NAME(Name,N'OBJECT',PermissionName),0)<>CASE WHEN @Phase=1 AND Id=@Profile THEN 1 ELSE 0 END)
    OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.USP_ContosoQueueRightsNoop',N'OBJECT',N'VIEW DEFINITION'),0)<>0
    THROW 52095,N'Nicht exakt das einzelne Queue-Frontend-Objektrecht.',8;
   IF @Profile=1 AND @Phase=1
   BEGIN
    SET @Caught=0;
    BEGIN TRY EXEC sys.sp_executesql @Sql; END TRY
    BEGIN CATCH IF ERROR_NUMBER()<>51902 THROW; SET @Caught=1; SET @MetadataDenied+=1; END CATCH;
    IF @Caught=0 THROW 52095,N'Legacyproducer ohne Handler-Metadatensicht wurde zugelassen.',17;
    REVERT; SET @Impersonated=0;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId)
     THROW 52095,N'Abgewiesener Metadatenvorlauf veraenderte Daten.',18;
    GRANT VIEW DEFINITION ON OBJECT::dbo.USP_ContosoQueueRightsNoop TO ContosoQueueFrontendCaller;
    EXECUTE AS USER=N'ContosoQueueFrontendCaller'; SET @Impersonated=1;
    IF ISNULL(HAS_PERMS_BY_NAME(N'dbo.USP_ContosoQueueRightsNoop',N'OBJECT',N'VIEW DEFINITION'),0)<>1
     OR ISNULL(HAS_PERMS_BY_NAME(N'dbo.USP_ContosoQueueRightsNoop',N'OBJECT',N'EXECUTE'),0)<>0
     THROW 52095,N'Legacyproducer braucht nur Metadatensicht, kein Handler-EXECUTE.',19;
   END;
   SET @Caught=0;
   BEGIN TRY EXEC sys.sp_executesql @Sql,N'@SeedId bigint',@SeedId; END TRY
   BEGIN CATCH IF @Phase=1 OR ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
   IF @Phase<>1 AND @Caught=0 THROW 52095,N'Fehlendes Queue-Frontend-Recht wurde zugelassen.',9;
   IF @Phase=1
   BEGIN
    SET @Positive+=1;
    SET @Other=1;
    WHILE @Other<=23
    BEGIN
     IF @Other<>@Profile
     BEGIN
      SELECT @Probe=Probe FROM @Apis WHERE Id=@Other; SET @Caught=0;
      BEGIN TRY EXEC sys.sp_executesql @Probe; END TRY
      BEGIN CATCH IF ERROR_NUMBER()<>229 THROW; SET @Caught=1; SET @Denied+=1; END CATCH;
      IF @Caught=0 THROW 52095,N'Fremdes Queue-API oder interner Zustand war zugaenglich.',10;
     END;
     SET @Other+=1;
    END;
   END;
   REVERT; SET @Impersonated=0;
   IF @Profile<=3 AND @Phase=1
   BEGIN
    SET @ExpectedStatus=CASE WHEN @Profile=3 THEN 'BARRIER_WAIT' ELSE 'QUEUED' END;
    SET @ExpectedMode=CASE WHEN @Profile=3 THEN 'DRAIN_BARRIER' ELSE 'SHARED' END;
    IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId)<>1
     OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId AND Status=@ExpectedStatus AND ExecutionMode=@ExpectedMode
      AND PayloadJson IS NULL AND ClaimToken IS NULL AND ClaimGeneration=0)
     THROW 52095,N'Persistiertes Producer-Festwertorakel verletzt.',11;
    IF @Profile=2 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId AND IdempotencyKey='ContosoPolicy' AND Priority=4
     AND ExecutionGroup='ContosoRights' AND MaxAttempts=2 AND RetryBaseDelaySeconds=1 AND RetryMaxDelaySeconds=2)
     THROW 52095,N'Persistierte Producer-Policy verletzt.',12;
    IF @Profile=3 AND NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId AND IdempotencyKey='ContosoBarrier' AND BarrierEpoch=1)
     THROW 52095,N'Persistierte Barrier-Metadaten verletzt.',13;
   END;
   IF @Profile<=3 AND @Phase<>1 AND EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId)
    THROW 52095,N'Abgewiesenes Producer-API veraenderte Daten.',14;
   DELETE toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId;
   SET @Phase+=1;
  END;
  SET @Profile+=1;
 END;
 IF @Positive<>6 OR @Denied<>144 OR @MetadataDenied<>1 THROW 52095,N'Unvollstaendige Queue-Frontend-Probenzahl.',15;
 DELETE toolbelt_core.WorkTypePermission WHERE WorkTypeId=@TypeId;
 DELETE toolbelt_core.WorkType WHERE WorkTypeId=@TypeId;
 DROP USER ContosoQueueFrontendCaller; SET @Created=0;
 DROP PROCEDURE dbo.USP_ContosoQueueRightsNoop; SET @HandlerCreated=0;
END TRY
BEGIN CATCH
 IF @Impersonated=1 REVERT;
 IF XACT_STATE()<>0 ROLLBACK;
 SELECT @TypeId=WorkTypeId FROM toolbelt_core.WorkType WHERE WorkTypeName='contoso.queue.rights';
 DELETE toolbelt_core.WorkQueueBarrierBlocker WHERE BarrierWorkItemId IN(SELECT WorkItemId FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId)
  OR BlockingWorkItemId IN(SELECT WorkItemId FROM toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId);
 DELETE toolbelt_core.WorkItem WHERE WorkTypeId=@TypeId;
 DELETE toolbelt_core.WorkTypePermission WHERE WorkTypeId=@TypeId;
 DELETE toolbelt_core.WorkType WHERE WorkTypeId=@TypeId;
 IF @Created=1 DROP USER ContosoQueueFrontendCaller;
 IF @HandlerCreated=1 DROP PROCEDURE dbo.USP_ContosoQueueRightsNoop;
 THROW;
END CATCH;
IF USER_ID(N'ContosoQueueFrontendCaller') IS NOT NULL OR OBJECT_ID(N'dbo.USP_ContosoQueueRightsNoop') IS NOT NULL
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='contoso.queue.rights') OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker) OR @@TRANCOUNT<>0
 THROW 52095,N'Eigene Queue-Frontendfixture nicht entfernt.',16;
PRINT N'Queue-Frontend-Rechte: fuenf Einzelgrants, Legacyproducer mit Handler-Metadatensicht, 144 SQL229 und eine SQL51902-Abweisung; eigene Fixture bereinigt.';
