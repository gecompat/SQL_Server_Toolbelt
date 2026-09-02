:On Error exit
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @AssemblyBits varbinary(max) = $(AssemblyBits), @AssemblyHash varbinary(64), @InstalledAssemblyHash varbinary(64), @AssemblyDdl nvarchar(max);
IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) NOT IN (15, 16, 17)
    THROW 51530, N'Dieses Modul unterstützt SQL Server 2019, 2022 und 2025.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = N'clr enabled' AND value_in_use = 1)
    THROW 51531, N'CLR ist nicht aktiviert; das Modul ändert keine Instanzoption.', 1;
IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = N'clr strict security' AND value_in_use = 1)
    THROW 51532, N'clr strict security muss aktiviert bleiben.', 1;
IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits) < 1024
    THROW 51533, N'AssemblyBits enthält kein plausibles CLR-Release-Binary.', 1;
SET @AssemblyHash = HASHBYTES(N'SHA2_512', @AssemblyBits);
IF NOT EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash = @AssemblyHash)
    THROW 51534, N'Der exakte SHA2-512-Hash der Assembly ist nicht per sys.sp_add_trusted_assembly freigegeben.', 1;

SELECT @InstalledAssemblyHash = HASHBYTES(N'SHA2_512', af.content)
FROM sys.assemblies AS a
INNER JOIN sys.assembly_files AS af
    ON af.assembly_id = a.assembly_id
   AND af.file_id = 1
WHERE a.name = N'Toolbelt_Filesystem_Windows';

BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @LockResult int;
    EXEC @LockResult = sys.sp_getapplock @Resource = N'toolbelt.deploy.toolbelt.filesystem.windows', @LockMode = N'Exclusive', @LockOwner = N'Transaction', @LockTimeout = 0, @DbPrincipal = N'public';
    IF @LockResult < 0 THROW 51535, N'Ein paralleles Deployment dieses Moduls ist bereits aktiv.', 1;
    IF SCHEMA_ID(N'toolbelt_filesystem') IS NULL EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_filesystem];';
    IF @InstalledAssemblyHash IS NULL
        SET @AssemblyDdl = N'CREATE ASSEMBLY [Toolbelt_Filesystem_Windows] FROM ' + CONVERT(nvarchar(max), @AssemblyBits, 1) + N' WITH PERMISSION_SET = EXTERNAL_ACCESS;';
    ELSE IF @InstalledAssemblyHash <> @AssemblyHash
        SET @AssemblyDdl = N'ALTER ASSEMBLY [Toolbelt_Filesystem_Windows] FROM ' + CONVERT(nvarchar(max), @AssemblyBits, 1) + N';';
    IF @AssemblyDdl IS NOT NULL
        EXEC sys.sp_executesql @AssemblyDdl;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/FileSystemRoot.sql
:r ../Source/Procedures.sql

BEGIN TRY
    IF @@TRANCOUNT = 0 THROW 51536, N'Die Deployment-Transaktion ist vorzeitig beendet worden.', 1;
    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = N'Toolbelt.Module.toolbelt.filesystem.windows.Version')
        EXEC sys.sp_updateextendedproperty @name = N'Toolbelt.Module.toolbelt.filesystem.windows.Version', @value = N'1.0.0';
    ELSE
        EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Module.toolbelt.filesystem.windows.Version', @value = N'1.0.0';
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
