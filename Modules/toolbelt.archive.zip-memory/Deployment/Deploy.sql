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
    , @AssemblyName sysname =
          N'Toolbelt_Archive_ZipMemory'
    , @DeploymentMode nvarchar(16) =
          LOWER(N'$(DeploymentMode)')
    , @InstalledVersion nvarchar(64)
    , @ProductMajorVersion int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'))
    , @AssemblyBits varbinary(max) =
          $(AssemblyBits)
    , @AssemblyHash varbinary(64)
    , @InstalledAssemblyHash varbinary(64);

IF @ProductMajorVersion NOT IN (15, 16, 17)
    THROW 51330, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 51331, N'Die SQLCMD-Variable DeploymentMode muss local oder central sein.', 1;

IF OBJECT_ID(N'toolbelt_core.USP_PrepareResultTable', N'P') IS NULL
    THROW 51332, N'Die Dependency toolbelt_core.USP_PrepareResultTable fehlt.', 1;
IF NOT EXISTS
   (
       SELECT 1
       FROM sys.extended_properties
       WHERE class = 0
         AND major_id = 0
         AND minor_id = 0
         AND name = @DependencyVersionProperty
   )
    THROW 51332, N'Die Dependency toolbelt.core.result-table ist nicht als Modul registriert.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.configurations
       WHERE name = N'clr enabled'
         AND value_in_use = 1
   )
    THROW 51340, N'CLR ist auf dieser Instanz nicht aktiviert. Das Modul ändert keine Instanzoption.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.configurations
       WHERE name = N'clr strict security'
         AND value_in_use = 1
   )
    THROW 51342, N'clr strict security muss aktiviert bleiben.', 1;

IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits) < 1024
    THROW 51343, N'AssemblyBits enthält kein plausibles CLR-Release-Binary.', 1;

SET @AssemblyHash = HASHBYTES(N'SHA2_512', @AssemblyBits);

IF @AssemblyHash IS NULL
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.trusted_assemblies
          WHERE hash = @AssemblyHash
      )
    THROW 51345, N'Der exakte SHA2-512-Hash der CLR-ZIP-Assembly ist auf dieser Instanz nicht freigegeben.', 1;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), value)
FROM sys.extended_properties
WHERE class = 0
  AND major_id = 0
  AND minor_id = 0
  AND name = @VersionProperty;

SELECT @InstalledAssemblyHash = HASHBYTES(N'SHA2_512', af.content)
FROM sys.assemblies AS a
INNER JOIN sys.assembly_files AS af
  ON af.assembly_id = a.assembly_id
 AND af.file_id = 1
WHERE a.name = @AssemblyName;

IF @InstalledVersion IS NOT NULL
   AND @InstalledVersion NOT IN (N'1.0.0', N'1.1.0')
    THROW 51333, N'Die installierte Modulversion ist diesem Deployment nicht bekannt.', 1;

IF @InstalledVersion IS NULL
   AND
   (
       OBJECT_ID(N'toolbelt_archive.USP_ExtractZipEntryFromBinary') IS NOT NULL
       OR OBJECT_ID(N'toolbelt_archive.TVF_InternalExtractZipEntryClr') IS NOT NULL
       OR EXISTS
          (
              SELECT 1
              FROM sys.assemblies
              WHERE name = @AssemblyName
          )
   )
    THROW 51334, N'Ein Zielobjekt oder die Assembly stammt nicht aus einem bekannten Toolbelt-Release.', 1;

IF SCHEMA_ID(N'toolbelt_archive') IS NULL
   AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
    THROW 51335, N'In der Installationsdatenbank fehlt CREATE SCHEMA.', 1;
IF SCHEMA_ID(N'toolbelt_archive') IS NOT NULL
   AND HAS_PERMS_BY_NAME(N'toolbelt_archive', N'SCHEMA', N'ALTER') <> 1
    THROW 51335, N'Für toolbelt_archive fehlt ALTER.', 1;
IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE PROCEDURE') <> 1
    THROW 51335, N'In der Installationsdatenbank fehlt CREATE PROCEDURE.', 1;
IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE FUNCTION') <> 1
    THROW 51335, N'In der Installationsdatenbank fehlt CREATE FUNCTION.', 1;

IF EXISTS
   (
       SELECT 1
       FROM sys.assemblies
       WHERE name = @AssemblyName
   )
BEGIN
    IF ISNULL(@InstalledAssemblyHash, 0x) <> @AssemblyHash
       AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'ALTER ANY ASSEMBLY') <> 1
        THROW 51335, N'Für die vorhandene CLR-ZIP-Assembly fehlt ALTER ANY ASSEMBLY.', 1;
END
ELSE IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE ASSEMBLY') <> 1
    THROW 51335, N'In der Installationsdatenbank fehlt CREATE ASSEMBLY.', 1;

BEGIN TRY
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
              @name = N'Toolbelt.Managed'
            , @value = 1
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_archive';

        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.SchemaCategory'
            , @value = N'archive'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_archive';
    END;

    DROP FUNCTION IF EXISTS
        [toolbelt_archive].[TVF_InternalExtractZipEntryClr];

    IF @InstalledAssemblyHash IS NULL
       OR @InstalledAssemblyHash <> @AssemblyHash
    BEGIN
        DECLARE @AssemblyDdl nvarchar(max) =
            CASE
                WHEN EXISTS
                     (
                         SELECT 1
                         FROM sys.assemblies
                         WHERE name = @AssemblyName
                     )
                    THEN N'ALTER ASSEMBLY [Toolbelt_Archive_ZipMemory]'
                ELSE N'CREATE ASSEMBLY [Toolbelt_Archive_ZipMemory]'
            END
            + N' FROM '
            + CONVERT(nvarchar(max), @AssemblyBits, 1)
            + N' WITH PERMISSION_SET = SAFE;';

        EXEC sys.sp_executesql @AssemblyDdl;
    END;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/TVF_InternalExtractZipEntryClr.sql
:r ../Source/USP_ExtractZipEntryFromBinary.sql

SET NOCOUNT ON;

BEGIN TRY
    IF @@TRANCOUNT = 0
        THROW 51339, N'Die Deployment-Transaktion ist vorzeitig beendet worden.', 1;

    DECLARE
          @VersionProperty sysname =
              N'Toolbelt.Module.toolbelt.archive.zip-memory.Version'
        , @ModeProperty sysname =
              N'Toolbelt.Module.toolbelt.archive.zip-memory.DeploymentMode';

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 0
             AND major_id = 0
             AND minor_id = 0
             AND name = @VersionProperty
       )
        EXEC sys.sp_updateextendedproperty
              @name = @VersionProperty
            , @value = N'1.1.0';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = @VersionProperty
            , @value = N'1.1.0';

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 0
             AND major_id = 0
             AND minor_id = 0
             AND name = @ModeProperty
       )
        EXEC sys.sp_updateextendedproperty
              @name = @ModeProperty
            , @value = N'$(DeploymentMode)';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = @ModeProperty
            , @value = N'$(DeploymentMode)';

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           INNER JOIN sys.assemblies AS a
             ON a.assembly_id = ep.major_id
           WHERE ep.class = 5
             AND ep.name = N'Toolbelt.Managed'
             AND a.name = N'Toolbelt_Archive_ZipMemory'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.Managed'
            , @value = 1
            , @level0type = N'ASSEMBLY'
            , @level0name = N'Toolbelt_Archive_ZipMemory';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed'
            , @value = 1
            , @level0type = N'ASSEMBLY'
            , @level0name = N'Toolbelt_Archive_ZipMemory';

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties AS ep
           INNER JOIN sys.assemblies AS a
             ON a.assembly_id = ep.major_id
           WHERE ep.class = 5
             AND ep.name = N'Toolbelt.ModuleId'
             AND a.name = N'Toolbelt_Archive_ZipMemory'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.ModuleId'
            , @value = N'toolbelt.archive.zip-memory'
            , @level0type = N'ASSEMBLY'
            , @level0name = N'Toolbelt_Archive_ZipMemory';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId'
            , @value = N'toolbelt.archive.zip-memory'
            , @level0type = N'ASSEMBLY'
            , @level0name = N'Toolbelt_Archive_ZipMemory';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
