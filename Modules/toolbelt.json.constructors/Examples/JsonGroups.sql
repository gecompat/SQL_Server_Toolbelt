-- Ausschließlich synthetische Entries, kein SQL aus Values.
CREATE TABLE #Entries(GroupOrdinal int,Ordinal int,[Key] nvarchar(max),ValueKind nvarchar(max),[Value] nvarchar(max));
INSERT #Entries VALUES(7,2,N'active',N'boolean',N'true'),(7,1,N'name',N'string',N'Contoso'),(19,1,N'name',N'string',N'Fabrikam');
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#Entries';
EXEC toolbelt_json.USP_JsonObjectsByGroup @EntriesTable=N'#Entries';
DROP TABLE #Entries;
GO
