-- Private synthetische Genuine1.1-Upgradefixture; keine Produktobjekte oder Cleanup.
SET NOCOUNT ON;
IF @After IS NULL THROW 55011,N'EXPORT_QUEUE11_PHASE',1;
IF @InstallMode IS NULL OR CONVERT(varbinary(max),@InstallMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')) THROW 55011,N'EXPORT_QUEUE11_MODE',1;
IF @@TRANCOUNT<>0 THROW 55011,N'EXPORT_QUEUE11_SESSION',1;
IF XACT_STATE()<>0 THROW 55011,N'EXPORT_QUEUE11_SESSION',1;
IF (@@OPTIONS&2)<>0 THROW 55011,N'EXPORT_QUEUE11_SESSION',1;
IF @@LOCK_TIMEOUT<>-1 THROW 55011,N'EXPORT_QUEUE11_SESSION',1;
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
 THROW 55011,N'EXPORT_QUEUE11_OLD_SHAPE',2;
IF (SELECT STRING_AGG(CONVERT(nvarchar(max),c.name),N',') WITHIN GROUP(ORDER BY c.column_id) FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND c.column_id<=23) COLLATE Latin1_General_100_BIN2<>N'WorkItemId,WorkTypeId,PayloadJson,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,ClaimToken,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion' COLLATE Latin1_General_100_BIN2
 THROW 55011,N'EXPORT_QUEUE11_OLD_NAMES',3;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkType)<>2 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>3
 OR (SELECT COUNT(*) FROM toolbelt_core.ExecutionCancellation)<>3 OR (SELECT COUNT(*) FROM toolbelt_core.SecondSessionProvider)<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.EventLog)<>3 OR (SELECT COUNT(*) FROM toolbelt_file.FileContentRootAllowlist)<>4
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='COMPLETED')<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='FAILED')<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem WHERE Status='QUEUED')<>1 OR EXISTS(SELECT 1 FROM toolbelt_core.WorkItem WHERE Status='CLAIMED')
 THROW 55011,N'EXPORT_QUEUE11_OLD_COUNTS',4;
CREATE TABLE #OldObjects(ObjectId int NOT NULL PRIMARY KEY,IsQueue bit NOT NULL,LegacyViewColumns int NULL);
INSERT #OldObjects SELECT DISTINCT o.object_id,CONVERT(bit,CASE WHEN EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),CONVERT(nvarchar(256),p.value))=CONVERT(varbinary(max),N'toolbelt.core.work-queue')) THEN 1 ELSE 0 END),CASE WHEN o.name=N'VW_WorkQueue' THEN 22 ELSE NULL END
FROM sys.objects o WHERE o.is_ms_shipped=0 AND o.parent_object_id=0 AND (o.object_id IN(SELECT ObjectId FROM #OldTables) OR EXISTS(SELECT 1 FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=o.object_id AND p.minor_id=0 AND p.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),p.value) IN(N'toolbelt.core.execution-context',N'toolbelt.core.result-table',N'toolbelt.file.content',N'toolbelt.core.execution-cancel',N'toolbelt.core.work-type',N'toolbelt.core.second-session',N'toolbelt.core.event-log')) OR o.name IN(N'VW_WorkQueue',N'USP_EnqueueWork',N'USP_ClaimWork',N'USP_RenewWorkLease',N'USP_RecoverExpiredWork',N'USP_CompleteWork',N'USP_FailWork',N'USP_GetWorkStatus') AND o.schema_id=SCHEMA_ID(N'toolbelt_core'));
CREATE TABLE #Snapshot(Category varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Payload varbinary(max) NOT NULL);
DECLARE @Id int,@Schema sysname,@Table sysname,@Fields int,@Category varchar(128),@Projection nvarchar(max),@Sql nvarchar(max),@Query nvarchar(max);
CREATE TABLE #RowTables(SchemaName sysname COLLATE Latin1_General_100_BIN2,TableName sysname COLLATE Latin1_General_100_BIN2,LegacyColumns int,ObjectId int NULL);
INSERT #RowTables SELECT SchemaName,TableName,LegacyColumns,ObjectId FROM #OldTables;
IF @After=1 INSERT #RowTables VALUES
(N'toolbelt_core',N'WorkQueueBarrierBlocker',5,OBJECT_ID(N'toolbelt_core.WorkQueueBarrierBlocker',N'U')),
(N'toolbelt_core',N'WorkQueueManagedGate',4,OBJECT_ID(N'toolbelt_core.WorkQueueManagedGate',N'U')),
(N'toolbelt_core',N'WorkQueueScheduler',1,OBJECT_ID(N'toolbelt_core.WorkQueueScheduler',N'U')),
(N'toolbelt_core',N'WorkerControlConfiguration',5,OBJECT_ID(N'toolbelt_core.WorkerControlConfiguration',N'U')),
(N'toolbelt_core',N'WorkerExecutionCommitWitness',5,OBJECT_ID(N'toolbelt_core.WorkerExecutionCommitWitness',N'U')),
(N'toolbelt_core',N'WorkerExecutionDisposition',5,OBJECT_ID(N'toolbelt_core.WorkerExecutionDisposition',N'U')),
(N'toolbelt_core',N'WorkerRegistration',12,OBJECT_ID(N'toolbelt_core.WorkerRegistration',N'U')),
(N'toolbelt_core',N'WorkerSlotReservation',13,OBJECT_ID(N'toolbelt_core.WorkerSlotReservation',N'U'));
IF EXISTS(SELECT 1 FROM #RowTables WHERE ObjectId IS NULL) OR (SELECT COUNT(*) FROM #RowTables)<>CASE WHEN @After=0 THEN 6 ELSE 14 END THROW 55011,N'EXPORT_QUEUE11_ROW_INVENTORY',5;
DECLARE row_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectId,SchemaName,TableName,LegacyColumns FROM #RowTables ORDER BY SchemaName,TableName;
OPEN row_cursor;FETCH NEXT FROM row_cursor INTO @Id,@Schema,@Table,@Fields;
WHILE @@FETCH_STATUS=0 BEGIN
 SELECT @Projection=STRING_AGG(CONVERT(nvarchar(max),N'CONVERT(varbinary(max),r.'+QUOTENAME(c.name)+N') AS '+QUOTENAME(c.name)),N',') WITHIN GROUP(ORDER BY c.column_id)
 FROM sys.columns c WHERE c.object_id=@Id AND c.column_id<=@Fields AND NOT(@Table=N'WorkItem' AND c.column_id=23);
 SET @Category=CONVERT(varchar(128),N'row:'+@Schema+N'.'+@Table);
 SET @Sql=N'INSERT #Snapshot SELECT @Category,CONVERT(varbinary(max),(SELECT COUNT_BIG(*) CountWitness FROM '+QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table)+N' FOR XML PATH(''count'')));
 INSERT #Snapshot SELECT @Category,CONVERT(varbinary(max),(SELECT '+@Projection+N' FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM '+QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table)+N' r;';
 EXEC sys.sp_executesql @Sql,N'@Category varchar(128)',@Category=@Category;
 FETCH NEXT FROM row_cursor INTO @Id,@Schema,@Table,@Fields;
END;
CLOSE row_cursor;DEALLOCATE row_cursor;
-- Der Caller vergleicht dieselben drei Keys, binary(8), und verlangt für jede Zeile einen Wechsel.
INSERT #Snapshot SELECT CONVERT(varchar(128),'rv:toolbelt_core.WorkItem:'+CONVERT(varchar(20),WorkItemId)),CONVERT(varbinary(max),CONVERT(binary(8),RowVersion)) FROM toolbelt_core.WorkItem;
INSERT #Snapshot SELECT 'catalog:rowversion-count',CONVERT(varbinary(max),(SELECT COUNT_BIG(*) CountWitness FROM toolbelt_core.WorkItem FOR XML PATH('count')));
-- Alle 23 neuen WorkItem-Werte zusätzlich privat erfassen; keine alte Zeile wird ersetzt.
IF @After=1 EXEC sys.sp_executesql N'INSERT #Snapshot SELECT ''target:toolbelt_core.WorkItem'',CONVERT(varbinary(max),(SELECT COUNT_BIG(*) CountWitness FROM toolbelt_core.WorkItem FOR XML PATH(''count'')));
INSERT #Snapshot SELECT ''target:toolbelt_core.WorkItem'',CONVERT(varbinary(max),(SELECT CONVERT(varbinary(max),w.[WorkItemId]) AS [WorkItemId],CONVERT(varbinary(max),w.[ExecutionGroup]) AS [ExecutionGroup],CONVERT(varbinary(max),w.[Priority]) AS [Priority],CONVERT(varbinary(max),w.[ExecutionMode]) AS [ExecutionMode],CONVERT(varbinary(max),w.[IdempotencyKey]) AS [IdempotencyKey],CONVERT(varbinary(max),w.[MaxAttempts]) AS [MaxAttempts],CONVERT(varbinary(max),w.[RetryBaseDelaySeconds]) AS [RetryBaseDelaySeconds],CONVERT(varbinary(max),w.[RetryMaxDelaySeconds]) AS [RetryMaxDelaySeconds],CONVERT(varbinary(max),w.[RetryCycleNumber]) AS [RetryCycleNumber],CONVERT(varbinary(max),w.[CycleAttemptCount]) AS [CycleAttemptCount],CONVERT(varbinary(max),w.[NextAttemptAtUtc]) AS [NextAttemptAtUtc],CONVERT(varbinary(max),w.[LastErrorCode]) AS [LastErrorCode],CONVERT(varbinary(max),w.[LastErrorMessage]) AS [LastErrorMessage],CONVERT(varbinary(max),w.[LastRetryScheduledAtUtc]) AS [LastRetryScheduledAtUtc],CONVERT(varbinary(max),w.[LastRetryScheduledBy]) AS [LastRetryScheduledBy],CONVERT(varbinary(max),w.[DeadLetteredAtUtc]) AS [DeadLetteredAtUtc],CONVERT(varbinary(max),w.[DeadLetteredBy]) AS [DeadLetteredBy],CONVERT(varbinary(max),w.[LastRequeuedAtUtc]) AS [LastRequeuedAtUtc],CONVERT(varbinary(max),w.[LastRequeuedBy]) AS [LastRequeuedBy],CONVERT(varbinary(max),w.[LastRequeueReason]) AS [LastRequeueReason],CONVERT(varbinary(max),w.[BarrierEpoch]) AS [BarrierEpoch],CONVERT(varbinary(max),w.[ManagedReservationId]) AS [ManagedReservationId],CONVERT(varbinary(max),w.[ManagedHold]) AS [ManagedHold],CONVERT(varbinary(max),w.[ManagedCompletionNonce]) AS [ManagedCompletionNonce] FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM toolbelt_core.WorkItem w;';
DECLARE catalog_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Category,Query FROM(VALUES
('catalog:schemas',N'SELECT schema_id,name,principal_id FROM sys.schemas WHERE schema_id IN(SCHEMA_ID(N''toolbelt_core''),SCHEMA_ID(N''toolbelt_file''))'),
('catalog:tables',N'SELECT o.object_id,o.name,o.schema_id,o.type,o.principal_id,t.uses_ansi_nulls,t.is_replicated,t.is_memory_optimized,t.durability,t.temporal_type FROM sys.objects o JOIN sys.tables t ON t.object_id=o.object_id JOIN #OldTables x ON x.ObjectId=o.object_id'),
('catalog:objects',N'SELECT o.object_id,o.name,o.schema_id,o.type,o.principal_id,o.create_date,o.is_ms_shipped FROM sys.objects o JOIN #OldObjects x ON x.ObjectId=o.object_id'),
('catalog:columns',N'SELECT c.* FROM sys.columns c JOIN #OldTables x ON x.ObjectId=c.object_id WHERE c.column_id<=x.LegacyColumns'),
('catalog:view-columns',N'SELECT c.* FROM sys.columns c JOIN #OldObjects x ON x.ObjectId=c.object_id WHERE x.LegacyViewColumns IS NOT NULL AND c.column_id<=x.LegacyViewColumns'),
('catalog:identity',N'SELECT c.object_id,c.name,c.column_id,c.system_type_id,CONVERT(decimal(38,0),c.seed_value) seed_value,CONVERT(decimal(38,0),c.increment_value) increment_value,CONVERT(decimal(38,0),c.last_value) last_value,c.is_not_for_replication FROM sys.identity_columns c JOIN #OldTables x ON x.ObjectId=c.object_id'),
('catalog:indexes',N'SELECT i.* FROM sys.indexes i JOIN #OldTables x ON x.ObjectId=i.object_id WHERE NOT(x.TableName=N''WorkItem'' AND i.name IN(N''IX_WorkItem_Scheduling'',N''UX_WorkItem_WorkType_IdempotencyKey''))'),
('catalog:index-columns',N'SELECT c.* FROM sys.index_columns c JOIN #OldTables x ON x.ObjectId=c.object_id JOIN sys.indexes i ON i.object_id=c.object_id AND i.index_id=c.index_id WHERE NOT(x.TableName=N''WorkItem'' AND i.name IN(N''IX_WorkItem_Scheduling'',N''UX_WorkItem_WorkType_IdempotencyKey''))'),
('catalog:defaults',N'SELECT d.object_id,d.name,d.parent_object_id,d.parent_column_id,d.definition,d.is_system_named FROM sys.default_constraints d JOIN #OldTables x ON x.ObjectId=d.parent_object_id WHERE d.parent_column_id<=x.LegacyColumns'),
('catalog:checks',N'SELECT CASE WHEN c.parent_object_id=OBJECT_ID(N''toolbelt_core.WorkItem'') AND c.name IN(N''CK_WorkItem_RecoveryMetadata'',N''CK_WorkItem_StateMetadata'',N''CK_WorkItem_Status'') THEN NULL ELSE c.object_id END StableCheckId,c.name,c.parent_object_id,CASE WHEN c.parent_object_id=OBJECT_ID(N''toolbelt_core.WorkItem'') AND c.name IN(N''CK_WorkItem_RecoveryMetadata'',N''CK_WorkItem_StateMetadata'',N''CK_WorkItem_Status'') THEN NULL ELSE c.parent_column_id END StableParentColumnId,CASE WHEN c.parent_object_id=OBJECT_ID(N''toolbelt_core.WorkItem'') AND c.name IN(N''CK_WorkItem_RecoveryMetadata'',N''CK_WorkItem_StateMetadata'',N''CK_WorkItem_Status'') THEN N''SOURCE_VERIFIED_RELEASE_CHECK'' ELSE c.definition END DefinitionBytes,c.is_disabled,c.is_not_trusted,c.is_not_for_replication,c.uses_database_collation,c.is_system_named FROM sys.check_constraints c JOIN #OldTables x ON x.ObjectId=c.parent_object_id WHERE NOT(x.TableName=N''WorkItem'' AND c.name=N''CK_WorkItem_W6cPolicy'')'),
('catalog:keys',N'SELECT k.object_id,k.name,k.parent_object_id,k.type,k.unique_index_id,k.is_system_named FROM sys.key_constraints k JOIN #OldTables x ON x.ObjectId=k.parent_object_id'),
('catalog:foreign-keys',N'SELECT f.* FROM sys.foreign_keys f JOIN #OldTables x ON x.ObjectId=f.parent_object_id'),
('catalog:foreign-key-columns',N'SELECT f.* FROM sys.foreign_key_columns f JOIN #OldTables x ON x.ObjectId=f.parent_object_id'),
('catalog:modules',N'SELECT m.object_id,CASE WHEN x.IsQueue=1 THEN N''SOURCE_VERIFIED_RELEASE_DEFINITION'' ELSE m.definition END definition,m.uses_ansi_nulls,m.uses_quoted_identifier,m.is_schema_bound,m.uses_database_collation,m.is_recompiled,m.null_on_null_input,m.execute_as_principal_id,m.uses_native_compilation FROM sys.sql_modules m JOIN #OldObjects x ON x.ObjectId=m.object_id'),
('catalog:parameters',N'SELECT p.* FROM sys.parameters p JOIN #OldObjects x ON x.ObjectId=p.object_id WHERE x.IsQueue=0'),
('catalog:properties',N'SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''BaseType'')) BaseType,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''MaxLength'')) MaxLength,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Precision'')) PrecisionValue,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Scale'')) ScaleValue,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''Collation'')) CollationValue,CASE WHEN (p.class=0 AND p.name=N''Toolbelt.Module.toolbelt.core.work-queue.Version'') OR (p.class=1 AND p.minor_id=0 AND p.name=N''Toolbelt.ModuleVersion'' AND p.major_id IN(SELECT ObjectId FROM #OldObjects WHERE IsQueue=1)) THEN CONVERT(varbinary(max),N''SOURCE_VERIFIED_QUEUE_VERSION'') WHEN p.class=1 AND p.minor_id=0 AND p.name=N''Toolbelt.SourceHash'' AND p.major_id IN(SELECT x.ObjectId FROM #OldObjects x JOIN sys.sql_modules m ON m.object_id=x.ObjectId WHERE x.IsQueue=1) THEN CONVERT(varbinary(max),N''SOURCE_VERIFIED_QUEUE_HASH'') ELSE CONVERT(varbinary(max),p.value) END ValueBytes FROM sys.extended_properties p WHERE (p.class IN(1,2) AND p.major_id IN(SELECT ObjectId FROM #OldObjects) AND (p.class=2 OR p.minor_id=0 OR p.minor_id<=COALESCE((SELECT LegacyColumns FROM #OldTables WHERE ObjectId=p.major_id),(SELECT LegacyViewColumns FROM #OldObjects WHERE ObjectId=p.major_id),2147483647))) OR (p.class=3 AND p.major_id IN(SCHEMA_ID(N''toolbelt_core''),SCHEMA_ID(N''toolbelt_file''))) OR (p.class=0 AND p.name LIKE N''Toolbelt.Module.%'' AND p.name NOT LIKE N''Toolbelt.Module.toolbelt.core.worker-control.%'')'),
('catalog:permissions',N'SELECT p.* FROM sys.database_permissions p WHERE p.class=0 OR (p.class=3 AND p.major_id IN(SCHEMA_ID(N''toolbelt_core''),SCHEMA_ID(N''toolbelt_file''))) OR (p.class=1 AND p.major_id IN(SELECT ObjectId FROM #OldObjects))')
)v(Category,Query);
OPEN catalog_cursor;FETCH NEXT FROM catalog_cursor INTO @Category,@Query;
WHILE @@FETCH_STATUS=0 BEGIN
 -- Auch leere Permissions-/Katalogmengen besitzen einen ausdrücklichen CountWitness.
 SET @Sql=N'INSERT #Snapshot SELECT @Category,CONVERT(varbinary(max),(SELECT COUNT_BIG(*) CountWitness FROM ('+@Query+N')r FOR XML PATH(''count'')));
 INSERT #Snapshot SELECT @Category,CONVERT(varbinary(max),(SELECT r.* FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM ('+@Query+N')r;';
 EXEC sys.sp_executesql @Sql,N'@Category varchar(128)',@Category=@Category;
 FETCH NEXT FROM catalog_cursor INTO @Category,@Query;
END;
CLOSE catalog_cursor;DEALLOCATE catalog_cursor;
SELECT Category,Payload FROM #Snapshot;
DROP TABLE #RowTables;DROP TABLE #Snapshot;DROP TABLE #OldObjects;DROP TABLE #OldTables;
