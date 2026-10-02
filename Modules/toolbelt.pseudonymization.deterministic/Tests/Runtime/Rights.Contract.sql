-- Ausschliesslich disposable CI: synthetischer DB-Benutzer, keine Serverrechte.
SET NOCOUNT ON;
CREATE USER SyntheticDeterministicCaller WITHOUT LOGIN;
GRANT SELECT ON OBJECT::toolbelt_pseudonymization.TVF_DeterministicTranslate TO SyntheticDeterministicCaller;
GRANT SELECT ON OBJECT::toolbelt_pseudonymization.TVF_DeterministicRange TO SyntheticDeterministicCaller;
GRANT SELECT ON OBJECT::toolbelt_pseudonymization.TVF_DeterministicDateShift TO SyntheticDeterministicCaller;
GRANT EXECUTE ON OBJECT::toolbelt_pseudonymization.USP_DeterministicLookup TO SyntheticDeterministicCaller;
GRANT EXECUTE ON OBJECT::toolbelt_core.USP_PrepareResultTable TO SyntheticDeterministicCaller;
EXECUTE AS USER=N'SyntheticDeterministicCaller';
BEGIN TRY
    IF NOT EXISTS(SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicRange(0x010203,1,DEFAULT,-10,10) WHERE Value=-9 AND ErrorCode=0)
        THROW 54090,N'Deterministic: minimale SELECT-Rechte Range verletzt.',1;
    IF NOT EXISTS(SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicDateShift(CONVERT(datetime2(7),'2026-01-01'),0x010203,1,DEFAULT,0) WHERE Value=CONVERT(datetime2(7),'2026-01-01') AND ErrorCode=0)
        THROW 54090,N'Deterministic: minimale SELECT-Rechte DateShift verletzt.',1;
    IF NOT EXISTS(SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'aAzZ09',1,DEFAULT,DEFAULT,DEFAULT) WHERE ErrorCode=0 AND DATALENGTH(Value)=12)
        THROW 54090,N'Deterministic: minimale Translate-SELECT-Rechte verletzt.',1;
    CREATE TABLE #RightsInput(Ordinal bigint,[Key] varbinary(max));
    CREATE TABLE #RightsPool(Ordinal bigint,[Value] nvarchar(max));
    CREATE TABLE #RightsResult(Dummy int);
    INSERT #RightsInput VALUES(1,0x01); INSERT #RightsPool VALUES(7,N'synthetic');
    EXEC toolbelt_pseudonymization.USP_DeterministicLookup @InputTable=N'#RightsInput',@LookupTable=N'#RightsPool',@MappingVersion=1,@LookupVersion=1,@ResultTable=N'#RightsResult';
    IF (SELECT COUNT_BIG(*) FROM #RightsResult)<>1 OR NOT EXISTS(SELECT 1 FROM #RightsResult WHERE InputOrdinal=1 AND LookupOrdinal=7 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'synthetic'))
        THROW 54090,N'Deterministic: minimale Lookup-/Helper-EXECUTE-Rechte verletzt.',1;
    DROP TABLE #RightsInput; DROP TABLE #RightsPool; DROP TABLE #RightsResult;
    REVERT;
END TRY
BEGIN CATCH REVERT; THROW; END CATCH;
DROP USER SyntheticDeterministicCaller;
PRINT N'PASS: Deterministic Release/API/Hashes und direkte Datenbank-Minimalrechte';
GO
