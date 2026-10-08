-- Acht alte Tabellen; alle 109 Legacyfelder bleiben im privaten Adaptermemory.
-- @After erlaubt ausschließlich die drei bekannten neuen WorkItem-Spalten.
SET NOCOUNT ON;
IF @After IS NULL
 THROW 54991,N'Legacycapture verlangt einen eindeutigen neutralen Zustand.',1;
IF @@TRANCOUNT<>0
 THROW 54991,N'Legacycapture verlangt einen eindeutigen neutralen Zustand.',1;
IF XACT_STATE()<>0
 THROW 54991,N'Legacycapture verlangt einen eindeutigen neutralen Zustand.',1;
IF (@@OPTIONS&2)<>0
 THROW 54991,N'Legacycapture verlangt einen eindeutigen neutralen Zustand.',1;
IF @@LOCK_TIMEOUT<>-1
 THROW 54991,N'Legacycapture verlangt einen eindeutigen neutralen Zustand.',1;
CREATE TABLE #tbx_UpgradeTables(SchemaName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,LegacyColumns int NOT NULL,ObjectId int NULL);
INSERT #tbx_UpgradeTables VALUES
 (N'toolbelt_core',N'WorkType',18,NULL),(N'toolbelt_core',N'WorkItem',43,NULL),
 (N'toolbelt_core',N'WorkQueueScheduler',1,NULL),(N'toolbelt_core',N'WorkQueueBarrierBlocker',5,NULL),
 (N'toolbelt_core',N'ExecutionCancellation',5,NULL),(N'toolbelt_core',N'SecondSessionProvider',8,NULL),
 (N'toolbelt_core',N'EventLog',24,NULL),(N'toolbelt_file',N'FileContentRootAllowlist',5,NULL);
UPDATE #tbx_UpgradeTables SET ObjectId=OBJECT_ID(QUOTENAME(SchemaName)+N'.'+QUOTENAME(TableName),N'U');
IF (SELECT COUNT(*) FROM #tbx_UpgradeTables)<>8 OR EXISTS(SELECT 1 FROM #tbx_UpgradeTables t WHERE ObjectId IS NULL
 OR (SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=t.ObjectId)<>t.LegacyColumns+CASE WHEN t.TableName=N'WorkItem' AND @After=1 THEN 3 ELSE 0 END)
 THROW 54991,N'Der gepinnte Acht-Tabellen-Shape fehlt.',2;
IF (SELECT COUNT(*) FROM toolbelt_core.WorkType)<>2 OR (SELECT COUNT(*) FROM toolbelt_core.WorkItem)<>3
 OR (SELECT COUNT(*) FROM toolbelt_core.WorkQueueScheduler)<>1 OR (SELECT COUNT(*) FROM toolbelt_core.WorkQueueBarrierBlocker)<>0
 OR (SELECT COUNT(*) FROM toolbelt_core.ExecutionCancellation)<>3 OR (SELECT COUNT(*) FROM toolbelt_core.SecondSessionProvider)<>1
 OR (SELECT COUNT(*) FROM toolbelt_core.EventLog)<>3 OR (SELECT COUNT(*) FROM toolbelt_file.FileContentRootAllowlist)<>4
 THROW 54991,N'Die expliziten acht synthetischen Zeilenzeugen sind unvollständig.',4;
-- Die Originalprojektion ist exakt gepinnt; keine neue Spalte ersetzt still ein altes Feld.
DECLARE @Names nvarchar(max)=N'WorkItemId,WorkTypeId,PayloadJson,Status,EnqueuedAtUtc,EnqueuedBy,ClaimedAtUtc,ClaimedBy,ClaimToken,ClaimGeneration,LeaseDurationSeconds,LeaseUntilUtc,LastHeartbeatAtUtc,RecoveryCount,LastRecoveredAtUtc,LastRecoveredBy,CompletedAtUtc,CompletedBy,FailedAtUtc,FailedBy,FailureCode,FailureMessage,RowVersion,ExecutionGroup,Priority,ExecutionMode,IdempotencyKey,MaxAttempts,RetryBaseDelaySeconds,RetryMaxDelaySeconds,RetryCycleNumber,CycleAttemptCount,NextAttemptAtUtc,LastErrorCode,LastErrorMessage,LastRetryScheduledAtUtc,LastRetryScheduledBy,DeadLetteredAtUtc,DeadLetteredBy,LastRequeuedAtUtc,LastRequeuedBy,LastRequeueReason,BarrierEpoch';
IF (SELECT STRING_AGG(CONVERT(nvarchar(max),c.name),N',') WITHIN GROUP(ORDER BY c.column_id) FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.WorkItem') AND c.column_id<=43) COLLATE Latin1_General_100_BIN2<>@Names COLLATE Latin1_General_100_BIN2
 THROW 54991,N'Die 43 Originalfelder sind nicht unverändert vorhanden.',3;
CREATE TABLE #tbx_UpgradeSnapshot(Category varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Payload varbinary(max) NOT NULL);
DECLARE @Id int,@Schema sysname,@Table sysname,@Fields int,@Category varchar(128),@Projection nvarchar(max),@Sql nvarchar(max);
DECLARE tables_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectId,SchemaName,TableName,LegacyColumns FROM #tbx_UpgradeTables ORDER BY SchemaName,TableName;
OPEN tables_cursor;FETCH NEXT FROM tables_cursor INTO @Id,@Schema,@Table,@Fields;
WHILE @@FETCH_STATUS=0 BEGIN
 SELECT @Projection=STRING_AGG(CONVERT(nvarchar(max),N'CONVERT(varbinary(max),r.'+QUOTENAME(c.name)+N') AS '+QUOTENAME(c.name)),N',') WITHIN GROUP(ORDER BY c.column_id) FROM sys.columns c WHERE c.object_id=@Id AND c.column_id<=@Fields;
 SET @Category=CONVERT(varchar(128),N'row:'+@Schema+N'.'+@Table);
 -- Ein eigener Countzeuge macht auch die ausdrücklich leere Barrier-Tabelle sichtbar.
 SET @Sql=N'INSERT #tbx_UpgradeSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT COUNT_BIG(*) AS CountWitness FROM '+QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table)+N' FOR XML PATH(''count'')));
 INSERT #tbx_UpgradeSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT '+@Projection+N' FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM '+QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table)+N' r;';
 EXEC sys.sp_executesql @Sql,N'@Category varchar(128)',@Category=@Category;
 FETCH NEXT FROM tables_cursor INTO @Id,@Schema,@Table,@Fields;
END;
CLOSE tables_cursor;DEALLOCATE tables_cursor;
-- Keine blanket Catalog-Ausnahme: alte Spalten/DFs/IDs, Indizes, Checks, Annotations und Permissions.
-- Nur Queue-ModuleVersion-Werte werden normalisiert; Assert prüft beide tatsächlichen Releases.
DECLARE @Query nvarchar(max);
DECLARE catalog_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Category,Query FROM(VALUES
 ('catalog:tables',N'SELECT o.object_id,o.name,o.schema_id,o.type,o.principal_id,t.uses_ansi_nulls,t.is_replicated,t.is_memory_optimized,t.durability,t.temporal_type FROM sys.objects o JOIN sys.tables t ON t.object_id=o.object_id JOIN #tbx_UpgradeTables x ON x.ObjectId=o.object_id'),
 ('catalog:columns',N'SELECT c.* FROM sys.columns c JOIN #tbx_UpgradeTables x ON x.ObjectId=c.object_id WHERE c.column_id<=x.LegacyColumns'),
 ('catalog:identity',N'SELECT c.object_id,c.name,c.column_id,c.system_type_id,CONVERT(decimal(38,0),c.seed_value) seed_value,CONVERT(decimal(38,0),c.increment_value) increment_value,CONVERT(decimal(38,0),c.last_value) last_value,c.is_not_for_replication FROM sys.identity_columns c JOIN #tbx_UpgradeTables x ON x.ObjectId=c.object_id'),
 ('catalog:indexes',N'SELECT i.* FROM sys.indexes i JOIN #tbx_UpgradeTables x ON x.ObjectId=i.object_id'),
 ('catalog:index_columns',N'SELECT c.* FROM sys.index_columns c JOIN #tbx_UpgradeTables x ON x.ObjectId=c.object_id'),
 ('catalog:defaults',N'SELECT d.object_id,d.name,d.parent_object_id,d.parent_column_id,d.definition,d.is_system_named FROM sys.default_constraints d JOIN #tbx_UpgradeTables x ON x.ObjectId=d.parent_object_id WHERE d.parent_column_id<=x.LegacyColumns'),
 ('catalog:checks',N'SELECT CASE WHEN c.parent_object_id=OBJECT_ID(N''toolbelt_core.WorkItem'') AND c.name IN(N''CK_WorkItem_RecoveryMetadata'',N''CK_WorkItem_StateMetadata'',N''CK_WorkItem_Status'') THEN NULL ELSE c.object_id END StableCheckId,c.name,c.parent_object_id,c.parent_column_id,c.definition,c.is_disabled,c.is_not_trusted,c.is_not_for_replication,c.uses_database_collation,c.is_system_named FROM sys.check_constraints c JOIN #tbx_UpgradeTables x ON x.ObjectId=c.parent_object_id'),
 ('catalog:keys',N'SELECT k.object_id,k.name,k.parent_object_id,k.type,k.unique_index_id,k.is_system_named FROM sys.key_constraints k JOIN #tbx_UpgradeTables x ON x.ObjectId=k.parent_object_id'),
 ('catalog:foreign_keys',N'SELECT f.* FROM sys.foreign_keys f JOIN #tbx_UpgradeTables x ON x.ObjectId=f.parent_object_id'),
 ('catalog:foreign_key_columns',N'SELECT f.* FROM sys.foreign_key_columns f JOIN #tbx_UpgradeTables x ON x.ObjectId=f.parent_object_id'),
 ('catalog:properties',N'SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''BaseType'')) BaseType,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''MaxLength'')) MaxLength,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Precision'')) PrecisionValue,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Scale'')) ScaleValue,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''Collation'')) CollationValue,CASE WHEN (p.class=0 AND p.name=N''Toolbelt.Module.toolbelt.core.work-queue.Version'') OR (p.class=1 AND p.name=N''Toolbelt.ModuleVersion'' AND p.major_id IN(SELECT ObjectId FROM #tbx_UpgradeTables WHERE TableName IN(N''WorkItem'',N''WorkQueueScheduler'',N''WorkQueueBarrierBlocker''))) THEN CONVERT(varbinary(max),N''EXPECTED_QUEUE_VERSION'') ELSE CONVERT(varbinary(max),p.value) END ValueBytes FROM sys.extended_properties p WHERE (p.class=1 AND p.major_id IN(SELECT ObjectId FROM #tbx_UpgradeTables) AND p.minor_id<=ISNULL((SELECT LegacyColumns FROM #tbx_UpgradeTables WHERE ObjectId=p.major_id),0)) OR (p.class=0 AND p.name LIKE N''Toolbelt.Module.%'' AND p.name NOT LIKE N''Toolbelt.Module.toolbelt.core.worker-control.%'')'),
 ('catalog:permissions',N'SELECT p.* FROM sys.database_permissions p WHERE p.class=0 OR (p.class=3 AND p.major_id IN(SCHEMA_ID(N''toolbelt_core''),SCHEMA_ID(N''toolbelt_file''))) OR (p.class=1 AND p.major_id IN(SELECT ObjectId FROM #tbx_UpgradeTables))')
 )v(Category,Query);
OPEN catalog_cursor;FETCH NEXT FROM catalog_cursor INTO @Category,@Query;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Sql=N'INSERT #tbx_UpgradeSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT r.* FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM ('+@Query+N')r;';
 EXEC sys.sp_executesql @Sql,N'@Category varchar(128)',@Category=@Category;
 FETCH NEXT FROM catalog_cursor INTO @Category,@Query;
END;
CLOSE catalog_cursor;DEALLOCATE catalog_cursor;
SELECT Category,Payload FROM #tbx_UpgradeSnapshot;
DROP TABLE #tbx_UpgradeSnapshot;
DROP TABLE #tbx_UpgradeTables;
