:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.file.content.Version'
    , @InstalledVersion nvarchar(64)
    , @ProductMajorVersion int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'));

IF @ProductMajorVersion NOT IN (15, 16, 17)
    THROW 51270, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), value)
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = @VersionProperty;

IF @InstalledVersion IS NOT NULL AND @InstalledVersion <> N'1.0.0'
    THROW 51273, N'Die installierte Modulversion ist diesem Uninstall nicht bekannt.', 1;

IF @InstalledVersion IS NULL
   AND (
          OBJECT_ID(N'toolbelt_file.USP_LoadBinaryFile') IS NOT NULL
       OR OBJECT_ID(N'toolbelt_file.USP_LoadTextFile') IS NOT NULL
       OR OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist') IS NOT NULL
       )
    THROW 51274, N'Eines der Zielobjekte stammt nicht aus einem bekannten Toolbelt-Release.', 1;

BEGIN TRANSACTION;
DECLARE @LockResult int;
EXEC @LockResult = sys.sp_getapplock
      @Resource = N'toolbelt.deploy.toolbelt.file.content'
    , @LockMode = N'Exclusive'
    , @LockOwner = N'Transaction'
    , @LockTimeout = 0
    , @DbPrincipal = N'public';
IF @LockResult < 0
    THROW 51277, N'Ein paralleles Uninstall dieses Moduls ist bereits aktiv.', 1;

IF OBJECT_ID(N'toolbelt_file.USP_LoadBinaryFile', N'P') IS NOT NULL
    DROP PROCEDURE [toolbelt_file].[USP_LoadBinaryFile];
IF OBJECT_ID(N'toolbelt_file.USP_LoadTextFile', N'P') IS NOT NULL
    DROP PROCEDURE [toolbelt_file].[USP_LoadTextFile];
IF OBJECT_ID(N'toolbelt_file.FileContentRootAllowlist', N'U') IS NOT NULL
    DROP TABLE [toolbelt_file].[FileContentRootAllowlist];

IF EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name = @VersionProperty
   )
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;

IF EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name = N'Toolbelt.Module.toolbelt.file.content.DeploymentMode'
   )
    EXEC sys.sp_dropextendedproperty
         @name = N'Toolbelt.Module.toolbelt.file.content.DeploymentMode';

IF SCHEMA_ID(N'toolbelt_file') IS NOT NULL
   AND NOT EXISTS
       (
           SELECT 1 FROM sys.objects
           WHERE schema_id = SCHEMA_ID(N'toolbelt_file')
       )
BEGIN
    EXEC sys.sp_executesql N'DROP SCHEMA [toolbelt_file];';
END;

COMMIT TRANSACTION;
GO
