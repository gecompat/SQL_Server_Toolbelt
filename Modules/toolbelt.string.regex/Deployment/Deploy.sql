:On Error exit
-- RETURN beendet den gesamten ersten Batch; SQLCMD stoppt vor weiteren Batches.
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'Der Regex-Lifecycle akzeptiert keine Caller-Transaktion.', 16, 1);
    RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;

DECLARE @VersionProperty sysname = N'Toolbelt.Module.toolbelt.string.regex.Version',
        @ModeProperty sysname = N'Toolbelt.Module.toolbelt.string.regex.DeploymentMode',
        @InstalledVersion nvarchar(max), @InstalledMode nvarchar(max),
        @Release int, @AssemblyId int, @InstalledAssemblyHash varbinary(64),
        @Pass int = 1, @OwnTransaction bit = 0;
DECLARE @Slots TABLE (Name sysname COLLATE DATABASE_DEFAULT PRIMARY KEY, SinceRelease int NOT NULL,
                      Kind char(2) COLLATE DATABASE_DEFAULT NOT NULL, ObjectId int NULL);
INSERT @Slots(Name, SinceRelease, Kind) VALUES
    (N'SVF_RegexIsMatch', 10, 'FS'),
    (N'SVF_RegexInstr', 10, 'FS'),
    (N'SVF_RegexCount', 10, 'FS'),
    (N'SVF_RegexReplace', 11, 'FN'),
    (N'SVF_RegexSubstring', 11, 'FN'),
    (N'SVF_RegexReplaceCore', 11, 'FS'),
    (N'SVF_RegexSubstringCore', 11, 'FS'),
    (N'TVF_RegexMatches', 12, 'IF'),
    (N'TVF_RegexSplit', 12, 'IF'),
    (N'TVF_RegexMatchesCore', 12, 'FT'),
    (N'TVF_RegexSplitCore', 12, 'FT'),
    (N'TVF_RegexCaptures', 13, 'IF'),
    (N'SVF_RegexReplaceGroups', 13, 'FN'),
    (N'TVF_RegexCapturesCore', 13, 'FT'),
    (N'SVF_RegexReplaceGroupsCore', 13, 'FS');
DECLARE @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)'),
        @AssemblyBits varbinary(max) = $(AssemblyBits), @AssemblyHash varbinary(64);
IF TRY_CONVERT(int, SERVERPROPERTY(N'ProductMajorVersion')) NOT IN (15, 16, 17)
    THROW 52030, N'Dieses Modul unterstützt SQL Server 2019, 2022 und 2025.', 1;
IF @DeploymentMode NOT IN (N'local', N'central')
    THROW 52031, N'DeploymentMode muss local oder central sein.', 1;
IF @AssemblyBits IS NULL OR DATALENGTH(@AssemblyBits) < 1024
    THROW 52043, N'AssemblyBits enthält kein plausibles Release-Binary.', 1;
SET @AssemblyHash = HASHBYTES(N'SHA2_512', @AssemblyBits);
BEGIN TRY
    WHILE @Pass <= 2
    BEGIN
        -- Beide Durchläufe lesen den aktuellen Katalog; der zweite läuft unter AppLock.
        SET @InstalledVersion = NULL;
        SET @InstalledMode = NULL;
        SET @AssemblyId = NULL;
        SET @InstalledAssemblyHash = NULL;
        SELECT @InstalledVersion = TRY_CONVERT(nvarchar(max), value)
        FROM sys.extended_properties
        WHERE class = 0 AND major_id = 0 AND minor_id = 0 AND name = @VersionProperty;
        SELECT @InstalledMode = TRY_CONVERT(nvarchar(max), value)
        FROM sys.extended_properties
        WHERE class = 0 AND major_id = 0 AND minor_id = 0 AND name = @ModeProperty;
        SET @Release = CASE CONVERT(varbinary(max), @InstalledVersion)
            WHEN CONVERT(varbinary(max), N'1.0.0') THEN 10
            WHEN CONVERT(varbinary(max), N'1.1.0') THEN 11
            WHEN CONVERT(varbinary(max), N'1.2.0') THEN 12
            WHEN CONVERT(varbinary(max), N'1.3.0') THEN 13 ELSE 0 END;
        IF @Release = 0 AND EXISTS (SELECT 1 FROM sys.extended_properties
            WHERE class = 0 AND major_id = 0 AND minor_id = 0 AND name = @VersionProperty)
            THROW 52032, N'Die installierte Modulversion ist nicht bekannt.', 1;
        SELECT @AssemblyId = a.assembly_id,
               @InstalledAssemblyHash = HASHBYTES(N'SHA2_512', f.content)
        FROM sys.assemblies a JOIN sys.assembly_files f
          ON f.assembly_id = a.assembly_id AND f.file_id = 1
        WHERE a.name = N'Toolbelt_String_Regex';
        UPDATE s SET ObjectId = o.object_id FROM @Slots s
        LEFT JOIN sys.objects o ON o.schema_id = SCHEMA_ID(N'toolbelt_string') AND o.name COLLATE DATABASE_DEFAULT = s.Name COLLATE DATABASE_DEFAULT;

        IF @Release = 0 AND (@AssemblyId IS NOT NULL OR @InstalledMode IS NOT NULL
            OR EXISTS (SELECT 1 FROM @Slots WHERE ObjectId IS NOT NULL))
            THROW 52033, N'Zielobjekte ohne bekannten Versionsmarker sind fremd belegt.', 7;
        IF @Release > 0 AND (@InstalledMode IS NULL OR
            CONVERT(varbinary(max), @InstalledMode) NOT IN
            (CONVERT(varbinary(max), N'local'), CONVERT(varbinary(max), N'central')))
            THROW 52033, N'Der installierte DeploymentMode ist nicht kohärent.', 1;
        IF SCHEMA_ID(N'toolbelt_string') IS NOT NULL AND
          (NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 3
            AND major_id = SCHEMA_ID(N'toolbelt_string') AND minor_id = 0
            AND name = N'Toolbelt.Managed' AND TRY_CONVERT(int, value) = 1)
           OR NOT EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 3
            AND major_id = SCHEMA_ID(N'toolbelt_string') AND minor_id = 0
            AND name = N'Toolbelt.SchemaCategory'
            AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), value)) = CONVERT(varbinary(max), N'string')))
            THROW 52033, N'Das vorhandene Schema hat keine eigene Toolbelt-Zuordnung.', 2;
        IF @Release > 0 AND EXISTS
          (SELECT 1 FROM @Slots s LEFT JOIN sys.objects o ON o.object_id = s.ObjectId
           WHERE s.SinceRelease <= @Release AND
           (o.object_id IS NULL OR o.type COLLATE DATABASE_DEFAULT <> s.Kind COLLATE DATABASE_DEFAULT
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 1
              AND e.major_id = o.object_id AND e.minor_id = 0 AND e.name = N'Toolbelt.Managed'
              AND TRY_CONVERT(int, e.value) = 1)
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 1
              AND e.major_id = o.object_id AND e.minor_id = 0 AND e.name = N'Toolbelt.ModuleId'
              AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), e.value)) = CONVERT(varbinary(max), N'toolbelt.string.regex'))
            OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 1
              AND e.major_id = o.object_id AND e.minor_id = 0 AND e.name = N'Toolbelt.ModuleVersion'
              AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), e.value)) = CONVERT(varbinary(max), @InstalledVersion))))
            THROW 52033, N'Das installierte Release-Objektmanifest ist nicht kohärent.', 3;
        -- Historische Assemblies haben keinen ModuleVersion-Marker. Ihre CLR-Version bleibt maßgeblich.
        IF @Release > 0 AND (@AssemblyId IS NULL OR @InstalledAssemblyHash IS NULL
          OR NOT EXISTS (SELECT 1 FROM sys.assemblies a WHERE a.assembly_id = @AssemblyId
              AND a.permission_set_desc = N'SAFE_ACCESS' AND a.is_user_defined = 1
              AND LEFT(LOWER(a.clr_name), LEN(N'toolbelt.string.regex, version=' + @InstalledVersion + N'.0,'))
                    COLLATE Latin1_General_100_BIN2 = N'toolbelt.string.regex, version=' + @InstalledVersion + N'.0,')
          OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 5
              AND e.major_id = @AssemblyId AND e.minor_id = 0 AND e.name = N'Toolbelt.Managed' AND TRY_CONVERT(int, e.value) = 1)
          OR NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 5
              AND e.major_id = @AssemblyId AND e.minor_id = 0 AND e.name = N'Toolbelt.ModuleId'
              AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), e.value)) = CONVERT(varbinary(max), N'toolbelt.string.regex'))
          OR (@Release = 13 AND NOT EXISTS (SELECT 1 FROM sys.extended_properties e WHERE e.class = 5
              AND e.major_id = @AssemblyId AND e.minor_id = 0 AND e.name = N'Toolbelt.ModuleVersion'
              AND CONVERT(varbinary(max), TRY_CONVERT(nvarchar(max), e.value)) = CONVERT(varbinary(max), @InstalledVersion))))
            THROW 52033, N'Die installierte Assembly-Zuordnung oder CLR-Version ist nicht kohärent.', 4;
        IF EXISTS (SELECT 1 FROM sys.sql_expression_dependencies d
              JOIN @Slots s ON s.ObjectId = d.referenced_id AND s.SinceRelease <= @Release
              WHERE NOT EXISTS (SELECT 1 FROM @Slots own WHERE own.ObjectId = d.referencing_id AND own.SinceRelease <= @Release))
            THROW 52038, N'Eine fremde same-database Dependency blockiert den Lifecycle.', 1;
        IF EXISTS (SELECT 1 FROM sys.assembly_modules m WHERE m.assembly_id = @AssemblyId
              AND NOT EXISTS (SELECT 1 FROM @Slots s WHERE s.ObjectId = m.object_id AND s.SinceRelease <= @Release AND s.Kind IN ('FS', 'FT')))
           OR EXISTS (SELECT 1 FROM sys.assembly_references WHERE referenced_assembly_id = @AssemblyId)
            THROW 52038, N'Ein fremder Assembly-Verbraucher blockiert den Lifecycle.', 2;
        IF EXISTS (SELECT 1 FROM @Slots s JOIN sys.assembly_modules m ON m.object_id = s.ObjectId
              WHERE s.SinceRelease <= @Release AND s.Kind IN ('FS', 'FT') AND m.assembly_id <> @AssemblyId)
            THROW 52033, N'Ein CLR-Kern verweist auf eine andere Assembly.', 5;
        IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = N'clr enabled' AND value_in_use = 1)
            THROW 52040, N'CLR ist nicht aktiviert; der Lifecycle ändert keine Instanzoption.', 1;
        IF NOT EXISTS (SELECT 1 FROM sys.configurations WHERE name = N'clr strict security' AND value_in_use = 1)
            THROW 52042, N'clr strict security muss aktiviert bleiben.', 1;
        IF @AssemblyHash IS NULL OR NOT EXISTS (SELECT 1 FROM sys.trusted_assemblies WHERE hash = @AssemblyHash)
            THROW 52045, N'Der exakte Release-Hash ist nicht freigegeben.', 1;
        -- Neue Slots gehören keinem Vorgängerrelease, auch mit imitierten Markern.
        IF EXISTS (SELECT 1 FROM @Slots WHERE SinceRelease > @Release AND ObjectId IS NOT NULL)
            OR (@Release = 0 AND (@AssemblyId IS NOT NULL OR @InstalledMode IS NOT NULL))
            THROW 52033, N'Ein Zielslot oder die Assembly ist fremd belegt.', 6;
        IF SCHEMA_ID(N'toolbelt_string') IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE SCHEMA'), 0) <> 1
            THROW 52034, N'CREATE SCHEMA fehlt.', 1;
        IF SCHEMA_ID(N'toolbelt_string') IS NOT NULL AND ISNULL(HAS_PERMS_BY_NAME(N'toolbelt_string', N'SCHEMA', N'ALTER'), 0) <> 1
            THROW 52034, N'ALTER auf toolbelt_string fehlt.', 2;
        IF ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE FUNCTION'), 0) <> 1
            THROW 52034, N'CREATE FUNCTION fehlt.', 3;
        IF @AssemblyId IS NULL AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'CREATE ASSEMBLY'), 0) <> 1
            THROW 52034, N'CREATE ASSEMBLY fehlt.', 4;
        IF @AssemblyId IS NOT NULL AND @InstalledAssemblyHash <> @AssemblyHash
           AND ISNULL(HAS_PERMS_BY_NAME(DB_NAME(), N'DATABASE', N'ALTER ANY ASSEMBLY'), 0) <> 1
            THROW 52034, N'ALTER ANY ASSEMBLY fehlt.', 5;
        IF @Pass = 1
        BEGIN
            BEGIN TRANSACTION;
            SET @OwnTransaction = 1;
            DECLARE @LockResult int;
            EXEC @LockResult = sys.sp_getapplock
                  @Resource = N'toolbelt.deploy.toolbelt.string.regex',
                  @LockMode = N'Exclusive', @LockOwner = N'Transaction',
                  @LockTimeout = 0, @DbPrincipal = N'public';
            IF @LockResult < 0
                THROW 52035, N'Ein paralleler Regex-Lifecycle ist bereits aktiv.', 1;
        END;
        SET @Pass += 1;
    END;
    IF SCHEMA_ID(N'toolbelt_string') IS NULL
    BEGIN
        EXEC sys.sp_executesql N'CREATE SCHEMA [toolbelt_string];';
        EXEC sys.sp_addextendedproperty @name = N'Toolbelt.Managed', @value = 1,
             @level0type = N'SCHEMA', @level0name = N'toolbelt_string';
        EXEC sys.sp_addextendedproperty @name = N'Toolbelt.SchemaCategory', @value = N'string',
             @level0type = N'SCHEMA', @level0name = N'toolbelt_string';
    END;
    IF @Release >= 10 DROP FUNCTION [toolbelt_string].[SVF_RegexCount];
    IF @Release >= 10 DROP FUNCTION [toolbelt_string].[SVF_RegexInstr];
    IF @Release >= 10 DROP FUNCTION [toolbelt_string].[SVF_RegexIsMatch];
    IF @Release >= 11 DROP FUNCTION [toolbelt_string].[SVF_RegexReplace];
    IF @Release >= 13 DROP FUNCTION [toolbelt_string].[SVF_RegexReplaceGroups];
    IF @Release >= 11 DROP FUNCTION [toolbelt_string].[SVF_RegexSubstring];
    IF @Release >= 13 DROP FUNCTION [toolbelt_string].[TVF_RegexCaptures];
    IF @Release >= 12 DROP FUNCTION [toolbelt_string].[TVF_RegexMatches];
    IF @Release >= 12 DROP FUNCTION [toolbelt_string].[TVF_RegexSplit];
    IF @Release >= 11 DROP FUNCTION [toolbelt_string].[SVF_RegexReplaceCore];
    IF @Release >= 13 DROP FUNCTION [toolbelt_string].[SVF_RegexReplaceGroupsCore];
    IF @Release >= 11 DROP FUNCTION [toolbelt_string].[SVF_RegexSubstringCore];
    IF @Release >= 13 DROP FUNCTION [toolbelt_string].[TVF_RegexCapturesCore];
    IF @Release >= 12 DROP FUNCTION [toolbelt_string].[TVF_RegexMatchesCore];
    IF @Release >= 12 DROP FUNCTION [toolbelt_string].[TVF_RegexSplitCore];
    IF @InstalledAssemblyHash IS NULL OR @InstalledAssemblyHash <> @AssemblyHash
    BEGIN
        DECLARE @AssemblyDdl nvarchar(max) =
            CASE WHEN @AssemblyId IS NULL THEN N'CREATE' ELSE N'ALTER' END
            + N' ASSEMBLY [Toolbelt_String_Regex] FROM ' + CONVERT(nvarchar(max), @AssemblyBits, 1)
            + N' WITH PERMISSION_SET = SAFE;';
        EXEC sys.sp_executesql @AssemblyDdl;
    END;
END TRY
BEGIN CATCH
    IF @OwnTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

:r ../Source/RegexFunctions.sql
:r ../Source/RegexRelations.sql
:r ../Source/RegexCaptures.sql

SET NOCOUNT ON;
BEGIN TRY
    IF @@TRANCOUNT <> 1
        THROW 52039, N'Die Deployment-Transaktion ist vorzeitig beendet worden.', 1;

    DECLARE
          @VersionProperty sysname =
              N'Toolbelt.Module.toolbelt.string.regex.Version'
        , @ModeProperty sysname =
              N'Toolbelt.Module.toolbelt.string.regex.DeploymentMode'
        , @DeploymentMode nvarchar(16) = LOWER(N'$(DeploymentMode)');

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @VersionProperty)
        EXEC sys.sp_updateextendedproperty @name = @VersionProperty, @value = N'1.3.0';
    ELSE
        EXEC sys.sp_addextendedproperty @name = @VersionProperty, @value = N'1.3.0';

    IF EXISTS (SELECT 1 FROM sys.extended_properties WHERE class = 0 AND name = @ModeProperty)
        EXEC sys.sp_updateextendedproperty @name = @ModeProperty, @value = @DeploymentMode;
    ELSE
        EXEC sys.sp_addextendedproperty @name = @ModeProperty, @value = @DeploymentMode;

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

    IF EXISTS (SELECT 1 FROM sys.extended_properties e JOIN sys.assemblies a ON a.assembly_id = e.major_id
               WHERE e.class = 5 AND e.name = N'Toolbelt.ModuleVersion' AND a.name = N'Toolbelt_String_Regex')
        EXEC sys.sp_updateextendedproperty @name = N'Toolbelt.ModuleVersion', @value = N'1.3.0',
             @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_Regex';
    ELSE
        EXEC sys.sp_addextendedproperty @name = N'Toolbelt.ModuleVersion', @value = N'1.3.0',
             @level0type = N'ASSEMBLY', @level0name = N'Toolbelt_String_Regex';

    DECLARE @FunctionName sysname;
    DECLARE FunctionCursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT name
        FROM sys.objects
        WHERE schema_id = SCHEMA_ID(N'toolbelt_string')
          AND name IN (N'SVF_RegexIsMatch', N'SVF_RegexInstr', N'SVF_RegexCount', N'SVF_RegexReplace', N'SVF_RegexSubstring', N'SVF_RegexReplaceCore', N'SVF_RegexSubstringCore', N'TVF_RegexMatches', N'TVF_RegexSplit', N'TVF_RegexMatchesCore', N'TVF_RegexSplitCore', N'TVF_RegexCaptures', N'SVF_RegexReplaceGroups', N'TVF_RegexCapturesCore', N'SVF_RegexReplaceGroupsCore');
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
              @name = N'Toolbelt.ModuleVersion', @value = N'1.3.0'
            , @level0type = N'SCHEMA', @level0name = N'toolbelt_string'
            , @level1type = N'FUNCTION', @level1name = @FunctionName;
        DECLARE @Visibility nvarchar(16) = CASE WHEN @FunctionName IN (N'SVF_RegexReplaceCore', N'SVF_RegexSubstringCore',N'TVF_RegexMatchesCore',N'TVF_RegexSplitCore', N'TVF_RegexCapturesCore', N'SVF_RegexReplaceGroupsCore') THEN N'internal' ELSE N'public' END;
        EXEC sys.sp_addextendedproperty
              @name = N'Toolbelt.Visibility', @value = @Visibility
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
