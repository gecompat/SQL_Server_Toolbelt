-- Uninstall für toolbelt.core.execution-cancel
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
DECLARE @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)');
DECLARE @AllowDataLoss bit=TRY_CONVERT(bit,N'$(AllowDataLoss)');
IF @ConfirmNoExternalConsumers IS NULL OR @AllowDataLoss IS NULL THROW 52643,N'ConfirmNoExternalConsumers und AllowDataLoss müssen 0 oder 1 sein.',1;
IF EXISTS
(
 SELECT 1 FROM (VALUES(N'ExecutionCancellation'),(N'TVF_ExecutionCancellationStatus'),(N'SVF_IsCancellationRequested'),(N'USP_RequestExecutionCancellation')) o(ObjectName)
 WHERE OBJECT_ID(N'toolbelt_core.'+o.ObjectName) IS NOT NULL AND NOT EXISTS
 (SELECT 1 FROM sys.extended_properties ep WHERE ep.class=1 AND ep.major_id=OBJECT_ID(N'toolbelt_core.'+o.ObjectName) AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),ep.value)=N'toolbelt.core.execution-cancel')
) THROW 52644,N'Ein Objekt ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.',1;
IF (SELECT CONVERT(nvarchar(16),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-cancel.DeploymentMode')=N'central' AND @ConfirmNoExternalConsumers<>1 THROW 52645,N'Zentraler Uninstall benötigt ConfirmNoExternalConsumers = 1.',1;
DECLARE @HasData bit=0;
IF OBJECT_ID(N'toolbelt_core.ExecutionCancellation',N'U') IS NOT NULL
 EXEC sys.sp_executesql N'IF EXISTS(SELECT 1 FROM toolbelt_core.ExecutionCancellation) SET @HasData=1;',N'@HasData bit OUTPUT',@HasData=@HasData OUTPUT;
IF @HasData=1 AND @AllowDataLoss<>1 THROW 52646,N'Die Cancellation-Tabelle enthält Daten; AllowDataLoss = 1 ist erforderlich.',1;
BEGIN TRANSACTION;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_RequestExecutionCancellation;
DROP FUNCTION IF EXISTS toolbelt_core.SVF_IsCancellationRequested;
DROP FUNCTION IF EXISTS toolbelt_core.TVF_ExecutionCancellationStatus;
DROP TABLE IF EXISTS toolbelt_core.ExecutionCancellation;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version') EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-cancel.DeploymentMode') EXEC sys.sp_dropextendedproperty @name=N'Toolbelt.Module.toolbelt.core.execution-cancel.DeploymentMode';
COMMIT TRANSACTION;
GO
