-- Installierter Releasezustand und minimale Callerrechte. Keine serverweiten
-- Logins, Trust-/Konfigurationsänderungen oder CrossDB-Rechtebehauptung.
SET NOCOUNT ON;
DECLARE @Objects TABLE(ObjectName sysname,ObjectType char(2),Visibility nvarchar(16));
INSERT @Objects VALUES
(N'TVF_DeterministicIntegerBytes','IF',N'internal'),(N'TVF_DeterministicRangeCore','IF',N'internal'),
(N'TVF_DeterministicRange','IF',N'public'),(N'TVF_DeterministicDateShift','IF',N'public'),(N'USP_DeterministicLookupCore','P',N'internal'),(N'USP_DeterministicLookup','P',N'public');
IF (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_pseudonymization'))<>6
    OR EXISTS(SELECT 1 FROM @Objects e LEFT JOIN sys.objects a ON a.object_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(e.ObjectName)) WHERE a.object_id IS NULL OR CONVERT(varbinary(2),a.type)<>CONVERT(varbinary(2),e.ObjectType))
    THROW 54090,N'Deterministic: Releaseinventar/echter IF-Typ verletzt.',1;
DECLARE @Properties TABLE(PropertyName sysname);
INSERT @Properties VALUES(N'Toolbelt.ModuleId'),(N'Toolbelt.ModuleVersion'),(N'Toolbelt.ContractVersion'),(N'Toolbelt.DeploymentMode'),(N'Toolbelt.Visibility'),(N'Toolbelt.SourceHash');
IF EXISTS(SELECT 1 FROM @Objects e CROSS JOIN @Properties p WHERE NOT EXISTS
    (SELECT 1 FROM sys.extended_properties a WHERE a.class=1 AND a.major_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(e.ObjectName)) AND a.minor_id=0 AND a.name=p.PropertyName))
    OR EXISTS(SELECT 1 FROM @Objects e JOIN sys.extended_properties p ON p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(e.ObjectName)) AND p.minor_id=0
        WHERE (p.name=N'Toolbelt.ModuleId' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),p.value)),0x)<>CONVERT(varbinary(max),N'toolbelt.pseudonymization.deterministic'))
        OR (p.name=N'Toolbelt.ModuleVersion' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),p.value)),0x)<>CONVERT(varbinary(max),N'1.0.0'))
        OR (p.name=N'Toolbelt.ContractVersion' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),p.value)),0x)<>CONVERT(varbinary(max),N'1.0'))
        OR (p.name=N'Toolbelt.Visibility' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(nvarchar(16),p.value)),0x)<>CONVERT(varbinary(max),e.Visibility))
        OR (p.name=N'Toolbelt.SourceHash' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(varchar(64),p.value)),0x)<>CONVERT(varbinary(max),CONVERT(varchar(64),HASHBYTES('SHA2_256',OBJECT_DEFINITION(p.major_id)),2))))
    THROW 54090,N'Deterministic: Ownership/Visibility/diagnostischer Sourcehash verletzt.',1;
-- Vollständiges öffentliches Parameterinventar; Defaults zusätzlich Help/Source.
DECLARE @Parameters TABLE(ObjectName sysname,Ordinal int,ParameterName sysname,TypeId int,MaxLength int);
INSERT @Parameters VALUES
(N'TVF_DeterministicRange',1,N'@Key',165,-1),(N'TVF_DeterministicRange',2,N'@MappingVersion',56,4),(N'TVF_DeterministicRange',3,N'@Seed',127,8),(N'TVF_DeterministicRange',4,N'@Min',127,8),(N'TVF_DeterministicRange',5,N'@Max',127,8),
(N'TVF_DeterministicDateShift',1,N'@Value',42,8),(N'TVF_DeterministicDateShift',2,N'@Key',165,-1),(N'TVF_DeterministicDateShift',3,N'@MappingVersion',56,4),(N'TVF_DeterministicDateShift',4,N'@Seed',127,8),(N'TVF_DeterministicDateShift',5,N'@MaxDays',56,4),
(N'USP_DeterministicLookup',1,N'@InputTable',231,256),(N'USP_DeterministicLookup',2,N'@LookupTable',231,256),(N'USP_DeterministicLookup',3,N'@MappingVersion',56,4),(N'USP_DeterministicLookup',4,N'@Seed',127,8),(N'USP_DeterministicLookup',5,N'@LookupVersion',127,8),
(N'USP_DeterministicLookup',6,N'@MaxInputRows',56,4),(N'USP_DeterministicLookup',7,N'@MaxLookupRows',56,4),(N'USP_DeterministicLookup',8,N'@MaxLookupTextBytes',127,8),(N'USP_DeterministicLookup',9,N'@MaxResultBytes',127,8),
(N'USP_DeterministicLookup',10,N'@ResultTable',231,256),(N'USP_DeterministicLookup',11,N'@KeepData',104,1),(N'USP_DeterministicLookup',12,N'@Debug',48,1),(N'USP_DeterministicLookup',13,N'@Hilfe',104,1);
IF EXISTS(SELECT 1 FROM @Parameters e LEFT JOIN sys.parameters a ON a.object_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(e.ObjectName)) AND a.parameter_id=e.Ordinal
    WHERE a.parameter_id IS NULL OR CONVERT(varbinary(256),a.name)<>CONVERT(varbinary(256),e.ParameterName) OR a.system_type_id<>e.TypeId OR a.max_length<>e.MaxLength OR a.is_output<>0)
    OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id IN(OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicRange'),OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicDateShift'),OBJECT_ID(N'toolbelt_pseudonymization.USP_DeterministicLookup')) AND parameter_id>0)<>23
    THROW 54090,N'Deterministic: öffentliches Parameterinventar verletzt.',1;
CREATE USER SyntheticDeterministicCaller WITHOUT LOGIN;
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
