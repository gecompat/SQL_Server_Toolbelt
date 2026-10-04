SET NOCOUNT ON;
CREATE TABLE #Output(Sentinel int NULL);
INSERT #Output VALUES(73);
CREATE TABLE #Help
(
 HelpContractVersion varchar(16) NOT NULL,SchemaName sysname NOT NULL,ObjectName sysname NOT NULL,
 Section varchar(32) NOT NULL,Ordinal int NOT NULL,ItemName sysname NULL,SqlDataType varchar(256) NULL,
 IsRequired bit NULL,IsNullable bit NULL,DefaultValue nvarchar(4000) NULL,Description nvarchar(max) NOT NULL,ExampleSql nvarchar(max) NULL
);
-- Top-level test capture only; no INSERT EXEC in the production wrapper.
INSERT #Help EXEC toolbelt_string.USP_CompareTextPairs @PairsTable=N'##invalid',@Algorithm=N'invalid',@MaxPairs=0,@ResultTable=N'#Output',@KeepData=0,@Debug=255,@Hilfe=1;
IF (SELECT COUNT(*) FROM #Help WHERE Section='PARAMETER')<>11
   OR (SELECT COUNT(*) FROM #Help WHERE Section='RESULT_COLUMN')<>5
   OR NOT EXISTS(SELECT 1 FROM #Help WHERE Section='DESCRIPTION')
   OR NOT EXISTS(SELECT 1 FROM #Help WHERE Section='EXAMPLE' AND ExampleSql IS NOT NULL)
   OR EXISTS(SELECT 1 FROM #Help WHERE HelpContractVersion<>'1.0' OR SchemaName<>N'toolbelt_string' OR ObjectName<>N'USP_CompareTextPairs')
   OR (SELECT COUNT(*) FROM #Output)<>1 OR NOT EXISTS(SELECT 1 FROM #Output WHERE Sentinel=73)
    THROW 55194,N'Help contract or no-mutation priority failed.',1;
DROP TABLE #Help;
DROP TABLE #Output;
SELECT N'PASS' AS Status;
