:On Error exit
SET NOCOUNT ON;
CREATE TABLE #Claim(Dummy int NULL);
EXEC toolbelt_core.USP_ClaimWork @ResultTable=N'#Claim';
WAITFOR DELAY '00:00:01';
GO
