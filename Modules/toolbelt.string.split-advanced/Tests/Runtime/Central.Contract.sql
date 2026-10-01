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
IF NOT EXISTS(SELECT 1 FROM [$(ToolbeltDatabase)].toolbelt_string.TVF_UnquoteToken
    (N'[a]]b]',DEFAULT,DEFAULT,DEFAULT)
    WHERE IsValid=1 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'a]b'))
    THROW 54532,N'Zentrales Unquoting falsch.',1;
CREATE TABLE #SplitCentral_Result(Dummy int NULL);
EXEC [$(ToolbeltDatabase)].toolbelt_string.USP_SplitAdvanced
    @Input=N'a;b',@SeparatorsJson=N'[";"]',@ResultTable=N'#SplitCentral_Result';
IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#SplitCentral_Result'))<>2
    THROW 54533,N'Zentrale USP-ResultTable falsch.',1;
DROP TABLE #SplitCentral_Result;
GO
