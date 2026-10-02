:On Error exit
-- Nichtdoomender Caller-Gate vor SET und sämtlichen Mutationen.
IF @@TRANCOUNT<>0
BEGIN
 RAISERROR(N'TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION: Uninstall benötigt einen eigenen Transaktionsscope.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Confirm bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)'),@Version nvarchar(max),
 @InstalledMode nvarchar(max),@AssemblyId int,@Installed bit,@Release int,@Phase int=0,@ProtectFuture bit=0;
DECLARE @Slots TABLE(Name sysname COLLATE DATABASE_DEFAULT NOT NULL,Kind char(2) COLLATE DATABASE_DEFAULT NOT NULL,FirstRelease int NOT NULL,Class nvarchar(128) NULL,Method nvarchar(128) NULL);
INSERT @Slots VALUES
 (N'USP_ListXlsxWorksheets','P',10,NULL,NULL),
 (N'USP_ReadXlsxWorksheetCells','P',10,NULL,NULL),
 (N'USP_InternalXlsxRead','P',10,NULL,NULL),
 (N'TVF_InternalXlsxSheets','FT',10,N'Toolbelt.Xlsx.Qualification.XlsxEntryPoints',N'ListSheets'),
 (N'TVF_InternalXlsxCells','FT',10,N'Toolbelt.Xlsx.Qualification.XlsxEntryPoints',N'ReadCells'),
 (N'TVF_InternalInterpretXlsxCell','FT',11,N'Toolbelt.Xlsx.Qualification.XlsxCellType',N'Interpret'),
 (N'TVF_InterpretXlsxCell','IF',11,NULL,NULL);
DECLARE @Own TABLE(Id int NOT NULL PRIMARY KEY);
BEGIN TRY
 WHILE @Phase<2
 BEGIN
  -- Benutzerfreigabe 2026-10-02: vollständige Consumersicht vor Mutation,
  -- im zweiten Durchlauf erneut unter demselben Transaktions-AppLock.
  IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'VIEW DEFINITION'),0)<>1
   OR ISNULL(HAS_PERMS_BY_NAME(N'sys.sql_expression_dependencies',N'OBJECT',N'SELECT'),0)<>1
   THROW 51535,N'Vollständige Sicht auf SQL-Abhängigkeiten ist erforderlich.',2;
-- Keine Hashgleichheit ersetzt die bekannte Release-/Slotidentität.
SELECT @Version=NULL,@Installed=0,@InstalledMode=NULL,@AssemblyId=NULL;
SELECT @Version=TRY_CONVERT(nvarchar(max),value),@Installed=1 FROM sys.extended_properties
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version';
SELECT @InstalledMode=TRY_CONVERT(nvarchar(max),value) FROM sys.extended_properties
 WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode';
IF @Installed=1 AND (@Version IS NULL OR CONVERT(varbinary(max),@Version) NOT IN
 (CONVERT(varbinary(max),N'1.0.0'),CONVERT(varbinary(max),N'1.1.0')))
 THROW 51534,N'Unbekannter oder inkohärenter XLSX-Release.',1;
IF (@Installed=1 AND (@InstalledMode IS NULL OR CONVERT(varbinary(max),@InstalledMode) NOT IN
 (CONVERT(varbinary(max),N'local'),CONVERT(varbinary(max),N'central'))))
 OR (@Installed=0 AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode'))
 THROW 51534,N'Unbekannter oder inkohärenter XLSX-Modus.',1;
SET @Release=CASE CONVERT(varbinary(max),@Version) WHEN CONVERT(varbinary(max),N'1.0.0') THEN 10 WHEN CONVERT(varbinary(max),N'1.1.0') THEN 11 ELSE 0 END;
SELECT @AssemblyId=assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory';
IF (@Installed=1 AND @AssemblyId IS NULL) OR (@Installed=0 AND @AssemblyId IS NOT NULL)
 OR (@AssemblyId IS NOT NULL AND (NOT EXISTS(SELECT 1 FROM sys.assemblies WHERE assembly_id=@AssemblyId AND permission_set=1
  AND CONVERT(varbinary(max),name)=CONVERT(varbinary(max),N'Toolbelt_File_XlsxMemory'))
 OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId AND name=N'Toolbelt.ModuleId'
 AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.file.xlsx-memory'))))
 THROW 51534,N'Fremde oder inkohärente XLSX-Assembly.',1;
IF EXISTS(SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id=OBJECT_ID(N'toolbelt_file.'+QUOTENAME(s.Name))
 WHERE (@Installed=1 AND s.FirstRelease<=@Release AND
  (o.object_id IS NULL OR CONVERT(varbinary(max),o.name)<>CONVERT(varbinary(max),s.Name)
   OR CONVERT(varbinary(max),o.type)<>CONVERT(varbinary(max),s.Kind)
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleId'
      AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),N'toolbelt.file.xlsx-memory'))
   OR NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=o.object_id AND minor_id=0 AND name=N'Toolbelt.ModuleVersion'
      AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(max),value))=CONVERT(varbinary(max),@Version))
   OR (s.Kind='FT' AND NOT EXISTS(SELECT 1 FROM sys.assembly_modules m WHERE m.object_id=o.object_id AND m.assembly_id=@AssemblyId
      AND CONVERT(varbinary(max),m.assembly_class)=CONVERT(varbinary(max),s.Class)
      AND CONVERT(varbinary(max),m.assembly_method)=CONVERT(varbinary(max),s.Method)))))
  OR ((@Installed=0 OR s.FirstRelease>@Release) AND o.object_id IS NOT NULL AND @ProtectFuture=1))
 THROW 51534,N'XLSX-Slot, Typ oder Eigentumsmarker ist nicht der bekannte Release.',1;
DELETE FROM @Own;
INSERT @Own SELECT OBJECT_ID(N'toolbelt_file.'+QUOTENAME(Name)) FROM @Slots WHERE FirstRelease<=@Release;
IF EXISTS(SELECT 1 FROM sys.assembly_modules WHERE assembly_id=@AssemblyId AND object_id NOT IN(SELECT Id FROM @Own))
 OR EXISTS(SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id=@AssemblyId)
 THROW 51535,N'Fremder Assemblyconsumer blockiert XLSX-Lifecycle.',1;

  IF @Installed=0
  BEGIN
   IF @Phase=0 RETURN;
   THROW 51534,N'XLSX-Release änderte sich während des Preflights.',1;
  END;
  IF @Confirm IS NULL OR (@InstalledMode=N'central' AND @Confirm<>1)
   THROW 51536,N'Zentraler Uninstall benötigt ConfirmNoExternalConsumers=1.',1;
  IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id IN(SELECT Id FROM @Own) AND referencing_id NOT IN(SELECT Id FROM @Own))
   THROW 51535,N'Fremder XLSX-Consumer blockiert Uninstall.',1;
  IF @Phase=0
  BEGIN
   BEGIN TRANSACTION;
   DECLARE @Lock int;
   EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.file.xlsx-memory',
    @LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
   IF @Lock<0 THROW 51533,N'Paralleler XLSX-Lifecycle aktiv.',1;
  END;
  SET @Phase+=1;
 END;
 IF @Release=11
 BEGIN
  DROP FUNCTION toolbelt_file.TVF_InterpretXlsxCell;
  DROP FUNCTION toolbelt_file.TVF_InternalInterpretXlsxCell;
 END;
 DROP PROCEDURE toolbelt_file.USP_ListXlsxWorksheets;
 DROP PROCEDURE toolbelt_file.USP_ReadXlsxWorksheetCells;
 DROP PROCEDURE toolbelt_file.USP_InternalXlsxRead;
 DROP FUNCTION toolbelt_file.TVF_InternalXlsxSheets;
 DROP FUNCTION toolbelt_file.TVF_InternalXlsxCells;
 DROP ASSEMBLY Toolbelt_File_XlsxMemory;
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version';
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode';
 IF SCHEMA_ID(N'toolbelt_file') IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_file'))
  AND EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=3 AND major_id=SCHEMA_ID(N'toolbelt_file') AND name=N'Toolbelt.Managed' AND TRY_CONVERT(bit,value)=1)
  EXEC(N'DROP SCHEMA toolbelt_file');
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
-- Kanonische Dependencies und instanzweiter Trust bleiben erhalten.
