:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)'),@VersionProperty sysname=N'Toolbelt.Module.toolbelt.datetime.calendar-difference.Version',@ModeProperty sysname=N'Toolbelt.Module.toolbelt.datetime.calendar-difference.DeploymentMode';
IF @ConfirmNoExternalConsumers IS NULL THROW 51205,N'ConfirmNoExternalConsumers muss 0 oder 1 sein.',1;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@VersionProperty) RETURN;
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id=OBJECT_ID(N'toolbelt_datetime.TVF_CalendarDifference') AND referencing_id<>OBJECT_ID(N'toolbelt_datetime.TVF_CalendarDifference')) THROW 51206,N'Die Deinstallation wird durch eine same-database Dependency blockiert.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_CalendarDifference];
 EXEC sys.sp_dropextendedproperty @name=@VersionProperty;
 EXEC sys.sp_dropextendedproperty @name=@ModeProperty;
 IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_datetime')) AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=SCHEMA_ID(N'toolbelt_datetime') AND name=N'Toolbelt.Managed') DROP SCHEMA [toolbelt_datetime];
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
