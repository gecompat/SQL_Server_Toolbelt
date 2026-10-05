:On Error exit
-- Technischer Core1.0: separat, known-exact, keine Dependency-/Trustbeschaffung.
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'JSON_CORE_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Mode nvarchar(max)=N'$(DeploymentMode)',@Bits varbinary(max)=$(AssemblyBits),
 @Pass int=0,@Lock int,@InitialId int,@InitialOwner int,@InitialTargetOwner int,@Owner int,@OwnerName sysname,@Sql nvarchar(max),@Marker sysname,@Value sql_variant,@ModeValue nvarchar(16);
:r ./KnownArtifact.sql
IF CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
 THROW 55621,N'JSON Core: ungültiger Deploymentmodus.',1;
IF @Bits IS NULL OR HASHBYTES(N'SHA2_512',@Bits)<>@JsonCoreKnownHash
 THROW 55623,N'JSON Core: Targetbinary ist kein bekanntes qualifiziertes Artefakt.',1;
SELECT @JsonCoreExpectedMode=@Mode,@JsonCoreRequired=0;
SET @ModeValue=CONVERT(nvarchar(16),@Mode);
BEGIN TRY
 WHILE @Pass<2
 BEGIN
  IF COALESCE(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
   OR COALESCE((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<150
   THROW 55620,N'JSON Core: SQL-Version oder Compatibility Level nicht unterstützt.',1;
:r ./Preflight.sql
  IF @Pass=1 AND (COALESCE(@JsonCoreId,-1)<>COALESCE(@InitialId,-1) OR COALESCE(@JsonCoreOwner,-1)<>COALESCE(@InitialOwner,-1))
   THROW 55627,N'JSON Core: Assemblyidentität hat sich unter Lock verändert.',1;
  IF @JsonCoreId IS NULL
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
    OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
    OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE ASSEMBLY'),0)<>1
    THROW 55622,N'JSON Core: CLR-Konfiguration oder vorhandenes CREATE-ASSEMBLY-Recht fehlt.',1;
   SELECT @Owner=COALESCE((SELECT principal_id FROM sys.schemas WHERE name=N'toolbelt_json'),USER_ID());
   IF @Owner IS NULL THROW 55622,N'JSON Core: vorhandener Zielowner ist nicht sichtbar.',1;
   IF @Pass=1 AND @Owner<>@InitialTargetOwner THROW 55627,N'JSON Core: Zielowner hat sich unter Lock verändert.',1;
  END;
  IF @Pass=0
  BEGIN
   SELECT @InitialId=@JsonCoreId,@InitialOwner=@JsonCoreOwner,@InitialTargetOwner=@Owner;
   BEGIN TRANSACTION;
   EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.json.shared-core',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
   IF @Lock IS NULL OR @Lock<0 THROW 55627,N'JSON Core: gemeinsame AppLock nicht verfügbar.',1;
  END;
  SET @Pass+=1;
 END;
 IF @JsonCoreId IS NULL
 BEGIN
  SET @OwnerName=USER_NAME(@Owner);
  IF @OwnerName IS NULL THROW 55622,N'JSON Core: vorhandener Zielowner ist nicht sichtbar.',1;
  SET @Sql=N'CREATE ASSEMBLY [Toolbelt_JsonCore] AUTHORIZATION '+QUOTENAME(@OwnerName)+N' FROM '+CONVERT(nvarchar(max),@Bits,1)+N' WITH PERMISSION_SET=SAFE;';
  EXEC sys.sp_executesql @Sql;
  ALTER ASSEMBLY [Toolbelt_JsonCore] WITH VISIBILITY=OFF;
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.json.core.Version',@value=N'1.0.0';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.json.core.DeploymentMode',@value=@ModeValue;
  INSERT @JsonCoreMarkers VALUES
  (N'Toolbelt.Managed',CONVERT(sql_variant,CONVERT(int,1))),
  (N'Toolbelt.ModuleId',CONVERT(sql_variant,CONVERT(nvarchar(64),N'toolbelt.json.core'))),
  (N'Toolbelt.ModuleVersion',CONVERT(sql_variant,CONVERT(nvarchar(16),N'1.0.0'))),
  (N'Toolbelt.DeploymentMode',CONVERT(sql_variant,CONVERT(nvarchar(16),@Mode))),
  (N'Toolbelt.AssemblySha512',CONVERT(sql_variant,@JsonCoreKnownHash)),
  (N'Toolbelt.ArtifactId',CONVERT(sql_variant,@JsonCoreArtifactId));
  WHILE EXISTS(SELECT 1 FROM @JsonCoreMarkers)
  BEGIN
   SELECT TOP(1) @Marker=Name,@Value=Value FROM @JsonCoreMarkers ORDER BY Name;
   EXEC sys.sp_addextendedproperty @name=@Marker,@value=@Value,@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_JsonCore';
   DELETE FROM @JsonCoreMarkers WHERE Name=@Marker;
  END;
 END;
 SELECT @JsonCoreRequired=1;
:r ./Preflight.sql
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
