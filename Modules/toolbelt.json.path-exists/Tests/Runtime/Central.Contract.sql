SET NOCOUNT ON;

IF NOT EXISTS
   (
       SELECT 1
       FROM [$(ToolbeltDatabase)].toolbelt_json.TVF_JsonPathExists
            (N'{"payload":{"id":42}}', N'$.payload.id')
       WHERE PathExists = 1
   )
    THROW 52922, N'Der zentrale JSON-Path-Aufruf ist fehlgeschlagen.', 1;

PRINT N'JSON Path Exists Central-Contract-Prüfung: erfolgreich';
GO
