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
 IF ISNULL(@Hilfe,0)=1 BEGIN SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_RequeueDeadLetter' AS sysname) ObjectName,CAST('DESCRIPTION' AS varchar(32)) Section,1 Ordinal,CAST(NULL AS sysname) ItemName,CAST(NULL AS varchar(256)) SqlDataType,CAST(NULL AS bit) IsRequired,CAST(NULL AS bit) IsNullable,CAST(NULL AS nvarchar(4000)) DefaultValue,CAST(N'Beginnt für ein Dead-Letter-Item einen neuen Retry-Zyklus.' AS nvarchar(max)) Description,CAST(NULL AS nvarchar(max)) ExampleSql; RETURN 0; END;
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 51993,N'USP_RequeueDeadLetter darf nicht innerhalb einer Caller-Transaktion ausgeführt werden.',1;
 IF @WorkItemId IS NULL OR @WorkItemId<=0 THROW 51990,N'@WorkItemId ist erforderlich.',1;
 IF @ResultTable IS NOT NULL THROW 51994,N'@ResultTable wird von dieser Version nicht unterstützt.',1;
 DECLARE @Now datetime2(7)=SYSUTCDATETIME(),@Mode varchar(16),@Group varchar(128),@Priority tinyint,@Epoch bigint;
 BEGIN TRANSACTION;
 BEGIN TRY
  SELECT SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
  SELECT @Mode=ExecutionMode,@Group=ExecutionGroup,@Priority=Priority,@Epoch=BarrierEpoch FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND Status='DEAD_LETTER' AND (@ExpectedRowVersion IS NULL OR RowVersion=@ExpectedRowVersion);
  IF @Mode IS NULL THROW 51991,N'Das Item ist nicht requeuebar.',1;
  SET @Epoch=CASE WHEN @Mode='DRAIN_BARRIER' THEN @Epoch+1 ELSE @Epoch END;
  UPDATE toolbelt_core.WorkItem SET Status=CASE WHEN @Mode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,RetryCycleNumber=RetryCycleNumber+1,CycleAttemptCount=0,NextAttemptAtUtc=NULL,BarrierEpoch=@Epoch,ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL,LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL,FailedAtUtc=NULL,FailedBy=NULL,FailureCode=NULL,FailureMessage=NULL,DeadLetteredAtUtc=NULL,DeadLetteredBy=NULL,LastRequeuedAtUtc=@Now,LastRequeuedBy=ORIGINAL_LOGIN(),LastRequeueReason=@RequeueReason WHERE WorkItemId=@WorkItemId;
  IF @Mode='DRAIN_BARRIER' INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration) SELECT @WorkItemId,@Epoch,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@Group AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
  COMMIT;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK; THROW; END CATCH;
 SELECT * FROM toolbelt_core.VW_WorkQueue WHERE WorkItemId=@WorkItemId;
END;
GO
