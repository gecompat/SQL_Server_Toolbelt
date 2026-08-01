-- Uninstall für toolbelt.core.error-envelope
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @ConfirmNoExternalConsumers bit = TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)');
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.error-envelope.DeploymentMode';
DECLARE @DeploymentMode nvarchar(16) =
    CONVERT(nvarchar(16), (
        SELECT ep.value FROM sys.extended_properties AS ep
        WHERE ep.class = 0 AND ep.name = @ModeProperty
    ));

IF @DeploymentMode = N'central' AND ISNULL(@ConfirmNoExternalConsumers, 0) <> 1
    THROW 51413, N'Der zentrale Uninstall erfordert ConfirmNoExternalConsumers=1.', 1;


IF OBJECT_ID(N'toolbelt_core.USP_CaptureErrorEnvelope', N'P') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_CaptureErrorEnvelope')
             AND ep.minor_id = 0
             AND ep.name = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.error-envelope'
       )
BEGIN
    THROW 51412, N'Das Objekt toolbelt_core.USP_CaptureErrorEnvelope ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;
END;

BEGIN TRANSACTION;
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_CaptureErrorEnvelope];

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.error-envelope.Version';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;
COMMIT TRANSACTION;
GO
