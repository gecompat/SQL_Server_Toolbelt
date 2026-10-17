:On Error exit
-- Keine geerbte Transaktion doomen; Guard vor SET und vor jeder Mutation.
IF @@TRANCOUNT<>0 OR (@@OPTIONS & 2)<>0
BEGIN
 RAISERROR(N'TBX_SSISDBG_lifecycle_transaction: Frische Sitzung ohne Callertransaktion erforderlich.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Mode nvarchar(16)=N'$(DeploymentMode)',@Removing bit=0,
 @InstalledVersion nvarchar(64),@AssemblyId int,@LockResult int,
 @Bits varbinary(max)=$(AssemblyBits),@AssemblyHash varbinary(64),
 @PublicSql nvarchar(max)=$(PublicProcedureSql),@InternalSql nvarchar(max)=$(InternalProcedureSql);
IF CONVERT(varbinary(max),@Mode) NOT IN(CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))
 THROW 50000,N'TBX_SSISDBG_lifecycle_mode: Modus muss local oder central sein.',1;
IF TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion')) NOT IN(15,16,17)
 OR NOT EXISTS(SELECT 1 FROM sys.dm_os_host_info WITH (NOLOCK) WHERE host_platform=N'Windows')
 OR NOT EXISTS(SELECT 1 FROM sys.databases WITH (NOLOCK) WHERE database_id=DB_ID() AND compatibility_level IN(150,160,170))
 THROW 50000,N'TBX_SSISDBG_lifecycle_platform: Windows SQL Server 2019/2022/2025 mit CL150+ erforderlich.',1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr enabled' AND value_in_use=1)
 OR NOT EXISTS(SELECT 1 FROM sys.configurations WITH (NOLOCK) WHERE name=N'clr strict security' AND value_in_use=1)
 THROW 50000,N'TBX_SSISDBG_lifecycle_clr: CLR muss aktiviert und Strict Security eingeschaltet sein.',1;
IF @Bits IS NULL OR DATALENGTH(@Bits)<1024
 THROW 50000,N'TBX_SSISDBG_lifecycle_binary: Releasebinary fehlt.',1;
SET @AssemblyHash=HASHBYTES('SHA2_512',@Bits);
IF @AssemblyHash<>$(ExpectedAssemblySha512)
 THROW 50000,N'TBX_SSISDBG_lifecycle_binary: Binary stimmt nicht mit dem gebauten Release überein.',1;
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WITH (NOLOCK) WHERE hash=@AssemblyHash)
 THROW 50000,N'TBX_SSISDBG_lifecycle_trust: Exakter Releasehash ist nicht administrativ freigegeben.',1;
:r DependencyPreflight.sql
:r OwnershipPreflight.sql
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.tsql.ssis-debug',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @LockResult<0 THROW 50000,N'TBX_SSISDBG_lifecycle_lock: Paralleler Modul-Lifecycle.',1;
 EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.tsql.script-parser',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @LockResult<0 THROW 50000,N'TBX_SSISDBG_lifecycle_lock: Paralleler Parser-Lifecycle.',1;
:r DependencyPreflight.sql
:r OwnershipPreflight.sql
 IF SCHEMA_ID(N'toolbelt_tsql') IS NULL OR NOT EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) WHERE ep.class=3 AND ep.major_id=SCHEMA_ID(N'toolbelt_tsql') AND ep.minor_id=0 AND ep.name=N'Toolbelt.Managed' AND TRY_CONVERT(int,ep.value)=1)
  THROW 50000,N'TBX_SSISDBG_lifecycle_collision: Gemeinsames Schema nicht frameworkeigen.',1;
 -- SQL Server weist ALTER mit identischer MVID zurück. Unveränderte,
 -- vollständig hashgleiche Binaries beim Repeat nicht erneut registrieren.
 IF @AssemblyId IS NULL OR NOT EXISTS(SELECT 1 FROM sys.assembly_files AS af WITH (NOLOCK) WHERE af.assembly_id=@AssemblyId AND af.file_id=1 AND HASHBYTES('SHA2_512',af.content)=@AssemblyHash)
 BEGIN
  DECLARE @AssemblySql nvarchar(max)=CASE WHEN @AssemblyId IS NULL THEN N'CREATE' ELSE N'ALTER' END+N' ASSEMBLY [Toolbelt_Tsql_SsisDebug] FROM '+CONVERT(nvarchar(max),@Bits,1)+N' WITH PERMISSION_SET=UNSAFE;';
  EXEC sys.sp_executesql @AssemblySql;
 END;
 EXEC sys.sp_executesql @InternalSql;
 EXEC sys.sp_executesql @PublicSql;
 DECLARE @Level0 sysname,@Level0Name sysname,@Level1 sysname,@Level1Name sysname,@Property sysname,@Value sql_variant;
 DECLARE markers CURSOR LOCAL FAST_FORWARD FOR
 SELECT N'ASSEMBLY',N'Toolbelt_Tsql_SsisDebug',CAST(NULL AS sysname),CAST(NULL AS sysname),N'Toolbelt.Managed',CONVERT(sql_variant,1) UNION ALL
 SELECT N'ASSEMBLY',N'Toolbelt_Tsql_SsisDebug',NULL,NULL,N'Toolbelt.ModuleId',CONVERT(sql_variant,N'toolbelt.tsql.ssis-debug') UNION ALL
 SELECT N'ASSEMBLY',N'Toolbelt_Tsql_SsisDebug',NULL,NULL,N'Toolbelt.ModuleVersion',CONVERT(sql_variant,N'1.0.0') UNION ALL
 SELECT N'SCHEMA',N'toolbelt_tsql',N'PROCEDURE',o.name,p.name,p.value
 FROM (VALUES(N'USP_ExplainSsisDataFlow'),(N'USP_ExplainSsisDataFlowInternal')) AS o(name)
 CROSS APPLY (VALUES(N'Toolbelt.Managed',CONVERT(sql_variant,1)),(N'Toolbelt.ModuleId',CONVERT(sql_variant,N'toolbelt.tsql.ssis-debug')),(N'Toolbelt.ModuleVersion',CONVERT(sql_variant,N'1.0.0')),(N'Toolbelt.Visibility',CONVERT(sql_variant,CASE WHEN o.name=N'USP_ExplainSsisDataFlow' THEN N'public' ELSE N'internal' END))) AS p(name,value);
 OPEN markers; FETCH NEXT FROM markers INTO @Level0,@Level0Name,@Level1,@Level1Name,@Property,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF @Level0=N'ASSEMBLY' AND EXISTS(SELECT 1 FROM sys.extended_properties AS ep WITH (NOLOCK) JOIN sys.assemblies AS a WITH (NOLOCK) ON a.assembly_id=ep.major_id WHERE ep.class=5 AND a.name=@Level0Name AND ep.minor_id=0 AND ep.name=@Property)
   OR @Level0=N'SCHEMA' AND EXISTS(SELECT 1 FROM sys.extended_properties WITH (NOLOCK) WHERE class=1 AND major_id=OBJECT_ID(QUOTENAME(@Level0Name)+N'.'+QUOTENAME(@Level1Name)) AND minor_id=0 AND name=@Property)
   EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value,@level0type=@Level0,@level0name=@Level0Name,@level1type=@Level1,@level1name=@Level1Name;
  ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=@Level0,@level0name=@Level0Name,@level1type=@Level1,@level1name=@Level1Name;
  FETCH NEXT FROM markers INTO @Level0,@Level0Name,@Level1,@Level1Name,@Property,@Value;
 END;
 CLOSE markers; DEALLOCATE markers;
 IF @InstalledVersion IS NULL EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version',@value=N'1.0.0';
 ELSE EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version',@value=N'1.0.0';
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF CURSOR_STATUS('local','markers')>=0 CLOSE markers;
 IF CURSOR_STATUS('local','markers')>-3 DEALLOCATE markers;
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
