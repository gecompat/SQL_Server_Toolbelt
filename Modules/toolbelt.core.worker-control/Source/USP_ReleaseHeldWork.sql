-- Objekt: toolbelt_core.USP_ReleaseHeldWork
-- Zweck: Beginnt ausschließlich nach bewiesenem Rollback eine explizite neue Retryphase; UNKNOWN und COMPLETED bleiben gesperrt.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_ReleaseHeldWork
 @WorkItemId bigint=NULL,
 @ExpectedHoldVersion binary(8)=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ReleaseHeldWork' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Beginnt ausschließlich nach bewiesenem Rollback eine explizite neue Retryphase; UNKNOWN und COMPLETED bleiben gesperrt.',NULL),
 ('PARAMETER',1,N'@WorkItemId',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkItemId',NULL),
 ('PARAMETER',2,N'@ExpectedHoldVersion',N'binary(8)',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExpectedHoldVersion',NULL),
 ('PARAMETER',3,N'@ResultTable',N'sysname',0,1,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',4,N'@KeepData',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',5,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',6,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'WorkItemId',N'bigint',0,0,NULL,N'WorkItemId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'ClaimGeneration',N'bigint',0,0,NULL,N'ClaimGeneration gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'Status',N'varchar(16)',0,0,NULL,N'Status gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',4,N'HoldVersion',N'binary(8)',0,0,NULL,N'HoldVersion gemäß Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_ReleaseHeldWork @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 CREATE TABLE #tbx_USP_ReleaseHeldWork_Result(WorkItemId bigint NOT NULL,ClaimGeneration bigint NOT NULL,Status varchar(16) NOT NULL,HoldVersion binary(8) NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 DECLARE @SlotReservationId uniqueidentifier,@Generation bigint,@Version binary(8),@Held bit,@State varchar(24),@Occupied bit,@Mode varchar(16),@Group varchar(128),@Priority tinyint,@Epoch bigint;
 SELECT @SlotReservationId=SlotReservationId,@Version=HoldVersion,@Held=IsHeld FROM toolbelt_core.WorkerExecutionDisposition WITH(READPAST,READCOMMITTEDLOCK) WHERE WorkItemId=@WorkItemId;
 IF @Held<>1 OR @Held IS NULL OR @ExpectedHoldVersion IS NULL OR @ExpectedHoldVersion<>@Version THROW 54225,N'Der erwartete Hold fehlt oder ist veraltet.',1;
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@DispositionLock int;
 EXEC @DispositionLock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @DispositionLock<0 THROW 54222,N'Die Holdfreigabe wartet nicht unter globalem Gate auf einen Completionpfad.',3;
 SELECT @Held=IsHeld,@Version=HoldVersion FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND SlotReservationId=@SlotReservationId;
 IF @Held IS NULL OR @Held<>1 OR @Version<>@ExpectedHoldVersion THROW 54225,N'Der Hold hat sich seit Auswahl verändert.',4;
 SELECT @Generation=ClaimGeneration,@State=State,@Occupied=IsOccupied FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @State<>'ROLLED_BACK' OR @Occupied<>0 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId) THROW 54225,N'Ungeklärte oder committed Ausführung darf nicht freigegeben werden.',2;
 SELECT @Mode=ExecutionMode,@Group=ExecutionGroup,@Priority=Priority,@Epoch=BarrierEpoch FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@WorkItemId AND Status='FAILED' AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation;
 IF @Mode IS NULL THROW 54225,N'Der bewiesene Hold besitzt keinen unveränderten Queuezustand.',3;
 SET @Epoch=CASE WHEN @Mode='DRAIN_BARRIER' THEN @Epoch+1 ELSE @Epoch END;
 UPDATE toolbelt_core.WorkItem SET Status=CASE WHEN @Mode='DRAIN_BARRIER' THEN 'BARRIER_WAIT' ELSE 'QUEUED' END,RetryCycleNumber=RetryCycleNumber+1,CycleAttemptCount=0,NextAttemptAtUtc=NULL,BarrierEpoch=@Epoch,
 ClaimedAtUtc=NULL,ClaimedBy=NULL,ClaimToken=NULL,LeaseDurationSeconds=NULL,LeaseUntilUtc=NULL,LastHeartbeatAtUtc=NULL,FailedAtUtc=NULL,FailedBy=NULL,FailureCode=NULL,FailureMessage=NULL,DeadLetteredAtUtc=NULL,DeadLetteredBy=NULL,
 LastRequeuedAtUtc=SYSUTCDATETIME(),LastRequeuedBy=ORIGINAL_LOGIN(),LastRequeueReason=N'Explicit held-work release',ManagedReservationId=NULL,ManagedHold=0,ManagedCompletionNonce=NULL WHERE WorkItemId=@WorkItemId;
 IF @Mode='DRAIN_BARRIER' INSERT toolbelt_core.WorkQueueBarrierBlocker(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration) SELECT @WorkItemId,@Epoch,WorkItemId,ClaimGeneration FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' AND ExecutionGroup=@Group AND NOT(ExecutionMode='DRAIN_BARRIER' AND Priority=@Priority);
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=0,StopStatus='NONE' WHERE WorkItemId=@WorkItemId;
 INSERT #tbx_USP_ReleaseHeldWork_Result SELECT wi.WorkItemId,wi.ClaimGeneration,wi.Status,d.HoldVersion FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkerExecutionDisposition d ON d.WorkItemId=wi.WorkItemId WHERE wi.WorkItemId=@WorkItemId;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_ReleaseHeldWork_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkItemId,ClaimGeneration,Status,HoldVersion) SELECT WorkItemId,ClaimGeneration,Status,HoldVersion FROM #tbx_USP_ReleaseHeldWork_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkItemId,ClaimGeneration,Status,HoldVersion FROM #tbx_USP_ReleaseHeldWork_Result;
 RETURN 0;
END;
GO
