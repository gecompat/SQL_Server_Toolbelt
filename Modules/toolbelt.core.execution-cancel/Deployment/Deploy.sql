-- Deployment für toolbelt.core.execution-cancel
:on error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central') THROW 52640, N'DeploymentMode muss local oder central sein.', 1;
IF SCHEMA_ID(N'toolbelt_core') IS NULL EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');
IF OBJECT_ID(N'toolbelt_core.SVF_CurrentExecutionId', N'FN') IS NULL
    THROW 52641, N'Die Abhängigkeit toolbelt.core.execution-context fehlt.', 1;
IF OBJECT_ID(N'toolbelt_core.ExecutionCancellation', N'U') IS NOT NULL
   AND EXISTS
   (
       SELECT required.name FROM (VALUES (N'ExecutionId'),(N'RequestedAtUtc'),(N'RequestedBy'),(N'CancellationReason'),(N'RowVersion')) required(name)
       WHERE NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id=OBJECT_ID(N'toolbelt_core.ExecutionCancellation') AND c.name=required.name)
   )
    THROW 52643, N'Die vorhandene ExecutionCancellation-Tabelle entspricht nicht dem erwarteten Version-1-Vertrag.', 1;
IF EXISTS
(
    SELECT 1 FROM (VALUES
      (N'ExecutionCancellation', N'U'), (N'TVF_ExecutionCancellationStatus', N'IF'),
      (N'SVF_IsCancellationRequested', N'FN'), (N'USP_RequestExecutionCancellation', N'P')
    ) AS o(ObjectName, ObjectType)
    WHERE OBJECT_ID(N'toolbelt_core.' + o.ObjectName, o.ObjectType) IS NOT NULL
      AND NOT EXISTS
      (
        SELECT 1 FROM sys.extended_properties ep
        WHERE ep.class=1 AND ep.major_id=OBJECT_ID(N'toolbelt_core.' + o.ObjectName)
          AND ep.minor_id=0 AND ep.name=N'Toolbelt.ModuleId'
          AND CONVERT(nvarchar(256), ep.value)=N'toolbelt.core.execution-cancel'
      )
)
    THROW 52642, N'Ein Zielname ist bereits durch ein frameworkfremdes Objekt belegt.', 1;
GO
BEGIN TRANSACTION;
GO
:r ../Source/ExecutionCancellation.sql
:r ../Source/TVF_ExecutionCancellationStatus.sql
:r ../Source/SVF_IsCancellationRequested.sql
:r ../Source/USP_RequestExecutionCancellation.sql
GO
DECLARE @DeploymentMode nvarchar(16)=LOWER(N'$(DeploymentMode)');
DECLARE @Objects TABLE (ObjectName sysname, LevelType nvarchar(16));
INSERT INTO @Objects VALUES
 (N'ExecutionCancellation',N'TABLE'),(N'TVF_ExecutionCancellationStatus',N'FUNCTION'),
 (N'SVF_IsCancellationRequested',N'FUNCTION'),(N'USP_RequestExecutionCancellation',N'PROCEDURE');
DECLARE @ObjectName sysname,@LevelType nvarchar(16);
DECLARE c CURSOR LOCAL FAST_FORWARD FOR SELECT ObjectName,LevelType FROM @Objects;
OPEN c; FETCH NEXT FROM c INTO @ObjectName,@LevelType;
WHILE @@FETCH_STATUS=0
BEGIN
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+@ObjectName) AND minor_id=0 AND name=N'Toolbelt.ModuleId')
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.core.execution-cancel',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
 ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleId',@value=N'toolbelt.core.execution-cancel',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
 IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=OBJECT_ID(N'toolbelt_core.'+@ObjectName) AND minor_id=0 AND name=N'Toolbelt.ModuleVersion')
  EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
 ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.ModuleVersion',@value=N'1.0.0',@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
 FETCH NEXT FROM c INTO @ObjectName,@LevelType;
END;
CLOSE c; DEALLOCATE c;
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version')
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version',@value=N'1.0.0';
ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.core.execution-cancel.Version',@value=N'1.0.0';
IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.execution-cancel.DeploymentMode')
 EXEC sys.sp_updateextendedproperty @name=N'Toolbelt.Module.toolbelt.core.execution-cancel.DeploymentMode',@value=@DeploymentMode;
ELSE EXEC sys.sp_addextendedproperty @name=N'Toolbelt.Module.toolbelt.core.execution-cancel.DeploymentMode',@value=@DeploymentMode;
COMMIT TRANSACTION;
GO
