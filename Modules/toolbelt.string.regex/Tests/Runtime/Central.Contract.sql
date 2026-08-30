SET NOCOUNT ON;

DECLARE @Sql nvarchar(max) = N'
IF [$(ToolbeltDatabase)].toolbelt_string.SVF_RegexIsMatch(N''abc123'', N''^[a-z]+\d+$'', ''c'') <> 1
   OR [$(ToolbeltDatabase)].toolbelt_string.SVF_RegexInstr(N''abc123'', N''\d+'', 1, 1, 0, ''c'') <> 4
   OR [$(ToolbeltDatabase)].toolbelt_string.SVF_RegexCount(N''a1b2'', N''\d'', 1, ''c'') <> 2
    THROW 52087, N''Der zentrale Regex-Vertrag ist verletzt.'', 1;';
EXEC sys.sp_executesql @Sql;

PRINT N'Regex-Central-Contract erfolgreich.';
