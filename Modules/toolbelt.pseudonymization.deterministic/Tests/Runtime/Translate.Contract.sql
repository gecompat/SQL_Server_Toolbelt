-- Synthetische Vertragsorakel; keine Verarbeitung realer Kennungen.
SET NOCOUNT ON;
DECLARE @ObjectId int = OBJECT_ID(N'toolbelt_pseudonymization.TVF_DeterministicTranslate', N'IF');
IF @ObjectId IS NULL THROW 54090, N'Translate muss eine echte Inline-TVF sein.', 1;
DECLARE @Columns TABLE (Ordinal int, Name sysname, TypeId int, MaxLength int, IsNullable bit);
INSERT @Columns VALUES (1,N'Value',231,-1,1),(2,N'ErrorCode',56,4,0);
IF EXISTS (SELECT 1 FROM @Columns AS expected
    LEFT JOIN sys.columns AS actual ON actual.object_id=@ObjectId AND actual.column_id=expected.Ordinal
    WHERE actual.column_id IS NULL OR actual.name COLLATE Latin1_General_100_BIN2<>expected.Name COLLATE Latin1_General_100_BIN2
        OR actual.system_type_id<>expected.TypeId OR actual.max_length<>expected.MaxLength OR actual.is_nullable<>expected.IsNullable)
    OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=@ObjectId)<>2
    OR EXISTS (SELECT 1 FROM sys.columns WHERE object_id=@ObjectId AND column_id=1 AND ISNULL(collation_name,N'')<>N'Latin1_General_100_BIN2')
    THROW 54090, N'Translate-Spaltenmetadaten sind falsch.', 1;
DECLARE @Parameters TABLE (Ordinal int, Name sysname, TypeId int, MaxLength int);
INSERT @Parameters VALUES (1,N'@Value',231,-1),(2,N'@MappingVersion',56,4),(3,N'@Seed',127,8),(4,N'@AllowedSeparators',231,-1),(5,N'@Profile',231,-1);
IF EXISTS (SELECT 1 FROM @Parameters AS expected
    LEFT JOIN sys.parameters AS actual ON actual.object_id=@ObjectId AND actual.parameter_id=expected.Ordinal
    WHERE actual.parameter_id IS NULL OR actual.name COLLATE Latin1_General_100_BIN2<>expected.Name COLLATE Latin1_General_100_BIN2
        OR actual.system_type_id<>expected.TypeId OR actual.max_length<>expected.MaxLength)
    OR (SELECT COUNT(*) FROM sys.parameters WHERE object_id=@ObjectId)<>5
    THROW 54090, N'Translate-Parametermetadaten sind falsch.', 1;

DECLARE @Min bigint=CONVERT(bigint,'-9223372036854775808'), @Max bigint=CONVERT(bigint,'9223372036854775807');
DECLARE @Alphabet nvarchar(max)=N'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
DECLARE @Vectors TABLE (MappingVersion int, Seed bigint, Expected nvarchar(max));
INSERT @Vectors VALUES
 (1,0,N'simvxkhroqdtbwnlguyzpefacjSIMVXKHROQDTBWNLGUYZPEFACJ6301725984'),
 (1,1,N'pajteydqszxviorhfwlcbmungkPAJTEYDQSZXVIORHFWLCBMUNGK7348015269'),
 (2,0,N'aqxfpbuvdntkeliogjchryzswmAQXFPBUVDNTKELIOGJCHRYZSWM3845210769'),
 (2147483647,@Min,N'lfahyntkmjvgdsocbzwxeruqipLFAHYNTKMJVGDSOCBZWXERUQIP3540129867'),
 (1,@Max,N'buevmpwczixgaynshqftrkdjloBUEVMPWCZIXGAYNSHQFTRKDJLO6741329850');
IF EXISTS (SELECT 1 FROM @Vectors AS vector
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicTranslate(@Alphabet,vector.MappingVersion,vector.Seed,N'',N'standard') AS actual
    WHERE actual.Value IS NULL OR CONVERT(varbinary(max),actual.Value)<>CONVERT(varbinary(max),vector.Expected) OR actual.ErrorCode<>0)
    OR (SELECT COUNT(*) FROM @Vectors AS vector CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicTranslate(@Alphabet,vector.MappingVersion,vector.Seed,N'',N'standard'))<>5
    THROW 54090, N'Translate-Mappingvektoren oder Einzeilenvertrag sind falsch.', 1;
IF NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'aA0',1,DEFAULT,DEFAULT,DEFAULT)
    WHERE CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N'sS6') AND ErrorCode=0)
    THROW 54090, N'Translate-Defaults sind falsch.', 1;

-- Unabhängige feste Hashframes; Encoderverwendung und signed Seedgrenzen.
IF EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicIntegerBytes(1) AS versionBytes
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicIntegerBytes(0) AS seedBytes
    WHERE HASHBYTES('SHA2_256',CONVERT(varbinary(max),0x5442584454524E31)+SUBSTRING(versionBytes.Bytes,5,4)+seedBytes.Bytes+0x0000)
        <>0xE70CD08926A33130655B7C0C3D647E62F90D664E08E9A7F1D9676B32626953D6)
    OR EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicIntegerBytes(2147483647) AS versionBytes
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicIntegerBytes(@Min) AS seedBytes
    WHERE HASHBYTES('SHA2_256',CONVERT(varbinary(max),0x5442584454524E31)+SUBSTRING(versionBytes.Bytes,5,4)+seedBytes.Bytes+0x0109)
        <>0xA34D48A3F37D6AE66C948F2DDF42B2DFB4C0575C03848C2D01AA7B27CE0FF6EE)
    THROW 54090, N'Translate-Hashframes sind falsch.', 1;

DECLARE @Separators nvarchar(max)=N' !"#$%&''()*+,-./:;<=>?@[\]^_`{|}~';
IF DATALENGTH(@Separators)<>66 THROW 54090, N'Synthetischer Separatorvorrat ist falsch.', 1;
IF NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(@Separators,1,0,@Separators,N'standard')
    WHERE CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),@Separators) AND ErrorCode=0)
    OR NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'a-A_0 ',1,0,N'-_ ',N'standard')
    WHERE CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),N's-S_6 ') AND ErrorCode=0)
    OR NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(N'',1,0,N'',N'standard')
    WHERE DATALENGTH(Value)=0 AND ErrorCode=0)
    THROW 54090, N'Separatoren, Case oder Leertext sind falsch.', 1;

DECLARE @Errors TABLE (Value nvarchar(max), MappingVersion int, Seed bigint, Separators nvarchar(max), Profile nvarchar(max), Expected int);
INSERT @Errors VALUES
 (NULL,NULL,NULL,NULL,NULL,0),(N'x',NULL,NULL,NULL,NULL,1),(N'x',0,NULL,NULL,NULL,1),
 (N'x',1,NULL,NULL,NULL,2),(N'x',1,0,NULL,NULL,10),(N'x',1,0,NULL,N'standard',11),
 (N'x',1,0,N'',N'standard ',10),(N'x',1,0,N'',N'STANDARD',10),(N'x',1,0,N'',N'large ',10),
 (N'x',1,0,N'--',N'standard',11),(N'x',1,0,N'a',N'standard',11),(N'x',1,0,N'0',N'standard',11),
 (N'x',1,0,NCHAR(0),N'standard',11),(N'x',1,0,NCHAR(9),N'standard',11),
 (N'x',1,0,CONVERT(nvarchar(max),0x00D8),N'standard',11),
 (N'x',1,0,@Separators+N'-',N'standard',11),
 (N'-',1,0,N'',N'standard',13),(N' ',1,0,N'',N'standard',13),
 (NCHAR(0),1,0,N'',N'standard',13),(NCHAR(9),1,0,N'',N'standard',13),
 (NCHAR(127),1,0,N'',N'standard',13),(N'ä',1,0,N'',N'standard',13),
 (CONVERT(nvarchar(max),0x00D8),1,0,N'',N'standard',13),
 (CONVERT(nvarchar(max),0xFFDF),1,0,N'',N'standard',13),
 (CONVERT(nvarchar(max),0x3DD800DE),1,0,N'',N'standard',13),
 (REPLICATE(CONVERT(nvarchar(max),N'a'),1048577),1,0,N'',N'standard',12),
 (REPLICATE(CONVERT(nvarchar(max),N'a'),1048577)+N'-',1,0,N'',N'standard',12),
 (N'x',1,0,REPLICATE(CONVERT(nvarchar(max),N'-'),1048576),N'standard',11);
IF EXISTS (SELECT 1 FROM @Errors AS example
    CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicTranslate(example.Value,example.MappingVersion,example.Seed,example.Separators,example.Profile) AS actual
    WHERE actual.Value IS NOT NULL OR actual.ErrorCode IS NULL OR actual.ErrorCode<>example.Expected)
    OR (SELECT COUNT(*) FROM @Errors AS example CROSS APPLY toolbelt_pseudonymization.TVF_DeterministicTranslate(example.Value,example.MappingVersion,example.Seed,example.Separators,example.Profile))<>(SELECT COUNT(*) FROM @Errors)
    THROW 54090, N'Translate-Fehlerpriorität, sichere Operanden oder NULL-Vertrag sind falsch.', 1;

-- Tatsächliche MAX-Strings: Ceiling, +1 und Unknown im letzten Codeunit.
DECLARE @Standard nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'a'),1048576);
DECLARE @Large nvarchar(max)=REPLICATE(CONVERT(nvarchar(max),N'A'),8388608);
IF NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(@Standard,1,0,N'',N'standard')
    WHERE DATALENGTH(Value)=2097152 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),N's'),1048576)) AND ErrorCode=0)
    OR NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(@Large,1,0,N'',N'large')
    WHERE DATALENGTH(Value)=16777216 AND CONVERT(varbinary(max),Value)=CONVERT(varbinary(max),REPLICATE(CONVERT(nvarchar(max),N'S'),8388608)) AND ErrorCode=0)
    OR NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(@Large+N'A',1,0,N'',N'large') WHERE Value IS NULL AND ErrorCode=12)
    OR NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(STUFF(@Standard,1048576,1,N'-'),1,0,N'',N'standard') WHERE Value IS NULL AND ErrorCode=13)
    OR NOT EXISTS (SELECT 1 FROM toolbelt_pseudonymization.TVF_DeterministicTranslate(STUFF(@Large,8388608,1,N'-'),1,0,N'',N'large') WHERE Value IS NULL AND ErrorCode=13)
    THROW 54090, N'Translate-Profilceiling, MAX oder letztes Unknown sind falsch.', 1;
PRINT N'PASS: Translate synthetischer Vertrag';
GO
