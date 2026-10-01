CREATE TABLE #CentralEntries(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #CentralEntries VALUES(9,N'number',N'12');
CREATE TABLE #CentralResult(Dummy int);
EXEC [$(ToolbeltDatabase)].toolbelt_json.USP_JsonArray @EntriesTable=N'#CentralEntries',@ResultTable=N'#CentralResult';
DECLARE @Value nvarchar(max);
EXEC sys.sp_executesql N'SELECT @x=JsonValue FROM #CentralResult',N'@x nvarchar(max) OUTPUT',@Value OUTPUT;
IF @Value IS NULL OR CONVERT(varbinary(max),@Value)<>CONVERT(varbinary(max),N'[12]') THROW 54600,N'Central cross-database #Temp contract failed.',45;
