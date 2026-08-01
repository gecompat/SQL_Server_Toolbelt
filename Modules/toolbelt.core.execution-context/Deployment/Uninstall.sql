-- Uninstall für toolbelt.core.execution-context
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @ConfirmNoExternalConsumers bit = TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)');
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.execution-context.DeploymentMode';
DECLARE @DeploymentMode nvarchar(16) =
    CONVERT(nvarchar(16), (
        SELECT ep.value FROM sys.extended_properties AS ep
        WHERE ep.class = 0 AND ep.name = @ModeProperty
    ));

IF @DeploymentMode = N'central' AND ISNULL(@ConfirmNoExternalConsumers, 0) <> 1
    THROW 51443, N'Der zentrale Uninstall erfordert ConfirmNoExternalConsumers=1.', 1;


IF OBJECT_ID(N'toolbelt_core.USP_EndExecution', N'P') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_EndExecution')
             AND ep.minor_id = 0
             AND ep.name = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.execution-context'
       )
BEGIN
    THROW 51442, N'Das Objekt toolbelt_core.USP_EndExecution ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;
END;
IF OBJECT_ID(N'toolbelt_core.USP_SetExecutionContext', N'P') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_SetExecutionContext')
             AND ep.minor_id = 0
             AND ep.name = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.execution-context'
       )
BEGIN
    THROW 51442, N'Das Objekt toolbelt_core.USP_SetExecutionContext ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;
END;
IF OBJECT_ID(N'toolbelt_core.USP_BeginExecution', N'P') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_BeginExecution')
             AND ep.minor_id = 0
             AND ep.name = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.execution-context'
       )
BEGIN
    THROW 51442, N'Das Objekt toolbelt_core.USP_BeginExecution ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;
END;
IF OBJECT_ID(N'toolbelt_core.SVF_CurrentExecutionId', N'FN') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = OBJECT_ID(N'toolbelt_core.SVF_CurrentExecutionId')
             AND ep.minor_id = 0
             AND ep.name = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.execution-context'
       )
BEGIN
    THROW 51442, N'Das Objekt toolbelt_core.SVF_CurrentExecutionId ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;
END;
IF OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext', N'IF') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           WHERE ep.class = 1
             AND ep.major_id = OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext')
             AND ep.minor_id = 0
             AND ep.name = N'Toolbelt.ModuleId'
             AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.execution-context'
       )
BEGIN
    THROW 51442, N'Das Objekt toolbelt_core.TVF_CurrentExecutionContext ist nicht eindeutig diesem Modul zugeordnet und wird nicht gelöscht.', 1;
END;

BEGIN TRANSACTION;
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_EndExecution];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_SetExecutionContext];
DROP PROCEDURE IF EXISTS [toolbelt_core].[USP_BeginExecution];
DROP FUNCTION IF EXISTS [toolbelt_core].[SVF_CurrentExecutionId];
DROP FUNCTION IF EXISTS [toolbelt_core].[TVF_CurrentExecutionContext];

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.execution-context.Version';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;
COMMIT TRANSACTION;
GO
