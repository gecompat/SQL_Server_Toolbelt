-- Neuer privater rein lesender Upgrade-Repeat-Shape, ursprüngliches Immediateorakel bleibt unverändert.
SET NOCOUNT ON;
IF @Completed IS NULL THROW 54998,N'Der begrenzte Completionzustand fehlt.',1;
IF @@TRANCOUNT<>0
 THROW 54998,N'Der Exportupgrade hinterließ keinen neutralen Zustand.',1;
IF XACT_STATE()<>0
 THROW 54998,N'Der Exportupgrade hinterließ keinen neutralen Zustand.',1;
IF (@@OPTIONS&2)<>0
 THROW 54998,N'Der Exportupgrade hinterließ keinen neutralen Zustand.',1;
IF @@LOCK_TIMEOUT<>-1
 THROW 54998,N'Der Exportupgrade hinterließ keinen neutralen Zustand.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-queue.Version' AND SQL_VARIANT_PROPERTY(value,'BaseType')='nvarchar' AND CONVERT(nvarchar(64),value)=N'2.1.0')
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.worker-control.Version' AND SQL_VARIANT_PROPERTY(value,'BaseType')='nvarchar' AND CONVERT(nvarchar(64),value)=N'1.0.0')
 THROW 54998,N'Die bekannten Zielversionen wurden nicht installiert.',2;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>3 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')<>CASE WHEN @Completed=1 THEN 0 ELSE 1 END
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE ManagedReservationId IS NOT NULL OR ManagedHold<>0 OR ManagedCompletionNonce IS NOT NULL)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueBarrierBlocker)
 THROW 54998,N'Die historische Queue besitzt nicht die erwarteten neutralen Manageddefaults.',3;
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
 THROW 54998,N'Die sechs neuen Tabellen und drei Managedspalten besitzen nicht den exakten Shape.',4;
IF NOT EXISTS(SELECT 1 FROM sys.default_constraints WHERE parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND parent_column_id=45 AND name=N'DF_WorkItem_ManagedHold' AND TRY_CONVERT(int,REPLACE(REPLACE(definition,N'(',N''),N')',N''))=0)
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkQueueManagedGate WHERE GateId=1 AND ManagedEnabled=0 AND AdmissionToken IS NOT NULL AND PendingReservationId IS NULL)
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkQueueManagedGate)<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkerControlConfiguration)<>1
 OR NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkerControlConfiguration WHERE ConfigurationId=1 AND MaxConcurrentExecutions=1 AND HeartbeatSeconds=15 AND UnreachableSeconds=60)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerRegistration) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerSlotReservation)
 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionDisposition) OR EXISTS(SELECT 1 FROM toolbelt_core.WorkerExecutionCommitWitness)
 THROW 54998,N'Die erstmals installierten Gate-/Controlzustände sind nicht neutral.',5;
IF EXISTS(SELECT 1 FROM(VALUES(N'WorkItem',N'toolbelt.core.work-queue',N'2.1.0'),(N'WorkQueueScheduler',N'toolbelt.core.work-queue',N'2.1.0'),(N'WorkQueueBarrierBlocker',N'toolbelt.core.work-queue',N'2.1.0'),(N'WorkQueueManagedGate',N'toolbelt.core.work-queue',N'2.1.0'),(N'WorkerControlConfiguration',N'toolbelt.core.worker-control',N'1.0.0'),(N'WorkerRegistration',N'toolbelt.core.worker-control',N'1.0.0'),(N'WorkerSlotReservation',N'toolbelt.core.worker-control',N'1.0.0'),(N'WorkerExecutionDisposition',N'toolbelt.core.worker-control',N'1.0.0'),(N'WorkerExecutionCommitWitness',N'toolbelt.core.worker-control',N'1.0.0'))e(TableName,ModuleId,Version)
 WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName),N'U') AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(nvarchar(256),p.value)=e.ModuleId)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(e.TableName),N'U') AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar' AND CONVERT(nvarchar(64),p.value)=e.Version))
 THROW 54998,N'Die aktuellen Tabelleneigentums-/Versionsmarker fehlen.',6;
IF (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND name=N'Toolbelt.Test.ExportUpgrade' AND minor_id=0)<>8
 OR (SELECT COUNT(*) FROM sys.extended_properties WHERE class=1 AND name=N'Toolbelt.Test.ExportUpgrade' AND minor_id>0)<>8
 OR EXISTS(SELECT 1 FROM sys.check_constraints WHERE parent_object_id IN(SELECT OBJECT_ID(N'toolbelt_core.'+QUOTENAME(TableName),N'U') FROM #tbx_UpgradeNewColumns) AND (is_disabled=1 OR is_not_trusted=1))
 THROW 54998,N'Alte Annotationen oder aktuelle vertrauenswürdige Constraints fehlen.',7;
DROP TABLE #tbx_UpgradeNewColumns;
-- Genau ein vorhandener eigener Payloadzeuge, unabhängig vom veränderlichen Status.
DECLARE @OwnWorkItemId bigint;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkItem w JOIN toolbelt_core.WorkType t ON t.WorkTypeId=w.WorkTypeId WHERE
 CONVERT(varbinary(max),t.WorkTypeName)=CONVERT(varbinary(max),'test.export.upgrade20') AND
 CONVERT(varbinary(max),w.PayloadJson)=CONVERT(varbinary(max),N'{"synthetic":"claimed – 漢字 "}'))<>1
 THROW 54998,N'Der einzelne eigene Legacyclaim ist nicht eindeutig gebunden.',2;
SELECT @OwnWorkItemId=WorkItemId FROM toolbelt_core.WorkItem w JOIN toolbelt_core.WorkType t ON t.WorkTypeId=w.WorkTypeId WHERE
 CONVERT(varbinary(max),t.WorkTypeName)=CONVERT(varbinary(max),'test.export.upgrade20') AND
 CONVERT(varbinary(max),w.PayloadJson)=CONVERT(varbinary(max),N'{"synthetic":"claimed – 漢字 "}');
IF NOT EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE WorkItemId=@OwnWorkItemId
 AND Status=CASE WHEN @Completed=1 THEN 'COMPLETED' ELSE 'CLAIMED' END)
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='COMPLETED')<>CASE WHEN @Completed=1 THEN 2 ELSE 1 END
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='QUEUED')<>1
 THROW 54998,N'Der endliche Originalqueuezustand weicht ab.',8;
-- Markerbytes sind hier streng; im anschließenden Repeat wird nichts normalisiert.
IF EXISTS(SELECT 1 FROM(VALUES(N'toolbelt.core.work-queue',N'2.1.0'),(N'toolbelt.core.worker-control',N'1.0.0'))e(ModuleId,Version)
 WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=0 AND p.major_id=0 AND p.minor_id=0
 AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),N'Toolbelt.Module.'+e.ModuleId+N'.Version')
 AND SQL_VARIANT_PROPERTY(p.value,'BaseType')='nvarchar'
 AND CONVERT(varbinary(max),CONVERT(nvarchar(64),p.value))=CONVERT(varbinary(max),e.Version)))
 THROW 54998,N'Die tatsächlichen bekannten Zielversionen sind nicht bytegenau.',9;
CREATE TABLE #NewTables(TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL PRIMARY KEY,ObjectId int NOT NULL);
INSERT #NewTables SELECT n,OBJECT_ID(N'toolbelt_core.'+QUOTENAME(n),N'U') FROM(VALUES
 (N'WorkQueueManagedGate'),(N'WorkerControlConfiguration'),(N'WorkerRegistration'),
 (N'WorkerSlotReservation'),(N'WorkerExecutionDisposition'),(N'WorkerExecutionCommitWitness'))v(n);
CREATE TABLE #ExpectedKeyColumns(TableName sysname COLLATE Latin1_General_100_BIN2,ConstraintName sysname COLLATE Latin1_General_100_BIN2,KeyType varchar(2) COLLATE Latin1_General_100_BIN2,IndexType tinyint,KeyOrdinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2);
INSERT #ExpectedKeyColumns VALUES
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
 OR (SELECT COUNT(*) FROM sys.key_constraints k JOIN #NewTables n ON n.ObjectId=k.parent_object_id)<>8
 OR (SELECT COUNT(*) FROM sys.indexes i JOIN #NewTables n ON n.ObjectId=i.object_id)<>8
 OR (SELECT COUNT(*) FROM sys.index_columns c JOIN #NewTables n ON n.ObjectId=c.object_id)<>10
 OR EXISTS(SELECT 1 FROM sys.indexes i JOIN #NewTables n ON n.ObjectId=i.object_id
 WHERE i.is_unique<>1 OR i.is_disabled<>0 OR i.is_hypothetical<>0 OR i.has_filter<>0 OR i.filter_definition IS NOT NULL
 OR i.ignore_dup_key<>0 OR (i.is_primary_key=0 AND i.is_unique_constraint=0))
 OR EXISTS(SELECT 1 FROM sys.key_constraints k JOIN #NewTables n ON n.ObjectId=k.parent_object_id
 JOIN sys.indexes i ON i.object_id=k.parent_object_id AND i.index_id=k.unique_index_id
 WHERE CONVERT(varbinary(max),k.name)<>CONVERT(varbinary(max),i.name) OR k.is_system_named<>0
 OR (k.type='PK' AND (i.is_primary_key<>1 OR i.is_unique_constraint<>0))
 OR (k.type='UQ' AND (i.is_primary_key<>0 OR i.is_unique_constraint<>1)))
 OR EXISTS(SELECT 1 FROM sys.index_columns c JOIN #NewTables n ON n.ObjectId=c.object_id WHERE c.is_descending_key<>0 OR c.is_included_column<>0 OR c.partition_ordinal<>0)
 THROW 54998,N'Die sechs neuen PKs, zwei UQs oder ihre acht Indizes besitzen nicht das sourcegebundene Sollinventar.',10;
CREATE TABLE #ExpectedFkColumns(TableName sysname COLLATE Latin1_General_100_BIN2,ConstraintName sysname COLLATE Latin1_General_100_BIN2,ColumnOrdinal int,ColumnName sysname COLLATE Latin1_General_100_BIN2,ReferencedSchema sysname COLLATE Latin1_General_100_BIN2,ReferencedTable sysname COLLATE Latin1_General_100_BIN2,ReferencedColumn sysname COLLATE Latin1_General_100_BIN2);
INSERT #ExpectedFkColumns VALUES
 (N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkerRegistration',1,N'WorkerId',N'toolbelt_core',N'WorkerRegistration',N'WorkerId'),
 (N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkerRegistration',2,N'WorkerGeneration',N'toolbelt_core',N'WorkerRegistration',N'WorkerGeneration'),
 (N'WorkerSlotReservation',N'FK_WorkerSlotReservation_WorkItem',1,N'WorkItemId',N'toolbelt_core',N'WorkItem',N'WorkItemId'),
 (N'WorkerExecutionDisposition',N'FK_WorkerExecutionDisposition_WorkItem',1,N'WorkItemId',N'toolbelt_core',N'WorkItem',N'WorkItemId'),
 (N'WorkerExecutionDisposition',N'FK_WorkerExecutionDisposition_Reservation',1,N'SlotReservationId',N'toolbelt_core',N'WorkerSlotReservation',N'SlotReservationId'),
 (N'WorkerExecutionCommitWitness',N'FK_WorkerExecutionCommitWitness_Reservation',1,N'SlotReservationId',N'toolbelt_core',N'WorkerSlotReservation',N'SlotReservationId');
IF EXISTS(SELECT CONVERT(varbinary(max),TableName),CONVERT(varbinary(max),ConstraintName),ColumnOrdinal,CONVERT(varbinary(max),ColumnName),CONVERT(varbinary(max),ReferencedSchema),CONVERT(varbinary(max),ReferencedTable),CONVERT(varbinary(max),ReferencedColumn) FROM #ExpectedFkColumns EXCEPT SELECT CONVERT(varbinary(max),n.TableName) TableName,CONVERT(varbinary(max),f.name) ConstraintName,fc.constraint_column_id ColumnOrdinal,CONVERT(varbinary(max),pc.name) ColumnName,CONVERT(varbinary(max),rs.name) ReferencedSchema,CONVERT(varbinary(max),rt.name) ReferencedTable,CONVERT(varbinary(max),rc.name) ReferencedColumn FROM #NewTables n JOIN sys.foreign_keys f ON f.parent_object_id=n.ObjectId JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id JOIN sys.tables rt ON rt.object_id=fc.referenced_object_id JOIN sys.schemas rs ON rs.schema_id=rt.schema_id JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id)
 OR EXISTS(SELECT CONVERT(varbinary(max),n.TableName) TableName,CONVERT(varbinary(max),f.name) ConstraintName,fc.constraint_column_id ColumnOrdinal,CONVERT(varbinary(max),pc.name) ColumnName,CONVERT(varbinary(max),rs.name) ReferencedSchema,CONVERT(varbinary(max),rt.name) ReferencedTable,CONVERT(varbinary(max),rc.name) ReferencedColumn FROM #NewTables n JOIN sys.foreign_keys f ON f.parent_object_id=n.ObjectId JOIN sys.foreign_key_columns fc ON fc.constraint_object_id=f.object_id JOIN sys.columns pc ON pc.object_id=fc.parent_object_id AND pc.column_id=fc.parent_column_id JOIN sys.tables rt ON rt.object_id=fc.referenced_object_id JOIN sys.schemas rs ON rs.schema_id=rt.schema_id JOIN sys.columns rc ON rc.object_id=fc.referenced_object_id AND rc.column_id=fc.referenced_column_id EXCEPT SELECT CONVERT(varbinary(max),TableName),CONVERT(varbinary(max),ConstraintName),ColumnOrdinal,CONVERT(varbinary(max),ColumnName),CONVERT(varbinary(max),ReferencedSchema),CONVERT(varbinary(max),ReferencedTable),CONVERT(varbinary(max),ReferencedColumn) FROM #ExpectedFkColumns)
 OR (SELECT COUNT(*) FROM sys.foreign_keys f JOIN #NewTables n ON n.ObjectId=f.parent_object_id)<>5
 OR (SELECT COUNT(*) FROM sys.foreign_key_columns f JOIN #NewTables n ON n.ObjectId=f.parent_object_id)<>6
 OR EXISTS(SELECT 1 FROM sys.foreign_keys f JOIN #NewTables n ON n.ObjectId=f.parent_object_id
 WHERE f.is_disabled<>0 OR f.is_not_trusted<>0 OR f.is_not_for_replication<>0 OR f.delete_referential_action<>0 OR f.update_referential_action<>0 OR f.is_system_named<>0
 OR NOT EXISTS(SELECT 1 FROM sys.key_constraints k WHERE k.parent_object_id=f.referenced_object_id AND k.type='PK' AND k.unique_index_id=f.key_index_id))
 THROW 54998,N'Die fünf neuen vertrauenswürdigen FKs besitzen nicht die sechs sourcegebundenen Spaltenbindungen.',11;
-- Neun Compiler-kanonische positive CHECK-Ausdrücke: anonyme lokale Tempconstraints.
-- Sourceausdrücke unverändert; keine Zeichen-/Klammernormalisierung, keine global benannten Temp-PKs.
CREATE TABLE #ExpectedChecks(TableName sysname COLLATE Latin1_General_100_BIN2,ConstraintName sysname COLLATE Latin1_General_100_BIN2,MirrorObjectId int NOT NULL);
CREATE TABLE #CheckMirror0(GateId tinyint NOT NULL,CHECK(GateId=1));
INSERT #ExpectedChecks VALUES(N'WorkQueueManagedGate',N'CK_WorkQueueManagedGate_Id',OBJECT_ID(N'tempdb..#CheckMirror0'));
CREATE TABLE #CheckMirror1(ConfigurationId tinyint NOT NULL,CHECK(ConfigurationId=1));
INSERT #ExpectedChecks VALUES(N'WorkerControlConfiguration',N'CK_WorkerControlConfiguration_Id',OBJECT_ID(N'tempdb..#CheckMirror1'));
CREATE TABLE #CheckMirror2(MaxConcurrentExecutions int NOT NULL,HeartbeatSeconds int NOT NULL,UnreachableSeconds int NOT NULL,CHECK(MaxConcurrentExecutions>=0 AND HeartbeatSeconds BETWEEN 1 AND 3600 AND UnreachableSeconds BETWEEN 3 AND 86400 AND UnreachableSeconds>=3*HeartbeatSeconds));
INSERT #ExpectedChecks VALUES(N'WorkerControlConfiguration',N'CK_WorkerControlConfiguration_Limits',OBJECT_ID(N'tempdb..#CheckMirror2'));
CREATE TABLE #CheckMirror3(WorkerGeneration bigint NOT NULL,CHECK(WorkerGeneration>0));
INSERT #ExpectedChecks VALUES(N'WorkerRegistration',N'CK_WorkerRegistration_Generation',OBJECT_ID(N'tempdb..#CheckMirror3'));
CREATE TABLE #CheckMirror4(State varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,CHECK(State IN('ACTIVE','PAUSED','DRAINING','UNREACHABLE','CLOSED')));
INSERT #ExpectedChecks VALUES(N'WorkerRegistration',N'CK_WorkerRegistration_State',OBJECT_ID(N'tempdb..#CheckMirror4'));
CREATE TABLE #CheckMirror5(Capacity int NOT NULL,CHECK(Capacity>0));
INSERT #ExpectedChecks VALUES(N'WorkerRegistration',N'CK_WorkerRegistration_Capacity',OBJECT_ID(N'tempdb..#CheckMirror5'));
CREATE TABLE #CheckMirror6(RunMode varchar(16) COLLATE Latin1_General_100_BIN2 NOT NULL,CHECK(RunMode IN('BOUNDED','CONTINUOUS')));
INSERT #ExpectedChecks VALUES(N'WorkerRegistration',N'CK_WorkerRegistration_RunMode',OBJECT_ID(N'tempdb..#CheckMirror6'));
CREATE TABLE #CheckMirror7(State varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,CHECK(State IN('RESERVED','RUNNING','STOP_REQUESTED','STOPPING','UNKNOWN','COMMITTED','ROLLED_BACK','CLOSED')));
INSERT #ExpectedChecks VALUES(N'WorkerSlotReservation',N'CK_WorkerSlotReservation_State',OBJECT_ID(N'tempdb..#CheckMirror7'));
CREATE TABLE #CheckMirror8(StopStatus varchar(24) COLLATE Latin1_General_100_BIN2 NOT NULL,CHECK(StopStatus IN('NONE','REQUESTED','STOPPING','ROLLED_BACK_HELD','ALREADY_COMMITTED','UNKNOWN')));
INSERT #ExpectedChecks VALUES(N'WorkerExecutionDisposition',N'CK_WorkerExecutionDisposition_Stop',OBJECT_ID(N'tempdb..#CheckMirror8'));
IF (SELECT COUNT(*) FROM sys.check_constraints c JOIN #NewTables n ON n.ObjectId=c.parent_object_id)<>9
 OR (SELECT COUNT(*) FROM tempdb.sys.check_constraints c JOIN #ExpectedChecks e ON e.MirrorObjectId=c.parent_object_id)<>9
 OR EXISTS(SELECT 1 FROM #ExpectedChecks e JOIN #NewTables n ON n.TableName=e.TableName
 LEFT JOIN sys.check_constraints c ON c.parent_object_id=n.ObjectId AND CONVERT(varbinary(max),c.name)=CONVERT(varbinary(max),e.ConstraintName)
 LEFT JOIN tempdb.sys.check_constraints m ON m.parent_object_id=e.MirrorObjectId
 WHERE c.object_id IS NULL OR m.object_id IS NULL OR CONVERT(varbinary(max),c.definition)<>CONVERT(varbinary(max),m.definition)
 OR c.is_disabled<>0 OR c.is_not_trusted<>0 OR c.is_not_for_replication<>0 OR c.is_system_named<>0 OR c.parent_column_id<>0
 OR c.uses_database_collation<>m.uses_database_collation)
BEGIN
 -- Nur im bereits fehlgeschlagenen CHECK-Zweig: feste Komponente plus Sourceordinal, keine Katalogwerte.
 IF (SELECT COUNT(*) FROM sys.check_constraints c JOIN #NewTables n ON n.ObjectId=c.parent_object_id)<>9
  THROW 54998,N'EXPORT_UPGRADE_REPEAT_CHECK_PRODUCTION_COUNT',14;
 IF (SELECT COUNT(*) FROM tempdb.sys.check_constraints c JOIN #ExpectedChecks e ON e.MirrorObjectId=c.parent_object_id)<>9
  THROW 54998,N'EXPORT_UPGRADE_REPEAT_CHECK_MIRROR_COUNT',15;
 DECLARE @DiagnosticCheckState int;
 SELECT TOP(1) @DiagnosticCheckState=p.ComponentBase+v.CheckIndex
 FROM(VALUES
  (0,N'WorkQueueManagedGate',N'CK_WorkQueueManagedGate_Id'),
  (1,N'WorkerControlConfiguration',N'CK_WorkerControlConfiguration_Id'),
  (2,N'WorkerControlConfiguration',N'CK_WorkerControlConfiguration_Limits'),
  (3,N'WorkerRegistration',N'CK_WorkerRegistration_Generation'),
  (4,N'WorkerRegistration',N'CK_WorkerRegistration_State'),
  (5,N'WorkerRegistration',N'CK_WorkerRegistration_Capacity'),
  (6,N'WorkerRegistration',N'CK_WorkerRegistration_RunMode'),
  (7,N'WorkerSlotReservation',N'CK_WorkerSlotReservation_State'),
  (8,N'WorkerExecutionDisposition',N'CK_WorkerExecutionDisposition_Stop')
 )v(CheckIndex,TableName,ConstraintName)
 JOIN #ExpectedChecks e ON CONVERT(varbinary(max),e.TableName)=CONVERT(varbinary(max),v.TableName)
  AND CONVERT(varbinary(max),e.ConstraintName)=CONVERT(varbinary(max),v.ConstraintName)
 JOIN #NewTables n ON n.TableName=e.TableName
 LEFT JOIN sys.check_constraints c ON c.parent_object_id=n.ObjectId AND CONVERT(varbinary(max),c.name)=CONVERT(varbinary(max),e.ConstraintName)
 LEFT JOIN tempdb.sys.check_constraints m ON m.parent_object_id=e.MirrorObjectId
 CROSS APPLY(VALUES
  (20,CASE WHEN c.object_id IS NULL THEN 1 ELSE 0 END),
  (30,CASE WHEN m.object_id IS NULL THEN 1 ELSE 0 END),
  (40,CASE WHEN CONVERT(varbinary(max),c.definition)<>CONVERT(varbinary(max),m.definition) THEN 1 ELSE 0 END),
  (50,CASE WHEN c.is_disabled<>0 THEN 1 ELSE 0 END),
  (60,CASE WHEN c.is_not_trusted<>0 THEN 1 ELSE 0 END),
  (70,CASE WHEN c.is_not_for_replication<>0 THEN 1 ELSE 0 END),
  (80,CASE WHEN c.is_system_named<>0 THEN 1 ELSE 0 END),
  (90,CASE WHEN c.parent_column_id<>0 THEN 1 ELSE 0 END),
  (100,CASE WHEN c.uses_database_collation<>m.uses_database_collation THEN 1 ELSE 0 END)
 )p(ComponentBase,Failed)
 WHERE p.Failed=1
 ORDER BY p.ComponentBase,v.CheckIndex;
 IF @DiagnosticCheckState IS NOT NULL
  THROW 54998,N'EXPORT_UPGRADE_REPEAT_CHECK_COMPONENT_INDEX',@DiagnosticCheckState;
 THROW 54998,N'Die neun neuen CHECKs besitzen nicht die aktiven vertrauenswürdigen sourcegebundenen Ausdrücke.',12;
END;
IF EXISTS(SELECT 1 FROM sys.columns c JOIN #NewTables n ON n.ObjectId=c.object_id WHERE c.is_identity<>0 OR c.default_object_id<>0)
 OR EXISTS(SELECT 1 FROM sys.default_constraints c JOIN #NewTables n ON n.ObjectId=c.parent_object_id)
 OR EXISTS(SELECT 1 FROM sys.triggers t JOIN #NewTables n ON n.ObjectId=t.parent_id)
 THROW 54998,N'Die neuen Tabellen besitzen unbekannte Identity-, Default- oder Triggerformen.',13;
DROP TABLE #CheckMirror0;
DROP TABLE #CheckMirror1;
DROP TABLE #CheckMirror2;
DROP TABLE #CheckMirror3;
DROP TABLE #CheckMirror4;
DROP TABLE #CheckMirror5;
DROP TABLE #CheckMirror6;
DROP TABLE #CheckMirror7;
DROP TABLE #CheckMirror8;
DROP TABLE #ExpectedChecks;DROP TABLE #ExpectedFkColumns;DROP TABLE #ExpectedKeyColumns;DROP TABLE #NewTables;
