SET NOCOUNT ON;
-- Installed 1.2: fünf eigene Procedure-Slots, exakte Marker und gekoppelte Signaturen.
DECLARE @Names TABLE(Name sysname COLLATE DATABASE_DEFAULT,IsPublic bit);
INSERT @Names VALUES(N'USP_JsonArray',1),(N'USP_JsonObject',1),(N'USP_JsonConstructInternal',0),
 (N'USP_JsonArraysByGroup',1),(N'USP_JsonObjectsByGroup',1);
DECLARE @Mode nvarchar(max);
SELECT @Mode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.DeploymentMode';
IF @Mode IS NULL OR CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
 THROW 54600,N'JSON lifecycle: installierter Modus fehlt oder ist inkohärent.',40;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.2.0'))
 THROW 54600,N'JSON lifecycle: exakte Modulversion fehlt.',40;
IF EXISTS(SELECT 1 FROM @Names n WHERE NOT EXISTS(SELECT 1 FROM sys.objects o
 WHERE o.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(n.Name),N'P')
 AND CONVERT(varbinary(256),o.name)=CONVERT(varbinary(256),n.Name)
 AND EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
  AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.json.constructors'))
 AND EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
  AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'1.2.0'))
 AND EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
  AND e.name=N'Toolbelt.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),@Mode))))
 THROW 54600,N'JSON lifecycle: eigene Objectmarker fehlen oder sind inkohärent.',41;
IF EXISTS(SELECT 1 FROM @Names n WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1
 AND e.major_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(n.Name)) AND e.minor_id=0 AND e.name=N'Toolbelt.SourceHash'
 AND CONVERT(varbinary(max),TRY_CONVERT(varchar(max),e.value))=CONVERT(varbinary(max),CONVERT(varchar(64),
 HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(e.major_id))),2))))
 THROW 54600,N'JSON lifecycle: diagnostischer SourceHash nach Deploy ist inkohärent.',42;
DECLARE @Expected TABLE(Id int,Name sysname COLLATE DATABASE_DEFAULT,TypeId int,Length smallint);
INSERT @Expected VALUES(1,N'@EntriesTable',231,256),(2,N'@MaxEntries',56,4),(3,N'@MaxTotalValueBytes',127,8),
 (4,N'@MaxResultBytes',127,8),(5,N'@ResultTable',231,256),(6,N'@KeepData',104,1),(7,N'@Debug',48,1),(8,N'@Hilfe',104,1);
IF EXISTS(SELECT 1 FROM @Names n WHERE n.IsPublic=1 AND (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(n.Name)))<>8)
 THROW 54600,N'JSON lifecycle: öffentliche Parameterzahl ist inkohärent.',43;
IF EXISTS(SELECT 1 FROM @Names n CROSS JOIN @Expected x WHERE n.IsPublic=1 AND NOT EXISTS
 (SELECT 1 FROM sys.parameters p WHERE p.object_id=OBJECT_ID(N'toolbelt_json.'+QUOTENAME(n.Name)) AND p.parameter_id=x.Id
 AND CONVERT(varbinary(256),p.name)=CONVERT(varbinary(256),x.Name) AND p.system_type_id=x.TypeId AND p.max_length=x.Length AND p.is_output=0))
 THROW 54600,N'JSON lifecycle: öffentlicher Parametervertrag ist inkohärent.',44;
DELETE FROM @Expected;
INSERT @Expected VALUES(1,N'@ObjectMode',104,1),(2,N'@EntriesTable',231,256),(3,N'@MaxEntries',56,4),
 (4,N'@MaxTotalValueBytes',127,8),(5,N'@MaxResultBytes',127,8),(6,N'@GroupMode',104,1),
 (7,N'@ResultTable',231,256),(8,N'@KeepData',104,1),(9,N'@Debug',48,1),(10,N'@Hilfe',104,1);
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.USP_JsonConstructInternal'))<>10
 OR EXISTS(SELECT 1 FROM @Expected x WHERE NOT EXISTS(SELECT 1 FROM sys.parameters p
  WHERE p.object_id=OBJECT_ID(N'toolbelt_json.USP_JsonConstructInternal') AND p.parameter_id=x.Id
  AND CONVERT(varbinary(256),p.name)=CONVERT(varbinary(256),x.Name) AND p.system_type_id=x.TypeId AND p.max_length=x.Length AND p.is_output=0))
 THROW 54600,N'JSON lifecycle: interner GroupMode-Parametervertrag ist inkohärent.',45;
PRINT N'PASS: JSON lifecycle fünf Slots und Parameter-/Markervertrag.';
