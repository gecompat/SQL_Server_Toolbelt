EXECUTE AS USER=N'TbxJsonCaller';
CREATE TABLE #RightsEntries(Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #RightsEntries VALUES(1,N'key',N'string',N'synthetic');
CREATE TABLE #RightsResult(Dummy int);
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#RightsEntries',@ResultTable=N'#RightsResult';
EXEC toolbelt_json.USP_JsonObject @EntriesTable=N'#RightsEntries',@ResultTable=N'#RightsResult';
IF (SELECT COUNT(*) FROM #RightsResult)<>1 THROW 54600,N'Minimum rights result missing.',46;
REVERT;
