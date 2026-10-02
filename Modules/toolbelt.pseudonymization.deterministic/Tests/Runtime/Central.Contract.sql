-- Administrative dreiteilige Baseline; kein CrossDB-Minimalrechtebeweis.
SET NOCOUNT ON;
IF NOT EXISTS(SELECT 1 FROM [$(CentralDb)].toolbelt_pseudonymization.TVF_DeterministicTranslate(N'Aa09 - ',1,0,N'- ',DEFAULT)
 WHERE ErrorCode=0 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'Ss64 - '))
    THROW 54090,N'Deterministic: dreiteiliger Translatevektor verletzt.',1;
IF NOT EXISTS(SELECT 1 FROM [$(CentralDb)].toolbelt_pseudonymization.TVF_DeterministicRange(0x010203,1,DEFAULT,-10,10) WHERE Value=-9 AND ErrorCode=0)
    THROW 54090,N'Deterministic: dreiteiliger Rangevektor verletzt.',1;
IF NOT EXISTS(SELECT 1 FROM [$(CentralDb)].toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2026-01-01'),0x010203,1,DEFAULT,0) WHERE Value=CONVERT(datetime2(7),'2026-01-01') AND ErrorCode=0)
    THROW 54090,N'Deterministic: dreiteiliger DateShift verletzt.',1;
CREATE TABLE #CentralInput(Ordinal bigint,[Key] varbinary(max));
CREATE TABLE #CentralPool(Ordinal bigint,[Value] nvarchar(max) COLLATE Latin1_General_100_CS_AS);
CREATE TABLE #CentralResult(Dummy int);
INSERT #CentralInput VALUES(10,0x010203),(90,NULL);
INSERT #CentralPool VALUES(20,N'synthetic alpha'),(80,N'synthetic beta');
EXEC [$(CentralDb)].toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#CentralInput',@LookupTable=N'#CentralPool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#CentralResult';
IF (SELECT COUNT_BIG(*) FROM #CentralResult)<>2
    OR NOT EXISTS(SELECT 1 FROM #CentralResult WHERE InputOrdinal=10 AND LookupOrdinal=80 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'synthetic beta'))
    OR NOT EXISTS(SELECT 1 FROM #CentralResult WHERE InputOrdinal=90 AND LookupOrdinal IS NULL AND Value IS NULL)
    THROW 54090,N'Deterministic: CrossDB-ResultTable/Lookupdomain verletzt.',1;
PRINT N'PASS: Deterministic administrative CrossDB-Baseline';
GO
