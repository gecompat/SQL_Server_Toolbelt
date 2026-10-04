-- Objekt: toolbelt_core.USP_ReserveWorkerExecution
-- Zweck: Reserviert global und lokal atomar genau einen kanonischen Queueclaim; keine zweite Claimauswahl.
-- Vertrag: WORKER_CONTROL_CONTRACT.md; vorhandene EXECUTE-Rechte, keine Grants.
-- Sichtbarkeit: internal; Version:1.0.0, SQL2019+/Windows/Linux.
-- Resultset und Parameter: explizit im gekoppelten Help definiert.
SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
CREATE OR ALTER PROCEDURE toolbelt_core.USP_ReserveWorkerExecution
 @WorkerId uniqueidentifier=NULL,
 @WorkerGeneration bigint=NULL,
 @WorkerToken uniqueidentifier=NULL,
 @ResultTable sysname=NULL,
 @KeepData bit=0,
 @Debug tinyint=0,
 @Hilfe bit=0
AS
BEGIN
 SET NOCOUNT ON; SET XACT_ABORT OFF;
 IF ISNULL(@Hilfe,0)=1 BEGIN
 SELECT CAST('1.0' AS varchar(16)) HelpContractVersion,CAST(N'toolbelt_core' AS sysname) SchemaName,CAST(N'USP_ReserveWorkerExecution' AS sysname) ObjectName,
 CAST(v.Section AS varchar(32)) Section,v.Ordinal,CAST(v.ItemName AS sysname) ItemName,CAST(v.SqlDataType AS varchar(256)) SqlDataType,CAST(v.IsRequired AS bit) IsRequired,CAST(v.IsNullable AS bit) IsNullable,CAST(v.DefaultValue AS nvarchar(4000)) DefaultValue,CAST(v.Description AS nvarchar(max)) Description,CAST(v.ExampleSql AS nvarchar(max)) ExampleSql
 FROM(VALUES ('DESCRIPTION',1,NULL,NULL,NULL,NULL,NULL,N'Reserviert global und lokal atomar genau einen kanonischen Queueclaim; keine zweite Claimauswahl.',NULL),
 ('PARAMETER',1,N'@WorkerId',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerId',NULL),
 ('PARAMETER',2,N'@WorkerGeneration',N'bigint',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerGeneration',NULL),
 ('PARAMETER',3,N'@WorkerToken',N'uniqueidentifier',1,0,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: WorkerToken',NULL),
 ('PARAMETER',4,N'@ResultTable',N'sysname',0,1,N'NULL',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: ResultTable',NULL),
 ('PARAMETER',5,N'@KeepData',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: KeepData',NULL),
 ('PARAMETER',6,N'@Debug',N'tinyint',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Debug',NULL),
 ('PARAMETER',7,N'@Hilfe',N'bit',0,0,N'0',N'Parameter gemäß verbindlichem Worker-Control-Vertrag: Hilfe',NULL),
 ('RESULT_COLUMN',1,N'WorkItemId',N'bigint',0,0,NULL,N'WorkItemId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',2,N'WorkTypeName',N'varchar(128)',0,0,NULL,N'WorkTypeName gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',3,N'PayloadJson',N'nvarchar(max)',0,1,NULL,N'PayloadJson gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',4,N'ClaimToken',N'uniqueidentifier',0,0,NULL,N'ClaimToken gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',5,N'ClaimedAtUtc',N'datetime2(7)',0,0,NULL,N'ClaimedAtUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',6,N'ClaimGeneration',N'bigint',0,0,NULL,N'ClaimGeneration gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',7,N'LeaseUntilUtc',N'datetime2(7)',0,0,NULL,N'LeaseUntilUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',8,N'LastHeartbeatAtUtc',N'datetime2(7)',0,0,NULL,N'LastHeartbeatAtUtc gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',9,N'SlotReservationId',N'uniqueidentifier',0,0,NULL,N'SlotReservationId gemäß Ergebnisvertrag.',NULL),
 ('RESULT_COLUMN',10,N'ExecutionId',N'uniqueidentifier',0,0,NULL,N'ExecutionId gemäß Ergebnisvertrag.',NULL),
 ('EXAMPLE',1,NULL,NULL,NULL,NULL,NULL,N'Synthetischer Help-Aufruf.',N'EXEC toolbelt_core.USP_ReserveWorkerExecution @Hilfe=1;'))v(Section,Ordinal,ItemName,SqlDataType,IsRequired,IsNullable,DefaultValue,Description,ExampleSql); RETURN 0; END;
 CREATE TABLE #tbx_USP_ReserveWorkerExecution_Result(WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,PayloadJson nvarchar(max) NULL,ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL,SlotReservationId uniqueidentifier NOT NULL,ExecutionId uniqueidentifier NOT NULL);
 IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54210,N'Workersteuerung verlangt eine eigene kurze Transaktion.',1;
 BEGIN TRANSACTION;
 BEGIN TRY
 DECLARE @GateId tinyint,@SchedulerId int,@Config binary(8);
 SELECT @GateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
 SELECT @SchedulerId=SchedulerId FROM toolbelt_core.WorkQueueScheduler WITH(UPDLOCK,HOLDLOCK) WHERE SchedulerId=1;
 SELECT @Config=ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WITH(UPDLOCK,HOLDLOCK) WHERE ConfigurationId=1;
 IF @GateId IS NULL OR @SchedulerId IS NULL OR @Config IS NULL THROW 54211,N'Der Worker-Control-Integrationsvertrag fehlt.',1;
 IF @WorkerId IS NULL OR @WorkerGeneration IS NULL OR @WorkerToken IS NULL OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WITH(UPDLOCK,HOLDLOCK) WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND WorkerToken=@WorkerToken AND OwnerPrincipalId=USER_ID() AND State<>'CLOSED') THROW 54215,N'Die Workergeneration besitzt keine gültige Autorität.',1;
 IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=1) THROW 54217,N'Managed-Betrieb ist nicht aktiviert.',2;
 DECLARE @Capacity int,@Global int,@CurrentSlots bigint,@TotalSlots bigint,@Paused bit,@WorkerState varchar(16),@Heartbeat datetime2(7),@Unreachable int;
 SELECT @Capacity=Capacity,@Paused=AdmissionPaused,@WorkerState=State,@Heartbeat=LastHeartbeatAtUtc,@Unreachable=UnreachableSeconds FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration;
 SELECT @Global=MaxConcurrentExecutions FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1;
 SELECT @CurrentSlots=COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE WorkerId=@WorkerId AND WorkerGeneration=@WorkerGeneration AND IsOccupied=1;
 SELECT @TotalSlots=COUNT_BIG(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1;
 IF @Paused=0 AND @WorkerState='ACTIVE' AND DATEADD(SECOND,@Unreachable,@Heartbeat)>SYSUTCDATETIME() AND @CurrentSlots<@Capacity AND @TotalSlots<@Global
 BEGIN
  DECLARE @Reservation uniqueidentifier=NEWID(),@Execution uniqueidentifier=NEWID(),@Admission uniqueidentifier=NEWID();
  CREATE TABLE #tbx_ManagedClaim(WorkItemId bigint NOT NULL,WorkTypeName varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,PayloadJson nvarchar(max) NULL,ClaimToken uniqueidentifier NOT NULL,ClaimedAtUtc datetime2(7) NOT NULL,ClaimGeneration bigint NOT NULL,LeaseUntilUtc datetime2(7) NOT NULL,LastHeartbeatAtUtc datetime2(7) NOT NULL);
  UPDATE toolbelt_core.WorkQueueManagedGate SET AdmissionToken=@Admission,PendingReservationId=@Reservation WHERE GateId=1;
  DECLARE @CanonicalClaimId bigint;
  EXEC toolbelt_core.USP_ClaimWorkCore @ManagedAdmissionToken=@Admission,@ManagedReservationId=@Reservation,@ClaimedWorkItemId=@CanonicalClaimId OUTPUT,@EmitResult=0;
  -- Fester interner Transport: kein öffentlicher ResultTable-Name und kein INSERT EXEC.
  INSERT #tbx_ManagedClaim(WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc)
  SELECT wi.WorkItemId,wt.WorkTypeName,wi.PayloadJson,wi.ClaimToken,wi.ClaimedAtUtc,wi.ClaimGeneration,wi.LeaseUntilUtc,wi.LastHeartbeatAtUtc
  FROM toolbelt_core.WorkItem wi JOIN toolbelt_core.WorkType wt ON wt.WorkTypeId=wi.WorkTypeId
  WHERE wi.WorkItemId=@CanonicalClaimId AND wi.ManagedReservationId=@Reservation AND wi.Status='CLAIMED';
  IF @CanonicalClaimId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM #tbx_ManagedClaim) THROW 54218,N'Der kanonische Claimtransport besitzt keine exakte Reservationbindung.',1;
  IF EXISTS(SELECT 1 FROM #tbx_ManagedClaim)
  BEGIN
   INSERT toolbelt_core.WorkerSlotReservation(SlotReservationId,WorkerId,WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,ExecutionId,State,IsOccupied,CreatedAtUtc)
   SELECT @Reservation,@WorkerId,@WorkerGeneration,WorkItemId,ClaimGeneration,ClaimToken,@Execution,'RESERVED',1,SYSUTCDATETIME() FROM #tbx_ManagedClaim;
   DECLARE @Item bigint; SELECT @Item=WorkItemId FROM #tbx_ManagedClaim;
   IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE WorkItemId=@Item)
    UPDATE toolbelt_core.WorkerExecutionDisposition SET SlotReservationId=@Reservation,StopStatus='NONE' WHERE WorkItemId=@Item AND IsHeld=0;
   ELSE INSERT toolbelt_core.WorkerExecutionDisposition(WorkItemId,SlotReservationId,IsHeld,StopStatus) VALUES(@Item,@Reservation,0,'NONE');
   INSERT #tbx_USP_ReserveWorkerExecution_Result SELECT WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc,@Reservation,@Execution FROM #tbx_ManagedClaim;
  END;
 END;
 IF @ResultTable IS NOT NULL BEGIN
 EXEC toolbelt_core.USP_PrepareResultTable @ResultTableToAlter=@ResultTable,@LikeTable=N'#tbx_USP_ReserveWorkerExecution_Result',@KeepData=@KeepData;
 DECLARE @PublishSql nvarchar(max)=N'INSERT INTO '+QUOTENAME(@ResultTable)+N'(WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc,SlotReservationId,ExecutionId) SELECT WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc,SlotReservationId,ExecutionId FROM #tbx_USP_ReserveWorkerExecution_Result'; EXEC sys.sp_executesql @PublishSql; END;
 COMMIT TRANSACTION;
 END TRY BEGIN CATCH IF XACT_STATE()<>0 ROLLBACK TRANSACTION; THROW; END CATCH;
 IF @ResultTable IS NULL SELECT WorkItemId,WorkTypeName,PayloadJson,ClaimToken,ClaimedAtUtc,ClaimGeneration,LeaseUntilUtc,LastHeartbeatAtUtc,SlotReservationId,ExecutionId FROM #tbx_USP_ReserveWorkerExecution_Result;
 RETURN 0;
END;
GO
