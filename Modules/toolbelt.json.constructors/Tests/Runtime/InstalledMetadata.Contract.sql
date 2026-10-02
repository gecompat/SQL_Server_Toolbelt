-- Synthetischer Katalogvertrag; Client-Resultmetadaten separat geprüft.
SET NOCOUNT ON;
DECLARE @version nvarchar(64);
SELECT @version=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.json.constructors.Version';
IF CONVERT(varbinary(max),@version)<>CONVERT(varbinary(max),N'1.1.0') OR @version IS NULL THROW 53690,N'JSON1.1 module marker incorrect.',1;
DECLARE @apis TABLE(Name sysname);
INSERT @apis VALUES(N'USP_JsonArray'),(N'USP_JsonObject'),(N'USP_JsonArraysByGroup'),(N'USP_JsonObjectsByGroup');
DECLARE @params TABLE(Ordinal int,Name sysname,TypeId int,Length int);
INSERT @params VALUES(1,N'@EntriesTable',231,256),(2,N'@MaxEntries',56,4),(3,N'@MaxTotalValueBytes',127,8),(4,N'@MaxResultBytes',127,8),(5,N'@ResultTable',231,256),(6,N'@KeepData',104,1),(7,N'@Debug',48,1),(8,N'@Hilfe',104,1);
IF EXISTS(SELECT 1 FROM @apis a WHERE OBJECT_ID(N'toolbelt_json.'+a.Name,N'P') IS NULL
 OR (SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id=OBJECT_ID(N'toolbelt_json.'+a.Name))<>8)
 OR EXISTS(SELECT 1 FROM @apis a CROSS JOIN @params expected LEFT JOIN sys.parameters actual ON actual.object_id=OBJECT_ID(N'toolbelt_json.'+a.Name) AND actual.parameter_id=expected.Ordinal
 WHERE actual.parameter_id IS NULL OR CONVERT(varbinary(max),actual.name)<>CONVERT(varbinary(max),expected.Name) OR actual.system_type_id<>expected.TypeId OR actual.max_length<>expected.Length)
 THROW 53690,N'JSON public parameter inventory incorrect.',1;
IF (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.USP_JsonConstructInternal'))<>10
 OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_json.USP_JsonConstructInternal') AND parameter_id=6 AND name=N'@GroupMode' AND system_type_id=104)
 THROW 53690,N'JSON internal GroupMode ordinal incorrect.',1;
IF (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_json') AND name IN(N'USP_JsonArray',N'USP_JsonObject',N'USP_JsonArraysByGroup',N'USP_JsonObjectsByGroup',N'USP_JsonConstructInternal') AND type='P')<>5
 THROW 53690,N'JSON five-slot inventory incorrect.',1;
GO
