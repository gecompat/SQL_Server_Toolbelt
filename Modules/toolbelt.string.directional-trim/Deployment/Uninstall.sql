:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)'),@VersionProperty sysname=N'Toolbelt.Module.toolbelt.string.directional-trim.Version',@ModeProperty sysname=N'Toolbelt.Module.toolbelt.string.directional-trim.DeploymentMode';
IF @ConfirmNoExternalConsumers IS NULL THROW 51215,N'ConfirmNoExternalConsumers muss 0 oder 1 sein.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@VersionProperty) RETURN;
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id IN(OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalNvarchar'),OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalVarchar')) AND referencing_id NOT IN(OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalNvarchar'),OBJECT_ID(N'toolbelt_string.TVF_TrimDirectionalVarchar'))) THROW 51216,N'Die Deinstallation wird durch eine same-database Dependency blockiert.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DROP FUNCTION IF EXISTS [toolbelt_string].[TVF_TrimDirectionalNvarchar];
 DROP FUNCTION IF EXISTS [toolbelt_string].[TVF_TrimDirectionalVarchar];
 EXEC sys.sp_dropextendedproperty @name=@VersionProperty;
 EXEC sys.sp_dropextendedproperty @name=@ModeProperty;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
