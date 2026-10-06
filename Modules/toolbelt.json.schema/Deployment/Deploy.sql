:On Error exit
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.',16,1);
 RETURN;
END;
IF OBJECT_ID(N'tempdb..#tbx_JsonSchema_DeployState',N'U') IS NOT NULL
 THROW 55633,N'JSON Schema lifecycle: reservierter Callerzustand belegt.',1;
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
DECLARE @Mode nvarchar(max)=N'$(DeploymentMode)',@Bits varbinary(max)=$(AssemblyBits),
 @Pass int=0,@Lock int,@Initial varbinary(max),@Current varbinary(max),@OwnerName sysname,@Sql nvarchar(max);
:r ./KnownArtifact.sql
:r ./State.sql
:r ../../toolbelt.json.core/Deployment/KnownArtifact.sql
:r ../../toolbelt.json.constructors/Deployment/KnownArtifact1_3.sql
IF CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
 THROW 55631,N'JSON Schema lifecycle: ungültiger Deploymentmodus.',1;
IF @Bits IS NULL OR HASHBYTES(N'SHA2_512',@Bits)<>@SchemaKnownHash
 THROW 55633,N'JSON Schema lifecycle: Targetbinary ist kein bekanntes qualifiziertes Artefakt.',1;
SET @SchemaInstalling=1;
BEGIN TRY
 WHILE @Pass<2
 BEGIN
  IF COALESCE(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
   OR COALESCE((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<150
   THROW 55630,N'JSON Schema lifecycle: SQL-Version oder Compatibility Level nicht unterstützt.',1;
:r ./Preflight.sql
  SELECT @Current=CONVERT(varbinary(max),(SELECT @SchemaVersion Version,@SchemaMode Mode,@SchemaAssemblyId AssemblyId,@SchemaAssemblyOwner AssemblyOwner,
   @SchemaOwner TargetOwner,@JsonCoreId CoreId,@JsonCoreOwner CoreOwner,@SchemaResultId ResultDependencyId,@SchemaResultVersion ResultVersion,
   @SchemaConstructorId ConstructorId,@SchemaConstructorVersion ConstructorVersion,@SchemaInstalledHash InstalledHash,
   @SchemaInstalledArtifactId InstalledArtifactId,SCHEMA_ID(N'toolbelt_json') SchemaId,
   OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema') PublicId,OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') BridgeId FOR XML RAW,BINARY BASE64));
  IF @Pass=1 AND @Current<>@Initial THROW 55637,N'JSON Schema lifecycle: Zustand hat sich unter Lock verändert.',1;
  IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
   OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
   OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE PROCEDURE'),0)<>1
   OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE FUNCTION'),0)<>1
   OR (SCHEMA_ID(N'toolbelt_json') IS NULL AND COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE SCHEMA'),0)<>1)
   OR (SCHEMA_ID(N'toolbelt_json') IS NOT NULL AND COALESCE(HAS_PERMS_BY_NAME(N'toolbelt_json',N'SCHEMA',N'ALTER'),0)<>1)
   OR (@SchemaAssemblyId IS NULL AND COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE ASSEMBLY'),0)<>1)
   OR (@SchemaAssemblyId IS NOT NULL AND @SchemaInstalledHash<>@SchemaKnownHash
    AND COALESCE(HAS_PERMS_BY_NAME(N'Toolbelt_JsonSchema',N'ASSEMBLY',N'ALTER'),0)<>1)
   THROW 55632,N'JSON Schema lifecycle: CLR-Konfiguration oder vorhandene Installationsrechte fehlen.',1;
  IF @Pass=0
  BEGIN
   SET @Initial=@Current;
   BEGIN TRANSACTION;
   EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.json.shared-core',@LockMode=N'Shared',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
   IF @Lock IS NULL OR @Lock<0 THROW 55637,N'JSON Schema lifecycle: gemeinsame Core-AppLock nicht verfügbar.',1;
   EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.json.schema',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
   IF @Lock IS NULL OR @Lock<0 THROW 55637,N'JSON Schema lifecycle: Modul-AppLock nicht verfügbar.',1;
  END;
  SET @Pass+=1;
 END;
 IF SCHEMA_ID(N'toolbelt_json') IS NULL
 BEGIN
  EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_json];';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_json';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'json',@level0type=N'SCHEMA',@level0name=N'toolbelt_json';
 END;
 IF @SchemaAssemblyId IS NULL
 BEGIN
  SET @OwnerName=USER_NAME(@SchemaOwner);
  IF @OwnerName IS NULL THROW 55632,N'JSON Schema lifecycle: vorhandener Owner nicht sichtbar.',1;
  SET @Sql=N'CREATE ASSEMBLY [Toolbelt_JsonSchema] AUTHORIZATION '+QUOTENAME(@OwnerName)+N' FROM '+CONVERT(nvarchar(max),@Bits,1)+N' WITH PERMISSION_SET=SAFE;';
  EXEC sys.sp_executesql @Sql;
 END;
 ELSE IF @SchemaInstalledHash<>@SchemaKnownHash
 BEGIN
  -- Nur die exakt bekannte Vorgängerversion; unveränderte CLR-Signatur/Core-
  -- Referenz. Eigene Slots, Rechte und ObjectIds bleiben im atomaren ALTER erhalten.
  SET @Sql=N'ALTER ASSEMBLY [Toolbelt_JsonSchema] FROM '+CONVERT(nvarchar(max),@Bits,1)+N' WITH PERMISSION_SET=SAFE;';
  EXEC sys.sp_executesql @Sql;
 END;
 CREATE TABLE #tbx_JsonSchema_DeployState(DeploymentMode nvarchar(16) NOT NULL);
 DECLARE @StateMode nvarchar(16)=CONVERT(nvarchar(16),@Mode);
 EXEC sys.sp_executesql N'INSERT #tbx_JsonSchema_DeployState(DeploymentMode) VALUES(@Mode);',N'@Mode nvarchar(16)',@Mode=@StateMode;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
:r ../Source/JsonSchemaBridge.sql
:r ../Source/USP_ValidateJsonSchema.sql
BEGIN TRY
 IF XACT_STATE()<>1 OR @@TRANCOUNT<>1 OR OBJECT_ID(N'tempdb..#tbx_JsonSchema_DeployState',N'U') IS NULL
  THROW 55638,N'JSON Schema lifecycle: eigene Deploymenttransaktion unvollständig.',1;
 DECLARE @Mode nvarchar(16)=(SELECT DeploymentMode FROM #tbx_JsonSchema_DeployState),@Name sysname,@Kind char(2),@Level varchar(16),@ObjectId int,@Property sysname,@Value sql_variant;
:r ./KnownArtifact.sql
:r ./State.sql
:r ../../toolbelt.json.core/Deployment/KnownArtifact.sql
:r ../../toolbelt.json.constructors/Deployment/KnownArtifact1_3.sql
 DECLARE @ObjectProperties TABLE(Name sysname PRIMARY KEY,Value sql_variant);
 DECLARE @SlotId int=1;
 WHILE @SlotId<=2
 BEGIN
  SELECT @Name=Name,@Kind=Kind FROM @SchemaSlots WHERE Id=@SlotId;
  SET @ObjectId=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(@Name),@Kind);
  IF @ObjectId IS NULL THROW 55638,N'JSON Schema lifecycle: Release-Slots unvollständig.',1;
  SET @Level=CASE @Kind WHEN 'P' THEN 'PROCEDURE' ELSE 'FUNCTION' END;
  INSERT @ObjectProperties VALUES(N'Toolbelt.ModuleId',N'toolbelt.json.schema'),(N'Toolbelt.ModuleVersion',N'1.0.1'),
   (N'Toolbelt.ContractVersion',N'1.0'),(N'Toolbelt.DeploymentMode',@Mode),
   (N'Toolbelt.SourceHash',CASE WHEN @Kind='P' THEN CONVERT(nvarchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@ObjectId))),2) ELSE CONVERT(nvarchar(64),@SchemaArtifactId) END);
  WHILE EXISTS(SELECT 1 FROM @ObjectProperties)
  BEGIN
   SELECT TOP(1) @Property=Name,@Value=Value FROM @ObjectProperties ORDER BY Name;
   IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=@Property)
    EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=@Level,@level1name=@Name;
   ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=@Level,@level1name=@Name;
   DELETE FROM @ObjectProperties WHERE Name=@Property;
  END;
  SET @SlotId+=1;
 END;
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.schema.Version')
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.schema.Version',@value=N'1.0.1';
 ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.json.schema.Version',@value=N'1.0.1';
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode')
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode',@value=@Mode;
 ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode',@value=@Mode;
 INSERT @SchemaAssemblyMarkers VALUES
 (N'Toolbelt.Managed',CONVERT(sql_variant,CONVERT(int,1))),
 (N'Toolbelt.ModuleId',CONVERT(sql_variant,CONVERT(nvarchar(64),N'toolbelt.json.schema'))),
 (N'Toolbelt.ModuleVersion',CONVERT(sql_variant,CONVERT(nvarchar(16),N'1.0.1'))),
 (N'Toolbelt.DeploymentMode',CONVERT(sql_variant,@Mode)),(N'Toolbelt.AssemblySha512',CONVERT(sql_variant,@SchemaKnownHash)),
 (N'Toolbelt.ArtifactId',CONVERT(sql_variant,@SchemaArtifactId));
 WHILE EXISTS(SELECT 1 FROM @SchemaAssemblyMarkers)
 BEGIN
  SELECT TOP(1) @Property=Name,@Value=Value FROM @SchemaAssemblyMarkers ORDER BY Name;
  IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema') AND minor_id=0 AND name=@Property)
   EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonSchema';
  ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonSchema';
  DELETE FROM @SchemaAssemblyMarkers WHERE Name=@Property;
 END;
 SET @SchemaInstalling=1;
:r ./Preflight.sql
 DROP TABLE #tbx_JsonSchema_DeployState;
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
