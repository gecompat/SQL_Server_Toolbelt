:On Error exit

-- ============================================================================
-- Zweck:     Kontrollierte Deinstallation von toolbelt.datetime.date-spine
-- Modus:     SQLCMD
-- Parameter: ConfirmNoExternalConsumers=0|1
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionPropertyName sysname =
          N'Toolbelt.Module.toolbelt.datetime.date-spine.Version'
    , @ModePropertyName sysname =
          N'Toolbelt.Module.toolbelt.datetime.date-spine.DeploymentMode'
    , @InstalledVersion nvarchar(64)
    , @DeploymentMode nvarchar(16)
    , @ReferencingSchema sysname
    , @ReferencingObject sysname;

IF @ConfirmNoExternalConsumers IS NULL
    THROW 51805, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0 AND ep.major_id = 0 AND ep.minor_id = 0
  AND ep.name = @VersionPropertyName;

SELECT @DeploymentMode = TRY_CONVERT(nvarchar(16), ep.value)
FROM sys.extended_properties AS ep
WHERE ep.class = 0 AND ep.major_id = 0 AND ep.minor_id = 0
  AND ep.name = @ModePropertyName;

IF @InstalledVersion IS NULL
BEGIN
    PRINT N'toolbelt.datetime.date-spine ist nicht als installiert registriert; keine Änderung erforderlich.';
    RETURN;
END;
IF @InstalledVersion COLLATE Latin1_General_100_BIN2 <> N'1.0.0'
    THROW 51803, N'Die installierte Modulversion ist diesem Uninstall-Skript nicht bekannt.', 1;
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51803, N'Der registrierte Deployment-Modus fehlt oder ist ungültig.', 1;
IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
    THROW 51805, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 1;

SELECT TOP (1)
      @ReferencingSchema = OBJECT_SCHEMA_NAME(dependencies.referencing_id)
    , @ReferencingObject = OBJECT_NAME(dependencies.referencing_id)
FROM sys.sql_expression_dependencies AS dependencies
WHERE dependencies.referenced_id IN
      (
          OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineCore'),
          OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineDay'),
          OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineIsoWeek'),
          OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineMonth')
      )
  AND dependencies.referencing_id NOT IN
      (
          OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineCore'),
          OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineDay'),
          OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineIsoWeek'),
          OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineMonth')
      )
ORDER BY OBJECT_SCHEMA_NAME(dependencies.referencing_id)
             COLLATE Latin1_General_100_BIN2,
         OBJECT_NAME(dependencies.referencing_id)
             COLLATE Latin1_General_100_BIN2;

IF @ReferencingObject IS NOT NULL
BEGIN
    DECLARE @DependencyMessage nvarchar(2048) =
        N'Die Deinstallation wird durch ' + QUOTENAME(@ReferencingSchema)
        + N'.' + QUOTENAME(@ReferencingObject) + N' blockiert.';
    THROW 51806, @DependencyMessage, 1;
END;

BEGIN TRY
    BEGIN TRANSACTION;
    DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_DateSpineDay];
    DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_DateSpineIsoWeek];
    DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_DateSpineMonth];
    DROP FUNCTION IF EXISTS [toolbelt_datetime].[TVF_DateSpineCore];
    EXEC sys.sp_dropextendedproperty @name = @VersionPropertyName;
    EXEC sys.sp_dropextendedproperty @name = @ModePropertyName;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
