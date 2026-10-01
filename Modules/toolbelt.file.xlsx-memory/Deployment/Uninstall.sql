:On Error exit
-- Nichtdoomender Guard vor Sessionoptionen und sämtlichen Mutationen.
IF @@TRANCOUNT<>0
BEGIN
 RAISERROR(N'TBX_XLSX_LIFECYCLE_CALLER_TRANSACTION: Uninstall benötigt einen eigenen Transaktionsscope.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Confirm bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)'),@Version nvarchar(64),@Mode nvarchar(16);
SELECT @Version=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.Version';
IF @Version IS NULL RETURN;
IF CONVERT(varbinary(max),@Version)<>CONVERT(varbinary(max),N'1.0.0') THROW 51534,N'Unbekannter installierter XLSX-Release.',1;
SELECT @Mode=TRY_CONVERT(nvarchar(16),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.file.xlsx-memory.DeploymentMode';
IF @Confirm IS NULL OR @Mode NOT IN(N'local',N'central') OR (@Mode=N'central' AND @Confirm<>1)
 THROW 51536,N'Zentraler Uninstall benötigt ConfirmNoExternalConsumers=1.',1;
DECLARE @Own TABLE(Id int NOT NULL PRIMARY KEY);
INSERT @Own SELECT object_id FROM sys.objects WHERE schema_id=SCHEMA_ID(N'toolbelt_file') AND name IN(N'USP_ListXlsxWorksheets',N'USP_ReadXlsxWorksheetCells',N'USP_InternalXlsxRead',N'TVF_InternalXlsxSheets',N'TVF_InternalXlsxCells');
IF EXISTS(SELECT 1 FROM @Own o WHERE NOT EXISTS(SELECT 1 FROM sys.extended_properties e WHERE e.class=1 AND e.major_id=o.Id AND e.minor_id=0
 AND e.name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),e.value))=CONVERT(varbinary(max),N'toolbelt.file.xlsx-memory')))
 THROW 51534,N'XLSX-Objekte besitzen fremde Eigentumsmarker.',1;
DECLARE @AssemblyId int=(SELECT assembly_id FROM sys.assemblies WHERE name=N'Toolbelt_File_XlsxMemory');
IF @AssemblyId IS NOT NULL AND NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=5 AND major_id=@AssemblyId
 AND name=N'Toolbelt.ModuleId' AND CONVERT(varbinary(max),TRY_CONVERT(nvarchar(128),value))=CONVERT(varbinary(max),N'toolbelt.file.xlsx-memory'))
 THROW 51534,N'XLSX-Assembly besitzt fremde Eigentumsmarker.',1;
IF EXISTS(SELECT 1 FROM sys.sql_expression_dependencies WHERE referenced_id IN(SELECT Id FROM @Own) AND referencing_id NOT IN(SELECT Id FROM @Own))
 OR EXISTS(SELECT 1 FROM sys.assembly_modules WHERE assembly_id=@AssemblyId AND object_id NOT IN(SELECT Id FROM @Own))
 OR EXISTS(SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id=@AssemblyId)
 THROW 51535,N'Fremder XLSX-Consumer blockiert Uninstall.',1;
BEGIN TRY
 BEGIN TRANSACTION;
 DECLARE @Lock int;
 EXEC @Lock=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.file.xlsx-memory',
 @LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @Lock<0 THROW 51533,N'Paralleler XLSX-Lifecycle aktiv.',1;
 DROP PROCEDURE IF EXISTS toolbelt_file.USP_ListXlsxWorksheets;
 DROP PROCEDURE IF EXISTS toolbelt_file.USP_ReadXlsxWorksheetCells;
 DROP PROCEDURE IF EXISTS toolbelt_file.USP_InternalXlsxRead;
 DROP FUNCTION IF EXISTS toolbelt_file.TVF_InternalXlsxSheets;
 DROP FUNCTION IF EXISTS toolbelt_file.TVF_InternalXlsxCells;
 IF @AssemblyId IS NOT NULL DROP ASSEMBLY Toolbelt_File_XlsxMemory;
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
-- Die kanonische ZIP-Dependency und instanzweiten Trust-Hashes bleiben bewusst erhalten.

