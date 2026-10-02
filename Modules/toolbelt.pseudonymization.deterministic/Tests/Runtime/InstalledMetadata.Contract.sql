-- Grantloser installierter Releasezustand und Metadaten. Keine serverweiten
-- Logins, Trust-/Konfigurationsänderungen oder CrossDB-Rechtebehauptung.
SET NOCOUNT ON;
DECLARE @Objects TABLE(ObjectName sysname COLLATE DATABASE_DEFAULT,ObjectType char(2) COLLATE DATABASE_DEFAULT,Visibility nvarchar(16) COLLATE DATABASE_DEFAULT);
INSERT @Objects VALUES
(N'TVF_DeterministicIntegerBytes','IF',N'internal'),(N'TVF_DeterministicRangeCore','IF',N'internal'),
(N'TVF_DeterministicRange','IF',N'public'),(N'TVF_DeterministicDateShift','IF',N'public'),(N'USP_DeterministicLookupCore','P',N'internal'),(N'USP_DeterministicLookup','P',N'public'),(N'TVF_DeterministicTranslate','IF',N'public'),(N'TVF_DeterministicGeoJitter','IF',N'public');
IF (SELECT COUNT(*) FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_pseudonymization'))<>8
    OR EXISTS(SELECT 1 FROM @Objects e LEFT JOIN sys.objects a ON a.object_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(e.ObjectName)) WHERE a.object_id IS NULL OR CONVERT(varbinary(2),a.type)<>CONVERT(varbinary(2),e.ObjectType))
    THROW 54090,N'Deterministic: Releaseinventar/echter IF-Typ verletzt.',1;
DECLARE @Properties TABLE(PropertyName sysname COLLATE DATABASE_DEFAULT);
INSERT @Properties VALUES(N'Toolbelt.ModuleId'),(N'Toolbelt.ModuleVersion'),(N'Toolbelt.ContractVersion'),(N'Toolbelt.DeploymentMode'),(N'Toolbelt.Visibility'),(N'Toolbelt.SourceHash');
IF EXISTS(SELECT 1 FROM @Objects e CROSS JOIN @Properties p WHERE NOT EXISTS
    (SELECT 1 FROM sys.extended_properties a WHERE a.class=1 AND a.major_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(e.ObjectName)) AND a.minor_id=0 AND a.name COLLATE DATABASE_DEFAULT=p.PropertyName COLLATE DATABASE_DEFAULT))
    OR EXISTS(SELECT 1 FROM @Objects e JOIN sys.extended_properties p ON p.class=1 AND p.major_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(e.ObjectName)) AND p.minor_id=0
        WHERE (p.name=N'Toolbelt.ModuleId' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),p.value)),0x)<>CONVERT(varbinary(max),N'toolbelt.pseudonymization.deterministic'))
        OR (p.name=N'Toolbelt.ModuleVersion' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),p.value)),0x)<>CONVERT(varbinary(max),N'1.2.0'))
        OR (p.name=N'Toolbelt.ContractVersion' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),p.value)),0x)<>CONVERT(varbinary(max),N'1.0'))
        OR (p.name=N'Toolbelt.Visibility' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(nvarchar(16),p.value)),0x)<>CONVERT(varbinary(max),e.Visibility))
        OR (p.name=N'Toolbelt.SourceHash' AND ISNULL(CONVERT(varbinary(max),TRY_CONVERT(varchar(64),p.value)),0x)<>CONVERT(varbinary(max),CONVERT(varchar(64),HASHBYTES('SHA2_256',OBJECT_DEFINITION(p.major_id)),2))))
    THROW 54090,N'Deterministic: Ownership/Visibility/diagnostischer Sourcehash verletzt.',1;
-- Vollständiges öffentliches Parameterinventar; Defaults zusätzlich Help/Source.
DECLARE @Parameters TABLE(ObjectName sysname COLLATE DATABASE_DEFAULT,Ordinal int,ParameterName sysname COLLATE DATABASE_DEFAULT,TypeId int,MaxLength int);
INSERT @Parameters VALUES
(N'TVF_DeterministicRange',1,N'@Key',165,-1),(N'TVF_DeterministicRange',2,N'@MappingVersion',56,4),(N'TVF_DeterministicRange',3,N'@Seed',127,8),(N'TVF_DeterministicRange',4,N'@Min',127,8),(N'TVF_DeterministicRange',5,N'@Max',127,8),
(N'TVF_DeterministicDateShift',1,N'@Value',42,8),(N'TVF_DeterministicDateShift',2,N'@Key',165,-1),(N'TVF_DeterministicDateShift',3,N'@MappingVersion',56,4),(N'TVF_DeterministicDateShift',4,N'@Seed',127,8),(N'TVF_DeterministicDateShift',5,N'@MaxDays',56,4),
(N'USP_DeterministicLookup',1,N'@InputTable',231,256),(N'USP_DeterministicLookup',2,N'@LookupTable',231,256),(N'USP_DeterministicLookup',3,N'@MappingVersion',56,4),(N'USP_DeterministicLookup',4,N'@Seed',127,8),(N'USP_DeterministicLookup',5,N'@LookupVersion',127,8),
(N'USP_DeterministicLookup',6,N'@MaxInputRows',56,4),(N'USP_DeterministicLookup',7,N'@MaxLookupRows',56,4),(N'USP_DeterministicLookup',8,N'@MaxLookupTextBytes',127,8),(N'USP_DeterministicLookup',9,N'@MaxResultBytes',127,8),
(N'USP_DeterministicLookup',10,N'@ResultTable',231,256),(N'USP_DeterministicLookup',11,N'@KeepData',104,1),(N'USP_DeterministicLookup',12,N'@Debug',48,1),(N'USP_DeterministicLookup',13,N'@Hilfe',104,1),
(N'TVF_DeterministicTranslate',1,N'@Value',231,-1),(N'TVF_DeterministicTranslate',2,N'@MappingVersion',56,4),
(N'TVF_DeterministicTranslate',3,N'@Seed',127,8),(N'TVF_DeterministicTranslate',4,N'@AllowedSeparators',231,-1),(N'TVF_DeterministicTranslate',5,N'@Profile',231,-1),
(N'TVF_DeterministicGeoJitter',1,N'@Value',240,-1),(N'TVF_DeterministicGeoJitter',2,N'@Key',165,-1),(N'TVF_DeterministicGeoJitter',3,N'@MappingVersion',56,4),
(N'TVF_DeterministicGeoJitter',4,N'@Seed',127,8),(N'TVF_DeterministicGeoJitter',5,N'@RadiusMeters',56,4);
IF EXISTS(SELECT 1 FROM @Parameters e LEFT JOIN sys.parameters a ON a.object_id=OBJECT_ID(N'toolbelt_pseudonymization.'+QUOTENAME(e.ObjectName)) AND a.parameter_id=e.Ordinal
    WHERE a.parameter_id IS NULL OR CONVERT(varbinary(256),a.name)<>CONVERT(varbinary(256),e.ParameterName) OR a.system_type_id<>e.TypeId OR a.max_length<>e.MaxLength OR a.is_output<>0)
    OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id IN(OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicRange'),OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicDateShift'),OBJECT_ID(N'toolbelt_pseudonymization.USP_DeterministicLookup'),OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicTranslate'),OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicGeoJitter')) AND parameter_id>0)<>33
    THROW 54090,N'Deterministic: öffentliches Parameterinventar verletzt.',1;
-- geography muss die native Spatial-UDT sein, kein beliebiger Typ mit ID 240.
IF NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicGeoJitter')
 AND parameter_id=1 AND user_type_id=TYPE_ID(N'sys.geography'))
 OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicGeoJitter')
 AND column_id=1 AND name=N'Value' AND user_type_id=TYPE_ID(N'sys.geography') AND is_nullable=1)
 OR NOT EXISTS(SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicGeoJitter')
 AND column_id=2 AND name=N'ErrorCode' AND system_type_id=56 AND is_nullable=0)
 OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicGeoJitter'))<>2
 THROW 54090,N'Deterministic: GeoJitter geography-/Spaltenvertrag verletzt.',1;
PRINT N'PASS: Deterministic Release/API/Hashes ohne Rechteaenderung';
GO
