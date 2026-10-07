-- Nur eigener stabiler DB-Scope; Resultbytes bleiben im privaten Adaptermemory.
-- Jedes Feld wird vor XML in Binary umgewandelt: NULL, Textpadding, RV und Auditpräzision bleiben erhalten.
SET NOCOUNT ON;
IF @@TRANCOUNT<>0 OR XACT_STATE()<>0 OR (@@OPTIONS&2)<>0 OR @@LOCK_TIMEOUT<>-1
 THROW 54981,N'Exportsnapshot verlangt eine neutrale Sitzung.',1;
CREATE TABLE #tbx_ExportObjects(ObjectId int NOT NULL PRIMARY KEY,SchemaName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ObjectName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,ObjectType char(2) NOT NULL);
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
 THROW 54981,N'Exportsnapshot erwartet genau 14 persistente Tabellen.',2;
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
 THROW 54981,N'Der gepinnte Export-Tabellen-Shape weicht ab.',5;
CREATE TABLE #tbx_ExportSnapshot(Category varchar(128) COLLATE Latin1_General_100_BIN2 NOT NULL,Payload varbinary(max) NOT NULL);
DECLARE @Id int,@Schema sysname,@Table sysname,@Category varchar(128),@Projection nvarchar(max),@Sql nvarchar(max),@FilteredSql nvarchar(max);
DECLARE tables_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectId,SchemaName,ObjectName FROM #tbx_ExportObjects WHERE ObjectType='U' ORDER BY SchemaName,ObjectName;
OPEN tables_cursor;FETCH NEXT FROM tables_cursor INTO @Id,@Schema,@Table;
WHILE @@FETCH_STATUS=0 BEGIN
 SELECT @Projection=STRING_AGG(CONVERT(nvarchar(max),N'CONVERT(varbinary(max),r.'+QUOTENAME(c.name)+N') AS '+QUOTENAME(c.name)),N',') WITHIN GROUP(ORDER BY c.column_id) FROM sys.columns c WHERE c.object_id=@Id;
 SET @Category=CONVERT(varchar(128),N'row:'+@Schema+N'.'+@Table);
 SET @Sql=N'INSERT #tbx_ExportSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT '+@Projection+N' FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM '+QUOTENAME(@Schema)+N'.'+QUOTENAME(@Table)+N' r';
 IF @Table=N'WorkType' AND @Schema=N'toolbelt_core'
 BEGIN
  SET @FilteredSql=@Sql+N' WHERE r.WorkTypeName<>''toolbelt.event-log.write'';';
  EXEC sys.sp_executesql @FilteredSql,N'@Category varchar(128)',@Category=@Category;
  SET @FilteredSql=@Sql+N' WHERE r.WorkTypeName=''toolbelt.event-log.write'';';
  EXEC sys.sp_executesql @FilteredSql,N'@Category varchar(128)',@Category='event-work-type';
 END;
 ELSE EXEC sys.sp_executesql @Sql,N'@Category varchar(128)',@Category=@Category;
 IF NOT EXISTS(SELECT 1 FROM #tbx_ExportSnapshot WHERE Category=@Category)
  THROW 54981,N'Eine der 14 Exporttabellen ist unbezeugt.',3;
 FETCH NEXT FROM tables_cursor INTO @Id,@Schema,@Table;
END;
CLOSE tables_cursor;DEALLOCATE tables_cursor;
-- Eventregistrierung darf Phase1 nur kanonisch verändern; ihre Herkunft bleibt identisch.
INSERT #tbx_ExportSnapshot
 SELECT 'event-original',CONVERT(varbinary(max),(SELECT CONVERT(varbinary(max),w.WorkTypeId) Id,
 CONVERT(varbinary(max),w.WorkTypeName) Name,CONVERT(varbinary(max),w.CreatedAtUtc) CreatedAtUtc,
 CONVERT(varbinary(max),w.CreatedBy) CreatedBy FOR XML PATH('row'),BINARY BASE64,ELEMENTS XSINIL))
 FROM toolbelt_core.WorkType w WHERE w.WorkTypeName='toolbelt.event-log.write';

-- Semantische Katalogform: wiedererzeugte WorkItem-CK-IDs und DDL-Zeitstempel sind keine Erhaltungszusage.
DECLARE @Query nvarchar(max);
DECLARE catalog_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT Category,Query FROM(VALUES
 ('catalog:objects',N'SELECT o.object_id,o.name,o.type,o.schema_id,o.principal_id FROM sys.objects o JOIN #tbx_ExportObjects x ON x.ObjectId=o.object_id'),
 ('catalog:children',N'SELECT o.name,o.type,o.parent_object_id,o.schema_id,o.principal_id FROM sys.objects o JOIN #tbx_ExportObjects x ON x.ObjectId=o.parent_object_id'),
 ('catalog:schemas',N'SELECT s.schema_id,s.name,s.principal_id FROM sys.schemas s WHERE s.schema_id IN(SELECT DISTINCT o.schema_id FROM sys.objects o JOIN #tbx_ExportObjects x ON x.ObjectId=o.object_id)'),
 ('catalog:tables',N'SELECT t.object_id,t.uses_ansi_nulls,t.is_replicated,t.has_replication_filter,t.is_merge_published,t.is_sync_tran_subscribed,t.is_memory_optimized,t.durability,t.temporal_type,t.is_filetable FROM sys.tables t JOIN #tbx_ExportObjects x ON x.ObjectId=t.object_id'),
 ('catalog:columns',N'SELECT c.* FROM sys.columns c JOIN #tbx_ExportObjects x ON x.ObjectId=c.object_id'),
 ('catalog:identity',N'SELECT c.object_id,c.name,c.column_id,c.system_type_id,CONVERT(decimal(38,0),c.seed_value) seed_value,CONVERT(decimal(38,0),c.increment_value) increment_value,CONVERT(decimal(38,0),c.last_value) last_value,c.is_not_for_replication FROM sys.identity_columns c JOIN #tbx_ExportObjects x ON x.ObjectId=c.object_id'),
 ('catalog:indexes',N'SELECT i.* FROM sys.indexes i JOIN #tbx_ExportObjects x ON x.ObjectId=i.object_id'),
 ('catalog:index_columns',N'SELECT c.* FROM sys.index_columns c JOIN #tbx_ExportObjects x ON x.ObjectId=c.object_id'),
 ('catalog:defaults',N'SELECT d.object_id,d.name,d.parent_object_id,d.parent_column_id,d.definition,d.is_system_named FROM sys.default_constraints d JOIN #tbx_ExportObjects x ON x.ObjectId=d.parent_object_id'),
 ('catalog:checks',N'SELECT c.name,c.parent_object_id,c.parent_column_id,c.definition,c.is_disabled,c.is_not_trusted,c.is_not_for_replication,c.uses_database_collation,c.is_system_named FROM sys.check_constraints c JOIN #tbx_ExportObjects x ON x.ObjectId=c.parent_object_id'),
 ('catalog:keys',N'SELECT k.object_id,k.name,k.parent_object_id,k.type,k.unique_index_id,k.is_system_named FROM sys.key_constraints k JOIN #tbx_ExportObjects x ON x.ObjectId=k.parent_object_id'),
 ('catalog:foreign_keys',N'SELECT f.* FROM sys.foreign_keys f JOIN #tbx_ExportObjects x ON x.ObjectId=f.parent_object_id'),
 ('catalog:foreign_key_columns',N'SELECT f.* FROM sys.foreign_key_columns f JOIN #tbx_ExportObjects x ON x.ObjectId=f.parent_object_id'),
 ('catalog:triggers',N'SELECT t.object_id,t.name,t.parent_id,t.is_disabled,t.is_instead_of_trigger,t.is_not_for_replication FROM sys.triggers t JOIN #tbx_ExportObjects x ON x.ObjectId=t.parent_id'),
 ('catalog:modules',N'SELECT m.* FROM sys.sql_modules m JOIN #tbx_ExportObjects x ON x.ObjectId=m.object_id'),
 ('catalog:properties',N'SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''BaseType'')) BaseType,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''MaxLength'')) MaxLength,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Precision'')) PrecisionValue,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Scale'')) ScaleValue,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''Collation'')) CollationValue,CONVERT(varbinary(max),p.value) ValueBytes FROM sys.extended_properties p WHERE ((p.class=1 AND p.major_id IN(SELECT ObjectId FROM #tbx_ExportObjects)) OR (p.class=0 AND p.name LIKE N''Toolbelt.Module.%'')) AND NOT(p.class=1 AND p.major_id=OBJECT_ID(N''toolbelt_file.FileContentRootAllowlist'') AND p.minor_id=0 AND p.name=N''MS_Description'')'),
 ('file-description',N'SELECT p.class,p.major_id,p.minor_id,CONVERT(varbinary(max),p.name) PropertyName,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''BaseType'')) BaseType,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''MaxLength'')) MaxLength,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''Collation'')) CollationValue,CONVERT(varbinary(max),p.value) ValueBytes FROM sys.extended_properties p WHERE p.class=1 AND p.major_id=OBJECT_ID(N''toolbelt_file.FileContentRootAllowlist'') AND p.minor_id=0 AND p.name=N''MS_Description'''),
 ('catalog:permissions',N'SELECT p.* FROM sys.database_permissions p WHERE p.class=0 OR (p.class=3 AND p.major_id IN(SCHEMA_ID(N''toolbelt_core''),SCHEMA_ID(N''toolbelt_file''))) OR (p.class=1 AND p.major_id IN(SELECT ObjectId FROM #tbx_ExportObjects))')
 )v(Category,Query);
OPEN catalog_cursor;FETCH NEXT FROM catalog_cursor INTO @Category,@Query;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Sql=N'INSERT #tbx_ExportSnapshot SELECT @Category,CONVERT(varbinary(max),(SELECT r.* FOR XML PATH(''row''),BINARY BASE64,ELEMENTS XSINIL)) FROM ('+@Query+N')r;';
 EXEC sys.sp_executesql @Sql,N'@Category varchar(128)',@Category=@Category;
 FETCH NEXT FROM catalog_cursor INTO @Category,@Query;
END;
CLOSE catalog_cursor;DEALLOCATE catalog_cursor;
IF (SELECT COUNT(*) FROM #tbx_ExportSnapshot WHERE Category='event-work-type')<>1
 OR (SELECT COUNT(*) FROM #tbx_ExportSnapshot WHERE Category='event-original')<>1
 OR (SELECT COUNT(*) FROM #tbx_ExportSnapshot WHERE Category='file-description')<>1
 THROW 54981,N'Die exakt abgegrenzten Normalisierungszeugen fehlen.',4;
SELECT Category,Payload FROM #tbx_ExportSnapshot;
DROP TABLE #tbx_ExportSnapshot;
DROP TABLE #tbx_ExportObjects;
