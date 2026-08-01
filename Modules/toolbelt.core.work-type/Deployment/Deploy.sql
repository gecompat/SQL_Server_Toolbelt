-- Deployment für toolbelt.core.work-type
:on error exit

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51541, N'DeploymentMode muss local oder central sein.', 1;

IF SCHEMA_ID(N'toolbelt_core') IS NULL
    EXEC(N'CREATE SCHEMA [toolbelt_core] AUTHORIZATION [dbo];');

IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
    THROW 51542, N'Die Abhängigkeit toolbelt.core.result-table fehlt.', 1;

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NOT NULL
   AND NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties AS ep
       WHERE ep.class = 1
         AND ep.major_id = OBJECT_ID(N'toolbelt_core.WorkType')
         AND ep.minor_id = 0
         AND ep.name = N'Toolbelt.ModuleId'
         AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.work-type'
   )
    THROW 51540, N'Der Zielname toolbelt_core.WorkType ist bereits durch ein frameworkfremdes Objekt belegt.', 1;

IF OBJECT_ID(N'toolbelt_core.WorkType', N'U') IS NOT NULL
   AND EXISTS
   (
       SELECT required.name
       FROM
       (
           VALUES
             (N'WorkTypeId'), (N'WorkTypeName'), (N'HandlerSchema'), (N'HandlerProcedure')
           , (N'ParameterMode'), (N'PayloadContractJson'), (N'DefaultTimeoutSeconds')
           , (N'IsIdempotent'), (N'IsEnabled'), (N'Description'), (N'CreatedAtUtc')
           , (N'CreatedBy'), (N'ModifiedAtUtc'), (N'ModifiedBy'), (N'DisabledAtUtc')
           , (N'DisabledBy'), (N'DisabledReason'), (N'RowVersion')
       ) AS required(name)
       WHERE NOT EXISTS
       (
           SELECT 1
           FROM sys.columns AS c
           WHERE c.object_id = OBJECT_ID(N'toolbelt_core.WorkType')
             AND c.name = required.name
       )
   )
    THROW 51543, N'Die vorhandene WorkType-Tabelle entspricht nicht dem erwarteten Version-1-Vertrag.', 1;

DECLARE @ObjectChecks TABLE(ObjectName sysname, ObjectType char(2));
INSERT INTO @ObjectChecks(ObjectName, ObjectType)
VALUES
  (N'VW_WorkTypes', N'V')
, (N'USP_RegisterWorkType', N'P')
, (N'USP_DisableWorkType', N'P')
, (N'USP_ResolveWorkType', N'P');

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
            AND CONVERT(nvarchar(256), ep.value) = N'toolbelt.core.work-type'
      )
)
    THROW 51544, N'Mindestens ein öffentlicher Zielname ist durch ein frameworkfremdes Objekt belegt.', 1;
GO

BEGIN TRANSACTION;
GO
:r ../Source/WorkType.sql
:r ../Source/VW_WorkTypes.sql
:r ../Source/USP_RegisterWorkType.sql
:r ../Source/USP_DisableWorkType.sql
:r ../Source/USP_ResolveWorkType.sql
GO

DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');

DECLARE @Objects TABLE(ObjectName sysname, LevelType nvarchar(16));
INSERT INTO @Objects(ObjectName, LevelType)
VALUES
  (N'WorkType', N'TABLE')
, (N'VW_WorkTypes', N'VIEW')
, (N'USP_RegisterWorkType', N'PROCEDURE')
, (N'USP_DisableWorkType', N'PROCEDURE')
, (N'USP_ResolveWorkType', N'PROCEDURE');

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
            , @value = N'toolbelt.core.work-type'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId'
            , @value = N'toolbelt.core.work-type'
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
            , @value = N'1.0.0'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleVersion'
            , @value = N'1.0.0'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_core'
            , @level1type = @LevelType
            , @level1name = @ObjectName;

    FETCH NEXT FROM object_cursor INTO @ObjectName, @LevelType;
END;
CLOSE object_cursor;
DEALLOCATE object_cursor;

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.core.work-type.Version';
DECLARE @ModeProperty sysname = N'Toolbelt.Module.toolbelt.core.work-type.DeploymentMode';
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
