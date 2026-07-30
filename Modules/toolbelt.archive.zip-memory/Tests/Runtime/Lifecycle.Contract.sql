SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary', N'P') IS NULL
    THROW 51380, N'Lifecycle-Voraussetzung fehlt: Procedure ist nicht installiert.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name = N'Toolbelt.Module.toolbelt.archive.zip-memory.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
    THROW 51381, N'Der erwartete Modulversionsmarker fehlt.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name = N'Toolbelt.Module.toolbelt.archive.zip-memory.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 51382, N'Der erwartete Deployment-Mode-Marker fehlt.', 1;

PRINT N'ZIP Memory Lifecycle-Contract-Pruefung: erfolgreich';
GO
