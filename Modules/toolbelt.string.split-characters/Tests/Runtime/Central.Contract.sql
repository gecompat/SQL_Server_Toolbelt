-- ============================================================================
-- Cross-database-Contract für zentrale Installation
-- SQLCMD-Variable: ToolbeltDatabase
-- ============================================================================

SET NOCOUNT ON;

DECLARE
      @TokenCount bigint
    , @FirstToken nvarchar(max)
    , @LastToken  nvarchar(max);

SELECT
      @TokenCount = COUNT_BIG(*)
    , @FirstToken = MAX(CASE WHEN tokens.Ordinal = 1 THEN tokens.Value END)
    , @LastToken = MAX(CASE WHEN tokens.Ordinal = 3 THEN tokens.Value END)
FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_SplitByCharacters
(
    N'Alpha,Beta;Gamma',
    N',;',
    DEFAULT
) AS tokens;

IF @TokenCount <> 3
   OR @FirstToken COLLATE Latin1_General_100_BIN2 <> N'Alpha'
   OR @LastToken COLLATE Latin1_General_100_BIN2 <> N'Gamma'
BEGIN
    THROW 52630, N'Der zentrale dreiteilige Split-Aufruf ist fehlgeschlagen.', 1;
END;

PRINT N'Split-Characters Central-Contract-Prüfung: erfolgreich';
GO
