SET NOCOUNT ON;
CREATE USER RegexRelationCaller WITHOUT LOGIN;
GRANT SELECT ON toolbelt_string.TVF_RegexMatches TO RegexRelationCaller;
GRANT SELECT ON toolbelt_string.TVF_RegexSplit TO RegexRelationCaller;
EXECUTE AS USER=N'RegexRelationCaller';
BEGIN TRY
 IF (SELECT COUNT(*) FROM toolbelt_string.TVF_RegexMatches(N'a1',N'[0-9]',DEFAULT,DEFAULT,DEFAULT,DEFAULT))<>1 THROW 52096,N'Least privilege Matches failed.',20;
 IF (SELECT COUNT(*) FROM toolbelt_string.TVF_RegexSplit(N'a,b',N',',DEFAULT,DEFAULT,DEFAULT))<>2 THROW 52096,N'Least privilege Split failed.',21;
 REVERT;
END TRY
BEGIN CATCH
 REVERT;
 THROW;
END CATCH;
DROP USER RegexRelationCaller;
PRINT N'Regex R2b local/direct-central SELECT minimum rights PASS.';
