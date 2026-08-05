-- Deployment für toolbelt.core.second-session
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51641, N'DeploymentMode muss local oder central sein.', 1;

IF SCHEMA_ID(N'toolbelt_core') IS NULL
    EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');

IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
    THROW 51642, N'Die Abhängigkeit toolbelt.core.result-table fehlt.', 1;
IF OBJECT_ID(N'toolbelt_core.TVF_CurrentExecutionContext', N'IF') IS NULL
   OR OBJECT_ID(N'toolbelt_core.USP_BeginExecution', N'P') IS NULL
   OR OBJECT_ID(N'toolbelt_core.USP_EndExecution', N'P') IS NULL
    THROW 51643, N'Die Abhängigkeit toolbelt.core.execution-context fehlt oder ist unvollständig.', 1;
IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NULL
   OR OBJECT_ID(N'toolbelt_core.VW_WorkTypes', N'V') IS NULL
    THROW 51644, N'Die Abhängigkeit toolbelt.core.work-type fehlt oder ist unvollständig.', 1;

IF OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.SecondSessionProvider')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
         AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.second-session'
   )
    THROW 51640, N'Der Zielname toolbelt_core.SecondSessionProvider ist bereits durch ein frameworkfremdes Objekt belegt.', 1;

IF OBJECT_ID(N'toolbelt_core.SecondSessionProvider', N'U') IS NOT NULL
   AND EXISTS
   (
       SELECT required.name
       FROM
       (
           VALUES
             (N'ProviderName'), (N'LinkedServerName'), (N'IsEnabled')
           , (N'CreatedAtUtc'), (N'CreatedBy'), (N'ModifiedAtUtc')
           , (N'ModifiedBy'), (N'RowVersion')
       ) AS required(name)
       WHERE NOT EXISTS
       (
           SELECT 1
           FROM sys.columns AS c
           WHERE c.object_id = OBJECT_ID(N'toolbelt_core.SecondSessionProvider')
             AND c.name = required.name
       )
   )
    THROW 51645, N'Die vorhandene SecondSessionProvider-Tabelle entspricht nicht dem erwarteten Version-1-Vertrag.', 1;

DECLARE @ObjectChecks TABLE(ObjectName sysname, ObjectType char(2));
INSERT INTO @ObjectChecks(ObjectName, ObjectType)
VALUES
  (N'VW_SecondSessionProviders', N'V')
, (N'USP_SecondSessionProbe', N'P')
, (N'USP_DispatchWorkType', N'P')
, (N'USP_ConfigureSecondSessionLoopback', N'P')
, (N'USP_ExecuteWorkTypeInNewSession', N'P');

IF EXISTS
(
    SELECT 1
    FROM @ObjectChecks AS oc
    WHERE OBJECT_ID(N'toolbelt_core.' + oc.ObjectName, oc.ObjectType) IS NOT NULL
      AND NOT EXISTS
      (
          SELECT 1
          FROM sys.extended_properties AS ep
          WHERE ep.class = 1
            AND ep.major_id = OBJECT_ID(N'toolbelt_core.' + oc.ObjectName)
            AND ep.minor_id = 0
            AND ep.name = N'Toolbelt.ModuleId'
            AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.second-session'
      )
)
    THROW 51646, N'Mindestens ein Second-Session-Zielname ist durch ein frameworkfremdes Objekt belegt.', 1;
GO

BEGIN TRANSACTION;
GO
:r ../Source/SecondSessionProvider.sql
:r ../Source/VW_SecondSessionProviders.sql
:r ../Source/USP_SecondSessionProbe.sql
:r ../Source/USP_DispatchWorkType.sql
:r ../Source/USP_ConfigureSecondSessionLoopback.sql
:r ../Source/USP_ExecuteWorkTypeInNewSession.sql
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
DECLARE @Objects TABLE(ObjectName sysname, LevelType nvarchar(16));
INSERT INTO @Objects(ObjectName, LevelType)
VALUES
  (N'SecondSessionProvider', N'TABLE')
, (N'VW_SecondSessionProviders', N'VIEW')
, (N'USP_SecondSessionProbe', N'PROCEDURE')
, (N'USP_DispatchWorkType', N'PROCEDURE')
, (N'USP_ConfigureSecondSessionLoopback', N'PROCEDURE')
, (N'USP_ExecuteWorkTypeInNewSession', N'PROCEDURE');

DECLARE @ObjectName sysname;
DECLARE @LevelType nvarchar(16);
DECLARE object_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT ObjectName, LevelType FROM @Objects;
OPEN object_cursor;
FETCH NEXT FROM object_cursor INTO @ObjectName, @LevelType;
WHILE @@FETCH_STATUS = 0
BEGIN
    IF EXISTS
    (
        SELECT 1
        FROM sys.extended_properties AS ep
        WHERE ep.class = 1
          AND ep.major_id = OBJECT_ID(N'toolbelt_core.' + @ObjectName)
          AND ep.minor_id = 0
          AND ep.name = N'Toolbelt.ModuleId'
    )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.ModuleId'
            , @value = N'toolbelt.core.second-session'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId'
            , @value = N'toolbelt.core.second-session'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;

    IF EXISTS
    (
        SELECT 1
        FROM sys.extended_properties AS ep
        WHERE ep.class = 1
          AND ep.major_id = OBJECT_ID(N'toolbelt_core.' + @ObjectName)
          AND ep.minor_id = 0
          AND ep.name = N'Toolbelt.ModuleVersion'
    )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.ModuleVersion'
            , @value = N'1.1.0'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleVersion'
            , @value = N'1.1.0'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;

    FETCH NEXT FROM object_cursor INTO @ObjectName, @LevelType;
END;
CLOSE object_cursor;
DEALLOCATE object_cursor;

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.second-session.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.second-session.DeploymentMode';
IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
    EXEC sys.sp_updateextendedproperty @name = @VersionProperty, @value = N'1.1.0';
ELSE
    EXEC sys.sp_addextendedproperty @name = @VersionProperty, @value = N'1.1.0';

IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
    EXEC sys.sp_updateextendedproperty @name = @ModeProperty, @value = @DeploymentMode;
ELSE
    EXEC sys.sp_addextendedproperty @name = @ModeProperty, @value = @DeploymentMode;

COMMIT TRANSACTION;
GO
