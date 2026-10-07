:On Error exit
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'Der ScriptParser-Lifecycle erlaubt keine vorhandene Caller-Transaktion.', 16, 1);
    RETURN;
END;

SET NOCOUNT ON;
SET XACT_ABORT ON;

/*
 * Preflight vor jeder Mutation.
 */
DECLARE
      @DeploymentMode sysname = N'$(DeploymentMode)'
    , @AssemblyBits varbinary(max) = $(AssemblyBits)
    , @ScriptDomAssemblyBits varbinary(max) = $(ScriptDomAssemblyBits)
    , @AssemblyHash varbinary(64)
    , @ScriptDomAssemblyHash varbinary(64)
    , @InstalledAssemblyHash varbinary(64)
    , @InstalledScriptDomAssemblyHash varbinary(64)
    , @ProductMajorVersion int = TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion'))
    , @LockResult int
    , @InstalledVersion nvarchar(64);

IF @ProductMajorVersion NOT IN (15, 16, 17)
    THROW 53100, N'Dieses Modul unterstützt ausschließlich SQL Server 2019, 2022 und 2025.', 1;

IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 53101, N'DeploymentMode muss ''local'' oder ''central'' sein.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.configurations
       WHERE name = N'clr enabled'
         AND value_in_use = 1
   )
    THROW 53111, N'CLR ist nicht aktiviert. Das Modul ändert keine Instanzoption.', 1;

IF NOT EXISTS
   (
       SELECT 1
       FROM sys.configurations
       WHERE name = N'clr strict security'
         AND value_in_use = 1
   )
    THROW 53112, N'clr strict security muss aktiviert bleiben.', 1;

IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits) < 1024
    THROW 53102, N'AssemblyBits enthält kein plausibles CLR-Release-Binary.', 1;

SET @AssemblyHash = HASHBYTES(N'SHA2_512', @AssemblyBits);
SET @ScriptDomAssemblyHash = HASHBYTES(N'SHA2_512', @ScriptDomAssemblyBits);
IF @AssemblyHash IS NULL
   OR NOT EXISTS
      (
          SELECT 1
          FROM sys.trusted_assemblies
          WHERE hash = @AssemblyHash
      )
    THROW 53114, N'Der exakte SHA2-512-Hash der ScriptParser-Assembly ist nicht in sys.trusted_assemblies freigegeben.', 1;
IF @ScriptDomAssemblyBits IS NULL OR DATALENGTH(@ScriptDomAssemblyBits) < 1024
    THROW 53115, N'ScriptDomAssemblyBits enthält kein plausibles CLR-Release-Binary.', 1;
IF @ScriptDomAssemblyHash IS NULL
   OR NOT EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash = @ScriptDomAssemblyHash)
    THROW 53116, N'Der exakte SHA2-512-Hash der ScriptDom-Assembly ist nicht in sys.trusted_assemblies freigegeben.', 1;

SELECT @InstalledAssemblyHash = HASHBYTES(N'SHA2_512', af.content)
FROM sys.assemblies AS a
INNER JOIN sys.assembly_files AS af
    ON af.assembly_id = a.assembly_id
   AND af.file_id = 1
WHERE a.name = N'Toolbelt_Tsql_ScriptParser';

SELECT @InstalledScriptDomAssemblyHash = HASHBYTES(N'SHA2_512', af.content)
FROM sys.assemblies AS a
INNER JOIN sys.assembly_files AS af
    ON af.assembly_id = a.assembly_id
   AND af.file_id = 1
WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom';

IF @InstalledScriptDomAssemblyHash IS NOT NULL
   AND @InstalledScriptDomAssemblyHash <> @ScriptDomAssemblyHash
   AND
   (
       @InstalledScriptDomAssemblyHash <> 0x24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0
       OR @InstalledAssemblyHash IS NULL
       OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION'), 0) <> 1
       OR NOT EXISTS
          (
              SELECT 1
              FROM sys.assemblies AS a
              INNER JOIN sys.extended_properties AS moduleId
                ON moduleId.class = 5 AND moduleId.major_id = a.assembly_id AND moduleId.minor_id = 0
               AND moduleId.name = N'Toolbelt.ModuleId'
              WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom'
                AND TRY_CONVERT(nvarchar(128), moduleId.value) = N'toolbelt.tsql.script-parser'
          )
       OR EXISTS
          (
              SELECT 1
              FROM sys.assembly_references AS r
              WHERE r.referenced_assembly_id =
                    (SELECT assembly_id FROM sys.assemblies WHERE name = N'Microsoft.SqlServer.TransactSql.ScriptDom')
                AND r.assembly_id <>
                    (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
          )
       OR EXISTS
          (
              SELECT 1
              FROM sys.assembly_modules
              WHERE assembly_id =
                    (SELECT assembly_id FROM sys.assemblies WHERE name = N'Microsoft.SqlServer.TransactSql.ScriptDom')
          )
       OR EXISTS
          (
              SELECT 1
              FROM sys.assembly_references AS r
              WHERE r.referenced_assembly_id =
                    (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
          )
       OR EXISTS
          (
              SELECT 1
              FROM sys.assembly_modules AS m
              WHERE m.assembly_id =
                    (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
                AND m.object_id NOT IN
                    (SELECT o.object_id
                     FROM sys.objects AS o
                     WHERE o.schema_id = SCHEMA_ID(N'toolbelt_tsql')
                       AND o.name IN
                           (N'TVF_ParseScriptNodes', N'TVF_ParseScriptNodeProperties',
                            N'TVF_TokenizeScript', N'TVF_ParseScriptErrors'))
          )
   )
    THROW 53117, N'Die vorhandene ScriptDom-Assembly stimmt nicht mit dem freigegebenen Releaseartefakt überein.', 1;

    -- Ownership und Version unmittelbar vor Mutation erneut prüfen.
    SET @InstalledVersion = NULL;
    SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), value)
    FROM sys.extended_properties
    WHERE class = 0 AND major_id = 0 AND minor_id = 0
      AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version';

    IF EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE class = 0 AND major_id = 0 AND minor_id = 0
                 AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version')
       AND (@InstalledVersion IS NULL OR @InstalledVersion NOT IN (N'1.0.0', N'2.0.0'))
        THROW 53119, N'Die installierte ScriptParser-Version wird von diesem Lifecycle nicht unterstützt.', 1;

    IF EXISTS
       (SELECT 1 FROM sys.objects AS o
        INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
        LEFT JOIN sys.extended_properties AS managed
          ON managed.class = 1 AND managed.major_id = o.object_id AND managed.minor_id = 0 AND managed.name = N'Toolbelt.Managed'
        LEFT JOIN sys.extended_properties AS moduleId
          ON moduleId.class = 1 AND moduleId.major_id = o.object_id AND moduleId.minor_id = 0 AND moduleId.name = N'Toolbelt.ModuleId'
        LEFT JOIN sys.extended_properties AS version
          ON version.class = 1 AND version.major_id = o.object_id AND version.minor_id = 0 AND version.name = N'Toolbelt.ModuleVersion'
        WHERE s.name = N'toolbelt_tsql'
          AND o.name IN (N'TVF_ParseScriptNodes', N'TVF_ParseScriptNodeProperties', N'TVF_TokenizeScript', N'TVF_ParseScriptErrors')
          AND (o.type <> N'FT' OR TRY_CONVERT(int, managed.value) IS NULL OR TRY_CONVERT(int, managed.value) <> 1
               OR TRY_CONVERT(nvarchar(128), moduleId.value) IS NULL OR TRY_CONVERT(nvarchar(128), moduleId.value) <> N'toolbelt.tsql.script-parser'
               OR @InstalledVersion IS NULL OR TRY_CONVERT(nvarchar(64), version.value) IS NULL
               OR TRY_CONVERT(nvarchar(64), version.value) <> @InstalledVersion))
        THROW 53118, N'Der Funktionsbestand besitzt keine kohärente ScriptParser-Ownership.', 1;

    IF EXISTS
       (SELECT 1 FROM sys.assemblies AS a
        LEFT JOIN sys.extended_properties AS managed
          ON managed.class = 5 AND managed.major_id = a.assembly_id AND managed.minor_id = 0 AND managed.name = N'Toolbelt.Managed'
        LEFT JOIN sys.extended_properties AS moduleId
          ON moduleId.class = 5 AND moduleId.major_id = a.assembly_id AND moduleId.minor_id = 0 AND moduleId.name = N'Toolbelt.ModuleId'
        WHERE a.name = N'Toolbelt_Tsql_ScriptParser'
          AND (@InstalledVersion IS NULL OR TRY_CONVERT(int, managed.value) IS NULL OR TRY_CONVERT(int, managed.value) <> 1
               OR TRY_CONVERT(nvarchar(128), moduleId.value) IS NULL
               OR TRY_CONVERT(nvarchar(128), moduleId.value) <> N'toolbelt.tsql.script-parser'))
        THROW 53118, N'Die Provider-Assembly besitzt keine kohärente ScriptParser-Ownership.', 2;

    IF @InstalledVersion IS NOT NULL
       AND (NOT EXISTS (SELECT 1 FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
            OR (SELECT COUNT(*) FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_tsql')
                AND name IN (N'TVF_ParseScriptNodes', N'TVF_ParseScriptNodeProperties', N'TVF_TokenizeScript', N'TVF_ParseScriptErrors')) <> 4)
        THROW 53118, N'Der markierte ScriptParser-Modulbestand ist unvollständig.', 3;
    IF @InstalledVersion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.extended_properties
                       WHERE class = 0 AND major_id = 0 AND minor_id = 0
                         AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode'
                         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central'))
        THROW 53118, N'Der DeploymentMode-Marker ist nicht kohärent.', 4;

BEGIN TRY
    BEGIN TRANSACTION;

    EXEC @LockResult = sys.sp_getapplock
          @Resource = N'toolbelt.deploy.toolbelt.tsql.script-parser'
        , @LockMode = N'Exclusive'
        , @LockOwner = N'Transaction'
        , @LockTimeout = 0
        , @DbPrincipal = N'public';

    IF @LockResult < 0
        THROW 53104, N'Ein paralleles Deployment dieses Moduls ist bereits aktiv.', 1;
    -- Ownership und Version unmittelbar vor Mutation erneut prüfen.
    SET @InstalledVersion = NULL;
    SELECT @InstalledVersion = TRY_CONVERT(nvarchar(64), value)
    FROM sys.extended_properties
    WHERE class = 0 AND major_id = 0 AND minor_id = 0
      AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version';

    IF EXISTS (SELECT 1 FROM sys.extended_properties
               WHERE class = 0 AND major_id = 0 AND minor_id = 0
                 AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version')
       AND (@InstalledVersion IS NULL OR @InstalledVersion NOT IN (N'1.0.0', N'2.0.0'))
        THROW 53119, N'Die installierte ScriptParser-Version wird von diesem Lifecycle nicht unterstützt.', 1;

    IF EXISTS
       (SELECT 1 FROM sys.objects AS o
        INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
        LEFT JOIN sys.extended_properties AS managed
          ON managed.class = 1 AND managed.major_id = o.object_id AND managed.minor_id = 0 AND managed.name = N'Toolbelt.Managed'
        LEFT JOIN sys.extended_properties AS moduleId
          ON moduleId.class = 1 AND moduleId.major_id = o.object_id AND moduleId.minor_id = 0 AND moduleId.name = N'Toolbelt.ModuleId'
        LEFT JOIN sys.extended_properties AS version
          ON version.class = 1 AND version.major_id = o.object_id AND version.minor_id = 0 AND version.name = N'Toolbelt.ModuleVersion'
        WHERE s.name = N'toolbelt_tsql'
          AND o.name IN (N'TVF_ParseScriptNodes', N'TVF_ParseScriptNodeProperties', N'TVF_TokenizeScript', N'TVF_ParseScriptErrors')
          AND (o.type <> N'FT' OR TRY_CONVERT(int, managed.value) IS NULL OR TRY_CONVERT(int, managed.value) <> 1
               OR TRY_CONVERT(nvarchar(128), moduleId.value) IS NULL OR TRY_CONVERT(nvarchar(128), moduleId.value) <> N'toolbelt.tsql.script-parser'
               OR @InstalledVersion IS NULL OR TRY_CONVERT(nvarchar(64), version.value) IS NULL
               OR TRY_CONVERT(nvarchar(64), version.value) <> @InstalledVersion))
        THROW 53118, N'Der Funktionsbestand besitzt keine kohärente ScriptParser-Ownership.', 1;

    IF EXISTS
       (SELECT 1 FROM sys.assemblies AS a
        LEFT JOIN sys.extended_properties AS managed
          ON managed.class = 5 AND managed.major_id = a.assembly_id AND managed.minor_id = 0 AND managed.name = N'Toolbelt.Managed'
        LEFT JOIN sys.extended_properties AS moduleId
          ON moduleId.class = 5 AND moduleId.major_id = a.assembly_id AND moduleId.minor_id = 0 AND moduleId.name = N'Toolbelt.ModuleId'
        WHERE a.name = N'Toolbelt_Tsql_ScriptParser'
          AND (@InstalledVersion IS NULL OR TRY_CONVERT(int, managed.value) IS NULL OR TRY_CONVERT(int, managed.value) <> 1
               OR TRY_CONVERT(nvarchar(128), moduleId.value) IS NULL
               OR TRY_CONVERT(nvarchar(128), moduleId.value) <> N'toolbelt.tsql.script-parser'))
        THROW 53118, N'Die Provider-Assembly besitzt keine kohärente ScriptParser-Ownership.', 2;

    IF @InstalledVersion IS NOT NULL
       AND (NOT EXISTS (SELECT 1 FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
            OR (SELECT COUNT(*) FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_tsql')
                AND name IN (N'TVF_ParseScriptNodes', N'TVF_ParseScriptNodeProperties', N'TVF_TokenizeScript', N'TVF_ParseScriptErrors')) <> 4)
        THROW 53118, N'Der markierte ScriptParser-Modulbestand ist unvollständig.', 3;
    IF @InstalledVersion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.extended_properties
                       WHERE class = 0 AND major_id = 0 AND minor_id = 0
                         AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode'
                         AND TRY_CONVERT(nvarchar(16), value) IN (N'local', N'central'))
        THROW 53118, N'Der DeploymentMode-Marker ist nicht kohärent.', 4;
    SET @InstalledAssemblyHash = NULL;
    SET @InstalledScriptDomAssemblyHash = NULL;
    SELECT @InstalledAssemblyHash = HASHBYTES(N'SHA2_512', af.content)
    FROM sys.assemblies AS a INNER JOIN sys.assembly_files AS af ON af.assembly_id = a.assembly_id AND af.file_id = 1
    WHERE a.name = N'Toolbelt_Tsql_ScriptParser';
    SELECT @InstalledScriptDomAssemblyHash = HASHBYTES(N'SHA2_512', af.content)
    FROM sys.assemblies AS a INNER JOIN sys.assembly_files AS af ON af.assembly_id = a.assembly_id AND af.file_id = 1
    WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom';
    IF @InstalledScriptDomAssemblyHash IS NOT NULL
       AND @InstalledScriptDomAssemblyHash <> @ScriptDomAssemblyHash
       AND
       (
           @InstalledScriptDomAssemblyHash <> 0x24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0
           OR @InstalledAssemblyHash IS NULL
           OR COALESCE(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'VIEW DEFINITION'), 0) <> 1
           OR NOT EXISTS
              (
                  SELECT 1
                  FROM sys.assemblies AS a
                  INNER JOIN sys.extended_properties AS moduleId
                    ON moduleId.class = 5 AND moduleId.major_id = a.assembly_id AND moduleId.minor_id = 0
                   AND moduleId.name = N'Toolbelt.ModuleId'
                  WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom'
                    AND TRY_CONVERT(nvarchar(128), moduleId.value) = N'toolbelt.tsql.script-parser'
              )
           OR EXISTS
              (
                  SELECT 1
                  FROM sys.assembly_references AS r
                  WHERE r.referenced_assembly_id =
                        (SELECT assembly_id FROM sys.assemblies WHERE name = N'Microsoft.SqlServer.TransactSql.ScriptDom')
                    AND r.assembly_id <>
                        (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
              )
           OR EXISTS
              (
                  SELECT 1
                  FROM sys.assembly_modules
                  WHERE assembly_id =
                        (SELECT assembly_id FROM sys.assemblies WHERE name = N'Microsoft.SqlServer.TransactSql.ScriptDom')
              )
           OR EXISTS
              (
                  SELECT 1
                  FROM sys.assembly_references AS r
                  WHERE r.referenced_assembly_id =
                        (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
              )
           OR EXISTS
              (
                  SELECT 1
                  FROM sys.assembly_modules AS m
                  WHERE m.assembly_id =
                        (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
                    AND m.object_id NOT IN
                        (SELECT o.object_id
                         FROM sys.objects AS o
                         WHERE o.schema_id = SCHEMA_ID(N'toolbelt_tsql')
                           AND o.name IN
                               (N'TVF_ParseScriptNodes', N'TVF_ParseScriptNodeProperties',
                                N'TVF_TokenizeScript', N'TVF_ParseScriptErrors'))
              )
       )
        THROW 53117, N'Die vorhandene ScriptDom-Assembly stimmt nicht mit dem freigegebenen Releaseartefakt überein.', 1;

    IF SCHEMA_ID(N'toolbelt_tsql') IS NULL
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_tsql];';
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed'
            , @value = 1
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_tsql';
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.SchemaCategory'
            , @value = N'tsql'
            , @level0type = N'SCHEMA'
            , @level0name = N'toolbelt_tsql';
    END;

    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptNodes];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptNodeProperties];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_TokenizeScript];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptErrors];

    IF @InstalledScriptDomAssemblyHash IS NOT NULL
       AND @InstalledScriptDomAssemblyHash <> @ScriptDomAssemblyHash
    BEGIN
        DROP ASSEMBLY [Toolbelt_Tsql_ScriptParser];
        DECLARE @AlterScriptDomDdl nvarchar(max) =
            N'ALTER ASSEMBLY [Microsoft.SqlServer.TransactSql.ScriptDom] FROM '
            + CONVERT(nvarchar(max), @ScriptDomAssemblyBits, 1)
            + N' WITH PERMISSION_SET = UNSAFE;';
        EXEC sys.sp_executesql @AlterScriptDomDdl;
        SET @InstalledAssemblyHash = NULL;
    END;

    IF @InstalledAssemblyHash IS NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM sys.assemblies WHERE name = N'Microsoft.SqlServer.TransactSql.ScriptDom')
        BEGIN
            DECLARE @CreateScriptDomDdl nvarchar(max) =
                N'CREATE ASSEMBLY [Microsoft.SqlServer.TransactSql.ScriptDom] FROM '
                + CONVERT(nvarchar(max), @ScriptDomAssemblyBits, 1)
                + N' WITH PERMISSION_SET = UNSAFE;';
            EXEC sys.sp_executesql @CreateScriptDomDdl;
            EXEC sys.sp_addextendedproperty
                  @name = N'Toolbelt.ModuleId', @value = N'toolbelt.tsql.script-parser'
                , @level0type = N'ASSEMBLY', @level0name = N'Microsoft.SqlServer.TransactSql.ScriptDom';
        END
        DECLARE @CreateAssemblyDdl nvarchar(max) =
            N'CREATE ASSEMBLY [Toolbelt_Tsql_ScriptParser] FROM '
            + CONVERT(nvarchar(max), @AssemblyBits, 1)
            + N' WITH PERMISSION_SET = UNSAFE;';
        EXEC sys.sp_executesql @CreateAssemblyDdl;
    END
    ELSE IF @InstalledAssemblyHash <> @AssemblyHash
    BEGIN
        DECLARE @AlterAssemblyDdl nvarchar(max) =
            N'ALTER ASSEMBLY [Toolbelt_Tsql_ScriptParser] FROM '
            + CONVERT(nvarchar(max), @AssemblyBits, 1) + N';';
        EXEC sys.sp_executesql @AlterAssemblyDdl;
    END;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/TVF_ParseScriptNodes.sql
:r ../Source/TVF_ParseScriptNodeProperties.sql
:r ../Source/TVF_TokenizeScript.sql
:r ../Source/TVF_ParseScriptErrors.sql

BEGIN TRY
    IF @@TRANCOUNT = 0
        THROW 53105, N'Die Deployment-Transaktion ist vorzeitig beendet worden.', 1;

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 0
             AND major_id = 0
             AND minor_id = 0
             AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version'
            , @value = N'2.0.0';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Module.toolbelt.tsql.script-parser.Version'
            , @value = N'2.0.0';

    IF EXISTS
       (
           SELECT 1
           FROM sys.extended_properties
           WHERE class = 0
             AND major_id = 0
             AND minor_id = 0
             AND name = N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode'
            , @value = N'$(DeploymentMode)';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode'
            , @value = N'$(DeploymentMode)';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties AS ep
           INNER JOIN sys.assemblies AS a ON a.assembly_id = ep.major_id
           WHERE ep.class = 5 AND ep.name = N'Toolbelt.Managed'
             AND a.name = N'Toolbelt_Tsql_ScriptParser'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_Tsql_ScriptParser';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Managed', @value = 1
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_Tsql_ScriptParser';

    IF EXISTS
       (
           SELECT 1 FROM sys.extended_properties AS ep
           INNER JOIN sys.assemblies AS a ON a.assembly_id = ep.major_id
           WHERE ep.class = 5 AND ep.name = N'Toolbelt.ModuleId'
             AND a.name = N'Toolbelt_Tsql_ScriptParser'
       )
        EXEC sys.sp_updateextendedproperty
              @name = N'Toolbelt.ModuleId', @value = N'toolbelt.tsql.script-parser'
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_Tsql_ScriptParser';
    ELSE
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.ModuleId', @value = N'toolbelt.tsql.script-parser'
            , @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_Tsql_ScriptParser';

    DECLARE @FunctionName sysname;
    DECLARE FunctionCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT name
        FROM sys.objects
        WHERE schema_id = SCHEMA_ID(N'toolbelt_tsql')
          AND name IN (
                N'TVF_ParseScriptNodes'
              , N'TVF_ParseScriptNodeProperties'
              , N'TVF_TokenizeScript'
              , N'TVF_ParseScriptErrors'
          );
    OPEN FunctionCursor;
    FETCH NEXT FROM FunctionCursor INTO @FunctionName;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF EXISTS (
            SELECT 1 FROM sys.extended_properties
            WHERE class = 1 AND major_id = OBJECT_ID(N'toolbelt_tsql.' + @FunctionName) AND name = N'Toolbelt.Managed'
        )
            EXEC sys.sp_updateextendedproperty
                  @name = N'Toolbelt.Managed', @value = 1
                , @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql'
                , @level1type = N'FUNCTION', @level1name = @FunctionName;
        ELSE
            EXEC sys.sp_addextendedproperty
                  @name = N'Toolbelt.Managed', @value = 1
                , @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql'
                , @level1type = N'FUNCTION', @level1name = @FunctionName;

        IF EXISTS (
            SELECT 1 FROM sys.extended_properties
            WHERE class = 1 AND major_id = OBJECT_ID(N'toolbelt_tsql.' + @FunctionName) AND name = N'Toolbelt.ModuleId'
        )
            EXEC sys.sp_updateextendedproperty
                  @name = N'Toolbelt.ModuleId', @value = N'toolbelt.tsql.script-parser'
                , @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql'
                , @level1type = N'FUNCTION', @level1name = @FunctionName;
        ELSE
            EXEC sys.sp_addextendedproperty
                  @name = N'Toolbelt.ModuleId', @value = N'toolbelt.tsql.script-parser'
                , @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql'
                , @level1type = N'FUNCTION', @level1name = @FunctionName;

        IF EXISTS (
            SELECT 1 FROM sys.extended_properties
            WHERE class = 1 AND major_id = OBJECT_ID(N'toolbelt_tsql.' + @FunctionName) AND name = N'Toolbelt.ModuleVersion'
        )
            EXEC sys.sp_updateextendedproperty
                  @name = N'Toolbelt.ModuleVersion', @value = N'2.0.0'
                , @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql'
                , @level1type = N'FUNCTION', @level1name = @FunctionName;
        ELSE
            EXEC sys.sp_addextendedproperty
                  @name = N'Toolbelt.ModuleVersion', @value = N'2.0.0'
                , @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql'
                , @level1type = N'FUNCTION', @level1name = @FunctionName;

        IF EXISTS (
            SELECT 1 FROM sys.extended_properties
            WHERE class = 1 AND major_id = OBJECT_ID(N'toolbelt_tsql.' + @FunctionName) AND name = N'Toolbelt.Visibility'
        )
            EXEC sys.sp_updateextendedproperty
                  @name = N'Toolbelt.Visibility', @value = N'public'
                , @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql'
                , @level1type = N'FUNCTION', @level1name = @FunctionName;
        ELSE
            EXEC sys.sp_addextendedproperty
                  @name = N'Toolbelt.Visibility', @value = N'public'
                , @level0type = N'SCHEMA', @level0name = N'toolbelt_tsql'
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
