SET NOCOUNT ON;
DECLARE @Comparison smallint;
SELECT @Comparison =
    [$(ToolbeltDatabase)].toolbelt_validation.SVF_CompareSemanticVersion
    ('1.2.3-alpha', '1.2.3');
IF @Comparison <> -1
    THROW 52730, N'Der zentrale dreiteilige SemVer-Aufruf ist fehlgeschlagen.', 1;
PRINT N'Semantic-Version Central-Contract-Prüfung: erfolgreich';
GO
