:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.datetime.bucket.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.datetime.bucket.DeploymentMode'
    , @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)')
    , @InstalledVersion nvarchar(64)
    , @ProductMajorVersion int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'));

DECLARE @ReleaseObjects TABLE
(
      ObjectName sysname NOT NULL PRIMARY KEY
    , ObjectType char(2) NOT NULL
);

INSERT INTO @ReleaseObjects (ObjectName, ObjectType)
VALUES
      (N'TVF_DateBucketDateTimeOffset', 'IF')
    , (N'TVF_DateBucketDateTime2', 'IF')
    , (N'TVF_DateBucketDate', 'IF');

IF @ProductMajorVersion NOT IN (15, 16, 17)
    THROW 51240, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51241, N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.', 1;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), value)
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = @VersionProperty;

IF @InstalledVersion IS NOT NULL AND @InstalledVersion <> N'1.0.0'
    THROW 51243, N'Die installierte Modulversion ist diesem Deployment nicht bekannt.', 1;

IF @InstalledVersion IS NULL
   AND EXISTS
       (
           SELECT 1
           FROM @ReleaseObjects AS release_objects
           WHERE OBJECT_ID
                 (
                     N'toolbelt_datetime.' + release_objects.ObjectName
                 ) IS NOT NULL
       )
    THROW 51244, N'Ein Zielobjekt stammt nicht aus einem bekannten Toolbelt-Release.', 1;

IF SCHEMA_ID(N'toolbelt_datetime') IS NULL
   AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
    THROW 51242, N'In der Installationsdatenbank fehlt CREATE SCHEMA.', 1;
IF SCHEMA_ID(N'toolbelt_datetime') IS NOT NULL
   AND HAS_PERMS_BY_NAME(N'toolbelt_datetime', N'SCHEMA', N'ALTER') <> 1
    THROW 51242, N'Für toolbelt_datetime fehlt ALTER.', 1;
IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE FUNCTION') <> 1
    THROW 51242, N'In der Installationsdatenbank fehlt CREATE FUNCTION.', 1;

BEGIN TRANSACTION;
DECLARE @LockResult int;
EXEC @LockResult = sys.sp_getapplock
      @Resource = N'toolbelt.deploy.toolbelt.datetime.bucket'
    , @LockMode = N'Exclusive'
    , @LockOwner = N'Transaction'
    , @LockTimeout = 0
    , @DbPrincipal = N'public';
IF @LockResult < 0
    THROW 51247, N'Ein paralleles Deployment dieses Moduls ist bereits aktiv.', 1;

IF SCHEMA_ID(N'toolbelt_datetime') IS NULL
BEGIN
    EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_datetime];';
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.Managed', @value = 1
        , @level0type = N'SCHEMA', @level0name = N'toolbelt_datetime';
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.SchemaCategory', @value = N'datetime'
        , @level0type = N'SCHEMA', @level0name = N'toolbelt_datetime';
END;
GO
:r ../Source/TVF_DateBucketDateTimeOffset.sql
:r ../Source/TVF_DateBucketDateTime2.sql
:r ../Source/TVF_DateBucketDate.sql
SET NOCOUNT ON;
BEGIN TRY
    DECLARE
          @VersionProperty sysname =
              N'Toolbelt.Module.toolbelt.datetime.bucket.Version'
        , @ModeProperty sysname =
              N'Toolbelt.Module.toolbelt.datetime.bucket.DeploymentMode';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties
           WHERE class = 0 AND major_id = 0 AND minor_id = 0
             AND name = @VersionProperty
       )
        EXEC sys.sp_updateextendedproperty
             @name = @VersionProperty, @value = N'1.0.0';
    ELSE
        EXEC sys.sp_addextendedproperty
             @name = @VersionProperty, @value = N'1.0.0';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties
           WHERE class = 0 AND major_id = 0 AND minor_id = 0
             AND name = @ModeProperty
       )
        EXEC sys.sp_updateextendedproperty
             @name = @ModeProperty, @value = N'$(DeploymentMode)';
    ELSE
        EXEC sys.sp_addextendedproperty
             @name = @ModeProperty, @value = N'$(DeploymentMode)';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
