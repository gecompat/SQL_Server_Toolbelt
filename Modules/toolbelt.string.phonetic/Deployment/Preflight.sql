-- Gemeinsamer Lifecycle-Preflight, kein eigenständiger öffentlicher EntryPoint.
-- @Install, @AssemblyBits, @DeploymentMode und @ConfirmNoExternalConsumers
-- werden ausschließlich vom konkreten Deploy-/Uninstall-Adapter gesetzt.
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'Der Phonetik-Lifecycle akzeptiert keine Caller-Transaktion.',16,1);
    RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
DECLARE @ModuleId nvarchar(128)=N'toolbelt.string.phonetic',
        @VersionProperty sysname=N'Toolbelt.Module.toolbelt.string.phonetic.Version',
        @ModeProperty sysname=N'Toolbelt.Module.toolbelt.string.phonetic.DeploymentMode',
        @InstalledVersion nvarchar(max),@InstalledMode nvarchar(max),
        @Release bit,@AssemblyId int,@InstalledHash varbinary(64),
        @TargetHash varbinary(64)=HASHBYTES(N'SHA2_512',@AssemblyBits),
        @ExpectedHash varbinary(64),@ExpectedAbsent bit=0,
        @ExpectedText nvarchar(max)=N'$(ExpectedInstalledAssemblyHash)',
        @Pass int=1,@OwnTransaction bit=0,@SchemaId int,@SchemaOwner int;
DECLARE @Slots TABLE(Name sysname COLLATE DATABASE_DEFAULT PRIMARY KEY,
    Kind char(2) COLLATE DATABASE_DEFAULT NOT NULL,ObjectId int NULL,
    Method sysname NULL,CodeColumns int NOT NULL);
INSERT @Slots VALUES
 (N'TVF_ColognePhonetic','IF',NULL,NULL,1),
 (N'TVF_DoubleMetaphone','IF',NULL,NULL,2),
 (N'TVF_ColognePhoneticCore','FT',NULL,N'EvaluateCologne',1),
 (N'TVF_DoubleMetaphoneCore','FT',NULL,N'EvaluateDoubleMetaphone',2);
IF ISNULL(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
    THROW 55260,N'Phonetik unterstützt SQL Server 2019,2022,2025.',1;
IF @Install=1 AND (@DeploymentMode IS NULL OR CONVERT(varbinary(max),@DeploymentMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')) OR DATALENGTH(@DeploymentMode) NOT IN(10,14))
    THROW 55261,N'DeploymentMode muss local oder central sein.',1;
IF CONVERT(varbinary(max),@ExpectedText)=CONVERT(varbinary(max),N'0x') SET @ExpectedAbsent=1;
ELSE
BEGIN
    IF @ExpectedText IS NULL OR DATALENGTH(@ExpectedText)<>260
       OR CONVERT(varbinary(max),LEFT(@ExpectedText,2))<>CONVERT(varbinary(max),N'0x')
       OR SUBSTRING(@ExpectedText,3,128) COLLATE Latin1_General_100_BIN2 LIKE N'%[^0-9A-Fa-f]%'
       OR DATALENGTH(TRY_CONVERT(varbinary(max),@ExpectedText,1))<>64
       OR TRY_CONVERT(varbinary(max),@ExpectedText,1) IS NULL
        THROW 55262,N'ExpectedInstalledAssemblyHash muss 0x oder ein vollständiger SHA2-512-Hexhash sein.',1;
    SET @ExpectedHash=CONVERT(varbinary(64),@ExpectedText,1);
END;
BEGIN TRY
 WHILE @Pass<=2
 BEGIN
    IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
       OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
        THROW 55263,N'Vollständige Lifecycle-Metadatensicht fehlt; keine Rechtevergabe.',1;
    SET @InstalledVersion=NULL;SET @InstalledMode=NULL;SET @AssemblyId=NULL;SET @InstalledHash=NULL;
    SELECT @InstalledVersion=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@VersionProperty;
    SELECT @InstalledMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND major_id=0 AND minor_id=0 AND name=@ModeProperty;
    SET @Release=CASE WHEN CONVERT(varbinary(max),@InstalledVersion)=CONVERT(varbinary(max),N'1.0.0') THEN 1 ELSE 0 END;
    SELECT @AssemblyId=a.assembly_id,@InstalledHash=HASHBYTES(N'SHA2_512',f.content)
    FROM sys.assemblies a LEFT JOIN sys.assembly_files f ON f.assembly_id=a.assembly_id AND f.file_id=1
    WHERE a.name=N'Toolbelt_String_Phonetic';
    SET @SchemaId=SCHEMA_ID(N'toolbelt_string');
    SET @SchemaOwner=NULL;
    SELECT @SchemaOwner=principal_id FROM sys.schemas WHERE schema_id=@SchemaId;
    UPDATE s SET ObjectId=o.object_id FROM @Slots s LEFT JOIN sys.objects o
        ON o.schema_id=@SchemaId AND o.name COLLATE DATABASE_DEFAULT=s.Name;
    IF @SchemaId IS NOT NULL AND
       (NOT EXISTS(SELECT 1 FROM sys.schemas WHERE schema_id=@SchemaId AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'toolbelt_string'))
        OR @SchemaOwner IS NULL
        OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0 AND name=N'Toolbelt.Managed' AND TRY_CONVERT(int,value)=1)
        OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0 AND name=N'Toolbelt.SchemaCategory' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'string')))
        THROW 55264,N'Das vorhandene Schema ist nicht kohärent zugeordnet.',1;
    IF @Release=0 AND (EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name IN(@VersionProperty,@ModeProperty)) OR @AssemblyId IS NOT NULL OR EXISTS(SELECT 1 FROM @Slots WHERE ObjectId IS NOT NULL))
        THROW 55264,N'Unbekannter Modulzustand oder fremde Zielslotbelegung.',2;
    IF @Release=1 AND (@InstalledMode IS NULL OR CONVERT(varbinary(max),@InstalledMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')))
        THROW 55264,N'Der installierte Modus ist inkohärent.',3;
    IF (@Release=0 AND @ExpectedAbsent=0) OR (@Release=1 AND @ExpectedAbsent=1)
        THROW 55262,N'Die erwartete Assembly-Anwesenheit stimmt nicht.',2;
    IF @Release=1 AND (@InstalledHash IS NULL OR @InstalledHash<>@ExpectedHash)
        THROW 55265,N'Der installierte Hash stimmt nicht mit der Offline-Erwartung überein.',1;
    IF @Release=1 AND
      (NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE assembly_id=@AssemblyId AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_String_Phonetic') AND permission_set=1 AND is_user_defined=1 AND principal_id=@SchemaOwner)
       OR (SELECT COUNT(*) FROM sys.assembly_files WHERE assembly_id=@AssemblyId)<>1
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0 AND name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'bit' AND TRY_CONVERT(bit,value)=1)
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@ModuleId))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0')))
        THROW 55264,N'Assemblytyp, Eigentümer oder Marker sind inkohärent.',4;
    IF @Release=1 AND EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=s.ObjectId WHERE
       o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name) OR CONVERT(varbinary(2),o.type)<>CONVERT(varbinary(2),s.Kind)
       OR COALESCE(o.principal_id,@SchemaOwner)<>@SchemaOwner
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'bit' AND TRY_CONVERT(bit,value)=1)
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@ModuleId))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0'))
       OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.Visibility' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),CASE WHEN s.Kind='FT' THEN N'internal' ELSE N'public' END)))
        THROW 55264,N'Slottypen, Eigentümer oder Marker sind inkohärent.',5;
    IF @Release=1 AND EXISTS(SELECT 1 FROM @Slots s WHERE s.Kind='FT' AND NOT EXISTS
       (SELECT 1 FROM sys.assembly_modules m WHERE m.object_id=s.ObjectId AND m.assembly_id=@AssemblyId AND m.null_on_null_input=0 AND m.execute_as_principal_id IS NULL
        AND CONVERT(varbinary(max),m.assembly_class)=CONVERT(varbinary(max),N'Toolbelt.String.Phonetic.PhoneticBridge') AND CONVERT(varbinary(max),m.assembly_method)=CONVERT(varbinary(max),s.Method)))
        THROW 55264,N'Die CLR-EntryPoint-Bindung ist inkohärent.',6;
    IF @Release=1 AND EXISTS(SELECT 1 FROM @Slots s WHERE
       (SELECT COUNT(*) FROM sys.parameters WHERE object_id=s.ObjectId AND parameter_id>0)<>1
       OR NOT EXISTS(SELECT 1 FROM sys.parameters WHERE object_id=s.ObjectId AND parameter_id=1 AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'@Text') AND system_type_id=231 AND user_type_id=system_type_id AND max_length=-1 AND is_output=0 AND has_default_value=0)
       OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=s.ObjectId)<>s.CodeColumns+1
       OR EXISTS(SELECT 1 FROM sys.columns c WHERE c.object_id=s.ObjectId AND
          (c.user_type_id<>c.system_type_id OR
           (c.column_id<=s.CodeColumns AND (c.system_type_id<>CASE WHEN s.Kind='FT' THEN 231 ELSE 167 END OR c.max_length<>-1 OR c.is_nullable<>1 OR CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),CASE WHEN s.CodeColumns=1 THEN N'PhoneticCode' WHEN c.column_id=1 THEN N'PrimaryCode' ELSE N'AlternateCode' END)))
           OR(s.Kind='IF' AND c.column_id<=s.CodeColumns AND CONVERT(varbinary(max),c.collation_name)<>CONVERT(varbinary(max),N'Latin1_General_100_BIN2'))
           OR(c.column_id=s.CodeColumns+1 AND(c.system_type_id<>56 OR c.max_length<>4 OR CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),N'ErrorCode'))))))
        THROW 55264,N'Parameter oder Ergebnisfelder sind inkohärent.',7;
    IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE
       (EXISTS(SELECT 1 FROM @Slots WHERE ObjectId=d.referenced_id)
        OR(d.referenced_id IS NULL AND (d.referenced_database_name IS NULL OR d.referenced_database_name COLLATE DATABASE_DEFAULT=DB_NAME()) AND d.referenced_schema_name COLLATE DATABASE_DEFAULT=N'toolbelt_string' AND EXISTS(SELECT 1 FROM @Slots WHERE Name=d.referenced_entity_name COLLATE DATABASE_DEFAULT)))
        AND NOT EXISTS(SELECT 1 FROM @Slots WHERE ObjectId=d.referencing_id))
        THROW 55266,N'Ein fremder SQL-Verbraucher blockiert den Lifecycle.',1;
    IF EXISTS(SELECT 1 FROM sys.assembly_modules m WHERE m.assembly_id=@AssemblyId AND NOT EXISTS(SELECT 1 FROM @Slots WHERE Kind='FT' AND ObjectId=m.object_id))
       OR EXISTS(SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id=@AssemblyId)
        THROW 55266,N'Ein fremder Assembly-Verbraucher blockiert den Lifecycle.',2;
    IF @Install=0 AND @Release=1 AND CONVERT(varbinary(max),@InstalledMode)=CONVERT(varbinary(max),N'central') AND @ConfirmNoExternalConsumers<>1
        THROW 55267,N'Central-Uninstall benötigt explizite Consumerbestätigung.',1;
    IF @Install=1
    BEGIN
       IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits)<1024 OR @TargetHash IS NULL THROW 55268,N'AssemblyBits enthält kein vollständiges Binary.',1;
       IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
          OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
          THROW 55268,N'CLR enabled und strict security müssen bereits wirksam sein.',2;
       IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@TargetHash) THROW 55268,N'Der exakte Zielhash ist nicht separat autorisiert.',3;
       IF @AssemblyId IS NULL AND @SchemaId IS NOT NULL AND @SchemaOwner<>USER_ID() THROW 55269,N'Neue Assembly und vorhandenes Schema benötigen denselben effektiven Eigentümer.',1;
       IF @SchemaId IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE SCHEMA'),0)<>1 THROW 55269,N'CREATE SCHEMA fehlt.',2;
       IF @SchemaId IS NOT NULL AND ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string',N'SCHEMA',N'ALTER'),0)<>1 THROW 55269,N'Schema-ALTER fehlt.',3;
       IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE FUNCTION'),0)<>1 THROW 55269,N'CREATE FUNCTION fehlt.',4;
       IF @AssemblyId IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE ASSEMBLY'),0)<>1 THROW 55269,N'CREATE ASSEMBLY fehlt.',5;
       IF @AssemblyId IS NOT NULL AND @InstalledHash<>@TargetHash AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'ALTER ANY ASSEMBLY'),0)<>1 THROW 55269,N'ALTER ANY ASSEMBLY fehlt.',6;
    END;
    IF @Pass=1
    BEGIN
       BEGIN TRANSACTION;SET @OwnTransaction=1;
       DECLARE @LockResult int;
       EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.string.phonetic',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
       IF @LockResult<0 THROW 55270,N'Ein paralleler Phonetik-Lifecycle ist aktiv.',1;
    END;
    SET @Pass+=1;
 END;
 IF @Install=1 AND @SchemaId IS NULL
 BEGIN
    EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_string];';
    EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_string';
    EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'string',@level0type=N'SCHEMA',@level0name=N'toolbelt_string';
 END;
 IF @Release=1
 BEGIN
    DROP FUNCTION toolbelt_string.TVF_ColognePhonetic;
    DROP FUNCTION toolbelt_string.TVF_DoubleMetaphone;
    DROP FUNCTION toolbelt_string.TVF_ColognePhoneticCore;
    DROP FUNCTION toolbelt_string.TVF_DoubleMetaphoneCore;
 END;
 IF @Install=1
 BEGIN
    IF @AssemblyId IS NULL OR @InstalledHash<>@TargetHash
    BEGIN
       DECLARE @Ddl nvarchar(max)=CASE WHEN @AssemblyId IS NULL THEN N'CREATE' ELSE N'ALTER' END+N' ASSEMBLY [Toolbelt_String_Phonetic] FROM '+CONVERT(nvarchar(max),@AssemblyBits,1)+N' WITH PERMISSION_SET=SAFE;';
       EXEC sys.sp_executesql @Ddl;
    END;
 END
 ELSE
 BEGIN
    IF @Release=1
    BEGIN
       DROP ASSEMBLY Toolbelt_String_Phonetic;
       EXEC sys.sp_dropextendedproperty @name=@VersionProperty;
       EXEC sys.sp_dropextendedproperty @name=@ModeProperty;
       IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=@SchemaId) AND NOT EXISTS(SELECT 1 FROM sys.types WHERE schema_id=@SchemaId AND is_user_defined=1) AND NOT EXISTS(SELECT 1 FROM sys.xml_schema_collections WHERE schema_id=@SchemaId) DROP SCHEMA toolbelt_string;
    END;
    COMMIT TRANSACTION;SET @OwnTransaction=0;
 END;
END TRY
BEGIN CATCH
 IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
