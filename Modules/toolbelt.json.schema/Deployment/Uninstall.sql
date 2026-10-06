:On Error exit
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'JSON_SCHEMA_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Confirmation nvarchar(max)=N'$(ConfirmNoExternalConsumers)',@Mode nvarchar(max),
 @Pass int=0,@Lock int,@Initial varbinary(max),@Current varbinary(max);
:r ./KnownArtifact.sql
:r ./State.sql
:r ../../toolbelt.json.core/Deployment/KnownArtifact.sql
:r ../../toolbelt.json.constructors/Deployment/KnownArtifact1_3.sql
IF CONVERT(varbinary(max),@Confirmation) NOT IN(CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))
 THROW 55635,N'JSON Schema lifecycle: ungültige Consumer-Bestätigung.',1;
BEGIN TRY
 WHILE @Pass<2
 BEGIN
  IF COALESCE(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
   OR COALESCE((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<150
   THROW 55630,N'JSON Schema lifecycle: SQL-Version oder Compatibility Level nicht unterstützt.',1;
  SET @Mode=NULL;
  SELECT @Mode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode';
  IF @Mode IS NOT NULL AND CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
   THROW 55633,N'JSON Schema lifecycle: inkohärenter installierter Modus.',1;
:r ./Preflight.sql
  IF @Pass=0 AND @SchemaAssemblyId IS NULL RETURN;
  IF CONVERT(varbinary(max),@Mode)=CONVERT(varbinary(max),N'central') AND @Confirmation=N'0'
   THROW 55635,N'JSON Schema lifecycle: zentrale Consumer-Bestätigung fehlt.',1;
  SELECT @Current=CONVERT(varbinary(max),(SELECT @SchemaVersion Version,@SchemaMode Mode,@SchemaAssemblyId AssemblyId,
   @SchemaAssemblyOwner AssemblyOwner,@SchemaOwner TargetOwner,@JsonCoreId CoreId,@JsonCoreOwner CoreOwner,
   @SchemaInstalledHash InstalledHash,@SchemaInstalledArtifactId InstalledArtifactId,
   SCHEMA_ID(N'toolbelt_json') SchemaId,OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema') PublicId,
   OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal') BridgeId FOR XML RAW,BINARY BASE64));
  IF @Pass=1 AND @Current<>@Initial THROW 55637,N'JSON Schema lifecycle: Zustand hat sich unter Lock verändert.',1;
  IF COALESCE(HAS_PERMS_BY_NAME(N'toolbelt_json',N'SCHEMA',N'ALTER'),0)<>1
   OR COALESCE(HAS_PERMS_BY_NAME(N'Toolbelt_JsonSchema',N'ASSEMBLY',N'ALTER'),0)<>1
   THROW 55632,N'JSON Schema lifecycle: vorhandene Uninstallrechte fehlen.',1;
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
 DROP PROCEDURE [toolbelt_json].[USP_ValidateJsonSchema];
 DROP FUNCTION [toolbelt_json].[FT_ValidateJsonSchemaInternal];
 DROP ASSEMBLY [Toolbelt_JsonSchema] WITH NO DEPENDENTS;
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.json.schema.Version';
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.json.schema.DeploymentMode';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
