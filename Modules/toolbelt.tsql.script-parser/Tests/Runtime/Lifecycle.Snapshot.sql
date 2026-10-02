-- Nur der private Runner verarbeitet die Ausgabe; keine Runtime-Ausgabe als Repo-Evidenz.
SELECT
    (SELECT o.object_id, s.name AS SchemaName, o.name, o.type,
            OBJECT_DEFINITION(o.object_id) AS Definition
     FROM sys.objects AS o INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
     WHERE s.name = N'toolbelt_tsql' OR o.name = N'ContosoParserConsumer'
     ORDER BY s.name, o.name FOR JSON PATH, INCLUDE_NULL_VALUES) AS ObjectsJson,
    (SELECT a.assembly_id, a.name, a.permission_set, CONVERT(varchar(128), HASHBYTES(N'SHA2_512', af.content), 2) AS BinaryHash
     FROM sys.assemblies AS a INNER JOIN sys.assembly_files AS af ON af.assembly_id = a.assembly_id AND af.file_id = 1
     WHERE a.name IN (N'Toolbelt_Tsql_ScriptParser', N'Microsoft.SqlServer.TransactSql.ScriptDom')
     ORDER BY a.name FOR JSON PATH, INCLUDE_NULL_VALUES) AS AssembliesJson,
    (SELECT ep.class, ep.major_id, ep.minor_id, ep.name, CONVERT(nvarchar(4000), ep.value) AS Value
     FROM sys.extended_properties AS ep
     WHERE ep.name LIKE N'Toolbelt.%'
       AND (ep.class = 0
            OR (ep.class = 3 AND ep.major_id = SCHEMA_ID(N'toolbelt_tsql'))
            OR (ep.class = 1 AND ep.major_id IN (SELECT object_id FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_tsql')))
            OR (ep.class = 5 AND ep.major_id IN (SELECT assembly_id FROM sys.assemblies WHERE name IN (N'Toolbelt_Tsql_ScriptParser', N'Microsoft.SqlServer.TransactSql.ScriptDom'))))
     ORDER BY ep.class, ep.major_id, ep.minor_id, ep.name FOR JSON PATH, INCLUDE_NULL_VALUES) AS MarkersJson,
    (SELECT schema_id, name, principal_id FROM sys.schemas WHERE name = N'toolbelt_tsql' FOR JSON PATH) AS SchemaJson;
