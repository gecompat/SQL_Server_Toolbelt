:On Error exit
SET NOCOUNT ON;
-- Wiederverwendbare binäre Momentaufnahme. Tempdaten verlassen die Session nicht.
DROP TABLE IF EXISTS #tbx_ControlRepeatActualRows;
DROP TABLE IF EXISTS #tbx_ControlRepeatActualCatalog;
CREATE TABLE #tbx_ControlRepeatActualRows(TableName sysname COLLATE Latin1_General_100_BIN2 NOT NULL,RowBytes varbinary(max) NOT NULL);
CREATE TABLE #tbx_ControlRepeatActualCatalog(Kind varchar(32) COLLATE Latin1_General_100_BIN2 NOT NULL,RowBytes varbinary(max) NOT NULL);
DECLARE @Table sysname,@Sql nvarchar(max);
DECLARE tables_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectName FROM #tbx_ControlRepeatObjects WHERE ObjectType='U' ORDER BY ObjectName;
OPEN tables_cursor;FETCH NEXT FROM tables_cursor INTO @Table;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Sql=N'INSERT #tbx_ControlRepeatActualRows SELECT @Name,CONVERT(varbinary(max),(SELECT r.* FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER)) FROM toolbelt_core.'+QUOTENAME(@Table)+N' r;';
 EXEC sys.sp_executesql @Sql,N'@Name sysname',@Name=@Table;
 FETCH NEXT FROM tables_cursor INTO @Table;
END;
CLOSE tables_cursor;DEALLOCATE tables_cursor;
-- Keine modify_date oder regenerierten CK-object_ids: relevant sind Struktur,
-- Definition, Trust, Zustand und die IDs der persistenten Tabellen/API-Objekte.
DECLARE @Kind varchar(32),@Query nvarchar(max);
DECLARE catalog_cursor CURSOR LOCAL FAST_FORWARD FOR
 SELECT Kind,Query FROM(VALUES
 ('objects',N'SELECT o.object_id,o.name,o.type,o.schema_id,o.principal_id FROM sys.objects o JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=o.object_id'),
 ('columns',N'SELECT c.* FROM sys.columns c JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=c.object_id'),
 ('identity',N'SELECT c.object_id,c.name,c.column_id,c.system_type_id,CONVERT(decimal(38,0),c.seed_value) seed_value,CONVERT(decimal(38,0),c.increment_value) increment_value,CONVERT(decimal(38,0),c.last_value) last_value,c.is_not_for_replication FROM sys.identity_columns c JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=c.object_id'),
 ('indexes',N'SELECT i.* FROM sys.indexes i JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=i.object_id'),
 ('index_columns',N'SELECT c.* FROM sys.index_columns c JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=c.object_id'),
 ('defaults',N'SELECT d.name,d.parent_object_id,d.parent_column_id,d.definition,d.is_system_named FROM sys.default_constraints d JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=d.parent_object_id'),
 ('checks',N'SELECT c.name,c.parent_object_id,c.parent_column_id,c.definition,c.is_disabled,c.is_not_trusted,c.is_not_for_replication,c.uses_database_collation,c.is_system_named FROM sys.check_constraints c JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=c.parent_object_id'),
 ('keys',N'SELECT k.name,k.parent_object_id,k.type,k.unique_index_id,k.is_system_named FROM sys.key_constraints k JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=k.parent_object_id'),
 ('foreign_keys',N'SELECT f.* FROM sys.foreign_keys f JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=f.parent_object_id'),
 ('foreign_key_columns',N'SELECT f.* FROM sys.foreign_key_columns f JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=f.parent_object_id'),
 ('modules',N'SELECT m.* FROM sys.sql_modules m JOIN #tbx_ControlRepeatObjects x ON x.ObjectId=m.object_id'),
 ('properties',N'SELECT p.class,p.major_id,p.minor_id,p.name,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''BaseType'')) BaseType,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''MaxLength'')) MaxLength,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Precision'')) PrecisionValue,CONVERT(int,SQL_VARIANT_PROPERTY(p.value,''Scale'')) ScaleValue,CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(p.value,''Collation'')) CollationValue,CONVERT(nvarchar(4000),p.value) PropertyValue FROM sys.extended_properties p WHERE (p.class=1 AND p.major_id IN(SELECT ObjectId FROM #tbx_ControlRepeatObjects)) OR (p.class=0 AND p.name IN(N''Toolbelt.Module.toolbelt.core.work-queue.Version'',N''Toolbelt.Module.toolbelt.core.work-queue.DeploymentMode'',N''Toolbelt.Module.toolbelt.core.worker-control.Version'',N''Toolbelt.Module.toolbelt.core.worker-control.DeploymentMode''))'),
 ('permissions',N'SELECT p.* FROM sys.database_permissions p WHERE p.class=0 OR (p.class=3 AND p.major_id=SCHEMA_ID(N''toolbelt_core'')) OR (p.class=1 AND p.major_id IN(SELECT ObjectId FROM #tbx_ControlRepeatObjects))')
 )v(Kind,Query);
OPEN catalog_cursor;FETCH NEXT FROM catalog_cursor INTO @Kind,@Query;
WHILE @@FETCH_STATUS=0 BEGIN
 SET @Sql=N'INSERT #tbx_ControlRepeatActualCatalog SELECT @Kind,CONVERT(varbinary(max),(SELECT r.* FOR JSON PATH,INCLUDE_NULL_VALUES,WITHOUT_ARRAY_WRAPPER)) FROM ('+@Query+N') r;';
 EXEC sys.sp_executesql @Sql,N'@Kind varchar(32)',@Kind=@Kind;
 FETCH NEXT FROM catalog_cursor INTO @Kind,@Query;
END;
CLOSE catalog_cursor;DEALLOCATE catalog_cursor;
GO
