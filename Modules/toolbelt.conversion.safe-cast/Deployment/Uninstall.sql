:On Error exit
-- Kein Caller-Vollrollback und keine SET-Änderung bei aktiver Callertransaktion.
IF @@TRANCOUNT<>0
BEGIN
 RAISERROR(N'TBX_SAFE_CAST_LIFECYCLE_CALLER_TRANSACTION: Ein eigener Transaktionsscope ist erforderlich.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Install bit=0,@Mode nvarchar(max)=NULL,@Confirm int=$(ConfirmNoExternalConsumers),@OwnTransaction bit=0;
BEGIN TRY
:r ./Preflight.sql
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.Version';
 EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.conversion.safe-cast.DeploymentMode';
 -- Das geteilte Konversionsschema und andere Module bleiben erhalten.
 COMMIT TRANSACTION;SET @OwnTransaction=0;
END TRY
BEGIN CATCH
 IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
