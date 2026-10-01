CREATE TABLE #Entries(Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(3,N'string',N'synthetic'),(9,N'null',NULL),(12,N'number',N'-1.25e+2');
EXEC toolbelt_json.USP_JsonArray @EntriesTable=N'#Entries';
DROP TABLE #Entries;
