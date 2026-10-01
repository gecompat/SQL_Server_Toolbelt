-- Dreiteiliger Aufruf aus anderer Datenbank mit abweichender Collation.
SET NOCOUNT ON;
IF (SELECT COUNT(*) FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_SplitAdvanced
    (N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT))<>3
    THROW 54530,N'Der zentrale TVF-Aufruf ist fehlgeschlagen.',1;
IF NOT EXISTS(SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_SplitAdvanced
    (N'a;"b;c";d',N'[";"]',DEFAULT,DEFAULT,DEFAULT)
    WHERE Ordinal=2 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'"b;c"') AND IsValid=1)
    THROW 54531,N'Die zentrale Originaltoken-Semantik ist falsch.',1;
PRINT N'Split-Advanced Central: erfolgreich';
GO
