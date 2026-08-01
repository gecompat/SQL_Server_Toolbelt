-- Deployment für toolbelt.core.execution-context
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51441, N'DeploymentMode muss local oder central sein.', 1;

IF SCHEMA_ID(N'toolbelt_core') IS NULL
    EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');


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
    THROW 51440, N'Der Zielname toolbelt_core.TVF_CurrentExecutionContext ist bereits durch ein frameworkfremdes Objekt belegt.', 1;
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
    THROW 51440, N'Der Zielname toolbelt_core.SVF_CurrentExecutionId ist bereits durch ein frameworkfremdes Objekt belegt.', 1;
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
    THROW 51440, N'Der Zielname toolbelt_core.USP_BeginExecution ist bereits durch ein frameworkfremdes Objekt belegt.', 1;
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
    THROW 51440, N'Der Zielname toolbelt_core.USP_SetExecutionContext ist bereits durch ein frameworkfremdes Objekt belegt.', 1;
END;
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
    THROW 51440, N'Der Zielname toolbelt_core.USP_EndExecution ist bereits durch ein frameworkfremdes Objekt belegt.', 1;
END;
GO

BEGIN TRANSACTION;
GO
:r ../Source/TVF_CurrentExecutionContext.sql
:r ../Source/SVF_CurrentExecutionId.sql
:r ../Source/USP_BeginExecution.sql
:r ../Source/USP_SetExecutionContext.sql
:r ../Source/USP_EndExecution.sql
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'FUNCTION'
        , @level1name = N'TVF_CurrentExecutionContext';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'FUNCTION'
        , @level1name = N'TVF_CurrentExecutionContext';
END;

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleVersion'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'FUNCTION'
        , @level1name = N'TVF_CurrentExecutionContext';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'FUNCTION'
        , @level1name = N'TVF_CurrentExecutionContext';
END;
IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.SVF_CurrentExecutionId')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'FUNCTION'
        , @level1name = N'SVF_CurrentExecutionId';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'FUNCTION'
        , @level1name = N'SVF_CurrentExecutionId';
END;

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.SVF_CurrentExecutionId')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleVersion'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'FUNCTION'
        , @level1name = N'SVF_CurrentExecutionId';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'FUNCTION'
        , @level1name = N'SVF_CurrentExecutionId';
END;
IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_BeginExecution')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_BeginExecution';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_BeginExecution';
END;

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_BeginExecution')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleVersion'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_BeginExecution';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_BeginExecution';
END;
IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_SetExecutionContext')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_SetExecutionContext';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_SetExecutionContext';
END;

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_SetExecutionContext')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleVersion'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_SetExecutionContext';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_SetExecutionContext';
END;
IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_EndExecution')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_EndExecution';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleId'
        , @value = N'toolbelt.core.execution-context'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_EndExecution';
END;

IF EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.USP_EndExecution')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleVersion'
   )
BEGIN
    EXEC sys.sp_updateextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_EndExecution';
END
ELSE
BEGIN
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.ModuleVersion'
        , @value = N'1.0.0'
        , @level0type = N'SCHEMA'
        , @level0name = N'toolbelt_core'
        , @level1type = N'PROCEDURE'
        , @level1name = N'USP_EndExecution';
END;

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.execution-context.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.execution-context.DeploymentMode';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_updateextendedproperty @name = @VersionProperty, @value = N'1.0.0';
ELSE
    EXEC sys.sp_addextendedproperty @name = @VersionProperty, @value = N'1.0.0';

IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_updateextendedproperty @name = @ModeProperty, @value = @DeploymentMode;
ELSE
    EXEC sys.sp_addextendedproperty @name = @ModeProperty, @value = @DeploymentMode;

COMMIT TRANSACTION;
GO
