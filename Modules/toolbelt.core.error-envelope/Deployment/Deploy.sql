-- Deployment für toolbelt.core.error-envelope
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51411, N'DeploymentMode muss local oder central sein.', 1;

IF SCHEMA_ID(N'toolbelt_core') IS NULL
    EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');


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
    THROW 51410, N'Der Zielname toolbelt_core.USP_CaptureErrorEnvelope ist bereits durch ein frameworkfremdes Objekt belegt.', 1;
END;
GO

BEGIN TRANSACTION;
GO
:r ../Source/USP_CaptureErrorEnvelope.sql
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_CaptureErrorEnvelope')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.error-envelope'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_CaptureErrorEnvelope';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.error-envelope'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_CaptureErrorEnvelope';
END;

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_CaptureErrorEnvelope')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleVersion'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_CaptureErrorEnvelope';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_CaptureErrorEnvelope';
END;

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.error-envelope.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.error-envelope.DeploymentMode';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_updateextendedproperty @name = @VersionProperty, @value = N'1.0.0';
ELSE
    EXEC sys.sp_addextendedproperty @name = @VersionProperty, @value = N'1.0.0';

IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_updateextendedproperty @name = @ModeProperty, @value = @DeploymentMode;
ELSE
    EXEC sys.sp_addextendedproperty @name = @ModeProperty, @value = @DeploymentMode;

COMMIT TRANSACTION;
GO
