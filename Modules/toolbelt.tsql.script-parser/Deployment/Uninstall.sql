:On Error exit
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'Der ScriptParser-Lifecycle erlaubt keine vorhandene Caller-Transaktion.', 16, 1);
    RETURN;
END;

SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE
      @ConfirmNoExternalConsumers bit =
          TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)')
    , @VersionProperty sysname =
          N'Toolbelt.Module.toolbelt.tsql.script-parser.Version'
    , @ModeProperty sysname =
          N'Toolbelt.Module.toolbelt.tsql.script-parser.DeploymentMode'
    , @DeploymentMode nvarchar(16)
    , @InstalledVersion nvarchar(64)
    , @LockResult int
    , @NodesId int = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptNodes')
    , @PropsId int = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptNodeProperties')
    , @TokensId int = OBJECT_ID(N'toolbelt_tsql.TVF_TokenizeScript')
    , @ErrorsId int = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptErrors')
    , @AssemblyId int =
          (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser');

IF @ConfirmNoExternalConsumers IS NULL
    THROW 53106, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;

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

IF NOT EXISTS
   (
       SELECT 1 FROM sys.extended_properties
       WHERE class = 0 AND major_id = 0 AND minor_id = 0
         AND name = @VersionProperty
   )
    RETURN;

SELECT @DeploymentMode = TRY_CONVERT(nvarchar(16), value)
FROM sys.extended_properties
WHERE class = 0 AND major_id = 0 AND minor_id = 0
  AND name = @ModeProperty;

IF @DeploymentMode IS NULL OR @DeploymentMode NOT IN (N'local', N'central')
    THROW 53118, N'Der DeploymentMode-Marker ist nicht kohärent.', 4;

IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
    THROW 53106, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 2;

IF EXISTS
   (SELECT 1 FROM sys.assemblies AS a
    INNER JOIN sys.extended_properties AS ep ON ep.class = 5 AND ep.major_id = a.assembly_id AND ep.minor_id = 0
    INNER JOIN sys.assembly_files AS af ON af.assembly_id = a.assembly_id AND af.file_id = 1
    WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom' AND ep.name = N'Toolbelt.ModuleId'
      AND TRY_CONVERT(nvarchar(128), ep.value) = N'toolbelt.tsql.script-parser'
      AND HASHBYTES(N'SHA2_512', af.content) <> 0x24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0)
    THROW 53117, N'Die moduleigene ScriptDom-Assembly stimmt nicht mit der qualifizierten Dependency überein.', 1;
IF EXISTS
   (
       SELECT 1 FROM sys.sql_expression_dependencies
       WHERE referenced_id IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
         AND referencing_id NOT IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
   )
    THROW 53108, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

IF @AssemblyId IS NOT NULL
   AND EXISTS
       (
           SELECT 1 FROM sys.assembly_modules
           WHERE assembly_id = @AssemblyId
             AND object_id NOT IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
       )
    THROW 53108, N'Die ScriptParser-Assembly wird von einem fremden SQL-Objekt verwendet.', 2;

IF @AssemblyId IS NOT NULL
   AND EXISTS
       (SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id = @AssemblyId)
    THROW 53108, N'Die ScriptParser-Assembly wird von einer anderen Assembly referenziert.', 3;

IF EXISTS
   (SELECT 1 FROM sys.assemblies AS a
    INNER JOIN sys.extended_properties AS ep ON ep.class = 5 AND ep.major_id = a.assembly_id AND ep.minor_id = 0
    WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom' AND ep.name = N'Toolbelt.ModuleId'
      AND TRY_CONVERT(nvarchar(128), ep.value) = N'toolbelt.tsql.script-parser'
      AND (EXISTS (SELECT 1 FROM sys.assembly_references AS r WHERE r.referenced_assembly_id = a.assembly_id AND r.assembly_id <> ISNULL(@AssemblyId, -1))
           OR EXISTS (SELECT 1 FROM sys.assembly_modules AS m WHERE m.assembly_id = a.assembly_id)))
    THROW 53108, N'Die moduleigene ScriptDom-Assembly wird von einem fremden Verbraucher verwendet.', 4;

BEGIN TRY
    BEGIN TRANSACTION;
    EXEC @LockResult = sys.sp_getapplock
          @Resource = N'toolbelt.deploy.toolbelt.tsql.script-parser'
        , @LockMode = N'Exclusive', @LockOwner = N'Transaction'
        , @LockTimeout = 0, @DbPrincipal = N'public';
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

    SET @NodesId = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptNodes');
    SET @PropsId = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptNodeProperties');
    SET @TokensId = OBJECT_ID(N'toolbelt_tsql.TVF_TokenizeScript');
    SET @ErrorsId = OBJECT_ID(N'toolbelt_tsql.TVF_ParseScriptErrors');
    SET @AssemblyId = (SELECT assembly_id FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser');
    SET @DeploymentMode = NULL;
    SELECT @DeploymentMode = TRY_CONVERT(nvarchar(16), value)
    FROM sys.extended_properties WHERE class = 0 AND major_id = 0 AND minor_id = 0 AND name = @ModeProperty;
    IF @DeploymentMode IS NULL OR @DeploymentMode NOT IN (N'local', N'central')
        THROW 53118, N'Der DeploymentMode-Marker ist nicht kohärent.', 4;
    IF @DeploymentMode = N'central' AND @ConfirmNoExternalConsumers <> 1
        THROW 53106, N'Bei zentraler Installation ist ConfirmNoExternalConsumers=1 erforderlich.', 2;
    IF EXISTS
       (SELECT 1 FROM sys.assemblies AS a
        INNER JOIN sys.extended_properties AS ep ON ep.class = 5 AND ep.major_id = a.assembly_id AND ep.minor_id = 0
        INNER JOIN sys.assembly_files AS af ON af.assembly_id = a.assembly_id AND af.file_id = 1
        WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom' AND ep.name = N'Toolbelt.ModuleId'
          AND TRY_CONVERT(nvarchar(128), ep.value) = N'toolbelt.tsql.script-parser'
          AND HASHBYTES(N'SHA2_512', af.content) <> 0x24BDEE1CC5296488C3609BB6911DD76935B510F823CAAE4D39E8C45C84D272F3D28E3F6156E1E185C0F81D5812C9100E9C71CBE788966AC477A5B213BCE672D0)
        THROW 53117, N'Die moduleigene ScriptDom-Assembly stimmt nicht mit der qualifizierten Dependency überein.', 1;
    IF EXISTS
       (
           SELECT 1 FROM sys.sql_expression_dependencies
           WHERE referenced_id IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
             AND referencing_id NOT IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
       )
        THROW 53108, N'Die Deinstallation wird durch eine same-database Dependency blockiert.', 1;

    IF @AssemblyId IS NOT NULL
       AND EXISTS
           (
               SELECT 1 FROM sys.assembly_modules
               WHERE assembly_id = @AssemblyId
                 AND object_id NOT IN (ISNULL(@NodesId, -1), ISNULL(@PropsId, -1), ISNULL(@TokensId, -1), ISNULL(@ErrorsId, -1))
           )
        THROW 53108, N'Die ScriptParser-Assembly wird von einem fremden SQL-Objekt verwendet.', 2;

    IF @AssemblyId IS NOT NULL
       AND EXISTS
           (SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id = @AssemblyId)
        THROW 53108, N'Die ScriptParser-Assembly wird von einer anderen Assembly referenziert.', 3;

    IF EXISTS
       (SELECT 1 FROM sys.assemblies AS a
        INNER JOIN sys.extended_properties AS ep ON ep.class = 5 AND ep.major_id = a.assembly_id AND ep.minor_id = 0
        WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom' AND ep.name = N'Toolbelt.ModuleId'
          AND TRY_CONVERT(nvarchar(128), ep.value) = N'toolbelt.tsql.script-parser'
          AND (EXISTS (SELECT 1 FROM sys.assembly_references AS r WHERE r.referenced_assembly_id = a.assembly_id AND r.assembly_id <> ISNULL(@AssemblyId, -1))
               OR EXISTS (SELECT 1 FROM sys.assembly_modules AS m WHERE m.assembly_id = a.assembly_id)))
        THROW 53108, N'Die moduleigene ScriptDom-Assembly wird von einem fremden Verbraucher verwendet.', 4;

    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptNodes];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptNodeProperties];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_TokenizeScript];
    DROP FUNCTION IF EXISTS [toolbelt_tsql].[TVF_ParseScriptErrors];

    IF EXISTS (SELECT 1 FROM sys.assemblies WHERE name = N'Toolbelt_Tsql_ScriptParser')
        DROP ASSEMBLY [Toolbelt_Tsql_ScriptParser];

    IF EXISTS
       (SELECT 1 FROM sys.assemblies AS a
        INNER JOIN sys.extended_properties AS ep ON ep.class = 5 AND ep.major_id = a.assembly_id
        WHERE a.name = N'Microsoft.SqlServer.TransactSql.ScriptDom'
          AND ep.name = N'Toolbelt.ModuleId' AND TRY_CONVERT(nvarchar(128), ep.value) = N'toolbelt.tsql.script-parser')
        DROP ASSEMBLY [Microsoft.SqlServer.TransactSql.ScriptDom];

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
        EXEC sys.sp_dropextendedproperty @name = @VersionProperty;

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
        EXEC sys.sp_dropextendedproperty @name = @ModeProperty;

    IF SCHEMA_ID(N'toolbelt_tsql') IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_tsql'))
       AND EXISTS
           (
               SELECT 1 FROM sys.extended_properties
               WHERE class = 3 AND major_id = SCHEMA_ID(N'toolbelt_tsql')
                 AND name = N'Toolbelt.Managed' AND TRY_CONVERT(bit, value) = 1
           )
       AND EXISTS
           (SELECT 1 FROM sys.extended_properties
            WHERE class = 3 AND major_id = SCHEMA_ID(N'toolbelt_tsql') AND minor_id = 0
              AND name = N'Toolbelt.SchemaCategory' AND TRY_CONVERT(nvarchar(64), value) = N'tsql')
        DROP SCHEMA [toolbelt_tsql];

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* Der serverweite Hash-Trust bleibt ein separater administrativer Lifecycle. */
