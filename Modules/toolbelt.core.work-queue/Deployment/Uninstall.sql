:On Error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @ConfirmNoExternalConsumers bit=TRY_CONVERT(bit,N'$(ConfirmNoExternalConsumers)');
DECLARE @AllowDataLoss bit=TRY_CONVERT(bit,N'$(AllowDataLoss)');
DECLARE @VersionPropertyName sysname=N'Toolbelt.Module.toolbelt.core.work-queue.Version';
DECLARE @ModePropertyName sysname=N'Toolbelt.Module.toolbelt.core.work-queue.DeploymentMode';
DECLARE @InstalledVersion nvarchar(64)=(SELECT TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=@VersionPropertyName);
DECLARE @DeploymentMode nvarchar(16)=(SELECT TRY_CONVERT(nvarchar(16),value) FROM sys.extended_properties WHERE class=0 AND name=@ModePropertyName);

IF @ConfirmNoExternalConsumers IS NULL OR @AllowDataLoss IS NULL
    THROW 51948,N'ConfirmNoExternalConsumers und AllowDataLoss müssen jeweils 0 oder 1 sein.',1;
IF @InstalledVersion IS NOT NULL AND @InstalledVersion COLLATE Latin1_General_100_BIN2<>N'1.0.0'
    THROW 51943,N'Die installierte Modulversion ist diesem Uninstall nicht bekannt.',3;
IF @InstalledVersion IS NULL RETURN;
IF @DeploymentMode NOT IN(N'local',N'central')
    THROW 51943,N'Der registrierte Deployment-Modus fehlt oder ist ungültig.',4;
IF @DeploymentMode=N'central' AND @ConfirmNoExternalConsumers<>1
    THROW 51948,N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.',2;

IF EXISTS
(
    SELECT 1 FROM (VALUES
      (N'WorkItem'),(N'VW_WorkQueue'),(N'USP_EnqueueWork'),(N'USP_ClaimWork'),(N'USP_CompleteWork'),(N'USP_FailWork'),(N'USP_GetWorkStatus'))x(ObjectName)
    WHERE OBJECT_ID(N'toolbelt_core.'+QUOTENAME(x.ObjectName)) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1 FROM sys.extended_properties ep
          WHERE ep.class=1 AND ep.major_id=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(x.ObjectName)) AND ep.minor_id=0
            AND ep.name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),ep.value)=N'toolbelt.core.work-queue'
      )
)
    THROW 51944,N'Mindestens ein Work-Queue-Objekt ist nicht eindeutig diesem Modul zugeordnet.',2;

DECLARE @HasData bit=0;
IF OBJECT_ID(N'toolbelt_core.WorkItem',N'U') IS NOT NULL
    EXEC sys.sp_executesql N'IF EXISTS(SELECT 1 FROM toolbelt_core.WorkItem) SET @v=1;',N'@v bit OUTPUT',@v=@HasData OUTPUT;
IF @HasData=1 AND @AllowDataLoss<>1
    THROW 51949,N'Die WorkItem-Tabelle enthält Daten; AllowDataLoss=1 ist erforderlich.',1;

IF @ConfirmNoExternalConsumers<>1 AND EXISTS
(
    SELECT 1 FROM sys.sql_expression_dependencies d
    WHERE d.referenced_id IN
      (OBJECT_ID(N'toolbelt_core.WorkItem'),OBJECT_ID(N'toolbelt_core.VW_WorkQueue'),OBJECT_ID(N'toolbelt_core.USP_EnqueueWork'),OBJECT_ID(N'toolbelt_core.USP_ClaimWork'),OBJECT_ID(N'toolbelt_core.USP_CompleteWork'),OBJECT_ID(N'toolbelt_core.USP_FailWork'),OBJECT_ID(N'toolbelt_core.USP_GetWorkStatus'))
      AND d.referencing_id NOT IN
      (OBJECT_ID(N'toolbelt_core.WorkItem'),OBJECT_ID(N'toolbelt_core.VW_WorkQueue'),OBJECT_ID(N'toolbelt_core.USP_EnqueueWork'),OBJECT_ID(N'toolbelt_core.USP_ClaimWork'),OBJECT_ID(N'toolbelt_core.USP_CompleteWork'),OBJECT_ID(N'toolbelt_core.USP_FailWork'),OBJECT_ID(N'toolbelt_core.USP_GetWorkStatus'))
      AND NOT EXISTS
      (
          SELECT 1 FROM sys.objects child
          WHERE child.object_id=d.referencing_id
            AND child.parent_object_id=OBJECT_ID(N'toolbelt_core.WorkItem')
      )
)
    THROW 51948,N'Externe SQL-Abhängigkeiten blockieren den Uninstall; ConfirmNoExternalConsumers=1 ist erforderlich.',3;

BEGIN TRANSACTION;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_GetWorkStatus;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_FailWork;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_CompleteWork;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_ClaimWork;
DROP PROCEDURE IF EXISTS toolbelt_core.USP_EnqueueWork;
DROP VIEW IF EXISTS toolbelt_core.VW_WorkQueue;
DROP TABLE IF EXISTS toolbelt_core.WorkItem;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@VersionPropertyName) EXEC sys.sp_dropextendedproperty @name=@VersionPropertyName;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModePropertyName) EXEC sys.sp_dropextendedproperty @name=@ModePropertyName;
COMMIT TRANSACTION;
GO
