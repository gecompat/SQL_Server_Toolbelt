:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @VersionProperty sysname=N'Toolbelt.Module.toolbelt.string.directional-trim.Version',@ModeProperty sysname=N'Toolbelt.Module.toolbelt.string.directional-trim.DeploymentMode',@DeploymentMode nvarchar(16)=LOWER(N'$(DeploymentMode)'),@InstalledVersion nvarchar(64),@DependencyVersion nvarchar(64),@ProductMajorVersion int=TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion'));
IF @ProductMajorVersion NOT IN(15,16,17) THROW 51210,N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.',1;
IF @DeploymentMode NOT IN(N'local',N'central') THROW 51211,N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.',1;
SELECT @DependencyVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.core.generate-series.Version';
IF @DependencyVersion<>N'1.0.0' OR OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigInt',N'IF') IS NULL THROW 51219,N'toolbelt.core.generate-series Version 1.0.0 muss vor diesem Modul in derselben Datenbank installiert sein.',1;
SELECT @InstalledVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@VersionProperty;
IF @InstalledVersion IS NOT NULL AND @InstalledVersion<>N'1.0.0' THROW 51213,N'Die installierte Modulversion ist diesem Deployment nicht bekannt.',1;
IF @InstalledVersion IS NULL AND (OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalNvarchar') IS NOT NULL OR OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalVarchar') IS NOT NULL) THROW 51214,N'Ein Zielobjekt stammt nicht aus einem bekannten Toolbelt-Release.',1;
IF SCHEMA_ID(N'toolbelt_string') IS NOT NULL AND HAS_PERMS_BY_NAME(N'toolbelt_string',N'SCHEMA',N'ALTER')<>1 THROW 51212,N'Für toolbelt_string fehlt ALTER.',1;
IF HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE FUNCTION')<>1 THROW 51212,N'In der Installationsdatenbank fehlt CREATE FUNCTION.',1;
BEGIN TRANSACTION;
DECLARE @LockResult int;
EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.string.directional-trim',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
IF @LockResult<0 THROW 51217,N'Ein paralleles Deployment dieses Moduls ist bereits aktiv.',1;
IF SCHEMA_ID(N'toolbelt_string') IS NULL
BEGIN
 EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_string];';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_string';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'string',@level0type=N'SCHEMA',@level0name=N'toolbelt_string';
END;
GO
:r ../Source/TVF_TrimDirectionalNvarchar.sql
:r ../Source/TVF_TrimDirectionalVarchar.sql
SET NOCOUNT ON;
BEGIN TRY
 DECLARE @VersionProperty sysname=N'Toolbelt.Module.toolbelt.string.directional-trim.Version',@ModeProperty sysname=N'Toolbelt.Module.toolbelt.string.directional-trim.DeploymentMode';
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@VersionProperty) EXEC sys.sp_updateextendedproperty @name=@VersionProperty,@value=N'1.0.0'; ELSE EXEC sys.sp_addextendedproperty @name=@VersionProperty,@value=N'1.0.0';
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@ModeProperty) EXEC sys.sp_updateextendedproperty @name=@ModeProperty,@value=N'$(DeploymentMode)'; ELSE EXEC sys.sp_addextendedproperty @name=@ModeProperty,@value=N'$(DeploymentMode)';
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
