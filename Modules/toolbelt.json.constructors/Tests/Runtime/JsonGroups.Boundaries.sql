-- Explizite native Ceiling-Orakel; kein schneller Standard-Smoketest.
SET NOCOUNT ON;
CREATE TABLE #GroupCeilingEntries(GroupOrdinal int,Ordinal int,ValueKind nvarchar(max),[Value] nvarchar(max));
CREATE TABLE #GroupCeilingOutput(Dummy int);
;WITH D AS(SELECT n FROM(VALUES(0),(1),(2),(3),(4),(5),(6),(7),(8),(9))d(n))
INSERT #GroupCeilingEntries SELECT 1+a.n+10*b.n+100*c.n+1000*d.n+10000*e.n,1,N'null',NULL FROM D a CROSS JOIN D b CROSS JOIN D c CROSS JOIN D d CROSS JOIN D e;
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupCeilingEntries',@MaxEntries=100000,@ResultTable=N'#GroupCeilingOutput';
IF (SELECT COUNT_BIG(*) FROM #GroupCeilingOutput)<>100000 OR (SELECT SUM(CONVERT(bigint,DATALENGTH(JsonValue))) FROM #GroupCeilingOutput)<>1200000 THROW 53690,N'Actual100000 group result failed.',1;
INSERT #GroupCeilingEntries VALUES(100001,1,N'null',NULL);
BEGIN TRY EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupCeilingEntries',@MaxEntries=100000; THROW 53690,N'Actual100001 limit missing.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 OR ERROR_STATE()<>1 THROW; END CATCH;
TRUNCATE TABLE #GroupCeilingEntries;
INSERT #GroupCeilingEntries VALUES(1,1,N'string',REPLICATE(CONVERT(nvarchar(max),N'x'),8388604));
EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupCeilingEntries',@MaxTotalValueBytes=16777216,@MaxResultBytes=16777216,@ResultTable=N'#GroupCeilingOutput';
IF (SELECT COUNT_BIG(*) FROM #GroupCeilingOutput)<>1 OR NOT EXISTS(SELECT 1 FROM #GroupCeilingOutput WHERE DATALENGTH(JsonValue)=16777216) THROW 53690,N'Actual16MiB output failed.',1;
BEGIN TRY EXEC toolbelt_json.USP_JsonArraysByGroup @EntriesTable=N'#GroupCeilingEntries',@MaxTotalValueBytes=16777216,@MaxResultBytes=16777215; THROW 53690,N'Actual16MiB minusone limit missing.',1; END TRY BEGIN CATCH IF ERROR_NUMBER()<>53609 OR ERROR_STATE()<>4 THROW; END CATCH;
DROP TABLE #GroupCeilingOutput; DROP TABLE #GroupCeilingEntries;
GO
