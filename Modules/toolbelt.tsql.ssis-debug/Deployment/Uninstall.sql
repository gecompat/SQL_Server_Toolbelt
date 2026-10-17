:On Error exit
IF @@TRANCOUNT<>0 OR (@@OPTIONS & 2)<>0
BEGIN
 RAISERROR(N'TBX_SSISDBG_lifecycle_transaction: Keine Callertransaktion zulässig.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @InstalledVersion nvarchar(64),@AssemblyId int,@LockResult int,@Removing bit=1;
:r OwnershipPreflight.sql
IF @InstalledVersion IS NULL RETURN;
BEGIN TRY
 BEGIN TRANSACTION;
 EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.tsql.ssis-debug',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @LockResult<0 THROW 50000,N'TBX_SSISDBG_lifecycle_lock: Paralleler Modul-Lifecycle.',1;
 EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.tsql.script-parser',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
 IF @LockResult<0 THROW 50000,N'TBX_SSISDBG_lifecycle_lock: Paralleler Parser-Lifecycle.',1;
:r OwnershipPreflight.sql
 DROP PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlow;
 DROP PROCEDURE toolbelt_tsql.USP_ExplainSsisDataFlowInternal;
 DROP ASSEMBLY [Toolbelt_Tsql_SsisDebug];
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.tsql.ssis-debug.Version';
 COMMIT TRANSACTION;
END TRY
BEGIN CATCH
 IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
-- Gemeinsames Schema, Parser, ScriptDom und administrativer Trust bleiben erhalten.
