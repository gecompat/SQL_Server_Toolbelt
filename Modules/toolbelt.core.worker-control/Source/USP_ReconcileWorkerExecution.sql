-- Objekt: toolbelt_core.USP_ReconcileWorkerExecution
-- Zweck: Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: public; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_ReconcileWorkerExecution
 @SlotReservationId uniqueidentifier=NULL,
 @ExpectedHoldVersion binary(8)=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ReconcileWorkerExecution' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Prüft actual Sessionfence und exakten locking Commitwitness; CAS und LateDispatchfence erhalten UNKNOWN ohne Replay.',NULL),
 ('PARAMETER',1,N'@SlotReservationId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: SlotReservationId',NULL),
 ('PARAMETER',2,N'@ExpectedHoldVersion',N'binary(8)',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ExpectedHoldVersion',NULL),
 ('PARAMETER',3,N'@ResultTable',N'sysname',0,1,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',4,N'@KeepData',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',5,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',6,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'SlotReservationId',N'uniqueidentifier',0,0,NULL,N'SlotReservationId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'Outcome',N'varchar(24)',0,0,NULL,N'Outcome gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'Occupied',N'bit',0,0,NULL,N'Occupied gemäß Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_ReconcileWorkerExecution @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 CREATE TABLE #tbx_USP_ReconcileWorkerExecution_Result(SlotReservationId uniqueidentifier NOT NULL,Outcome varchar(24) NOT NULL,Occupied bit NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @OwnSessionLock bit=0;
 -- Prozedurscope: SQL Server restauriert SET-Optionen bei Return/THROW.
 -- Kein dynamisches SET kann den Aufruferkontext restaurieren.
 SET LOCK_TIMEOUT 5000;
 DECLARE @AttemptResource nvarchar(255)=N'Toolbelt.Worker.Attempt.'+CONVERT(nvarchar(36),@SlotReservationId),@SessionLock int,@Item bigint,@Execution uniqueidentifier,@Generation bigint,@Nonce uniqueidentifier,@HoldVersion binary(8),@Held bit,@Occupied bit,@State varchar(24),@Outcome varchar(24),@WitnessExists bit=0,@WitnessMatches bit=0;
 IF @SlotReservationId IS NULL OR @ExpectedHoldVersion IS NULL THROW 54227,N'Reconcile verlangt exakte Reservation und Holdversion.',1;
 EXEC @SessionLock=sys.sp_getapplock @Resource=@AttemptResource,@LockMode=N'Exclusive',@LockOwner=N'Session',@LockTimeout=0,@DbPrincipal=N'public';
 IF @SessionLock<0 INSERT #tbx_USP_ReconcileWorkerExecution_Result VALUES(@SlotReservationId,'UNKNOWN',1);
 ELSE
 BEGIN
 SET @OwnSessionLock=1;
 DECLARE @DispositionResource nvarchar(255)=N'Toolbelt.Worker.Disposition.'+CONVERT(nvarchar(36),@SlotReservationId),@DispositionLock int;
 EXEC @DispositionLock=sys.sp_getapplock @Resource=@DispositionResource,@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @DispositionLock<0 INSERT #tbx_USP_ReconcileWorkerExecution_Result VALUES(@SlotReservationId,'UNKNOWN',1);
 ELSE
 BEGIN
 -- Nach beiden Gates sämtliche attemptgebundenen Fakten frisch einlesen; keine
 -- vor dem Lock eingefrorene Holdversion kann einen parallelen Stop überholen.
 SELECT @Item=WorkItemId,@Execution=ExecutionId,@Generation=ClaimGeneration,@Nonce=AttemptNonce,@Occupied=IsOccupied,@State=State FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 SELECT @HoldVersion=HoldVersion,@Held=IsHeld FROM toolbelt_core.WorkerExecutionDisposition WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId;
 IF @Item IS NULL OR @HoldVersion<>@ExpectedHoldVersion OR @HoldVersion IS NULL THROW 54227,N'Die exakte aktuelle Disposition fehlt oder ist veraltet.',2;
 BEGIN TRY
 -- SERIALIZABLE-HOLDLOCK erzwingt auch unter RCSI echten Witness-/Absence-Range-Lock;
 -- READCOMMITTEDLOCK wäre ein widersprechender Isolationshint (SQL1047).
 IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(UPDLOCK,HOLDLOCK) WHERE SlotReservationId=@SlotReservationId) SET @WitnessExists=1;
 IF @WitnessExists=1 AND EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness WHERE SlotReservationId=@SlotReservationId AND AttemptNonce=@Nonce AND ExecutionId=@Execution AND ClaimGeneration=@Generation) SET @WitnessMatches=1;
IF @Occupied=0 AND @State IN('COMMITTED','ROLLED_BACK','CLOSED')
 BEGIN
 SET @Outcome=CASE WHEN @State='COMMITTED' THEN 'COMMITTED' WHEN @Held=1 THEN 'ROLLED_BACK_HELD' ELSE 'ROLLED_BACK' END;
 END
 ELSE  IF @WitnessMatches=1 AND EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WITH(UPDLOCK,HOLDLOCK) WHERE WorkItemId=@Item AND Status='COMPLETED' AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation)
 BEGIN
 UPDATE toolbelt_core.WorkerSlotReservation SET State='COMMITTED',IsOccupied=0,EndedAtUtc=ISNULL(EndedAtUtc,SYSUTCDATETIME()) WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=0,StopStatus='ALREADY_COMMITTED' WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkItem SET ManagedHold=0 WHERE WorkItemId=@Item AND Status='COMPLETED';
 SET @Outcome='COMMITTED';SET @Occupied=0;
 END
 ELSE IF @WitnessExists=0 AND @Held=1 AND @State IN('STOP_REQUESTED','STOPPING','UNKNOWN','ROLLED_BACK')
 BEGIN
 IF NOT(@State='ROLLED_BACK' AND @Occupied=0 AND EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@Item AND Status='FAILED' AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND ManagedHold=1))
 BEGIN
 UPDATE toolbelt_core.WorkItem SET Status='FAILED',FailedAtUtc=SYSUTCDATETIME(),FailedBy=ORIGINAL_LOGIN(),FailureCode='WORKER.STOP_HELD',FailureMessage=NULL,ManagedHold=1,ManagedCompletionNonce=NULL WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId AND ClaimGeneration=@Generation AND Status='CLAIMED';
 IF @@ROWCOUNT<>1 THROW 54227,N'Kein unveränderter Queueclaim für den Rollbacknachweis.',3;
 END;
 UPDATE toolbelt_core.WorkerSlotReservation SET State='ROLLED_BACK',IsOccupied=0,EndedAtUtc=ISNULL(EndedAtUtc,SYSUTCDATETIME()) WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus='ROLLED_BACK_HELD' WHERE SlotReservationId=@SlotReservationId;
 SET @Outcome='ROLLED_BACK_HELD';SET @Occupied=0;
 END
 ELSE
 BEGIN
 UPDATE toolbelt_core.WorkerSlotReservation SET State='UNKNOWN',IsOccupied=1,EndedAtUtc=NULL WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkerExecutionDisposition SET IsHeld=1,StopStatus='UNKNOWN' WHERE SlotReservationId=@SlotReservationId;
 UPDATE toolbelt_core.WorkItem SET ManagedHold=1 WHERE WorkItemId=@Item AND ManagedReservationId=@SlotReservationId;
 SET @Outcome='UNKNOWN';SET @Occupied=1;
 END;
 INSERT #tbx_USP_ReconcileWorkerExecution_Result VALUES(@SlotReservationId,@Outcome,@Occupied);
 END TRY BEGIN CATCH
 IF ERROR_NUMBER()=1222 AND XACT_STATE()=1 INSERT #tbx_USP_ReconcileWorkerExecution_Result VALUES(@SlotReservationId,'UNKNOWN',1);
 ELSE THROW;
 END CATCH;
 END;
 END;

 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_ReconcileWorkerExecution_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(SlotReservationId,Outcome,Occupied) SELECT SlotReservationId,Outcome,Occupied FROM #tbx_USP_ReconcileWorkerExecution_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 IF @OwnSessionLock=1 EXEC sys.sp_releaseapplock @Resource=@AttemptResource,@LockOwner=N'Session',@DbPrincipal=N'public';

 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; IF @OwnSessionLock=1 EXEC sys.sp_releaseapplock @Resource=@AttemptResource,@LockOwner=N'Session',@DbPrincipal=N'public';  THROW; END CATCH;
 IF @ResultTable IS NULL SELECT SlotReservationId,Outcome,Occupied FROM #tbx_USP_ReconcileWorkerExecution_Result;
 RETURN 0;
END;
GO
