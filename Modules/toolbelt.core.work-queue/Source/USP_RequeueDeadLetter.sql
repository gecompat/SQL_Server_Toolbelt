SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE [toolbelt_core].[USP_RequeueDeadLetter]
      @WorkItemId bigint=NULL,@ExpectedRowVersion binary(8)=NULL,@RequeueReason nvarchar(1000)=NULL,
      @ResultTable sysname=NULL,@KeepData bit=0,@Debug tinyint=0,@Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1
 BEGIN
  DECLARE @Help TABLE(HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL);
  INSERT @Help VALUES
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus. Callertransaktionen sind nicht erlaubt; verwaltete/gehaltene Arbeit benötigt den geschützten Freigabepfad.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','PARAMETER',1,N'@WorkItemId','bigint',1,0,N'NULL',N'Positive ID eines Dead-Letter-Items.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','PARAMETER',2,N'@ExpectedRowVersion','binary(8)',0,1,N'NULL',N'Optionaler Compare-and-swap-Schutz.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','PARAMETER',3,N'@RequeueReason','nvarchar(1000)',0,1,N'NULL',N'Optionale fachliche Begründung.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','PARAMETER',4,N'@ResultTable','sysname',0,1,N'NULL',N'Optionaler lokaler Temp-Tabellenname für die aktualisierte Queue-Statuszeile.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','PARAMETER',5,N'@KeepData','bit',0,0,N'0',N'Bei ResultTable-Routing bleiben vorhandene Zielzeilen erhalten, wenn 1.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','PARAMETER',6,N'@Debug','tinyint',0,0,N'0',N'Beim ResultTable-Routing Diagnosemeldungen des kanonischen Helpers; keine zusätzlichen fachlichen Resultsets.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','PARAMETER',7,N'@Hilfe','bit',0,0,N'0',N'1 gibt ausschließlich diese Hilfe aus.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','ERROR',1,N'51908,51990-51993',NULL,NULL,NULL,NULL,N'Fehlende ResultTable-Dependency, ungültige ID, nicht requeuebarer Zustand oder Callertransaktion.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','PERMISSION',1,NULL,NULL,NULL,NULL,NULL,N'EXECUTE und die vorgesehenen Queue-Autorisierungen; für @ResultTable zusätzlich EXECUTE auf USP_PrepareResultTable.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','LIMITATION',1,NULL,NULL,NULL,NULL,NULL,N'Bei Fehlern entsteht keine fachliche Statuszeile. Managed-Holds benötigen den geschützten Freigabepfad.',NULL),
  ('1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Requeue eines Dead-Letter-Items mit Rowversion-Schutz.',N'EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=42,@ExpectedRowVersion=0x0000000000000001;');
  INSERT @Help
  SELECT '1.0',N'toolbelt_core',N'USP_RequeueDeadLetter','RESULT_COLUMN',ROW_NUMBER() OVER(ORDER BY c.column_id),c.name,TYPE_NAME(c.user_type_id),1,c.is_nullable,NULL,N'Wert aus toolbelt_core.VW_WorkQueue.',NULL
  FROM sys.columns AS c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.VW_WorkQueue',N'V');
  SELECT HelpContractVersion,SchemaName,ObjectName,Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql
  FROM @Help ORDER BY CASE Section WHEN 'DESCRIPTION' THEN 0 WHEN 'PARAMETER' THEN 1 WHEN 'RESULT_COLUMN' THEN 2 ELSE 3 END,Ordinal;
  RETURN 0;
 END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51993,N'USP_RequeueDeadLetter darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@WorkItemId AND (ManagedHold=1 OR ManagedReservationId IS NOT NULL))
        THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Abschluss-/Freigabepfad.',1;
 IF @WorkItemId IS NULL OR @WorkItemId<=0 THROW 51990,N'@WorkItemId ist erforderlich.',1;
 DECLARE @Now datetime2(7)=SYSUTCDATETIME(),@Mode varchar(16),@Group varchar(128),@Priority tinyint,@Epoch bigint,@InsertResultSql nvarchar(max);
 SELECT TOP (0) v.* INTO #tbx_WorkQueue_RequeueResult FROM toolbelt_core.VW_WorkQueue AS v;
 BEGIN TRANSACTION;
 BEGIN TRY
  IF @ResultTable IS NOT NULL
  BEGIN
   IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 51908,N'Für @ResultTable fehlt toolbelt.core.result-table.',1;
   EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_WorkQueue_RequeueResult',@KeepData=@KeepData,@Debug=@Debug;
  END;
  DECLARE @SchedulerId tinyint; SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
  SELECT @Mode=ExecutionMode,@Group=ExecutionGroup,@Priority=Priority,@Epoch=BarrierEpoch FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND Status='DEAD_LETTER' AND (@ExpectedRowVersion IS NULL OR RowVersion=@ExpectedRowVersion);
  IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND (ManagedHold=1 OR ManagedReservationId IS NOT NULL)) THROW 54201,N'Gehaltene oder verwaltete Arbeit verlangt den geschützten Freigabepfad.',2;
  IF @Mode IS NULL THROW 51991,N'Das Item ist nicht requeuebar.',1;
  SET @Epoch=CASE WHEN @Mode='DRAIN_BARRIER' THEN @Epoch+1 ELSE @Epoch END;
  UPDATE toolbelt_core.WorkItem SET Status=CASE WHEN @Mode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,RetryCycleNumber=RetryCycleNumber+1,CycleAttemptCount=0,NextAttemptAtUtc=NULL,BarrierEpoch=@Epoch,ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL,LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL,FailedAtUtc=NULL,FailedBy=NULL,FailureCode=NULL,FailureMessage=NULL,DeadLetteredAtUtc=NULL,DeadLetteredBy=NULL,LastRequeuedAtUtc=@Now,LastRequeuedBy=ORIGINAL_LOGIN(),LastRequeueReason=@RequeueReason WHERE WorkItemId=@WorkItemId;
  IF @Mode='DRAIN_BARRIER' INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration) SELECT @WorkItemId,@Epoch,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@Group AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
  IF @ResultTable IS NOT NULL
  BEGIN
   INSERT #tbx_WorkQueue_RequeueResult SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
   SET @InsertResultSql=N'INSERT INTO '+QUOTENAME(@ResultTable)+N' SELECT * FROM #tbx_WorkQueue_RequeueResult;';
   EXEC sys.sp_executesql @InsertResultSql;
  END;
  COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
END;
GO
