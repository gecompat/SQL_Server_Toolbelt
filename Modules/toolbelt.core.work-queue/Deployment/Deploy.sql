:On Error exit

-- ============================================================================
-- Zweck:     Erst- und Wiederholungsdeployment
-- Modul:     toolbelt.core.work-queue v1.0.0 (E1a)
-- Erfordert: toolbelt.core.result-table 1.0.0; toolbelt.core.work-type 1.1.0
-- Modus:     SQLCMD; Ausführung aus diesem Deployment-Verzeichnis
-- Parameter: DeploymentMode=local|central
-- ============================================================================

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;

DROP TABLE IF EXISTS #tbx_WorkQueueReleaseObjects;
DROP TABLE IF EXISTS #tbx_WorkQueueDeployState;

CREATE TABLE #tbx_WorkQueueReleaseObjects
(
      ReleaseVersion nvarchar(64) NOT NULL
    , SchemaName sysname NOT NULL
    , ObjectName sysname NOT NULL
    , ObjectType char(2) NOT NULL
    , LevelType nvarchar(16) NOT NULL
    , CONSTRAINT PK_tbx_WorkQueueReleaseObjects
          PRIMARY KEY (ReleaseVersion, SchemaName, ObjectName)
);
INSERT INTO #tbx_WorkQueueReleaseObjects
    (ReleaseVersion,SchemaName,ObjectName,ObjectType,LevelType)
VALUES
  (N'1.0.0',N'toolbelt_core',N'WorkItem',N'U',N'TABLE')
 ,(N'1.0.0',N'toolbelt_core',N'VW_WorkQueue',N'V',N'VIEW')
 ,(N'1.0.0',N'toolbelt_core',N'USP_EnqueueWork',N'P',N'PROCEDURE')
 ,(N'1.0.0',N'toolbelt_core',N'USP_ClaimWork',N'P',N'PROCEDURE')
 ,(N'1.0.0',N'toolbelt_core',N'USP_CompleteWork',N'P',N'PROCEDURE')
 ,(N'1.0.0',N'toolbelt_core',N'USP_FailWork',N'P',N'PROCEDURE')
 ,(N'1.0.0',N'toolbelt_core',N'USP_GetWorkStatus',N'P',N'PROCEDURE');

CREATE TABLE #tbx_WorkQueueDeployState
(TargetVersion nvarchar(64) NOT NULL,InstalledVersion nvarchar(64) NULL,DeploymentMode nvarchar(16) NOT NULL);

DECLARE @TargetVersion nvarchar(64)=N'1.0.0';
DECLARE @DeploymentMode nvarchar(16)=LOWER(N'$(DeploymentMode)');
DECLARE @VersionPropertyName sysname=N'Toolbelt.Module.toolbelt.core.work-queue.Version';
DECLARE @InstalledVersion nvarchar(64);
DECLARE @ProductMajorVersion int=TRY_CONVERT(int,SERVERPROPERTY(N'ProductMajorVersion'));
DECLARE @ResultTableVersion nvarchar(64),@WorkTypeVersion nvarchar(64);

IF @ProductMajorVersion NOT IN(15,16,17)
    THROW 51940,N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.',1;
IF @DeploymentMode NOT IN(N'local',N'central')
    THROW 51941,N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.',1;

SELECT @ResultTableVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.result-table.Version';
SELECT @WorkTypeVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
WHERE class=0 AND name=N'Toolbelt.Module.toolbelt.core.work-type.Version';
IF ISNULL(@ResultTableVersion,N'') COLLATE Latin1_General_100_BIN2<>N'1.0.0'
 OR OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable',N'P') IS NULL
 OR ISNULL(@WorkTypeVersion,N'') COLLATE Latin1_General_100_BIN2<>N'1.1.0'
 OR OBJECT_ID(N'toolbelt_core.WorkType',N'U') IS NULL
    THROW 51942,N'toolbelt.core.result-table 1.0.0 und toolbelt.core.work-type 1.1.0 müssen in derselben Datenbank installiert sein.',1;

SELECT @InstalledVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties
WHERE class=0 AND name=@VersionPropertyName;
IF @InstalledVersion IS NOT NULL AND @InstalledVersion COLLATE Latin1_General_100_BIN2<>N'1.0.0'
    THROW 51943,N'Die installierte Modulversion ist diesem Deployment nicht als unterstütztes Release bekannt.',1;

IF EXISTS
(
    SELECT 1
    FROM #tbx_WorkQueueReleaseObjects r
    JOIN sys.schemas s
      ON s.name COLLATE Latin1_General_100_BIN2
         = r.SchemaName COLLATE Latin1_General_100_BIN2
    JOIN sys.objects o
      ON o.schema_id=s.schema_id
     AND o.name COLLATE Latin1_General_100_BIN2
         = r.ObjectName COLLATE Latin1_General_100_BIN2
    WHERE r.ReleaseVersion=@TargetVersion
      AND
      (
          @InstalledVersion IS NULL
          OR o.type COLLATE Latin1_General_100_BIN2
             <> r.ObjectType COLLATE Latin1_General_100_BIN2
          OR NOT EXISTS
             (
                 SELECT 1 FROM sys.extended_properties ep
                 WHERE ep.class=1 AND ep.major_id=o.object_id AND ep.minor_id=0
                   AND ep.name=N'Toolbelt.ModuleId'
                   AND CONVERT(nvarchar(256),ep.value)=N'toolbelt.core.work-queue'
             )
      )
)
    THROW 51944,N'Mindestens ein Work-Queue-Zielname ist neu oder inkonsistent durch ein nicht autorisiertes Objekt belegt.',1;

IF OBJECT_ID(N'toolbelt_core.WorkItem',N'U') IS NOT NULL
 AND EXISTS
 (
     SELECT required.ColumnName FROM (VALUES
       (N'WorkItemId'),(N'WorkTypeId'),(N'PayloadJson'),(N'Status'),(N'EnqueuedAtUtc'),(N'EnqueuedBy'),
       (N'ClaimedAtUtc'),(N'ClaimedBy'),(N'ClaimToken'),(N'CompletedAtUtc'),(N'CompletedBy'),
       (N'FailedAtUtc'),(N'FailedBy'),(N'FailureCode'),(N'FailureMessage'),(N'RowVersion'))required(ColumnName)
     WHERE NOT EXISTS
     (
         SELECT 1 FROM sys.columns c
         WHERE c.object_id=OBJECT_ID(N'toolbelt_core.WorkItem')
           AND c.name COLLATE Latin1_General_100_BIN2
               = required.ColumnName COLLATE Latin1_General_100_BIN2
     )
 )
    THROW 51943,N'Die vorhandene WorkItem-Tabelle entspricht nicht dem Version-1-Vertrag.',2;

IF HAS_PERMS_BY_NAME(N'toolbelt_core',N'SCHEMA',N'ALTER')<>1
 OR HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE PROCEDURE')<>1
 OR HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE VIEW')<>1
 OR HAS_PERMS_BY_NAME(DB_NAME(),N'DATABASE',N'CREATE TABLE')<>1
    THROW 51945,N'Für das Work-Queue-Deployment fehlen erforderliche DDL-Rechte.',1;

INSERT INTO #tbx_WorkQueueDeployState VALUES(@TargetVersion,@InstalledVersion,@DeploymentMode);

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @LockResult int;
    EXEC @LockResult=sys.sp_getapplock @Resource=N'toolbelt.deploy.toolbelt.core.work-queue',@LockMode=N'Exclusive',@LockOwner=N'Transaction',@LockTimeout=0,@DbPrincipal=N'public';
    IF @LockResult<0 THROW 51946,N'Ein paralleles Work-Queue-Deployment ist bereits aktiv.',1;

    DECLARE @CurrentVersion nvarchar(64);
    SELECT @CurrentVersion=TRY_CONVERT(nvarchar(64),value) FROM sys.extended_properties WHERE class=0 AND name=@VersionPropertyName;
    IF ISNULL(@CurrentVersion,N'') COLLATE Latin1_General_100_BIN2<>ISNULL(@InstalledVersion,N'') COLLATE Latin1_General_100_BIN2
        THROW 51946,N'Der installierte Modulstand hat sich seit dem Preflight verändert.',2;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/WorkItem.sql
:r ../Source/VW_WorkQueue.sql
:r ../Source/USP_EnqueueWork.sql
:r ../Source/USP_ClaimWork.sql
:r ../Source/USP_CompleteWork.sql
:r ../Source/USP_FailWork.sql
:r ../Source/USP_GetWorkStatus.sql

SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    DECLARE @TargetVersion nvarchar(64),@DeploymentMode nvarchar(16),@InstalledVersion nvarchar(64);
    SELECT @TargetVersion=TargetVersion,@DeploymentMode=DeploymentMode,@InstalledVersion=InstalledVersion FROM #tbx_WorkQueueDeployState;
    IF XACT_STATE()<>1 OR EXISTS
    (
        SELECT 1 FROM #tbx_WorkQueueReleaseObjects r
        WHERE r.ReleaseVersion=@TargetVersion
          AND OBJECT_ID(QUOTENAME(r.SchemaName)+N'.'+QUOTENAME(r.ObjectName),r.ObjectType) IS NULL
    )
        THROW 51947,N'Die Work-Queue-Objekte wurden nicht vollständig innerhalb der Deployment-Transaktion angelegt.',1;

    DECLARE @ObjectName sysname,@LevelType nvarchar(16),@ObjectId int,@PropertyName sysname,@PropertyValue nvarchar(4000),@SourceHash varchar(64);
    DECLARE object_cursor CURSOR LOCAL FAST_FORWARD FOR
      SELECT ObjectName,LevelType FROM #tbx_WorkQueueReleaseObjects WHERE ReleaseVersion=@TargetVersion ORDER BY ObjectName;
    OPEN object_cursor; FETCH NEXT FROM object_cursor INTO @ObjectName,@LevelType;
    WHILE @@FETCH_STATUS=0
    BEGIN
        SET @ObjectId=OBJECT_ID(N'toolbelt_core.'+QUOTENAME(@ObjectName));
        SET @SourceHash=CONVERT(varchar(64),HASHBYTES(N'SHA2_256',CONVERT(varbinary(max),OBJECT_DEFINITION(@ObjectId))),2);
        DECLARE @Properties TABLE(PropertyName sysname NOT NULL,PropertyValue nvarchar(4000) NOT NULL);
        INSERT INTO @Properties VALUES
          (N'Toolbelt.ModuleId',N'toolbelt.core.work-queue'),(N'Toolbelt.ModuleVersion',@TargetVersion),
          (N'Toolbelt.ContractVersion',N'1.0'),(N'Toolbelt.DeploymentMode',@DeploymentMode),
          (N'Toolbelt.SourceHash',COALESCE(CONVERT(nvarchar(4000),@SourceHash),N'PERSISTENT_TABLE'));
        DECLARE property_cursor CURSOR LOCAL FAST_FORWARD FOR SELECT PropertyName,PropertyValue FROM @Properties;
        OPEN property_cursor; FETCH NEXT FROM property_cursor INTO @PropertyName,@PropertyValue;
        WHILE @@FETCH_STATUS=0
        BEGIN
            IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=1 AND major_id=@ObjectId AND minor_id=0 AND name=@PropertyName)
                EXEC sys.sp_updateextendedproperty @name=@PropertyName,@value=@PropertyValue,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
            ELSE
                EXEC sys.sp_addextendedproperty @name=@PropertyName,@value=@PropertyValue,@level0type=N'SCHEMA',@level0name=N'toolbelt_core',@level1type=@LevelType,@level1name=@ObjectName;
            FETCH NEXT FROM property_cursor INTO @PropertyName,@PropertyValue;
        END;
        CLOSE property_cursor; DEALLOCATE property_cursor; DELETE FROM @Properties;
        FETCH NEXT FROM object_cursor INTO @ObjectName,@LevelType;
    END;
    CLOSE object_cursor; DEALLOCATE object_cursor;

    DECLARE @VersionPropertyName sysname=N'Toolbelt.Module.toolbelt.core.work-queue.Version';
    DECLARE @ModePropertyName sysname=N'Toolbelt.Module.toolbelt.core.work-queue.DeploymentMode';
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@VersionPropertyName)
        EXEC sys.sp_updateextendedproperty @name=@VersionPropertyName,@value=@TargetVersion;
    ELSE EXEC sys.sp_addextendedproperty @name=@VersionPropertyName,@value=@TargetVersion;
    IF EXISTS(SELECT 1 FROM sys.extended_properties WHERE class=0 AND name=@ModePropertyName)
        EXEC sys.sp_updateextendedproperty @name=@ModePropertyName,@value=@DeploymentMode;
    ELSE EXEC sys.sp_addextendedproperty @name=@ModePropertyName,@value=@DeploymentMode;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE()<>0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
