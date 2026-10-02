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
DECLARE @ConfirmNoExternalConsumers bit = TRY_CONVERT(bit, N'$(ConfirmNoExternalConsumers)');
IF @ConfirmNoExternalConsumers IS NULL OR N'$(ConfirmNoExternalConsumers)' NOT IN (N'0', N'1')
    THROW 52036, N'ConfirmNoExternalConsumers muss 0 oder 1 sein.', 1;
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
        IF @Release = 0
        BEGIN
            IF @OwnTransaction = 1 COMMIT TRANSACTION;
            RETURN;
        END;
        IF @InstalledMode = N'central' AND @ConfirmNoExternalConsumers <> 1
            THROW 52036, N'Zentrale Installation benötigt ConfirmNoExternalConsumers=1.', 2;
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
    DROP ASSEMBLY [Toolbelt_String_Regex];
    EXEC sys.sp_dropextendedproperty @name = @VersionProperty;
    EXEC sys.sp_dropextendedproperty @name = @ModeProperty;
    -- Unbekannte zukünftige Slots und fremde Objekte bleiben erhalten.
    IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE schema_id = SCHEMA_ID(N'toolbelt_string'))
        DROP SCHEMA [toolbelt_string];
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @OwnTransaction = 1 AND XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

/* Der serverweite Hash-Trust bleibt ein separater administrativer Lifecycle. */
