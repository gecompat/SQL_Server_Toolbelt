SET NOCOUNT ON;

SELECT
      ModuleId
    , ModuleVersion
    , DeploymentMode
    , MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities
ORDER BY ModuleId;
GO
