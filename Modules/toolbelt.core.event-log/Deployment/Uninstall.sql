-- Uninstall für toolbelt.core.event-log
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
DECLARE @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)');
DECLARE @AllowDataLoss bit=TRY_CONVERT(bit,N'$(AllowDataLoss)');
IF @ConfirmNoExternalConsumers IS NULL THROW 51746,N'ConfirmNoExternalConsumers muss 0 oder 1 sein.',1;
IF @AllowDataLoss IS NULL THROW 51747,N'AllowDataLoss muss 0 oder 1 sein.',1;
DECLARE @DeploymentMode nvarchar(16)=(SELECT CONVERT(nvarchar(16),value) FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.event-log.DeploymentMode');
IF @DeploymentMode=N'central' AND @ConfirmNoExternalConsumers<>1
    THROW 51748,N'Zentraler Uninstall benötigt ConfirmNoExternalConsumers = 1.',1;
IF EXISTS
(
    SELECT 1 FROM (VALUES(N'EventLog'),(N'VW_Events'),(N'USP_WriteEventInternal'),(N'USP_WriteEvent'),(N'USP_DeleteEventsBefore'))o(ObjectName)
    WHERE OBJECT_ID(N'toolbelt_core.'+o.ObjectName) IS NOT NULL
      AND NOT EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+o.ObjectName) AND minor_id=0 AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),value)=N'toolbelt.core.event-log')
)
    THROW 51745,N'Mindestens ein Objekt ist nicht eindeutig diesem Modul zugeordnet.',2;
DECLARE @HasData bit=0;
IF OBJECT_ID(N'toolbelt_core.EventLog',N'U') IS NOT NULL
    EXEC sys.sp_executesql N'IF EXISTS(SELECT 1 FROM toolbelt_core.EventLog) SET @v=1;',N'@v bit OUTPUT',@v=@HasData OUTPUT;
IF @HasData=1 AND @AllowDataLoss<>1
    THROW 51749,N'Die EventLog-Tabelle enthält Daten; AllowDataLoss = 1 ist erforderlich.',1;
IF EXISTS
(
    SELECT 1 FROM toolbelt_core.WorkType
    WHERE WorkTypeName='toolbelt.event-log.write'
      AND (HandlerSchema<>N'toolbelt_core' OR HandlerProcedure<>N'USP_WriteEventInternal' OR ParameterMode<>'JSON_PAYLOAD')
)
    THROW 51748,N'Der Event-Log-Work-Type entspricht nicht dem Modulvertrag und wird nicht entfernt.',2;

BEGIN TRANSACTION;
IF EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write')
BEGIN
    DECLARE @rv binary(8)=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write');
    IF EXISTS(SELECT 1 FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write' AND IsEnabled=1)
        EXEC toolbelt_core.USP_DisableWorkType @WorkTypeName='toolbelt.event-log.write',@ExpectedRowVersion=@rv,@DisabledReason=N'Event-Log-Uninstall';
    SET @rv=(SELECT CONVERT(binary(8),RowVersion) FROM toolbelt_core.WorkType WHERE WorkTypeName='toolbelt.event-log.write');
    EXEC toolbelt_core.USP_RemoveWorkType @WorkTypeName='toolbelt.event-log.write',@ExpectedRowVersion=@rv,@AllowDelete=1;
END;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_DeleteEventsBefore;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_WriteEvent;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_WriteEventInternal;
DROP VIEW IF EXISTS toolbelt_core.VW_Events;
DROP TABLE IF EXISTS toolbelt_core.EventLog;
DECLARE @VersionProperty sysname=N'Toolbelt.Module.toolbelt.core.event-log.Version';
DECLARE @ModeProperty sysname=N'Toolbelt.Module.toolbelt.core.event-log.DeploymentMode';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@VersionProperty) EXEC sys.sp_dropextendedproperty @name=@VersionProperty;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty) EXEC sys.sp_dropextendedproperty @name=@ModeProperty;
COMMIT TRANSACTION;
GO
