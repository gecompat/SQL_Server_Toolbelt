:On Error exit
IF @@TRANCOUNT<>0
BEGIN
 RAISERROR(N'Lifecycle darf keine aktive Callertransaktion übernehmen.',16,1);
 RETURN;
END;
IF XACT_STATE()<>0
BEGIN
 RAISERROR(N'Lifecycle darf keinen aktiven Transaktionszustand übernehmen.',16,1);
 RETURN;
END;
IF (@@OPTIONS&2)=2
BEGIN
 RAISERROR(N'Lifecycle darf keine implizite Transaktion übernehmen.',16,1);
 RETURN;
END;
-- Source-DDL bleibt im installierten Verbund auf fünf Sekunden Lockwait begrenzt.
IF @@LOCK_TIMEOUT<>-1 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version' AND CONVERT(nvarchar(4000),value) COLLATE Latin1_General_100_BIN2=N'1.0.0')
BEGIN
 RAISERROR(N'Installierter Queue-/Control-Repeat benötigt initial LOCK_TIMEOUT -1.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;

CREATE TABLE #tbx_WorkerControlOwned(ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,ObjectType char(2) COLLATE Latin1_General_100_BIN2 NOT NULL,LevelType nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #tbx_WorkerControlOwned VALUES (N'WorkerControlConfiguration',N'U',N'TABLE'),(N'WorkerRegistration',N'U',N'TABLE'),(N'WorkerSlotReservation',N'U',N'TABLE'),(N'WorkerExecutionDisposition',N'U',N'TABLE'),(N'WorkerExecutionCommitWitness',N'U',N'TABLE'),(N'VW_WorkerStatus',N'V',N'VIEW'),(N'VW_WorkerExecutionStatus',N'V',N'VIEW'),(N'USP_BeginWorkerCompletion',N'P',N'PROCEDURE'),(N'USP_BeginWorkerTransactionWitness',N'P',N'PROCEDURE'),(N'USP_BindWorkerExecution',N'P',N'PROCEDURE'),(N'USP_ClaimWorkerWork',N'P',N'PROCEDURE'),(N'USP_CloseWorker',N'P',N'PROCEDURE'),(N'USP_DisableManagedWorkers',N'P',N'PROCEDURE'),(N'USP_EnableManagedWorkers',N'P',N'PROCEDURE'),(N'USP_FinalizeWorkerFailure',N'P',N'PROCEDURE'),(N'USP_HeartbeatWorker',N'P',N'PROCEDURE'),(N'USP_ReconcileWorkerExecution',N'P',N'PROCEDURE'),(N'USP_RecordWorkerCommit',N'P',N'PROCEDURE'),(N'USP_RecordWorkerRollback',N'P',N'PROCEDURE'),(N'USP_RecordWorkerUnknown',N'P',N'PROCEDURE'),(N'USP_RegisterWorker',N'P',N'PROCEDURE'),(N'USP_ReleaseHeldWork',N'P',N'PROCEDURE'),(N'USP_ReserveWorkerExecution',N'P',N'PROCEDURE'),(N'USP_SetWorkerCapacity',N'P',N'PROCEDURE'),(N'USP_SetWorkerConcurrency',N'P',N'PROCEDURE'),(N'USP_SetWorkerIntervals',N'P',N'PROCEDURE'),(N'USP_SetWorkerState',N'P',N'PROCEDURE'),(N'USP_StopWorkerExecution',N'P',N'PROCEDURE'),(N'USP_StopWorkers',N'P',N'PROCEDURE');
DECLARE @Installed nvarchar(64)=(SELECT TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version');
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version' AND (value IS NULL OR ISNULL(CONVERT(sysname,SQL_VARIANT_PROPERTY(value,'BaseType')),N'')<>N'nvarchar')) THROW 54241,N'Der vorhandene installierte Release-Marker ist kein bekannter typisierter Stand.',3;
IF @Installed IS NOT NULL AND (DATALENGTH(@Installed)<>DATALENGTH(N'1.0.0') OR @Installed COLLATE Latin1_General_100_BIN2<>N'1.0.0') THROW 54241,N'Das installierte Release ist unbekannt.',3;
DECLARE @HasOccupied bit=0,@HasHeld bit=0;
DECLARE @DeploymentMode nvarchar(16)=N'$(DeploymentMode)';
IF @DeploymentMode COLLATE Latin1_General_100_BIN2 NOT IN(N'local',N'central') THROW 54240,N'DeploymentMode muss local oder central sein.',3;
IF CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN(15,16,17) THROW 54240,N'Der SQL-Hauptversionsvertrag ist nicht erfüllt.',4;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'2.1.0')
 OR OBJECT_ID(N'toolbelt_core.WorkQueueManagedGate',N'U') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_ClaimWorkCore',N'P') IS NULL THROW 54244,N'Queue2.1 muss separat vorinstalliert sein.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-context.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 OR OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 54244,N'Execution-Context/Cancellation1.0 und ResultTable müssen separat vorhanden sein.',2;
EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WITH(READCOMMITTEDLOCK) WHERE GateId=1) THROW 54244,N''Der exakte Queue-Managed-Singleton fehlt.'',4;';
IF @Installed IS NULL EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;IF EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WITH(READCOMMITTEDLOCK) WHERE ManagedEnabled=1) THROW 54244,N''Ein aktiver Gate ohne konformen Controlprovider wird nicht adoptiert.'',3;';
IF ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'ALTER'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE PROCEDURE'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE VIEW'),0)<>1 THROW 54240,N'Vorhandene DDL-Rechte fehlen.',5;
 IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1 THROW 54240,N'Lifecycle benötigt vorhandene vollständige Metadatensicht.',1;
 IF EXISTS(SELECT 1 FROM #tbx_WorkerControlOwned expected JOIN sys.schemas schemas ON schemas.name=N'toolbelt_core' JOIN sys.objects actual ON actual.schema_id=schemas.schema_id AND actual.name COLLATE Latin1_General_100_BIN2=expected.ObjectName COLLATE Latin1_General_100_BIN2
 WHERE @Installed IS NULL OR actual.type COLLATE Latin1_General_100_BIN2<>expected.ObjectType COLLATE Latin1_General_100_BIN2 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties marker WHERE marker.class=1 AND marker.major_id=actual.object_id AND marker.minor_id=0 AND marker.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),marker.value)=N'toolbelt.core.worker-control')) THROW 54241,N'Fremde oder inkonsistent markierte Zielobjekte blockieren Lifecycle.',1;
 IF @Installed IS NOT NULL AND EXISTS(SELECT 1 FROM #tbx_WorkerControlOwned expected WHERE OBJECT_ID(N'toolbelt_core.'+QUOTENAME(expected.ObjectName),expected.ObjectType) IS NULL) THROW 54241,N'Der installierte Objektstand ist unvollständig.',2;
 IF @Installed IS NOT NULL
 BEGIN
  SET @HasOccupied=0;SET @HasHeld=0;
  EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;SELECT @occupied=CASE WHEN EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1 OR State IN(''UNKNOWN'',''STOP_REQUESTED'',''STOPPING'')) THEN 1 ELSE 0 END;SELECT @held=CASE WHEN EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1) THEN 1 ELSE 0 END;',N'@occupied bit OUTPUT,@held bit OUTPUT',@occupied=@HasOccupied OUTPUT,@held=@HasHeld OUTPUT;
  IF @HasOccupied=1 OR @HasHeld=1 THROW 54242,N'Aktive oder ungeklärte Reservations und Holds blockieren Lifecycle.',1;
 END;
 IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies dependency WHERE dependency.referenced_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned)
 AND dependency.referencing_id NOT IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned)
 AND NOT EXISTS(SELECT 1 FROM sys.objects child WHERE child.object_id=dependency.referencing_id AND child.parent_object_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned))) THROW 54243,N'Sichtbare fremde Abhängigkeiten blockieren Lifecycle.',1;
DECLARE @RepeatGuard nvarchar(max);
IF @Installed IS NOT NULL
BEGIN
:r ../../toolbelt.core.work-queue/Deployment/RepeatInstalledControl.Preflight.sql
 SELECT @RepeatGuard=SqlText FROM #tbx_RepeatGuard;
 EXEC sys.sp_executesql @RepeatGuard,N'@Fence bit',@Fence=0;
END;
BEGIN TRY
BEGIN TRANSACTION;
DECLARE @LifecycleLock int;EXEC @LifecycleLock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.core.worker-control',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
IF @LifecycleLock<0 BEGIN ROLLBACK;THROW 54245,N'Ein paralleler Lifecycle ist aktiv.',1;END;
DECLARE @QueueLifecycleLock int;EXEC @QueueLifecycleLock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.core.work-queue',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
IF @QueueLifecycleLock<0 BEGIN ROLLBACK;THROW 54245,N'Ein paralleler Queue-Lifecycle ist aktiv.',3;END;
IF @Installed IS NOT NULL
BEGIN
 EXEC sys.sp_executesql @RepeatGuard,N'@Fence bit',@Fence=1;
 EXEC sys.sp_executesql @RepeatGuard,N'@Fence bit',@Fence=0;
END;
DECLARE @ManagedGateId tinyint;SELECT @ManagedGateId=GateId FROM toolbelt_core.WorkQueueManagedGate WITH(UPDLOCK,HOLDLOCK) WHERE GateId=1;
IF @ManagedGateId IS NULL THROW 54244,N'Der exakte Queue-Managed-Singleton fehlt.',4;
DECLARE @CurrentInstalled nvarchar(64)=(SELECT TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version');
IF ISNULL(@CurrentInstalled,N'')<>ISNULL(@Installed,N'') BEGIN ROLLBACK;THROW 54245,N'Der Modulstand hat sich seit Preflight verändert.',2;END;

IF @DeploymentMode COLLATE Latin1_General_100_BIN2 NOT IN(N'local',N'central') THROW 54240,N'DeploymentMode muss local oder central sein.',3;
IF CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN(15,16,17) THROW 54240,N'Der SQL-Hauptversionsvertrag ist nicht erfüllt.',4;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(64),value)=N'2.1.0')
 OR OBJECT_ID(N'toolbelt_core.WorkQueueManagedGate',N'U') IS NULL OR OBJECT_ID(N'toolbelt_core.USP_ClaimWorkCore',N'P') IS NULL THROW 54244,N'Queue2.1 muss separat vorinstalliert sein.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-context.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 OR OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL THROW 54244,N'Execution-Context/Cancellation1.0 und ResultTable müssen separat vorhanden sein.',2;
IF @Installed IS NULL EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;IF EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WITH(READCOMMITTEDLOCK) WHERE ManagedEnabled=1) THROW 54244,N''Ein aktiver Gate ohne konformen Controlprovider wird nicht adoptiert.'',3;';
IF ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'ALTER'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE PROCEDURE'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE VIEW'),0)<>1 THROW 54240,N'Vorhandene DDL-Rechte fehlen.',5;
 IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1 THROW 54240,N'Lifecycle benötigt vorhandene vollständige Metadatensicht.',1;
 IF EXISTS(SELECT 1 FROM #tbx_WorkerControlOwned expected JOIN sys.schemas schemas ON schemas.name=N'toolbelt_core' JOIN sys.objects actual ON actual.schema_id=schemas.schema_id AND actual.name COLLATE Latin1_General_100_BIN2=expected.ObjectName COLLATE Latin1_General_100_BIN2
 WHERE @Installed IS NULL OR actual.type COLLATE Latin1_General_100_BIN2<>expected.ObjectType COLLATE Latin1_General_100_BIN2 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties marker WHERE marker.class=1 AND marker.major_id=actual.object_id AND marker.minor_id=0 AND marker.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),marker.value)=N'toolbelt.core.worker-control')) THROW 54241,N'Fremde oder inkonsistent markierte Zielobjekte blockieren Lifecycle.',1;
 IF @Installed IS NOT NULL AND EXISTS(SELECT 1 FROM #tbx_WorkerControlOwned expected WHERE OBJECT_ID(N'toolbelt_core.'+QUOTENAME(expected.ObjectName),expected.ObjectType) IS NULL) THROW 54241,N'Der installierte Objektstand ist unvollständig.',2;
 IF @Installed IS NOT NULL
 BEGIN
  SET @HasOccupied=0;SET @HasHeld=0;
  EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;SELECT @occupied=CASE WHEN EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WHERE IsOccupied=1 OR State IN(''UNKNOWN'',''STOP_REQUESTED'',''STOPPING'')) THEN 1 ELSE 0 END;SELECT @held=CASE WHEN EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WHERE IsHeld=1) THEN 1 ELSE 0 END;',N'@occupied bit OUTPUT,@held bit OUTPUT',@occupied=@HasOccupied OUTPUT,@held=@HasHeld OUTPUT;
  IF @HasOccupied=1 OR @HasHeld=1 THROW 54242,N'Aktive oder ungeklärte Reservations und Holds blockieren Lifecycle.',1;
 END;
 IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies dependency WHERE dependency.referenced_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned)
 AND dependency.referencing_id NOT IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned)
 AND NOT EXISTS(SELECT 1 FROM sys.objects child WHERE child.object_id=dependency.referencing_id AND child.parent_object_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName)) FROM #tbx_WorkerControlOwned))) THROW 54243,N'Sichtbare fremde Abhängigkeiten blockieren Lifecycle.',1;
IF @Installed IS NOT NULL SET LOCK_TIMEOUT 5000;
END TRY
BEGIN CATCH
 IF OBJECT_ID(N'tempdb..#tbx_RepeatGuard',N'U') IS NOT NULL SET LOCK_TIMEOUT -1;
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
:r ../Source/WorkerControlTables.sql
:r ../Source/VW_WorkerStatus.sql
:r ../Source/VW_WorkerExecutionStatus.sql
:r ../Source/USP_BeginWorkerCompletion.sql
:r ../Source/USP_BeginWorkerTransactionWitness.sql
:r ../Source/USP_BindWorkerExecution.sql
:r ../Source/USP_ClaimWorkerWork.sql
:r ../Source/USP_CloseWorker.sql
:r ../Source/USP_DisableManagedWorkers.sql
:r ../Source/USP_EnableManagedWorkers.sql
:r ../Source/USP_FinalizeWorkerFailure.sql
:r ../Source/USP_HeartbeatWorker.sql
:r ../Source/USP_ReconcileWorkerExecution.sql
:r ../Source/USP_RecordWorkerCommit.sql
:r ../Source/USP_RecordWorkerRollback.sql
:r ../Source/USP_RecordWorkerUnknown.sql
:r ../Source/USP_RegisterWorker.sql
:r ../Source/USP_ReleaseHeldWork.sql
:r ../Source/USP_ReserveWorkerExecution.sql
:r ../Source/USP_SetWorkerCapacity.sql
:r ../Source/USP_SetWorkerConcurrency.sql
:r ../Source/USP_SetWorkerIntervals.sql
:r ../Source/USP_SetWorkerState.sql
:r ../Source/USP_StopWorkerExecution.sql
:r ../Source/USP_StopWorkers.sql
SET NOCOUNT ON;
BEGIN TRY
DECLARE @Object sysname,@Level nvarchar(16),@ObjectId int,@Property sysname,@Value nvarchar(4000);
DECLARE objects_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectName,LevelType FROM #tbx_WorkerControlOwned ORDER BY ObjectName;
OPEN objects_cursor;FETCH NEXT FROM objects_cursor INTO @Object,@Level;
WHILE @@FETCH_STATUS=0 BEGIN
SET @ObjectId=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(@Object));
DECLARE @Properties TABLE(PropertyName sysname NOT NULL,PropertyValue nvarchar(4000) NOT NULL);
INSERT @Properties VALUES(N'Toolbelt.ModuleId',N'toolbelt.core.worker-control'),(N'Toolbelt.ModuleVersion',N'1.0.0'),(N'Toolbelt.ContractVersion',N'1.0'),(N'Toolbelt.DeploymentMode',N'$(DeploymentMode)'),(N'Toolbelt.SourceHash',ISNULL(CONVERT(nvarchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@ObjectId))),2),N'PERSISTENT_TABLE'));
DECLARE properties_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT PropertyName,PropertyValue FROM @Properties;
OPEN properties_cursor;FETCH NEXT FROM properties_cursor INTO @Property,@Value;
WHILE @@FETCH_STATUS=0 BEGIN
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=@Property)
EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@Level,@level1name=@Object;
ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@Level,@level1name=@Object;
FETCH NEXT FROM properties_cursor INTO @Property,@Value;END;
CLOSE properties_cursor;DEALLOCATE properties_cursor;DELETE FROM @Properties;
FETCH NEXT FROM objects_cursor INTO @Object,@Level;END;
CLOSE objects_cursor;DEALLOCATE objects_cursor;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version') EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.core.worker-control.Version',@value=N'1.0.0';
ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.core.worker-control.Version',@value=N'1.0.0';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.DeploymentMode') EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.core.worker-control.DeploymentMode',@value=N'$(DeploymentMode)';
ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.core.worker-control.DeploymentMode',@value=N'$(DeploymentMode)';
COMMIT;
IF OBJECT_ID(N'tempdb..#tbx_RepeatGuard',N'U') IS NOT NULL SET LOCK_TIMEOUT -1;
:r ../../toolbelt.core.work-queue/Deployment/RepeatInstalledControl.Cleanup.sql
DROP TABLE #tbx_WorkerControlOwned;
END TRY
BEGIN CATCH
 IF OBJECT_ID(N'tempdb..#tbx_RepeatGuard',N'U') IS NOT NULL SET LOCK_TIMEOUT -1;
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
