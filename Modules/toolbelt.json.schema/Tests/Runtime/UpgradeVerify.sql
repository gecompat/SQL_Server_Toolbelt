-- Prüfung nach Abweisung/Rollback (Previous) sowie Upgrade/Repeat (Current).
SET NOCOUNT ON;
DECLARE @ExpectedVersion nvarchar(16)=N'$(SchemaExpectedVersion)',
 @AssemblyId int=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema'),
 @PublicId int=OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema'),@BridgeId int=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal');
IF @ExpectedVersion NOT IN(N'1.0.0',N'1.0.1') OR (SELECT COUNT(*) FROM dbo.TbxSchemaUpgradeSnapshot)<>1
 THROW 55690,N'Schema upgrade witness invalid.',21;
DECLARE @Permissions varbinary(max)=COALESCE(CONVERT(varbinary(max),(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state
 FROM sys.database_permissions WHERE (class=5 AND major_id=@AssemblyId) OR (class=1 AND major_id IN(@PublicId,@BridgeId))
 ORDER BY class,major_id,minor_id,grantee_principal_id,type FOR XML RAW,BINARY BASE64)),0x);
IF NOT EXISTS(SELECT 1 FROM dbo.TbxSchemaUpgradeSnapshot s
 JOIN sys.assemblies a ON a.assembly_id=s.AssemblyId
 JOIN sys.objects p ON p.object_id=s.PublicId JOIN sys.objects b ON b.object_id=s.BridgeId
 WHERE s.AssemblyId=@AssemblyId AND s.PublicId=@PublicId AND s.BridgeId=@BridgeId
 AND (a.principal_id=s.AssemblyOwner OR (a.principal_id IS NULL AND s.AssemblyOwner IS NULL))
 AND (p.principal_id=s.PublicOwner OR (p.principal_id IS NULL AND s.PublicOwner IS NULL))
 AND (b.principal_id=s.BridgeOwner OR (b.principal_id IS NULL AND s.BridgeOwner IS NULL))
 AND s.PublicDefinition=HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@PublicId)))
 AND s.Permissions=@Permissions)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0
  AND name=N'Toolbelt.Module.toolbelt.json.schema.Version' AND CONVERT(nvarchar(16),value)=@ExpectedVersion)
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@PublicId
  AND name=N'Synthetic.SchemaUpgrade' AND CONVERT(nvarchar(16),value)=N'preserve')
 THROW 55690,N'Schema upgrade changed identities, owners, permissions or annotations.',21;
IF @ExpectedVersion=N'1.0.0'
BEGIN
 DECLARE @Metadata varbinary(max)=CONVERT(varbinary(max),(SELECT class,major_id,minor_id,name,CONVERT(varbinary(max),value) value
 FROM sys.extended_properties WHERE (class=5 AND major_id=@AssemblyId) OR (class=1 AND major_id IN(@PublicId,@BridgeId))
 OR (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.json.schema.%') ORDER BY class,major_id,minor_id,name
 FOR XML RAW,BINARY BASE64));
 IF NOT EXISTS(SELECT 1 FROM dbo.TbxSchemaUpgradeSnapshot WHERE PreviousMetadata=@Metadata)
  OR NOT EXISTS(SELECT 1 FROM sys.assembly_files WHERE assembly_id=@AssemblyId AND file_id=1
   AND HASHBYTES(N'SHA2_512',content)=0xf67e0f9f3f6e83acc304e8e60bc98ee2610018e654ac4eb6e430f98a9665f9a1c85e90ef97950d348fcc0fc6389de71b214d1f9101835fec9a305ef39c41af21)
  THROW 55690,N'Schema failed upgrade did not restore exact predecessor.',21;
END;
PRINT N'PASS JSON_SCHEMA_GENUINE_UPGRADE_WITNESS';
GO
