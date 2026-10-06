-- Pure Include: Own2-Slots, bekannte Assembly, Dependencies; keine Mutation.
IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_files',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_modules',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_references',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
 THROW 55632,N'JSON Schema lifecycle: vollständige Metadatensicht fehlt.',1;
SELECT @SchemaVersion=NULL,@SchemaMode=NULL,@SchemaAssemblyId=NULL,@SchemaAssemblyOwner=NULL,@SchemaInstalledHash=NULL,@SchemaInstalledArtifactId=NULL;
SELECT @SchemaVersion=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.schema.Version';
SELECT @SchemaMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode';
SELECT @SchemaAssemblyId=a.assembly_id,@SchemaAssemblyOwner=a.principal_id,@SchemaInstalledHash=HASHBYTES(N'SHA2_512',f.content)
 FROM sys.assemblies a LEFT JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1 WHERE a.name=N'Toolbelt_JsonSchema';
IF @SchemaVersion IS NULL
BEGIN
 IF @SchemaAssemblyId IS NOT NULL OR @SchemaMode IS NOT NULL
  OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.schema.Version')
  OR EXISTS(SELECT 1 FROM @SchemaSlots WHERE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(Name)) IS NOT NULL)
  THROW 55634,N'JSON Schema lifecycle: unregistrierter oder fremder Zielslot.',1;
END
ELSE
BEGIN
 SET @SchemaInstalledArtifactId=CASE
  WHEN CONVERT(varbinary(max),@SchemaVersion)=CONVERT(varbinary(max),N'1.0.0') AND @SchemaInstalledHash=@SchemaPreviousHash THEN @SchemaPreviousArtifactId
  WHEN CONVERT(varbinary(max),@SchemaVersion)=CONVERT(varbinary(max),N'1.0.1') AND @SchemaInstalledHash=@SchemaKnownHash THEN @SchemaArtifactId END;
 IF @SchemaInstalledArtifactId IS NULL
  OR @SchemaMode IS NULL OR CONVERT(varbinary(max),@SchemaMode)<>CONVERT(varbinary(max),@Mode)
  OR @SchemaAssemblyId IS NULL OR @SchemaInstalledHash IS NULL
  OR NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE assembly_id=@SchemaAssemblyId AND is_user_defined=1 AND permission_set=1 AND is_visible=1
   AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_JsonSchema'))
  OR (SELECT COUNT(*) FROM sys.assembly_files WHERE assembly_id=@SchemaAssemblyId)<>1
  THROW 55633,N'JSON Schema lifecycle: unbekannter oder inkohärenter Releasezustand.',1;
 DELETE FROM @SchemaAssemblyMarkers;
 INSERT @SchemaAssemblyMarkers VALUES
 (N'Toolbelt.Managed',CONVERT(sql_variant,CONVERT(int,1))),
 (N'Toolbelt.ModuleId',CONVERT(sql_variant,CONVERT(nvarchar(64),N'toolbelt.json.schema'))),
 (N'Toolbelt.ModuleVersion',CONVERT(sql_variant,CONVERT(nvarchar(16),@SchemaVersion))),
 (N'Toolbelt.DeploymentMode',CONVERT(sql_variant,CONVERT(nvarchar(16),@Mode))),
 (N'Toolbelt.AssemblySha512',CONVERT(sql_variant,@SchemaInstalledHash)),(N'Toolbelt.ArtifactId',CONVERT(sql_variant,@SchemaInstalledArtifactId));
 IF EXISTS(SELECT 1 FROM @SchemaAssemblyMarkers expected WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e
  WHERE e.class=5 AND e.major_id=@SchemaAssemblyId AND e.minor_id=0 AND e.name=expected.Name
   AND SQL_VARIANT_PROPERTY(e.value,N'BaseType')=SQL_VARIANT_PROPERTY(expected.Value,N'BaseType')
   AND SQL_VARIANT_PROPERTY(e.value,N'MaxLength')=SQL_VARIANT_PROPERTY(expected.Value,N'MaxLength')
   AND DATALENGTH(e.value)=DATALENGTH(expected.Value) AND CONVERT(varbinary(max),e.value)=CONVERT(varbinary(max),expected.Value)))
  THROW 55633,N'JSON Schema lifecycle: typisiertes Assemblymarkertuple inkohärent.',1;
 IF EXISTS(SELECT 1 FROM @SchemaSlots slot WHERE NOT EXISTS(SELECT 1 FROM sys.objects o
  WHERE o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(slot.Name)) AND CONVERT(varbinary(2),o.type)=CONVERT(varbinary(2),slot.Kind)
   AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),slot.Name)
   AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleId'
    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.json.schema'))
   AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@SchemaVersion))
   AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.DeploymentMode'
    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Mode))))
  THROW 55633,N'JSON Schema lifecycle: objektgenaue Ownership inkohärent.',1;
 IF NOT EXISTS(SELECT 1 FROM sys.assembly_modules WHERE object_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') AND assembly_id=@SchemaAssemblyId
  AND CONVERT(varbinary(max),assembly_class)=CONVERT(varbinary(max),N'Toolbelt.JsonSchema.JsonSchemaBridge')
  AND CONVERT(varbinary(max),assembly_method)=CONVERT(varbinary(max),N'Validate'))
  OR EXISTS(SELECT 1 FROM @SchemaParameters expected WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p
   WHERE p.object_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') AND p.parameter_id=expected.Id
    AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.Name) AND p.system_type_id=expected.TypeId
    AND p.user_type_id=p.system_type_id AND p.max_length=expected.Length AND p.is_output=0))
  OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal'))<>8
  OR EXISTS(SELECT 1 FROM @SchemaColumns expected WHERE NOT EXISTS(SELECT 1 FROM sys.columns c
   WHERE c.object_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') AND c.column_id=expected.Id
    AND CONVERT(varbinary(max),c.name)=CONVERT(varbinary(max),expected.Name) AND c.system_type_id=expected.TypeId
    AND c.user_type_id=c.system_type_id AND c.max_length=expected.Length AND c.is_nullable=1))
  OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal'))<>10
  THROW 55633,N'JSON Schema lifecycle: CLR-Binding-/Parameters-/Spaltenvertrag inkohärent.',1;
 IF EXISTS(SELECT 1 FROM @SchemaPublicParameters expected WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p
  WHERE p.object_id=OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema') AND p.parameter_id=expected.Id
   AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),expected.Name) AND p.system_type_id=expected.TypeId
   AND p.max_length=expected.Length AND p.is_output=0
   AND ((expected.AliasName IS NULL AND p.user_type_id=p.system_type_id)
    OR (expected.AliasName IS NOT NULL AND CONVERT(varbinary(max),TYPE_NAME(p.user_type_id))=CONVERT(varbinary(max),expected.AliasName)))))
  OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema'))<>12
  THROW 55633,N'JSON Schema lifecycle: öffentliche Parametersignatur inkohärent.',1;
 IF EXISTS(SELECT 1 FROM sys.assembly_modules WHERE assembly_id=@SchemaAssemblyId AND object_id<>OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal'))
  OR EXISTS(SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id=@SchemaAssemblyId)
  OR EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN @SchemaSlots target ON d.referenced_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(target.Name))
   WHERE NOT EXISTS(SELECT 1 FROM @SchemaSlots own WHERE d.referencing_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(own.Name))))
  THROW 55636,N'JSON Schema lifecycle: fremder Verbraucher blockiert Lifecycle.',1;
END;
IF @SchemaInstalling=1 OR @SchemaAssemblyId IS NOT NULL
BEGIN
 SELECT @JsonCoreExpectedMode=@Mode,@JsonCoreRequired=1;
:r ../../toolbelt.json.core/Deployment/Preflight.sql
 -- Schema installiert/repariert weder ResultTable noch Constructors.
 IF @SchemaInstalling=1
 BEGIN
 SELECT @SchemaResultVersion=NULL;
 SELECT @SchemaResultVersion=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
 SELECT @SchemaResultId=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'),@SchemaMajor=TRY_CONVERT(int,PARSENAME(@SchemaResultVersion,3)),
  @SchemaMinor=TRY_CONVERT(int,PARSENAME(@SchemaResultVersion,2)),@SchemaPatch=TRY_CONVERT(int,PARSENAME(@SchemaResultVersion,1));
 IF @SchemaResultId IS NULL OR @SchemaMajor IS NULL OR @SchemaMajor<1 OR @SchemaMinor IS NULL OR @SchemaMinor<0 OR @SchemaPatch IS NULL OR @SchemaPatch<0
  OR CONVERT(varbinary(max),@SchemaResultVersion)<>CONVERT(varbinary(max),CONCAT(@SchemaMajor,N'.',@SchemaMinor,N'.',@SchemaPatch))
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@SchemaResultId AND minor_id=0 AND name=N'Toolbelt.ModuleId'
   AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.core.result-table'))
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@SchemaResultId AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
   AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@SchemaResultVersion))
  THROW 55632,N'JSON Schema lifecycle: registrierte ResultTable-Dependency >=1.0.0 fehlt.',1;
 END;
 SELECT @SchemaOwner=COALESCE((SELECT principal_id FROM sys.schemas WHERE name=N'toolbelt_json'),USER_ID());
 IF @SchemaOwner IS NULL OR @SchemaOwner<>@JsonCoreOwner OR (@SchemaAssemblyId IS NOT NULL AND @SchemaAssemblyOwner<>@SchemaOwner)
  OR EXISTS(SELECT 1 FROM @SchemaSlots slot JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(slot.Name))
   WHERE COALESCE(o.principal_id,@SchemaOwner)<>@SchemaOwner)
  THROW 55633,N'JSON Schema lifecycle: kohärente vorhandene Owner fehlen; keine Ownerreparatur.',1;
 IF @SchemaAssemblyId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sys.assembly_references WHERE assembly_id=@SchemaAssemblyId AND referenced_assembly_id=@JsonCoreId)
  THROW 55633,N'JSON Schema lifecycle: bekannte Assembly referenziert Core nicht.',1;
END;
-- Eine vorliegende Legacy1.2-Assembly würde einen zweiten aktuellen Scanner
-- aktiv lassen. Diese Read-only-Dependencyprüfung verändert Constructors nicht.
IF @SchemaInstalling=1 AND (EXISTS(SELECT 1 FROM sys.assemblies WHERE name=N'Toolbelt_JsonConstructors')
 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version'))
BEGIN
 SELECT @SchemaConstructorId=NULL,@SchemaConstructorVersion=NULL;
 SELECT @SchemaConstructorVersion=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version';
 SELECT @SchemaConstructorId=a.assembly_id FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
  WHERE a.name=N'Toolbelt_JsonConstructors' AND a.permission_set=1 AND a.is_user_defined=1 AND a.principal_id=@JsonCoreOwner
   AND HASHBYTES(N'SHA2_512',f.content)=@TargetKnownHash;
 IF @SchemaConstructorVersion IS NULL OR CONVERT(varbinary(max),@SchemaConstructorVersion)<>CONVERT(varbinary(max),N'1.3.0')
  OR @SchemaConstructorId IS NULL
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode'
   AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Mode))
  OR NOT EXISTS(SELECT 1 FROM sys.assembly_references WHERE assembly_id=@SchemaConstructorId AND referenced_assembly_id=@JsonCoreId)
  THROW 55633,N'JSON Schema lifecycle: vorhandene Constructors zuerst explizit und kohärent auf1.3 migrieren.',1;
 DELETE FROM @SchemaConstructorMarkers;
 INSERT @SchemaConstructorMarkers VALUES
 (N'Toolbelt.Managed',CONVERT(sql_variant,CONVERT(int,1))),
 (N'Toolbelt.ModuleId',CONVERT(sql_variant,CONVERT(nvarchar(64),N'toolbelt.json.constructors'))),
 (N'Toolbelt.ModuleVersion',CONVERT(sql_variant,CONVERT(nvarchar(16),N'1.3.0'))),
 (N'Toolbelt.DeploymentMode',CONVERT(sql_variant,CONVERT(nvarchar(16),@Mode))),
 (N'Toolbelt.AssemblySha512',CONVERT(sql_variant,@TargetKnownHash)),(N'Toolbelt.ArtifactId',CONVERT(sql_variant,@TargetArtifactId));
 IF EXISTS(SELECT 1 FROM @SchemaConstructorMarkers expected WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e
  WHERE e.class=5 AND e.major_id=@SchemaConstructorId AND e.minor_id=0 AND e.name=expected.Name
   AND SQL_VARIANT_PROPERTY(e.value,N'BaseType')=SQL_VARIANT_PROPERTY(expected.Value,N'BaseType')
   AND SQL_VARIANT_PROPERTY(e.value,N'MaxLength')=SQL_VARIANT_PROPERTY(expected.Value,N'MaxLength')
   AND DATALENGTH(e.value)=DATALENGTH(expected.Value) AND CONVERT(varbinary(max),e.value)=CONVERT(varbinary(max),expected.Value)))
  THROW 55633,N'JSON Schema lifecycle: Constructor-Dependencytuple inkohärent.',1;
END;
