:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)'),@VersionProperty sysname=N'Toolbelt.Module.toolbelt.conversion.uri-component.Version',@ModeProperty sysname=N'Toolbelt.Module.toolbelt.conversion.uri-component.DeploymentMode';
IF @ConfirmNoExternalConsumers IS NULL THROW 51225,N'ConfirmNoExternalConsumers muss 0 oder 1 sein.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@VersionProperty) RETURN;
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id IN(OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentEncode'),OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentDecode'),OBJECT_ID(N'toolbelt_conversion.SVF_UriComponentEncode'),OBJECT_ID(N'toolbelt_conversion.SVF_UriComponentDecode')) AND referencing_id NOT IN(OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentEncode'),OBJECT_ID(N'toolbelt_conversion.TVF_UriComponentDecode'),OBJECT_ID(N'toolbelt_conversion.SVF_UriComponentEncode'),OBJECT_ID(N'toolbelt_conversion.SVF_UriComponentDecode'))) THROW 51226,N'Die Deinstallation wird durch eine same-database Dependency blockiert.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DROP FUNCTION IF EXISTS [toolbelt_conversion].[SVF_UriComponentEncode];
 DROP FUNCTION IF EXISTS [toolbelt_conversion].[SVF_UriComponentDecode];
 DROP FUNCTION IF EXISTS [toolbelt_conversion].[TVF_UriComponentEncode];
 DROP FUNCTION IF EXISTS [toolbelt_conversion].[TVF_UriComponentDecode];
 EXEC sys.sp_dropextendedproperty @name=@VersionProperty;
 EXEC sys.sp_dropextendedproperty @name=@ModeProperty;
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
