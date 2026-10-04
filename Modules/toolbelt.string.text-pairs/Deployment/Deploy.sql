:On Error exit
-- SQLCMD: DeploymentMode=local|central, ExpectedComparisonAssemblyHash=0x+128hex.
-- Keine Assembly-/Trust-/Rechteänderung; bekannte Dependencies bleiben erhalten.
IF @@TRANCOUNT>0
BEGIN
    RAISERROR(N'TBX_TEXT_PAIRS_CALLER_TRANSACTION: Lifecycle erfordert keine aktive Caller-Transaktion.',16,1);
    RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
IF OBJECT_ID(N'tempdb..#tbx_TextPairs_Deploy',N'U') IS NOT NULL
    THROW 55120,N'Reservierter Lifecycle-Tempname ist belegt.',1;
CREATE TABLE #tbx_TextPairs_Deploy(DeploymentMode nvarchar(16) NOT NULL);
DECLARE @Mode nvarchar(max)=N'$(DeploymentMode)',@HashText nvarchar(max)=N'$(ExpectedComparisonAssemblyHash)',
        @ExpectedHash varbinary(max),@Pass int=1,@LockResult int,@ObjectId int,@SchemaId int,
        @Version nvarchar(max),@InstalledMode nvarchar(max);
IF CONVERT(varbinary(max),@Mode) NOT IN (CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
    THROW 55121,N'DeploymentMode muss bytegenau local oder central sein.',1;
IF DATALENGTH(@HashText)<>260 OR LEFT(@HashText,2) COLLATE Latin1_General_100_BIN2<>N'0x'
    THROW 55121,N'ExpectedComparisonAssemblyHash benötigt 0x und 128 Hexzeichen.',2;
SET @ExpectedHash=TRY_CONVERT(varbinary(max),@HashText,1);
IF @ExpectedHash IS NULL OR DATALENGTH(@ExpectedHash)<>64
    THROW 55121,N'ExpectedComparisonAssemblyHash ist kein vollständiger SHA2-512-Hash.',2;
IF TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN (15,16,17)
    THROW 55121,N'Unterstützt sind SQL Server 2019, 2022 und 2025.',3;
DECLARE @Slots TABLE(Name sysname NOT NULL,Kind char(2) NOT NULL,ModuleId nvarchar(128) NOT NULL,Version nvarchar(16) NOT NULL);
INSERT @Slots VALUES
 (N'TVF_LevenshteinDistance','IF',N'toolbelt.string.edit-distance',N'1.1.0'),
 (N'TVF_OsaDistance','IF',N'toolbelt.string.edit-distance',N'1.1.0'),
 (N'TVF_JaroWinklerSimilarity','IF',N'toolbelt.string.edit-distance',N'1.1.0'),
 (N'TVF_LevenshteinDistanceCore','FT',N'toolbelt.string.edit-distance',N'1.1.0'),
 (N'TVF_OsaDistanceCore','FT',N'toolbelt.string.edit-distance',N'1.1.0'),
 (N'TVF_JaroWinklerSimilarityCore','FT',N'toolbelt.string.edit-distance',N'1.1.0'),
 (N'USP_PrepareResultTable','P',N'toolbelt.core.result-table',N'1.0.0');
DECLARE @Parameters TABLE(Name sysname NOT NULL,Ordinal int NOT NULL,ParamName sysname NOT NULL,TypeId int NOT NULL,MaxLength smallint NOT NULL);
INSERT @Parameters
SELECT s.Name,v.Ordinal,v.ParamName,v.TypeId,v.MaxLength FROM @Slots s
CROSS JOIN (VALUES(1,N'@LeftText',231,-1),(2,N'@RightText',231,-1),(3,N'@MaxDistance',56,4),(4,N'@Profile',231,-1)) v(Ordinal,ParamName,TypeId,MaxLength)
WHERE s.Name IN(N'TVF_LevenshteinDistance',N'TVF_OsaDistance',N'TVF_LevenshteinDistanceCore',N'TVF_OsaDistanceCore');
INSERT @Parameters
SELECT s.Name,v.Ordinal,v.ParamName,v.TypeId,v.MaxLength FROM @Slots s
CROSS JOIN (VALUES(1,N'@LeftText',231,-1),(2,N'@RightText',231,-1),(3,N'@Profile',231,-1)) v(Ordinal,ParamName,TypeId,MaxLength)
WHERE s.Name IN(N'TVF_JaroWinklerSimilarity',N'TVF_JaroWinklerSimilarityCore');
INSERT @Parameters VALUES
 (N'USP_PrepareResultTable',1,N'@ResultTableToAlter',231,256),
 (N'USP_PrepareResultTable',2,N'@LikeTable',231,1552),
 (N'USP_PrepareResultTable',3,N'@KeepData',104,1),
 (N'USP_PrepareResultTable',4,N'@Debug',48,1),
 (N'USP_PrepareResultTable',5,N'@Hilfe',104,1);
DECLARE @Columns TABLE(Name sysname NOT NULL,Ordinal int NOT NULL,ColumnName sysname NOT NULL,TypeId int NOT NULL,MaxLength smallint NOT NULL);
INSERT @Columns
SELECT s.Name,v.Ordinal,v.ColumnName,v.TypeId,v.MaxLength FROM @Slots s
CROSS JOIN (VALUES(1,N'Distance',56,4),(2,N'ExceedsMaxDistance',104,1),(3,N'ErrorCode',56,4)) v(Ordinal,ColumnName,TypeId,MaxLength)
WHERE s.Name IN(N'TVF_LevenshteinDistance',N'TVF_OsaDistance',N'TVF_LevenshteinDistanceCore',N'TVF_OsaDistanceCore');
INSERT @Columns
SELECT s.Name,v.Ordinal,v.ColumnName,v.TypeId,v.MaxLength FROM @Slots s
CROSS JOIN (VALUES(1,N'Similarity',62,8),(2,N'ErrorCode',56,4)) v(Ordinal,ColumnName,TypeId,MaxLength)
WHERE s.Name IN(N'TVF_JaroWinklerSimilarity',N'TVF_JaroWinklerSimilarityCore');
BEGIN TRY
    -- Gleicher vollständiger Gatecode vor Mutation und frisch unter AppLock.
    WHILE @Pass<=2
    BEGIN
        IF COALESCE(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
           OR COALESCE(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
            THROW 55122,N'Vollständige Lifecycle-Metadatensicht fehlt.',1;
        IF EXISTS
        (
            SELECT 1 FROM @Slots s
            LEFT JOIN sys.schemas sc ON CONVERT(varbinary(max),sc.name)=CONVERT(varbinary(max),CASE WHEN s.Kind='P' THEN N'toolbelt_core' ELSE N'toolbelt_string' END)
            LEFT JOIN sys.objects o ON o.schema_id=sc.schema_id AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),s.Name)
            WHERE o.object_id IS NULL OR CONVERT(varbinary(max),o.type)<>CONVERT(varbinary(max),s.Kind)
               OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),s.ModuleId))
               OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),s.Version))
               -- Der bekannte Distanzrelease bindet Mode am Datenbankmarker,
               -- der ResultTable-Release zusätzlich am eigenen P-Objekt.
               OR (s.Kind='P' AND NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),@Mode)))
               OR EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0 AND e.name=N'Toolbelt.DeploymentMode' AND
                  (TRY_CONVERT(nvarchar(max),e.value) IS NULL OR CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))<>CONVERT(varbinary(max),@Mode)))
        ) THROW 55123,N'Bekannte Dependency-Slots/Marker/Version/Mode fehlen oder sind inkohärent.',1;
        IF EXISTS(SELECT 1 FROM (VALUES(N'toolbelt.string.edit-distance',N'1.1.0'),(N'toolbelt.core.result-table',N'1.0.0')) d(ModuleId,Version)
           WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=0 AND e.major_id=0 AND e.minor_id=0
             AND e.name=N'Toolbelt.Module.'+d.ModuleId+N'.Version' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),d.Version))
             OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=0 AND e.major_id=0 AND e.minor_id=0
             AND e.name=N'Toolbelt.Module.'+d.ModuleId+N'.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),@Mode)))
            THROW 55123,N'Dependency-Datenbankmarker fehlen oder sind inkohärent.',3;
        IF EXISTS
        (
            SELECT 1 FROM @Slots s
            JOIN sys.objects o ON o.schema_id=SCHEMA_ID(CASE WHEN s.Kind='P' THEN N'toolbelt_core' ELSE N'toolbelt_string' END) AND CONVERT(varbinary(max),o.name)=CONVERT(varbinary(max),s.Name)
            WHERE (SELECT COUNT(*) FROM sys.parameters p WHERE p.object_id=o.object_id AND p.parameter_id>0)<>(SELECT COUNT(*) FROM @Parameters x WHERE x.Name=s.Name)
              OR EXISTS(SELECT 1 FROM @Parameters x LEFT JOIN sys.parameters p ON p.object_id=o.object_id AND p.parameter_id=x.Ordinal WHERE x.Name=s.Name AND (p.parameter_id IS NULL OR CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),x.ParamName) OR p.system_type_id<>x.TypeId OR p.user_type_id NOT IN(p.system_type_id,256) OR p.max_length<>x.MaxLength OR p.is_output<>0))
              OR (s.Kind<>'P' AND ((SELECT COUNT(*) FROM sys.columns c WHERE c.object_id=o.object_id)<>(SELECT COUNT(*) FROM @Columns x WHERE x.Name=s.Name)
                 OR EXISTS(SELECT 1 FROM @Columns x LEFT JOIN sys.columns c ON c.object_id=o.object_id AND c.column_id=x.Ordinal WHERE x.Name=s.Name AND (c.column_id IS NULL OR CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),x.ColumnName) OR c.system_type_id<>x.TypeId OR c.user_type_id<>c.system_type_id OR c.max_length<>x.MaxLength))))
        ) THROW 55123,N'Dependency-Parameter oder Resulttypen weichen vom bekannten Vertrag ab.',2;
        DECLARE @AssemblyId int;
        SET @AssemblyId=NULL;
        SELECT @AssemblyId=a.assembly_id FROM sys.assemblies a WHERE CONVERT(varbinary(max),a.name)=CONVERT(varbinary(max),N'Toolbelt_String_EditDistance') AND a.permission_set=1 AND a.is_user_defined=1;
        IF @AssemblyId IS NULL
           OR NOT EXISTS(SELECT 1 FROM sys.assembly_files f WHERE f.assembly_id=@AssemblyId AND f.file_id=1 AND HASHBYTES(N'SHA2_512',f.content)=@ExpectedHash)
           OR (SELECT COUNT(*) FROM sys.assembly_modules m JOIN @Slots s ON s.Kind='FT' AND m.object_id=OBJECT_ID(N'toolbelt_string.'+QUOTENAME(s.Name)) WHERE m.assembly_id=@AssemblyId
                AND CONVERT(varbinary(max),m.assembly_class)=CONVERT(varbinary(max),CASE WHEN s.Name=N'TVF_JaroWinklerSimilarityCore' THEN N'Toolbelt.String.EditDistance.JaroProvider' ELSE N'Toolbelt.String.EditDistance.DistanceProvider' END)
                AND CONVERT(varbinary(max),m.assembly_method)=CONVERT(varbinary(max),CASE s.Name WHEN N'TVF_LevenshteinDistanceCore' THEN N'Levenshtein' WHEN N'TVF_OsaDistanceCore' THEN N'Osa' ELSE N'Evaluate' END))<>3
            THROW 55124,N'Exakte SAFE-Assembly-/SHA2-512-/Methodenbindung fehlt.',1;
        SET @SchemaId=SCHEMA_ID(N'toolbelt_string');
        SET @ObjectId=OBJECT_ID(N'toolbelt_string.USP_CompareTextPairs');
        SET @Version=NULL; SET @InstalledMode=NULL;
        SELECT @Version=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.string.text-pairs.Version';
        SELECT @InstalledMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.string.text-pairs.DeploymentMode';
        IF (@ObjectId IS NULL AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name IN(N'Toolbelt.Module.toolbelt.string.text-pairs.Version',N'Toolbelt.Module.toolbelt.string.text-pairs.DeploymentMode')))
           OR (@ObjectId IS NOT NULL AND
              (NOT EXISTS(SELECT 1 FROM sys.objects WHERE object_id=@ObjectId AND type=N'P') OR @Version IS NULL OR @InstalledMode IS NULL
               OR CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0') OR CONVERT(varbinary(max),@InstalledMode)<>CONVERT(varbinary(max),@Mode)
               OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=@ObjectId AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.string.text-pairs'))
               OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=@ObjectId AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'1.0.0'))
               OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=@ObjectId AND e.minor_id=0 AND e.name=N'Toolbelt.DeploymentMode' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),@Mode))))
            THROW 55125,N'Eigener Release-/Objektzustand ist unbekannt oder kollidiert.',1;
        IF EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId'
            AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),e.value))=CONVERT(varbinary(max),N'toolbelt.string.text-pairs') AND (@ObjectId IS NULL OR e.major_id<>@ObjectId))
            THROW 55125,N'Zusätzliche unbekannte Modulobjekte bleiben erhalten.',2;
        IF @Pass=1
        BEGIN
            BEGIN TRANSACTION;
            EXEC @LockResult=sys.sp_getapplock @Resource=N'Toolbelt.Module.toolbelt.string.text-pairs',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=15000;
            IF @LockResult<0 THROW 55126,N'Lifecycle-AppLock konnte nicht erworben werden.',1;
        END;
        SET @Pass+=1;
    END;
    -- Dependency benötigt bereits toolbelt_string; ein fremdes Schema wird
    -- weder adoptiert noch umgeowned. Dieses Release erstellt kein Schema.
    INSERT #tbx_TextPairs_Deploy VALUES(CONVERT(nvarchar(16),@Mode));
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
:r ../Source/USP_CompareTextPairs.sql
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    DECLARE @ObjectId int=OBJECT_ID(N'toolbelt_string.USP_CompareTextPairs',N'P'),@Mode nvarchar(16),@SourceHash nvarchar(64);
    SELECT @Mode=DeploymentMode FROM #tbx_TextPairs_Deploy;
    IF XACT_STATE()<>1 OR @ObjectId IS NULL OR @Mode IS NULL THROW 55127,N'Installation ist nicht vollständig in eigener Transaktion.',1;
    SET @SourceHash=CONVERT(nvarchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@ObjectId))),2);
    IF @SourceHash IS NULL THROW 55127,N'SourceHash ist nicht sichtbar.',2;
    DECLARE @Properties TABLE(Ordinal int IDENTITY NOT NULL,Name sysname NOT NULL,Value nvarchar(4000) NOT NULL);
    INSERT @Properties(Name,Value) VALUES(N'Toolbelt.ModuleId',N'toolbelt.string.text-pairs'),(N'Toolbelt.ModuleVersion',N'1.0.0'),(N'Toolbelt.ContractVersion',N'1.0'),(N'Toolbelt.DeploymentMode',@Mode),(N'Toolbelt.SourceHash',@SourceHash);
    DECLARE @i int=1,@Name sysname,@Value nvarchar(4000);
    WHILE @i<=5
    BEGIN
        SELECT @Name=Name,@Value=Value FROM @Properties WHERE Ordinal=@i;
        IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=@Name)
            EXEC sys.sp_updateextendedproperty @name=@Name,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'PROCEDURE',@level1name=N'USP_CompareTextPairs';
        ELSE EXEC sys.sp_addextendedproperty @name=@Name,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_string',@level1type=N'PROCEDURE',@level1name=N'USP_CompareTextPairs';
        SET @i+=1;
    END;
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.string.text-pairs.Version')
        EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.text-pairs.Version',@value=N'1.0.0';
    ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.string.text-pairs.Version',@value=N'1.0.0';
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=N'Toolbelt.Module.toolbelt.string.text-pairs.DeploymentMode')
        EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.string.text-pairs.DeploymentMode',@value=@Mode;
    ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.string.text-pairs.DeploymentMode',@value=@Mode;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
DROP TABLE #tbx_TextPairs_Deploy;
GO
