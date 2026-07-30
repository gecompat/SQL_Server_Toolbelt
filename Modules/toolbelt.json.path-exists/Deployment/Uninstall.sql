:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.json.path-exists.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.json.path-exists.DeploymentMode';

IF @ConfirmNoExternalConsumers IS NULL
    THROW 51265,
          N'ConfirmNoExternalConsumers muss 0 oder 1 sein.',
          1;
IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name = @VersionProperty
   )
    RETURN;

IF EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies
       WHERE referenced_id =
             OBJECT_ID(N'toolbelt_json.TVF_JsonPathExists')
         AND referencing_id <>
             OBJECT_ID(N'toolbelt_json.TVF_JsonPathExists')
   )
    THROW 51266,
          N'Die Deinstallation wird durch eine same-database Dependency blockiert.',
          1;

BEGIN TRY
    BEGIN TRANSACTION;

    DROP FUNCTION IF EXISTS [toolbelt_json].[TVF_JsonPathExists];

    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
