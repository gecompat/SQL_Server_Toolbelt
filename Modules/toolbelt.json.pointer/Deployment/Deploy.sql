:On Error exit
-- Caller-Gate vor SET, Temp-DDL und eigener Transaktion; RAISERROR bleibt nicht-dooming.
IF @@TRANCOUNT<>0
BEGIN
 RAISERROR(N'TBX_JSON_POINTER_LIFECYCLE_CALLER_TRANSACTION: Ein eigener Transaktionsscope ist erforderlich.',16,1);
 RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @Install bit=1,@Mode nvarchar(max)=N'$(DeploymentMode)',@Confirm int=0,@OwnTransaction bit=0;
BEGIN TRY
:r ./Preflight.sql
:r ./CreateObjects.sql
:r ./MarkRelease.sql
 COMMIT TRANSACTION;SET @OwnTransaction=0;
END TRY
BEGIN CATCH
 IF @OwnTransaction=1 AND XACT_STATE()<>0 ROLLBACK TRANSACTION;
 THROW;
END CATCH;
GO
