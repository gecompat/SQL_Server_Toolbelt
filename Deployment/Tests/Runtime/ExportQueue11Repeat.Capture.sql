-- Privater Current-Repeat nach Genuine Queue1.1: alle 14 Tabellen/156 Felder, auch fünf leere Tabellen.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 THROW 55013,N'Der Queue11-Repeat verlangt eine neutrale Sitzung.',1;
IF XACT_STATE()<>0 THROW 55013,N'Der Queue11-Repeat verlangt eine neutrale Sitzung.',1;
IF (@@OPTIONS&2)<>0 THROW 55013,N'Der Queue11-Repeat verlangt eine neutrale Sitzung.',1;
IF @@LOCK_TIMEOUT<>-1 THROW 55013,N'Der Queue11-Repeat verlangt eine neutrale Sitzung.',1;
CREATE TABLE #tbx_ExportObjects(ObjectId int NOT NULL PRIMARY KEY,SchemaName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ObjectType char(2) COLLATE Latin1_General_100_BIN2 NOT NULL);
INSERT #tbx_ExportObjects
 SELECT o.object_id,s.name,o.name,o.type FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
 JOIN sys.extended_properties p ON p.class=1 AND p.major_id=o.object_id AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleId'
 WHERE CONVERT(nvarchar(256),p.value) IN(N'toolbelt.core.execution-context',N'toolbelt.core.result-table',N'toolbelt.file.content',N'toolbelt.core.execution-cancel',N'toolbelt.core.work-type',N'toolbelt.core.second-session',N'toolbelt.core.work-queue',N'toolbelt.core.event-log',N'toolbelt.core.worker-control');
-- File Content verwendet Datenbankmarker und keinen Object-Level-ModuleId.
INSERT #tbx_ExportObjects SELECT o.object_id,s.name,o.name,o.type FROM sys.objects o JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE s.name=N'toolbelt_file' AND o.name IN(N'FileContentRootAllowlist',N'USP_LoadBinaryFile',N'USP_LoadTextFile')
 AND NOT EXISTS(SELECT 1 FROM #tbx_ExportObjects x WHERE x.ObjectId=o.object_id);
IF (SELECT COUNT(*) FROM #tbx_ExportObjects WHERE ObjectType='U')<>14
 OR EXISTS(SELECT TableName FROM(VALUES(N'WorkType'),(N'WorkItem'),(N'WorkQueueScheduler'),(N'WorkQueueBarrierBlocker'),(N'WorkQueueManagedGate'),(N'WorkerControlConfiguration'),(N'WorkerRegistration'),(N'WorkerSlotReservation'),(N'WorkerExecutionDisposition'),(N'WorkerExecutionCommitWitness'),(N'ExecutionCancellation'),(N'SecondSessionProvider'),(N'EventLog'))v(TableName)
 EXCEPT SELECT ObjectName FROM #tbx_ExportObjects WHERE ObjectType='U' AND SchemaName=N'toolbelt_core')
 OR NOT EXISTS(SELECT 1 FROM #tbx_ExportObjects WHERE ObjectType='U' AND SchemaName=N'toolbelt_file' AND ObjectName=N'FileContentRootAllowlist')
 THROW 55013,N'Exportsnapshot erwartet genau 14 persistente Tabellen.',2;
-- Alle positiven Bindungen stammen aus den neun aktuellen Modulmanifesten.
CREATE TABLE #tbx_Queue11RepeatObjects(SchemaName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ObjectType char(2) COLLATE Latin1_General_100_BIN2 NOT NULL,PRIMARY KEY(SchemaName,ObjectName));
INSERT #tbx_Queue11RepeatObjects VALUES
 (N'toolbelt_core',N'TVF_CurrentExecutionContext','IF'),
 (N'toolbelt_core',N'SVF_CurrentExecutionId','FN'),
 (N'toolbelt_core',N'USP_BeginExecution','P'),
 (N'toolbelt_core',N'USP_SetExecutionContext','P'),
 (N'toolbelt_core',N'USP_EndExecution','P'),
 (N'toolbelt_core',N'USP_PrepareResultTable','P'),
 (N'toolbelt_file',N'FileContentRootAllowlist','U'),
 (N'toolbelt_file',N'USP_LoadBinaryFile','P'),
 (N'toolbelt_file',N'USP_LoadTextFile','P'),
 (N'toolbelt_core',N'ExecutionCancellation','U'),
 (N'toolbelt_core',N'TVF_ExecutionCancellationStatus','IF'),
 (N'toolbelt_core',N'SVF_IsCancellationRequested','FN'),
 (N'toolbelt_core',N'USP_RequestExecutionCancellation','P'),
 (N'toolbelt_core',N'WorkType','U'),
 (N'toolbelt_core',N'VW_WorkTypes','V'),
 (N'toolbelt_core',N'USP_RegisterWorkType','P'),
 (N'toolbelt_core',N'USP_DisableWorkType','P'),
 (N'toolbelt_core',N'USP_RemoveWorkType','P'),
 (N'toolbelt_core',N'USP_ResolveWorkType','P'),
 (N'toolbelt_core',N'SecondSessionProvider','U'),
 (N'toolbelt_core',N'VW_SecondSessionProviders','V'),
 (N'toolbelt_core',N'USP_ConfigureSecondSessionLoopback','P'),
 (N'toolbelt_core',N'USP_ExecuteWorkTypeInNewSession','P'),
 (N'toolbelt_core',N'USP_SecondSessionProbe','P'),
 (N'toolbelt_core',N'USP_DispatchWorkType','P'),
 (N'toolbelt_core',N'USP_FailWorkCore','P'),
 (N'toolbelt_core',N'USP_ScheduleWorkRetryCore','P'),
 (N'toolbelt_core',N'WorkQueueManagedGate','U'),
 (N'toolbelt_core',N'USP_ClaimWorkCore','P'),
 (N'toolbelt_core',N'WorkItem','U'),
 (N'toolbelt_core',N'WorkQueueScheduler','U'),
 (N'toolbelt_core',N'WorkQueueBarrierBlocker','U'),
 (N'toolbelt_core',N'VW_WorkQueue','V'),
 (N'toolbelt_core',N'VW_WorkQueueBarrierBlockers','V'),
 (N'toolbelt_core',N'USP_EnqueueWork','P'),
 (N'toolbelt_core',N'USP_EnqueueWorkWithPolicy','P'),
 (N'toolbelt_core',N'USP_EnqueueBarrierWork','P'),
 (N'toolbelt_core',N'USP_ClaimWork','P'),
 (N'toolbelt_core',N'USP_RenewWorkLease','P'),
 (N'toolbelt_core',N'USP_RecoverExpiredWork','P'),
 (N'toolbelt_core',N'USP_CompleteWork','P'),
 (N'toolbelt_core',N'USP_FailWork','P'),
 (N'toolbelt_core',N'USP_ScheduleWorkRetry','P'),
 (N'toolbelt_core',N'USP_RequeueDeadLetter','P'),
 (N'toolbelt_core',N'USP_GetWorkStatus','P'),
 (N'toolbelt_core',N'EventLog','U'),
 (N'toolbelt_core',N'VW_Events','V'),
 (N'toolbelt_core',N'USP_WriteEvent','P'),
 (N'toolbelt_core',N'USP_DeleteEventsBefore','P'),
 (N'toolbelt_core',N'USP_WriteEventInternal','P'),
 (N'toolbelt_core',N'WorkerControlConfiguration','U'),
 (N'toolbelt_core',N'WorkerRegistration','U'),
 (N'toolbelt_core',N'WorkerSlotReservation','U'),
 (N'toolbelt_core',N'WorkerExecutionDisposition','U'),
 (N'toolbelt_core',N'WorkerExecutionCommitWitness','U'),
 (N'toolbelt_core',N'VW_WorkerStatus','V'),
 (N'toolbelt_core',N'VW_WorkerExecutionStatus','V'),
 (N'toolbelt_core',N'USP_BeginWorkerCompletion','P'),
 (N'toolbelt_core',N'USP_BeginWorkerTransactionWitness','P'),
 (N'toolbelt_core',N'USP_BindWorkerExecution','P'),
 (N'toolbelt_core',N'USP_ClaimWorkerWork','P'),
 (N'toolbelt_core',N'USP_CloseWorker','P'),
 (N'toolbelt_core',N'USP_DisableManagedWorkers','P'),
 (N'toolbelt_core',N'USP_EnableManagedWorkers','P'),
 (N'toolbelt_core',N'USP_FinalizeWorkerFailure','P'),
 (N'toolbelt_core',N'USP_HeartbeatWorker','P'),
 (N'toolbelt_core',N'USP_ReconcileWorkerExecution','P'),
 (N'toolbelt_core',N'USP_RecordWorkerCommit','P'),
 (N'toolbelt_core',N'USP_RecordWorkerRollback','P'),
 (N'toolbelt_core',N'USP_RecordWorkerUnknown','P'),
 (N'toolbelt_core',N'USP_RegisterWorker','P'),
 (N'toolbelt_core',N'USP_ReleaseHeldWork','P'),
 (N'toolbelt_core',N'USP_ReserveWorkerExecution','P'),
 (N'toolbelt_core',N'USP_SetWorkerCapacity','P'),
 (N'toolbelt_core',N'USP_SetWorkerConcurrency','P'),
 (N'toolbelt_core',N'USP_SetWorkerIntervals','P'),
 (N'toolbelt_core',N'USP_SetWorkerState','P'),
 (N'toolbelt_core',N'USP_StopWorkerExecution','P'),
 (N'toolbelt_core',N'USP_StopWorkers','P');
IF (SELECT COUNT(*) FROM #tbx_ExportObjects)<>79
 OR EXISTS(SELECT SchemaName,ObjectName,ObjectType FROM #tbx_Queue11RepeatObjects
 EXCEPT SELECT SchemaName,ObjectName,ObjectType FROM #tbx_ExportObjects)
 OR EXISTS(SELECT SchemaName,ObjectName,ObjectType FROM #tbx_ExportObjects
 EXCEPT SELECT SchemaName,ObjectName,ObjectType FROM #tbx_Queue11RepeatObjects)
 THROW 55013,N'Die 79 sourcegebundenen Modulobjekte sind nicht exakt vorhanden.',10;
-- Ruhender installierter Verbund; kein Claim, Hold oder offener Bindungsslot.
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=0 AND PendingReservationId IS NULL)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED' OR ManagedHold<>0 OR ManagedReservationId IS NOT NULL OR ManagedCompletionNonce IS NOT NULL)
 THROW 55013,N'Der Queue11-Repeat verlangt den neutralen installierten Verbund.',11;
IF (SELECT COUNT(*) FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND
 name COLLATE Latin1_General_100_BIN2 IN(N'CK_WorkItem_RecoveryMetadata',N'CK_WorkItem_StateMetadata',N'CK_WorkItem_Status'))<>3
 THROW 55013,N'Die drei sourcegebundenen erneuerten CHECKs fehlen.',12;
-- Aktueller gepinnter Shape: zusätzliche oder fehlende Felder sind kein stiller PASS.
IF EXISTS(SELECT 1 FROM(VALUES
 (N'toolbelt_core',N'WorkType',18),(N'toolbelt_core',N'WorkItem',46),
 (N'toolbelt_core',N'WorkQueueScheduler',1),(N'toolbelt_core',N'WorkQueueBarrierBlocker',5),
 (N'toolbelt_core',N'WorkQueueManagedGate',4),(N'toolbelt_core',N'WorkerControlConfiguration',5),
 (N'toolbelt_core',N'WorkerRegistration',12),(N'toolbelt_core',N'WorkerSlotReservation',13),
 (N'toolbelt_core',N'WorkerExecutionDisposition',5),(N'toolbelt_core',N'WorkerExecutionCommitWitness',5),
 (N'toolbelt_core',N'ExecutionCancellation',5),(N'toolbelt_core',N'SecondSessionProvider',8),
 (N'toolbelt_core',N'EventLog',24),(N'toolbelt_file',N'FileContentRootAllowlist',5)
 )v(SchemaName,TableName,ColumnCount)
 JOIN #tbx_ExportObjects o ON o.SchemaName=v.SchemaName AND o.ObjectName=v.TableName AND o.ObjectType='U'
 WHERE (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=o.ObjectId)<>v.ColumnCount)
 THROW 55013,N'Der gepinnte Export-Tabellen-Shape weicht ab.',5;
CREATE TABLE #tbx_Queue11RepeatCounts(SchemaName sysname COLLATE Latin1_General_100_BIN2,TableName sysname COLLATE Latin1_General_100_BIN2,ExpectedRows bigint,PRIMARY KEY(SchemaName,TableName));
INSERT #tbx_Queue11RepeatCounts VALUES
 (N'toolbelt_core',N'WorkType',2),
 (N'toolbelt_core',N'WorkItem',3),
 (N'toolbelt_core',N'WorkQueueScheduler',1),
 (N'toolbelt_core',N'WorkQueueBarrierBlocker',0),
 (N'toolbelt_core',N'WorkQueueManagedGate',1),
 (N'toolbelt_core',N'WorkerControlConfiguration',1),
 (N'toolbelt_core',N'WorkerRegistration',0),
 (N'toolbelt_core',N'WorkerSlotReservation',0),
 (N'toolbelt_core',N'WorkerExecutionDisposition',0),
 (N'toolbelt_core',N'WorkerExecutionCommitWitness',0),
 (N'toolbelt_core',N'ExecutionCancellation',3),
 (N'toolbelt_core',N'SecondSessionProvider',1),
 (N'toolbelt_core',N'EventLog',3),
 (N'toolbelt_file',N'FileContentRootAllowlist',4);
CREATE TABLE #tbx_Queue11RepeatFields(SchemaName sysname COLLATE Latin1_General_100_BIN2,TableName sysname COLLATE Latin1_General_100_BIN2,Ordinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2,PRIMARY KEY(SchemaName,TableName,Ordinal));
INSERT #tbx_Queue11RepeatFields VALUES
 (N'toolbelt_core',N'WorkType',1,N'WorkTypeId'),
 (N'toolbelt_core',N'WorkType',2,N'WorkTypeName'),
 (N'toolbelt_core',N'WorkType',3,N'HandlerSchema'),
 (N'toolbelt_core',N'WorkType',4,N'HandlerProcedure'),
 (N'toolbelt_core',N'WorkType',5,N'ParameterMode'),
 (N'toolbelt_core',N'WorkType',6,N'PayloadContractJson'),
 (N'toolbelt_core',N'WorkType',7,N'DefaultTimeoutSeconds'),
 (N'toolbelt_core',N'WorkType',8,N'IsIdempotent'),
 (N'toolbelt_core',N'WorkType',9,N'IsEnabled'),
 (N'toolbelt_core',N'WorkType',10,N'Description'),
 (N'toolbelt_core',N'WorkType',11,N'CreatedAtUtc'),
 (N'toolbelt_core',N'WorkType',12,N'CreatedBy'),
 (N'toolbelt_core',N'WorkType',13,N'ModifiedAtUtc'),
 (N'toolbelt_core',N'WorkType',14,N'ModifiedBy'),
 (N'toolbelt_core',N'WorkType',15,N'DisabledAtUtc'),
 (N'toolbelt_core',N'WorkType',16,N'DisabledBy'),
 (N'toolbelt_core',N'WorkType',17,N'DisabledReason'),
 (N'toolbelt_core',N'WorkType',18,N'RowVersion'),
 (N'toolbelt_core',N'WorkItem',1,N'WorkItemId'),
 (N'toolbelt_core',N'WorkItem',2,N'WorkTypeId'),
 (N'toolbelt_core',N'WorkItem',3,N'PayloadJson'),
 (N'toolbelt_core',N'WorkItem',4,N'Status'),
 (N'toolbelt_core',N'WorkItem',5,N'EnqueuedAtUtc'),
 (N'toolbelt_core',N'WorkItem',6,N'EnqueuedBy'),
 (N'toolbelt_core',N'WorkItem',7,N'ClaimedAtUtc'),
 (N'toolbelt_core',N'WorkItem',8,N'ClaimedBy'),
 (N'toolbelt_core',N'WorkItem',9,N'ClaimToken'),
 (N'toolbelt_core',N'WorkItem',10,N'ClaimGeneration'),
 (N'toolbelt_core',N'WorkItem',11,N'LeaseDurationSeconds'),
 (N'toolbelt_core',N'WorkItem',12,N'LeaseUntilUtc'),
 (N'toolbelt_core',N'WorkItem',13,N'LastHeartbeatAtUtc'),
 (N'toolbelt_core',N'WorkItem',14,N'RecoveryCount'),
 (N'toolbelt_core',N'WorkItem',15,N'LastRecoveredAtUtc'),
 (N'toolbelt_core',N'WorkItem',16,N'LastRecoveredBy'),
 (N'toolbelt_core',N'WorkItem',17,N'CompletedAtUtc'),
 (N'toolbelt_core',N'WorkItem',18,N'CompletedBy'),
 (N'toolbelt_core',N'WorkItem',19,N'FailedAtUtc'),
 (N'toolbelt_core',N'WorkItem',20,N'FailedBy'),
 (N'toolbelt_core',N'WorkItem',21,N'FailureCode'),
 (N'toolbelt_core',N'WorkItem',22,N'FailureMessage'),
 (N'toolbelt_core',N'WorkItem',23,N'RowVersion'),
 (N'toolbelt_core',N'WorkItem',24,N'ExecutionGroup'),
 (N'toolbelt_core',N'WorkItem',25,N'Priority'),
 (N'toolbelt_core',N'WorkItem',26,N'ExecutionMode'),
 (N'toolbelt_core',N'WorkItem',27,N'IdempotencyKey'),
 (N'toolbelt_core',N'WorkItem',28,N'MaxAttempts'),
 (N'toolbelt_core',N'WorkItem',29,N'RetryBaseDelaySeconds'),
 (N'toolbelt_core',N'WorkItem',30,N'RetryMaxDelaySeconds'),
 (N'toolbelt_core',N'WorkItem',31,N'RetryCycleNumber'),
 (N'toolbelt_core',N'WorkItem',32,N'CycleAttemptCount'),
 (N'toolbelt_core',N'WorkItem',33,N'NextAttemptAtUtc'),
 (N'toolbelt_core',N'WorkItem',34,N'LastErrorCode'),
 (N'toolbelt_core',N'WorkItem',35,N'LastErrorMessage'),
 (N'toolbelt_core',N'WorkItem',36,N'LastRetryScheduledAtUtc'),
 (N'toolbelt_core',N'WorkItem',37,N'LastRetryScheduledBy'),
 (N'toolbelt_core',N'WorkItem',38,N'DeadLetteredAtUtc'),
 (N'toolbelt_core',N'WorkItem',39,N'DeadLetteredBy'),
 (N'toolbelt_core',N'WorkItem',40,N'LastRequeuedAtUtc'),
 (N'toolbelt_core',N'WorkItem',41,N'LastRequeuedBy'),
 (N'toolbelt_core',N'WorkItem',42,N'LastRequeueReason'),
 (N'toolbelt_core',N'WorkItem',43,N'BarrierEpoch'),
 (N'toolbelt_core',N'WorkItem',44,N'ManagedReservationId'),
 (N'toolbelt_core',N'WorkItem',45,N'ManagedHold'),
 (N'toolbelt_core',N'WorkItem',46,N'ManagedCompletionNonce'),
 (N'toolbelt_core',N'WorkQueueScheduler',1,N'SchedulerId'),
 (N'toolbelt_core',N'WorkQueueBarrierBlocker',1,N'BarrierWorkItemId'),
 (N'toolbelt_core',N'WorkQueueBarrierBlocker',2,N'BarrierEpoch'),
 (N'toolbelt_core',N'WorkQueueBarrierBlocker',3,N'BlockingWorkItemId'),
 (N'toolbelt_core',N'WorkQueueBarrierBlocker',4,N'BlockingClaimGeneration'),
 (N'toolbelt_core',N'WorkQueueBarrierBlocker',5,N'CapturedAtUtc'),
 (N'toolbelt_core',N'WorkQueueManagedGate',1,N'GateId'),
 (N'toolbelt_core',N'WorkQueueManagedGate',2,N'ManagedEnabled'),
 (N'toolbelt_core',N'WorkQueueManagedGate',3,N'AdmissionToken'),
 (N'toolbelt_core',N'WorkQueueManagedGate',4,N'PendingReservationId'),
 (N'toolbelt_core',N'WorkerControlConfiguration',1,N'ConfigurationId'),
 (N'toolbelt_core',N'WorkerControlConfiguration',2,N'MaxConcurrentExecutions'),
 (N'toolbelt_core',N'WorkerControlConfiguration',3,N'HeartbeatSeconds'),
 (N'toolbelt_core',N'WorkerControlConfiguration',4,N'UnreachableSeconds'),
 (N'toolbelt_core',N'WorkerControlConfiguration',5,N'ConfigVersion'),
 (N'toolbelt_core',N'WorkerRegistration',1,N'WorkerId'),
 (N'toolbelt_core',N'WorkerRegistration',2,N'WorkerGeneration'),
 (N'toolbelt_core',N'WorkerRegistration',3,N'WorkerToken'),
 (N'toolbelt_core',N'WorkerRegistration',4,N'OwnerPrincipalId'),
 (N'toolbelt_core',N'WorkerRegistration',5,N'ProviderKind'),
 (N'toolbelt_core',N'WorkerRegistration',6,N'State'),
 (N'toolbelt_core',N'WorkerRegistration',7,N'AdmissionPaused'),
 (N'toolbelt_core',N'WorkerRegistration',8,N'Capacity'),
 (N'toolbelt_core',N'WorkerRegistration',9,N'RunMode'),
 (N'toolbelt_core',N'WorkerRegistration',10,N'LastHeartbeatAtUtc'),
 (N'toolbelt_core',N'WorkerRegistration',11,N'HeartbeatSeconds'),
 (N'toolbelt_core',N'WorkerRegistration',12,N'UnreachableSeconds'),
 (N'toolbelt_core',N'WorkerSlotReservation',1,N'SlotReservationId'),
 (N'toolbelt_core',N'WorkerSlotReservation',2,N'WorkerId'),
 (N'toolbelt_core',N'WorkerSlotReservation',3,N'WorkerGeneration'),
 (N'toolbelt_core',N'WorkerSlotReservation',4,N'WorkItemId'),
 (N'toolbelt_core',N'WorkerSlotReservation',5,N'ClaimGeneration'),
 (N'toolbelt_core',N'WorkerSlotReservation',6,N'ClaimToken'),
 (N'toolbelt_core',N'WorkerSlotReservation',7,N'ExecutionId'),
 (N'toolbelt_core',N'WorkerSlotReservation',8,N'State'),
 (N'toolbelt_core',N'WorkerSlotReservation',9,N'IsOccupied'),
 (N'toolbelt_core',N'WorkerSlotReservation',10,N'AttemptNonce'),
 (N'toolbelt_core',N'WorkerSlotReservation',11,N'BoundPrincipalId'),
 (N'toolbelt_core',N'WorkerSlotReservation',12,N'CreatedAtUtc'),
 (N'toolbelt_core',N'WorkerSlotReservation',13,N'EndedAtUtc'),
 (N'toolbelt_core',N'WorkerExecutionDisposition',1,N'WorkItemId'),
 (N'toolbelt_core',N'WorkerExecutionDisposition',2,N'SlotReservationId'),
 (N'toolbelt_core',N'WorkerExecutionDisposition',3,N'IsHeld'),
 (N'toolbelt_core',N'WorkerExecutionDisposition',4,N'StopStatus'),
 (N'toolbelt_core',N'WorkerExecutionDisposition',5,N'HoldVersion'),
 (N'toolbelt_core',N'WorkerExecutionCommitWitness',1,N'SlotReservationId'),
 (N'toolbelt_core',N'WorkerExecutionCommitWitness',2,N'AttemptNonce'),
 (N'toolbelt_core',N'WorkerExecutionCommitWitness',3,N'ExecutionId'),
 (N'toolbelt_core',N'WorkerExecutionCommitWitness',4,N'ClaimGeneration'),
 (N'toolbelt_core',N'WorkerExecutionCommitWitness',5,N'RecordedAtUtc'),
 (N'toolbelt_core',N'ExecutionCancellation',1,N'ExecutionId'),
 (N'toolbelt_core',N'ExecutionCancellation',2,N'RequestedAtUtc'),
 (N'toolbelt_core',N'ExecutionCancellation',3,N'RequestedBy'),
 (N'toolbelt_core',N'ExecutionCancellation',4,N'CancellationReason'),
 (N'toolbelt_core',N'ExecutionCancellation',5,N'RowVersion'),
 (N'toolbelt_core',N'SecondSessionProvider',1,N'ProviderName'),
 (N'toolbelt_core',N'SecondSessionProvider',2,N'LinkedServerName'),
 (N'toolbelt_core',N'SecondSessionProvider',3,N'IsEnabled'),
 (N'toolbelt_core',N'SecondSessionProvider',4,N'CreatedAtUtc'),
 (N'toolbelt_core',N'SecondSessionProvider',5,N'CreatedBy'),
 (N'toolbelt_core',N'SecondSessionProvider',6,N'ModifiedAtUtc'),
 (N'toolbelt_core',N'SecondSessionProvider',7,N'ModifiedBy'),
 (N'toolbelt_core',N'SecondSessionProvider',8,N'RowVersion'),
 (N'toolbelt_core',N'EventLog',1,N'EventId'),
 (N'toolbelt_core',N'EventLog',2,N'OccurredAtUtc'),
 (N'toolbelt_core',N'EventLog',3,N'RecordedAtUtc'),
 (N'toolbelt_core',N'EventLog',4,N'EventName'),
 (N'toolbelt_core',N'EventLog',5,N'EventLevel'),
 (N'toolbelt_core',N'EventLog',6,N'Category'),
 (N'toolbelt_core',N'EventLog',7,N'Message'),
 (N'toolbelt_core',N'EventLog',8,N'DataJson'),
 (N'toolbelt_core',N'EventLog',9,N'ExecutionId'),
 (N'toolbelt_core',N'EventLog',10,N'CorrelationId'),
 (N'toolbelt_core',N'EventLog',11,N'Actor'),
 (N'toolbelt_core',N'EventLog',12,N'Tenant'),
 (N'toolbelt_core',N'EventLog',13,N'SourceDatabaseName'),
 (N'toolbelt_core',N'EventLog',14,N'SourceSchemaName'),
 (N'toolbelt_core',N'EventLog',15,N'SourceObjectName'),
 (N'toolbelt_core',N'EventLog',16,N'CallerSessionId'),
 (N'toolbelt_core',N'EventLog',17,N'CallerXactState'),
 (N'toolbelt_core',N'EventLog',18,N'CallerTransactionCount'),
 (N'toolbelt_core',N'EventLog',19,N'RemoteSessionId'),
 (N'toolbelt_core',N'EventLog',20,N'ErrorNumber'),
 (N'toolbelt_core',N'EventLog',21,N'ErrorSeverity'),
 (N'toolbelt_core',N'EventLog',22,N'ErrorState'),
 (N'toolbelt_core',N'EventLog',23,N'ErrorProcedure'),
 (N'toolbelt_core',N'EventLog',24,N'ErrorLine'),
 (N'toolbelt_file',N'FileContentRootAllowlist',1,N'RootPathId'),
 (N'toolbelt_file',N'FileContentRootAllowlist',2,N'RootPath'),
 (N'toolbelt_file',N'FileContentRootAllowlist',3,N'Description'),
 (N'toolbelt_file',N'FileContentRootAllowlist',4,N'IsActive'),
 (N'toolbelt_file',N'FileContentRootAllowlist',5,N'CreatedAt');
IF (SELECT COUNT(*) FROM #tbx_Queue11RepeatFields)<>156
 OR EXISTS(SELECT 1 FROM #tbx_Queue11RepeatFields e JOIN #tbx_ExportObjects o ON o.SchemaName=e.SchemaName AND o.ObjectName=e.TableName AND o.ObjectType='U'
 LEFT JOIN sys.columns c ON c.object_id=o.ObjectId AND c.column_id=e.Ordinal
 WHERE c.column_id IS NULL OR CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),e.ColumnName))
 THROW 55013,N'Die sourcegebundenen 156 Feldnamen und Ordinalpositionen weichen ab.',9;
CREATE TABLE #tbx_ExportSnapshot(Category varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Payload varbinary(max) NOT NULL);
DECLARE @Id int,@Schema sysname,@Table sysname,@Category varchar(128),@Projection nvarchar(max),@Sql nvarchar(max),@ExpectedRows bigint,@ObservedRows bigint;
DECLARE tables_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT o.ObjectId,o.SchemaName,o.ObjectName,e.ExpectedRows FROM #tbx_ExportObjects o
 JOIN #tbx_Queue11RepeatCounts e ON e.SchemaName=o.SchemaName AND e.TableName=o.ObjectName
 WHERE o.ObjectType='U' ORDER BY o.SchemaName,o.ObjectName;
OPEN tables_cursor;FETCH NEXT FROM tables_cursor INTO @Id,@Schema,@Table,@ExpectedRows;
WHILE @@FETCH_STATUS=0 BEGIN
 SELECT @Projection=STRING_AGG(CONVERT(nvarchar(max),N'CONVERT(varbinary(max),r.'+QUOTENAME(c.name)+N') AS '+QUOTENAME(c.name)),N',') WITHIN GROUP(ORDER BY c.column_id) FROM sys.columns c WHERE c.object_id=@Id;
 SET @Category=CONVERT(varchar(128),N'row:'+@Schema+N'.'+@Table);
 SET @Sql=N'SELECT @ObservedRows=COUNT_BIG(*) FROM '+QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table)+N';';
 EXEC sys.sp_executesql @Sql,N'@ObservedRows bigint OUTPUT',@ObservedRows=@ObservedRows OUTPUT;
 IF @ObservedRows<>@ExpectedRows THROW 55013,N'Der endliche Tabellenzeilenshape weicht ab.',4;
 INSERT #tbx_ExportSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT CONVERT(varbinary(max),@ObservedRows) CountWitness FOR XML PATH('count'),BINARY BASE64,ELEMENTS));
 SET @Sql=N'INSERT #tbx_ExportSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT '+@Projection+N' FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM '+QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table)+N' r;';
 EXEC sys.sp_executesql @Sql,N'@Category varchar(128)',@Category=@Category;
 IF (SELECT COUNT_BIG(*) FROM #tbx_ExportSnapshot WHERE Category=@Category)<>@ObservedRows+1
  THROW 55013,N'Der vollständige Tabellen- und Leerzeuge ist unbezeugt.',5;
 FETCH NEXT FROM tables_cursor INTO @Id,@Schema,@Table,@ExpectedRows;
END;
CLOSE tables_cursor;DEALLOCATE tables_cursor;
-- Vollständiger semantischer Katalog ohne First-Ausnahmen und Versionsnormalisierung.
DECLARE @Query nvarchar(max);
DECLARE catalog_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Category,Query FROM(VALUES
 ('catalog:objects',N'SELECT o.object_id,o.name,o.type,o.schema_id,o.principal_id,o.create_date FROM sys.objects o JOIN #tbx_ExportObjects x ON x.ObjectId=o.object_id'),
 ('catalog:children',N'SELECT CASE WHEN o.parent_object_id=OBJECT_ID(N''toolbelt_core.WorkItem'') AND o.type=''C'' AND o.name COLLATE Latin1_General_100_BIN2 IN(N''CK_WorkItem_RecoveryMetadata'',N''CK_WorkItem_StateMetadata'',N''CK_WorkItem_Status'') THEN NULL ELSE o.object_id END StableChildId,o.name,o.type,o.parent_object_id,o.schema_id,o.principal_id,CASE WHEN o.parent_object_id=OBJECT_ID(N''toolbelt_core.WorkItem'') AND o.type=''C'' AND o.name COLLATE Latin1_General_100_BIN2 IN(N''CK_WorkItem_RecoveryMetadata'',N''CK_WorkItem_StateMetadata'',N''CK_WorkItem_Status'') THEN NULL ELSE o.create_date END StableChildCreated,CASE WHEN o.parent_object_id=OBJECT_ID(N''toolbelt_core.WorkItem'') AND o.type=''C'' AND o.name COLLATE Latin1_General_100_BIN2 IN(N''CK_WorkItem_RecoveryMetadata'',N''CK_WorkItem_StateMetadata'',N''CK_WorkItem_Status'') THEN NULL ELSE o.modify_date END StableChildModified FROM sys.objects o JOIN #tbx_ExportObjects x ON x.ObjectId=o.parent_object_id'),
 ('catalog:schemas',N'SELECT s.schema_id,s.name,s.principal_id FROM sys.schemas s WHERE s.schema_id IN(SELECT DISTINCT o.schema_id FROM sys.objects o JOIN #tbx_ExportObjects x ON x.ObjectId=o.object_id)'),
 ('catalog:tables',N'SELECT t.object_id,t.uses_ansi_nulls,t.is_replicated,t.has_replication_filter,t.is_merge_published,t.is_sync_tran_subscribed,t.is_memory_optimized,t.durability,t.temporal_type,t.is_filetable FROM sys.tables t JOIN #tbx_ExportObjects x ON x.ObjectId=t.object_id'),
 ('catalog:columns',N'SELECT c.* FROM sys.columns c JOIN #tbx_ExportObjects x ON x.ObjectId=c.object_id'),
 ('catalog:identity',N'SELECT c.object_id,c.name,c.column_id,c.system_type_id,CONVERT(decimal(38,0),c.seed_value) seed_value,CONVERT(decimal(38,0),c.increment_value) increment_value,CONVERT(decimal(38,0),c.last_value) last_value,c.is_not_for_replication FROM sys.identity_columns c JOIN #tbx_ExportObjects x ON x.ObjectId=c.object_id'),
 ('catalog:indexes',N'SELECT i.* FROM sys.indexes i JOIN #tbx_ExportObjects x ON x.ObjectId=i.object_id'),
 ('catalog:index_columns',N'SELECT c.* FROM sys.index_columns c JOIN #tbx_ExportObjects x ON x.ObjectId=c.object_id'),
 ('catalog:defaults',N'SELECT d.object_id,d.name,d.parent_object_id,d.parent_column_id,d.definition,d.is_system_named FROM sys.default_constraints d JOIN #tbx_ExportObjects x ON x.ObjectId=d.parent_object_id'),
 ('catalog:checks',N'SELECT CASE WHEN c.parent_object_id=OBJECT_ID(N''toolbelt_core.WorkItem'') AND c.name COLLATE Latin1_General_100_BIN2 IN(N''CK_WorkItem_RecoveryMetadata'',N''CK_WorkItem_StateMetadata'',N''CK_WorkItem_Status'') THEN NULL ELSE c.object_id END StableCheckId,c.name,c.parent_object_id,c.parent_column_id,c.definition,c.is_disabled,c.is_not_trusted,c.is_not_for_replication,c.uses_database_collation,c.is_system_named FROM sys.check_constraints c JOIN #tbx_ExportObjects x ON x.ObjectId=c.parent_object_id'),
 ('catalog:keys',N'SELECT k.object_id,k.name,k.parent_object_id,k.type,k.unique_index_id,k.is_system_named FROM sys.key_constraints k JOIN #tbx_ExportObjects x ON x.ObjectId=k.parent_object_id'),
 ('catalog:foreign_keys',N'SELECT f.* FROM sys.foreign_keys f JOIN #tbx_ExportObjects x ON x.ObjectId=f.parent_object_id'),
 ('catalog:foreign_key_columns',N'SELECT f.* FROM sys.foreign_key_columns f JOIN #tbx_ExportObjects x ON x.ObjectId=f.parent_object_id'),
 ('catalog:triggers',N'SELECT t.object_id,t.name,t.parent_id,t.is_disabled,t.is_instead_of_trigger,t.is_not_for_replication FROM sys.triggers t JOIN #tbx_ExportObjects x ON x.ObjectId=t.parent_id'),
 ('catalog:modules',N'SELECT m.* FROM sys.sql_modules m JOIN #tbx_ExportObjects x ON x.ObjectId=m.object_id'),
 ('catalog:properties',N'SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,CONVERT(bit,CASE WHEN p.value IS NULL THEN 0 ELSE 1 END) HasValue,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''BaseType'')) BaseType,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''MaxLength'')) MaxLength,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Precision'')) PrecisionValue,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Scale'')) ScaleValue,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''Collation'')) CollationValue,CONVERT(varbinary(max),p.value) ValueBytes FROM sys.extended_properties p WHERE (p.class IN(1,2) AND p.major_id IN(SELECT ObjectId FROM #tbx_ExportObjects)) OR (p.class=0 AND p.name LIKE N''Toolbelt.Module.%'') OR (p.class=3 AND p.major_id IN(SCHEMA_ID(N''toolbelt_core''),SCHEMA_ID(N''toolbelt_file'')))'),
 ('catalog:permissions',N'SELECT p.* FROM sys.database_permissions p WHERE p.class=0 OR (p.class=3 AND p.major_id IN(SCHEMA_ID(N''toolbelt_core''),SCHEMA_ID(N''toolbelt_file''))) OR (p.class=1 AND p.major_id IN(SELECT ObjectId FROM #tbx_ExportObjects))')
 )v(Category,Query);
OPEN catalog_cursor;FETCH NEXT FROM catalog_cursor INTO @Category,@Query;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Sql=N'INSERT #tbx_ExportSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT CONVERT(varbinary(max),COUNT_BIG(*)) CountWitness FROM ('+@Query+N')r FOR XML PATH(''count''),BINARY BASE64,ELEMENTS)); INSERT #tbx_ExportSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT r.* FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM ('+@Query+N')r;';
 EXEC sys.sp_executesql @Sql,N'@Category varchar(128)',@Category=@Category;
 FETCH NEXT FROM catalog_cursor INTO @Category,@Query;
END;
CLOSE catalog_cursor;DEALLOCATE catalog_cursor;
IF (SELECT COUNT(DISTINCT Category) FROM #tbx_ExportSnapshot WHERE Category LIKE 'row:%')<>14
 OR (SELECT COUNT(DISTINCT Category) FROM #tbx_ExportSnapshot WHERE Category LIKE 'catalog:%')<>17
 THROW 55013,N'Der vollständige Queue11-Repeat-Snapshot fehlt.',8;
SELECT Category,Payload FROM #tbx_ExportSnapshot;
DROP TABLE #tbx_ExportSnapshot;DROP TABLE #tbx_ExportObjects;DROP TABLE #tbx_Queue11RepeatCounts;DROP TABLE #tbx_Queue11RepeatFields;DROP TABLE #tbx_Queue11RepeatObjects;
