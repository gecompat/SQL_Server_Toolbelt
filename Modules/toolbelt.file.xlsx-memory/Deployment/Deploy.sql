:On Error exit
-- RAISERROR honoriert XACT_ABORT nicht: Ablehnung darf die Callertransaktion
-- weder doomen noch zurückrollen. SQLCMD -b/:On Error exit beendet das Skript.
IF @@TRANCOUNT<>0
BEGIN
 RAISERROR(N'TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION: Deploy benötigt einen eigenen Transaktionsscope.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
IF TRY_CONVERT(int,SERVERPROPERTY('ProductMajorVersion')) NOT IN(15,16,17)
 THROW 51530,N'Unterstützt werden SQL Server 2019, 2022 und 2025.',1;
DECLARE @Mode nvarchar(16)=LOWER(N'$(DeploymentMode)'),@Bits varbinary(max)=$(AssemblyBits),
 @Version nvarchar(64),@Hash varbinary(64),@AssemblyId int;
IF @Mode NOT IN(N'local',N'central') THROW 51530,N'DeploymentMode muss local oder central sein.',1;
IF NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr enabled' AND value_in_use=1)
 OR NOT EXISTS(SELECT 1 FROM sys.configurations WHERE name=N'clr strict security' AND value_in_use=1)
 THROW 51531,N'CLR muss aktiviert sein; strict security bleibt aktiviert.',1;
IF @Bits IS NULL OR DATALENGTH(@Bits)<1024 THROW 51531,N'Plausibles Releasebinary fehlt.',1;
SET @Hash=HASHBYTES('SHA2_512',@Bits);
IF NOT EXISTS(SELECT 1 FROM sys.trusted_assemblies WHERE hash=@Hash)
 THROW 51531,N'Der exakte Releasehash ist nicht vertraut.',1;

-- Beide Dependencies werden vor jeder Mutation kanonisch geprüft.
DECLARE @Dependency TABLE(Id nvarchar(128) NOT NULL,MinimumMinor int NOT NULL,ObjectId int NULL,Version nvarchar(64) NULL);
INSERT @Dependency SELECT N'toolbelt.core.result-table',0,OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P'),
 TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
INSERT @Dependency SELECT N'toolbelt.archive.zip-memory',4,NULL,TRY_CONVERT(nvarchar(64),value)
 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.archive.zip-memory.Version';
IF (SELECT COUNT(*) FROM @Dependency)<>2 OR EXISTS
 (SELECT 1 FROM @Dependency d
  CROSS APPLY(SELECT TRY_CONVERT(int,PARSENAME(d.Version,3)) Major,
    TRY_CONVERT(int,PARSENAME(d.Version,2)) Minor,TRY_CONVERT(int,PARSENAME(d.Version,1)) Patch) p
  WHERE p.Major IS NULL OR p.Major<>1 OR p.Minor IS NULL OR p.Minor<d.MinimumMinor OR p.Patch IS NULL OR p.Patch<0
    OR CONVERT(varbinary(max),d.Version)<>CONVERT(varbinary(max),CONCAT(p.Major,N'.',p.Minor,N'.',p.Patch))
    OR (d.Id=N'toolbelt.core.result-table' AND (d.ObjectId IS NULL
        OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=d.ObjectId AND e.minor_id=0
             AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),d.Id))
        OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=d.ObjectId AND e.minor_id=0
             AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),e.value))=CONVERT(varbinary(max),d.Version)))))
 THROW 51532,N'Die registrierten ResultTable- und ZIP-Dependencies sind ungeeignet.',1;
IF NOT EXISTS(SELECT 1 FROM sys.assemblies a JOIN sys.extended_properties e ON e.class=5 AND e.major_id=a.assembly_id
 WHERE a.name=N'Toolbelt_Archive_ZipMemory' AND a.permission_set=1 AND e.name=N'Toolbelt.ModuleId'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'toolbelt.archive.zip-memory'))
 THROW 51532,N'Die kanonische SAFE-ZIP-Assembly fehlt.',1;

BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.file.xlsx-memory',
   @LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @Lock<0 THROW 51533,N'Paralleles XLSX-Deployment aktiv.',1;
 SELECT @Version=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version';
 SELECT @AssemblyId=assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory';
 IF @Version IS NOT NULL AND CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0')
  THROW 51534,N'Unbekannter installierter XLSX-Release.',1;
 IF @AssemblyId IS NOT NULL AND (@Version IS NULL OR NOT EXISTS
  (SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND name=N'Toolbelt.ModuleId'
   AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'toolbelt.file.xlsx-memory')))
  THROW 51534,N'Fremde Zielassembly.',1;
 IF EXISTS(SELECT 1 FROM sys.objects o WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.name IN(N'USP_ListXlsxWorksheets',N'USP_ReadXlsxWorksheetCells',N'USP_InternalXlsxRead',N'TVF_InternalXlsxSheets',N'TVF_InternalXlsxCells')
  AND (@Version IS NULL OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id
    AND e.minor_id=0 AND e.name=N'Toolbelt.ModuleId'
    AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'toolbelt.file.xlsx-memory'))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.object_id AND e.minor_id=0
    AND e.name=N'Toolbelt.ModuleVersion' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(64),e.value))=CONVERT(varbinary(max),@Version))))
  THROW 51534,N'Fremdes oder nicht passend markiertes XLSX-Zielobjekt.',1;
 IF EXISTS(SELECT 1 FROM sys.assembly_modules WHERE assembly_id=@AssemblyId AND object_id NOT IN
   (ISNULL(OBJECT_ID(N'toolbelt_file.TVF_InternalXlsxSheets'),-1),ISNULL(OBJECT_ID(N'toolbelt_file.TVF_InternalXlsxCells'),-1)))
  OR EXISTS(SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id=@AssemblyId)
  THROW 51535,N'Fremder Assemblyconsumer blockiert das Deployment.',1;
 IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies d JOIN sys.objects o ON o.object_id=d.referenced_id
   WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.name IN(N'TVF_InternalXlsxSheets',N'TVF_InternalXlsxCells')
     AND d.referencing_id NOT IN(ISNULL(OBJECT_ID(N'toolbelt_file.USP_ListXlsxWorksheets'),-1),ISNULL(OBJECT_ID(N'toolbelt_file.USP_ReadXlsxWorksheetCells'),-1),ISNULL(OBJECT_ID(N'toolbelt_file.USP_InternalXlsxRead'),-1)))
  THROW 51535,N'Fremder Consumer verwendet ein internes XLSX-Binding.',1;
 IF SCHEMA_ID(N'toolbelt_file') IS NULL
 BEGIN
   EXEC(N'CREATE SCHEMA toolbelt_file');
   EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Managed',@value=1,@level0type=N'SCHEMA',@level0name=N'toolbelt_file';
   EXEC sys.sp_addextendedproperty @name=N'Toolbelt.SchemaCategory',@value=N'file',@level0type=N'SCHEMA',@level0name=N'toolbelt_file';
 END;
 DROP FUNCTION IF EXISTS toolbelt_file.TVF_InternalXlsxSheets;
 DROP FUNCTION IF EXISTS toolbelt_file.TVF_InternalXlsxCells;
 DECLARE @InstalledHash varbinary(64)=(SELECT HASHBYTES('SHA2_512',content) FROM sys.assembly_files WHERE assembly_id=@AssemblyId AND file_id=1);
 IF @InstalledHash IS NULL OR @InstalledHash<>@Hash
 BEGIN
   DECLARE @Ddl nvarchar(max)=CASE WHEN @AssemblyId IS NULL THEN N'CREATE' ELSE N'ALTER' END
      +N' ASSEMBLY [Toolbelt_File_XlsxMemory] FROM '+CONVERT(nvarchar(max),@Bits,1)+N' WITH PERMISSION_SET=SAFE;';
   EXEC sys.sp_executesql @Ddl;
 END;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
:r ../Source/TVF_InternalXlsxSheets.sql
:r ../Source/TVF_InternalXlsxCells.sql
:r ../Source/USP_InternalXlsxRead.sql
:r ../Source/USP_ListXlsxWorksheets.sql
:r ../Source/USP_ReadXlsxWorksheetCells.sql
SET NOCOUNT ON;
BEGIN TRY
 IF @@TRANCOUNT<>1 THROW 51539,N'Deploymenttransaktion fehlt.',1;
 DECLARE @Property sysname,@Value nvarchar(128);
 DECLARE ModuleMarkers CURSOR LOCAL FAST_FORWARD FOR SELECT Name,Value FROM
  (VALUES(N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version',N'1.0.0'),
         (N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode',N'$(DeploymentMode)'))p(Name,Value);
 OPEN ModuleMarkers; FETCH NEXT FROM ModuleMarkers INTO @Property,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@Property)
   EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value;
  ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value;
  FETCH NEXT FROM ModuleMarkers INTO @Property,@Value;
 END;
 CLOSE ModuleMarkers; DEALLOCATE ModuleMarkers;
 DECLARE @Object sysname,@Type varchar(16);
 DECLARE ObjectMarkers CURSOR LOCAL FAST_FORWARD FOR
  SELECT o.name,CASE WHEN o.type=N'P' THEN 'PROCEDURE' ELSE 'FUNCTION' END,p.Name,p.Value
  FROM sys.objects o CROSS APPLY(VALUES(N'Toolbelt.ModuleId',N'toolbelt.file.xlsx-memory'),
     (N'Toolbelt.ModuleVersion',N'1.0.0'),
     (N'Toolbelt.Visibility',CASE WHEN o.name IN(N'USP_ListXlsxWorksheets',N'USP_ReadXlsxWorksheetCells') THEN N'public' ELSE N'internal' END))p(Name,Value)
  WHERE o.schema_id=SCHEMA_ID(N'toolbelt_file') AND o.name IN(N'USP_ListXlsxWorksheets',N'USP_ReadXlsxWorksheetCells',N'USP_InternalXlsxRead',N'TVF_InternalXlsxSheets',N'TVF_InternalXlsxCells');
 OPEN ObjectMarkers; FETCH NEXT FROM ObjectMarkers INTO @Object,@Type,@Property,@Value;
 WHILE @@FETCH_STATUS=0
 BEGIN
  IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(@Object)) AND minor_id=0 AND name=@Property)
   EXEC sys.sp_updateextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=@Type,@level1name=@Object;
  ELSE EXEC sys.sp_addextendedproperty @name=@Property,@value=@Value,@level0type=N'SCHEMA',@level0name=N'toolbelt_file',@level1type=@Type,@level1name=@Object;
  FETCH NEXT FROM ObjectMarkers INTO @Object,@Type,@Property,@Value;
 END;
 CLOSE ObjectMarkers; DEALLOCATE ObjectMarkers;
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory') AND name=N'Toolbelt.ModuleId')
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.file.xlsx-memory',@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_File_XlsxMemory';
 ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.file.xlsx-memory',@level0type=N'ASSEMBLY',@level0name=N'Toolbelt_File_XlsxMemory';
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO

