SET NOCOUNT ON;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_metadata.VW_ModuleCapabilities
       WHERE ModuleId = N'toolbelt.metadata.capability-catalog'
         AND ModuleVersion = N'1.0.0'
         AND DeploymentMode = N'central'
         AND MetadataStatus = 'valid'
   )
    THROW 52948, N'Der zentrale Capability-Catalog-Aufruf ist fehlgeschlagen.', 1;

PRINT N'Module Capability Catalog Central-Contract-Prüfung: erfolgreich';
GO
