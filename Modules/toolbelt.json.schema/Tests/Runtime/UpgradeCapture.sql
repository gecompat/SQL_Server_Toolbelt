-- Eigene synthetische CI-Datenbank: bekannte 1.0.0 vor dem echten Upgrade.
SET NOCOUNT ON;
IF OBJECT_ID(N'dbo.TbxSchemaUpgradeSnapshot',N'U') IS NOT NULL
 THROW 55690,N'Schema upgrade fixture already exists.',20;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0
 AND name=N'Toolbelt.Module.toolbelt.json.schema.Version' AND CONVERT(nvarchar(16),value)=N'1.0.0')
 OR NOT EXISTS(SELECT 1 FROM sys.assemblies a JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
 WHERE a.name=N'Toolbelt_JsonSchema' AND HASHBYTES(N'SHA2_512',f.content)=
  0xf67e0f9f3f6e83acc304e8e60bc98ee2610018e654ac4eb6e430f98a9665f9a1c85e90ef97950d348fcc0fc6389de71b214d1f9101835fec9a305ef39c41af21)
 THROW 55690,N'Schema upgrade requires genuine known predecessor.',20;
EXEC sys.sp_addextendedproperty @name=N'Synthetic.SchemaUpgrade',@value=N'preserve',
 @level0type=N'SCHEMA',@level0name=N'toolbelt_json',@level1type=N'PROCEDURE',@level1name=N'USP_ValidateJsonSchema';
CREATE TABLE dbo.TbxSchemaUpgradeSnapshot(AssemblyId int NOT NULL,PublicId int NOT NULL,
 BridgeId int NOT NULL,AssemblyOwner int NULL,PublicOwner int NULL,BridgeOwner int NULL,
 PublicDefinition varbinary(32) NOT NULL,Permissions varbinary(max) NOT NULL,
 PreviousMetadata varbinary(max) NOT NULL);
DECLARE @AssemblyId int=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_JsonSchema'),
 @PublicId int=OBJECT_ID(N'toolbelt_json.USP_ValidateJsonSchema'),@BridgeId int=OBJECT_ID(N'toolbelt_json.FT_ValidateJsonSchemaInternal');
INSERT dbo.TbxSchemaUpgradeSnapshot
SELECT @AssemblyId,@PublicId,@BridgeId,(SELECT principal_id FROM sys.assemblies WHERE assembly_id=@AssemblyId),
 (SELECT principal_id FROM sys.objects WHERE object_id=@PublicId),(SELECT principal_id FROM sys.objects WHERE object_id=@BridgeId),
 HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@PublicId))),
 CONVERT(varbinary(max),(SELECT class,major_id,minor_id,grantee_principal_id,grantor_principal_id,type,state
 FROM sys.database_permissions WHERE (class=5 AND major_id=@AssemblyId) OR (class=1 AND major_id IN(@PublicId,@BridgeId))
 ORDER BY class,major_id,minor_id,grantee_principal_id,type FOR XML RAW,BINARY BASE64)),
 CONVERT(varbinary(max),(SELECT class,major_id,minor_id,name,CONVERT(varbinary(max),value) value
 FROM sys.extended_properties WHERE (class=5 AND major_id=@AssemblyId) OR (class=1 AND major_id IN(@PublicId,@BridgeId))
 OR (class=0 AND name LIKE N'Toolbelt.Module.toolbelt.json.schema.%') ORDER BY class,major_id,minor_id,name
 FOR XML RAW,BINARY BASE64));
GO
