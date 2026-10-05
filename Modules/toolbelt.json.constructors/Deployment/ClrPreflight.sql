-- SQLCMD-Include im gemeinsamen Preflight, erneut unter derselben AppLock.
-- Keine Prozedur, keine eigene Mutation und keine Katalogzeile als Registryautorität.
IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_files',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_modules',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_references',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
 THROW 53622,N'JSON lifecycle: vollständige CLR-/Dependency-Metadatensicht fehlt.',1;
IF @CreatingSlots=1 OR CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.3.0')
BEGIN
 SELECT @JsonCoreExpectedMode=@Mode,@JsonCoreRequired=1;
:r ../../toolbelt.json.core/Deployment/Preflight.sql
END;
SELECT @AssemblyId=NULL,@AssemblyOwner=NULL,@InstalledHash=NULL;
SELECT @AssemblyId=a.assembly_id,@AssemblyOwner=a.principal_id,@InstalledHash=HASHBYTES(N'SHA2_512',f.content)
 FROM sys.assemblies a LEFT JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
 WHERE a.name=N'Toolbelt_JsonConstructors';
DECLARE @ExpectedInstalledHash varbinary(64)=CASE WHEN CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.3.0') THEN @TargetKnownHash ELSE @KnownHash END,
 @ExpectedInstalledArtifact varchar(64)=CASE WHEN CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.3.0') THEN @TargetArtifactId ELSE @KnownArtifactId END;
IF @Version IS NULL OR CONVERT(varbinary(max),@Version) NOT IN(CONVERT(varbinary(max),N'1.2.0'),CONVERT(varbinary(max),N'1.3.0'))
BEGIN
 IF @AssemblyId IS NOT NULL THROW 53624,N'JSON lifecycle: neuer Assemblyslot ist fremd belegt.',1;
END
ELSE
BEGIN
 IF @AssemblyId IS NULL OR @InstalledHash IS NULL OR @InstalledHash<>@ExpectedInstalledHash
  OR NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE assembly_id=@AssemblyId AND permission_set=1 AND is_user_defined=1
   AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_JsonConstructors'))
  THROW 53623,N'JSON lifecycle: installierte Assembly ist kein bekanntes SAFE-Artefakt.',1;
 -- Die geschlossene Offlinezeile ist eigenständig, nicht der Targethash oder clr_name.
 IF NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
  AND name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'int'
  AND SQL_VARIANT_PROPERTY(value,N'MaxLength')=4 AND DATALENGTH(value)=4 AND CONVERT(int,value)=1)
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
   AND name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar'
   AND SQL_VARIANT_PROPERTY(value,N'MaxLength')=128 AND DATALENGTH(value)=52
   AND CONVERT(varbinary(max),CONVERT(nvarchar(64),value))=CONVERT(varbinary(max),N'toolbelt.json.constructors'))
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
   AND name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar'
   AND SQL_VARIANT_PROPERTY(value,N'MaxLength')=32 AND DATALENGTH(value)=10
   AND CONVERT(varbinary(max),CONVERT(nvarchar(16),value))=CONVERT(varbinary(max),@Version))
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
   AND name=N'Toolbelt.DeploymentMode' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar'
   AND SQL_VARIANT_PROPERTY(value,N'MaxLength')=32 AND DATALENGTH(value)=DATALENGTH(@KnownMode)
   AND CONVERT(varbinary(max),CONVERT(nvarchar(16),value))=CONVERT(varbinary(max),@KnownMode))
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
   AND name=N'Toolbelt.AssemblySha512' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'varbinary'
   AND SQL_VARIANT_PROPERTY(value,N'MaxLength')=64 AND DATALENGTH(value)=64 AND CONVERT(varbinary(64),value)=@ExpectedInstalledHash)
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE class=5 AND major_id=@AssemblyId AND minor_id=0
   AND name=N'Toolbelt.ArtifactId' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'varchar'
   AND SQL_VARIANT_PROPERTY(value,N'MaxLength')=64 AND DATALENGTH(value)=64
   AND CONVERT(varbinary(max),CONVERT(varchar(64),value))=CONVERT(varbinary(max),@ExpectedInstalledArtifact))
  THROW 53623,N'JSON lifecycle: typisiertes Assemblymarkertuple ist inkohärent.',1;
 IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.assembly_modules m ON m.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
   WHERE s.Kind IN('FT','AF') AND (m.object_id IS NULL OR m.assembly_id<>@AssemblyId
    OR m.assembly_class IS NULL OR CONVERT(varbinary(max),m.assembly_class)<>CONVERT(varbinary(max),CASE s.Name
     WHEN N'FT_JsonEntryEvaluateInternal' THEN N'Toolbelt.JsonConstructors.JsonEntryEvaluateBridge'
     WHEN N'AGF_JsonArray' THEN N'Toolbelt.JsonConstructors.JsonArrayAggregate' ELSE N'Toolbelt.JsonConstructors.JsonObjectAggregate' END)
    OR (s.Kind='FT' AND (m.assembly_method IS NULL OR CONVERT(varbinary(max),m.assembly_method)<>CONVERT(varbinary(max),N'Evaluate')))
    OR (s.Kind='AF' AND m.assembly_method IS NOT NULL)))
  THROW 53623,N'JSON lifecycle: bekannte CLR-Bindings sind inkohärent.',1;
 IF EXISTS(SELECT 1 FROM @Parameters e WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p
  WHERE p.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(e.Slot)) AND p.parameter_id=e.Id
   AND CONVERT(varbinary(max),p.name)=CONVERT(varbinary(max),e.Name) AND p.system_type_id=e.TypeId
   AND p.user_type_id=p.system_type_id AND p.max_length=e.Length AND (p.parameter_id=0 OR p.is_output=0)))
  OR EXISTS(SELECT 1 FROM sys.parameters p JOIN @Slots s ON p.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
   WHERE s.Kind IN('FT','AF') AND NOT EXISTS(SELECT 1 FROM @Parameters e WHERE e.Slot=s.Name AND e.Id=p.parameter_id))
  THROW 53623,N'JSON lifecycle: CLR-Parametersignatur ist inkohärent.',1;
 IF EXISTS(SELECT 1 FROM @Columns e WHERE NOT EXISTS(SELECT 1 FROM sys.columns c
  WHERE c.object_id=OBJECT_ID(N'toolbelt_json.FT_JsonEntryEvaluateInternal') AND c.column_id=e.Id
   AND CONVERT(varbinary(max),c.name)=CONVERT(varbinary(max),e.Name) AND c.system_type_id=e.TypeId
   AND c.user_type_id=c.system_type_id AND c.max_length=e.Length AND c.is_nullable=1))
  OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_json.FT_JsonEntryEvaluateInternal'))<>8
  THROW 53623,N'JSON lifecycle: CLR-Bridgeresultschema ist inkohärent.',1;
END;
IF CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.3.0')
 AND NOT EXISTS(SELECT 1 FROM sys.assembly_references WHERE assembly_id=@AssemblyId AND referenced_assembly_id=@JsonCoreId)
 THROW 53623,N'JSON lifecycle: bekannte1.3-Assembly referenziert den erforderlichen Core nicht.',1;
-- Vollständiger Verbrauchercheck; fremde direkte CLR-Slots und Assemblyreferenzen ebenfalls.
IF @AssemblyId IS NOT NULL AND (EXISTS(SELECT 1 FROM sys.assembly_modules m WHERE m.assembly_id=@AssemblyId
 AND NOT EXISTS(SELECT 1 FROM @Slots s WHERE OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))=m.object_id))
 OR EXISTS(SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id=@AssemblyId))
 THROW 53626,N'JSON lifecycle: fremder Assemblyverbraucher blockiert Lifecycle.',1;
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN @Slots t ON d.referenced_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(t.Name))
 WHERE t.Id<=@KnownCount AND NOT EXISTS(SELECT 1 FROM @Slots s WHERE s.Id<=@KnownCount AND d.referencing_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))))
 THROW 53626,N'JSON lifecycle: fremder SQL-Verbraucher blockiert Lifecycle.',1;
IF @SchemaId IS NOT NULL
BEGIN
 SELECT @EffectiveOwner=MIN(COALESCE(o.principal_id,sc.principal_id))
  FROM @Slots s JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
  JOIN sys.schemas sc ON sc.schema_id=o.schema_id WHERE s.Id<=@KnownCount;
 IF @EffectiveOwner IS NULL SELECT @EffectiveOwner=principal_id FROM sys.schemas WHERE schema_id=@SchemaId;
 IF @EffectiveOwner IS NULL OR EXISTS(SELECT 1 FROM @Slots s JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(s.Name))
  JOIN sys.schemas sc ON sc.schema_id=o.schema_id WHERE s.Id<=@KnownCount AND COALESCE(o.principal_id,sc.principal_id)<>@EffectiveOwner)
  OR (@AssemblyId IS NOT NULL AND (@AssemblyOwner IS NULL OR @AssemblyOwner<>@EffectiveOwner))
  THROW 53623,N'JSON lifecycle: kohärente vorhandene Owner fehlen; keine Ownerreparatur.',1;
 -- Neue CLR-Objekte erben den Schemaowner. Ohne Owneränderung muss eine
 -- Migration bereits dazu kohärent sein; Repeat erhält explizite Owner.
 IF @CreatingSlots=1 AND @KnownCount<8 AND @KnownCount>0 AND @EffectiveOwner<>(SELECT principal_id FROM sys.schemas WHERE schema_id=@SchemaId)
  THROW 53623,N'JSON lifecycle: neue Slots würden inkohärente Owner erben.',1;
END;
IF (@CreatingSlots=1 OR CONVERT(varbinary(max),@Version)=CONVERT(varbinary(max),N'1.3.0'))
 AND (@JsonCoreOwner IS NULL OR @JsonCoreOwner<>COALESCE(@EffectiveOwner,USER_ID()))
 THROW 53623,N'JSON lifecycle: Core-/Constructorowner sind inkohärent; keine Ownerreparatur.',1;
