SET NOCOUNT ON;
CREATE USER TbxSplitApiReader WITHOUT LOGIN;
GRANT SELECT ON OBJECT::toolbelt_string.TVF_UnquoteToken TO TbxSplitApiReader;
GRANT EXECUTE ON OBJECT::toolbelt_string.USP_SplitAdvanced TO TbxSplitApiReader;
GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO TbxSplitApiReader;
EXECUTE AS USER=N'TbxSplitApiReader';
BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM toolbelt_string.TVF_UnquoteToken(N'[a]]b]',DEFAULT,DEFAULT,DEFAULT)
        WHERE IsValid=1 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'a]b'))
        THROW 54581,N'Unquote minimales SELECT-Recht falsch.',1;
    CREATE TABLE #MinimalSplitResult(Dummy int NULL);
    EXEC toolbelt_string.USP_SplitAdvanced @Input=N'a;b',@SeparatorsJson=N'[";"]',@ResultTable=N'#MinimalSplitResult';
    IF (SELECT COUNT(*) FROM tempdb.sys.columns WHERE object_id=OBJECT_ID(N'tempdb..#MinimalSplitResult'))<>2
        THROW 54582,N'USP minimales EXECUTE-/ResultTable-Recht falsch.',1;
    DROP TABLE #MinimalSplitResult;
    REVERT;
END TRY
BEGIN CATCH
    REVERT;
    DROP USER TbxSplitApiReader;
    THROW;
END CATCH;
DROP USER TbxSplitApiReader;
PRINT N'Split neue APIs MinimumRights: erfolgreich';
GO
