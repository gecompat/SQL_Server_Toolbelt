/* Befüllter Deploymentrepeat ohne Aufruf einer Dateisystem-API.
   Der Labadapter übergibt @Phase als SQL-Parameter: Setup oder Capture.
   Alle Pfade sind synthetische Katalogwerte; sie werden nicht aufgelöst. */
SET NOCOUNT ON;
-- Die reine Probe unterschied zusammengesetzte und getrennte Auswertung.
-- Getrennte Statements erhalten alle drei Prädikate; keine Ursachenbehauptung.
IF @@TRANCOUNT <> 0
    THROW 52970,N'Der Repeatzeuge benötigt eine neutrale Session.',1;
IF XACT_STATE() <> 0
    THROW 52970,N'Der Repeatzeuge benötigt eine neutrale Session.',1;
IF (2 & @@OPTIONS) <> 0
    THROW 52970,N'Der Repeatzeuge benötigt eine neutrale Session.',1;
DECLARE @ObjectId int=OBJECT_ID(N'toolbelt_filesystem.FileSystemRoot',N'U');
IF @ObjectId IS NULL OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=@ObjectId)<>10
    THROW 52970,N'Der aktuelle Rootvertrag mit zehn Spalten fehlt.',2;

IF @Phase=N'Setup'
BEGIN
    IF EXISTS(SELECT 1 FROM toolbelt_filesystem.FileSystemRoot)
        THROW 52970,N'Der eigene frische Rootkatalog muss leer sein.',3;
    INSERT toolbelt_filesystem.FileSystemRoot
        (RootAlias,RootPath,WorkPath,AllowRead,AllowWrite,AllowList,AllowDelete,AllowCreateDirectory,IsActive,AllowServiceAccount)
    VALUES
        (N'ContosoEmpty',N'C:\Contoso\Empty',NULL,0,0,0,0,0,0,0),
        (N'ContosoUnicode',N'C:\Contoso\Größe\ ',N'work\ ',1,1,1,1,1,1,1),
        (N'ContosoMixed',N'C:\Contoso\Mixed',N'',1,0,1,0,1,1,0),
        (N'FabrikamInactive',N'C:\Fabrikam\Root',N'relative',1,1,1,1,1,0,1);
    EXEC sys.sp_addextendedproperty @name=N'Contoso.Repeat',@value=0x00102000,
        @level0type=N'SCHEMA',@level0name=N'toolbelt_filesystem',@level1type=N'TABLE',@level1name=N'FileSystemRoot';
    EXEC sys.sp_addextendedproperty @name=N'Contoso.Repeat',@value=N'Unicode ä; padding ',
        @level0type=N'SCHEMA',@level0name=N'toolbelt_filesystem',@level1type=N'TABLE',@level1name=N'FileSystemRoot',
        @level2type=N'COLUMN',@level2name=N'WorkPath';
    RETURN;
END;
IF @Phase<>N'Capture' OR @Phase IS NULL
    THROW 52970,N'Unbekannte Repeatphase.',4;
IF (SELECT COUNT_BIG(*) FROM toolbelt_filesystem.FileSystemRoot)<>4
    THROW 52970,N'Der vollständige Vierzeilenzeuge fehlt.',5;

/* XML mit expliziten NULLs und Binary/Base64 erhält Typ-/Text-/Paddingbytes.
   Bewusst ausgewählte stabile Katalogfelder: keine DDL-Änderungszeitstempel.
   Jede Kategorie liefert genau eine Zeile, auch bei leerem Permissionset. */
SELECT N'rows' Category,CONVERT(varbinary(max),(SELECT (SELECT COUNT_BIG(*) FROM toolbelt_filesystem.FileSystemRoot) [RowCount],
    (SELECT RootAlias,RootPath,WorkPath,AllowRead,AllowWrite,AllowList,AllowDelete,AllowCreateDirectory,IsActive,AllowServiceAccount
     FROM toolbelt_filesystem.FileSystemRoot ORDER BY RootAlias COLLATE Latin1_General_100_BIN2
     FOR XML PATH('row'),ELEMENTS XSINIL,TYPE) [Rows]
    FOR XML PATH('data'),TYPE)) Payload
UNION ALL SELECT N'table',CONVERT(varbinary(max),(SELECT t.object_id,t.schema_id,t.principal_id,t.lob_data_space_id,t.filestream_data_space_id,
    t.lock_on_bulk_load,t.is_replicated,t.is_memory_optimized,t.temporal_type,s.principal_id SchemaOwner
    FROM sys.tables t JOIN sys.schemas s ON s.schema_id=t.schema_id WHERE t.object_id=@ObjectId
    FOR XML PATH('table'),ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'columns',CONVERT(varbinary(max),(SELECT column_id,name,system_type_id,user_type_id,max_length,precision,scale,
    collation_name,is_nullable,is_ansi_padded,is_rowguidcol,is_identity,is_computed,default_object_id,rule_object_id
    FROM sys.columns WHERE object_id=@ObjectId ORDER BY column_id FOR XML PATH('column'),ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'indexes',CONVERT(varbinary(max),(SELECT index_id,name,type,is_unique,data_space_id,ignore_dup_key,
    is_primary_key,is_unique_constraint,fill_factor,is_padded,is_disabled,allow_row_locks,allow_page_locks,has_filter,filter_definition
    FROM sys.indexes WHERE object_id=@ObjectId ORDER BY index_id FOR XML PATH('index'),ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'index_columns',CONVERT(varbinary(max),(SELECT index_id,index_column_id,column_id,key_ordinal,
    partition_ordinal,is_descending_key,is_included_column FROM sys.index_columns WHERE object_id=@ObjectId
    ORDER BY index_id,index_column_id FOR XML PATH('column'),ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'constraints',CONVERT(varbinary(max),(SELECT o.object_id,o.name,o.type,c.parent_column_id,c.definition,
    c.is_disabled,c.is_not_trusted,c.is_not_for_replication,d.definition DefaultDefinition,d.parent_column_id DefaultColumn
    FROM sys.objects o LEFT JOIN sys.check_constraints c ON c.object_id=o.object_id
    LEFT JOIN sys.default_constraints d ON d.object_id=o.object_id WHERE o.parent_object_id=@ObjectId
    ORDER BY o.type,o.name COLLATE Latin1_General_100_BIN2 FOR XML PATH('constraint'),ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'properties',CONVERT(varbinary(max),(SELECT class,major_id,minor_id,name,
    CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,'BaseType')) BaseType,
    CONVERT(nvarchar(128),SQL_VARIANT_PROPERTY(value,'Collation')) Collation,
    CONVERT(varbinary(max),value) ValueBytes
    FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId
    ORDER BY minor_id,name COLLATE Latin1_General_100_BIN2 FOR XML PATH('property'),BINARY BASE64,ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'permissions',CONVERT(varbinary(max),(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state
    FROM sys.database_permissions WHERE class=1 AND major_id=@ObjectId
    ORDER BY minor_id,grantee_principal_id,grantor_principal_id,type FOR XML PATH('permission'),ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'role',CONVERT(varbinary(max),(SELECT principal_id,name,type,owning_principal_id,is_fixed_role
    FROM sys.database_principals WHERE name=N'toolbelt_filesystem_service_account'
    FOR XML PATH('role'),ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'assembly',CONVERT(varbinary(max),(SELECT a.assembly_id,a.name,a.permission_set,a.clr_name,a.principal_id,
    af.file_id,HASHBYTES('SHA2_512',af.content) ContentHash FROM sys.assemblies a
    JOIN sys.assembly_files af ON af.assembly_id=a.assembly_id WHERE a.name=N'Toolbelt_Filesystem_Windows'
    ORDER BY af.file_id FOR XML PATH('assembly'),BINARY BASE64,ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'bindings',CONVERT(varbinary(max),(SELECT m.object_id,m.assembly_id,m.assembly_class,m.assembly_method,
    m.execute_as_principal_id FROM sys.assembly_modules m JOIN sys.objects o ON o.object_id=m.object_id
    WHERE o.schema_id=SCHEMA_ID(N'toolbelt_filesystem') ORDER BY m.object_id
    FOR XML PATH('binding'),ELEMENTS XSINIL,TYPE))
UNION ALL SELECT N'marker',CONVERT(varbinary(max),(SELECT name,CONVERT(varbinary(max),value) ValueBytes
    FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.filesystem.windows.Version'
    FOR XML PATH('marker'),BINARY BASE64,ELEMENTS XSINIL,TYPE));
