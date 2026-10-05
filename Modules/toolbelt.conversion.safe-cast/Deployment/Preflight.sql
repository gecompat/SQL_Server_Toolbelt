-- Gemeinsamer read-only Preflight; vom eigenen Deploy-/Uninstall-TRY umschlossen.
DECLARE @Module nvarchar(128)=N'toolbelt.conversion.safe-cast',@Version nvarchar(max),@InstalledMode nvarchar(max),
 @Installed bit,@SchemaId int,@SchemaOwner int,@Phase int=0;
DECLARE @Slots TABLE(Name sysname COLLATE DATABASE_DEFAULT PRIMARY KEY);
INSERT @Slots VALUES(N'TVF_TryCastBigInt'),(N'TVF_TryCastDecimal'),(N'TVF_TryCastDate'),
 (N'TVF_TryCastDateTime2'),(N'TVF_TryCastBit'),(N'TVF_TryCastUniqueIdentifier');
DECLARE @Own TABLE(Id int PRIMARY KEY);
IF ISNULL(TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')),0) NOT IN(15,16,17)
 THROW 55420,N'Safe Cast benötigt SQL Server 2019, 2022 oder 2025.',1;
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND compatibility_level IN(150,160,170)
 AND compatibility_level<=CASE TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) WHEN 15 THEN 150 WHEN 16 THEN 160 WHEN 17 THEN 170 END)
 THROW 55420,N'Compatibility Level passt nicht zur unterstützten SQL-Version.',2;
IF @Install=1 AND (@Mode IS NULL OR CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')))
 THROW 55420,N'DeploymentMode muss exakt local oder central sein.',3;
IF @Install=0 AND (@Confirm IS NULL OR @Confirm NOT IN(0,1))
 THROW 55426,N'ConfirmNoExternalConsumers muss exakt 0 oder 1 sein.',2;
WHILE @Phase<2
BEGIN
 IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
  OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
  THROW 55425,N'Vollständige Sicht auf Lifecyclemetadaten und Abhängigkeiten fehlt.',1;
 SELECT @Version=NULL,@InstalledMode=NULL,@Installed=0,@SchemaOwner=NULL;
 SELECT @Version=TRY_CONVERT(nvarchar(max),value),@Installed=1 FROM sys.extended_properties
  WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version';
 SELECT @InstalledMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
  WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.DeploymentMode';
 SET @SchemaId=SCHEMA_ID(N'toolbelt_conversion');
 SELECT @SchemaOwner=principal_id FROM sys.schemas WHERE schema_id=@SchemaId;
 IF @SchemaId IS NOT NULL AND (NOT EXISTS(SELECT 1 FROM sys.schemas WHERE schema_id=@SchemaId AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'toolbelt_conversion'))
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0 AND name=N'Toolbelt.Managed' AND TRY_CONVERT(bit,value)=1)
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0 AND name=N'Toolbelt.SchemaCategory' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'conversion')))
  THROW 55424,N'Geteiltes Schema ist nicht kohärent zugeordnet.',1;
 IF @Installed=1 AND (NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar')
  OR @Version IS NULL OR CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0')
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.DeploymentMode' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar')
  OR @InstalledMode IS NULL OR CONVERT(varbinary(max),@InstalledMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')))
  THROW 55424,N'Unbekannter Release oder inkohärenter Modus.',2;
 IF @Installed=0 AND (EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.DeploymentMode')
  OR EXISTS(SELECT 1 FROM @Slots WHERE OBJECT_ID(N'toolbelt_conversion.'+QUOTENAME(Name)) IS NOT NULL))
  THROW 55424,N'Fremde Zielslotbelegung oder unvollständiger Modulzustand.',3;
 IF @Installed=1 AND EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_conversion.'+QUOTENAME(s.Name))
  WHERE o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name) OR o.type<>'IF' OR COALESCE(o.principal_id,@SchemaOwner)<>@SchemaOwner
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'bit' AND TRY_CONVERT(bit,value)=1)
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Module))
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0'))
  OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.Visibility' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'public')))
  THROW 55424,N'Safe-Cast-Slot, Objekttyp oder Ownershipmarker ist inkohärent.',5;
 DELETE FROM @Own;
 INSERT @Own SELECT OBJECT_ID(N'toolbelt_conversion.'+QUOTENAME(Name)) FROM @Slots WHERE @Installed=1;
 IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE (d.referenced_id IN(SELECT Id FROM @Own)
  OR(d.referenced_id IS NULL AND (d.referenced_server_name IS NULL) AND (d.referenced_database_name IS NULL OR d.referenced_database_name COLLATE DATABASE_DEFAULT=DB_NAME())
   AND d.referenced_schema_name COLLATE DATABASE_DEFAULT=N'toolbelt_conversion' AND EXISTS(SELECT 1 FROM @Slots WHERE Name COLLATE DATABASE_DEFAULT=d.referenced_entity_name COLLATE DATABASE_DEFAULT)))
  AND d.referencing_id NOT IN(SELECT Id FROM @Own))
  THROW 55425,N'Fremder SQL-Verbraucher blockiert Safe-Cast-Lifecycle.',3;
 IF @Install=0 AND @Installed=0
 BEGIN
  IF @Phase=0 RETURN;
  THROW 55424,N'Modulzustand änderte sich während des Preflights.',6;
 END;
 IF @Install=0 AND CONVERT(varbinary(max),@InstalledMode)=CONVERT(varbinary(max),N'central') AND @Confirm<>1
  THROW 55426,N'Zentraler Uninstall benötigt explizite Consumerbestätigung.',1;
 IF @SchemaId IS NOT NULL AND ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_conversion',N'SCHEMA',N'ALTER'),0)<>1
  THROW 55427,N'Schema-ALTER fehlt; keine Rechtevergabe.',1;
 IF @Install=1 AND (@SchemaId IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE SCHEMA'),0)<>1)
  THROW 55427,N'CREATE SCHEMA fehlt; keine Rechtevergabe.',2;
 IF @Install=1 AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE FUNCTION'),0)<>1
  THROW 55427,N'CREATE FUNCTION fehlt; keine Rechtevergabe.',3;
 IF @Phase=0
 BEGIN
  BEGIN TRANSACTION;SET @OwnTransaction=1;
  DECLARE @Lock int;
  EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.conversion.safe-cast',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
  IF @Lock<0 THROW 55423,N'Paralleler Safe-Cast-Lifecycle aktiv.',1;
 END;
 SET @Phase+=1;
END;
IF @Install=1 AND @SchemaId IS NULL
BEGIN
 EXEC(N'CREATE SCHEMA toolbelt_conversion');
 DECLARE @SchemaManaged bit=CONVERT(bit,1);
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=@SchemaManaged,@level0type=N'SCHEMA',@level0name=N'toolbelt_conversion';
 EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'conversion',@level0type=N'SCHEMA',@level0name=N'toolbelt_conversion';
END;
IF @Installed=1
BEGIN
 DROP FUNCTION toolbelt_conversion.TVF_TryCastBigInt;
 DROP FUNCTION toolbelt_conversion.TVF_TryCastDecimal;
 DROP FUNCTION toolbelt_conversion.TVF_TryCastDate;
 DROP FUNCTION toolbelt_conversion.TVF_TryCastDateTime2;
 DROP FUNCTION toolbelt_conversion.TVF_TryCastBit;
 DROP FUNCTION toolbelt_conversion.TVF_TryCastUniqueIdentifier;
END;
