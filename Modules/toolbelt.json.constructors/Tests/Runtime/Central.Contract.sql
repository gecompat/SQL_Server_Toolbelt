CREATE TABLE #CentralEntries(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #CentralEntries VALUES(9,N'number',N'12');
CREATE TABLE #CentralResult(Dummy int);
EXEC [$(ToolbeltDatabase)].toolbelt_json.USP_JsonArray @EntriesTable=N'#CentralEntries',@ResultTable=N'#CentralResult';
DECLARE @Value nvarchar(max);
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #CentralResult',N'@x nvarchar(max) OUTPUT',@Value OUTPUT;
IF @Value IS NULL OR CONVERT(varbinary(max),@Value)<>CONVERT(varbinary(max),N'[12]') THROW 54600,N'Central cross-database #Temp contract failed.',45;

-- Beide gruppierten Fassaden lesen Caller-Tempdaten auch aus einem UTF8-Consumer.
CREATE TABLE #CentralGroups(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #CentralGroups VALUES(8,7,N'A',N'string',N'Contoso'),(2,4,N'A',N'null',NULL);
CREATE TABLE #CentralGroupResult(Dummy int);
EXEC [$(ToolbeltDatabase)].toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#CentralGroups',@ResultTable=N'#CentralGroupResult';
IF (SELECT COUNT_BIG(*) FROM #CentralGroupResult)<>2
 OR NOT EXISTS(SELECT 1 FROM #CentralGroupResult WHERE GroupOrdinal=2 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'[null]'))
 OR NOT EXISTS(SELECT 1 FROM #CentralGroupResult WHERE GroupOrdinal=8 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'["Contoso"]'))
 THROW 54600,N'Central grouped array routing failed.',46;
EXEC [$(ToolbeltDatabase)].toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#CentralGroups',@ResultTable=N'#CentralGroupResult';
IF (SELECT COUNT_BIG(*) FROM #CentralGroupResult)<>2
 OR NOT EXISTS(SELECT 1 FROM #CentralGroupResult WHERE GroupOrdinal=2 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'{"A":null}'))
 OR NOT EXISTS(SELECT 1 FROM #CentralGroupResult WHERE GroupOrdinal=8 AND CONVERT(varbinary(max),JsonValue)=CONVERT(varbinary(max),N'{"A":"Contoso"}'))
 THROW 54600,N'Central grouped object routing failed.',47;
DECLARE @GroupResultId int=OBJECT_ID(N'tempdb..#CentralGroupResult',N'U'),@GroupMetadataValid bit;
;WITH ResultColumns AS
(
 SELECT ROW_NUMBER() OVER(ORDER BY column_id) ResultOrdinal,name,system_type_id,max_length,is_nullable,collation_name
 FROM tempdb.sys.columns WHERE object_id=@GroupResultId
)
SELECT @GroupMetadataValid=CASE WHEN (SELECT COUNT(*) FROM ResultColumns)=2
 AND EXISTS(SELECT 1 FROM ResultColumns WHERE ResultOrdinal=1 AND name=N'GroupOrdinal' AND system_type_id=56 AND is_nullable=0)
 AND EXISTS(SELECT 1 FROM ResultColumns WHERE ResultOrdinal=2 AND name=N'JsonValue' AND system_type_id=231 AND max_length=-1 AND is_nullable=0 AND collation_name=N'Latin1_General_100_BIN2')
 THEN 1 ELSE 0 END;
IF @GroupMetadataValid<>1 THROW 54600,N'Central grouped metadata failed.',48;
-- SELECT/Help-Metadaten werden zusätzlich im unabhängigen SqlDataReader-Probe geprüft.
DROP TABLE #CentralGroups;DROP TABLE #CentralGroupResult;
