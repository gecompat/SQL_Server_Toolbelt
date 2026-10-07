:On Error exit

-- ============================================================================
-- Zweck:     Erst- und Wiederholungsdeployment
-- Modul:     toolbelt.core.work-queue v2.1.0 (neutrale Managedintegration)
-- Erfordert: toolbelt.core.result-table 1.0.0; toolbelt.core.work-type 1.1.0
-- Modus:     SQLCMD; Ausführung aus diesem Deployment-Verzeichnis
-- Parameter: DeploymentMode=local|central
-- ============================================================================

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
-- Der installierte Verbund-Repeat verwendet eine frische Session mit Standardtimeout.
IF @@LOCK_TIMEOUT<>-1
 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND CONVERT(nvarchar(4000),value) COLLATE Latin1_General_100_BIN2=N'2.1.0')
 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version' AND CONVERT(nvarchar(4000),value) COLLATE Latin1_General_100_BIN2=N'1.0.0')
BEGIN
 RAISERROR(N'Installierter Queue-/Control-Repeat benötigt initial LOCK_TIMEOUT -1.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

DROP TABLE IF EXISTS #tbx_WorkQueueReleaseObjects;
DROP TABLE IF EXISTS #tbx_WorkQueueDeployState;

CREATE TABLE #tbx_WorkQueueReleaseObjects
(
      ReleaseVersion nvarchar(64) NOT NULL
    , SchemaName sysname NOT NULL
    , ObjectName sysname NOT NULL
    , ObjectType char(2) NOT NULL
    , LevelType nvarchar(16) NOT NULL
    , CONSTRAINT PK_tbx_WorkQueueReleaseObjects
          PRIMARY KEY (ReleaseVersion, SchemaName, ObjectName)
);
INSERT INTO #tbx_WorkQueueReleaseObjects
    (ReleaseVersion,SchemaName,ObjectName,ObjectType,LevelType)
VALUES
  (N'1.0.0',N'toolbelt_core',N'WorkItem',N'U',N'TABLE')
 ,(N'1.0.0',N'toolbelt_core',N'VW_WorkQueue',N'V',N'VIEW')
 ,(N'1.0.0',N'toolbelt_core',N'USP_EnqueueWork',N'P',N'PROCEDURE')
 ,(N'1.0.0',N'toolbelt_core',N'USP_ClaimWork',N'P',N'PROCEDURE')
 ,(N'1.0.0',N'toolbelt_core',N'USP_CompleteWork',N'P',N'PROCEDURE')
 ,(N'1.0.0',N'toolbelt_core',N'USP_FailWork',N'P',N'PROCEDURE')
 ,(N'1.0.0',N'toolbelt_core',N'USP_GetWorkStatus',N'P',N'PROCEDURE');

INSERT INTO #tbx_WorkQueueReleaseObjects
    (ReleaseVersion,SchemaName,ObjectName,ObjectType,LevelType)
VALUES
  (N'1.1.0',N'toolbelt_core',N'WorkItem',N'U',N'TABLE')
 ,(N'1.1.0',N'toolbelt_core',N'VW_WorkQueue',N'V',N'VIEW')
 ,(N'1.1.0',N'toolbelt_core',N'USP_EnqueueWork',N'P',N'PROCEDURE')
 ,(N'1.1.0',N'toolbelt_core',N'USP_ClaimWork',N'P',N'PROCEDURE')
 ,(N'1.1.0',N'toolbelt_core',N'USP_RenewWorkLease',N'P',N'PROCEDURE')
 ,(N'1.1.0',N'toolbelt_core',N'USP_RecoverExpiredWork',N'P',N'PROCEDURE')
 ,(N'1.1.0',N'toolbelt_core',N'USP_CompleteWork',N'P',N'PROCEDURE')
 ,(N'1.1.0',N'toolbelt_core',N'USP_FailWork',N'P',N'PROCEDURE')
 ,(N'1.1.0',N'toolbelt_core',N'USP_GetWorkStatus',N'P',N'PROCEDURE');

INSERT INTO #tbx_WorkQueueReleaseObjects
    (ReleaseVersion,SchemaName,ObjectName,ObjectType,LevelType)
VALUES
  (N'2.0.0',N'toolbelt_core',N'WorkItem',N'U',N'TABLE')
 ,(N'2.0.0',N'toolbelt_core',N'WorkQueueScheduler',N'U',N'TABLE')
 ,(N'2.0.0',N'toolbelt_core',N'WorkQueueBarrierBlocker',N'U',N'TABLE')
 ,(N'2.0.0',N'toolbelt_core',N'VW_WorkQueue',N'V',N'VIEW')
 ,(N'2.0.0',N'toolbelt_core',N'VW_WorkQueueBarrierBlockers',N'V',N'VIEW')
 ,(N'2.0.0',N'toolbelt_core',N'USP_EnqueueWork',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_EnqueueWorkWithPolicy',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_EnqueueBarrierWork',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_ClaimWork',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_RenewWorkLease',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_RecoverExpiredWork',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_CompleteWork',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_FailWork',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_ScheduleWorkRetry',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_RequeueDeadLetter',N'P',N'PROCEDURE')
 ,(N'2.0.0',N'toolbelt_core',N'USP_GetWorkStatus',N'P',N'PROCEDURE');

INSERT INTO #tbx_WorkQueueReleaseObjects SELECT N'2.1.0',SchemaName,ObjectName,ObjectType,LevelType FROM #tbx_WorkQueueReleaseObjects WHERE ReleaseVersion=N'2.0.0';
INSERT INTO #tbx_WorkQueueReleaseObjects VALUES(N'2.1.0',N'toolbelt_core',N'WorkQueueManagedGate',N'U',N'TABLE'),(N'2.1.0',N'toolbelt_core',N'USP_ClaimWorkCore',N'P',N'PROCEDURE'),(N'2.1.0',N'toolbelt_core',N'USP_FailWorkCore',N'P',N'PROCEDURE'),(N'2.1.0',N'toolbelt_core',N'USP_ScheduleWorkRetryCore',N'P',N'PROCEDURE');

CREATE TABLE #tbx_WorkQueueDeployState
(TargetVersion nvarchar(64) NOT NULL,InstalledVersion nvarchar(64) NULL,DeploymentMode nvarchar(16) NOT NULL);

DECLARE @TargetVersion nvarchar(64)=N'2.1.0';
DECLARE @DeploymentMode nvarchar(16)=LOWER(N'$(DeploymentMode)');
DECLARE @VersionPropertyName sysname=N'Toolbelt.Module.toolbelt.core.work-queue.Version';
DECLARE @InstalledVersion nvarchar(64);
DECLARE @ProductMajorVersion int=TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion'));
DECLARE @ResultTableVersion nvarchar(64),@WorkTypeVersion nvarchar(64);

IF @ProductMajorVersion NOT IN(15,16,17)
    THROW 51940,N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.',1;
IF @DeploymentMode NOT IN(N'local',N'central')
    THROW 51941,N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.',1;

SELECT @ResultTableVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
SELECT @WorkTypeVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-type.Version';
IF ISNULL(@ResultTableVersion,N'') COLLATE Latin1_General_100_BIN2<>N'1.0.0'
 OR OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL
 OR ISNULL(@WorkTypeVersion,N'') COLLATE Latin1_General_100_BIN2<>N'1.1.0'
 OR OBJECT_ID(N'toolbelt_core.WorkType',N'U') IS NULL
    THROW 51942,N'toolbelt.core.result-table 1.0.0 und toolbelt.core.work-type 1.1.0 müssen in derselben Datenbank installiert sein.',1;

SELECT @InstalledVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
WHERE class=0 AND name=@VersionPropertyName;
IF @InstalledVersion IS NOT NULL AND @InstalledVersion COLLATE Latin1_General_100_BIN2 NOT IN(N'1.0.0',N'1.1.0',N'2.0.0',N'2.1.0')
    THROW 51943,N'Die installierte Modulversion ist diesem Deployment nicht als unterstütztes Release bekannt.',1;

IF EXISTS
(
    SELECT 1
    FROM #tbx_WorkQueueReleaseObjects r
    JOIN sys.schemas s
      ON s.name COLLATE Latin1_General_100_BIN2
         = r.SchemaName COLLATE Latin1_General_100_BIN2
    JOIN sys.objects o
      ON o.schema_id=s.schema_id
     AND o.name COLLATE Latin1_General_100_BIN2
         = r.ObjectName COLLATE Latin1_General_100_BIN2
    WHERE r.ReleaseVersion=@TargetVersion
      AND
      (
          @InstalledVersion IS NULL
          OR o.type COLLATE Latin1_General_100_BIN2
             <> r.ObjectType COLLATE Latin1_General_100_BIN2
          OR NOT EXISTS
             (
                 SELECT 1 FROM sys.extended_properties ep
                 WHERE ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
                   AND ep.name=N'Toolbelt.ModuleId'
                   AND CONVERT(nvarchar(256),ep.value)=N'toolbelt.core.work-queue'
             )
      )
)
    THROW 51944,N'Mindestens ein Work-Queue-Zielname ist neu oder inkonsistent durch ein nicht autorisiertes Objekt belegt.',1;

IF OBJECT_ID(N'toolbelt_core.WorkItem',N'U') IS NOT NULL
 AND EXISTS
 (
     SELECT required.ColumnName FROM (VALUES
       (N'WorkItemId'),(N'WorkTypeId'),(N'PayloadJson'),(N'Status'),(N'EnqueuedAtUtc'),(N'EnqueuedBy'),
       (N'ClaimedAtUtc'),(N'ClaimedBy'),(N'ClaimToken'),(N'CompletedAtUtc'),(N'CompletedBy'),
       (N'FailedAtUtc'),(N'FailedBy'),(N'FailureCode'),(N'FailureMessage'),(N'RowVersion'))required(ColumnName)
     WHERE NOT EXISTS
     (
         SELECT 1 FROM sys.columns c
         WHERE c.object_id=OBJECT_ID(N'toolbelt_core.WorkItem')
           AND c.name COLLATE Latin1_General_100_BIN2
               = required.ColumnName COLLATE Latin1_General_100_BIN2
     )
 )
    THROW 51943,N'Die vorhandene WorkItem-Tabelle entspricht keinem unterstützten Work-Queue-Vertrag.',2;

IF @InstalledVersion=N'1.1.0' AND EXISTS
(
    SELECT required.ColumnName FROM (VALUES
      (N'ClaimGeneration'),(N'LeaseDurationSeconds'),(N'LeaseUntilUtc'),(N'LastHeartbeatAtUtc'),
      (N'RecoveryCount'),(N'LastRecoveredAtUtc'),(N'LastRecoveredBy'))required(ColumnName)
    WHERE NOT EXISTS
    (
        SELECT 1 FROM sys.columns c
        WHERE c.object_id=OBJECT_ID(N'toolbelt_core.WorkItem')
          AND c.name COLLATE Latin1_General_100_BIN2=required.ColumnName COLLATE Latin1_General_100_BIN2
    )
)
    THROW 51943,N'Die vorhandene WorkItem-Tabelle entspricht nicht dem Version-1.1-Vertrag.',3;

IF @InstalledVersion IN(N'1.0.0',N'1.1.0')
BEGIN
    DECLARE @HasActiveLegacyClaim bit=0;
    EXEC sys.sp_executesql
         N'IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status=''CLAIMED'') SET @Value=1;',
         N'@Value bit OUTPUT',@Value=@HasActiveLegacyClaim OUTPUT;
    IF @HasActiveLegacyClaim=1
        THROW 51948,N'Das Upgrade auf Work Queue 2.0.0 ist mit aktiven Claims nicht zulässig; diese müssen zuerst fachlich abgeschlossen werden.',4;
END;

IF HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'ALTER')<>1
 OR HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE PROCEDURE')<>1
 OR HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE VIEW')<>1
 OR HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE')<>1
    THROW 51945,N'Für das Work-Queue-Deployment fehlen erforderliche DDL-Rechte.',1;

-- Eine installierte Consumergrenze wird nur für den exakten ruhenden Repeat geöffnet.
DECLARE @RepeatControl bit=CASE WHEN EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version')
 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(4000),value) COLLATE Latin1_General_100_BIN2=N'toolbelt.core.worker-control')
 OR EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_core') AND name COLLATE Latin1_General_100_BIN2 IN(N'WorkerControlConfiguration',N'WorkerRegistration',N'WorkerSlotReservation',N'WorkerExecutionDisposition',N'WorkerExecutionCommitWitness',N'VW_WorkerStatus',N'VW_WorkerExecutionStatus',N'USP_BeginWorkerCompletion',N'USP_BeginWorkerTransactionWitness',N'USP_BindWorkerExecution',N'USP_ClaimWorkerWork',N'USP_CloseWorker',N'USP_DisableManagedWorkers',N'USP_EnableManagedWorkers',N'USP_FinalizeWorkerFailure',N'USP_HeartbeatWorker',N'USP_ReconcileWorkerExecution',N'USP_RecordWorkerCommit',N'USP_RecordWorkerRollback',N'USP_RecordWorkerUnknown',N'USP_RegisterWorker',N'USP_ReleaseHeldWork',N'USP_ReserveWorkerExecution',N'USP_SetWorkerCapacity',N'USP_SetWorkerConcurrency',N'USP_SetWorkerIntervals',N'USP_SetWorkerState',N'USP_StopWorkerExecution',N'USP_StopWorkers')) THEN 1 ELSE 0 END;
DECLARE @RepeatGuard nvarchar(max);
IF @RepeatControl=1
BEGIN
:r RepeatInstalledControl.Preflight.sql
 SELECT @RepeatGuard=SqlText FROM #tbx_RepeatGuard;
END;
IF @RepeatControl=1 EXEC sys.sp_executesql @RepeatGuard,N'@Fence bit',@Fence=0;
ELSE
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version')
 THROW 54202,N'Der installierte Worker-Control-Consumer blockiert Queue-Lifecycle; zuerst dessen Lifecycle abschließen.',2;
IF OBJECT_ID(N'toolbelt_core.WorkQueueManagedGate',N'U') IS NOT NULL
BEGIN
 DECLARE @QueueManagedActive bit=NULL;
 EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;SELECT @active=ManagedEnabled FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1;',N'@active bit OUTPUT',@active=@QueueManagedActive OUTPUT;
 IF ISNULL(@QueueManagedActive,1)<>0 THROW 54202,N'Managed-Betrieb blockiert den Queue-Lifecycle.',1;
END;
IF COL_LENGTH(N'toolbelt_core.WorkItem',N'ManagedHold') IS NOT NULL
BEGIN
 DECLARE @QueueHasHeld bit=0;
 EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE ManagedHold=1 OR (ManagedReservationId IS NOT NULL AND Status=''CLAIMED'')) SET @held=1;',N'@held bit OUTPUT',@held=@QueueHasHeld OUTPUT;
 IF @QueueHasHeld=1 THROW 54202,N'Managedclaims oder Holds blockieren den Queue-Lifecycle.',3;
END;

INSERT INTO #tbx_WorkQueueDeployState VALUES(@TargetVersion,@InstalledVersion,@DeploymentMode);

BEGIN TRY
    BEGIN TRANSACTION;
    -- Gemeinsame Reihenfolge Control -> Queue verhindert Lifecycle-Lockzyklen.
    DECLARE @ControlLockResult int;
    EXEC @ControlLockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.core.worker-control',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
    IF @ControlLockResult<0 THROW 51946,N'Ein paralleler Worker-Control-Lifecycle ist bereits aktiv.',3;
    DECLARE @LockResult int;
    EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.core.work-queue',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
    IF @LockResult<0 THROW 51946,N'Ein paralleles Work-Queue-Deployment ist bereits aktiv.',1;

    DECLARE @CurrentVersion nvarchar(64);
    SELECT @CurrentVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=@VersionPropertyName;
    IF ISNULL(@CurrentVersion,N'') COLLATE Latin1_General_100_BIN2<>ISNULL(@InstalledVersion,N'') COLLATE Latin1_General_100_BIN2
        THROW 51946,N'Der installierte Modulstand hat sich seit dem Preflight verändert.',2;
IF @RepeatControl=0 AND (EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version')
 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(4000),value) COLLATE Latin1_General_100_BIN2=N'toolbelt.core.worker-control')
 OR EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_core') AND name COLLATE Latin1_General_100_BIN2 IN(N'WorkerControlConfiguration',N'WorkerRegistration',N'WorkerSlotReservation',N'WorkerExecutionDisposition',N'WorkerExecutionCommitWitness',N'VW_WorkerStatus',N'VW_WorkerExecutionStatus',N'USP_BeginWorkerCompletion',N'USP_BeginWorkerTransactionWitness',N'USP_BindWorkerExecution',N'USP_ClaimWorkerWork',N'USP_CloseWorker',N'USP_DisableManagedWorkers',N'USP_EnableManagedWorkers',N'USP_FinalizeWorkerFailure',N'USP_HeartbeatWorker',N'USP_ReconcileWorkerExecution',N'USP_RecordWorkerCommit',N'USP_RecordWorkerRollback',N'USP_RecordWorkerUnknown',N'USP_RegisterWorker',N'USP_ReleaseHeldWork',N'USP_ReserveWorkerExecution',N'USP_SetWorkerCapacity',N'USP_SetWorkerConcurrency',N'USP_SetWorkerIntervals',N'USP_SetWorkerState',N'USP_StopWorkerExecution',N'USP_StopWorkers'))) THROW 54202,N'Der installierte Worker-Control-Consumer blockiert Queue-Lifecycle; sein Stand hat sich seit Preflight verändert.',2;
IF @RepeatControl=1
BEGIN
 EXEC sys.sp_executesql @RepeatGuard,N'@Fence bit',@Fence=1;
 EXEC sys.sp_executesql @RepeatGuard,N'@Fence bit',@Fence=0;
END;
ELSE
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version')
 THROW 54202,N'Der installierte Worker-Control-Consumer blockiert Queue-Lifecycle; zuerst dessen Lifecycle abschließen.',2;
IF OBJECT_ID(N'toolbelt_core.WorkQueueManagedGate',N'U') IS NOT NULL
BEGIN
 SET @QueueManagedActive=NULL;
 EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;SELECT @active=ManagedEnabled FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1;',N'@active bit OUTPUT',@active=@QueueManagedActive OUTPUT;
 IF ISNULL(@QueueManagedActive,1)<>0 THROW 54202,N'Managed-Betrieb blockiert den Queue-Lifecycle.',1;
END;
IF COL_LENGTH(N'toolbelt_core.WorkItem',N'ManagedHold') IS NOT NULL
BEGIN
 SET @QueueHasHeld=0;
 EXEC sys.sp_executesql N'SET LOCK_TIMEOUT 0;IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE ManagedHold=1 OR (ManagedReservationId IS NOT NULL AND Status=''CLAIMED'')) SET @held=1;',N'@held bit OUTPUT',@held=@QueueHasHeld OUTPUT;
 IF @QueueHasHeld=1 THROW 54202,N'Managedclaims oder Holds blockieren den Queue-Lifecycle.',3;
END;
    IF @RepeatControl=1 SET LOCK_TIMEOUT 5000;
END TRY
BEGIN CATCH
    IF OBJECT_ID(N'tempdb..#tbx_RepeatGuard',N'U') IS NOT NULL SET LOCK_TIMEOUT -1;
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/WorkItem.sql
:r ../Source/WorkQueueManagedGate.sql
:r ../Source/USP_ClaimWorkCore.sql
:r ../Source/VW_WorkQueue.sql
:r ../Source/VW_WorkQueueBarrierBlockers.sql
:r ../Source/USP_EnqueueWork.sql
:r ../Source/USP_EnqueueWorkWithPolicy.sql
:r ../Source/USP_EnqueueBarrierWork.sql
:r ../Source/USP_ClaimWork.sql
:r ../Source/USP_RenewWorkLease.sql
:r ../Source/USP_RecoverExpiredWork.sql
:r ../Source/USP_CompleteWork.sql
:r ../Source/USP_FailWorkCore.sql
:r ../Source/USP_FailWork.sql
:r ../Source/USP_ScheduleWorkRetryCore.sql
:r ../Source/USP_ScheduleWorkRetry.sql
:r ../Source/USP_RequeueDeadLetter.sql
:r ../Source/USP_GetWorkStatus.sql

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    DECLARE @TargetVersion nvarchar(64),@DeploymentMode nvarchar(16),@InstalledVersion nvarchar(64);
    SELECT @TargetVersion=TargetVersion,@DeploymentMode=DeploymentMode,@InstalledVersion=InstalledVersion FROM #tbx_WorkQueueDeployState;
    IF XACT_STATE()<>1 OR EXISTS
    (
        SELECT 1 FROM #tbx_WorkQueueReleaseObjects r
        WHERE r.ReleaseVersion=@TargetVersion
          AND OBJECT_ID(QUOTENAME(r.SchemaName)+N'.'+QUOTENAME(r.ObjectName),r.ObjectType) IS NULL
    )
        THROW 51947,N'Die Work-Queue-Objekte wurden nicht vollständig innerhalb der Deployment-Transaktion angelegt.',1;

    DECLARE @ObjectName sysname,@LevelType nvarchar(16),@ObjectId int,@PropertyName sysname,@PropertyValue nvarchar(4000),@SourceHash varchar(64);
    DECLARE object_cursor CURSOR LOCAL FAST_FORWARD FOR
      SELECT ObjectName,LevelType FROM #tbx_WorkQueueReleaseObjects WHERE ReleaseVersion=@TargetVersion ORDER BY ObjectName;
    OPEN object_cursor; FETCH NEXT FROM object_cursor INTO @ObjectName,@LevelType;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @ObjectId=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(@ObjectName));
        SET @SourceHash=CONVERT(varchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@ObjectId))),2);
        DECLARE @Properties TABLE(PropertyName sysname NOT NULL,PropertyValue nvarchar(4000) NOT NULL);
        INSERT INTO @Properties VALUES
          (N'Toolbelt.ModuleId',N'toolbelt.core.work-queue'),(N'Toolbelt.ModuleVersion',@TargetVersion),
          (N'Toolbelt.ContractVersion',N'1.1'),(N'Toolbelt.DeploymentMode',@DeploymentMode),
          (N'Toolbelt.SourceHash',COALESCE(CONVERT(nvarchar(4000),@SourceHash),N'PERSISTENT_TABLE'));
        DECLARE property_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT PropertyName,PropertyValue FROM @Properties;
        OPEN property_cursor; FETCH NEXT FROM property_cursor INTO @PropertyName,@PropertyValue;
        WHILE @@FETCH_STATUS=0
        BEGIN
            IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=@PropertyName)
                EXEC sys.sp_updateextendedproperty @name=@PropertyName,@value=@PropertyValue,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
            ELSE
                EXEC sys.sp_addextendedproperty @name=@PropertyName,@value=@PropertyValue,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
            FETCH NEXT FROM property_cursor INTO @PropertyName,@PropertyValue;
        END;
        CLOSE property_cursor; DEALLOCATE property_cursor; DELETE FROM @Properties;
        FETCH NEXT FROM object_cursor INTO @ObjectName,@LevelType;
    END;
    CLOSE object_cursor; DEALLOCATE object_cursor;

    DECLARE @VersionPropertyName sysname=N'Toolbelt.Module.toolbelt.core.work-queue.Version';
    DECLARE @ModePropertyName sysname=N'Toolbelt.Module.toolbelt.core.work-queue.DeploymentMode';
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@VersionPropertyName)
        EXEC sys.sp_updateextendedproperty @name=@VersionPropertyName,@value=@TargetVersion;
    ELSE EXEC sys.sp_addextendedproperty @name=@VersionPropertyName,@value=@TargetVersion;
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModePropertyName)
        EXEC sys.sp_updateextendedproperty @name=@ModePropertyName,@value=@DeploymentMode;
    ELSE EXEC sys.sp_addextendedproperty @name=@ModePropertyName,@value=@DeploymentMode;
    COMMIT TRANSACTION;
    IF OBJECT_ID(N'tempdb..#tbx_RepeatGuard',N'U') IS NOT NULL SET LOCK_TIMEOUT -1;
:r RepeatInstalledControl.Cleanup.sql
END TRY
BEGIN CATCH
    IF OBJECT_ID(N'tempdb..#tbx_RepeatGuard',N'U') IS NOT NULL SET LOCK_TIMEOUT -1;
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
