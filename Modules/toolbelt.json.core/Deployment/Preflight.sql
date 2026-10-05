-- Pure SQLCMD-Include: keine Helper-USP, Mutation, Trust- oder Ownerreparatur.
-- KnownArtifact.sql deklariert den Scope. Aufruf vor/unter der gemeinsamen Lock.
IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_files',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_modules',N'OBJECT',N'SELECT'),0)<>1
 OR COALESCE(HAS_PERMS_BY_NAME(N'sys.assembly_references',N'OBJECT',N'SELECT'),0)<>1
 THROW 55622,N'JSON Core: vollständige Assemblymetadatensicht fehlt.',1;
SELECT @JsonCoreId=NULL,@JsonCoreOwner=NULL,@JsonCoreHash=NULL,@JsonCoreVersion=NULL,@JsonCoreStoredMode=NULL;
SELECT @JsonCoreVersion=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.core.Version';
SELECT @JsonCoreStoredMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.core.DeploymentMode';
SELECT @JsonCoreId=a.assembly_id,@JsonCoreOwner=a.principal_id,@JsonCoreHash=HASHBYTES(N'SHA2_512',f.content)
 FROM sys.assemblies a LEFT JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
 WHERE a.name=N'Toolbelt_JsonCore';
IF @JsonCoreId IS NULL
BEGIN
 IF @JsonCoreRequired=1 OR EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0
  AND name IN(N'Toolbelt.Module.toolbelt.json.core.Version',N'Toolbelt.Module.toolbelt.json.core.DeploymentMode'))
  THROW 55623,N'JSON Core: erforderliche bekannte Dependency fehlt oder ist inkohärent.',1;
END
ELSE
BEGIN
 IF @JsonCoreVersion IS NULL OR CONVERT(varbinary(max),@JsonCoreVersion)<>CONVERT(varbinary(max),N'1.0.0')
  OR @JsonCoreStoredMode IS NULL OR CONVERT(varbinary(max),@JsonCoreStoredMode)<>CONVERT(varbinary(max),@JsonCoreExpectedMode)
  OR @JsonCoreHash IS NULL OR @JsonCoreHash<>@JsonCoreKnownHash
  OR NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE assembly_id=@JsonCoreId AND is_user_defined=1 AND permission_set=1 AND is_visible=0
   AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_JsonCore'))
  OR (SELECT COUNT(*) FROM sys.assembly_files WHERE assembly_id=@JsonCoreId)<>1
  THROW 55623,N'JSON Core: keine kohärente bekannte technische SAFE-Assembly.',1;
 DELETE FROM @JsonCoreMarkers;
 INSERT @JsonCoreMarkers VALUES
 (N'Toolbelt.Managed',CONVERT(sql_variant,CONVERT(int,1))),
 (N'Toolbelt.ModuleId',CONVERT(sql_variant,CONVERT(nvarchar(64),N'toolbelt.json.core'))),
 (N'Toolbelt.ModuleVersion',CONVERT(sql_variant,CONVERT(nvarchar(16),N'1.0.0'))),
 (N'Toolbelt.DeploymentMode',CONVERT(sql_variant,CONVERT(nvarchar(16),@JsonCoreExpectedMode))),
 (N'Toolbelt.AssemblySha512',CONVERT(sql_variant,@JsonCoreKnownHash)),
 (N'Toolbelt.ArtifactId',CONVERT(sql_variant,@JsonCoreArtifactId));
 IF EXISTS(SELECT 1 FROM @JsonCoreMarkers expected WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e
  WHERE e.class=5 AND e.major_id=@JsonCoreId AND e.minor_id=0 AND e.name=expected.Name
   AND SQL_VARIANT_PROPERTY(e.value,N'BaseType')=SQL_VARIANT_PROPERTY(expected.Value,N'BaseType')
   AND SQL_VARIANT_PROPERTY(e.value,N'MaxLength')=SQL_VARIANT_PROPERTY(expected.Value,N'MaxLength')
   AND DATALENGTH(e.value)=DATALENGTH(expected.Value)
   AND CONVERT(varbinary(max),e.value)=CONVERT(varbinary(max),expected.Value)))
  THROW 55623,N'JSON Core: typisiertes bekanntes Markertuple ist inkohärent.',1;
 -- Die technische Dependency stellt keine eigenen oder fremden SQL-Slots bereit.
 IF EXISTS(SELECT 1 FROM sys.assembly_modules WHERE assembly_id=@JsonCoreId)
  THROW 55626,N'JSON Core: direkter SQL-Verbraucher blockiert den technischen Corevertrag.',1;
 IF @JsonCoreRemoving=1 AND EXISTS(SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id=@JsonCoreId)
  THROW 55626,N'JSON Core: verbleibende Assemblyverbraucher blockieren den Abbau.',1;
END;
