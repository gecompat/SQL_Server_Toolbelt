-- Uninstall für toolbelt.core.second-session
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @ConfirmNoExternalConsumers bit = TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)');
DECLARE @AllowDataLoss bit = TRY_CONVERT(bit, N'$(AllowDataLoss)');
IF @ConfirmNoExternalConsumers IS NULL
    THROW 51647, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
IF @AllowDataLoss IS NULL
    THROW 51648, N'AllowDataLoss muss 0 oder 1 sein.', 1;

IF EXISTS
(
    SELECT 1
    FROM
    (
        VALUES
          (N'SecondSessionProvider')
        , (N'VW_SecondSessionProviders')
        , (N'USP_SecondSessionProbe')
        , (N'USP_DispatchWorkType')
        , (N'USP_ConfigureSecondSessionLoopback')
        , (N'USP_ExecuteWorkTypeInNewSession')
    ) AS o(ObjectName)
    WHERE OBJECT_ID(N'toolbelt_core.' + o.ObjectName) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties AS ep
          WHERE ep.class = 1
            AND ep.major_id = OBJECT_ID(N'toolbelt_core.' + o.ObjectName)
            AND ep.minor_id = 0
            AND ep.name = N'Toolbelt.ModuleId'
            AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.second-session'
      )
)
    THROW 51646, N'Mindestens ein Objekt ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 2;

DECLARE @DeploymentMode nvarchar(16) =
(
    SELECT CONVERT(nvarchar(16), value)
    FROM sys.extended_properties
    WHERE class = 0
      AND name = N'Toolbelt.Module.toolbelt.core.second-session.DeploymentMode'
);
IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
    THROW 51647, N'Zentraler Uninstall benötigt ConfirmNoExternalConsumers = 1.', 2;

DECLARE @ProviderHasData bit = 0;
IF OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U') IS NOT NULL
BEGIN
    EXEC sys.sp_executesql
          N'IF EXISTS (SELECT 1 FROM toolbelt_core.SecondSessionProvider) SET @HasData = 1;'
        , N'@HasData bit OUTPUT'
        , @HasData = @ProviderHasData OUTPUT;
END;
IF @ProviderHasData = 1 AND @AllowDataLoss <> 1
    THROW 51649, N'Die Providerkonfiguration enthält Daten; AllowDataLoss = 1 ist erforderlich.', 1;

BEGIN TRANSACTION;

DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_ExecuteWorkTypeInNewSession];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_ConfigureSecondSessionLoopback];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_DispatchWorkType];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_SecondSessionProbe];
DROP VIEW IF EXISTS [toolbelt_core].[VW_SecondSessionProviders];
DROP TABLE IF EXISTS [toolbelt_core].[SecondSessionProvider];

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.second-session.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.second-session.DeploymentMode';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

COMMIT TRANSACTION;
GO
