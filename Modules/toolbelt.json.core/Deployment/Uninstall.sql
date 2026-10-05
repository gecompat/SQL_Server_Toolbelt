:On Error exit
IF @@TRANCOUNT>0
BEGIN
 RAISERROR(N'JSON_CORE_CALLER_TRANSACTION: aktive Callertransaktion ausgeschlossen.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Confirmation nvarchar(max)=N'$(ConfirmNoExternalConsumers)',@Pass int=0,@Lock int,@InitialId int,@InitialOwner int,@InitialMode varbinary(max);
:r ./KnownArtifact.sql
IF CONVERT(varbinary(max),@Confirmation) NOT IN(CONVERT(varbinary(max),N'0'),CONVERT(varbinary(max),N'1'))
 THROW 55625,N'JSON Core: ungültige Consumer-Bestätigung.',1;
SELECT @JsonCoreRemoving=1,@JsonCoreRequired=0;
BEGIN TRY
 WHILE @Pass<2
 BEGIN
  IF COALESCE(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
   OR COALESCE((SELECT compatibility_level FROM sys.databases WHERE database_id=DB_ID()),0)<150
   THROW 55620,N'JSON Core: SQL-Version oder Compatibility Level nicht unterstützt.',1;
  SELECT @JsonCoreExpectedMode=NULL;
  SELECT @JsonCoreExpectedMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
   WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.core.DeploymentMode';
  IF @JsonCoreExpectedMode IS NOT NULL AND CONVERT(varbinary(max),@JsonCoreExpectedMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
   THROW 55623,N'JSON Core: inkohärenter installierter Modus.',1;
:r ./Preflight.sql
  IF @Pass=0 AND @JsonCoreId IS NULL RETURN;
  IF CONVERT(varbinary(max),@JsonCoreExpectedMode)=CONVERT(varbinary(max),N'central') AND @Confirmation=N'0'
   THROW 55625,N'JSON Core: zentrale Consumer-Bestätigung fehlt.',1;
  IF @Pass=1 AND (COALESCE(@JsonCoreId,-1)<>@InitialId OR COALESCE(@JsonCoreOwner,-1)<>@InitialOwner
   OR COALESCE(CONVERT(varbinary(max),@JsonCoreExpectedMode),0x)<>@InitialMode)
   THROW 55627,N'JSON Core: Assemblyidentität hat sich unter Lock verändert.',1;
  IF COALESCE(HAS_PERMS_BY_NAME(N'Toolbelt_JsonCore',N'ASSEMBLY',N'ALTER'),0)<>1
   THROW 55622,N'JSON Core: vorhandenes Assembly-ALTER-Recht fehlt.',1;
  IF @Pass=0
  BEGIN
   SELECT @InitialId=@JsonCoreId,@InitialOwner=@JsonCoreOwner,@InitialMode=CONVERT(varbinary(max),@JsonCoreExpectedMode);
   BEGIN TRANSACTION;
   EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.json.shared-core',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
   IF @Lock IS NULL OR @Lock<0 THROW 55627,N'JSON Core: gemeinsame AppLock nicht verfügbar.',1;
  END;
  SET @Pass+=1;
 END;
 DROP ASSEMBLY [Toolbelt_JsonCore] WITH NO DEPENDENTS;
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.json.core.Version';
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.json.core.DeploymentMode';
 COMMIT;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK;
 THROW;
END CATCH;
GO
