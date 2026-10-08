-- Private synthetische Genuine1.1-Upgradefixture; keine Produktobjekte oder Cleanup.
SET NOCOUNT ON;
IF @After IS NULL THROW 55012,N'EXPORT_QUEUE11_PHASE',1;
IF @InstallMode IS NULL OR CONVERT(varbinary(max),@InstallMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')) THROW 55012,N'EXPORT_QUEUE11_MODE',1;
IF @@TRANCOUNT<>0 THROW 55012,N'EXPORT_QUEUE11_SESSION',1;
IF XACT_STATE()<>0 THROW 55012,N'EXPORT_QUEUE11_SESSION',1;
IF (@@OPTIONS&2)<>0 THROW 55012,N'EXPORT_QUEUE11_SESSION',1;
IF @@LOCK_TIMEOUT<>-1 THROW 55012,N'EXPORT_QUEUE11_SESSION',1;
CREATE TABLE #OldTables(SchemaName sysname COLLATE Latin1_General_100_BIN2,TableName sysname COLLATE Latin1_General_100_BIN2,LegacyColumns int,ExpectedRows int,ObjectId int NULL);
INSERT #OldTables VALUES
(N'toolbelt_core',N'WorkType',18,2,NULL),
(N'toolbelt_core',N'WorkItem',23,3,NULL),
(N'toolbelt_core',N'ExecutionCancellation',5,3,NULL),
(N'toolbelt_core',N'SecondSessionProvider',8,1,NULL),
(N'toolbelt_core',N'EventLog',24,3,NULL),
(N'toolbelt_file',N'FileContentRootAllowlist',5,4,NULL);
UPDATE #OldTables SET ObjectId=OBJECT_ID(QUOTENAME(SchemaName)+N'.'+QUOTENAME(TableName),N'U');
IF (SELECT COUNT(*) FROM #OldTables)<>6 OR EXISTS(SELECT 1 FROM #OldTables t WHERE ObjectId IS NULL OR (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=t.ObjectId)<>t.LegacyColumns+CASE WHEN t.TableName=N'WorkItem' AND @After=1 THEN 23 ELSE 0 END)
 THROW 55012,N'EXPORT_QUEUE11_OLD_SHAPE',2;
IF (SELECT STRING_AGG(CONVERT(nvarchar(max),c.name),N',') WITHIN GROUP(ORDER BY c.column_id) FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND c.column_id<=23) COLLATE Latin1_General_100_BIN2<>N'WorkItemId,WorkTypeId,PayloadJson,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,ClaimToken,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion' COLLATE Latin1_General_100_BIN2
 THROW 55012,N'EXPORT_QUEUE11_OLD_NAMES',3;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkType)<>2 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>3
 OR (SELECT COUNT(*) FROM toolbelt_core.ExecutionCancellation)<>3 OR (SELECT COUNT(*) FROM toolbelt_core.SecondSessionProvider)<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.EventLog)<>3 OR (SELECT COUNT(*) FROM toolbelt_file.FileContentRootAllowlist)<>4
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='COMPLETED')<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='FAILED')<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='QUEUED')<>1 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')
 THROW 55012,N'EXPORT_QUEUE11_OLD_COUNTS',4;
CREATE TABLE #ExpectedColumns(SchemaName sysname COLLATE Latin1_General_100_BIN2,TableName sysname COLLATE Latin1_General_100_BIN2,Ordinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2,TypeId int,MaxLength int,PrecisionValue int,ScaleValue int,Nullable bit,IdentityValue bit,SysnameAlias bit,CollationKind varchar(16) COLLATE Latin1_General_100_BIN2);
INSERT #ExpectedColumns VALUES
(N'toolbelt_core',N'WorkType',1,N'WorkTypeId',127,8,19,0,0,1,0,N'NONE'),
(N'toolbelt_core',N'WorkType',2,N'WorkTypeName',167,128,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkType',3,N'HandlerSchema',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkType',4,N'HandlerProcedure',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkType',5,N'ParameterMode',167,16,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkType',6,N'PayloadContractJson',231,8000,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'WorkType',7,N'DefaultTimeoutSeconds',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkType',8,N'IsIdempotent',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkType',9,N'IsEnabled',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkType',10,N'Description',231,2000,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'WorkType',11,N'CreatedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkType',12,N'CreatedBy',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkType',13,N'ModifiedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkType',14,N'ModifiedBy',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkType',15,N'DisabledAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkType',16,N'DisabledBy',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkType',17,N'DisabledReason',231,2000,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'WorkType',18,N'RowVersion',189,8,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',1,N'WorkItemId',127,8,19,0,0,1,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',2,N'WorkTypeId',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',3,N'PayloadJson',231,-1,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',4,N'Status',167,16,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkItem',5,N'EnqueuedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',6,N'EnqueuedBy',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',7,N'ClaimedAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',8,N'ClaimedBy',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',9,N'ClaimToken',36,16,0,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',10,N'ClaimGeneration',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',11,N'LeaseDurationSeconds',56,4,10,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',12,N'LeaseUntilUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',13,N'LastHeartbeatAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',14,N'RecoveryCount',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',15,N'LastRecoveredAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',16,N'LastRecoveredBy',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',17,N'CompletedAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',18,N'CompletedBy',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',19,N'FailedAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',20,N'FailedBy',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',21,N'FailureCode',167,64,0,0,1,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkItem',22,N'FailureMessage',231,2000,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',23,N'RowVersion',189,8,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'ExecutionCancellation',1,N'ExecutionId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'ExecutionCancellation',2,N'RequestedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'ExecutionCancellation',3,N'RequestedBy',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'ExecutionCancellation',4,N'CancellationReason',231,1024,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'ExecutionCancellation',5,N'RowVersion',189,8,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'SecondSessionProvider',1,N'ProviderName',167,32,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'SecondSessionProvider',2,N'LinkedServerName',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'SecondSessionProvider',3,N'IsEnabled',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'SecondSessionProvider',4,N'CreatedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'SecondSessionProvider',5,N'CreatedBy',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'SecondSessionProvider',6,N'ModifiedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'SecondSessionProvider',7,N'ModifiedBy',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'SecondSessionProvider',8,N'RowVersion',189,8,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',1,N'EventId',127,8,19,0,0,1,0,N'NONE'),
(N'toolbelt_core',N'EventLog',2,N'OccurredAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',3,N'RecordedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',4,N'EventName',167,128,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'EventLog',5,N'EventLevel',167,16,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'EventLog',6,N'Category',167,128,0,0,1,0,0,N'BIN2'),
(N'toolbelt_core',N'EventLog',7,N'Message',231,8000,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'EventLog',8,N'DataJson',231,-1,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'EventLog',9,N'ExecutionId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',10,N'CorrelationId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',11,N'Actor',231,512,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'EventLog',12,N'Tenant',231,512,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'EventLog',13,N'SourceDatabaseName',231,256,0,0,0,0,1,N'DATABASE'),
(N'toolbelt_core',N'EventLog',14,N'SourceSchemaName',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'EventLog',15,N'SourceObjectName',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'EventLog',16,N'CallerSessionId',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',17,N'CallerXactState',52,2,5,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',18,N'CallerTransactionCount',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',19,N'RemoteSessionId',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',20,N'ErrorNumber',56,4,10,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',21,N'ErrorSeverity',56,4,10,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',22,N'ErrorState',56,4,10,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'EventLog',23,N'ErrorProcedure',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'EventLog',24,N'ErrorLine',56,4,10,0,1,0,0,N'NONE'),
(N'toolbelt_file',N'FileContentRootAllowlist',1,N'RootPathId',56,4,10,0,0,1,0,N'NONE'),
(N'toolbelt_file',N'FileContentRootAllowlist',2,N'RootPath',231,8000,0,0,0,0,0,N'DATABASE'),
(N'toolbelt_file',N'FileContentRootAllowlist',3,N'Description',231,8000,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_file',N'FileContentRootAllowlist',4,N'IsActive',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_file',N'FileContentRootAllowlist',5,N'CreatedAt',42,6,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',24,N'ExecutionGroup',167,128,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkItem',25,N'Priority',48,1,3,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',26,N'ExecutionMode',167,16,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkItem',27,N'IdempotencyKey',167,128,0,0,1,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkItem',28,N'MaxAttempts',48,1,3,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',29,N'RetryBaseDelaySeconds',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',30,N'RetryMaxDelaySeconds',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',31,N'RetryCycleNumber',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',32,N'CycleAttemptCount',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',33,N'NextAttemptAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',34,N'LastErrorCode',167,64,0,0,1,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkItem',35,N'LastErrorMessage',231,2000,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',36,N'LastRetryScheduledAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',37,N'LastRetryScheduledBy',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',38,N'DeadLetteredAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',39,N'DeadLetteredBy',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',40,N'LastRequeuedAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',41,N'LastRequeuedBy',231,256,0,0,1,0,1,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',42,N'LastRequeueReason',231,2000,0,0,1,0,0,N'DATABASE'),
(N'toolbelt_core',N'WorkItem',43,N'BarrierEpoch',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueManagedGate',1,N'GateId',48,1,3,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueManagedGate',2,N'ManagedEnabled',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueManagedGate',3,N'AdmissionToken',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueManagedGate',4,N'PendingReservationId',36,16,0,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerControlConfiguration',1,N'ConfigurationId',48,1,3,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerControlConfiguration',2,N'MaxConcurrentExecutions',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerControlConfiguration',3,N'HeartbeatSeconds',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerControlConfiguration',4,N'UnreachableSeconds',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerControlConfiguration',5,N'ConfigVersion',189,8,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',1,N'WorkerId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',2,N'WorkerGeneration',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',3,N'WorkerToken',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',4,N'OwnerPrincipalId',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',5,N'ProviderKind',167,16,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkerRegistration',6,N'State',167,16,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkerRegistration',7,N'AdmissionPaused',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',8,N'Capacity',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',9,N'RunMode',167,16,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkerRegistration',10,N'LastHeartbeatAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',11,N'HeartbeatSeconds',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerRegistration',12,N'UnreachableSeconds',56,4,10,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',1,N'SlotReservationId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',2,N'WorkerId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',3,N'WorkerGeneration',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',4,N'WorkItemId',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',5,N'ClaimGeneration',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',6,N'ClaimToken',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',7,N'ExecutionId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',8,N'State',167,24,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkerSlotReservation',9,N'IsOccupied',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',10,N'AttemptNonce',36,16,0,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',11,N'BoundPrincipalId',56,4,10,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',12,N'CreatedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerSlotReservation',13,N'EndedAtUtc',42,8,27,7,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionDisposition',1,N'WorkItemId',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionDisposition',2,N'SlotReservationId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionDisposition',3,N'IsHeld',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionDisposition',4,N'StopStatus',167,24,0,0,0,0,0,N'BIN2'),
(N'toolbelt_core',N'WorkerExecutionDisposition',5,N'HoldVersion',189,8,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionCommitWitness',1,N'SlotReservationId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionCommitWitness',2,N'AttemptNonce',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionCommitWitness',3,N'ExecutionId',36,16,0,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionCommitWitness',4,N'ClaimGeneration',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkerExecutionCommitWitness',5,N'RecordedAtUtc',42,8,27,7,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',44,N'ManagedReservationId',36,16,0,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',45,N'ManagedHold',104,1,1,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkItem',46,N'ManagedCompletionNonce',36,16,0,0,1,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueScheduler',1,N'SchedulerId',48,1,3,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueBarrierBlocker',1,N'BarrierWorkItemId',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueBarrierBlocker',2,N'BarrierEpoch',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueBarrierBlocker',3,N'BlockingWorkItemId',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueBarrierBlocker',4,N'BlockingClaimGeneration',127,8,19,0,0,0,0,N'NONE'),
(N'toolbelt_core',N'WorkQueueBarrierBlocker',5,N'CapturedAtUtc',42,8,27,7,0,0,0,N'NONE');
DELETE #ExpectedColumns WHERE @After=0 AND NOT EXISTS(SELECT 1 FROM #OldTables t WHERE t.SchemaName=#ExpectedColumns.SchemaName AND t.TableName=#ExpectedColumns.TableName AND #ExpectedColumns.Ordinal<=t.LegacyColumns);
IF (SELECT COUNT(*) FROM #ExpectedColumns)<>CASE WHEN @After=0 THEN 83 ELSE 156 END
 OR (SELECT COUNT(*) FROM sys.tables WHERE is_ms_shipped=0)<>CASE WHEN @After=0 THEN 6 ELSE 14 END
 OR (SELECT COUNT(*) FROM (SELECT DISTINCT SchemaName,TableName FROM #ExpectedColumns)v)<>CASE WHEN @After=0 THEN 6 ELSE 14 END
 OR EXISTS(SELECT 1 FROM #ExpectedColumns e LEFT JOIN sys.columns c ON c.object_id=OBJECT_ID(QUOTENAME(e.SchemaName)+N'.'+QUOTENAME(e.TableName),N'U') AND c.column_id=e.Ordinal
 WHERE c.column_id IS NULL OR CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),e.ColumnName)
 OR c.system_type_id<>e.TypeId OR c.user_type_id<>CASE WHEN e.SysnameAlias=1 THEN TYPE_ID(N'sysname') ELSE e.TypeId END
 OR c.max_length<>e.MaxLength OR c.precision<>e.PrecisionValue OR c.scale<>e.ScaleValue OR c.is_nullable<>e.Nullable
 OR c.is_identity<>e.IdentityValue OR c.is_computed<>0 OR c.is_rowguidcol<>0 OR c.is_filestream<>0 OR c.is_sparse<>0 OR c.is_column_set<>0 OR c.generated_always_type<>0
 OR (e.CollationKind='NONE' AND c.collation_name IS NOT NULL)
 OR (e.CollationKind='BIN2' AND (c.collation_name IS NULL OR CONVERT(varbinary(max),c.collation_name)<>CONVERT(varbinary(max),N'Latin1_General_100_BIN2')))
 OR (e.CollationKind='DATABASE' AND (c.collation_name IS NULL OR CONVERT(varbinary(max),c.collation_name)<>CONVERT(varbinary(max),CONVERT(nvarchar(128),DATABASEPROPERTYEX(DB_NAME(),'Collation'))))))
 OR EXISTS(SELECT 1 FROM #ExpectedColumns e GROUP BY e.SchemaName,e.TableName HAVING COUNT(*)<>(SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=OBJECT_ID(QUOTENAME(e.SchemaName)+N'.'+QUOTENAME(e.TableName),N'U')))
 THROW 55012,N'EXPORT_QUEUE11_FULL_COLUMNS',5;
CREATE TABLE #ExpectedDefinitions(AfterValue bit,ObjectName sysname COLLATE Latin1_General_100_BIN2,DefinitionHash binary(32));
INSERT #ExpectedDefinitions VALUES
(0,N'VW_WorkQueue',0x42F3E8ED56FC327664E8B15464A72E89CAB09F2046A60A0C2CB9F932E29530B3),
(0,N'USP_EnqueueWork',0x78D1DBD05E428EACC53334AA8902EA58038FB9F2B47B2F3BCA0D106B9A5A2C74),
(0,N'USP_ClaimWork',0xA156968DF5B3BE3C8FD9E0DF0647C393DD6EED61366620840C72CEF1781E1CAC),
(0,N'USP_RenewWorkLease',0x5B01679C6414401A6DE7624132EC7978B6F1669CEAE27879FD80E5792512562F),
(0,N'USP_RecoverExpiredWork',0x4879473127B88BE9CD054477F3CEC5E3AC0C5FDFFB32430CE424C6322378C46C),
(0,N'USP_CompleteWork',0xA8B12C3D6B192A3C0A8B6048953BFC68025CD8CC68341C4AC2B16027A9D7AE3F),
(0,N'USP_FailWork',0x56CB0C19707213680079AAB7A397739DBBA6BFF14F256B523B161C04D4435CED),
(0,N'USP_GetWorkStatus',0x36E7ED8688540A5CD1226D651D12398CBEAE00A0B9C420E6CF9068B8B6216648),
(1,N'VW_WorkQueue',0x25454FC5A11930E90E3274AFC913B25366A343830FA6142975BE92520D5BE221),
(1,N'USP_EnqueueWork',0x524A8609C12D2DE9236DE16E1D3C08CEC6AFB2B2D2E67EBCB7EBB20613B64DA7),
(1,N'USP_ClaimWork',0x612F71E86926003EB668F35DC4510AD4E7D9AF7AB29B93AD9F103C247B217F73),
(1,N'USP_RenewWorkLease',0x5B01679C6414401A6DE7624132EC7978B6F1669CEAE27879FD80E5792512562F),
(1,N'USP_RecoverExpiredWork',0x53460D4DFD236B6C88BB445B7EA82C10BEF3884D22B3BBA8FA5DC7A304644F06),
(1,N'USP_CompleteWork',0x92764B2BCAFC4BAF63134564AB153C5804D7E96BE6543553DF1233FEC70B2F04),
(1,N'USP_FailWork',0x9AB2FA01E9D7CE804A63AFB397BC97C8ED2745C1036E5AA9A759CE91FD873A96),
(1,N'USP_GetWorkStatus',0x687B03C0FD94BD4BE723CC171B7E6CAF24C4A2A9956329789D420DDAC5E33D78);
IF (SELECT COUNT(*) FROM #ExpectedDefinitions WHERE AfterValue=@After)<>8
 OR EXISTS(SELECT 1 FROM #ExpectedDefinitions e LEFT JOIN sys.sql_modules m ON m.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.ObjectName))
 WHERE e.AfterValue=@After AND (m.object_id IS NULL OR m.definition IS NULL OR HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),m.definition))<>e.DefinitionHash
 OR m.uses_ansi_nulls<>1 OR m.uses_quoted_identifier<>1 OR m.execute_as_principal_id IS NOT NULL OR m.is_schema_bound<>0 OR m.uses_native_compilation<>0))
BEGIN
 -- Nur die bereits abgelehnte BEFORE-Darstellung enger klassifizieren; kein zusätzlicher Erfolgsweg.
 IF @After=0
 BEGIN
  -- Alle acht festen Client-Batchhashes und sämtliche bisherigen Modulflags müssen positiv passen.
  IF (SELECT COUNT(*) FROM (VALUES
   (N'VW_WorkQueue',0x6B5C9E5C75E9F5AFA199F7789A1CD68892EE968FC488FA8150D0858AB6ACF02C),
   (N'USP_EnqueueWork',0x0CF962DC4EA9D2677DE0BE66138C0B69F0BE300971607C82E79AB918B55B2423),
   (N'USP_ClaimWork',0xE959E0D5DEE9CA8BA0186D5BC50122450133D3704646F535A61F0731DDCB34D1),
   (N'USP_RenewWorkLease',0xCEB1F1A6003BFB665C82C3713A50510252090A46BA526EF536FE1AE4AC33D47B),
   (N'USP_RecoverExpiredWork',0x5A26635D526560FA911DE167872D93C9F09D5AD6DDF7C3144BA4691A37112777),
   (N'USP_CompleteWork',0xFDD256460794D7CAA76A1758598EB7F23A677D8B2D7C150553BE1D1206F558DC),
   (N'USP_FailWork',0xB4DD7F3B191624C6775407D89814902151C7034434AF63B7D69771B7EC5D68A3),
   (N'USP_GetWorkStatus',0x9102AD285EAF93E0F13AC2DD95246A015FDFE1604B3DDA16EBB22C1793A48F2F)
  ) v(ObjectName,DefinitionHash) JOIN sys.sql_modules m
   ON m.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(v.ObjectName))
   WHERE m.object_id IS NOT NULL AND m.definition IS NOT NULL
    AND HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),m.definition))=v.DefinitionHash
    AND m.uses_ansi_nulls=1 AND m.uses_quoted_identifier=1 AND m.execute_as_principal_id IS NULL
    AND m.is_schema_bound=0 AND m.uses_native_compilation=0)=8
   THROW 55012,N'EXPORT_QUEUE11_BEFORE_VERBATIM_DEFINITIONS',19;
  -- Nur den bereits verletzten BEFORE-Leaf lokalisieren; keine neue Akzeptanz oder Runtimewerte.
  IF (SELECT COUNT(*) FROM #ExpectedDefinitions WHERE AfterValue=0)<>8
   THROW 55012,N'EXPORT_QUEUE11_BEFORE_DEFINITION_LEAF',20;
  DECLARE @Queue11BeforeDefinitionLeafState tinyint;
  SELECT TOP(1) @Queue11BeforeDefinitionLeafState=CONVERT(tinyint,l.Component+b.SourceOrdinal)
  FROM (VALUES
   (0,N'VW_WorkQueue',0x6B5C9E5C75E9F5AFA199F7789A1CD68892EE968FC488FA8150D0858AB6ACF02C),
   (1,N'USP_EnqueueWork',0x0CF962DC4EA9D2677DE0BE66138C0B69F0BE300971607C82E79AB918B55B2423),
   (2,N'USP_ClaimWork',0xE959E0D5DEE9CA8BA0186D5BC50122450133D3704646F535A61F0731DDCB34D1),
   (3,N'USP_RenewWorkLease',0xCEB1F1A6003BFB665C82C3713A50510252090A46BA526EF536FE1AE4AC33D47B),
   (4,N'USP_RecoverExpiredWork',0x5A26635D526560FA911DE167872D93C9F09D5AD6DDF7C3144BA4691A37112777),
   (5,N'USP_CompleteWork',0xFDD256460794D7CAA76A1758598EB7F23A677D8B2D7C150553BE1D1206F558DC),
   (6,N'USP_FailWork',0xB4DD7F3B191624C6775407D89814902151C7034434AF63B7D69771B7EC5D68A3),
   (7,N'USP_GetWorkStatus',0x9102AD285EAF93E0F13AC2DD95246A015FDFE1604B3DDA16EBB22C1793A48F2F)
  ) b(SourceOrdinal,ObjectName,VerbatimHash)
  JOIN #ExpectedDefinitions e ON e.AfterValue=0
   AND e.ObjectName COLLATE Latin1_General_100_BIN2=b.ObjectName COLLATE Latin1_General_100_BIN2
  LEFT JOIN sys.sql_modules m ON m.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(b.ObjectName))
  CROSS APPLY(VALUES(HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),m.definition)))) h(DefinitionHash)
  CROSS APPLY(VALUES
   (30,CASE WHEN m.object_id IS NULL THEN 1 ELSE 0 END),
   (40,CASE WHEN m.object_id IS NOT NULL AND m.definition IS NULL THEN 1 ELSE 0 END),
   (50,CASE WHEN m.uses_ansi_nulls<>1 THEN 1 ELSE 0 END),
   (60,CASE WHEN m.uses_quoted_identifier<>1 THEN 1 ELSE 0 END),
   (70,CASE WHEN m.execute_as_principal_id IS NOT NULL THEN 1 ELSE 0 END),
   (80,CASE WHEN m.is_schema_bound<>0 THEN 1 ELSE 0 END),
   (90,CASE WHEN m.uses_native_compilation<>0 THEN 1 ELSE 0 END),
   (100,CASE WHEN h.DefinitionHash<>e.DefinitionHash AND h.DefinitionHash<>b.VerbatimHash THEN 1 ELSE 0 END),
   (110,CASE WHEN h.DefinitionHash<>e.DefinitionHash AND h.DefinitionHash=b.VerbatimHash THEN 1 ELSE 0 END)
  ) l(Component,IsViolation)
  WHERE l.IsViolation=1
  ORDER BY l.Component,b.SourceOrdinal;
  IF @Queue11BeforeDefinitionLeafState IS NOT NULL
   THROW 55012,N'EXPORT_QUEUE11_BEFORE_DEFINITION_LEAF',@Queue11BeforeDefinitionLeafState;
 END;
 THROW 55012,N'EXPORT_QUEUE11_SOURCE_DEFINITIONS',6;
END;
-- Alle fünf Queue-Objektmarker prüfen; nur tatsächliche bekannte Version/Definition ändern sich.
CREATE TABLE #QueueObjects(ObjectName sysname COLLATE Latin1_General_100_BIN2,ObjectType varchar(2) COLLATE Latin1_General_100_BIN2,ObjectId int NULL);
INSERT #QueueObjects VALUES(N'WorkItem','U',NULL),
(N'VW_WorkQueue','V',NULL),
(N'USP_EnqueueWork','P',NULL),
(N'USP_ClaimWork','P',NULL),
(N'USP_RenewWorkLease','P',NULL),
(N'USP_RecoverExpiredWork','P',NULL),
(N'USP_CompleteWork','P',NULL),
(N'USP_FailWork','P',NULL),
(N'USP_GetWorkStatus','P',NULL);
UPDATE #QueueObjects SET ObjectId=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(ObjectName),ObjectType);
DECLARE @QueueVersion nvarchar(64)=CASE WHEN @After=0 THEN N'1.1.0' ELSE N'2.1.0' END;
IF EXISTS(SELECT 1 FROM #QueueObjects o CROSS JOIN(VALUES(N'Toolbelt.ModuleId',N'toolbelt.core.work-queue'),(N'Toolbelt.ModuleVersion',@QueueVersion),(N'Toolbelt.ContractVersion',N'1.1'),(N'Toolbelt.DeploymentMode',@InstallMode))e(Name,Value)
 WHERE o.ObjectId IS NULL OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.ObjectId AND p.minor_id=0 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.Name) AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(4000),p.value))=CONVERT(varbinary(max),e.Value)))
 OR EXISTS(SELECT 1 FROM #QueueObjects o WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.ObjectId AND p.minor_id=0 AND p.name=N'Toolbelt.SourceHash' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(4000),p.value))=CONVERT(varbinary(max),CASE WHEN o.ObjectType='U' THEN N'PERSISTENT_TABLE' ELSE CONVERT(nvarchar(64),CONVERT(varchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(o.ObjectId))),2)) END)))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=0 AND p.major_id=0 AND p.minor_id=0 AND p.name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(64),p.value))=CONVERT(varbinary(max),@QueueVersion))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=0 AND p.major_id=0 AND p.minor_id=0 AND p.name=N'Toolbelt.Module.toolbelt.core.work-queue.DeploymentMode' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(16),p.value))=CONVERT(varbinary(max),@InstallMode))
 THROW 55012,N'EXPORT_QUEUE11_RELEASE_MARKERS',7;
IF @After=0 BEGIN
 IF EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_core') AND name IN(N'WorkQueueScheduler',N'WorkQueueBarrierBlocker',N'WorkQueueManagedGate',N'WorkerControlConfiguration',N'WorkerRegistration',N'WorkerSlotReservation',N'WorkerExecutionDisposition',N'WorkerExecutionCommitWitness',N'USP_ClaimWorkCore'))
  OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.core.worker-control.%')
  THROW 55012,N'EXPORT_QUEUE11_ORIGINAL_BOUNDARY',8;
END;
IF (SELECT COUNT(*) FROM sys.extended_properties p JOIN #OldTables t ON t.ObjectId=p.major_id WHERE p.class=1 AND p.name=N'Toolbelt.Test.ExportQueue11' AND p.minor_id=0)<>6
 OR (SELECT COUNT(*) FROM sys.extended_properties p JOIN #OldTables t ON t.ObjectId=p.major_id WHERE p.class=1 AND p.name=N'Toolbelt.Test.ExportQueue11' AND p.minor_id>0)<>6
 THROW 55012,N'EXPORT_QUEUE11_OWN_ANNOTATIONS',9;
IF @After=1 BEGIN
 EXEC sys.sp_executesql N'IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE CONVERT(varbinary(max),ExecutionGroup)<>CONVERT(varbinary(max),''default'') OR Priority<>0 OR CONVERT(varbinary(max),ExecutionMode)<>CONVERT(varbinary(max),''SHARED'') OR IdempotencyKey IS NOT NULL OR MaxAttempts<>3 OR RetryBaseDelaySeconds<>60 OR RetryMaxDelaySeconds<>3600 OR RetryCycleNumber<>1 OR CycleAttemptCount<>0 OR NextAttemptAtUtc IS NOT NULL OR LastErrorCode IS NOT NULL OR LastErrorMessage IS NOT NULL OR LastRetryScheduledAtUtc IS NOT NULL OR LastRetryScheduledBy IS NOT NULL OR DeadLetteredAtUtc IS NOT NULL OR DeadLetteredBy IS NOT NULL OR LastRequeuedAtUtc IS NOT NULL OR LastRequeuedBy IS NOT NULL OR LastRequeueReason IS NOT NULL OR BarrierEpoch<>0 OR ManagedReservationId IS NOT NULL OR ManagedHold<>0 OR ManagedCompletionNonce IS NOT NULL)
 THROW 55012,N''EXPORT_QUEUE11_23_DEFAULT_VALUES'',10;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkQueueScheduler)<>1 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueScheduler WHERE SchedulerId=1)
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkQueueManagedGate)<>1 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=0 AND AdmissionToken IS NOT NULL AND PendingReservationId IS NULL)
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkerControlConfiguration)<>1 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1 AND MaxConcurrentExecutions=1 AND HeartbeatSeconds=15 AND UnreachableSeconds=60 AND DATALENGTH(ConfigVersion)=8)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness)
 THROW 55012,N''EXPORT_QUEUE11_NEW_NEUTRAL_COUNTS'',11;
';
CREATE TABLE #NewTables(TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,ObjectId int NOT NULL);
INSERT #NewTables SELECT n,OBJECT_ID(N'toolbelt_core.'+QUOTENAME(n),N'U') FROM(VALUES
 (N'WorkQueueScheduler'),(N'WorkQueueBarrierBlocker'),(N'WorkQueueManagedGate'),(N'WorkerControlConfiguration'),(N'WorkerRegistration'),
 (N'WorkerSlotReservation'),(N'WorkerExecutionDisposition'),(N'WorkerExecutionCommitWitness'))v(n);
CREATE TABLE #ExpectedKeyColumns(TableName sysname COLLATE Latin1_General_100_BIN2,ConstraintName sysname COLLATE Latin1_General_100_BIN2,KeyType varchar(2) COLLATE Latin1_General_100_BIN2,IndexType tinyint,KeyOrdinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2);
INSERT #ExpectedKeyColumns VALUES
 (N'WorkQueueScheduler',N'PK_WorkQueueScheduler','PK',1,1,N'SchedulerId'),
 (N'WorkQueueBarrierBlocker',N'PK_WorkQueueBarrierBlocker','PK',1,1,N'BarrierWorkItemId'),
 (N'WorkQueueBarrierBlocker',N'PK_WorkQueueBarrierBlocker','PK',1,2,N'BarrierEpoch'),
 (N'WorkQueueBarrierBlocker',N'PK_WorkQueueBarrierBlocker','PK',1,3,N'BlockingWorkItemId'),
 (N'WorkQueueBarrierBlocker',N'PK_WorkQueueBarrierBlocker','PK',1,4,N'BlockingClaimGeneration'),
 (N'WorkQueueManagedGate',N'PK_WorkQueueManagedGate','PK',1,1,N'GateId'),
 (N'WorkerControlConfiguration',N'PK_WorkerControlConfiguration','PK',1,1,N'ConfigurationId'),
 (N'WorkerRegistration',N'PK_WorkerRegistration','PK',1,1,N'WorkerId'),
 (N'WorkerRegistration',N'PK_WorkerRegistration','PK',1,2,N'WorkerGeneration'),
 (N'WorkerSlotReservation',N'PK_WorkerSlotReservation','PK',1,1,N'SlotReservationId'),
 (N'WorkerSlotReservation',N'UQ_WorkerSlotReservation_Execution','UQ',2,1,N'ExecutionId'),
 (N'WorkerSlotReservation',N'UQ_WorkerSlotReservation_Claim','UQ',2,1,N'WorkItemId'),
 (N'WorkerSlotReservation',N'UQ_WorkerSlotReservation_Claim','UQ',2,2,N'ClaimGeneration'),
 (N'WorkerExecutionDisposition',N'PK_WorkerExecutionDisposition','PK',1,1,N'WorkItemId'),
 (N'WorkerExecutionCommitWitness',N'PK_WorkerExecutionCommitWitness','PK',1,1,N'SlotReservationId');
IF EXISTS(SELECT CONVERT(varbinary(max),TableName),CONVERT(varbinary(max),ConstraintName),CONVERT(varbinary(max),KeyType),IndexType,KeyOrdinal,CONVERT(varbinary(max),ColumnName) FROM #ExpectedKeyColumns EXCEPT SELECT CONVERT(varbinary(max),n.TableName) TableName,CONVERT(varbinary(max),k.name) ConstraintName,CONVERT(varbinary(max),CONVERT(varchar(2),k.type)) KeyType,i.type IndexType,ic.key_ordinal KeyOrdinal,CONVERT(varbinary(max),c.name) ColumnName FROM #NewTables n JOIN sys.key_constraints k ON k.parent_object_id=n.ObjectId JOIN sys.indexes i ON i.object_id=k.parent_object_id AND i.index_id=k.unique_index_id JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id)
 OR EXISTS(SELECT CONVERT(varbinary(max),n.TableName) TableName,CONVERT(varbinary(max),k.name) ConstraintName,CONVERT(varbinary(max),CONVERT(varchar(2),k.type)) KeyType,i.type IndexType,ic.key_ordinal KeyOrdinal,CONVERT(varbinary(max),c.name) ColumnName FROM #NewTables n JOIN sys.key_constraints k ON k.parent_object_id=n.ObjectId JOIN sys.indexes i ON i.object_id=k.parent_object_id AND i.index_id=k.unique_index_id JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id EXCEPT SELECT CONVERT(varbinary(max),TableName),CONVERT(varbinary(max),ConstraintName),CONVERT(varbinary(max),KeyType),IndexType,KeyOrdinal,CONVERT(varbinary(max),ColumnName) FROM #ExpectedKeyColumns)
 OR (SELECT COUNT(*) FROM sys.key_constraints k JOIN #NewTables n ON n.ObjectId=k.parent_object_id)<>10
 OR (SELECT COUNT(*) FROM sys.indexes i JOIN #NewTables n ON n.ObjectId=i.object_id)<>10
 OR (SELECT COUNT(*) FROM sys.index_columns c JOIN #NewTables n ON n.ObjectId=c.object_id)<>15
 OR EXISTS(SELECT 1 FROM sys.indexes i JOIN #NewTables n ON n.ObjectId=i.object_id
 WHERE i.is_unique<>1 OR i.is_disabled<>0 OR i.is_hypothetical<>0 OR i.has_filter<>0 OR i.filter_definition IS NOT NULL
 OR i.ignore_dup_key<>0 OR (i.is_primary_key=0 AND i.is_unique_constraint=0))
 OR EXISTS(SELECT 1 FROM sys.key_constraints k JOIN #NewTables n ON n.ObjectId=k.parent_object_id
 JOIN sys.indexes i ON i.object_id=k.parent_object_id AND i.index_id=k.unique_index_id
 WHERE CONVERT(varbinary(max),k.name)<>CONVERT(varbinary(max),i.name) OR k.is_system_named<>0
 OR (k.type='PK' AND (i.is_primary_key<>1 OR i.is_unique_constraint<>0))
 OR (k.type='UQ' AND (i.is_primary_key<>0 OR i.is_unique_constraint<>1)))
 OR EXISTS(SELECT 1 FROM sys.index_columns c JOIN #NewTables n ON n.ObjectId=c.object_id WHERE c.is_descending_key<>0 OR c.is_included_column<>0 OR c.partition_ordinal<>0)
 THROW 55012,N'EXPORT_QUEUE11_NEW_KEYS',10;
CREATE TABLE #ExpectedFkColumns(TableName sysname COLLATE Latin1_General_100_BIN2,ConstraintName sysname COLLATE Latin1_General_100_BIN2,ColumnOrdinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2,ReferencedSchema sysname COLLATE Latin1_General_100_BIN2,ReferencedTable sysname COLLATE Latin1_General_100_BIN2,ReferencedColumn sysname COLLATE Latin1_General_100_BIN2);
INSERT #ExpectedFkColumns VALUES
 (N'WorkQueueBarrierBlocker',N'FK_WorkQueueBarrierBlocker_Barrier',1,N'BarrierWorkItemId',N'toolbelt_core',N'WorkItem',N'WorkItemId'),
 (N'WorkQueueBarrierBlocker',N'FK_WorkQueueBarrierBlocker_Blocking',1,N'BlockingWorkItemId',N'toolbelt_core',N'WorkItem',N'WorkItemId'),
 (N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkerRegistration',1,N'WorkerId',N'toolbelt_core',N'WorkerRegistration',N'WorkerId'),
 (N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkerRegistration',2,N'WorkerGeneration',N'toolbelt_core',N'WorkerRegistration',N'WorkerGeneration'),
 (N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkItem',1,N'WorkItemId',N'toolbelt_core',N'WorkItem',N'WorkItemId'),
 (N'WorkerExecutionDisposition',N'FK_WorkerExecutionDisposition_WorkItem',1,N'WorkItemId',N'toolbelt_core',N'WorkItem',N'WorkItemId'),
 (N'WorkerExecutionDisposition',N'FK_WorkerExecutionDisposition_Reservation',1,N'SlotReservationId',N'toolbelt_core',N'WorkerSlotReservation',N'SlotReservationId'),
 (N'WorkerExecutionCommitWitness',N'FK_WorkerExecutionCommitWitness_Reservation',1,N'SlotReservationId',N'toolbelt_core',N'WorkerSlotReservation',N'SlotReservationId');
IF EXISTS(SELECT CONVERT(varbinary(max),TableName),CONVERT(varbinary(max),ConstraintName),ColumnOrdinal,CONVERT(varbinary(max),ColumnName),CONVERT(varbinary(max),ReferencedSchema),CONVERT(varbinary(max),ReferencedTable),CONVERT(varbinary(max),ReferencedColumn) FROM #ExpectedFkColumns EXCEPT SELECT CONVERT(varbinary(max),n.TableName) TableName,CONVERT(varbinary(max),f.name) ConstraintName,fc.constraint_column_id ColumnOrdinal,CONVERT(varbinary(max),pc.name) ColumnName,CONVERT(varbinary(max),rs.name) ReferencedSchema,CONVERT(varbinary(max),rt.name) ReferencedTable,CONVERT(varbinary(max),rc.name) ReferencedColumn FROM #NewTables n JOIN sys.foreign_keys f ON f.parent_object_id=n.ObjectId JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id JOIN sys.tables rt ON rt.object_id=fc.referenced_object_id JOIN sys.schemas rs ON rs.schema_id=rt.schema_id JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id)
 OR EXISTS(SELECT CONVERT(varbinary(max),n.TableName) TableName,CONVERT(varbinary(max),f.name) ConstraintName,fc.constraint_column_id ColumnOrdinal,CONVERT(varbinary(max),pc.name) ColumnName,CONVERT(varbinary(max),rs.name) ReferencedSchema,CONVERT(varbinary(max),rt.name) ReferencedTable,CONVERT(varbinary(max),rc.name) ReferencedColumn FROM #NewTables n JOIN sys.foreign_keys f ON f.parent_object_id=n.ObjectId JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id JOIN sys.tables rt ON rt.object_id=fc.referenced_object_id JOIN sys.schemas rs ON rs.schema_id=rt.schema_id JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id EXCEPT SELECT CONVERT(varbinary(max),TableName),CONVERT(varbinary(max),ConstraintName),ColumnOrdinal,CONVERT(varbinary(max),ColumnName),CONVERT(varbinary(max),ReferencedSchema),CONVERT(varbinary(max),ReferencedTable),CONVERT(varbinary(max),ReferencedColumn) FROM #ExpectedFkColumns)
 OR (SELECT COUNT(*) FROM sys.foreign_keys f JOIN #NewTables n ON n.ObjectId=f.parent_object_id)<>7
 OR (SELECT COUNT(*) FROM sys.foreign_key_columns f JOIN #NewTables n ON n.ObjectId=f.parent_object_id)<>8
 OR EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #NewTables n ON n.ObjectId=f.parent_object_id
 WHERE f.is_disabled<>0 OR f.is_not_trusted<>0 OR f.is_not_for_replication<>0 OR f.delete_referential_action<>0 OR f.update_referential_action<>0 OR f.is_system_named<>0
 OR NOT EXISTS(SELECT 1 FROM sys.key_constraints k WHERE k.parent_object_id=f.referenced_object_id AND k.type='PK' AND k.unique_index_id=f.key_index_id))
 THROW 55012,N'EXPORT_QUEUE11_NEW_FKS',11;
-- Zehn Compiler-kanonische positive CHECK-Ausdrücke: anonyme lokale Tempconstraints.
-- Sourceausdrücke unverändert; keine Zeichen-/Klammernormalisierung, keine global benannten Temp-PKs.
CREATE TABLE #ExpectedChecks(TableName sysname COLLATE Latin1_General_100_BIN2,ConstraintName sysname COLLATE Latin1_General_100_BIN2,MirrorObjectId int NOT NULL,SourceColumnName sysname COLLATE Latin1_General_100_BIN2 NULL);
CREATE TABLE #CheckMirror0(GateId tinyint NOT NULL,CHECK(GateId=1));
INSERT #ExpectedChecks VALUES(N'WorkQueueManagedGate',N'CK_WorkQueueManagedGate_Id',OBJECT_ID(N'tempdb..#CheckMirror0'),N'GateId');
CREATE TABLE #CheckMirror1(ConfigurationId tinyint NOT NULL,CHECK(ConfigurationId=1));
INSERT #ExpectedChecks VALUES(N'WorkerControlConfiguration',N'CK_WorkerControlConfiguration_Id',OBJECT_ID(N'tempdb..#CheckMirror1'),N'ConfigurationId');
CREATE TABLE #CheckMirror2(MaxConcurrentExecutions int NOT NULL,HeartbeatSeconds int NOT NULL,UnreachableSeconds int NOT NULL,CHECK(MaxConcurrentExecutions>=0 AND HeartbeatSeconds BETWEEN 1 AND 3600 AND UnreachableSeconds BETWEEN 3 AND 86400 AND UnreachableSeconds>=3*HeartbeatSeconds));
INSERT #ExpectedChecks VALUES(N'WorkerControlConfiguration',N'CK_WorkerControlConfiguration_Limits',OBJECT_ID(N'tempdb..#CheckMirror2'),NULL);
CREATE TABLE #CheckMirror3(WorkerGeneration bigint NOT NULL,CHECK(WorkerGeneration>0));
INSERT #ExpectedChecks VALUES(N'WorkerRegistration',N'CK_WorkerRegistration_Generation',OBJECT_ID(N'tempdb..#CheckMirror3'),N'WorkerGeneration');
CREATE TABLE #CheckMirror4(State varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,CHECK(State IN('ACTIVE','PAUSED','DRAINING','UNREACHABLE','CLOSED')));
INSERT #ExpectedChecks VALUES(N'WorkerRegistration',N'CK_WorkerRegistration_State',OBJECT_ID(N'tempdb..#CheckMirror4'),N'State');
CREATE TABLE #CheckMirror5(Capacity int NOT NULL,CHECK(Capacity>0));
INSERT #ExpectedChecks VALUES(N'WorkerRegistration',N'CK_WorkerRegistration_Capacity',OBJECT_ID(N'tempdb..#CheckMirror5'),N'Capacity');
CREATE TABLE #CheckMirror6(RunMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,CHECK(RunMode IN('BOUNDED','CONTINUOUS')));
INSERT #ExpectedChecks VALUES(N'WorkerRegistration',N'CK_WorkerRegistration_RunMode',OBJECT_ID(N'tempdb..#CheckMirror6'),N'RunMode');
CREATE TABLE #CheckMirror7(State varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,CHECK(State IN('RESERVED','RUNNING','STOP_REQUESTED','STOPPING','UNKNOWN','COMMITTED','ROLLED_BACK','CLOSED')));
INSERT #ExpectedChecks VALUES(N'WorkerSlotReservation',N'CK_WorkerSlotReservation_State',OBJECT_ID(N'tempdb..#CheckMirror7'),N'State');
CREATE TABLE #CheckMirror8(StopStatus varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,CHECK(StopStatus IN('NONE','REQUESTED','STOPPING','ROLLED_BACK_HELD','ALREADY_COMMITTED','UNKNOWN')));
INSERT #ExpectedChecks VALUES(N'WorkerExecutionDisposition',N'CK_WorkerExecutionDisposition_Stop',OBJECT_ID(N'tempdb..#CheckMirror8'),N'StopStatus');
CREATE TABLE #CheckMirror9(SchedulerId tinyint NOT NULL CHECK(SchedulerId=1));
INSERT #ExpectedChecks VALUES(N'WorkQueueScheduler',NULL,OBJECT_ID(N'tempdb..#CheckMirror9'),N'SchedulerId');
IF (SELECT COUNT(*) FROM sys.check_constraints c JOIN #NewTables n ON n.ObjectId=c.parent_object_id)<>10
 OR (SELECT COUNT(*) FROM tempdb.sys.check_constraints c JOIN #ExpectedChecks e ON e.MirrorObjectId=c.parent_object_id)<>10
 OR EXISTS(SELECT 1 FROM #ExpectedChecks e JOIN #NewTables n ON n.TableName=e.TableName
 LEFT JOIN sys.check_constraints c ON c.parent_object_id=n.ObjectId AND (CONVERT(varbinary(max),c.name)=CONVERT(varbinary(max),e.ConstraintName) OR (e.ConstraintName IS NULL AND e.TableName=N'WorkQueueScheduler'))
 LEFT JOIN tempdb.sys.check_constraints m ON m.parent_object_id=e.MirrorObjectId
 LEFT JOIN sys.columns pc ON pc.object_id=c.parent_object_id AND pc.column_id=c.parent_column_id
 LEFT JOIN tempdb.sys.columns mc ON mc.object_id=m.parent_object_id AND mc.column_id=m.parent_column_id
 WHERE c.object_id IS NULL OR m.object_id IS NULL OR CONVERT(varbinary(max),c.definition)<>CONVERT(varbinary(max),m.definition)
 OR c.is_disabled<>0 OR c.is_not_trusted<>0 OR c.is_not_for_replication<>0 OR c.is_system_named<>CASE WHEN e.ConstraintName IS NULL THEN 1 ELSE 0 END OR (c.parent_column_id IS NULL OR m.parent_column_id IS NULL OR NOT (
 (e.SourceColumnName IS NULL AND c.parent_column_id=0 AND m.parent_column_id=0)
 OR (e.SourceColumnName IS NOT NULL AND (
  (c.parent_column_id=0 AND m.parent_column_id=0)
  OR (c.parent_column_id>0 AND m.parent_column_id>0
   AND pc.column_id IS NOT NULL AND mc.column_id IS NOT NULL
   AND CONVERT(varbinary(max),pc.name)=CONVERT(varbinary(max),e.SourceColumnName)
   AND CONVERT(varbinary(max),mc.name)=CONVERT(varbinary(max),e.SourceColumnName)
   AND pc.system_type_id=mc.system_type_id
   AND pc.user_type_id=pc.system_type_id AND mc.user_type_id=mc.system_type_id
   AND pc.max_length=mc.max_length AND pc.precision=mc.precision AND pc.scale=mc.scale
   AND pc.is_nullable=mc.is_nullable
   AND pc.is_computed=0 AND mc.is_computed=0 AND pc.is_identity=0 AND mc.is_identity=0
   AND ((pc.collation_name IS NULL AND mc.collation_name IS NULL)
    OR (pc.collation_name IS NOT NULL AND mc.collation_name IS NOT NULL
     AND CONVERT(varbinary(max),pc.collation_name)=CONVERT(varbinary(max),mc.collation_name)))
  )
 ))
))
 OR c.uses_database_collation<>m.uses_database_collation)
 THROW 55012,N'EXPORT_QUEUE11_NEW_CHECK_SHAPES',14;

IF EXISTS(SELECT 1 FROM sys.columns c JOIN #NewTables n ON n.ObjectId=c.object_id WHERE c.is_identity<>0 OR (c.default_object_id<>0 AND NOT(n.TableName=N'WorkQueueBarrierBlocker' AND c.name=N'CapturedAtUtc')))
 OR EXISTS(SELECT 1 FROM sys.default_constraints c JOIN #NewTables n ON n.ObjectId=c.parent_object_id WHERE NOT(n.TableName=N'WorkQueueBarrierBlocker' AND c.name=N'DF_WorkQueueBarrierBlocker_CapturedAtUtc' AND c.parent_column_id=5 AND c.is_system_named=0))
 OR EXISTS(SELECT 1 FROM sys.triggers t JOIN #NewTables n ON n.ObjectId=t.parent_id)
 THROW 55012,N'EXPORT_QUEUE11_NEW_FORMS',13;
DROP TABLE #CheckMirror0;
DROP TABLE #CheckMirror1;
DROP TABLE #CheckMirror2;
DROP TABLE #CheckMirror3;
DROP TABLE #CheckMirror4;
DROP TABLE #CheckMirror5;
DROP TABLE #CheckMirror6;
DROP TABLE #CheckMirror7;
DROP TABLE #CheckMirror8;DROP TABLE #CheckMirror9;
DROP TABLE #ExpectedChecks;DROP TABLE #ExpectedFkColumns;DROP TABLE #ExpectedKeyColumns;DROP TABLE #NewTables;
IF EXISTS(SELECT 1 FROM(VALUES
(N'WorkItem',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'WorkQueueBarrierBlocker',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'WorkQueueManagedGate',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'WorkQueueScheduler',N'toolbelt.core.work-queue',N'2.1.0',N'1.1'),
(N'WorkerControlConfiguration',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'WorkerExecutionCommitWitness',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'WorkerExecutionDisposition',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'WorkerRegistration',N'toolbelt.core.worker-control',N'1.0.0',N'1.0'),
(N'WorkerSlotReservation',N'toolbelt.core.worker-control',N'1.0.0',N'1.0')
)o(TableName,ModuleId,Version,ContractVersion) CROSS APPLY(VALUES(N'Toolbelt.ModuleId',o.ModuleId),(N'Toolbelt.ModuleVersion',o.Version),(N'Toolbelt.ContractVersion',o.ContractVersion),(N'Toolbelt.DeploymentMode',@InstallMode),(N'Toolbelt.SourceHash',N'PERSISTENT_TABLE'))e(Name,Value)
 WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(o.TableName),N'U') AND p.minor_id=0 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.Name) AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(4000),p.value))=CONVERT(varbinary(max),e.Value)))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=0 AND p.major_id=0 AND p.minor_id=0 AND p.name=N'Toolbelt.Module.toolbelt.core.worker-control.Version' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(64),p.value))=CONVERT(varbinary(max),N'1.0.0'))
 THROW 55012,N'EXPORT_QUEUE11_TARGET_MARKERS',15;
CREATE TABLE #ExpectedDefaults(TableName sysname COLLATE Latin1_General_100_BIN2,ColumnName sysname COLLATE Latin1_General_100_BIN2,ConstraintName sysname COLLATE Latin1_General_100_BIN2,MirrorObjectId int);
CREATE TABLE #DefaultMirror0(ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL DEFAULT('default'));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'ExecutionGroup',N'DF_WorkItem_ExecutionGroup',OBJECT_ID(N'tempdb..#DefaultMirror0'));
CREATE TABLE #DefaultMirror1(Priority tinyint NOT NULL DEFAULT(0));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'Priority',N'DF_WorkItem_Priority',OBJECT_ID(N'tempdb..#DefaultMirror1'));
CREATE TABLE #DefaultMirror2(ExecutionMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL DEFAULT('SHARED'));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'ExecutionMode',N'DF_WorkItem_ExecutionMode',OBJECT_ID(N'tempdb..#DefaultMirror2'));
CREATE TABLE #DefaultMirror3(MaxAttempts tinyint NOT NULL DEFAULT(3));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'MaxAttempts',N'DF_WorkItem_MaxAttempts',OBJECT_ID(N'tempdb..#DefaultMirror3'));
CREATE TABLE #DefaultMirror4(RetryBaseDelaySeconds int NOT NULL DEFAULT(60));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'RetryBaseDelaySeconds',N'DF_WorkItem_RetryBaseDelaySeconds',OBJECT_ID(N'tempdb..#DefaultMirror4'));
CREATE TABLE #DefaultMirror5(RetryMaxDelaySeconds int NOT NULL DEFAULT(3600));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'RetryMaxDelaySeconds',N'DF_WorkItem_RetryMaxDelaySeconds',OBJECT_ID(N'tempdb..#DefaultMirror5'));
CREATE TABLE #DefaultMirror6(RetryCycleNumber bigint NOT NULL DEFAULT(1));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'RetryCycleNumber',N'DF_WorkItem_RetryCycleNumber',OBJECT_ID(N'tempdb..#DefaultMirror6'));
CREATE TABLE #DefaultMirror7(CycleAttemptCount bigint NOT NULL DEFAULT(0));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'CycleAttemptCount',N'DF_WorkItem_CycleAttemptCount',OBJECT_ID(N'tempdb..#DefaultMirror7'));
CREATE TABLE #DefaultMirror8(BarrierEpoch bigint NOT NULL DEFAULT(0));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'BarrierEpoch',N'DF_WorkItem_BarrierEpoch',OBJECT_ID(N'tempdb..#DefaultMirror8'));
CREATE TABLE #DefaultMirror9(ManagedHold bit NOT NULL DEFAULT(0));
INSERT #ExpectedDefaults VALUES(N'WorkItem',N'ManagedHold',N'DF_WorkItem_ManagedHold',OBJECT_ID(N'tempdb..#DefaultMirror9'));
CREATE TABLE #DefaultMirror10(CapturedAtUtc datetime2(7) NOT NULL DEFAULT(SYSUTCDATETIME()));
INSERT #ExpectedDefaults VALUES(N'WorkQueueBarrierBlocker',N'CapturedAtUtc',N'DF_WorkQueueBarrierBlocker_CapturedAtUtc',OBJECT_ID(N'tempdb..#DefaultMirror10'));
IF (SELECT COUNT(*) FROM #ExpectedDefaults)<>11
 OR (SELECT COUNT(*) FROM sys.default_constraints d WHERE (d.parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND d.parent_column_id>23) OR d.parent_object_id=OBJECT_ID(N'toolbelt_core.WorkQueueBarrierBlocker'))<>11
 OR EXISTS(SELECT 1 FROM #ExpectedDefaults e LEFT JOIN sys.columns c ON c.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName)) AND CONVERT(varbinary(max),c.name)=CONVERT(varbinary(max),e.ColumnName)
 LEFT JOIN sys.default_constraints d ON d.parent_object_id=c.object_id AND d.parent_column_id=c.column_id
 LEFT JOIN tempdb.sys.default_constraints m ON m.parent_object_id=e.MirrorObjectId
 WHERE c.column_id IS NULL OR d.object_id IS NULL OR m.object_id IS NULL OR CONVERT(varbinary(max),d.name)<>CONVERT(varbinary(max),e.ConstraintName) OR d.is_system_named<>0 OR CONVERT(varbinary(max),d.definition)<>CONVERT(varbinary(max),m.definition))
 THROW 55012,N'EXPORT_QUEUE11_NEW_DEFAULT_SHAPES',16;
DROP TABLE #DefaultMirror0;
DROP TABLE #DefaultMirror1;
DROP TABLE #DefaultMirror2;
DROP TABLE #DefaultMirror3;
DROP TABLE #DefaultMirror4;
DROP TABLE #DefaultMirror5;
DROP TABLE #DefaultMirror6;
DROP TABLE #DefaultMirror7;
DROP TABLE #DefaultMirror8;
DROP TABLE #DefaultMirror9;
DROP TABLE #DefaultMirror10;
DROP TABLE #ExpectedDefaults;
CREATE TABLE #ExpectedWorkItemIndexColumns(IndexName sysname COLLATE Latin1_General_100_BIN2,KeyOrdinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2,DescendingValue bit);
INSERT #ExpectedWorkItemIndexColumns VALUES(N'UX_WorkItem_WorkType_IdempotencyKey',1,N'WorkTypeId',0),(N'UX_WorkItem_WorkType_IdempotencyKey',2,N'IdempotencyKey',0),(N'IX_WorkItem_Scheduling',1,N'Status',0),(N'IX_WorkItem_Scheduling',2,N'Priority',1),(N'IX_WorkItem_Scheduling',3,N'ExecutionGroup',0),(N'IX_WorkItem_Scheduling',4,N'NextAttemptAtUtc',0),(N'IX_WorkItem_Scheduling',5,N'WorkItemId',0);
CREATE TABLE #FilterMirror(WorkTypeId bigint NOT NULL,IdempotencyKey varchar(128) COLLATE Latin1_General_100_BIN2 NULL);
CREATE UNIQUE NONCLUSTERED INDEX FilterMirrorIndex ON #FilterMirror(WorkTypeId,IdempotencyKey) WHERE IdempotencyKey IS NOT NULL;
IF EXISTS(SELECT CONVERT(varbinary(max),e.IndexName),e.KeyOrdinal,CONVERT(varbinary(max),e.ColumnName),e.DescendingValue FROM #ExpectedWorkItemIndexColumns e EXCEPT SELECT CONVERT(varbinary(max),i.name),ic.key_ordinal,CONVERT(varbinary(max),c.name),ic.is_descending_key FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE i.object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND i.name IN(N'UX_WorkItem_WorkType_IdempotencyKey',N'IX_WorkItem_Scheduling'))
 OR EXISTS(SELECT CONVERT(varbinary(max),i.name),ic.key_ordinal,CONVERT(varbinary(max),c.name),ic.is_descending_key FROM sys.indexes i JOIN sys.index_columns ic ON ic.object_id=i.object_id AND ic.index_id=i.index_id JOIN sys.columns c ON c.object_id=ic.object_id AND c.column_id=ic.column_id WHERE i.object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND i.name IN(N'UX_WorkItem_WorkType_IdempotencyKey',N'IX_WorkItem_Scheduling') EXCEPT SELECT CONVERT(varbinary(max),e.IndexName),e.KeyOrdinal,CONVERT(varbinary(max),e.ColumnName),e.DescendingValue FROM #ExpectedWorkItemIndexColumns e)
 OR (SELECT COUNT(*) FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.WorkItem'))<>6
 OR (SELECT COUNT(*) FROM sys.indexes WHERE object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND name IN(N'UX_WorkItem_WorkType_IdempotencyKey',N'IX_WorkItem_Scheduling'))<>2
 OR EXISTS(SELECT 1 FROM sys.indexes i WHERE i.object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND i.name IN(N'UX_WorkItem_WorkType_IdempotencyKey',N'IX_WorkItem_Scheduling') AND (i.type<>2 OR i.is_unique<>CASE WHEN i.name=N'UX_WorkItem_WorkType_IdempotencyKey' THEN 1 ELSE 0 END OR i.is_disabled<>0 OR i.is_hypothetical<>0 OR i.is_primary_key<>0 OR i.is_unique_constraint<>0 OR i.ignore_dup_key<>0 OR i.has_filter<>CASE WHEN i.name=N'UX_WorkItem_WorkType_IdempotencyKey' THEN 1 ELSE 0 END OR (i.name=N'IX_WorkItem_Scheduling' AND i.filter_definition IS NOT NULL) OR (i.name=N'UX_WorkItem_WorkType_IdempotencyKey' AND (i.filter_definition IS NULL OR CONVERT(varbinary(max),i.filter_definition)<>(SELECT CONVERT(varbinary(max),filter_definition) FROM tempdb.sys.indexes WHERE object_id=OBJECT_ID(N'tempdb..#FilterMirror') AND name=N'FilterMirrorIndex')))))
 OR EXISTS(SELECT 1 FROM sys.index_columns ic JOIN sys.indexes i ON i.object_id=ic.object_id AND i.index_id=ic.index_id WHERE i.object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND i.name IN(N'UX_WorkItem_WorkType_IdempotencyKey',N'IX_WorkItem_Scheduling') AND (ic.is_included_column<>0 OR ic.partition_ordinal<>0))
 THROW 55012,N'EXPORT_QUEUE11_NEW_INDEX_SHAPES',17;
DROP TABLE #FilterMirror;DROP TABLE #ExpectedWorkItemIndexColumns;
END;
CREATE TABLE #ExpectedWorkItemChecks(ConstraintName sysname COLLATE Latin1_General_100_BIN2,MirrorObjectId int NOT NULL);
IF @After=0 BEGIN
CREATE TABLE #WorkItemCheck0_0(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,CHECK ([Status] IN ('QUEUED', 'CLAIMED', 'COMPLETED', 'FAILED')));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_Status',OBJECT_ID(N'tempdb..#WorkItemCheck0_0'));
CREATE TABLE #WorkItemCheck0_1(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,CHECK (
              [PayloadJson] IS NULL OR
              (DATALENGTH([PayloadJson]) <= 65536 AND ISJSON([PayloadJson]) = 1 AND LEFT(LTRIM([PayloadJson]), 1) = N'{')
          ));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_PayloadJson',OBJECT_ID(N'tempdb..#WorkItemCheck0_1'));
CREATE TABLE #WorkItemCheck0_2(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,CHECK (
              [FailureCode] IS NULL OR
              (LEN([FailureCode]) BETWEEN 1 AND 64
               AND [FailureCode] LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2
               AND [FailureCode] NOT LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2)
          ));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_FailureCode',OBJECT_ID(N'tempdb..#WorkItemCheck0_2'));
CREATE TABLE #WorkItemCheck0_3(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,CHECK (
              ([RecoveryCount] = 0 AND [LastRecoveredAtUtc] IS NULL AND [LastRecoveredBy] IS NULL)
              OR ([RecoveryCount] > 0 AND [LastRecoveredAtUtc] IS NOT NULL AND [LastRecoveredBy] IS NOT NULL)
          ));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_RecoveryMetadata',OBJECT_ID(N'tempdb..#WorkItemCheck0_3'));
CREATE TABLE #WorkItemCheck0_4(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,CHECK (
              ([Status] = 'QUEUED'
               AND [ClaimedAtUtc] IS NULL AND [ClaimedBy] IS NULL AND [ClaimToken] IS NULL
               AND [LeaseDurationSeconds] IS NULL AND [LeaseUntilUtc] IS NULL AND [LastHeartbeatAtUtc] IS NULL
               AND [CompletedAtUtc] IS NULL AND [CompletedBy] IS NULL
               AND [FailedAtUtc] IS NULL AND [FailedBy] IS NULL
               AND [FailureCode] IS NULL AND [FailureMessage] IS NULL)
              OR
              ([Status] = 'CLAIMED'
               AND [ClaimedAtUtc] IS NOT NULL AND [ClaimedBy] IS NOT NULL AND [ClaimToken] IS NOT NULL
               AND [ClaimGeneration] > 0 AND [LeaseDurationSeconds] BETWEEN 5 AND 86400
               AND [LeaseUntilUtc] IS NOT NULL AND [LastHeartbeatAtUtc] IS NOT NULL
               AND [CompletedAtUtc] IS NULL AND [CompletedBy] IS NULL
               AND [FailedAtUtc] IS NULL AND [FailedBy] IS NULL
               AND [FailureCode] IS NULL AND [FailureMessage] IS NULL)
              OR
              ([Status] = 'COMPLETED'
               AND [ClaimedAtUtc] IS NOT NULL AND [ClaimedBy] IS NOT NULL AND [ClaimToken] IS NOT NULL
               AND [ClaimGeneration] > 0 AND [LeaseDurationSeconds] BETWEEN 5 AND 86400
               AND [LeaseUntilUtc] IS NOT NULL AND [LastHeartbeatAtUtc] IS NOT NULL
               AND [CompletedAtUtc] IS NOT NULL AND [CompletedBy] IS NOT NULL
               AND [FailedAtUtc] IS NULL AND [FailedBy] IS NULL
               AND [FailureCode] IS NULL AND [FailureMessage] IS NULL)
              OR
              ([Status] = 'FAILED'
               AND [ClaimedAtUtc] IS NOT NULL AND [ClaimedBy] IS NOT NULL AND [ClaimToken] IS NOT NULL
               AND [ClaimGeneration] > 0 AND [LeaseDurationSeconds] BETWEEN 5 AND 86400
               AND [LeaseUntilUtc] IS NOT NULL AND [LastHeartbeatAtUtc] IS NOT NULL
               AND [CompletedAtUtc] IS NULL AND [CompletedBy] IS NULL
               AND [FailedAtUtc] IS NOT NULL AND [FailedBy] IS NOT NULL
               AND [FailureCode] IS NOT NULL)
          ));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_StateMetadata',OBJECT_ID(N'tempdb..#WorkItemCheck0_4'));
END ELSE BEGIN
CREATE TABLE #WorkItemCheck1_0(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Priority tinyint NOT NULL,ExecutionMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,IdempotencyKey varchar(128) COLLATE Latin1_General_100_BIN2 NULL,MaxAttempts tinyint NOT NULL,RetryBaseDelaySeconds int NOT NULL,RetryMaxDelaySeconds int NOT NULL,RetryCycleNumber bigint NOT NULL,CycleAttemptCount bigint NOT NULL,NextAttemptAtUtc datetime2(7) NULL,LastErrorCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,LastErrorMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,LastRetryScheduledAtUtc datetime2(7) NULL,LastRetryScheduledBy sysname COLLATE DATABASE_DEFAULT NULL,DeadLetteredAtUtc datetime2(7) NULL,DeadLetteredBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeuedAtUtc datetime2(7) NULL,LastRequeuedBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeueReason nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,BarrierEpoch bigint NOT NULL,ManagedReservationId uniqueidentifier NULL,ManagedHold bit NOT NULL,ManagedCompletionNonce uniqueidentifier NULL,CHECK (Status IN ('QUEUED','BARRIER_WAIT','CLAIMED','RETRY_WAIT','COMPLETED','FAILED','DEAD_LETTER')));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_Status',OBJECT_ID(N'tempdb..#WorkItemCheck1_0'));
CREATE TABLE #WorkItemCheck1_1(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Priority tinyint NOT NULL,ExecutionMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,IdempotencyKey varchar(128) COLLATE Latin1_General_100_BIN2 NULL,MaxAttempts tinyint NOT NULL,RetryBaseDelaySeconds int NOT NULL,RetryMaxDelaySeconds int NOT NULL,RetryCycleNumber bigint NOT NULL,CycleAttemptCount bigint NOT NULL,NextAttemptAtUtc datetime2(7) NULL,LastErrorCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,LastErrorMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,LastRetryScheduledAtUtc datetime2(7) NULL,LastRetryScheduledBy sysname COLLATE DATABASE_DEFAULT NULL,DeadLetteredAtUtc datetime2(7) NULL,DeadLetteredBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeuedAtUtc datetime2(7) NULL,LastRequeuedBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeueReason nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,BarrierEpoch bigint NOT NULL,ManagedReservationId uniqueidentifier NULL,ManagedHold bit NOT NULL,ManagedCompletionNonce uniqueidentifier NULL,CHECK (Status IN ('QUEUED','BARRIER_WAIT','CLAIMED','RETRY_WAIT','COMPLETED','FAILED','DEAD_LETTER')));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_StateMetadata',OBJECT_ID(N'tempdb..#WorkItemCheck1_1'));
CREATE TABLE #WorkItemCheck1_2(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Priority tinyint NOT NULL,ExecutionMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,IdempotencyKey varchar(128) COLLATE Latin1_General_100_BIN2 NULL,MaxAttempts tinyint NOT NULL,RetryBaseDelaySeconds int NOT NULL,RetryMaxDelaySeconds int NOT NULL,RetryCycleNumber bigint NOT NULL,CycleAttemptCount bigint NOT NULL,NextAttemptAtUtc datetime2(7) NULL,LastErrorCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,LastErrorMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,LastRetryScheduledAtUtc datetime2(7) NULL,LastRetryScheduledBy sysname COLLATE DATABASE_DEFAULT NULL,DeadLetteredAtUtc datetime2(7) NULL,DeadLetteredBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeuedAtUtc datetime2(7) NULL,LastRequeuedBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeueReason nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,BarrierEpoch bigint NOT NULL,ManagedReservationId uniqueidentifier NULL,ManagedHold bit NOT NULL,ManagedCompletionNonce uniqueidentifier NULL,CHECK (ExecutionGroup<>'' AND ExecutionMode IN ('SHARED','DRAIN_BARRIER') AND MaxAttempts BETWEEN 1 AND 10
     AND RetryBaseDelaySeconds BETWEEN 1 AND 86400 AND RetryMaxDelaySeconds BETWEEN RetryBaseDelaySeconds AND 86400
     AND RetryCycleNumber>=1 AND CycleAttemptCount>=0 AND BarrierEpoch>=0));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_W6cPolicy',OBJECT_ID(N'tempdb..#WorkItemCheck1_2'));
CREATE TABLE #WorkItemCheck1_3(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Priority tinyint NOT NULL,ExecutionMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,IdempotencyKey varchar(128) COLLATE Latin1_General_100_BIN2 NULL,MaxAttempts tinyint NOT NULL,RetryBaseDelaySeconds int NOT NULL,RetryMaxDelaySeconds int NOT NULL,RetryCycleNumber bigint NOT NULL,CycleAttemptCount bigint NOT NULL,NextAttemptAtUtc datetime2(7) NULL,LastErrorCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,LastErrorMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,LastRetryScheduledAtUtc datetime2(7) NULL,LastRetryScheduledBy sysname COLLATE DATABASE_DEFAULT NULL,DeadLetteredAtUtc datetime2(7) NULL,DeadLetteredBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeuedAtUtc datetime2(7) NULL,LastRequeuedBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeueReason nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,BarrierEpoch bigint NOT NULL,ManagedReservationId uniqueidentifier NULL,ManagedHold bit NOT NULL,ManagedCompletionNonce uniqueidentifier NULL,CHECK (
        (RecoveryCount = 0 AND LastRecoveredAtUtc IS NULL AND LastRecoveredBy IS NULL)
        OR (RecoveryCount > 0 AND LastRecoveredAtUtc IS NOT NULL AND LastRecoveredBy IS NOT NULL)
    ));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_RecoveryMetadata',OBJECT_ID(N'tempdb..#WorkItemCheck1_3'));
CREATE TABLE #WorkItemCheck1_4(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Priority tinyint NOT NULL,ExecutionMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,IdempotencyKey varchar(128) COLLATE Latin1_General_100_BIN2 NULL,MaxAttempts tinyint NOT NULL,RetryBaseDelaySeconds int NOT NULL,RetryMaxDelaySeconds int NOT NULL,RetryCycleNumber bigint NOT NULL,CycleAttemptCount bigint NOT NULL,NextAttemptAtUtc datetime2(7) NULL,LastErrorCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,LastErrorMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,LastRetryScheduledAtUtc datetime2(7) NULL,LastRetryScheduledBy sysname COLLATE DATABASE_DEFAULT NULL,DeadLetteredAtUtc datetime2(7) NULL,DeadLetteredBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeuedAtUtc datetime2(7) NULL,LastRequeuedBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeueReason nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,BarrierEpoch bigint NOT NULL,ManagedReservationId uniqueidentifier NULL,ManagedHold bit NOT NULL,ManagedCompletionNonce uniqueidentifier NULL,CHECK (
              [PayloadJson] IS NULL OR
              (DATALENGTH([PayloadJson]) <= 65536 AND ISJSON([PayloadJson]) = 1 AND LEFT(LTRIM([PayloadJson]), 1) = N'{')
          ));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_PayloadJson',OBJECT_ID(N'tempdb..#WorkItemCheck1_4'));
CREATE TABLE #WorkItemCheck1_5(WorkItemId bigint NOT NULL,WorkTypeId bigint NOT NULL,PayloadJson nvarchar(max) COLLATE DATABASE_DEFAULT NULL,Status varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,EnqueuedAtUtc datetime2(7) NOT NULL,EnqueuedBy sysname COLLATE DATABASE_DEFAULT NOT NULL,ClaimedAtUtc datetime2(7) NULL,ClaimedBy sysname COLLATE DATABASE_DEFAULT NULL,ClaimToken uniqueidentifier NULL,ClaimGeneration bigint NOT NULL,LeaseDurationSeconds int NULL,LeaseUntilUtc datetime2(7) NULL,LastHeartbeatAtUtc datetime2(7) NULL,RecoveryCount bigint NOT NULL,LastRecoveredAtUtc datetime2(7) NULL,LastRecoveredBy sysname COLLATE DATABASE_DEFAULT NULL,CompletedAtUtc datetime2(7) NULL,CompletedBy sysname COLLATE DATABASE_DEFAULT NULL,FailedAtUtc datetime2(7) NULL,FailedBy sysname COLLATE DATABASE_DEFAULT NULL,FailureCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,FailureMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,RowVersion binary(8) NOT NULL,ExecutionGroup varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Priority tinyint NOT NULL,ExecutionMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,IdempotencyKey varchar(128) COLLATE Latin1_General_100_BIN2 NULL,MaxAttempts tinyint NOT NULL,RetryBaseDelaySeconds int NOT NULL,RetryMaxDelaySeconds int NOT NULL,RetryCycleNumber bigint NOT NULL,CycleAttemptCount bigint NOT NULL,NextAttemptAtUtc datetime2(7) NULL,LastErrorCode varchar(64) COLLATE Latin1_General_100_BIN2 NULL,LastErrorMessage nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,LastRetryScheduledAtUtc datetime2(7) NULL,LastRetryScheduledBy sysname COLLATE DATABASE_DEFAULT NULL,DeadLetteredAtUtc datetime2(7) NULL,DeadLetteredBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeuedAtUtc datetime2(7) NULL,LastRequeuedBy sysname COLLATE DATABASE_DEFAULT NULL,LastRequeueReason nvarchar(1000) COLLATE DATABASE_DEFAULT NULL,BarrierEpoch bigint NOT NULL,ManagedReservationId uniqueidentifier NULL,ManagedHold bit NOT NULL,ManagedCompletionNonce uniqueidentifier NULL,CHECK (
              [FailureCode] IS NULL OR
              (LEN([FailureCode]) BETWEEN 1 AND 64
               AND [FailureCode] LIKE '[A-Za-z]%' COLLATE Latin1_General_100_BIN2
               AND [FailureCode] NOT LIKE '%[^A-Za-z0-9._-]%' COLLATE Latin1_General_100_BIN2)
          ));
INSERT #ExpectedWorkItemChecks VALUES(N'CK_WorkItem_FailureCode',OBJECT_ID(N'tempdb..#WorkItemCheck1_5'));
END;
IF (SELECT COUNT(*) FROM sys.check_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem'))<>CASE WHEN @After=0 THEN 5 ELSE 6 END
 OR EXISTS(SELECT 1 FROM #ExpectedWorkItemChecks e LEFT JOIN sys.check_constraints c ON c.parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND CONVERT(varbinary(max),c.name)=CONVERT(varbinary(max),e.ConstraintName)
 LEFT JOIN tempdb.sys.check_constraints m ON m.parent_object_id=e.MirrorObjectId
 WHERE c.object_id IS NULL OR m.object_id IS NULL OR CONVERT(varbinary(max),c.definition)<>CONVERT(varbinary(max),m.definition) OR c.is_disabled<>0 OR c.is_not_trusted<>0 OR c.is_not_for_replication<>0 OR c.is_system_named<>0 OR c.uses_database_collation<>m.uses_database_collation
 OR (c.parent_column_id=0 AND m.parent_column_id<>0) OR (c.parent_column_id<>0 AND m.parent_column_id=0)
 OR (c.parent_column_id>0 AND m.parent_column_id>0 AND NOT EXISTS(SELECT 1 FROM sys.columns pc JOIN tempdb.sys.columns mc ON mc.object_id=m.parent_object_id AND mc.column_id=m.parent_column_id WHERE pc.object_id=c.parent_object_id AND pc.column_id=c.parent_column_id AND CONVERT(varbinary(max),pc.name)=CONVERT(varbinary(max),mc.name) AND pc.system_type_id=mc.system_type_id AND pc.max_length=mc.max_length AND pc.precision=mc.precision AND pc.scale=mc.scale AND pc.is_nullable=mc.is_nullable)))
 THROW 55012,N'EXPORT_QUEUE11_WORKITEM_CHECK_SHAPES',18;
IF @After=0 BEGIN
DROP TABLE #WorkItemCheck0_0;
DROP TABLE #WorkItemCheck0_1;
DROP TABLE #WorkItemCheck0_2;
DROP TABLE #WorkItemCheck0_3;
DROP TABLE #WorkItemCheck0_4;
END;
IF @After=1 BEGIN
DROP TABLE #WorkItemCheck1_0;
DROP TABLE #WorkItemCheck1_1;
DROP TABLE #WorkItemCheck1_2;
DROP TABLE #WorkItemCheck1_3;
DROP TABLE #WorkItemCheck1_4;
DROP TABLE #WorkItemCheck1_5;
END;
DROP TABLE #ExpectedWorkItemChecks;DROP TABLE #QueueObjects;DROP TABLE #ExpectedDefinitions;DROP TABLE #ExpectedColumns;DROP TABLE #OldTables;
