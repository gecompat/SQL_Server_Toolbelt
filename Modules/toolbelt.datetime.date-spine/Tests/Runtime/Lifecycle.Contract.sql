SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineCore', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineDay', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineIsoWeek', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_datetime.TVF_DateSpineMonth', N'IF') IS NULL
    THROW 52963, N'Die Date-Spine-Releaseobjekte fehlen.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name = N'Toolbelt.Module.toolbelt.datetime.date-spine.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name = N'Toolbelt.Module.toolbelt.datetime.date-spine.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 52964, N'Die Date-Spine-Modulmarker sind inkonsistent.', 1;

IF (SELECT COUNT(*)
    FROM sys.extended_properties AS properties
    JOIN sys.objects AS objects ON objects.object_id = properties.major_id
    JOIN sys.schemas AS schemas ON schemas.schema_id = objects.schema_id
    WHERE properties.class = 1 AND properties.minor_id = 0
      AND properties.name = N'Toolbelt.ModuleId'
      AND TRY_CONVERT(nvarchar(256), properties.value)
          = N'toolbelt.datetime.date-spine'
      AND schemas.name = N'toolbelt_datetime'
      AND objects.name IN
          (N'TVF_DateSpineCore', N'TVF_DateSpineDay',
           N'TVF_DateSpineIsoWeek', N'TVF_DateSpineMonth')) <> 4
    THROW 52965, N'Die Date-Spine-Objektmarker sind unvollständig.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name = N'Toolbelt.Module.toolbelt.core.generate-series.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0
         AND name = N'Toolbelt.Module.toolbelt.datetime.truncate.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
    THROW 52966, N'Die Date-Spine-Dependencies sind inkonsistent.', 1;

PRINT N'Date-Spine Lifecycle-Contract-Prüfung: erfolgreich';
GO
