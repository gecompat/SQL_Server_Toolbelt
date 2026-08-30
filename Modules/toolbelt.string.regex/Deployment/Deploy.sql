:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.string.regex.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.string.regex.DeploymentMode'
    , @AssemblyName sysname = N'Toolbelt_String_Regex'
    , @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)')
    , @InstalledVersion nvarchar(64)
    , @ProductMajorVersion int =
          TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'))
    , @AssemblyBits varbinary(max) = $(AssemblyBits)
    , @AssemblyHash varbinary(64)
    , @InstalledAssemblyHash varbinary(64);

IF @ProductMajorVersion NOT IN (15, 16, 17)
    THROW 52030, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 52031, N'DeploymentMode muss local oder central sein.', 1;

IF NOT EXISTS
   (
       SELECT 1 FROM sys.configurations
       WHERE name = N'clr enabled' AND value_in_use = 1
   )
    THROW 52040, N'CLR ist nicht aktiviert. Das Modul ändert keine Instanzoption.', 1;
IF NOT EXISTS
   (
       SELECT 1 FROM sys.configurations
       WHERE name = N'clr strict security' AND value_in_use = 1
   )
    THROW 52042, N'clr strict security muss aktiviert bleiben.', 1;
IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits) < 1024
    THROW 52043, N'AssemblyBits enthält kein plausibles CLR-Release-Binary.', 1;

SET @AssemblyHash = HASHBYTES(N'SHA2_512', @AssemblyBits);
IF @AssemblyHash IS NULL
   OR NOT EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash = @AssemblyHash)
    THROW 52045, N'Der exakte SHA2-512-Hash der Regex-Assembly ist nicht freigegeben.', 1;

SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), value)
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = @VersionProperty;

SELECT @InstalledAssemblyHash = HASHBYTES(N'SHA2_512', af.content)
FROM sys.assemblies AS a
INNER JOIN sys.assembly_files AS af
  ON af.assembly_id = a.assembly_id AND af.file_id = 1
WHERE a.name = @AssemblyName;

IF @InstalledVersion IS NOT NULL AND @InstalledVersion <> N'1.0.0'
    THROW 52032, N'Die installierte Modulversion ist diesem Deployment nicht bekannt.', 1;

IF @InstalledVersion IS NULL
   AND
   (
       OBJECT_ID(N'toolbelt_string.SVF_RegexIsMatch') IS NOT NULL
       OR OBJECT_ID(N'toolbelt_string.SVF_RegexInstr') IS NOT NULL
       OR OBJECT_ID(N'toolbelt_string.SVF_RegexCount') IS NOT NULL
       OR EXISTS (SELECT 1 FROM sys.assemblies WHERE name = @AssemblyName)
   )
    THROW 52033, N'Ein Zielobjekt oder die Assembly stammt nicht aus einem bekannten Toolbelt-Release.', 1;

IF SCHEMA_ID(N'toolbelt_string') IS NULL
   AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA') <> 1
    THROW 52034, N'In der Installationsdatenbank fehlt CREATE SCHEMA.', 1;
IF SCHEMA_ID(N'toolbelt_string') IS NOT NULL
   AND HAS_PERMS_BY_NAME(N'toolbelt_string', N'SCHEMA', N'ALTER') <> 1
    THROW 52034, N'Für toolbelt_string fehlt ALTER.', 1;
IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE FUNCTION') <> 1
    THROW 52034, N'In der Installationsdatenbank fehlt CREATE FUNCTION.', 1;

IF @InstalledAssemblyHash IS NULL
BEGIN
    IF HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE ASSEMBLY') <> 1
        THROW 52034, N'In der Installationsdatenbank fehlt CREATE ASSEMBLY.', 1;
END
ELSE IF @InstalledAssemblyHash <> @AssemblyHash
    AND HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'ALTER ANY ASSEMBLY') <> 1
    THROW 52034, N'Für die vorhandene Regex-Assembly fehlt ALTER ANY ASSEMBLY.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @LockResult int;
    EXEC @LockResult = sys.sp_getapplock
          @Resource = N'toolbelt.deploy.toolbelt.string.regex'
        , @LockMode = N'Exclusive'
        , @LockOwner = N'Transaction'
        , @LockTimeout = 0
        , @DbPrincipal = N'public';
    IF @LockResult < 0
        THROW 52035, N'Ein paralleles Deployment dieses Moduls ist bereits aktiv.', 1;

    IF SCHEMA_ID(N'toolbelt_string') IS NULL
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_string];';
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string';
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.SchemaCategory', @value = N'string'
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string';
    END;

    DROP FUNCTION IF EXISTS [toolbelt_string].[SVF_RegexIsMatch];
    DROP FUNCTION IF EXISTS [toolbelt_string].[SVF_RegexInstr];
    DROP FUNCTION IF EXISTS [toolbelt_string].[SVF_RegexCount];

    IF @InstalledAssemblyHash IS NULL OR @InstalledAssemblyHash <> @AssemblyHash
    BEGIN
        DECLARE @AssemblyDdl nvarchar(max) =
            CASE WHEN @InstalledAssemblyHash IS NULL
                 THEN N'CREATE ASSEMBLY [Toolbelt_String_Regex]'
                 ELSE N'ALTER ASSEMBLY [Toolbelt_String_Regex]'
            END
            + N' FROM ' + CONVERT(nvarchar(max), @AssemblyBits, 1)
            + N' WITH PERMISSION_SET = SAFE;';
        EXEC sys.sp_executesql @AssemblyDdl;
    END;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/RegexFunctions.sql

SET NOCOUNT ON;
BEGIN TRY
    IF @@TRANCOUNT = 0
        THROW 52039, N'Die Deployment-Transaktion ist vorzeitig beendet worden.', 1;

    DECLARE
          @VersionProperty sysname =
              N'Toolbelt.Module.toolbelt.string.regex.Version'
        , @ModeProperty sysname =
              N'Toolbelt.Module.toolbelt.string.regex.DeploymentMode';

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
        EXEC sys.sp_updateextendedproperty @name = @VersionProperty, @value = N'1.0.0';
    ELSE
        EXEC sys.sp_addextendedproperty @name = @VersionProperty, @value = N'1.0.0';

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
        EXEC sys.sp_updateextendedproperty @name = @ModeProperty, @value = N'$(DeploymentMode)';
    ELSE
        EXEC sys.sp_addextendedproperty @name = @ModeProperty, @value = N'$(DeploymentMode)';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties AS ep
           INNER JOIN sys.assemblies AS a ON a.assembly_id = ep.major_id
           WHERE ep.class = 5 AND ep.name = N'Toolbelt.Managed'
             AND a.name = N'Toolbelt_String_Regex'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_Regex';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_Regex';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties AS ep
           INNER JOIN sys.assemblies AS a ON a.assembly_id = ep.major_id
           WHERE ep.class = 5 AND ep.name = N'Toolbelt.ModuleId'
             AND a.name = N'Toolbelt_String_Regex'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.ModuleId', @value = N'toolbelt.string.regex'
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_Regex';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId', @value = N'toolbelt.string.regex'
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_Regex';

    DECLARE @FunctionName sysname;
    DECLARE FunctionCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT name
        FROM sys.objects
        WHERE schema_id = SCHEMA_ID(N'toolbelt_string')
          AND name IN (N'SVF_RegexIsMatch', N'SVF_RegexInstr', N'SVF_RegexCount');
    OPEN FunctionCursor;
    FETCH NEXT FROM FunctionCursor INTO @FunctionName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId', @value = N'toolbelt.string.regex'
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleVersion', @value = N'1.0.0'
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Visibility', @value = N'public'
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        FETCH NEXT FROM FunctionCursor INTO @FunctionName;
    END;
    CLOSE FunctionCursor;
    DEALLOCATE FunctionCursor;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF CURSOR_STATUS(N'local', N'FunctionCursor') >= 0 CLOSE FunctionCursor;
    IF CURSOR_STATUS(N'local', N'FunctionCursor') > -3 DEALLOCATE FunctionCursor;
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
