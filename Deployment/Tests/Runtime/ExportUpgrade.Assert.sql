-- Rein lesend, sofort nach dem gesamten unveränderten Export und vor weiterer DML.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0
 THROW 54992,N'Der Exportupgrade hinterließ keinen neutralen Zustand.',1;
IF XACT_STATE()<>0
 THROW 54992,N'Der Exportupgrade hinterließ keinen neutralen Zustand.',1;
IF (@@OPTIONS&2)<>0
 THROW 54992,N'Der Exportupgrade hinterließ keinen neutralen Zustand.',1;
IF @@LOCK_TIMEOUT<>-1
 THROW 54992,N'Der Exportupgrade hinterließ keinen neutralen Zustand.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND SQL_VARIANT_PROPERTY(value,'BaseType')='nvarchar' AND CONVERT(nvarchar(64),value)=N'2.1.0')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version' AND SQL_VARIANT_PROPERTY(value,'BaseType')='nvarchar' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 THROW 54992,N'Die bekannten Zielversionen wurden nicht installiert.',2;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>3 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')<>1
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE ManagedReservationId IS NOT NULL OR ManagedHold<>0 OR ManagedCompletionNonce IS NOT NULL)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker)
 THROW 54992,N'Die historische Queue besitzt nicht die erwarteten neutralen Manageddefaults.',3;
CREATE TABLE #tbx_UpgradeNewColumns(TableName sysname COLLATE Latin1_General_100_BIN2,Ordinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2,TypeId int,MaxLength int,Scale int,Nullable bit);
INSERT #tbx_UpgradeNewColumns VALUES
 (N'WorkQueueManagedGate',1,N'GateId',48,1,0,0),(N'WorkQueueManagedGate',2,N'ManagedEnabled',104,1,0,0),(N'WorkQueueManagedGate',3,N'AdmissionToken',36,16,0,0),(N'WorkQueueManagedGate',4,N'PendingReservationId',36,16,0,1),
 (N'WorkerControlConfiguration',1,N'ConfigurationId',48,1,0,0),(N'WorkerControlConfiguration',2,N'MaxConcurrentExecutions',56,4,0,0),(N'WorkerControlConfiguration',3,N'HeartbeatSeconds',56,4,0,0),(N'WorkerControlConfiguration',4,N'UnreachableSeconds',56,4,0,0),(N'WorkerControlConfiguration',5,N'ConfigVersion',189,8,0,0),
 (N'WorkerRegistration',1,N'WorkerId',36,16,0,0),(N'WorkerRegistration',2,N'WorkerGeneration',127,8,0,0),(N'WorkerRegistration',3,N'WorkerToken',36,16,0,0),(N'WorkerRegistration',4,N'OwnerPrincipalId',56,4,0,0),(N'WorkerRegistration',5,N'ProviderKind',167,16,0,0),(N'WorkerRegistration',6,N'State',167,16,0,0),(N'WorkerRegistration',7,N'AdmissionPaused',104,1,0,0),(N'WorkerRegistration',8,N'Capacity',56,4,0,0),(N'WorkerRegistration',9,N'RunMode',167,16,0,0),(N'WorkerRegistration',10,N'LastHeartbeatAtUtc',42,8,7,0),(N'WorkerRegistration',11,N'HeartbeatSeconds',56,4,0,0),(N'WorkerRegistration',12,N'UnreachableSeconds',56,4,0,0),
 (N'WorkerSlotReservation',1,N'SlotReservationId',36,16,0,0),(N'WorkerSlotReservation',2,N'WorkerId',36,16,0,0),(N'WorkerSlotReservation',3,N'WorkerGeneration',127,8,0,0),(N'WorkerSlotReservation',4,N'WorkItemId',127,8,0,0),(N'WorkerSlotReservation',5,N'ClaimGeneration',127,8,0,0),(N'WorkerSlotReservation',6,N'ClaimToken',36,16,0,0),(N'WorkerSlotReservation',7,N'ExecutionId',36,16,0,0),(N'WorkerSlotReservation',8,N'State',167,24,0,0),(N'WorkerSlotReservation',9,N'IsOccupied',104,1,0,0),(N'WorkerSlotReservation',10,N'AttemptNonce',36,16,0,1),(N'WorkerSlotReservation',11,N'BoundPrincipalId',56,4,0,1),(N'WorkerSlotReservation',12,N'CreatedAtUtc',42,8,7,0),(N'WorkerSlotReservation',13,N'EndedAtUtc',42,8,7,1),
 (N'WorkerExecutionDisposition',1,N'WorkItemId',127,8,0,0),(N'WorkerExecutionDisposition',2,N'SlotReservationId',36,16,0,0),(N'WorkerExecutionDisposition',3,N'IsHeld',104,1,0,0),(N'WorkerExecutionDisposition',4,N'StopStatus',167,24,0,0),(N'WorkerExecutionDisposition',5,N'HoldVersion',189,8,0,0),
 (N'WorkerExecutionCommitWitness',1,N'SlotReservationId',36,16,0,0),(N'WorkerExecutionCommitWitness',2,N'AttemptNonce',36,16,0,0),(N'WorkerExecutionCommitWitness',3,N'ExecutionId',36,16,0,0),(N'WorkerExecutionCommitWitness',4,N'ClaimGeneration',127,8,0,0),(N'WorkerExecutionCommitWitness',5,N'RecordedAtUtc',42,8,7,0),
 (N'WorkItem',44,N'ManagedReservationId',36,16,0,1),(N'WorkItem',45,N'ManagedHold',104,1,0,0),(N'WorkItem',46,N'ManagedCompletionNonce',36,16,0,1);
IF EXISTS(SELECT 1 FROM #tbx_UpgradeNewColumns e LEFT JOIN sys.columns c ON c.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName),N'U') AND c.column_id=e.Ordinal
 WHERE c.column_id IS NULL OR c.name COLLATE Latin1_General_100_BIN2<>e.ColumnName OR c.system_type_id<>e.TypeId OR c.user_type_id<>e.TypeId
 OR c.max_length<>e.MaxLength OR c.scale<>e.Scale OR c.is_nullable<>e.Nullable OR c.is_identity<>0 OR c.is_computed<>0
 OR (e.TypeId=167 AND ISNULL(c.collation_name,N'') COLLATE Latin1_General_100_BIN2<>N'Latin1_General_100_BIN2'))
 OR EXISTS(SELECT 1 FROM #tbx_UpgradeNewColumns e WHERE e.TableName<>N'WorkItem' GROUP BY e.TableName HAVING COUNT(*)<>(SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName),N'U')))
 THROW 54992,N'Die sechs neuen Tabellen und drei Managedspalten besitzen nicht den exakten Shape.',4;
IF NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND parent_column_id=45 AND name=N'DF_WorkItem_ManagedHold' AND TRY_CONVERT(int,REPLACE(REPLACE(definition,N'(',N''),N')',N''))=0)
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=0 AND AdmissionToken IS NOT NULL AND PendingReservationId IS NULL)
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkQueueManagedGate)<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkerControlConfiguration)<>1
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1 AND MaxConcurrentExecutions=1 AND HeartbeatSeconds=15 AND UnreachableSeconds=60)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness)
 THROW 54992,N'Die erstmals installierten Gate-/Controlzustände sind nicht neutral.',5;
IF EXISTS(SELECT 1 FROM(VALUES(N'WorkItem',N'toolbelt.core.work-queue',N'2.1.0'),(N'WorkQueueScheduler',N'toolbelt.core.work-queue',N'2.1.0'),(N'WorkQueueBarrierBlocker',N'toolbelt.core.work-queue',N'2.1.0'),(N'WorkQueueManagedGate',N'toolbelt.core.work-queue',N'2.1.0'),(N'WorkerControlConfiguration',N'toolbelt.core.worker-control',N'1.0.0'),(N'WorkerRegistration',N'toolbelt.core.worker-control',N'1.0.0'),(N'WorkerSlotReservation',N'toolbelt.core.worker-control',N'1.0.0'),(N'WorkerExecutionDisposition',N'toolbelt.core.worker-control',N'1.0.0'),(N'WorkerExecutionCommitWitness',N'toolbelt.core.worker-control',N'1.0.0'))e(TableName,ModuleId,Version)
 WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName),N'U') AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(nvarchar(256),p.value)=e.ModuleId)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName),N'U') AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(nvarchar(64),p.value)=e.Version))
 THROW 54992,N'Die aktuellen Tabelleneigentums-/Versionsmarker fehlen.',6;
IF (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND name=N'Toolbelt.Test.ExportUpgrade' AND minor_id=0)<>8
 OR (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND name=N'Toolbelt.Test.ExportUpgrade' AND minor_id>0)<>8
 OR EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(TableName),N'U') FROM #tbx_UpgradeNewColumns) AND (is_disabled=1 OR is_not_trusted=1))
 THROW 54992,N'Alte Annotationen oder aktuelle vertrauenswürdige Constraints fehlen.',7;
DROP TABLE #tbx_UpgradeNewColumns;
