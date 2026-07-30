:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.archive.zip-memory.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.archive.zip-memory.DeploymentMode'
    , @DependencyVersionProperty sysname =
          N'Toolbelt.Module.toolbelt.core.result-table.Version'
    , @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)')
    , @InstalledVersion nvarchar(64)
    , @ProductMajorVersion int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'));

IF @ProductMajorVersion NOT IN (15, 16, 17)
    THROW 51330, N'Dieses Modul unterstuetzt ausschliesslich SQL Server 2019, 2022 und 2025.', 1;
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51331, N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.', 1;

IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
    THROW 51332, N'Die Dependency toolbelt_core.USP_PrepareResultTable fehlt.', 1;
IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name = @DependencyVersionProperty
   )
    THROW 51332, N'Die Dependency toolbelt.core.result-table ist nicht als Modul registriert.', 1;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), value)
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = @VersionProperty;

IF @InstalledVersion IS NOT NULL AND @InstalledVersion <> N'1.0.0'
    THROW 51333, N'Die installierte Modulversion ist diesem Deployment nicht bekannt.', 1;

IF @InstalledVersion IS NULL
   AND OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary') IS NOT NULL
    THROW 51334, N'Das Zielobjekt stammt nicht aus einem bekannten Toolbelt-Release.', 1;

IF SCHEMA_ID(N'toolbelt_archive') IS NULL
   AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
    THROW 51335, N'In der Installationsdatenbank fehlt CREATE SCHEMA.', 1;
IF SCHEMA_ID(N'toolbelt_archive') IS NOT NULL
   AND HAS_PERMS_BY_NAME(N'toolbelt_archive', N'SCHEMA', N'ALTER') <> 1
    THROW 51335, N'Fuer toolbelt_archive fehlt ALTER.', 1;
IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE PROCEDURE') <> 1
    THROW 51335, N'In der Installationsdatenbank fehlt CREATE PROCEDURE.', 1;

BEGIN TRANSACTION;
DECLARE @LockResult int;
EXEC @LockResult = sys.sp_getapplock
      @Resource = N'toolbelt.deploy.toolbelt.archive.zip-memory'
    , @LockMode = N'Exclusive'
    , @LockOwner = N'Transaction'
    , @LockTimeout = 0
    , @DbPrincipal = N'public';
IF @LockResult < 0
    THROW 51337, N'Ein paralleles Deployment dieses Moduls ist bereits aktiv.', 1;

IF SCHEMA_ID(N'toolbelt_archive') IS NULL
BEGIN
    EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_archive];';
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.Managed', @value = 1
        , @level0type = N'SCHEMA', @level0name = N'toolbelt_archive';
    EXEC sys.sp_addextendedproperty
          @name = N'Toolbelt.SchemaCategory', @value = N'archive'
        , @level0type = N'SCHEMA', @level0name = N'toolbelt_archive';
END;
GO
:r ../Source/USP_ExtractZipEntryFromBinary.sql
SET NOCOUNT ON;
BEGIN TRY
    DECLARE
          @VersionProperty sysname =
              N'Toolbelt.Module.toolbelt.archive.zip-memory.Version'
        , @ModeProperty sysname =
              N'Toolbelt.Module.toolbelt.archive.zip-memory.DeploymentMode';

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
