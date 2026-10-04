:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT OFF;
-- Nur auf einer isolierten, vollständig installierten Testdatenbank ausführen.
CREATE TABLE #ExpectedWorkerViews(ViewName sysname COLLATE Latin1_General_100_BIN2,Ordinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2,TypeId tinyint,MaxLength smallint,Scale tinyint,Nullable bit);
INSERT #ExpectedWorkerViews VALUES (N'VW_WorkerStatus',1,N'WorkerId',36,16,0,0),
(N'VW_WorkerStatus',2,N'WorkerGeneration',127,8,0,0),
(N'VW_WorkerStatus',3,N'ProviderKind',167,16,0,0),
(N'VW_WorkerStatus',4,N'State',167,16,0,0),
(N'VW_WorkerStatus',5,N'Capacity',56,4,0,0),
(N'VW_WorkerStatus',6,N'RunMode',167,16,0,0),
(N'VW_WorkerStatus',7,N'LastHeartbeatAtUtc',42,8,7,0),
(N'VW_WorkerStatus',8,N'OccupiedSlots',127,8,0,0),
(N'VW_WorkerStatus',9,N'ConfigVersion',173,8,0,0),
(N'VW_WorkerStatus',10,N'HeartbeatSeconds',56,4,0,0),
(N'VW_WorkerStatus',11,N'UnreachableSeconds',56,4,0,0),
(N'VW_WorkerExecutionStatus',1,N'SlotReservationId',36,16,0,0),
(N'VW_WorkerExecutionStatus',2,N'WorkItemId',127,8,0,0),
(N'VW_WorkerExecutionStatus',3,N'ClaimGeneration',127,8,0,0),
(N'VW_WorkerExecutionStatus',4,N'ExecutionId',36,16,0,0),
(N'VW_WorkerExecutionStatus',5,N'WorkerId',36,16,0,0),
(N'VW_WorkerExecutionStatus',6,N'WorkerGeneration',127,8,0,0),
(N'VW_WorkerExecutionStatus',7,N'State',167,24,0,0),
(N'VW_WorkerExecutionStatus',8,N'IsHeld',104,1,0,0),
(N'VW_WorkerExecutionStatus',9,N'HoldVersion',173,8,0,1),
(N'VW_WorkerExecutionStatus',10,N'StopStatus',167,24,0,0);
DECLARE @ViewMetadataMismatch nvarchar(2048);
SELECT TOP(1) @ViewMetadataMismatch=N'WorkerViewMetadata '+expected.ViewName+N'.'+expected.ColumnName
 +N' ordinal='+CONVERT(nvarchar(10),expected.Ordinal)+N' actualName='+ISNULL(actual.name COLLATE Latin1_General_100_BIN2,N'MISSING')
 +N' type='+ISNULL(CONVERT(nvarchar(10),actual.system_type_id),N'MISSING')+N'/'+CONVERT(nvarchar(10),expected.TypeId)
 +N' userType='+ISNULL(CONVERT(nvarchar(10),actual.user_type_id),N'MISSING')+N'/'+CONVERT(nvarchar(10),expected.TypeId)
 +N' length='+ISNULL(CONVERT(nvarchar(10),actual.max_length),N'MISSING')+N'/'+CONVERT(nvarchar(10),expected.MaxLength)
 +N' scale='+ISNULL(CONVERT(nvarchar(10),actual.scale),N'MISSING')+N'/'+CONVERT(nvarchar(10),expected.Scale)
 +N' nullable='+ISNULL(CONVERT(nvarchar(10),actual.is_nullable),N'MISSING')+N'/'+CONVERT(nvarchar(10),expected.Nullable)
FROM #ExpectedWorkerViews expected LEFT JOIN sys.columns actual ON actual.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(expected.ViewName),N'V') AND actual.column_id=expected.Ordinal
WHERE actual.column_id IS NULL OR actual.name COLLATE Latin1_General_100_BIN2<>expected.ColumnName OR actual.system_type_id<>expected.TypeId OR actual.user_type_id<>expected.TypeId OR actual.max_length<>expected.MaxLength OR actual.scale<>expected.Scale OR actual.is_nullable<>expected.Nullable
ORDER BY expected.ViewName,expected.Ordinal;
IF @ViewMetadataMismatch IS NULL AND (SELECT COUNT(*) FROM sys.columns WHERE object_id IN(OBJECT_ID(N'toolbelt_core.VW_WorkerStatus',N'V'),OBJECT_ID(N'toolbelt_core.VW_WorkerExecutionStatus',N'V')))<>(SELECT COUNT(*) FROM #ExpectedWorkerViews)
 SET @ViewMetadataMismatch=N'WorkerViewMetadata Gesamtzahl weicht vom expliziten21Spaltenvertrag ab.';
IF @ViewMetadataMismatch IS NOT NULL THROW 54933,@ViewMetadataMismatch,1;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration)
 THROW 54900,N'Fixture verlangt eine leere isolierte Queue/Workerinstallation.',1;
GO
CREATE OR ALTER PROCEDURE dbo.USP_TbxManagedNone AS BEGIN SET NOCOUNT ON;END;
GO
EXEC toolbelt_core.USP_RegisterWorkType @WorkTypeName='test.worker.control',@HandlerSchema=N'dbo',@HandlerProcedure=N'USP_TbxManagedNone',@ParameterMode='NONE';
CREATE TABLE #Config(Dummy int NULL);
CREATE TABLE #Worker(Dummy int NULL);
CREATE TABLE #Claim(Dummy int NULL);
CREATE TABLE #Status(Dummy int NULL);
DECLARE @Version binary(8)=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=2,@ExpectedConfigVersion=@Version,@ResultTable=N'#Config';
DECLARE @OldVersion binary(8)=@Version,@NewVersion binary(8)=(SELECT ConfigVersion FROM #Config);
BEGIN TRY EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=99,@ExpectedConfigVersion=@OldVersion;THROW 54930,N'Stale Konfigurationsversion wurde akzeptiert.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54212 OR ERROR_STATE()<>1 THROW;END CATCH;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1 AND ConfigVersion=@NewVersion AND MaxConcurrentExecutions=2) THROW 54930,N'Stale CAS änderte Konfiguration oder Version.',2;

DECLARE @A uniqueidentifier=NEWID(),@B uniqueidentifier=NEWID(),@GA bigint,@GB bigint,@TA uniqueidentifier,@TB uniqueidentifier;
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@A,@Capacity=2,@RunMode='BOUNDED',@ResultTable=N'#Worker';
SELECT @GA=WorkerGeneration,@TA=WorkerToken FROM #Worker;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@A AND WorkerGeneration=@GA AND HeartbeatSeconds=15 AND UnreachableSeconds=60) THROW 54931,N'Defaultregistrierungsintervalle fehlen.',1;
SET @Version=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_SetWorkerIntervals @HeartbeatSeconds=20,@UnreachableSeconds=80,@ExpectedConfigVersion=@Version,@ResultTable=N'#Config';
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@A AND WorkerGeneration=@GA AND HeartbeatSeconds=15 AND UnreachableSeconds=60) THROW 54931,N'Neue Intervalle änderten bestehende Generation.',2;

EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@B,@Capacity=2,@RunMode='BOUNDED',@ResultTable=N'#Worker';
SELECT @GB=WorkerGeneration,@TB=WorkerToken FROM #Worker;
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@B AND WorkerGeneration=@GB AND HeartbeatSeconds=20 AND UnreachableSeconds=80) THROW 54931,N'Neue Generation übernahm neue Intervalle nicht.',3;
BEGIN TRY EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@A,@WorkerGeneration=@GA,@WorkerToken=@TA,@ResultTable=N'#Claim';THROW 54940,N'Claim vor Opt-in wurde akzeptiert.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54217 OR ERROR_STATE()<>2 THROW;END CATCH;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation) THROW 54940,N'Claim vor Opt-in hinterließ Reservation.',2;
SET @Version=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_EnableManagedWorkers @ExpectedConfigVersion=@Version,@ResultTable=N'#Config';
-- Nur Help-Branches: INSERT EXEC ist hier ohne fachliche TX-/Rollbackpfade zulässig.
CREATE TABLE #PublicWorkerHelp(HelpContractVersion varchar(16),SchemaName sysname,ObjectName sysname,Section varchar(32),Ordinal int,ItemName sysname NULL,SqlDataType varchar(256) NULL,IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NULL,ExampleSql nvarchar(max) NULL);
CREATE TABLE #PublicWorkerNames(Name sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY);
INSERT #PublicWorkerNames VALUES(N'USP_ClaimWorkerWork'),(N'USP_CloseWorker'),(N'USP_DisableManagedWorkers'),(N'USP_EnableManagedWorkers'),(N'USP_HeartbeatWorker'),(N'USP_ReconcileWorkerExecution'),(N'USP_RegisterWorker'),(N'USP_ReleaseHeldWork'),(N'USP_SetWorkerCapacity'),(N'USP_SetWorkerConcurrency'),(N'USP_SetWorkerIntervals'),(N'USP_SetWorkerState'),(N'USP_StopWorkerExecution'),(N'USP_StopWorkers');
DECLARE @HelpName sysname,@HelpSql nvarchar(max),@HelpConfigBefore binary(8)=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
DECLARE publichelp CURSOR LOCAL FAST_FORWARD FOR SELECT Name FROM #PublicWorkerNames;
OPEN publichelp;FETCH NEXT FROM publichelp INTO @HelpName;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @HelpSql=N'INSERT #PublicWorkerHelp EXEC toolbelt_core.'+QUOTENAME(@HelpName)+N' @Hilfe=1;';
 EXEC sys.sp_executesql @HelpSql;
 FETCH NEXT FROM publichelp INTO @HelpName;
END;CLOSE publichelp;DEALLOCATE publichelp;
IF EXISTS(SELECT 1 FROM #PublicWorkerHelp WHERE HelpContractVersion<>'1.0' OR SchemaName<>N'toolbelt_core') OR EXISTS(SELECT 1 FROM #PublicWorkerNames expected CROSS JOIN(VALUES('DESCRIPTION'),('PARAMETER'),('EXAMPLE'))sections(Section) WHERE NOT EXISTS(SELECT 1 FROM #PublicWorkerHelp actual WHERE actual.ObjectName COLLATE Latin1_General_100_BIN2=expected.Name AND actual.Section COLLATE Latin1_General_100_BIN2=sections.Section COLLATE Latin1_General_100_BIN2)) OR (SELECT COUNT(DISTINCT ObjectName) FROM #PublicWorkerHelp)<>14 THROW 54941,N'Öffentlicher14Objekt-Helpvertrag ist unvollständig.',1;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkerRegistration)<>2 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation) OR (SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1)<>@HelpConfigBefore THROW 54941,N'Reine Helpaufrufe änderten fachliche Zustände.',2;

EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.worker.control',@ResultTable=N'#Status';
EXEC toolbelt_core.USP_EnqueueWork @WorkTypeName='test.worker.control',@ResultTable=N'#Status';
-- Barrier-Enqueue unterstützt in Queue 2.1 keinen ResultTable-Sink; dessen Ausgabe wird hier nicht benötigt.
EXEC toolbelt_core.USP_EnqueueBarrierWork @WorkTypeName='test.worker.control',@ExecutionGroup='test.worker.holdbarrier',@Priority=0;
CREATE TABLE #tbx_InvalidPublicClaimSink(Dummy int NULL);
BEGIN TRY EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@A,@WorkerGeneration=@GA,@WorkerToken=@TA,@ResultTable=N'#tbx_InvalidPublicClaimSink';THROW 54936,N'Öffentlicher ResultTable-Namensschutz wurde umgangen.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>51020 OR ERROR_STATE()<>1 THROW;END CATCH;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status NOT IN('QUEUED','BARRIER_WAIT')) THROW 54936,N'ResultTable-Fehler ließ private Admissionmutation zurück.',2;
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@A,@WorkerGeneration=@GA,@WorkerToken=@TA,@ResultTable=N'#Claim';
IF (SELECT COUNT(*) FROM #Claim)<>1 THROW 54901,N'Erster Supervisor erhielt keinen Slot.',1;
DECLARE @ProofSlot uniqueidentifier,@ProofItem bigint,@ProofToken uniqueidentifier,@ProofGen bigint,@ProofExecution uniqueidentifier,@FalseToken uniqueidentifier=NEWID(),@FalseAdmission uniqueidentifier=NEWID(),@FalseReservation uniqueidentifier=NEWID();
SELECT @ProofSlot=SlotReservationId,@ProofItem=WorkItemId,@ProofToken=ClaimToken,@ProofGen=ClaimGeneration,@ProofExecution=ExecutionId FROM #Claim;
BEGIN TRY BEGIN TRANSACTION;EXEC toolbelt_core.USP_ClaimWorkCore @ManagedAdmissionToken=@FalseAdmission,@ManagedReservationId=@FalseReservation;ROLLBACK;THROW 54942,N'Gefälschte Admission wurde akzeptiert.',1;END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;IF ERROR_NUMBER()<>54200 OR ERROR_STATE()<>2 THROW;END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_BindWorkerExecution @SlotReservationId=@ProofSlot,@WorkerId=@A,@WorkerGeneration=@GA,@WorkerToken=@FalseToken,@ClaimGeneration=@ProofGen,@ClaimToken=@ProofToken,@ExecutionId=@ProofExecution;THROW 54942,N'Falsches Bindtoken wurde akzeptiert.',2;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54218 OR ERROR_STATE()<>2 THROW;END CATCH;
BEGIN TRY BEGIN TRANSACTION;EXEC toolbelt_core.USP_BeginWorkerTransactionWitness @SlotReservationId=@ProofSlot,@ClaimToken=@ProofToken,@ExecutionId=@ProofExecution;ROLLBACK;THROW 54942,N'Witness ohne tatsächliche Connectionbindung wurde akzeptiert.',3;END TRY BEGIN CATCH IF @@TRANCOUNT>0 ROLLBACK;IF ERROR_NUMBER()<>54220 OR ERROR_STATE()<>1 THROW;END CATCH;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness) OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE SlotReservationId=@ProofSlot AND State='RESERVED' AND AttemptNonce IS NULL AND IsOccupied=1) OR (SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation)<>1 THROW 54942,N'Abgewiesene private Autorität hinterließ eine Mutation.',4;

DECLARE @ManagedClaimObjectId int=OBJECT_ID(N'tempdb..#Claim');
CREATE TABLE #ExpectedManagedClaim(Ordinal int,Name sysname COLLATE Latin1_General_100_BIN2,TypeId tinyint,MaxLength smallint,Scale tinyint,Nullable bit);
INSERT #ExpectedManagedClaim VALUES(1,N'WorkItemId',127,8,0,0),(2,N'WorkTypeName',167,128,0,0),(3,N'PayloadJson',231,-1,0,1),(4,N'ClaimToken',36,16,0,0),(5,N'ClaimedAtUtc',42,8,7,0),(6,N'ClaimGeneration',127,8,0,0),(7,N'LeaseUntilUtc',42,8,7,0),(8,N'LastHeartbeatAtUtc',42,8,7,0),(9,N'SlotReservationId',36,16,0,0),(10,N'ExecutionId',36,16,0,0);
IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=@ManagedClaimObjectId)<>10 OR EXISTS(SELECT 1 FROM #ExpectedManagedClaim expected LEFT JOIN (SELECT ROW_NUMBER() OVER(ORDER BY column_id) OutputOrdinal,name,column_id,system_type_id,user_type_id,max_length,scale,is_nullable,collation_name FROM tempdb.sys.columns WHERE object_id=@ManagedClaimObjectId) actual ON actual.OutputOrdinal=expected.Ordinal AND actual.name COLLATE Latin1_General_100_BIN2=expected.Name WHERE actual.column_id IS NULL OR actual.system_type_id<>expected.TypeId OR actual.user_type_id<>expected.TypeId OR actual.max_length<>expected.MaxLength OR actual.scale<>expected.Scale OR actual.is_nullable<>expected.Nullable OR (expected.Name=N'WorkTypeName' AND ISNULL(actual.collation_name,N'') COLLATE Latin1_General_100_BIN2<>N'Latin1_General_100_BIN2')) THROW 54937,N'Managedclaim liefert nicht den exakten10Spaltenvertrag mit BIN2WorkTypeName.',1;

EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@B,@WorkerGeneration=@GB,@WorkerToken=@TB,@ResultTable=N'#Claim';
IF (SELECT COUNT(*) FROM #Claim)<>1 THROW 54901,N'Zweiter Supervisor erhielt keinen Slot.',2;
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@A,@WorkerGeneration=@GA,@WorkerToken=@TA,@ResultTable=N'#Claim';
IF EXISTS(SELECT 1 FROM #Claim) OR (SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1)<>2 THROW 54902,N'Globales Budget wurde überschritten.',1;
SET @Version=(SELECT ConfigVersion FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1);
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=1,@ExpectedConfigVersion=@Version,@ResultTable=N'#Config';
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@B,@WorkerGeneration=@GB,@WorkerToken=@TB,@ResultTable=N'#Claim';
IF EXISTS(SELECT 1 FROM #Claim) OR (SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1)<>2 THROW 54903,N'Budgetsenkung änderte aktive Slots oder ließ neue Admission zu.',1;
SET @Version=(SELECT ConfigVersion FROM #Config);
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=3,@ExpectedConfigVersion=@Version,@ResultTable=N'#Config';
SET @Version=(SELECT ConfigVersion FROM #Config);
EXEC toolbelt_core.USP_SetWorkerCapacity @WorkerId=@A,@WorkerGeneration=@GA,@Capacity=1,@ExpectedConfigVersion=@Version,@ResultTable=N'#Config';
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@A,@WorkerGeneration=@GA,@WorkerToken=@TA,@ResultTable=N'#Claim';
IF EXISTS(SELECT 1 FROM #Claim) OR (SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE WorkerId=@A AND IsOccupied=1)<>1 THROW 54932,N'Kapazitätssenkung erlaubte neue Admission oder brach vorhandenen Slot ab.',1;
SET @Version=(SELECT ConfigVersion FROM #Config);
EXEC toolbelt_core.USP_SetWorkerCapacity @WorkerId=@A,@WorkerGeneration=@GA,@Capacity=2,@ExpectedConfigVersion=@Version,@ResultTable=N'#Config';

EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@A,@WorkerGeneration=@GA,@WorkerToken=@TA,@ResultTable=N'#Claim';
IF (SELECT COUNT(*) FROM #Claim)<>1 OR (SELECT COUNT(*) FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1)<>3 THROW 54904,N'Budgeterhöhung wurde nicht wirksam.',1;
SET @Version=(SELECT ConfigVersion FROM #Config);
EXEC toolbelt_core.USP_SetWorkerConcurrency @MaxConcurrentExecutions=0,@ExpectedConfigVersion=@Version,@ResultTable=N'#Config';
EXEC toolbelt_core.USP_ClaimWorkerWork @WorkerId=@B,@WorkerGeneration=@GB,@WorkerToken=@TB,@ResultTable=N'#Claim';
IF EXISTS(SELECT 1 FROM #Claim) THROW 54905,N'Nullbudget erlaubte Admission.',1;
BEGIN TRY EXEC toolbelt_core.USP_ClaimWork;THROW 54906,N'Legacyclaim umging Managedmodus.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()=54906 THROW;IF ERROR_NUMBER()<>54200 OR ERROR_STATE()<>2 THROW;END CATCH;
CREATE TABLE #Workers(WorkerId uniqueidentifier NOT NULL,WorkerGeneration bigint NOT NULL);
INSERT #Workers VALUES(@A,@GA),(@B,@GB);
SET LOCK_TIMEOUT 1234;
BEGIN TRY EXEC toolbelt_core.USP_StopWorkers @WorkersTable=N'#MissingWorkerSelection';THROW 54934,N'Fehlende Auswahl wurde akzeptiert.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54226 OR ERROR_STATE()<>2 THROW;END CATCH;
IF @@LOCK_TIMEOUT<>1234 THROW 54934,N'GroupStop-Throw restaurierte den Aufrufer-Locktimeout nicht.',2;
EXEC toolbelt_core.USP_StopWorkers @WorkersTable=N'#Workers',@ResultTable=N'#Status';
IF @@LOCK_TIMEOUT<>1234 THROW 54934,N'GroupStop-Erfolg restaurierte den Aufrufer-Locktimeout nicht.',3;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE AdmissionPaused<>1) THROW 54907,N'Stop hinterließ keine stabile Admissionpause.',1;
EXEC toolbelt_core.USP_RecordWorkerUnknown @SlotReservationId=@ProofSlot,@WorkerToken=@TA,@ExecutionId=@ProofExecution;
DECLARE @ProofHoldVersion binary(8)=(SELECT HoldVersion FROM toolbelt_core.WorkerExecutionDisposition WHERE SlotReservationId=@ProofSlot);
BEGIN TRY EXEC toolbelt_core.USP_ReleaseHeldWork @WorkItemId=@ProofItem,@ExpectedHoldVersion=@ProofHoldVersion;THROW 54943,N'UNKNOWN wurde ohne Rollbacknachweis freigegeben.',1;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54225 OR ERROR_STATE()<>2 THROW;END CATCH;
-- Synthetische Leasealterung ohne Wartezeit; dies simuliert keine Handler-Rollbackbestätigung.
UPDATE toolbelt_core.WorkItem SET ClaimedAtUtc=DATEADD(SECOND,-600,SYSUTCDATETIME()),LastHeartbeatAtUtc=DATEADD(SECOND,-600,SYSUTCDATETIME()),LeaseUntilUtc=DATEADD(SECOND,-1,SYSUTCDATETIME()) WHERE ManagedHold=1 AND Status='CLAIMED';
SELECT WorkItemId,ClaimToken,ClaimGeneration,Status,RowVersion,ManagedHold,RecoveryCount,RetryCycleNumber INTO #HeldGuardBefore FROM toolbelt_core.WorkItem;
CREATE TABLE #RecoveredManaged(Dummy int NULL);
EXEC toolbelt_core.USP_RecoverExpiredWork @ResultTable=N'#RecoveredManaged';
IF EXISTS(SELECT 1 FROM #RecoveredManaged) THROW 54944,N'Recovery übernahm einen expiredManagedHold.',1;
BEGIN TRY EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=@ProofItem,@ClaimToken=@ProofToken,@FailureCode='TEST.HOLD';THROW 54944,N'Retry umging persistenten Hold.',2;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54201 OR ERROR_STATE()<>1 THROW;END CATCH;
DECLARE @HeldBarrierId bigint,@HeldBarrierToken uniqueidentifier;
SELECT @HeldBarrierId=WorkItemId,@HeldBarrierToken=ClaimToken FROM toolbelt_core.WorkItem WHERE ExecutionMode='DRAIN_BARRIER' AND ManagedHold=1;
IF @HeldBarrierId IS NULL THROW 54944,N'Echte gehaltene Barrier-Testzeile fehlt.',7;
BEGIN TRY EXEC toolbelt_core.USP_ScheduleWorkRetry @WorkItemId=@HeldBarrierId,@ClaimToken=@HeldBarrierToken,@FailureCode='TEST.BARRIER_HOLD';THROW 54944,N'Barrier-Retry umging persistenten Hold.',8;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54201 OR ERROR_STATE()<>1 THROW;END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_RequeueDeadLetter @WorkItemId=@ProofItem;THROW 54944,N'Requeue umging persistenten Hold.',3;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54201 OR ERROR_STATE()<>1 THROW;END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_CompleteWork @WorkItemId=@ProofItem,@ClaimToken=@ProofToken;THROW 54944,N'Complete umging persistenten Hold.',4;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54201 OR ERROR_STATE()<>2 THROW;END CATCH;
BEGIN TRY EXEC toolbelt_core.USP_FailWork @WorkItemId=@ProofItem,@ClaimToken=@ProofToken,@FailureCode='TEST.HOLD';THROW 54944,N'Fail umging persistenten Hold.',5;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54201 OR ERROR_STATE()<>1 THROW;END CATCH;
IF EXISTS(SELECT WorkItemId,ClaimToken,ClaimGeneration,Status,RowVersion,ManagedHold,RecoveryCount,RetryCycleNumber FROM toolbelt_core.WorkItem EXCEPT SELECT WorkItemId,ClaimToken,ClaimGeneration,Status,RowVersion,ManagedHold,RecoveryCount,RetryCycleNumber FROM #HeldGuardBefore) OR EXISTS(SELECT WorkItemId,ClaimToken,ClaimGeneration,Status,RowVersion,ManagedHold,RecoveryCount,RetryCycleNumber FROM #HeldGuardBefore EXCEPT SELECT WorkItemId,ClaimToken,ClaimGeneration,Status,RowVersion,ManagedHold,RecoveryCount,RetryCycleNumber FROM toolbelt_core.WorkItem) OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE SlotReservationId=@ProofSlot AND HoldVersion=@ProofHoldVersion AND IsHeld=1) THROW 54944,N'Holdbypassversuch änderte Queue/History/Holdversion.',6;

DECLARE @Slot uniqueidentifier,@HV binary(8),@TimeoutThrowChecked bit=0;
DECLARE held CURSOR LOCAL FAST_FORWARD FOR SELECT SlotReservationId,HoldVersion FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1;
OPEN held;FETCH NEXT FROM held INTO @Slot,@HV;
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@HV,@ResultTable=N'#Status';
 IF @@LOCK_TIMEOUT<>1234 THROW 54935,N'Reconcile-Erfolg restaurierte den Aufrufer-Locktimeout nicht.',1;
 IF @TimeoutThrowChecked=0
 BEGIN
  -- Der Erfolgsweg hat HoldVersion geändert; dieselbe alte Version muss scheitern.
  BEGIN TRY EXEC toolbelt_core.USP_ReconcileWorkerExecution @SlotReservationId=@Slot,@ExpectedHoldVersion=@HV;THROW 54935,N'Stale Holdversion wurde akzeptiert.',2;END TRY BEGIN CATCH IF ERROR_NUMBER()<>54227 OR ERROR_STATE()<>2 THROW;END CATCH;
  IF @@LOCK_TIMEOUT<>1234 THROW 54935,N'Reconcile-Throw restaurierte den Aufrufer-Locktimeout nicht.',3;
  SET @TimeoutThrowChecked=1;
 END;

 IF (SELECT Outcome FROM #Status)<>'ROLLED_BACK_HELD' THROW 54908,N'Vor Dispatch gestoppte Reservation blieb ungeklärt.',1;
 FETCH NEXT FROM held INTO @Slot,@HV;
END;CLOSE held;DEALLOCATE held;
EXEC toolbelt_core.USP_CloseWorker @WorkerId=@A,@WorkerGeneration=@GA,@WorkerToken=@TA;
EXEC toolbelt_core.USP_RegisterWorker @WorkerId=@A,@Capacity=2,@RunMode='BOUNDED',@ResultTable=N'#Worker';
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WHERE WorkerId=@A AND WorkerGeneration=(SELECT WorkerGeneration FROM #Worker) AND State='PAUSED' AND AdmissionPaused=1) THROW 54909,N'Neuregistrierung nach Close umging Pause.',1;
-- Fixture lässt ausschließlich synthetische, bewiesen gehaltene History zurück.
-- Tatsächliche Handler-Cancellation/Commit-/Rollbackfälle erfordern den Provideradapter.
SELECT CAST('PASS' AS varchar(16)) BasicAdmissionAndGenerationContract;
GO
