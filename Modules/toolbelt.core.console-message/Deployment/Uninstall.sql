:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.core.console-message.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.core.console-message.DeploymentMode'
    , @DeploymentMode nvarchar(16);

IF @ConfirmNoExternalConsumers IS NULL
    THROW 51275, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name = @VersionProperty
   )
    RETURN;

SELECT @DeploymentMode = TRY_CONVERT(nvarchar(16), value)
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = @ModeProperty;

IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
    THROW 51275, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies
       WHERE referenced_id =
             OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage')
         AND referencing_id <>
             OBJECT_ID(N'toolbelt_core.USP_WriteConsoleMessage')
   )
    THROW 51276, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_WriteConsoleMessage];
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

    IF NOT EXISTS
       (
           SELECT 1 FROM sys.objects
           WHERE schema_id = SCHEMA_ID(N'toolbelt_core')
       )
       AND EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 3
             AND major_id = SCHEMA_ID(N'toolbelt_core')
             AND name = N'Toolbelt.Managed'
             AND TRY_CONVERT(bit, value) = 1
       )
        DROP SCHEMA [toolbelt_core];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
