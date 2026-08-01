-- Uninstall für toolbelt.core.work-type
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @ConfirmNoExternalConsumers bit = TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)');
DECLARE @AllowDataLoss bit = TRY_CONVERT(bit, N'$(AllowDataLoss)');
IF @ConfirmNoExternalConsumers IS NULL
    THROW 51545, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
IF @AllowDataLoss IS NULL
    THROW 51546, N'AllowDataLoss muss 0 oder 1 sein.', 1;

IF EXISTS
(
    SELECT 1
    FROM
    (
        VALUES
          (N'WorkType'), (N'VW_WorkTypes'), (N'USP_RegisterWorkType')
        , (N'USP_DisableWorkType'), (N'USP_ResolveWorkType')
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
            AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.work-type'
      )
)
    THROW 51547, N'Mindestens ein Objekt ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;

DECLARE @DeploymentMode nvarchar(16) =
(
    SELECT CONVERT(nvarchar(16), value)
    FROM sys.extended_properties
    WHERE class = 0
      AND name = N'Toolbelt.Module.toolbelt.core.work-type.DeploymentMode'
);
IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
    THROW 51548, N'Zentraler Uninstall benötigt ConfirmNoExternalConsumers = 1.', 1;

DECLARE @WorkTypeHasData bit = 0;
IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NOT NULL
BEGIN
    EXEC sys.sp_executesql
          N'IF EXISTS (SELECT 1 FROM toolbelt_core.WorkType) SET @HasData = 1;'
        , N'@HasData bit OUTPUT'
        , @HasData = @WorkTypeHasData OUTPUT;
END;
IF @WorkTypeHasData = 1 AND @AllowDataLoss <> 1
    THROW 51549, N'Die WorkType-Tabelle enthält Daten; AllowDataLoss = 1 ist erforderlich.', 1;

BEGIN TRANSACTION;

DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_ResolveWorkType];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_DisableWorkType];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_RegisterWorkType];
DROP VIEW IF EXISTS [toolbelt_core].[VW_WorkTypes];
DROP TABLE IF EXISTS [toolbelt_core].[WorkType];

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.work-type.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.work-type.DeploymentMode';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

COMMIT TRANSACTION;
GO
