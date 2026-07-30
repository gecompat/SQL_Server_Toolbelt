SET NOCOUNT ON;

DECLARE @CompatibilityLevel int = TRY_CONVERT(int, N'$(CompatibilityLevel)');
IF @CompatibilityLevel NOT IN (150, 160, 170)
    THROW 52940, N'CompatibilityLevel muss 150, 160 oder 170 sein.', 1;
IF (SELECT compatibility_level FROM sys.databases WHERE database_id = DB_ID())
       <> @CompatibilityLevel
    THROW 52941, N'Falscher Compatibility Level.', 1;

IF OBJECT_ID(N'toolbelt_metadata.VW_ModuleCapabilities', N'V') IS NULL
    THROW 52942, N'VW_ModuleCapabilities fehlt oder besitzt den falschen Typ.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_metadata.VW_ModuleCapabilities
       WHERE ModuleId = N'toolbelt.core.console-message'
         AND ModuleVersion = N'1.0.0'
         AND DeploymentMode = N'local'
         AND MetadataStatus = 'valid'
   )
   OR NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_metadata.VW_ModuleCapabilities
       WHERE ModuleId = N'toolbelt.metadata.capability-catalog'
         AND ModuleVersion = N'1.0.0'
         AND DeploymentMode = N'local'
         AND MetadataStatus = 'valid'
   )
BEGIN
    SELECT
          ModuleId
        , ModuleVersion = CONVERT(nvarchar(64), ModuleVersion)
        , DeploymentMode = CONVERT(nvarchar(16), DeploymentMode)
        , MetadataStatus
        , ModulePrefixIsValid =
              CASE
                  WHEN ModuleId COLLATE Latin1_General_100_BIN2
                           LIKE N'toolbelt.%' THEN 1
                  ELSE 0
              END
        , ModuleCharactersAreValid =
              CASE
                  WHEN REPLACE(ModuleId, N'-', N'')
                           COLLATE Latin1_General_100_BIN2
                           NOT LIKE N'%[^a-z0-9.]%' THEN 1
                  ELSE 0
              END
        , VersionDotCount =
              LEN(ModuleVersion) - LEN(REPLACE(ModuleVersion, N'.', N''))
        , VersionMajor = PARSENAME(ModuleVersion, 3)
        , VersionMinor = PARSENAME(ModuleVersion, 2)
        , VersionPatch = PARSENAME(ModuleVersion, 1)
        , VersionBaseType =
              (
                  SELECT
                      CONVERT
                      (
                          sysname,
                          SQL_VARIANT_PROPERTY(ep.value, 'BaseType')
                      )
                  FROM sys.extended_properties AS ep
                  WHERE ep.class = 0
                    AND ep.major_id = 0
                    AND ep.minor_id = 0
                    AND ep.name =
                          N'Toolbelt.Module.'
                          + ModuleId
                          + N'.Version'
              )
        , ModeBaseType =
              (
                  SELECT
                      CONVERT
                      (
                          sysname,
                          SQL_VARIANT_PROPERTY(ep.value, 'BaseType')
                      )
                  FROM sys.extended_properties AS ep
                  WHERE ep.class = 0
                    AND ep.major_id = 0
                    AND ep.minor_id = 0
                    AND ep.name =
                          N'Toolbelt.Module.'
                          + ModuleId
                          + N'.DeploymentMode'
              )
    FROM toolbelt_metadata.VW_ModuleCapabilities
    WHERE ModuleId IN
          (
                N'toolbelt.core.console-message'
              , N'toolbelt.metadata.capability-catalog'
          )
    ORDER BY ModuleId;

    THROW 52943, N'Gültige Toolbelt-Modulmarker werden falsch projiziert.', 1;
END;

EXEC sys.sp_addextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.incomplete.Version'
    , @value = N'1.0.0';
EXEC sys.sp_addextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.invalid-mode.Version'
    , @value = N'1.0.0';
EXEC sys.sp_addextendedproperty
      @name =
          N'Toolbelt.Module.toolbelt.synthetic.invalid-mode.DeploymentMode'
    , @value = N'remote';
EXEC sys.sp_addextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.invalid-version.Version'
    , @value = N'01.0.0';
EXEC sys.sp_addextendedproperty
      @name =
          N'Toolbelt.Module.toolbelt.synthetic.invalid-version.DeploymentMode'
    , @value = N'local';
EXEC sys.sp_addextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.invalid-type.Version'
    , @value = 1;
EXEC sys.sp_addextendedproperty
      @name =
          N'Toolbelt.Module.toolbelt.synthetic.invalid-type.DeploymentMode'
    , @value = N'local';
EXEC sys.sp_addextendedproperty
      @name = N'toolbelt.module.toolbelt.synthetic.bad-case.Version'
    , @value = N'1.0.0';
EXEC sys.sp_addextendedproperty
      @name = N'toolbelt.module.toolbelt.synthetic.bad-case.DeploymentMode'
    , @value = N'local';
EXEC sys.sp_addextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.object-level.Version'
    , @value = N'1.0.0'
    , @level0type = N'SCHEMA'
    , @level0name = N'toolbelt_metadata'
    , @level1type = N'VIEW'
    , @level1name = N'VW_ModuleCapabilities';

IF NOT EXISTS
   (
       SELECT 1
       FROM toolbelt_metadata.VW_ModuleCapabilities
       WHERE ModuleId = N'toolbelt.synthetic.incomplete'
         AND ModuleVersion = N'1.0.0'
         AND DeploymentMode IS NULL
         AND MetadataStatus = 'incomplete'
   )
    THROW 52944, N'Ein unvollständiger Marker wird nicht sichtbar ausgewiesen.', 1;

IF
   (
       SELECT COUNT(*)
       FROM toolbelt_metadata.VW_ModuleCapabilities
       WHERE ModuleId IN
             (
                   N'toolbelt.synthetic.invalid-mode'
                 , N'toolbelt.synthetic.invalid-version'
                 , N'toolbelt.synthetic.invalid-type'
                 , N'toolbelt.synthetic.bad-case'
             )
         AND MetadataStatus = 'invalid'
   ) <> 4
    THROW 52945, N'Ein ungültiger Marker wird nicht als invalid ausgewiesen.', 1;

IF EXISTS
   (
       SELECT 1
       FROM toolbelt_metadata.VW_ModuleCapabilities
       WHERE ModuleId = N'toolbelt.synthetic.object-level'
   )
    THROW 52946, N'Ein nicht datenbankweiter Marker wurde fälschlich projiziert.', 1;

EXEC sys.sp_dropextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.object-level.Version'
    , @level0type = N'SCHEMA'
    , @level0name = N'toolbelt_metadata'
    , @level1type = N'VIEW'
    , @level1name = N'VW_ModuleCapabilities';
EXEC sys.sp_dropextendedproperty
      @name = N'toolbelt.module.toolbelt.synthetic.bad-case.DeploymentMode';
EXEC sys.sp_dropextendedproperty
      @name = N'toolbelt.module.toolbelt.synthetic.bad-case.Version';
EXEC sys.sp_dropextendedproperty
      @name =
          N'Toolbelt.Module.toolbelt.synthetic.invalid-type.DeploymentMode';
EXEC sys.sp_dropextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.invalid-type.Version';
EXEC sys.sp_dropextendedproperty
      @name =
          N'Toolbelt.Module.toolbelt.synthetic.invalid-version.DeploymentMode';
EXEC sys.sp_dropextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.invalid-version.Version';
EXEC sys.sp_dropextendedproperty
      @name =
          N'Toolbelt.Module.toolbelt.synthetic.invalid-mode.DeploymentMode';
EXEC sys.sp_dropextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.invalid-mode.Version';
EXEC sys.sp_dropextendedproperty
      @name = N'Toolbelt.Module.toolbelt.synthetic.incomplete.Version';

PRINT N'Module Capability Catalog Contract-Prüfung: erfolgreich';
GO
