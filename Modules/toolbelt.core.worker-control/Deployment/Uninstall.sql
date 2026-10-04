:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 THROW 54240,N'Lifecycle darf keine Callertransaktion übernehmen.',2;
CREATE TABLE #tbx_WorkerControlOwned(ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,ObjectType char(2) COLLATE Latin1_General_100_BIN2 NOT NULL,LevelType nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #tbx_WorkerControlOwned VALUES (N'WorkerControlConfiguration',N'U',N'TABLE'),(N'WorkerRegistration',N'U',N'TABLE'),(N'WorkerSlotReservation',N'U',N'TABLE'),(N'WorkerExecutionDisposition',N'U',N'TABLE'),(N'WorkerExecutionCommitWitness',N'U',N'TABLE'),(N'VW_WorkerStatus',N'V',N'VIEW'),(N'VW_WorkerExecutionStatus',N'V',N'VIEW'),(N'USP_BeginWorkerCompletion',N'P',N'PROCEDURE'),(N'USP_BeginWorkerTransactionWitness',N'P',N'PROCEDURE'),(N'USP_BindWorkerExecution',N'P',N'PROCEDURE'),(N'USP_ClaimWorkerWork',N'P',N'PROCEDURE'),(N'USP_CloseWorker',N'P',N'PROCEDURE'),(N'USP_DisableManagedWorkers',N'P',N'PROCEDURE'),(N'USP_EnableManagedWorkers',N'P',N'PROCEDURE'),(N'USP_FinalizeWorkerFailure',N'P',N'PROCEDURE'),(N'USP_HeartbeatWorker',N'P',N'PROCEDURE'),(N'USP_ReconcileWorkerExecution',N'P',N'PROCEDURE'),(N'USP_RecordWorkerCommit',N'P',N'PROCEDURE'),(N'USP_RecordWorkerRollback',N'P',N'PROCEDURE'),(N'USP_RecordWorkerUnknown',N'P',N'PROCEDURE'),(N'USP_RegisterWorker',N'P',N'PROCEDURE'),(N'USP_ReleaseHeldWork',N'P',N'PROCEDURE'),(N'USP_ReserveWorkerExecution',N'P',N'PROCEDURE'),(N'USP_SetWorkerCapacity',N'P',N'PROCEDURE'),(N'USP_SetWorkerConcurrency',N'P',N'PROCEDURE'),(N'USP_SetWorkerIntervals',N'P',N'PROCEDURE'),(N'USP_SetWorkerState',N'P',N'PROCEDURE'),(N'USP_StopWorkerExecution',N'P',N'PROCEDURE'),(N'USP_StopWorkers',N'P',N'PROCEDURE');
DECLARE @Installed nvarchar(64)=(SELECT TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version');
IF @Installed IS NOT NULL AND @Installed COLLATE Latin1_General_100_BIN2<>N'1.0.0' THROW 54241,N'Das installierte Release ist unbekannt.',3;
DECLARE @HasOccupied bit=0,@HasHeld bit=0;
IF @Installed IS NULL RETURN;
DECLARE @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)'),@AllowDataLoss bit=TRY_CONVERT(bit,N'$(AllowDataLoss)');
IF ISNULL(@ConfirmNoExternalConsumers,0)<>1 OR @AllowDataLoss IS NULL THROW 54246,N'Expliziter Consumerabschluss und gültiges AllowDataLoss sind erforderlich.',1;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE ManagedEnabled=1) THROW 54246,N'Managed-Betrieb muss kontrolliert deaktiviert sein.',2;
IF @AllowDataLoss<>1 AND (EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation)) THROW 54246,N'Persistierte History wird ohne AllowDataLoss nicht gelöscht.',3;
 IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1 THROW 54240,N'Lifecycle benötigt vorhandene vollständige Metadatensicht.',1;
 IF EXISTS(SELECT 1 FROM #tbx_WorkerControlOwned expected JOIN sys.schemas schemas ON schemas.name=N'toolbelt_core' JOIN sys.objects actual ON actual.schema_id=schemas.schema_id AND actual.name COLLATE Latin1_General_100_BIN2=expected.ObjectName COLLATE Latin1_General_100_BIN2
 WHERE @Installed IS NULL OR actual.type COLLATE Latin1_General_100_BIN2<>expected.ObjectType COLLATE Latin1_General_100_BIN2 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties marker WHERE marker.class=1 AND marker.major_id=actual.object_id AND marker.minor_id=0 AND marker.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),marker.value)=N'toolbelt.core.worker-control')) THROW 54241,N'Fremde oder inkonsistent markierte Zielobjekte blockieren Lifecycle.',1;
 IF @Installed IS NOT NULL AND EXISTS(SELECT 1 FROM #tbx_WorkerControlOwned expected WHERE OBJECT_ID(N'toolbelt_core.'+QUOTENAME(expected.ObjectName),expected.ObjectType) IS NULL) THROW 54241,N'Der installierte Objektstand ist unvollständig.',2;
 IF @Installed IS NOT NULL
 BEGIN
  SET @HasOccupied=0;SET @HasHeld=0;
  EXEC sys.sp_executesql N'SELECT @occupied=CASE WHEN EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1 OR State IN(''UNKNOWN'',''STOP_REQUESTED'',''STOPPING'')) THEN 1 ELSE 0 END;SELECT @held=CASE WHEN EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1) THEN 1 ELSE 0 END;',N'@occupied bit OUTPUT,@held bit OUTPUT',@occupied=@HasOccupied OUTPUT,@held=@HasHeld OUTPUT;
  IF @HasOccupied=1 OR @HasHeld=1 THROW 54242,N'Aktive oder ungeklärte Reservations und Holds blockieren Lifecycle.',1;
 END;
 IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies dependency WHERE dependency.referenced_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned)
 AND dependency.referencing_id NOT IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned)
 AND NOT EXISTS(SELECT 1 FROM sys.objects child WHERE child.object_id=dependency.referencing_id AND child.parent_object_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned))) THROW 54243,N'Sichtbare fremde Abhängigkeiten blockieren Lifecycle.',1;
BEGIN TRANSACTION;
DECLARE @LifecycleLock int;EXEC @LifecycleLock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.core.worker-control',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
IF @LifecycleLock<0 BEGIN ROLLBACK;THROW 54245,N'Ein paralleler Lifecycle ist aktiv.',1;END;
DECLARE @QueueLifecycleLock int;EXEC @QueueLifecycleLock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.core.work-queue',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
IF @QueueLifecycleLock<0 BEGIN ROLLBACK;THROW 54245,N'Ein paralleler Queue-Lifecycle ist aktiv.',3;END;
DECLARE @ManagedGateId tinyint;SELECT @ManagedGateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
IF @ManagedGateId IS NULL THROW 54244,N'Der exakte Queue-Managed-Singleton fehlt.',4;
DECLARE @CurrentInstalled nvarchar(64)=(SELECT TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version');
IF ISNULL(@CurrentInstalled,N'')<>ISNULL(@Installed,N'') BEGIN ROLLBACK;THROW 54245,N'Der Modulstand hat sich seit Preflight verändert.',2;END;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE ManagedEnabled=1) THROW 54246,N'Managed-Betrieb muss kontrolliert deaktiviert sein.',2;
IF @AllowDataLoss<>1 AND (EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration WITH(UPDLOCK,HOLDLOCK)) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WITH(UPDLOCK,HOLDLOCK))) THROW 54246,N'Persistierte History wird ohne AllowDataLoss nicht gelöscht.',3;
 IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1 THROW 54240,N'Lifecycle benötigt vorhandene vollständige Metadatensicht.',1;
 IF EXISTS(SELECT 1 FROM #tbx_WorkerControlOwned expected JOIN sys.schemas schemas ON schemas.name=N'toolbelt_core' JOIN sys.objects actual ON actual.schema_id=schemas.schema_id AND actual.name COLLATE Latin1_General_100_BIN2=expected.ObjectName COLLATE Latin1_General_100_BIN2
 WHERE @Installed IS NULL OR actual.type COLLATE Latin1_General_100_BIN2<>expected.ObjectType COLLATE Latin1_General_100_BIN2 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties marker WHERE marker.class=1 AND marker.major_id=actual.object_id AND marker.minor_id=0 AND marker.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),marker.value)=N'toolbelt.core.worker-control')) THROW 54241,N'Fremde oder inkonsistent markierte Zielobjekte blockieren Lifecycle.',1;
 IF @Installed IS NOT NULL AND EXISTS(SELECT 1 FROM #tbx_WorkerControlOwned expected WHERE OBJECT_ID(N'toolbelt_core.'+QUOTENAME(expected.ObjectName),expected.ObjectType) IS NULL) THROW 54241,N'Der installierte Objektstand ist unvollständig.',2;
 IF @Installed IS NOT NULL
 BEGIN
  SET @HasOccupied=0;SET @HasHeld=0;
  EXEC sys.sp_executesql N'SELECT @occupied=CASE WHEN EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1 OR State IN(''UNKNOWN'',''STOP_REQUESTED'',''STOPPING'')) THEN 1 ELSE 0 END;SELECT @held=CASE WHEN EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1) THEN 1 ELSE 0 END;',N'@occupied bit OUTPUT,@held bit OUTPUT',@occupied=@HasOccupied OUTPUT,@held=@HasHeld OUTPUT;
  IF @HasOccupied=1 OR @HasHeld=1 THROW 54242,N'Aktive oder ungeklärte Reservations und Holds blockieren Lifecycle.',1;
 END;
 IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies dependency WHERE dependency.referenced_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned)
 AND dependency.referencing_id NOT IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned)
 AND NOT EXISTS(SELECT 1 FROM sys.objects child WHERE child.object_id=dependency.referencing_id AND child.parent_object_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned))) THROW 54243,N'Sichtbare fremde Abhängigkeiten blockieren Lifecycle.',1;
DROP PROCEDURE toolbelt_core.USP_BeginWorkerCompletion;
DROP PROCEDURE toolbelt_core.USP_BeginWorkerTransactionWitness;
DROP PROCEDURE toolbelt_core.USP_BindWorkerExecution;
DROP PROCEDURE toolbelt_core.USP_ClaimWorkerWork;
DROP PROCEDURE toolbelt_core.USP_CloseWorker;
DROP PROCEDURE toolbelt_core.USP_DisableManagedWorkers;
DROP PROCEDURE toolbelt_core.USP_EnableManagedWorkers;
DROP PROCEDURE toolbelt_core.USP_FinalizeWorkerFailure;
DROP PROCEDURE toolbelt_core.USP_HeartbeatWorker;
DROP PROCEDURE toolbelt_core.USP_ReconcileWorkerExecution;
DROP PROCEDURE toolbelt_core.USP_RecordWorkerCommit;
DROP PROCEDURE toolbelt_core.USP_RecordWorkerRollback;
DROP PROCEDURE toolbelt_core.USP_RecordWorkerUnknown;
DROP PROCEDURE toolbelt_core.USP_RegisterWorker;
DROP PROCEDURE toolbelt_core.USP_ReleaseHeldWork;
DROP PROCEDURE toolbelt_core.USP_ReserveWorkerExecution;
DROP PROCEDURE toolbelt_core.USP_SetWorkerCapacity;
DROP PROCEDURE toolbelt_core.USP_SetWorkerConcurrency;
DROP PROCEDURE toolbelt_core.USP_SetWorkerIntervals;
DROP PROCEDURE toolbelt_core.USP_SetWorkerState;
DROP PROCEDURE toolbelt_core.USP_StopWorkerExecution;
DROP PROCEDURE toolbelt_core.USP_StopWorkers;
DROP VIEW toolbelt_core.VW_WorkerStatus;
DROP VIEW toolbelt_core.VW_WorkerExecutionStatus;
DROP TABLE toolbelt_core.WorkerExecutionCommitWitness;
DROP TABLE toolbelt_core.WorkerExecutionDisposition;
DROP TABLE toolbelt_core.WorkerSlotReservation;
DROP TABLE toolbelt_core.WorkerRegistration;
DROP TABLE toolbelt_core.WorkerControlConfiguration;
EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.core.worker-control.Version';
EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.core.worker-control.DeploymentMode';
COMMIT;
DROP TABLE #tbx_WorkerControlOwned;
GO
