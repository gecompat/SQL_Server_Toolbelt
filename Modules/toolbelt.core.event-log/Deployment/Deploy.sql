-- Deployment für toolbelt.core.event-log
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51741, N'DeploymentMode muss local oder central sein.', 1;
IF SCHEMA_ID(N'toolbelt_core') IS NULL
    EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');
IF OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession', N'P') IS NULL
 OR NOT EXISTS (SELECT 1 FROM sys.parameters WHERE object_id=OBJECT_ID(N'toolbelt_core.USP_ExecuteWorkTypeInNewSession') AND name=N'@SuppressResult')
    THROW 51742, N'Die Abhängigkeit toolbelt.core.second-session Version 1.1.0 fehlt.', 1;
IF OBJECT_ID(N'toolbelt_core.USP_RemoveWorkType', N'P') IS NULL
    THROW 51743, N'Die Abhängigkeit toolbelt.core.work-type Version 1.1.0 fehlt.', 1;
IF OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext', N'IF') IS NULL
    THROW 51744, N'Die Abhängigkeit toolbelt.core.execution-context fehlt.', 1;
IF OBJECT_ID(N'toolbelt_core.EventLog', N'U') IS NOT NULL
 AND NOT EXISTS
 (
     SELECT 1 FROM sys.extended_properties
     WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.EventLog') AND minor_id=0
       AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256), value)=N'toolbelt.core.event-log'
 )
    THROW 51740, N'Der Zielname toolbelt_core.EventLog ist frameworkfremd belegt.', 1;
DECLARE @ObjectChecks TABLE(ObjectName sysname, ObjectType char(2));
INSERT INTO @ObjectChecks VALUES
  (N'VW_Events',N'V'),(N'USP_WriteEventInternal',N'P'),(N'USP_WriteEvent',N'P'),(N'USP_DeleteEventsBefore',N'P');
IF EXISTS
(
    SELECT 1 FROM @ObjectChecks o
    WHERE OBJECT_ID(N'toolbelt_core.'+o.ObjectName,o.ObjectType) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1 FROM sys.extended_properties
          WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+o.ObjectName) AND minor_id=0
            AND name=N'Toolbelt.ModuleId' AND CONVERT(nvarchar(256),value)=N'toolbelt.core.event-log'
      )
)
    THROW 51745, N'Mindestens ein Event-Log-Zielname ist frameworkfremd belegt.', 1;
GO
BEGIN TRANSACTION;
GO
:r ../Source/EventLog.sql
:r ../Source/VW_Events.sql
:r ../Source/USP_WriteEventInternal.sql
:r ../Source/USP_WriteEvent.sql
:r ../Source/USP_DeleteEventsBefore.sql
GO
EXEC toolbelt_core.USP_RegisterWorkType
      @WorkTypeName = 'toolbelt.event-log.write'
    , @HandlerSchema = N'toolbelt_core'
    , @HandlerProcedure = N'USP_WriteEventInternal'
    , @ParameterMode = 'JSON_PAYLOAD'
    , @PayloadContractJson = N'{"type":"object"}'
    , @DefaultTimeoutSeconds = 30
    , @IsIdempotent = 0
    , @Description = N'Interner Handler für rollback-unabhängige Toolbelt-Events.'
    , @AllowUpdate = 1
    , @Reactivate = 1;

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
DECLARE @Objects TABLE(ObjectName sysname, LevelType nvarchar(16));
INSERT INTO @Objects VALUES
  (N'EventLog',N'TABLE'),(N'VW_Events',N'VIEW'),(N'USP_WriteEventInternal',N'PROCEDURE'),(N'USP_WriteEvent',N'PROCEDURE'),(N'USP_DeleteEventsBefore',N'PROCEDURE');
DECLARE @ObjectName sysname,@LevelType nvarchar(16);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectName,LevelType FROM @Objects;
OPEN c; FETCH NEXT FROM c INTO @ObjectName,@LevelType;
WHILE @@FETCH_STATUS=0
BEGIN
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+@ObjectName) AND minor_id=0 AND name=N'Toolbelt.ModuleId')
        EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.core.event-log',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.core.event-log',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+@ObjectName) AND minor_id=0 AND name=N'Toolbelt.ModuleVersion')
        EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
    FETCH NEXT FROM c INTO @ObjectName,@LevelType;
END;
CLOSE c; DEALLOCATE c;
DECLARE @VersionProperty sysname=N'Toolbelt.Module.toolbelt.core.event-log.Version';
DECLARE @ModeProperty sysname=N'Toolbelt.Module.toolbelt.core.event-log.DeploymentMode';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@VersionProperty)
    EXEC sys.sp_updateextendedproperty @name=@VersionProperty,@value=N'1.0.0';
ELSE EXEC sys.sp_addextendedproperty @name=@VersionProperty,@value=N'1.0.0';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModeProperty)
    EXEC sys.sp_updateextendedproperty @name=@ModeProperty,@value=@DeploymentMode;
ELSE EXEC sys.sp_addextendedproperty @name=@ModeProperty,@value=@DeploymentMode;
COMMIT TRANSACTION;
GO
