-- ============================================================================
-- Read-only Lifecycle-Contract-Prüfung nach Deploy.sql
-- ============================================================================

SET NOCOUNT ON;

IF SCHEMA_ID(N'toolbelt_string') IS NULL
   OR OBJECT_ID(N'toolbelt_string.TVF_SplitByCharacters', N'IF') IS NULL
BEGIN
    THROW 52620, N'Schema oder Release-Funktion der Modulinstallation fehlt.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND name =
             N'Toolbelt.Module.toolbelt.string.split-characters.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties
          WHERE class = 0
            AND name =
                N'Toolbelt.Module.toolbelt.string.split-characters.DeploymentMode'
            AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
      )
BEGIN
    THROW 52621, N'Die Modulmarker fehlen oder sind inkonsistent.', 1;
END;

DECLARE @ObjectId int =
    OBJECT_ID(N'toolbelt_string.TVF_SplitByCharacters', N'IF');

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS properties
       WHERE properties.class = 1
         AND properties.major_id = @ObjectId
         AND properties.name = N'Toolbelt.ModuleId'
         AND TRY_CONVERT(nvarchar(256), properties.value)
               = N'toolbelt.string.split-characters'
   )
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties AS properties
          WHERE properties.class = 1
            AND properties.major_id = @ObjectId
            AND properties.name = N'Toolbelt.SourceHash'
            AND TRY_CONVERT(varchar(64), properties.value) =
                CONVERT
                (
                    varchar(64),
                    HASHBYTES
                    (
                        N'SHA2_256',
                        CONVERT(varbinary(max), OBJECT_DEFINITION(@ObjectId))
                    ),
                    2
                )
      )
BEGIN
    THROW 52622, N'Objektmarker oder diagnostischer Source-Hash sind inkonsistent.', 1;
END;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.sql_expression_dependencies AS dependencies
       WHERE dependencies.referencing_id = @ObjectId
         AND dependencies.referenced_id =
             OBJECT_ID(N'toolbelt_core.TVF_GenerateSeriesBigInt', N'IF')
   )
BEGIN
    THROW 52623, N'Die Dependency auf den portablen Generate-Series-Kern fehlt.', 1;
END;

PRINT N'Split-Characters Lifecycle-Contract-Prüfung: erfolgreich';
GO
