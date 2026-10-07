-- Deployment-interner exakter Wiederholungsvertrag: Queue2.1 und Control1.0.
-- Erwartete private Tempformen liefern denselben SQL-Katalogserializer für Checks/Defaults.
-- Keine Laufzeit-API, keine Datenadoption und keine persistenten Änderungen.

CREATE TABLE #tbx_Repeat_WorkItem
(
 [WorkItemId] bigint IDENTITY(1,1) NOT NULL,
 [WorkTypeId] bigint NOT NULL,
 [PayloadJson] nvarchar(max) COLLATE database_default NULL,
 [Status] varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL DEFAULT ('QUEUED'),
 [EnqueuedAtUtc] datetime2(7) NOT NULL DEFAULT (SYSUTCDATETIME()),
 [EnqueuedBy] sysname COLLATE database_default NOT NULL DEFAULT (ORIGINAL_LOGIN()),
 [ClaimedAtUtc] datetime2(7) NULL,
 [ClaimedBy] sysname COLLATE database_default NULL,
 [ClaimToken] uniqueidentifier NULL,
 [ClaimGeneration] bigint NOT NULL DEFAULT (0),
 [LeaseDurationSeconds] int NULL,
 [LeaseUntilUtc] datetime2(7) NULL,
 [LastHeartbeatAtUtc] datetime2(7) NULL,
 [RecoveryCount] bigint NOT NULL DEFAULT (0),
 [LastRecoveredAtUtc] datetime2(7) NULL,
 [LastRecoveredBy] sysname COLLATE database_default NULL,
 [CompletedAtUtc] datetime2(7) NULL,
 [CompletedBy] sysname COLLATE database_default NULL,
 [FailedAtUtc] datetime2(7) NULL,
 [FailedBy] sysname COLLATE database_default NULL,
 [FailureCode] varchar(64) COLLATE Latin1_General_100_BIN2 NULL,
 [FailureMessage] nvarchar(1000) COLLATE database_default NULL,
 [RowVersion] rowversion NOT NULL,
 PRIMARY KEY ([WorkItemId]),
 CHECK
          (
              [PayloadJson] IS NULL OR
              (DATALENGTH([PayloadJson]) <= 65536 AND ISJSON([PayloadJson]) = 1 AND LEFT(LTRIM([PayloadJson]), 1) = N'{')
          ),
 CHECK
          (
              [FailureCode] IS NULL OR
              (LEN([FailureCode]) BETWEEN 1 AND 64
               AND [FailureCode] LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2
               AND [FailureCode] NOT LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2)
          ),
 CHECK
          (
              ([RecoveryCount] = 0 AND [LastRecoveredAtUtc] IS NULL AND [LastRecoveredBy] IS NULL)
              OR ([RecoveryCount] > 0 AND [LastRecoveredAtUtc] IS NOT NULL AND [LastRecoveredBy] IS NOT NULL)
          ),
 ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL DEFAULT('default'),
 Priority tinyint NOT NULL DEFAULT(0),
 ExecutionMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL DEFAULT('SHARED'),
 IdempotencyKey varchar(128) COLLATE Latin1_General_100_BIN2 NULL,
 MaxAttempts tinyint NOT NULL DEFAULT(3),
 RetryBaseDelaySeconds int NOT NULL DEFAULT(60),
 RetryMaxDelaySeconds int NOT NULL DEFAULT(3600),
 RetryCycleNumber bigint NOT NULL DEFAULT(1),
 CycleAttemptCount bigint NOT NULL DEFAULT(0),
 NextAttemptAtUtc datetime2(7) NULL,
 LastErrorCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,
 LastErrorMessage nvarchar(1000) COLLATE database_default NULL,
 LastRetryScheduledAtUtc datetime2(7) NULL,
 LastRetryScheduledBy sysname COLLATE database_default NULL,
 DeadLetteredAtUtc datetime2(7) NULL,
 DeadLetteredBy sysname COLLATE database_default NULL,
 LastRequeuedAtUtc datetime2(7) NULL,
 LastRequeuedBy sysname COLLATE database_default NULL,
 LastRequeueReason nvarchar(1000) COLLATE database_default NULL,
 BarrierEpoch bigint NOT NULL DEFAULT(0),
 ManagedReservationId uniqueidentifier NULL,
 ManagedHold bit NOT NULL DEFAULT(0),
 ManagedCompletionNonce uniqueidentifier NULL,
 CHECK (Status IN ('QUEUED','BARRIER_WAIT','CLAIMED','RETRY_WAIT','COMPLETED','FAILED','DEAD_LETTER')),
 CHECK (Status IN ('QUEUED','BARRIER_WAIT','CLAIMED','RETRY_WAIT','COMPLETED','FAILED','DEAD_LETTER')),
 CHECK (ExecutionGroup<>'' AND ExecutionMode IN ('SHARED','DRAIN_BARRIER') AND MaxAttempts BETWEEN 1 AND 10
     AND RetryBaseDelaySeconds BETWEEN 1 AND 86400 AND RetryMaxDelaySeconds BETWEEN RetryBaseDelaySeconds AND 86400
     AND RetryCycleNumber>=1 AND CycleAttemptCount>=0 AND BarrierEpoch>=0)
);

CREATE TABLE #tbx_Repeat_WorkQueueScheduler
(
 SchedulerId tinyint NOT NULL PRIMARY KEY CHECK(SchedulerId=1)
);

CREATE TABLE #tbx_Repeat_WorkQueueBarrierBlocker
(
 BarrierWorkItemId bigint NOT NULL,
 BarrierEpoch bigint NOT NULL,
 BlockingWorkItemId bigint NOT NULL,
 BlockingClaimGeneration bigint NOT NULL,
 CapturedAtUtc datetime2(7) NOT NULL DEFAULT(SYSUTCDATETIME()),
 PRIMARY KEY(BarrierWorkItemId,BarrierEpoch,BlockingWorkItemId,BlockingClaimGeneration)
);

CREATE TABLE #tbx_Repeat_WorkQueueManagedGate
(
 GateId tinyint NOT NULL PRIMARY KEY,
 ManagedEnabled bit NOT NULL,
 AdmissionToken uniqueidentifier NOT NULL,
 PendingReservationId uniqueidentifier NULL,
 CHECK(GateId=1)
);

CREATE TABLE #tbx_Repeat_WorkerControlConfiguration
(
 ConfigurationId tinyint NOT NULL PRIMARY KEY,
 MaxConcurrentExecutions int NOT NULL,
 HeartbeatSeconds int NOT NULL,
 UnreachableSeconds int NOT NULL,
 ConfigVersion rowversion NOT NULL,
 CHECK(ConfigurationId=1),
 CHECK(MaxConcurrentExecutions>=0 AND HeartbeatSeconds BETWEEN 1 AND 3600 AND UnreachableSeconds BETWEEN 3 AND 86400 AND UnreachableSeconds>=3*HeartbeatSeconds)
);

CREATE TABLE #tbx_Repeat_WorkerRegistration
(
 WorkerId uniqueidentifier NOT NULL,
 WorkerGeneration bigint NOT NULL,
 WorkerToken uniqueidentifier NOT NULL,
 OwnerPrincipalId int NOT NULL,
 ProviderKind varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
 State varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
 AdmissionPaused bit NOT NULL,
 Capacity int NOT NULL,
 RunMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,
 LastHeartbeatAtUtc datetime2(7) NOT NULL,
 HeartbeatSeconds int NOT NULL,
 UnreachableSeconds int NOT NULL,
 PRIMARY KEY(WorkerId,WorkerGeneration),
 CHECK(WorkerGeneration>0),
 CHECK(State IN('ACTIVE','PAUSED','DRAINING','UNREACHABLE','CLOSED')),
 CHECK(Capacity>0),
 CHECK(RunMode IN('BOUNDED','CONTINUOUS'))
);

CREATE TABLE #tbx_Repeat_WorkerSlotReservation
(
 SlotReservationId uniqueidentifier NOT NULL PRIMARY KEY,
 WorkerId uniqueidentifier NOT NULL,
 WorkerGeneration bigint NOT NULL,
 WorkItemId bigint NOT NULL,
 ClaimGeneration bigint NOT NULL,
 ClaimToken uniqueidentifier NOT NULL,
 ExecutionId uniqueidentifier NOT NULL,
 State varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,
 IsOccupied bit NOT NULL,
 AttemptNonce uniqueidentifier NULL,
 BoundPrincipalId int NULL,
 CreatedAtUtc datetime2(7) NOT NULL,
 EndedAtUtc datetime2(7) NULL,
 UNIQUE(ExecutionId),
 UNIQUE(WorkItemId,ClaimGeneration),
 CHECK(State IN('RESERVED','RUNNING','STOP_REQUESTED','STOPPING','UNKNOWN','COMMITTED','ROLLED_BACK','CLOSED'))
);

CREATE TABLE #tbx_Repeat_WorkerExecutionDisposition
(
 WorkItemId bigint NOT NULL PRIMARY KEY,
 SlotReservationId uniqueidentifier NOT NULL,
 IsHeld bit NOT NULL,
 StopStatus varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,
 HoldVersion rowversion NOT NULL,
 CHECK(StopStatus IN('NONE','REQUESTED','STOPPING','ROLLED_BACK_HELD','ALREADY_COMMITTED','UNKNOWN'))
);

CREATE TABLE #tbx_Repeat_WorkerExecutionCommitWitness
(
 SlotReservationId uniqueidentifier NOT NULL PRIMARY KEY,
 AttemptNonce uniqueidentifier NOT NULL,
 ExecutionId uniqueidentifier NOT NULL,
 ClaimGeneration bigint NOT NULL,
 RecordedAtUtc datetime2(7) NOT NULL
);

CREATE UNIQUE NONCLUSTERED INDEX UX_WorkItem_WorkType_IdempotencyKey ON #tbx_Repeat_WorkItem(WorkTypeId,IdempotencyKey) WHERE IdempotencyKey IS NOT NULL;

CREATE NONCLUSTERED INDEX IX_WorkItem_Status_WorkItemId ON #tbx_Repeat_WorkItem(Status,WorkItemId) INCLUDE(WorkTypeId);
CREATE NONCLUSTERED INDEX IX_WorkItem_WorkTypeId_Status_WorkItemId ON #tbx_Repeat_WorkItem(WorkTypeId,Status,WorkItemId);
CREATE NONCLUSTERED INDEX IX_WorkItem_Status_LeaseUntilUtc_WorkItemId ON #tbx_Repeat_WorkItem(Status,LeaseUntilUtc,WorkItemId);
CREATE NONCLUSTERED INDEX IX_WorkItem_Scheduling ON #tbx_Repeat_WorkItem(Status,Priority DESC,ExecutionGroup,NextAttemptAtUtc,WorkItemId);

CREATE TABLE #tbx_RepeatTables(TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,ExpectedId int NOT NULL);
INSERT #tbx_RepeatTables VALUES
(N'WorkItem',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkItem',N'U')),
(N'WorkQueueScheduler',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkQueueScheduler',N'U')),
(N'WorkQueueBarrierBlocker',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkQueueBarrierBlocker',N'U')),
(N'WorkQueueManagedGate',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkQueueManagedGate',N'U')),
(N'WorkerControlConfiguration',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkerControlConfiguration',N'U')),
(N'WorkerRegistration',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkerRegistration',N'U')),
(N'WorkerSlotReservation',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkerSlotReservation',N'U')),
(N'WorkerExecutionDisposition',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkerExecutionDisposition',N'U')),
(N'WorkerExecutionCommitWitness',OBJECT_ID(N'tempdb..#tbx_Repeat_WorkerExecutionCommitWitness',N'U'));

CREATE TABLE #tbx_RepeatOwned(ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,ObjectType char(2) COLLATE Latin1_General_100_BIN2 NOT NULL,ModuleId nvarchar(256) COLLATE Latin1_General_100_BIN2 NOT NULL,ModuleVersion nvarchar(64) COLLATE Latin1_General_100_BIN2 NOT NULL,ContractVersion nvarchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #tbx_RepeatOwned VALUES
(N'WorkItem',N'U',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'WorkQueueScheduler',N'U',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'WorkQueueBarrierBlocker',N'U',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'VW_WorkQueue',N'V',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'VW_WorkQueueBarrierBlockers',N'V',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_EnqueueWork',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_EnqueueWorkWithPolicy',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_EnqueueBarrierWork',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_ClaimWork',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_RenewWorkLease',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_RecoverExpiredWork',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_CompleteWork',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_FailWork',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_ScheduleWorkRetry',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_RequeueDeadLetter',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_GetWorkStatus',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'WorkQueueManagedGate',N'U',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_ClaimWorkCore',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_FailWorkCore',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'USP_ScheduleWorkRetryCore',N'P',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'WorkerControlConfiguration',N'U',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'WorkerRegistration',N'U',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'WorkerSlotReservation',N'U',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'WorkerExecutionDisposition',N'U',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'WorkerExecutionCommitWitness',N'U',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'VW_WorkerStatus',N'V',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'VW_WorkerExecutionStatus',N'V',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_BeginWorkerCompletion',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_BeginWorkerTransactionWitness',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_BindWorkerExecution',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_ClaimWorkerWork',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_CloseWorker',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_DisableManagedWorkers',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_EnableManagedWorkers',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_FinalizeWorkerFailure',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_HeartbeatWorker',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_ReconcileWorkerExecution',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_RecordWorkerCommit',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_RecordWorkerRollback',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_RecordWorkerUnknown',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_RegisterWorker',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_ReleaseHeldWork',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_ReserveWorkerExecution',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_SetWorkerCapacity',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_SetWorkerConcurrency',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_SetWorkerIntervals',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_SetWorkerState',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_StopWorkerExecution',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'USP_StopWorkers',N'P',N'toolbelt.core.worker-control',N'1.0.0',N'1.0');

CREATE TABLE #tbx_RepeatForeignKeys(TableName sysname COLLATE Latin1_General_100_BIN2,KeyName sysname COLLATE Latin1_General_100_BIN2,ColumnName sysname COLLATE Latin1_General_100_BIN2,ReferencedTable sysname COLLATE Latin1_General_100_BIN2,ReferencedColumn sysname COLLATE Latin1_General_100_BIN2,Ordinal int);
INSERT #tbx_RepeatForeignKeys VALUES
(N'WorkItem',N'FK_WorkItem_WorkType',N'WorkTypeId',N'WorkType',N'WorkTypeId',1),
(N'WorkQueueBarrierBlocker',N'FK_WorkQueueBarrierBlocker_Barrier',N'BarrierWorkItemId',N'WorkItem',N'WorkItemId',1),
(N'WorkQueueBarrierBlocker',N'FK_WorkQueueBarrierBlocker_Blocking',N'BlockingWorkItemId',N'WorkItem',N'WorkItemId',1),
(N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkerRegistration',N'WorkerId',N'WorkerRegistration',N'WorkerId',1),
(N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkerRegistration',N'WorkerGeneration',N'WorkerRegistration',N'WorkerGeneration',2),
(N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkItem',N'WorkItemId',N'WorkItem',N'WorkItemId',1),
(N'WorkerExecutionDisposition',N'FK_WorkerExecutionDisposition_WorkItem',N'WorkItemId',N'WorkItem',N'WorkItemId',1),
(N'WorkerExecutionDisposition',N'FK_WorkerExecutionDisposition_Reservation',N'SlotReservationId',N'WorkerSlotReservation',N'SlotReservationId',1),
(N'WorkerExecutionCommitWitness',N'FK_WorkerExecutionCommitWitness_Reservation',N'SlotReservationId',N'WorkerSlotReservation',N'SlotReservationId',1);

CREATE TABLE #tbx_RepeatConstraintNames(TableName sysname COLLATE Latin1_General_100_BIN2,ConstraintName sysname COLLATE Latin1_General_100_BIN2,Kind char(1) COLLATE Latin1_General_100_BIN2,ColumnName sysname COLLATE Latin1_General_100_BIN2);
INSERT #tbx_RepeatConstraintNames VALUES
(N'WorkItem',N'DF_WorkItem_Status',N'D',N'Status'),
(N'WorkItem',N'DF_WorkItem_EnqueuedAtUtc',N'D',N'EnqueuedAtUtc'),
(N'WorkItem',N'DF_WorkItem_EnqueuedBy',N'D',N'EnqueuedBy'),
(N'WorkItem',N'DF_WorkItem_ClaimGeneration',N'D',N'ClaimGeneration'),
(N'WorkItem',N'DF_WorkItem_RecoveryCount',N'D',N'RecoveryCount'),
(N'WorkItem',N'CK_WorkItem_Status',N'C',N''),
(N'WorkItem',N'CK_WorkItem_PayloadJson',N'C',N''),
(N'WorkItem',N'CK_WorkItem_FailureCode',N'C',N''),
(N'WorkItem',N'CK_WorkItem_RecoveryMetadata',N'C',N''),
(N'WorkItem',N'CK_WorkItem_StateMetadata',N'C',N''),
(N'WorkQueueBarrierBlocker',N'DF_WorkQueueBarrierBlocker_CapturedAtUtc',N'D',N'CapturedAtUtc'),
(N'WorkQueueManagedGate',N'CK_WorkQueueManagedGate_Id',N'C',N''),
(N'WorkerControlConfiguration',N'CK_WorkerControlConfiguration_Id',N'C',N''),
(N'WorkerControlConfiguration',N'CK_WorkerControlConfiguration_Limits',N'C',N''),
(N'WorkerRegistration',N'CK_WorkerRegistration_Generation',N'C',N''),
(N'WorkerRegistration',N'CK_WorkerRegistration_State',N'C',N''),
(N'WorkerRegistration',N'CK_WorkerRegistration_Capacity',N'C',N''),
(N'WorkerRegistration',N'CK_WorkerRegistration_RunMode',N'C',N''),
(N'WorkerSlotReservation',N'CK_WorkerSlotReservation_State',N'C',N''),
(N'WorkerExecutionDisposition',N'CK_WorkerExecutionDisposition_Stop',N'C',N''),
(N'WorkItem',N'CK_WorkItem_W6cPolicy',N'C',N''),
(N'WorkItem',N'DF_WorkItem_ManagedHold',N'D',N'ManagedHold'),
(N'WorkItem',N'DF_WorkItem_ExecutionGroup',N'D',N'ExecutionGroup'),
(N'WorkItem',N'DF_WorkItem_Priority',N'D',N'Priority'),
(N'WorkItem',N'DF_WorkItem_ExecutionMode',N'D',N'ExecutionMode'),
(N'WorkItem',N'DF_WorkItem_MaxAttempts',N'D',N'MaxAttempts'),
(N'WorkItem',N'DF_WorkItem_RetryBaseDelaySeconds',N'D',N'RetryBaseDelaySeconds'),
(N'WorkItem',N'DF_WorkItem_RetryMaxDelaySeconds',N'D',N'RetryMaxDelaySeconds'),
(N'WorkItem',N'DF_WorkItem_RetryCycleNumber',N'D',N'RetryCycleNumber'),
(N'WorkItem',N'DF_WorkItem_CycleAttemptCount',N'D',N'CycleAttemptCount'),
(N'WorkItem',N'DF_WorkItem_BarrierEpoch',N'D',N'BarrierEpoch');

CREATE TABLE #tbx_RepeatGuard(SqlText nvarchar(max) NOT NULL);
INSERT #tbx_RepeatGuard VALUES(N'-- Bounded Metadaten- und Zustandsreads; SET wird mit dynamischem Scope zurückgesetzt.
SET LOCK_TIMEOUT 0;
-- Derselbe Guard läuft vor dem Lock und danach erneut unter allen Schreibfences.
IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N''DATABASE'',N''VIEW DEFINITION''),0)<>1
 THROW 54202,N''Installierter Control-Repeat benötigt vollständige vorhandene Metadatensicht.'',5;
IF EXISTS(SELECT 1 FROM (VALUES
 (N''Toolbelt.Module.toolbelt.core.work-queue.Version'',N''2.1.0''),
 (N''Toolbelt.Module.toolbelt.core.worker-control.Version'',N''1.0.0'')) required(PropertyName,ExpectedValue)
 WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=0 AND ep.name COLLATE Latin1_General_100_BIN2=required.PropertyName
 AND CONVERT(sysname,SQL_VARIANT_PROPERTY(ep.value,''BaseType''))=N''nvarchar''
 AND DATALENGTH(CONVERT(nvarchar(4000),ep.value))=DATALENGTH(required.ExpectedValue)
 AND CONVERT(nvarchar(4000),ep.value) COLLATE Latin1_General_100_BIN2=required.ExpectedValue))
 THROW 54202,N''Der installierte Worker-Control-Consumer blockiert Queue-Lifecycle; nur der vollständige Queue2.1/Control1.0-Repeat ist freigegeben.'',2;
IF EXISTS(SELECT 1 FROM #tbx_RepeatOwned expected
 LEFT JOIN sys.schemas s ON s.name COLLATE Latin1_General_100_BIN2=N''toolbelt_core''
 LEFT JOIN sys.objects actual ON actual.schema_id=s.schema_id AND actual.name COLLATE Latin1_General_100_BIN2=expected.ObjectName
 WHERE actual.object_id IS NULL OR actual.type COLLATE Latin1_General_100_BIN2<>expected.ObjectType COLLATE Latin1_General_100_BIN2
 OR EXISTS(SELECT 1 FROM (VALUES(N''Toolbelt.ModuleId'',expected.ModuleId),(N''Toolbelt.ModuleVersion'',expected.ModuleVersion),(N''Toolbelt.ContractVersion'',expected.ContractVersion)) required(PropertyName,ExpectedValue)
 WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=actual.object_id AND ep.minor_id=0
 AND ep.name COLLATE Latin1_General_100_BIN2=required.PropertyName AND CONVERT(sysname,SQL_VARIANT_PROPERTY(ep.value,''BaseType''))=N''nvarchar''
 AND DATALENGTH(CONVERT(nvarchar(4000),ep.value))=DATALENGTH(required.ExpectedValue)
 AND CONVERT(nvarchar(4000),ep.value) COLLATE Latin1_General_100_BIN2=required.ExpectedValue)))
 OR EXISTS(SELECT 1 FROM sys.extended_properties ep JOIN sys.objects o ON ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
 WHERE ep.name=N''Toolbelt.ModuleId'' AND CONVERT(nvarchar(4000),ep.value) COLLATE Latin1_General_100_BIN2 IN(N''toolbelt.core.work-queue'',N''toolbelt.core.worker-control'')
 AND NOT EXISTS(SELECT 1 FROM #tbx_RepeatOwned expected WHERE o.schema_id=SCHEMA_ID(N''toolbelt_core'') AND o.name COLLATE Latin1_General_100_BIN2=expected.ObjectName))
 THROW 54202,N''Der bekannte installierte Queue-/Control-Objektstand ist unvollständig oder inkonsistent markiert.'',5;

IF EXISTS(SELECT 1 FROM #tbx_RepeatTables t CROSS APPLY(SELECT OBJECT_ID(N''toolbelt_core.''+QUOTENAME(t.TableName),N''U'') ActualId) ids
 WHERE EXISTS(SELECT c.name COLLATE Latin1_General_100_BIN2,c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,c.is_identity,c.is_computed,c.is_rowguidcol,c.is_sparse,c.is_column_set,c.generated_always_type,ISNULL(c.collation_name,N'''') COLLATE Latin1_General_100_BIN2
 FROM sys.columns c WHERE c.object_id=ids.ActualId
 EXCEPT SELECT c.name COLLATE Latin1_General_100_BIN2,c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,c.is_identity,c.is_computed,c.is_rowguidcol,c.is_sparse,c.is_column_set,c.generated_always_type,ISNULL(c.collation_name,N'''') COLLATE Latin1_General_100_BIN2 FROM tempdb.sys.columns c WHERE c.object_id=t.ExpectedId)
 OR EXISTS(SELECT c.name COLLATE Latin1_General_100_BIN2,c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,c.is_identity,c.is_computed,c.is_rowguidcol,c.is_sparse,c.is_column_set,c.generated_always_type,ISNULL(c.collation_name,N'''') COLLATE Latin1_General_100_BIN2
 FROM tempdb.sys.columns c WHERE c.object_id=t.ExpectedId
 EXCEPT SELECT c.name COLLATE Latin1_General_100_BIN2,c.system_type_id,c.user_type_id,c.max_length,c.precision,c.scale,c.is_nullable,c.is_identity,c.is_computed,c.is_rowguidcol,c.is_sparse,c.is_column_set,c.generated_always_type,ISNULL(c.collation_name,N'''') COLLATE Latin1_General_100_BIN2 FROM sys.columns c WHERE c.object_id=ids.ActualId)
 OR EXISTS(SELECT 1 FROM sys.tables a WHERE a.object_id=ids.ActualId AND(a.is_memory_optimized=1 OR a.temporal_type<>0 OR a.is_filetable=1))
 OR EXISTS(SELECT 1 FROM sys.identity_columns a JOIN tempdb.sys.identity_columns e ON e.object_id=t.ExpectedId AND e.name COLLATE Latin1_General_100_BIN2=a.name COLLATE Latin1_General_100_BIN2
 WHERE a.object_id=ids.ActualId AND(CONVERT(bigint,a.seed_value)<>CONVERT(bigint,e.seed_value) OR CONVERT(bigint,a.increment_value)<>CONVERT(bigint,e.increment_value) OR a.is_not_for_replication<>e.is_not_for_replication)))
 THROW 54202,N''Die installierte persistente Queue-/Control-Tabellenform entspricht nicht dem aktuellen bekannten Vertrag.'',5;

-- Alle fünf kanonischen WorkItem-Indizes einschließlich INCLUDE-/Filtersemantik;
-- fremde zusätzliche Indexnamen werden weder geprüft noch verändert.
CREATE TABLE #tbx_RepeatIndexes(Side bit,IndexName sysname COLLATE Latin1_General_100_BIN2,IndexType tinyint,IsUnique bit,HasFilter bit,ColumnSignature nvarchar(max) COLLATE Latin1_General_100_BIN2);
INSERT #tbx_RepeatIndexes
SELECT 0,i.name,i.type,i.is_unique,i.has_filter,
 STRING_AGG(CONVERT(nvarchar(max),CONCAT(ic.index_column_id,N'':'',ic.key_ordinal,N'':'',c.name,N'':'',ic.is_descending_key,N'':'',ic.is_included_column)),N''|'') WITHIN GROUP(ORDER BY ic.index_column_id)
FROM #tbx_RepeatTables t JOIN tempdb.sys.indexes i ON i.object_id=t.ExpectedId
JOIN tempdb.sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
JOIN tempdb.sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE t.TableName=N''WorkItem'' AND i.is_primary_key=0
GROUP BY i.index_id,i.name,i.type,i.is_unique,i.has_filter;
INSERT #tbx_RepeatIndexes
SELECT 1,i.name,i.type,i.is_unique,i.has_filter,
 STRING_AGG(CONVERT(nvarchar(max),CONCAT(ic.index_column_id,N'':'',ic.key_ordinal,N'':'',c.name,N'':'',ic.is_descending_key,N'':'',ic.is_included_column)),N''|'') WITHIN GROUP(ORDER BY ic.index_column_id)
FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE i.object_id=OBJECT_ID(N''toolbelt_core.WorkItem'',N''U'') AND i.name COLLATE Latin1_General_100_BIN2 IN(SELECT IndexName FROM #tbx_RepeatIndexes WHERE Side=0)
AND i.is_disabled=0 AND i.is_hypothetical=0 AND i.is_primary_key=0 AND i.is_unique_constraint=0
GROUP BY i.index_id,i.name,i.type,i.is_unique,i.has_filter;
IF EXISTS(SELECT IndexName,IndexType,IsUnique,HasFilter,ColumnSignature FROM #tbx_RepeatIndexes WHERE Side=0
 EXCEPT SELECT IndexName,IndexType,IsUnique,HasFilter,ColumnSignature FROM #tbx_RepeatIndexes WHERE Side=1)
 OR EXISTS(SELECT IndexName,IndexType,IsUnique,HasFilter,ColumnSignature FROM #tbx_RepeatIndexes WHERE Side=1
 EXCEPT SELECT IndexName,IndexType,IsUnique,HasFilter,ColumnSignature FROM #tbx_RepeatIndexes WHERE Side=0)
 THROW 54202,N''Die installierten kanonischen WorkItem-Indizes entsprechen nicht dem aktuellen Queuevertrag.'',5;
-- Geordnete Signaturen pro Schlüssel verhindern ein Vertauschen von UQ-Spaltengruppen.
CREATE TABLE #tbx_RepeatKeys(Side bit,TableName sysname COLLATE Latin1_General_100_BIN2,IsPrimary bit,IsUniqueConstraint bit,IndexType tinyint,ColumnSignature nvarchar(max) COLLATE Latin1_General_100_BIN2);
INSERT #tbx_RepeatKeys
SELECT 0,t.TableName,i.is_primary_key,i.is_unique_constraint,i.type,
 STRING_AGG(CONVERT(nvarchar(max),CONCAT(ic.key_ordinal,N'':'',c.name,N'':'',ic.is_descending_key)),N''|'') WITHIN GROUP(ORDER BY ic.key_ordinal)
FROM #tbx_RepeatTables t JOIN tempdb.sys.indexes i ON i.object_id=t.ExpectedId
JOIN tempdb.sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
JOIN tempdb.sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE (i.is_primary_key=1 OR i.is_unique_constraint=1)
GROUP BY t.TableName,i.index_id,i.is_primary_key,i.is_unique_constraint,i.type;
INSERT #tbx_RepeatKeys
SELECT 1,t.TableName,i.is_primary_key,i.is_unique_constraint,i.type,
 STRING_AGG(CONVERT(nvarchar(max),CONCAT(ic.key_ordinal,N'':'',c.name,N'':'',ic.is_descending_key)),N''|'') WITHIN GROUP(ORDER BY ic.key_ordinal)
FROM #tbx_RepeatTables t JOIN sys.indexes i ON i.object_id=OBJECT_ID(N''toolbelt_core.''+QUOTENAME(t.TableName),N''U'')
JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id
JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id
WHERE (i.is_primary_key=1 OR i.is_unique_constraint=1) AND i.is_unique=1 AND i.is_disabled=0 AND i.is_hypothetical=0 AND i.has_filter=0
GROUP BY t.TableName,i.index_id,i.is_primary_key,i.is_unique_constraint,i.type;
IF EXISTS(SELECT TableName,IsPrimary,IsUniqueConstraint,IndexType,ColumnSignature,COUNT_BIG(*) FROM #tbx_RepeatKeys WHERE Side=0 GROUP BY TableName,IsPrimary,IsUniqueConstraint,IndexType,ColumnSignature
 EXCEPT SELECT TableName,IsPrimary,IsUniqueConstraint,IndexType,ColumnSignature,COUNT_BIG(*) FROM #tbx_RepeatKeys WHERE Side=1 GROUP BY TableName,IsPrimary,IsUniqueConstraint,IndexType,ColumnSignature)
 OR EXISTS(SELECT TableName,IsPrimary,IsUniqueConstraint,IndexType,ColumnSignature,COUNT_BIG(*) FROM #tbx_RepeatKeys WHERE Side=1 GROUP BY TableName,IsPrimary,IsUniqueConstraint,IndexType,ColumnSignature
 EXCEPT SELECT TableName,IsPrimary,IsUniqueConstraint,IndexType,ColumnSignature,COUNT_BIG(*) FROM #tbx_RepeatKeys WHERE Side=0 GROUP BY TableName,IsPrimary,IsUniqueConstraint,IndexType,ColumnSignature)
 THROW 54202,N''Die installierten Queue-/Control-Schlüssel sind nicht kanonisch oder nicht aktiviert.'',5;
DROP TABLE #tbx_RepeatKeys;
IF EXISTS(SELECT TableName,KeyName,ColumnName,ReferencedTable,ReferencedColumn,Ordinal FROM #tbx_RepeatForeignKeys
 EXCEPT SELECT t.TableName,f.name COLLATE Latin1_General_100_BIN2,pc.name COLLATE Latin1_General_100_BIN2,rt.name COLLATE Latin1_General_100_BIN2,rc.name COLLATE Latin1_General_100_BIN2,fc.constraint_column_id
 FROM #tbx_RepeatTables t JOIN sys.foreign_keys f ON f.parent_object_id=OBJECT_ID(N''toolbelt_core.''+QUOTENAME(t.TableName),N''U'')
 JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id
 JOIN sys.tables rt ON rt.object_id=fc.referenced_object_id JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id
 WHERE rt.schema_id=SCHEMA_ID(N''toolbelt_core'') AND f.is_disabled=0 AND f.is_not_trusted=0 AND f.is_not_for_replication=0 AND f.delete_referential_action=0 AND f.update_referential_action=0)
 OR EXISTS(SELECT t.TableName,f.name COLLATE Latin1_General_100_BIN2,pc.name COLLATE Latin1_General_100_BIN2,rt.name COLLATE Latin1_General_100_BIN2,rc.name COLLATE Latin1_General_100_BIN2,fc.constraint_column_id
 FROM #tbx_RepeatTables t JOIN sys.foreign_keys f ON f.parent_object_id=OBJECT_ID(N''toolbelt_core.''+QUOTENAME(t.TableName),N''U'')
 JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id
 JOIN sys.tables rt ON rt.object_id=fc.referenced_object_id JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id
 EXCEPT SELECT TableName,KeyName,ColumnName,ReferencedTable,ReferencedColumn,Ordinal FROM #tbx_RepeatForeignKeys)
 THROW 54202,N''Die installierten Queue-/Control-Fremdschlüssel sind nicht kanonisch oder nicht vertrauenswürdig.'',5;

-- Kanonische feste Namen verhindern, dass Source-Drops/Defaultgates neue Duplikate erzeugen.
IF EXISTS(SELECT 1 FROM #tbx_RepeatConstraintNames expected
 WHERE (expected.Kind=''C'' AND NOT EXISTS(SELECT 1 FROM sys.check_constraints actual WHERE actual.parent_object_id=OBJECT_ID(N''toolbelt_core.''+QUOTENAME(expected.TableName),N''U'') AND actual.name COLLATE Latin1_General_100_BIN2=expected.ConstraintName))
 OR (expected.Kind=''D'' AND NOT EXISTS(SELECT 1 FROM sys.default_constraints actual JOIN sys.columns col ON col.object_id=actual.parent_object_id AND col.column_id=actual.parent_column_id
 WHERE actual.parent_object_id=OBJECT_ID(N''toolbelt_core.''+QUOTENAME(expected.TableName),N''U'') AND actual.name COLLATE Latin1_General_100_BIN2=expected.ConstraintName AND col.name COLLATE Latin1_General_100_BIN2=expected.ColumnName)))
 THROW 54202,N''Die installierten festen Check-/Defaultnamen entsprechen nicht dem Source-Lifecyclevertrag.'',5;
-- Literale bleiben bytegetreu; nur Leerraum/Identifierklammern außerhalb von Literalen
-- werden normalisiert. Klammern des Ausdrucks bleiben erhalten: keine geratenen Äquivalenzen.
CREATE TABLE #tbx_RepeatDefinitions(Side bit,TableName sysname COLLATE Latin1_General_100_BIN2,Kind char(1) COLLATE Latin1_General_100_BIN2,ColumnId sysname COLLATE Latin1_General_100_BIN2,Definition nvarchar(max) COLLATE Latin1_General_100_BIN2,Normalized nvarchar(max) COLLATE Latin1_General_100_BIN2);
INSERT #tbx_RepeatDefinitions SELECT 0,t.TableName,''C'',ISNULL((SELECT col.name COLLATE Latin1_General_100_BIN2 FROM tempdb.sys.columns col WHERE col.object_id=c.parent_object_id AND col.column_id=c.parent_column_id),N''''),c.definition,NULL FROM #tbx_RepeatTables t JOIN tempdb.sys.check_constraints c ON c.parent_object_id=t.ExpectedId;
INSERT #tbx_RepeatDefinitions SELECT 1,t.TableName,''C'',ISNULL((SELECT col.name COLLATE Latin1_General_100_BIN2 FROM sys.columns col WHERE col.object_id=c.parent_object_id AND col.column_id=c.parent_column_id),N''''),c.definition,NULL FROM #tbx_RepeatTables t JOIN sys.check_constraints c ON c.parent_object_id=OBJECT_ID(N''toolbelt_core.''+QUOTENAME(t.TableName),N''U'');
INSERT #tbx_RepeatDefinitions SELECT 0,t.TableName,''D'',ISNULL((SELECT col.name COLLATE Latin1_General_100_BIN2 FROM tempdb.sys.columns col WHERE col.object_id=c.parent_object_id AND col.column_id=c.parent_column_id),N''''),c.definition,NULL FROM #tbx_RepeatTables t JOIN tempdb.sys.default_constraints c ON c.parent_object_id=t.ExpectedId;
INSERT #tbx_RepeatDefinitions SELECT 1,t.TableName,''D'',ISNULL((SELECT col.name COLLATE Latin1_General_100_BIN2 FROM sys.columns col WHERE col.object_id=c.parent_object_id AND col.column_id=c.parent_column_id),N''''),c.definition,NULL FROM #tbx_RepeatTables t JOIN sys.default_constraints c ON c.parent_object_id=OBJECT_ID(N''toolbelt_core.''+QUOTENAME(t.TableName),N''U'');
INSERT #tbx_RepeatDefinitions SELECT 0,N''WorkItem'',''I'',i.name,i.filter_definition,NULL FROM #tbx_RepeatTables t JOIN tempdb.sys.indexes i ON i.object_id=t.ExpectedId WHERE t.TableName=N''WorkItem'' AND i.is_primary_key=0;
INSERT #tbx_RepeatDefinitions SELECT 1,N''WorkItem'',''I'',i.name,i.filter_definition,NULL FROM sys.indexes i WHERE i.object_id=OBJECT_ID(N''toolbelt_core.WorkItem'',N''U'') AND i.name COLLATE Latin1_General_100_BIN2 IN(SELECT IndexName FROM #tbx_RepeatIndexes WHERE Side=0);
DECLARE @Definition nvarchar(max),@Normalized nvarchar(max),@Pos int,@Quoted bit,@Char nchar(1);
DECLARE definition_cursor CURSOR LOCAL FOR SELECT Definition,Normalized FROM #tbx_RepeatDefinitions FOR UPDATE OF Normalized;
OPEN definition_cursor;FETCH NEXT FROM definition_cursor INTO @Definition,@Normalized;
WHILE @@FETCH_STATUS=0
BEGIN
 SET @Normalized=N'''';SET @Pos=1;SET @Quoted=0;
 WHILE @Pos<=DATALENGTH(@Definition)/2
 BEGIN
  SET @Char=SUBSTRING(@Definition,@Pos,1);
  IF @Char=N''''''''
  BEGIN
   SET @Normalized+=@Char;
   IF @Quoted=1 AND SUBSTRING(@Definition,@Pos+1,1)=N'''''''' BEGIN SET @Normalized+=N'''''''';SET @Pos+=1;END
   ELSE SET @Quoted=1-@Quoted;
  END
  ELSE IF @Quoted=1 SET @Normalized+=@Char;
  ELSE IF UNICODE(@Char) NOT IN(9,10,13,32,91,93) SET @Normalized+=UPPER(@Char COLLATE Latin1_General_100_BIN2);
  SET @Pos+=1;
 END;
 IF @Quoted=1 THROW 54202,N''Nicht unterstützte Check-/Defaultdefinition blockiert Repeat.'',5;
 UPDATE #tbx_RepeatDefinitions SET Normalized=@Normalized WHERE CURRENT OF definition_cursor;
 FETCH NEXT FROM definition_cursor INTO @Definition,@Normalized;
END;
CLOSE definition_cursor;DEALLOCATE definition_cursor;
IF EXISTS(SELECT TableName,Kind,ColumnId,Normalized,COUNT_BIG(*) CountDefinitions FROM #tbx_RepeatDefinitions WHERE Side=0 GROUP BY TableName,Kind,ColumnId,Normalized
 EXCEPT SELECT TableName,Kind,ColumnId,Normalized,COUNT_BIG(*) FROM #tbx_RepeatDefinitions WHERE Side=1 GROUP BY TableName,Kind,ColumnId,Normalized)
 OR EXISTS(SELECT TableName,Kind,ColumnId,Normalized,COUNT_BIG(*) FROM #tbx_RepeatDefinitions WHERE Side=1 GROUP BY TableName,Kind,ColumnId,Normalized
 EXCEPT SELECT TableName,Kind,ColumnId,Normalized,COUNT_BIG(*) FROM #tbx_RepeatDefinitions WHERE Side=0 GROUP BY TableName,Kind,ColumnId,Normalized)
 OR EXISTS(SELECT 1 FROM #tbx_RepeatTables t JOIN sys.check_constraints c ON c.parent_object_id=OBJECT_ID(N''toolbelt_core.''+QUOTENAME(t.TableName),N''U'') WHERE c.is_disabled=1 OR c.is_not_trusted=1 OR c.is_not_for_replication=1)
 THROW 54202,N''Die installierten Queue-/Control-Checks oder Defaults sind nicht kanonisch und vertrauenswürdig.'',5;
DROP TABLE #tbx_RepeatDefinitions;
DROP TABLE #tbx_RepeatIndexes;

IF @Fence=1
BEGIN
 -- LOCK_TIMEOUT ist nur in diesem dynamischen Scope gesetzt. TOP(1) führt den
 -- Tabellenzugriff auch bei leeren Historytabellen aus und hält X-Fences bis Commit.
 EXEC sys.sp_executesql N''SET LOCK_TIMEOUT 0;
 DECLARE @FenceValue int;
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkQueueManagedGate WITH(TABLOCKX,HOLDLOCK);
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkQueueScheduler WITH(TABLOCKX,HOLDLOCK);
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkerControlConfiguration WITH(TABLOCKX,HOLDLOCK);
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkerRegistration WITH(TABLOCKX,HOLDLOCK);
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkerSlotReservation WITH(TABLOCKX,HOLDLOCK);
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkerExecutionDisposition WITH(TABLOCKX,HOLDLOCK);
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkerExecutionCommitWitness WITH(TABLOCKX,HOLDLOCK);
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkItem WITH(TABLOCKX,HOLDLOCK);
 SELECT TOP(1) @FenceValue=1 FROM toolbelt_core.WorkQueueBarrierBlocker WITH(TABLOCKX,HOLDLOCK);
'';
END;
EXEC sys.sp_executesql N''-- Lockbasierte aktuelle Reads auch bei Caller-SNAPSHOT/RCSI; keine SET-Isolationsänderung.
IF (SELECT COUNT_BIG(*) FROM toolbelt_core.WorkQueueManagedGate WITH(READCOMMITTEDLOCK))<>1
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WITH(READCOMMITTEDLOCK) WHERE GateId=1 AND ManagedEnabled=0 AND PendingReservationId IS NULL)
 OR (SELECT COUNT_BIG(*) FROM toolbelt_core.WorkQueueScheduler WITH(READCOMMITTEDLOCK))<>1
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueScheduler WITH(READCOMMITTEDLOCK) WHERE SchedulerId=1)
 OR (SELECT COUNT_BIG(*) FROM toolbelt_core.WorkerControlConfiguration WITH(READCOMMITTEDLOCK))<>1
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerControlConfiguration WITH(READCOMMITTEDLOCK) WHERE ConfigurationId=1)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WITH(READCOMMITTEDLOCK) WHERE Status=''''CLAIMED'''' OR ManagedHold=1)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation WITH(READCOMMITTEDLOCK) WHERE IsOccupied=1 OR State NOT IN(''''COMMITTED'''',''''ROLLED_BACK'''',''''CLOSED'''') OR EndedAtUtc IS NULL)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition WITH(READCOMMITTEDLOCK) WHERE IsHeld=1 OR StopStatus NOT IN(''''NONE'''',''''ALREADY_COMMITTED''''))
 THROW 54202,N''''Der installierte Worker-Control-Consumer blockiert Queue-Lifecycle; Managedgate, Claims, ausstehende Bindung oder nichtterminale Control-History verhindern Repeat.'''',4;
'';
');
