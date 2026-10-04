-- Read-only Installed-Lifecycle-Witness, keine automatische Mutation.
-- Erwartung wird vom getrennt qualifizierten Binary/Release-Manifest geliefert.
SET NOCOUNT ON;
DECLARE @Text nvarchar(max)=N'$(ExpectedInstalledAssemblyHash)',@Expected varbinary(64);
IF @Text IS NULL OR DATALENGTH(@Text)<>260 OR LEFT(@Text,2)<>N'0x'
 OR TRY_CONVERT(varbinary(max),@Text,1) IS NULL OR DATALENGTH(TRY_CONVERT(varbinary(max),@Text,1))<>64
 THROW 55284,N'Die vollständige installierte SHA2-512-Erwartung fehlt.',1;
SET @Expected=CONVERT(varbinary(64),@Text,1);
DECLARE @Assembly int,@Owner int,@Hash varbinary(64);
SELECT @Assembly=a.assembly_id,@Owner=a.principal_id,@Hash=HASHBYTES(N'SHA2_512',f.content)
FROM sys.assemblies a JOIN sys.assembly_files f ON a.assembly_id=f.assembly_id AND f.file_id=1
WHERE CONVERT(varbinary(max),a.name)=CONVERT(varbinary(max),N'Toolbelt_String_Phonetic');
IF @Assembly IS NULL OR @Hash IS NULL OR @Hash<>@Expected OR (SELECT COUNT(*) FROM sys.assembly_files WHERE assembly_id=@Assembly)<>1
 THROW 55284,N'Die installierten Assemblybytes stimmen nicht.',2;
IF NOT EXISTS(SELECT 1 FROM sys.schemas WHERE schema_id=SCHEMA_ID(N'toolbelt_string') AND principal_id=@Owner)
 OR EXISTS(SELECT 1 FROM sys.objects o JOIN sys.schemas s ON o.schema_id=s.schema_id WHERE o.schema_id=SCHEMA_ID(N'toolbelt_string') AND o.name IN(N'TVF_ColognePhonetic',N'TVF_DoubleMetaphone',N'TVF_ColognePhoneticCore',N'TVF_DoubleMetaphoneCore') AND COALESCE(o.principal_id,s.principal_id)<>@Owner)
 THROW 55284,N'Die effektiven eigenen Eigentümer stimmen nicht.',3;
IF NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.string.phonetic.Version' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0'))
 THROW 55284,N'Der installierte Release-Marker fehlt.',4;
PRINT 'PASS PHONETIC_INSTALLED_HASH_OWNER';
GO