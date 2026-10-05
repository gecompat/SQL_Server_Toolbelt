-- Gemeinsamer CSV-Lifecycle: read-only Preflight zweimal, dann eigene atomare DDL.
-- Nur Deploy/Uninstall setzen @Install, @Bits, @Mode und @Confirm.
IF @@TRANCOUNT<>0
BEGIN
 RAISERROR(N'TBX_CSV_LIFECYCLE_CALLER_TRANSACTION: Ein eigener Transaktionsscope ist erforderlich.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Module nvarchar(128)=N'toolbelt.file.csv-memory',@Version nvarchar(max),
 @InstalledMode nvarchar(max),@AssemblyId int,@SchemaId int,@SchemaOwner int,
 @Installed bit,@Phase int=0,@OwnTransaction bit=0,@Hash varbinary(64)=HASHBYTES('SHA2_512',@Bits);
DECLARE @Slots TABLE(Name sysname COLLATE DATABASE_DEFAULT PRIMARY KEY,Kind char(2) COLLATE DATABASE_DEFAULT NOT NULL,Method sysname NULL);
INSERT @Slots VALUES(N'USP_ParseCsv','P',NULL),(N'USP_WriteCsv','P',NULL),
 (N'TVF_InternalParseCsv','FT',N'Parse'),(N'SVF_InternalQuoteCsvCell','FS',N'QuoteCell'),(N'SVF_InternalMeasureCsvCell','FS',N'MeasureCell');
DECLARE @Own TABLE(Id int PRIMARY KEY);
-- CLR-Transportsignaturen sind Teil der technischen Releaseidentität.
DECLARE @Parameters TABLE(Name sysname,Ordinal int,ParameterName sysname,TypeId int,Length smallint);
INSERT @Parameters VALUES
 (N'TVF_InternalParseCsv',1,N'@Text',231,-1),(N'TVF_InternalParseCsv',2,N'@Separator',231,4),(N'TVF_InternalParseCsv',3,N'@HasHeader',104,1),(N'TVF_InternalParseCsv',4,N'@NullToken',231,256),
 (N'TVF_InternalParseCsv',5,N'@MaxRows',127,8),(N'TVF_InternalParseCsv',6,N'@MaxColumns',56,4),(N'TVF_InternalParseCsv',7,N'@MaxCells',127,8),(N'TVF_InternalParseCsv',8,N'@MaxInputBytes',127,8),
 (N'SVF_InternalMeasureCsvCell',0,N'',127,8),(N'SVF_InternalMeasureCsvCell',1,N'@Value',231,-1),(N'SVF_InternalMeasureCsvCell',2,N'@Separator',231,4),(N'SVF_InternalMeasureCsvCell',3,N'@NullToken',231,256),(N'SVF_InternalMeasureCsvCell',4,N'@IsHeader',104,1),
 (N'SVF_InternalQuoteCsvCell',0,N'',231,-1),(N'SVF_InternalQuoteCsvCell',1,N'@Value',231,-1),(N'SVF_InternalQuoteCsvCell',2,N'@Separator',231,4),(N'SVF_InternalQuoteCsvCell',3,N'@NullToken',231,256),(N'SVF_InternalQuoteCsvCell',4,N'@IsHeader',104,1),(N'SVF_InternalQuoteCsvCell',5,N'@MaxOutputBytes',127,8);
DECLARE @Columns TABLE(Ordinal int,Name sysname,TypeId int,Length smallint);
INSERT @Columns VALUES(1,N'RowKind',231,12),(2,N'RowOrdinal',127,8),(3,N'ColumnOrdinal',56,4),(4,N'Value',231,-1),(5,N'ErrorCode',56,4);
IF ISNULL(TRY_CONVERT(int,SERVERPROPERTY('ProductMajorVersion')),0) NOT IN(15,16,17)
 THROW 55320,N'CSV benötigt SQL Server 2019, 2022 oder 2025.',1;
IF NOT EXISTS(SELECT 1 FROM sys.databases WHERE database_id=DB_ID() AND compatibility_level IN(150,160,170)
 AND compatibility_level<=CASE TRY_CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) WHEN 15 THEN 150 WHEN 16 THEN 160 WHEN 17 THEN 170 END)
 THROW 55320,N'CSV benötigt einen zur SQL-Version passenden CL150/160/170.',3;
IF @Install=1 AND (@Mode IS NULL OR CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')))
 THROW 55320,N'DeploymentMode muss exakt local oder central sein.',2;
IF @Install=1 AND (@Bits IS NULL OR DATALENGTH(@Bits)<1024 OR @Hash IS NULL)
 THROW 55321,N'Vollständiges Releasebinary fehlt.',1;
IF @Install=0 AND (@Confirm IS NULL OR @Confirm NOT IN(0,1))
 THROW 55326,N'ConfirmNoExternalConsumers muss exakt 0 oder 1 sein.',2;
BEGIN TRY
 WHILE @Phase<2
 BEGIN
  IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
   OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
   THROW 55325,N'Vollständige Sicht auf Lifecyclemetadaten und SQL-Abhängigkeiten fehlt.',1;
  IF @Install=1
  BEGIN
   IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
    OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
    OR NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash)
    THROW 55321,N'CLR, strict security und separat autorisierter exakter Zielhashtrust fehlen.',2;
   DECLARE @DependencyVersion nvarchar(max)=NULL,@DependencyObject int=OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P');
   SELECT @DependencyVersion=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
   DECLARE @Major int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,3)),@Minor int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,2)),@Patch int=TRY_CONVERT(int,PARSENAME(@DependencyVersion,1));
   IF @DependencyObject IS NULL OR @Major IS NULL OR @Major<1 OR @Minor IS NULL OR @Minor<0 OR @Patch IS NULL OR @Patch<0
    OR CONVERT(varbinary(max),@DependencyVersion)<>CONVERT(varbinary(max),CONCAT(@Major,N'.',@Minor,N'.',@Patch))
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyObject AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.core.result-table'))
    OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@DependencyObject AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@DependencyVersion))
    THROW 55322,N'Kanonische sameDB-ResultTable-Abhängigkeit >=1.0.0 fehlt.',1;
  END;
  SELECT @Version=NULL,@InstalledMode=NULL,@AssemblyId=NULL,@Installed=0,@SchemaOwner=NULL;
  SELECT @Version=TRY_CONVERT(nvarchar(max),value),@Installed=1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.csv-memory.Version';
  SELECT @InstalledMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.csv-memory.DeploymentMode';
  SELECT @AssemblyId=assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_CsvMemory';
  SET @SchemaId=SCHEMA_ID(N'toolbelt_file');
  SELECT @SchemaOwner=principal_id FROM sys.schemas WHERE schema_id=@SchemaId;
  IF @SchemaId IS NOT NULL AND (NOT EXISTS(SELECT 1 FROM sys.schemas WHERE schema_id=@SchemaId AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'toolbelt_file'))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0 AND name=N'Toolbelt.Managed' AND TRY_CONVERT(bit,value)=1)
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=@SchemaId AND minor_id=0 AND name=N'Toolbelt.SchemaCategory' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'file')))
   THROW 55324,N'Vorhandenes Schema ist nicht kohärent zugeordnet.',1;
  IF @Installed=1 AND (@Version IS NULL OR CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0') OR @InstalledMode IS NULL OR CONVERT(varbinary(max),@InstalledMode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central')))
   THROW 55324,N'Unbekannter CSV-Release oder inkohärenter Modus.',2;
  IF @Installed=0 AND (EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.csv-memory.DeploymentMode') OR @AssemblyId IS NOT NULL OR EXISTS(SELECT 1 FROM @Slots WHERE OBJECT_ID(N'toolbelt_file.'+QUOTENAME(Name)) IS NOT NULL))
   THROW 55324,N'Fremde Zielslotbelegung oder unvollständiger Modulzustand.',3;
  IF @Installed=1 AND (@AssemblyId IS NULL OR NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE assembly_id=@AssemblyId AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_File_CsvMemory') AND permission_set=1 AND is_user_defined=1 AND principal_id=@SchemaOwner)
   OR (SELECT COUNT(*) FROM sys.assembly_files WHERE assembly_id=@AssemblyId)<>1
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0 AND name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'bit' AND TRY_CONVERT(bit,value)=1)
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Module))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0')))
   THROW 55324,N'CSV-Assembly, Eigentümer oder Releasezuordnung ist inkohärent.',4;
  IF @Installed=1 AND EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(s.Name)) WHERE o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name) OR CONVERT(varbinary(max),o.type)<>CONVERT(varbinary(max),s.Kind) OR COALESCE(o.principal_id,@SchemaOwner)<>@SchemaOwner
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.Managed' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'bit' AND TRY_CONVERT(bit,value)=1)
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Module))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleVersion' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'1.0.0'))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.Visibility' AND SQL_VARIANT_PROPERTY(value,N'BaseType')=N'nvarchar' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),CASE WHEN s.Kind='P' THEN N'public' ELSE N'internal' END))
   OR(s.Method IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sys.assembly_modules m WHERE m.object_id=o.object_id AND m.assembly_id=@AssemblyId AND m.null_on_null_input=0 AND m.execute_as_principal_id IS NULL AND CONVERT(varbinary(max),m.assembly_class)=CONVERT(varbinary(max),N'Toolbelt.Csv.CsvEntryPoints') AND CONVERT(varbinary(max),m.assembly_method)=CONVERT(varbinary(max),s.Method))))
   THROW 55324,N'CSV-Slot, Binding, Typ oder Ownershipmarker ist inkohärent.',5;
  IF @Installed=1 AND (EXISTS(SELECT 1 FROM @Parameters e LEFT JOIN sys.parameters p ON p.object_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(e.Name)) AND p.parameter_id=e.Ordinal WHERE p.object_id IS NULL OR CONVERT(varbinary(max),p.name)<>CONVERT(varbinary(max),e.ParameterName) OR p.system_type_id<>e.TypeId OR p.user_type_id<>p.system_type_id OR p.max_length<>e.Length OR (e.Ordinal>0 AND(p.is_output<>0 OR p.has_default_value<>0)))
   OR EXISTS(SELECT 1 FROM @Slots s WHERE s.Method IS NOT NULL AND (SELECT COUNT(*) FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(s.Name)))<>(SELECT COUNT(*) FROM @Parameters WHERE Name=s.Name))
   OR (SELECT COUNT(*) FROM sys.columns WHERE object_id=OBJECT_ID(N'toolbelt_file.TVF_InternalParseCsv'))<>5
   OR EXISTS(SELECT 1 FROM @Columns e LEFT JOIN sys.columns c ON c.object_id=OBJECT_ID(N'toolbelt_file.TVF_InternalParseCsv') AND c.column_id=e.Ordinal WHERE c.object_id IS NULL OR CONVERT(varbinary(max),c.name)<>CONVERT(varbinary(max),e.Name) OR c.system_type_id<>e.TypeId OR c.user_type_id<>c.system_type_id OR c.max_length<>e.Length OR c.is_nullable<>1))
   THROW 55324,N'Interne CLR-Parameter oder nullable Parserfelder sind inkohärent.',7;
  DELETE FROM @Own;
  INSERT @Own SELECT OBJECT_ID(N'toolbelt_file.'+QUOTENAME(Name)) FROM @Slots WHERE @Installed=1;
  IF EXISTS(SELECT 1 FROM sys.assembly_modules WHERE assembly_id=@AssemblyId AND object_id NOT IN(SELECT Id FROM @Own)) OR EXISTS(SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id=@AssemblyId)
   THROW 55325,N'Fremder Assemblyconsumer blockiert CSV-Lifecycle.',2;
  IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d WHERE (d.referenced_id IN(SELECT Id FROM @Own)
   OR(d.referenced_id IS NULL AND (d.referenced_database_name IS NULL OR d.referenced_database_name COLLATE DATABASE_DEFAULT=DB_NAME()) AND d.referenced_schema_name COLLATE DATABASE_DEFAULT=N'toolbelt_file' AND EXISTS(SELECT 1 FROM @Slots WHERE Name COLLATE DATABASE_DEFAULT=d.referenced_entity_name COLLATE DATABASE_DEFAULT))) AND d.referencing_id NOT IN(SELECT Id FROM @Own))
   THROW 55325,N'Fremder SQL-Verbraucher blockiert CSV-Lifecycle.',3;
  IF @Install=0 AND @Installed=0
  BEGIN
   IF @Phase=0 RETURN;
   THROW 55324,N'CSV-Zustand änderte sich während des Preflights.',6;
  END;
  IF @Install=0 AND CONVERT(varbinary(max),@InstalledMode)=CONVERT(varbinary(max),N'central') AND @Confirm<>1
   THROW 55326,N'Zentraler Uninstall benötigt explizite Consumerbestätigung.',1;
  IF @Install=0 AND @Installed=1 AND (ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_file',N'SCHEMA',N'ALTER'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'ALTER ANY ASSEMBLY'),0)<>1)
   THROW 55327,N'Schema-ALTER/ALTER ANY ASSEMBLY für Uninstall fehlt; keine Rechtevergabe.',7;
  IF @Install=1
  BEGIN
   IF @SchemaId IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE SCHEMA'),0)<>1 THROW 55327,N'CREATE SCHEMA fehlt; keine Rechtevergabe.',1;
   IF @SchemaId IS NOT NULL AND ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_file',N'SCHEMA',N'ALTER'),0)<>1 THROW 55327,N'Schema-ALTER fehlt; keine Rechtevergabe.',2;
   IF @SchemaId IS NOT NULL AND @AssemblyId IS NULL AND @SchemaOwner<>USER_ID() THROW 55327,N'Neue Assembly benötigt denselben effektiven Eigentümer wie das Schema.',3;
   IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE FUNCTION'),0)<>1 OR ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE PROCEDURE'),0)<>1 THROW 55327,N'CREATE FUNCTION/PROCEDURE fehlt; keine Rechtevergabe.',4;
   IF @AssemblyId IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE ASSEMBLY'),0)<>1 THROW 55327,N'CREATE ASSEMBLY fehlt; keine Rechtevergabe.',5;
   IF @AssemblyId IS NOT NULL AND EXISTS(SELECT 1 FROM sys.assembly_files WHERE assembly_id=@AssemblyId AND file_id=1 AND HASHBYTES('SHA2_512',content)<>@Hash) AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'ALTER ANY ASSEMBLY'),0)<>1 THROW 55327,N'ALTER ANY ASSEMBLY fehlt; keine Rechtevergabe.',6;
  END;
  IF @Phase=0
  BEGIN
   BEGIN TRANSACTION;SET @OwnTransaction=1;
   DECLARE @Lock int;
   EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.file.csv-memory',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
   IF @Lock<0 THROW 55323,N'Paralleler CSV-Lifecycle aktiv.',1;
  END;
  SET @Phase+=1;
 END;
 IF @Install=1 AND @SchemaId IS NULL
 BEGIN
  EXEC(N'CREATE SCHEMA toolbelt_file');
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_file';
  EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'file',@level0type=N'SCHEMA',@level0name=N'toolbelt_file';
 END;
 IF @Installed=1
 BEGIN
  DROP PROCEDURE toolbelt_file.USP_ParseCsv;
  DROP PROCEDURE toolbelt_file.USP_WriteCsv;
  DROP FUNCTION toolbelt_file.TVF_InternalParseCsv;
  DROP FUNCTION toolbelt_file.SVF_InternalQuoteCsvCell;
  DROP FUNCTION toolbelt_file.SVF_InternalMeasureCsvCell;
 END;
 IF @Install=1
 BEGIN
  DECLARE @InstalledHash varbinary(64)=(SELECT HASHBYTES('SHA2_512',content) FROM sys.assembly_files WHERE assembly_id=@AssemblyId AND file_id=1);
  IF @InstalledHash IS NULL OR @InstalledHash<>@Hash
  BEGIN
   DECLARE @Ddl nvarchar(max)=CASE WHEN @AssemblyId IS NULL THEN N'CREATE' ELSE N'ALTER' END+N' ASSEMBLY [Toolbelt_File_CsvMemory] FROM '+CONVERT(nvarchar(max),@Bits,1)+N' WITH PERMISSION_SET=SAFE;';
   EXEC sys.sp_executesql @Ddl;
  END;
 END
 ELSE
 BEGIN
  DROP ASSEMBLY Toolbelt_File_CsvMemory;
  EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.file.csv-memory.Version';
  EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.file.csv-memory.DeploymentMode';
  -- Geteiltes Schema/Dependencies und instanzweiter Trust bleiben erhalten.
  COMMIT TRANSACTION;SET @OwnTransaction=0;
 END;
END TRY
BEGIN CATCH
 IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
