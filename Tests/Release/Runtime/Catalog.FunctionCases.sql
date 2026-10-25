-- Fixed SELECT profile; metadata visibility may legitimately restrict visible rows.
DECLARE @ExpectedApiCount int=1;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name LIKE N'Toolbelt.Module.toolbelt.contoso.%') THROW 52097,N'Catalog synthetic marker collision.',12;
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.contoso.catalog-valid.Version',@value=N'1.2.3';
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.contoso.catalog-valid.DeploymentMode',@value=N'local';
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.contoso.catalog-incomplete.Version',@value=N'2.0.0';
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.contoso.catalog-invalid.Version',@value=N'broken';
EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.contoso.catalog-invalid.DeploymentMode',@value=N'central';
DECLARE @CatalogMode nvarchar(4000)=CASE RIGHT(DB_NAME(),2) WHEN N'_l' THEN N'local' WHEN N'_c' THEN N'central' END; IF @CatalogMode IS NULL THROW 52097,N'Catalog context guard.',12;
DECLARE @CatalogExpected table(ModuleId sysname COLLATE Latin1_General_100_BIN2,ModuleVersion nvarchar(4000) COLLATE Latin1_General_100_BIN2,DeploymentMode nvarchar(4000) COLLATE Latin1_General_100_BIN2,MetadataStatus varchar(16) COLLATE Latin1_General_100_BIN2);
INSERT @CatalogExpected VALUES
(N'toolbelt.core.result-table',N'1.0.0',@CatalogMode,'valid'),
(N'toolbelt.metadata.capability-catalog',N'1.0.0',@CatalogMode,'valid'),
(N'toolbelt.contoso.catalog-valid',N'1.2.3',N'local','valid'),
(N'toolbelt.contoso.catalog-incomplete',N'2.0.0',NULL,'incomplete'),
(N'toolbelt.contoso.catalog-invalid',N'broken',N'central','invalid');
IF EXISTS(SELECT ModuleId COLLATE Latin1_General_100_BIN2,ModuleVersion COLLATE Latin1_General_100_BIN2,DeploymentMode COLLATE Latin1_General_100_BIN2,MetadataStatus COLLATE Latin1_General_100_BIN2 FROM toolbelt_metadata.VW_ModuleCapabilities EXCEPT SELECT ModuleId,ModuleVersion,DeploymentMode,MetadataStatus FROM @CatalogExpected) OR EXISTS(SELECT ModuleId,ModuleVersion,DeploymentMode,MetadataStatus FROM @CatalogExpected EXCEPT SELECT ModuleId COLLATE Latin1_General_100_BIN2,ModuleVersion COLLATE Latin1_General_100_BIN2,DeploymentMode COLLATE Latin1_General_100_BIN2,MetadataStatus COLLATE Latin1_General_100_BIN2 FROM toolbelt_metadata.VW_ModuleCapabilities) OR (SELECT COUNT(*) FROM toolbelt_metadata.VW_ModuleCapabilities)<>5 THROW 52097,N'Catalog fixed marker oracle.',12;
INSERT @Apis VALUES
(1,N'toolbelt_metadata',N'VW_ModuleCapabilities','SELECT',N'SELECT * FROM toolbelt_metadata.VW_ModuleCapabilities;',N'DECLARE @CatalogMode nvarchar(4000)=CASE RIGHT(DB_NAME(),2) WHEN N''_l'' THEN N''local'' WHEN N''_c'' THEN N''central'' END; IF @CatalogMode IS NULL THROW 52097,N''Catalog context guard.'',12;
DECLARE @CatalogExpected table(ModuleId sysname COLLATE Latin1_General_100_BIN2,ModuleVersion nvarchar(4000) COLLATE Latin1_General_100_BIN2,DeploymentMode nvarchar(4000) COLLATE Latin1_General_100_BIN2,MetadataStatus varchar(16) COLLATE Latin1_General_100_BIN2);
INSERT @CatalogExpected VALUES
(N''toolbelt.core.result-table'',N''1.0.0'',@CatalogMode,''valid''),
(N''toolbelt.metadata.capability-catalog'',N''1.0.0'',@CatalogMode,''valid''),
(N''toolbelt.contoso.catalog-valid'',N''1.2.3'',N''local'',''valid''),
(N''toolbelt.contoso.catalog-incomplete'',N''2.0.0'',NULL,''incomplete''),
(N''toolbelt.contoso.catalog-invalid'',N''broken'',N''central'',''invalid'');
IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N''DATABASE'',N''VIEW DEFINITION''),0)<>0 THROW 52097,N''Catalog unexpected broad visibility.'',12;
IF EXISTS(SELECT ModuleId COLLATE Latin1_General_100_BIN2,ModuleVersion COLLATE Latin1_General_100_BIN2,DeploymentMode COLLATE Latin1_General_100_BIN2,MetadataStatus COLLATE Latin1_General_100_BIN2 FROM toolbelt_metadata.VW_ModuleCapabilities EXCEPT SELECT ModuleId,ModuleVersion,DeploymentMode,MetadataStatus FROM @CatalogExpected) THROW 52097,N''Catalog restricted subset oracle.'',12;
');
INSERT @Denied VALUES
(1,N'toolbelt_core',N'USP_PrepareResultTable','EXECUTE',N'EXEC toolbelt_core.USP_PrepareResultTable @Hilfe=1;');
