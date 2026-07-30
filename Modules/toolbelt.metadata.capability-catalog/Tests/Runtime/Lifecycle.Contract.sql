SET NOCOUNT ON;

IF OBJECT_ID(N'toolbelt_metadata.VW_ModuleCapabilities', N'V') IS NULL
    THROW 52947, N'VW_ModuleCapabilities fehlt.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name =
             N'Toolbelt.Module.toolbelt.metadata.capability-catalog.Version'
         AND TRY_CONVERT(nvarchar(64), value) = N'1.0.0'
   )
   OR NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name =
             N'Toolbelt.Module.toolbelt.metadata.capability-catalog.DeploymentMode'
         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central')
   )
    THROW 52947, N'Die Capability-Catalog-Modulmarker sind inkonsistent.', 1;

PRINT N'Module Capability Catalog Lifecycle-Contract-Prüfung: erfolgreich';
GO
