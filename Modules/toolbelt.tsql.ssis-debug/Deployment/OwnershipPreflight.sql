-- Gemeinsamer Preflight vor und unter der Application Lock; keine Mutation.
IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
 THROW 50000,N'TBX_SSISDBG_catalog_visibility: Vollständige Lifecycle-Metadatensicht fehlt.',1;
SET @InstalledVersion=NULL;
SELECT @InstalledVersion=TRY_CONVERT(nvarchar(64),ep.value)
FROM sys.extended_properties AS ep WITH (NOLOCK)
WHERE ep.class=0 AND ep.major_id=0 AND ep.minor_id=0
 AND ep.name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version';
IF EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=0 AND ep.major_id=0 AND ep.minor_id=0 AND ep.name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version')
 AND NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=0 AND ep.major_id=0 AND ep.minor_id=0 AND ep.name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version' AND SQL_VARIANT_PROPERTY(ep.value,'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'1.0.0'))
 THROW 50000,N'TBX_SSISDBG_lifecycle_version: Unbekannter installierter Modulstand.',1;
SET @AssemblyId=(SELECT assembly_id FROM sys.assemblies AS a WITH (NOLOCK) WHERE a.name=N'Toolbelt_Tsql_SsisDebug');
IF @InstalledVersion IS NULL AND (@AssemblyId IS NOT NULL OR OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow') IS NOT NULL OR OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlowInternal') IS NOT NULL)
 THROW 50000,N'TBX_SSISDBG_lifecycle_collision: Namen ohne vollständige Modulownership belegt.',1;
IF @InstalledVersion IS NOT NULL
BEGIN
 IF @AssemblyId IS NULL OR OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow',N'P') IS NULL OR OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlowInternal',N'PC') IS NULL
  THROW 50000,N'TBX_SSISDBG_lifecycle_collision: Unklare Teilinstallation.',1;
 IF EXISTS
 (SELECT 1 FROM (VALUES(OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow')),(OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlowInternal'))) AS slot(id)
  WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=1 AND ep.major_id=slot.id AND ep.minor_id=0 AND ep.name=N'Toolbelt.Managed' AND TRY_CONVERT(int,ep.value)=1)
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=1 AND ep.major_id=slot.id AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'toolbelt.tsql.ssis-debug'))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=1 AND ep.major_id=slot.id AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'1.0.0')))
  THROW 50000,N'TBX_SSISDBG_lifecycle_collision: Objektmarker abweichend.',1;
 IF NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=5 AND ep.major_id=@AssemblyId AND ep.minor_id=0 AND ep.name=N'Toolbelt.Managed' AND TRY_CONVERT(int,ep.value)=1)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=5 AND ep.major_id=@AssemblyId AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'toolbelt.tsql.ssis-debug'))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=5 AND ep.major_id=@AssemblyId AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),ep.value))=CONVERT(varbinary(max),N'1.0.0'))
  THROW 50000,N'TBX_SSISDBG_lifecycle_collision: Assemblymarker abweichend.',1;
END;
IF @AssemblyId IS NOT NULL AND (EXISTS(SELECT 1 FROM sys.assembly_references AS r WITH (NOLOCK) WHERE r.referenced_assembly_id=@AssemblyId)
 OR EXISTS(SELECT 1 FROM sys.assembly_modules AS m WITH (NOLOCK) WHERE m.assembly_id=@AssemblyId AND m.object_id<>OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlowInternal')))
 THROW 50000,N'TBX_SSISDBG_lifecycle_consumer: Fremder Assemblyverbraucher vorhanden.',1;
IF @Removing=1 AND EXISTS
 (SELECT 1 FROM sys.sql_expression_dependencies AS d WITH (NOLOCK)
  WHERE d.referenced_id IN(OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow'),OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlowInternal'))
  AND d.referencing_id NOT IN(OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlow'),OBJECT_ID(N'toolbelt_tsql.USP_ExplainSsisDataFlowInternal')))
 THROW 50000,N'TBX_SSISDBG_lifecycle_consumer: Fremder SQL-Verbraucher vorhanden.',1;
