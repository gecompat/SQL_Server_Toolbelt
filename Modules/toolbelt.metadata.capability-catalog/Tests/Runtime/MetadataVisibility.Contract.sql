:on error exit
SET NOCOUNT ON;

DROP TABLE IF EXISTS #tbx_CapabilityCatalogDbo;
DROP TABLE IF EXISTS #tbx_CapabilityCatalogRestricted;

CREATE TABLE #tbx_CapabilityCatalogDbo
(
      ModuleId sysname COLLATE DATABASE_DEFAULT NOT NULL
    , ModuleVersion nvarchar(4000) COLLATE DATABASE_DEFAULT NULL
    , DeploymentMode nvarchar(4000) COLLATE DATABASE_DEFAULT NULL
    , MetadataStatus varchar(16) COLLATE DATABASE_DEFAULT NOT NULL
);

INSERT INTO #tbx_CapabilityCatalogDbo
(
    ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
)
SELECT ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
FROM toolbelt_metadata.VW_ModuleCapabilities;

CREATE TABLE #tbx_CapabilityCatalogRestricted
(
      ModuleId sysname COLLATE DATABASE_DEFAULT NOT NULL
    , ModuleVersion nvarchar(4000) COLLATE DATABASE_DEFAULT NULL
    , DeploymentMode nvarchar(4000) COLLATE DATABASE_DEFAULT NULL
    , MetadataStatus varchar(16) COLLATE DATABASE_DEFAULT NOT NULL
);

IF USER_ID(N'tbx_capability_reader') IS NOT NULL
    DROP USER [tbx_capability_reader];
CREATE USER [tbx_capability_reader] WITHOUT LOGIN;
GRANT SELECT ON OBJECT::toolbelt_metadata.VW_ModuleCapabilities
    TO [tbx_capability_reader];
DENY VIEW DEFINITION TO [tbx_capability_reader];

BEGIN TRY
    EXECUTE AS USER = N'tbx_capability_reader';
    INSERT INTO #tbx_CapabilityCatalogRestricted
    (
        ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
    )
    SELECT ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
    FROM toolbelt_metadata.VW_ModuleCapabilities;
    REVERT;
END TRY
BEGIN CATCH
    IF USER_NAME() = N'tbx_capability_reader'
        REVERT;
    DROP USER IF EXISTS [tbx_capability_reader];
    THROW;
END CATCH;

IF EXISTS
(
    SELECT ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
    FROM #tbx_CapabilityCatalogRestricted
    EXCEPT
    SELECT ModuleId, ModuleVersion, DeploymentMode, MetadataStatus
    FROM #tbx_CapabilityCatalogDbo
)
BEGIN
    DROP USER [tbx_capability_reader];
    THROW 52970, N'Die View machte unter eingeschränkter Metadata-Visibility zusätzliche Marker sichtbar.', 1;
END;

DROP USER [tbx_capability_reader];
DROP TABLE #tbx_CapabilityCatalogRestricted;
DROP TABLE #tbx_CapabilityCatalogDbo;

PRINT N'Capability Catalog Metadata-Visibility-Contract: erfolgreich';
GO
