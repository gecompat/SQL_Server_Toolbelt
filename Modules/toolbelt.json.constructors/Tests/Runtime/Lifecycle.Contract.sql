SET NOCOUNT ON;
DECLARE @Names TABLE(Name sysname);
INSERT @Names VALUES(N'USP_JsonArray'),(N'USP_JsonObject'),(N'USP_JsonConstructInternal');
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version' AND CONVERT(nvarchar(64),value)=N'1.0.0') THROW 54600,N'Module version missing.',40;
IF EXISTS(SELECT 1 FROM @Names n WHERE OBJECT_ID(N'toolbelt_json.'+n.Name,N'P') IS NULL OR NOT EXISTS
(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(N'toolbelt_json.'+n.Name) AND e.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(128),e.value)=N'toolbelt.json.constructors')) THROW 54600,N'Object marker missing.',41;
IF EXISTS(SELECT 1 FROM @Names n WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=OBJECT_ID(N'toolbelt_json.'+n.Name) AND e.name=N'Toolbelt.SourceHash' AND CONVERT(varchar(64),e.value)=CONVERT(varchar(64),HASHBYTES('SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(e.major_id))),2))) THROW 54600,N'SourceHash marker mismatch.',42;
DECLARE @Expected TABLE(Id int,Name sysname,TypeId int,Length smallint);
INSERT @Expected VALUES(1,N'@EntriesTable',231,256),(2,N'@MaxEntries',56,4),(3,N'@MaxTotalValueBytes',127,8),(4,N'@MaxResultBytes',127,8),(5,N'@ResultTable',231,256),(6,N'@KeepData',104,1),(7,N'@Debug',48,1),(8,N'@Hilfe',104,1);
IF EXISTS(SELECT 1 FROM @Names n WHERE n.Name<>N'USP_JsonConstructInternal' AND (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.'+n.Name))<>8) THROW 54600,N'Parameter count wrong.',43;
IF EXISTS(SELECT 1 FROM @Names n CROSS JOIN @Expected x WHERE n.Name<>N'USP_JsonConstructInternal' AND NOT EXISTS(SELECT 1 FROM sys.parameters p WHERE p.object_id=OBJECT_ID(N'toolbelt_json.'+n.Name) AND p.parameter_id=x.Id AND p.name=x.Name AND p.system_type_id=x.TypeId AND p.max_length=x.Length AND p.is_output=0)) THROW 54600,N'Parameter type/order wrong.',44;
