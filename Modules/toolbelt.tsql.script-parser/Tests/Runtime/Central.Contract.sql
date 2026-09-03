SET NOCOUNT ON;

DECLARE @Sql nvarchar(max) = N'
IF NOT EXISTS (
    SELECT 1
    FROM [$(ToolbeltDatabase)].toolbelt_tsql.TVF_TokenizeScript(N''SELECT 1;'', 160, 1, 2097152, 256)
    WHERE TokenType = N''Select''
)
    THROW 53124, N''Der zentrale ScriptParser-Vertrag ist verletzt.'', 1;
';

EXEC sys.sp_executesql @Sql;
PRINT N'ScriptParser-Central-Contract erfolgreich.';
