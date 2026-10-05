-- Ausschließlich synthetische Beispiele; local installierte TVF, vier explizite Argumente.
SELECT input.Pointer,resolved.Status,resolved.JsonType,resolved.Value,resolved.ErrorCode
FROM (VALUES(N''),(N'/a~1b/0'),(N'/a~1b/1'),(N'/a~1b/2')) input(Pointer)
CROSS APPLY toolbelt_json.TVF_ResolveJsonPointer(N'{"a/b":[null,"example"]}',input.Pointer,DEFAULT,DEFAULT) resolved;
GO
